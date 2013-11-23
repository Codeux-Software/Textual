/* ********************************************************************* 
       _____        _               _    ___ ____   ____
      |_   _|___  _| |_ _   _  __ _| |  |_ _|  _ \ / ___|
       | |/ _ \ \/ / __| | | |/ _` | |   | || |_) | |
       | |  __/>  <| |_| |_| | (_| | |   | ||  _ <| |___
       |_|\___/_/\_\\__|\__,_|\__,_|_|  |___|_| \_\\____|

 Copyright (c) 2010 — 2013 Codeux Software & respective contributors.
        Contributors.rtfd and Acknowledgements.rtfd

 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions
 are met:

    * Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the
      documentation and/or other materials provided with the distribution.
    * Neither the name of the Textual IRC Client & Codeux Software nor the
      names of its contributors may be used to endorse or promote products
      derived from this software without specific prior written permission.

 THIS SOFTWARE IS PROVIDED BY THE AUTHOR AND CONTRIBUTORS ``AS IS'' AND
 ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 ARE DISCLAIMED. IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE LIABLE
 FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
 OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
 LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
 OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
 SUCH DAMAGE.

 *********************************************************************** */

#import "TextualApplication.h"

#ifdef TEXTUAL_BUILT_WITH_ICLOUD_SUPPORT

/* Internal cloud work is divided into two timers. Important work such as
 syncing upstream to the cloud is put on a per-minute timer. This timer
 also checks if a theme stored in the temporary store now exists. 
 
 The second timer is ten-minute (roughly) based and handles less important
 tasks. When this comment was written, it only handled the checking of
 whether fonts exist, but it could be changed to include more later. */
#define _localKeysUpstreamSyncTimerInterval_1			60.0	// 1 minute
#define _localKeysUpstreamSyncTimerInterval_2			630.0	// 10 minutes, 30 seconds

@interface TPCPreferencesCloudSync ()
@property (nonatomic, strong) id ubiquityIdentityToken;
@property (nonatomic, assign) BOOL localKeysWereUpdated;
@property (nonatomic, assign) BOOL isSyncingLocalKeysDownstream;
@property (nonatomic, assign) BOOL isSyncingLocalKeysUpstream;
@property (nonatomic, assign) BOOL initialMetadataQueryCompleted;
@property (nonatomic, assign) dispatch_queue_t workerQueue;
@property (nonatomic, strong) NSTimer *cloudOneMinuteSyncTimer;
@property (nonatomic, strong) NSTimer *cloudTenMinuteSyncTimer;
@property (nonatomic, strong) NSURL *ubiquitousContainerURL;
@property (nonatomic, strong) NSMetadataQuery *cloudContainerNotificationQuery;
@end

@implementation TPCPreferencesCloudSync

#pragma mark -
#pragma mark Public API

- (void)setValue:(id)value forKey:(NSString *)key
{
	NSObjectIsEmptyAssert(key); // Yeah, we need a key…
	
	/* Set it and forget it. */
	NSString *hashedKey = [NSString stringWithUnsignedInteger:[key hash]];
	
	[RZUbiquitousKeyValueStore() setObject:@{@"key" : key, @"value" : value} forKey:hashedKey];
}

- (id)valueForKey:(NSString *)key
{
	NSObjectIsEmptyAssertReturn(key, nil); // Yeah, we need a key…
	
	/* Insert pointless comment here. */
	NSString *hashedKey = [NSString stringWithUnsignedInteger:[key hash]];
	
	/* Another pointless comment here. */
	return [self valueForHashedKey:hashedKey actualKey:NULL];
}

- (id)valueForHashedKey:(NSString *)key actualKey:(NSString **)realKeyValue /* @private */
{
	/* Get initial value. */
	id dictObject = [RZUbiquitousKeyValueStore() objectForKey:key];
	
	/* We are only looking for dictionary entries… */
	NSObjectIsKindOfClassAssertReturn(dictObject, NSDictionary, nil);
	
	/* Gather entry info. */
	id keyname = [dictObject objectForKey:@"key"];
	id objectValue = [dictObject objectForKey:@"value"];
	
	/* Some validation. Not strict, but meh… */
	PointerIsEmptyAssertReturn(keyname, nil);
	PointerIsEmptyAssertReturn(objectValue, nil);
	
	/* Give it back. */
	if (NSDissimilarObjects(realKeyValue, NULL)) {
		*realKeyValue = keyname;
	}
	
	return objectValue;
}

