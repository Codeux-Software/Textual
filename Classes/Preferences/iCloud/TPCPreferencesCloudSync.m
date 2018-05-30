/* *********************************************************************
 *                  _____         _               _
 *                 |_   _|____  _| |_ _   _  __ _| |
 *                   | |/ _ \ \/ / __| | | |/ _` | |
 *                   | |  __/>  <| |_| |_| | (_| | |
 *                   |_|\___/_/\_\\__|\__,_|\__,_|_|
 *
 * Copyright (c) 2010 - 2015 Codeux Software, LLC & respective contributors.
 *       Please see Acknowledgements.pdf for additional information.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *
 *  * Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 *  * Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 *  * Neither the name of Textual, "Codeux Software, LLC", nor the
 *    names of its contributors may be used to endorse or promote products
 *    derived from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE AUTHOR AND CONTRIBUTORS ``AS IS'' AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED. IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE LIABLE
 * FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
 * OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
 * LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
 * OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
 * SUCH DAMAGE.
 *
 *********************************************************************** */

#import "TXMasterController.h"
#import "IRCWorldPrivateCloudExtension.h"
#import "TPCThemeControllerPrivate.h"
#import "TPCPreferencesCloudSyncExtensionPrivate.h"
#import "TPCPreferencesLocal.h"
#import "TPCPreferencesImportExportPrivate.h"
#import "TPCPreferencesReload.h"
#import "TPCPreferencesUserDefaults.h"
#import "TPCPreferencesCloudSyncPrivate.h"

NS_ASSUME_NONNULL_BEGIN

#if TEXTUAL_BUILT_WITH_ICLOUD_SUPPORT == 1
/* Internal cloud work is divided into two timers. Important work such as
 syncing upstream to the cloud is put on a per-minute timer. This timer
 also checks if a theme stored in the temporary store now exists. */
/* The second timer is ten-minute (roughly) based and handles less important
 tasks. When this comment was written, it only handled the checking of
 whether fonts exist, but it could be changed to include more later. */
#define _localKeysUpstreamSyncTimerInterval_1			60.0	// 1 minute
#define _localKeysUpstreamSyncTimerInterval_2			630.0	// 10 minutes, 30 seconds

@interface TPCPreferencesCloudSync ()
@property (nonatomic, strong, nullable) id ubiquityIdentityToken;
@property (nonatomic, assign) BOOL pushAllLocalKeysNextSync;
@property (nonatomic, strong) dispatch_queue_t workerQueue;
@property (nonatomic, strong) NSTimer *cloudOneMinuteSyncTimer;
@property (nonatomic, strong) NSTimer *cloudTenMinuteSyncTimer;
@property (nonatomic, copy, nullable, readwrite) NSURL *ubiquitousContainerURL;
@property (nonatomic, strong) NSMutableArray<NSString *> *keysToSync;
@property (nonatomic, strong) NSMutableArray<NSString *> *keysToRemove;
@property (nonatomic, copy) NSArray<NSString *> *remoteKeysBeingSynced;
@property (nonatomic, assign, readwrite) BOOL isTerminated;
@property (nonatomic, assign) BOOL isSyncingLocalKeysDownstream;
@property (nonatomic, assign) BOOL isSyncingLocalKeysUpstream;
@property (nonatomic, assign) BOOL hasUncommittedDataStoredInCloud;
@end

@implementation TPCPreferencesCloudSync

#pragma mark -
#pragma mark Public API

- (void)setValue:(nullable id)value forKey:(NSString *)key
{
	NSParameterAssert(key != nil);

	NSString *keyHashed = key.md5;

	if (value == nil) {
		[RZUbiquitousKeyValueStore() removeObjectForKey:keyHashed];

		return;
	}

	NSDictionary *valueDic = @{
		@"key" : key,
		@"value" : value
	};

	[RZUbiquitousKeyValueStore() setObject:valueDic forKey:keyHashed];
}

- (nullable id)valueForKey:(NSString *)key
{
	NSParameterAssert(key != nil);

	NSString *keyHashed = key.md5;

	return [self valueForHashedKey:keyHashed unhashedKey:NULL];
}

