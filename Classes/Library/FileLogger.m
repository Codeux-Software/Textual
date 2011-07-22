// Created by Satoshi Nakagawa <psychs AT limechat DOT net> <http://github.com/psychs/limechat>
// Modifications by Codeux Software <support AT codeux DOT com> <https://github.com/codeux/Textual>
// You can redistribute it and/or modify it under the new BSD license.

@implementation FileLogger

@synthesize client;
@synthesize channel;
@synthesize filename;
@synthesize file;

- (void)dealloc
{
	[self close];
	
	[filename drain];
	
	[super dealloc];
}

- (void)close
{
	if (file) {
		[file closeFile];
		[file drain];
		
		file = nil;
	}
}

- (void)writeLine:(NSString *)s
{
    if (client.isConnected == NO) {
        return;
    }
    
	[self open];
	
	if (file) {
		s = [s stringByAppendingString:NSNewlineCharacter];
		
		NSData *data = [s dataUsingEncoding:client.encoding];
		
		if (NSObjectIsEmpty(data)) {
			data = [s dataUsingEncoding:client.config.fallbackEncoding];
			
			if (NSObjectIsEmpty(data)) {
				data = [s dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES];
			}
		}
		
		if (data) {
			[file writeData:data];
		}
	}
}

- (void)reopenIfNeeded
{
	if (NSObjectIsEmpty(filename) || [filename isEqualToString:[self buildFileName]] == NO) {
		[self open];
	}
}

- (void)open
{
	[self close];
	
	[filename drain];
	filename = [[self buildFileName] retain];
	
	NSString *dir = [filename stringByDeletingLastPathComponent];
	
	BOOL isDir = NO;
	
	if ([_NSFileManager() fileExistsAtPath:dir isDirectory:&isDir] == NO) {
		[_NSFileManager() createDirectoryAtPath:dir withIntermediateDirectories:YES attributes:nil error:NULL];
	}
	
	if ([_NSFileManager() fileExistsAtPath:filename] == NO) {
		[_NSFileManager() createFileAtPath:filename contents:[NSData data] attributes:nil];
	}
	
	[file drain];
	file = [[NSFileHandle fileHandleForUpdatingAtPath:filename] retain];
	
	if (file) {
		[file seekToEndOfFile];
	}
}

- (NSString *)buildPath
{
	NSString *base = [[Preferences transcriptFolder] stringByExpandingTildeInPath];
	
	NSString *serv = [[client name] safeFileName];
	NSString *chan = [[channel name] safeFileName];
	
	if (PointerIsEmpty(channel)) {
		return [base stringByAppendingFormat:@"/%@/Console/", serv];
	} else if ([channel isTalk]) {
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