/* ********************************************************************* 
       _____        _               _    ___ ____   ____
      |_   _|___  _| |_ _   _  __ _| |  |_ _|  _ \ / ___|
       | |/ _ \ \/ / __| | | |/ _` | |   | || |_) | |
       | |  __/>  <| |_| |_| | (_| | |   | ||  _ <| |___
       |_|\___/_/\_\\__|\__,_|\__,_|_|  |___|_| \_\\____|

 Copyright (c) 2010 — 2013 Codeux Software & respective contributors.
        Please see Contributors.pdf and Acknowledgements.pdf

 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions
 are met:

    * Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the
      documentation and/or other materials provided with the distribution.
    * Neither the name of the Textual IRC Client & Codeux Software nor the
      names of its contributors may be used to endorse or promote products
      derived from this software without specific prior written permission.

 THIS SOFTWARE IS PROVIDED BY THE AUTHOR AND CONTRIBUTORS ``AS IS'' AND
 ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 ARE DISCLAIMED. IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE LIABLE
 FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
 OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
 LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
 OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
 SUCH DAMAGE.

 *********************************************************************** */

#import "TextualApplication.h"

@implementation TVCServerListCell

#pragma mark -
#pragma mark Cell Information

- (NSInteger)rowIndex
{
	return [self.serverList rowForItem:self.cellItem];
}

- (TVCServerList *)serverList
{
	return self.masterController.serverList;
}

#pragma mark -
#pragma mark Cell Drawing

- (NSRect)expansionFrameWithFrame:(NSRect)cellFrame inView:(NSView *)view
{
	return NSZeroRect;
}

- (NSColor *)highlightColorWithFrame:(NSRect)cellFrame inView:(NSView *)controlView
{
	return nil;
}

- (void)updateGroupDisclosureTriangle /* DO NOT CALL DIRECTLY FROM THIS CLASS. */
{
	/* View based outline views do not tell us when we are showing our triangle thingy
	 or even provide us the pointer to the button. We are going to hack the views to 
	 find the button and do it ourself. Thanks Fapple! */

	NSButtonCell *theButton;

	for (id view in self.superview.subviews) {
		if ([view isKindOfClass:[NSButton class]]) {
			theButton = [(NSButton *)view cell];
		}
	}

	PointerIsEmptyAssert(theButton);

	/* Button, yay! */
	NSInteger rowIndex = [self rowIndex];

	BOOL isSelected = (rowIndex == self.serverList.selectedRow);

	/* We keep a reference to the default button. */
	if (PointerIsEmpty(self.serverList.defaultDisclosureTriangle)) {
		self.serverList.defaultDisclosureTriangle = [theButton image];
	}

	if (PointerIsEmpty(self.serverList.alternateDisclosureTriangle)) {
		self.serverList.alternateDisclosureTriangle = [theButton alternateImage];
	}

	/* Now the fun can begin. */
	NSImage *primary = [self.serverList disclosureTriangleInContext:YES selected:isSelected];
	NSImage *alterna = [self.serverList disclosureTriangleInContext:NO selected:isSelected];

	[theButton setImage:primary];
	[theButton setAlternateImage:alterna];

	if (isSelected) {
		[theButton setBackgroundStyle:NSBackgroundStyleLowered];
	} else {
		[theButton setBackgroundStyle:NSBackgroundStyleRaised];
	}
}

