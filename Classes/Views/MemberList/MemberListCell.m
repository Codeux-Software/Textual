// Created by Codeux Software <support AT codeux DOT com> <https://github.com/codeux/Textual>
// You can redistribute it and/or modify it under the new BSD license.

/* That is a lot of defenitions … */
#define BADGE_MARGIN                                5.0
#define BADGE_HEIGHT                                14.0
#define BADGE_WIDTH                                 18.0

#define BADGE_FONT                                  [_NSFontManager() fontWithFamily:@"Helvetica" traits:NSBoldFontMask weight:15 size:10.5]
#define BADGE_TEXT_COLOR_TS                         [NSColor _colorWithCalibratedRed:158 green:169 blue:197 alpha:1]
#define BADGE_TEXT_COLOR_NS                         [NSColor whiteColor]

#define BADGE_SHADOW_COLOR                          [NSColor colorWithCalibratedWhite:1.00 alpha:0.60]
#define BADGE_MESSAGE_BACKGROUND_COLOR_TS           [NSColor whiteColor]

#define BADGE_MESSAGE_BACKGROUND_COLOR_MODE_Q		[NSColor _colorWithCalibratedRed:186 green:0   blue:0   alpha:1]
#define BADGE_MESSAGE_BACKGROUND_COLOR_MODE_A		[NSColor _colorWithCalibratedRed:157 green:0   blue:89  alpha:1]
#define BADGE_MESSAGE_BACKGROUND_COLOR_MODE_O		[NSColor _colorWithCalibratedRed:210 green:105 blue:30  alpha:1]
#define BADGE_MESSAGE_BACKGROUND_COLOR_MODE_H		[NSColor _colorWithCalibratedRed:48  green:128 blue:17  alpha:1]
#define BADGE_MESSAGE_BACKGROUND_COLOR_MODE_V		[NSColor _colorWithCalibratedRed:57  green:154 blue:199 alpha:1]
#define BADGE_MESSAGE_BACKGROUND_COLOR_MODE_X		[NSColor _colorWithCalibratedRed:152 green:168 blue:202 alpha:1]

#define USER_CELL_FONT                              [NSFont fontWithName:@"LucidaGrande" size:11.0]
#define USER_CELL_FONT_COLOR                        [NSColor blackColor]
#define USER_CELL_SELECTION_FONT_COLOR              [NSColor whiteColor]
#define USER_CELL_SELECTION_FONT                    [NSFont fontWithName:@"LucidaGrande-Bold" size:11.0]
#define USER_CELL_SHADOW_COLOR                      [NSColor _colorWithSRGBRed:1.0 green:1.0 blue:1.0 alpha:0.5]
#define USER_CELL_SELECTION_SHADOW_COLOR_AW         [NSColor colorWithCalibratedWhite:0.00 alpha:0.48]
#define USER_CELL_SELECTION_SHADOW_COLOR_IA         [NSColor colorWithCalibratedWhite:0.00 alpha:0.30]

#define GRAPHITE_SELECTION_COLOR_AW                 [NSColor _colorWithCalibratedRed:17 green:73 blue:126 alpha:1.00]

@implementation MemberListCell

@synthesize member;
@synthesize parent;
@synthesize cellItem;

#pragma mark -
#pragma mark Status Badge

- (NSAttributedString *)modeBadgeText:(NSString *)badgeString isSelected:(BOOL)selected
{
    /* Pick which font size best aligns with badge heights. */
	NSMutableDictionary *attributes = [NSMutableDictionary dictionary];
	
	NSColor *textColor = BADGE_TEXT_COLOR_NS;
    
    if (selected) {
        textColor = BADGE_TEXT_COLOR_TS;
    }
	
    [attributes setObject:BADGE_FONT forKey:NSFontAttributeName];
	[attributes setObject:textColor  forKey:NSForegroundColorAttributeName];
	
	NSAttributedString *mcstring = [[NSAttributedString alloc] initWithString:badgeString
																   attributes:attributes];
    
	return [mcstring autodrain];
}

