/* *********************************************************************
 *                  _____         _               _
 *                 |_   _|____  _| |_ _   _  __ _| |
 *                   | |/ _ \ \/ / __| | | |/ _` | |
 *                   | |  __/>  <| |_| |_| | (_| | |
 *                   |_|\___/_/\_\\__|\__,_|\__,_|_|
 *
 * Copyright (c) 2010 - 2015 Codeux Software, LLC & respective contributors.
 *       Please see Acknowledgements.pdf for additional information.

 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions
 are met:

    * Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the
      documentation and/or other materials provided with the distribution.
    *  *  * Neither the name of Textual, "Codeux Software, LLC", nor the
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

#import "NSStringHelper.h"
#import "NSTableVIewHelperPrivate.h"
#import "NSViewHelperPrivate.h"
#import "TLOLanguagePreferences.h"
#import "TPCPreferencesLocal.h"
#import "IRCChannelUser.h"
#import "IRCUser.h"
#import "TVCMainWindow.h"
#import "TVCMemberListPrivate.h"
#import "TVCMemberListSharedUserInterfacePrivate.h"
#import "TVCMemberListUserInfoPopoverPrivate.h"
#import "TVCMemberListCellPrivate.h"

NS_ASSUME_NONNULL_BEGIN

@interface TVCMemberListRowCell ()
@property (nonatomic, weak) TVCMemberListCell *childCell;
@end

@interface TVCMemberListCell ()
@property (nonatomic, weak) IBOutlet NSTextField *cellTextField;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *textFieldTopConstraint;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *userMarkBadgeTopConstraint;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *userMarkBadgeWidthConstraint;
@property (readonly, copy) NSDictionary<NSString *, id> *drawingContext;
@property (readonly) TVCMemberList *memberList;
@property (readonly) TVCMemberListRowCell *rowCell;
@property (readonly) IRCChannelUser *cellItem;
@end

@implementation TVCMemberListCell

#pragma mark -
#pragma mark Drawing
- (void)viewDidMoveToWindow
{
	[super viewDidMoveToWindow];

	[self tx_updateConstraints];
}

- (void)tx_updateConstraints
{
	id interfaceObjects = self.memberList.userInterfaceObjects;

	if (TEXTUAL_RUNNING_ON(10.10, Yosemite)) {
		[self updateConstraintsForYosemite:interfaceObjects];
	}
}

- (void)updateConstraintsForYosemite:(TVCMemberListYosemiteUserInterface *)interfaceObjects
{
	self.textFieldTopConstraint.constant = [interfaceObjects cellTextTopOffset];

	self.userMarkBadgeTopConstraint.constant = [interfaceObjects userMarkBadgeTopOffset];

	self.userMarkBadgeWidthConstraint.constant = [interfaceObjects userMarkBadgeWidth];
}

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
	id interfaceObjects = self.memberList.userInterfaceObjects;

	[self updateDrawing:interfaceObjects];
}

- (void)updateDrawing:(id)interfaceObjects
{
	IRCChannelUser *cellItem = self.cellItem;

	NSString *stringValueNew = cellItem.user.nickname;

	NSTextField *textField = self.cellTextField;

	NSString *stringValueOld = textField.stringValue;

	if ([stringValueOld isEqualTo:stringValueNew] == NO) {
		textField.stringValue = stringValueNew;
	}

	NSDictionary *drawingContext = self.drawingContext;

	BOOL isSelected = [drawingContext boolForKey:@"isSelected"];

	if (TEXTUAL_RUNNING_ON(10.10, Yosemite)) {
		NSAttributedString *newValue = [self attributedTextFieldValueForYosemite:interfaceObjects inContext:drawingContext];

		textField.attributedStringValue = newValue;
	} else {
		NSAttributedString *newValue = [self attributedTextFieldValueForMavericks:interfaceObjects inContext:drawingContext];

		textField.attributedStringValue = newValue;
	}

	[self updateUserMarkBadge:isSelected];

	[self populateAccessibilityDescriptions];
}

- (void)populateAccessibilityDescriptions
{
	IRCChannelUser *cellItem = self.cellItem;

	[XRAccessibility setAccessibilityValueDescription:TXTLS(@"Accessibility[1000]", cellItem.user.nickname) forObject:self.cellTextField.cell];
}

#pragma mark -
#pragma mark Text Field Attributes

- (NSAttributedString *)attributedTextFieldValueForMavericks:(id)interfaceObjects inContext:(NSDictionary<NSString *, id> *)drawingContext
{
	BOOL isActiveWindow = [drawingContext boolForKey:@"isActiveWindow"];
	BOOL isGraphite = [drawingContext boolForKey:@"isGraphite"];
	BOOL isInverted = [drawingContext boolForKey:@"isInverted"];
	BOOL isSelected = [drawingContext boolForKey:@"isSelected"];

	IRCChannelUser *cellItem = self.cellItem;

	NSTextField *textField = self.cellTextField;

	NSAttributedString *stringValue = textField.attributedStringValue;

	NSRange stringValueRange = stringValue.range;

	NSMutableAttributedString *mutableStringValue = [stringValue mutableCopy];

	[mutableStringValue beginEditing];

	NSShadow *itemShadow = [NSShadow new];

	itemShadow.shadowOffset = NSMakeSize(0, (-1.0));

	if (isSelected == NO) {
		itemShadow.shadowColor = [interfaceObjects normalCellTextShadowColor];
	} else {
		if (isInverted) {
			itemShadow.shadowBlurRadius = 1.0;
		} else {
			itemShadow.shadowBlurRadius = 2.0;
		}

		if (isActiveWindow) {
			if (isGraphite && isInverted == NO) {
				itemShadow.shadowColor = [interfaceObjects graphiteSelectedCellTextShadowColorForActiveWindow];
			} else {
				itemShadow.shadowColor = [interfaceObjects normalSelectedCellTextShadowColorForActiveWindow];
			}
		} else {
			itemShadow.shadowColor = [interfaceObjects normalSelectedCellTextShadowColorForInactiveWindow];
		}
	}

	if (isSelected) {
		[mutableStringValue addAttribute:NSFontAttributeName value:[interfaceObjects selectedCellTextFont] range:stringValueRange];

		[mutableStringValue addAttribute:NSForegroundColorAttributeName value:[interfaceObjects selectedCellTextColor] range:stringValueRange];
	} else {
		[mutableStringValue addAttribute:NSFontAttributeName value:[interfaceObjects normalCellTextFont] range:stringValueRange];

		if (cellItem.user.isAway) {
			[mutableStringValue addAttribute:NSForegroundColorAttributeName value:[interfaceObjects awayUserCellTextColor] range:stringValueRange];
		} else {
			[mutableStringValue addAttribute:NSForegroundColorAttributeName value:[interfaceObjects normalCellTextColor] range:stringValueRange];
		}
	}

	[mutableStringValue addAttribute:NSShadowAttributeName value:itemShadow range:stringValueRange];

	[mutableStringValue endEditing];

	return mutableStringValue;
}

- (NSAttributedString *)attributedTextFieldValueForYosemite:(id)interfaceObjects inContext:(NSDictionary<NSString *, id> *)drawingContext
{
	BOOL isActiveWindow = [drawingContext boolForKey:@"isActiveWindow"];
	BOOL isSelected = [drawingContext boolForKey:@"isSelected"];

	IRCChannelUser *cellItem = self.cellItem;

	NSTextField *textField = self.cellTextField;

	NSAttributedString *stringValue = textField.attributedStringValue;

	NSRange stringValueRange = stringValue.range;

	NSMutableAttributedString *mutableStringValue = [stringValue mutableCopy];

	[mutableStringValue beginEditing];

	if (isSelected == NO) {
		if (cellItem.user.isAway == NO) {
			if (isActiveWindow == NO) {
				[mutableStringValue addAttribute:NSForegroundColorAttributeName value:[interfaceObjects normalCellTextColorForInactiveWindow] range:stringValueRange];
			} else {
				[mutableStringValue addAttribute:NSForegroundColorAttributeName value:[interfaceObjects normalCellTextColorForActiveWindow] range:stringValueRange];
			}
		} else {
			if (isActiveWindow == NO) {
				[mutableStringValue addAttribute:NSForegroundColorAttributeName value:[interfaceObjects awayUserCellTextColorForInactiveWindow] range:stringValueRange];
			} else {
				[mutableStringValue addAttribute:NSForegroundColorAttributeName value:[interfaceObjects awayUserCellTextColorForActiveWindow] range:stringValueRange];
			}
		}
	} else {
		if (isActiveWindow == NO) {
			[mutableStringValue addAttribute:NSForegroundColorAttributeName value:[interfaceObjects selectedCellTextColorForInactiveWindow] range:stringValueRange];
		} else {
			[mutableStringValue addAttribute:NSForegroundColorAttributeName value:[interfaceObjects selectedCellTextColorForActiveWindow] range:stringValueRange];
		}
	}

	[mutableStringValue addAttribute:NSFontAttributeName value:[interfaceObjects cellTextFont] range:stringValueRange];

	[mutableStringValue endEditing];

	return mutableStringValue;
}

#pragma mark -
#pragma mark Badge Drawing

- (NSAttributedString *)modeBadgeText:(NSString *)modeSymbol isSelected:(BOOL)isSelected
{
	TVCMainWindow *mainWindow = self.mainWindow;

	id interfaceObjects = mainWindow.memberList.userInterfaceObjects;

	NSColor *textColor = nil;

	NSFont *textFont = nil;

	if (isSelected) {
		textColor = [interfaceObjects userMarkBadgeSelectedTextColor];

		textFont = [interfaceObjects userMarkBadgeFontSelected];
	} else {
		textColor = [interfaceObjects userMarkBadgeNormalTextColor];

		textFont = [interfaceObjects userMarkBadgeFont];
	}

	NSDictionary *attributes = @{NSForegroundColorAttributeName : textColor, NSFontAttributeName : textFont};

	NSAttributedString *stringToDraw = [NSAttributedString attributedStringWithString:modeSymbol attributes:attributes];

	return stringToDraw;
}

- (void)updateUserMarkBadge:(BOOL)isSelected
{
	id interfaceObjects = self.memberList.userInterfaceObjects;

	IRCChannelUser *cellItem = self.cellItem;

	NSString *modeSymbol = cellItem.mark;

	IRCUserRank userRankToDraw = IRCUserNoRank;

	if ([TPCPreferences memberListSortFavorsServerStaff]) {
		if (cellItem.user.isIRCop) {
			userRankToDraw = IRCUserIRCopByModeRank;
		}
	}

	if (userRankToDraw == IRCUserNoRank) {
		userRankToDraw = cellItem.rank;
	}

	NSImage *cachedImage = nil;

	if (isSelected == NO) {
		cachedImage = [interfaceObjects cachedUserMarkBadgeForSymbol:modeSymbol rank:userRankToDraw];
	}

	if (cachedImage == nil) {
		cachedImage = [self drawModeBadgeForRank:userRankToDraw isSelected:isSelected];

		if (isSelected == NO) {
			[interfaceObjects cacheUserMarkBadge:cachedImage forSymbol:modeSymbol rank:userRankToDraw];
		}
	}

	self.imageView.image = cachedImage;
}

- (NSImage *)drawModeBadgeForRank:(IRCUserRank)userRank isSelected:(BOOL)isSelected
{
	TVCMainWindow *mainWindow = self.mainWindow;

	id interfaceObjects = mainWindow.memberList.userInterfaceObjects;

	BOOL isDrawingOnMavericks = (TEXTUAL_RUNNING_ON(10.10, Yosemite) == NO);

	NSString *stringToDraw = self.cellItem.mark;

	/* Create image that we will draw into. If we are drawing for Mavericks,
	 then the frame of our image is one pixel greater because we draw a shadow. */
	NSImage *badgeImage = nil;

	NSRect badgeFrame = NSZeroRect;

	if (isDrawingOnMavericks) {
		badgeFrame = NSMakeRect(0.0, 1.0,
				[interfaceObjects userMarkBadgeWidth],
				[interfaceObjects userMarkBadgeHeight]);

		badgeImage = [NSImage newImageWithSize:NSMakeSize(NSWidth(badgeFrame), (NSHeight(badgeFrame) + 1.0))];
	} else {
		badgeFrame = NSMakeRect(0.0, 0.0,
				[interfaceObjects userMarkBadgeWidth],
				[interfaceObjects userMarkBadgeHeight]);

		badgeImage = [NSImage newImageWithSize:NSMakeSize(NSWidth(badgeFrame),  NSHeight(badgeFrame))];
	}

	[badgeImage lockFocus];

	/* Decide the background color */
	NSColor *backgroundColor = nil;

	if (isSelected) {
		backgroundColor = [interfaceObjects userMarkBadgeSelectedBackgroundColor];
	} else if (userRank == IRCUserIRCopByModeRank) {
		backgroundColor = [interfaceObjects userMarkBadgeBackgroundColor_Y];
	} else if (userRank == IRCUserChannelOwnerRank) {
		backgroundColor = [interfaceObjects userMarkBadgeBackgroundColor_Q];
	} else if (userRank == IRCUserSuperOperatorRank) {
		backgroundColor = [interfaceObjects userMarkBadgeBackgroundColor_A];
	} else if (userRank == IRCUserNormalOperatorRank) {
		backgroundColor = [interfaceObjects userMarkBadgeBackgroundColor_O];
	} else if (userRank == IRCUserHalfOperatorRank) {
		backgroundColor = [interfaceObjects userMarkBadgeBackgroundColor_H];
	} else if (userRank == IRCUserVoicedRank) {
		backgroundColor = [interfaceObjects userMarkBadgeBackgroundColor_V];
	} else {
		if (isDrawingOnMavericks) {
			if ([NSColor currentControlTint] == NSGraphiteControlTint) {
				backgroundColor = [interfaceObjects userMarkBadgeBackgroundColorForGraphite];
			} else {
				backgroundColor = [interfaceObjects userMarkBadgeBackgroundColorForAqua];
			}
		} else {
			backgroundColor = [interfaceObjects userMarkBadgeBackgroundColor];
		}
	}

	/* Set "x" if the user has no modes set */
	if ([TPCPreferences memberListDisplayNoModeSymbol]) {
		if (stringToDraw.length == 0) {
			stringToDraw = @"×";
		}
	}

	/* Frame is dropped by 1 to make room for shadow */
	if (isDrawingOnMavericks) {
		if (isSelected == NO) {
			NSRect shadowFrame = badgeFrame;

			shadowFrame.origin.y -= 1;

			NSBezierPath *shadowPath = [NSBezierPath bezierPathWithRoundedRect:shadowFrame xRadius:4.0 yRadius:4.0];

			NSColor *shadowColor = [interfaceObjects userMarkBadgeShadowColor];

			[shadowColor set];

			[shadowPath fill];
		}
	}

	/* Draw the background of the badge */
	NSBezierPath *badgePath = [NSBezierPath bezierPathWithRoundedRect:badgeFrame xRadius:4.0 yRadius:4.0];

	[backgroundColor set];

	[badgePath fill];

	/* Begin building the actual mode string */
	if (stringToDraw.length > 0) {
		NSAttributedString *badgeText = [self modeBadgeText:stringToDraw isSelected:isSelected];

		NSSize badgeTextSize = badgeText.size;

		NSPoint badgeTextPoint = NSMakePoint((NSMidX(badgeFrame) - (badgeTextSize.width / 2.0)),
											 (NSMidY(badgeFrame) - (badgeTextSize.height / 2.0)));

		if (mainWindow.runningInHighResolutionMode)
		{
			if ([stringToDraw isEqualToString:@"+"] ||
				[stringToDraw isEqualToString:@"~"] ||
				[stringToDraw isEqualToString:@"×"])
			{
				badgeTextPoint.y -= (-1.0);
			}
			else if ([stringToDraw isEqualToString:@"^"])
			{
				badgeTextPoint.y -= 2.0;
			}
			else if ([stringToDraw isEqualToString:@"*"])
			{
				badgeTextPoint.y -= 2.5;
			}
/*			else if ([stringToDraw isEqualToString:@"@"] ||
					 [stringToDraw isEqualToString:@"!"] ||
					 [stringToDraw isEqualToString:@"%"] ||
					 [stringToDraw isEqualToString:@"&"] ||
					 [stringToDraw isEqualToString:@"#"] ||
					 [stringToDraw isEqualToString:@"?"] ||
					 [stringToDraw isEqualToString:@"$"])
			{
				badgeTextPoint.y -= 0.0;
			} */
		}
		else // isDrawingForRetina
		{
			if ([stringToDraw isEqualToString:@"+"] ||
				[stringToDraw isEqualToString:@"~"] ||
				[stringToDraw isEqualToString:@"×"])
			{
				badgeTextPoint.y -= (-2.0);
			}
			else if ([stringToDraw isEqualToString:@"@"] ||
					 [stringToDraw isEqualToString:@"!"] ||
					 [stringToDraw isEqualToString:@"%"] ||
					 [stringToDraw isEqualToString:@"&"] ||
					 [stringToDraw isEqualToString:@"#"] ||
					 [stringToDraw isEqualToString:@"?"])
			{
				badgeTextPoint.y -= (-1.0);
			}
/*			else if ([stringToDraw isEqualToString:@"^"])
			{
				badgeTextPoint.y -= 0.0;
			} */
			else if ([stringToDraw isEqualToString:@"*"])
			{
				badgeTextPoint.y -= 1.0;
			}
			else if ([stringToDraw isEqualToString:@"$"])
			{
				badgeTextPoint.y -= (-1.0);
			}
		}

		[badgeText drawAtPoint:badgeTextPoint];
	}

	[badgeImage unlockFocus];

	return badgeImage;
}

