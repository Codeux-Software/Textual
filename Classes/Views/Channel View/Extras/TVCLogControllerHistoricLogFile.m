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

NS_ASSUME_NONNULL_BEGIN

@interface TVCLogControllerHistoricLogFile ()
@property (nonatomic, assign) BOOL isPerformingSave;
@property (nonatomic, strong) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, strong) NSManagedObjectModel *managedObjectModel;
@property (nonatomic, strong) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@property (nonatomic, strong) TLOTimer *saveTimer;
@end

@implementation TVCLogControllerHistoricLogFile

#pragma mark -
#pragma mark Public API

+ (TVCLogControllerHistoricLogFile *)sharedInstance
{
	static id sharedSelf = nil;

	static dispatch_once_t onceToken;

	dispatch_once(&onceToken, ^{
		sharedSelf = [[self alloc] init];

		[sharedSelf prepareInitialState];
	});

	return sharedSelf;
}

- (void)prepareInitialState
{
	[self createBaseModel];

	TLOTimer *saveTimer = [TLOTimer new];

	saveTimer.target = self;
	saveTimer.action = @selector(saveData:);
	saveTimer.repeatTimer = YES;

	[saveTimer start:(60 * 15)]; //  15 minutes

	self.saveTimer = saveTimer;
}

- (NSFetchRequest *)fetchRequestForChannel:(IRCChannel *)channel
								fetchLimit:(NSUInteger)fetchLimit
							   limitToDate:(nullable NSDate *)limitToDate
								resultType:(NSFetchRequestResultType)resultType
{
	NSParameterAssert(channel != nil);

	if (limitToDate == nil) {
		limitToDate = [NSDate distantFuture];
	}

	NSDictionary *substitutionVariables = @{
		@"channel_id" : channel.uniqueIdentifier,
		@"creation_date" : @([limitToDate timeIntervalSince1970])
	};

	NSFetchRequest *fetchRequest =
	[self.managedObjectModel fetchRequestFromTemplateWithName:@"LogLineFetchRequest"
										substitutionVariables:substitutionVariables];

	if (fetchLimit > 0) {
		fetchRequest.fetchLimit = fetchLimit;
	}

	fetchRequest.resultType = resultType;

	fetchRequest.sortDescriptors = @[[[NSSortDescriptor alloc] initWithKey:@"creationDate" ascending:YES]];

	return fetchRequest;
}

- (void)resetData
{
	LogToConsoleDebug("Resetting data")

	NSString *oldPath = [self databaseSavePath];

	[RZFileManager() removeItemAtPath:oldPath error:NULL];

	[RZFileManager() removeItemAtPath:[oldPath stringByAppendingString:@"-wal"] error:NULL];
	[RZFileManager() removeItemAtPath:[oldPath stringByAppendingString:@"-shm"] error:NULL];
}

- (void)_resetDataForChannelUsingBatch:(IRCChannel *)channel
{
	NSParameterAssert(channel  != nil);

	NSManagedObjectContext *context = self.managedObjectContext;

	[context performBlockAndWait:^{
		NSFetchRequest *fetchRequest = [self fetchRequestForChannel:channel
														 fetchLimit:0
														limitToDate:nil
														 resultType:NSManagedObjectIDResultType];

		NSBatchDeleteRequest *batchDeleteRequest = [[NSBatchDeleteRequest alloc] initWithFetchRequest:fetchRequest];

		batchDeleteRequest.resultType = NSBatchDeleteResultTypeObjectIDs;

		NSError *batchDeleteError = nil;

		NSBatchDeleteResult *batchDeleteResult =
		[self.persistentStoreCoordinator executeRequest:batchDeleteRequest
											withContext:context
												  error:&batchDeleteError];

		if (batchDeleteResult == nil) {
			LogToConsoleError("Failed to perform batch delete: %@",
							  batchDeleteError.localizedDescription)
		}

//		[NSManagedObjectContext mergeChangesFromRemoteContextSave:@{NSDeletedObjectsKey : batchDeleteResult.result}
//													 intoContexts:@[context]];

		[context refreshAllObjects];
	}];
}

