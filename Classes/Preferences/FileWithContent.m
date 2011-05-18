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
	[filename drain];
	[content drain];
	
	[super dealloc];
}

- (NSString *)filename
{
	return filename;
}

- (void)setFilename:(NSString *)value
{
	if (NSDissimilarObjects(filename, value)) {
		[filename drain];
		filename = [value retain];
	}
	
	[self reload];
}

- (void)reload
{
	[content drain];
	content = nil;
	
	content = [NSString stringWithContentsOfFile:filename encoding:NSUTF8StringEncoding error:NULL];
	[content retain];
}

@end