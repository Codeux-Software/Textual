/* ********************************************************************* 
       _____        _               _    ___ ____   ____
      |_   _|___  _| |_ _   _  __ _| |  |_ _|  _ \ / ___|
       | |/ _ \ \/ / __| | | |/ _` | |   | || |_) | |
       | |  __/>  <| |_| |_| | (_| | |   | ||  _ <| |___
       |_|\___/_/\_\\__|\__,_|\__,_|_|  |___|_| \_\\____|

 Copyright (c) 2010 — 2013 Codeux Software & respective contributors.
        Please see Contributors.rtfd and Acknowledgements.rtfd

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

- (void)updateDrawing
{
	/**************************************************************/
	/* Create our new string from scratch. */
	/**************************************************************/

	/* Declare variables. */
	NSDictionary *drawContext = [self drawingContext];

	BOOL invertedColors = [drawContext boolForKey:@"isInverted"];
	BOOL isKeyWindow = [drawContext boolForKey:@"isKeyWindow"];
	BOOL isGraphite = [drawContext boolForKey:@"isGraphite"];

	NSMutableAttributedString *newStrValue = [NSMutableAttributedString mutableStringWithBase:self.memberPointer.nickname attributes:self.customTextField.attributedStringValue.attributes];

	/* Prepare the drop shadow for text. */
	NSShadow *itemShadow = [NSShadow new];

	[itemShadow setShadowOffset:NSMakeSize(0, -1)];

	if (self.rowIsSelected == NO) {
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

	/* Prepare other attributes. */
	NSRange textRange = NSMakeRange(0, newStrValue.length);

	if (self.rowIsSelected) {
		[newStrValue addAttribute:NSFontAttributeName value:self.memberList.selectedCellFont range:textRange];

		[newStrValue addAttribute:NSForegroundColorAttributeName value:self.memberList.selectedCellTextColor range:textRange];
	} else {
		[newStrValue addAttribute:NSFontAttributeName value:self.memberList.normalCellFont range:textRange];

        if (self.memberPointer.isAway) {
            [newStrValue addAttribute:NSForegroundColorAttributeName value:self.memberList.awayUserCellTextColor range:textRange];
        } else {
            [newStrValue addAttribute:NSForegroundColorAttributeName value:self.memberList.normalCellTextColor range:textRange];
        }
	}

	[newStrValue addAttribute:NSShadowAttributeName value:itemShadow range:textRange];

	/* Set the new attributed string. */
	if ([self.customTextField.attributedStringValue isEqual:newStrValue] == NO) {
		[self.customTextField setAttributedStringValue:newStrValue];
	}

	/**************************************************************/
	/* Prepare the badge image and text. */
	/**************************************************************/

	/* Setup badge image. */
	NSImage *badgeImage;

	/* See IRCUser.m for an explantion of what favorIRCop does. */
	BOOL favorIRCop = [self.memberPointer.supportInfo modeIsSupportedUserPrefix:@"y"];

	if (favorIRCop == NO) {
		favorIRCop = [TPCPreferences memberListSortFavorsServerStaff];
	}

	if (self.rowIsSelected) {
		badgeImage = [self.badgeRenderer userModeBadgeImage_Selected];
	} else if (self.memberPointer.isCop && favorIRCop) {
		badgeImage = [self.badgeRenderer userModeBadgeImage_Y];
	} else if (self.memberPointer.q) {
		badgeImage = [self.badgeRenderer userModeBadgeImage_Q];
	} else if (self.memberPointer.a) {
		badgeImage = [self.badgeRenderer userModeBadgeImage_A];
	} else if (self.memberPointer.o) {
		badgeImage = [self.badgeRenderer userModeBadgeImage_O];
	} else if (self.memberPointer.h) {
		badgeImage = [self.badgeRenderer userModeBadgeImage_H];
	} else if (self.memberPointer.v) {
		badgeImage = [self.badgeRenderer userModeBadgeImage_V];
	} else {
		badgeImage = [self.badgeRenderer userModeBadgeImage_X];
	}

	if ([badgeImage isEqual:[self.imageView image]] == NO) {
		[self.imageView setImage:badgeImage];
	}

	/* Setup badge text. */
	NSString *mcnstring = self.memberPointer.mark;

	if (NSObjectIsEmpty(mcnstring)) {
		if ([RZUserDefaults() boolForKey:@"DisplayUserListNoModeSymbol"]) {
			mcnstring = @"x";
		} else {
			mcnstring = NSStringEmptyPlaceholder;
		}
	}

	/* Pick which font size best aligns with the badge. */
	NSColor *textColor = self.memberList.userMarkBadgeNormalTextColor;

	if (self.rowIsSelected) {
		textColor = self.memberList.userMarkBadgeSelectedTextColor;
	}

	NSAttributedString *mcstring = [NSAttributedString stringWithBase:mcnstring attributes:@{
		 NSForegroundColorAttributeName		: textColor,
		 NSFontAttributeName				: self.memberList.userMarkBadgeFont
	}];

	if ([self.modeSymbolTextField.attributedStringValue isEqual:mcstring] == NO) {
		/* Set the actual mode badge text. */
		[self.modeSymbolTextField setAttributedStringValue:mcstring];

		/* Change frame. */

		NSRect symbolTextFieldRectOld = [self.modeSymbolTextField frame];
		NSRect symbolTextFieldRectNew = symbolTextFieldRectOld;

		if ([mcnstring isEqualToString:@"@"]) {
			symbolTextFieldRectNew.origin = [self.memberList userMarkBadgeTextOrigin_AtSign];
		} else if ([mcnstring isEqualToString:@"&"]) {
			symbolTextFieldRectNew.origin = [self.memberList userMarkBadgeTextOrigin_AndSign];
		} else if ([mcnstring isEqualToString:@"%"]) {
			symbolTextFieldRectNew.origin = [self.memberList userMarkBadgeTextOrigin_PercentSign];
		} else {
			symbolTextFieldRectNew.origin = [self.memberList userMarkBadgeTextOrigin_Normal];
		}

		if (NSEqualRects(symbolTextFieldRectOld, symbolTextFieldRectNew) == NO) {
			[self.modeSymbolTextField setFrame:symbolTextFieldRectNew];
		}
	}
}

