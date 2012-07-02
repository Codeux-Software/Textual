// Created by Satoshi Nakagawa <psychs AT limechat DOT net> <http://github.com/psychs/limechat>
// Modifications by Codeux Software <support AT codeux DOT com> <https://github.com/codeux/Textual>
// You can redistribute it and/or modify it under the new BSD license.
// Converted to ARC Support on June 08, 2012

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