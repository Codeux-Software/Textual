/* ********************************************************************* 
                  _____         _               _
                 |_   _|____  _| |_ _   _  __ _| |
                   | |/ _ \ \/ / __| | | |/ _` | |
                   | |  __/>  <| |_| |_| | (_| | |
                   |_|\___/_/\_\\__|\__,_|\__,_|_|

 Copyright (c) 2008 - 2010 Satoshi Nakagawa <psychs AT limechat DOT net>
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

#import "NSViewHelperPrivate.h"
#import "TXGlobalModels.h"
#import "TLOLanguagePreferences.h"
#import "TPCPreferencesLocal.h"
#import "IRCClient.h"
#import "IRCChannel.h"
#import "TVCMainWindow.h"
#import "TVCServerListPrivate.h"
#import "TVCServerListSharedUserInterfacePrivate.h"
#import "TVCServerListCellPrivate.h"

NS_ASSUME_NONNULL_BEGIN

#define _groupItemLeadingConstraintQuirkCorrectedConstraint		5.0

@interface TVCServerListRowCell ()
@property (nonatomic, weak) __kindof TVCServerListCell *childCell;
@property (readonly) BOOL isGroupItem;
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
	id interfaceObjects = self.serverList.userInterfaceObjects;

	if (TEXTUAL_RUNNING_ON(10.10, Yosemite)) {
		[self updateConstraintsForYosemite:interfaceObjects];
	}
}

- (void)updateConstraintsForYosemite:(id)interfaceObjects
{
	NSDictionary *drawingContext = self.drawingContext;

	BOOL isGroupItem = [drawingContext boolForKey:@"isGroupItem"];

	if (isGroupItem) {
		self.textFieldTopConstraint.constant = [interfaceObjects serverCellTextTopOffset];
	} else {
		self.textFieldTopConstraint.constant = [interfaceObjects channelCellTextTopOffset];

		self.messageCountBadgeTopConstraint.constant = [interfaceObjects messageCountBadgeTopOffset];
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
	id interfaceObjects = self.serverList.userInterfaceObjects;

	[self updateDrawing:interfaceObjects];
}

- (void)updateDrawing:(id)interfaceObjects
{
	[self updateTextFieldValue];

	if (TEXTUAL_RUNNING_ON(10.10, Yosemite)) {
		[self updateDrawingForYosemite:interfaceObjects];
	} else {
		[self updateDrawingForMavericks:interfaceObjects];
	}

	[self populateAccessibilityDescriptions];
}

- (void)populateAccessibilityDescriptions
{
	NSDictionary *drawingContext = self.drawingContext;

	BOOL isActive = [drawingContext boolForKey:@"isActive"];
	BOOL isGroupItem = [drawingContext boolForKey:@"isGroupItem"];

	IRCTreeItem *cellItem = self.cellItem;

	if (isGroupItem) {
		if (isActive) {
			[XRAccessibility setAccessibilityValueDescription:TXTLS(@"Accessibility[1001][1]", cellItem.label) forObject:self.cellTextField.cell];
		} else {
			[XRAccessibility setAccessibilityValueDescription:TXTLS(@"Accessibility[1001][2]", cellItem.label) forObject:self.cellTextField.cell];
		}
	} else {
		IRCChannel *channel = (IRCChannel *)cellItem;

		if (channel.isChannel == NO) {
			[XRAccessibility setAccessibilityValueDescription:TXTLS(@"Accessibility[1003]", channel.label) forObject:self.cellTextField.cell];
		} else {
			if (isActive) {
				[XRAccessibility setAccessibilityValueDescription:TXTLS(@"Accessibility[1002][1]", channel.label) forObject:self.cellTextField.cell];
			} else {
				[XRAccessibility setAccessibilityValueDescription:TXTLS(@"Accessibility[1002][2]", channel.label) forObject:self.cellTextField.cell];
			}
		}

		[XRAccessibility setAccessibilityLabel:nil forObject:self.imageView.cell];
	}
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

- (void)updateDrawingForYosemite:(id)interfaceObjects
{
	NSDictionary *drawingContext = self.drawingContext;

	BOOL isActive = [drawingContext boolForKey:@"isActive"];
	BOOL isActiveWindow = [drawingContext boolForKey:@"isActiveWindow"];
	BOOL isGroupItem = [drawingContext boolForKey:@"isGroupItem"];
	BOOL isSelected = [drawingContext boolForKey:@"isSelected"];

	if (isGroupItem == NO) {
		IRCTreeItem *cellItem = self.cellItem;

		IRCChannel *channel = (IRCChannel *)cellItem;

		BOOL isInverted = [TPCPreferences invertSidebarColors];

		NSImage *icon = nil;

		BOOL iconIsTemplate = (isInverted == NO);

		if (channel.isChannel == NO) {
			NSString *queryIcon = [interfaceObjects privateMessageStatusIconFilename:isActive];

			icon = [NSImage imageNamed:queryIcon];
		} else {
			/* When the window is not in focus, when this item is selected, and when we are not
			 using vibrant dark mode; the outline view does not turn our icon to a light variant
			 like it would do if the window was in focus and used as a template. To workaround
			 this oddity that Apple does, we fudge the icon by using another variant of it. */
			if (isActiveWindow == NO) {
				if (isInverted == NO) {
					if (isSelected) {
						iconIsTemplate = NO;

						if (isActive) {
							icon = [NSImage imageNamed:@"channelRoomStatusIconYosemiteDarkActive"];
						} else {
							icon = [NSImage imageNamed:@"channelRoomStatusIconYosemiteDarkInactive"];
						}
					}
				}
			}

			if (icon == nil) {
				if (isActive) {
					if (isInverted) {
						icon = [NSImage imageNamed:@"channelRoomStatusIconYosemiteDarkActive"];
					} else {
						icon = [NSImage imageNamed:@"channelRoomStatusIconYosemiteLightActive"];
					}
				} else {
					if (isInverted) {
						icon = [NSImage imageNamed:@"channelRoomStatusIconYosemiteDarkInactive"];
					} else {
						icon = [NSImage imageNamed:@"channelRoomStatusIconYosemiteLightInactive"];
					}
				}
			}
		}

		icon.template = iconIsTemplate;

		self.imageView.image = icon;
	}

	NSAttributedString *newValue = [self attributedTextFieldValueForYosemite:interfaceObjects inContext:drawingContext];

	self.cellTextField.attributedStringValue = newValue;

	if (isGroupItem == NO) {
		[self populateMessageCountBadge:interfaceObjects inContext:drawingContext];
	}
}

