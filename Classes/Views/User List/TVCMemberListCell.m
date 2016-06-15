/* ********************************************************************* 
                  _____         _               _
                 |_   _|____  _| |_ _   _  __ _| |
                   | |/ _ \ \/ / __| | | |/ _` | |
                   | |  __/>  <| |_| |_| | (_| | |
                   |_|\___/_/\_\\__|\__,_|\__,_|_|

 Copyright (c) 2010 - 2015 Codeux Software, LLC & respective contributors.
        Please see Acknowledgements.pdf for additional information.

 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions
 are met:

    * Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the
      documentation and/or other materials provided with the distribution.
    * Neither the name of Textual and/or "Codeux Software, LLC", nor the 
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
#pragma mark Drawing

- (BOOL)wantsUpdateLayer
{
	return YES;
}

- (NSViewLayerContentsRedrawPolicy)layerContentsRedrawPolicy
{
	return NSViewLayerContentsRedrawOnSetNeedsDisplay;
}

- (void)updateLayer
{
	[self updateDrawing];
}

- (void)updateDrawing
{
	[self updateDrawing:[mainWindowMemberList() userInterfaceObjects]];
}

- (void)updateDrawing:(id)interfaceObject
{
	/* Define context. */
	IRCUser *associatedUser = [self memberPointer];
	
	/* Maybe update text field value. */
	NSTextField *textField = [self cellTextField];
	
	NSString *stringValue = [textField stringValue];
	
	NSString *labelValue = [associatedUser nickname];
	
	if ([stringValue isEqualTo:labelValue] == NO) {
		[textField setStringValue:labelValue];
	}
	
	NSDictionary *drawingContext = [self drawingContext];
	
	id userInterfaceObjects = [mainWindowMemberList() userInterfaceObjects];
	
	BOOL isSelected = [drawingContext boolForKey:@"isSelected"];
	
	if ([XRSystemInformation isUsingOSXYosemiteOrLater]) {
		NSAttributedString *newValue = [self attributedTextFieldValueForYosemite:userInterfaceObjects inContext:drawingContext];
		
		[textField setAttributedStringValue:newValue];
	} else {
		NSAttributedString *newValue = [self attributedTextFieldValueForMavericks:userInterfaceObjects inContext:drawingContext];
		
		[textField setAttributedStringValue:newValue];
	}
		
	[self updateUserMarkBadge:isSelected];

	[self populateAccessibilityDescriptions];
}

- (void)populateAccessibilityDescriptions
{
	IRCUser *associatedUser = [self memberPointer];

	NSString *nickname = [associatedUser nickname];

	[XRAccessibility setAccessibilityValueDescription:TXTLS(@"Accessibility[1000]", nickname) forObject:[[self cellTextField] cell]];
}

#pragma mark -
#pragma mark Text Field Attributes

