/* ********************************************************************* 
       _____        _               _    ___ ____   ____
      |_   _|___  _| |_ _   _  __ _| |  |_ _|  _ \ / ___|
       | |/ _ \ \/ / __| | | |/ _` | |   | || |_) | |
       | |  __/>  <| |_| |_| | (_| | |   | ||  _ <| |___
       |_|\___/_/\_\\__|\__,_|\__,_|_|  |___|_| \_\\____|

 Copyright (c) 2010 — 2012 Codeux Software & respective contributors.
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

@implementation TLOFileLogger
{
	NSMutableDictionary *_temporaryPropertyListItems;
}

- (void)dealloc
{
	[self close];
}

#pragma mark -
#pragma mark Reading API

- (id)data
{
	if (self.writePlainText) {
		return [self.file availableData];
	} else {
		NSMutableDictionary *propertyList = self.propertyList.mutableCopy;

		// ---- //
		
		if (NSObjectIsNotEmpty(_temporaryPropertyListItems)) {
			[propertyList addEntriesFromDictionary:_temporaryPropertyListItems];
		}

		// ---- //

		if (self.maxEntryCount >= 1) {
			if (propertyList.count >= self.maxEntryCount) {
				NSArray *reverKkeys = propertyList.sortedDictionaryReversedKeys;

				NSMutableDictionary *newDict = [NSMutableDictionary dictionary];

				NSInteger loopCount = 0;

				// ---- //

				for (NSString *key in reverKkeys) {
					if (loopCount >= self.maxEntryCount) {
						break;
					}
					
					[newDict setObject:[propertyList objectForKey:key] forKey:key];

					loopCount += 1;
				}

				// ---- //

				return [newDict sortedDictionary];
			}
		}

		// ---- //

		return [propertyList sortedDictionary];
	}

	return nil;
}

#pragma mark -
#pragma mark Writing API

- (void)writePlainTextLine:(NSString *)s
{
	if (self.writePlainText == NO) {
		return;
	}

	// ---- //

	[self reopenIfNeeded];

	// ---- //

	if (self.file) {
		s = [s stringByAppendingString:NSStringNewlinePlaceholder];

		// ---- //

		NSData *data = [self.client convertToCommonEncoding:s];

		// ---- //

		if (data) {
			[self.file writeData:data];
		}
	}
}

- (void)writePropertyListEntry:(NSDictionary *)s toKey:(NSString *)key
{
	if (self.writePlainText == NO) {
		[self reopenIfNeeded];

		// ---- //
		
		if (PointerIsEmpty(_temporaryPropertyListItems)) {
			_temporaryPropertyListItems = [NSMutableDictionary dictionary];
		}

		// ---- //

		[_temporaryPropertyListItems setObject:s forKey:key];
	}
}

#pragma mark -

- (void)updateCache
{
	if (self.writePlainText) {
		return;
	}
	
	[NSObject cancelPreviousPerformRequestsWithTarget:self];

	[self updatePropertyListCache];
}

- (void)updatePropertyListCache /* @private */
{
	if (self.writePlainText == NO) {
		/* We loop updatePropertyListCache every one minute to write any unsaved property
		 list items to disk. Creating a property list and writing it to disk every time a new
		 entry is created is probably a bad idea so we save periodically. */
		
		[self performSelector:@selector(updatePropertyListCache) withObject:nil afterDelay:60.0];

		// ---- //
		
		if (NSObjectIsEmpty(_temporaryPropertyListItems)) { // check if it is empty or nil
			return;
		}

		// ---- //

		NSDictionary *propertyList = [self data];

		// ---- //
		
		NSString *parseError;

#ifdef DEBUG
		NSPropertyListFormat format = NSPropertyListXMLFormat_v1_0;
#else
		NSPropertyListFormat format = NSPropertyListBinaryFormat_v1_0;
#endif

		NSData *plist = [NSPropertyListSerialization dataFromPropertyList:propertyList
																   format:format
														 errorDescription:&parseError];

		// ---- //
		
		if (NSObjectIsEmpty(plist) || parseError) {
			LogToConsole(@"Error Creating Property List: %@", parseError);
		} else {
			NSError *dataWriteError;

			[plist writeToFile:self.filename options:0 error:&dataWriteError];

			if (dataWriteError) {
				LogToConsole(@"Error Writing Property List: %@", [dataWriteError localizedDescription]);

				[_temporaryPropertyListItems removeAllObjects];
			}
		}
	}
}

