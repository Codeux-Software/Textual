/* *********************************************************************
 *                  _____         _               _
 *                 |_   _|____  _| |_ _   _  __ _| |
 *                   | |/ _ \ \/ / __| | | |/ _` | |
 *                   | |  __/>  <| |_| |_| | (_| | |
 *                   |_|\___/_/\_\\__|\__,_|\__,_|_|
 *
 * Copyright (c) 2008 - 2010 Satoshi Nakagawa <psychs AT limechat DOT net>
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

#import "NSViewHelperPrivate.h"
#import "TXGlobalModels.h"
#import "TLOLanguagePreferences.h"
#import "TPCPreferencesLocal.h"
#import "IRCClient.h"
#import "IRCChannel.h"
#import "TVCMainWindow.h"
#import "TVCServerListAppearancePrivate.h"
#import "TVCServerListPrivate.h"
#import "TVCServerListCellPrivate.h"

NS_ASSUME_NONNULL_BEGIN

#define _groupItemLeadingConstraintQuirkCorrectedConstraint		5.0

@interface TVCServerListRowCell ()
@property (nonatomic, weak) __kindof TVCServerListCell *childCell;
@property (readonly) BOOL isGroupItem;
@property (nonatomic, assign) BOOL disableQuirks;
@end

@interface TVCServerListCell ()
@property (nonatomic, weak) IBOutlet NSTextField *cellTextField;
@property (nonatomic, weak) IBOutlet NSImageView *messageCountBadgeImageView;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *messageCountBadgeWidthConstraint;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *messageCountBadgeTrailingConstraint;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *textFieldTopConstraint;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *messageCountBadgeTopConstraint;
@property (readonly) TVCServerList *serverList;
@property (readonly) __kindof TVCServerListRowCell *rowCell;
@property (readonly) IRCTreeItem *cellItem;
@property (readonly, copy) NSDictionary<NSString *, id> *drawingContext;
@end

@implementation TVCServerListCell

#pragma mark -
#pragma mark Cell Drawing

- (void)viewDidMoveToWindow
{
	[super viewDidMoveToWindow];

	[self tx_updateConstraints];
}

- (void)tx_updateConstraints
{
	TVCServerListAppearance *appearance = self.serverList.userInterfaceObjects;

	if (appearance.isModernAppearance) {
		[self updateConstraintsForYosemite:appearance];
	}
}

- (void)updateConstraintsForYosemite:(TVCServerListAppearance *)appearance
{
	NSDictionary *drawingContext = self.drawingContext;

	BOOL isGroupItem = [drawingContext boolForKey:@"isGroupItem"];

	if (isGroupItem) {
		self.textFieldTopConstraint.constant = appearance.serverTopOffset;
	} else {
		self.textFieldTopConstraint.constant = appearance.channelTopOffset;

		self.messageCountBadgeTopConstraint.constant = appearance.unreadBadgeTopOffset;
	}
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
	TVCServerListAppearance *appearance = self.serverList.userInterfaceObjects;

	[self updateDrawing:appearance];
}

- (void)updateDrawing:(TVCServerListAppearance *)appearance
{
	[self updateTextFieldValue];

	if (appearance.isModernAppearance) {
		[self updateDrawingForYosemite:appearance];
	} else {
		[self updateDrawingForMavericks:appearance];
	}

	[self populateAccessibilityDescriptions];
}

- (void)populateAccessibilityDescriptions
{
	NSDictionary *drawingContext = self.drawingContext;

	BOOL isActive = [drawingContext boolForKey:@"isActive"];
	BOOL isGroupItem = [drawingContext boolForKey:@"isGroupItem"];

	NSTextFieldCell *textFieldCell = self.cellTextField.cell;

	IRCTreeItem *cellItem = self.cellItem;

	NSString *cellItemLabel = cellItem.label;

	if (isGroupItem) {
		if (isActive) {
			[XRAccessibility setAccessibilityValueDescription:TXTLS(@"Accessibility[1001][1]", cellItemLabel) forObject:textFieldCell];
		} else {
			[XRAccessibility setAccessibilityValueDescription:TXTLS(@"Accessibility[1001][2]", cellItemLabel) forObject:textFieldCell];
		} // isActive
	} else {
		if (((IRCChannel *)cellItem).isChannel == NO) {
			[XRAccessibility setAccessibilityValueDescription:TXTLS(@"Accessibility[1003]", cellItemLabel) forObject:textFieldCell];
		} else {
			if (isActive) {
				[XRAccessibility setAccessibilityValueDescription:TXTLS(@"Accessibility[1002][1]", cellItemLabel) forObject:textFieldCell];
			} else {
				[XRAccessibility setAccessibilityValueDescription:TXTLS(@"Accessibility[1002][2]", cellItemLabel) forObject:textFieldCell];
			} // isActive
		} // isChannel

		[XRAccessibility setAccessibilityLabel:nil forObject:self.imageView.cell];
	} // isGroupItem
}

- (void)updateTextFieldValue
{
	IRCTreeItem *cellItem = self.cellItem;

	NSString *stringValueNew = cellItem.label;

	NSTextField *textField = self.cellTextField;

	NSString *stringValueOld = textField.stringValue;

	if ([stringValueOld isEqualTo:stringValueNew] == NO) {
		textField.stringValue = stringValueNew;
	}
}

- (void)updateDrawingForYosemite:(TVCServerListAppearance *)appearance
{
	NSDictionary *drawingContext = self.drawingContext;

	BOOL isActive = [drawingContext boolForKey:@"isActive"];
	BOOL isActiveWindow = [drawingContext boolForKey:@"isActiveWindow"];
	BOOL isGroupItem = [drawingContext boolForKey:@"isGroupItem"];
	BOOL isSelected = [drawingContext boolForKey:@"isSelected"];

	if (isGroupItem == NO) {
		IRCTreeItem *cellItem = self.cellItem;

		IRCChannel *channel = (IRCChannel *)cellItem;

		NSString *iconName = nil;

		BOOL iconIsTemplate = NO;

		if (channel.isChannel) {
			iconName = [appearance statusIconForActiveChannel:isActive selected:isSelected activeWindow:isActiveWindow treatAsTemplate:&iconIsTemplate];
		} else {
			iconName = [appearance statusIconForActiveQuery:isActive selected:isSelected activeWindow:isActiveWindow treatAsTemplate:&iconIsTemplate];
		} // isChannel

		NSImage *icon = [NSImage imageNamed:iconName];

		icon.template = iconIsTemplate;

		self.imageView.image = icon;
	}

	NSAttributedString *newValue = [self attributedTextFieldValueForYosemite:appearance inContext:drawingContext];

	self.cellTextField.attributedStringValue = newValue;

	if (isGroupItem == NO) {
		[self populateMessageCountBadge:appearance inContext:drawingContext];
	}
}

- (void)updateDrawingForMavericks:(TVCServerListAppearance *)appearance
{
	NSDictionary *drawingContext = self.drawingContext;

	BOOL isActive = [drawingContext boolForKey:@"isActive"];
	BOOL isActiveWindow = [drawingContext boolForKey:@"isActiveWindow"];
	BOOL isSelected = [drawingContext boolForKey:@"isSelected"];
	BOOL isGroupItem = [drawingContext boolForKey:@"isGroupItem"];

	if (isGroupItem == NO) {
		IRCTreeItem *cellItem = self.cellItem;

		IRCChannel *channel = (IRCChannel *)cellItem;

		NSString *iconName = nil;

		BOOL iconIsTemplate = NO;

		if (channel.isChannel) {
			iconName = [appearance statusIconForActiveChannel:isActive selected:isSelected activeWindow:isActiveWindow treatAsTemplate:&iconIsTemplate];
		} else {
			iconName = [appearance statusIconForActiveQuery:isActive selected:isSelected activeWindow:isActiveWindow treatAsTemplate:&iconIsTemplate];
		} // isChannel

		NSImage *icon = [NSImage imageNamed:iconName];

		icon.template = iconIsTemplate;

		self.imageView.image = icon;
	}

	NSAttributedString *newValue = [self attributedTextFieldValueForMavericks:appearance inContext:drawingContext];

	self.cellTextField.attributedStringValue = newValue;

	if (isGroupItem == NO) {
		[self populateMessageCountBadge:appearance inContext:drawingContext];
	}
}

- (NSAttributedString *)attributedTextFieldValueForMavericks:(TVCServerListAppearance *)appearance inContext:(NSDictionary<NSString *, id> *)drawingContext
{
	BOOL isActive = [drawingContext boolForKey:@"isActive"];
	BOOL isGroupItem = [drawingContext boolForKey:@"isGroupItem"];
	BOOL isInverted = [drawingContext boolForKey:@"isInverted"];
	BOOL isSelected = [drawingContext boolForKey:@"isSelected"];
	BOOL isWindowActive = [drawingContext boolForKey:@"isActiveWindow"];

	NSTextField *textField = self.cellTextField;

	NSAttributedString *stringValue = textField.attributedStringValue;

	NSMutableAttributedString *mutableStringValue = [stringValue mutableCopy];

	[mutableStringValue beginEditing];

	NSFont *controlFont = nil;

	NSColor *controlColor = nil;

	NSShadow *itemShadow = nil;

	if (isGroupItem)
	{
		if (isSelected) {
			if (isWindowActive) {
				controlFont = appearance.serverFontSelectedActiveWindow;
			} else {
				controlFont = appearance.serverFontSelectedInactiveWindow;
			} // isWindowActive
		} else {
			if (isWindowActive) {
				controlFont = appearance.serverFontActiveWindow;
			} else {
				controlFont = appearance.serverFontInactiveWindow;
			} // isWindowActive
		} // isSelected

		NSColor *shadowColor = nil;

		if (isSelected) {
			if (isWindowActive) {
				controlColor = appearance.serverSelectedTextColorActiveWindow;
				shadowColor = appearance.serverSelectedTextShadowColorActiveWindow;
			} else {
				controlColor = appearance.serverSelectedTextColorInactiveWindow;
				shadowColor = appearance.serverSelectedTextShadowColorInactiveWindow;
			} // isWindowActive
		} else if (isActive) {
			if (isWindowActive) {
				controlColor = appearance.serverTextColorActiveWindow;
				shadowColor = appearance.serverTextShadowColorActiveWindow;
			} else {
				controlColor = appearance.serverTextColorInactiveWindow;
				shadowColor = appearance.serverTextShadowColorInactiveWindow;
			} // isWindowActive
		} else {
			if (isWindowActive) {
				controlColor = appearance.serverDisabledTextColorActiveWindow;
				shadowColor = appearance.serverDisabledTextShadowColorActiveWindow;
			} else {
				controlColor = appearance.serverDisabledTextColorInactiveWindow;
				shadowColor = appearance.serverDisabledTextShadowColorInactiveWindow;
			} // isWindowActive
		} // isActive

		if (shadowColor) {
			itemShadow = [NSShadow new];

			itemShadow.shadowOffset = NSMakeSize(0.0, (-1.0));

			if (isInverted) {
				itemShadow.shadowBlurRadius = 1.0;
			}

			itemShadow.shadowColor = shadowColor;
		} // shadowColor
	}
	else // isGroupItem
	{
		if (isSelected) {
			if (isWindowActive) {
				controlFont = appearance.channelFontSelectedActiveWindow;
			} else {
				controlFont = appearance.channelFontSelectedInactiveWindow;
			} // isWindowActive
		} else {
			if (isWindowActive) {
				controlFont = appearance.channelFontActiveWindow;
			} else {
				controlFont = appearance.channelFontInactiveWindow;
			} // isWindowActive
		} // isSelected

		NSColor *shadowColor = nil;

		if (isSelected) {
			if (isWindowActive) {
				controlColor = appearance.channelSelectedTextColorActiveWindow;
				shadowColor = appearance.channelSelectedTextShadowColorActiveWindow;
			} else {
				controlColor = appearance.channelSelectedTextColorInactiveWindow;
				shadowColor = appearance.channelSelectedTextShadowColorInactiveWindow;
			} // isWindowActive
		} else if (isActive) {
			if (isWindowActive) {
				controlColor = appearance.channelTextColorActiveWindow;
				shadowColor = appearance.channelTextShadowColorActiveWindow;
			} else {
				controlColor = appearance.channelTextColorInactiveWindow;
				shadowColor = appearance.channelTextShadowColorInactiveWindow;
			} // isWindowActive
		} else {
			if (isWindowActive) {
				controlColor = appearance.channelDisabledTextColorActiveWindow;
				shadowColor = appearance.channelDisabledTextShadowColorActiveWindow;
			} else {
				controlColor = appearance.channelDisabledTextColorInactiveWindow;
				shadowColor = appearance.channelDisabledTextShadowColorInactiveWindow;
			} // isWindowActive
		} // isActive

		if (shadowColor) {
			itemShadow = [NSShadow new];

			itemShadow.shadowBlurRadius = 1.0;

			itemShadow.shadowOffset = NSMakeSize(0.0, (-1.0));

			if (isSelected && isInverted == NO) {
				itemShadow.shadowBlurRadius = 2.0;
			}

			itemShadow.shadowColor = shadowColor;
		} // shadowColor
	} // isGroupItem

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

- (NSAttributedString *)attributedTextFieldValueForYosemite:(TVCServerListAppearance *)appearance inContext:(NSDictionary<NSString *, id> *)drawingContext
{
	BOOL isActive = [drawingContext boolForKey:@"isActive"];
	BOOL isGroupItem = [drawingContext boolForKey:@"isGroupItem"];
	BOOL isSelected = [drawingContext boolForKey:@"isSelected"];
	BOOL isWindowActive = [drawingContext boolForKey:@"isActiveWindow"];

	IRCTreeItem *cellItem = self.cellItem;

	BOOL isErroneous = NO;

	BOOL isHighlight = NO;

	if (isGroupItem == NO) {
		IRCChannel *associatedChannel = (id)cellItem;

		isErroneous = associatedChannel.errorOnLastJoinAttempt;

		isHighlight = (associatedChannel.nicknameHighlightCount > 0);
	}

	NSTextField *textField = self.cellTextField;

	NSAttributedString *stringValue = textField.attributedStringValue;

	NSMutableAttributedString *mutableStringValue = [stringValue mutableCopy];

	[mutableStringValue beginEditing];

	NSFont *controlFont = nil;

	NSColor *controlColor = nil;

	if (isGroupItem)
	{
		if (isSelected) {
			if (isWindowActive) {
				controlFont = appearance.serverFontSelectedActiveWindow;
			} else {
				controlFont = appearance.serverFontSelectedInactiveWindow;
			} // isWindowActive
		} else {
			if (isWindowActive) {
				controlFont = appearance.serverFontActiveWindow;
			} else {
				controlFont = appearance.serverFontInactiveWindow;
			} // isWindowActive
		} // isSelected

		if (isSelected) {
			if (isWindowActive) {
				controlColor = appearance.serverSelectedTextColorActiveWindow;
			} else {
				controlColor = appearance.serverSelectedTextColorInactiveWindow;
			} // isWindowActive
		} else if (isActive) {
			if (isWindowActive) {
				controlColor = appearance.serverTextColorActiveWindow;
			} else {
				controlColor = appearance.serverTextColorInactiveWindow;
			} // isWindowActive
		} else {
			if (isWindowActive) {
				controlColor = appearance.serverDisabledTextColorActiveWindow;
			} else {
				controlColor = appearance.serverDisabledTextColorInactiveWindow;
			} // isWindowActive
		}
	}
	else // isGroupItem
	{
		if (isSelected) {
			if (isWindowActive) {
				controlFont = appearance.channelFontSelectedActiveWindow;
			} else {
				controlFont = appearance.channelFontSelectedInactiveWindow;
			} // isWindowActive
		} else {
			if (isWindowActive) {
				controlFont = appearance.channelFontActiveWindow;
			} else {
				controlFont = appearance.channelFontInactiveWindow;
			} // isWindowActive
		} // isSelected

		if (isSelected) {
			if (isWindowActive) {
				controlColor = appearance.channelSelectedTextColorActiveWindow;
			} else {
				controlColor = appearance.channelSelectedTextColorInactiveWindow;
			} // isWindowActive
		} else if (isActive && isHighlight) {
			NSColor *customColor = appearance.unreadBadgeHighlightBackgroundColorByUser;

			if (customColor && [customColor isEqual:[NSColor clearColor]] == NO) {
				controlColor = customColor;
			} else {
				if (isWindowActive) {
					controlColor = appearance.channelHighlightTextColorActiveWindow;
				} else {
					customColor = appearance.channelHighlightTextColorInactiveWindow;
				} // isWindowActive
			} // custom color set
		} else if (isActive) {
			if (isWindowActive) {
				controlColor = appearance.channelTextColorActiveWindow;
			} else {
				controlColor = appearance.channelTextColorInactiveWindow;
			} // isWindowActive
		} else if (isErroneous) {
			if (isWindowActive) {
				controlColor = appearance.channelErroneousTextColorActiveWindow;
			} else {
				controlColor = appearance.channelErroneousTextColorInactiveWindow;
			} // isWindowActive
		} else {
			if (isWindowActive) {
				controlColor = appearance.channelDisabledTextColorActiveWindow;
			} else {
				controlColor = appearance.channelDisabledTextColorInactiveWindow;
			} // isWindowActive
		}
	} // isGroupItem

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

- (void)populateMessageCountBadge
{
	TVCServerListAppearance *appearance = self.serverList.userInterfaceObjects;

	NSDictionary *drawingContext = self.drawingContext;

	[self populateMessageCountBadge:appearance inContext:drawingContext];
}

- (void)populateMessageCountBadge:(TVCServerListAppearance *)appearance inContext:(NSDictionary<NSString *, id> *)drawingContext
{
	BOOL isActiveWindow = [drawingContext boolForKey:@"isActiveWindow"];

	BOOL isSelected = [drawingContext boolForKey:@"isSelected"];
	BOOL isSelectedFrontmost = [drawingContext boolForKey:@"isSelectedFrontmost"];

	BOOL multipleRowsSelected = (self.serverList.numberOfSelectedRows > 1);

	IRCChannel *associatedChannel = (id)self.cellItem;

	BOOL drawMessageBadge = (isSelected == NO ||
							(isSelectedFrontmost == NO && isSelected && multipleRowsSelected) ||
							(isActiveWindow == NO && isSelected));

	NSUInteger treeUnreadCount = associatedChannel.treeUnreadCount;
	NSUInteger nicknameHighlightCount = associatedChannel.nicknameHighlightCount;

	BOOL isHighlight = (nicknameHighlightCount > 0);

	if (associatedChannel.config.ignoreHighlights) {
		isHighlight = NO;
	}

	if (associatedChannel.config.showTreeBadgeCount == NO) {
		if (appearance.isModernAppearance) {
			drawMessageBadge = NO; /* On Yosemite we colorize the channel name itself. */
		} else {
			if (isHighlight) {
				treeUnreadCount = nicknameHighlightCount;
			} else {
				drawMessageBadge = NO;
			}
		}
	}

	/* Begin draw if we want to. */
	if (treeUnreadCount > 0 && drawMessageBadge) {
		NSAttributedString *stringToDraw = [self messageCountBadgeText:treeUnreadCount isSelected:isSelected isHighlight:isHighlight];

		NSRect badgeRect = [self messageCountBadgeRectWithText:stringToDraw];

		[self drawMessageCountBadge:stringToDraw inRect:badgeRect isHighlight:isHighlight isSelected:isSelected];

		self.messageCountBadgeTrailingConstraint.constant = appearance.unreadBadgeRightMargin;
		self.messageCountBadgeWidthConstraint.constant = NSWidth(badgeRect);
	} else {
		self.messageCountBadgeTrailingConstraint.constant = 0.0;
		self.messageCountBadgeWidthConstraint.constant = 0.0;

		self.messageCountBadgeImageView.image = nil;
	}
}