- (NSAttributedString *)attributedTextFieldValueForMavericks:(id)interfaceObject inContext:(NSDictionary *)drawingContext
{
	BOOL isWindowActive = [drawingContext boolForKey:@"isActiveWindow"];
	BOOL isSelected = [drawingContext boolForKey:@"isSelected"];
	BOOL isInverted = [drawingContext boolForKey:@"isInverted"];
	BOOL isGraphite = [drawingContext boolForKey:@"isGraphite"];
	
	/* Update actual text field value. */
	IRCUser *assosicatedUser = [self memberPointer];
	
	/* Update attributed string. */
	NSTextField *textField = [self cellTextField];
	
	NSAttributedString *stringValue = [textField attributedStringValue];
	
	NSMutableAttributedString *mutableStringValue = [stringValue mutableCopy];
	
	NSRange stringLengthRange = NSMakeRange(0, [mutableStringValue length]);
	
	[mutableStringValue beginEditing];
	
	/* Prepare the drop shadow for text. */
	NSShadow *itemShadow = [NSShadow new];
	
	[itemShadow setShadowOffset:NSMakeSize(0, -(1.0))];
	
	if (isSelected == NO) {
		[itemShadow setShadowColor:[interfaceObject normalCellTextShadowColor]];
	} else {
		if (isInverted) {
			[itemShadow setShadowBlurRadius:1.0];
		} else {
			[itemShadow setShadowBlurRadius:2.0];
		}
		
		if (isWindowActive) {
			if (isGraphite && isInverted == NO) {
				[itemShadow setShadowColor:[interfaceObject graphiteSelectedCellTextShadowColorForActiveWindow]];
			} else {
				[itemShadow setShadowColor:[interfaceObject normalSelectedCellTextShadowColorForActiveWindow]];
			}
		} else {
			[itemShadow setShadowColor:[interfaceObject normalSelectedCellTextShadowColorForInactiveWindow]];
		}
	}
	
	/* Prepare other attributes. */
	if (isSelected) {
		[mutableStringValue addAttribute:NSFontAttributeName value:[interfaceObject selectedCellFont] range:stringLengthRange];
		
		[mutableStringValue addAttribute:NSForegroundColorAttributeName value:[interfaceObject selectedCellTextColor] range:stringLengthRange];
	} else {
		[mutableStringValue addAttribute:NSFontAttributeName value:[interfaceObject normalCellFont] range:stringLengthRange];
		
		if ([assosicatedUser isAway]) {
			[mutableStringValue addAttribute:NSForegroundColorAttributeName value:[interfaceObject awayUserCellTextColor] range:stringLengthRange];
		} else {
			[mutableStringValue addAttribute:NSForegroundColorAttributeName value:[interfaceObject normalCellTextColor] range:stringLengthRange];
		}
	}
	
	[mutableStringValue addAttribute:NSShadowAttributeName value:itemShadow range:stringLengthRange];
	
	/* End editing. */
	[mutableStringValue endEditing];
	
	/* Draw new attributed string. */
	return mutableStringValue;
}

- (NSAttributedString *)attributedTextFieldValueForYosemite:(id)interfaceObject inContext:(NSDictionary *)drawingContext
{
	/* Gather basic context information. */
	BOOL isWindowActive = [drawingContext boolForKey:@"isActiveWindow"];
	BOOL isSelected = [drawingContext boolForKey:@"isSelected"];
	
	/* Update actual text field value. */
	IRCUser *assosicatedUser = [self memberPointer];
	
	/* Update attributed string. */
	NSTextField *textField = [self cellTextField];
	
	NSAttributedString *stringValue = [textField attributedStringValue];
	
	NSMutableAttributedString *mutableStringValue = [stringValue mutableCopy];
	
	NSRange stringLengthRange = NSMakeRange(0, [mutableStringValue length]);
	
	/* Finish editing. */
	[mutableStringValue beginEditing];
	
	if (isSelected == NO) {
		if ([assosicatedUser isAway] == NO) {
			if (isWindowActive == NO) {
				[mutableStringValue addAttribute:NSForegroundColorAttributeName value:[interfaceObject normalCellTextColorForInactiveWindow] range:stringLengthRange];
			} else {
				[mutableStringValue addAttribute:NSForegroundColorAttributeName value:[interfaceObject normalCellTextColorForActiveWindow] range:stringLengthRange];
			}
		} else {
			if (isWindowActive == NO) {
				[mutableStringValue addAttribute:NSForegroundColorAttributeName value:[interfaceObject awayUserCellTextColorForInactiveWindow] range:stringLengthRange];
			} else {
				[mutableStringValue addAttribute:NSForegroundColorAttributeName value:[interfaceObject awayUserCellTextColorForActiveWindow] range:stringLengthRange];
			}
		}
	} else {
		if (isWindowActive == NO) {
			[mutableStringValue addAttribute:NSForegroundColorAttributeName value:[interfaceObject selectedCellTextColorForInactiveWindow] range:stringLengthRange];
		} else {
			[mutableStringValue addAttribute:NSForegroundColorAttributeName value:[interfaceObject selectedCellTextColorForActiveWindow] range:stringLengthRange];
		}
	}
	
	/* Finish editing. */
	[mutableStringValue endEditing];
	
	/* Draw new attributed string. */
	return mutableStringValue;
}

#pragma mark -
#pragma mark Badge Drawing

