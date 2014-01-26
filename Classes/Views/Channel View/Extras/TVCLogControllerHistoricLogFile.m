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
	[RZFileManager() removeItemAtPath:[self databaseSavePath] error:NULL]; // Destroy archive file completely.
}

- (void)resetDataForEntriesMatchingClient:(IRCClient *)client inChannel:(IRCChannel *)channel
{
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
}

- (void)entriesForClient:(IRCClient *)client inChannel:(IRCChannel *)channel withCompletionBlock:(void (^)(NSArray *objects))completionBlock fetchLimit:(NSInteger)maxEntryCount afterDate:(NSDate *)referenceDate
{
	/* What are we fetching for? */
	PointerIsEmptyAssert(client);

	/* _privateContext will execute the fetch on whatever the current thread is. */
	NSManagedObjectContext *_privateContext = [NSManagedObjectContext new];

	[_privateContext setPersistentStoreCoordinator:self.persistentStoreCoordinator];

	/* Build base model. */
	NSFetchRequest *fetchRequest = [NSFetchRequest new];

	NSEntityDescription *entity = [NSEntityDescription entityForName:@"TVCLogLine" inManagedObjectContext:_privateContext];

	/* Gather relevant information. */
	NSString *clientID = [client uniqueIdentifier];
	NSString *channelID = nil;

	if (channel) {
		channelID = [channel uniqueIdentifier];
	}

	/* Build the match. */
	NSPredicate *matchPredicate;

	if (referenceDate) {
		if (channel) {
			matchPredicate = [NSPredicate predicateWithFormat:@"clientID == %@ AND channelID == %@ AND creationDate >= %@", clientID, channelID, referenceDate];
		} else {
			matchPredicate = [NSPredicate predicateWithFormat:@"clientID == %@ AND channelID == nil AND creationDate >= %@", clientID, referenceDate];
		}
	} else {
		if (channel) {
			matchPredicate = [NSPredicate predicateWithFormat:@"clientID == %@ AND channelID == %@", clientID, channelID];
		} else {
			matchPredicate = [NSPredicate predicateWithFormat:@"clientID == %@ AND channelID == nil", clientID];
		}
	}

	/* Perform actual fetch. */
	[fetchRequest setEntity:entity];
	[fetchRequest setPredicate:matchPredicate];
	[fetchRequest setSortDescriptors:@[self.managedSortDescriptor]];

	/* Define match limit. */
	if (maxEntryCount > 0) {
		[fetchRequest setFetchLimit:maxEntryCount];
	}

	NSArray *fetchResults = [_privateContext executeFetchRequest:fetchRequest error:NULL];

	/* Now that we fetched the results, we push them to the main context. */
	[self.managedObjectContext performBlock:^{
		/* We have to use this hack because Core Data is not
		 very thread safe so this is what you get… */
		NSMutableArray *resultObjectIDs = [NSMutableArray array];

		for (NSManagedObject *line in fetchResults) {
			[resultObjectIDs addObject:[line objectID]];
		}

		/* Build list of objects from IDs. */
		NSMutableArray *resultObjects = [NSMutableArray array];

		for (NSManagedObjectID *objectID in resultObjectIDs) {
			NSManagedObject *obj = [self.managedObjectContext objectWithID:objectID];

			[resultObjects addObject:obj];
		}

		/* Our sort descriptor places newest lines at the top and oldest
		 at the bottom. This is done so that when a fetch limit is supplied,
		 the fetch limit only applies to the newest lines without us having
		 to supply an offset. Obivously, we do not want newest lines first
		 though, so before passing to the callback, we reverse. */
		NSArray *finalData = [resultObjects.reverseObjectEnumerator allObjects];

		completionBlock(finalData);
	}];
}


#pragma mark -
#pragma mark Core Data Model

- (id)init
{
	if (self = [super init]) {
		/* Call variables to initalize objects. */
		(void)self.persistentStoreCoordinator;

		/* Return ourself. */
		return self;
	}

	return nil;
}

- (NSString *)databaseSavePath
{
	return [[TPCPreferences applicationCachesFolderPath] stringByAppendingPathComponent:@"logControllerHistoricLog.sqlite"];
}

- (void)saveData
{
	[self.managedObjectContext performBlock:^{
		/* Do changes even exist? */
		if ([self.managedObjectContext commitEditing]) {
			if ([self.managedObjectContext hasChanges]) {
				/* Try to save. */
				NSError *saveError;

				if ([self.managedObjectContext save:&saveError] == NO) {
					/* There was an error saving. As the information stored
					 within our historic log model is not very important,
					 we do not care much about errors here, but we will
					 still report them for the sake of debugging. */

					LogToConsole(@"%@", [saveError localizedDescription]);
				}
			}
		}
	}];
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

	/* Define save path. */
	NSString *savePath = [self databaseSavePath];

	/* Add model to persistent store. */
	NSURL *url = [NSURL fileURLWithPath:savePath];

	NSManagedObjectModel *mom = [self managedObjectModel];

	_persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:mom];

	/* Try to create the actual persistent store. */
	NSError *addErr = nil;

	id result = [_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:url options:nil error:&addErr];

	/* Was there an error? */
	if (result == nil) {
		/* Log error. */
		LogToConsole(@"Error Creating Persistent Store: %@", [addErr localizedDescription]);

		/* Destroy state. */
		_persistentStoreCoordinator = nil;
	}

	/* Return new store. */
	return _persistentStoreCoordinator;
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

	return _managedObjectContext;
}

- (NSSortDescriptor *)managedSortDescriptor
{
	/* We do not need to do work if this property exists already. */
	PointerIsNotEmptyAssertReturn(_managedSortDescriptor, _managedSortDescriptor);

	/* Create new sort descriptor. */
	_managedSortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"creationDate" ascending:NO];

	return _managedSortDescriptor;
}

@end
