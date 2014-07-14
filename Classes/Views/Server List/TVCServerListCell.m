/* ********************************************************************* 
       _____        _               _    ___ ____   ____
      |_   _|___  _| |_ _   _  __ _| |  |_ _|  _ \ / ___|
       | |/ _ \ \/ / __| | | |/ _` | |   | || |_) | |
       | |  __/>  <| |_| |_| | (_| | |   | ||  _ <| |___
       |_|\___/_/\_\\__|\__,_|\__,_|_|  |___|_| \_\\____|

 Copyright (c) 2008 - 2010 Satoshi Nakagawa <psychs AT limechat DOT net>
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

@implementation TVCServerListCell

#pragma mark -
#pragma mark Cell Drawing

- (void)updateDrawing:(NSRect)cellFrame
{
	if ([CSFWSystemInformation featureAvailableToOSXYosemite]) {
		[self updateDrawingForYosemite:cellFrame withUserInterfaceObject:[mainWindowServerList() userInterfaceObjects]];
	} else {
		;
	}
}

- (void)updateDrawingForYosemite:(NSRect)cellFrame withUserInterfaceObject:(id)interfaceObject
{
	/* Define context. */
	NSDictionary *drawingContext = [self drawingContext];
	
	BOOL isActive = [drawingContext boolForKey:@"isActive"];
	
	IRCTreeItem *cellItem = [self cellItem];
	
	/* Maybe update text field value. */
	NSTextField *textField = [self textField];

	NSString *stringValue = [textField stringValue];
	
	NSString *labelValue = [cellItem label];
	
	if ([stringValue isEqualTo:labelValue] == NO) {
		[textField setStringValue:labelValue];
	} else {
		[textField setNeedsDisplay:YES];
	}
	
	/* Maybe update icon image. */
	NSImageView *imageView = [self imageView];
	
	NSImage *icon;
	
	if ([cellItem isPrivateMessage]) {
		icon = [NSImage imageNamed:[interfaceObject privateMessageStatusIconFilename:isActive]];
	} else {
		if (isActive) {
			icon = [NSImage imageNamed:@"channelRoomStatusIcon_Glass_Active"];
		} else {
			icon = [NSImage imageNamed:@"channelRoomStatusIcon_Glass_Inactive"];
		}
	}
	
	if ([mainWindow() isUsingVibrantDarkAppearance]) {
		icon = [icon imageTintedWithColor:[NSColor whiteColor]];
			
		[icon setTemplate:NO];
	} else {
		[icon setTemplate:YES];
	}
	
	[imageView setImage:icon];
}


- (void)updateGroupDisclosureTriangle
{
	NSButton *theButtonParent;
	
	for (id view in [[self superview] subviews]) {
		if ([view isKindOfClass:[NSButton class]]) {
			theButtonParent = view;
		}
	}
	
	if (theButtonParent) {
		[self updateGroupDisclosureTriangle:theButtonParent];
	}
}

- (void)updateGroupDisclosureTriangle:(NSButton *)theButtonParent
{
	NSButtonCell *theButton = [theButtonParent cell];
	
	/* Button, yay! */
	NSInteger rowIndex = [self rowIndex];
	
	BOOL isSelected = [mainWindowServerList() isRowSelected:rowIndex];
	
	/* We keep a reference to the default button. */
	/* These two methods only copy the image if it has never been set before. */
	[TVCServerListSharedUserInterface setOutlineViewDefaultDisclosureTriangle:[theButton image]];
	[TVCServerListSharedUserInterface setOutlineViewAlternateDisclosureTriangle:[theButton alternateImage]];
	
	/* Now the fun can begin. */
	NSImage *primary = [TVCServerListSharedUserInterface disclosureTriangleInContext:YES selected:isSelected];
	NSImage *alterna = [TVCServerListSharedUserInterface disclosureTriangleInContext:NO selected:isSelected];
	
	/* Set image. */
	[theButton setImage:primary];
	[theButton setAlternateImage:alterna];
	
	[theButton setHighlightsBy:NSNoCellMask];
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

	return @{
		@"rowIndex"				: @(rowIndex),
		@"isActive"				: @([self.cellItem isActive]),
		@"isGroupItem"			: @([self.cellItem isClient]),
		@"isInverted"			: @([TPCPreferences invertSidebarColors]),
		@"isRetina"				: @([mainWindow() runningInHighResolutionMode]),
		@"isActiveWindow"		: @([mainWindow() isActiveForDrawing]),
		@"isVibrantDark"		: @([mainWindow() isUsingVibrantDarkAppearance]),
		@"isSelected"			: @([mainWindowServerList() isRowSelected:rowIndex]),
		@"isGraphite"			: @([NSColor currentControlTint] == NSGraphiteControlTint)
	};
}

@end

@implementation TVCServerListCellGroupItem
@end

@implementation TVCServerListCellChildItem
@end

@implementation TVCServerListRowCell

