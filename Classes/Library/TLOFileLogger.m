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

- (void)dealloc
{
	[self close];
}

#pragma mark -
#pragma mark Writing API

- (void)writePlainTextLine:(NSString *)s
{
	if (self.writePlainText == NO) {
		return;
	}

	[self reopenIfNeeded];

	if (self.file) {
		s = [s stringByAppendingString:NSStringNewlinePlaceholder];

		NSData *data = [s dataUsingEncoding:self.client.encoding];

		if (NSObjectIsEmpty(data)) {
			data = [s dataUsingEncoding:self.client.config.fallbackEncoding];

			if (NSObjectIsEmpty(data)) {
				data = [s dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES];
			}
		}

		if (data) {
			[self.file writeData:data];
		}
	}
}

- (void)writePropertyListEntry:(NSDictionary *)s toKey:(NSString *)key
{
	if (self.writePlainText) {
		return;
	}

	[self reopenIfNeeded];

	if (self.file) {
		NSMutableDictionary *propertyList = self.propertyList.mutableCopy;

		if (PointerIsEmpty(propertyList)) {
			return;
		}

		[propertyList setObject:s forKey:key];

		// ---- //

		NSString *writeError;

		NSData *plist = [NSPropertyListSerialization dataFromPropertyList:propertyList
																   format:NSPropertyListBinaryFormat_v1_0
														 errorDescription:&writeError];

		if (NSObjectIsEmpty(plist) || writeError) {
			LogToConsole(@"Error Creating Property List: %@", writeError);
		} else {
			[self.file truncateFileAtOffset:0];
			[self.file writeData:plist];
		}
	}
}

- (NSDictionary *)propertyList /* @private */
{
	if (self.file && self.writePlainText == NO) {
		NSData *rawData = [self.file readDataToEndOfFile];

		NSString *readError;

		NSDictionary *plist = [NSPropertyListSerialization propertyListFromData:rawData
															   mutabilityOption:NSPropertyListImmutable
																		 format:NULL
															   errorDescription:&readError];

		if (readError) {
			LogToConsole(@"Error Reading Property List: %@", readError);

			return nil;
		}

		return plist;
	}

	return nil;
}

#pragma mark -
#pragma mark File Handle Management

- (void)reset
{
	if (self.file) {
		[self.file truncateFileAtOffset:0];
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
	if (NSObjectIsEmpty(self.filename) ||
		([self.filename isEqualToString:self.buildFileName] == NO
		 && self.hashFilename == NO)
		) {

		[self open];
	}
}

- (void)open
{
	[self close];

	NSString *path = self.fileWritePath;

	DebugLogToConsole(@"%@", path);

	if (NSObjectIsEmpty(path)) {
		return;
	}

	if (self.hashFilename == NO || NSObjectIsEmpty(self.filename)) {
		self.filename = [self buildFileName];
	}
	
	NSString *dir = [self.filename stringByDeletingLastPathComponent];
	
	BOOL isDir = NO;
	
	if ([_NSFileManager() fileExistsAtPath:dir isDirectory:&isDir] == NO) {
		NSError *fmerr;
		
		[_NSFileManager() createDirectoryAtPath:dir withIntermediateDirectories:YES attributes:nil error:&fmerr];

		if (fmerr) {
			LogToConsole(@"Error Creating Folder: %@", [fmerr localizedDescription]);
		}
	}
	
	if ([_NSFileManager() fileExistsAtPath:self.filename] == NO) {
		[_NSFileManager() createFileAtPath:self.filename contents:[NSData data] attributes:nil];
	}
	
	self.file = [NSFileHandle fileHandleForUpdatingAtPath:self.filename];
	
	if (self.file) {
		[self.file seekToEndOfFile];
	}

	DebugLogToConsole(@"%@", self.filename);
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

	if (self.hashFilename) {
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
	
	if (self.hashFilename) {
		date = [NSString stringWithUUID];
	} else {
		date = [NSDate.date dateWithCalendarFormat:@"%Y-%m-%d" timeZone:nil];
	}
	
	return [NSString stringWithFormat:@"%@%@.txt", [self buildPath], date];
}

@end