- (NSAttributedString *)messageCountBadgeText:(NSUInteger)messageCount isSelected:(BOOL)isSelected isHighlight:(BOOL)isHighlight
{
	TVCMainWindow *mainWindow = self.mainWindow;

	BOOL isWindowActive = mainWindow.isActiveForDrawing;

	TVCServerListAppearance *appearance = mainWindow.serverList.userInterfaceObjects;

	NSString *messageCountString = TXFormattedNumber(messageCount);

	NSFont *controlFont = nil;

	if (isSelected) {
		if (isWindowActive) {
			controlFont = appearance.unreadBadgeFontSelectedActiveWindow;
		} else {
			controlFont = appearance.unreadBadgeFontSelectedInactiveWindow;
		} // isWindowActive
	} else {
		if (isWindowActive) {
			controlFont = appearance.unreadBadgeFontActiveWindow;
		} else {
			controlFont = appearance.unreadBadgeFontInactiveWindow;
		} // isWindowActive
	} // isSelected

	NSColor *controlColor = nil;

	if (isSelected) {
		if (isWindowActive) {
			controlColor = appearance.unreadBadgeSelectedTextColorActiveWindow;
		} else {
			controlColor = appearance.unreadBadgeSelectedTextColorInactiveWindow;
		} // isWindowActive
	} else if (isHighlight) {
		if (isWindowActive) {
			controlColor = appearance.unreadBadgeHighlightTextColorActiveWindow;
		} else {
			controlColor = appearance.unreadBadgeHighlightTextColorInactiveWindow;
		} // isWindowActive
	} else {
		if (isWindowActive) {
			controlColor = appearance.unreadBadgeTextColorActiveWindow;
		} else {
			controlColor = appearance.unreadBadgeTextColorInactiveWindow;
		} // isWindowActive
	}

	NSDictionary *attributes = @{NSForegroundColorAttributeName : controlColor, NSFontAttributeName : controlFont};

	NSAttributedString *stringToDraw = [NSAttributedString attributedStringWithString:messageCountString attributes:attributes];

	return stringToDraw;
}

