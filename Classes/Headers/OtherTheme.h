// Created by Satoshi Nakagawa <psychs AT limechat DOT net> <http://github.com/psychs/limechat>
// Modifications by Codeux Software <support AT codeux DOT com> <https://github.com/codeux/Textual>
// You can redistribute it and/or modify it under the new BSD license.

@interface OtherTheme : NSObject
{	
	NSString *path;
	
	NSColor *underlyingWindowColor;
	
	NSFont *treeFont;
	NSFont *inputTextFont;
	NSFont *memberListFont;
	NSFont *overrideChannelFont;
	
	NSColor *inputTextBgColor;
	NSColor *inputTextColor;
	
	NSColor *treeBgColor;
	NSColor *treeHighlightColor;
	NSColor *treeNewTalkColor;
	NSColor *treeUnreadColor;
	
	NSColor *treeActiveColor;
	NSColor *treeInactiveColor;
	
	NSColor *treeSelActiveColor;
	NSColor *treeSelInactiveColor;
	NSColor *treeSelTopLineColor;
	NSColor *treeSelBottomLineColor;
	NSColor *treeSelTopColor;
	NSColor *treeSelBottomColor;
	
	NSColor *memberListBgColor;
	NSColor *memberListColor;
	NSColor *memberListOpColor;
	
	NSColor *memberListSelColor;
	NSColor *memberListSelTopLineColor;
	NSColor *memberListSelBottomLineColor;
	NSColor *memberListSelTopColor;
	NSColor *memberListSelBottomColor;
	
	NSString *nicknameFormat;
	NSString *timestampFormat;
	
	BOOL indentWrappedMessages;
	BOOL overrideMessageIndentWrap;
	
	NSInteger nicknameFormatFixedWidth;
}

@property (retain, getter=path, setter=setPath:) NSString *path;
@property (retain) NSFont *inputTextFont;
@property (retain) NSColor *underlyingWindowColor;
@property (retain) NSColor *inputTextBgColor;
@property (retain) NSColor *inputTextColor;
@property (retain) NSFont *treeFont;
@property (retain) NSColor *treeBgColor;
@property (retain) NSColor *treeHighlightColor;
@property (retain) NSColor *treeNewTalkColor;
@property (retain) NSColor *treeUnreadColor;
@property (retain) NSColor *treeActiveColor;
@property (retain) NSColor *treeInactiveColor;
@property (retain) NSColor *treeSelActiveColor;
@property (retain) NSColor *treeSelInactiveColor;
@property (retain) NSColor *treeSelTopLineColor;
@property (retain) NSColor *treeSelBottomLineColor;
@property (retain) NSColor *treeSelTopColor;
@property (retain) NSColor *treeSelBottomColor;
@property (retain) NSFont *memberListFont;
@property (retain) NSColor *memberListBgColor;
@property (retain) NSColor *memberListColor;
@property (retain) NSColor *memberListOpColor;
@property (retain) NSColor *memberListSelColor;
@property (retain) NSColor *memberListSelTopLineColor;
@property (retain) NSColor *memberListSelBottomLineColor;
@property (retain) NSColor *memberListSelTopColor;
@property (retain) NSColor *memberListSelBottomColor;
@property (retain) NSString *nicknameFormat;
@property (retain) NSString *timestampFormat;
@property (retain) NSFont *overrideChannelFont;
@property (assign) BOOL indentWrappedMessages;
@property (assign) BOOL overrideMessageIndentWrap;
@property (assign) NSInteger nicknameFormatFixedWidth;

- (void)reload;

@end