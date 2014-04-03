/* ********************************************************************* 
       _____        _               _    ___ ____   ____
      |_   _|___  _| |_ _   _  __ _| |  |_ _|  _ \ / ___|
       | |/ _ \ \/ / __| | | |/ _` | |   | || |_) | |
       | |  __/>  <| |_| |_| | (_| | |   | ||  _ <| |___
       |_|\___/_/\_\\__|\__,_|\__,_|_|  |___|_| \_\\____|

 Copyright (c) 2010 — 2014 Codeux Software & respective contributors.
     Please see Acknowledgements.pdf for additional information.

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

@interface TVCLogControllerHistoricLogFile ()
@property (nonatomic, assign) BOOL isPerformingSave;
@property (nonatomic, assign) BOOL hasPendingAutosaveTimer;
@property (nonatomic, strong) NSManagedObjectModel *managedObjectModel;
@property (nonatomic, strong) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@end

@implementation TVCLogControllerHistoricLogFile

@synthesize managedObjectContext = _managedObjectContext;

#pragma mark -
#pragma mark Public API

+ (TVCLogControllerHistoricLogFile *)sharedInstance
{
	/* Create a copy of self and maintain as static reference. */
	static id sharedSelf = nil;

	static dispatch_once_t onceToken;

	dispatch_once(&onceToken, ^{
		sharedSelf = [self new];
	});

	return sharedSelf;
}

- (void)resetData
{
#ifndef TEXTUAL_BUILT_WITH_CORE_DATA_DISABLED
	NSString *oldPath = [self databaseSavePath];

	NSString *auxfile1 = [oldPath stringByAppendingString:@"-wal"];
	NSString *auxfile2 = [oldPath stringByAppendingString:@"-shm"];

	[RZFileManager() removeItemAtPath:oldPath error:NULL]; // Destroy archive file completely.
	[RZFileManager() removeItemAtPath:auxfile1 error:NULL]; // Destroy archive file completely.
	[RZFileManager() removeItemAtPath:auxfile2 error:NULL]; // Destroy archive file completely.
#endif
}

- (NSFetchRequest *)fetchRequestForClient:(IRCClient *)client
								inChannel:(IRCChannel *)channel
							   fetchLimit:(NSInteger)maxEntryCount
				   includesPendingChanges:(BOOL)includesPendingChanges
{
#ifndef TEXTUAL_BUILT_WITH_CORE_DATA_DISABLED
	/* What are we fetching for? */
	PointerIsEmptyAssertReturn(client, nil);

	/* Build base model. */
	NSMutableDictionary *fetchVariables = [NSMutableDictionary dictionary];

	/* Channel ID. */
	if (channel) {
		[fetchVariables setObject:[channel uniqueIdentifier] forKey:@"channel_id"];
	} else {
		[fetchVariables setObject:[NSNull null] forKey:@"channel_id"];
	}

	/* Client ID. */
	[fetchVariables setObject:[client uniqueIdentifier] forKey:@"client_id"];

	/* Request actual predicate. */
	NSFetchRequest *fetchRequest = [_managedObjectModel fetchRequestFromTemplateWithName:@"LogLineFetchRequest"
																   substitutionVariables:fetchVariables];

	/* Define sort order. */
	[fetchRequest setSortDescriptors:@[[self managedSortDescriptor]]];

	/* Return types. */
	[fetchRequest setIncludesPendingChanges:includesPendingChanges];
	[fetchRequest setReturnsObjectsAsFaults:YES];
	[fetchRequest setIncludesPropertyValues:YES];

	[fetchRequest setResultType:NSManagedObjectIDResultType];

	/* Define match limit. */
	if (maxEntryCount > 0) {
		[fetchRequest setFetchLimit:maxEntryCount];
	}

	/* We're done. */
	return fetchRequest;
#else
	return nil;
#endif
}

- (void)resetDataForEntriesMatchingClient:(IRCClient *)client inChannel:(IRCChannel *)channel
{
#ifndef TEXTUAL_BUILT_WITH_CORE_DATA_DISABLED
	[_managedObjectContext performBlock:^{
		/* Build fetch request. */
		NSFetchRequest *fetchRequest = [self fetchRequestForClient:client
														 inChannel:channel
														fetchLimit:0
											includesPendingChanges:YES];

		/* Gather results. */
		NSArray *objects = [_managedObjectContext executeFetchRequest:fetchRequest error:NULL];

		/* Delete objects. */
		for (NSManagedObjectID *objectID in objects) {
			NSManagedObject *managedObject = [_managedObjectContext objectWithID:objectID];

			[_managedObjectContext deleteObject:managedObject];
		}
	}];
#endif
}

