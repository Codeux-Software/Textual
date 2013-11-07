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

#define _localKeysUpstreamSyncTimerInterval			60.0

@interface TPCPreferencesCloudSync ()
@property (nonatomic, assign) BOOL localKeysWereUpdated;
@property (nonatomic, assign) BOOL isSyncingLocalKeysDownstream;
@property (nonatomic, assign) BOOL isSyncingLocalKeysUpstream;
@property (nonatomic, assign) dispatch_queue_t workerQueue;
@property (nonatomic, strong) NSTimer *cloudSyncTimer;
@property (nonatomic, strong) NSURL *ubiquitousContainerURL;
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

- (NSString *)ubiquitousContainerURLPath
{
	/* Handle URL request. */
	static BOOL ubiquitousContainerURLRequestDispatched;
	
	if (ubiquitousContainerURLRequestDispatched == NO) {
		ubiquitousContainerURLRequestDispatched = YES;
		
		dispatch_async(self.workerQueue, ^{
			/* Apple very clearly states not to do call this on the main thread
			 since it does a lot of work, so we wont… */
			NSURL *ucurl = [RZFileManager() URLForUbiquityContainerIdentifier:nil];
			
			if (ucurl) {
				self.ubiquitousContainerURL = ucurl;
			}
		});
	}
			
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

- (BOOL)keyIsNotPermittedInCloud:(NSString *)key
{
	return ([key isEqualToString:IRCWorldControllerDefaultsStorageKey] ||
			[key isEqualToString:@"SyncPreferencesToTheCloud"]);
}

- (void)syncPreferencesToCloud
{
	dispatch_async(self.workerQueue, ^{
		/* We don't even want to sync if user doesn't want to. */
		NSAssertReturn([TPCPreferences syncPreferencesToTheCloud]);
		
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
	dispatch_async(self.workerQueue, ^{
		/* Debug data. */
		DebugLogToConsole(@"iCloud: Beginning sync downstream.");

		/* We don't even want to sync if user doesn't want to. */
		NSAssertReturn([TPCPreferences syncPreferencesToTheCloud]);

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
#pragma mark Session Management

- (void)initializeCloudSyncSession
{
	/* Debug data. */
	DebugLogToConsole(@"iCloud: Beginning session.");

	/* Begin actual session. */
	if (RZUbiquitousKeyValueStore()) {
		/* Create worker queue. */
		self.workerQueue = dispatch_queue_create("iCloudSyncWorkerQueue", NULL);
		
		/* Notification for when a local value through NSUserDefaults is changed. */
		[RZNotificationCenter() addObserver:self
								   selector:@selector(localKeysDidChangeNotification:)
									   name:NSUserDefaultsDidChangeNotification
									 object:nil];
		
		NSTimer *syncTimer = [NSTimer scheduledTimerWithTimeInterval:_localKeysUpstreamSyncTimerInterval
															  target:self
															selector:@selector(syncPreferencesToCloud)
															userInfo:nil
															 repeats:YES];
		
		self.cloudSyncTimer = syncTimer;

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
	});
}

- (void)closeCloudSyncSession
{
	/* Debug data. */
	DebugLogToConsole(@"iCloud: Closing session.");

	/* Stop listening for notification related to local changes. */
    [self.cloudSyncTimer invalidate];
	
    [RZNotificationCenter() removeObserver:self
									  name:NSUserDefaultsDidChangeNotification
									object:nil];

	/* Stop listening for notification related to remote changes. */
    [RZNotificationCenter() removeObserver:self
									  name:NSUbiquitousKeyValueStoreDidChangeExternallyNotification
									object:nil];
	
	/* Dispatch clean-up. */
	if (self.workerQueue) {
		dispatch_release(self.workerQueue);
		
		self.workerQueue = NULL;
	}
}

@end

#endif
