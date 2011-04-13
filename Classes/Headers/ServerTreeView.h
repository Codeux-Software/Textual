// Created by Satoshi Nakagawa <psychs AT limechat DOT net> <http://github.com/psychs/limechat>
// You can redistribute it and/or modify it under the new BSD license.

@interface ServerTreeView : TreeView
{
	id responderDelegate;
	
	OtherTheme *theme;
	
	NSColor *bgColor;
	NSColor *topLineColor;
	NSColor *bottomLineColor;
	
	NSGradient *gradient;
}

@property (assign) id responderDelegate;
@property (retain) OtherTheme *theme;
@property (retain) NSColor *bgColor;
@property (retain) NSColor *topLineColor;
@property (retain) NSColor *bottomLineColor;
@property (retain) NSGradient *gradient;

- (void)themeChanged;
@end

@interface NSObject (ServerTreeViewDelegate)
- (void)serverTreeViewAcceptsFirstResponder;
@end