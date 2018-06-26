/* *********************************************************************
 *                  _____         _               _
 *                 |_   _|____  _| |_ _   _  __ _| |
 *                   | |/ _ \ \/ / __| | | |/ _` | |
 *                   | |  __/>  <| |_| |_| | (_| | |
 *                   |_|\___/_/\_\\__|\__,_|\__,_|_|
 *
 * Copyright (c) 2008 - 2010 Satoshi Nakagawa <psychs AT limechat DOT net>
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

#import "NSObjectHelperPrivate.h"
#import "TXGlobalModels.h"
#import "TDCAlert.h"
#import "TLOLanguagePreferences.h"
#import "TLOTimer.h"
#import "TPCPathInfoPrivate.h"
#import "TPCPreferencesLocal.h"
#import "IRCClient.h"
#import "IRCChannel.h"
#import "TVCLogLinePrivate.h"
#import "TLOFileLoggerPrivate.h"

NS_ASSUME_NONNULL_BEGIN

#define _noSpaceLeftOnDeviceAlertInterval		300 // 5 minutes

NSString * const TLOFileLoggerConsoleDirectoryName				= @"Console";
NSString * const TLOFileLoggerChannelDirectoryName				= @"Channels";
NSString * const TLOFileLoggerPrivateMessageDirectoryName		= @"Queries";

NSString * const TLOFileLoggerUndefinedNicknameFormat	= @"<%@%n>";
NSString * const TLOFileLoggerActionNicknameFormat		= @"\u2022 %n:";
NSString * const TLOFileLoggerNoticeNicknameFormat		= @"-%n-";

NSString * const TLOFileLoggerISOStandardClockFormat		= @"[%Y-%m-%dT%H:%M:%S%z]"; // 2008-07-09T16:13:30+12:00

NSString * const TLOFileLoggerIdleTimerNotification		= @"TLOFileLoggerIdleTimerNotification";

@interface TLOFileLogger ()
@property (nonatomic, weak) IRCClient *client;
@property (nonatomic, weak) IRCChannel *channel;
@property (nonatomic, strong, nullable) NSFileHandle *fileHandle;
@property (nonatomic, copy, readwrite, nullable) NSString *filePath;

/* Properties that end in an underscore are the live
 (uncached) values for their counterpart. */
@property (readonly, copy) NSString *fileName_;

/* The file path hash is the hash of the configured save
 location combined with the dated file name. When the hash
 changes, it signals to TLOFileLogger that the file handler
 has to be reopened. */
@property (nonatomic, assign) NSUInteger filePathHash;
@property (readonly) NSUInteger filePathHash_;

@property (nonatomic, assign) NSTimeInterval lastWriteTime;
@property (readonly) BOOL fileHandleIdle;
@property (readonly, class) TLOTimer *idleTimer;
@end

static NSUInteger _numberOfOpenFileHandles = 0;

@implementation TLOFileLogger

ClassWithDesignatedInitializerInitMethod

- (instancetype)initWithClient:(IRCClient *)client
{
	NSParameterAssert(client != nil);

	if ((self = [super init])) {
		self.client = client;

		return self;
	}

	return nil;
}

- (instancetype)initWithChannel:(IRCChannel *)channel
{
	NSParameterAssert(channel != nil);

	if ((self = [super init])) {
		self.client = channel.associatedClient;
		self.channel = channel;

		return self;
	}

	return nil;
}

- (void)dealloc
{
	[self close];
}

#pragma mark -
#pragma mark Plain Text API

- (void)writeLogLine:(TVCLogLine *)logLine
{
	NSParameterAssert(logLine != nil);

	NSString *stringToWrite = nil;

	if (self.channel) {
		stringToWrite = [logLine renderedBodyForTranscriptLogInChannel:self.channel];
	} else {
		stringToWrite = [logLine renderedBodyForTranscriptLog];
	}

	[self writePlainText:stringToWrite];
}

- (void)writePlainText:(NSString *)string
{
	NSParameterAssert(string != nil);

	[self reopenIfNeeded];

	if (self.fileHandle == nil) {
		LogToConsoleError("File handle is closed");

		return;
	}

	NSString *stringToWrite = [string stringByAppendingString:@"\n"];

	NSData *dataToWrite = [stringToWrite dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:YES];

	if (dataToWrite) {
		@try {
			self.lastWriteTime = [NSDate timeIntervalSince1970];

			[self.fileHandle writeData:dataToWrite];
		}
		@catch (NSException *exception) {
			LogToConsoleError("Caught exception: %@", exception.reason);
			LogToConsoleCurrentStackTrace

			if ([exception.reason contains:@"No space left on device"]) {
				[self failWithNoSpaceLeftOnDevice];
			}

			[self close];
		} // @catch
	}
}

#pragma mark -
#pragma mark File Handle Management

