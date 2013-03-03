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

@interface TVCMemberListCell ()
@property (nonatomic, readonly, uweak) TVCMemberList *memberList;
@end

@implementation TVCMemberListCell

#pragma mark -
#pragma mark Status Badge

- (NSAttributedString *)modeBadgeText:(NSString *)badgeString isSelected:(BOOL)selected
{
	NSObjectIsEmptyAssertReturn(badgeString, nil);

    /* Pick which font size best aligns with the badge. */
	NSColor *textColor = self.memberList.userMarkBadgeNormalTextColor;
    
    if (selected) {
        textColor = self.memberList.userMarkBadgeSelectedTextColor;
    }

	NSDictionary *attributes = @{
		NSForegroundColorAttributeName : textColor,
		NSFontAttributeName : self.memberList.userMarkBadgeFont
	};
	
	NSAttributedString *mcstring = [[NSAttributedString alloc] initWithString:badgeString
																   attributes:attributes];
    
	return mcstring;
}

- (void)drawModeBadge:(NSString *)mcnstring inCell:(NSRect)badgeFrame isSelected:(BOOL)selected
{
	/* Align the badge. */
    badgeFrame = NSMakeRect((badgeFrame.origin.x + self.memberList.userMarkBadgeMargin),
                            (NSMidY(badgeFrame) - (self.memberList.userMarkBadgeHeight / 2.0)),
												   self.memberList.userMarkBadgeWidth,
												   self.memberList.userMarkBadgeHeight);

	char mcstring = [mcnstring characterAtIndex:0];
	
    NSBezierPath *badgePath = nil;
    
	if (selected == NO) {
		/* If the badge is not selected, then change the Y origin
		 by a value of 1 to compensate for the shadow that will be
		 drawn to the badge. Selected badges do not have a drop 
		 shadow. */
		
        NSRect shadowFrame = badgeFrame;
		
        shadowFrame.origin.y += 1;
        
        badgePath = [NSBezierPath bezierPathWithRoundedRect:shadowFrame xRadius:4.0 yRadius:4.0];
        
		[self.memberList.userMarkBadgeShadowColor set];
		
		[badgePath fill];
	} else {
        badgeFrame.size.width += 1;
    }

	/* Determin the badge's background color. White is the default
	 because that is the color used when the badge is selected. */
    NSColor *backgroundColor = [NSColor whiteColor];
    
    if (selected == NO) {
        if (mcstring == '~') {
            backgroundColor = [self.memberList userMarkBadgeBackgroundColor_Q];
        } else if (mcstring == '&' || mcstring == '!') {
            backgroundColor = [self.memberList userMarkBadgeBackgroundColor_A];
        } else if (mcstring == '@') {
            backgroundColor = [self.memberList userMarkBadgeBackgroundColor_O];
        } else if (mcstring == '%') {
            backgroundColor = [self.memberList userMarkBadgeBackgroundColor_H];
        } else if (mcstring == '+') {
            backgroundColor = [self.memberList userMarkBadgeBackgroundColor_V];
        } else {
			if ([NSColor currentControlTint] == NSGraphiteControlTint) {
				backgroundColor = [self.memberList userMarkBadgeBackgroundColor_XGraphite];
			} else {
				backgroundColor = [self.memberList userMarkBadgeBackgroundColor_XAqua];
			}
        }
    }
	
    if (NSObjectIsEmpty(mcnstring) && [RZUserDefaults() boolForKey:@"DisplayUserListNoModeSymbol"]) {
        mcstring = 'x';
		mcnstring = @"x";
    }

	/* Fill in the background. */
	badgePath = [NSBezierPath bezierPathWithRoundedRect:badgeFrame xRadius:4.0 yRadius:4.0];
	
    [backgroundColor set];
        
	[badgePath fill];

	/* Draw the actual mode symbol. */
    NSAttributedString *modeString = [self modeBadgeText:mcnstring isSelected:selected];

	NSObjectIsEmptyAssert(modeString);

	/* Center the mode symbol relative to the badge itself. */
	NSPoint badgeTextPoint = NSMakePoint((NSMidX(badgeFrame) - (modeString.size.width / 2.0)),
										((NSMidY(badgeFrame) - (modeString.size.height / 2.0)) + 1));
	
	if (mcstring == '+' || mcstring == '~' || mcstring == 'x') {
		badgeTextPoint.y -= 1;
	}

	/* Mountain Lion didn't like our origin. */
	if ([TPCPreferences featureAvailableToOSXMountainLion] && [TPCPreferences runningInHighResolutionMode] == NO) {
		badgeTextPoint.y -= 1;
	}
    
	if ([TPCPreferences useLogAntialiasing] == NO) {
		[RZGraphicsCurrentContext() saveGraphicsState];
		[RZGraphicsCurrentContext() setShouldAntialias:NO];
	}

	/* The actual draw. */
    [modeString drawAtPoint:badgeTextPoint];
	
	if ([TPCPreferences useLogAntialiasing] == NO) {
		[RZGraphicsCurrentContext() restoreGraphicsState];
	}
}

