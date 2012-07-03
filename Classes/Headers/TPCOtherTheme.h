// Created by Satoshi Nakagawa <psychs AT limechat DOT net> <http://github.com/psychs/limechat>
// Modifications by Codeux Software <support AT codeux DOT com> <https://github.com/codeux/Textual>
// You can redistribute it and/or modify it under the new BSD license.

#import "TextualApplication.h"

#define TXThemeDisabledIndentationOffset     -99

@interface TPCOtherTheme : NSObject
@property (nonatomic, strong) NSString *path;
@property (nonatomic, strong) NSFont *channelViewFont;
@property (nonatomic, strong) NSString *nicknameFormat;
@property (nonatomic, strong) NSString *timestampFormat;
@property (nonatomic, assign) BOOL channelViewFontOverrode;
@property (nonatomic, assign) BOOL forceInvertSidebarColors;
@property (nonatomic, strong) NSColor *underlyingWindowColor;
@property (nonatomic, assign) TXNSDouble indentationOffset;
@property (nonatomic, assign) TXNSDouble renderingEngineVersion;

- (void)reload;
@end