- (void)entriesForClient:(IRCClient *)client
			   inChannel:(IRCChannel *)channel
			  fetchLimit:(NSInteger)maxEntryCount
	 withCompletionBlock:(void (^)(NSManagedObjectContext *context, NSArray *objects))completionBlock
{
#ifndef TEXTUAL_BUILT_WITH_CORE_DATA_DISABLED
	/* What are we fetching for? */
	if (PointerIsEmpty(client)) {
		completionBlock(nil, nil);

		return;
	}

	/* Create private dispatch queue. */
	NSManagedObjectContext *backgroundContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];

	/* Add observer. */
	id saveObserver = [RZNotificationCenter() addObserverForName:NSManagedObjectContextDidSaveNotification
														  object:backgroundContext
														   queue:nil
													  usingBlock:^(NSNotification *note) {
														  [_managedObjectContext mergeChangesFromContextDidSaveNotification:note];
													  }];

	/* Lock context. */
	[_persistentStoreCoordinator lock];

	/* Perform block. */
	[backgroundContext performBlockAndWait:^{
		/* Pass information. */
		[backgroundContext setPersistentStoreCoordinator:_persistentStoreCoordinator];

		/* Perform fetch. */
		NSFetchRequest *fetchRequest = [self fetchRequestForClient:client
														 inChannel:channel
														fetchLimit:maxEntryCount
											includesPendingChanges:NO];

		NSError *fetchError;

		NSArray *fetchResults = [backgroundContext executeFetchRequest:fetchRequest error:&fetchError];

		/* nil if we had error… */
		if (fetchResults) {
			/* Our sort descriptor places newest lines at the top and oldest
			 at the bottom. This is done so that when a fetch limit is supplied,
			 the fetch limit only applies to the newest lines without us having
			 to supply an offset. Obivously, we do not want newest lines first
			 though, so before passing to the callback, we reverse. */
			NSEnumerator *reverseEnum = [fetchResults reverseObjectEnumerator];

			NSArray *finalData = [reverseEnum allObjects];

			/* Call completion block. */
			completionBlock(backgroundContext, finalData);
		} else {
			DebugLogToConsole(@"Fetch request failed for channel %@ on client %@ with error: %@", channel, client, [fetchError localizedDescription]);

			completionBlock(nil, nil);
		}
	}];

	/* Unlock context. */
	[_persistentStoreCoordinator unlock];

	/* Remove observer. */
	[RZNotificationCenter() removeObserver:saveObserver];

	/* Cleanup. */
	backgroundContext = nil;
#else
	completionBlock(nil, nil);
#endif
}

#pragma mark -
#pragma mark Core Data Model

- (void)createBaseModel
{
	[self createBaseModel:NO];
}