- (void)removeObjectForKey:(NSString *)key
{
	NSObjectIsEmptyAssert(key); // Yeah, we need a key…
	
	/* Set it and forget it. */
	NSString *hashedKey = [NSString stringWithUnsignedInteger:[key hash]];
	
	/* Umm, I just copy and paste these things. */
	[RZUbiquitousKeyValueStore() removeObjectForKey:hashedKey];
}

#pragma mark -
#pragma mark URL Management

- (void)setupUbiquitousContainerURLPath
{
	dispatch_async(self.workerQueue, ^{
		/* Apple very clearly states not to do call this on the main thread
		 since it does a lot of work, so we wont… */
		NSURL *ucurl = [RZFileManager() URLForUbiquityContainerIdentifier:nil];
		
		if (ucurl) {
			self.ubiquitousContainerURL = ucurl;
		} else {
			self.ubiquitousContainerURL = nil;
			
			LogToConsole(@"iCloud Access Is Not Available.");
		}
	});
}

- (NSString *)ubiquitousContainerURLPath
{
	/* Return a path if we have it… */
	if (self.ubiquitousContainerURL) {
		return [self.ubiquitousContainerURL path];
	}
	
	return nil;
}

#pragma mark -
#pragma mark Cloud Sync Management

- (void)synchronizeToCloud
{
	[self syncPreferencesToCloud];
}

- (void)synchronizeFromCloud
{
	[self syncPreferencesFromCloud:nil];
}

- (void)performTenMinuteTimeBasedMaintenance
{
	/* We don't even want to sync if user doesn't want to. */
	NSAssertReturn([TPCPreferences syncPreferencesToTheCloud]);
	
	DebugLogToConsole(@"iCloud: Performing ten-minute based maintenance.");
	
	/* Perform actual maintenance tasks. */
	dispatch_async(self.workerQueue, ^{
		/* Compare fonts. */
		BOOL fontMissing = [RZUserDefaults() boolForKey:TPCPreferencesThemeFontNameMissingLocallyDefaultsKey];
		
		if (fontMissing) {
			NSString *remoteValue = [self valueForKey:TPCPreferencesThemeFontNameDefaultsKey];
			
			NSString *localFontVa = [TPCPreferences themeChannelViewFontName];
			
			/* Do the actual compare… */
			if (remoteValue && [localFontVa isEqual:remoteValue] == NO) {
				if ([NSFont fontIsAvailable:remoteValue]) {
					DebugLogToConsole(@"iCloud: Remote font does not match local font. Setting font and reloading theme.");
					
					[TPCPreferences setThemeChannelViewFontName:remoteValue]; // Will remove the BOOL
					
					/* Font only applies to actual theme so we don't have to reload sidebars too… */
					[TPCPreferences performReloadActionForActionType:TPCPreferencesKeyReloadStyleAction];
				}
			}
		}
	});
}

- (void)performOneMinuteTimeBasedMaintenance
{
	/* We don't even want to sync if user doesn't want to. */
	NSAssertReturn([TPCPreferences syncPreferencesToTheCloud]);
	
	/* Perform a sync. */
	[self synchronizeToCloud];
	
	/* Perform actual maintenance tasks. */
	dispatch_async(self.workerQueue, ^{
		/* Have a theme in the temporary store? */
		BOOL missingTheme = [RZUserDefaults() boolForKey:TPCPreferencesThemeNameMissingLocallyDefaultsKey];
		
		/* If we do, pass it through the set property to set it or continue to keep in store. */
		if (missingTheme) {
			NSString *temporaryTheme = [self valueForKey:TPCPreferencesThemeNameDefaultsKey];
			
			if ([TPCThemeController themeExists:temporaryTheme]) {
				DebugLogToConsole(@"iCloud: Theme name \"%@\" is stored in the temporary store and will now be applied.", temporaryTheme);
				
				[TPCPreferences setThemeName:temporaryTheme]; // Will reset the BOOL
				
				[TPCPreferences performReloadActionForActionType:TPCPreferencesKeyReloadStyleAction];
				[TPCPreferences performReloadActionForActionType:TPCPreferencesKeyReloadMemberListAction];
				[TPCPreferences performReloadActionForActionType:TPCPreferencesKeyReloadServerListAction];
			} else {
				DebugLogToConsole(@"iCloud: Theme name \"%@\" is stored in the temporary store.", temporaryTheme);
			}
		}
	});
}

