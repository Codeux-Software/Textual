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

#import "HLSHistoricLogProtocol.h"

#import "TVCLogLineXPC.h"

NS_ASSUME_NONNULL_BEGIN

@interface TVCLogControllerHistoricLogFile ()
@property (nonatomic, assign, readwrite) BOOL isSaving;
@property (nonatomic, strong) NSXPCConnection *serviceConnection;
@property (nonatomic, strong) TLOTimer *saveTimer;
@property (nonatomic, strong) TLOTimer *trimTimer;
@property (nonatomic, assign) BOOL connectionInvalidatedVoluntarily;
@property (nonatomic, assign) BOOL connectionInvalidatedErrorDialogDisplayed;
@property (nonatomic, copy, nullable) NSError *lastServiceConnectionError;
@end

@implementation TVCLogControllerHistoricLogFile

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

#pragma mark -
#pragma mark Migration

- (void)relocateDatabaseFrom200PathTo300Path
{
	NSString *filenameNew = [RZUserDefaults() objectForKey:@"TVCLogControllerHistoricLogFileSavePath_v3"];

	NSString *filenameOld = [RZUserDefaults() objectForKey:@"TVCLogControllerHistoricLogFileSavePath_v2"];

	if (filenameNew != nil || filenameOld == nil) {
		return;
	}

	NSString *oldPath = [TPCPathInfo applicationCachesFolderPath];

	NSError *oldPathFilesError = nil;

	NSArray *oldPathFiles = [RZFileManager() contentsOfDirectoryAtPath:oldPath error:&oldPathFilesError];

	if (oldPathFiles == nil) {
		LogToConsoleError("Failed to list contents of old directory: %@",
			oldPathFilesError.localizedDescription)

		return;
	}

	NSString *newPath = [TPCPathInfo applicationCachesFolderInsideGroupContainerPath];

	for (NSString *file in oldPathFiles) {
		if ([file hasPrefix:@"logControllerHistoricLog_"] == NO) {
			continue;
		}

		NSString *oldFilePath = [oldPath stringByAppendingPathComponent:file];

		NSString *newFilePath = [newPath stringByAppendingPathComponent:file];

		(void)[RZFileManager() replaceItemAtPath:newFilePath
								  withItemAtPath:oldFilePath
							   moveToDestination:YES
						  moveDestinationToTrash:YES];
	}

	[RZUserDefaults() removeObjectForKey:@"TVCLogControllerHistoricLogFileSavePath_v2"];

	[RZUserDefaults() setObject:filenameOld forKey:@"TVCLogControllerHistoricLogFileSavePath_v2"];
}

#pragma mark -
#pragma mark Save Path

- (void)resetDatabaseSavePath
{
	NSString *filename = [NSString stringWithFormat:@"logControllerHistoricLog_%@.sqlite", [NSString stringWithUUID]];

	[RZUserDefaults() setObject:filename forKey:@"TVCLogControllerHistoricLogFileSavePath_v3"];
}

- (NSString *)databaseSavePath
{
	NSString *filename = [RZUserDefaults() objectForKey:@"TVCLogControllerHistoricLogFileSavePath_v3"];

	if (filename == nil) {
		[self resetDatabaseSavePath];

		return [self databaseSavePath];
	}

	NSString *sourcePath = [TPCPathInfo applicationCachesFolderInsideGroupContainerPath];

	return [sourcePath stringByAppendingPathComponent:filename];
}

#pragma mark -
#pragma mark Construction

- (void)prepareInitialState
{
	[self relocateDatabaseFrom200PathTo300Path];

	[self connectToService];

	[self openDatabase];

	[self setupTimers];
}

- (void)openDatabase
{
	[[self remoteObjectProxy] openDatabaseAtPath:[self databaseSavePath]];
}

- (void)connectToService
{
	NSXPCConnection *serviceConnection = [[NSXPCConnection alloc] initWithServiceName:@"com.codeux.app-utilities.Textual-HistoricLogFileManager"];

	NSXPCInterface *remoteObjectInterface = [NSXPCInterface interfaceWithProtocol:@protocol(HLSHistoricLogProtocol)];

	[remoteObjectInterface setClasses:[NSSet setWithObjects:[NSArray class], [TVCLogLineXPC class], nil]
					  forSelector:@selector(fetchEntriesForChannel:fetchLimit:limitToDate:withCompletionBlock:)
					argumentIndex:0
						  ofReply:YES];

	serviceConnection.remoteObjectInterface = remoteObjectInterface;

	serviceConnection.interruptionHandler = ^{
		[self interuptionHandler];

		LogToConsole("Interuption handler called")
	};

	serviceConnection.invalidationHandler = ^{
		[self invalidationHandler];

		LogToConsole("Invalidation handler called")
	};

	[serviceConnection resume];

	self.serviceConnection = serviceConnection;
}

