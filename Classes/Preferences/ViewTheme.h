// Created by Satoshi Nakagawa <psychs AT limechat DOT net> <http://github.com/psychs/limechat>
// Modifications by Michael Morris <mikey AT codeux DOT com> <http://github.com/mikemac11/Textual>
// You can redistribute it and/or modify it under the new BSD license.

#import <Cocoa/Cocoa.h>
#import "LogTheme.h"
#import "OtherTheme.h"
#import "CustomJSFile.h"

@interface ViewTheme : NSObject
{
	NSString* name;
	LogTheme* log;
	OtherTheme* other;
	CustomJSFile* js;
}

@property (retain, getter=name, setter=setName:) NSString* name;
@property (readonly) LogTheme* log;
@property (readonly) OtherTheme* other;
@property (readonly) CustomJSFile* js;

- (void)reload;

+ (void)createUserDirectory;

+ (NSString*)buildResourceFileName:(NSString*)name;
+ (NSString*)buildUserFileName:(NSString*)name;
+ (NSArray*)extractFileName:(NSString*)source;

@end