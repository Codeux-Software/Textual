/* ********************************************************************* 
                  _____         _               _
                 |_   _|____  _| |_ _   _  __ _| |
                   | |/ _ \ \/ / __| | | |/ _` | |
                   | |  __/>  <| |_| |_| | (_| | |
                   |_|\___/_/\_\\__|\__,_|\__,_|_|

 Copyright (c) 2008 - 2010 Satoshi Nakagawa <psychs AT limechat DOT net>
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

NSString * const TLOFileLoggerConsoleDirectoryName				= @"Console";
NSString * const TLOFileLoggerChannelDirectoryName				= @"Channels";
NSString * const TLOFileLoggerPrivateMessageDirectoryName		= @"Queries";

NSString * const TLOFileLoggerUndefinedNicknameFormat	= @"<%@%n>";
NSString * const TLOFileLoggerActionNicknameFormat		= @"\u2022 %n:";
NSString * const TLOFileLoggerNoticeNicknameFormat		= @"-%n-";

NSString * const TLOFileLoggerISOStandardClockFormat		= @"[%Y-%m-%dT%H:%M:%S%z]"; // 2008-07-09T16:13:30+12:00

@interface TLOFileLogger ()
@property (readonly, copy) NSURL *fileWritePath;
@property (nonatomic, copy) NSURL *filename;
@property (nonatomic, strong) NSFileHandle *file;
@end

@implementation TLOFileLogger

#pragma mark -
#pragma mark Plain Text API

- (void)writeLine:(TVCLogLine *)logLine
{
	NSString *lineString = [logLine renderedBodyForTranscriptLogInChannel:self.channel];

	[self writePlainTextLine:lineString];
}

- (void)writePlainTextLine:(NSString *)s
{
	[self reopenIfNeeded];

	if (self.file) {
		NSString *writeString = [s stringByAppendingString:@"\x0a"];
		
		NSData *writeData = [writeString dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:YES];

		if (writeData) {
			[self.file writeData:writeData];
		}
	}
}

#pragma mark -
#pragma mark File Handle Management

- (void)reset
{
	if ( self.file) {
		[self.file truncateFileAtOffset:0];
	}
}

- (void)close
{
	if ( self.file) {
		[self.file closeFile];
		 self.file = nil;
	}

	self.filename = nil;
}

- (void)reopenIfNeeded
{
	/* This call is designed to reopen the file pointer when using
	 the date as the filename. When the date changes, the log path
	 will have to change as well. This handles that. */

	if ([[self buildFileName] isEqual:self.filename] == NO) {
		[self open];
	}
}

- (void)open
{
	/* Where are we writing to? */
	NSURL *path = [self fileWritePath];

	if (path == nil) {
		return; // Some type of error occured...
	}

	/* What will the filename be? The filename
	 includes the folder being written to. */
	self.filename = [self buildFileName];

	/* Make sure the folder being written to exists. */
	/* We extract the folder from self.filename for this
	 check instead of using "path" because the generation
	 of self.filename may have added extra directories to 
	 the structure of the path beyond what "path" provided. */
	NSURL *folder = [self.filename URLByDeletingLastPathComponent];

	if ([RZFileManager() fileExistsAtPath:[folder path] isDirectory:NULL] == NO) {
		NSError *fmerr = nil;

		[RZFileManager() createDirectoryAtURL:folder withIntermediateDirectories:YES attributes:nil error:&fmerr];

		if (fmerr) {
			DebugLogToConsole(@"Error Creating Folder: %@", [fmerr localizedDescription]);

			[self close]; // We couldn't create the folder. Destroy everything.

			return;
		}
	}

	/* Does the file exist? */
	if ([RZFileManager() fileExistsAtPath:[self.filename path]] == NO) {
		NSError *fcerr = nil;

		[NSStringEmptyPlaceholder writeToURL:self.filename atomically:NO encoding:NSUTF8StringEncoding error:&fcerr];

		if (fcerr) {
			DebugLogToConsole(@"Error Creating File: %@", [fcerr localizedDescription]);

			[self close]; // We couldn't create the file. Destroy everything.

			return;
		}
	}

	/* Open our file handle. */
	self.file = [NSFileHandle fileHandleForUpdatingAtPath:[self.filename path]];

	if ( self.file) {
		[self.file seekToEndOfFile];
	}
}

#pragma mark -
#pragma mark File Handler Path

- (NSURL *)fileWritePath
{
	return [TPCPathInfo logFileFolderLocation];
}

- (NSURL *)buildPath
{
	return [self buildPath:YES];
}

- (NSURL *)buildPath:(BOOL)forceUUID
{
	NSURL *base = [self fileWritePath];

	NSObjectIsEmptyAssertReturn(base, nil);

	NSString *serverName = [[self.client name] safeFilename];
	NSString *channelName = [[self.channel name] safeFilename];

	/* When our folder structure is not flat, then we have to make sure the folders
	 that we create our unique. The check of whether our folders are unique was not
	 added until version 3.0.0. To keep backwards compatible, we first see if our 
	 folder exists using the old naming scheme. If it does, then we use that for
	 our write path. This makes the transition to the new naming scheme seamless
	 for the end user. */

	/* To make the folder unique, we take the first five characters of the client's
	 UUID which does not change between restarts. Not 100% accurate, but still works
	 99.9999% of the time. */
	if (forceUUID) {
		NSURL *oldPath = [self buildPath:NO];

		/* Does the old path exist? */
		if ([RZFileManager() fileExistsAtPath:[oldPath path]]) {
			return oldPath;
		}

		/* It did not exist... use new naming scheme. */
		NSString *servHead = [[self.client uniqueIdentifier] substringToIndex:5];

		serverName = [NSString stringWithFormat:@"%@ (%@)", serverName, servHead];
	}
	
	if (self.channel == nil) {
		return [base URLByAppendingPathComponent:[NSString stringWithFormat:@"/%@/%@/", serverName, TLOFileLoggerConsoleDirectoryName] isDirectory:YES];
	} else if ([self.channel isChannel]) {
		return [base URLByAppendingPathComponent:[NSString stringWithFormat:@"/%@/%@/%@/", serverName, TLOFileLoggerChannelDirectoryName, channelName] isDirectory:YES];
	} else if ([self.channel isPrivateMessage]) {
		return [base URLByAppendingPathComponent:[NSString stringWithFormat:@"/%@/%@/%@/", serverName, TLOFileLoggerPrivateMessageDirectoryName, channelName] isDirectory:YES];
	}

	return nil;
}

- (NSURL *)buildFileName
{
	NSURL *buildPath = [self buildPath];
	
	if (buildPath) {
		NSString *datetime = TXFormattedTimestamp([NSDate date], @"%Y-%m-%d");

		NSString *filename = [NSString stringWithFormat:@"%@.txt", datetime];
		
		return [buildPath URLByAppendingPathComponent:filename isDirectory:NO];
	}
	
	return nil;
}

#pragma mark -
#pragma mark Memory Management

- (void)dealloc
{
	[self close];
}

@end