- (BOOL)keyIsNotPermittedInCloud:(NSString *)key
{
	return ([key isEqualToString:IRCWorldControllerDefaultsStorageKey] ||
			[key isEqualToString:TPCPreferencesCloudSyncDefaultsKey] ||
			[key isEqualToString:TPCPreferencesThemeNameMissingLocallyDefaultsKey] ||
			[key isEqualToString:TPCPreferencesThemeFontNameMissingLocallyDefaultsKey]);
}

- (void)syncPreferencesToCloud
{
	/* We don't even want to sync if user doesn't want to. */
	NSAssertReturn([TPCPreferences syncPreferencesToTheCloud]);
	
	dispatch_async(self.workerQueue, ^{
		if (self.localKeysWereUpdated == NO) {
			DebugLogToConsole(@"iCloud: Upstream sync cancelled because nothing has changed.");
			
			return; // Cancel this operation;
		}
		
		if (self.isSyncingLocalKeysDownstream) {
			DebugLogToConsole(@"iCloud: Upstream sync cancelled because a downstream sync was already running.");
			
			return; // Cancel this operation;
		}
		
		if (self.isSyncingLocalKeysUpstream) {
			DebugLogToConsole(@"iCloud: Upstream sync cancelled because an upstream sync was already running.");
			
			return; // Cancel this operation;
		}
		
		if (self.hasUncommittedDataStoredInCloud) {
			DebugLogToConsole(@"iCloud: Upstream sync cancelled because there is uncommitted data remaining in the cloud.");
			
			return; // Cancel this operation;
		}
		
		/* Debug data. */
		DebugLogToConsole(@"iCloud: Beginning sync upstream.");
		
		/* Continue normal work. */
		self.isSyncingLocalKeysUpstream = YES;

		/* Gather dictionary representation of all local preferences. */
		NSDictionary *localdict = [TPCPreferencesImportExport exportedPreferencesDictionaryRepresentation];
		
		NSMutableDictionary *clientDict = [self.worldController cloudDictionaryValue];
		
		/* Combine these two… */
		[clientDict addEntriesFromDictionary:localdict];

		/* Sync latest changes from disc for the dictionary. */
		[RZUbiquitousKeyValueStore() synchronize];
		
		/* Compare to the remote. */
		NSDictionary *remotedict = [RZUbiquitousKeyValueStore() dictionaryRepresentation];
		
		NSArray *remotedictkeys = [remotedict allKeys];
		
		/* Get a copy of our defaults. */
		NSDictionary *defaults = [TPCPreferences defaultPreferences];
		
		NSArray *defaultskeys = [defaults allKeys];
		
		if ([clientDict isEqual:remotedict]) {
			DebugLogToConsole(@"iCloud: Remote dictionary and local dictionary are the same. Not syncing.");
		} else {
			/* Set the remote dictionary. */
			/* Some people may look at this code and wonder what the fuck was this
			 developer thinking? Well, since I know I will be asking myself that in
			 probably a few months when I need to maintain this code; I will explain.

			 You cannot have a key longer than 64 bytes in iCloud so what am I going
			 to do when there are keys stored by Textual longer than that? Rewrite
			 the entire internals of Textual to use shorter keys? Ha, as-if… Instead
			 just use a static hash of the key name as the actual key, then have the
			 value of the key a dictionary with the real key name in it and the value. */
			[clientDict enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
				if ([self keyIsNotPermittedInCloud:key]) {
					// Nobody cares about this…
				} else {
					/* Special save conditions. */
					if ([key isEqualToString:TPCPreferencesThemeNameDefaultsKey]) {
						/* Do not save the theme name, if we have something set in
						 the temporary story. */
						/* This defaults key as well as the one for TPCPreferencesThemeFontNameMissingLocallyDefaultsKey
						 resets if user actually changes these value locally instead of the cloud doing it
						 so if the user decided to change the value on this machine, it will still sync. */
						
						BOOL missingTheme = [RZUserDefaults() boolForKey:TPCPreferencesThemeNameMissingLocallyDefaultsKey];
						
						if (missingTheme) {
							return; // Skip this entry.
						}
					} else if ([key isEqualToString:TPCPreferencesThemeFontNameDefaultsKey]) {
						BOOL fontMissing = [RZUserDefaults() boolForKey:TPCPreferencesThemeFontNameMissingLocallyDefaultsKey];
		
						if (fontMissing) {
							return; // Skip this entry.
						}
					}
					
					/* If the key does not already exist in the cloud, then we check 
					 if its value matches the default value maintained internally. If
					 it has not changed from the default, why are we saving it? */
					BOOL keyExistsInCloud = [remotedictkeys containsObject:key];
					BOOL keyExistsInDefaults = [defaultskeys containsObject:key];
					
					if (keyExistsInCloud == NO && keyExistsInDefaults) {
						id defaultsValue = [defaults objectForKey:key];
						
						if ([defaultsValue isEqual:obj]) {
							return; // Nothing has changed…
						}
					}
					
					[self setValue:obj forKey:key];
				}
			}];
		}

		/* Allow us to continue work. */
		self.isSyncingLocalKeysUpstream = NO;
		self.localKeysWereUpdated = NO;

		DebugLogToConsole(@"iCloud: Completeing sync upstream.");
	});
}

