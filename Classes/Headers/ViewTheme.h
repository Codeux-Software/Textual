// Created by Satoshi Nakagawa <psychs AT limechat DOT net> <http://github.com/psychs/limechat>
// Modifications by Codeux Software <support AT codeux DOT com> <https://github.com/codeux/Textual>
// You can redistribute it and/or modify it under the new BSD license.

@interface ViewTheme : NSObject
{
	NSURL *baseUrl;
	
	NSString *path;
	NSString *name;
	
	OtherTheme *other;
	FileWithContent *core_js;
}

@property (retain) NSURL *baseUrl;
@property (retain) NSString *path;
@property (retain, getter=name, setter=setName:) NSString *name;
@property (readonly) OtherTheme *other;
@property (readonly) FileWithContent *core_js;

- (void)reload;
+ (void)createUserDirectory:(BOOL)force_reset;

- (void)validateFilePathExistanceAndReload:(BOOL)reload;

+ (NSString *)buildResourceFilename:(NSString *)name;
+ (NSString *)buildUserFilename:(NSString *)name;

+ (NSString *)extractThemeSource:(NSString *)source;
+ (NSString *)extractThemeName:(NSString *)source;

@end