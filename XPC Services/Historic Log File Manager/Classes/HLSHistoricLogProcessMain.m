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

NS_ASSUME_NONNULL_BEGIN

@interface HLSHistoricLogProcessMain ()
@property (nonatomic, assign) BOOL isPerformingSave;
@property (nonatomic, strong) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, strong) NSManagedObjectModel *managedObjectModel;
@property (nonatomic, strong) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@property (nonatomic, copy) NSString *savePath;
/* contextObjects is mutable. It should only be accessed in a queue. Use the global context's queue. */
@property (nonatomic, strong) NSMutableDictionary<NSString *, HLSHistoricLogChannelContext *> *contextObjects;
@property (nonatomic, assign) NSUInteger maximumLineCount;
@property (nonatomic, strong) dispatch_source_t saveTimer;
@end

@implementation HLSHistoricLogProcessMain

- (instancetype)init
{
	if ((self = [super init])) {
		[self prepareInitialState];
		
		return self;
	}
	
	return nil;
}

- (void)prepareInitialState
{
	self.contextObjects = [NSMutableDictionary dictionary];
	
	self.maximumLineCount = 100;
}

- (void)openDatabaseAtPath:(NSString *)path withCompletionBlock:(void (NS_NOESCAPE ^ _Nullable)(BOOL))completionBlock
{
	NSParameterAssert(path != nil);
	
	LogToConsoleInfo("Opening database at path: %@", path);
	
	self.savePath = path;
	
	BOOL success = [self _createBaseModel];
	
	if (completionBlock) {
		completionBlock(success);
	}
	
	if (success == NO) {
		return;
	}
	
	[self _rescheduleSave];
}

- (void)setMaximumLineCount:(NSUInteger)maximumLineCount
{
	NSParameterAssert(maximumLineCount > 0);
	
	if (self->_maximumLineCount != maximumLineCount) {
		self->_maximumLineCount = maximumLineCount;
	}
}

- (NSFetchRequest *)_fetchRequestForChannel:(NSString *)channelId
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

- (void)forgetChannel:(NSString *)channelId
{
	NSParameterAssert(channelId != nil);

	LogToConsoleDebug("Forgetting channel: %@", channelId);

	HLSHistoricLogChannelContext *channelContext = [self contextForChannel:channelId];
	
	[channelContext performBlockAndWait:^{
		[channelContext reset];

		[self cancelResizeInChannelContext:channelContext];
		
		NSFetchRequest *fetchRequest = [self _fetchRequestForChannel:channelContext.hls_channelId
														  fetchLimit:0
														 limitToDate:nil
														  resultType:NSManagedObjectResultType];
		
		[self _deleteDataInChannelContext:channelContext withFetchRequest:fetchRequest performOnQueue:NO];
	}];
	
	NSManagedObjectContext *parentContext = self.managedObjectContext;
	
	[parentContext performBlockAndWait:^{
		[self.contextObjects removeObjectForKey:channelId];
	}];
}

- (void)resetDataForChannel:(NSString *)channelId
{
	NSParameterAssert(channelId != nil);

	LogToConsoleDebug("Resetting the contents of channel: %@", channelId);
	
	HLSHistoricLogChannelContext *channelContext = [self contextForChannel:channelId];
	
	[channelContext performBlockAndWait:^{
		[self cancelResizeInChannelContext:channelContext];
		
		NSFetchRequest *fetchRequest = [self _fetchRequestForChannel:channelContext.hls_channelId
														  fetchLimit:0
														 limitToDate:nil
														  resultType:NSManagedObjectResultType];
		
		[self _deleteDataInChannelContext:channelContext withFetchRequest:fetchRequest performOnQueue:NO];
	}];
}