- (NSRect)messageCountBadgeRectWithText:(NSAttributedString *)stringToDraw
{
	TVCServerListAppearance *appearance = self.serverList.userInterfaceObjects;

	CGFloat messageCountWidth = (stringToDraw.size.width + (appearance.unreadBadgePadding * 2.0));

	NSRect badgeFrame = NSMakeRect(0.0, 0.0, messageCountWidth, appearance.unreadBadgeHeight);

	CGFloat minimumWidth = appearance.unreadBadgeMinimumWidth;

	if (badgeFrame.size.width < minimumWidth) {
		CGFloat widthDiff  = (minimumWidth - badgeFrame.size.width);

		badgeFrame.size.width += widthDiff;

		badgeFrame.origin.x -= widthDiff;
	}

	return badgeFrame;
}

- (void)drawMessageCountBadge:(NSAttributedString *)stringToDraw inRect:(NSRect)rectToDraw isHighlight:(BOOL)isHighlight isSelected:(BOOL)isSelected
{
	TVCMainWindow *mainWindow = self.mainWindow;

	BOOL isWindowActive = mainWindow.isActiveForDrawing;

	TVCServerListAppearance *appearance = mainWindow.serverList.userInterfaceObjects;

	BOOL isDrawingOnMavericks = (appearance.isModernAppearance == NO);

	/* Create image that we will draw into. If we are drawing for Mavericks,
	 then the frame of our image is one point greater because we draw a shadow. */
	NSImage *badgeImage = nil;

	NSRect badgeFrame = NSZeroRect;

	if (isDrawingOnMavericks) {
		badgeFrame = NSMakeRect(0.0, 1.0, NSWidth(rectToDraw), NSHeight(rectToDraw));

		badgeImage = [NSImage newImageWithSize:NSMakeSize(NSWidth(rectToDraw), (NSHeight(rectToDraw) + 1.0))];
	} else {
		badgeFrame = NSMakeRect(0.0, 0.0, NSWidth(rectToDraw), NSHeight(rectToDraw));

		badgeImage = [NSImage newImageWithSize:NSMakeSize(NSWidth(rectToDraw),  NSHeight(rectToDraw))];
	} // isDrawingOnMavericks

	[badgeImage lockFocus];

	/* Draw the background color. */
	NSColor *backgroundColor = nil;

	if (isSelected) {
		if (isWindowActive) {
			backgroundColor = appearance.unreadBadgeSelectedBackgroundColorActiveWindow;
		} else {
			backgroundColor = appearance.unreadBadgeSelectedBackgroundColorInactiveWindow;
		} // isWindowActive
	} else if (isHighlight) {
		NSColor *customColor = appearance.unreadBadgeHighlightBackgroundColorByUser;

		if (customColor && [customColor isEqual:[NSColor clearColor]] == NO) {
			backgroundColor = customColor;
		} else {
			if (isWindowActive) {
				backgroundColor = appearance.unreadBadgeHighlightBackgroundColorActiveWindow;
			} else {
				backgroundColor = appearance.unreadBadgeHighlightBackgroundColorInactiveWindow;
			} // isWindowActive
		} // custom color set
	} else {
		if (isWindowActive) {
			backgroundColor = appearance.unreadBadgeBackgroundColorActiveWindow;
		} else {
			backgroundColor = appearance.unreadBadgeBackgroundColorActiveWindow;
		} // isWindowActive
	}

	/* Frame is dropped by 1 point to make room for shadow */
	if (isDrawingOnMavericks) {
		if (isSelected == NO) {
			NSRect shadowFrame = badgeFrame;

			shadowFrame.origin.y -= 1;

			/* The shadow frame is a round rectangle that matches the one
			 being drawn with a 1 point offset below the badge to give the
			 appearance of a drop shadow. */
			NSBezierPath *shadowPath = [NSBezierPath bezierPathWithRoundedRect:shadowFrame xRadius:7.0 yRadius:7.0];

			NSColor *shadowColor = nil;

			if (isWindowActive) {
				shadowColor = appearance.unreadBadgeShadowColorActiveWindow;
			} else {
				shadowColor = appearance.unreadBadgeShadowColorInactiveWindow;
			} // isWindowActive

			[shadowColor set];

			[shadowPath fill];
		} // isSelected
	} // isDrawingOnMavericks

	/* Draw the background of the badge */
	NSBezierPath *badgePath = [NSBezierPath bezierPathWithRoundedRect:badgeFrame xRadius:7.0 yRadius:7.0];

	[backgroundColor set];

	[badgePath fill];

	/* Center the text relative to the badge itself */
	NSPoint badgeTextPoint =
	NSMakePoint((NSMidX(badgeFrame) - (stringToDraw.size.width  / 2.0)),
				(NSMidY(badgeFrame) - (stringToDraw.size.height / 2.0)));

	badgeTextPoint.y += appearance.unreadBadgeTextCenterYOffset;

	/* Perform draw and set image */
	[stringToDraw drawAtPoint:badgeTextPoint];

	[badgeImage unlockFocus];

	self.messageCountBadgeImageView.image = badgeImage;
}

