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

- (void)resetDataForEntriesMatchingClient:(IRCClient *)client inChannel:(IRCChannel *)channel
{
#ifndef TEXTUAL_BUILT_WITH_CORE_DATA_DISABLED
	[self entriesForClient:client
				 inChannel:channel
	   withCompletionBlock:^(NSArray *objects)
	{
		for (TVCLogLine *line in objects) {
			[self.managedObjectContext deleteObject:line];
		}

		[self saveData];
	}
				fetchLimit:0
				 afterDate:nil];
#endif
}

- (void)entriesForClient:(IRCClient *)client inChannel:(IRCChannel *)channel withCompletionBlock:(void (^)(NSArray *objects))completionBlock fetchLimit:(NSInteger)maxEntryCount afterDate:(NSDate *)referenceDate
{
#ifndef TEXTUAL_BUILT_WITH_CORE_DATA_DISABLED
	/* What are we fetching for? */
	PointerIsEmptyAssert(client);

	[self.managedObjectContext performBlock:^{
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

		/* Define match limit. */
		if (maxEntryCount > 0) {
			[fetchRequest setFetchLimit:maxEntryCount];
		}

		/* Lock the context before performing fetch. */
		[self.managedObjectContext lock];

		/* Perform fetch. */
		NSArray *fetchResults = [self.managedObjectContext executeFetchRequest:fetchRequest error:NULL];

		/* Our sort descriptor places newest lines at the top and oldest
		 at the bottom. This is done so that when a fetch limit is supplied,
		 the fetch limit only applies to the newest lines without us having
		 to supply an offset. Obivously, we do not want newest lines first
		 though, so before passing to the callback, we reverse. */
		NSArray *finalData = [[fetchResults reverseObjectEnumerator] allObjects];

		/* Unlock context. */
		[self.managedObjectContext unlock];

		/* Call completion block. */
		completionBlock(finalData);
	}];
#else
	completionBlock(nil);
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
	return [[TPCPreferences applicationCachesFolderPath] stringByAppendingPathComponent:@"logControllerHistoricLog_v001.sqlite"];
}

- (BOOL)hasPersistentStore
{
	NSArray *persistentStores = [self.persistentStoreCoordinator persistentStores];

	return ([persistentStores count] > 0);
}

- (void)saveData
{
#ifndef TEXTUAL_BUILT_WITH_CORE_DATA_DISABLED
	/* Cancel any previous running timers incase this is manual save. */
	[self handleManagedObjectContextChangeTimerInitializer];

	/* Continue with save operation. */
	[self.managedObjectContext performBlock:^{
		/* Do changes even exist? */
		NSAssertReturn([self hasPersistentStore]);

		if ([self.managedObjectContext commitEditing]) {
			if ([self.managedObjectContext hasChanges]) {
				/* Try to save. */
				NSError *saveError;

				if ([self.managedObjectContext save:&saveError] == NO) {
					/* There was an error saving. As the information stored
					 within our historic log model is not very important,
					 we do not care much about errors here, but we will
					 still report them for the sake of debugging. */

					[self nukeAllManagedObjects];
				}
			}
		}
	}];
#endif
}

- (void)processPendingChanges
{
#ifndef TEXTUAL_BUILT_WITH_CORE_DATA_DISABLED
	[self.managedObjectContext processPendingChanges];
#endif
}

- (void)resetContext
{
#ifndef TEXTUAL_BUILT_WITH_CORE_DATA_DISABLED
	[self.managedObjectContext reset];
#endif
}

- (void)refreshObject:(id)object
{
#ifndef TEXTUAL_BUILT_WITH_CORE_DATA_DISABLED
	[self.managedObjectContext refreshObject:object mergeChanges:NO];
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
	id result = [_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:url options:nil error:&addErr];

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

#pragma mark -
#pragma mark Atomic Bomb

#ifndef TEXTUAL_BUILT_WITH_CORE_DATA_DISABLED
- (void)nukeAllManagedObjects
{
	[self _nukeAllManagedObjects];
}

- (void)_nukeAllManagedObjects
{
	/* Lock the current context. */
    [self.managedObjectContext lock];

	/* Find list of current stores. */
	NSArray *persistentStores = [self.persistentStoreCoordinator persistentStores];

	/* Try to remove old store. */
	NSError *removeError;

	if ([self.persistentStoreCoordinator removePersistentStore:[persistentStores lastObject] error:&removeError] == NO) {
		LogToConsole(@"There was a problem removing the previous store: %@", [removeError localizedDescription]);
	} else {
		(void)[self addPersistentStoreToCoordinator];
	}

	/* Reset the current context and reset it. */
    [self.managedObjectContext reset];
    [self.managedObjectContext unlock];
}
#endif

@end
