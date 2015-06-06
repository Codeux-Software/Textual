/* ********************************************************************* 
                  _____         _               _
                 |_   _|____  _| |_ _   _  __ _| |
                   | |/ _ \ \/ / __| | | |/ _` | |
                   | |  __/>  <| |_| |_| | (_| | |
                   |_|\___/_/\_\\__|\__,_|\__,_|_|

 Copyright (c) 2010 - 2015 Codeux Software, LLC & respective contributors.
        Please see Acknowledgements.pdf for additional information.

 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions
 are met:

    * Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the
      documentation and/or other materials provided with the distribution.
    * Neither the name of Textual and/or "Codeux Software, LLC", nor the 
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

#warning TPCPreferencesCloudSync FIXME: This file requires a significant overhaul.

#if TEXTUAL_BUILT_WITH_ICLOUD_SUPPORT == 1
NSString * const TPCPreferencesCloudSyncUbiquitousContainerCacheWasRebuiltNotification	= @"TPCPreferencesCloudSyncUbiquitousContainerCacheWasRebuiltNotification";

NSString * const TPCPreferencesCloudSyncDidChangeGlobalThemeNamePreferenceNotification	= @"TPCPreferencesCloudSyncDidChangeGlobalThemeNamePreferenceNotification";
NSString * const TPCPreferencesCloudSyncDidChangeGlobalThemeFontPreferenceNotification	= @"TPCPreferencesCloudSyncDidChangeGlobalThemeFontPreferenceNotification";

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
@property (nonatomic, assign) BOOL pushAllLocalKeysNextSync;
@property (nonatomic, strong) dispatch_queue_t workerQueue;
@property (nonatomic, strong) NSTimer *cloudOneMinuteSyncTimer;
@property (nonatomic, strong) NSTimer *cloudTenMinuteSyncTimer;
@property (nonatomic, copy) NSURL *ubiquitousContainerURL;
@property (nonatomic, strong) NSMetadataQuery *cloudContainerNotificationQuery;
@property (nonatomic, strong) NSMutableArray *unsavedLocalKeys;
@property (nonatomic, strong) NSMutableArray *keysToRemoveNextSync;
@property (nonatomic, copy) NSArray *remoteKeysBeingSynced;
@end

@implementation TPCPreferencesCloudSync

#pragma mark -
#pragma mark Public API

- (void)setValue:(id)value forKey:(NSString *)key
{
	NSObjectIsEmptyAssert(key); // Yeah, we need a key...
	
	/* Set it and forget it. */
	NSString *hashedKey = [key md5];
	
	if (value == nil) {
		value = [NSNull null];
	}
	
	[RZUbiquitousKeyValueStore() setObject:@{@"key" : key, @"value" : value} forKey:hashedKey];
}

- (id)valueForKey:(NSString *)key
{
	NSObjectIsEmptyAssertReturn(key, nil); // Yeah, we need a key...
	
	/* Insert pointless comment here. */
	NSString *hashedKey = [key md5];
	
	/* Another pointless comment here. */
	return [self valueForHashedKey:hashedKey actualKey:NULL];
}

- (id)valueForHashedKey:(NSString *)key actualKey:(NSString * __autoreleasing *)realKeyValue /* @private */
{
	/* Get initial value. */
	id dictObject = [RZUbiquitousKeyValueStore() objectForKey:key];
	
	/* We are only looking for dictionary entries... */
	NSObjectIsKindOfClassAssertReturn(dictObject, NSDictionary, nil);
	
	/* Gather entry info. */
	id keyname = [dictObject objectForKey:@"key"];
	id objectValue = [dictObject objectForKey:@"value"];
	
	/* Some validation. Not strict, but meh... */
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
	NSObjectIsEmptyAssert(key); // Yeah, we need a key...
	
	/* Set it and forget it. */
	NSString *hashedKey = [key md5];
	
	/* Umm, I just copy and paste these things. */
	[RZUbiquitousKeyValueStore() removeObjectForKey:hashedKey];
}

- (void)removeObjectForKeyNextUpstreamSync:(NSString *)key
{
	/* Do not perform any actions during termination. */
	if ([self applicationIsTerminating]) {
		return; // Do not continue operation...
	}

	/* We don't even want to sync if user doesn't want to. */
	if ([TPCPreferences syncPreferencesToTheCloud] == NO) {
		return; // Do not continue operation...
	}

	/* Add key to removal array. */
	XRPerformBlockAsynchronouslyOnQueue([self workerQueue], ^{
		@synchronized([self keysToRemoveNextSync]) {
			[[self keysToRemoveNextSync] addObject:key];
		}
	});
}


#pragma mark -
#pragma mark URL Management

