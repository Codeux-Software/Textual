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

@interface TVCLogControllerHistoricLogFile ()
@property (nonatomic, strong) NSMutableDictionary *temporaryPropertyList;
@property (nonatomic, strong) NSString *filename;
@end

@implementation TVCLogControllerHistoricLogFile

#pragma mark -
#pragma mark Read Data

- (NSDictionary *)data
{
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

#pragma mark -
#pragma mark Property List API

- (void)writePropertyListEntry:(NSDictionary *)s toKey:(NSString *)key
{
	[self reopenIfNeeded];

	PointerIsEmptyAssert(self.temporaryPropertyList);

	[self.temporaryPropertyList safeSetObject:s forKey:key];
}

- (void)updateCache
{
	[NSObject cancelPreviousPerformRequestsWithTarget:self];

	[self updatePropertyListCache];
}

- (void)updatePropertyListCache /* @private */
{
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
	/* Reset property list. */

	[RZFileManager() removeItemAtPath:self.filename error:NULL];

	[NSObject cancelPreviousPerformRequestsWithTarget:self];

	[self.temporaryPropertyList removeAllObjects];

	self.filename = nil; // Invalidate everything.
}

- (void)close
{
	/* Close property list. */

	self.temporaryPropertyList = nil;

	[NSObject cancelPreviousPerformRequestsWithTarget:self];

	self.filename = nil; // Invalidate everything.
}

- (void)reopenIfNeeded
{
	if (NSObjectIsEmpty(self.filename)) {
		[self open];
	}
}

- (void)open
{
	NSAssert(PointerIsNotEmpty(self.owner), @"Unknown owner.");

	/* Reset everything. */
	[self close];

	/* Where are we writing to? */
	NSString *path = self.fileWritePath;

	NSObjectIsEmptyAssert(path);

	/* What will the filename be? The filename
	 includes the folder being written to. */
	self.filename = [self buildFileName];

	/* Make sure the folder being written to exists. */
	if ([RZFileManager() fileExistsAtPath:path isDirectory:NULL] == NO) {
		NSError *fmerr;

		[RZFileManager() createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:&fmerr];

		if (fmerr) {
			LogToConsole(@"Error Creating Folder: %@", [fmerr localizedDescription]);
		}
	}

	/* Does the file exist? */
	if ([RZFileManager() fileExistsAtPath:self.filename] == NO) {
		[RZFileManager() createFileAtPath:self.filename contents:[NSData data] attributes:nil];
	}

	/* Property list specific additions. */
	self.temporaryPropertyList = [NSMutableDictionary dictionary];

	[self updatePropertyListCache];
}

#pragma mark -
#pragma mark File Handler Path

- (NSString *)fileWritePath
{
	return [TPCPreferences applicationCachesFolderPath];
}

- (NSString *)buildFileName
{
	/* Get the UUID to use for filename. */
	NSString *ownerUUID;

	if (self.owner.channel) {
		ownerUUID = self.owner.channel.config.itemUUID;
	} else {
		ownerUUID = self.owner.client.config.itemUUID;
	}

	/* Return result. */
	return [NSString stringWithFormat:@"%@historic-Log-%@.plist", self.fileWritePath, ownerUUID];
}

#pragma mark -
#pragma mark Memory Management

- (void)dealloc
{
	[self close];
}

@end
