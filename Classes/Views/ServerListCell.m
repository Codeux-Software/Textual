// Created by Codeux Software <support AT codeux DOT com> <https://github.com/codeux/Textual>
// You can redistribute it and/or modify it under the new BSD license.

/* This class and the one for the user list is based off the open source PXSourceList 
 toolkit developed by Alex Rozanski. The implemtnation is fairly dirty and uses a lot
 of hard coded math/numbers so not recommended to try and use in your own app. 
 
 Let's hope I can even remember how this works six months from now. — Mikey 
 
 Also, I did so much custom drawing in this class and the user list because I enjoyed
 the shadows and such that Lion added to table views so I wanted that to be experienced
 on both Snow Leopard and Lion. */

#define ICON_SPACING                                5.0
#define BADGE_RIGHT_MARGIN                          5.0		
#define BADGE_INSIDE_MARGIN                         5.0
#define MIN_BADGE_WIDTH                             22.0
#define BADGE_HEIGHT                                14.0	

#define BADGE_FONT                                  [_NSFontManager() fontWithFamily:@"Helvetica" traits:NSBoldFontMask weight:15 size:10.5]
#define BADGE_TEXT_COLOR_TS                         [NSColor _colorWithCalibratedRed:158 green:169 blue:197 alpha:1]
#define BADGE_TEXT_COLOR_NS                         [NSColor whiteColor]
#define BADGE_SHADOW_COLOR                          [NSColor colorWithCalibratedWhite:1.00 alpha:0.60]
#define BADGE_MESSAGE_BACKGROUND_COLOR_TS           [NSColor whiteColor]
#define BADGE_HIGHLIGHT_BACKGROUND_COLOR            [NSColor _colorWithCalibratedRed:210 green:15  blue:15  alpha:1]
#define BADGE_MESSAGE_BACKGROUND_COLOR_AQUA         [NSColor _colorWithCalibratedRed:152 green:168 blue:202 alpha:1]
#define BADGE_MESSAGE_BACKGROUND_COLOR_GRAPHITE     [NSColor _colorWithCalibratedRed:132 green:147 blue:163 alpha:1]

#define SERVER_CELL_FONT                            [NSFont fontWithName:@"LucidaGrande-Bold" size:12.0]
#define SERVER_CELL_FONT_COLOR                      [NSColor outlineViewHeaderTextColor]
#define SERVER_CELL_SELECTION_FONT_COLOR            [NSColor whiteColor]
#define SERVER_CELL_SELECTION_SHADOW_COLOR_AW       [NSColor colorWithCalibratedWhite:0.00 alpha:0.30]
#define SERVER_CELL_SELECTION_SHADOW_COLOR_IA       [NSColor colorWithCalibratedWhite:0.00 alpha:0.20]
#define SERVER_CELL_SHADOW_COLOR_AW                 [NSColor colorWithCalibratedWhite:1.00 alpha:1.00]
#define SERVER_CELL_SHADOW_COLOR_NA                 [NSColor colorWithCalibratedWhite:1.00 alpha:1.00]

#define CHANNEL_CELL_FONT                           [NSFont fontWithName:@"LucidaGrande" size:11.0]
#define CHANNEL_CELL_FONT_COLOR                     [NSColor blackColor]
#define CHANNEL_CELL_SELECTION_FONT_COLOR           [NSColor whiteColor]
#define CHANNEL_CELL_SELECTION_FONT                 [NSFont fontWithName:@"LucidaGrande-Bold" size:11.0]
#define CHANNEL_CELL_SHADOW_COLOR                   [NSColor _colorWithSRGBRed:1.0 green:1.0 blue:1.0 alpha:0.5]
#define CHANNEL_CELL_SELECTION_SHADOW_COLOR_AW      [NSColor colorWithCalibratedWhite:0.00 alpha:0.48]
#define CHANNEL_CELL_SELECTION_SHADOW_COLOR_IA      [NSColor colorWithCalibratedWhite:0.00 alpha:0.30]

#define GRAPHITE_SELECTION_COLOR_AW                 [NSColor _colorWithCalibratedRed:17 green:73 blue:126 alpha:1.00]

@implementation ServerListCell

@synthesize parent;
@synthesize cellItem;

#pragma mark -
#pragma mark Status Icon