- (void)interuptionHandler
{
	[self resetContext];
}

- (void)invalidationHandler
{
	self.serviceConnection = nil;

	[self resetContext];

	if (self.connectionInvalidatedVoluntarily) {
		return;
	}

	/* Error dialog is purposely only ever shown once */
	if (self.connectionInvalidatedErrorDialogDisplayed == NO) {
		self.connectionInvalidatedErrorDialogDisplayed = YES;
	} else {
		return;
	}

	NSString *lastErrorMessage = self.lastServiceConnectionError.localizedDescription;

	if (lastErrorMessage == nil) {
		lastErrorMessage = NSStringEmptyPlaceholder;
	} else {
		lastErrorMessage = TXTLS(@"Prompts[1137][2]", lastErrorMessage);
	}

	(void)[TLOPopupPrompts dialogWindowWithMessage:lastErrorMessage
											 title:TXTLS(@"Prompts[1137][1]")
									 defaultButton:TXTLS(@"Prompts[0005]")
								   alternateButton:nil];
}

- (void)resetContext
{
	self.isSaving = NO;
}

- (void)setupTimers
{
	TLOTimer *saveTimer = [TLOTimer new];

	saveTimer.target = self;
	saveTimer.action = @selector(saveData:);
	saveTimer.repeatTimer = YES;

	[saveTimer start:(60 * 2)]; // 2 minutes

	self.saveTimer = saveTimer;

	TLOTimer *trimTimer = [TLOTimer new];

	trimTimer.target = self;
	trimTimer.action = @selector(trimData:);
	trimTimer.repeatTimer = YES;

	/* A few seconds are added so saves do not land
	 on save timer */
	[trimTimer start:((60 * 30) + 12)]; // 30:12 minutes

	self.trimTimer = trimTimer;
}

- (void)prepareForApplicationTermination
{
	[self saveData];

	self.connectionInvalidatedVoluntarily = YES;
}

#pragma mark -
#pragma mark Private API

- (id <HLSHistoricLogProtocol>)remoteObjectProxy
{
	if (self.serviceConnection == nil) {
		[self connectToService];
	}

	return [self.serviceConnection remoteObjectProxyWithErrorHandler:^(NSError *error) {
		self.lastServiceConnectionError = error;

		LogToConsoleError("Error occurred while communicating with service: %@",
			error.localizedDescription);
	}];
}

- (void)saveData:(id)sender
{
	[self saveData];
}

- (void)trimData:(id)sender
{
	NSUInteger rowLimit = MIN([TPCPreferences scrollbackLimit], [TPCPreferences scrollbackHistoryLimit]);

	LogToConsoleInfo("Maximum line count per-channel is: %ld", rowLimit)

	[[self remoteObjectProxy] resizeDatabaseToConformToRowLimit:rowLimit];
}

#pragma mark -
#pragma mark Public API 

- (void)fetchEntriesForChannel:(IRCChannel *)channel
					fetchLimit:(NSUInteger)fetchLimit
				   limitToDate:(nullable NSDate *)limitToDate
		   withCompletionBlock:(void (^)(NSArray<TVCLogLine *> *entries))completionBlock
{
	void (^privateCompletionBlock)(NSArray *) = ^(NSArray<TVCLogLineXPC *> *entries) {
		@autoreleasepool {
			NSMutableArray *logLines = [NSMutableArray arrayWithCapacity:entries.count];

			for (TVCLogLineXPC *entry in entries) {
				TVCLogLine *logLine = [[TVCLogLine alloc] initWithXPCObject:entry];

				if (logLine == nil) {
					LogToConsoleError("Failed to initalize object %@. Corrupt data?",
						entry.description)

					continue;
				}

				[logLines addObject:logLine];
			}

			completionBlock([logLines copy]);
		}
	};

	[[self remoteObjectProxy] fetchEntriesForChannel:channel.uniqueIdentifier
										  fetchLimit:fetchLimit
										 limitToDate:limitToDate
								 withCompletionBlock:privateCompletionBlock];
}

- (void)saveData
{
	if (self.isSaving == NO) {
		self.isSaving = YES;
	} else {
		return;
	}

	[[self remoteObjectProxy] saveDataWithCompletionBlock:^{
		self.isSaving = NO;
	}];
}

- (void)resetDataForChannel:(IRCChannel *)channel
{
	[[self remoteObjectProxy] resetDataForChannel:channel.uniqueIdentifier];
}

- (void)writeNewEntryWithLogLine:(TVCLogLine *)logLine inChannel:(IRCChannel *)channel
{
	TVCLogLineXPC *newEntry = [logLine xpcObjectForChannel:channel];

	[[self remoteObjectProxy] writeLogLine:newEntry];
}

@end

NS_ASSUME_NONNULL_END
