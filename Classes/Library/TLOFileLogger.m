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
#import "TPCPathInfoPrivate.h"
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

@interface TLOFileLogger ()
@property (nonatomic, weak) IRCClient *client;
@property (nonatomic, weak) IRCChannel *channel;
@property (nonatomic, strong, nullable) NSFileHandle *fileHandle;
@property (nonatomic, copy, readwrite, nullable) NSString *writePath;
@property (nonatomic, copy, nullable) NSString *filenameCached;
@property (readonly, copy) NSString *filename;
@end

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

	NSString *stringToWrite = [string stringByAppendingString:@"\x0a"];

	NSData *dataToWrite = [stringToWrite dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:YES];

	if (dataToWrite) {
		@try {
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
	[TDCAlert alertWithMessage:TXTLS(@"Prompts[1140][2]")
						 title:TXTLS(@"Prompts[1140][1]")
				 defaultButton:TXTLS(@"Prompts[0005]")
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

	self.filenameCached = nil;

	self.writePath = nil;
}

- (void)reopenIfNeeded
{
#warning TODO: Fix handler not reopening when write path changes

	if ([self.filename isEqualToString:self.filenameCached] && self.fileHandle != nil) {
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

	if ([self buildWritePath] == NO) {
		return;
	}

	NSString *path = self.writePath;

	NSString *pathLeading = path.stringByDeletingLastPathComponent;

	if ([RZFileManager() fileExistsAtPath:pathLeading] == NO) {
		NSError *createDirectoryError = nil;

		if ([RZFileManager() createDirectoryAtPath:pathLeading withIntermediateDirectories:YES attributes:nil error:&createDirectoryError] == NO) {
			LogToConsoleError("Error Creating Folder: %{public}@",
				 createDirectoryError.localizedDescription);

			return;
		}
	}

	if ([RZFileManager() fileExistsAtPath:path] == NO) {
		NSError *writeFileError = nil;

		if ([@"" writeToFile:path atomically:NO encoding:NSUTF8StringEncoding error:&writeFileError] == NO) {
			LogToConsoleError("Error Creating File: %{public}@",
				  writeFileError.localizedDescription);

			return;
		}
	}

	self.fileHandle = [NSFileHandle fileHandleForUpdatingAtPath:path];

	if ( self.fileHandle) {
		[self.fileHandle seekToEndOfFile];

		return;
	}

	LogToConsoleError("Failed to open file handle at path '%{public}@'", path);
}

#pragma mark -
#pragma mark File Handler Path

+ (nullable NSString *)writePathForItem:(IRCTreeItem *)item
{
	NSParameterAssert(item != nil);
	
	return [self writePathWithUniqueIdentifier:YES forItem:item];
}

+ (nullable NSString *)writePathWithUniqueIdentifier:(BOOL)withUniqueIdentifier forItem:(IRCTreeItem *)item
{
	NSParameterAssert(item != nil);

	NSURL *sourcePath = [TPCPathInfo transcriptFolderURL];
	
	if (sourcePath == nil) {
		return nil;
	}
	
	IRCClient *client = item.associatedClient;
	
	NSString *clientName = nil;
	
	/* When our folder structure is not flat, then we have to make sure the folders
	 that we create are unique. The check of whether our folders are unique was not
	 added until version 3.0.0. To keep backwards compatible, we first see if our
	 folder exists using the old naming scheme. If it does, then we use that for
	 our write path. This makes the transition to the new naming scheme seamless
	 for the end user. */
	if (withUniqueIdentifier) {
		NSString *pathWithoutIdentifier = [self writePathWithUniqueIdentifier:NO forItem:item];
		
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
	
	return [sourcePath.path stringByAppendingPathComponent:basePath];
}

- (nullable NSString *)writePathLeading
{
	IRCClient *client = self.client;
	IRCChannel *channel = self.channel;
	
	IRCTreeItem *item = ((channel) ? : client);

	return [self.class writePathForItem:item];
}

- (NSString *)filename
{
	NSString *dateTime = TXFormattedTimestamp([NSDate date], @"%Y-%m-%d");

	NSString *filename = [NSString stringWithFormat:@"%@.txt", dateTime];

	return filename;
}

- (BOOL)buildWritePath
{
	NSString *sourcePath = [self writePathLeading];

	if (sourcePath == nil) {
		return NO;
	}

	self.filenameCached = self.filename;

	self.writePath = [sourcePath stringByAppendingPathComponent:self.filenameCached];

	return YES;
}

@end

NS_ASSUME_NONNULL_END
