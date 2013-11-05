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

@implementation TPCPreferencesCloudSync

/* We want to know when we are setting local keys so that
 syncPreferencesToCloud: is not sent into an infinite loop. */
static BOOL isSyncingLocalKeysDownstream = NO;
static BOOL isSyncingLocalKeysUpstream = NO;
static BOOL isSyncingTemporarilyDisabled = NO;
static BOOL isSyncingTemporarilyDelayed = NO;

static dispatch_queue_t workerQueue = NULL;

#pragma mark -
#pragma mark Public API

+ (void)setValue:(id)value forKey:(NSString *)key
{
	NSObjectIsEmptyAssert(key); // Yeah, we need a key…
	
	/* Set it and forget it. */
	NSString *hashedKey = [NSString stringWithUnsignedInteger:[key hash]];
	
	[RZUbiquitousKeyValueStore() setObject:@{@"key" : key, @"value" : value} forKey:hashedKey];
}

+ (id)valueForKey:(NSString *)key
{
	NSObjectIsEmptyAssertReturn(key, nil); // Yeah, we need a key…
	
	/* Insert pointless comment here. */
	NSString *hashedKey = [NSString stringWithUnsignedInteger:[key hash]];
	
	/* Another pointless comment here. */
	return [self valueForHashedKey:hashedKey actualKey:NULL];
}

+ (id)valueForHashedKey:(NSString *)key actualKey:(NSString **)realKeyValue /* @private */
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

+ (void)removeObjectForKey:(NSString *)key
{
	NSObjectIsEmptyAssert(key); // Yeah, we need a key…
	
	/* Set it and forget it. */
	NSString *hashedKey = [NSString stringWithUnsignedInteger:[key hash]];
	
	/* Umm, I just copy and paste these things. */
	[RZUbiquitousKeyValueStore() removeObjectForKey:hashedKey];
}

#pragma mark -
#pragma mark Cloud Sync Management

+ (void)synchronizeToCloud /* Manually sync. Not recommended to call. */
{
	[self syncPreferencesToCloud:nil];
}

+ (void)setSyncingTemporarilyDisabled:(BOOL)disableSync
{
	isSyncingTemporarilyDisabled = disableSync;
}

+ (void)setSyncingTemporarilyDelayed
{
	if (isSyncingTemporarilyDelayed == NO) {
		isSyncingTemporarilyDelayed = YES;
		
		/* Resets after five seconds. */
		dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (5 * NSEC_PER_SEC)), dispatch_get_current_queue(), ^{
			[TPCPreferencesCloudSync resetSyncingTemporarilyDelayedToken];
		});
	}
}

+ (void)resetSyncingTemporarilyDelayedToken
{
	if (isSyncingTemporarilyDelayed) {
		isSyncingTemporarilyDelayed = NO;
		
		[self synchronizeToCloud];
	}
}

+ (BOOL)keyIsNotPermittedInCloud:(NSString *)key
{
	return ([key isEqualToString:IRCWorldControllerDefaultsStorageKey] ||
			[key isEqualToString:@"SyncPreferencesToTheCloud"]);
}

+ (void)syncPreferencesToCloud:(NSNotification *)aNote
{
	dispatch_async(workerQueue, ^{
		/* Debug data. */
		DebugLogToConsole(@"iCloud: Beginning sync upstream.");

		/* We don't even want to sync if user doesn't want to. */
		NSAssertReturn([TPCPreferences syncPreferencesToTheCloud]);

		/* Are we already syncing? */
		if (isSyncingLocalKeysDownstream) {
			DebugLogToConsole(@"iCloud: Upstream sync cancelled because a downstream sync was already running.");
			
			return; // Cancel this operation;
		}
		
		if (isSyncingLocalKeysUpstream) {
			DebugLogToConsole(@"iCloud: Upstream sync cancelled because an upstream sync was already running.");
			
			return; // Cancel this operation;
		}
		
		if (isSyncingTemporarilyDelayed) {
			DebugLogToConsole(@"iCloud: Upstream sync cancelled because a delayed sync is set.");
			
			return; // Cancel this operation;
		}
		
		if (isSyncingTemporarilyDisabled) {
			DebugLogToConsole(@"iCloud: Upstream sync cancelled because syncing is disabled.");
			
			return; // Cancel this operation;
		}
		
		/* Continue normal work. */
		isSyncingLocalKeysUpstream = YES;

		/* Gather dictionary representation of all local preferences. */
		NSDictionary *localdict = [TPCPreferencesImportExport exportedPreferencesDictionaryRepresentation];
		
		NSMutableDictionary *clientDict = [self.worldController cloudDictionaryValue];
		
		/* Combine these two… */
		[clientDict addEntriesFromDictionary:localdict];

		/* Sync latest changes from disc for the dictionary. */
		[RZUbiquitousKeyValueStore() synchronize];

		/* Compare to the remote. */
		NSDictionary *remotedict = [RZUbiquitousKeyValueStore() dictionaryRepresentation];

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
					[TPCPreferencesCloudSync setValue:obj forKey:key];
				}
			}];
		}

		/* Allow us to continue work. */
		isSyncingLocalKeysUpstream = NO;

		DebugLogToConsole(@"iCloud: Completeing sync upstream.");
	});
}

