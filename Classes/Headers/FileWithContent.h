// Created by Satoshi Nakagawa <psychs AT limechat DOT net> <http://github.com/psychs/limechat>
// Modifications by Codeux Software <support AT codeux DOT com> <https://github.com/codeux/Textual>
// You can redistribute it and/or modify it under the new BSD license.

@interface FileWithContent : NSObject
{
	NSString *filename;
	NSString *content;
}

@property (retain) NSString *filename;
@property (readonly) NSString *content;

@end