#pragma mark -
#pragma mark Selection Drawing

- (void)disableSelectionBackgroundImage
{
	[self.backgroundImageCell setHidden:YES];
}

- (void)enableSelectionBackgroundImage
{
	/****************************************************************/
	/* Define context variables. */
	/****************************************************************/

	NSDictionary *drawContext = [self drawingContext];

	BOOL invertedColors = [drawContext boolForKey:@"isInverted"];
	BOOL isKeyWindow = [drawContext boolForKey:@"isKeyWindow"];
	BOOL isGraphite = [drawContext boolForKey:@"isGraphite"];

	/****************************************************************/
	/* Find the name of the image to be drawn. */
	/****************************************************************/

	NSString *backgroundImage = @"ChannelCellSelection";

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

	NSImage *origBackgroundImage = [NSImage imageNamed:backgroundImage];

	/****************************************************************/
	/* Put the background to screen. */
	/****************************************************************/

	/* When our image view is visible for the selected item, right clicking on
	 it will not do anything unless we define a menu to use with our view. Below,
	 we define the menu that matches the selection. */
	NSMenu *menu = self.masterController.userControlMenu;

	/* Setting the menu on our imageView, not only backgroundImageCell, makes it
	 so right clicking on the channel status produces the same menu that is given
	 clicking anywhere else in the server list. */
	[self.imageView setMenu:menu];

	/* Populate the background image cell. */
	[self.backgroundImageCell setImage:origBackgroundImage];
	[self.backgroundImageCell setMenu:menu];
	[self.backgroundImageCell setHidden:NO];

	/* Force redraw. */
	[self updateDrawing];
}

#pragma mark -
#pragma mark Common Pointers

- (TVCMemberList *)memberList
{
	return self.masterController.memberList;
}

- (TVCMemberListCellBadge *)badgeRenderer
{
	return self.masterController.memberList.badgeRenderer;
}

#pragma mark -
#pragma mark Drawing Context Information

- (NSInteger)rowIndex
{
	return [self.memberList rowForItem:self.memberPointer];
}

- (NSDictionary *)drawingContext
{
	NSInteger rowIndex = [self rowIndex];

	return @{
		@"rowIndex"		: @(rowIndex),
		@"isInverted"	: @([TPCPreferences invertSidebarColors]),
		@"isRetina"		: @([TPCPreferences runningInHighResolutionMode]),
		@"isGraphite"	: @([NSColor currentControlTint] == NSGraphiteControlTint),
		@"isKeyWindow"	: @(self.masterController.mainWindowIsActive)
	};
}

@end

#pragma mark -
#pragma mark Row View Cell

@implementation TVCMemberListRowCell

- (void)drawDraggingDestinationFeedbackInRect:(NSRect)dirtyRect
{
	/* Ignore this. */
}

- (void)drawSelectionInRect:(NSRect)dirtyRect
{
	/* Ignore this. */
}

- (void)drawRect:(NSRect)dirtyRect
{
	/* Ignore this. */
}

@end
