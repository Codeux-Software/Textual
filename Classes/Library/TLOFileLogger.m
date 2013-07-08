/* ********************************************************************* 
       _____        _               _    ___ ____   ____
      |_   _|___  _| |_ _   _  __ _| |  |_ _|  _ \ / ___|
       | |/ _ \ \/ / __| | | |/ _` | |   | || |_) | |
       | |  __/>  <| |_| |_| | (_| | |   | ||  _ <| |___
       |_|\___/_/\_\\__|\__,_|\__,_|_|  |___|_| \_\\____|

 Copyright (c) 2008 - 2010 Satoshi Nakagawa <psychs AT limechat DOT net>
 Copyright (c) 2010 — 2013 Codeux Software & respective contributors.
        Please see Contributors.pdf and Acknowledgements.pdf

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

@interface TLOFileLogger ()
@property (strong) NSMutableString *temporaryWriteString;
@end

@implementation TLOFileLogger

#pragma mark -
#pragma mark Plain Text API

- (void)writePlainTextLine:(NSString *)s
{
	[self reopenIfNeeded];

	PointerIsEmptyAssert(self.file);

	NSString *writeString = [NSString stringWithFormat:@"%@%@", s, NSStringNewlinePlaceholder];

	NSObjectIsEmptyAssert(writeString);
	
	if ([TPCPreferences logTranscriptInBatches]) {
		/* If we are going to log in batches, then make sure we have
		 a string to append data to. */
		if (PointerIsEmpty(self.temporaryWriteString)) {
			self.temporaryWriteString = [NSMutableString string];
		}

		[self.temporaryWriteString appendString:writeString];
	} else {
		/* Write straight to file. */
		NSData *writeData = [self.client convertToCommonEncoding:writeString];
		
		NSObjectIsEmptyAssert(writeData);

		[self.file writeData:writeData];
	}
}

- (void)updateWriteCacheInternalInit
{
	/* Twenty seconds seems a fair value… */
	[self performSelector:@selector(updateWriteCacheInternalInit) withObject:nil afterDelay:20.0];

	/* Write buffer. */
	[self updateWriteCache];
}

- (void)updateWriteCache
{
	NSObjectIsEmptyAssert(self.temporaryWriteString);
	
	/* Write cache to the file. */
	NSData *writeData = [self.client convertToCommonEncoding:self.temporaryWriteString];

	[self.file writeData:writeData];

	/* Remove cache. */
	[self.temporaryWriteString setString:NSStringEmptyPlaceholder];
}

- (void)updateWriteCacheTimer
{
	/* Cancel any previous perform requests. aka timers. */
	[NSObject cancelPreviousPerformRequestsWithTarget:self];

	if ([TPCPreferences logTranscriptInBatches]) {
		/* Clear any existing buffer and reset timer. */
		[self updateWriteCacheInternalInit];
	} else {
		/* We aren't writing in batches anymore. Do we have a previous cache? */
		[self updateWriteCache];

		/* nil out any existing cache store. */
		self.temporaryWriteString = nil;
	}
}

#pragma mark -
#pragma mark File Handle Management

- (void)reset
{
	/* Reset plain text file. */
	PointerIsEmptyAssert(self.file);

	self.temporaryWriteString = nil;

	[self.file truncateFileAtOffset:0];
}

- (void)close
{
	/* Close plain text file. */
	PointerIsEmptyAssert(self.file);

	[self updateWriteCache];

	[self.file closeFile];
	self.file = nil;

	self.filename = nil; // Invalidate everything. 
}

- (void)reopenIfNeeded
{
	/* This call is designed to reopen the file pointer when using 
	 the date as the filename. When the date changes, the log path
	 will have to change as well. This handles that. */
	
	if ([self.filename isEqualToString:self.buildFileName] == NO) {
		[self open];
	}
}

- (void)open
{
	/* Reset everything. */
	[self close];

	/* Where are we writing to? */
	NSString *path = self.fileWritePath;

	NSObjectIsEmptyAssert(path);

	/* What will the filename be? The filename
	 includes the folder being written to. */
	self.filename = [self buildFileName];

	/* Make sure the folder being written to exists. */
	/* We extract the folder from self.filename for this
	 check instead of using "path" because the generation
	 of self.filename may have added extra directories to 
	 the structure of the path beyond what "path" provided. */
	NSString *folder = [self.filename stringByDeletingLastPathComponent];
	
	if ([RZFileManager() fileExistsAtPath:folder isDirectory:NULL] == NO) {
		NSError *fmerr;
		
		[RZFileManager() createDirectoryAtPath:folder withIntermediateDirectories:YES attributes:nil error:&fmerr];

		if (fmerr) {
			LogToConsole(@"Error Creating Folder: %@", [fmerr localizedDescription]);
		}
	}

	/* Does the file exist? */
	if ([RZFileManager() fileExistsAtPath:self.filename] == NO) {
		[RZFileManager() createFileAtPath:self.filename contents:[NSData data] attributes:nil];
	}

	/* Open our file handle. */
	self.file = [NSFileHandle fileHandleForUpdatingAtPath:self.filename];

	if (self.file) {
		[self.file seekToEndOfFile];
	}

	[self updateWriteCacheInternalInit];
}

#pragma mark -
#pragma mark File Handler Path

- (NSString *)fileWritePath
{
	return [TPCPreferences transcriptFolder];
}

- (NSString *)buildPath
{
	return [self buildPath:YES];
}

- (NSString *)buildPath:(BOOL)forceUUID
{
	NSString *base = self.fileWritePath;

	NSObjectIsEmptyAssertReturn(base, nil);

	NSString *serv = [self.client.name safeFilename];
	NSString *chan = [self.channel.name safeFilename];

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
		NSString *oldPath = [self buildPath:NO];

		/* Does the old path exist? */
		if ([RZFileManager() fileExistsAtPath:oldPath]) {
			return oldPath;
		}

		/* It did not exist… use new naming scheme. */
		NSString *servHead = [self.client.config.itemUUID safeSubstringToIndex:5];

		serv = [serv stringByAppendingFormat:@" (%@)", servHead];
	}
	
	if (PointerIsEmpty(self.channel)) {
		return [base stringByAppendingFormat:@"/%@/%@/", serv, TLOFileLoggerConsoleDirectoryName];
	} else if (self.channel.isPrivateMessage) {
		return [base stringByAppendingFormat:@"/%@/%@/%@/", serv, TLOFileLoggerPrivateMessageDirectoryName, chan];
	} else {
		return [base stringByAppendingFormat:@"/%@/%@/%@/", serv, TLOFileLoggerChannelDirectoryName, chan];
	}

	return base;
}

- (NSString *)buildFileName
{
	NSDate *filename = [[NSDate date] dateWithCalendarFormat:@"%Y-%m-%d" timeZone:nil];

	NSString *buildPath = self.buildPath;

	NSObjectIsEmptyAssertReturn(buildPath, NSStringEmptyPlaceholder);

	return [NSString stringWithFormat:@"%@%@.txt", buildPath, filename];
}

#pragma mark -
#pragma mark Memory Management

- (void)dealloc
{
	[self close];
}

@end
