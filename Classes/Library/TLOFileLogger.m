/* ********************************************************************* 
       _____        _               _    ___ ____   ____
      |_   _|___  _| |_ _   _  __ _| |  |_ _|  _ \ / ___|
       | |/ _ \ \/ / __| | | |/ _` | |   | || |_) | |
       | |  __/>  <| |_| |_| | (_| | |   | ||  _ <| |___
       |_|\___/_/\_\\__|\__,_|\__,_|_|  |___|_| \_\\____|

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

#define _emptyDictionary			[NSDictionary dictionary]

@interface TLOFileLogger ()
@property (nonatomic, strong) NSMutableDictionary *temporaryPropertyList;
@end

@implementation TLOFileLogger

#pragma mark -
#pragma mark Read Data

- (id)data
{
	if (self.writePlainText) {
		/* This logger is not designed to be read for plain text logs. 
		 Why would those be read at all? That is why we have not put
		 too much care into this read method for them. */
		
		return [self.file availableData];
	} else {
		NSMutableDictionary *propertyList = [NSMutableDictionary dictionary];

		[propertyList addEntriesFromDictionary:self.propertyList];
		[propertyList addEntriesFromDictionary:self.temporaryPropertyList];

		if (self.maxEntryCount && propertyList.count > self.maxEntryCount) {
			NSArray *sortedKeys = propertyList.sortedDictionaryKeys;

			for (NSString *skey in sortedKeys) {
				NSAssertReturnLoopBreak(propertyList.count > self.maxEntryCount);

				/* We cut out each object in order until the dictionary
				 count is below or equal to the max entry count. */
				[propertyList removeObjectForKey:skey];
			}
		}

		return [propertyList sortedDictionary];
	}

	return nil;
}

#pragma mark -
#pragma mark Plain Text API

- (void)writePlainTextLine:(NSString *)s
{
	NSAssertReturn(self.writePlainText);

	[self reopenIfNeeded];

	PointerIsEmptyAssert(self.file);

	NSString *writeString = [NSString stringWithFormat:@"%@%@", s, NSStringNewlinePlaceholder];

	NSData *writeData = [self.client convertToCommonEncoding:writeString];

	NSObjectIsEmptyAssert(writeData);

	[self.file writeData:writeData];
}

#pragma mark -
#pragma mark Property List API

- (void)writePropertyListEntry:(NSDictionary *)s toKey:(NSString *)key
{
	NSAssertReturn(self.writePlainText == NO);

	/* We use a temporary store for property list writes because we do not
	 write to disk for every new entry. */
	
	[self reopenIfNeeded];

	PointerIsEmptyAssert(self.temporaryPropertyList);

	[self.temporaryPropertyList safeSetObject:s forKey:key];
}

- (void)updateCache
{
	NSAssertReturn(self.writePlainText == NO);
	
	[NSObject cancelPreviousPerformRequestsWithTarget:self];

	[self updatePropertyListCache];
}

- (void)updatePropertyListCache /* @private */
{
	NSAssertReturn(self.writePlainText == NO);

	/* We loop updatePropertyListCache every one minute to write any unsaved property
	 list items to disk. Creating a property list and writing it to disk every time a new
	 entry is created is probably a bad idea so we save periodically. */
	[self performSelector:@selector(updatePropertyListCache) withObject:nil afterDelay:60.0];

	/* If our temporary store is empty, then there is nothing to write. */
	NSObjectIsEmptyAssert(self.temporaryPropertyList);

	/* [self data] combines disk reads and our temporary store to create 
	 our property list to make the call a seamless experience. */
	NSDictionary *propertyList = [self data];
	
	NSString *parseError;

	/* When we are debugging, write the property list as plain text. In production
	 version we save in binary because it is faster and smaller. */
#ifdef DEBUG
	NSPropertyListFormat format = NSPropertyListXMLFormat_v1_0;
#else
	NSPropertyListFormat format = NSPropertyListBinaryFormat_v1_0;
#endif

	/* Create the new property list. */
	NSData *plist = [NSPropertyListSerialization dataFromPropertyList:propertyList
															   format:format
													 errorDescription:&parseError];

	/* Report results. */
	if (NSObjectIsEmpty(plist) || parseError) {
		/* What happens if plist = nil, but parseError is too? What error
		  are we reporting. This error reporting needs some work. */
		
		LogToConsole(@"Error Creating Property List: %@", parseError);
	} else {
		/* Do the write. */
		BOOL writeResult = [plist writeToFile:self.filename atomically:YES];

		if (writeResult) {
			/* Successful write. Clear our temporary store. */

			[self.temporaryPropertyList removeAllObjects];
		} else {
			/* 
				 When I was in fourth grade I asked my English teacher
				 how to spell "write" when referring to the process of 
				 putting pen/pencil to paper. I was sure it was W R I T E. 
				 I made the question very clear to her, but still she insisted
				 that I was wrong. She said that it was spelled R I G H T.
				 Wrong word! I tried explaining. Only got me in trouble.
				 
				 True story. 'MERICA! 
			 */
			
			LogToConsole(@"Write failed.");
		}
	}
}

