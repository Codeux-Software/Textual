// Created by Satoshi Nakagawa <psychs AT limechat DOT net> <http://github.com/psychs/limechat>
// Modifications by Codeux Software <support AT codeux DOT com> <https://github.com/codeux/Textual>
// You can redistribute it and/or modify it under the new BSD license.
// Converted to ARC Support on Thursday, June 07, 2012

@interface TLOFileWithContent (Private)
- (void)reload;
@end

@implementation TLOFileWithContent

@synthesize filename;
@synthesize content;

- (void)setFilename:(NSString *)value
{
	if (NSDissimilarObjects(self.filename, value)) {
		filename = value;
	}
	
	[self reload];
}

- (void)reload
{
	self.content = nil;
	self.content = [NSString stringWithContentsOfFile:self.filename encoding:NSUTF8StringEncoding error:NULL];
}

@end