#pragma mark -
#pragma mark Cell Drawing

- (void)drawWithExpansionFrame:(NSRect)cellFrame inView:(NSView *)view
{
    /* Hide yellow tooltip. */
    [[NSColor clearColor] set];
    NSRectFill(cellFrame);

    /* Begin popover. */
    TVCMemberListUserInfoPopover *userInfoPopover = self.masterController.memberListUserInfoPopover;

    /* What permissions does the user have? */
    NSString *permissions = @"UserHostmaskHoverTooltipMode_NA";

    if (self.memberPointer.q) {
        permissions = @"UserHostmaskHoverTooltipMode_Q";
    } else if (self.memberPointer.a) {
        permissions = @"UserHostmaskHoverTooltipMode_A";
    } else if (self.memberPointer.o) {
        permissions = @"UserHostmaskHoverTooltipMode_O";
    } else if (self.memberPointer.h) {
        permissions = @"UserHostmaskHoverTooltipMode_H";
    } else if (self.memberPointer.v) {
        permissions = @"UserHostmaskHoverTooltipMode_V";
    }

    permissions = TXTLS(permissions);

    if (self.memberPointer.isCop) {
        permissions = [permissions stringByAppendingString:TXTLS(@"UserHostmaskHoverTooltipMode_IRCop")];
    }

    /* User info. */
    NSString *nickname = self.memberPointer.nickname;
    NSString *username = self.memberPointer.username;
    NSString *address = self.memberPointer.address;

    if (NSObjectIsEmpty(username)) {
        username = TXTLS(@"UserHostmaskHoverTooltipNoInfo");
    }

    if (NSObjectIsEmpty(address)) {
        address = TXTLS(@"UserHostmaskHoverTooltipNoInfo");
    }

    /* Where is our cell? */
	NSInteger rowIndex = [self.memberList rowAtPoint:cellFrame.origin];
    
    cellFrame = [self.memberList rectOfRow:rowIndex];

    /* Pop our popover. */
    userInfoPopover.nicknameField.stringValue = nickname;
    userInfoPopover.usernameField.stringValue = username;
    userInfoPopover.addressField.stringValue = address;
    userInfoPopover.privilegesField.stringValue = permissions;

    [userInfoPopover showRelativeToRect:cellFrame
                                 ofView:view
                          preferredEdge:NSMinXEdge];
}

- (NSColor *)highlightColorWithFrame:(NSRect)cellFrame inView:(NSView *)controlView
{
	return nil;
}

- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)view
{
	PointerIsEmptyAssert(self.channelPointer);
	PointerIsEmptyAssert(self.memberPointer);

	/* Declare variables. */
	BOOL invertedColors = [TPCPreferences invertSidebarColors];

	IRCChannel *channel = self.channelPointer;
	IRCUser *member = self.memberPointer;

	NSInteger rowIndex = [self.memberList rowAtPoint:cellFrame.origin];
	
	BOOL isGraphite = ([NSColor currentControlTint] == NSGraphiteControlTint);
	BOOL isKeyWindow = [self.masterController.mainWindow isOnCurrentWorkspace];
	BOOL isSelected = ([self.memberList.selectedRows containsObject:@(rowIndex)]);

	/* Draw Background */
	if (isSelected) {
		NSRect backgdRect = cellFrame;
		NSRect parentRect = self.masterController.memberSplitView.frame;

		// ---- //
		
		backgdRect.origin.x = cellFrame.origin.x;
		backgdRect.origin.y -= 1;
		
		backgdRect.size.width = parentRect.size.width;
		backgdRect.size.height = 18;

		// ---- //
		
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

		// ---- //
		
		NSImage *origBackgroundImage = [NSImage imageNamed:backgroundImage];
		
		[origBackgroundImage drawInRect:backgdRect
							   fromRect:NSZeroRect
							  operation:NSCompositeSourceOver
							   fraction:1
						 respectFlipped:YES
								  hints:nil];
	}
		
	/* Draw Badges, Text, and Status Icon */
	[self drawModeBadge:member.mark inCell:cellFrame isSelected:isSelected];
	
	NSMutableAttributedString *newStrValue = [[NSMutableAttributedString alloc] initWithString:member.nickname
																					attributes:self.attributedStringValue.attributes];

	/* Prepare the drop shadow. */
	NSShadow *itemShadow = [NSShadow new];
	
	[itemShadow setShadowOffset:NSMakeSize(0, -1)];
	
	if (isSelected == NO) {
		[itemShadow setShadowColor:[self.memberList normalCellTextShadowColor]];
	} else {
		if (invertedColors) {
			[itemShadow setShadowBlurRadius:1.0];
		} else {
			[itemShadow setShadowBlurRadius:2.0];
		}
		
		if (isKeyWindow) {
			if (isGraphite && invertedColors == NO) {
				[itemShadow setShadowColor:self.memberList.graphiteSelectedCellTextShadowColorForActiveWindow];
			} else {
				[itemShadow setShadowColor:self.memberList.normalSelectedCellTextShadowColorForActiveWindow];
			}
		} else {
			[itemShadow setShadowColor:self.memberList.normalSelectedCellTextShadowColorForInactiveWindow];
		}
	}

	/* Update our origin. Probaby not a good idea to have such values hard-coded into
	 here, but stuff like this is all over the codebase of Textual so it is not something
	 that is new to us. */
	cellFrame.origin.y += 1;
	cellFrame.origin.x += 29;
	
	cellFrame.size.width -= 29;

	NSRange textRange = NSMakeRange(0, newStrValue.length);

	/* Define our attributes. */
	if (isSelected) {
		[newStrValue addAttribute:NSFontAttributeName value:self.memberList.selectedCellFont range:textRange];
		[newStrValue addAttribute:NSForegroundColorAttributeName value:self.memberList.selectedCellTextColor range:textRange];
	} else {
		[newStrValue addAttribute:NSFontAttributeName value:self.memberList.normalCellFont range:textRange];
		[newStrValue addAttribute:NSForegroundColorAttributeName value:self.memberList.normalCellTextColor range:textRange];
	}
	
	[newStrValue addAttribute:NSShadowAttributeName value:itemShadow range:textRange];
	
	if ([TPCPreferences useLogAntialiasing] == NO) {
		[RZGraphicsCurrentContext() saveGraphicsState];
		[RZGraphicsCurrentContext() setShouldAntialias:NO];
	}

	/* Do the actual draw. */
	[newStrValue drawInRect:cellFrame];
	
	if ([TPCPreferences useLogAntialiasing] == NO) {
		[RZGraphicsCurrentContext() restoreGraphicsState];
	}
}

- (TVCMemberList *)memberList
{
	return self.masterController.memberList;
}

@end