- (void)updateSelectionBackgroundView /* DO NOT CALL DIRECTLY FROM THIS CLASS. */
{
	/****************************************************************/
	/* Define context variables. */
	/****************************************************************/

	BOOL invertedColors = [TPCPreferences invertSidebarColors];
	BOOL isKeyWindow = self.masterController.mainWindowIsActive;
	BOOL isGraphite = ([NSColor currentControlTint] == NSGraphiteControlTint);

	IRCChannel *channel = self.cellItem.viewController.channel;

	/****************************************************************/
	/* Find the name of the image to be drawn. */
	/****************************************************************/
	
	NSString *backgroundImage;

	if (channel.isChannel || channel.isPrivateMessage) {
		backgroundImage = @"ChannelCellSelection";
	} else {
		backgroundImage = @"ServerCellSelection";
	}

	if (invertedColors == NO) {
		if (isKeyWindow) {
			backgroundImage = [backgroundImage stringByAppendingString:@"_Focused"];
		} else {
			backgroundImage = [backgroundImage stringByAppendingString:@"_Unfocused"];
		}

		if (isGraphite) {
			backgroundImage = [backgroundImage stringByAppendingString:@"_Graphite"];
		} else {
			backgroundImage = [backgroundImage stringByAppendingString:@"_Aqua"];
		}
	}

	if (invertedColors) {
		backgroundImage = [backgroundImage stringByAppendingString:@"_Inverted"];
	}

	NSImage *origBackgroundImage = [NSImage imageNamed:backgroundImage];

	/****************************************************************/
	/* Put the background to screen. */
	/****************************************************************/

	NSMenu *menu = self.masterController.serverMenuItem.submenu;
	
	if (channel) {
		menu = self.masterController.channelMenuItem.submenu;
	}

	[self.imageView setMenu:menu];

	[self.backgroundImageCell setMenu:menu];
	[self.backgroundImageCell setImage:origBackgroundImage];
	[self.backgroundImageCell setHidden:NO];
}

- (void)updateDrawing:(NSRect)cellFrame
{
	PointerIsEmptyAssert(self.cellItem);

	BOOL isGroupItem = [self.serverList isGroupItem:self.cellItem];

	if (isGroupItem) {
		[self updateDrawingForGroupItem:cellFrame];
	} else {
		[self updateDrawingForChildItem:cellFrame];
	}
}

#pragma mark -
#pragma mark Group Item Drawing

- (void)updateDrawingForGroupItem:(NSRect)cellFrame
{
	/**************************************************************/
	/* Define our context variables. */
	/**************************************************************/

	NSInteger rowIndex = [self rowIndex];

	BOOL invertedColors = [TPCPreferences invertSidebarColors];
	BOOL isSelected = (rowIndex == self.serverList.selectedRow);
	BOOL isKeyWindow = self.masterController.mainWindowIsActive;

	IRCClient *client = self.cellItem.viewController.client;

	/**************************************************************/
	/* Create our new string from scratch. */
	/**************************************************************/
	
	NSMutableAttributedString *newStrValue = [[NSMutableAttributedString alloc] initWithString:self.cellItem.label
																					attributes:self.textField.attributedStringValue.attributes];
	
	/* Text font and color. */
	NSColor *controlColor = self.serverList.serverCellNormalTextColor;

	if (client.isConnected == NO) {
		controlColor = self.serverList.serverCellDisabledTextColor;
	}

	/* Prepare text shadow. */
	NSShadow *itemShadow = [NSShadow new];

	[itemShadow setShadowOffset:NSMakeSize(0, -1)];

	if (invertedColors) {
		[itemShadow setShadowBlurRadius:1.0];
	}

	if (isSelected) {
		if (isKeyWindow) {
			controlColor = self.serverList.serverCellSelectedTextColorForActiveWindow;
		} else {
			controlColor = self.serverList.serverCellSelectedTextColorForInactiveWindow;
		}

		if (isKeyWindow) {
			[itemShadow setShadowColor:self.serverList.serverCellSelectedTextShadowColorForActiveWindow];
		} else {
			[itemShadow setShadowColor:self.serverList.serverCellSelectedTextShadowColorForInactiveWindow];
		}
	} else {
		if (isKeyWindow) {
			[itemShadow setShadowColor:self.serverList.serverCellNormalTextShadowColorForActiveWindow];
		} else {
			[itemShadow setShadowColor:self.serverList.serverCellNormalTextShadowColorForInactiveWindow];

		}
	}

	/**************************************************************/
	/* Set attributes on the new string. */
	/**************************************************************/
	
	NSRange textRange = NSMakeRange(0, newStrValue.length);

	[newStrValue addAttribute:NSShadowAttributeName	value:itemShadow range:textRange];
	[newStrValue addAttribute:NSForegroundColorAttributeName value:controlColor	range:textRange];
	[newStrValue addAttribute:NSFontAttributeName value:self.serverList.serverCellFont range:textRange];

	/**************************************************************/
	/* Set the text field value to our new string. */
	/**************************************************************/

	[self.textField setAttributedStringValue:newStrValue];
}