- (void)updateDrawingForMavericks:(id)interfaceObjects
{
	NSDictionary *drawingContext = self.drawingContext;

	BOOL isActive = [drawingContext boolForKey:@"isActive"];
	BOOL isSelected = [drawingContext boolForKey:@"isSelected"];
	BOOL isGroupItem = [drawingContext boolForKey:@"isGroupItem"];

	if (isGroupItem == NO) {
		IRCTreeItem *cellItem = self.cellItem;

		IRCChannel *channel = (IRCChannel *)cellItem;

		BOOL isInverted = [TPCPreferences invertSidebarColors];

		NSImage *icon = nil;

		if (channel.isChannel == NO) {
			NSString *queryIcon = [interfaceObjects privateMessageStatusIconFilename:isActive selected:isSelected];

			icon = [NSImage imageNamed:queryIcon];
		} else {
			if (isActive) {
				if (isInverted) {
					icon = [NSImage imageNamed:@"channelRoomStatusIconMavericksDarkActive"];
				} else {
					icon = [NSImage imageNamed:@"channelRoomStatusIconMavericksLightActive"];
				}
			} else {
				if (isInverted) {
					icon = [NSImage imageNamed:@"channelRoomStatusIconMavericksDarkInactive"];
				} else {
					icon = [NSImage imageNamed:@"channelRoomStatusIconMavericksLightInactive"];
				}
			}
		}

		self.imageView.image = icon;
	}

	NSAttributedString *newValue = [self attributedTextFieldValueForMavericks:interfaceObjects inContext:drawingContext];

	self.cellTextField.attributedStringValue = newValue;

	if (isGroupItem == NO) {
		[self populateMessageCountBadge:interfaceObjects inContext:drawingContext];
	}
}