- (NSTableViewSelectionHighlightStyle)selectionHighlightStyle
{
	if ([CSFWSystemInformation featureAvailableToOSXYosemite]) {
		if ([mainWindow() isUsingVibrantDarkAppearance]) {
			return NSTableViewSelectionHighlightStyleRegular;
		} else {
			return NSTableViewSelectionHighlightStyleSourceList;
		}
	} else {
		return NSTableViewSelectionHighlightStyleSourceList;
	}
}

- (void)drawSelectionInRect:(NSRect)dirtyRect
{
	if ([self needsToDrawRect:dirtyRect]) {
		id userInterfaceObjects = [mainWindowServerList() userInterfaceObjects];
		
		NSColor *selectionColor;
		
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
}

- (void)didAddSubview:(NSView *)subview
{
	if ([subview isKindOfClass:[NSButton class]]) {
		id firstObject = self.subviews[0];
	
		if ([firstObject isKindOfClass:[TVCServerListCellGroupItem class]]) {
			TVCServerListCellGroupItem *groupItem = firstObject;
			
			[groupItem updateGroupDisclosureTriangle:(id)subview];
		}
	}
	
	[super didAddSubview:subview];
}

- (BOOL)isEmphasized
{
	return YES;
}

@end

@implementation TVCServerLisCellTextFieldInterior

- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView
{
	if ([CSFWSystemInformation featureAvailableToOSXYosemite]) {
		/* Build draw context for border of text field. When we draw the text field,
		 we will also render the unread count badge with it. */
		TVCServerListCell *parentCell = [self parentCell];
		
		NSDictionary *drawingContext = [parentCell drawingContext];
		
		BOOL isWindowInactive = [drawingContext boolForKey:@"isInactiveWindow"];
		BOOL isGroupItem = [drawingContext boolForKey:@"isGroupItem"];
		BOOL isSelected = [drawingContext boolForKey:@"isSelected"];
		
		id interfaceObjects = [mainWindowServerList() userInterfaceObjects];
		
		/* If we are a client, then there will be no badged. */
		if (isGroupItem == NO) {
			/* Gather information about this badge draw. */
			IRCChannel *channelPointer = (id)[parentCell cellItem];
			
			BOOL drawMessageBadge = (isSelected == NO || (isWindowInactive && isSelected));
			
			NSInteger channelTreeUnreadCount = [channelPointer treeUnreadCount];
			NSInteger nicknameHighlightCount = [channelPointer nicknameHighlightCount];
			
			BOOL isHighlight = (nicknameHighlightCount >= 1);
			
			if (channelPointer.config.showTreeBadgeCount == NO) {
				if ([CSFWSystemInformation featureAvailableToOSXYosemite]) {
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
				/* Get the string being draw. */
				NSAttributedString *mcstring = [self messageCountBadgeText:channelTreeUnreadCount selected:isSelected];
				
				/* Get the rect being drawn. */
				NSRect badgeRect = [self messageCountBadgeRect:cellFrame withText:mcstring];
				
				/* Draw the badge. */
				[self drawMessageCountBadge:mcstring inCell:badgeRect isHighlighgt:isHighlight isSelected:isSelected];
				
				/* Trim our text field to make room for the newly drawn badge. */
				cellFrame.size.width -= (badgeRect.size.width + [interfaceObjects channelCellTextFieldWithBadgeRightMargin]);
			}
		}
		
		[self drawInteriorWithFrameForYosemite:cellFrame withUserInterfaceObject:interfaceObjects];
	} else {
		[super drawWithFrame:cellFrame inView:controlView];
	}
}

#pragma mark -
#pragma mark Badge Drawing

- (NSAttributedString *)messageCountBadgeText:(NSInteger)messageCount selected:(BOOL)isSelected
{
	NSString *messageCountString = TXFormattedNumber(messageCount);
	
	id interfaceObjects = [mainWindowServerList() userInterfaceObjects];
	
	NSColor *textColor = nil;
	
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
	
	NSDictionary *attributes = @{NSForegroundColorAttributeName : textColor, NSFontAttributeName : [interfaceObjects messageCountBadgeFont]};
	
	NSAttributedString *mcstring = [NSAttributedString stringWithBase:messageCountString attributes:attributes];
	
	return mcstring;
}

- (NSRect)messageCountBadgeRect:(NSRect)cellFrame withText:(NSAttributedString *)mcstring
{
	id interfaceObjects = [mainWindowServerList() userInterfaceObjects];
	
	NSInteger messageCountWidth = (mcstring.size.width + ([interfaceObjects messageCountBadgePadding] * 2));
	
	NSRect badgeFrame = NSMakeRect((NSMaxX(cellFrame) - ([interfaceObjects messageCountBadgeRightMargin] + messageCountWidth)),
								   (NSMidY(cellFrame) - ([interfaceObjects messageCountBadgeHeight] / 2.0)),
								   messageCountWidth,    [interfaceObjects messageCountBadgeHeight]);
	
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
	NSBezierPath *badgePath = nil;
	
	id interfaceObjects = [mainWindowServerList() userInterfaceObjects];

	/* Draw the background color. */
	NSColor *backgroundColor = nil;
	
	if (isHighlight && (( [mainWindow() isUsingVibrantDarkAppearance]			&& [mainWindow() isActiveForDrawing]) ||
						 ([mainWindow() isUsingVibrantDarkAppearance] == NO)))
	{
		if ([mainWindow() isActiveForDrawing]) {
			backgroundColor = [interfaceObjects messageCountHighlightedBadgeBackgroundColorForActiveWindow];
		} else {
			backgroundColor = [interfaceObjects messageCountHighlightedBadgeBackgroundColorForInactiveWindow];
		}
	} else {
		if (isSelected) {
			if ([mainWindow() isActiveForDrawing]) {
				backgroundColor = [interfaceObjects messageCountSelectedBadgeBackgroundColorForActiveWindow];
			} else {
				backgroundColor = [interfaceObjects messageCountSelectedBadgeBackgroundColorForInactiveWindow];
			}
		} else {
			if ([mainWindow() isActiveForDrawing]) {
				backgroundColor = [interfaceObjects messageCountNormalBadgeBackgroundColorForActiveWindow];
			} else {
				backgroundColor = [interfaceObjects messageCountNormalBadgeBackgroundColorForInactiveWindow];
			}
		}
	}
	
	badgePath = [NSBezierPath bezierPathWithRoundedRect:badgeFrame
												xRadius:([interfaceObjects messageCountBadgeHeight] / 2.0)
												yRadius:([interfaceObjects messageCountBadgeHeight] / 2.0)];
	
	[backgroundColor set];
	
	[badgePath fill];
	
	/* Center the text relative to the badge itself. */
	NSPoint badgeTextPoint;
	
	badgeTextPoint = NSMakePoint((NSMidX(badgeFrame) - (mcstring.size.width  / 2.0)),
								 (NSMidY(badgeFrame) - (mcstring.size.height / 2.0)));
	
	/* Gotta be pixel (point?) perfect. */
	if ([mainWindow() runningInHighResolutionMode]) {
		badgeTextPoint.y += 0.5;
	}
	
	/* The actual draw. */
	[mcstring drawAtPoint:badgeTextPoint];
}

#pragma mark -
#pragma mark Interior Drawing

- (void)drawInteriorWithFrameForYosemite:(NSRect)cellFrame withUserInterfaceObject:(id)interfaceObject
{
	/* Gather basic context information. */
	TVCServerListCell *parentCell = [self parentCell];
	
	NSDictionary *drawingContext = [parentCell drawingContext];
	
	BOOL isWindowActive = [drawingContext boolForKey:@"isActiveWindow"];
	BOOL isVibrantDark = [drawingContext boolForKey:@"isVibrantDark"];
	BOOL isGroupItem = [drawingContext boolForKey:@"isGroupItem"];
	BOOL isSelected = [drawingContext boolForKey:@"isSelected"];
	BOOL isActive = [drawingContext boolForKey:@"isActive"];
	
	BOOL isHighlight = NO;
	BOOL isErroneous = NO;
	
	IRCTreeItem *rawPointer = [parentCell cellItem];
	
	/* Gather channel specific context information. */
	IRCChannel *channelPointer = nil;
	
	if (isGroupItem == NO) {
		channelPointer = (id)rawPointer;
		
		isErroneous =  [channelPointer errorOnLastJoinAttempt];
		isHighlight = ([channelPointer nicknameHighlightCount] > 0);
	}
	
	/* Update attributed string. */
	NSAttributedString *stringValue = [self attributedStringValue];
	
	NSMutableAttributedString *mutableStringValue = [stringValue mutableCopy];
	
	NSRange stringLengthRange = NSMakeRange(0, [mutableStringValue length]);
	
	[mutableStringValue beginEditing];
	
	if (isSelected == NO) {
		if (isGroupItem == NO) {
			if (isActive) {
				if (isHighlight) {
					if (isWindowActive == NO) {
						if (isVibrantDark) {
							[mutableStringValue addAttribute:NSForegroundColorAttributeName value:[interfaceObject channelCellNormalItemTextColorForInactiveWindow] range:stringLengthRange];
						} else {
							[mutableStringValue addAttribute:NSForegroundColorAttributeName value:[interfaceObject channelCellHighlightedItemTextColorForInactiveWindow] range:stringLengthRange];
						}
					} else {
						[mutableStringValue addAttribute:NSForegroundColorAttributeName value:[interfaceObject channelCellHighlightedItemTextColorForActiveWindow] range:stringLengthRange];
					}
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
						if (isVibrantDark) {
							[mutableStringValue addAttribute:NSForegroundColorAttributeName value:[interfaceObject channelCellDisabledItemTextColorForInactiveWindow] range:stringLengthRange];
						} else {
							[mutableStringValue addAttribute:NSForegroundColorAttributeName value:[interfaceObject channelCellErroneousItemTextColorForInactiveWindow] range:stringLengthRange];
						}
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
	
	[mutableStringValue endEditing];
	
	/* Draw new attributed string. */
	[mutableStringValue drawInRect:cellFrame];
}

@end