- (void)fetchEntriesForChannel:(NSString *)channelId
					fetchLimit:(NSUInteger)fetchLimit
				   limitToDate:(nullable NSDate *)limitToDate
		   withCompletionBlock:(void (NS_NOESCAPE ^)(NSArray<TVCLogLineXPC *> *entries))completionBlock
{
	NSParameterAssert(channelId != nil);
	NSParameterAssert(completionBlock != nil);
	
	HLSHistoricLogChannelContext *channelContext = [self contextForChannel:channelId];
	
	[channelContext performBlockAndWait:^{
		NSFetchRequest *fetchRequest = [self _fetchRequestForChannel:channelContext.hls_channelId
														  fetchLimit:fetchLimit
														 limitToDate:limitToDate
														  resultType:NSManagedObjectResultType];
		
		fetchRequest.includesPropertyValues = YES;
		
		fetchRequest.sortDescriptors = @[[[NSSortDescriptor alloc] initWithKey:@"creationDate" ascending:YES]];
		
		NSError *fetchRequestError = nil;
		
		NSArray<NSManagedObject *> *fetchedObjects = [channelContext executeFetchRequest:fetchRequest error:&fetchRequestError];
		
		if (fetchedObjects == nil) {
			LogToConsoleError("Error occurred fetching objects: %@",
				  fetchRequestError.localizedDescription);
			
			return;
		}
		
		LogToConsoleDebug("%ld results fetched for channel %@",
			  fetchedObjects.count, channelId);
		
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
	
	HLSHistoricLogChannelContext *channelContext = [self contextForChannel:logLine.channelId];
	
	[channelContext performBlockAndWait:^{
		NSEntityDescription *entity = [NSEntityDescription entityForName:@"LogLine" inManagedObjectContext:channelContext];
		
		NSManagedObject *newEntry = [[NSManagedObject alloc] initWithEntity:entity insertIntoManagedObjectContext:channelContext];
		
		NSUInteger newestIdentifier = [self _incrementNewestIdentifierInChannelContext:channelContext];
		
		[newEntry setValue:@(newestIdentifier) forKey:@"id"];
		
		[newEntry setValue:logLine.channelId forKey:@"channelId"];
		
		[newEntry setValue:logLine.creationDate forKey:@"creationDate"];
		
		[newEntry setValue:logLine.data forKey:@"data"];
		
		[self scheduleResizeInChannelContext:channelContext];
	}];
}

- (BOOL)_createBaseModel
{
	return [self _createBaseModelWithRecursion:0];
}

- (BOOL)_createBaseModelWithRecursion:(NSUInteger)recursionDepth
{
	NSURL *modelPath = [[NSBundle mainBundle] URLForResource:@"HistoricLogFileStorageModel" withExtension:@"momd"];
	
	NSManagedObjectModel *managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelPath];
	
	NSPersistentStoreCoordinator *persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:managedObjectModel];
	
	NSDictionary *pragmaOptions = @{
		@"synchronous" : @"FULL",
		@"journal_mode" : @"DELETE"
	};
	
	NSDictionary *persistentStoreOptions = @{
											 NSMigratePersistentStoresAutomaticallyOption : @(YES),
											 NSInferMappingModelAutomaticallyOption : @(YES),
											 NSSQLitePragmasOption : pragmaOptions
											 };
	
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
			  addPersistentStoreError.localizedDescription);
		
		if (recursionDepth == 0) {
			LogToConsoleInfo("Attempting to create a new persistent store");
			
			/* If we failed to load our store, we create a brand new one at a new path
			 incase the old one is corrupted. We also erase the old database to not allow
			 the file to just hang on the OS. */
			[self resetDatabase]; // Destroy any data that may exist
			
			return [self _createBaseModelWithRecursion:1];
		}
		
		return NO;
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
		
		return YES;
	}
}

- (void)resetDatabase
{
	NSString *path = self.savePath;
	
	[[NSFileManager defaultManager] removeItemAtPath:path error:NULL];
	[[NSFileManager defaultManager] removeItemAtPath:[path stringByAppendingString:@"-shm"] error:NULL];
	[[NSFileManager defaultManager] removeItemAtPath:[path stringByAppendingString:@"-wal"] error:NULL];
}

- (void)_rescheduleSave
{
	if (self.saveTimer) {
		XRCancelScheduledBlock(self.saveTimer);
	}
	
	static NSTimeInterval saveTimerInterval = (60 * 2); // 2 minutes
	
	dispatch_source_t saveTimer =
	XRScheduleBlockOnQueue(dispatch_get_main_queue(), ^{
		[self saveDataWithCompletionBlock:nil];
	}, saveTimerInterval, YES);
	
	XRResumeScheduledBlock(saveTimer);
	
	self.saveTimer = saveTimer;
}