- (void)failWithNoSpaceLeftOnDevice
{
	static BOOL alertVisible = NO;

	if (alertVisible) {
		return;
	}

	static NSTimeInterval lastFailTime = 0;

	NSTimeInterval currentTime = [NSDate timeIntervalSince1970];

	if (lastFailTime > 0) {
		if ((currentTime - lastFailTime) < _noSpaceLeftOnDeviceAlertInterval) {
			return;
		}
	}

	lastFailTime = currentTime;

	alertVisible = YES;

	/* Present alert as non-blocking because there is no need for it to disrupt UI */
	[TDCAlert alertWithMessage:TXTLS(@"Prompts[v9e-jy]")
						 title:TXTLS(@"Prompts[bi7-ah]")
				 defaultButton:TXTLS(@"Prompts[c7s-dq]")
			   alternateButton:nil
			   completionBlock:^(TDCAlertResponse buttonClicked, BOOL suppressed, id underlyingAlert) {
				   alertVisible = NO;
			   }];
}

- (void)reset
{
	if (self.fileHandle == nil) {
		return;
	}

	[self.fileHandle truncateFileAtOffset:0];
}

- (void)close
{
	if (self.fileHandle == nil) {
		return;
	}

	@try {
		[self.fileHandle synchronizeFile];
	}
	@catch (NSException *exception) {
		LogToConsoleError("Caught exception: %@", exception.reason);
		LogToConsoleCurrentStackTrace
	}

	[self.fileHandle closeFile];

	self.fileHandle = nil;

	self.filePath = nil;
	self.filePathHash = 0;

	self.lastWriteTime = 0;

	[self removeIdleTimerObserver];
}

- (void)reopenIfNeeded
{
	if (self.fileHandle != nil && self.filePathHash == self.filePathHash_) {
		return;
	}

	[self reopen];
}

- (void)reopen
{
	[self close];

	[self open];
}

- (void)open
{
	if (self.fileHandle != nil) {
		LogToConsoleError("Tried to open log file when a file handle already exists");

		return;
	}

	if ([self buildFilePath] == NO) {
		return;
	}

	NSString *filePath = self.filePath;

	NSString *writePath = filePath.stringByDeletingLastPathComponent;

	if ([RZFileManager() fileExistsAtPath:writePath] == NO) {
		NSError *createDirectoryError = nil;

		if ([RZFileManager() createDirectoryAtPath:writePath withIntermediateDirectories:YES attributes:nil error:&createDirectoryError] == NO) {
			LogToConsoleError("Error Creating Folder: %@",
				 createDirectoryError.localizedDescription);

			return;
		}
	}

	if ([RZFileManager() fileExistsAtPath:filePath] == NO) {
		NSError *writeFileError = nil;

		if ([@"" writeToFile:filePath atomically:NO encoding:NSUTF8StringEncoding error:&writeFileError] == NO) {
			LogToConsoleError("Error Creating File: %@",
				  writeFileError.localizedDescription);

			return;
		}
	}

	NSFileHandle *fileHandle = [NSFileHandle fileHandleForUpdatingAtPath:filePath];

	if (fileHandle == nil) {
		LogToConsoleError("Failed to open file handle at path '%@'", filePath);

		return;
	}

	[fileHandle seekToEndOfFile];

	self.fileHandle = fileHandle;

	[self addIdleTimerObserver];
}

#pragma mark -
#pragma mark Idle Timer

- (BOOL)fileHandleIdle
{
#define _fileHandleIdleLimit		1200 // 20 minutes

	NSTimeInterval lastWriteTime = self.lastWriteTime;

	NSTimeInterval currentTime = [NSDate timeIntervalSince1970];

	if (lastWriteTime > 0) {
		if ((currentTime - lastWriteTime) > _fileHandleIdleLimit) {
			return YES;
		}
	}

	return NO;

#undef _fileHandleIdleTime
}

+ (TLOTimer *)idleTimer
{
	static TLOTimer *idleTimer = nil;

	static dispatch_once_t onceToken;

	dispatch_once(&onceToken, ^{
		idleTimer = [TLOTimer timerWithActionBlock:^(TLOTimer *sender) {
			[self idleTimerFired];
		} onQueue:dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0)];
	});

	return idleTimer;
}

+ (void)idleTimerFired
{
	if (_numberOfOpenFileHandles == 0) {
		[self stopIdleTimer];

		return;
	}

	[RZNotificationCenter() postNotificationName:TLOFileLoggerIdleTimerNotification object:nil];
}

+ (void)startIdleTimer
{
	TLOTimer *idleTimer = self.idleTimer;

	if (idleTimer.timerIsActive) {
		return;
	}

#define _idleTimerInterval			600 // 10 minutes

	[idleTimer start:_idleTimerInterval onRepeat:YES];

#undef _idleTimerInterval
}

+ (void)stopIdleTimer
{
	TLOTimer *idleTimer = self.idleTimer;

	if (idleTimer.timerIsActive == NO) {
		return;
	}

	[idleTimer stop];
}

- (void)idleTimerFired:(NSNotification *)notification
{
	if (self.fileHandleIdle == NO) {
		return;
	}

	LogToConsoleDebug("Closing %@ because it's idle.", self);

	[self close];
}