- (void)syncPreferencesFromCloud:(NSArray *)changedKeys
{
	/* We don't even want to sync if user doesn't want to. */
	NSAssertReturn([TPCPreferences syncPreferencesToTheCloud]);
	
	dispatch_async(self.workerQueue, ^{
		/* Debug data. */
		DebugLogToConsole(@"iCloud: Beginning sync downstream.");

		/* Announce our intents… */
		self.isSyncingLocalKeysDownstream = YES;

		/* Get the list of changed keys. */
		NSArray *changedKeyList = changedKeys;
		
		if (PointerIsEmpty(changedKeyList) || changedKeyList.count <= 0) {
			/* If the list is empty, then we populate every single key. */
			NSDictionary *upstreamRep = [RZUbiquitousKeyValueStore() dictionaryRepresentation];
			
			changedKeyList = [upstreamRep allKeys];
		}
		
		/* See the code of syncPreferencesToCloud: for an expalantion of how these keys are hashed. */
		NSMutableArray *actualChangedKeys = [NSMutableArray array];
		NSMutableArray *importedClients = [NSMutableArray array];
		
		for (id hashedKey in changedKeyList) {
			id keyname = nil;
			id objectValue = [self valueForHashedKey:hashedKey actualKey:&keyname];
			
			if (objectValue && keyname) {
				/* Compare the local to the new. */
				/* This is for when we are going through the entire dictionary. */
				id localValue = [RZUserDefaults() objectForKey:keyname];
				
				if (localValue && [localValue isEqual:objectValue]) {
					continue; // They are same. Don't even try to set.
				}
				
				/* Set it to the new dictionary. */
				if ([keyname isEqual:IRCWorldControllerCloudDeletedClientsStorageKey])
				{
					NSObjectIsKindOfClassAssert(objectValue, NSArray);
					
					dispatch_async(dispatch_get_main_queue(), ^{
						[self.worldController processCloudCientDeletionList:objectValue];
					});
				}
				else if ([keyname hasPrefix:IRCWorldControllerCloudClientEntryKeyPrefix])
				{
					NSObjectIsKindOfClassAssert(objectValue, NSDictionary);
					
					/* Bet you're wondering why this is added to an array instead of
					 just calling the importWorld… method. Well, it took me a long time
					 to figure this out too. It used to just call the method directly,
					 then I realized, doing that creates a new instance of TVCLogController
					 for each client/channel added. That's all fine, but if the theme
					 ends up changing when calling the TPCPreferences reload… method 
					 below, then that will also reload the theme of thenewly created 
					 view controller instance creating a race condition. Now, we just
					 reload the theme then create the views afterwars. */
					
					[importedClients addObject:objectValue];
				}
				else
				{
					[actualChangedKeys addObject:keyname];
					
					[TPCPreferencesImportExport import:objectValue withKey:keyname];
				}
			}
		}

		/* Perform reload. */
		dispatch_async(dispatch_get_main_queue(), ^{
				if (actualChangedKeys.count > 0) {
					[TPCPreferences performReloadActionForKeyValues:actualChangedKeys];
				}
				
				if (importedClients.count > 0) {
					for (NSDictionary *seed in importedClients) {
						[TPCPreferencesImportExport importWorldControllerClientConfiguratoin:seed isCloudBasedImport:YES];
					}
				}
			});

		/* Allow us to continue work. */
		self.isSyncingLocalKeysDownstream = NO;
		
		/* If we made it this far, reset this notificaiton. */
		_hasUncommittedDataStoredInCloud = NO;
		
		DebugLogToConsole(@"iCloud: Completeing sync downstream.");
	});
}

