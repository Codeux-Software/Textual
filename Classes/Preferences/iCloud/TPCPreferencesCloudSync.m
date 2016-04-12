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

#import "TPCPreferencesCloudSyncPrivate.h"
#import "TPCPreferencesImportExportPrivate.h"

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

@implementation TPCPreferencesCloudSync

#pragma mark -
#pragma mark Public API

- (void)setValue:(id)value forKey:(NSString *)key
{
	NSObjectIsEmptyAssert(key);

	NSString *hashedKey = [key md5];
	
	if (value == nil) {
		[RZUbiquitousKeyValueStore() removeObjectForKey:hashedKey];
	} else {
		[RZUbiquitousKeyValueStore() setObject:@{@"key" : key, @"value" : value} forKey:hashedKey];
	}
}

- (id)valueForKey:(NSString *)key
{
	NSObjectIsEmptyAssertReturn(key, nil);

	NSString *hashedKey = [key md5];

	return [self valueForHashedKey:hashedKey actualKey:NULL];
}

- (id)valueForHashedKey:(NSString *)key actualKey:(NSString * __autoreleasing *)realKeyValue /* @private */
{
	id dictObject = [RZUbiquitousKeyValueStore() objectForKey:key];

	NSObjectIsKindOfClassAssertReturn(dictObject, NSDictionary, nil);

	id keyname = [dictObject objectForKey:@"key"];
	id objectValue = [dictObject objectForKey:@"value"];

	PointerIsEmptyAssertReturn(keyname, nil);
	PointerIsEmptyAssertReturn(objectValue, nil);

	if ( realKeyValue) {
		*realKeyValue = keyname;
	}
	
	return objectValue;
}

- (void)removeObjectForKey:(NSString *)key
{
	NSObjectIsEmptyAssert(key);

	NSString *hashedKey = [key md5];

	[RZUbiquitousKeyValueStore() removeObjectForKey:hashedKey];
}

- (void)removeObjectForKeyNextUpstreamSync:(NSString *)key
{
	if ([self applicationIsTerminating]) {
		return; // Do not continue operation...
	}

	if ([TPCPreferences syncPreferencesToTheCloud] == NO) {
		return; // Do not continue operation...
	}

	/* Add key to removal array */
	NSObjectIsEmptyAssert(key);

	XRPerformBlockAsynchronouslyOnQueue(self.workerQueue, ^{
		@synchronized(self.keysToRemove) {
			[self.keysToRemove addObject:key];
		}
	});
}


#pragma mark -
#pragma mark URL Management

- (void)setupUbiquitousContainerPath
{
	XRPerformBlockAsynchronouslyOnQueue(self.workerQueue, ^{
		NSURL *ucurl = [RZFileManager() URLForUbiquityContainerIdentifier:nil];
		
		if (ucurl) {
			self.ubiquitousContainerURL = ucurl;
		} else {
			self.ubiquitousContainerURL = nil;
			
			LogToConsole(@"iCloud access is not available.");
		}
	});
}

- (NSString *)ubiquitousContainerPath
{
	if (self.ubiquitousContainerURL == nil) {
		return nil;
	}

	return [self.ubiquitousContainerURL path];
}

- (BOOL)ubiquitousContainerIsAvailable
{
	return (self.ubiquitousContainerURL != nil);
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
	if ([self applicationIsTerminating]) {
		return; // Do not continue operation...
	}

	if ([TPCPreferences syncPreferencesToTheCloud] == NO) {
		return; // Do not continue operation...
	}

	DebugLogToConsole(@"iCloud: Performing ten-minute based maintenance.");

	XRPerformBlockAsynchronouslyOnQueue(self.workerQueue, ^{
		[TPCPreferences fixThemeFontNameMissingDuringSync];
	});
}