- (nullable id)valueForHashedKey:(NSString *)hashedKey unhashedKey:(NSString * _Nullable * _Nullable)unhashedKey /* @private */
{
	NSParameterAssert(hashedKey != nil);

	id dictObject = [RZUbiquitousKeyValueStore() objectForKey:hashedKey];

	NSObjectIsKindOfClassAssertReturn(dictObject, NSDictionary, nil)

	id keyValue = dictObject[@"key"];

	if (keyValue == nil) {
		return nil;
	}

	id objectValue = dictObject[@"value"];

	if (objectValue == nil) {
		return nil;
	}

	if ( unhashedKey) {
		*unhashedKey = keyValue;
	}

	return objectValue;
}

- (void)removeObjectForKey:(NSString *)key
{
	NSParameterAssert(key != nil);

	NSString *keyHashed = key.md5;

	[RZUbiquitousKeyValueStore() removeObjectForKey:keyHashed];
}

- (void)removeObjectForKeyNextUpstreamSync:(NSString *)key
{
	NSParameterAssert(key != nil);

	if (self.isTerminated) {
		return;
	}

	if ([TPCPreferences syncPreferencesToTheCloud] == NO) {
		return;
	}

	XRPerformBlockAsynchronouslyOnQueue(self.workerQueue, ^{
		[self.keysToRemove addObject:key];
	});
}

#pragma mark -
#pragma mark URL Management

- (void)setupUbiquitousContainerPath
{
	if (self.isTerminated) {
		return;
	}

	XRPerformBlockAsynchronouslyOnQueue(self.workerQueue, ^{
		NSURL *containerURL = [RZFileManager() URLForUbiquityContainerIdentifier:nil];

		if (containerURL) {
			self.ubiquitousContainerURL = containerURL;
		} else {
			self.ubiquitousContainerURL = nil;

			LogToConsoleInfo("iCloud access is not available.");
		}

		[themeController() reloadMonitoringActiveThemePath];
	});
}

- (nullable NSString *)ubiquitousContainerPath
{
	return (self.ubiquitousContainerURL).path;
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
	if (self.isTerminated) {
		return;
	}

	if ([TPCPreferences syncPreferencesToTheCloud] == NO) {
		return;
	}

	XRPerformBlockAsynchronouslyOnQueue(self.workerQueue, ^{
		[TPCPreferences fixThemeFontNameMissingDuringSync];
	});
}

- (void)performOneMinuteTimeBasedMaintenance
{
	if (self.isTerminated) {
		return;
	}

	if ([TPCPreferences syncPreferencesToTheCloud] == NO) {
		return;
	}

	[self synchronizeToCloud];

	XRPerformBlockAsynchronouslyOnQueue(self.workerQueue, ^{
		[TPCPreferences fixThemeNameMissingDuringSync];
	});
}

