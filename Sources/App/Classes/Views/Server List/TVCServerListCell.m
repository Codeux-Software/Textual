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
#import "TLOLocalization.h"
#import "TPCPreferencesLocal.h"
#import "IRCClient.h"
#import "IRCChannel.h"
#import "TVCMainWindow.h"
#import "TVCServerListAppearancePrivate.h"
#import "TVCServerListPrivate.h"
#import "TVCServerListCellPrivate.h"

NS_ASSUME_NONNULL_BEGIN

@class TVCServerListCellDrawingContext;

@interface TVCServerListRowCell ()
@property (nonatomic, weak) TVCServerList *serverList;
@property (nonatomic, weak) __kindof TVCServerListCell *childCell;
@property (readonly) TVCServerListAppearance *userInterfaceObjects;
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
@property (readonly) BOOL isGroupItem;
@property (readonly) TVCServerList *serverList;
@property (readonly) __kindof TVCServerListRowCell *rowCell;
@property (readonly) TVCServerListAppearance *userInterfaceObjects;
@property (readonly) TVCServerListCellDrawingContext *drawingContext;
@property (readonly) IRCTreeItem *cellItem;
@end

@interface TVCServerListCellDrawingContext : NSObject
@property (nonatomic, assign) BOOL isActive;
@property (nonatomic, assign) BOOL isGroupItem;
@property (nonatomic, assign) BOOL isInverted;
@property (nonatomic, assign) BOOL isSelected;
@property (nonatomic, assign) BOOL isSelectedFrontmost;
@property (nonatomic, assign) BOOL isWindowActive;
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
	TVCServerListAppearance *appearance = self.userInterfaceObjects;

	if (appearance.isModernAppearance) {
		[self updateConstraintsForYosemiteWithAppearance:appearance];
	}
}

