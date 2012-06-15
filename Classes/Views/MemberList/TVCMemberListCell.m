// Created by Codeux Software <support AT codeux DOT com> <https://github.com/codeux/Textual>
// You can redistribute it and/or modify it under the new BSD license.
// Converted to ARC Support on June 07, 2012

/* That is a lot of defenitions … */
#define _badgeMargin                                5.0
#define _badgeHeight                                14.0
#define _badgeWidth                                 18.0

#define _badgeFont									[_NSFontManager() fontWithFamily:@"Helvetica" traits:NSBoldFontMask weight:15 size:10.5]
#define _badgeTextColorTS							[NSColor internalCalibratedRed:158 green:169 blue:197 alpha:1]
#define _badgeTextColorNS							[NSColor whiteColor]
#define _badgeShadowColor							[NSColor colorWithCalibratedWhite:1.00 alpha:0.60]

#define _badgeMessageBackgroundColorTS				[NSColor whiteColor]
#define _badgeMessageBackgroundColorQ				[NSColor internalCalibratedRed:186 green:0   blue:0   alpha:1]
#define _badgeMessageBackgroundColorA				[NSColor internalCalibratedRed:157 green:0   blue:89  alpha:1]
#define _badgeMessageBackgroundColorO				[NSColor internalCalibratedRed:210 green:105 blue:30  alpha:1]
#define _badgeMessageBackgroundColorH				[NSColor internalCalibratedRed:48  green:128 blue:17  alpha:1]
#define _badgeMessageBackgroundColorV				[NSColor internalCalibratedRed:57  green:154 blue:199 alpha:1]
#define _badgeMessageBackgroundColorX				[NSColor internalCalibratedRed:152 green:168 blue:202 alpha:1]

#define _userCellFont								[NSFont fontWithName:@"LucidaGrande" size:11.0]
#define _userCellFontColor							[NSColor blackColor]
#define _userCellSelectionFontColor					[NSColor whiteColor]
#define _userCellSelectionFont						[NSFont fontWithName:@"LucidaGrande-Bold" size:11.0]
#define _userCellShadowColor						[NSColor internalColorWithSRGBRed:1.0 green:1.0 blue:1.0 alpha:0.6]
#define _userCellSelectionShadowColorAW				[NSColor colorWithCalibratedWhite:0.00 alpha:0.48]
#define _userCellSelectionShadowColorIA				[NSColor colorWithCalibratedWhite:0.00 alpha:0.30]

#define _graphiteSelectionColorAW					[NSColor internalCalibratedRed:17 green:73 blue:126 alpha:1.00]

@implementation TVCMemberListCell

@synthesize member;
@synthesize parent;
@synthesize cellItem;

#pragma mark -
#pragma mark Status Badge

- (NSAttributedString *)modeBadgeText:(NSString *)badgeString isSelected:(BOOL)selected
{
    /* Pick which font size best aligns with badge heights. */
	NSMutableDictionary *attributes = [NSMutableDictionary dictionary];
	
	NSColor *textColor = _badgeTextColorNS;
    
    if (selected) {
        textColor = _badgeTextColorTS;
    }
	
    [attributes setObject:_badgeFont forKey:NSFontAttributeName];
	[attributes setObject:textColor  forKey:NSForegroundColorAttributeName];
	
	NSAttributedString *mcstring = [[NSAttributedString alloc] initWithString:badgeString
																   attributes:attributes];
    
	return mcstring;
}

- (void)drawModeBadge:(char)mcstring inCell:(NSRect)badgeFrame isSelected:(BOOL)selected
{
    badgeFrame = NSMakeRect((badgeFrame.origin.x + _badgeMargin),
                            (NSMidY(badgeFrame) - (_badgeHeight / 2.0)),
                            _badgeWidth, _badgeHeight);
    
    NSBezierPath *badgePath = nil;
    
	if (selected == NO) {
        NSRect shadowFrame;
        
        shadowFrame = badgeFrame;
        shadowFrame.origin.y += 1;
        
        badgePath = [NSBezierPath bezierPathWithRoundedRect:shadowFrame
                                                    xRadius:4.0
                                                    yRadius:4.0];
        
        NSColor *shadow = _badgeShadowColor;
        
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
            backgroundColor = _badgeMessageBackgroundColorQ;
        } else if (mcstring == '&' || mcstring == '!') {
            backgroundColor = _badgeMessageBackgroundColorA;
        } else if (mcstring == '@') {
            backgroundColor = _badgeMessageBackgroundColorO;
        } else if (mcstring == '%') {
            backgroundColor = _badgeMessageBackgroundColorH;
        } else if (mcstring == '+') {
            backgroundColor = _badgeMessageBackgroundColorV;
        } else {
            backgroundColor = _badgeMessageBackgroundColorX;
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
	
	if ([TPCPreferences featureAvailableToOSXMountainLion]) {
		badgeTextPoint.y -= 1;
	}
    
	if ([TPCPreferences useLogAntialiasing] == NO) {
		[_NSGraphicsCurrentContext() saveGraphicsState];
		[_NSGraphicsCurrentContext() setShouldAntialias: NO];
	}
	
    [modeString drawAtPoint:badgeTextPoint];
	
	if ([TPCPreferences useLogAntialiasing] == NO) {
		[_NSGraphicsCurrentContext() restoreGraphicsState];
	}
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
    NSArray *selectedRows = [self.parent selectedRows];
    
    if (self.cellItem) {
		IRCChannel *channel = (id)[self.parent dataSource];
        IRCClient  *client  = [channel client];
        
        NSInteger rowIndex = [self.parent rowAtPoint:cellFrame.origin];
		
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
        
        [self drawModeBadge:self.member.mark inCell:cellFrame isSelected:isSelected];
		
		NSAttributedString			*stringValue	= [self attributedStringValue];	
		NSMutableAttributedString	*newValue		= nil;
        
        newValue = [NSMutableAttributedString alloc];
        newValue = [newValue initWithString:self.member.nick attributes:[stringValue attributes]];
		
		NSShadow *itemShadow = [NSShadow new];
		
        if (isSelected == NO) {
            [itemShadow setShadowOffset:NSMakeSize(1, -1)];
            [itemShadow setShadowColor:_userCellShadowColor];
        } else {
            [itemShadow setShadowBlurRadius:2.0];
            [itemShadow setShadowOffset:NSMakeSize(1, -1)];
            
            if (isKeyWindow) {
                if (isGraphite) {
                    [itemShadow setShadowColor:_graphiteSelectionColorAW];
                } else {
                    [itemShadow setShadowColor:_userCellSelectionShadowColorAW];
                }
            } else {
                [itemShadow setShadowColor:_userCellSelectionShadowColorIA];
            }
        }
        
        cellFrame.origin.y += 1;
        cellFrame.origin.x += 29;
        cellFrame.size.width -= 29;
        
        NSRange textRange = NSMakeRange(0, [newValue length]);
        
        if (isSelected) {
            [newValue addAttribute:NSFontAttributeName              value:_userCellSelectionFont       range:textRange];
            [newValue addAttribute:NSForegroundColorAttributeName	value:_userCellSelectionFontColor range:textRange];
        } else {
            [newValue addAttribute:NSFontAttributeName              value:_userCellFont        range:textRange];
            [newValue addAttribute:NSForegroundColorAttributeName   value:_userCellFontColor  range:textRange];
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
		
	}
    
}

@end