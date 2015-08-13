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

#warning TVCLogControllerHistoricLogFile FIXME: This file requires a significant overhaul.

#define _usesBackgroundActivityTask			0

#define _maximumRowCountPerClient			1000

@interface TVCLogControllerHistoricLogFile ()
@property (nonatomic, strong) NSFileHandle *fileHandle;
@property (nonatomic, assign) BOOL truncationTimerScheduled;
@end

@implementation TVCLogControllerHistoricLogFile

#pragma mark -
#pragma mark Public API

- (void)writeNewEntryWithRawData:(NSData *)jsondata
{
	if (self.fileHandle == nil) {
		[self open];
	}

	if (self.fileHandle) {
		@try {
			[self.fileHandle writeData:jsondata];

			[self scheduleNextRandomFileTruncationEvent];
		}
		@catch (NSException *exception) {
			self.fileHandle = nil;

			LogToConsole(@"An exception happened to a non-critical component of Textual.");
		}
	}
}

- (void)writeNewEntryForLogLine:(TVCLogLine *)logLine
{
	NSData *jsondata = [logLine jsonDictionaryRepresentation];

	[self writeNewEntryWithRawData:jsondata];
	[self writeNewEntryWithRawData:[NSData lineFeed]];
}

- (void)open
{
	/* Where are we writing to? */
	NSString *rawpath = [self writePath];

	NSURL *path = [NSURL fileURLWithPath:rawpath];

	/* Make sure the folder being written to exists. */
	NSURL *folder = [path URLByDeletingLastPathComponent];

	if ([RZFileManager() fileExistsAtPath:[folder path] isDirectory:NULL] == NO) {
		NSError *fmerr = nil;

		[RZFileManager() createDirectoryAtURL:folder withIntermediateDirectories:YES attributes:nil error:&fmerr];

		if (fmerr) {
			LogToConsole(@"Error Creating Folder: %@", [fmerr localizedDescription]);

			[self close]; // We couldn't create the folder. Destroy everything.

			return;
		}
	}

	/* Does the file exist? */
	if ([RZFileManager() fileExistsAtPath:rawpath] == NO) {
		NSError *fcerr = nil;

		[NSStringEmptyPlaceholder writeToURL:path atomically:NO encoding:NSUTF8StringEncoding error:&fcerr];

		if (fcerr) {
			LogToConsole(@"Error Creating File: %@", [fcerr localizedDescription]);

			[self close]; // We couldn't create the file. Destroy everything.

			return;
		}
	}

	/* Open our file handle. */
	self.fileHandle = [NSFileHandle fileHandleForUpdatingAtPath:rawpath];

	if ( self.fileHandle) {
		[self.fileHandle seekToEndOfFile];
	} else {
		LogToConsole(@"Failed to open file handle at path \"%@\". Unkown reason.", rawpath);
	}
}

- (void)close
{
	if ( self.fileHandle) {
		[self.fileHandle synchronizeFile];
		[self.fileHandle closeFile];
		 self.fileHandle = nil;
	}

	[self cancelAnyPreviouslyScheduledFileTruncationEvents];
}

- (void)resetData
{
	/* Close anything already open. */
	[self close];

	/* Destroy file at write path. */
	/* error: is ignored because file may not exist at all so 
	 no reason to report that when we already know it. */
	[RZFileManager() removeItemAtPath:[self writePath] error:NULL];
}

- (void)cancelAnyPreviouslyScheduledFileTruncationEvents
{
	if (self.truncationTimerScheduled) {
		[NSObject cancelPreviousPerformRequestsWithTarget:self];

		self.truncationTimerScheduled = NO;
	}
}

- (void)scheduleNextRandomFileTruncationEvent
{
	/* File truncation events are scheduled to happen at random 
	 intervals so they are all not running at one time. */

	if (self.truncationTimerScheduled == NO) {
		NSInteger timeInterval = ((arc4random() % 951) + 950); // ~15 minutes

		[self performSelector:@selector(truncateFileToMatchDefinedMaximumLineCount)
				   withObject:nil
				   afterDelay:timeInterval];

		self.truncationTimerScheduled = YES;
	}
}

