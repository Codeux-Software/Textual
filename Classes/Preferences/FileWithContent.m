// Created by Satoshi Nakagawa <psychs AT limechat DOT net> <http://github.com/psychs/limechat>
// Modifications by Codeux Software <support AT codeux DOT com> <https://github.com/codeux/Textual>
// You can redistribute it and/or modify it under the new BSD license.

#import "FileWithContent.h"

@interface FileWithContent (Private)
- (void)reload;
@end

@implementation FileWithContent

@synthesize fileName;
@synthesize content;

- (id)init
{
	if ((self = [super init])) {
	}
	return self;
}

- (void)dealloc
{
	[fileName release];
	[content release];
	[super dealloc];
}

- (void)setFileName:(NSString *)value
{
	if (fileName != value) {
		[fileName release];
		fileName = [value retain];
	}
	
	[self reload];
}

- (void)reload
{
	[content release];
	
	NSData *data = [NSData dataWithContentsOfFile:fileName];
	content = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
}

@end