- (void)drawModeBadge:(char)mcstring inCell:(NSRect)badgeFrame isSelected:(BOOL)selected
{
    badgeFrame = NSMakeRect((badgeFrame.origin.x + BADGE_MARGIN),
                            (NSMidY(badgeFrame) - (BADGE_HEIGHT / 2.0)),
                            BADGE_WIDTH, BADGE_HEIGHT);
    
    NSBezierPath *badgePath = nil;
    
	if (selected == NO) {
        NSRect shadowFrame;
        
        shadowFrame = badgeFrame;
        shadowFrame.origin.y += 1;
        
        badgePath = [NSBezierPath bezierPathWithRoundedRect:shadowFrame
                                                    xRadius:4.0
                                                    yRadius:4.0];
        
        NSColor *shadow = BADGE_SHADOW_COLOR;
        
        if (shadow) {
            [shadow set];
            
            if (badgePath) {
                [badgePath fill];
            }
        }
	} else {
        badgeFrame.size.width += 1;
    }
    
    NSColor *backgroundColor = [NSColor whiteColor];
    
    if (selected == NO) {
        if (mcstring == '~') {
            backgroundColor = BADGE_MESSAGE_BACKGROUND_COLOR_MODE_Q;
        } else if (mcstring == '&' || mcstring == '!') {
            backgroundColor = BADGE_MESSAGE_BACKGROUND_COLOR_MODE_A;
        } else if (mcstring == '@') {
            backgroundColor = BADGE_MESSAGE_BACKGROUND_COLOR_MODE_O;
        } else if (mcstring == '%') {
            backgroundColor = BADGE_MESSAGE_BACKGROUND_COLOR_MODE_H;
        } else if (mcstring == '+') {
            backgroundColor = BADGE_MESSAGE_BACKGROUND_COLOR_MODE_V;
        } else {
            backgroundColor = BADGE_MESSAGE_BACKGROUND_COLOR_MODE_X;
        }
    } 
    
    if (mcstring == ' ' && [_NSUserDefaults() boolForKey:@"Preferences.General.use_nomode_symbol"]) {
        mcstring = 'x';
    }
    
	badgePath = [NSBezierPath bezierPathWithRoundedRect:badgeFrame
												xRadius:4.0
												yRadius:4.0];
	
    if (backgroundColor) {
        [backgroundColor set];
        
        if (badgePath) {
            [badgePath fill];
        }
    }
    
    NSAttributedString *modeString;
    
	NSPoint badgeTextPoint;
	NSSize  badgeTextSize;
    
    modeString = [self modeBadgeText:[NSString stringWithChar:mcstring] isSelected:selected];
    
	badgeTextSize  = modeString.size;
	badgeTextPoint = NSMakePoint( (NSMidX(badgeFrame) - (badgeTextSize.width / 2.0)),
								 ((NSMidY(badgeFrame) - (badgeTextSize.height / 2.0)) + 1));
    
    if (mcstring == '+' || mcstring == '~' || mcstring == 'x') {
        badgeTextPoint.y -= 1;
    }
    
    [modeString drawAtPoint:badgeTextPoint];
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

- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)view
{
    NSArray *selectedRows = [parent selectedRows];
    
    if (cellItem) {
		IRCChannel *channel = (id)[parent dataSource];
        IRCClient  *client  = [channel client];
        
        NSInteger rowIndex = [parent rowAtPoint:cellFrame.origin];
		
		NSWindow *parentWindow = [client.world window];
        
		BOOL isKeyWindow = [parentWindow isOnCurrentWorkspace];
        BOOL isGraphite  = ([NSColor currentControlTint] == NSGraphiteControlTint);
        BOOL isSelected  = [selectedRows containsObject:[NSNumber numberWithUnsignedInteger:rowIndex]];
		
		/* Draw Background */
        
		if (isSelected && isKeyWindow) {
			/* We draw selected cells using images because the color
			 that Apple uses for cells when the table is not in focus
			 looks ugly in this developer's opinion. */
			
			NSRect backgroundRect = cellFrame;
			NSRect parentRect	  = [client.world.master.memberSplitView frame];
			
			backgroundRect.origin.x   = cellFrame.origin.x;
            backgroundRect.origin.y  -= 1;
			backgroundRect.size.width = parentRect.size.width;
            backgroundRect.size.height = 18;
			
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
        
        [self drawModeBadge:member.mark inCell:cellFrame isSelected:isSelected];
		
		NSAttributedString			*stringValue	= [self attributedStringValue];	
		NSMutableAttributedString	*newValue		= nil;
        
        newValue = [NSMutableAttributedString alloc];
        newValue = [newValue initWithString:member.nick attributes:[stringValue attributes]];
		
		NSShadow *itemShadow = [NSShadow new];
		
        if (isSelected == NO) {
            [itemShadow setShadowOffset:NSMakeSize(0, -1)];
            [itemShadow setShadowColor:USER_CELL_SHADOW_COLOR];
        } else {
            [itemShadow setShadowBlurRadius:2.0];
            [itemShadow setShadowOffset:NSMakeSize(1, -1)];
            
            if (isKeyWindow) {
                if (isGraphite) {
                    [itemShadow setShadowColor:GRAPHITE_SELECTION_COLOR_AW];
                } else {
                    [itemShadow setShadowColor:USER_CELL_SELECTION_SHADOW_COLOR_AW];
                }
            } else {
                [itemShadow setShadowColor:USER_CELL_SELECTION_SHADOW_COLOR_IA];
            }
        }
        
        cellFrame.origin.y += 1;
        cellFrame.origin.x += 29;
        cellFrame.size.width -= 29;
        
        NSRange textRange = NSMakeRange(0, [newValue length]);
        
        if (isSelected) {
            [newValue addAttribute:NSFontAttributeName              value:USER_CELL_SELECTION_FONT       range:textRange];
            [newValue addAttribute:NSForegroundColorAttributeName	value:USER_CELL_SELECTION_FONT_COLOR range:textRange];
        } else {
            [newValue addAttribute:NSFontAttributeName              value:USER_CELL_FONT        range:textRange];
            [newValue addAttribute:NSForegroundColorAttributeName   value:USER_CELL_FONT_COLOR  range:textRange];
        }
        
        [newValue addAttribute:NSShadowAttributeName value:itemShadow range:textRange];
        [newValue drawInRect:cellFrame];
		
		[newValue drain];
		[itemShadow drain];
	}
    
}

@end