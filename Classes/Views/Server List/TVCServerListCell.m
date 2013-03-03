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

@interface TVCServerListCell ()
@property (nonatomic, readonly, uweak) TVCServerList *serverList;
@end

@implementation TVCServerListCell

#pragma mark -
#pragma mark Status Icon

- (void)drawStatusBadge:(NSString *)iconName inCell:(NSRect)cellFrame withAlpha:(CGFloat)alpha
{
	NSInteger extraMath = 0;

	/* The private message icon is designed a little different than the 
	 channel status icon. Therefore, we have to change its origin to make
	 up for the difference in design. */
	if ([iconName hasPrefix:@"colloquy"] == NO) {
		extraMath = -1;
	} 

	/* More math… */
	NSSize iconSize = NSMakeSize(16, 16);
	NSRect iconRect = NSMakeRect((NSMinX(cellFrame) -   iconSize.width - self.serverList.channelCellStatusIconMargin),
								 (NSMidY(cellFrame) - ((iconSize.height / 2.0f) - extraMath)),
								 iconSize.width, iconSize.height);
	
	NSImage *icon = [NSImage imageNamed:iconName];

	/* Draw the icon. */
	if (icon) {
		NSSize actualIconSize = [icon size];
		
		if ((actualIconSize.width < iconSize.width) || 
		    (actualIconSize.height < iconSize.height))
		{
			iconRect = NSMakeRect((NSMidX(iconRect) - (actualIconSize.width / 2.0f)),
								  (NSMidY(iconRect) - (actualIconSize.height / 2.0f)),
									actualIconSize.width, actualIconSize.height);
		}
		
		iconRect.origin.y += 1;
		
		[icon drawInRect:iconRect
				fromRect:NSZeroRect
			   operation:NSCompositeSourceOver
				fraction:alpha
		  respectFlipped:YES
				   hints:nil];
	}
}

#pragma mark -
#pragma mark Status Badge

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

