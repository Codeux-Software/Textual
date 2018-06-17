/* *********************************************************************
 *                  _____         _               _
 *                 |_   _|____  _| |_ _   _  __ _| |
 *                   | |/ _ \ \/ / __| | | |/ _` | |
 *                   | |  __/>  <| |_| |_| | (_| | |
 *                   |_|\___/_/\_\\__|\__,_|\__,_|_|
 *
 * Copyright (c) 2010 - 2015 Codeux Software, LLC & respective contributors.
 *       Please see Acknowledgements.pdf for additional information.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *
 *  * Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 *  * Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 *  * Neither the name of Textual, "Codeux Software, LLC", nor the
 *    names of its contributors may be used to endorse or promote products
 *    derived from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE AUTHOR AND CONTRIBUTORS ``AS IS'' AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED. IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE LIABLE
 * FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
 * OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
 * LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
 * OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
 * SUCH DAMAGE.
 *
 *********************************************************************** */

#import "NSStringHelper.h"
#import "NSTableVIewHelperPrivate.h"
#import "NSViewHelperPrivate.h"
#import "TLOLanguagePreferences.h"
#import "TPCPreferencesLocal.h"
#import "IRCChannelUser.h"
#import "IRCUser.h"
#import "TVCMainWindow.h"
#import "TVCMemberListAppearance.h"
#import "TVCMemberListPrivate.h"
#import "TVCMemberListUserInfoPopoverPrivate.h"
#import "TVCMemberListCellPrivate.h"

NS_ASSUME_NONNULL_BEGIN

@class TVCMemberListCellDrawingContext;

@interface TVCMemberListRowCell ()
@property (nonatomic, weak) TVCMemberList *memberList;
@property (nonatomic, weak) TVCMemberListCell *childCell;
@property (readonly) TVCMemberListAppearance *userInterfaceObjects;
@property (nonatomic, assign) BOOL disableQuirks;
@end

@interface TVCMemberListCell ()
@property (nonatomic, weak) IBOutlet NSTextField *cellTextField;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *textFieldTopConstraint;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *userMarkBadgeTopConstraint;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *userMarkBadgeWidthConstraint;
@property (readonly, copy) TVCMemberListCellDrawingContext *drawingContext;
@property (readonly) TVCMemberList *memberList;
@property (readonly) TVCMemberListRowCell *rowCell;
@property (readonly) TVCMemberListAppearance *userInterfaceObjects;
@property (readonly) IRCChannelUser *cellItem;
@property (readonly) NSInteger rowIndex;
@end

@interface TVCMemberListCellDrawingContext : NSObject
@property (nonatomic, assign) BOOL isInverted;
@property (nonatomic, assign) BOOL isSelected;
@property (nonatomic, assign) BOOL isWindowActive;
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
	TVCMemberListAppearance *appearance = self.userInterfaceObjects;

	if (appearance.isModernAppearance) {
		[self updateConstraintsForYosemiteWithAppearance:appearance];
	}
}

- (void)updateConstraintsForYosemiteWithAppearance:(TVCMemberListAppearance *)appearance
{
	NSParameterAssert(appearance != nil);

	self.textFieldTopConstraint.constant = appearance.cellTopOffset;

	self.userMarkBadgeTopConstraint.constant = appearance.markBadgeTopOffset;

	self.userMarkBadgeWidthConstraint.constant = appearance.markBadgeWidth;
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
	TVCMemberListCellDrawingContext *drawingContext = self.drawingContext;

	[self updateTextFieldInContext:drawingContext];

	TVCMemberListAppearance *appearance = self.userInterfaceObjects;

	if (appearance.isModernAppearance) {
		[self updateDrawingForYosemiteWithAppearance:appearance inContext:drawingContext];
	} else {
		[self updateDrawingForMavericksWithAppearance:appearance inContext:drawingContext];
	}

	[self updateMarkBadgeWithAppearance:appearance inContext:drawingContext];
}

- (void)updateTextFieldInContext:(TVCMemberListCellDrawingContext *)drawingContext
{
	NSParameterAssert(drawingContext != nil);

	/* Update string value */
	IRCChannelUser *cellItem = self.cellItem;

	NSString *stringValueNew = cellItem.user.nickname;

	NSTextField *textField = self.cellTextField;

	NSString *stringValueOld = textField.stringValue;

	if ([stringValueOld isEqualTo:stringValueNew]) {
		return;
	}

	textField.stringValue = stringValueNew;

	/* Update accessibility */
	NSTextFieldCell *textFieldCell = textField.cell;

	[XRAccessibility setAccessibilityValueDescription:TXTLS(@"Accessibility[1000]", stringValueNew) forObject:textFieldCell];
}

