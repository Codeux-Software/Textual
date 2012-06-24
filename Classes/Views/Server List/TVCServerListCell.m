// Created by Codeux Software <support AT codeux DOT com> <https://github.com/codeux/Textual>
// You can redistribute it and/or modify it under the new BSD license.
// Converted to ARC Support on June 07, 2012

#import "TextualApplication.h"

/* This class and the one for the user list is based off the open source PXSourceList 
 toolkit developed by Alex Rozanski. */

#define _iconSpacing							6.0

#define _badgeRightMargin						5.0		
#define _badgeInsideMargin						5.0
#define _badgeMinimumWidth						22.0
#define _badgeHeight							14.0	

#define _badgeFont								[_NSFontManager() fontWithFamily:@"Helvetica" traits:NSBoldFontMask weight:15 size:10.5]
#define _badgeTextColorTS						TXInvertSidebarColor([NSColor internalCalibratedRed:158 green:169 blue:197 alpha:1])
#define _badgeTextColorNS						TXInvertSidebarColor([NSColor whiteColor])
#define _badgeShadowColor						TXInvertSidebarColor([NSColor colorWithCalibratedWhite:1.00 alpha:0.60])
#define _badgeMessageBackgroundColorTS				TXInvertSidebarColor([NSColor whiteColor])
#define _badgeHighlightBackgroundColor				TXInvertSidebarColor([NSColor internalCalibratedRed:210 green:15  blue:15  alpha:1])
#define _badgeMessageBackgroundColorAqua			TXInvertSidebarColor([NSColor internalCalibratedRed:152 green:168 blue:202 alpha:1])
#define _badgeMessageBackgroundColorGraphite			TXInvertSidebarColor([NSColor internalCalibratedRed:132 green:147 blue:163 alpha:1])

#define _serverCellFont							[NSFont fontWithName:@"LucidaGrande-Bold" size:12.0]
#define _serverCellFontColor						TXInvertSidebarColor([NSColor outlineViewHeaderTextColor])
#define _serverCellFontColorDisabled				TXInvertSidebarColor([NSColor outlineViewHeaderDisabledTextColor])
#define _serverCellSelectionFontColor				TXInvertSidebarColor([NSColor whiteColor])
#define _serverCellSelectionShadowFontColorAW		TXInvertSidebarColor([NSColor colorWithCalibratedWhite:0.00 alpha:0.30])
#define _serverCellSelectionShadowFontColorIA		TXInvertSidebarColor([NSColor colorWithCalibratedWhite:0.00 alpha:0.20])
#define _serverCellShadowColorAW					TXInvertSidebarColor([NSColor colorWithCalibratedWhite:1.00 alpha:1.00])
#define _serverCellShadowColorNA					TXInvertSidebarColor([NSColor colorWithCalibratedWhite:1.00 alpha:1.00])

#define _channelCellFont							[NSFont fontWithName:@"LucidaGrande" size:11.0]
#define _channelCellFontColor						TXInvertSidebarColor([NSColor blackColor])
#define _channelCellSelectionFontColor				TXInvertSidebarColor([NSColor whiteColor])
#define _channelCellSelectionFont					[NSFont fontWithName:@"LucidaGrande-Bold" size:11.0]
#define _channelCellShadowColor					TXInvertSidebarColor([NSColor internalColorWithSRGBRed:1.0 green:1.0 blue:1.0 alpha:0.6])
#define _channelCellSelectionShadowColor_AW			TXInvertSidebarColor([NSColor colorWithCalibratedWhite:0.00 alpha:0.48])
#define _channelCellSelectionShadowColor_IA			TXInvertSidebarColor([NSColor colorWithCalibratedWhite:0.00 alpha:0.30])

#define _graphiteSelectionColorAW					TXInvertSidebarColor([NSColor internalCalibratedRed:17 green:73 blue:126 alpha:1.00])

@implementation TVCServerListCell


#pragma mark -
#pragma mark Status Icon

