// Created by Satoshi Nakagawa <psychs AT limechat DOT net> <http://github.com/psychs/limechat>
// Modifications by Codeux Software <support AT codeux DOT com> <https://github.com/codeux/Textual>
// You can redistribute it and/or modify it under the new BSD license.

@interface FileWithContent : NSObject
{
	NSString* fileName;
	NSString* content;
}

@property (nonatomic, retain) NSString* fileName;
@property (nonatomic, readonly) NSString* content;

@end