- (void)syncPreferenceFromCloudNotification:(NSNotification *)aNote
{
	/* Gather information about the sync request. */
	NSInteger syncReason = [aNote.userInfo integerForKey:NSUbiquitousKeyValueStoreChangeReasonKey];
	
	/* Are we out of memory? */
	if (syncReason == NSUbiquitousKeyValueStoreQuotaViolationChange) {
		[self cloudStorageLimitExceeded]; // We will not be syncing for this error.
	} else {
		/* It is kind of important to know this. */
		/* Even if we do not handle it, we still want to know
		 if iCloud tried to sync something to this client. */
		_hasUncommittedDataStoredInCloud = YES;
		
		/* Get the list of changed keys. */
		NSArray *changedKeys = [aNote.userInfo arrayForKey:NSUbiquitousKeyValueStoreChangedKeysKey];

		/* Do the work. */
		[self syncPreferencesFromCloud:changedKeys];
	}
}

- (void)localKeysDidChangeNotification:(NSNotification *)aNote
{
	if (self.localKeysWereUpdated == NO) {
		self.localKeysWereUpdated = YES;
	}
}

#pragma mark -
#pragma mark Misc. Notificatoins

/* 
	To quote Apple's own documentation:
	
	"The total space available in your app’s iCloud key-value storage is 1 MB per user. 
	The maximum number of keys you can specify is 1024, and the size limit for each 
	value associated with a key is 1 MB. For example, if you store a single large 
	value of exactly 1 MB for a single key, that fully consumes your quota for a 
	given user of your app. If you store 1 KB of data for each key, you can use 
	1,000 key-value pairs.

	The maximum length for a key string is 64 bytes using UTF8 encoding. The data 
	size of your cumulative key strings does not count against your 1 MB total 
	quota for iCloud key-value storage; rather, your key strings (which at maximum 
	consume 64 KB) count against a user’s total iCloud allotment."
*/

- (void)cloudStorageLimitExceeded
{
#warning TODO: Make user aware of this…
	LogToConsole(@"The cloud storage limit was exceeded.");
}

#pragma mark -
#pragma mark Container Updates

/* This call has several layers of complexities on it. Therefore, it wont be used for anything
 more than copying to the cache. The actual detection of theme changes can be handled by the
 timers which they were designed to do. */