- (void)drawStatusBadge:(NSString *)iconName inCell:(NSRect)cellFrame withAlpha:(CGFloat)alpha
{
	NSInteger extraMath = 0;
	
	if ([iconName isEqualNoCase:@"NSUser"]) {
		extraMath = 1;
	} 
	
	NSSize iconSize = NSMakeSize(16, 16);
	NSRect iconRect = NSMakeRect( (NSMinX(cellFrame) - iconSize.width - _iconSpacing),
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
	
	NSColor *textColor = _badgeTextColorNS;
	
	if (isSelected) {
		textColor = _badgeTextColorTS;
	}
	
	attributes[NSFontAttributeName] = _badgeFont;
	attributes[NSForegroundColorAttributeName] = textColor;
	
	NSAttributedString *mcstring = [[NSAttributedString alloc] initWithString:messageCountString
																   attributes:attributes];
	
	return mcstring;
}

- (NSRect)messageCountBadgeRect:(NSRect)cellFrame withText:(NSAttributedString *)mcstring 
{
	NSRect badgeFrame;
	
	NSSize    messageCountSize  = [mcstring size];
	NSInteger messageCountWidth = (messageCountSize.width + (_badgeInsideMargin * 2));
	
	badgeFrame = NSMakeRect((NSMaxX(cellFrame) - (_badgeRightMargin + messageCountWidth)),
							(NSMidY(cellFrame) - (_badgeHeight / 2.0)),
							messageCountWidth, _badgeHeight);
	
	if (badgeFrame.size.width < _badgeMinimumWidth) {
		NSInteger widthDiff = (_badgeMinimumWidth - badgeFrame.size.width);
		
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
													xRadius:(_badgeHeight / 2.0)
													yRadius:(_badgeHeight / 2.0)];
		
		[_badgeShadowColor set];
		[badgePath fill];
	}
	
	NSColor *backgroundColor;
	
	if (highlight) {
		backgroundColor = _badgeHighlightBackgroundColor;
	} else {
		if (isSelected) {
			backgroundColor = _badgeMessageBackgroundColorTS;
		} else {
			if ([NSColor currentControlTint] == NSGraphiteControlTint) {
				backgroundColor = _badgeMessageBackgroundColorGraphite;
			} else {
				backgroundColor = _badgeMessageBackgroundColorAqua;
			}
		}
	}
	
	badgePath = [NSBezierPath bezierPathWithRoundedRect:badgeFrame
												xRadius:(_badgeHeight / 2.0)
												yRadius:(_badgeHeight / 2.0)];
	
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
		[_NSGraphicsCurrentContext() setShouldAntialias: NO];
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
				NSString *iconName = @"colloquyRoomTab";
				
				if ([TPCPreferences invertSidebarColors]) {
					iconName = [iconName stringByAppendingString:@"Inverted"];
				} else {
					iconName = [iconName stringByAppendingString:@"Regular"];
				}
				
				if (channel.isActive) {
					[self drawStatusBadge:iconName inCell:cellFrame withAlpha:1.0];
				} else {
					[self drawStatusBadge:iconName inCell:cellFrame withAlpha:0.5];
				}
			} else {
				[self drawStatusBadge:@"NSUser" inCell:cellFrame withAlpha:0.8];
			}
			
			if (unreadCount >= 1 && drawMessageBadge) {
				NSAttributedString *mcstring  = [self messageCountBadgeText:unreadCount selected:(isSelected && isHighlight == NO)];
				NSRect              badgeRect = [self messageCountBadgeRect:cellFrame withText:mcstring];
				
				[self drawMessageCountBadge:mcstring inCell:badgeRect withHighlighgt:isHighlight selected:isSelected];
				
				cellFrame.size.width -= badgeRect.size.width;
			}
			
			cellFrame.size.width -= (_badgeRightMargin * 2);
			
			if (isSelected == NO) {
				[itemShadow setShadowOffset:NSMakeSize(1, -1)];
				[itemShadow setShadowColor:_channelCellShadowColor];
			} else {
				[itemShadow setShadowBlurRadius:2.0];
				[itemShadow setShadowOffset:NSMakeSize(1, -1)];
				
				if (isKeyWindow) {
					if (isGraphite) {
						[itemShadow setShadowColor:_graphiteSelectionColorAW];
					} else {
						[itemShadow setShadowColor:_channelCellSelectionShadowColor_AW];
					}
				} else {
					[itemShadow setShadowColor:_channelCellSelectionShadowColor_IA];
				}
			}
			
			cellFrame.origin.y += 2;
			cellFrame.origin.x -= 2;
			
			NSRange textRange = NSMakeRange(0, [newValue length]);
			
			if (isSelected) {
				[newValue addAttribute:NSFontAttributeName              value:_channelCellSelectionFont       range:textRange];
				[newValue addAttribute:NSForegroundColorAttributeName	value:_channelCellSelectionFontColor range:textRange];
			} else {
				[newValue addAttribute:NSFontAttributeName              value:_channelCellFont         range:textRange];
				[newValue addAttribute:NSForegroundColorAttributeName   value:_channelCellFontColor	range:textRange];
			}
			
			[newValue addAttribute:NSShadowAttributeName value:itemShadow range:textRange];
			
			if ([TPCPreferences useLogAntialiasing] == NO) {
				[_NSGraphicsCurrentContext() saveGraphicsState];
				[_NSGraphicsCurrentContext() setShouldAntialias: NO];
			}
			
			[newValue drawInRect:cellFrame];
			
			if ([TPCPreferences useLogAntialiasing] == NO) {
				[_NSGraphicsCurrentContext() restoreGraphicsState];
			}
		} else {
			cellFrame.origin.y += 4;
			
			NSColor *controlColor	= _serverCellFontColor;
			NSFont  *groupFont		= _serverCellFont;
			
			if (self.cellItem.client.isConnected == NO) {
				controlColor = _serverCellFontColorDisabled;
			}
			
			[itemShadow setShadowOffset:NSMakeSize(1, -1)];
			
			if (isSelected) {
				controlColor = _serverCellSelectionFontColor;
				
				if (isKeyWindow) {
					if (isGraphite) {
						[itemShadow setShadowColor:_graphiteSelectionColorAW];
					} else {
						[itemShadow setShadowColor:_serverCellSelectionShadowFontColorAW];
					}
				} else {
					[itemShadow setShadowColor:_serverCellSelectionShadowFontColorIA];
				}
			} else {
				if (isKeyWindow) {
					[itemShadow setShadowColor:_serverCellShadowColorAW];
				} else {
					[itemShadow setShadowColor:_serverCellShadowColorNA];
				}
			}
			
			NSRange textRange = NSMakeRange(0, [newValue length]);
			
			[newValue addAttribute:NSFontAttributeName				value:groupFont		range:textRange];
			[newValue addAttribute:NSShadowAttributeName			value:itemShadow	range:textRange];
			[newValue addAttribute:NSForegroundColorAttributeName	value:controlColor	range:textRange];
			
			if ([TPCPreferences useLogAntialiasing] == NO) {
				[_NSGraphicsCurrentContext() saveGraphicsState];
				[_NSGraphicsCurrentContext() setShouldAntialias: NO];
			}
			
			[newValue drawInRect:cellFrame];
			
			if ([TPCPreferences useLogAntialiasing] == NO) {
				[_NSGraphicsCurrentContext() restoreGraphicsState];
			}
		}
		
	}
}

@end