- (NSAttributedString *)attributedTextFieldValueForMavericks:(id)interfaceObjects inContext:(NSDictionary<NSString *, id> *)drawingContext
{
	BOOL isActive = [drawingContext boolForKey:@"isActive"];
	BOOL isGraphite = [drawingContext boolForKey:@"isGraphite"];
	BOOL isGroupItem = [drawingContext boolForKey:@"isGroupItem"];
	BOOL isInverted = [drawingContext boolForKey:@"isInverted"];
	BOOL isSelected = [drawingContext boolForKey:@"isSelected"];
	BOOL isWindowActive = [drawingContext boolForKey:@"isActiveWindow"];

	NSTextField *textField = self.cellTextField;

	NSAttributedString *stringValue = textField.attributedStringValue;

	NSRange stringValueRange = stringValue.range;

	NSMutableAttributedString *mutableStringValue = [stringValue mutableCopy];

	[mutableStringValue beginEditing];

	if (isGroupItem)
	{
		NSColor *controlColor = nil;

		if (isActive) {
			controlColor = [interfaceObjects serverCellNormalTextColor];
		} else {
			controlColor = [interfaceObjects serverCellDisabledTextColor];
		}

		NSShadow *itemShadow = [NSShadow new];

		itemShadow.shadowOffset = NSMakeSize(0.0, (-1.0));

		if (isInverted) {
			itemShadow.shadowBlurRadius = 1.0;
		}

		if (isSelected) {
			if (isWindowActive) {
				controlColor = [interfaceObjects serverCellSelectedTextColorForActiveWindow];
			} else {
				controlColor = [interfaceObjects serverCellSelectedTextColorForInactiveWindow];
			}

			if (isWindowActive) {
				itemShadow.shadowColor = [interfaceObjects serverCellSelectedTextShadowColorForActiveWindow];
			} else {
				itemShadow.shadowColor = [interfaceObjects serverCellSelectedTextShadowColorForInactiveWindow];
			}
		} else {
			if (isWindowActive) {
				itemShadow.shadowColor = [interfaceObjects serverCellNormalTextShadowColorForActiveWindow];
			} else {
				itemShadow.shadowColor = [interfaceObjects serverCellNormalTextShadowColorForInactiveWindow];
			}
		}

		[mutableStringValue addAttribute:NSShadowAttributeName value:itemShadow range:stringValueRange];

		[mutableStringValue addAttribute:NSForegroundColorAttributeName value:controlColor	range:stringValueRange];

		[mutableStringValue addAttribute:NSFontAttributeName value:[interfaceObjects serverCellFont] range:stringValueRange];
	}
	else
	{
		NSShadow *itemShadow = [NSShadow new];

		itemShadow.shadowBlurRadius = 1.0;

		itemShadow.shadowOffset = NSMakeSize(0.0, (-1.0));

		if (isSelected == NO) {
			itemShadow.shadowColor = [interfaceObjects channelCellNormalTextShadowColor];
		} else {
			if (isInverted == NO) {
				itemShadow.shadowBlurRadius = 2.0;
			}

			if (isWindowActive) {
				if (isGraphite && isWindowActive == NO) {
					itemShadow.shadowColor = [interfaceObjects graphiteTextSelectionShadowColor];
				} else {
					itemShadow.shadowColor = [interfaceObjects channelCellSelectedTextShadowColorForActiveWindow];
				}
			} else {
				itemShadow.shadowColor = [interfaceObjects channelCellSelectedTextShadowColorForInactiveWindow];
			}
		}

		if (isSelected) {
			[mutableStringValue addAttribute:NSFontAttributeName value:[interfaceObjects selectedChannelCellFont] range:stringValueRange];

			if (isWindowActive) {
				[mutableStringValue addAttribute:NSForegroundColorAttributeName value:[interfaceObjects channelCellSelectedTextColorForActiveWindow] range:stringValueRange];
			} else {
				[mutableStringValue addAttribute:NSForegroundColorAttributeName value:[interfaceObjects channelCellSelectedTextColorForInactiveWindow] range:stringValueRange];
			}
		} else {
			if (isActive) {
				[mutableStringValue addAttribute:NSForegroundColorAttributeName value:[interfaceObjects channelCellNormalTextColor] range:stringValueRange];
			} else {
				[mutableStringValue addAttribute:NSForegroundColorAttributeName value:[interfaceObjects channelCellDisabledTextColor] range:stringValueRange];
			}

			[mutableStringValue addAttribute:NSFontAttributeName value:[interfaceObjects normalChannelCellFont] range:stringValueRange];
		}

		[mutableStringValue addAttribute:NSShadowAttributeName value:itemShadow range:stringValueRange];
	}

	[mutableStringValue endEditing];

	return mutableStringValue;
}