- (void)cloudMetadataQueryDidUpdate:(NSNotification *)notification
{
	dispatch_async(self.workerQueue, ^{
		/* Do not accept updates during work. */
		[self.cloudContainerNotificationQuery disableUpdates];
		
		/* Get the existing cache path. */
		NSString *cachePath = [TPCPreferences cloudCustomThemeCachedFolderPath];
		NSString *ubiqdPath = [TPCPreferences cloudCustomThemeFolderPath];
		
		NSObjectIsEmptyAssert(ubiqdPath);
		
		NSURL *cachePahtURL = [NSURL fileURLWithPath:cachePath];
		NSURL *ubiqdPathURL = [NSURL fileURLWithPath:ubiqdPath];
		
		/* ========================================================== */
	
		/* We will now enumrate through all existing cache files gathering a list of those that
		 exist and their modification dates. This information is stored in a dictionary with the
		 file URL being the dictionary key and the value being its modification date. */
		NSDirectoryEnumerator *enumerator = [RZFileManager() enumeratorAtURL:cachePahtURL
												  includingPropertiesForKeys:@[NSURLIsDirectoryKey, NSURLContentModificationDateKey]
																	 options:NSDirectoryEnumerationSkipsHiddenFiles
																errorHandler:^(NSURL *url, NSError *error)
																{
																	DebugLogToConsole(@"Enumeration Error: %@", [error localizedDescription]);
																	
																	return YES; // Continue regardless of error.
																}];
		
		/* Build list of files. */
		NSMutableDictionary *cachedFiles = [NSMutableDictionary dictionary];
		
		/* Enumrate the cache. */
		for (NSURL *itemURL in enumerator) {
			NSError *error;
			
			NSNumber *isDirectory = nil;
			
			/* Directories and files are handled differently. This handles that. */
			if ([itemURL getResourceValue:&isDirectory forKey:NSURLIsDirectoryKey error:&error]) {
				/* Get the path of this item minus the prefix path. */
				NSString *path = [itemURL.path stringByDeletingPreifx:cachePahtURL.path];
				
				/* Continus processing… */
				if ([isDirectory boolValue]) {
					/* We do not care about modification dates of directories. */
					[cachedFiles setObject:[NSNull null] forKey:path];
				} else {
					/* Path is a file. We need it's modification date. */
					NSDate *fileDate;
					
					if ([itemURL getResourceValue:&fileDate forKey:NSURLContentModificationDateKey error:&error]) {
						[cachedFiles setObject:fileDate forKey:path];
					}
				}
			}
		}
		
		/* ========================================================== */
		
		/* Now that we have an idea of our existing cache, we can
		 go through our actual iCloud data and update files. */
		
		/* Go through each result item and do work. */
		NSUInteger resultCount = [self.cloudContainerNotificationQuery resultCount];
		
		for (int i = 0; i < resultCount; i++) {
			NSMetadataItem *item = [self.cloudContainerNotificationQuery resultAtIndex:i];
			
			/* First thing first is to get the URL. */
			NSURL *fileURL = [item valueForAttribute:NSMetadataItemURLKey];
			
			/* Build some relevant path information. */
			/* First the path to the file minus its path prefix. */
			NSString *basicFilePath = [fileURL.path stringByDeletingPreifx:ubiqdPathURL.path];
			
			/* Then the actual folder in which the file is stored. */
			NSString *basicFolderPath = [basicFilePath stringByDeletingLastPathComponent];
			
			/* More paths, lol. */
			NSURL *cachedFolderLocation = [cachePahtURL URLByAppendingPathComponent:basicFolderPath];
			NSURL *cachedFileLocation = [cachePahtURL URLByAppendingPathComponent:basicFilePath];
			
			/* Now, we begin gathering relevant information about the file. */
			BOOL updateOrAddFile = NO; // Used later on…
			BOOL removeFromCacheArray = NO; // Setting to YES will remove the file from deletion pool.
			
			BOOL cloudFileExists = [RZFileManager() fileExistsAtPath:fileURL.path];
			BOOL cachedFileExists = [RZFileManager() fileExistsAtPath:cachedFileLocation.path];
			
			NSDate *lastChangeDate = [item valueForAttribute:NSMetadataItemFSContentChangeDateKey];
			
			NSNumber *isDownloaded = [item valueForAttribute:NSMetadataUbiquitousItemIsDownloadedKey];
			
			/* ========================================================== */
			
			/* Begin work. */
			if ([isDownloaded boolValue] == NO) {
				if (cachedFileExists) {
					removeFromCacheArray = YES; // Do not delete cached file.
				}
			} else {
				if (cachedFileExists == NO) {
					if (cloudFileExists) {
						updateOrAddFile = YES;
					}
				} else {
					/* This file exists in the cache, so let's get the modificaiton date we stored for it. */
					NSDate *cachedFileModDate = [cachedFiles objectForKey:basicFilePath];
					
					if (cloudFileExists) {
						/* If for some reason we do not have either modificaiton date, then
						 we do not try to change the cached version. */
						
						if (PointerIsEmpty(lastChangeDate) || PointerIsEmpty(cachedFileModDate)) {
							removeFromCacheArray = YES;
						} else {
							NSTimeInterval timeDiff = [lastChangeDate timeIntervalSinceDate:cachedFileModDate];
							
							/* If we have a negative, then that means the change date for the file
							 on the cloud is older than the one in the cache. What? Anyways, we
							 only update the file if the date is in the future. */
							
							if (timeDiff > 0) {
								updateOrAddFile = YES;
							}
						}
					} else {
						removeFromCacheArray = YES; // Do not delete cached file.
					}
				}
			}
			
			/* ========================================================== */
			
			/* Begin actual update process for this file. */
			if (updateOrAddFile || removeFromCacheArray) {
				/* If a file is marked for update or it was marked to be
				 removed from the cache array, then we remove it from that
				 so that when the array is processed later on, the only
				 files we want in it, are those that will be erased from
				 the cache folder. */
				/* Removing it from array reduces calls to fileExistsAtPath
				 down the line. */
				
				/* Remove any known cache entries. */
				[cachedFiles removeObjectForKey:basicFilePath]; // File cache.
				[cachedFiles removeObjectForKey:basicFolderPath]; // Folder cache.
				
				/* Now we can copy the file if needed. */
				NSError *updateError;
				
				if (updateOrAddFile) {
					/* Delete old file if we have to. */
					if (cachedFileExists) {
						[RZFileManager() removeItemAtURL:cachedFileLocation error:&updateError];
						
						if (updateError) {
							LogToConsole(@"Error Deleting Cached File: %@", [updateError localizedDescription]);
						}
					}
					
					/* Create the destination. */
					if ([RZFileManager() fileExistsAtPath:cachedFolderLocation.path] == NO) {
						[RZFileManager() createDirectoryAtURL:cachedFolderLocation withIntermediateDirectories:YES attributes:nil error:&updateError];
						
						if (updateError) {
							LogToConsole(@"Error Creating Destination Folder: %@", [updateError localizedDescription]);
						}
					}
					
					/* Copy new item into place. */
					[RZFileManager() copyItemAtURL:fileURL toURL:cachedFileLocation error:&updateError];
					
					if (updateError) {
						LogToConsole(@"Error Copying Cached File: %@", [updateError localizedDescription]);
					}
					
					/* Debugging data. */
					DebugLogToConsole(@"Cached file \"%@\" updated with the file \"%@\" (%@)", cachedFileLocation, fileURL, lastChangeDate);
				}
			}
			
			/* We are done with this file. Do it all again for the next… */
		}
		
		/* ========================================================== */
		
		/* Time to destroy old caches. */
		[cachedFiles enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
			/* Check the folder to see if anything left in the cache does exist in cloud. */
			NSURL *ubiqdFolderLocation = [ubiqdPathURL URLByAppendingPathComponent:key];
			NSURL *cacheFolderLocation = [cachePahtURL URLByAppendingPathComponent:key];
			
			/* Destroy cached location. */
			if ([RZFileManager() fileExistsAtPath:ubiqdFolderLocation.path] == NO) {
				[RZFileManager() removeItemAtURL:cacheFolderLocation error:NULL];
				
				DebugLogToConsole(@"Destroying cached item \"%@\" which no longer exists in the cloud.", cacheFolderLocation);
			}
		}];
		
		/* After everything is updated, run a validation on the 
		 theme to make sure the active still exists. */
		if (self.initialMetadataQueryCompleted) {
			if ([TPCPreferences performValidationForKeyValues]) {
				[TPCPreferences performReloadActionForActionType:TPCPreferencesKeyReloadStyleAction];
				[TPCPreferences performReloadActionForActionType:TPCPreferencesKeyReloadMemberListAction];
				[TPCPreferences performReloadActionForActionType:TPCPreferencesKeyReloadServerListAction];
			}
		}
		
		/* ========================================================== */
		
		if (self.initialMetadataQueryCompleted == NO) {
			self.initialMetadataQueryCompleted = YES;
		}
		
		/* Accept updates again. */
		[self.cloudContainerNotificationQuery enableUpdates];
		
		/* Post notification. */
		[RZNotificationCenter() postNotificationName:TPCPreferencesCloudSyncUbiquitousContainerCacheWasRebuiltNotification object:nil];
	});
}