- (void)_quickSaveContext:(NSManagedObjectContext *)context
{
	NSParameterAssert(context != nil);
	
	if ([context hasChanges] == NO) {
		return;
	}
	
	NSError *saveError = nil;
	
	if ([context save:&saveError] == NO) {
		LogToConsoleError("Failed to perform save: %@",
			  saveError.localizedDescription);
	}
}

- (void)saveDataWithCompletionBlock:(void (NS_NOESCAPE ^ _Nullable)(void))completionBlock
{
	if (self.isPerformingSave == NO) {
		self.isPerformingSave = YES;
	} else {
		return;
	}
	
	NSManagedObjectContext *context = self.managedObjectContext;
	
	[context performBlock:^{
		LogToConsoleDebug("Performing save");
		
		[self _rescheduleSave];
		
		[self.contextObjects enumerateKeysAndObjectsUsingBlock:^(NSString *channelId, HLSHistoricLogChannelContext *channelContext, BOOL *stop) {
			[self _quickSaveContext:channelContext];
		}];
		
		[self _quickSaveContext:context];
		
		self.isPerformingSave = NO;
		
		if (completionBlock) {
			completionBlock();
		}
	}];
}

#pragma mark -
#pragma mark Channel Resize Logic

- (void)cancelResizeInChannelContext:(HLSHistoricLogChannelContext *)channelContext
{
	NSParameterAssert(channelContext != nil);
	
	if (channelContext.hls_resizeTimer == nil) {
		return;
	}
	
	XRCancelScheduledBlock(channelContext.hls_resizeTimer);
	
	channelContext.hls_resizeTimer = nil;
}

- (void)scheduleResizeInChannelContext:(HLSHistoricLogChannelContext *)channelContext
{
	NSParameterAssert(channelContext != nil);
	
	if (channelContext.hls_resizeTimer != nil) {
		return;
	}
	
	if (channelContext.hls_totalLineCount < self.maximumLineCount) {
		return;
	}
	
	NSString *channelId = channelContext.hls_channelId;
	
	NSTimeInterval resizeTimerInterval = (NSTimeInterval)arc4random_uniform(60 * 30); // Somewhere in 30 minutes
	
	dispatch_source_t resizeTimer =
	XRScheduleBlockOnQueue(dispatch_get_main_queue(), ^{
		[self resizeChannel:channelId];
	}, resizeTimerInterval, NO);
	
	XRResumeScheduledBlock(resizeTimer);
	
	channelContext.hls_resizeTimer = resizeTimer;
	
	LogToConsoleDebug("Scheduled to resize %@ in %f seconds",
		  channelId, resizeTimerInterval);
}

- (void)resizeChannel:(NSString *)channelId
{
	NSParameterAssert(channelId != nil);
	
	HLSHistoricLogChannelContext *channelContext = [self contextForChannel:channelId];
	
	[channelContext performBlock:^{
		[self _resizeChannelContext:channelContext];
	}];
}

- (void)_resizeChannelContext:(HLSHistoricLogChannelContext *)channelContext
{
	NSParameterAssert(channelContext != nil);
	
	LogToConsoleDebug("Resizing channel %@", channelContext.hls_channelId);
	
	channelContext.hls_resizeTimer = nil;
	
	NSString *channelId = channelContext.hls_channelId;
	
	NSInteger lowestIdentifier = (channelContext.hls_newestIdentifier - self.maximumLineCount);
	
	NSDictionary *substitutionVariables = @{
		@"channel_id" : channelId,
		@"lowest_id" : @(lowestIdentifier)
	};
	
	NSFetchRequest *fetchRequest =
	[self.managedObjectModel fetchRequestFromTemplateWithName:@"LogLineFetchRequestTruncate"
										substitutionVariables:substitutionVariables];
	
	NSUInteger rowsDeleted =
	[self _deleteDataInChannelContext:channelContext withFetchRequest:fetchRequest performOnQueue:NO];
	
	channelContext.hls_totalLineCount -= rowsDeleted;
}