#pragma mark -
#pragma mark Child Item Drawing

- (void)drawStatusBadge:(NSString *)iconName withAlpha:(CGFloat)alpha
{
	NSImage *oldImage = [NSImage imageNamed:iconName];
	NSImage *newImage = oldImage;
	
	/* Draw an image with alpha. */
	/* We already know all these images will be 16x16. */

	if (alpha < 1.0) {
		newImage = [[NSImage alloc] initWithSize:NSMakeSize(16, 16)];

		[newImage lockFocus];
		
		[oldImage drawInRect:NSMakeRect(0, 0, 16, 16)
					fromRect:NSZeroRect
				   operation:NSCompositeSourceOver
					fraction:alpha
			  respectFlipped:YES
					   hints:nil];
		
		[newImage unlockFocus];
	}

	/* Set the new image. */
	[self.imageView setImage:newImage];
	
	/* The private message icon is designed a little different than the
	 channel status icon. Therefore, we have to change its origin to make
	 up for the difference in design. */
	if ([iconName hasPrefix:@"colloquy"] == NO) {
		static BOOL frameUpdated = NO;

		if (frameUpdated == NO) {
			NSRect oldRect = [self.imageView frame];

			oldRect.origin.y += 1;

			[self.imageView setFrame:oldRect];

			frameUpdated = YES;
		}
	}
}

- (void)updateDrawingForChildItem:(NSRect)cellFrame
{
	/**************************************************************/
	/* Define our context variables. */
	/**************************************************************/

	NSInteger rowIndex = [self rowIndex];

	BOOL invertedColors = [TPCPreferences invertSidebarColors];

	BOOL isSelected = (rowIndex == self.serverList.selectedRow);
	BOOL isGraphite = ([NSColor currentControlTint] == NSGraphiteControlTint);
	BOOL isKeyWindow = self.masterController.mainWindowIsActive;

	IRCChannel *channel = self.cellItem.viewController.channel;

	/**************************************************************/
	/* Prepare for badge drawing. */
	/**************************************************************/

	NSTextFieldCell *textFieldCell = [self.textField cell];

	if ([textFieldCell isKindOfClass:[TVCServerListCellItemTextField class]]) {
		TVCServerListCellItemTextField *textField = (TVCServerListCellItemTextField *)textFieldCell;

		[textField setDrawMessageCountBadge:YES];
		[textField setChannelPointer:channel];
		[textField setIsSelected:isSelected];
		[textField setIsKeyWindow:isKeyWindow];
	}

	/**************************************************************/
	/* Draw status icon for channel. */
	/**************************************************************/
	
	/* Status icon. */
	if (channel.isChannel) {
		if (channel.isActive) {
			[self drawStatusBadge:@"colloquyRoomTabRegular" withAlpha:1.0];
		} else {
			[self drawStatusBadge:@"colloquyRoomTabRegular" withAlpha:0.5];
		}
	} else {
		[self drawStatusBadge:[self.serverList privateMessageStatusIconFilename:isSelected] withAlpha:0.8];
	}

	/**************************************************************/
	/* Create our new string from scratch. */
	/**************************************************************/
	
	NSMutableAttributedString *newStrValue = [[NSMutableAttributedString alloc] initWithString:self.cellItem.label
																					attributes:self.textField.attributedStringValue.attributes];

	/* Define the text shadow information. */
	NSShadow *itemShadow = [NSShadow new];

	[itemShadow setShadowBlurRadius:1.0];
	[itemShadow setShadowOffset:NSMakeSize(0, -1)];

	if (isSelected == NO) {
		[itemShadow setShadowColor:self.serverList.channelCellNormalTextShadowColor];
	} else {
		if (invertedColors == NO) {
			[itemShadow setShadowBlurRadius:2.0];
		}

		if (isKeyWindow) {
			if (isGraphite && invertedColors == NO) {
				[itemShadow setShadowColor:self.serverList.graphiteTextSelectionShadowColor];
			} else {
				[itemShadow setShadowColor:self.serverList.channelCellSelectedTextShadowColorForActiveWindow];
			}
		} else {
			[itemShadow setShadowColor:self.serverList.channelCellSelectedTextShadowColorForInactiveWindow];
		}
	}

	/**************************************************************/
	/* Set attributes on the new string. */
	/**************************************************************/
	
	NSRange textRange = NSMakeRange(0, newStrValue.length);

	if (isSelected) {
		[newStrValue addAttribute:NSFontAttributeName value:self.serverList.selectedChannelCellFont range:textRange];
		
		if (isKeyWindow) {
			[newStrValue addAttribute:NSForegroundColorAttributeName value:self.serverList.channelCellSelectedTextColorForActiveWindow range:textRange];
		} else {
			[newStrValue addAttribute:NSForegroundColorAttributeName value:self.serverList.channelCellSelectedTextColorForInactiveWindow range:textRange];
		}
	} else {
		[newStrValue addAttribute:NSForegroundColorAttributeName value:self.serverList.channelCellNormalTextColor range:textRange];
		
		[newStrValue addAttribute:NSFontAttributeName value:self.serverList.normalChannelCellFont range:textRange];
	}

	[newStrValue addAttribute:NSShadowAttributeName value:itemShadow range:textRange];

	/**************************************************************/
	/* Set the text field value to our new string. */
	/**************************************************************/

	[self.textField setAttributedStringValue:newStrValue];
}