#pragma mark -
#pragma mark Session Management

- (void)iCloudAccountAvailabilityChanged:(NSNotification *)aNote
{
	/* Get new token first. */
	id newToken = [RZFileManager() ubiquityIdentityToken];
	
	if (PointerIsNotEmpty(newToken)) {
		if (NSDissimilarObjects(newToken, self.ubiquityIdentityToken)) {
			/* If the new token is logged in and is different from the old,
			 then mark local keys as changed to force an upstream sync. */
			
			self.localKeysWereUpdated = YES;
		}
	}
	
	self.ubiquityIdentityToken = newToken;
	
	[self setupUbiquitousContainerURLPath];
}

- (void)initializeCloudSyncSession
{
	/* Debug data. */
	DebugLogToConsole(@"iCloud: Beginning session.");

	/* Begin actual session. */
	if (RZUbiquitousKeyValueStore()) {
		/* Create worker queue. */
		self.workerQueue = dispatch_queue_create("iCloudSyncWorkerQueue", NULL);
		
		self.ubiquityIdentityToken = [RZFileManager() ubiquityIdentityToken];
		
		[self setupUbiquitousContainerURLPath];
		
		/* Notification for when a local value through NSUserDefaults is changed. */
		[RZNotificationCenter() addObserver:self
								   selector:@selector(localKeysDidChangeNotification:)
									   name:NSUserDefaultsDidChangeNotification
									 object:nil];
		
		[RZNotificationCenter() addObserver:self
								   selector:@selector(iCloudAccountAvailabilityChanged:)
									   name:NSUbiquityIdentityDidChangeNotification
									 object:nil];
		
		NSTimer *syncTimer1 = [NSTimer scheduledTimerWithTimeInterval:_localKeysUpstreamSyncTimerInterval_1
															  target:self
															selector:@selector(performOneMinuteTimeBasedMaintenance)
															userInfo:nil
															  repeats:YES];
		
		NSTimer *syncTimer2 = [NSTimer scheduledTimerWithTimeInterval:_localKeysUpstreamSyncTimerInterval_2
															   target:self
															 selector:@selector(performTenMinuteTimeBasedMaintenance)
															 userInfo:nil
															  repeats:YES];
		
		self.cloudOneMinuteSyncTimer = syncTimer1;
		self.cloudTenMinuteSyncTimer = syncTimer2;
		
		/* Setup query for container changes. */
		self.cloudContainerNotificationQuery = [NSMetadataQuery new];
		
		[self.cloudContainerNotificationQuery setSearchScopes:@[NSMetadataQueryUbiquitousDataScope]];
		[self.cloudContainerNotificationQuery setPredicate:[NSPredicate predicateWithFormat:@"%K LIKE %@", NSMetadataItemFSNameKey, @"*"]];
		
        [RZNotificationCenter() addObserver:self
								   selector:@selector(cloudMetadataQueryDidUpdate:)
									   name:NSMetadataQueryDidFinishGatheringNotification
									 object:nil];
		
        [RZNotificationCenter() addObserver:self
								   selector:@selector(cloudMetadataQueryDidUpdate:)
									   name:NSMetadataQueryDidUpdateNotification
									 object:nil];
		
        [self.cloudContainerNotificationQuery startQuery];

		/* Notification for when a remote value through the key-value store is changed. */
		[RZNotificationCenter() addObserver:self
								   selector:@selector(syncPreferenceFromCloudNotification:)
									   name:NSUbiquitousKeyValueStoreDidChangeExternallyNotification
									 object:nil];
		
		/* Sync latest changes from disc for the dictionary. */
		[RZUbiquitousKeyValueStore() synchronize];
		
		/* Prepare the container… even if we don't use it. */
		(void)[self ubiquitousContainerURLPath];
	} else {
		/* The key value store is not available. */

		LogToConsole(@"Key-value store for iCloud syncing not available.");
	}
}

