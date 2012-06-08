// Created by Satoshi Nakagawa <psychs AT limechat DOT net> <http://github.com/psychs/limechat>
// Modifications by Codeux Software <support AT codeux DOT com> <https://github.com/codeux/Textual>
// You can redistribute it and/or modify it under the new BSD license.
// Converted to ARC Support on Thursday, June 07, 2012

@interface ViewTheme : NSObject
@property (strong) NSURL *baseUrl;
@property (strong) NSString *path;
@property (nonatomic, strong) NSString *name;
@property (strong) OtherTheme *other;
@property (strong) FileWithContent *core_js;

- (void)reload;
+ (void)createUserDirectory:(BOOL)force_reset;

- (void)validateFilePathExistanceAndReload:(BOOL)reload;

+ (NSString *)buildResourceFilename:(NSString *)name;
+ (NSString *)buildUserFilename:(NSString *)name;

+ (NSString *)extractThemeSource:(NSString *)source;
+ (NSString *)extractThemeName:(NSString *)source;
@end