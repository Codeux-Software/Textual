// Created by Satoshi Nakagawa <psychs AT limechat DOT net> <http://github.com/psychs/limechat>
// Modifications by Codeux Software <support AT codeux DOT com> <https://github.com/codeux/Textual>
// You can redistribute it and/or modify it under the new BSD license.

@interface FileWithContent (Private)
- (void)reload;
@end

@implementation FileWithContent

@synthesize filename;
@synthesize content;

- (void)dealloc
{
	[filename release];
	[content release];
	
	[super dealloc];
}

- (void)setFilename:(NSString *)value
{
	if (filename != value) {
		[filename release];
		filename = [value retain];
	}
	
	[self reload];
}

- (void)reload
{
	[content release];
	content = nil;
	
	content = [NSString stringWithContentsOfFile:filename encoding:NSUTF8StringEncoding error:NULL];
	[content retain];
}

@end