- (void)purgeDataStoredWithCloud
{
	dispatch_async(self.workerQueue, ^{
		/* Sync latest changes from disc for the dictionary. */
		[RZUbiquitousKeyValueStore() synchronize];

		/* Get the remote. */
		NSDictionary *remotedict = [RZUbiquitousKeyValueStore() dictionaryRepresentation];

		/* Start destroying. */
		[remotedict enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
			[RZUbiquitousKeyValueStore() removeObjectForKey:key];
		}];
		
		/* Destroy local keys not stored on cloud. */
		[RZUserDefaults() removeObjectForKey:TPCPreferencesThemeNameMissingLocallyDefaultsKey];
		[RZUserDefaults() removeObjectForKey:TPCPreferencesThemeFontNameMissingLocallyDefaultsKey];
	});
	
	self.localKeysWereUpdated = YES;
}

- (void)closeCloudSyncSession
{
	/* Debug data. */
	DebugLogToConsole(@"iCloud: Closing session.");

	/* Stop listening for notification related to local changes. */
	if (self.cloudOneMinuteSyncTimer) {
		[self.cloudOneMinuteSyncTimer invalidate];
	}
	
	if (self.cloudTenMinuteSyncTimer) {
		[self.cloudTenMinuteSyncTimer invalidate];
	}
	
	if (self.cloudContainerNotificationQuery) {
		[self.cloudContainerNotificationQuery stopQuery];
	}
	
    [RZNotificationCenter() removeObserver:self name:NSMetadataQueryDidUpdateNotification object:nil];
    [RZNotificationCenter() removeObserver:self name:NSMetadataQueryDidFinishGatheringNotification object:nil];
    [RZNotificationCenter() removeObserver:self name:NSUserDefaultsDidChangeNotification object:nil];
	[RZNotificationCenter() removeObserver:self name:NSUbiquityIdentityDidChangeNotification object:nil];
    [RZNotificationCenter() removeObserver:self name:NSUbiquitousKeyValueStoreDidChangeExternallyNotification object:nil];
	
	/* Dispatch clean-up. */
	if (self.workerQueue) {
		dispatch_release(self.workerQueue);
		
		self.workerQueue = NULL;
	}
	
	self.localKeysWereUpdated = NO;
	self.isSyncingLocalKeysDownstream = NO;
	self.isSyncingLocalKeysUpstream = NO;
	
	self.ubiquityIdentityToken = nil;
	self.ubiquitousContainerURL = nil;
	self.cloudOneMinuteSyncTimer = nil;
	self.cloudTenMinuteSyncTimer = nil;
	self.cloudContainerNotificationQuery = nil;
}

@end

#endif