- (void)syncPreferencesToCloud
{
	if (self.isTerminated) {
		return;
	}

	if ([TPCPreferences syncPreferencesToTheCloud] == NO) {
		return;
	}

	XRPerformBlockAsynchronouslyOnQueue(self.workerQueue, ^{
		/* Only perform sync if there is something to sync */
		if (self.pushAllLocalKeysNextSync == NO && (self.keysToRemove).count == 0 && (self.keysToSync).count == 0) {
			LogToConsoleDebug("iCloud: Upstream sync cancelled because nothing has changed");

			return;
		}

		if (self.isSyncingLocalKeysDownstream) {
			LogToConsoleDebug("iCloud: Upstream sync cancelled because a downstream sync is in progress");

			return;
		}

		if (self.isSyncingLocalKeysUpstream) {
			LogToConsoleDebug("iCloud: Upstream sync cancelled because an upstream sync is in progress");

			return;
		}

		if (self.hasUncommittedDataStoredInCloud) {
			LogToConsoleDebug("iCloud: Upstream sync cancelled because there is uncommitted data remaining in the cloud");

			return;
		}

		LogToConsoleDebug("iCloud: Beginning sync upstream");

		self.isSyncingLocalKeysUpstream = YES;

		/* Compare to the remote */
		NSDictionary *remoteValues = RZUbiquitousKeyValueStore().dictionaryRepresentation;

		/* Gather dictionary representation of all local preferences */
		NSMutableDictionary<NSString *, id> *changedValues = [NSMutableDictionary dictionary];

		if (self.pushAllLocalKeysNextSync) {
			self.pushAllLocalKeysNextSync = NO;

			NSDictionary *exportedPreferences = [TPCPreferencesImportExport exportedPreferencesDictionaryForCloud];

			[changedValues addEntriesFromDictionary:exportedPreferences];
		} else {
			for (NSString *key in self.keysToSync) {
				id object = [RZUserDefaults() objectForKey:key];

				if (object) {
					changedValues[key] = object;
				}
			}
		}

		/* Remove keys to sync even if we are syncing all */
		[self.keysToSync removeAllObjects];

		/* If one of the values changed is our world controller, then we 
		 intercept that key and replace it with a few special values. */
		if ([changedValues containsKey:IRCWorldClientListDefaultsKey]) {
			[changedValues removeObjectForKey:IRCWorldClientListDefaultsKey];

			NSDictionary *clientDict = [worldController() cloud_clientConfigurations];

			[changedValues addEntriesFromDictionary:clientDict];
		}

		/* Remove any keys that were marked for removal */
		for (NSString *key in self.keysToRemove) {
			LogToConsoleDebug("Key (%{public}@) is being removed from iCloud as it was marked to be", key);

			[self removeObjectForKey:key];

			[changedValues removeObjectForKey:key];
		};

		[self.keysToRemove removeAllObjects];

		/* Get a copy of our defaults */
		static NSDictionary<NSString *, NSString *> *defaults = nil;

		if (defaults == nil) {
			defaults = [TPCPreferences defaultPreferences];
		}

		/* Set the remote dictionary */
		[changedValues enumerateKeysAndObjectsUsingBlock:^(id key, id objectValue, BOOL *stop) {
			/* Special save conditions */
			if ([self keyIsNotPermittedInCloud:key]) {
				return;
			}

			if ([key isEqualToString:TPCPreferencesThemeNameDefaultsKey]) {
				BOOL missingTheme = [RZUserDefaults() boolForKey:TPCPreferencesThemeNameMissingLocallyDefaultsKey];

				if (missingTheme) {
					return;
				}
			} else if ([key isEqualToString:TPCPreferencesThemeFontNameDefaultsKey]) {
				BOOL fontMissing = [RZUserDefaults() boolForKey:TPCPreferencesThemeFontNameMissingLocallyDefaultsKey];

				if (fontMissing) {
					return;
				}
			}

			/* If the key does not already exist in the cloud, then we check 
			 if its value matches the default value maintained internally. If
			 it has not changed from the default, why are we saving it? */
			id defaultsValue = defaults[key];

			id remoteValue = remoteValues[key];

			if (defaultsValue != nil && remoteValue == nil) {
				if ([defaultsValue isEqual:objectValue]) {
					return;
				}
			}

			/* Save value */
			[self setValue:objectValue forKey:key];
		}];

		[RZUbiquitousKeyValueStore() synchronize];

		self.isSyncingLocalKeysUpstream = NO;

		LogToConsoleDebug("iCloud: Completeing sync upstream");
	});
}