#pragma mark -
#pragma mark Expansion Frame

- (void)drawWithExpansionFrame
{
	TVCMainWindow *mainWindow = self.mainWindow;

	TVCMemberList *memberList = mainWindow.memberList;

	TVCMemberListUserInfoPopover *userInfoPopover = memberList.memberListUserInfoPopover;

	IRCChannelUser *cellItem = self.cellItem;

	/* =============================================== */

	userInfoPopover.nicknameField.stringValue = cellItem.user.nickname;

	/* =============================================== */

	NSString *hostmaskUsername = cellItem.user.username;

	if (hostmaskUsername.length == 0) {
		hostmaskUsername = TXTLS(@"TVCMainWindow[1010]");
	}

	userInfoPopover.usernameField.stringValue = hostmaskUsername;

	/* =============================================== */

	BOOL stripIRCFormatting = [TPCPreferences removeAllFormatting];

	NSString *hostmaskAddress = cellItem.user.address;

	if (hostmaskAddress.length == 0) {
		hostmaskAddress = TXTLS(@"TVCMainWindow[1010]");
	}

	if (stripIRCFormatting) {
		userInfoPopover.addressField.stringValue = hostmaskAddress;
	} else {
		NSAttributedString *hostmaskAddressFormatted =
		[hostmaskAddress attributedStringWithIRCFormatting:[NSFont systemFontOfSize:12.0]
										preferredFontColor:nil
								 honorFormattingPreference:NO];

		userInfoPopover.addressField.attributedStringValue = hostmaskAddressFormatted;
	}

	/* =============================================== */

	NSString *realName = cellItem.user.realName;

	if (realName.length == 0) {
		realName = TXTLS(@"TVCMainWindow[1010]");
	}

	if (stripIRCFormatting) {
		userInfoPopover.realNameField.stringValue = realName;
	} else {
		NSAttributedString *realNameFormatted =
		[realName attributedStringWithIRCFormatting:[NSFont systemFontOfSize:12.0]
								 preferredFontColor:nil
						  honorFormattingPreference:NO];

		userInfoPopover.realNameField.attributedStringValue = realNameFormatted;
	}

	/* =============================================== */

	if (cellItem.user.isAway) {
		userInfoPopover.awayStatusField.stringValue = TXTLS(@"TVCMainWindow[1008]");
	} else {
		userInfoPopover.awayStatusField.stringValue = TXTLS(@"TVCMainWindow[1009]");
	}

	/* =============================================== */

	IRCUserRank userRank = cellItem.rank;

	if (cellItem.user.isIRCop) {
		userRank = IRCUserIRCopByModeRank;
	}

	NSString *userPrivileges = nil;

	if (userRank == IRCUserIRCopByModeRank) {
		userPrivileges = TXTLS(@"TVCMainWindow[1007]");
	} else if (userRank == IRCUserChannelOwnerRank) {
		userPrivileges = TXTLS(@"TVCMainWindow[1006]");
	} else if (userRank == IRCUserSuperOperatorRank) {
		userPrivileges = TXTLS(@"TVCMainWindow[1005]");
	} else if (userRank == IRCUserNormalOperatorRank) {
		userPrivileges = TXTLS(@"TVCMainWindow[1004]");
	} else if (userRank == IRCUserHalfOperatorRank) {
		userPrivileges = TXTLS(@"TVCMainWindow[1003]");
	} else if (userRank == IRCUserVoicedRank) {
		userPrivileges = TXTLS(@"TVCMainWindow[1002]");
	} else {
		userPrivileges = TXTLS(@"TVCMainWindow[1001]");
	}

	userInfoPopover.privilegesField.stringValue = userPrivileges;

	/* =============================================== */

	NSRect cellFrame = [memberList frameOfCellAtColumn:0 row:self.rowIndex];

	/* Presenting the popover will steal focus. To workaround this,
	 we record the active first responder then set it back. */
	id activeFirstResponder = mainWindow.firstResponder;

	[userInfoPopover showRelativeToRect:cellFrame
								 ofView:self.memberList
						  preferredEdge:NSMaxXEdge];

	[mainWindow makeFirstResponder:activeFirstResponder];
}