- (void)_resetDataForChannelUsingEnumeration:(IRCChannel *)channel
{
	NSParameterAssert(channel != nil);

	NSManagedObjectContext *context = self.managedObjectContext;

	[context performBlockAndWait:^{
		NSFetchRequest *fetchRequest = [self fetchRequestForChannel:channel
														 fetchLimit:0
														limitToDate:nil
														 resultType:NSManagedObjectResultType];

		NSError *fetchRequestError = nil;

		NSArray *fetchedObjects = [context executeFetchRequest:fetchRequest error:&fetchRequestError];

		if (fetchedObjects == nil) {
			LogToConsoleError("Error occurred fetching objects: %@",
							  fetchRequestError.localizedDescription)

			return;
		}

		for (NSManagedObject *object in fetchedObjects) {
			[context deleteObject:object];
		}
	}];
}

- (void)resetDataForChannel:(IRCChannel *)channel
{
	LogToConsoleDebug("Resetting the contents of channel: %@", channel.description)

	if ([XRSystemInformation isUsingOSXElCapitanOrLater]) {
		[self _resetDataForChannelUsingBatch:channel];
	} else {
		[self _resetDataForChannelUsingEnumeration:channel];
	}
}

- (void)fetchEntriesForChannel:(IRCChannel *)channel
					fetchLimit:(NSUInteger)fetchLimit
				   limitToDate:(nullable NSDate *)limitToDate
		   withCompletionBlock:(void (^)(NSArray<TVCLogLineManaged *> *entries))completionBlock
{
	NSParameterAssert(channel != nil);
	NSParameterAssert(completionBlock != nil);

	NSManagedObjectContext *context = self.managedObjectContext;

	[context performBlockAndWait:^{
		NSFetchRequest *fetchRequest = [self fetchRequestForChannel:channel
														 fetchLimit:0
														limitToDate:limitToDate
														 resultType:NSManagedObjectResultType];

		NSError *fetchRequestError = nil;

		NSArray *fetchedObjects = [context executeFetchRequest:fetchRequest error:&fetchRequestError];

		if (fetchedObjects == nil) {
			LogToConsoleError("Error occurred fetching objects: %@",
				fetchRequestError.localizedDescription)

			return;
		}

		LogToConsoleDebug("%ld results fetched for channel %@",
			fetchedObjects.count, channel.description)

		completionBlock(fetchedObjects);
	}];
}

- (void)writeNewEntryWithLogLine:(TVCLogLine *)logLine inChannel:(IRCChannel *)channel
{
	NSParameterAssert(logLine != nil);
	NSParameterAssert(channel != nil);

	NSManagedObjectContext *context = self.managedObjectContext;

	TVCLogLineManaged *newEntry =
	[[TVCLogLineManaged alloc] initWithLogLine:logLine
									 inChannel:channel
									   context:context];

	[context performBlockAndWait:^{
		[context insertObject:newEntry];
	}];
}

#pragma mark -
#pragma mark Core Data Model

- (void)createBaseModel
{
	[self createBaseModelWithRecursion:0];
}

- (void)createBaseModelWithRecursion:(NSUInteger)recursionDepth
{
	NSURL *modelPath = [RZMainBundle() URLForResource:@"LogControllerStorageModel" withExtension:@"momd"];

	NSManagedObjectModel *managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelPath];

	NSPersistentStoreCoordinator *persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:managedObjectModel];

	NSDictionary *pragmaOptions = @{
		@"synchronous" : @"FULL",
		@"journal_mode" : @"WAL"
	};

	NSDictionary *persistentStoreOptions = @{NSSQLitePragmasOption : pragmaOptions};

	NSURL *persistentStorePath = [NSURL fileURLWithPath:[self databaseSavePath]];

	NSError *addPersistentStoreError = nil;

	NSPersistentStore *persistentStore =
	[persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType
											 configuration:nil
													   URL:persistentStorePath
												   options:persistentStoreOptions
													 error:&addPersistentStoreError];

	if (persistentStore == nil)
	{
		LogToConsoleError("Error Creating Persistent Store: %@",
			addPersistentStoreError.localizedDescription)

		if (recursionDepth == 0) {
			LogToConsoleInfo("Attempting to create a new persistent store")

			/* If we failed to load our store, we create a brand new one at a new path
			 incase the old one is corrupted. We also erase the old database to not allow
			 the file to just hang on the OS. */
			[self resetData]; // Destroy any data that may exist

			[self createBaseModelWithRecursion:1];
		}

		return;
	}
	else
	{
		NSManagedObjectContext *managedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];

		managedObjectContext.persistentStoreCoordinator = persistentStoreCoordinator;

		managedObjectContext.retainsRegisteredObjects = NO;

		managedObjectContext.undoManager = nil;

		self.managedObjectContext = managedObjectContext;
		self.managedObjectModel = managedObjectModel;

		self.persistentStoreCoordinator = persistentStoreCoordinator;
	}
}