- (NSAttributedString *)attributedTextFieldValueForYosemite:(id)interfaceObjects inContext:(NSDictionary<NSString *, id> *)drawingContext
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

	NSRange stringValueRange = stringValue.range;

	NSMutableAttributedString *mutableStringValue = [stringValue mutableCopy];

	[mutableStringValue beginEditing];

	if (isSelected == NO) {
		if (isGroupItem == NO) {
			if (isActive) {
				if (isHighlight) {
					NSColor *customColor = [interfaceObjects userConfiguredMessageCountHighlightedBadgeBackgroundColor];

					if (customColor == nil || [customColor isEqual:[NSColor clearColor]]) {
						if (isWindowActive == NO) {
							customColor = [interfaceObjects channelCellHighlightedItemTextColorForInactiveWindow];
						} else {
							customColor = [interfaceObjects channelCellHighlightedItemTextColorForActiveWindow];
						}
					}

					[mutableStringValue addAttribute:NSForegroundColorAttributeName value:customColor range:stringValueRange];
				} else {
					if (isWindowActive == NO) {
						[mutableStringValue addAttribute:NSForegroundColorAttributeName value:[interfaceObjects channelCellNormalItemTextColorForInactiveWindow] range:stringValueRange];
					} else {
						[mutableStringValue addAttribute:NSForegroundColorAttributeName value:[interfaceObjects channelCellNormalItemTextColorForActiveWindow] range:stringValueRange];
					}
				}
			} else {
				if (isErroneous) {
					if (isWindowActive == NO) {
						[mutableStringValue addAttribute:NSForegroundColorAttributeName value:[interfaceObjects channelCellErroneousItemTextColorForInactiveWindow] range:stringValueRange];
					} else {
						[mutableStringValue addAttribute:NSForegroundColorAttributeName value:[interfaceObjects channelCellErroneousItemTextColorForActiveWindow] range:stringValueRange];
					}
				} else {
					if (isWindowActive == NO) {
						[mutableStringValue addAttribute:NSForegroundColorAttributeName value:[interfaceObjects channelCellDisabledItemTextColorForInactiveWindow] range:stringValueRange];
					} else {
						[mutableStringValue addAttribute:NSForegroundColorAttributeName value:[interfaceObjects channelCellDisabledItemTextColorForActiveWindow] range:stringValueRange];
					}
				}
			}
		} else {
			if (isActive) {
				if (isWindowActive == NO) {
					[mutableStringValue addAttribute:NSForegroundColorAttributeName value:[interfaceObjects serverCellNormalItemTextColorForInactiveWindow] range:stringValueRange];
				} else {
					[mutableStringValue addAttribute:NSForegroundColorAttributeName value:[interfaceObjects serverCellNormalItemTextColorForActiveWindow] range:stringValueRange];
				}
			} else {
				if (isWindowActive == NO) {
					[mutableStringValue addAttribute:NSForegroundColorAttributeName value:[interfaceObjects serverCellDisabledItemTextColorForInactiveWindow] range:stringValueRange];
				} else {
					[mutableStringValue addAttribute:NSForegroundColorAttributeName value:[interfaceObjects serverCellDisabledItemTextColorForActiveWindow] range:stringValueRange];
				}
			}
		}
	} else {
		if (isGroupItem == NO) {
			if (isWindowActive) {
				[mutableStringValue addAttribute:NSForegroundColorAttributeName value:[interfaceObjects channelCellSelectedTextColorForActiveWindow] range:stringValueRange];
			} else {
				[mutableStringValue addAttribute:NSForegroundColorAttributeName value:[interfaceObjects channelCellSelectedTextColorForInactiveWindow] range:stringValueRange];
			}
		} else {
			if (isWindowActive) {
				[mutableStringValue addAttribute:NSForegroundColorAttributeName value:[interfaceObjects serverCellSelectedTextColorForActiveWindow] range:stringValueRange];
			} else {
				[mutableStringValue addAttribute:NSForegroundColorAttributeName value:[interfaceObjects serverCellSelectedTextColorForInactiveWindow] range:stringValueRange];
			}
		}
	}

	if (isGroupItem == NO) {
		[mutableStringValue addAttribute:NSFontAttributeName value:[interfaceObjects channelCellFont] range:stringValueRange];
	} else {
		[mutableStringValue addAttribute:NSFontAttributeName value:[interfaceObjects serverCellFont] range:stringValueRange];
	}

	[mutableStringValue endEditing];

	return mutableStringValue;
}

#pragma mark -
#pragma mark Badge Drawing

- (void)populateMessageCountBadge
{
	id interfaceObjects = self.serverList.userInterfaceObjects;

	NSDictionary *drawingContext = self.drawingContext;

	[self populateMessageCountBadge:interfaceObjects inContext:drawingContext];
}