- (void)drawStatusBadge:(NSString *)iconName inCell:(NSRect)cellFrame
{
	NSInteger extraMath = 0;
	
	if ([iconName isEqualNoCase:@"NSUser"]) {
		extraMath = 1;
	} 
	
	NSSize iconSize = NSMakeSize(16, 16);
	NSRect iconRect = NSMakeRect( (NSMinX(cellFrame) - iconSize.width - ICON_SPACING),
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
		
		[icon drawInRect:iconRect
				fromRect:NSZeroRect
			   operation:NSCompositeSourceOver
				fraction:1
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
	
	NSColor *textColor = BADGE_TEXT_COLOR_NS;
    
    if (isSelected) {
        textColor = BADGE_TEXT_COLOR_TS;
    }
	
	[attributes setObject:BADGE_FONT forKey:NSFontAttributeName];
	[attributes setObject:textColor  forKey:NSForegroundColorAttributeName];
	
	NSAttributedString *mcstring = [[NSAttributedString alloc] initWithString:messageCountString
																   attributes:attributes];
	
	return [mcstring autodrain];
}

- (NSRect)messageCountBadgeRect:(NSRect)cellFrame withText:(NSAttributedString *)mcstring 
{
	NSRect badgeFrame;
	
	NSSize    messageCountSize  = [mcstring size];
	NSInteger messageCountWidth = (messageCountSize.width + (BADGE_INSIDE_MARGIN * 2));
	
	badgeFrame = NSMakeRect((NSMaxX(cellFrame) - (BADGE_RIGHT_MARGIN + messageCountWidth)),
							(NSMidY(cellFrame) - (BADGE_HEIGHT / 2.0)),
							messageCountWidth, BADGE_HEIGHT);
	
	if (badgeFrame.size.width < MIN_BADGE_WIDTH) {
		NSInteger widthDiff = (MIN_BADGE_WIDTH - badgeFrame.size.width);
		
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
                                                    xRadius:(BADGE_HEIGHT / 2.0)
                                                    yRadius:(BADGE_HEIGHT / 2.0)];
        
        [BADGE_SHADOW_COLOR set];
        [badgePath fill];
    }
    
    NSColor *backgroundColor;
	
	if (highlight) {
		backgroundColor = BADGE_HIGHLIGHT_BACKGROUND_COLOR;
	} else {
        if (isSelected) {
            backgroundColor = BADGE_MESSAGE_BACKGROUND_COLOR_TS;
        } else {
            if ([NSColor currentControlTint] == NSGraphiteControlTint) {
                backgroundColor = BADGE_MESSAGE_BACKGROUND_COLOR_GRAPHITE;
            } else {
                backgroundColor = BADGE_MESSAGE_BACKGROUND_COLOR_AQUA;
            }
        }
	}
	
	badgePath = [NSBezierPath bezierPathWithRoundedRect:badgeFrame
												xRadius:(BADGE_HEIGHT / 2.0)
												yRadius:(BADGE_HEIGHT / 2.0)];
	
	[backgroundColor set];
	[badgePath fill];
	
	NSPoint badgeTextPoint;
	
	badgeTextPoint = NSMakePoint( (NSMidX(badgeFrame) - (messageCountSize.width / 2.0)),
								 ((NSMidY(badgeFrame) - (messageCountSize.height / 2.0)) + 1));
	
	[mcstring drawAtPoint:badgeTextPoint];
	
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
	NSInteger selectedRow = [parent selectedRow];
	
	if (cellItem) {
		NSInteger rowIndex = [parent rowForItem:cellItem];
		
		NSWindow *parentWindow = [parent.keyDelegate window];
        
		BOOL isGroupItem = [parent isGroupItem:cellItem];
		BOOL isSelected  = (rowIndex == selectedRow);
		BOOL isKeyWindow = [parentWindow isOnCurrentWorkspace];
        BOOL isGraphite  = ([NSColor currentControlTint] == NSGraphiteControlTint);
        
		IRCChannel *channel = cellItem.log.channel;
		
		/* Draw Background */
        
		if (isSelected && isKeyWindow) {
			/* We draw selected cells using images because the color
			 that Apple uses for cells when the table is not in focus
			 looks ugly in this developer's opinion. */
			
			NSRect backgroundRect = cellFrame;
			NSRect parentRect	  = [parent frame];
			
			backgroundRect.origin.x   = parentRect.origin.x;
			backgroundRect.size.width = parentRect.size.width;
			
			NSString *backgroundImage;
			
			if (channel.isChannel || channel.isTalk) {
				backgroundImage = @"ChannelCellSelection";
			} else {
				backgroundImage = @"ServerCellSelection";
			}
			
			if (isGraphite) {
				backgroundImage = [backgroundImage stringByAppendingString:@"_Graphite.tif"];
			} else {
				backgroundImage = [backgroundImage stringByAppendingString:@"_Aqua.tif"];
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
		
		if (isGroupItem == NO) {
			if (channel.isChannel) {
                if (channel.isActive) {
                    [self drawStatusBadge:@"status-channel-active.tif" inCell:cellFrame];
                } else {
                    [self drawStatusBadge:@"status-channel-inactive.tif" inCell:cellFrame];
                } 
			} else {
				[self drawStatusBadge:@"NSUser" inCell:cellFrame];
			}
			
            BOOL drawMessageBadge = (isSelected == NO ||
                                     (isKeyWindow == NO && isSelected));
            
            NSInteger unreadCount  = cellItem.treeUnreadCount;
            NSInteger keywordCount = cellItem.keywordCount;
            
            BOOL isHighlight = (keywordCount >= 1);
            
            if (unreadCount >= 1 && drawMessageBadge) {
                NSAttributedString *mcstring  = [self messageCountBadgeText:unreadCount selected:(isSelected && isHighlight == NO)];
                NSRect              badgeRect = [self messageCountBadgeRect:cellFrame withText:mcstring];
                
                [self drawMessageCountBadge:mcstring inCell:badgeRect withHighlighgt:isHighlight selected:isSelected];
                
                cellFrame.size.width -= badgeRect.size.width;
            }
            
            cellFrame.size.width -= (BADGE_RIGHT_MARGIN * 2);
            
			if (isSelected == NO) {
                [itemShadow setShadowOffset:NSMakeSize(0, -1)];
                [itemShadow setShadowColor:CHANNEL_CELL_SHADOW_COLOR];
			} else {
                [itemShadow setShadowBlurRadius:2.0];
                [itemShadow setShadowOffset:NSMakeSize(1, -1)];
                
                if (isKeyWindow) {
                    if (isGraphite) {
                        [itemShadow setShadowColor:GRAPHITE_SELECTION_COLOR_AW];
                    } else {
                        [itemShadow setShadowColor:CHANNEL_CELL_SELECTION_SHADOW_COLOR_AW];
                    }
                } else {
                    [itemShadow setShadowColor:CHANNEL_CELL_SELECTION_SHADOW_COLOR_IA];
                }
            }
			
			cellFrame.origin.y += 2;
            cellFrame.origin.x -= 2;
            
			NSRange textRange = NSMakeRange(0, [newValue length]);
			
            if (isSelected) {
                [newValue addAttribute:NSFontAttributeName              value:CHANNEL_CELL_SELECTION_FONT       range:textRange];
                [newValue addAttribute:NSForegroundColorAttributeName	value:CHANNEL_CELL_SELECTION_FONT_COLOR range:textRange];
            } else {
                [newValue addAttribute:NSFontAttributeName              value:CHANNEL_CELL_FONT         range:textRange];
                [newValue addAttribute:NSForegroundColorAttributeName   value:CHANNEL_CELL_FONT_COLOR	range:textRange];
            }
            
            [newValue addAttribute:NSShadowAttributeName value:itemShadow range:textRange];
			[newValue drawInRect:cellFrame];
		} else {
			cellFrame.origin.y += 4;
			
			NSColor *controlColor	= SERVER_CELL_FONT_COLOR;
			NSFont  *groupFont		= SERVER_CELL_FONT;
			
			[itemShadow setShadowOffset:NSMakeSize(1, -1)];
			
			if (isSelected) {
				controlColor = SERVER_CELL_SELECTION_FONT_COLOR;
				
                if (isKeyWindow) {
                    if (isGraphite) {
                        [itemShadow setShadowColor:GRAPHITE_SELECTION_COLOR_AW];
                    } else {
                        [itemShadow setShadowColor:SERVER_CELL_SELECTION_SHADOW_COLOR_AW];
                    }
                } else {
                    [itemShadow setShadowColor:SERVER_CELL_SELECTION_SHADOW_COLOR_IA];
                }
			} else {
                if (isKeyWindow) {
                    [itemShadow setShadowColor:SERVER_CELL_SHADOW_COLOR_AW];
                } else {
                    [itemShadow setShadowColor:SERVER_CELL_SHADOW_COLOR_NA];
                }
			}
			
			NSRange textRange = NSMakeRange(0, [newValue length]);
			
			[newValue addAttribute:NSFontAttributeName				value:groupFont		range:textRange];
			[newValue addAttribute:NSShadowAttributeName			value:itemShadow	range:textRange];
			[newValue addAttribute:NSForegroundColorAttributeName	value:controlColor	range:textRange];
			
			[newValue drawInRect:cellFrame];
		}
		
		[newValue drain];
		[itemShadow drain];
	}
}

@end