@end

@implementation TVCServerListCellGroupItem
@end

@implementation TVCServerListCellChildItem
@end

@implementation TVCServerListCellItemTextField

- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView
{
	if ([TPCPreferences useLogAntialiasing] == NO) {
		[RZGraphicsCurrentContext() saveGraphicsState];
		[RZGraphicsCurrentContext() setShouldAntialias:NO];
	}

	if (self.drawMessageCountBadge) {
		PointerIsEmptyAssert(self.channelPointer);

		/* Gather information about this badge draw. */
		BOOL drawMessageBadge = (self.isSelected == NO || (self.isKeyWindow == NO && self.isSelected));

		NSInteger channelTreeUnreadCount = self.channelPointer.treeUnreadCount;
		NSInteger nicknameHighlightCount = self.channelPointer.nicknameHighlightCount;

		BOOL isHighlight = (nicknameHighlightCount >= 1);

		/* Begin draw if we want to. */
		if (channelTreeUnreadCount >= 1 && drawMessageBadge) {
			/* Get the string being draw. */
			NSAttributedString *mcstring = [self messageCountBadgeText:channelTreeUnreadCount selected:(self.isSelected && isHighlight == NO)];

			/* Get the rect being drawn. */
			NSRect badgeRect = [self messageCountBadgeRect:cellFrame withText:mcstring];

			/* Draw the badge. */
			[self drawMessageCountBadge:mcstring inCell:badgeRect withHighlighgt:isHighlight];

			/* Trim our text field to make room for the newly drawn badge. */
			cellFrame.size.width -= badgeRect.size.width;
		}

		/* Trim our rect a little bit more. */
		cellFrame.size.width -= (self.serverList.messageCountBadgeRightMargin * 2);
	}

	/* Draw the actual text field. */
	[self.attributedStringValue drawInRect:cellFrame];

	if ([TPCPreferences useLogAntialiasing] == NO) {
		[RZGraphicsCurrentContext() restoreGraphicsState];
	}
}

#pragma mark -
#pragma mark Badge Drawing 

