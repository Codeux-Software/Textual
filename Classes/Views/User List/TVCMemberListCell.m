/* ********************************************************************* 
       _____        _               _    ___ ____   ____
      |_   _|___  _| |_ _   _  __ _| |  |_ _|  _ \ / ___|
       | |/ _ \ \/ / __| | | |/ _` | |   | || |_) | |
       | |  __/>  <| |_| |_| | (_| | |   | ||  _ <| |___
       |_|\___/_/\_\\__|\__,_|\__,_|_|  |___|_| \_\\____|

 Copyright (c) 2010 — 2014 Codeux Software & respective contributors.
     Please see Acknowledgements.pdf for additional information.

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
#pragma mark Drawing

- (void)updateDrawing
{
	if ([CSFWSystemInformation featureAvailableToOSXYosemite]) {
		[self updateDrawingForYosemite:[mainWindowMemberList() userInterfaceObjects]];
	} else {
		;
	}
}

- (void)updateDrawingForYosemite:(id)interfaceObject
{
	/* Define context. */
	IRCUser *associatedUser = [self memberPointer];
	
	/* Maybe update text field value. */
	NSTextField *textField = [self textField];
	
	NSString *stringValue = [textField stringValue];
	
	NSString *labelValue = [associatedUser nickname];
	
	if ([stringValue isEqualTo:labelValue] == NO) {
		[textField setStringValue:labelValue];
	} else {
		[textField setNeedsDisplay:YES];
	}
}

#pragma mark -
#pragma mark Expansion Frame

- (void)drawWithExpansionFrame
{
    /* Begin popover. */
	TVCMemberListUserInfoPopover *userInfoPopover = [mainWindowMemberList() memberListUserInfoPopover];

	/* What permissions does the user have? */
	IRCUser *associatedUser = [self memberPointer];
	
    NSString *permissions = @"BasicLanguage[1206]";

	if ([associatedUser q]) {
        permissions = @"BasicLanguage[1211]";
    } else if ([associatedUser a]) {
        permissions = @"BasicLanguage[1210]";
    } else if ([associatedUser o]) {
        permissions = @"BasicLanguage[1209]";
    } else if ([associatedUser h]) {
        permissions = @"BasicLanguage[1208]";
    } else if ([associatedUser v]) {
        permissions = @"BasicLanguage[1207]";
    }

    permissions = TXTLS(permissions);

    if ([associatedUser isCop]) {
        permissions = [permissions stringByAppendingString:BLS(1212)];
    }

    /* User info. */
	NSString *nickname = [associatedUser nickname];
	NSString *username = [associatedUser username];
	NSString *address = [associatedUser address];

    if (NSObjectIsEmpty(username)) {
        username = BLS(1215);
    }

    if (NSObjectIsEmpty(address)) {
        address = BLS(1215);
    }

    /* Where is our cell? */
	NSInteger rowIndex = [self rowIndex];

    NSRect cellFrame = [mainWindowMemberList() frameOfCellAtColumn:0 row:rowIndex];

    /* Pop our popover. */
	[[userInfoPopover nicknameField] setStringValue:nickname];
	[[userInfoPopover usernameField] setStringValue:username];
	
	[[userInfoPopover privilegesField] setStringValue:permissions];

	/* Interestingly enough, some IRC networks allow formatting characters.
	 That makes absolutely no sense, but let's support it in the pop up
	 just to say that we can. */
	NSAttributedString *addressAttr = [address attributedStringWithIRCFormatting:TXPreferredGlobalTableViewFont
													   honorFormattingPreference:NO];

	[[userInfoPopover addressField] setAttributedStringValue:addressAttr];
	
	/* Update away status. */
	if ([associatedUser isAway]) {
		[[userInfoPopover awayStatusField] setStringValue:BLS(1213)];
	} else {
		[[userInfoPopover awayStatusField] setStringValue:BLS(1214)];
	}

    [userInfoPopover showRelativeToRect:cellFrame
                                 ofView:mainWindowMemberList()
                          preferredEdge:NSMaxXEdge];
	
	[mainWindowTextField() focus]; // Add focus back to text field.
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
			 @"isInactiveWindow"	: @([mainWindow() isInactive] == NO),
			 @"isKeyWindow"			: @([mainWindow() isKeyWindow]),
			 @"isSelected"			: @([mainWindowMemberList() isRowSelected:rowIndex]),
			 @"isGraphite"			: @([NSColor currentControlTint] == NSGraphiteControlTint)
		};
}

