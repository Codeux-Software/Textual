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

- (void)close
{
	if (self.file) {
		[self.file closeFile];
		
		self.file = nil;
	}
}

- (void)writeLine:(NSString *)s
{
    if (self.client.isConnected == NO) {
        return;
    }
    
	[self open];
	
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

- (void)reopenIfNeeded
{
	if (NSObjectIsEmpty(self.filename) || [self.filename isEqualToString:[self buildFileName]] == NO) {
		[self open];
	}
}

- (void)open
{
	[self close];

	NSString *path = [TPCPreferences transcriptFolder];

	if (NSObjectIsEmpty(path)) {
		return;
	}
	
	self.filename = [self buildFileName];
	
	NSString *dir = [self.filename stringByDeletingLastPathComponent];
	
	BOOL isDir = NO;
	
	if ([_NSFileManager() fileExistsAtPath:dir isDirectory:&isDir] == NO) {
		[_NSFileManager() createDirectoryAtPath:dir withIntermediateDirectories:YES attributes:nil error:NULL];
	}
	
	if ([_NSFileManager() fileExistsAtPath:self.filename] == NO) {
		[_NSFileManager() createFileAtPath:self.filename contents:[NSData data] attributes:nil];
	}
	
	self.file = [NSFileHandle fileHandleForUpdatingAtPath:self.filename];
	
	if (self.file) {
		[self.file seekToEndOfFile];
	}
}

- (NSString *)buildPath
{
	NSString *base = [TPCPreferences transcriptFolder];

	NSString *serv = [[self.client name] safeFileName];
	NSString *chan = [[self.channel name] safeFileName];
	
	if (PointerIsEmpty(self.channel)) {
		return [base stringByAppendingFormat:@"/%@/Console/", serv];
	} else if ([self.channel isTalk]) {
		return [base stringByAppendingFormat:@"/%@/Queries/%@/", serv, chan];
	} else {
		return [base stringByAppendingFormat:@"/%@/Channels/%@/", serv, chan];
	}
}

- (NSString *)buildFileName
{
	static NSDateFormatter *format = nil;
	
	if (PointerIsEmpty(format)) {
		format = [NSDateFormatter new];
		[format setDateFormat:@"yyyy-MM-dd"];
	}
	
	NSString *date = [format stringFromDate:[NSDate date]];	
	
	return [NSString stringWithFormat:@"%@%@.txt", [self buildPath], date];
}

@end