- (NSAttributedString *)messageCountBadgeText:(NSInteger)messageCount selected:(BOOL)isSelected
{
	NSString *messageCountString = TXFormattedNumber(messageCount);

    /* Pick which font size best aligns with the badge. */
	NSColor *textColor = self.serverList.messageCountBadgeNormalTextColor;

	if (isSelected) {
		textColor = self.serverList.messageCountBadgeSelectedTextColor;
	}

	NSDictionary *attributes = @{
		NSForegroundColorAttributeName : textColor,
		NSFontAttributeName : self.serverList.messageCountBadgeFont
	};

	NSAttributedString *mcstring = [[NSAttributedString alloc] initWithString:messageCountString
																   attributes:attributes];

	return mcstring;
}

- (NSRect)messageCountBadgeRect:(NSRect)cellFrame withText:(NSAttributedString *)mcstring
{
	NSInteger messageCountWidth = (mcstring.size.width + (self.serverList.messageCountBadgePadding * 2));

	NSRect badgeFrame = NSMakeRect((NSMaxX(cellFrame) - (self.serverList.messageCountBadgeRightMargin + messageCountWidth)),
								   (NSMidY(cellFrame) - (self.serverList.messageCountBadgeHeight / 2.0)),
								   messageCountWidth, self.serverList.messageCountBadgeHeight);

	if (badgeFrame.size.width < self.serverList.messageCountBadgeMinimumWidth) {
		NSInteger widthDiff = (self.serverList.messageCountBadgeMinimumWidth - badgeFrame.size.width);

		badgeFrame.size.width += widthDiff;
		badgeFrame.origin.x -= widthDiff;
	}

	return badgeFrame;
}

- (NSInteger)drawMessageCountBadge:(NSAttributedString *)mcstring inCell:(NSRect)badgeFrame withHighlighgt:(BOOL)highlight
{
	NSBezierPath *badgePath;

	/* Draw the badge's drop shadow. */
	if (self.isSelected == NO) {
		NSRect shadowFrame = badgeFrame;

		shadowFrame.origin.y += 1;

		badgePath = [NSBezierPath bezierPathWithRoundedRect:shadowFrame
													xRadius:(self.serverList.messageCountBadgeHeight / 2.0)
													yRadius:(self.serverList.messageCountBadgeHeight / 2.0)];

		[self.serverList.messageCountBadgeShadowColor set];

		[badgePath fill];
	}

	/* Draw the background color. */
	NSColor *backgroundColor;

	if (highlight) {
		backgroundColor = self.serverList.messageCountBadgeHighlightBackgroundColor;
	} else {
		if (self.isSelected) {
			backgroundColor = self.serverList.messageCountBadgeSelectedBackgroundColor;
		} else {
			if ([NSColor currentControlTint] == NSGraphiteControlTint) {
				backgroundColor = self.serverList.messageCountBadgeGraphtieBackgroundColor;
			} else {
				backgroundColor = self.serverList.messageCountBadgeAquaBackgroundColor;
			}
		}
	}

	badgePath = [NSBezierPath bezierPathWithRoundedRect:badgeFrame
												xRadius:(self.serverList.messageCountBadgeHeight / 2.0)
												yRadius:(self.serverList.messageCountBadgeHeight / 2.0)];

	[backgroundColor set];

	[badgePath fill];

	/* Center the text relative to the badge itself. */
	NSPoint badgeTextPoint;

	badgeTextPoint = NSMakePoint((NSMidX(badgeFrame) - (mcstring.size.width / 2.0)),
								((NSMidY(badgeFrame) - (mcstring.size.height / 2.0)) + 1));

	/* Mountain Lion did not like our origin. */
	if ([TPCPreferences featureAvailableToOSXMountainLion]) {
		badgeTextPoint.y -= 1;
	}
	
	/* The actual draw. */
	[mcstring drawAtPoint:badgeTextPoint];

	/* Return the frame of the badge. */
	return badgeFrame.size.width;
}

#pragma mark -
#pragma mark Cell Information

- (TVCServerList *)serverList
{
	return self.masterController.serverList;
}

@end