- (IRCChannelUser *)cellItem
{
	return self.objectValue;
}

- (TVCMemberList *)memberList
{
	return self.mainWindow.memberList;
}

- (NSInteger)rowIndex
{
	return [self.memberList rowForItem:self.cellItem];
}

- (NSDictionary<NSString *, id> *)drawingContext
{
	TVCMainWindow *mainWindow = self.mainWindow;

	TVCMemberList *memberList = mainWindow.memberList;

	NSInteger rowIndex = self.rowIndex;

	return @{
		 @"isActiveWindow"		: @(mainWindow.isActiveForDrawing),
		 @"isGraphite"			: @([NSColor currentControlTint] == NSGraphiteControlTint),
		 @"isInverted"			: @(mainWindow.usingDarkAppearance),
		 @"isRetina"			: @(mainWindow.runningInHighResolutionMode),
		 @"isSelected"			: @([memberList isRowSelected:rowIndex]),
		 @"rowIndex"			: @(rowIndex)
	};
}

@end

#pragma mark -
#pragma mark Row View Cell

@implementation TVCMemberListRowCell

- (void)setSelected:(BOOL)selected
{
	super.selected = selected;

	[self postSelectionChangeNeedsDisplay];
}

- (void)postSelectionChangeNeedsDisplay
{
	if (self.isSelected)
	{
		if (TEXTUAL_RUNNING_ON(10.10, Yosemite))
		{
			if (self.mainWindow.usingDarkAppearance) {
				self.selectionHighlightStyle = NSTableViewSelectionHighlightStyleRegular;
			} else {
				self.selectionHighlightStyle = NSTableViewSelectionHighlightStyleSourceList;
			}
		}
		else
		{
			if (self.mainWindow.usingDarkAppearance) {
				self.selectionHighlightStyle = NSTableViewSelectionHighlightStyleRegular;
			} else {
				self.selectionHighlightStyle = NSTableViewSelectionHighlightStyleSourceList;
			}
		}
	}
	else
	{
		self.selectionHighlightStyle = NSTableViewSelectionHighlightStyleRegular;
	}

	[self setNeedsDisplayOnChild];
}