- (NSDictionary *)propertyList /* @private */
{
	if (self.writePlainText == NO) {
		NSError *readError;
		
		NSData *rawData = [NSData dataWithContentsOfFile:self.filename
												 options:NSDataReadingUncached
												   error:&readError];

		if (readError) {
			LogToConsole(@"Error Reading Property List: %@", [readError localizedDescription]);

			return [NSDictionary dictionary];
		}

		// ---- //

		if (NSObjectIsEmpty(rawData)) {
			return [NSDictionary dictionary];
		}

		// ---- //
		
		NSString *parseError;

		NSDictionary *plist = [NSPropertyListSerialization propertyListFromData:rawData
															   mutabilityOption:NSPropertyListImmutable
																		 format:NULL
															   errorDescription:&parseError];

		if (readError) {
			DebugLogToConsole(@"Error Reading Property List: %@", parseError);
		} else {
			return plist;
		}
	}

	return [NSDictionary dictionary];
}

#pragma mark -
#pragma mark File Handle Management

- (void)reset
{
	if (self.file) {
		[self.file truncateFileAtOffset:0];
	}

	// ---- //

	if (self.writePlainText == NO) {
		[_NSFileManager() createFileAtPath:self.filename contents:[NSData data] attributes:nil];
		
		if (PointerIsNotEmpty(_temporaryPropertyListItems)) {
			[_temporaryPropertyListItems removeAllObjects];
		}

		[NSObject cancelPreviousPerformRequestsWithTarget:self];

		// ---- //

		[self updatePropertyListCache];
	}
}

- (void)close
{
	if (self.file) {
		[self.file closeFile];

		self.file = nil;
	}
}

- (void)reopenIfNeeded
{
	if ([self.filename isEqualToString:self.buildFileName] == NO) {
		[self open];
	}
}

- (void)open
{
	[self close];

	// ---- //
	
	if (self.writePlainText == NO) {
		[self updatePropertyListCache];
	}

	// ---- //

	NSString *path = self.fileWritePath;

	if (NSObjectIsEmpty(path)) {
		return;
	}

	if (NSObjectIsEmpty(self.filename)) {
		self.filename = [self buildFileName];
	}

	// ---- //

	BOOL isDirectory = NO;
	
	NSString *dir = [self.filename stringByDeletingLastPathComponent];
	
	if ([_NSFileManager() fileExistsAtPath:dir isDirectory:&isDirectory] == NO) {
		NSError *fmerr;
		
		[_NSFileManager() createDirectoryAtPath:dir withIntermediateDirectories:YES attributes:nil error:&fmerr];

		if (fmerr) {
			LogToConsole(@"Error Creating Folder: %@", [fmerr localizedDescription]);
		}
	}

	// ---- //
	
	if ([_NSFileManager() fileExistsAtPath:self.filename] == NO) {
		[_NSFileManager() createFileAtPath:self.filename contents:[NSData data] attributes:nil];
	}

	// ---- //
	
	if (self.writePlainText) {
		/* NSFileHandle does not always have immediate access to written data. It did not
		 in our original implementation of our property list addon. To accomidate for this,
		 TLOFileLogger writes and reads directly to disk for property lists instead of relying
		 on a file handle. That did not work well for us. */

		self.file = [NSFileHandle fileHandleForUpdatingAtPath:self.filename];

		if (self.file) {
			[self.file seekToEndOfFile];
		}
	}

}

#pragma mark -
#pragma mark File Handle Path

- (NSString *)fileWritePath
{
	if (NSObjectIsEmpty(_fileWritePath)) {
		return [TPCPreferences transcriptFolder];
	}

	return _fileWritePath;
}

- (NSString *)buildPath
{
	NSString *base = self.fileWritePath;

	if (self.flatFileStructure) {
		return base;
	}

	NSString *serv = [self.client.name  safeFileName];
	NSString *chan = [self.channel.name safeFileName];
	
	if (PointerIsEmpty(self.channel)) {
		return [base stringByAppendingFormat:@"/%@/%@/", serv, TLOFileLoggerConsoleDirectoryName];
	} else if (self.channel.isTalk) {
		return [base stringByAppendingFormat:@"/%@/%@/%@/", serv, TLOFileLoggerPrivateMessageDirectoryName, chan];
	} else {
		return [base stringByAppendingFormat:@"/%@/%@/%@/", serv, TLOFileLoggerChannelDirectoryName, chan];
	}
}

- (NSString *)buildFileName
{
	id date;
	id extn;
	
	if (self.flatFileStructure) {
		extn = @"plist";
	} else {
		extn = @"txt";
	}

	if (NSObjectIsNotEmpty(self.filenameOverride)) {
		date = self.filenameOverride;
	} else {
		date = [NSDate.date dateWithCalendarFormat:@"%Y-%m-%d" timeZone:nil];
	}
	
	return [NSString stringWithFormat:@"%@%@.%@", [self buildPath], date, extn];
}

@end