- (void)populateMessageCountBadge:(id)interfaceObjects inContext:(NSDictionary<NSString *, id> *)drawingContext
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
		if (TEXTUAL_RUNNING_ON(10.10, Yosemite)) {
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

		self.messageCountBadgeTrailingConstraint.constant = [interfaceObjects messageCountBadgeRightMargin];
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

	id interfaceObjects = mainWindow.serverList.userInterfaceObjects;

	NSString *messageCountString = TXFormattedNumber(messageCount);

	NSFont *textFont = [interfaceObjects messageCountBadgeFont];

	NSColor *textColor = nil;

	if (isHighlight) {
		textColor = [interfaceObjects messageCountHighlightedBadgeTextColor];
	} else {
		if (isSelected) {
			if (mainWindow.activeForDrawing) {
				textColor = [interfaceObjects messageCountSelectedBadgeTextColorForActiveWindow];
			} else {
				textColor = [interfaceObjects messageCountSelectedBadgeTextColorForInactiveWindow];
			}
		} else {
			if (mainWindow.activeForDrawing) {
				textColor = [interfaceObjects messageCountNormalBadgeTextColorForActiveWindow];
			} else {
				textColor = [interfaceObjects messageCountNormalBadgeTextColorForInactiveWindow];
			}
		}
	}

	NSDictionary *attributes = @{NSForegroundColorAttributeName : textColor, NSFontAttributeName : textFont};

	NSAttributedString *stringToDraw = [NSAttributedString attributedStringWithString:messageCountString attributes:attributes];

	return stringToDraw;
}

- (NSRect)messageCountBadgeRectWithText:(NSAttributedString *)stringToDraw
{
	id interfaceObjects = self.serverList.userInterfaceObjects;

	CGFloat messageCountWidth = (stringToDraw.size.width + ([interfaceObjects messageCountBadgePadding] * 2.0));

	NSRect badgeFrame = NSMakeRect(0.0, 0.0, messageCountWidth, [interfaceObjects messageCountBadgeHeight]);

	if (badgeFrame.size.width < [interfaceObjects messageCountBadgeMinimumWidth]) {
		CGFloat widthDiff  = ([interfaceObjects messageCountBadgeMinimumWidth] - badgeFrame.size.width);

		badgeFrame.size.width += widthDiff;

		badgeFrame.origin.x -= widthDiff;
	}

	return badgeFrame;
}