- (NSString *)databaseSavePath
{
	NSString *filename = [RZUserDefaults() objectForKey:@"TVCLogControllerHistoricLogFileSavePath_v2"];

	if (filename == nil) {
		filename = [NSString stringWithFormat:@"logControllerHistoricLog_%@.sqlite", [NSString stringWithUUID]];

		[RZUserDefaults() setObject:filename forKey:@"TVCLogControllerHistoricLogFileSavePath_v2"];
	}

	NSString *sourcePath = [TPCPathInfo applicationCachesFolderPath];

	return [sourcePath stringByAppendingPathComponent:filename];
}

- (BOOL)isSaving
{
	return self.isPerformingSave;
}

- (void)prepareForApplicationTermination
{
	[self saveDataDuringTermination:YES];
}

- (void)saveData
{
	[self saveDataDuringTermination:NO];
}

- (void)saveDataDuringTermination:(BOOL)duringTermination
{
	NSManagedObjectContext *context = self.managedObjectContext;

	[context performBlock:^{
		if (self.isPerformingSave == NO) {
			self.isPerformingSave = YES;
		} else {
			return;
		}

		if ([context commitEditing] == NO)
		{
			LogToConsoleError("Failed to commit editing")
		}
		else if ([context hasChanges])
		{
			/* Truncate database before saving it */
			[self trimStoreBeforeSaving];

			NSError *saveError = nil;

			if ([context save:&saveError] == NO) {
				LogToConsoleError("Failed to perform save: %@",
					saveError.localizedDescription)
			} else {
				LogToConsoleInfo("Performed save")
			}
		} else {
			LogToConsoleInfo("Did not perform save because nothing has changed")
		}

		self.isPerformingSave = NO;
	}];
}

- (void)saveData:(id)sender
{
	[self saveData];
}

- (void)trimStoreBeforeSaving
{
	/* To keep the store from going without check, we trim it here, ever so often. 
	 To trim it, we first sort the entries by the channelId, then sort those from 
	 the newest to oldest. Once we reach an old record that exceeds a specific 
	 size (see macro at top of file), then we delete it and everything that follows. */
	NSFetchRequest *fetchRequest =
	[[self.managedObjectModel fetchRequestTemplateForName:@"LogLineFetchRequestForTrimming"] copy];

	fetchRequest.sortDescriptors =
	@[[[NSSortDescriptor alloc] initWithKey:@"channelId" ascending:NO],
	  [[NSSortDescriptor alloc] initWithKey:@"creationDate" ascending:NO]];

	NSManagedObjectContext *context = self.managedObjectContext;

	NSError *fetchRequestError = nil;

	NSArray *fetchedObjects = [context executeFetchRequest:fetchRequest error:&fetchRequestError];

	if (fetchedObjects == nil) {
		LogToConsoleError("Error occurred fetching objects: %@",
			fetchRequestError.localizedDescription)

		return;
	}

	NSUInteger channelsCountMaximum = MIN([TPCPreferences scrollbackLimit], [TPCPreferences scrollbackHistoryLimit]);

	LogToConsoleInfo("Maximum line count per-channel is: %ld",
		channelsCountMaximum)

	NSMutableDictionary<NSString *, NSNumber *> *channelCounts = [NSMutableDictionary dictionary];

	for (NSManagedObject *object in fetchedObjects) {
		NSString *channelId = [object valueForKey:@"channelId"];

		if (channelId == nil) {
			[context deleteObject:object];

			continue;
		}

		NSNumber *channelCount = channelCounts[channelId];

		if (channelCount == nil) {
			channelCounts[channelId] = @(1);
		} else {
			channelCounts[channelId] = @(channelCount.unsignedIntegerValue + 1);
		}

		if (channelCount.unsignedIntegerValue > channelsCountMaximum) {
			[context deleteObject:object];

			LogToConsoleDebug("Deleting object %@ in %@",
				object.description, channelId.description)
		}
	}

	LogToConsoleInfo("Finished trimming Core Data store")
}

@end

NS_ASSUME_NONNULL_END
