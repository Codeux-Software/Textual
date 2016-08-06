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

NS_ASSUME_NONNULL_BEGIN

@interface TVCLogControllerHistoricLogFile ()
@property (nonatomic, strong) TVCLogController *viewController;
@property (nonatomic, strong, nullable) NSFileHandle *fileHandle;
@property (nonatomic, assign) BOOL truncationEventScheduled;
@end

@implementation TVCLogControllerHistoricLogFile

#pragma mark -
#pragma mark Public API

+ (dispatch_queue_t)dispatchQueue
{
	static dispatch_queue_t dispatchQueue = NULL;

	static dispatch_once_t onceToken;

	dispatch_once(&onceToken, ^{
		dispatchQueue = dispatch_queue_create("HistoricLogFileDispatchQueue", DISPATCH_QUEUE_SERIAL);
	});

	return dispatchQueue;
}

ClassWithDesignatedInitializerInitMethod

- (instancetype)initWithViewController:(TVCLogController *)viewController
{
	NSParameterAssert(viewController != nil);

	if ((self = [super init])) {
		self.viewController = viewController;

		return self;
	}

	return nil;
}

+ (void)prepareForPermanentDestruction
{
	dispatch_suspend([TVCLogControllerHistoricLogFile dispatchQueue]);
}

- (void)writeNewEntryWithData:(NSData *)data
{
	XRPerformBlockAsynchronouslyOnQueue([TVCLogControllerHistoricLogFile dispatchQueue], ^{
		[self _writeNewEntryWithData:data];
	});
}

- (void)writeNewEntryWithLogLine:(TVCLogLine *)logLine
{
	XRPerformBlockAsynchronouslyOnQueue([TVCLogControllerHistoricLogFile dispatchQueue], ^{
		[self _writeNewEntryWithLogLine:logLine];
	});
}

- (void)open
{
	XRPerformBlockAsynchronouslyOnQueue([TVCLogControllerHistoricLogFile dispatchQueue], ^{
		(void)[self _reopenFileHandleIfNeeded];
	});
}

- (void)close
{
	XRPerformBlockAsynchronouslyOnQueue([TVCLogControllerHistoricLogFile dispatchQueue], ^{
		[self _close];
	});
}

- (void)reset
{
	XRPerformBlockAsynchronouslyOnQueue([TVCLogControllerHistoricLogFile dispatchQueue], ^{
		[self _reset];
	});
}

- (void)_writeNewEntryWithData:(NSData *)data
{
	NSParameterAssert(data != nil);

	if ([self _reopenFileHandleIfNeeded] == NO) {
		return;
	}

	@try {
		[self.fileHandle writeData:data];

		[self _scheduleTruncationEvent];
	}
	@catch (NSException *exception) {
		self.fileHandle = nil;

		LogToConsoleError("Caught exception: %{public}@", exception.reason)
		LogToConsoleCurrentStackTrace
	}
}

- (void)_writeNewEntryWithLogLine:(TVCLogLine *)logLine
{
	NSParameterAssert(logLine != nil);

	NSData *jsonRepresentation = logLine.jsonRepresentation;

	[self writeNewEntryWithData:jsonRepresentation];

	[self writeNewEntryWithData:[NSData lineFeed]];
}

- (BOOL)_reopenFileHandleIfNeeded
{
	if (self.fileHandle == nil) {
		return [self _openFileHandle];
	}

	return YES;
}

- (BOOL)_openFileHandle
{
	NSString *path = self.writePath;

	NSString *pathLeading = path.stringByDeletingLastPathComponent;

	if ([RZFileManager() fileExistsAtPath:pathLeading] == NO) {
		NSError *createDirectoryError = nil;

		if ([RZFileManager() createDirectoryAtPath:pathLeading withIntermediateDirectories:YES attributes:nil error:&createDirectoryError] == NO) {
			LogToConsoleError("Error Creating Folder: %{public}@",
				createDirectoryError.localizedDescription)

			return NO;
		}
	}

	if ([RZFileManager() fileExistsAtPath:path] == NO) {
		NSError *writeFileError = nil;

		if ([NSStringEmptyPlaceholder writeToFile:path atomically:NO encoding:NSUTF8StringEncoding error:&writeFileError] == NO) {
			LogToConsoleError("Error Creating File: %{public}@",
				writeFileError.localizedDescription)

			return NO;
		}
	}

	self.fileHandle = [NSFileHandle fileHandleForUpdatingAtPath:path];

	if ( self.fileHandle) {
		[self.fileHandle seekToEndOfFile];

		return YES;
	}

	LogToConsoleError("Failed to open file handle at path '%{public}@'", path)

	return NO;
}

- (void)_close
{
	if ( self.fileHandle) {
		[self.fileHandle synchronizeFile];
		[self.fileHandle closeFile];
		 self.fileHandle = nil;
	}

	[self _cancelTruncationEvent];
}

- (void)_reset
{
	[self _close];

	/* error: is ignored because file may not exist at all so 
	 no reason to report that when we already know it. */
	(void)[RZFileManager() removeItemAtPath:self.writePath error:NULL];
}

- (void)_cancelTruncationEvent
{
	if (self.truncationEventScheduled) {
		self.truncationEventScheduled = NO;

		[self cancelPerformRequests];
	}
}

