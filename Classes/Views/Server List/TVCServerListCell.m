/* ********************************************************************* 
       _____        _               _    ___ ____   ____
      |_   _|___  _| |_ _   _  __ _| |  |_ _|  _ \ / ___|
       | |/ _ \ \/ / __| | | |/ _` | |   | || |_) | |
       | |  __/>  <| |_| |_| | (_| | |   | ||  _ <| |___
       |_|\___/_/\_\\__|\__,_|\__,_|_|  |___|_| \_\\____|

 Copyright (c) 2010 — 2012 Codeux Software & respective contributors.
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
#pragma mark Status Icon

- (void)drawStatusBadge:(NSString *)iconName inCell:(NSRect)cellFrame withAlpha:(CGFloat)alpha
{
	NSInteger extraMath = 0;
	
	if ([iconName isEqualNoCase:@"NSUser"] || [iconName isEqualNoCase:@"DarkServerListViewSelectedQueryUser"]) {
		extraMath = 1;
	} 
	
	NSSize iconSize = NSMakeSize(16, 16);
	NSRect iconRect = NSMakeRect( (NSMinX(cellFrame) - iconSize.width - self.parent.layoutIconSpacing),
								 ((NSMidY(cellFrame) - (iconSize.width / 2.0f) - extraMath)),
								 iconSize.width, iconSize.height);
	
	NSImage *icon = [NSImage imageNamed:iconName];
	
	if (icon) {
		NSSize actualIconSize = [icon size];
		
		if ((actualIconSize.width < iconSize.width) || 
		    (actualIconSize.height < iconSize.height)) {
			
			iconRect = NSMakeRect((NSMidX(iconRect) - (actualIconSize.width / 2.0f)),
								  (NSMidY(iconRect) - (actualIconSize.height / 2.0f)),
								  actualIconSize.width, actualIconSize.height);
		}
		
		iconRect.origin.y += 1;
		
		[icon drawInRect:iconRect
				fromRect:NSZeroRect
			   operation:NSCompositeSourceOver
				fraction:alpha
		  respectFlipped:YES hints:nil];
	}
}

#pragma mark -
#pragma mark Status Badge

- (NSAttributedString *)messageCountBadgeText:(NSInteger)messageCount selected:(BOOL)isSelected
{
	NSString *messageCountString;
	
	if ([_NSUserDefaults() boolForKey:@"ForceServerListBadgeLocalization"]) {
		messageCountString = TXFormattedNumber(messageCount);
	} else {
		messageCountString = [NSString stringWithInteger:messageCount];
	}
	
	NSMutableDictionary *attributes = [NSMutableDictionary dictionary];
	
	NSColor *textColor = self.parent.layoutBadgeTextColorNS;
	
	if (isSelected) {
		textColor = self.parent.layoutBadgeTextColorTS;
	}
	
	attributes[NSFontAttributeName] = self.parent.layoutBadgeFont;
	attributes[NSForegroundColorAttributeName] = textColor;
	
	NSAttributedString *mcstring = [[NSAttributedString alloc] initWithString:messageCountString
																   attributes:attributes];
	
	return mcstring;
}

- (NSRect)messageCountBadgeRect:(NSRect)cellFrame withText:(NSAttributedString *)mcstring 
{
	NSRect badgeFrame;
	
	NSSize    messageCountSize  = [mcstring size];
	NSInteger messageCountWidth = (messageCountSize.width + (self.parent.layoutBadgeInsideMargin * 2));
	
	badgeFrame = NSMakeRect((NSMaxX(cellFrame) - (self.parent.layoutBadgeRightMargin + messageCountWidth)),
							(NSMidY(cellFrame) - (self.parent.layoutBadgeHeight / 2.0)),
							messageCountWidth, self.parent.layoutBadgeHeight);
	
	if (badgeFrame.size.width < self.parent.layoutBadgeMinimumWidth) {
		NSInteger widthDiff = (self.parent.layoutBadgeMinimumWidth - badgeFrame.size.width);
		
		badgeFrame.size.width += widthDiff;
		badgeFrame.origin.x   -= widthDiff;
	}
	
	return badgeFrame;
}

- (NSInteger)drawMessageCountBadge:(NSAttributedString *)mcstring 
                            inCell:(NSRect)badgeFrame 
                    withHighlighgt:(BOOL)highlight
                          selected:(BOOL)isSelected
{
	NSBezierPath *badgePath;
	
	NSSize messageCountSize = [mcstring size];
	NSRect shadowFrame;
	
	if (isSelected == NO) {
		shadowFrame = badgeFrame;
		shadowFrame.origin.y += 1;
		
		badgePath = [NSBezierPath bezierPathWithRoundedRect:shadowFrame
													xRadius:(self.parent.layoutBadgeHeight / 2.0)
													yRadius:(self.parent.layoutBadgeHeight / 2.0)];
		
		[self.parent.layoutBadgeShadowColor set];
		[badgePath fill];
	}
	
	NSColor *backgroundColor;
	
	if (highlight) {
		backgroundColor = self.parent.layoutBadgeHighlightBackgroundColor;
	} else {
		if (isSelected) {
			backgroundColor = self.parent.layoutBadgeMessageBackgroundColorTS;
		} else {
			if ([NSColor currentControlTint] == NSGraphiteControlTint) {
				backgroundColor = self.parent.layoutBadgeMessageBackgroundColorGraphite;
			} else {
				backgroundColor = self.parent.layoutBadgeMessageBackgroundColorAqua;
			}
		}
	}
	
	badgePath = [NSBezierPath bezierPathWithRoundedRect:badgeFrame
												xRadius:(self.parent.layoutBadgeHeight / 2.0)
												yRadius:(self.parent.layoutBadgeHeight / 2.0)];
	
	[backgroundColor set];
	[badgePath fill];
	
	NSPoint badgeTextPoint;
	
	badgeTextPoint = NSMakePoint( (NSMidX(badgeFrame) - (messageCountSize.width / 2.0)),
								 ((NSMidY(badgeFrame) - (messageCountSize.height / 2.0)) + 1));
	
	if ([TPCPreferences featureAvailableToOSXMountainLion]) {
		badgeTextPoint.y -= 1;
	}
	
	if ([TPCPreferences useLogAntialiasing] == NO) {
		[_NSGraphicsCurrentContext() saveGraphicsState];
		[_NSGraphicsCurrentContext() setShouldAntialias:NO];
	}
	
	[mcstring drawAtPoint:badgeTextPoint];
	
	if ([TPCPreferences useLogAntialiasing] == NO) {
		[_NSGraphicsCurrentContext() restoreGraphicsState];
	}
	
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
	BOOL invertedColors = [TPCPreferences invertSidebarColors];

	// ---- //

	NSInteger selectedRow = [self.parent selectedRow];
	
	if (self.cellItem) {
		NSInteger rowIndex = [self.parent rowForItem:self.cellItem];
		
		NSWindow *parentWindow = [self.parent.keyDelegate window];
		
		BOOL isGroupItem = [self.parent isGroupItem:self.cellItem];
		BOOL isSelected  = (rowIndex == selectedRow);
		BOOL isKeyWindow = [parentWindow isOnCurrentWorkspace];
		BOOL isGraphite  = ([NSColor currentControlTint] == NSGraphiteControlTint);
		
		IRCChannel *channel = self.cellItem.log.channel;
		
		/* Draw Background */
		if (isSelected) {
			NSRect backgroundRect = cellFrame;
			NSRect parentRect	  = [self.parent frame];
			
			backgroundRect.origin.x   = parentRect.origin.x;
			backgroundRect.size.width = parentRect.size.width;
			
			NSString *backgroundImage;
			
			if (channel.isChannel || channel.isTalk) {
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
					backgroundImage = [backgroundImage stringByAppendingString:@"self.parent.layoutGraphite"];
				} else {
					backgroundImage = [backgroundImage stringByAppendingString:@"_Aqua"];
				}
			}
			
			if ([TPCPreferences invertSidebarColors]) {
				backgroundImage = [backgroundImage stringByAppendingString:@"_Inverted"];
			}
			
			NSImage *origBackgroundImage = [NSImage imageNamed:backgroundImage];
			
			[origBackgroundImage drawInRect:backgroundRect
								   fromRect:NSZeroRect
								  operation:NSCompositeSourceOver
								   fraction:1
							 respectFlipped:YES hints:nil];
		}
		
		/* Draw Badges, Text, and Status Icon */
		
		NSAttributedString			*stringValue	= [self attributedStringValue];	
		NSMutableAttributedString	*newValue		= [stringValue mutableCopy];
		
		NSShadow *itemShadow = [NSShadow new];
		
		BOOL drawMessageBadge = (isSelected == NO ||
								 (isKeyWindow == NO && isSelected));

		NSInteger unreadCount  = self.cellItem.treeUnreadCount;
		NSInteger keywordCount = self.cellItem.keywordCount;
		
		BOOL isHighlight = (keywordCount >= 1);
		
		if (isGroupItem == NO) {
			if (channel.isChannel) {
				NSString *iconName = @"colloquyRoomTabRegular";
				
				if (channel.isActive) {
					[self drawStatusBadge:iconName inCell:cellFrame withAlpha:1.0];
				} else {
					[self drawStatusBadge:iconName inCell:cellFrame withAlpha:0.5];
				}
			} else {
				if (isSelected == NO && invertedColors) {
					[self drawStatusBadge:@"DarkServerListViewSelectedQueryUser" inCell:cellFrame withAlpha:0.8];
				} else {
					[self drawStatusBadge:@"NSUser" inCell:cellFrame withAlpha:0.8];
				}
			}
			
			if (unreadCount >= 1 && drawMessageBadge) {
				NSAttributedString *mcstring  = [self messageCountBadgeText:unreadCount selected:(isSelected && isHighlight == NO)];
				NSRect              badgeRect = [self messageCountBadgeRect:cellFrame withText:mcstring];
				
				[self drawMessageCountBadge:mcstring inCell:badgeRect withHighlighgt:isHighlight selected:isSelected];
				
				cellFrame.size.width -= badgeRect.size.width;
			}
			
			cellFrame.size.width -= (self.parent.layoutBadgeRightMargin * 2);
			
			[itemShadow setShadowBlurRadius:1.0];
			[itemShadow setShadowOffset:NSMakeSize(0, -1)];
			
			if (isSelected == NO) {
				[itemShadow setShadowColor:self.parent.layoutChannelCellShadowColor];
			} else {
				if (invertedColors == NO) {
					[itemShadow setShadowBlurRadius:2.0];
				}
				
				if (isKeyWindow) {
					if (isGraphite && invertedColors == NO) {
						[itemShadow setShadowColor:self.parent.layoutGraphiteSelectionColorAW];
					} else {
						[itemShadow setShadowColor:self.parent.layoutChannelCellSelectionShadowColor_AW];
					}
				} else {
					[itemShadow setShadowColor:self.parent.layoutChannelCellSelectionShadowColor_IA];
				}
			}
			
			cellFrame.origin.y += 2;
			cellFrame.origin.x -= 2;
			
			NSRange textRange = NSMakeRange(0, [newValue length]);
			
			if (isSelected) {
				[newValue addAttribute:NSFontAttributeName              value:self.parent.layoutChannelCellSelectionFont       range:textRange];
				
				if (isKeyWindow) {
					[newValue addAttribute:NSForegroundColorAttributeName value:self.parent.layoutChannelCellSelectionFontColor_AW range:textRange];
				} else {
					[newValue addAttribute:NSForegroundColorAttributeName value:self.parent.layoutChannelCellSelectionFontColor_IA range:textRange];
				}
			} else {
				[newValue addAttribute:NSFontAttributeName              value:self.parent.layoutChannelCellFont         range:textRange];
				[newValue addAttribute:NSForegroundColorAttributeName   value:self.parent.layoutChannelCellFontColor	range:textRange];
			}
			
			[newValue addAttribute:NSShadowAttributeName value:itemShadow range:textRange];
		}
		else // isGroupItem == NO
		{ 
			cellFrame.origin.y += 4;
			
			NSColor *controlColor	= self.parent.layoutServerCellFontColor;
			NSFont  *groupFont		= self.parent.layoutServerCellFont;
			
			if (self.cellItem.client.isConnected == NO) {
				controlColor = self.parent.layoutServerCellFontColorDisabled;
			}
			
			[itemShadow setShadowOffset:NSMakeSize(0, -1)];
			
			if (invertedColors) {
				[itemShadow setShadowBlurRadius:1.0];
			}
			
			if (isSelected) {
				if (isKeyWindow) {
					controlColor = self.parent.layoutServerCellSelectionFontColor_AW;
				} else {
					controlColor = self.parent.layoutServerCellSelectionFontColor_IA;
				}
				
				if (isKeyWindow) {
					if (isGraphite) {
						[itemShadow setShadowColor:self.parent.layoutGraphiteSelectionColorAW];
					} else {
						[itemShadow setShadowColor:self.parent.layoutServerCellSelectionShadowColorAW];
					}
				} else {
					[itemShadow setShadowColor:self.parent.layoutServerCellSelectionShadowColorIA];
				}
			} else {
				if (isKeyWindow) {
					[itemShadow setShadowColor:self.parent.layoutServerCellShadowColorAW];
				} else {
					[itemShadow setShadowColor:self.parent.layoutServerCellShadowColorNA];
				}
			}
			
			NSRange textRange = NSMakeRange(0, [newValue length]);
			
			[newValue addAttribute:NSFontAttributeName				value:groupFont		range:textRange];
			[newValue addAttribute:NSShadowAttributeName			value:itemShadow	range:textRange];
			[newValue addAttribute:NSForegroundColorAttributeName	value:controlColor	range:textRange];
		}
		
		if ([TPCPreferences useLogAntialiasing] == NO) {
			[_NSGraphicsCurrentContext() saveGraphicsState];
			[_NSGraphicsCurrentContext() setShouldAntialias:NO];
		}
		
		[newValue drawInRect:cellFrame];
		
		if ([TPCPreferences useLogAntialiasing] == NO) {
			[_NSGraphicsCurrentContext() restoreGraphicsState];
		}
	}
}

@end