#pragma mark -
#pragma mark Disclosure Triangle

- (void)updateGroupDisclosureTriangle
{
	TVCServerListRowCell *rowCell = self.rowCell;

	NSButton *theButtonParent = nil;

	for (NSView *subview in rowCell.subviews) {
		if ([subview isKindOfClass:[NSButton class]]) {
			theButtonParent = (id)subview;
		}
	}

	if (theButtonParent) {
		[self updateGroupDisclosureTriangle:theButtonParent isSelected:rowCell.isSelected setNeedsDisplay:YES];
	} else {
		self.needsDisplay = YES;
	}
}

- (void)updateGroupDisclosureTriangle:(NSButton *)theButtonParent isSelected:(BOOL)isSelected setNeedsDisplay:(BOOL)setNeedsDisplay
{
	TVCServerListAppearance *appearance = self.mainWindow.serverList.userInterfaceObjects;

	NSButtonCell *theButton = theButtonParent.cell;

	[appearance setOutlineViewDefaultDisclosureTriangle:theButton.image];
	[appearance setOutlineViewAlternateDisclosureTriangle:theButton.alternateImage];

	NSImage *primaryImage = [appearance disclosureTriangleInContext:YES selected:isSelected];
	NSImage *alternateImage = [appearance disclosureTriangleInContext:NO selected:isSelected];

	// If the images are not nullified before setting the new,
	// then NSImageView has some weird behavior on OS X Mountain Lion and
	// OS X Mavericks that causes the images not to draw as intended.
	theButton.image = nil;
	theButton.image = primaryImage;

	theButton.alternateImage = nil;
	theButton.alternateImage = alternateImage;

	if (appearance.isModernAppearance) {
		theButton.highlightsBy = NSNoCellMask;
	} else {
		if (isSelected) {
			theButton.backgroundStyle = NSBackgroundStyleLowered;
		} else {
			theButton.backgroundStyle = NSBackgroundStyleRaised;
		}
	}

	if (setNeedsDisplay) {
		self.needsDisplay = YES;
	}
}