- (void)syncPreferencesFromCloud:(NSArray<NSString *> *)keysChangedHashed
{
	if (self.isTerminated) {
		return;
	}

	if ([TPCPreferences syncPreferencesToTheCloud] == NO) {
		return;
	}

	XRPerformBlockAsynchronouslyOnQueue(self.workerQueue, ^{
		LogToConsoleDebug("iCloud: Beginning sync downstream");

		self.isSyncingLocalKeysDownstream = YES;

		if (keysChangedHashed == nil || keysChangedHashed.count == 0) {
			NSDictionary *upstreamValues = RZUbiquitousKeyValueStore().dictionaryRepresentation;

			self.remoteKeysBeingSynced = upstreamValues.allKeys;
		} else {
			self.remoteKeysBeingSynced = keysChangedHashed;
		}

		/* See the code of syncPreferencesToCloud: for an expalantion of how these keys are hashed. */
		NSMutableArray<NSDictionary *> *clientsImported = [NSMutableArray array];

		NSMutableArray<NSString *> *keysChanged = [NSMutableArray array];
		NSMutableArray<NSString *> *keysToRemove = [NSMutableArray array];

		NSArray<NSString *> *listOfDeletedClients = nil;

		for (NSString *hashedKey in self.remoteKeysBeingSynced) {
			NSString *unhashedKey = nil;

			id unhashedValue = [self valueForHashedKey:hashedKey unhashedKey:&unhashedKey];

			/* Maybe remove certain keys from the local defaults store */
			if (unhashedKey == nil || unhashedValue == nil) {
				unhashedKey = [self unhashedKeyFromHashedKey:hashedKey];

				LogToConsoleDebug("Hashed key (%{public}@) is missing a value or key name. Possible key name: %@", hashedKey, unhashedKey);

				if (unhashedKey) {
					LogToConsoleDebug("Asking for permission to remove key (%{public}@) from local defaults store", unhashedKey);

					if ([self keyIsNotPermittedFromCloud:unhashedKey]) {
						continue;
					}

					if ([self keyIsPermittedToBeRemovedThroughCloud:unhashedKey]) {
						[keysToRemove addObject:unhashedKey];

						[keysChanged addObject:unhashedKey];
					}
				}

				continue;
			}

			if ([self keyIsNotPermittedFromCloud:unhashedKey]) {
				continue;
			}

			/* Compare the local to the new */
			/* This is for when we are going through the entire dictionary */
			id localValue = [RZUserDefaults() objectForKey:unhashedKey];

			if (localValue && [localValue isEqual:unhashedValue]) {
				continue;
			}

			/* Set it to the new dictionary */
			if ([unhashedKey isEqualToString:IRCWorldControllerCloudListOfDeletedClientsDefaultsKey])
			{
				if ([unhashedValue isKindOfClass:[NSArray class]] == NO) {
					continue;
				}

				listOfDeletedClients = unhashedValue;
			}
			else if ([unhashedKey hasPrefix:IRCWorldControllerCloudClientItemDefaultsKeyPrefix])
			{
				if ([unhashedValue isKindOfClass:[NSDictionary class]] == NO) {
					continue;
				}

				[clientsImported addObject:unhashedValue];
			}
			else
			{
				[keysChanged addObject:unhashedKey];

				[TPCPreferencesImportExport import:unhashedValue withKey:unhashedKey];
			}
		}

		/* Perform reload */
		XRPerformBlockAsynchronouslyOnMainQueue(^{
			if (listOfDeletedClients.count > 0) {
				[worldController() cloud_processDeletedClientsList:listOfDeletedClients];
			}

			for (NSString *key in keysToRemove) {
				[RZUserDefaults() removeObjectForKey:key];
			}

			if (keysChanged.count > 0) {
				[TPCPreferences performReloadActionForKeys:keysChanged];
			}

			for (NSDictionary *client in clientsImported) {
				[TPCPreferencesImportExport importClientConfiguration:client isImportedFromCloud:YES];
			}
		});

		self.hasUncommittedDataStoredInCloud = NO;

		self.isSyncingLocalKeysDownstream = NO;

		self.remoteKeysBeingSynced = nil;

		LogToConsoleDebug("iCloud: Completeing sync downstream");
	});
}

- (void)resetDataToSync
{
	if (self.isTerminated) {
		return;
	}

	XRPerformBlockAsynchronouslyOnQueue(self.workerQueue, ^{
		self.pushAllLocalKeysNextSync = NO;

		[self.keysToRemove removeAllObjects];
		[self.keysToSync removeAllObjects];
	});
}

- (void)syncEverythingNextSync
{
	if (self.isTerminated) {
		return;
	}

	self.pushAllLocalKeysNextSync = YES;
}

- (void)purgeDataStoredWithCloud
{
	if (self.isTerminated) {
		return;
	}

	XRPerformBlockAsynchronouslyOnQueue(self.workerQueue, ^{
		[RZUbiquitousKeyValueStore() synchronize];

		NSDictionary *remoteValues = RZUbiquitousKeyValueStore().dictionaryRepresentation;

		[remoteValues enumerateKeysAndObjectsUsingBlock:^(NSString *key, id object, BOOL *stop) {
			[RZUbiquitousKeyValueStore() removeObjectForKey:key];
		}];

		[RZUserDefaults() removeObjectForKey:TPCPreferencesThemeFontNameMissingLocallyDefaultsKey];

		[RZUserDefaults() removeObjectForKey:TPCPreferencesThemeNameMissingLocallyDefaultsKey];

		self.pushAllLocalKeysNextSync = YES;
	});
}

#pragma mark -
#pragma mark Key Conditions

- (BOOL)keyIsNotPermittedInCloud:(NSString *)key
{
	NSParameterAssert(key != nil);

	if ([TPCPreferences syncPreferencesToTheCloudLimitedToServers]) {
		return ([key hasPrefix:IRCWorldControllerCloudClientItemDefaultsKeyPrefix] == NO);
	}

	return ([key isEqualToString:@"World Controller"] ||
			[key isEqualToString:IRCWorldClientListDefaultsKey] ||
			[key isEqualToString:IRCWorldControllerCloudListOfDeletedClientsDefaultsKey] ||
			[key isEqualToString:TPCPreferencesCloudSyncServicesEnabledDefaultsKey] ||
			[key isEqualToString:TPCPreferencesCloudSyncServicesLimitedToServersDefaultsKey] ||
			[key isEqualToString:TPCPreferencesThemeNameMissingLocallyDefaultsKey] ||
			[key isEqualToString:TPCPreferencesThemeFontNameMissingLocallyDefaultsKey]);
}