#pragma mark -
#pragma mark Batch Delete Logic

- (NSUInteger)_deleteDataInChannelContext:(HLSHistoricLogChannelContext *)channelContext withFetchRequest:(NSFetchRequest *)fetchRequest performOnQueue:(BOOL)performOnQueue
{
	NSParameterAssert(fetchRequest != nil);
	
	__block NSUInteger rowsDeleted = 0;
	
	dispatch_block_t blockToPerform = ^{
		if (XRRunningOnOSXElCapitanOrLater()) {
			rowsDeleted = [self __deleteDataForFetchRequestUsingBatch:fetchRequest inContext:channelContext];
		} else {
			rowsDeleted = [self __deleteDataForFetchRequestUsingEnumeration:fetchRequest inContext:channelContext];
		}
	};
	
	if (performOnQueue) {
		[channelContext performBlockAndWait:blockToPerform];
	} else {
		blockToPerform();
	}
	
	LogToConsoleDebug("Deleted %ld rows in %@", rowsDeleted, channelContext.hls_channelId);
	
	return rowsDeleted;
}

- (NSUInteger)__deleteDataForFetchRequestUsingBatch:(NSFetchRequest *)fetchRequest inContext:(NSManagedObjectContext *)context
{
	NSParameterAssert(fetchRequest != nil);
	NSParameterAssert(context != nil);
	
	NSBatchDeleteRequest *batchDeleteRequest = [[NSBatchDeleteRequest alloc] initWithFetchRequest:fetchRequest];
	
	batchDeleteRequest.resultType = NSBatchDeleteResultTypeObjectIDs;
	
	NSError *batchDeleteError = nil;
	
	NSBatchDeleteResult *batchDeleteResult =
	[context executeRequest:batchDeleteRequest error:&batchDeleteError];
	
	if (batchDeleteResult == nil) {
		LogToConsoleError("Failed to perform batch delete: %@",
						  batchDeleteError.localizedDescription);
		
		return 0;
	}
	
	NSArray<NSManagedObjectID *> *rowsDeleted = batchDeleteResult.result;
	
	NSUInteger rowsDeletedCount = rowsDeleted.count;
	
	if (rowsDeletedCount > 0) {
		[NSManagedObjectContext mergeChangesFromRemoteContextSave:@{NSDeletedObjectsKey : rowsDeleted} intoContexts:@[context]];
		
		[self _quickSaveContext:context];
	}
	
	return rowsDeletedCount;
}

- (NSUInteger)__deleteDataForFetchRequestUsingEnumeration:(NSFetchRequest *)fetchRequest inContext:(NSManagedObjectContext *)context
{
	NSParameterAssert(fetchRequest != nil);
	NSParameterAssert(context != nil);
	
	NSError *fetchRequestError = nil;
	
	NSArray *fetchedObjects = [context executeFetchRequest:fetchRequest error:&fetchRequestError];
	
	if (fetchedObjects == nil) {
		LogToConsoleError("Error occurred fetching objects: %@",
			  fetchRequestError.localizedDescription);
		
		return 0;
	}
	
	for (NSManagedObject *object in fetchedObjects) {
		[context deleteObject:object];
	}
	
	NSUInteger rowsDeletedCount = fetchedObjects.count;
	
	if (rowsDeletedCount > 0) {
		[self _quickSaveContext:context];
	}
	
	return rowsDeletedCount;
}

#pragma mark -
#pragma mark Identifier Cache Management