@end

#pragma mark -
#pragma mark Row View Cell

@implementation TVCMemberListRowCell

- (BOOL)isEmphasized
{
	return YES;
}

@end

@implementation TVCMemberLisCellTextFieldInterior

- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView
{
	TVCMemberListCell *parentCell = [self parentCell];
	
	NSDictionary *drawingContext = [parentCell drawingContext];
	
	[self drawModeBadge:[drawingContext boolForKey:@"isSelected"]];
	
	id userInterfaceObjects = [mainWindowMemberList() userInterfaceObjects];
	
	cellFrame.origin.x = [userInterfaceObjects textCellLeftMargin];
	cellFrame.origin.y = [userInterfaceObjects textCellBottomMargin];
	
	[super drawWithFrame:cellFrame inView:controlView];
}

#pragma mark -
#pragma mark Badge Drawing

- (NSAttributedString *)modeBadgeText:(NSString *)badgeString isSelected:(BOOL)selected
{
	id userInterfaceObjects = [mainWindowMemberList() userInterfaceObjects];
	
	NSColor *textColor = nil;
	
	if (selected) {
		textColor = [userInterfaceObjects userMarkBadgeSelectedTextColor];
	} else {
		textColor = [userInterfaceObjects userMarkBadgeNormalTextColor];
	}
	
	NSDictionary *attributes = @{NSForegroundColorAttributeName : textColor, NSFontAttributeName : [userInterfaceObjects userMarkBadgeFont]};
	
	NSAttributedString *mcstring = [NSAttributedString stringWithBase:badgeString attributes:attributes];
	
	return mcstring;
}

