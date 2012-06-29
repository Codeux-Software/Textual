// Created by Codeux Software <support AT codeux DOT com> <https://github.com/codeux/Textual>
// You can redistribute it and/or modify it under the new BSD license.
// Converted to ARC Support on June 07, 2012

#import "TextualApplication.h"

@implementation TVCMemberListCell

#pragma mark -
#pragma mark Color Scheme

/* We have a lot of variables to keep track of… */
static NSInteger _badgeMargin	= 5.0;
static NSInteger _badgeHeight	= 14.0;
static NSInteger _badgeWidth	= 18.0;

static NSFont  *_badgeFont;
static NSColor *_badgeTextColorTS;
static NSColor *_badgeTextColorNS;
static NSColor *_badgeShadowColor;

static NSColor *_badgeMessageBackgroundColorTS;
static NSColor *_badgeMessageBackgroundColorQ;
static NSColor *_badgeMessageBackgroundColorA;
static NSColor *_badgeMessageBackgroundColorO;
static NSColor *_badgeMessageBackgroundColorH;
static NSColor *_badgeMessageBackgroundColorV;
static NSColor *_badgeMessageBackgroundColorX;

static NSFont  *_userCellFont;
static NSColor *_userCellFontColor;
static NSColor *_userCellSelectionFontColor;
static NSFont  *_userCellSelectionFont;
static NSColor *_userCellShadowColor;
static NSColor *_userCellSelectionShadowColorAW;
static NSColor *_userCellSelectionShadowColorIA;

static NSColor *_graphiteSelectionColorAW;

static BOOL _drawUsingInvertedColors;
static BOOL _defaultDrawingColorsPopulated;

