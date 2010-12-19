// Created by Satoshi Nakagawa <psychs AT limechat DOT net> <http://github.com/psychs/limechat>
// You can redistribute it and/or modify it under the new BSD license.

#import "ChatBox.h"

#define CHATBOX_SPACE	3

@implementation ChatBox

- (NSView *)logBase
{
	return [[[[self subviews] safeObjectAtIndex:0] subviews] safeObjectAtIndex:0];
}

- (NSTextField *)inputText
{
	return [[[[self subviews] safeObjectAtIndex:0] subviews] safeObjectAtIndex:1];
}

- (void)setInputTextFont:(NSFont *)font
{
	NSTextField *text = [self inputText];
	[text setFont:font];
	
	// calculate height of the text field
	NSRect f = [text frame];
	f.size.height = 1e+37;
	f.size.height = ceil([[text cell] cellSizeForBounds:f].height) + 2;
	[text setFrameSize:f.size];
	
	// apply the current font to text
	NSRange range;
	NSText *e = [text currentEditor];
	if (e) range = [e selectedRange];
	NSString *s = [text stringValue];
	[text setAttributedStringValue:[[NSAttributedString new] autorelease]];
	[text setStringValue:s];
	if (e) [e setSelectedRange:range];
	
	[self setFrame:[self frame]];
}

- (void)setFrame:(NSRect)rect
{
	if ([self subviews].count > 0) {
		NSRect f = rect;
		NSView *box = [self logBase];
		NSTextField *text = [self inputText];
		NSRect boxFrame = [box frame];
		NSRect textFrame = [text frame];
		
		boxFrame.origin.x = 0;
		boxFrame.origin.y = textFrame.size.height + CHATBOX_SPACE;
		boxFrame.size.width = f.size.width;
		boxFrame.size.height = f.size.height - textFrame.size.height - CHATBOX_SPACE;
		[box setFrame:boxFrame];
		
		textFrame.origin = NSMakePoint(0, 0);
		textFrame.size.width = f.size.width;
		[text setFrame:textFrame];
	}
	
	[super setFrame:rect];
}

@end