- (BOOL)keyIsNotPermittedFromCloud:(NSString *)key
{
	NSParameterAssert(key != nil);

	if ([TPCPreferences syncPreferencesToTheCloudLimitedToServers]) {
		return ([self keyIsRelatedToSavedServerState:key] == NO);
	}

	return ([key isEqualToString:@"World Controller"] ||
			[key isEqualToString:IRCWorldClientListDefaultsKey] ||
			[key isEqualToString:TPCPreferencesCloudSyncServicesEnabledDefaultsKey] ||
			[key isEqualToString:TPCPreferencesCloudSyncServicesLimitedToServersDefaultsKey] ||
			[key isEqualToString:TPCPreferencesThemeNameMissingLocallyDefaultsKey] ||
			[key isEqualToString:TPCPreferencesThemeFontNameMissingLocallyDefaultsKey]);
}

- (BOOL)keyIsRelatedToSavedServerState:(NSString *)key
{
	NSParameterAssert(key != nil);

	return ([key isEqualToString:IRCWorldControllerCloudListOfDeletedClientsDefaultsKey] ||
			[key hasPrefix:IRCWorldControllerCloudClientItemDefaultsKeyPrefix]);
}

- (nullable NSString *)unhashedKeyFromHashedKey:(NSString *)hashedKey
{
	/* This method only lists specific keys that we need to know which cannot
	 be viewed directly by asking for the key-value entry in iCloud. */
	/* It was at the point that I wrote this method that I realized how
	 fucking stupid Textual's implementation of iCloud is. */
	NSParameterAssert(hashedKey != nil);

	static NSDictionary<NSString *, NSString *> *cachedValues = nil;

	static dispatch_once_t onceToken;

	dispatch_once(&onceToken, ^{
		cachedValues = @{
			@"eb2dc862342c6c653e29d7363f6d421e" : @"User List Mode Badge Colors -> +y",
			@"0d6b24b13a7e43211762da51815b2064" : @"User List Mode Badge Colors -> +q",
			@"74f61fa09dce30a57fd7c1331cd99ddb" : @"User List Mode Badge Colors -> +a",
			@"1ceffaa7b5291aa3b15e7e229a50e272" : @"User List Mode Badge Colors -> +o",
			@"4f8e8414604e9ccb757d980991d576a1" : @"User List Mode Badge Colors -> +h",
			@"76248ae19d477d639cb821f1e0a6dae2" : @"User List Mode Badge Colors -> +v",
			@"051baac72009cc4914d1815916e1ed49" : @"Server List Unread Message Count Badge Colors -> Highlight"
		};
	});

	return cachedValues[hashedKey];
}

- (BOOL)keyIsPermittedToBeRemovedThroughCloud:(NSString *)key
{
	/* List of keys that when synced downstream are allowed to be removed
	 from NSUserDefaults if they no longer exist in the cloud. */
	NSParameterAssert(key != nil);

	return ([key isEqualToString:@"User List Mode Badge Colors -> +y"] ||
			[key isEqualToString:@"User List Mode Badge Colors -> +q"] ||
			[key isEqualToString:@"User List Mode Badge Colors -> +a"] ||
			[key isEqualToString:@"User List Mode Badge Colors -> +o"] ||
			[key isEqualToString:@"User List Mode Badge Colors -> +h"] ||
			[key isEqualToString:@"User List Mode Badge Colors -> +v"] ||
			[key isEqualToString:@"Server List Unread Message Count Badge Colors -> Highlight"]);
}

#pragma mark -
#pragma mark Notifications

- (void)syncPreferenceFromCloudNotification:(NSNotification *)aNote
{
	if (self.isTerminated) {
		return;
	}

	NSInteger syncReason =
	[aNote.userInfo integerForKey:NSUbiquitousKeyValueStoreChangeReasonKey];

	if (syncReason == NSUbiquitousKeyValueStoreQuotaViolationChange) {
		[self cloudStorageLimitExceeded];
	} else if (syncReason == NSUbiquitousKeyValueStoreServerChange ||
			   syncReason == NSUbiquitousKeyValueStoreInitialSyncChange)
	{
		self.hasUncommittedDataStoredInCloud = YES;

		NSArray<NSString *> *keysChangedHashed =
		[aNote.userInfo arrayForKey:NSUbiquitousKeyValueStoreChangedKeysKey];

		[self syncPreferencesFromCloud:keysChangedHashed];
	}
}