- (void)updateOutlineViewColorScheme
{
	BOOL invertedColors = [TPCPreferences invertSidebarColors];
	
	if (_drawUsingInvertedColors == invertedColors && _defaultDrawingColorsPopulated) {
		return;
	}
	
	_drawUsingInvertedColors = invertedColors;
	
	if (_defaultDrawingColorsPopulated == NO) {
		_badgeFont						= [_NSFontManager() fontWithFamily:@"Helvetica" traits:NSBoldFontMask weight:15 size:10.5];
		
		_userCellFont					= [NSFont fontWithName:@"LucidaGrande"		size:11.0];
		_userCellSelectionFont			= [NSFont fontWithName:@"LucidaGrande-Bold" size:11.0];
		
		_defaultDrawingColorsPopulated = YES;
	}
	
	if (_drawUsingInvertedColors == NO) {
		/* //////////////////////////////////////////////////// */
		/* Standard Aqua Colors. */
		/* //////////////////////////////////////////////////// */
		
		_badgeTextColorTS				= [NSColor internalCalibratedRed:158 green:169 blue:197 alpha:1];
		_badgeTextColorNS				= [NSColor whiteColor];
		_badgeShadowColor				= [NSColor colorWithCalibratedWhite:1.00 alpha:0.60];
		
		_badgeMessageBackgroundColorTS	= [NSColor whiteColor];
		_badgeMessageBackgroundColorQ	= [NSColor internalCalibratedRed:186 green:0   blue:0   alpha:1];
		_badgeMessageBackgroundColorA	= [NSColor internalCalibratedRed:157 green:0   blue:89  alpha:1];
		_badgeMessageBackgroundColorO	= [NSColor internalCalibratedRed:210 green:105 blue:30  alpha:1];
		_badgeMessageBackgroundColorH	= [NSColor internalCalibratedRed:48  green:128 blue:17  alpha:1];
		_badgeMessageBackgroundColorV	= [NSColor internalCalibratedRed:57  green:154 blue:199 alpha:1];
		_badgeMessageBackgroundColorX	= [NSColor internalCalibratedRed:152 green:168 blue:202 alpha:1];
		
		_userCellFontColor				= [NSColor blackColor];
		_userCellSelectionFontColor		= [NSColor whiteColor];
		_userCellShadowColor			= [NSColor internalColorWithSRGBRed:1.0 green:1.0 blue:1.0 alpha:0.6];
		_userCellSelectionShadowColorAW	= [NSColor colorWithCalibratedWhite:0.00 alpha:0.48];
		_userCellSelectionShadowColorIA	= [NSColor colorWithCalibratedWhite:0.00 alpha:0.30];
		
		_graphiteSelectionColorAW		= [NSColor internalCalibratedRed:17 green:73 blue:126 alpha:1.00];
		
		/* //////////////////////////////////////////////////// */
		/* Standard Aqua Colors. — @end */
		/* //////////////////////////////////////////////////// */
	} else {
		/* //////////////////////////////////////////////////// */
		/* Black Aqua Colors. */
		/* //////////////////////////////////////////////////// */
		
		_badgeTextColorTS				= [NSColor internalCalibratedRed:36.0 green:36.0 blue:36.0 alpha:1];
		_badgeTextColorNS				= [NSColor whiteColor];
		_badgeShadowColor				= [NSColor internalCalibratedRed:60.0 green:60.0 blue:60.0 alpha:1];
		
		_badgeMessageBackgroundColorTS	= [NSColor whiteColor];
		_badgeMessageBackgroundColorQ	= [NSColor internalCalibratedRed:186 green:0   blue:0   alpha:1];
		_badgeMessageBackgroundColorA	= [NSColor internalCalibratedRed:157 green:0   blue:89  alpha:1];
		_badgeMessageBackgroundColorO	= [NSColor internalCalibratedRed:210 green:105 blue:30  alpha:1];
		_badgeMessageBackgroundColorH	= [NSColor internalCalibratedRed:48  green:128 blue:17  alpha:1];
		_badgeMessageBackgroundColorV	= [NSColor internalCalibratedRed:57  green:154 blue:199 alpha:1];
		_badgeMessageBackgroundColorX	= [NSColor internalCalibratedRed:48  green:48  blue:48 alpha:1];;
		
		_userCellFontColor				= [NSColor internalCalibratedRed:225.0 green:224.0 blue:224.0 alpha:1];
		_userCellSelectionFontColor		= [NSColor internalCalibratedRed:36.0 green:36.0 blue:36.0 alpha:1];
		_userCellShadowColor			= [NSColor colorWithCalibratedWhite:0.00 alpha:0.90];
		_userCellSelectionShadowColorAW	= [NSColor colorWithCalibratedWhite:1.00 alpha:0.30];
		_userCellSelectionShadowColorIA	= [NSColor colorWithCalibratedWhite:1.00 alpha:0.30];
		
		/* //////////////////////////////////////////////////// */
		/* Black Aqua Colors. — @end */
		/* //////////////////////////////////////////////////// */
	}
}

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
	
    attributes[NSFontAttributeName] = _badgeFont;
	attributes[NSForegroundColorAttributeName] = textColor;
	
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
    
    if (mcstring == ' ' && [_NSUserDefaults() boolForKey:@"DisplayUserListNoModeSymbol"]) {
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
	
	if ([TPCPreferences featureAvailableToOSXMountainLion] && [TPCPreferences runningInHighResolutionMode] == NO) {
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
	[self updateOutlineViewColorScheme];
	
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
        
		if (isSelected) {
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
			
			if (_drawUsingInvertedColors == NO) {
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
        
        [self drawModeBadge:self.member.mark inCell:cellFrame isSelected:isSelected];
		
		NSAttributedString			*stringValue	= [self attributedStringValue];	
		NSMutableAttributedString	*newValue		= nil;
        
        newValue = [NSMutableAttributedString alloc];
        newValue = [newValue initWithString:self.member.nick attributes:[stringValue attributes]];
		
		NSShadow *itemShadow = [NSShadow new];
		
		[itemShadow setShadowOffset:NSMakeSize(0, -1)];
		
        if (isSelected == NO) {
            [itemShadow setShadowColor:_userCellShadowColor];
        } else {
			if (_drawUsingInvertedColors) {
				[itemShadow setShadowBlurRadius:1.0];
			} else {
				[itemShadow setShadowBlurRadius:2.0];
			}
            
            if (isKeyWindow) {
                if (isGraphite && _drawUsingInvertedColors == NO) {
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