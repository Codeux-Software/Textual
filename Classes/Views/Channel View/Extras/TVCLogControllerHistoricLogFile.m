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
@property (nonatomic, strong) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@property (nonatomic, strong) NSManagedObjectModel *managedObjectModel;
@property (nonatomic, strong) NSSortDescriptor *managedSortDescriptor;
@end

@implementation TVCLogControllerHistoricLogFile

@synthesize managedObjectContext = _managedObjectContext;

#pragma mark -
#pragma mark Public API

+ (TVCLogControllerHistoricLogFile *)sharedInstance
{
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
	[RZFileManager() removeItemAtPath:[self databaseSavePath] error:NULL]; // Destroy archive file completely.
#endif
}

- (NSFetchRequest *)fetchRequestForClient:(IRCClient *)client
								inChannel:(IRCChannel *)channel
							   fetchLimit:(NSInteger)maxEntryCount
								afterDate:(NSDate *)referenceDate
						   returnIsObject:(BOOL)returnObjects
{
#ifndef TEXTUAL_BUILT_WITH_CORE_DATA_DISABLED
	/* What are we fetching for? */
	PointerIsEmptyAssertReturn(client, nil);

	/* Gather relevant information. */
	NSString *clientID = [client uniqueIdentifier];
	NSString *channelID = nil;

	if (channel) {
		channelID = [channel uniqueIdentifier];
	}

	/* Build base model. */
	NSMutableDictionary *fetchVariables = [NSMutableDictionary dictionary];

	/* Reference date. */
	if (referenceDate) {
		[fetchVariables setObject:referenceDate forKey:@"creation_date"];
	} else {
		/* There should be no records younger than this… */

		[fetchVariables setObject:[NSDate dateWithTimeIntervalSinceReferenceDate:0] forKey:@"creation_date"];
	}

	/* Channel ID. */
	if (channelID) {
		[fetchVariables setObject:channelID forKey:@"channel_id"];
	} else {
		[fetchVariables setObject:[NSNull null] forKey:@"channel_id"];
	}

	/* Client ID. */
	[fetchVariables setObject:clientID forKey:@"client_id"];

	/* Request actual predicate. */
	NSFetchRequest *fetchRequest = [self.managedObjectModel fetchRequestFromTemplateWithName:@"LogLineFetchRequest"
																	   substitutionVariables:fetchVariables];

	/* Define sort order. */
	[fetchRequest setSortDescriptors:@[self.managedSortDescriptor]];

	/* Return types. */
	[fetchRequest setIncludesPendingChanges:NO];
	[fetchRequest setReturnsObjectsAsFaults:YES];

	/* When returning ID, Core Data will need property values
	 to properly perform sort or it will just do a best guess. */
	if (returnObjects == NO) {
		[fetchRequest setResultType:NSManagedObjectIDResultType];
		[fetchRequest setIncludesPropertyValues:YES];
	} else {
		[fetchRequest setResultType:NSManagedObjectResultType];
		[fetchRequest setIncludesPropertyValues:NO];
	}

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
														 afterDate:nil
													returnIsObject:YES];

		/* Gather results. */
		NSArray *objects = [_managedObjectContext executeFetchRequest:fetchRequest error:NULL];

		/* Delete objects. */
		for (TVCLogLine *line in objects) {
			[_managedObjectContext deleteObject:line];
		}
	}];
#endif
}

- (void)entriesForClient:(IRCClient *)client
			   inChannel:(IRCChannel *)channel
			  fetchLimit:(NSInteger)maxEntryCount
			   afterDate:(NSDate *)referenceDate
	 withCompletionBlock:(void (^)(NSManagedObjectContext *context, NSArray *objects))completionBlock
{
#ifndef TEXTUAL_BUILT_WITH_CORE_DATA_DISABLED
	/* What are we fetching for? */
	PointerIsEmptyAssert(client);

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
	[_managedObjectContext lock];

	[backgroundContext lock];

	/* Perform block. */
	[backgroundContext performBlockAndWait:^{
		/* Pass information. */
		[backgroundContext setPersistentStoreCoordinator:_persistentStoreCoordinator];

		/* Perform fetch. */
		NSFetchRequest *fetchRequest = [self fetchRequestForClient:client
														 inChannel:channel
														fetchLimit:maxEntryCount
														 afterDate:referenceDate
													returnIsObject:NO];

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
			LogToConsole(@"Fetch request failed for channel %@ on client %@ with error: %@", channel, client, [fetchError localizedDescription]);

			completionBlock(nil, nil);
		}
	}];

	/* Unlock context. */
	[_persistentStoreCoordinator unlock];
	[_managedObjectContext unlock];

	[backgroundContext unlock];

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

- (id)init
{
	if (self = [super init]) {
#ifndef TEXTUAL_BUILT_WITH_CORE_DATA_DISABLED
		/* Call variables to initalize objects. */
		(void)self.managedObjectModel;
		(void)self.persistentStoreCoordinator;
		(void)self.managedObjectContext;

		/* Listen for changes. */
		self.hasPendingAutosaveTimer = NO;
		self.isPerformingSave = NO;

		[self handleManagedObjectContextChangeTimerInitializer];
#endif

		/* Return ourself. */
		return self;
	}

	return nil;
}

