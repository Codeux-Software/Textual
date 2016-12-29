/* ********************************************************************* 
                  _____         _               _
                 |_   _|____  _| |_ _   _  __ _| |
                   | |/ _ \ \/ / __| | | |/ _` | |
                   | |  __/>  <| |_| |_| | (_| | |
                   |_|\___/_/\_\\__|\__,_|\__,_|_|

 Copyright (c) 2010 - 2017 Codeux Software, LLC & respective contributors.
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

#import "HLSHistoricLogProcessMain.h"

#import <CoreData/CoreData.h>

#import <CocoaExtensions/CocoaExtensions.h>

NS_ASSUME_NONNULL_BEGIN

@interface HLSHistoricLogProcessMain ()
@property (nonatomic, assign) BOOL isPerformingSave;
@property (nonatomic, strong) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, strong) NSManagedObjectModel *managedObjectModel;
@property (nonatomic, strong) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@property (nonatomic, copy) NSString *savePath;
@end

@implementation HLSHistoricLogProcessMain

- (void)openDatabaseAtPath:(NSString *)path
{
	NSParameterAssert(path != nil);

	LogToConsoleInfo("Opening database at path: %@", path)

	self.savePath = path;

	[self createBaseModel];
}

- (NSFetchRequest *)fetchRequestForChannel:(NSString *)channelId
								fetchLimit:(NSUInteger)fetchLimit
							   limitToDate:(nullable NSDate *)limitToDate
								resultType:(NSFetchRequestResultType)resultType
{
	NSParameterAssert(channelId != nil);

	if (limitToDate == nil) {
		limitToDate = [NSDate distantFuture];
	}

	NSDictionary *substitutionVariables = @{
		@"channel_id" : channelId,
		@"creation_date" : @([limitToDate timeIntervalSince1970])
	};

	NSFetchRequest *fetchRequest =
	[self.managedObjectModel fetchRequestFromTemplateWithName:@"LogLineFetchRequest"
										substitutionVariables:substitutionVariables];

	if (fetchLimit > 0) {
		fetchRequest.fetchLimit = fetchLimit;
	}

	fetchRequest.resultType = resultType;

	return fetchRequest;
}

- (void)_resetDataForChannelUsingBatch:(NSString *)channelId
{
	NSParameterAssert(channelId  != nil);

	NSManagedObjectContext *context = self.managedObjectContext;

	[context performBlockAndWait:^{
		NSFetchRequest *fetchRequest = [self fetchRequestForChannel:channelId
														 fetchLimit:0
														limitToDate:nil
														 resultType:NSManagedObjectResultType];

		NSBatchDeleteRequest *batchDeleteRequest = [[NSBatchDeleteRequest alloc] initWithFetchRequest:fetchRequest];

		batchDeleteRequest.resultType = NSBatchDeleteResultTypeObjectIDs;

		NSError *batchDeleteError = nil;

		NSBatchDeleteResult *batchDeleteResult =
		[context executeRequest:batchDeleteRequest error:&batchDeleteError];

		if (batchDeleteResult == nil) {
			LogToConsoleError("Failed to perform batch delete: %@",
				batchDeleteError.localizedDescription)

			return;
		}

		[NSManagedObjectContext mergeChangesFromRemoteContextSave:@{NSDeletedObjectsKey : batchDeleteResult.result}
													 intoContexts:@[context]];
	}];
}

- (void)_resetDataForChannelUsingEnumeration:(NSString *)channelId
{
	NSParameterAssert(channelId != nil);

	NSManagedObjectContext *context = self.managedObjectContext;

	[context performBlockAndWait:^{
		NSFetchRequest *fetchRequest = [self fetchRequestForChannel:channelId
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

- (void)resetDataForChannel:(NSString *)channelId
{
	LogToConsoleDebug("Resetting the contents of channel: %@", channelId)

	//	if ([XRSystemInformation isUsingOSXElCapitanOrLater]) {
	//		[self _resetDataForChannelUsingBatch:channelId];
	//	} else {
	[self _resetDataForChannelUsingEnumeration:channelId];
	//	}
}

- (void)fetchEntriesForChannel:(NSString *)channelId
					fetchLimit:(NSUInteger)fetchLimit
				   limitToDate:(nullable NSDate *)limitToDate
		   withCompletionBlock:(void (^)(NSArray<TVCLogLineXPC *> *entries))completionBlock
{
	NSParameterAssert(channelId != nil);
	NSParameterAssert(completionBlock != nil);

	NSManagedObjectContext *context = self.managedObjectContext;

	[context performBlockAndWait:^{
		NSFetchRequest *fetchRequest = [self fetchRequestForChannel:channelId
														 fetchLimit:fetchLimit
														limitToDate:limitToDate
														 resultType:NSManagedObjectResultType];

		fetchRequest.includesPropertyValues = YES;

		fetchRequest.sortDescriptors = @[[[NSSortDescriptor alloc] initWithKey:@"creationDate" ascending:YES]];

		NSError *fetchRequestError = nil;

		NSArray<NSManagedObject *> *fetchedObjects = [context executeFetchRequest:fetchRequest error:&fetchRequestError];

		if (fetchedObjects == nil) {
			LogToConsoleError("Error occurred fetching objects: %@",
				fetchRequestError.localizedDescription)

			return;
		}

		LogToConsoleDebug("%ld results fetched for channel %@",
			fetchedObjects.count, channelId)

		@autoreleasepool {
			NSMutableArray<TVCLogLineXPC *> *fetchedEntries = [NSMutableArray arrayWithCapacity:fetchedObjects.count];

			for (NSManagedObject *fetchedObject in fetchedObjects) {
				TVCLogLineXPC *fetchedEntry = [[TVCLogLineXPC alloc] initWithManagedObject:fetchedObject];

				[fetchedEntries addObject:fetchedEntry];
			}

			completionBlock([fetchedEntries copy]);
		}
	}];
}

- (void)writeLogLine:(TVCLogLineXPC *)logLine
{
	NSParameterAssert(logLine != nil);

	NSManagedObjectContext *context = self.managedObjectContext;

	[context performBlockAndWait:^{
		NSEntityDescription *entity = [NSEntityDescription entityForName:@"LogLine" inManagedObjectContext:context];

		NSManagedObject *newEntry = [[NSManagedObject alloc] initWithEntity:entity insertIntoManagedObjectContext:context];

		[newEntry setValue:logLine.creationDate forKey:@"creationDate"];

		[newEntry setValue:logLine.channelId forKey:@"channelId"];

		[newEntry setValue:logLine.data forKey:@"data"];
	}];
}

- (void)createBaseModel
{
	[self createBaseModelWithRecursion:0];
}

- (void)createBaseModelWithRecursion:(NSUInteger)recursionDepth
{
	NSURL *modelPath = [[NSBundle mainBundle] URLForResource:@"HistoricLogFileStorageModel" withExtension:@"momd"];

	NSManagedObjectModel *managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelPath];

	NSPersistentStoreCoordinator *persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:managedObjectModel];

	NSDictionary *pragmaOptions = @{
		@"synchronous" : @"FULL",
		@"journal_mode" : @"DELETE"
	};

	NSDictionary *persistentStoreOptions = @{NSSQLitePragmasOption : pragmaOptions};

	NSURL *persistentStorePath = [NSURL fileURLWithPath:self.savePath];

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
			[self resetDatabase]; // Destroy any data that may exist

			[self createBaseModelWithRecursion:1];
		}

		return;
	}
	else
	{
		NSManagedObjectContext *managedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];

		managedObjectContext.persistentStoreCoordinator = persistentStoreCoordinator;

		managedObjectContext.retainsRegisteredObjects = YES;

		managedObjectContext.undoManager = nil;

		self.managedObjectContext = managedObjectContext;
		self.managedObjectModel = managedObjectModel;

		self.persistentStoreCoordinator = persistentStoreCoordinator;
	}
}

- (void)resetDatabase
{
	NSString *path = self.savePath;

	[[NSFileManager defaultManager] removeItemAtPath:path error:NULL];
	[[NSFileManager defaultManager] removeItemAtPath:[path stringByAppendingString:@"-shm"] error:NULL];
	[[NSFileManager defaultManager] removeItemAtPath:[path stringByAppendingString:@"-wal"] error:NULL];
}

- (void)saveDataWithCompletionBlock:(void (^ _Nullable)(void))completionBlock
{
	if (self.isPerformingSave == NO) {
		self.isPerformingSave = YES;
	} else {
		return;
	}

	NSManagedObjectContext *context = self.managedObjectContext;

	[context performBlock:^{
		if ([context commitEditing] == NO)
		{
			LogToConsoleError("Failed to commit editing")
		}

		if ([context hasChanges])
		{
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

		if (completionBlock) {
			completionBlock();
		}
	}];
}

- (void)resizeDatabaseToConformToRowLimit:(NSUInteger)rowLimit
{
	NSManagedObjectContext *context = self.managedObjectContext;

	[context performBlock:^{
		[self _resizeDatabaseToConformToRowLimit:rowLimit];
	}];
}

- (void)_resizeDatabaseToConformToRowLimit:(NSUInteger)rowLimit
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

	NSString *currentChannelId = nil;

	NSUInteger currentChannelIdCount = 0;

	for (NSManagedObject *object in fetchedObjects) {
		NSString *channelId = [object valueForKey:@"channelId"];

		if (channelId == nil) {
			[context deleteObject:object];

			continue;
		}

		if ([currentChannelId isEqualToString:channelId] == NO) {
			currentChannelId = channelId;

			currentChannelIdCount = 0;
		}

		if (currentChannelIdCount > rowLimit) {
			[context deleteObject:object];
			
			LogToConsoleDebug("Deleting object %@ in %@",
				object.description, channelId)
		}
		
		currentChannelIdCount += 1;
	}
	
	LogToConsoleInfo("Finished trimming Core Data store")
}

@end

NS_ASSUME_NONNULL_END