- (void)createBaseModel:(BOOL)isSecondRun
{
#ifndef TEXTUAL_BUILT_WITH_CORE_DATA_DISABLED
	/* Find the location of the file. */
	NSString *path = [RZMainBundle() pathForResource:@"LogControllerStorageModel" ofType:@"mom"];

	NSURL *url = [NSURL fileURLWithPath:path];

	/* Create the model. */
	_managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:url];

	/* Create persistent store. */
	_persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:_managedObjectModel];

	/* Add persistent store. */
	NSError *addErr = nil;

	/* Define save path. */
	NSString *savePath = [self databaseSavePath];

	NSURL *saveurl = [NSURL fileURLWithPath:savePath];

	/* Perform add. */
	NSDictionary *pragmaOptions = @{@"synchronous" : @"OFF", @"journal_mode" : @"WAL"};
	NSDictionary *storeOptions = @{NSSQLitePragmasOption : pragmaOptions};

	id result = [_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType
														  configuration:nil
																	URL:saveurl
																options:storeOptions
																  error:&addErr];

	/* Was there an error? */
	if (result == nil) {
		LogToConsole(@"Error Creating Persistent Store: %@", [addErr localizedDescription]);

		if (isSecondRun == NO) {
			LogToConsole(@"Attempting to create a new persistent store in a new path…");

			/* If we failed to load our store, we create a brand new one at a new path
			 incase the old one is corrupted. We also erase the old database to not allow
			 the file to just hang on the OS. */
			[self resetData]; // Destroy old.

			[self createNewDatabaseSavePath]; // Create new path.

			[self createBaseModel:YES]; // Run creation process again.
		}

		_persistentStoreCoordinator = nil; // Destroy.
	} else {
		/* Create primary managed object. */
		_managedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];

		[_managedObjectContext setPersistentStoreCoordinator:_persistentStoreCoordinator];
		[_managedObjectContext setUndoManager:nil];
		[_managedObjectContext setRetainsRegisteredObjects:NO];
	}

	/* Continue work. */
	if (_managedObjectContext == nil) {
		NSAssert(NO, @"Missing managed object context.");
	} else {
		/* Define default values. */
		_hasPendingAutosaveTimer = NO;
		_isPerformingSave = NO;

		/* Start save timer. */
		[self handleManagedObjectContextChangeTimerInitializer];
	}
#endif
}

- (void)handleManagedObjectContextChangeTimerInitializer
{
#ifndef TEXTUAL_BUILT_WITH_CORE_DATA_DISABLED
	/* Cancel any previous running timers. */
	if (_hasPendingAutosaveTimer) {
		[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(saveData) object:nil];

		_hasPendingAutosaveTimer = NO;
	}

	/* Auto save thirty seconds after last change. */
	_hasPendingAutosaveTimer = YES;

	[self performSelector:@selector(saveData) withObject:nil afterDelay:300.0];
#endif
}

- (void)createNewDatabaseSavePath
{
#ifndef TEXTUAL_BUILT_WITH_CORE_DATA_DISABLED
	/* Filename is just a UUID. Does not need anything more than that… */

	[RZUserDefaults() setObject:[NSString stringWithUUID] forKey:@"TVCLogControllerHistoricLogFileSavePath"];
#else
	return nil;
#endif
}

- (NSString *)databaseSavePath
{
#ifndef TEXTUAL_BUILT_WITH_CORE_DATA_DISABLED
	NSString *filename = [RZUserDefaults() objectForKey:@"TVCLogControllerHistoricLogFileSavePath"];

	if (filename == nil) {
		/* Use old filename for Textaul v4.1.3. */
		[RZUserDefaults() setObject:@"logControllerHistoricLog_v001.sqlite" forKey:@"TVCLogControllerHistoricLogFileSavePath"];

		return [self databaseSavePath];
	}

	NSString *savepath = [[TPCPreferences applicationCachesFolderPath] stringByAppendingPathComponent:filename];

	return savepath;
#else
	return nil;
#endif
}

- (BOOL)isPerformingSave
{
#ifndef TEXTUAL_BUILT_WITH_CORE_DATA_DISABLED
	return _isPerformingSave;
#else
	return nil;
#endif
}

- (void)saveData
{
#ifndef TEXTUAL_BUILT_WITH_CORE_DATA_DISABLED
	/* What are we saving to? */
	PointerIsEmptyAssert(_managedObjectContext);

	/* Cancel any previous running timers incase this is manual save. */
	[self handleManagedObjectContextChangeTimerInitializer];

	[_managedObjectContext performBlock:^{
		/* Do we have a save running? */
		NSAssertReturn(_isPerformingSave == NO)

		/* Continue with save operation. */
		_isPerformingSave = YES;

		/* Do changes even exist? */
		if ([_managedObjectContext commitEditing]) {
			if ([_managedObjectContext hasChanges]) {
				if ([_managedObjectContext save:NULL] == NO) {
					[_managedObjectContext reset];
				}
			}
		}

		/* Reset state. */
		_isPerformingSave = NO;
	}];
#endif
}

- (NSSortDescriptor *)managedSortDescriptor
{
#ifndef TEXTUAL_BUILT_WITH_CORE_DATA_DISABLED
	return [[NSSortDescriptor alloc] initWithKey:@"creationDate" ascending:NO];
#else
	return nil;
#endif
}

@end