- (HLSHistoricLogChannelContext *)contextForChannel:(NSString *)channelId
{
	NSParameterAssert(channelId != nil);
	
	@synchronized(self.contextObjects) {
		/* Returned cached object or create new */
		HLSHistoricLogChannelContext *channelContext = [self.contextObjects objectForKey:channelId];
		
		if (channelContext != nil) {
			return channelContext;
		}
		
		NSManagedObjectContext *parentObjectContext = self.managedObjectContext;
		
		channelContext = [[HLSHistoricLogChannelContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
		
		/* Properties specific to NSManagedObjectContext */
		channelContext.parentContext = parentObjectContext;
		
		channelContext.retainsRegisteredObjects = YES;
		
		channelContext.undoManager = nil;
		
		/* Properties specific to HLSHistoricLogChannelContext */
		channelContext.hls_channelId = channelId;
		
		channelContext.hls_totalLineCount = [self _lineCountInChannelContextFromDatabase:channelContext performOnQueue:YES];
		
		channelContext.hls_newestIdentifier = [self _newestIdentifierInChannelContextFromDatabase:channelContext performOnQueue:YES];
		
		/* Log information for debugging */
		LogToConsoleDebug("Context created for %@ - Line count: %ld, Newest identifier: %ld",
						  channelContext.hls_channelId,
						  channelContext.hls_totalLineCount,
						  channelContext.hls_newestIdentifier);
		
		/* Cache new object and return it */
		[parentObjectContext performBlockAndWait:^{
			[self.contextObjects setObject:channelContext forKey:channelId];
		}];
		
		return channelContext;
	}
}

- (NSUInteger)_incrementNewestIdentifierInChannelContext:(HLSHistoricLogChannelContext *)channelContext
{
	NSParameterAssert(channelContext != nil);
	
	channelContext.hls_totalLineCount += 1;
	
	channelContext.hls_newestIdentifier += 1;
	
	return channelContext.hls_newestIdentifier;
}

- (NSUInteger)_newestIdentifierInChannelContext:(HLSHistoricLogChannelContext *)channelContext
{
	NSParameterAssert(channelContext != nil);
	
	return channelContext.hls_newestIdentifier;
}

- (NSUInteger)_newestIdentifierInChannelContextFromDatabase:(HLSHistoricLogChannelContext *)channelContext performOnQueue:(BOOL)performOnQueue
{
	NSParameterAssert(channelContext != nil);
	
	__block NSUInteger newestIdentifier = 0;
	
	dispatch_block_t blockToPerform = ^{
		NSFetchRequest *fetchRequest = [self _fetchRequestForChannel:channelContext.hls_channelId
														  fetchLimit:1
														 limitToDate:nil
														  resultType:NSManagedObjectResultType];
		
		fetchRequest.includesPropertyValues = YES;
		
		fetchRequest.sortDescriptors = @[[[NSSortDescriptor alloc] initWithKey:@"creationDate" ascending:NO]];
		
		NSError *fetchRequestError = nil;
		
		NSArray<NSManagedObject *> *fetchedObjects = [channelContext executeFetchRequest:fetchRequest error:&fetchRequestError];
		
		if (fetchedObjects == nil) {
			NSAssert1(NO, @"Error occurred fetching objects: %@",
				  fetchRequestError.localizedDescription);
		}
		
		NSManagedObject *fetchedObject = fetchedObjects.firstObject;
		
		if (fetchedObject == nil) {
			return;
		}
		
		NSNumber *newestIdentifierObject = [fetchedObject valueForKey:@"id"];
		
		newestIdentifier = newestIdentifierObject.unsignedIntegerValue;
	};
	
	if (performOnQueue) {
		[channelContext performBlockAndWait:blockToPerform];
	} else {
		blockToPerform();
	}
	
	return newestIdentifier;
}

- (NSUInteger)_lineCountInChannelContextFromDatabase:(HLSHistoricLogChannelContext *)channelContext performOnQueue:(BOOL)performOnQueue
{
	NSParameterAssert(channelContext != nil);
	
	__block NSUInteger lineCount = 0;
	
	dispatch_block_t blockToPerform = ^{
		NSFetchRequest *fetchRequest = [self _fetchRequestForChannel:channelContext.hls_channelId
														  fetchLimit:0
														 limitToDate:nil
														  resultType:NSCountResultType];
		
		NSError *fetchRequestError = nil;
		
		lineCount = [channelContext countForFetchRequest:fetchRequest error:&fetchRequestError];
		
		if (lineCount == NSNotFound) {
			NSAssert1(NO, @"Error occurred fetching objects: %@",
				  fetchRequestError.localizedDescription);
		}
	};
	
	if (performOnQueue) {
		[channelContext performBlockAndWait:blockToPerform];
	} else {
		blockToPerform();
	}
	
	return lineCount;
}

@end

NS_ASSUME_NONNULL_END