- (NSDictionary *)propertyList /* @private */
{
	NSAssertReturnR((self.writePlainText == NO), _emptyDictionary);

	NSData *rawData = [NSData dataWithContentsOfFile:self.filename];
	
	NSObjectIsEmptyAssertReturn(rawData, _emptyDictionary);

	NSDictionary *plist = [NSPropertyListSerialization propertyListFromData:rawData
														   mutabilityOption:NSPropertyListImmutable
																	 format:NULL
														   errorDescription:NULL];
	
	NSObjectIsEmptyAssertReturn(plist, _emptyDictionary);

	return plist;
}

#pragma mark -
#pragma mark File Handle Management

- (void)reset
{
	if (self.writePlainText) {
		/* Reset plain text file. */
		
		PointerIsEmptyAssert(self.file);

		[self.file truncateFileAtOffset:0];
	} else {
		/* Reset property list. */

		[RZFileManager() removeItemAtPath:self.filename error:NULL];

		[NSObject cancelPreviousPerformRequestsWithTarget:self];

		[self.temporaryPropertyList removeAllObjects];

		self.filename = nil; // Invalidate everything.
	}
}

- (void)close
{
	if (self.writePlainText) {
		/* Close plain text file. */
		
		PointerIsEmptyAssert(self.file);

		[self.file closeFile];
		self.file = nil;
	} else {
		/* Close property list. */
		
		self.temporaryPropertyList = nil;

		[NSObject cancelPreviousPerformRequestsWithTarget:self];
	}

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

	if (self.writePlainText == NO) {
		/* Property list specific additions. */

		self.temporaryPropertyList = [NSMutableDictionary dictionary];

		[self updatePropertyListCache];
	} else {
		/* Open our file handle. This is only used for plain text logging. 
		 The property list writing requires the entire file to be replaced.
		 This does not work well with a handle. It is best to use NSData 
		 write and read APIs instead. A handle is better for plain text 
		 logging where we are only appending data. Not replacing it. */
		
		self.file = [NSFileHandle fileHandleForUpdatingAtPath:self.filename];

		if (self.file) {
			[self.file seekToEndOfFile];
		}
	}
}

#pragma mark -
#pragma mark File Handler Path

- (NSString *)fileWritePath
{
	NSObjectIsEmptyAssertReturn(_fileWritePath, [TPCPreferences transcriptFolder]);

	return _fileWritePath;
}

- (NSString *)buildPath
{
	return [self buildPath:YES];
}

- (NSString *)buildPath:(BOOL)forceUUID
{
	NSString *base = self.fileWritePath;

	NSObjectIsEmptyAssertReturn(base, nil);

	if (self.flatFileStructure == NO) {
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
	}

	return base;
}

- (NSString *)buildFileName
{
	id filename = self.filenameOverride;
	id extension = @"txt";
	
	if (self.flatFileStructure) {
		extension = @"plist";
	}

	if (NSObjectIsEmpty(filename)) {
		filename = [[NSDate date] dateWithCalendarFormat:@"%Y-%m-%d" timeZone:nil];
	}

	NSString *buildPath = self.buildPath;

	NSObjectIsEmptyAssertReturn(buildPath, NSStringEmptyPlaceholder);

	return [NSString stringWithFormat:@"%@%@.%@", buildPath, filename, extension];
}

#pragma mark -
#pragma mark Memory Management

- (void)dealloc
{
	[self close];
}

@end
