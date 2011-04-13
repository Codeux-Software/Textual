// Created by Satoshi Nakagawa <psychs AT limechat DOT net> <http://github.com/psychs/limechat>
// You can redistribute it and/or modify it under the new BSD license.

@interface ThinSplitView : NSSplitView
{
	NSColor *dividerColor;
	
	NSInteger position;
	NSInteger fixedViewIndex;
	NSInteger myDividerThickness;
	
	BOOL hidden;
	BOOL inverted;
}

@property (assign) NSColor *dividerColor;
@property (assign, setter=setFixedViewIndex:, getter=fixedViewIndex) NSInteger fixedViewIndex;
@property (assign, setter=setPosition:, getter=position) NSInteger position;
@property (assign, setter=setInverted:, getter=inverted) BOOL inverted;
@property (assign, setter=setHidden:, getter=hidden) BOOL hidden;
@property (setter=setDividerThickness:, getter=myDividerThickness) NSInteger myDividerThickness;
@end