- (void)updateConstraintsForYosemiteWithAppearance:(TVCServerListAppearance *)appearance
{
	NSParameterAssert(appearance != nil);

	if (self.isGroupItem) {
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
	TVCServerListCellDrawingContext *drawingContext = self.drawingContext;

	[self updateTextFieldInContext:drawingContext];

	TVCServerListAppearance *appearance = self.userInterfaceObjects;

	if (appearance.isModernAppearance) {
		[self updateDrawingForYosemiteWithAppearance:appearance inContext:drawingContext];
	} else {
		[self updateDrawingForMavericksWithAppearance:appearance inContext:drawingContext];
	}
}

- (void)updateTextFieldInContext:(TVCServerListCellDrawingContext *)drawingContext
{
	NSParameterAssert(drawingContext != nil);

	/* Update string value */
	IRCTreeItem *cellItem = self.cellItem;

	NSString *stringValueNew = cellItem.label;

	NSTextField *textField = self.cellTextField;

	NSString *stringValueOld = textField.stringValue;

	if ([stringValueOld isEqualTo:stringValueNew]) {
		return;
	}

	textField.stringValue = stringValueNew;

	/* Update accessibility */
	BOOL isActive = drawingContext.isActive;
	BOOL isGroupItem = drawingContext.isGroupItem;

	NSTextFieldCell *textFieldCell = textField.cell;

	if (isGroupItem) {
		if (isActive) {
			[XRAccessibility setAccessibilityValueDescription:TXTLS(@"Accessibility[bmy-d2]", stringValueNew) forObject:textFieldCell];
		} else {
			[XRAccessibility setAccessibilityValueDescription:TXTLS(@"Accessibility[tu4-8u]", stringValueNew) forObject:textFieldCell];
		} // isActive
	} else {
		if (((IRCChannel *)cellItem).isChannel == NO) {
			[XRAccessibility setAccessibilityValueDescription:TXTLS(@"Accessibility[9sn-xp]", stringValueNew) forObject:textFieldCell];
		} else {
			if (isActive) {
				[XRAccessibility setAccessibilityValueDescription:TXTLS(@"Accessibility[75f-og]", stringValueNew) forObject:textFieldCell];
			} else {
				[XRAccessibility setAccessibilityValueDescription:TXTLS(@"Accessibility[edc-7o]", stringValueNew) forObject:textFieldCell];
			} // isActive
		} // isChannel

		[XRAccessibility setAccessibilityLabel:nil forObject:self.imageView.cell];
	} // isGroupItem
}

- (void)updateDrawingForYosemiteWithAppearance:(TVCServerListAppearance *)appearance inContext:(TVCServerListCellDrawingContext *)drawingContext
{
	NSParameterAssert(appearance != nil);
	NSParameterAssert(drawingContext != nil);

	BOOL isActive = drawingContext.isActive;
	BOOL isGroupItem = drawingContext.isGroupItem;
	BOOL isSelected = drawingContext.isSelected;
	BOOL isWindowActive = drawingContext.isWindowActive;

	if (isGroupItem == NO) {
		IRCTreeItem *cellItem = self.cellItem;

		IRCChannel *channel = (IRCChannel *)cellItem;

		NSString *iconName = nil;

		BOOL iconIsTemplate = NO;

		if (channel.isChannel) {
			iconName = [appearance statusIconForActiveChannel:isActive selected:isSelected activeWindow:isWindowActive treatAsTemplate:&iconIsTemplate];
		} else {
			iconName = [appearance statusIconForActiveQuery:isActive selected:isSelected activeWindow:isWindowActive treatAsTemplate:&iconIsTemplate];
		} // isChannel

		NSImage *icon = [NSImage imageNamed:iconName];

		icon.template = iconIsTemplate;

		self.imageView.image = icon;
	}

	NSAttributedString *newValue = [self attributedTextFieldValueForYosemiteWithAppearance:appearance inContext:drawingContext];

	self.cellTextField.attributedStringValue = newValue;

	if (isGroupItem == NO) {
		[self populateMessageCountBadgeWithAppearance:appearance inContext:drawingContext];
	}
}

- (void)updateDrawingForMavericksWithAppearance:(TVCServerListAppearance *)appearance inContext:(TVCServerListCellDrawingContext *)drawingContext
{
	NSParameterAssert(appearance != nil);
	NSParameterAssert(drawingContext != nil);

	BOOL isActive = drawingContext.isActive;
	BOOL isWindowActive = drawingContext.isWindowActive;
	BOOL isSelected = drawingContext.isSelected;
	BOOL isGroupItem = drawingContext.isGroupItem;

	if (isGroupItem == NO) {
		IRCTreeItem *cellItem = self.cellItem;

		IRCChannel *channel = (IRCChannel *)cellItem;

		NSString *iconName = nil;

		BOOL iconIsTemplate = NO;

		if (channel.isChannel) {
			iconName = [appearance statusIconForActiveChannel:isActive selected:isSelected activeWindow:isWindowActive treatAsTemplate:&iconIsTemplate];
		} else {
			iconName = [appearance statusIconForActiveQuery:isActive selected:isSelected activeWindow:isWindowActive treatAsTemplate:&iconIsTemplate];
		} // isChannel

		NSImage *icon = [NSImage imageNamed:iconName];

		icon.template = iconIsTemplate;

		self.imageView.image = icon;
	}

	NSAttributedString *newValue = [self attributedTextFieldValueForMavericksWithAppearance:appearance inContext:drawingContext];

	self.cellTextField.attributedStringValue = newValue;

	if (isGroupItem == NO) {
		[self populateMessageCountBadgeWithAppearance:appearance inContext:drawingContext];
	}
}

- (NSAttributedString *)attributedTextFieldValueForMavericksWithAppearance:(TVCServerListAppearance *)appearance inContext:(TVCServerListCellDrawingContext *)drawingContext
{
	NSParameterAssert(appearance != nil);
	NSParameterAssert(drawingContext != nil);

	BOOL isActive = drawingContext.isActive;
	BOOL isGroupItem = drawingContext.isGroupItem;
	BOOL isInverted = drawingContext.isInverted;
	BOOL isSelected = drawingContext.isSelected;
	BOOL isWindowActive = drawingContext.isWindowActive;

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
			controlFont = appearance.serverFontSelected;
		} else {
			controlFont = appearance.serverFont;
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
			controlFont = appearance.channelFontSelected;
		} else {
			controlFont = appearance.channelFont;
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

- (NSAttributedString *)attributedTextFieldValueForYosemiteWithAppearance:(TVCServerListAppearance *)appearance inContext:(TVCServerListCellDrawingContext *)drawingContext
{
	NSParameterAssert(appearance != nil);
	NSParameterAssert(drawingContext != nil);

	BOOL isActive = drawingContext.isActive;
	BOOL isGroupItem = drawingContext.isGroupItem;
	BOOL isSelected = drawingContext.isSelected;
	BOOL isWindowActive = drawingContext.isWindowActive;

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
			controlFont = appearance.serverFontSelected;
		} else {
			controlFont = appearance.serverFont;
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
			controlFont = appearance.channelFontSelected;
		} else {
			controlFont = appearance.channelFont;
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
					controlColor = appearance.channelHighlightTextColorInactiveWindow;
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
	TVCServerListAppearance *appearance = self.userInterfaceObjects;

	TVCServerListCellDrawingContext *drawingContext = self.drawingContext;

	[self populateMessageCountBadgeWithAppearance:appearance inContext:drawingContext];
}

- (void)populateMessageCountBadgeWithAppearance:(TVCServerListAppearance *)appearance inContext:(TVCServerListCellDrawingContext *)drawingContext
{
	NSParameterAssert(appearance != nil);
	NSParameterAssert(drawingContext != nil);

	BOOL isSelected = drawingContext.isSelected;
	BOOL isSelectedFrontmost = drawingContext.isSelectedFrontmost;
	BOOL isWindowActive = drawingContext.isWindowActive;
	BOOL multipleRowsSelected = (self.serverList.numberOfSelectedRows > 1);

	IRCChannel *associatedChannel = (id)self.cellItem;

	BOOL drawMessageBadge = (isSelected == NO ||
							(isSelectedFrontmost == NO && isSelected && multipleRowsSelected) ||
							(isWindowActive == NO && isSelected));

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
		NSAttributedString *stringToDraw = [self messageCountBadgeTextForCount:treeUnreadCount isHighlight:isHighlight withAppearance:appearance inContext:drawingContext];

		NSRect badgeRect = [self messageCountBadgeRectForText:stringToDraw withAppearance:appearance inContext:drawingContext];

		[self drawMessageCountBadgeWithString:stringToDraw inRect:badgeRect isHighlight:isHighlight withAppearance:appearance inContext:drawingContext];

		self.messageCountBadgeTrailingConstraint.constant = appearance.unreadBadgeRightMargin;
		self.messageCountBadgeWidthConstraint.constant = NSWidth(badgeRect);
	} else {
		self.messageCountBadgeTrailingConstraint.constant = 0.0;
		self.messageCountBadgeWidthConstraint.constant = 0.0;

		self.messageCountBadgeImageView.image = nil;
	}
}

- (NSAttributedString *)messageCountBadgeTextForCount:(NSUInteger)messageCount isHighlight:(BOOL)isHighlight withAppearance:(TVCServerListAppearance *)appearance inContext:(TVCServerListCellDrawingContext *)drawingContext
{
	NSParameterAssert(appearance != nil);
	NSParameterAssert(drawingContext != nil);

	BOOL isSelected = drawingContext.isSelected;
	BOOL isWindowActive = drawingContext.isWindowActive;

	NSString *messageCountString = TXFormattedNumber(messageCount);

	NSFont *controlFont = nil;

	if (isSelected) {
		controlFont = appearance.unreadBadgeFontSelected;
	} else {
		controlFont = appearance.unreadBadgeFont;
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

- (NSRect)messageCountBadgeRectForText:(NSAttributedString *)stringToDraw withAppearance:(TVCServerListAppearance *)appearance inContext:(TVCServerListCellDrawingContext *)drawingContext
{
	NSParameterAssert(appearance != nil);
	NSParameterAssert(drawingContext != nil);

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

- (void)drawMessageCountBadgeWithString:(NSAttributedString *)stringToDraw inRect:(NSRect)rectToDraw isHighlight:(BOOL)isHighlight withAppearance:(TVCServerListAppearance *)appearance inContext:(TVCServerListCellDrawingContext *)drawingContext
{
	NSParameterAssert(appearance != nil);
	NSParameterAssert(drawingContext != nil);

	BOOL isDrawingOnMavericks = (appearance.isModernAppearance == NO);
	BOOL isSelected = drawingContext.isSelected;
	BOOL isWindowActive = drawingContext.isWindowActive;

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
	TVCServerListAppearance *appearance = self.userInterfaceObjects;

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

- (BOOL)isGroupItem
{
	return [self isKindOfClass:[TVCServerListCellGroupItem class]];
}

- (__kindof TVCServerListRowCell *)rowCell
{
	return (id)self.superview;
}

- (IRCTreeItem *)cellItem
{
	return self.objectValue;
}

- (TVCServerList *)serverList
{
	return self.rowCell.serverList;
}

- (TVCServerListAppearance *)userInterfaceObjects
{
	return self.rowCell.userInterfaceObjects;
}

- (TVCServerListCellDrawingContext *)drawingContext
{
	TVCServerList *serverList = self.serverList;

	TVCServerListAppearance *appearance = self.userInterfaceObjects;

	IRCTreeItem *cellItem = self.cellItem;

	NSInteger rowIndex = [serverList rowForItem:cellItem];

	TVCMainWindow *mainWindow = self.mainWindow;

	TVCServerListCellDrawingContext *drawingContext = [TVCServerListCellDrawingContext new];

	drawingContext.isActive = cellItem.isActive;
	drawingContext.isGroupItem = self.isGroupItem;
	drawingContext.isInverted = appearance.isDarkAppearance;
	drawingContext.isSelected = [serverList isRowSelected:rowIndex];
	drawingContext.isSelectedFrontmost = [mainWindow isItemSelected:cellItem];
	drawingContext.isWindowActive = mainWindow.isActiveForDrawing;

	return drawingContext;
}

@end

@implementation TVCServerListCellGroupItem
@end

@implementation TVCServerListCellChildItem
@end

@implementation TVCServerListCellDrawingContext
@end

#pragma mark -
#pragma mark Row Cell

@implementation TVCServerListRowCell

- (instancetype)initWithServerList:(TVCServerList *)serverList
{
	if ((self = [super initWithFrame:NSZeroRect])) {
		self.serverList = serverList;

		return self;
	}

	return nil;
}

- (void)viewWillMoveToWindow:(nullable NSWindow *)newWindow
{
	[super viewWillMoveToWindow:newWindow];

	self.disableQuirks = TEXTUAL_RUNNING_ON_MOJAVE;
}

- (void)drawDraggingDestinationFeedbackInRect:(NSRect)dirtyRect
{
	; // Do nothing for this...
}

- (void)setSelected:(BOOL)selected
{
	super.selected = selected;

	if (selected == NO && self.invalidatingBackgroundForSelection) {
		return;
	}

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
		TVCServerListAppearance *appearance = self.userInterfaceObjects;

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

	BOOL isWindowActive = self.mainWindow.isActiveForDrawing;

	TVCServerListAppearance *appearance = self.userInterfaceObjects;

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
	TVCServerListAppearance *appearance = self.userInterfaceObjects;

	BOOL emphasized = NO;

	if (self.isGroupItem) {
		emphasized = appearance.serverRowEmphasized;
	} else {
		emphasized = appearance.channelRowEmphasized;
	}

	NSWindow *window = self.window;

	return (emphasized &&
			(window == nil || window.isKeyWindow));
}

- (nullable NSColor *)fontSmoothingBackgroundColor
{
	if (self.disableQuirks) {
		return nil;
	}

	TVCServerListAppearance *appearance = self.userInterfaceObjects;

	if (appearance.isDarkAppearance) {
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

- (TVCServerListAppearance *)userInterfaceObjects
{
	return self.serverList.userInterfaceObjects;
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