- (void)updateDrawingForYosemiteWithAppearance:(TVCMemberListAppearance *)appearance inContext:(TVCMemberListCellDrawingContext *)drawingContext
{
	NSParameterAssert(appearance != nil);
	NSParameterAssert(drawingContext != nil);

	NSAttributedString *newValue = [self attributedTextFieldValueForYosemiteWithAppearance:appearance inContext:drawingContext];

	self.cellTextField.attributedStringValue = newValue;
}

- (void)updateDrawingForMavericksWithAppearance:(TVCMemberListAppearance *)appearance inContext:(TVCMemberListCellDrawingContext *)drawingContext
{
	NSParameterAssert(appearance != nil);
	NSParameterAssert(drawingContext != nil);

	NSAttributedString *newValue = [self attributedTextFieldValueForMavericksWithAppearance:appearance inContext:drawingContext];

	self.cellTextField.attributedStringValue = newValue;
}

- (NSAttributedString *)attributedTextFieldValueForMavericksWithAppearance:(TVCMemberListAppearance *)appearance inContext:(TVCMemberListCellDrawingContext *)drawingContext
{
	NSParameterAssert(appearance != nil);
	NSParameterAssert(drawingContext != nil);

	BOOL isInverted = drawingContext.isInverted;
	BOOL isSelected = drawingContext.isSelected;
	BOOL isWindowActive = drawingContext.isWindowActive;

	IRCChannelUser *cellItem = self.cellItem;

	NSTextField *textField = self.cellTextField;

	NSAttributedString *stringValue = textField.attributedStringValue;

	NSMutableAttributedString *mutableStringValue = [stringValue mutableCopy];

	[mutableStringValue beginEditing];

	NSFont *controlFont = nil;

	if (isSelected) {
		controlFont = appearance.cellFontSelected;
	} else {
		controlFont = appearance.cellFont;
	} // isSelected

	NSColor *controlColor = nil;
	NSColor *shadowColor = nil;

	if (isSelected) {
		if (isWindowActive) {
			controlColor = appearance.cellSelectedTextColorActiveWindow;
			shadowColor = appearance.cellSelectedTextShadowColorActiveWindow;
		} else {
			controlColor = appearance.cellSelectedTextColorInactiveWindow;
			shadowColor = appearance.cellSelectedTextShadowColorInactiveWindow;
		} // isWindowActive
	} else if (cellItem.user.isAway) {
		if (isWindowActive) {
			controlColor = appearance.cellAwayTextColorActiveWindow;
			shadowColor = appearance.cellAwayTextShadowColorActiveWindow;
		} else {
			controlColor = appearance.cellAwayTextColorInactiveWindow;
			shadowColor = appearance.cellAwayTextShadowColorInactiveWindow;
		} // isWindowActive
	} else {
		if (isWindowActive) {
			controlColor = appearance.cellTextColorActiveWindow;
			shadowColor = appearance.cellTextShadowColorActiveWindow;
		} else {
			controlColor = appearance.cellTextColorInactiveWindow;
			shadowColor = appearance.cellTextShadowColorInactiveWindow;
		} // isWindowActive
	} // isActive

	NSShadow *itemShadow = nil;

	if (shadowColor) {
		itemShadow = [NSShadow new];

		itemShadow.shadowBlurRadius = 1.0;

		itemShadow.shadowOffset = NSMakeSize(0.0, (-1.0));

		if (isSelected && isInverted == NO) {
			itemShadow.shadowBlurRadius = 2.0;
		}

		itemShadow.shadowColor = shadowColor;
	} // shadowColor

	NSRange stringValueRange = stringValue.range;

	if (controlFont) {
		[mutableStringValue addAttribute:NSFontAttributeName value:controlFont range:stringValueRange];
	}

	if (controlColor) {
		[mutableStringValue addAttribute:NSForegroundColorAttributeName value:controlColor	range:stringValueRange];
	}

	if (itemShadow) {
		[mutableStringValue addAttribute:NSShadowAttributeName value:itemShadow range:stringValueRange];
	}

	[mutableStringValue endEditing];

	return mutableStringValue;
}

