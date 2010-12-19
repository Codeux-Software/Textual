// Created by Satoshi Nakagawa <psychs AT limechat DOT net> <http://github.com/psychs/limechat>
// Modifications by Codeux Software <support AT codeux DOT com> <https://github.com/codeux/Textual>
// You can redistribute it and/or modify it under the new BSD license.

@interface OtherTheme : NSObject
{	
	NSString *path;
	
	NSColor *underlyingWindowColor;
	
	NSFont *inputTextFont;
	NSColor *inputTextBgColor;
	NSColor *inputTextColor;
	
	NSFont *treeFont;
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
	
	NSFont *memberListFont;
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
	
	NSFont *overrideChannelFont;
	
	BOOL indentWrappedMessages;
	BOOL overrideMessageIndentWrap;
	
	NSInteger nicknameFormatFixedWidth;
}

@property (nonatomic, retain, getter=path, setter=setPath:) NSString *path;
@property (nonatomic, retain) NSFont *inputTextFont;
@property (nonatomic, retain) NSColor *underlyingWindowColor;
@property (nonatomic, retain) NSColor *inputTextBgColor;
@property (nonatomic, retain) NSColor *inputTextColor;
@property (nonatomic, retain) NSFont *treeFont;
@property (nonatomic, retain) NSColor *treeBgColor;
@property (nonatomic, retain) NSColor *treeHighlightColor;
@property (nonatomic, retain) NSColor *treeNewTalkColor;
@property (nonatomic, retain) NSColor *treeUnreadColor;
@property (nonatomic, retain) NSColor *treeActiveColor;
@property (nonatomic, retain) NSColor *treeInactiveColor;
@property (nonatomic, retain) NSColor *treeSelActiveColor;
@property (nonatomic, retain) NSColor *treeSelInactiveColor;
@property (nonatomic, retain) NSColor *treeSelTopLineColor;
@property (nonatomic, retain) NSColor *treeSelBottomLineColor;
@property (nonatomic, retain) NSColor *treeSelTopColor;
@property (nonatomic, retain) NSColor *treeSelBottomColor;
@property (nonatomic, retain) NSFont *memberListFont;
@property (nonatomic, retain) NSColor *memberListBgColor;
@property (nonatomic, retain) NSColor *memberListColor;
@property (nonatomic, retain) NSColor *memberListOpColor;
@property (nonatomic, retain) NSColor *memberListSelColor;
@property (nonatomic, retain) NSColor *memberListSelTopLineColor;
@property (nonatomic, retain) NSColor *memberListSelBottomLineColor;
@property (nonatomic, retain) NSColor *memberListSelTopColor;
@property (nonatomic, retain) NSColor *memberListSelBottomColor;
@property (nonatomic, retain) NSString *nicknameFormat;
@property (nonatomic, retain) NSString *timestampFormat;
@property (nonatomic, retain) NSFont *overrideChannelFont;
@property (nonatomic, assign) BOOL indentWrappedMessages;
@property (nonatomic, assign) BOOL overrideMessageIndentWrap;
@property (nonatomic, assign) NSInteger nicknameFormatFixedWidth;

- (void)reload;

@end