- (void)updateIdleTimer
{
	if (_numberOfOpenFileHandles == 0) {
		[self.class stopIdleTimer];
	} else {
		[self.class startIdleTimer];
	}
}

- (void)addIdleTimerObserver
{
	_numberOfOpenFileHandles += 1;

	[RZNotificationCenter() addObserver:self selector:@selector(idleTimerFired:) name:TLOFileLoggerIdleTimerNotification object:nil];

	[self updateIdleTimer];
}

- (void)removeIdleTimerObserver
{
	_numberOfOpenFileHandles -= 1;

	[RZNotificationCenter() removeObserver:self name:TLOFileLoggerIdleTimerNotification object:nil];

	[self updateIdleTimer];
}

#pragma mark -
#pragma mark Paths

+ (nullable NSString *)writePathForItem:(IRCTreeItem *)item
{
	NSParameterAssert(item != nil);

	NSString *sourcePath = [TPCPathInfo transcriptFolder];

	if (sourcePath == nil) {
		return nil;
	}

	return [self writePathForItem:item relativeTo:sourcePath];
}

+ (NSString *)writePathForItem:(IRCTreeItem *)item relativeTo:(NSString *)sourcePath
{
	NSParameterAssert(sourcePath != nil);
	NSParameterAssert(item != nil);

	return [self writePathForItem:item relativeTo:sourcePath withUniqueIdentifier:YES];
}

+ (NSString *)writePathForItem:(IRCTreeItem *)item relativeTo:(NSString *)sourcePath withUniqueIdentifier:(BOOL)withUniqueIdentifier
{
	NSParameterAssert(sourcePath != nil);
	NSParameterAssert(item != nil);
	
	IRCClient *client = item.associatedClient;
	
	NSString *clientName = nil;
	
	/* When our folder structure is not flat, then we have to make sure the folders
	 that we create are unique. The check of whether our folders are unique was not
	 added until version 3.0.0. To keep backwards compatible, we first see if our
	 folder exists using the old naming scheme. If it does, then we use that for
	 our write path. This makes the transition to the new naming scheme seamless
	 for the end user. */
	if (withUniqueIdentifier) {
		NSString *pathWithoutIdentifier = [self writePathForItem:item relativeTo:sourcePath withUniqueIdentifier:NO];
		
		if ([RZFileManager() fileExistsAtPath:pathWithoutIdentifier]) {
			return pathWithoutIdentifier;
		}
		
		NSString *identifier = [client.uniqueIdentifier substringToIndex:5];
		
		clientName = [NSString stringWithFormat:@"%@ (%@)", client.name, identifier];
	} else {
		clientName = client.name;
	}
	
	IRCChannel *channel = item.associatedChannel;

	NSString *basePath = nil;
	
	if (channel == nil) {
		basePath = [NSString stringWithFormat:@"/%@/%@/", clientName.safeFilename, TLOFileLoggerConsoleDirectoryName];
	} else if (channel.isChannel) {
		basePath = [NSString stringWithFormat:@"/%@/%@/%@/", clientName.safeFilename, TLOFileLoggerChannelDirectoryName, channel.name.safeFilename];
	} else if (channel.isPrivateMessage) {
		basePath = [NSString stringWithFormat:@"/%@/%@/%@/", clientName.safeFilename, TLOFileLoggerPrivateMessageDirectoryName, channel.name.safeFilename];
	}
	
	return [sourcePath stringByAppendingPathComponent:basePath];
}

- (nullable NSString *)writePath
{
	return self.filePath.stringByDeletingLastPathComponent;
}

- (NSString *)writePathRelativeTo:(NSString *)sourcePath
{
	NSParameterAssert(sourcePath != nil);

	IRCClient *client = self.client;
	IRCChannel *channel = self.channel;

	IRCTreeItem *item = ((channel) ?: client);

	return [self.class writePathForItem:item relativeTo:sourcePath];
}

- (nullable NSString *)fileName
{
	return self.filePath.lastPathComponent;
}

- (NSString *)fileName_
{
	NSString *dateTime = TXFormattedTimestamp([NSDate date], @"%Y-%m-%d");

	NSString *fileName = [NSString stringWithFormat:@"%@.txt", dateTime];

	return fileName;
}

- (BOOL)buildFilePath
{
	NSString *sourcePath = [TPCPathInfo transcriptFolder];

	if (sourcePath == nil) {
		return NO;
	}

	NSString *writePath = [self writePathRelativeTo:sourcePath];

	NSString *fileName = self.fileName_;

	NSString *filePath = [writePath stringByAppendingPathComponent:fileName];

	self.filePath = filePath;

	NSString *filePathHash = [sourcePath stringByAppendingString:fileName];

	self.filePathHash = filePathHash.hash;

	return YES;
}

- (NSUInteger)filePathHash_
{
	NSString *sourcePath = [TPCPathInfo transcriptFolder];

	if (sourcePath == nil) {
		return 0;
	}

	NSString *fileName = self.fileName_;

	NSString *filePathHash = [sourcePath stringByAppendingString:fileName];

	return filePathHash.hash;
}

@end

NS_ASSUME_NONNULL_END