- (void)setupUbiquitousContainerURLPath:(BOOL)isCalledFromInit
{
	XRPerformBlockAsynchronouslyOnQueue([self workerQueue], ^{
		/* Apple very clearly states not to do call this on the main thread
		 since it does a lot of work, so we wont... */
		NSURL *ucurl = [RZFileManager() URLForUbiquityContainerIdentifier:nil];
		
		if (ucurl) {
			[self setUbiquitousContainerURL:ucurl];
		} else {
			[self setUbiquitousContainerURL:nil];
			
			LogToConsole(@"iCloud access is not available.");
		}
		
		/* Update monitor based on state of container path. */
		[self performBlockOnMainThread:^{
			if ([self cloudContainerNotificationQuery] == nil) {
				if ([self ubiquitousContainerURL]) {
					[self startMonitoringUbiquitousContainer];
				}
			} else {
				if ([self ubiquitousContainerURL] == nil) {
					[self stopMonitoringUbiquitousContainer];
				}
			}
		}];
	});
}

- (NSString *)ubiquitousContainerURLPath
{
	return [[self ubiquitousContainerURL] path];
}

- (BOOL)ubiquitousContainerIsAvailable
{
	return NSObjectIsNotEmpty([self ubiquitousContainerURLPath]);
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
	/* Do not perform any actions during termination. */
	if ([self applicationIsTerminating]) {
		return; // Do not continue operation...
	}
	
	/* We don't even want to sync if user doesn't want to. */
	if ([TPCPreferences syncPreferencesToTheCloud] == NO) {
		return; // Do not continue operation...
	}
	
	/* Debug information. */
	DebugLogToConsole(@"iCloud: Performing ten-minute based maintenance.");
	
	/* Perform actual maintenance tasks. */
	XRPerformBlockAsynchronouslyOnQueue([self workerQueue], ^{
		/* Compare fonts. */
		BOOL fontMissing = [RZUserDefaults() boolForKey:TPCPreferencesThemeFontNameMissingLocallyDefaultsKey];
		
		if (fontMissing) {
			NSString *remoteValue = [self valueForKey:TPCPreferencesThemeFontNameDefaultsKey];
			
			NSString *localFontVa = [TPCPreferences themeChannelViewFontName];
			
			/* Do the actual compare... */
			if ([localFontVa isEqual:remoteValue] == NO) {
				if ([NSFont fontIsAvailable:remoteValue]) {
					DebugLogToConsole(@"iCloud: Remote font does not match local font. Setting font and reloading theme.");
					
					[TPCPreferences setThemeChannelViewFontName:remoteValue]; // Will remove the BOOL
					
					/* Font only applies to actual theme so we don't have to reload sidebars too... */
					[TPCPreferences performReloadActionForActionType:TPCPreferencesKeyReloadStyleAction];
					
					[RZNotificationCenter() postNotificationName:TPCPreferencesCloudSyncDidChangeGlobalThemeFontPreferenceNotification object:nil];
				}
			}
		}
	});
}

- (void)performOneMinuteTimeBasedMaintenance
{
	/* Do not perform any actions during termination. */
	if ([self applicationIsTerminating]) {
		return; // Do not continue operation...
	}
	
	/* We don't even want to sync if user doesn't want to. */
	if ([TPCPreferences syncPreferencesToTheCloud] == NO) {
		return; // Do not continue operation...
	}

	/* Perform a sync. */
	[self synchronizeToCloud];
	
	/* Perform actual maintenance tasks. */
	XRPerformBlockAsynchronouslyOnQueue([self workerQueue], ^{
		/* Have a theme in the temporary store? */
		BOOL missingTheme = [RZUserDefaults() boolForKey:TPCPreferencesThemeNameMissingLocallyDefaultsKey];
		
		/* If we do, pass it through the set property to set it or continue to keep in store. */
		if (missingTheme) {
			NSString *temporaryTheme = [self valueForKey:TPCPreferencesThemeNameDefaultsKey];
			
			if ([TPCThemeController themeExists:temporaryTheme]) {
				DebugLogToConsole(@"iCloud: Theme name \"%@\" is stored in the temporary store and will now be applied.", temporaryTheme);
				
				[TPCPreferences setThemeName:temporaryTheme]; // Will reset the BOOL
				
				[TPCPreferences performReloadActionForActionType:TPCPreferencesKeyReloadStyleWithTableViewsAction];
			
				[RZNotificationCenter() postNotificationName:TPCPreferencesCloudSyncDidChangeGlobalThemeNamePreferenceNotification object:nil];
			} else {
				DebugLogToConsole(@"iCloud: Theme name \"%@\" is stored in the temporary store.", temporaryTheme);
			}
		}
	});
}

- (BOOL)keyIsNotPermittedInCloud:(NSString *)key
{
	if ([TPCPreferences syncPreferencesToTheCloudLimitedToServers]) {
		return ([key hasPrefix:IRCWorldControllerCloudClientEntryKeyPrefix] == NO);
	} else {
		return ([key isEqualToString:IRCWorldControllerDefaultsStorageKey] ||
				[key isEqualToString:IRCWorldControllerCloudDeletedClientsStorageKey] ||
				[key isEqualToString:TPCPreferencesCloudSyncKeyValueStoreServicesDefaultsKey] ||
				[key isEqualToString:TPCPreferencesCloudSyncKeyValueStoreServicesLimitedToServersDefaultsKey] ||
				[key isEqualToString:TPCPreferencesThemeNameMissingLocallyDefaultsKey] ||
				[key isEqualToString:TPCPreferencesThemeFontNameMissingLocallyDefaultsKey]);
	}
}