- (void)drawMessageCountBadge:(NSAttributedString *)stringToDraw inRect:(NSRect)rectToDraw isHighlight:(BOOL)isHighlight isSelected:(BOOL)isSelected
{
	TVCMainWindow *mainWindow = self.mainWindow;

	id interfaceObjects = mainWindow.serverList.userInterfaceObjects;

	BOOL isDrawingOnMavericks = (TEXTUAL_RUNNING_ON(10.10, Yosemite) == NO);

	/* Create image that we will draw into. If we are drawing for Mavericks,
	 then the frame of our image is one pixel greater because we draw a shadow. */
	NSImage *badgeImage = nil;

	NSRect badgeFrame = NSZeroRect;

	if (isDrawingOnMavericks) {
		badgeFrame = NSMakeRect(0.0, 1.0, NSWidth(rectToDraw), NSHeight(rectToDraw));

		badgeImage = [NSImage newImageWithSize:NSMakeSize(NSWidth(rectToDraw), (NSHeight(rectToDraw) + 1.0))];
	} else {
		badgeFrame = NSMakeRect(0.0, 0.0, NSWidth(rectToDraw), NSHeight(rectToDraw));

		badgeImage = [NSImage newImageWithSize:NSMakeSize(NSWidth(rectToDraw),  NSHeight(rectToDraw))];
	}

	[badgeImage lockFocus];

	/* Draw the background color. */
	NSColor *backgroundColor = nil;

	if (isHighlight) {
		NSColor *customColor = [interfaceObjects userConfiguredMessageCountHighlightedBadgeBackgroundColor];

		if (customColor == nil || [customColor isEqual:[NSColor clearColor]]) {
			if (mainWindow.activeForDrawing == NO) {
				customColor = [interfaceObjects messageCountHighlightedBadgeBackgroundColorForInactiveWindow];
			} else {
				customColor = [interfaceObjects messageCountHighlightedBadgeBackgroundColorForActiveWindow];
			}
		}

		backgroundColor = customColor;
	} else {
		if (isSelected) {
			if (mainWindow.activeForDrawing) {
				backgroundColor = [interfaceObjects messageCountSelectedBadgeBackgroundColorForActiveWindow];
			} else {
				backgroundColor = [interfaceObjects messageCountSelectedBadgeBackgroundColorForInactiveWindow];
			}
		} else {
			if (isDrawingOnMavericks) {
				if ([NSColor currentControlTint] == NSGraphiteControlTint) {
					backgroundColor = [interfaceObjects messageCountBadgeGraphiteBackgroundColor];
				} else {
					backgroundColor = [interfaceObjects messageCountBadgeAquaBackgroundColor];
				}
			} else {
				if (mainWindow.activeForDrawing) {
					backgroundColor = [interfaceObjects messageCountNormalBadgeBackgroundColorForActiveWindow];
				} else {
					backgroundColor = [interfaceObjects messageCountNormalBadgeBackgroundColorForInactiveWindow];
				}
			}
		}
	}

	/* Frame is dropped by 1 to make room for shadow */
	if (isDrawingOnMavericks) {
		if (isSelected == NO) {
			NSRect shadowFrame = badgeFrame;

			shadowFrame.origin.y -= 1;

			/* The shadow frame is a round rectangle that matches the one
			 being drawn with a 1 point offset below the badge to give the
			 appearance of a drop shadow. */
			NSBezierPath *shadowPath = [NSBezierPath bezierPathWithRoundedRect:shadowFrame xRadius:7.0 yRadius:7.0];

			NSColor *shadowColor = [interfaceObjects messageCountBadgeShadowColor];

			[shadowColor set];

			[shadowPath fill];
		}
	}

	/* Draw the background of the badge */
	NSBezierPath *badgePath = [NSBezierPath bezierPathWithRoundedRect:badgeFrame xRadius:7.0 yRadius:7.0];

	[backgroundColor set];

	[badgePath fill];

	/* Center the text relative to the badge itself */
	NSPoint badgeTextPoint =
	NSMakePoint((NSMidX(badgeFrame) - (stringToDraw.size.width  / 2.0)),
				(NSMidY(badgeFrame) - (stringToDraw.size.height / 2.0)));

	badgeTextPoint.y += [interfaceObjects messageCountBadgeTextCenterYOffset];

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
	id interfaceObjects = self.mainWindow.serverList.userInterfaceObjects;

	NSButtonCell *theButton = theButtonParent.cell;

	[interfaceObjects setOutlineViewDefaultDisclosureTriangle:theButton.image];
	[interfaceObjects setOutlineViewAlternateDisclosureTriangle:theButton.alternateImage];

	NSImage *primaryImage = [interfaceObjects disclosureTriangleInContext:YES selected:isSelected];
	NSImage *alternateImage = [interfaceObjects disclosureTriangleInContext:NO selected:isSelected];

	// If the images are not nullified before setting the new,
	// then NSImageView has some weird behavior on OS X Mountain Lion and
	// OS X Mavericks that causes the images not to draw as intended.
	theButton.image = nil;
	theButton.image = primaryImage;

	theButton.alternateImage = nil;
	theButton.alternateImage = alternateImage;

	if (TEXTUAL_RUNNING_ON(10.10, Yosemite)) {
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
		 @"isGraphite"			: @([NSColor currentControlTint] == NSGraphiteControlTint),
		 @"isGroupItem"			: @([self isKindOfClass:[TVCServerListCellGroupItem class]]),
		 @"isInverted"			: @([TPCPreferences invertSidebarColors]),
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
	if (self.isSelected)
	{
		if (TEXTUAL_RUNNING_ON(10.10, Yosemite))
		{
			if ([TPCPreferences invertSidebarColors]) {
				self.selectionHighlightStyle = NSTableViewSelectionHighlightStyleRegular;
			} else {
				self.selectionHighlightStyle = NSTableViewSelectionHighlightStyleSourceList;
			}
		}
		else
		{
			if ([TPCPreferences invertSidebarColors]) {
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

	id interfaceObjects = mainWindow.serverList.userInterfaceObjects;

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

		if (self.isGroupItem) {
			if (mainWindow.isActiveForDrawing) {
				selectionImage = [interfaceObjects serverRowSelectionImageForActiveWindow];
			} else {
				selectionImage = [interfaceObjects serverRowSelectionImageForInactiveWindow];
			}
		} else {
			if (mainWindow.isActiveForDrawing) {
				selectionImage = [interfaceObjects channelRowSelectionImageForActiveWindow];
			} else {
				selectionImage = [interfaceObjects channelRowSelectionImageForInactiveWindow];
			}
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
