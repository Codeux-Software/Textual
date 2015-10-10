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

#import "TextualApplication.h"

#define _groupItemLeadingConstraintQuirkCorrectedConstraint		5.0

@implementation TVCServerListCell

#pragma mark -
#pragma mark Cell Drawing

- (void)awakeFromNib
{
	/* On Mountain Lion and maybe earlier, NSOutlineView does not properly honor our 
	 leading constraint on our group item resulting in the text field hugging the 
	 disclosure triangle of the group view. This is a dirty hack that fixes this 
	 by updating our leading constraint. */
	if ([XRSystemInformation isUsingOSXMavericksOrLater] == NO) {
		if ( self.groupItemTextFieldLeadingConstraint) {
			[self.groupItemTextFieldLeadingConstraint setConstant:_groupItemLeadingConstraintQuirkCorrectedConstraint];
		}
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
	[self updateDrawing:[mainWindowServerList() userInterfaceObjects]];
}

- (void)updateDrawing:(id)interfaceObject
{
	[self updateTextFieldValue];
	
	if ([XRSystemInformation isUsingOSXYosemiteOrLater]) {
		[self updateDrawingForYosemite:interfaceObject];
	} else {
		[self updateDrawingForMavericks:interfaceObject];
	}

	[self populateAccessibilityDescriptions];
}

- (void)populateAccessibilityDescriptions
{
	IRCTreeItem *cellItem = [self cellItem];

	NSDictionary *drawingContext = [self drawingContext];

	BOOL isActive = [drawingContext boolForKey:@"isActive"];
	BOOL isGroupItem = [drawingContext boolForKey:@"isGroupItem"];

	if (isGroupItem) {
		if (isActive) {
			[XRAccessibility setAccessibilityValueDescription:TXTLS(@"BasicLanguage[1278][1]", [cellItem label]) forObject:[[self textField] cell]];
		} else {
			[XRAccessibility setAccessibilityValueDescription:TXTLS(@"BasicLanguage[1278][2]", [cellItem label]) forObject:[[self textField] cell]];
		}
	} else {
		if ([cellItem isPrivateMessage]) {
			[XRAccessibility setAccessibilityValueDescription:TXTLS(@"BasicLanguage[1280]", [cellItem label]) forObject:[[self textField] cell]];
		} else {
			if (isActive) {
				[XRAccessibility setAccessibilityValueDescription:TXTLS(@"BasicLanguage[1279][1]", [cellItem label]) forObject:[[self textField] cell]];
			} else {
				[XRAccessibility setAccessibilityValueDescription:TXTLS(@"BasicLanguage[1279][2]", [cellItem label]) forObject:[[self textField] cell]];
			}
		}
	}

	[XRAccessibility setAccessibilityLabel:nil forObject:[[self imageView] cell]];
}

- (void)updateTextFieldValue
{
	/* Maybe update text field value. */
	IRCTreeItem *cellItem = [self cellItem];
	
	NSTextField *textField = [self cellTextField];
	
	NSString *stringValue = [textField stringValue];
	
	NSString *labelValue = [cellItem label];
	
	if ([stringValue isEqualTo:labelValue] == NO) {
		[textField setStringValue:labelValue];
	}
}

- (void)updateDrawingForYosemite:(id)interfaceObject
{
	/* Define context. */
	NSDictionary *drawingContext = [self drawingContext];
	
	BOOL isActive = [drawingContext boolForKey:@"isActive"];
	BOOL isSelected = [drawingContext boolForKey:@"isSelected"];
	BOOL isGroupItem = [drawingContext boolForKey:@"isGroupItem"];
	BOOL isWindowActive = [drawingContext boolForKey:@"isActiveWindow"];
	
	if (isGroupItem == NO) {
		/* Maybe update icon image. */
		IRCTreeItem *cellItem = [self cellItem];
		
		BOOL isVibrantDark = [TVCServerListSharedUserInterface yosemiteIsUsingVibrantDarkMode];
		
		NSImageView *imageView = [self imageView];
		
		NSImage *icon = nil;

		BOOL iconIsTemplate = (isVibrantDark == NO);
		
		if ([cellItem isPrivateMessage]) {
			NSString *queryIcon = [interfaceObject privateMessageStatusIconFilename:isActive];
			
			icon = [NSImage imageNamed:queryIcon];
		} else {
			/* When the window is not in focus, when this item is selected, and when we are not
			 using vibrant dark mode; the outline view does not turn our icon to a light variant
			 like it would do if the window was in focus and used as a template. To workaround
			 this oddity that Apple does, we fudge the icon by using another variant of it. */
			if (isWindowActive == NO) {
				if (isVibrantDark == NO) {
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

			/* Normal icon processing. */
			if (icon == nil) {
				if (isActive) {
					if (isVibrantDark) {
						icon = [NSImage imageNamed:@"channelRoomStatusIconYosemiteDarkActive"];
					} else {
						icon = [NSImage imageNamed:@"channelRoomStatusIconYosemiteLightActive"];
					}
				} else {
					if (isVibrantDark) {
						icon = [NSImage imageNamed:@"channelRoomStatusIconYosemiteDarkInactive"];
					} else {
						icon = [NSImage imageNamed:@"channelRoomStatusIconYosemiteLightInactive"];
					}
				}
			}
		}
		
		[icon setTemplate:iconIsTemplate];

		[imageView setImage:icon];
	}

	/* Update attributed value. */
	NSAttributedString *newValue = [self attributedTextFieldValueForYosemite:interfaceObject inContext:drawingContext];
	
	NSTextField *textField = [self cellTextField];

	[textField setAttributedStringValue:newValue];
	
	/* Maybe update badge. */
	if (isGroupItem == NO) {
		[self populateMessageCountBadge:interfaceObject inContext:drawingContext];
	}
}

- (void)updateDrawingForMavericks:(id)interfaceObject
{
	/* Define context. */
	NSDictionary *drawingContext = [self drawingContext];
	
	BOOL isActive = [drawingContext boolForKey:@"isActive"];
	BOOL isSelected = [drawingContext boolForKey:@"isSelected"];
	BOOL isGroupItem = [drawingContext boolForKey:@"isGroupItem"];
	
	if (isGroupItem == NO) {
		/* Maybe update icon image. */
		IRCTreeItem *cellItem = [self cellItem];
	
		NSImageView *imageView = [self imageView];
		
		NSImage *icon = nil;
		
		BOOL isInverted = [TPCPreferences invertSidebarColors];
		
		if ([cellItem isPrivateMessage]) {
			NSString *queryIcon = [interfaceObject privateMessageStatusIconFilename:isActive selected:isSelected];
			
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
		
		[imageView setImage:icon];
	}
	
	/* Update attributed value. */
	NSAttributedString *newValue = [self attributedTextFieldValueForMavericks:interfaceObject inContext:drawingContext];

	NSTextField *textField = [self cellTextField];

	[textField setAttributedStringValue:newValue];
	
	/* Maybe update badge. */
	if (isGroupItem == NO) {
		[self populateMessageCountBadge:interfaceObject inContext:drawingContext];
	}
}

- (NSAttributedString *)attributedTextFieldValueForMavericks:(id)interfaceObject inContext:(NSDictionary *)drawingContext
{
	/* Gather basic context information. */
	BOOL isWindowActive = [drawingContext boolForKey:@"isActiveWindow"];
	BOOL isGroupItem = [drawingContext boolForKey:@"isGroupItem"];
	BOOL isInverted = [drawingContext boolForKey:@"isInverted"];
	BOOL isGraphite = [drawingContext boolForKey:@"isGraphite"];
	BOOL isSelected = [drawingContext boolForKey:@"isSelected"];
	
	IRCTreeItem *rawPointer = [self cellItem];
	
	/* Update attributed string. */
	NSTextField *textField = [self cellTextField];
	
	NSAttributedString *stringValue = [textField attributedStringValue];
	
	NSMutableAttributedString *mutableStringValue = [stringValue mutableCopy];
	
	NSRange stringLengthRange = NSMakeRange(0, [mutableStringValue length]);
	
	[mutableStringValue beginEditing];
	
	/* Begin building string. */
	if (isGroupItem)
	{
		/* Server item. */
		IRCClient *associatedClient = (id)rawPointer;
		
		/* Pick appropriate font color. */
		NSColor *controlColor = nil;
		
		if ([associatedClient isConnected]) {
			controlColor = [interfaceObject serverCellNormalTextColor];
		} else {
			controlColor = [interfaceObject serverCellDisabledTextColor];
		}
		
		/* Prepare text shadow. */
		NSShadow *itemShadow = [NSShadow new];
		
		[itemShadow setShadowOffset:NSMakeSize(0, -(1.0))];
		
		if (isInverted) {
			[itemShadow setShadowBlurRadius:1.0];
		}
		
		if (isSelected) {
			if (isWindowActive) {
				controlColor = [interfaceObject serverCellSelectedTextColorForActiveWindow];
			} else {
				controlColor = [interfaceObject serverCellSelectedTextColorForInactiveWindow];
			}
			
			if (isWindowActive) {
				[itemShadow setShadowColor:[interfaceObject serverCellSelectedTextShadowColorForActiveWindow]];
			} else {
				[itemShadow setShadowColor:[interfaceObject serverCellSelectedTextShadowColorForInactiveWindow]];
			}
		} else {
			if (isWindowActive) {
				[itemShadow setShadowColor:[interfaceObject serverCellNormalTextShadowColorForActiveWindow]];
			} else {
				[itemShadow setShadowColor:[interfaceObject serverCellNormalTextShadowColorForInactiveWindow]];
			}
		}
		
		/* Set attributes. */
		[mutableStringValue addAttribute:NSShadowAttributeName value:itemShadow range:stringLengthRange];
		
		[mutableStringValue addAttribute:NSForegroundColorAttributeName value:controlColor	range:stringLengthRange];
		
		[mutableStringValue addAttribute:NSFontAttributeName value:[interfaceObject serverCellFont] range:stringLengthRange];
	}
	else
	{
		/* Channel cell. */
		IRCChannel *associatedChannel = (id)rawPointer;
		
		/* Prepare text shadow. */
		NSShadow *itemShadow = [NSShadow new];
		
		[itemShadow setShadowBlurRadius:1.0];
		[itemShadow setShadowOffset:NSMakeSize(0, -(1.0))];
		
		if (isSelected == NO) {
			[itemShadow setShadowColor:[interfaceObject channelCellNormalTextShadowColor]];
		} else {
			if (isInverted == NO) {
				[itemShadow setShadowBlurRadius:2.0];
			}
			
			if (isWindowActive) {
				if (isGraphite && isWindowActive == NO) {
					[itemShadow setShadowColor:[interfaceObject graphiteTextSelectionShadowColor]];
				} else {
					[itemShadow setShadowColor:[interfaceObject channelCellSelectedTextShadowColorForActiveWindow]];
				}
			} else {
				[itemShadow setShadowColor:[interfaceObject channelCellSelectedTextShadowColorForInactiveWindow]];
			}
		}
		
		/* Set attributes. */
		if (isSelected) {
			[mutableStringValue addAttribute:NSFontAttributeName value:[interfaceObject selectedChannelCellFont] range:stringLengthRange];
			
			if (isWindowActive) {
				[mutableStringValue addAttribute:NSForegroundColorAttributeName value:[interfaceObject channelCellSelectedTextColorForActiveWindow] range:stringLengthRange];
			} else {
				[mutableStringValue addAttribute:NSForegroundColorAttributeName value:[interfaceObject channelCellSelectedTextColorForInactiveWindow] range:stringLengthRange];
			}
		} else {
			if ([associatedChannel isActive]) {
				[mutableStringValue addAttribute:NSForegroundColorAttributeName value:[interfaceObject channelCellNormalTextColor] range:stringLengthRange];
			} else {
				[mutableStringValue addAttribute:NSForegroundColorAttributeName value:[interfaceObject channelCellDisabledTextColor] range:stringLengthRange];
			}
			
			[mutableStringValue addAttribute:NSFontAttributeName value:[interfaceObject normalChannelCellFont] range:stringLengthRange];
		}
		
		[mutableStringValue addAttribute:NSShadowAttributeName value:itemShadow range:stringLengthRange];
	}
	
	/* Finish editing. */
	[mutableStringValue endEditing];
	
	/* Draw new attributed string. */
	return mutableStringValue;
}

- (NSAttributedString *)attributedTextFieldValueForYosemite:(id)interfaceObject inContext:(NSDictionary *)drawingContext
{
	/* Gather basic context information. */
	BOOL isWindowActive = [drawingContext boolForKey:@"isActiveWindow"];
	BOOL isGroupItem = [drawingContext boolForKey:@"isGroupItem"];
	BOOL isSelected = [drawingContext boolForKey:@"isSelected"];
	BOOL isActive = [drawingContext boolForKey:@"isActive"];
	
	BOOL isHighlight = NO;
	BOOL isErroneous = NO;
	
	IRCTreeItem *rawPointer = [self cellItem];
	
	/* Gather channel specific context information. */
	IRCChannel *channelPointer = nil;
	
	if (isGroupItem == NO) {
		channelPointer = (id)rawPointer;
		
		isErroneous =  [channelPointer errorOnLastJoinAttempt];
		isHighlight = ([channelPointer nicknameHighlightCount] > 0);
	}
	
	/* Update attributed string. */
	NSTextField *textField = [self cellTextField];
	
	NSAttributedString *stringValue = [textField attributedStringValue];
	
	NSMutableAttributedString *mutableStringValue = [stringValue mutableCopy];
	
	NSRange stringLengthRange = NSMakeRange(0, [mutableStringValue length]);
	
	/* Begin editing. */
	[mutableStringValue beginEditing];
	
	if (isSelected == NO) {
		if (isGroupItem == NO) {
			if (isActive) {
				if (isHighlight) {
					NSColor *customColor = [interfaceObject userConfiguredMessageCountHighlightedBadgeBackgroundColor];

					if (customColor == nil || [customColor isEqual:[NSColor clearColor]]) {
						if (isWindowActive == NO) {
							customColor = [interfaceObject channelCellHighlightedItemTextColorForInactiveWindow];
						} else {
							customColor = [interfaceObject channelCellHighlightedItemTextColorForActiveWindow];
						}
					}

					[mutableStringValue addAttribute:NSForegroundColorAttributeName value:customColor range:stringLengthRange];
				} else {
					if (isWindowActive == NO) {
						[mutableStringValue addAttribute:NSForegroundColorAttributeName value:[interfaceObject channelCellNormalItemTextColorForInactiveWindow] range:stringLengthRange];
					} else {
						[mutableStringValue addAttribute:NSForegroundColorAttributeName value:[interfaceObject channelCellNormalItemTextColorForActiveWindow] range:stringLengthRange];
					}
				}
			} else {
				if (isErroneous) {
					if (isWindowActive == NO) {
						[mutableStringValue addAttribute:NSForegroundColorAttributeName value:[interfaceObject channelCellErroneousItemTextColorForInactiveWindow] range:stringLengthRange];
					} else {
						[mutableStringValue addAttribute:NSForegroundColorAttributeName value:[interfaceObject channelCellErroneousItemTextColorForActiveWindow] range:stringLengthRange];
					}
				} else {
					if (isWindowActive == NO) {
						[mutableStringValue addAttribute:NSForegroundColorAttributeName value:[interfaceObject channelCellDisabledItemTextColorForInactiveWindow] range:stringLengthRange];
					} else {
						[mutableStringValue addAttribute:NSForegroundColorAttributeName value:[interfaceObject channelCellDisabledItemTextColorForActiveWindow] range:stringLengthRange];
					}
				}
			}
		} else {
			if (isActive) {
				if (isWindowActive == NO) {
					[mutableStringValue addAttribute:NSForegroundColorAttributeName value:[interfaceObject serverCellNormalItemTextColorForInactiveWindow] range:stringLengthRange];
				} else {
					[mutableStringValue addAttribute:NSForegroundColorAttributeName value:[interfaceObject serverCellNormalItemTextColorForActiveWindow] range:stringLengthRange];
				}
			} else {
				if (isWindowActive == NO) {
					[mutableStringValue addAttribute:NSForegroundColorAttributeName value:[interfaceObject serverCellDisabledItemTextColorForInactiveWindow] range:stringLengthRange];
				} else {
					[mutableStringValue addAttribute:NSForegroundColorAttributeName value:[interfaceObject serverCellDisabledItemTextColorForActiveWindow] range:stringLengthRange];
				}
			}
		}
	} else {
		if (isGroupItem == NO) {
			if (isWindowActive) {
				[mutableStringValue addAttribute:NSForegroundColorAttributeName value:[interfaceObject channelCellSelectedTextColorForActiveWindow] range:stringLengthRange];
			} else {
				[mutableStringValue addAttribute:NSForegroundColorAttributeName value:[interfaceObject channelCellSelectedTextColorForInactiveWindow] range:stringLengthRange];
			}
		} else {
			if (isWindowActive) {
				[mutableStringValue addAttribute:NSForegroundColorAttributeName value:[interfaceObject serverCellSelectedTextColorForActiveWindow] range:stringLengthRange];
			} else {
				[mutableStringValue addAttribute:NSForegroundColorAttributeName value:[interfaceObject serverCellSelectedTextColorForInactiveWindow] range:stringLengthRange];
			}
		}
	}
	
	/* Finish editing. */
	[mutableStringValue endEditing];
	
	/* Draw new attributed string. */
	return mutableStringValue;
}

#pragma mark -
#pragma mark Badge Drawing

- (void)populateMessageCountBadge
{
	[self populateMessageCountBadge:[mainWindowServerList() userInterfaceObjects] inContext:[self drawingContext]];
}

- (void)populateMessageCountBadge:(id)interfaceObject inContext:(NSDictionary *)drawingContext
{
	BOOL isWindowActive = [drawingContext boolForKey:@"isActiveWindow"];
	BOOL isSelected = [drawingContext boolForKey:@"isSelected"];

	/* Gather information about this badge draw. */
	IRCChannel *channelPointer = (id)[self cellItem];
	
	BOOL drawMessageBadge = (isSelected == NO || (isWindowActive == NO && isSelected));
	
	NSInteger channelTreeUnreadCount = [channelPointer treeUnreadCount];
	NSInteger nicknameHighlightCount = [channelPointer nicknameHighlightCount];
	
	BOOL isHighlight = (nicknameHighlightCount > 0);
	
	if (channelPointer.config.showTreeBadgeCount == NO) {
		if ([XRSystemInformation isUsingOSXYosemiteOrLater]) {
			drawMessageBadge = NO; /* On Yosemite we colorize the channel name itself. */
		} else {
			if (isHighlight) {
				channelTreeUnreadCount = nicknameHighlightCount;
			} else {
				drawMessageBadge = NO;
			}
		}
	}
	
	/* Begin draw if we want to. */
	if (channelTreeUnreadCount > 0 && drawMessageBadge) {
		NSAttributedString *mcstring = [self messageCountBadgeText:channelTreeUnreadCount isSelected:isSelected isHighlight:isHighlight];

		NSRect badgeRect = [self messageCountBadgeRectWithText:mcstring];

		[self drawMessageCountBadge:mcstring inCell:badgeRect isHighlighgt:isHighlight isSelected:isSelected];

		[self.messageCountBadgeTrailingConstraint setConstant:[interfaceObject messageCountBadgeRightMargin]];
		[self.messageCountBadgeWidthConstraint setConstant:NSWidth(badgeRect)];
	} else {
		[self.messageCountBadgeTrailingConstraint setConstant:0.0];
		[self.messageCountBadgeWidthConstraint setConstant:0.0];

		NSImageView *badgeView = [self messageCountBadgeImageView];
		
		[badgeView setImage:nil];
	}
}

- (NSAttributedString *)messageCountBadgeText:(NSInteger)messageCount isSelected:(BOOL)isSelected isHighlight:(BOOL)isHighlight
{
	NSString *messageCountString = TXFormattedNumber(messageCount);
	
	id interfaceObjects = [mainWindowServerList() userInterfaceObjects];
	
	NSFont *textFont = [interfaceObjects messageCountBadgeFont];
	
	NSColor *textColor = nil;
	
	if (isHighlight) {
		textColor = [interfaceObjects messageCountHighlightedBadgeTextColor];
	} else {
		if (isSelected) {
			if ([mainWindow() isActiveForDrawing]) {
				textColor = [interfaceObjects messageCountSelectedBadgeTextColorForActiveWindow];
			} else {
				textColor = [interfaceObjects messageCountSelectedBadgeTextColorForInactiveWindow];
			}
		} else {
			if ([mainWindow() isActiveForDrawing]) {
				textColor = [interfaceObjects messageCountNormalBadgeTextColorForActiveWindow];
			} else {
				textColor = [interfaceObjects messageCountNormalBadgeTextColorForInactiveWindow];
			}
		}
	}
	
	NSDictionary *attributes = @{NSForegroundColorAttributeName : textColor, NSFontAttributeName : textFont};
	
	NSAttributedString *mcstring = [NSAttributedString attributedStringWithString:messageCountString attributes:attributes];
	
	return mcstring;
}

- (NSRect)messageCountBadgeRectWithText:(NSAttributedString *)mcstring
{
	id interfaceObjects = [mainWindowServerList() userInterfaceObjects];
	
	NSInteger messageCountWidth = (mcstring.size.width + ([interfaceObjects messageCountBadgePadding] * 2));
	
	NSRect badgeFrame = NSMakeRect(0.0, 0.0, messageCountWidth, [interfaceObjects messageCountBadgeHeight]);
	
	if (badgeFrame.size.width < [interfaceObjects messageCountBadgeMinimumWidth]) {
		NSInteger widthDiff  = ([interfaceObjects messageCountBadgeMinimumWidth] - badgeFrame.size.width);
		
		badgeFrame.size.width += widthDiff;
		
		badgeFrame.origin.x -= widthDiff;
	}
	
	return badgeFrame;
}

- (void)drawMessageCountBadge:(NSAttributedString *)mcstring inCell:(NSRect)badgeFrame isHighlighgt:(BOOL)isHighlight isSelected:(BOOL)isSelected
{
	/* Begin drawing badge. */
	BOOL isDrawingForMavericks = ([XRSystemInformation isUsingOSXYosemiteOrLater] == NO);
	
	id interfaceObjects = [mainWindowServerList() userInterfaceObjects];

	/* Create image that we will draw into. If we are drawing for Mavericks,
	 then the frame of our image is one pixel greater because we draw a shadow. */
	NSImage *newImage = nil;
	
	NSRect boxFrame = NSZeroRect;
	
	if (isDrawingForMavericks) {
		boxFrame = NSMakeRect(0.0, 1.0, NSWidth(badgeFrame), NSHeight(badgeFrame));
		
		newImage = [NSImage newImageWithSize:NSMakeSize(NSWidth(boxFrame), (NSHeight(boxFrame) + 1.0))];
	} else {
		boxFrame = NSMakeRect(0.0, 0.0, NSWidth(badgeFrame), NSHeight(badgeFrame));
		
		newImage = [NSImage newImageWithSize:NSMakeSize(NSWidth(boxFrame),  NSHeight(boxFrame))];
	}
	
	[newImage lockFocus];
	
	/* Draw the background color. */
	NSColor *backgroundColor = nil;
	
	if (isHighlight) {
		NSColor *customColor = [interfaceObjects userConfiguredMessageCountHighlightedBadgeBackgroundColor];

		if (customColor == nil || [customColor isEqual:[NSColor clearColor]]) {
			if ([mainWindow() isActiveForDrawing] == NO) {
				customColor = [interfaceObjects messageCountHighlightedBadgeBackgroundColorForInactiveWindow];
			} else {
				customColor = [interfaceObjects messageCountHighlightedBadgeBackgroundColorForActiveWindow];
			}
		}

		backgroundColor = customColor;
	} else {
		if (isSelected) {
			if ([mainWindow() isActiveForDrawing]) {
				backgroundColor = [interfaceObjects messageCountSelectedBadgeBackgroundColorForActiveWindow];
			} else {
				backgroundColor = [interfaceObjects messageCountSelectedBadgeBackgroundColorForInactiveWindow];
			}
		} else {
			if (isDrawingForMavericks) {
				if ([NSColor currentControlTint] == NSGraphiteControlTint) {
					backgroundColor = [interfaceObjects messageCountBadgeGraphtieBackgroundColor];
				} else {
					backgroundColor = [interfaceObjects messageCountBadgeAquaBackgroundColor];
				}
			} else {
				if ([mainWindow() isActiveForDrawing]) {
					backgroundColor = [interfaceObjects messageCountNormalBadgeBackgroundColorForActiveWindow];
				} else {
					backgroundColor = [interfaceObjects messageCountNormalBadgeBackgroundColorForInactiveWindow];
				}
			}
		}
	}
	
	/* Frame is dropped by 1 to make room for shadow. */
	if (isDrawingForMavericks) {
		if (isSelected == NO) {
			/* Begin work on shadow frame. */
			NSRect shadowFrame = boxFrame;
			
			/* Change size. */
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
	
	/* Draw the background of the badge. */
	NSBezierPath *badgePath = [NSBezierPath bezierPathWithRoundedRect:boxFrame xRadius:7.0 yRadius:7.0];
	
	[backgroundColor set];
	
	[badgePath fill];
	
	/* Center the text relative to the badge itself. */
	NSPoint badgeTextPoint;
	
	badgeTextPoint = NSMakePoint((NSMidX(boxFrame) - (mcstring.size.width  / 2.0)),
								 (NSMidY(boxFrame) - (mcstring.size.height / 2.0)));
	
	/* Gotta be pixel (point?) perfect. */
	if ([mainWindow() runningInHighResolutionMode]) {
		badgeTextPoint.y -= 0.5;
	}
	
	/* The actual draw. */
	[mcstring drawAtPoint:badgeTextPoint];
	
	/* Set the new image. */
	[newImage unlockFocus];
	
	NSImageView *badgeView = [self messageCountBadgeImageView];
	
	[badgeView setImage:newImage];
}

#pragma mark -
#pragma mark Disclosure Triangle

- (void)updateGroupDisclosureTriangle
{
	NSButton *theButtonParent = nil;
	
	for (id view in [[self superview] subviews]) {
		if ([view isKindOfClass:[NSButton class]]) {
			theButtonParent = view;
		}
	}
	
	if (theButtonParent) {
		NSInteger rowIndex = [self rowIndex];
		
		BOOL isSelected = [mainWindowServerList() isRowSelected:rowIndex];
		
		[self updateGroupDisclosureTriangle:theButtonParent isSelected:isSelected setNeedsDisplay:YES];
	} else {
		[self setNeedsDisplay:YES];
	}
}

- (void)updateGroupDisclosureTriangle:(NSButton *)theButtonParent isSelected:(BOOL)isSelected setNeedsDisplay:(BOOL)setNeedsDisplay
{
	NSButtonCell *theButton = [theButtonParent cell];
	
	/* Button, yay! */
	id interfaceObjects = [mainWindowServerList() userInterfaceObjects];

	/* We keep a reference to the default button. */
	/* These two methods only copy the image if it has never been set before. */
	[interfaceObjects setOutlineViewDefaultDisclosureTriangle:[theButton image]];
	[interfaceObjects setOutlineViewAlternateDisclosureTriangle:[theButton alternateImage]];
	
	/* Now the fun can begin. */
	NSImage *primary = [interfaceObjects disclosureTriangleInContext:YES selected:isSelected];
	NSImage *alterna = [interfaceObjects disclosureTriangleInContext:NO selected:isSelected];
	
	/* Set image. */
	[theButton setImage:nil];
	[theButton setAlternateImage:nil];
	
	[theButton setImage:primary];
	[theButton setAlternateImage:alterna];

	/* Update style of button. */
	if ([XRSystemInformation isUsingOSXYosemiteOrLater]) {
		[theButton setHighlightsBy:NSNoCellMask];
	} else {
		if (isSelected) {
			[theButton setBackgroundStyle:NSBackgroundStyleLowered];
		} else {
			[theButton setBackgroundStyle:NSBackgroundStyleRaised];
		}
	}

	if (setNeedsDisplay) {
		[self setNeedsDisplay:YES];
	}
}

#pragma mark -
#pragma mark Cell Information

- (NSInteger)rowIndex
{
	return [mainWindowServerList() rowForItem:[self cellItem]];
}

- (NSDictionary *)drawingContext
{
	NSInteger rowIndex = [self rowIndex];
	
	IRCTreeItem *cellItem = [self cellItem];

	return @{
		@"rowIndex"				: @(rowIndex),
		@"isActive"				: @([cellItem isActive]),
		@"isGroupItem"			: @([cellItem isClient]),
		@"isInverted"			: @([TPCPreferences invertSidebarColors]),
		@"isRetina"				: @([mainWindow() runningInHighResolutionMode]),
		@"isActiveWindow"		: @([mainWindow() isActiveForDrawing]),
		@"isSelected"			: @([mainWindowServerList() isRowSelected:rowIndex]),
		@"isGraphite"			: @([NSColor currentControlTint] == NSGraphiteControlTint),
		@"isVibrantDark"		: @([TVCServerListSharedUserInterface yosemiteIsUsingVibrantDarkMode])
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
	
	if ([self isGroupItem]) {
		id theButton = nil;
		id theBackground = nil;
		
		for (id subview in subviews) {
			if ([subview isKindOfClass:[TVCServerListCell class]]) {
				theBackground = subview;
			} else if ([subview isKindOfClass:[NSButton class]]) {
				theButton = subview;
			}
		}
		
		if (theBackground) {
			if (theButton) {
				[theBackground updateGroupDisclosureTriangle:theButton isSelected:[self isSelected] setNeedsDisplay:YES];
			} else {
				[theBackground setNeedsDisplay:YES];
			}
		}
	} else {
		for (id subview in subviews) {
			if ([subview isKindOfClass:[TVCServerListCell class]]) {
				[subview setNeedsDisplay:YES];
			}
		}
	}
}

- (void)drawSelectionInRect:(NSRect)dirtyRect
{
	if ([self needsToDrawRect:dirtyRect])
	{
		id userInterfaceObjects = [mainWindowServerList() userInterfaceObjects];
		
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
			
			if ([self isGroupItem]) {
				if ([mainWindow() isActiveForDrawing]) {
					selectionImage = [userInterfaceObjects serverRowSelectionImageForActiveWindow];
				} else {
					selectionImage = [userInterfaceObjects serverRowSelectionImageForInactiveWindow];
				}
			} else {
				if ([mainWindow() isActiveForDrawing]) {
					selectionImage = [userInterfaceObjects channelRowSelectionImageForActiveWindow];
				} else {
					selectionImage = [userInterfaceObjects channelRowSelectionImageForInactiveWindow];
				}
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

- (void)didAddSubview:(NSView *)subview
{
	if ([subview isKindOfClass:[NSButton class]])
	{
		NSArray *subviews = [self subviews];
		
		for (id subviewd in subviews) {
			if ([subviewd isKindOfClass:[TVCServerListCellGroupItem class]]) {
				TVCServerListCellGroupItem *groupItem = subviewd;
				
				[self setIsGroupItem:YES];
				
				[groupItem updateGroupDisclosureTriangle:(id)subview isSelected:[self isSelected] setNeedsDisplay:NO];
			}
		}
	}
	
	[super didAddSubview:subview];
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