- (void)truncateFileToMatchDefinedMaximumLineCount
{
	DebugLogToConsole(@"Performing truncation on file to meet maximum line count of %i.", _maximumRowCountPerClient);

	@autoreleasepool {
		/* Close the open file handle. */
		[self close];

		/* Read contents of file. */
		NSData *rawdata = [NSData dataWithContentsOfFile:[self writePath] options:NSDataReadingUncached error:NULL];

		NSObjectIsEmptyAssert(rawdata);

		/* Discussion: Yes, I could simply convert this NSData chunk to 
		 an NSString, split it, and be done with it... BUT, NSJSONSerialization
		 which the data will ultimately be fed to only accepts NSData so
		 the workload of converting this to NSString then converting the
		 individual chunks back to NSData is a lot of overhead. That is
		 why I implement such a messy while loop that gets the range of
		 every newline and breaks it apart into smaller data. */
		/* The same idea applies to the code for reading entries which
		 is inherited from this codebase. */
		/* Seek each newline, truncate to that, insert into array, then
		 find the next one and repeat process until there are no more. */
		NSMutableArray *alllines = [NSMutableArray array];

		NSMutableData *mutdata = [rawdata mutableCopy];

		NSInteger startIndex = 0;

		while (1 == 1) {
			/* Our scan range is the range from last newline. */
			NSRange scanrange = NSMakeRange(startIndex, ([mutdata length] - startIndex));

			NSRange nlrang = [mutdata rangeOfData:[NSData lineFeed] options:0 range:scanrange];

			/* If no more newlines are found, then there is nothing to do. */
			if (nlrang.location == NSNotFound) {
				break; // No newline was found.
			} else {
				[alllines addObject:@(nlrang.location)];

				startIndex = (nlrang.location + 1);
			}
		}

		/* Now that we have all lines, limit them based on fetch count. */
		if ([alllines count] > _maximumRowCountPerClient) {
			/* The last possible index is the line which will be truncated to. This line
			 is calculated by taking the maximum number of clients and subtracting the
			 file number of lines from it. That will give us a negative number, so we
			 times it by -1. After that, we minus one so the only rows remaining are the
			 number that we have defined as maximum. */
			NSInteger lastPosIndex = (((_maximumRowCountPerClient - [alllines count]) * (-1)) - 1);

			/* Add 1 to not have first line a newline. */
			NSInteger lastBytePos = ([alllines integerAtIndex:lastPosIndex] + 1);

			NSRange cutRange = NSMakeRange(lastBytePos, ([rawdata length] - lastBytePos));

			NSData *finalData = [rawdata subdataWithRange:cutRange];

			/* We completely clear out file, write the new data, then save it. */
			NSError *writeError = nil;

			if ([finalData writeToFile:[self writePath] options:NSDataWritingAtomic error:&writeError] == NO) {
				LogToConsole(@"Failed to write file to disk: %@", [writeError localizedDescription]);
			}
		}
	}

	/* Reset timer. */
	self.truncationTimerScheduled = NO;
}

- (NSArray *)listEntriesWithFetchLimit:(NSUInteger)maxEntryCount
{
	@autoreleasepool {
		/* Close the open file handle. */
		[self close];

		/* Read contents of file. */
		NSData *rawdata = [NSData dataWithContentsOfFile:[self writePath] options:NSDataReadingUncached error:NULL];

		NSObjectIsEmptyAssertReturn(rawdata, nil);

		/* Seek each newline, truncate to that, insert into array, then 
		 find the next one and repeat process until there are no more. */
		NSMutableArray *alllines = [NSMutableArray array];

		NSMutableData *mutdata = [rawdata mutableCopy];

		while (1 == 1) {
			NSRange scanrange = NSMakeRange(0, [mutdata length]);

			NSRange nlrang = [mutdata rangeOfData:[NSData lineFeed] options:0 range:scanrange];

			if (nlrang.location == NSNotFound) {
				break; // No newline was found.
			} else {
				NSRange cutRange = NSMakeRange(0, (nlrang.location + 1));

				NSData *chunkedData = [mutdata subdataWithRange:cutRange];

				[alllines addObject:chunkedData];

				[mutdata replaceBytesInRange:cutRange withBytes:NULL length:0];
			}
		}

		/* Now that we have all lines, limit them based on fetch count. */
		if ([alllines count] > maxEntryCount) {
			NSInteger finalCount = [alllines count];

			NSInteger startingIndex = ((maxEntryCount - finalCount) * (-1));

			NSMutableArray *countedEntries = [NSMutableArray array];

			for (NSInteger i = startingIndex; i < finalCount; i++)
			{
				[countedEntries addObject:alllines[i]];
			}

			return countedEntries;
		}

		/* Return found data. */
		return alllines;
	}
}

#pragma mark -
#pragma mark Private API

- (NSString *)writePath
{
	NSString *cachesFolder = [TPCPathInfo applicationCachesFolderPath];

	id client = [self.associatedController associatedClient];
	id channel = [self.associatedController associatedChannel];

	NSString *combinedName = nil;

	if (channel) {
		combinedName = [NSString stringWithFormat:@"/MessageArchive/%@/historicLogFile-%@.json", [client uniqueIdentifier], [channel uniqueIdentifier]];
	} else {
		combinedName = [NSString stringWithFormat:@"/MessageArchive/%@/historicLogFile-console.json", [client uniqueIdentifier]];
	}

	return [cachesFolder stringByAppendingPathComponent:combinedName];
}

@end