- (BOOL)keyIsNotPermittedFromCloud:(NSString *)key
{
	if ([TPCPreferences syncPreferencesToTheCloudLimitedToServers]) {
		return ([self keyIsRelatedToSavedServerState:key] == NO);
	} else {
		return ([key isEqualToString:IRCWorldControllerDefaultsStorageKey] ||
				[key isEqualToString:TPCPreferencesCloudSyncKeyValueStoreServicesDefaultsKey] ||
				[key isEqualToString:TPCPreferencesCloudSyncKeyValueStoreServicesLimitedToServersDefaultsKey] ||
				[key isEqualToString:TPCPreferencesThemeNameMissingLocallyDefaultsKey] ||
				[key isEqualToString:TPCPreferencesThemeFontNameMissingLocallyDefaultsKey]);
	}
}

- (BOOL)keyIsRelatedToSavedServerState:(NSString *)key
{
	return ([key isEqualToString:IRCWorldControllerCloudDeletedClientsStorageKey] ||
				  [key hasPrefix:IRCWorldControllerCloudClientEntryKeyPrefix]);
}

- (NSString *)unhashedKeyFromHashedKey:(NSString *)key
{
	/* This method only lists specific keys that we need to know which cannot
	 be viewed directly by asking for the key-value entry in iCloud. */
	/* It was at the point that I wrote this method that I realized how
	 fucking stupid Textual's implementation of iCloud is. */

	NSDictionary *cachedValues = [[masterController() sharedApplicationCacheObject] objectForKey:
								  @"TPCPreferencesCloudSync -> Apple iCloud List of Mapped Hashed Keys"];

	if (cachedValues == nil) {
		NSDictionary *staticValues = [TPCResourceManager loadContentsOfPropertyListInResourcesFolderNamed:@"AppleCloudMappedKeys"];

		[[masterController() sharedApplicationCacheObject] setObject:staticValues forKey:
		 @"TPCPreferencesCloudSync -> Apple iCloud List of Mapped Hashed Keys"];

		cachedValues = staticValues;
	}

	return [cachedValues objectForKey:key];
}

- (BOOL)keyIsPermittedToBeRemovedThroughCloud:(NSString *)key
{
	/* List of keys that when synced downstream are allowed to be removed
	 from NSUserDefaults if they no longer exist in the cloud. */

	return ([key isEqualToString:@"User List Mode Badge Colors -> +y"] ||
			[key isEqualToString:@"User List Mode Badge Colors -> +q"] ||
			[key isEqualToString:@"User List Mode Badge Colors -> +a"] ||
			[key isEqualToString:@"User List Mode Badge Colors -> +o"] ||
			[key isEqualToString:@"User List Mode Badge Colors -> +h"] ||
			[key isEqualToString:@"User List Mode Badge Colors -> +v"] ||
			[key isEqualToString:@"Server List Unread Message Count Badge Colors -> Highlight"]);
}

