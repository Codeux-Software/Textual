// Created by Satoshi Nakagawa <psychs AT limechat DOT net> <http://github.com/psychs/limechat>
// Modifications by Michael Morris <mikey AT codeux DOT com> <http://github.com/mikemac11/Textual>
// You can redistribute it and/or modify it under the new BSD license.

#import <Cocoa/Cocoa.h>
#import "LogTheme.h"
#import "OtherTheme.h"
#import "CustomJSFile.h"

@interface ViewTheme : NSObject
{
	NSString* path;
	NSString* name;
	LogTheme* log;
	OtherTheme* other;
	CustomJSFile* js;
}

@property (nonatomic, retain) NSString *path;
@property (nonatomic, retain, getter=name, setter=setName:) NSString* name;
@property (nonatomic, readonly) LogTheme* log;
@property (nonatomic, readonly) OtherTheme* other;
@property (nonatomic, readonly) CustomJSFile* js;

- (void)reload;
+ (void)createUserDirectory:(BOOL)force_reset;

+ (NSString*)buildResourceFileName:(NSString*)name;
+ (NSString*)buildUserFileName:(NSString*)name;
+ (NSArray*)extractFileName:(NSString*)source;

@end