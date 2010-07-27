// Created by Satoshi Nakagawa <psychs AT limechat DOT net> <http://github.com/psychs/limechat>
// You can redistribute it and/or modify it under the new BSD license.

#import <Cocoa/Cocoa.h>

@interface ThinSplitView : NSSplitView
{
	NSInteger fixedViewIndex;
	NSInteger myDividerThickness;
	NSInteger position;
	BOOL inverted;
	BOOL hidden;
}

@property (assign, setter=setFixedViewIndex:, getter=fixedViewIndex) NSInteger fixedViewIndex;
@property (assign, setter=setPosition:, getter=position) NSInteger position;
@property (assign, setter=setInverted:, getter=inverted) BOOL inverted;
@property (assign, setter=setHidden:, getter=hidden) BOOL hidden;
@property (setter=setDividerThickness:, getter=myDividerThickness) NSInteger myDividerThickness;
@end