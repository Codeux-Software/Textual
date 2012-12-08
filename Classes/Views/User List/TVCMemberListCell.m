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

@implementation TVCMemberListCell

#pragma mark -
#pragma mark Status Badge

- (NSAttributedString *)modeBadgeText:(NSString *)badgeString isSelected:(BOOL)selected
{
    /* Pick which font size best aligns with badge heights. */
	NSMutableDictionary *attributes = [NSMutableDictionary dictionary];

	NSColor *textColor = self.parent.layoutBadgeTextColorNS;
    
    if (selected) {
        textColor = self.parent.layoutBadgeTextColorTS;
    }
	
    attributes[NSFontAttributeName] = self.parent.layoutBadgeFont;
	attributes[NSForegroundColorAttributeName] = textColor;
	
	NSAttributedString *mcstring = [[NSAttributedString alloc] initWithString:badgeString
																   attributes:attributes];
    
	return mcstring;
}

- (void)drawModeBadge:(char)mcstring inCell:(NSRect)badgeFrame isSelected:(BOOL)selected
{
    badgeFrame = NSMakeRect((badgeFrame.origin.x + self.parent.layoutBadgeMargin),
                            (NSMidY(badgeFrame) - (self.parent.layoutBadgeHeight / 2.0)),
                            self.parent.layoutBadgeWidth, self.parent.layoutBadgeHeight);
    
    NSBezierPath *badgePath = nil;
    
	if (selected == NO) {
        NSRect shadowFrame;
        
        shadowFrame = badgeFrame;
        shadowFrame.origin.y += 1;
        
        badgePath = [NSBezierPath bezierPathWithRoundedRect:shadowFrame
                                                    xRadius:4.0
                                                    yRadius:4.0];
        
        NSColor *shadow = self.parent.layoutBadgeShadowColor;
        
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
            backgroundColor = self.parent.layoutBadgeMessageBackgroundColorQ;
        } else if (mcstring == '&' || mcstring == '!') {
            backgroundColor = self.parent.layoutBadgeMessageBackgroundColorA;
        } else if (mcstring == '@') {
            backgroundColor = self.parent.layoutBadgeMessageBackgroundColorO;
        } else if (mcstring == '%') {
            backgroundColor = self.parent.layoutBadgeMessageBackgroundColorH;
        } else if (mcstring == '+') {
            backgroundColor = self.parent.layoutBadgeMessageBackgroundColorV;
        } else {
            backgroundColor = self.parent.layoutBadgeMessageBackgroundColorX;
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
		[_NSGraphicsCurrentContext() setShouldAntialias:NO];
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
	BOOL invertedColors = [TPCPreferences invertSidebarColors];

	// ---- //

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
        
        [self drawModeBadge:self.member.mark inCell:cellFrame isSelected:isSelected];
		
		NSAttributedString			*stringValue	= [self attributedStringValue];	
		NSMutableAttributedString	*newValue		= nil;
        
        newValue = [NSMutableAttributedString alloc];
        newValue = [newValue initWithString:self.member.nick attributes:[stringValue attributes]];
		
		NSShadow *itemShadow = [NSShadow new];
		
		[itemShadow setShadowOffset:NSMakeSize(0, -1)];
		
        if (isSelected == NO) {
            [itemShadow setShadowColor:self.parent.layoutUserCellShadowColor];
        } else {
			if (invertedColors) {
				[itemShadow setShadowBlurRadius:1.0];
			} else {
				[itemShadow setShadowBlurRadius:2.0];
			}
            
            if (isKeyWindow) {
                if (isGraphite && invertedColors == NO) {
                    [itemShadow setShadowColor:self.parent.layoutGraphiteSelectionColorAW];
                } else {
                    [itemShadow setShadowColor:self.parent.layoutUserCellSelectionShadowColorAW];
                }
            } else {
                [itemShadow setShadowColor:self.parent.layoutUserCellSelectionShadowColorIA];
            }
        }
        
        cellFrame.origin.y += 1;
        cellFrame.origin.x += 29;
        cellFrame.size.width -= 29;

        NSRange textRange = NSMakeRange(0, [newValue length]);
        
        if (isSelected) {
            [newValue addAttribute:NSFontAttributeName              value:self.parent.layoutUserCellSelectionFont       range:textRange];
            [newValue addAttribute:NSForegroundColorAttributeName	value:self.parent.layoutUserCellSelectionFontColor range:textRange];
        } else {
            [newValue addAttribute:NSFontAttributeName              value:self.parent.layoutUserCellFont        range:textRange];
            [newValue addAttribute:NSForegroundColorAttributeName   value:self.parent.layoutUserCellFontColor  range:textRange];
        }
        
        [newValue addAttribute:NSShadowAttributeName value:itemShadow range:textRange];
		
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