- (NSAttributedString *)modeBadgeText:(NSString *)badgeString isSelected:(BOOL)selected
{
	id userInterfaceObjects = [mainWindowMemberList() userInterfaceObjects];
	
	BOOL isDrawingForRetina = [mainWindow() runningInHighResolutionMode];
	
	NSColor *textColor = nil;
	
	NSFont *textFont = nil;
	
	if (selected) {
		textColor = [userInterfaceObjects userMarkBadgeSelectedTextColor];
		
		if (isDrawingForRetina) {
			textFont = [userInterfaceObjects userMarkBadgeFontSelectedForRetina];
		} else {
			textFont = [userInterfaceObjects userMarkBadgeFontSelected];
		}
	} else {
		textColor = [userInterfaceObjects userMarkBadgeNormalTextColor];
		
		if (isDrawingForRetina) {
			textFont = [userInterfaceObjects userMarkBadgeFontForRetina];
		} else {
			textFont = [userInterfaceObjects userMarkBadgeFont];
		}
	}
	
	NSDictionary *attributes = @{NSForegroundColorAttributeName : textColor, NSFontAttributeName : textFont};
	
	NSAttributedString *mcstring = [NSAttributedString attributedStringWithString:badgeString attributes:attributes];
	
	return mcstring;
}

- (void)updateUserMarkBadge:(BOOL)selected
{
	/* Define context information. */
	id userInterfaceObjects = [mainWindowMemberList() userInterfaceObjects];

	IRCUser *assosicatedUser = [self memberPointer];
	
	NSString *userMark = [assosicatedUser mark];

	IRCUserRank userRankToDraw = IRCUserNoRank;

	if ([TPCPreferences memberListSortFavorsServerStaff]) {
		if ([assosicatedUser isCop]) {
			userRankToDraw = IRCUserIRCopByModeRank;
		}
	}

	if (userRankToDraw == IRCUserNoRank) {
		userRankToDraw = [assosicatedUser rank];
	}

	/* Get value by performing cache token. */
	NSImage *cachedImage = nil;
	
	if (selected == NO) {
		cachedImage = [userInterfaceObjects cachedUserMarkBadgeForSymbol:userMark rank:userRankToDraw];
	}
	
	/* Do we have a cache? */
	if (cachedImage == nil) {
		/* There is no cache so we generate the image live then set it. */
		cachedImage = [self drawModeBadge:selected forRank:userRankToDraw];
		
		/* If we are not selected, we write the cached value to the UI. */
		if (selected == NO) {
			[userInterfaceObjects cacheUserMarkBadge:cachedImage forSymbol:userMark rank:userRankToDraw];
		}
	}
	
	/* Now that we have a cached image, we compare it. */
	NSImageView *imageView = [self imageView];
	
	if (NSObjectsAreEqual([imageView image], cachedImage) == NO) {
		[imageView setImage:cachedImage];
	}
}

