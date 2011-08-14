// Created by Satoshi Nakagawa <psychs AT limechat DOT net> <http://github.com/psychs/limechat>
// Modifications by Codeux Software <support AT codeux DOT com> <https://github.com/codeux/Textual>
// You can redistribute it and/or modify it under the new BSD license.

#define THEME_DISABLED_INDENTATION_OFFSET     -99

@interface OtherTheme : NSObject
{	
	NSString *path;
	
	NSColor *underlyingWindowColor;
	
	NSFont *channelViewFont;
	
	NSString *nicknameFormat;
	NSString *timestampFormat;
	
	BOOL channelViewFontOverrode;
	
    NSDoubleN indentationOffset;
	NSDoubleN renderingEngineVersion;
}

@property (nonatomic, retain, getter=path, setter=setPath:) NSString *path;
@property (nonatomic, retain) NSFont *channelViewFont;
@property (nonatomic, retain) NSString *nicknameFormat;
@property (nonatomic, retain) NSString *timestampFormat;
@property (nonatomic, assign) BOOL channelViewFontOverrode;
@property (nonatomic, retain) NSColor *underlyingWindowColor;
@property (nonatomic, assign) NSDoubleN indentationOffset;
@property (nonatomic, assign) NSDoubleN renderingEngineVersion;

- (void)reload;

@end