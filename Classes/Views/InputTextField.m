// Created by Satoshi Nakagawa <psychs AT limechat DOT net> <http://github.com/psychs/limechat>
// You can redistribute it and/or modify it under the new BSD license.

@implementation InputTextField
@end

@implementation InputTextFieldCell 

- (void)drawInteriorWithFrame:(NSRect)cellFrame inView:(NSView *)controlView
{
	/* Draw rounded text field using picture elements used by the Safari address bar. */
	
	NSImage *leftTopCap,    *middleTopCap,    *rightTopCap;
	NSImage *leftBottomCap, *middleBottomCap, *rightBottomCap;
	
	NSRect leftTopRect		= cellFrame;
	NSRect middleTopRect	= cellFrame;
	NSRect rightTopRect		= cellFrame;
	NSRect leftBottomRect	= cellFrame;
	NSRect middleBottomRect = cellFrame;
	NSRect rightBottomRect	= cellFrame;
	
	leftTopRect.size.width = 5;
	leftTopRect.size.height = 4;
	
	leftBottomRect.origin.y = (cellFrame.size.height - 5);
	leftBottomRect.size.width = 5;
	leftBottomRect.size.height = 5;
	
	rightTopRect.origin.x = (cellFrame.size.width - 5);
	rightTopRect.size.width = 5;
	rightTopRect.size.height = 4;
	
	rightBottomRect.origin.x = (cellFrame.size.width - 5);
	rightBottomRect.origin.y = (cellFrame.size.height - 5);
	rightBottomRect.size.width = 5;
	rightBottomRect.size.height = 5;
	
	middleTopRect.origin.x += 5;
	middleTopRect.size.width -= 10;
	middleTopRect.size.height = 2;
	
	middleBottomRect.origin.x += 5;
	middleBottomRect.origin.y = (cellFrame.size.height - 2);
	middleBottomRect.size.width -= 10;
	middleBottomRect.size.height = 2;
	
	if ([[NSApp keyWindow] isOnCurrentWorkspace]) {
		leftTopCap		= [NSImage imageNamed:@"InputBox_LeftTop_Active.png"];
		middleTopCap	= [NSImage imageNamed:@"InputBox_MiddleTop_Active.png"];
		rightTopCap		= [NSImage imageNamed:@"InputBox_RightTop_Active.png"];
		leftBottomCap	= [NSImage imageNamed:@"InputBox_LeftBottom_Active.png"];
		middleBottomCap	= [NSImage imageNamed:@"InputBox_MiddleBottom_Active.png"];
		rightBottomCap	= [NSImage imageNamed:@"InputBox_RightBottom_Active.png"];
	} else {
		leftTopCap		= [NSImage imageNamed:@"InputBox_LeftTop_Inactive.png"];
		middleTopCap	= [NSImage imageNamed:@"InputBox_MiddleTop_Inactive.png"];
		rightTopCap		= [NSImage imageNamed:@"InputBox_RightTop_Inactive.png"];
		leftBottomCap	= [NSImage imageNamed:@"InputBox_LeftBottom_Inactive.png"];
		middleBottomCap	= [NSImage imageNamed:@"InputBox_MiddleBottom_Inactive.png"];
		rightBottomCap	= [NSImage imageNamed:@"InputBox_RightBottom_Inactive.png"];
	}
	
	[leftTopCap drawInRect:leftTopRect
				  fromRect:NSZeroRect 
				 operation:NSCompositeSourceOver 
				  fraction:1 
			respectFlipped:YES 
					 hints:nil];
	
	[middleTopCap drawInRect:middleTopRect
					fromRect:NSZeroRect 
				   operation:NSCompositeSourceOver 
					fraction:1 
			  respectFlipped:YES 
					   hints:nil];
	
	[rightTopCap drawInRect:rightTopRect
				   fromRect:NSZeroRect 
				  operation:NSCompositeSourceOver 
				   fraction:1 
			 respectFlipped:YES 
					  hints:nil];
	
	[leftBottomCap drawInRect:leftBottomRect
					 fromRect:NSZeroRect 
					operation:NSCompositeSourceOver 
					 fraction:1 
			   respectFlipped:YES 
						hints:nil];
	
	[middleBottomCap drawInRect:middleBottomRect
					   fromRect:NSZeroRect 
					  operation:NSCompositeSourceOver 
					   fraction:1 
				 respectFlipped:YES 
						  hints:nil];
	
	[rightBottomCap drawInRect:rightBottomRect
					  fromRect:NSZeroRect 
					 operation:NSCompositeSourceOver 
					  fraction:1 
				respectFlipped:YES 
						 hints:nil];
}

@end