- (void)performOneMinuteTimeBasedMaintenance
{
	if ([self applicationIsTerminating]) {
		return; // Do not continue operation...
	}

	if ([TPCPreferences syncPreferencesToTheCloud] == NO) {
		return; // Do not continue operation...
	}

	/* Perform a sync */
	[self synchronizeToCloud];
	
	/* Perform maintenance */
	XRPerformBlockAsynchronouslyOnQueue(self.workerQueue, ^{
		[TPCPreferences fixThemeNameMissingDuringSync];
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
		NSDictionary *staticValues =
		[TPCResourceManager loadContentsOfPropertyListInResources:@"AppleCloudMappedKeys"];

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
	if ([self applicationIsTerminating]) {
		return; // Do not continue operation...
	}

	if ([TPCPreferences syncPreferencesToTheCloud] == NO) {
		return; // Do not continue operation...
	}

	XRPerformBlockAsynchronouslyOnQueue(self.workerQueue, ^{
		/* Only perform sync if there is something to sync */
		if ([self.keysToSync count] == 0 &&
			[self.keysToRemove count] == 0 &&
			self.pushAllLocalKeysNextSync == NO)
		{
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

		DebugLogToConsole(@"iCloud: Beginning sync upstream.");

		self.isSyncingLocalKeysUpstream = YES;
		
		/* Compare to the remote. */
		NSDictionary *remoteDictionary = [RZUbiquitousKeyValueStore() dictionaryRepresentation];
		
		NSArray *remoteDictionaryKeys = [remoteDictionary allKeys];
		
		/* Gather dictionary representation of all local preferences. */
		id changedValues = nil; // Can be NSDictionary or NSMutableDictionary
		
		if (self.pushAllLocalKeysNextSync) {
			self.pushAllLocalKeysNextSync = NO;

			changedValues = [TPCPreferencesImportExport exportedPreferencesDictionaryRepresentationForCloud];
		} else {
			changedValues = [NSMutableDictionary dictionary];

			@synchronized(self.keysToSync) {
				for (id objectKey in self.keysToSync) {
					id objectValue = [RZUserDefaults() objectForKey:objectKey];
					
					if (objectValue) {
						changedValues[objectKey] = objectValue;
					}
				}
			}
		}

		/* If one of the values changed is our world controller, then we intercept
		 that key and replace it with a few special values. */
		if ([changedValues containsObject:IRCWorldControllerDefaultsStorageKey]) {
			[changedValues removeObjectForKey:IRCWorldControllerDefaultsStorageKey];

			NSMutableDictionary *clientDict = [worldController() cloudDictionaryValue];

			[changedValues addEntriesFromDictionary:clientDict];
		}

		/* Remove keys to sync even if we are syncing all. */
		@synchronized(self.keysToSync) {
			[self.keysToSync removeAllObjects];
		}

		/* Remove any keys that were marked for removal */
		@synchronized(self.keysToRemove) {
			[self.keysToRemove enumerateObjectsUsingBlock:^(id object, NSUInteger idx, BOOL *stop) {
				DebugLogToConsole(@"Key (%@) is being removed from iCloud as it was marked to be.", object);

				[self removeObjectForKey:object];

				[changedValues removeObjectForKey:object];
			}];

			[self.keysToRemove removeAllObjects];
		}

		/* Get a copy of our defaults. */
		static NSDictionary *defaults = nil;

		if (defaults == nil) {
			defaults = [TPCPreferences defaultPreferences];
		}
		
		NSArray *defaultsKeys = [defaults allKeys];
		
		/* Set the remote dictionary. */
		/* Some people may look at this code and wonder what the fuck was this
		 developer thinking? Well, since I know I will be asking myself that in
		 probably a few months when I need to maintain this code; I will explain.

		 You cannot have a key longer than 64 bytes in iCloud so what am I going
		 to do when there are keys stored by Textual longer than that? Rewrite
		 the entire internals of Textual to use shorter keys? Ha, as-if... Instead
		 just use a static hash of the key name as the actual key, then have the
		 value of the key a dictionary with the real key name in it and the value. */
		[changedValues enumerateKeysAndObjectsUsingBlock:^(id key, id object, BOOL *stop) {
			if ([self keyIsNotPermittedInCloud:key]) {
				return;
			}

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
			BOOL keyExistsInCloud = [remoteDictionaryKeys containsObject:key];

			BOOL keyExistsInDefaults = [defaultsKeys containsObject:key];
			
			if (keyExistsInCloud == NO && keyExistsInDefaults) {
				id defaultsValue = [defaults objectForKey:key];
				
				if ([defaultsValue isEqual:object]) {
					return; // Nothing has changed...
				}
			}
			
			[self setValue:object forKey:key];
		}];

		[RZUbiquitousKeyValueStore() synchronize];

		self.isSyncingLocalKeysUpstream = NO;

		DebugLogToConsole(@"iCloud: Completeing sync upstream.");
	});
}

- (void)syncPreferencesFromCloud:(NSArray *)changedKeysHashed
{
	if ([self applicationIsTerminating]) {
		return; // Do not continue operation...
	}

	if ([TPCPreferences syncPreferencesToTheCloud] == NO) {
		return; // Do not continue operation...
	}

	XRPerformBlockAsynchronouslyOnQueue(self.workerQueue, ^{
		DebugLogToConsole(@"iCloud: Beginning sync downstream.");

		self.isSyncingLocalKeysDownstream = YES;

		if (changedKeysHashed == nil || [changedKeysHashed count] <= 0) {
			NSDictionary *upstreamRep = [RZUbiquitousKeyValueStore() dictionaryRepresentation];

			self.remoteKeysBeingSynced = [upstreamRep allKeys];
		} else {
			self.remoteKeysBeingSynced = changedKeysHashed;
		}
		
		/* See the code of syncPreferencesToCloud: for an expalantion of how these keys are hashed. */
		NSMutableArray *changedKeysUnhashed = [NSMutableArray array];
		NSMutableArray *importedClients = [NSMutableArray array];
		NSMutableArray *valuesToRemove = [NSMutableArray array];
		
		for (id hashedKey in self.remoteKeysBeingSynced) {
			id unhashedKey = nil;
			
			id unhashedValue = [self valueForHashedKey:hashedKey actualKey:&unhashedKey];

			/* Maybe remove certain keys from the local defaults store */
			if (unhashedKey == nil || unhashedValue == nil) {
				unhashedKey = [self unhashedKeyFromHashedKey:hashedKey];

				DebugLogToConsole(@"Hashed key (%@) is missing a value or key name. Possible key name: %@", hashedKey, unhashedKey);

				if (unhashedKey) {
					DebugLogToConsole(@"Asking for permission to remove key (%@) from local defaults store.", unhashedKey);

					if ([self keyIsNotPermittedFromCloud:unhashedKey]) {
						continue;
					}

					if ([self keyIsPermittedToBeRemovedThroughCloud:unhashedKey]) {
						[valuesToRemove addObject:unhashedKey];

						[changedKeysUnhashed addObject:unhashedKey];
					}
				}

				continue;
			}

			/* Block stuff from syncing that we did not want. */
			if ([self keyIsNotPermittedFromCloud:unhashedKey]) {
				continue; // Do not continue operation...
			}
			
			/* Compare the local to the new. */
			/* This is for when we are going through the entire dictionary. */
			id localValue = [RZUserDefaults() objectForKey:unhashedKey];
			
			if (localValue && [localValue isEqual:unhashedValue]) {
				continue; // They are same. Don't even try to set.
			}
			
			/* Set it to the new dictionary. */
			if ([unhashedKey isEqual:IRCWorldControllerCloudDeletedClientsStorageKey])
			{
				NSObjectIsKindOfClassAssertContinue(unhashedValue, NSArray);
				
				[self performBlockOnMainThread:^{
					[worldController() processCloudCientDeletionList:unhashedValue];
				}];
			}
			else if ([unhashedKey hasPrefix:IRCWorldControllerCloudClientEntryKeyPrefix])
			{
				NSObjectIsKindOfClassAssertContinue(unhashedValue, NSDictionary);
				
				/* Bet you're wondering why this is added to an array instead of
				 just calling the importWorld... method. Well, it took me a long time
				 to figure this out too. It used to just call the method directly,
				 then I realized, doing that creates a new instance of TVCLogController
				 for each client/channel added. That's all fine, but if the theme
				 ends up changing when calling the TPCPreferences reload... method 
				 below, then that will also reload the theme of thenewly created 
				 view controller instance creating a race condition. Now, we just
				 reload the theme then create the views afterwars. */
				
				[importedClients addObject:unhashedValue];
			}
			else
			{
				[changedKeysUnhashed addObject:unhashedKey];
				
				[TPCPreferencesImportExport import:unhashedValue withKey:unhashedKey];
			}
		}

		/* Perform reload. */
		[self performBlockOnMainThread:^{
			if ([valuesToRemove count] > 0) {
				for (NSString *key in valuesToRemove) {
					[RZUserDefaults() removeObjectForKey:key];
				}
			}

			if ([changedKeysUnhashed count] > 0) {
				[TPCPreferences performReloadActionForKeyValues:changedKeysUnhashed];
			}
			
			if ([importedClients count] > 0) {
				for (NSDictionary *seed in importedClients) {
					[TPCPreferencesImportExport importWorldControllerClientConfiguration:seed isCloudBasedImport:YES];
				}
			}

			self.remoteKeysBeingSynced = nil;
		}];

		self.isSyncingLocalKeysDownstream = NO;

		self.hasUncommittedDataStoredInCloud = NO;

		DebugLogToConsole(@"iCloud: Completeing sync downstream.");
	});
}

- (void)syncPreferenceFromCloudNotification:(NSNotification *)aNote
{
	if ([self applicationIsTerminating]) {
		return; // Do not continue operation...
	}

	NSInteger syncReason = [[aNote userInfo] integerForKey:NSUbiquitousKeyValueStoreChangeReasonKey];

	if (syncReason == NSUbiquitousKeyValueStoreQuotaViolationChange) {
		[self cloudStorageLimitExceeded]; // We will not be syncing for this error.
	} else {
		/* It is kind of important to know this. */
		/* Even if we do not handle it, we still want to know
		 if iCloud tried to sync something to this client. */
		self.hasUncommittedDataStoredInCloud = YES;

		NSArray *changedKeys = [[aNote userInfo] arrayForKey:NSUbiquitousKeyValueStoreChangedKeysKey];

		[self syncPreferencesFromCloud:changedKeys];
	}
}

- (void)resetDataToSync
{
	XRPerformBlockAsynchronouslyOnQueue(self.workerQueue, ^{
		self.pushAllLocalKeysNextSync = NO;
		
		@synchronized(self.keysToSync) {
			[self.keysToSync removeAllObjects];
		}

		@synchronized (self.keysToRemove) {
			[self.keysToRemove removeAllObjects];
		}
	});
}

- (void)syncEverythingNextSync
{
	self.pushAllLocalKeysNextSync = YES;
}

- (void)localKeysDidChangeNotification:(NSNotification *)aNote
{
	if ([self applicationIsTerminating]) {
		return; // Do not continue operation...
	}

	if ([TPCPreferences syncPreferencesToTheCloud] == NO) {
		return; // Do not continue operation...
	}

	/* Downstream syncing will fire this notification so we
	 check whether the key exists before adding it to our list. */
	XRPerformBlockAsynchronouslyOnQueue(self.workerQueue, ^{
		NSString *changedKey = [[aNote userInfo] objectForKey:@"changedKey"];
		
		if (changedKey == nil) {
			return;
		}

		NSArray *pendingWrites = self.remoteKeysBeingSynced;
		
		if (pendingWrites) {
			if ([pendingWrites containsObject:changedKey]) {
				return; // Do not add this key...
			}
		}

		@synchronized(self.keysToSync) {
			[self.keysToSync addObject:changedKey];
		}

		@synchronized(self.keysToRemove) {
			[self.keysToRemove removeObject:changedKey];
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
#pragma mark Session Management

- (void)iCloudAccountAvailabilityChanged:(NSNotification *)aNote
{
	if ([self applicationIsTerminating]) {
		return; // Do not continue operation...
	}

	id oldToken = self.ubiquityIdentityToken;

	id newToken = [RZFileManager() cloudUbiquityIdentityToken];

	if (newToken && newToken != oldToken) {
		self.pushAllLocalKeysNextSync = YES;
	}

	self.ubiquityIdentityToken = newToken;
	
	[self setupUbiquitousContainerPath];
}

- (void)initializeCloudSyncSession
{
	if ([NSUbiquitousKeyValueStore defaultStore] == nil) {
		LogToConsole(@"Key-value store for iCloud syncing not available.");

		return;
	}

	DebugLogToConsole(@"iCloud: Beginning session.");

	self.workerQueue = dispatch_queue_create("iCloudSyncWorkerQueue", DISPATCH_QUEUE_SERIAL);

	self.ubiquityIdentityToken = [RZFileManager() cloudUbiquityIdentityToken];

	[self setupUbiquitousContainerPath];

	self.keysToSync = [NSMutableArray array];
	self.keysToRemove = [NSMutableArray array];

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

	self.cloudOneMinuteSyncTimer = syncTimer1;
	self.cloudTenMinuteSyncTimer = syncTimer2;

	[RZNotificationCenter() addObserver:self
							   selector:@selector(syncPreferenceFromCloudNotification:)
								   name:NSUbiquitousKeyValueStoreDidChangeExternallyNotification
								 object:nil];

	[RZUbiquitousKeyValueStore() synchronize];
}

- (void)purgeDataStoredWithCloud
{
	if ([self applicationIsTerminating]) {
		return; // Do not continue operation...
	}

	XRPerformBlockAsynchronouslyOnQueue(self.workerQueue, ^{
		[RZUbiquitousKeyValueStore() synchronize];

		NSDictionary *remoteDictionary = [RZUbiquitousKeyValueStore() dictionaryRepresentation];

		[remoteDictionary enumerateKeysAndObjectsUsingBlock:^(id key, id object, BOOL *stop) {
			[RZUbiquitousKeyValueStore() removeObjectForKey:key];
		}];

		[RZUserDefaults() removeObjectForKey:TPCPreferencesThemeNameMissingLocallyDefaultsKey];
		[RZUserDefaults() removeObjectForKey:TPCPreferencesThemeFontNameMissingLocallyDefaultsKey];

		self.pushAllLocalKeysNextSync = YES;
	});
}

- (void)prepareForApplicationTermination
{
	/* The cloud session is closed from within the worker queue so that 
	 any operations that aren't already finished will have time to do so. */
	XRPerformBlockAsynchronouslyOnQueue(self.workerQueue, ^{
		self.applicationIsTerminating = YES;

		[self closeCloudSyncSession];
	});
}

- (void)closeCloudSyncSession
{
	DebugLogToConsole(@"iCloud: Closing session.");

	if ( self.cloudOneMinuteSyncTimer) {
		[self.cloudOneMinuteSyncTimer invalidate];
		 self.cloudOneMinuteSyncTimer = nil;
	}
	
	if ( self.cloudTenMinuteSyncTimer) {
		[self.cloudTenMinuteSyncTimer invalidate];
		 self.cloudTenMinuteSyncTimer = nil;
	}
	
    [RZNotificationCenter() removeObserver:self name:TPCPreferencesUserDefaultsDidChangeNotification object:nil];
	
	[RZNotificationCenter() removeObserver:self name:NSUbiquityIdentityDidChangeNotification object:nil];

    [RZNotificationCenter() removeObserver:self name:NSUbiquitousKeyValueStoreDidChangeExternallyNotification object:nil];
	
	if (self.workerQueue) {
		self.workerQueue = nil;
	}

	self.pushAllLocalKeysNextSync = NO;

	self.keysToSync = nil;
	self.keysToRemove = nil;

	self.remoteKeysBeingSynced = nil;

	self.isSyncingLocalKeysDownstream = NO;
	self.isSyncingLocalKeysUpstream = NO;

	self.ubiquityIdentityToken = nil;
	self.ubiquitousContainerURL = nil;

	self.isTerminated = YES;
}

@end

#endif