+ (void)syncPreferencesFromCloud:(NSNotification *)aNote
{
	dispatch_async(workerQueue, ^{
		/* Debug data. */
		DebugLogToConsole(@"iCloud: Beginning sync downstream.");

		/* We don't even want to sync if user doesn't want to. */
		NSAssertReturn([TPCPreferences syncPreferencesToTheCloud]);

		/* Announce our intents… */
		isSyncingLocalKeysDownstream = YES;

		/* Gather information about the sync request. */
		NSInteger syncReason = [aNote.userInfo integerForKey:NSUbiquitousKeyValueStoreChangeReasonKey];

		/* Are we out of memory? */
		if (syncReason == NSUbiquitousKeyValueStoreQuotaViolationChange) {
			[self cloudStorageLimitExceeded]; // We will not be syncing for this error.
		} else {
			/* Get the list of changed keys. */
			NSArray *changedKeys = [aNote.userInfo arrayForKey:NSUbiquitousKeyValueStoreChangedKeysKey];

			NSMutableArray *actualChangedKeys = [NSMutableArray array];
			
			/* See the code of syncPreferencesToCloud: for an expalantion of how these keys are hashed. */
			for (id hashedKey in changedKeys) {
				id keyname = nil;
				id objectValue = [self valueForHashedKey:hashedKey actualKey:&keyname];
				
				if (objectValue) {
					/* Set it to the new dictionary. */
					
					if ([keyname isEqual:IRCWorldControllerCloudDeletedClientsStorageKey])
					{
						NSObjectIsKindOfClassAssert(objectValue, NSArray);
						
						dispatch_async(dispatch_get_main_queue(), ^{
							[self.worldController processCloudCientDeletionList:objectValue];
						});
					}
					else if ([keyname hasPrefix:IRCWorldControllerCloudDeletedClientsStorageKey])
					{
						NSObjectIsKindOfClassAssert(objectValue, NSDictionary);
						
						dispatch_async(dispatch_get_main_queue(), ^{
							[TPCPreferencesImportExport importWorldControllerClientConfiguratoin:objectValue isCloudBasedImport:YES];
						});
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
				[TPCPreferences performReloadActionForKeyValues:actualChangedKeys];
			});
		}

		/* Allow us to continue work. */
		isSyncingLocalKeysDownstream = NO;
	});
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

+ (void)cloudStorageLimitExceeded
{
#warning TODO: Make user aware of this…
	LogToConsole(@"The cloud storage limit was exceeded.");
}

#pragma mark -
#pragma mark Session Management

+ (void)initializeCloudSyncSession
{
	/* Debug data. */
	DebugLogToConsole(@"iCloud: Beginning session.");

	/* Begin actual session. */
	if (RZUbiquitousKeyValueStore()) {
		/* Create worker queue. */
		workerQueue = dispatch_queue_create("iCloudSyncWorkerQueue", NULL);
		
		/* Notification for when a local value through NSUserDefaults is changed. */
		[RZNotificationCenter() addObserver:[self class]
								   selector:@selector(syncPreferencesToCloud:)
									   name:NSUserDefaultsDidChangeNotification
									 object:nil];

		/* Notification for when a remote value through the key-value store is changed. */
		[RZNotificationCenter() addObserver:[self class]
								   selector:@selector(syncPreferencesFromCloud:)
									   name:NSUbiquitousKeyValueStoreDidChangeExternallyNotification
									 object:nil];
		
		/* Sync latest changes from disc for the dictionary. */
		[RZUbiquitousKeyValueStore() synchronize];
	} else {
		/* The key value store is not available. */

		LogToConsole(@"Key-value store for iCloud syncing not available.");
	}
}

+ (void)purgeDataStoredWithCloud
{
	dispatch_async(workerQueue, ^{
		/* Sync latest changes from disc for the dictionary. */
		[RZUbiquitousKeyValueStore() synchronize];

		/* Get the remote. */
		NSDictionary *remotedict = [RZUbiquitousKeyValueStore() dictionaryRepresentation];

		/* Start destroying. */
		[remotedict enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
			[RZUbiquitousKeyValueStore() removeObjectForKey:key];
		}];
	});
}

+ (void)closeCloudSyncSession
{
	/* Dispatch clean-up. */
	if (workerQueue) {
		dispatch_release(workerQueue);
	}
	
	/* Debug data. */
	DebugLogToConsole(@"iCloud: Closing session.");

	/* Stop listening for notification related to local changes. */
    [RZNotificationCenter() removeObserver:[self class]
									  name:NSUserDefaultsDidChangeNotification
									object:nil];

	/* Stop listening for notification related to remote changes. */
    [RZNotificationCenter() removeObserver:[self class]
									  name:NSUbiquitousKeyValueStoreDidChangeExternallyNotification
									object:nil];
}

@end

#endif