- (void)syncPreferencesToCloud
{
	/* Do not perform any actions during termination. */
	if ([self applicationIsTerminating]) {
		return; // Do not continue operation...
	}
	
	/* We don't even want to sync if user doesn't want to. */
	if ([TPCPreferences syncPreferencesToTheCloud] == NO) {
		return; // Do not continue operation...
	}
	
	/* Begin work. */
	XRPerformBlockAsynchronouslyOnQueue([self workerQueue], ^{
		/* Only perform sync under strict conditions. */
		if ([[self unsavedLocalKeys] count] == 0 &&
			[[self keysToRemoveNextSync] count] == 0 &&
			[self pushAllLocalKeysNextSync] == NO)
		{
			DebugLogToConsole(@"iCloud: Upstream sync cancelled because nothing has changed.");
			
			return; // Cancel this operation;
		}
		
		if ([self isSyncingLocalKeysDownstream]) {
			DebugLogToConsole(@"iCloud: Upstream sync cancelled because a downstream sync was already running.");
			
			return; // Cancel this operation;
		}
		
		if ([self isSyncingLocalKeysUpstream]) {
			DebugLogToConsole(@"iCloud: Upstream sync cancelled because an upstream sync was already running.");
			
			return; // Cancel this operation;
		}
		
		if ([self hasUncommittedDataStoredInCloud]) {
			DebugLogToConsole(@"iCloud: Upstream sync cancelled because there is uncommitted data remaining in the cloud.");
			
			return; // Cancel this operation;
		}
		
		/* Debug data. */
		DebugLogToConsole(@"iCloud: Beginning sync upstream.");
		
		/* Continue normal work. */
		[self setIsSyncingLocalKeysUpstream:YES];
		
		/* Compare to the remote. */
		NSDictionary *remotedict = [RZUbiquitousKeyValueStore() dictionaryRepresentation];
		
		NSArray *remotedictkeys = [remotedict allKeys];
		
		/* Gather dictionary representation of all local preferences. */
		NSMutableDictionary *changedValues = nil;
		
		if ([self pushAllLocalKeysNextSync]) {
			changedValues = (id)[TPCPreferencesImportExport exportedPreferencesDictionaryRepresentation];
			
			[self setPushAllLocalKeysNextSync:NO];
		} else {
			changedValues = [NSMutableDictionary dictionary];

			@synchronized([self unsavedLocalKeys]) {
				for (id objectKey in [self unsavedLocalKeys]) {
					id objectValue = [RZUserDefaults() objectForKey:objectKey];
					
					if (objectValue) {
						changedValues[objectKey] = objectValue;
					}
				}
			}
		}

		/* If one of the values changed is our world controller, then we intercept
		 that key and replace it with a few special values. */
		if (NSDissimilarObjects(changedValues[IRCWorldControllerDefaultsStorageKey], nil)) {
			[changedValues removeObjectForKey:IRCWorldControllerDefaultsStorageKey];

			NSMutableDictionary *clientDict = [worldController() cloudDictionaryValue];

			[changedValues addEntriesFromDictionary:clientDict];
		}

		/* Remove keys to sync even if we are syncing all. */
		[[self unsavedLocalKeys] removeAllObjects];

		/* Remove any keys that were marked for removal */
		@synchronized([self keysToRemoveNextSync]) {
			if ([[self keysToRemoveNextSync] count] > 0) {
				[[self keysToRemoveNextSync] enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
					DebugLogToConsole(@"Key (%@) is being removed from iCloud as it was marked to be.", obj);

					[self removeObjectForKey:obj];

					if ( changedValues[obj]) {
						[changedValues removeObjectForKey:obj];
					}
				}];

				[[self keysToRemoveNextSync] removeAllObjects];
			}
		}

		/* Get a copy of our defaults. */
		static NSDictionary *defaults = nil;

		if (defaults == nil) {
			defaults = [TPCPreferences defaultPreferences];
		}
		
		NSArray *defaultskeys = [defaults allKeys];
		
		/* Set the remote dictionary. */
		/* Some people may look at this code and wonder what the fuck was this
		 developer thinking? Well, since I know I will be asking myself that in
		 probably a few months when I need to maintain this code; I will explain.

		 You cannot have a key longer than 64 bytes in iCloud so what am I going
		 to do when there are keys stored by Textual longer than that? Rewrite
		 the entire internals of Textual to use shorter keys? Ha, as-if... Instead
		 just use a static hash of the key name as the actual key, then have the
		 value of the key a dictionary with the real key name in it and the value. */
		[changedValues enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
			if ([self keyIsNotPermittedInCloud:key]) {
				// Nobody cares about this...
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
						return; // Skip this entry. This only returns the block.
					}
				} else if ([key isEqualToString:TPCPreferencesThemeFontNameDefaultsKey]) {
					BOOL fontMissing = [RZUserDefaults() boolForKey:TPCPreferencesThemeFontNameMissingLocallyDefaultsKey];
	
					if (fontMissing) {
						return; // Skip this entry. This only returns the block.
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
						return; // Nothing has changed...
					}
				}
				
				[self setValue:obj forKey:key];
			}
		}];

		/* Sync changes. */
		[RZUbiquitousKeyValueStore() synchronize];

		/* Allow us to continue work. */
		[self setIsSyncingLocalKeysUpstream:NO];

		/* Debug information. */
		DebugLogToConsole(@"iCloud: Completeing sync upstream.");
	});
}