- (void)setNeedsDisplayOnChild
{
	self.childCell.needsDisplay = YES;
}

- (void)drawSelectionInRect:(NSRect)dirtyRect
{
	if ([self needsToDrawRect:dirtyRect] == NO) {
		return;
	}

	TVCMainWindow *mainWindow = self.mainWindow;

	id interfaceObjects = mainWindow.memberList.userInterfaceObjects;

	if (TEXTUAL_RUNNING_ON(10.10, Yosemite))
	{
		NSColor *selectionColor = nil;

		if (mainWindow.isActiveForDrawing) {
			selectionColor = [interfaceObjects rowSelectionColorForActiveWindow];
		} else {
			selectionColor = [interfaceObjects rowSelectionColorForInactiveWindow];
		}

		if (selectionColor) {
			[selectionColor set];

			NSRect selectionRect = self.bounds;

			NSRectFill(selectionRect);
		} else {
			[super drawSelectionInRect:dirtyRect];
		}
	}
	else
	{
		NSImage *selectionImage = nil;

		if (mainWindow.isActiveForDrawing) {
			selectionImage = [interfaceObjects rowSelectionImageForActiveWindow];
		} else {
			selectionImage = [interfaceObjects rowSelectionImageForInactiveWindow];
		}

		if (selectionImage) {
			NSRect selectionRect = self.bounds;

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

#pragma mark -
#pragma mark Cell Information

- (BOOL)isEmphasized
{
	return YES;
}

- (NSColor *)fontSmoothingBackgroundColor
{
	if (self.mainWindow.usingDarkAppearance) {
		return [NSColor grayColor];
	} else {
		return [NSColor whiteColor];
	}
}

- (TVCMemberListCell * _Nullable)childCell
{
	if (self->_childCell == nil) {
		if (self.numberOfColumns == 0) {
			return nil;
		}

		self->_childCell = [self viewAtColumn:0];
	}

	return self->_childCell;
}

@end

NS_ASSUME_NONNULL_END