- (NSImage *)drawModeBadge:(BOOL)selected forRank:(IRCUserRank)userRank
{
	/* Define context information. */
	id userInterfaceObjects = [mainWindowMemberList() userInterfaceObjects];

	IRCUser *assosicatedUser = [self memberPointer];
	
	BOOL isDrawingForMavericks = ([XRSystemInformation isUsingOSXYosemiteOrLater] == NO);
	
	NSString *mcstring = [assosicatedUser mark];
	
	/* Create image that we will draw into. If we are drawing for Mavericks,
	 then the frame of our image is one pixel greater because we draw a shadow. */
	NSImage *newImage = nil;
	
	NSRect boxFrame = NSZeroRect;
	
	if (isDrawingForMavericks) {
		boxFrame = NSMakeRect(0.0,
							  1.0,
							  [userInterfaceObjects userMarkBadgeWidth],
							  [userInterfaceObjects userMarkBadgeHeight]);
		
		newImage = [NSImage newImageWithSize:NSMakeSize(NSWidth(boxFrame), (NSHeight(boxFrame) + 1.0))];
	} else {
		boxFrame = NSMakeRect(0.0,
							  0.0,
							  [userInterfaceObjects userMarkBadgeWidth],
							  [userInterfaceObjects userMarkBadgeHeight]);
		
		newImage = [NSImage newImageWithSize:NSMakeSize(NSWidth(boxFrame),  NSHeight(boxFrame))];
	}
	
	[newImage lockFocus];
	
	/* Decide the background color. */
	NSColor *backgroundColor = nil;

	if (selected) {
		backgroundColor = [userInterfaceObjects userMarkBadgeSelectedBackgroundColor];
	} else if (userRank == IRCUserIRCopByModeRank) {
		backgroundColor = [userInterfaceObjects userMarkBadgeBackgroundColor_Y];
	} else if (userRank == IRCUserChannelOwnerRank) {
		backgroundColor = [userInterfaceObjects userMarkBadgeBackgroundColor_Q];
	} else if (userRank == IRCUserSuperOperatorRank) {
		backgroundColor = [userInterfaceObjects userMarkBadgeBackgroundColor_A];
	} else if (userRank == IRCUserNormalOperatorRank) {
		backgroundColor = [userInterfaceObjects userMarkBadgeBackgroundColor_O];
	} else if (userRank == IRCUserHalfOperatorRank) {
		backgroundColor = [userInterfaceObjects userMarkBadgeBackgroundColor_H];
	} else if (userRank == IRCUserVoicedRank) {
		backgroundColor = [userInterfaceObjects userMarkBadgeBackgroundColor_V];
	} else {
		if (isDrawingForMavericks) {
			if ([NSColor currentControlTint] == NSGraphiteControlTint) {
				backgroundColor = [userInterfaceObjects userMarkBadgeBackgroundColorForGraphite];
			} else {
				backgroundColor = [userInterfaceObjects userMarkBadgeBackgroundColorForAqua];
			}
		} else {
			backgroundColor = [userInterfaceObjects userMarkBadgeBackgroundColor];
		}
	}
	
	/* Maybe set a default mark. */
	if (mcstring == nil) {
		if ([TPCPreferences memberListDisplayNoModeSymbol]) {
			mcstring = @"×";
		} else {
			mcstring = NSStringEmptyPlaceholder;
		}
	}
	
	/* Frame is dropped by 1 to make room for shadow. */
	if (isDrawingForMavericks) {
		if (selected == NO) {
			/* Begin work on shadow frame. */
			NSRect shadowFrame = boxFrame;
			
			/* Change size. */
			shadowFrame.origin.y -= 1;
			
			/* The shadow frame is a round rectangle that matches the one
			 being drawn with a 1 point offset below the badge to give the
			 appearance of a drop shadow. */
			NSBezierPath *shadowPath = [NSBezierPath bezierPathWithRoundedRect:shadowFrame xRadius:4.0 yRadius:4.0];
			
			NSColor *shadowColor = [userInterfaceObjects userMarkBadgeShadowColor];
			
			[shadowColor set];
			
			[shadowPath fill];
		}
	}

	/* Draw the background of the badge. */
	NSBezierPath *badgePath = [NSBezierPath bezierPathWithRoundedRect:boxFrame xRadius:4.0 yRadius:4.0];
	
	[backgroundColor set];
	
	[badgePath fill];
	
	/* Begin building the actual mode string. */
	if ([mcstring length] > 0) {
		NSAttributedString *modeString = [self modeBadgeText:mcstring isSelected:selected];
		
		NSSize badgeTextSize = [modeString size];
		
		/* Calculate frame of text. */
		NSPoint badgeTextPoint = NSMakePoint((NSMidX(boxFrame) - (badgeTextSize.width / 2.0)),
											((NSMidY(boxFrame) - (badgeTextSize.height / 2.0))));
		
		/* Small frame corrections. */
		/* This is so ugly, I know. */
		BOOL isDrawingForRetina = [mainWindow() runningInHighResolutionMode];

		if (isDrawingForRetina)
		{
			if ([mcstring isEqualToString:@"+"] ||
				[mcstring isEqualToString:@"~"] ||
				[mcstring isEqualToString:@"×"])
			{
				badgeTextPoint.y -= -(1.0);
			}
			else if ([mcstring isEqualToString:@"^"])
			{
				badgeTextPoint.y -= 2.0;
			}
			else if ([mcstring isEqualToString:@"*"])
			{
				badgeTextPoint.y -= 2.5;
			}
			else if ([mcstring isEqualToString:@"@"] ||
					 [mcstring isEqualToString:@"!"] ||
					 [mcstring isEqualToString:@"%"] ||
					 [mcstring isEqualToString:@"&"] ||
					 [mcstring isEqualToString:@"#"] ||
					 [mcstring isEqualToString:@"?"] ||
					 [mcstring isEqualToString:@"$"])
			{
				badgeTextPoint.y -= 0.0;
			}
		}
		else // isDrawingForRetina
		{
			if ([mcstring isEqualToString:@"+"] ||
				[mcstring isEqualToString:@"~"] ||
				[mcstring isEqualToString:@"×"])
			{
				badgeTextPoint.y -= -(2.0);
			}
			else if ([mcstring isEqualToString:@"@"] ||
					 [mcstring isEqualToString:@"!"] ||
					 [mcstring isEqualToString:@"%"] ||
					 [mcstring isEqualToString:@"&"] ||
					 [mcstring isEqualToString:@"#"] ||
					 [mcstring isEqualToString:@"?"])
			{
				badgeTextPoint.y -= -(1.0);
			}
			else if ([mcstring isEqualToString:@"^"])
			{
				badgeTextPoint.y -= 0.0;
			}
			else if ([mcstring isEqualToString:@"*"])
			{
				badgeTextPoint.y -= 1.0;
			}
			else if ([mcstring isEqualToString:@"$"])
			{
				badgeTextPoint.y -= -(1.0);
			}
		}

		/* Draw mode string. */
		[modeString drawAtPoint:badgeTextPoint];
	}
	
	/* Now that we finished drawing, return the result. */
	[newImage unlockFocus];
	
	return newImage;
}