#pragma mark -
#pragma mark Cell Information

- (IRCTreeItem *)cellItem
{
	return self.objectValue;
}

- (__kindof TVCServerListRowCell *)rowCell
{
	return (id)self.superview;
}

- (TVCServerList *)serverList
{
	return self.mainWindow.serverList;
}

- (NSInteger)rowIndex
{
	return [self.serverList rowForItem:self.cellItem];
}

- (NSDictionary<NSString *, id> *)drawingContext
{
	TVCMainWindow *mainWindow = self.mainWindow;

	TVCServerList *serverList = mainWindow.serverList;

	IRCTreeItem *cellItem = self.cellItem;

	NSInteger rowIndex = [serverList rowForItem:cellItem];

	return @{
		 @"isActive"			: @(cellItem.isActive),
		 @"isActiveWindow"		: @(mainWindow.isActiveForDrawing),
		 @"isGroupItem"			: @([self isKindOfClass:[TVCServerListCellGroupItem class]]),
		 @"isInverted"			: @(mainWindow.usingDarkAppearance),
		 @"isSelected"			: @([serverList isRowSelected:rowIndex]),
		 @"isSelectedFrontmost"	: @([mainWindow isItemSelected:cellItem]),
		 @"rowIndex"			: @(rowIndex)
	};
}