- (void)drawModeBadge:(BOOL)selected
{
	/* Define context information. */
	id userInterfaceObjects = [mainWindowMemberList() userInterfaceObjects];
	
	TVCMemberListCell *parentCell = [self parentCell];
	
	IRCUser *assosicatedUser = [parentCell memberPointer];
	
	NSString *mcstring = [assosicatedUser mark];

	/* Build the drawing frame. */
	NSRect boxFrame = NSMakeRect([userInterfaceObjects userMarkBadgeLeftMargin],
								 [userInterfaceObjects userMarkBadgeBottomMargin],
								 [userInterfaceObjects userMarkBadgeWidth],
								 [userInterfaceObjects userMarkBadgeHeight]);

	/* Decide the background color. */
	NSColor *backgroundColor;
	
	BOOL favorIRCop = ([assosicatedUser InspIRCd_y_lower] ||
					   [assosicatedUser InspIRCd_y_upper]);
	
	if (favorIRCop == NO) {
		favorIRCop = [TPCPreferences memberListSortFavorsServerStaff];
	}
	
	if (selected) {
		backgroundColor = [userInterfaceObjects userMarkBadgeSelectedBackgroundColor];
	} else if ([assosicatedUser isCop] && favorIRCop) {
		backgroundColor = [userInterfaceObjects userMarkBadgeBackgroundColor_Y];
	} else if ([assosicatedUser q]) {
		backgroundColor = [userInterfaceObjects userMarkBadgeBackgroundColor_Q];
	} else if ([assosicatedUser a]) {
		backgroundColor = [userInterfaceObjects userMarkBadgeBackgroundColor_A];
	} else if ([assosicatedUser o]) {
		backgroundColor = [userInterfaceObjects userMarkBadgeBackgroundColor_O];
	} else if ([assosicatedUser h]) {
		backgroundColor = [userInterfaceObjects userMarkBadgeBackgroundColor_H];
	} else if ([assosicatedUser v]) {
		backgroundColor = [userInterfaceObjects userMarkBadgeBackgroundColor_V];
	} else {
		backgroundColor = [userInterfaceObjects userMarkBadgeBackgroundColor];
	}
	
	/* Maybe set a default mark. */
	if (mcstring == nil) {
		if ([RZUserDefaults() boolForKey:@"DisplayUserListNoModeSymbol"]) {
			mcstring = @"x";
		} else {
			mcstring = NSStringEmptyPlaceholder;
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
		if ([mcstring isEqualToString:@"+"] ||
			[mcstring isEqualToString:@"~"] ||
			[mcstring isEqualToString:@"x"])
		{
			badgeTextPoint.y -= 1.5;
		}
		else if ([mcstring isEqualToString:@"@"] ||
				 [mcstring isEqualToString:@"!"] ||
				 [mcstring isEqualToString:@"%"] ||
				 [mcstring isEqualToString:@"&"] ||
				 [mcstring isEqualToString:@"#"] ||
				 [mcstring isEqualToString:@"?"])
		{
			badgeTextPoint.y -= 1.0;
		}
		else if ([mcstring isEqualToString:@"^"])
		{
			badgeTextPoint.y += 1;
		}
		else if ([mcstring isEqualToString:@"*"])
		{
			badgeTextPoint.y += 2;
		}
		else if ([mcstring isEqualToString:@"$"])
		{
			badgeTextPoint.y -= 0.5;
		}
		
		if ([mainWindow() runningInHighResolutionMode]) {
			badgeTextPoint.y -= 1;
		}
		
		/* Draw mode string. */
		[modeString drawAtPoint:badgeTextPoint];
	}
}

#pragma mark -
#pragma mark Interior Drawing

- (void)drawInteriorWithFrame:(NSRect)cellFrame inView:(NSView *)controlView
{
	if ([CSFWSystemInformation featureAvailableToOSXYosemite]) {
		[self drawInteriorWithFrameForYosemite:cellFrame withUserInterfaceObject:[mainWindowMemberList() userInterfaceObjects]];
	} else {
		;
	}
}

- (void)drawInteriorWithFrameForYosemite:(NSRect)cellFrame withUserInterfaceObject:(id)interfaceObject
{
	/* Gather basic context information. */
	TVCMemberListCell *parentCell = [self parentCell];
	
	NSDictionary *drawingContext = [parentCell drawingContext];
	
	BOOL isWindowInactive = [drawingContext boolForKey:@"isInactiveWindow"];
	BOOL isKeyWindow = [drawingContext boolForKey:@"isKeyWindow"];
	BOOL isSelected = [drawingContext boolForKey:@"isSelected"];
	
	IRCUser *assosicatedUser = [parentCell memberPointer];
	
	/* Update attributed string. */
	NSAttributedString *stringValue = [self attributedStringValue];
	
	NSMutableAttributedString *mutableStringValue = [stringValue mutableCopy];
	
	NSRange stringLengthRange = NSMakeRange(0, [mutableStringValue length]);
	
	[mutableStringValue beginEditing];
	
	if (isSelected == NO) {
		if ([assosicatedUser isAway] == NO) {
			[mutableStringValue addAttribute:NSForegroundColorAttributeName value:[interfaceObject normalCellTextColor] range:stringLengthRange];
		} else {
			[mutableStringValue addAttribute:NSForegroundColorAttributeName value:[interfaceObject awayUserCellTextColor] range:stringLengthRange];
		}
	} else {
		if (isKeyWindow || isWindowInactive) {
			[mutableStringValue addAttribute:NSForegroundColorAttributeName value:[interfaceObject selectedCellTextColorForActiveWindow] range:stringLengthRange];
		} else {
			[mutableStringValue addAttribute:NSForegroundColorAttributeName value:[interfaceObject selectedCellTextColorForInactiveWindow] range:stringLengthRange];
		}
	}
	
	[mutableStringValue endEditing];
	
	/* Draw new attributed string. */
	[mutableStringValue drawInRect:cellFrame];
}

@end