- (NSAttributedString *)attributedTextFieldValueForYosemiteWithAppearance:(TVCMemberListAppearance *)appearance inContext:(TVCMemberListCellDrawingContext *)drawingContext
{
	NSParameterAssert(appearance != nil);
	NSParameterAssert(drawingContext != nil);

	BOOL isSelected = drawingContext.isSelected;
	BOOL isWindowActive = drawingContext.isWindowActive;

	IRCChannelUser *cellItem = self.cellItem;

	NSTextField *textField = self.cellTextField;

	NSAttributedString *stringValue = textField.attributedStringValue;

	NSMutableAttributedString *mutableStringValue = [stringValue mutableCopy];

	[mutableStringValue beginEditing];

	NSFont *controlFont = nil;

	if (isSelected) {
		controlFont = appearance.cellFontSelected;
	} else {
		controlFont = appearance.cellFont;
	} // isSelected

	NSColor *controlColor = nil;

	if (isSelected) {
		if (isWindowActive) {
			controlColor = appearance.cellSelectedTextColorActiveWindow;
		} else {
			controlColor = appearance.cellSelectedTextColorInactiveWindow;
		} // isWindowActive
	} else if (cellItem.user.isAway) {
		if (isWindowActive) {
			controlColor = appearance.cellAwayTextColorActiveWindow;
		} else {
			controlColor = appearance.cellAwayTextColorInactiveWindow;
		} // isWindowActive
	} else {
		if (isWindowActive) {
			controlColor = appearance.cellTextColorActiveWindow;
		} else {
			controlColor = appearance.cellTextColorInactiveWindow;
		} // isWindowActive
	}

	NSRange stringValueRange = stringValue.range;

	if (controlFont) {
		[mutableStringValue addAttribute:NSFontAttributeName value:controlFont range:stringValueRange];
	}

	if (controlColor) {
		[mutableStringValue addAttribute:NSForegroundColorAttributeName value:controlColor	range:stringValueRange];
	}

	[mutableStringValue endEditing];

	return mutableStringValue;
}

#pragma mark -
#pragma mark Badge Drawing

- (NSAttributedString *)markBadgeTextForModeSymbol:(NSString *)modeSymbol isSelected:(BOOL)isSelected withAppearance:(TVCMemberListAppearance *)appearance inContext:(TVCMemberListCellDrawingContext *)drawingContext
{
	NSParameterAssert(appearance != nil);
	NSParameterAssert(drawingContext != nil);

	BOOL isWindowActive = drawingContext.isWindowActive;

	NSFont *controlFont = nil;

	if (isSelected) {
		controlFont = appearance.markBadgeFontSelected;
	} else {
		controlFont = appearance.markBadgeFont;
	} // isSelected

	NSColor *controlColor = nil;

	if (isSelected) {
		if (isWindowActive) {
			controlColor = appearance.markBadgeSelectedTextColorActiveWindow;
		} else {
			controlColor = appearance.markBadgeSelectedTextColorInactiveWindow;
		} // isWindowActive
	} else {
		if (isWindowActive) {
			controlColor = appearance.markBadgeTextColorActiveWindow;
		} else {
			controlColor = appearance.markBadgeTextColorInactiveWindow;
		} // isWindowActive
	} // isSelected

	NSDictionary *attributes = @{NSForegroundColorAttributeName : controlColor, NSFontAttributeName : controlFont};

	NSAttributedString *stringToDraw = [NSAttributedString attributedStringWithString:modeSymbol attributes:attributes];

	return stringToDraw;
}

- (void)updateMarkBadgeWithAppearance:(TVCMemberListAppearance *)appearance inContext:(TVCMemberListCellDrawingContext *)drawingContext
{
	NSParameterAssert(appearance != nil);
	NSParameterAssert(drawingContext != nil);

	BOOL isSelected = drawingContext.isSelected;

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
		cachedImage = [appearance cachedUserMarkBadgeForSymbol:modeSymbol rank:userRankToDraw];
	}

	if (cachedImage == nil) {
		cachedImage = [self drawMarkBadgeForRank:userRankToDraw isSelected:isSelected withAppearance:appearance inContext:drawingContext];

		if (isSelected == NO) {
			[appearance cacheUserMarkBadge:cachedImage forSymbol:modeSymbol rank:userRankToDraw];
		}
	}

	self.imageView.image = cachedImage;
}