#pragma mark -
#pragma mark Expansion Frame

- (void)drawWithExpansionFrame
{
    /* Begin popover. */
	TVCMemberListUserInfoPopover *userInfoPopover = [mainWindowMemberList() memberListUserInfoPopover];

	/* What permissions does the user have? */
	IRCUser *associatedUser = [self memberPointer];

	IRCUserRank userRank = [associatedUser rank];

	NSString *permissions = nil;

	if ([associatedUser isCop]) {
		userRank = IRCUserIRCopByModeRank;
	}

	if (userRank == IRCUserIRCopByModeRank) {
		permissions = TXTLS(@"TVCMainWindow[1007]");
	} else if (userRank == IRCUserChannelOwnerRank) {
		permissions = TXTLS(@"TVCMainWindow[1006]");
	} else if (userRank == IRCUserSuperOperatorRank) {
		permissions = TXTLS(@"TVCMainWindow[1005]");
	} else if (userRank == IRCUserNormalOperatorRank) {
		permissions = TXTLS(@"TVCMainWindow[1004]");
	} else if (userRank == IRCUserHalfOperatorRank) {
		permissions = TXTLS(@"TVCMainWindow[1003]");
	} else if (userRank == IRCUserVoicedRank) {
		permissions = TXTLS(@"TVCMainWindow[1002]");
	} else {
		permissions = TXTLS(@"TVCMainWindow[1001]");
	}

    /* User info. */
	NSString *nickname = [associatedUser nickname];
	NSString *username = [associatedUser username];
	NSString *address = [associatedUser address];

	NSString *realname = [associatedUser realname];

    if (NSObjectIsEmpty(username)) {
        username = TXTLS(@"TVCMainWindow[1010]");
    }

    if (NSObjectIsEmpty(address)) {
        address = TXTLS(@"TVCMainWindow[1010]");
	}
	
	if (NSObjectIsEmpty(realname)) {
		realname = TXTLS(@"TVCMainWindow[1010]");
	}

    /* Where is our cell? */
	NSInteger rowIndex = [self rowIndex];

    NSRect cellFrame = [mainWindowMemberList() frameOfCellAtColumn:0 row:rowIndex];

    /* Pop our popover. */
	[[userInfoPopover nicknameField] setStringValue:nickname];
	[[userInfoPopover usernameField] setStringValue:username];
	
	[[userInfoPopover privilegesField] setStringValue:permissions];

	[[userInfoPopover realnameField] setStringValue:realname];

	/* Interestingly enough, some IRC networks allow formatting characters.
	 That makes absolutely no sense, but let's support it in the pop up
	 just to say that we can. */
	NSAttributedString *addressAttr = [address attributedStringWithIRCFormatting:[NSFont systemFontOfSize:12.0]
															  preferredFontColor:nil
													   honorFormattingPreference:NO];

	[[userInfoPopover addressField] setAttributedStringValue:addressAttr];
	
	/* Update away status. */
	if ([associatedUser isAway]) {
		[[userInfoPopover awayStatusField] setStringValue:TXTLS(@"TVCMainWindow[1008]")];
	} else {
		[[userInfoPopover awayStatusField] setStringValue:TXTLS(@"TVCMainWindow[1009]")];
	}

	id currentFirstResponder = [mainWindow() firstResponder];

    [userInfoPopover showRelativeToRect:cellFrame
                                 ofView:mainWindowMemberList()
                          preferredEdge:NSMaxXEdge];

	[mainWindow() makeFirstResponder:currentFirstResponder];
}