- (NSInteger)drawMessageCountBadge:(NSAttributedString *)mcstring 
                            inCell:(NSRect)badgeFrame 
                    withHighlighgt:(BOOL)highlight
                          selected:(BOOL)isSelected
{
	NSBezierPath *badgePath;

	/* Draw the badge's drop shadow. */
	if (isSelected == NO) {
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
		if (isSelected) {
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
	
	if ([TPCPreferences useLogAntialiasing] == NO) {
		[RZGraphicsCurrentContext() saveGraphicsState];
		[RZGraphicsCurrentContext() setShouldAntialias:NO];
	}

	/* The actual draw. */
	[mcstring drawAtPoint:badgeTextPoint];
	
	if ([TPCPreferences useLogAntialiasing] == NO) {
		[RZGraphicsCurrentContext() restoreGraphicsState];
	}

	/* Return the frame of the badge. */
	return badgeFrame.size.width;
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

- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView
{
	PointerIsEmptyAssert(self.cellItem);

	/* Define variables. */
	BOOL invertedColors = [TPCPreferences invertSidebarColors];

	IRCClient *client = self.cellItem.viewController.client;
	IRCChannel *channel = self.cellItem.viewController.channel;
	
	BOOL isGroupItem = [self.serverList isGroupItem:self.cellItem];
	BOOL isGraphite = ([NSColor currentControlTint] == NSGraphiteControlTint);
	BOOL isKeyWindow = [self.masterController.mainWindow isOnCurrentWorkspace];
	BOOL isSelected = ([self.serverList rowForItem:self.cellItem] == self.serverList.selectedRow);
	
	/* Draw Background */
	if (isSelected) {
		NSRect backgdRect = cellFrame;
		NSRect parentRect = self.serverList.frame;
		
		backgdRect.origin.x = parentRect.origin.x;
		backgdRect.size.width = parentRect.size.width;
		
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
		
		[origBackgroundImage drawInRect:backgdRect
							   fromRect:NSZeroRect
							  operation:NSCompositeSourceOver
							   fraction:1
						 respectFlipped:YES
								  hints:nil];
	}
	
	/* Draw Badges, Text, and Status Icon */
	NSMutableAttributedString *newStrValue = self.attributedStringValue.mutableCopy;
	
	NSShadow *itemShadow = [NSShadow new];
	
	BOOL drawMessageBadge = (isSelected == NO || (isKeyWindow == NO && isSelected));

	NSInteger channelTreeUnreadCount = self.cellItem.treeUnreadCount;
	NSInteger nicknameHighlightCount = self.cellItem.nicknameHighlightCount;
	
	BOOL isHighlight = (nicknameHighlightCount >= 1);
	
	if (isGroupItem == NO) {
		// ************************************************************** /
		// Draw related items for a channel.							  /
		// ************************************************************** /

		/* Status icon. */
		if (channel.isChannel) {
			if (channel.isActive) {
				[self drawStatusBadge:@"colloquyRoomTabRegular" inCell:cellFrame withAlpha:1.0];
			} else {
				[self drawStatusBadge:@"colloquyRoomTabRegular" inCell:cellFrame withAlpha:0.5];
			}
		} else {
			[self drawStatusBadge:[self.serverList privateMessageStatusIconFilename:isSelected] inCell:cellFrame withAlpha:0.8];
		}

		/* Message count badge. */
		if (channelTreeUnreadCount >= 1 && drawMessageBadge) {
			NSAttributedString *mcstring = [self messageCountBadgeText:channelTreeUnreadCount selected:(isSelected && isHighlight == NO)];
			
			NSRect badgeRect = [self messageCountBadgeRect:cellFrame withText:mcstring];
			
			[self drawMessageCountBadge:mcstring inCell:badgeRect withHighlighgt:isHighlight selected:isSelected];
			
			cellFrame.size.width -= badgeRect.size.width;
		}

		cellFrame.size.width -= (self.serverList.messageCountBadgeRightMargin * 2);

		/* Prepare text shadow. */
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

		/* Set frame and define our attributes. */
		cellFrame.origin.y += 2;
		cellFrame.origin.x -= 2;
		
		NSRange textRange = NSMakeRange(0, newStrValue.length);
		
		if (isSelected) {
			[newStrValue addAttribute:NSFontAttributeName value:self.serverList.selectedChannelCellFont range:textRange];
			
			if (isKeyWindow) {
				[newStrValue addAttribute:NSForegroundColorAttributeName value:self.serverList.channelCellSelectedTextColorForActiveWindow range:textRange];
			} else {
				[newStrValue addAttribute:NSForegroundColorAttributeName value:self.serverList.channelCellSelectedTextColorForInactiveWindow range:textRange];
			}
		} else {
			[newStrValue addAttribute:NSFontAttributeName value:self.serverList.normalChannelCellFont range:textRange];
			
			[newStrValue addAttribute:NSForegroundColorAttributeName value:self.serverList.channelCellNormalTextColor range:textRange];
		}
		
		[newStrValue addAttribute:NSShadowAttributeName value:itemShadow range:textRange];
		
		// ************************************************************** /
		// End channel draw.											  /
		// ************************************************************** /
	}
	else // isGroupItem == NO
	{
		// ************************************************************** /
		// Draw related items for a client.								  /
		// ************************************************************** /

		cellFrame.origin.y += 4;

		/* Text font and color. */
		NSColor *controlColor = self.serverList.serverCellNormalTextColor;

		if (client.isConnected == NO) {
			controlColor = self.serverList.serverCellDisabledTextColor;
		}
		
		NSFont *groupFont = self.serverList.serverCellFont;

		/* Prepare text shadow. */
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
				if (isGraphite) {
					[itemShadow setShadowColor:self.serverList.graphiteTextSelectionShadowColor];
				} else {
					[itemShadow setShadowColor:self.serverList.serverCellSelectedTextShadowColorForActiveWindow];
				}
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

		/* Define attributes. */
		NSRange textRange = NSMakeRange(0, newStrValue.length);
		
		[newStrValue addAttribute:NSFontAttributeName value:groupFont range:textRange];
		[newStrValue addAttribute:NSShadowAttributeName	value:itemShadow range:textRange];
		[newStrValue addAttribute:NSForegroundColorAttributeName value:controlColor	range:textRange];
		
		// ************************************************************** /
		// End client draw.												  /
		// ************************************************************** /
	}
	
	if ([TPCPreferences useLogAntialiasing] == NO) {
		[RZGraphicsCurrentContext() saveGraphicsState];
		[RZGraphicsCurrentContext() setShouldAntialias:NO];
	}

	/* Draw the final result. */
	[newStrValue drawInRect:cellFrame];
	
	if ([TPCPreferences useLogAntialiasing] == NO) {
		[RZGraphicsCurrentContext() restoreGraphicsState];
	}
}

- (TVCServerList *)serverList
{
	return self.masterController.serverList;
}

@end