- (void)syncPreferencesFromCloud:(NSArray *)changedKeys
{
	/* Do not perform any actions during termination. */
	if ([self applicationIsTerminating]) {
		return; // Do not continue operation...
	}

	/* We don't even want to sync if user doesn't want to. */
	if ([TPCPreferences syncPreferencesToTheCloud] == NO) {
		return; // Do not continue operation...
	}
	
	/* Perform operation. */
	XRPerformBlockAsynchronouslyOnQueue([self workerQueue], ^{
		/* Debug data. */
		DebugLogToConsole(@"iCloud: Beginning sync downstream.");

		/* Announce our intents... */
		[self setIsSyncingLocalKeysDownstream:YES];

		/* Get the list of changed keys. */
		if (PointerIsEmpty(changedKeys) || [changedKeys count] <= 0) {
			/* If the list is empty, then we populate every single key. */
			NSDictionary *upstreamRep = [RZUbiquitousKeyValueStore() dictionaryRepresentation];
			
			[self setRemoteKeysBeingSynced:[upstreamRep allKeys]];
		} else {
			[self setRemoteKeysBeingSynced:changedKeys];
		}
		
		/* See the code of syncPreferencesToCloud: for an expalantion of how these keys are hashed. */
		NSMutableArray *actualChangedKeys = [NSMutableArray array];
		NSMutableArray *importedClients = [NSMutableArray array];
		NSMutableArray *valuesToRemove = [NSMutableArray array];
		
		for (id hashedKey in [self remoteKeysBeingSynced]) {
			id keyname = nil;
			
			id  objectValue = [self valueForHashedKey:hashedKey actualKey:&keyname];

			if (objectValue == nil || keyname == nil) {
				/* Maybe remove certain keys from the local defaults store depending
				 on whether we are able to determine its actual name and whether it
				 is allowed to be removed at all. */
				NSString *unhashedKey = [self unhashedKeyFromHashedKey:hashedKey];

				DebugLogToConsole(@"Hashed key (%@) is missing a value or key name. Possible key name: %@", hashedKey, unhashedKey);

				if (unhashedKey) {
					DebugLogToConsole(@"Asking for permission to remove key (%@) from local defaults store.", unhashedKey);

					if ([self keyIsNotPermittedFromCloud:unhashedKey] == NO) {
						if ([self keyIsPermittedToBeRemovedThroughCloud:unhashedKey]) {
							[valuesToRemove addObject:unhashedKey];

							[actualChangedKeys addObject:unhashedKey];
						}
					}
				}
			} else {
				/* Block stuff from syncing that we did not want. */
				if ([self keyIsNotPermittedFromCloud:keyname]) {
					continue; // Do not continue operation...
				}
				
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
					
					[self performBlockOnMainThread:^{
						[worldController() processCloudCientDeletionList:objectValue];
					}];
				}
				else if ([keyname hasPrefix:IRCWorldControllerCloudClientEntryKeyPrefix])
				{
					NSObjectIsKindOfClassAssert(objectValue, NSDictionary);
					
					/* Bet you're wondering why this is added to an array instead of
					 just calling the importWorld... method. Well, it took me a long time
					 to figure this out too. It used to just call the method directly,
					 then I realized, doing that creates a new instance of TVCLogController
					 for each client/channel added. That's all fine, but if the theme
					 ends up changing when calling the TPCPreferences reload... method 
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
		[self performBlockOnMainThread:^{
			if ([valuesToRemove count] > 0) {
				for (NSString *key in valuesToRemove) {
					[RZUserDefaults() removeObjectForKey:key];
				}
			}

			if ([actualChangedKeys count] > 0) {
				[TPCPreferences performReloadActionForKeyValues:actualChangedKeys];
			}
			
			if ([importedClients count] > 0) {
				for (NSDictionary *seed in importedClients) {
					[TPCPreferencesImportExport importWorldControllerClientConfiguration:seed isCloudBasedImport:YES];
				}
			}
			
			[self setRemoteKeysBeingSynced:nil];
		}];

		/* Allow us to continue work. */
		[self setIsSyncingLocalKeysDownstream:NO];
		
		/* If we made it this far, reset this notificaiton. */
		[self setHasUncommittedDataStoredInCloud:NO];
		
		/* Debug data. */
		DebugLogToConsole(@"iCloud: Completeing sync downstream.");
	});
}

- (void)syncPreferenceFromCloudNotification:(NSNotification *)aNote
{
	/* Do not perform any actions during termination. */
	if ([self applicationIsTerminating]) {
		return; // Do not continue operation...
	}

	/* Gather information about the sync request. */
	NSInteger syncReason = [[aNote userInfo] integerForKey:NSUbiquitousKeyValueStoreChangeReasonKey];
	
	/* Are we out of memory? */
	if (syncReason == NSUbiquitousKeyValueStoreQuotaViolationChange) {
		[self cloudStorageLimitExceeded]; // We will not be syncing for this error.
	} else {
		/* It is kind of important to know this. */
		/* Even if we do not handle it, we still want to know
		 if iCloud tried to sync something to this client. */
		[self setHasUncommittedDataStoredInCloud:YES];
		
		/* Get the list of changed keys. */
		NSArray *changedKeys = [[aNote userInfo] arrayForKey:NSUbiquitousKeyValueStoreChangedKeysKey];

		/* Do the work. */
		[self syncPreferencesFromCloud:changedKeys];
	}
}

- (void)resetDataToSync
{
	XRPerformBlockAsynchronouslyOnQueue([self workerQueue], ^{
		[self setPushAllLocalKeysNextSync:NO];
		
		@synchronized([self unsavedLocalKeys]) {
			[[self unsavedLocalKeys] removeAllObjects];
		}
	});
}

- (void)syncEverythingNextSync
{
	[self setPushAllLocalKeysNextSync:YES];
}

- (void)localKeysDidChangeNotification:(NSNotification *)aNote
{
	/* Do not perform any actions during termination. */
	if ([self applicationIsTerminating]) {
		return; // Do not continue operation...
	}
	
	/* We don't even want to sync if user doesn't want to. */
	if ([TPCPreferences syncPreferencesToTheCloud] == NO) {
		return; // Do not continue operation...
	}

	/* Downstream syncing will fire this notification so we
	 check whether the key exists before adding it to our list. */
	XRPerformBlockAsynchronouslyOnQueue([self workerQueue], ^{
		NSString *changedKey = [[aNote userInfo] objectForKey:@"changedKey"];
		
		if (changedKey) {
			NSArray *pendingWrites = [self remoteKeysBeingSynced];
			
			if (pendingWrites) {
				if ([pendingWrites containsObject:changedKey]) {
					return; // Do not add this key...
				}
			}

			@synchronized([self unsavedLocalKeys]) {
				[[self unsavedLocalKeys] addObject:changedKey];
			}

			@synchronized([self keysToRemoveNextSync]) {
				if ([[self keysToRemoveNextSync] containsObject:changedKey]) {
					[[self keysToRemoveNextSync] removeObject:changedKey];
				}
			}
		}
	});
}

#pragma mark -
#pragma mark Misc. Notifications

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
	LogToConsole(@"The cloud storage limit was exceeded.");
}

#pragma mark -
#pragma mark Container Updates

- (void)pauseCloudContainerMetadataUpdates
{
	[[self cloudContainerNotificationQuery] disableUpdates];
}

- (void)resumeCloudContainerMetadataUpdates
{
	[[self cloudContainerNotificationQuery] enableUpdates];
}

- (void)cloudMetadataQueryDidUpdate:(NSNotification *)notification
{
	/* Do not perform any actions during termination. */
	if ([self applicationIsTerminating]) {
		return; // Do not continue operation...
	}

	/* Begin work. */
	BOOL isGatheringNotification = [NSMetadataQueryDidFinishGatheringNotification isEqualToString:[notification name]];
	
	DebugLogToConsole(@"iCloud: Metadata Query Update: isGathering = %i", isGatheringNotification);
	
	XRPerformBlockAsynchronouslyOnQueue([self workerQueue], ^{
		/* Do not accept updates during work. */
		[[self cloudContainerNotificationQuery] disableUpdates];
		
		/* Get the existing cache path. */
		NSString *cachePath = [TPCPathInfo cloudCustomThemeCachedFolderPath];
		NSString *ubiqdPath = [TPCPathInfo cloudCustomThemeFolderPath];
		
		if (NSObjectIsNotEmpty(ubiqdPath)) {
			NSURL *cachePahtURL = [NSURL fileURLWithPath:cachePath];
			NSURL *ubiqdPathURL = [NSURL fileURLWithPath:ubiqdPath];
			
			DebugLogToConsole(@"iCloud: Updating cache for container at path: \"%@\"", [ubiqdPathURL path]);

			/* ========================================================== */
		
			/* We will now enumrate through all existing cache files gathering a list of those that
			 exist and their modification dates. This information is stored in a dictionary with the
			 file URL being the dictionary key and the value being its modification date. */
			NSDirectoryEnumerator *enumerator = [RZFileManager() enumeratorAtURL:cachePahtURL
													  includingPropertiesForKeys:@[NSURLIsDirectoryKey, NSURLContentModificationDateKey]
																		 options:NSDirectoryEnumerationSkipsHiddenFiles
																	errorHandler:^(NSURL *url, NSError *error)
																	{
																		LogToConsole(@"Enumeration Error: %@", [error localizedDescription]);
																		
																		return YES; // Continue regardless of error.
																	}];
			
			/* Build list of files. */
			NSMutableDictionary *cachedFiles = [NSMutableDictionary dictionary];
			
			/* Enumrate the cache. */
			for (NSURL *itemURL in enumerator) {
				NSError *error = nil;
				
				NSNumber *isDirectory = nil;
				
				/* Directories and files are handled differently. This handles that. */
				if ([itemURL getResourceValue:&isDirectory forKey:NSURLIsDirectoryKey error:&error]) {
					/* Get the path of this item minus the prefix path. */
					NSString *path = [[itemURL path] stringByDeletingPreifx:[cachePahtURL path]];
					
					/* Continus processing... */
					if ([isDirectory boolValue]) {
						/* We do not care about modification dates of directories. */
						[cachedFiles setObject:[NSNull null] forKey:path];
					} else {
						/* Path is a file. We need it's modification date. */
						NSDate *fileDate = nil;
						
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
			NSUInteger resultCount = [[self cloudContainerNotificationQuery] resultCount];
			
			for (NSUInteger i = 0; i < resultCount; i++) {
				NSMetadataItem *item = [[self cloudContainerNotificationQuery] resultAtIndex:i];
				
				/* First thing first is to get the URL. */
				NSURL *fileURL = [item valueForAttribute:NSMetadataItemURLKey];
				
				/* Build some relevant path information. */
				/* First the path to the file minus its path prefix. */
				NSString *basicFilePath = [[fileURL path] stringByDeletingPreifx:[ubiqdPathURL path]];

				if ([basicFilePath length] <= 0) {
					continue;
				}
				
				/* Then the actual folder in which the file is stored. */
				NSString *basicFolderPath = [basicFilePath stringByDeletingLastPathComponent];
				
				/* More paths, lol. */
				NSURL *cachedFolderLocation = [cachePahtURL URLByAppendingPathComponent:basicFolderPath];
				NSURL *cachedFileLocation = [cachePahtURL URLByAppendingPathComponent:basicFilePath];
				
				/* Now, we begin gathering relevant information about the file. */
				BOOL updateOrAddFile = NO; // Used later on...
				BOOL removeFromCacheArray = NO; // Setting to YES will remove the file from deletion pool.
				
				BOOL cloudFileExists = [RZFileManager() fileExistsAtPath:[fileURL path]];
				BOOL cachedFileExists = [RZFileManager() fileExistsAtPath:[cachedFileLocation path]];
				
				BOOL isDownloaded = NO;
				
				if ([XRSystemInformation isUsingOSXMavericksOrLater]) {
					NSString *_isDownloaded = [item valueForAttribute:NSMetadataUbiquitousItemDownloadingStatusKey];
				
					isDownloaded = (NSObjectsAreEqual(_isDownloaded, NSMetadataUbiquitousItemDownloadingStatusCurrent) ||
									NSObjectsAreEqual(_isDownloaded, NSMetadataUbiquitousItemDownloadingStatusDownloaded));
				} else {
					NSNumber *_isDownloaded = [item valueForAttribute:NSMetadataUbiquitousItemIsDownloadedKey];
					
					isDownloaded = [_isDownloaded boolValue];
				}
				
				NSDate *lastChangeDate = [item valueForAttribute:NSMetadataItemFSContentChangeDateKey];
				
				/* ========================================================== */
				
				/* Begin work. */
				if (isDownloaded == NO) {
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
						id cachedFileModDate = [cachedFiles objectForKey:basicFilePath];

						if (cloudFileExists) {
							/* If for some reason we do not have either modificaiton date, then
							 we do not try to change the cached version. */
							
							if (PointerIsEmpty(lastChangeDate) || NSObjectIsEmpty(cachedFileModDate)) {
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
					NSError *updateError = nil;
					
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
						} else {
							DebugLogToConsole(@"Cached file \"%@\" updated with the file \"%@\" (%@)", cachedFileLocation, fileURL, lastChangeDate);
						}
					}
				}
				
				/* We are done with this file. Do it all again for the next... */
			};
			
			/* ========================================================== */
			
			/* Time to destroy old caches. */
			[cachedFiles enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
				/* Check the folder to see if anything left in the cache does exist in cloud. */
				NSURL *ubiqdFolderLocation = [ubiqdPathURL URLByAppendingPathComponent:key];
				NSURL *cacheFolderLocation = [cachePahtURL URLByAppendingPathComponent:key];
				
				/* Destroy cached location. */
				if ([RZFileManager() fileExistsAtPath:[ubiqdFolderLocation path]] == NO) {
					[RZFileManager() removeItemAtURL:cacheFolderLocation error:NULL];
					
					DebugLogToConsole(@"Destroying cached item \"%@\" which no longer exists in the cloud.", cacheFolderLocation);
				}
			}];
			
			/* After everything is updated, run a validation on the
			 theme to make sure the active still exists. */
			[self performBlockOnMainThread:^{
				[RZNotificationCenter() postNotificationName:TPCPreferencesCloudSyncUbiquitousContainerCacheWasRebuiltNotification object:nil];
			}];
		}
		
		/* Accept updates again. */
		[[self cloudContainerNotificationQuery] enableUpdates];
	});
}

- (void)startMonitoringUbiquitousContainer
{
	/* Setup query for container changes. */
	[self setCloudContainerNotificationQuery:[NSMetadataQuery new]];
	
	[[self cloudContainerNotificationQuery] setSearchScopes:@[NSMetadataQueryUbiquitousDocumentsScope]];
	[[self cloudContainerNotificationQuery] setPredicate:[NSPredicate predicateWithFormat:@"%K LIKE %@", NSMetadataItemFSNameKey, @"*"]];
	
	[RZNotificationCenter() addObserver:self
							   selector:@selector(cloudMetadataQueryDidUpdate:)
								   name:NSMetadataQueryDidFinishGatheringNotification
								 object:[self cloudContainerNotificationQuery]];
	
	[RZNotificationCenter() addObserver:self
							   selector:@selector(cloudMetadataQueryDidUpdate:)
								   name:NSMetadataQueryDidUpdateNotification
								 object:[self cloudContainerNotificationQuery]];
	
	[[self cloudContainerNotificationQuery] startQuery];
}

- (void)stopMonitoringUbiquitousContainer
{
	if ( [self cloudContainerNotificationQuery]) {
		[[self cloudContainerNotificationQuery] stopQuery];
	}
	
    [RZNotificationCenter() removeObserver:self name:NSMetadataQueryDidUpdateNotification object:[self cloudContainerNotificationQuery]];
    [RZNotificationCenter() removeObserver:self name:NSMetadataQueryDidFinishGatheringNotification object:[self cloudContainerNotificationQuery]];

	[self setCloudContainerNotificationQuery:nil];
}

#pragma mark -
#pragma mark Session Management

- (void)iCloudAccountAvailabilityChanged:(NSNotification *)aNote
{
	/* Do not perform any actions during termination. */
	if ([self applicationIsTerminating]) {
		return; // Do not continue operation...
	}

	/* Get new token first. */
	id newToken = [RZFileManager() cloudUbiquityIdentityToken];
	
	if (PointerIsNotEmpty(newToken)) {
		if (NSDissimilarObjects(newToken, [self ubiquityIdentityToken])) {
			/* If the new token is logged in and is different from the old,
			 then mark local keys as changed to force an upstream sync. */
			
			[self setPushAllLocalKeysNextSync:YES];
		}
	}
	
	[self setUbiquityIdentityToken:newToken];
	
	[self setupUbiquitousContainerURLPath:NO];
}

- (void)initializeCloudSyncSession
{
	/* Debug data. */
	DebugLogToConsole(@"iCloud: Beginning session.");

	/* Begin actual session. */
	if (RZUbiquitousKeyValueStore()) {
		/* Create worker queue. */
		[self setWorkerQueue:dispatch_queue_create("iCloudSyncWorkerQueue", DISPATCH_QUEUE_SERIAL)];
		
		[self setUbiquityIdentityToken:[RZFileManager() cloudUbiquityIdentityToken]];
		
		[self setupUbiquitousContainerURLPath:YES];
		
		[self setUnsavedLocalKeys:[NSMutableArray new]];
		[self setKeysToRemoveNextSync:[NSMutableArray new]];
		
		/* Notification for when a local value through NSUserDefaults is changed. */
		[RZNotificationCenter() addObserver:self
								   selector:@selector(localKeysDidChangeNotification:)
									   name:TPCPreferencesUserDefaultsDidChangeNotification
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
		
		[self setCloudOneMinuteSyncTimer:syncTimer1];
		[self setCloudTenMinuteSyncTimer:syncTimer2];

		/* Notification for when a remote value through the key-value store is changed. */
		[RZNotificationCenter() addObserver:self
								   selector:@selector(syncPreferenceFromCloudNotification:)
									   name:NSUbiquitousKeyValueStoreDidChangeExternallyNotification
									 object:nil];
		
		/* Sync latest changes from disc for the dictionary. */
		[RZUbiquitousKeyValueStore() synchronize];
	} else {
		/* The key value store is not available. */

		LogToConsole(@"Key-value store for iCloud syncing not available.");
	}
}

- (void)purgeDataStoredWithCloud
{
	/* Do not perform any actions during termination. */
	if ([self applicationIsTerminating]) {
		return; // Do not continue operation...
	}

	/* Perform work. */
	XRPerformBlockAsynchronouslyOnQueue([self workerQueue], ^{
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
	
	[self setPushAllLocalKeysNextSync:YES];
}

- (void)closeCloudSyncSession
{
	/* Debug data. */
	DebugLogToConsole(@"iCloud: Closing session.");

	/* Stop listening for notification related to local changes. */
	if ( [self cloudOneMinuteSyncTimer]) {
		[[self cloudOneMinuteSyncTimer] invalidate];
	}
	
	if ( [self cloudTenMinuteSyncTimer]) {
		[[self cloudTenMinuteSyncTimer] invalidate];
	}
	
    [RZNotificationCenter() removeObserver:self name:TPCPreferencesUserDefaultsDidChangeNotification object:nil];
	
	[RZNotificationCenter() removeObserver:self name:NSUbiquityIdentityDidChangeNotification object:nil];
    [RZNotificationCenter() removeObserver:self name:NSUbiquitousKeyValueStoreDidChangeExternallyNotification object:nil];
	
	[self stopMonitoringUbiquitousContainer];
	
	/* Dispatch clean-up. */
	if ([self workerQueue]) {
		[self setWorkerQueue:NULL];
	}
	
	[self setPushAllLocalKeysNextSync:NO];

	[self setUnsavedLocalKeys:nil];
	[self setRemoteKeysBeingSynced:nil];
	
	[self setIsSyncingLocalKeysDownstream:NO];
	[self setIsSyncingLocalKeysUpstream:NO];
	
	[self setUbiquityIdentityToken:nil];
	[self setUbiquitousContainerURL:nil];
	
	[self setCloudOneMinuteSyncTimer:nil];
	[self setCloudTenMinuteSyncTimer:nil];
}

@end

#endif
