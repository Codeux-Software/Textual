// Created by Satoshi Nakagawa <psychs AT limechat DOT net> <http://github.com/psychs/limechat>
// Modifications by Michael Morris <mikey AT codeux DOT com> <http://github.com/mikemac11/Textual>
// You can redistribute it and/or modify it under the new BSD license.

#import <Cocoa/Cocoa.h>

@interface OtherTheme : NSObject
{	
	NSString *fileName;
	
	NSColor *underlyingWindowColor;
	
	NSFont* inputTextFont;
	NSColor* inputTextBgColor;
	NSColor* inputTextColor;
	
	NSFont* treeFont;
	NSColor* treeBgColor;
	NSColor* treeHighlightColor;
	NSColor* treeNewTalkColor;
	NSColor* treeUnreadColor;
	
	NSColor* treeActiveColor;
	NSColor* treeInactiveColor;
	
	NSColor* treeSelActiveColor;
	NSColor* treeSelInactiveColor;
	NSColor* treeSelTopLineColor;
	NSColor* treeSelBottomLineColor;
	NSColor* treeSelTopColor;
	NSColor* treeSelBottomColor;
	
	NSFont* memberListFont;
	NSColor* memberListBgColor;
	NSColor* memberListColor;
	NSColor* memberListOpColor;
	
	NSColor* memberListSelColor;
	NSColor* memberListSelTopLineColor;
	NSColor* memberListSelBottomLineColor;
	NSColor* memberListSelTopColor;
	NSColor* memberListSelBottomColor;
}

@property (nonatomic, retain, getter=fileName, setter=setFileName:) NSString* fileName;
@property (nonatomic, readonly) NSFont* inputTextFont;
@property (nonatomic, readonly) NSColor* underlyingWindowColor;
@property (nonatomic, readonly) NSColor* inputTextBgColor;
@property (nonatomic, readonly) NSColor* inputTextColor;
@property (nonatomic, readonly) NSFont* treeFont;
@property (nonatomic, readonly) NSColor* treeBgColor;
@property (nonatomic, readonly) NSColor* treeHighlightColor;
@property (nonatomic, readonly) NSColor* treeNewTalkColor;
@property (nonatomic, readonly) NSColor* treeUnreadColor;
@property (nonatomic, readonly) NSColor* treeActiveColor;
@property (nonatomic, readonly) NSColor* treeInactiveColor;
@property (nonatomic, readonly) NSColor* treeSelActiveColor;
@property (nonatomic, readonly) NSColor* treeSelInactiveColor;
@property (nonatomic, readonly) NSColor* treeSelTopLineColor;
@property (nonatomic, readonly) NSColor* treeSelBottomLineColor;
@property (nonatomic, readonly) NSColor* treeSelTopColor;
@property (nonatomic, readonly) NSColor* treeSelBottomColor;
@property (nonatomic, readonly) NSFont* memberListFont;
@property (nonatomic, readonly) NSColor* memberListBgColor;
@property (nonatomic, readonly) NSColor* memberListColor;
@property (nonatomic, readonly) NSColor* memberListOpColor;
@property (nonatomic, readonly) NSColor* memberListSelColor;
@property (nonatomic, readonly) NSColor* memberListSelTopLineColor;
@property (nonatomic, readonly) NSColor* memberListSelBottomLineColor;
@property (nonatomic, readonly) NSColor* memberListSelTopColor;
@property (nonatomic, readonly) NSColor* memberListSelBottomColor;

- (void)reload;

@end