- (void)localKeysDidChangeNotification:(NSNotification *)aNote
{
	if (self.isTerminated) {
		return;
	}

	if ([TPCPreferences syncPreferencesToTheCloud] == NO) {
		return;
	}

	XRPerformBlockAsynchronouslyOnQueue(self.workerQueue, ^{
		NSString *changedKey = aNote.userInfo[@"changedKey"];

		if (changedKey == nil) {
			return;
		}

		// If the key changed is in the list of the keys being imported at
		// this time, then the key probably changed because we imported it.
		if ([self.remoteKeysBeingSynced containsObject:changedKey]) {
			return;
		}

		[self.keysToRemove removeObject:changedKey];

		[self.keysToSync addObject:changedKey];
	});
}

- (void)cloudStorageLimitExceeded
{
	LogToConsoleError("The cloud storage limit was exceeded");
}

#pragma mark -
#pragma mark Session Management

- (void)iCloudAccountAvailabilityChanged:(NSNotification *)aNote
{
	if (self.isTerminated) {
		return;
	}

	id newToken = RZFileManager().cloudUbiquityIdentityToken;

	id oldToken = self.ubiquityIdentityToken;

	if (newToken && newToken != oldToken) {
		self.pushAllLocalKeysNextSync = YES;
	}

	self.ubiquityIdentityToken = newToken;

	[self setupUbiquitousContainerPath];
}

#pragma mark -
#pragma mark Initialization

- (void)prepareInitialState
{
	LogToConsoleDebug("iCloud: Beginning session");

	self.workerQueue =
	XRCreateDispatchQueueWithPriority("Textual.TPCPreferencesCloudSync.iCloudSyncDispatchQueue", DISPATCH_QUEUE_SERIAL, QOS_CLASS_BACKGROUND);

	self.ubiquityIdentityToken = RZFileManager().cloudUbiquityIdentityToken;

	[self setupUbiquitousContainerPath];

	self.keysToRemove = [NSMutableArray array];
	self.keysToSync = [NSMutableArray array];

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

	self.cloudOneMinuteSyncTimer = syncTimer1;

	NSTimer *syncTimer2 = [NSTimer scheduledTimerWithTimeInterval:_localKeysUpstreamSyncTimerInterval_2
														   target:self
														 selector:@selector(performTenMinuteTimeBasedMaintenance)
														 userInfo:nil
														  repeats:YES];

	self.cloudTenMinuteSyncTimer = syncTimer2;

	[RZNotificationCenter() addObserver:self
							   selector:@selector(syncPreferenceFromCloudNotification:)
								   name:NSUbiquitousKeyValueStoreDidChangeExternallyNotification
								 object:nil];

	[RZUbiquitousKeyValueStore() synchronize];
}

- (void)prepareForApplicationTermination
{
	if (self.isTerminated) {
		return;
	}

	/* The cloud session is closed from within the worker queue so that 
	 any operations that aren't already finished will have time to do so. */
	XRPerformBlockAsynchronouslyOnQueue(self.workerQueue, ^{
		[self _closeCloudSyncSession];
	});
}

- (void)_closeCloudSyncSession
{
	if (self.isTerminated) {
		return;
	}

	LogToConsoleDebug("iCloud: Closing session");

	if ( self.cloudOneMinuteSyncTimer) {
		[self.cloudOneMinuteSyncTimer invalidate];
		 self.cloudOneMinuteSyncTimer = nil;
	}

	if ( self.cloudTenMinuteSyncTimer) {
		[self.cloudTenMinuteSyncTimer invalidate];
		 self.cloudTenMinuteSyncTimer = nil;
	}

	[RZNotificationCenter() removeObserver:self];

	if (self.workerQueue) {
		self.workerQueue = nil;
	}

	self.pushAllLocalKeysNextSync = NO;

	self.keysToRemove = nil;
	self.keysToSync = nil;

	self.remoteKeysBeingSynced = nil;

	self.isSyncingLocalKeysDownstream = NO;
	self.isSyncingLocalKeysUpstream = NO;

	self.ubiquityIdentityToken = nil;

	self.ubiquitousContainerURL = nil;

	self.isTerminated = YES;
}

@end

#endif

NS_ASSUME_NONNULL_END
