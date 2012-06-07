// Created by Satoshi Nakagawa <psychs AT limechat DOT net> <http://github.com/psychs/limechat>
// Modifications by Codeux Software <support AT codeux DOT com> <https://github.com/codeux/Textual>
// You can redistribute it and/or modify it under the new BSD license.

@interface FileWithContent (Private)
- (void)reload;
@end

@implementation FileWithContent

@synthesize filename;
@synthesize content;


- (NSString *)filename
{
	return filename;
}

- (void)setFilename:(NSString *)value
{
	if (NSDissimilarObjects(filename, value)) {
		filename = value;
	}
	
	[self reload];
}

- (void)reload
{
	content = nil;
	
	content = [NSString stringWithContentsOfFile:filename encoding:NSUTF8StringEncoding error:NULL];
}

@end