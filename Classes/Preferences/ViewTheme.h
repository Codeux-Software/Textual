// Created by Satoshi Nakagawa <psychs AT limechat DOT net> <http://github.com/psychs/limechat>
// Modifications by Codeux Software <support AT codeux DOT com> <https://github.com/codeux/Textual>
// You can redistribute it and/or modify it under the new BSD license.

#import <Cocoa/Cocoa.h>
#import "OtherTheme.h"
#import "FileWithContent.h"

@interface ViewTheme : NSObject
{
	NSURL* baseUrl;
	NSString* path;
	NSString* name;
	OtherTheme* other;
	FileWithContent* core_js;
}

@property (nonatomic, retain) NSURL *baseUrl;
@property (nonatomic, retain) NSString *path;
@property (nonatomic, retain, getter=name, setter=setName:) NSString* name;
@property (nonatomic, readonly) OtherTheme* other;
@property (nonatomic, readonly) FileWithContent* core_js;

- (void)reload;
+ (void)createUserDirectory:(BOOL)force_reset;

- (void)validateFilePathExistanceAndReload:(BOOL)reload;

+ (NSString*)buildResourceFileName:(NSString*)name;
+ (NSString*)buildUserFileName:(NSString*)name;
+ (NSArray*)extractFileName:(NSString*)source;

@end