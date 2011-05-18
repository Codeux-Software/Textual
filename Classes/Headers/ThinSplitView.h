// Created by Satoshi Nakagawa <psychs AT limechat DOT net> <http://github.com/psychs/limechat>
// You can redistribute it and/or modify it under the new BSD license.

@interface ThinSplitView : NSSplitView
{
	NSInteger position;
	NSInteger fixedViewIndex;
	NSInteger myDividerThickness;
	
	BOOL hidden;
	BOOL inverted;
}

@property (nonatomic, assign, setter=setFixedViewIndex:, getter=fixedViewIndex) NSInteger fixedViewIndex;
@property (nonatomic, assign, setter=setPosition:, getter=position) NSInteger position;
@property (nonatomic, assign, setter=setInverted:, getter=inverted) BOOL inverted;
@property (nonatomic, assign, setter=setHidden:, getter=hidden) BOOL hidden;
@property (nonatomic, setter=setDividerThickness:, getter=myDividerThickness) NSInteger myDividerThickness;
@end