- (NSImage *)drawMarkBadgeForRank:(IRCUserRank)userRank isSelected:(BOOL)isSelected withAppearance:(TVCMemberListAppearance *)appearance inContext:(TVCMemberListCellDrawingContext *)drawingContext
{
	NSParameterAssert(appearance != nil);
	NSParameterAssert(drawingContext != nil);

	BOOL isWindowActive = drawingContext.isWindowActive;

	BOOL isDrawingOnMavericks = (appearance.isModernAppearance == NO);

	/* Create image that we will draw into. If we are drawing for Mavericks,
	 then the frame of our image is one pixel greater because we draw a shadow. */
	NSImage *badgeImage = nil;

	NSRect badgeFrame = NSZeroRect;

	if (isDrawingOnMavericks) {
		badgeFrame = NSMakeRect(0.0, 1.0, appearance.markBadgeWidth, appearance.markBadgeHeight);

		badgeImage = [NSImage newImageWithSize:NSMakeSize(NSWidth(badgeFrame), (NSHeight(badgeFrame) + 1.0))];
	} else {
		badgeFrame = NSMakeRect(0.0, 0.0, appearance.markBadgeWidth, appearance.markBadgeHeight);

		badgeImage = [NSImage newImageWithSize:NSMakeSize(NSWidth(badgeFrame),  NSHeight(badgeFrame))];
	}

	[badgeImage lockFocus];

	/* Decide the background color */
	NSColor *backgroundColor = nil;

	if (isSelected) {
		if (isWindowActive) {
			backgroundColor = appearance.markBadgeSelectedBackgroundColorActiveWindow;
		} else {
			backgroundColor = appearance.markBadgeSelectedBackgroundColorInactiveWindow;
		} // isWindowActive
	} else if (userRank == IRCUserIRCopByModeRank) {
		backgroundColor = appearance.markBadgeBackgroundColor_Y;
	} else if (userRank == IRCUserChannelOwnerRank) {
		backgroundColor = appearance.markBadgeBackgroundColor_Q;
	} else if (userRank == IRCUserSuperOperatorRank) {
		backgroundColor = appearance.markBadgeBackgroundColor_A;
	} else if (userRank == IRCUserNormalOperatorRank) {
		backgroundColor = appearance.markBadgeBackgroundColor_O;
	} else if (userRank == IRCUserHalfOperatorRank) {
		backgroundColor = appearance.markBadgeBackgroundColor_H;
	} else if (userRank == IRCUserVoicedRank) {
		backgroundColor = appearance.markBadgeBackgroundColor_V;
	} else {
		NSColor *customColor = appearance.markBadgeBackgroundColorByUser;

		if (customColor && [customColor isEqual:[NSColor clearColor]] == NO) {
			backgroundColor = customColor;
		} else {
			if (isWindowActive) {
				backgroundColor = appearance.markBadgeBackgroundColorActiveWindow;
			} else {
				backgroundColor = appearance.markBadgeBackgroundColorInactiveWindow;
			} // isWindowActive
		} // custom color set
	}

	/* Set "x" if the user has no modes set */
	NSString *stringToDraw = self.cellItem.mark;

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

			NSColor *shadowColor = nil;

			if (isWindowActive) {
				shadowColor = appearance.markBadgeShadowColorActiveWindow;
			} else {
				shadowColor = appearance.markBadgeShadowColorInactiveWindow;
			} // isWindowActive

			[shadowColor set];

			[shadowPath fill];
		} // isSelected
	} // isDrawingOnMavericks

	/* Draw the background of the badge */
	NSBezierPath *badgePath = [NSBezierPath bezierPathWithRoundedRect:badgeFrame xRadius:4.0 yRadius:4.0];

	[backgroundColor set];

	[badgePath fill];

	/* Begin building the actual mode string */
	if (stringToDraw.length > 0) {
		NSAttributedString *badgeText = [self markBadgeTextForModeSymbol:stringToDraw isSelected:isSelected withAppearance:appearance inContext:drawingContext];

		NSSize badgeTextSize = badgeText.size;

		NSPoint badgeTextPoint = NSMakePoint((NSMidX(badgeFrame) - (badgeTextSize.width / 2.0)),
											 (NSMidY(badgeFrame) - (badgeTextSize.height / 2.0)));

		if (appearance.isHighResolutionAppearance)
		{
			if ([stringToDraw isEqualToString:@"+"] ||
				[stringToDraw isEqualToString:@"~"] ||
				[stringToDraw isEqualToString:@"×"])
			{
				badgeTextPoint.y += 1.0;
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
				badgeTextPoint.y += 2.0;
			}
			else if ([stringToDraw isEqualToString:@"@"] ||
					 [stringToDraw isEqualToString:@"!"] ||
					 [stringToDraw isEqualToString:@"%"] ||
					 [stringToDraw isEqualToString:@"&"] ||
					 [stringToDraw isEqualToString:@"#"] ||
					 [stringToDraw isEqualToString:@"?"])
			{
				badgeTextPoint.y += 1.0;
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
				badgeTextPoint.y += 1.0;
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
	TVCMemberList *memberList = self.memberList;

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

	NSInteger rowIndex = [memberList rowForItem:cellItem];

	NSRect cellFrame = [memberList frameOfCellAtColumn:0 row:rowIndex];

	/* Presenting the popover will steal focus. To workaround this,
	 we record the active first responder then set it back. */
	NSWindow *window = self.window;

	NSResponder *activeFirstResponder = window.firstResponder;

	[userInfoPopover showRelativeToRect:cellFrame
								 ofView:memberList
						  preferredEdge:NSMaxXEdge];

	[window makeFirstResponder:activeFirstResponder];
}

- (TVCMemberListRowCell *)rowCell
{
	return (id)self.superview;
}

- (IRCChannelUser *)cellItem
{
	return self.objectValue;
}

- (TVCMemberList *)memberList
{
	return self.rowCell.memberList;
}

- (TVCMemberListAppearance *)userInterfaceObjects
{
	return self.rowCell.userInterfaceObjects;
}

- (TVCMemberListCellDrawingContext *)drawingContext
{
	TVCMemberList *memberList = self.memberList;

	NSInteger rowIndex = [memberList rowForItem:self.objectValue];

	TVCMemberListAppearance *appearance = self.userInterfaceObjects;

	TVCMemberListCellDrawingContext *drawingContext = [TVCMemberListCellDrawingContext new];

	TVCMainWindow *mainWindow = self.mainWindow;

	drawingContext.isInverted = appearance.isDarkAppearance;
	drawingContext.isSelected = [memberList isRowSelected:rowIndex];
	drawingContext.isWindowActive = mainWindow.isActiveForDrawing;

	return drawingContext;
}

@end

@implementation TVCMemberListCellDrawingContext
@end

#pragma mark -
#pragma mark Row View Cell

@implementation TVCMemberListRowCell

- (instancetype)initWithMemberList:(TVCMemberList *)memberList
{
	NSParameterAssert(memberList != nil);

	if ((self = [super initWithFrame:NSZeroRect])) {
		self.memberList = memberList;

		return self;
	}

	return nil;
}

- (void)viewWillMoveToWindow:(nullable NSWindow *)newWindow
{
	[super viewWillMoveToWindow:newWindow];

	self.disableQuirks = TEXTUAL_RUNNING_ON_MOJAVE;
}

- (void)setSelected:(BOOL)selected
{
	super.selected = selected;

	[self modifySelectionHighlightStyle];

	[self setNeedsDisplayOnChild];
}

- (void)modifySelectionHighlightStyle
{
	if (self.disableQuirks) {
		return;
	}

	if (self.isSelected)
	{
		TVCMemberListAppearance *appearance = self.userInterfaceObjects;

		if (appearance.isDarkAppearance) {
			self.selectionHighlightStyle = NSTableViewSelectionHighlightStyleRegular;
		} else {
			self.selectionHighlightStyle = NSTableViewSelectionHighlightStyleSourceList;
		}
	}
	else
	{
		self.selectionHighlightStyle = NSTableViewSelectionHighlightStyleRegular;
	}
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

	BOOL isWindowActive = self.mainWindow.isActiveForDrawing;

	TVCMemberListAppearance *appearance = self.userInterfaceObjects;

	if (appearance.isModernAppearance)
	{
		NSColor *selectionColor = nil;

		if (isWindowActive) {
			selectionColor = appearance.rowSelectionColorActiveWindow;
		} else {
			selectionColor = appearance.rowSelectionColorInactiveWindow;
		} // isWindowActive

		if (selectionColor) {
			[selectionColor set];

			NSRect selectionRect = self.bounds;

			NSRectFill(selectionRect);
		} else {
			[super drawSelectionInRect:dirtyRect];
		} // selectionColor
	}
	else
	{
		NSImage *selectionImage = nil;

		if (isWindowActive) {
			selectionImage = appearance.cellSelectionImageActiveWindow;
		} else {
			selectionImage = appearance.cellSelectionImageInactiveWindow;
		} // isWindowActive

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
		} // selectionImage
	} // Yosemite or later
}

#pragma mark -
#pragma mark Cell Information

- (BOOL)isEmphasized
{
	if (self.disableQuirks) {
		/* Default behavior is to return YES when the table
		 is the first responder, but because the main window
		 will force the first responder back to the main text
		 field, we fudge the results a little bit. */

		return self.window.isKeyWindow;
	}

	return YES;
}

- (nullable NSColor *)fontSmoothingBackgroundColor
{
	if (self.disableQuirks) {
		return nil;
	}

	TVCMemberListAppearance *appearance = self.userInterfaceObjects;

	if (appearance.isDarkAppearance) {
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

- (TVCMemberListAppearance *)userInterfaceObjects
{
	return self.memberList.userInterfaceObjects;
}

@end

NS_ASSUME_NONNULL_END