- (void)_scheduleTruncationEvent
{
	/* File truncation events are scheduled to happen at random
	 intervals so they are all not running at one time. */
	if (self.truncationEventScheduled == NO) {
		self.truncationEventScheduled = YES;

		NSUInteger timeInterval = TXRandomNumber(1800); // ~30 minutes

		[self performBlockOnMainThread:^{
			[self performSelector:@selector(_truncateFile)
					   withObject:nil
					   afterDelay:timeInterval];
		}];
	}
}

- (void)_truncateFile
{
	/* It is acceptable for -listEntriesWithFetchLimit: to return incomplete JSON data (corrupt)
	 which means the truncate process is very easy. Get last X bytes from file, clear the file, 
	 then place those bytes back in the file, save the file. */
	XRPerformBlockAsynchronouslyOnQueue([TVCLogControllerHistoricLogFile dispatchQueue], ^{
		if ([self _reopenFileHandleIfNeeded] == NO) {
			return;
		}

		const unsigned long long filesizeMax = (1000 * 1000 * 8); // 1 megabyte;

		unsigned long long filesize = [self.fileHandle seekToEndOfFile];

		if (filesize < filesizeMax) {
			return;
		}

		[self.fileHandle seekToFileOffset:(filesize - filesizeMax)];

		NSData *dataToRetain = [self.fileHandle readDataOfLength:filesizeMax];

		[self.fileHandle truncateFileAtOffset:0];

		[self.fileHandle writeData:dataToRetain];

		[self.fileHandle synchronizeFile];

		dataToRetain = nil;
	});

	self.truncationEventScheduled = NO;
}

- (NSArray<NSData *> *)listEntriesWithFetchLimit:(NSUInteger)fetchLimit
{
	NSParameterAssert(fetchLimit > 0);

	NSMutableArray<NSData *> *items = [NSMutableArray arrayWithCapacity:fetchLimit];

	const unsigned long long offsetChunkSize = (1000 * 50 * 8); // 50 kilobytes

	NSData *lineFeed = [NSData lineFeed];

	XRPerformBlockSynchronouslyOnQueue([TVCLogControllerHistoricLogFile dispatchQueue], ^{
		if ([self _reopenFileHandleIfNeeded] == NO) {
			return;
		}

		/* This procedure works backwards, from the bottom of the file, upwards.
		 The file is read in chunks, as defined by /offsetChunkSize/ */
		unsigned long long filesize = [self.fileHandle seekToEndOfFile];

		unsigned long long bytesRemaining = filesize;

		while (bytesRemaining > 0) {
			/* Calculate the index of the next chunk and its length */
			long long nextOffset = (bytesRemaining - offsetChunkSize);
			long long nextOffsetLength = offsetChunkSize;

			if (nextOffset < 0) {
				nextOffset = 0;
				nextOffsetLength = bytesRemaining;
			}

			/* Seek to next chunk then extract the chunk itself */
			[self.fileHandle seekToFileOffset:nextOffset];

			NSData *chunkedData = [self.fileHandle readDataOfLength:nextOffsetLength];

			/* Enumerate over lines and subdata the objects they separate */
			__block BOOL fetchLimitExceeded = NO;

			__block NSRange lastRangeProcessed = NSMakeRange(NSNotFound, 0);

			[chunkedData enumerateMatchesOfData:lineFeed
									  withBlock:^(NSRange range, BOOL *stop) {
				  if (lastRangeProcessed.location == NSNotFound) {
					  lastRangeProcessed = NSMakeRange(range.location, (chunkedData.length - range.location));
				  } else {
					  lastRangeProcessed = NSMakeRange(range.location, (lastRangeProcessed.location - range.location));
				  }

				  NSData *subdata = [chunkedData subdataWithRange:lastRangeProcessed];

				  if ([subdata isEqual:lineFeed]) { // Empty data
					  return;
				  }

				  [items addObject:subdata];

				  if (items.count == fetchLimit) {
					  fetchLimitExceeded = YES;
				  }
			  } options:NSDataSearchBackwards];

			if (fetchLimitExceeded) {
				break;
			}

			/* If there was no data to be divided because a line break could not be found,
			 then just add the entire chunk to the outgoing array */
			if (lastRangeProcessed.location == NSNotFound)
			{
				[items addObject:chunkedData];
			}

			/* Capture any data that remains when at the top of the file. */
			else if (lastRangeProcessed.location > 0 && nextOffset == 0)
			{
				lastRangeProcessed = NSMakeRange(0, lastRangeProcessed.location);

				NSData *subdata = [chunkedData subdataWithRange:lastRangeProcessed];

				[items addObject:subdata];
			}

			/* Update math to move to next chunk */
			if (nextOffset == 0) {
				break;
			}

			bytesRemaining -= (nextOffsetLength + lastRangeProcessed.location);
		} // while()
	});

	/* Reading from the bottom up which means the array needs to be reversed */
	return items.reverseObjectEnumerator.allObjects;
}

#pragma mark -
#pragma mark Private API

- (NSString *)writePath
{
	IRCClient *client = self.viewController.associatedClient;
	IRCChannel *channel = self.viewController.associatedChannel;

	NSString *combinedName = nil;

	if (channel) {
		combinedName = [NSString stringWithFormat:@"/MessageArchive/%@/historicLogFile-%@.json", client.uniqueIdentifier, channel.uniqueIdentifier];
	} else {
		combinedName = [NSString stringWithFormat:@"/MessageArchive/%@/historicLogFile-console.json", client.uniqueIdentifier];
	}

	NSString *cachesFolder = [TPCPathInfo applicationCachesFolderPath];

	return [cachesFolder stringByAppendingPathComponent:combinedName];
}

@end

NS_ASSUME_NONNULL_END
