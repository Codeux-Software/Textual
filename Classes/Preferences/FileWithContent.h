// Created by Satoshi Nakagawa <psychs AT limechat DOT net> <http://github.com/psychs/limechat>
// Modifications by Michael Morris <mikey AT codeux DOT com> <http://github.com/mikemac11/Textual>
// You can redistribute it and/or modify it under the new BSD license.

#import <Foundation/Foundation.h>

@interface FileWithContent : NSObject
{
	NSString* fileName;
	NSString* content;
	NSURL* baseUrl;
}

@property (nonatomic, retain, getter=fileName, setter=setFileName:) NSString* fileName;
@property (nonatomic, readonly) NSString* content;
@property (nonatomic, readonly) NSURL* baseUrl;

- (void)reload;

@end