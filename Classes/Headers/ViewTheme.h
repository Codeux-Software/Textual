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

@property (nonatomic, retain) NSURL *baseUrl;
@property (nonatomic, retain) NSString *path;
@property (nonatomic, retain, getter=name, setter=setName:) NSString *name;
@property (nonatomic, readonly) OtherTheme *other;
@property (nonatomic, readonly) FileWithContent *core_js;

- (void)reload;
+ (void)createUserDirectory:(BOOL)force_reset;

- (void)validateFilePathExistanceAndReload:(BOOL)reload;

+ (NSString *)buildResourceFilename:(NSString *)name;
+ (NSString *)buildUserFilename:(NSString *)name;

+ (NSString *)extractThemeSource:(NSString *)source;
+ (NSString *)extractThemeName:(NSString *)source;

@end