@end

@implementation TVCServerListCellGroupItem
@end

@implementation TVCServerListCellChildItem
@end

#pragma mark -
#pragma mark Row Cell

@implementation TVCServerListRowCell

- (void)viewWillMoveToWindow:(nullable NSWindow *)newWindow
{
	[super viewWillMoveToWindow:newWindow];

	self.disableQuirks = TEXTUAL_RUNNING_ON(10.14, Mojave);
}

- (void)drawDraggingDestinationFeedbackInRect:(NSRect)dirtyRect
{
	; // Do nothing for this...
}

- (void)setSelected:(BOOL)selected
{
	super.selected = selected;

	[self postSelectionChangeNeedsDisplay];
}

- (void)postSelectionChangeNeedsDisplay
{
	if (self.disableQuirks) {
		return;
	}

	if (self.isSelected)
	{
		TVCMainWindow *mainWindow = self.mainWindow;

		BOOL isWindowActive = mainWindow.isActiveForDrawing;

		if (isWindowActive) {
			self.selectionHighlightStyle = NSTableViewSelectionHighlightStyleRegular;
		} else {
			self.selectionHighlightStyle = NSTableViewSelectionHighlightStyleSourceList;
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
	if (self.isGroupItem) {
		NSButton *disclosureTriangle = nil;

		for (NSView *subview in self.subviews) {
			if ([subview isKindOfClass:[NSButton class]]) {
				disclosureTriangle = (id)subview;
			}
		}

		if (disclosureTriangle) {
			[self.childCell updateGroupDisclosureTriangle:disclosureTriangle isSelected:self.isSelected setNeedsDisplay:YES];

			return;
		}
	}

	self.childCell.needsDisplay = YES;
}

- (void)drawSelectionInRect:(NSRect)dirtyRect
{
	if ([self needsToDrawRect:dirtyRect] == NO) {
		return;
	}

	TVCMainWindow *mainWindow = self.mainWindow;

	BOOL isWindowActive = mainWindow.isActiveForDrawing;

	TVCServerListAppearance *appearance = mainWindow.serverList.userInterfaceObjects;

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
	else // Yosemite or later
	{
		NSImage *selectionImage = nil;

		if (self.isGroupItem) {
			if (isWindowActive) {
				selectionImage = appearance.serverSelectionImageActiveWindow;
			} else {
				selectionImage = appearance.serverSelectionImageInactiveWindow;
			} // isWindowActive
		} else {
			if (isWindowActive) {
				selectionImage = appearance.channelSelectionImageActiveWindow;
			} else {
				selectionImage = appearance.channelSelectionImageInactiveWindow;
			} // isWindowActive
		} // isGroupItem

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

- (void)didAddSubview:(NSView *)subview
{
	if ([subview isKindOfClass:[NSButton class]]) {
		if (self.isGroupItem) {
			[self.childCell updateGroupDisclosureTriangle:(id)subview isSelected:self.isSelected setNeedsDisplay:NO];
		}
	}

	[super didAddSubview:subview];
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

	if (self.mainWindow.usingDarkAppearance) {
		return [NSColor grayColor];
	} else {
		return [NSColor whiteColor];
	}
}

- (__kindof TVCServerListCell * _Nullable)childCell
{
	if (self->_childCell == nil) {
		if (self.numberOfColumns == 0) {
			return nil;
		}

		self->_childCell = [self viewAtColumn:0];
	}

	return self->_childCell;
}

- (BOOL)isGroupItem
{
	return [self isKindOfClass:[TVCServerListGroupRowCell class]];
}

@end

@implementation TVCServerListGroupRowCell
@end

@implementation TVCServerListChildRowCell
@end

NS_ASSUME_NONNULL_END