- (void)handleManagedObjectContextChangeTimerInitializer
{
#ifndef TEXTUAL_BUILT_WITH_CORE_DATA_DISABLED
	/* Cancel any previous running timers. */
	if (self.hasPendingAutosaveTimer) {
		[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(saveData) object:nil];

		self.hasPendingAutosaveTimer = NO;
	}

	/* Auto save thirty seconds after last change. */
	self.hasPendingAutosaveTimer = YES;

	[self performSelector:@selector(saveData) withObject:nil afterDelay:300.0];
#endif
}

- (NSString *)databaseSavePath
{
#ifndef TEXTUAL_BUILT_WITH_CORE_DATA_DISABLED
	return [[TPCPreferences applicationCachesFolderPath] stringByAppendingPathComponent:@"logControllerHistoricLog_v001.sqlite"];
#else
	return nil;
#endif
}

- (BOOL)hasPersistentStore
{
#ifndef TEXTUAL_BUILT_WITH_CORE_DATA_DISABLED
	NSArray *persistentStores = [self.persistentStoreCoordinator persistentStores];

	return ([persistentStores count] > 0);
#else
	return NO;
#endif
}

- (BOOL)isPerformingSave
{
	return _isPerformingSave;
}

- (void)saveData
{
#ifndef TEXTUAL_BUILT_WITH_CORE_DATA_DISABLED
	/* Cancel any previous running timers incase this is manual save. */
	[self handleManagedObjectContextChangeTimerInitializer];

	[_managedObjectContext performBlock:^{
		/* Do we have a save running? */
		if (self.isPerformingSave) {
			return; // Cancel save.
		}

		/* Continue with save operation. */
		self.isPerformingSave = YES;

		/* What are we saving to? */
		if ([self hasPersistentStore] == NO) {
			self.isPerformingSave = NO;

			return; // Cancel save.
		}

		/* Do changes even exist? */
		if ([_managedObjectContext commitEditing]) {
			if ([_managedObjectContext hasChanges]) {
				if ([_managedObjectContext save:NULL] == NO) {
					[_managedObjectContext reset];
				}
			}
		}

		/* Reset state. */
		self.isPerformingSave = NO;
	}];
#endif
}

- (NSManagedObjectModel *)managedObjectModel
{
	/* We do not need to do work if this property exists already. */
	PointerIsNotEmptyAssertReturn(_managedObjectModel, _managedObjectModel);

	/* Find the location of the file. */
	NSString *path = [RZMainBundle() pathForResource:@"LogControllerStorageModel" ofType:@"mom"];

	/* Create the model. */
	NSURL *url = [NSURL fileURLWithPath:path];

	_managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:url];

	/* Return the model. */
	return _managedObjectModel;
}

- (NSPersistentStoreCoordinator *)persistentStoreCoordinator;
{
	/* We do not need to do work if this property exists already. */
	PointerIsNotEmptyAssertReturn(_persistentStoreCoordinator, _persistentStoreCoordinator);

	/* Add model to persistent store. */
	NSManagedObjectModel *mom = [self managedObjectModel];

	_persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:mom];

	/* Try to add new store. */
	if ([self addPersistentStoreToCoordinator] == NO) {
		/* There was an error adding. */

		_persistentStoreCoordinator = nil;
	}

	/* Return new store. */
	return _persistentStoreCoordinator;
}

- (BOOL)addPersistentStoreToCoordinator
{
	/* Try to create the actual persistent store. */
	NSError *addErr = nil;

	/* Define save path. */
	NSString *savePath = [self databaseSavePath];

	NSURL *url = [NSURL fileURLWithPath:savePath];

	/* Perform add. */

	NSDictionary *pragmaOptions = @{@"synchronous" : @"OFF", @"journal_mode" : @"WAL"};
	NSDictionary *storeOptions = @{NSSQLitePragmasOption : pragmaOptions};

	id result = [_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType
														  configuration:nil
																	URL:url
																options:storeOptions
																  error:&addErr];

	/* Was there an error? */
	if (result == nil) {
		LogToConsole(@"Error Creating Persistent Store: %@", [addErr localizedDescription]);

		return NO; /* Return error. */
	}

	/* Return success. */
	return YES;
}

- (NSManagedObjectContext *)managedObjectContext
{
	/* We do not need to do work if this property exists already. */
	PointerIsNotEmptyAssertReturn(_managedObjectContext, _managedObjectContext);

	/* Create the context. */
	NSPersistentStoreCoordinator *coord = [self persistentStoreCoordinator];

	PointerIsEmptyAssertReturn(coord, nil);

	 _managedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];

	[_managedObjectContext setPersistentStoreCoordinator:coord];
	[_managedObjectContext setUndoManager:nil];
	[_managedObjectContext setRetainsRegisteredObjects:NO];

	return _managedObjectContext;
}

- (NSSortDescriptor *)managedSortDescriptor
{
#ifndef TEXTUAL_BUILT_WITH_CORE_DATA_DISABLED
	/* We do not need to do work if this property exists already. */
	PointerIsNotEmptyAssertReturn(_managedSortDescriptor, _managedSortDescriptor);

	/* Create new sort descriptor. */
	_managedSortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"creationDate" ascending:NO];

	return _managedSortDescriptor;
#else
	return nil;
#endif
}

@end