- (NSInteger)rowIndex
{
	return [mainWindowMemberList() rowForItem:[self memberPointer]];
}

- (NSDictionary *)drawingContext
{
	NSInteger rowIndex = [self rowIndex];
	
	return @{
			 @"rowIndex"			: @(rowIndex),
			 @"isInverted"			: @([TPCPreferences invertSidebarColors]),
			 @"isRetina"			: @([mainWindow() runningInHighResolutionMode]),
			 @"isActiveWindow"		: @([mainWindow() isActiveForDrawing]),
			 @"isSelected"			: @([mainWindowMemberList() isRowSelected:rowIndex]),
			 @"isGraphite"			: @([NSColor currentControlTint] == NSGraphiteControlTint)
		};
}

@end

#pragma mark -
#pragma mark Row View Cell

@implementation TVCMemberListRowCell

- (void)setSelected:(BOOL)selected
{
	[super setSelected:selected];
	
	[self postSelectionChangeNeedsDisplay];
}

- (void)postSelectionChangeNeedsDisplay
{
	if ([self isSelected])
	{
		if ([XRSystemInformation isUsingOSXYosemiteOrLater])
		{
			if ([TVCMemberListSharedUserInterface yosemiteIsUsingVibrantDarkMode]) {
				[self setSelectionHighlightStyle:NSTableViewSelectionHighlightStyleRegular];
			} else {
				[self setSelectionHighlightStyle:NSTableViewSelectionHighlightStyleSourceList];
			}
		}
		else
		{
			if ([TPCPreferences invertSidebarColors]) {
				[self setSelectionHighlightStyle:NSTableViewSelectionHighlightStyleRegular];
			} else {
				[self setSelectionHighlightStyle:NSTableViewSelectionHighlightStyleSourceList];
			}
		}
	}
	else
	{
		[self setSelectionHighlightStyle:NSTableViewSelectionHighlightStyleRegular];
	}
	
	[self setNeedsDisplayOnChild];
}

- (void)setNeedsDisplayOnChild
{
	NSArray *subviews = [self subviews];
	
	for (id subview in subviews) {
		if ([subview isKindOfClass:[TVCMemberListCell class]]) {
			[subview setNeedsDisplay:YES];
		}
	}
}

- (void)drawSelectionInRect:(NSRect)dirtyRect
{
	if ([self needsToDrawRect:dirtyRect])
	{
		id userInterfaceObjects = [mainWindowMemberList() userInterfaceObjects];
		
		if ([XRSystemInformation isUsingOSXYosemiteOrLater])
		{
			NSColor *selectionColor = nil;
			
			if ([mainWindow() isActiveForDrawing]) {
				selectionColor = [userInterfaceObjects rowSelectionColorForActiveWindow];
			} else {
				selectionColor = [userInterfaceObjects rowSelectionColorForInactiveWindow];
			}
			
			if (selectionColor) {
				NSRect selectionRect = [self bounds];
				
				[selectionColor set];
				
				NSRectFill(selectionRect);
			} else {
				[super drawSelectionInRect:dirtyRect];
			}
		}
		else
		{
			NSImage *selectionImage = nil;
			
			if ([mainWindow() isActiveForDrawing]) {
				selectionImage = [userInterfaceObjects rowSelectionImageForActiveWindow];
			} else {
				selectionImage = [userInterfaceObjects rowSelectionImageForInactiveWindow];
			}
			
			if (selectionImage) {
				NSRect selectionRect = [self bounds];
				
				[selectionImage drawInRect:selectionRect
								  fromRect:NSZeroRect
								 operation:NSCompositeSourceOver
								  fraction:1.0
							respectFlipped:YES
									 hints:nil];
			} else {
				[super drawSelectionInRect:dirtyRect];
			}
		}
	}
}

- (BOOL)isEmphasized
{
	return YES;
}

- (NSColor *)fontSmoothingBackgroundColor
{
	if ([TPCPreferences invertSidebarColors]) {
		return [NSColor grayColor];
	} else {
		return [NSColor whiteColor];
	}
}

@end
