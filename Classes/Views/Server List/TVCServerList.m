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

@implementation TVCServerList

#pragma mark -
#pragma mark Additions/Removal

- (void)addItemToList:(NSInteger)index inParent:(id)parent
{
	NSAssertReturn(index >= 0);

	[self insertItemsAtIndexes:[NSIndexSet indexSetWithIndex:index]
					  inParent:parent
				 withAnimation:(NSTableViewAnimationEffectFade | NSTableViewAnimationSlideRight)];

	if (parent) {
		[self reloadItem:parent];
	}
}

- (void)removeItemFromList:(id)oldObject
{
	/* Get the row. */
	NSInteger rowIndex = [self rowForItem:oldObject];

	NSAssertReturn(rowIndex >= 0);

	/* Do we have a parent? */
	id parentItem = [self parentForItem:oldObject];

	if ([parentItem isKindOfClass:[IRCClient class]]) {
		/* We have a parent, get the index of the child. */
		NSArray *childrenItems = [self rowsFromParentGroup:parentItem];

		rowIndex = [childrenItems indexOfObject:oldObject];
	} else {
		/* We are the parent. Get our own index. */
		NSArray *groupItems = [self groupItems];
		
		rowIndex = [groupItems indexOfObject:oldObject];
	}

	/* Remove object. */
	NSIndexSet *indexSet = [NSIndexSet indexSetWithIndex:rowIndex];

	[self removeItemsAtIndexes:indexSet
					  inParent:parentItem
				 withAnimation:(NSTableViewAnimationEffectFade | NSTableViewAnimationSlideLeft)];

	if (parentItem) {
		[self reloadItem:parentItem];
	}
}

#pragma mark -
#pragma mark Drawing Updates

- (void)reloadAllDrawings
{
	for (NSInteger i = 0; i < [self numberOfRows]; i++) {
		[self updateDrawingForRow:i];
	}
	
	[self setNeedsDisplay:YES];
}

- (void)updateDrawingForItem:(IRCTreeItem *)cellItem
{
	PointerIsEmptyAssert(cellItem);
	
	NSInteger rowIndex = [self rowForItem:cellItem];
	
	NSAssertReturn(rowIndex >= 0);
	
	[self updateDrawingForRow:rowIndex];
}

- (void)updateDrawingForRow:(NSInteger)rowIndex
{
	NSAssertReturn(rowIndex >= 0);
	
	id rowView = [self viewAtColumn:0 row:rowIndex makeIfNecessary:NO];
	
	BOOL isGroupItem = [rowView isKindOfClass:[TVCServerListCellGroupItem class]];
	BOOL isChildItem = [rowView isKindOfClass:[TVCServerListCellChildItem class]];
	
	if (isGroupItem || isChildItem) {
		NSRect cellFrame = [self frameOfCellAtColumn:0 row:rowIndex];
		
		[rowView updateDrawing:cellFrame];
		
		if (isGroupItem) {
			[rowView updateGroupDisclosureTriangle];
		}
	}
}

- (BOOL)allowsVibrancy
{
	return YES;
}

- (NSScrollView *)scrollView
{
	return [self enclosingScrollView];
}

- (void)drawBackgroundInClipRect:(NSRect)clipRect
{
	if ([self needsToDrawRect:clipRect]) {
		id userInterfaceObjects = [self userInterfaceObjects];
		
		NSColor *backgroundColor = [userInterfaceObjects serverListBackgroundColor];
		
		if (backgroundColor) {
			[backgroundColor set];
			
			NSRectFill(clipRect);
		} else {
			[super drawBackgroundInClipRect:clipRect];
		}
	}
}

- (id)userInterfaceObjects
{
	if ([CSFWSystemInformation featureAvailableToOSXYosemite]) {
		if ([TVCServerListSharedUserInterface yosemiteIsUsingVibrantDarkMode] == NO) {
			return [TVCServerListLightYosemiteUserInterface class];
		} else {
			return [TVCServerListDarkYosemiteUserInterface class];
		}
	} else {
		return nil;
	}
}

- (void)updateBackgroundColor
{
	if ([CSFWSystemInformation featureAvailableToOSXYosemite]) {
		[mainWindow() setTemporarilyDisablePreviousSelectionUpdates:YES];
		[mainWindow() setTemporarilyIgnoreOutlineViewSelectionChanges:YES];
		
		/* When changing from vibrant light to vibrant dark we must deselect all
		 rows, change the appearance, and reselect them. If we don't do this, the
		 drawing that NSOutlineView uses for drawling vibrant light rows will stick
		 forever leaving blue on selected rows no matter how hard we try to draw. */
		NSIndexSet *selectedRows = [self selectedRowIndexes];
		
		[self deselectAll:nil];
		
		if ([TPCPreferences invertSidebarColors]) {
			/* Source List style of NSOutlineView will actually ignore this appearance… that's
			 why we have self.visualEffectView behind it. However, we still set the appearance
			 so that the menu that inherits form it is dark. */
			[self setAppearance:[NSAppearance appearanceNamed:NSAppearanceNameVibrantDark]];
			
			[self.visualEffectView setAppearance:[NSAppearance appearanceNamed:NSAppearanceNameVibrantDark]];
		} else {
			[self setAppearance:[NSAppearance appearanceNamed:NSAppearanceNameVibrantLight]];
			
			[self.visualEffectView setAppearance:[NSAppearance appearanceNamed:NSAppearanceNameVibrantLight]];
		}
		
		[self selectRowIndexes:selectedRows byExtendingSelection:NO];
		
		[mainWindow() setTemporarilyDisablePreviousSelectionUpdates:NO];
		[mainWindow() setTemporarilyIgnoreOutlineViewSelectionChanges:NO];
	}
}

#pragma mark -
#pragma mark Events

- (NSMenu *)menuForEvent:(NSEvent *)e
{
	NSPoint p = [self convertPoint:[e locationInWindow] fromView:nil];

	NSInteger i = [self rowAtPoint:p];

	if (i >= 0 && NSDissimilarObjects(i, [self selectedRow])) {
		[self selectItemAtIndex:i];
	} else if (i == -1) {
		return [menuController() addServerMenu];
	}

	return [self menu];
}

- (void)rightMouseDown:(NSEvent *)theEvent
{
	TVCMainWindowNegateActionWithAttachedSheet();
	
	[super rightMouseDown:theEvent];
}

- (void)keyDown:(NSEvent *)e
{
	if (self.keyDelegate) {
		switch ([e keyCode]) {
			case 123 ... 126:
			case 116:
			case 121:
			{
				break;
			}
			default:
			{
				if ([self.keyDelegate respondsToSelector:@selector(serverListKeyDown:)]) {
					[self.keyDelegate serverListKeyDown:e];
				}
				
				break;
			}
		}
	}
}

@end

#pragma mark -
#pragma mark User Interface Shared Elements

@implementation TVCServerListSharedUserInterface

+ (BOOL)yosemiteIsUsingVibrantDarkMode
{
	NSVisualEffectView *visualEffectView = [mainWindowServerList() visualEffectView];
	
	NSAppearance *currentDesign = [visualEffectView appearance];
	
	NSString *name = [currentDesign name];
	
	if ([name hasPrefix:NSAppearanceNameVibrantDark]) {
		return YES;
	} else {
		return NO;
	}
}

+ (NSColor *)serverListBackgroundColor
{
	id userInterfaceObjects = [mainWindowServerList() userInterfaceObjects];
	
	if ([mainWindow() isInactiveForDrawing]) {
		return [userInterfaceObjects serverListBackgroundColorForInactiveWindow];
	} else {
		return [userInterfaceObjects serverListBackgroundColorForActiveWindow];
	}
}

static NSImage *_outlineViewDefaultDisclosureTriangle = nil;
static NSImage *_outlineViewAlternateDisclosureTriangle = nil;

+ (void)setOutlineViewDefaultDisclosureTriangle:(NSImage *)image
{
	if (_outlineViewDefaultDisclosureTriangle == nil) {
		_outlineViewDefaultDisclosureTriangle = [image copy];
	}
}

+ (void)setOutlineViewAlternateDisclosureTriangle:(NSImage *)image
{
	if (_outlineViewAlternateDisclosureTriangle == nil) {
		_outlineViewAlternateDisclosureTriangle = [image copy];
	}
}

+ (NSImage *)disclosureTriangleInContext:(BOOL)up selected:(BOOL)selected
{
	if ([CSFWSystemInformation featureAvailableToOSXYosemite]) {
		if ([TVCServerListSharedUserInterface yosemiteIsUsingVibrantDarkMode]) {
			if (up) {
				return [NSImage imageNamed:@"YosemiteDarkServerListViewDisclosureUp"];
			} else {
				return [NSImage imageNamed:@"YosemiteDarkServerListViewDisclosureDown"];
			}
		} else {
			if (up) {
				return _outlineViewDefaultDisclosureTriangle;
			} else {
				return _outlineViewAlternateDisclosureTriangle;
			}
		}
	}
	
	return nil;
}

@end

#pragma mark -
#pragma mark User Interface for Mavericks

@implementation TVCServerListMavericksUserInterface
@end

#pragma mark -
#pragma mark User Interface for Vibrant Light in Yosemite

@implementation TVCServerListLightYosemiteUserInterface

+ (NSString *)privateMessageStatusIconFilename:(BOOL)isActive
{
	if (isActive) {
		return @"VibrantLightServerListViewPrivateMessageUserIconActive";
	} else {
		return @"VibrantLightServerListViewPrivateMessageUserIconInactive";
	}
}

+ (NSColor *)channelCellNormalItemTextColorForActiveWindow
{
	return [NSColor colorWithCalibratedRed:0.232 green:0.232 blue:0.232 alpha:1.0];
}

+ (NSColor *)channelCellNormalItemTextColorForInactiveWindow
{
	return [NSColor colorWithCalibratedRed:0.232 green:0.232 blue:0.232 alpha:1.0];
}

+ (NSColor *)channelCellDisabledItemTextColorForActiveWindow
{
	return [NSColor colorWithCalibratedRed:0.0 green:0.0 blue:0.0 alpha:0.5];
}

+ (NSColor *)channelCellDisabledItemTextColorForInactiveWindow
{
	return [NSColor colorWithCalibratedRed:0.0 green:0.0 blue:0.0 alpha:0.5];
}

+ (NSColor *)channelCellHighlightedItemTextColorForActiveWindow
{
	return [NSColor colorWithCalibratedRed:0.0 green:0.414 blue:0.117 alpha:1.0];
}

+ (NSColor *)channelCellHighlightedItemTextColorForInactiveWindow
{
	return [NSColor colorWithCalibratedRed:0.0 green:0.414 blue:0.117 alpha:1.0];
}

+ (NSColor *)channelCellErroneousItemTextColorForActiveWindow
{
	return [NSColor colorWithCalibratedRed:0.8203 green:0.0585 blue:0.0585 alpha:1.0];
}

+ (NSColor *)channelCellErroneousItemTextColorForInactiveWindow
{
	return [NSColor colorWithCalibratedRed:0.8203 green:0.0585 blue:0.0585 alpha:1.0];
}

+ (NSColor *)channelCellSelectedTextColorForActiveWindow
{
	return [NSColor colorWithCalibratedWhite:1.0 alpha:1.0];
}

+ (NSColor *)channelCellSelectedTextColorForInactiveWindow
{
	return [NSColor colorWithCalibratedWhite:0.0 alpha:0.5];
}

+ (NSColor *)serverCellDisabledItemTextColorForActiveWindow
{
	return [NSColor colorWithCalibratedWhite:0.0 alpha:0.3];
}

+ (NSColor *)serverCellDisabledItemTextColorForInactiveWindow
{
	return [NSColor colorWithCalibratedWhite:0.0 alpha:0.3];
}

+ (NSColor *)serverCellNormalItemTextColorForActiveWindow
{
	return [NSColor colorWithCalibratedWhite:0.0 alpha:0.5];
}

+ (NSColor *)serverCellNormalItemTextColorForInactiveWindow
{
	return [NSColor colorWithCalibratedWhite:0.0 alpha:0.5];
}

+ (NSColor *)serverCellSelectedTextColorForActiveWindow
{
	return [NSColor colorWithCalibratedWhite:1.0 alpha:1.0];
}

+ (NSColor *)serverCellSelectedTextColorForInactiveWindow
{
	return [NSColor colorWithCalibratedWhite:0.0 alpha:0.5];
}

+ (NSFont *)messageCountBadgeFont
{
	return [NSFont systemFontOfSize:10.5];
}

+ (NSInteger)messageCountBadgeHeight
{
	return 14.0;
}

+ (NSInteger)messageCountBadgeMinimumWidth
{
	return 22.0;
}

+ (NSInteger)messageCountBadgePadding
{
	return 6.0;
}

+ (NSInteger)messageCountBadgeRightMargin
{
	return 3.0;
}

+ (NSInteger)channelCellTextFieldWithBadgeRightMargin
{
	return 8.0;
}

+ (NSColor *)messageCountNormalBadgeTextColorForActiveWindow
{
	return [NSColor whiteColor];
}

+ (NSColor *)messageCountNormalBadgeTextColorForInactiveWindow
{
	return [NSColor whiteColor];
}

+ (NSColor *)messageCountSelectedBadgeTextColorForActiveWindow
{
	return [NSColor colorWithCalibratedRed:0.232 green:0.232 blue:0.232 alpha:1.0];
}

+ (NSColor *)messageCountSelectedBadgeTextColorForInactiveWindow
{
	return [NSColor colorWithCalibratedRed:0.232 green:0.232 blue:0.232 alpha:1.0];
}

+ (NSColor *)messageCountHighlightedBadgeTextColor
{
	return [NSColor whiteColor];
}

+ (NSColor *)messageCountNormalBadgeBackgroundColorForActiveWindow
{
	return [NSColor colorWithCalibratedRed:0.232 green:0.232 blue:0.232 alpha:0.7];
}

+ (NSColor *)messageCountNormalBadgeBackgroundColorForInactiveWindow
{
	return [NSColor colorWithCalibratedRed:0.232 green:0.232 blue:0.232 alpha:0.7];
}

+ (NSColor *)messageCountSelectedBadgeBackgroundColorForActiveWindow
{
	return [NSColor whiteColor];
}

+ (NSColor *)messageCountSelectedBadgeBackgroundColorForInactiveWindow
{
	return [NSColor whiteColor];
}

+ (NSColor *)messageCountHighlightedBadgeBackgroundColorForActiveWindow
{
	return [NSColor colorWithCalibratedRed:0.0 green:0.414 blue:0.117 alpha:0.7];
}

+ (NSColor *)messageCountHighlightedBadgeBackgroundColorForInactiveWindow
{
	return [NSColor colorWithCalibratedRed:0.0 green:0.414 blue:0.117 alpha:0.7];
}

+ (NSColor *)rowSelectionColorForActiveWindow
{
	return nil; // Use system default.
}

+ (NSColor *)rowSelectionColorForInactiveWindow
{
	return nil; // Use system default.
}

+ (NSColor *)serverListBackgroundColorForInactiveWindow
{
	return [NSColor clearColor]; // -clearColor informs receiver to disregard drawing entirely
}

+ (NSColor *)serverListBackgroundColorForActiveWindow
{
	return [NSColor clearColor];
}

@end

#pragma mark -
#pragma mark User Interface for Vibrant Dark in Yosemite

@implementation TVCServerListDarkYosemiteUserInterface

+ (NSString *)privateMessageStatusIconFilename:(BOOL)isActive
{
	if (isActive) {
		return @"VibrantLightServerListViewPrivateMessageUserIconActive";
	} else {
		return @"VibrantLightServerListViewPrivateMessageUserIconInactive";
	}
}

+ (NSColor *)channelCellNormalItemTextColorForActiveWindow
{
	return [NSColor colorWithCalibratedWhite:0.8 alpha:1.0];
}

+ (NSColor *)channelCellNormalItemTextColorForInactiveWindow
{
	return [NSColor colorWithCalibratedWhite:0.9 alpha:1.0];
}

+ (NSColor *)channelCellDisabledItemTextColorForActiveWindow
{
	return [NSColor colorWithCalibratedWhite:0.4 alpha:1.0];
}

+ (NSColor *)channelCellDisabledItemTextColorForInactiveWindow
{
	return [NSColor colorWithCalibratedWhite:0.6 alpha:1.0];
}

+ (NSColor *)channelCellHighlightedItemTextColorForActiveWindow
{
	return [NSColor colorWithCalibratedRed:0.0 green:0.414 blue:0.117 alpha:1.0];
}

+ (NSColor *)channelCellHighlightedItemTextColorForInactiveWindow
{
	return nil; // This value is ignored on dark mode.
}

+ (NSColor *)channelCellErroneousItemTextColorForActiveWindow
{
	return [NSColor colorWithCalibratedRed:0.850 green:0.0 blue:0.0 alpha:1.0];
}

+ (NSColor *)channelCellErroneousItemTextColorForInactiveWindow
{
	return nil; // This value is ignored on dark mode.
}

+ (NSColor *)channelCellSelectedTextColorForActiveWindow
{
	return [NSColor colorWithCalibratedWhite:0.7 alpha:1.0];
}

+ (NSColor *)channelCellSelectedTextColorForInactiveWindow
{
	return [NSColor colorWithCalibratedWhite:0.2 alpha:1.0];
}

+ (NSColor *)serverCellDisabledItemTextColorForActiveWindow
{
	return [NSColor colorWithCalibratedWhite:0.4 alpha:1.0];
}

+ (NSColor *)serverCellDisabledItemTextColorForInactiveWindow
{
	return [NSColor colorWithCalibratedWhite:0.6 alpha:1.0];
}

+ (NSColor *)serverCellNormalItemTextColorForActiveWindow
{
	return [NSColor colorWithCalibratedWhite:0.8 alpha:1.0];
}

+ (NSColor *)serverCellNormalItemTextColorForInactiveWindow
{
	return [NSColor colorWithCalibratedWhite:0.9 alpha:1.0];
}

+ (NSColor *)serverCellSelectedTextColorForActiveWindow
{
	return [NSColor colorWithCalibratedWhite:0.7 alpha:1.0];
}

+ (NSColor *)serverCellSelectedTextColorForInactiveWindow
{
	return [NSColor colorWithCalibratedWhite:0.2 alpha:1.0];
}

+ (NSFont *)messageCountBadgeFont
{
	return [NSFont systemFontOfSize:10.5];
}

+ (NSInteger)messageCountBadgeHeight
{
	return 14.0;
}

+ (NSInteger)messageCountBadgeMinimumWidth
{
	return 22.0;
}

+ (NSInteger)messageCountBadgePadding
{
	return 6.0;
}

+ (NSInteger)messageCountBadgeRightMargin
{
	return 3.0;
}

+ (NSInteger)channelCellTextFieldWithBadgeRightMargin
{
	return 8.0;
}

+ (NSColor *)messageCountNormalBadgeTextColorForActiveWindow
{
	return [NSColor whiteColor];
}

+ (NSColor *)messageCountNormalBadgeTextColorForInactiveWindow
{
	return [NSColor whiteColor];
}

+ (NSColor *)messageCountSelectedBadgeTextColorForActiveWindow
{
	return [NSColor colorWithCalibratedRed:0.232 green:0.232 blue:0.232 alpha:1.0];
}

+ (NSColor *)messageCountSelectedBadgeTextColorForInactiveWindow
{
	return [NSColor colorWithCalibratedRed:0.232 green:0.232 blue:0.232 alpha:1.0];
}

+ (NSColor *)messageCountHighlightedBadgeTextColor
{
	return [NSColor whiteColor];
}

+ (NSColor *)messageCountNormalBadgeBackgroundColorForActiveWindow
{
	return [NSColor colorWithCalibratedWhite:0.15 alpha:1.0];
}

+ (NSColor *)messageCountNormalBadgeBackgroundColorForInactiveWindow
{
	return [NSColor colorWithCalibratedWhite:0.3 alpha:1.0];
}

+ (NSColor *)messageCountSelectedBadgeBackgroundColorForActiveWindow
{
	return [NSColor whiteColor];
}

+ (NSColor *)messageCountSelectedBadgeBackgroundColorForInactiveWindow
{
	return [NSColor whiteColor];
}

+ (NSColor *)messageCountHighlightedBadgeBackgroundColorForActiveWindow
{
	return [NSColor colorWithCalibratedRed:0.0117 green:0.1562 blue:0.0 alpha:1.0];
}

+ (NSColor *)messageCountHighlightedBadgeBackgroundColorForInactiveWindow
{
	return nil; // This value is ignored on dark mode.
}

+ (NSColor *)rowSelectionColorForActiveWindow
{
	return [NSColor colorWithCalibratedWhite:0.2 alpha:1.0];
}

+ (NSColor *)rowSelectionColorForInactiveWindow
{
	return [NSColor colorWithCalibratedWhite:0.6 alpha:1.0];
}

+ (NSColor *)serverListBackgroundColorForActiveWindow
{
	return [NSColor clearColor];
}

+ (NSColor *)serverListBackgroundColorForInactiveWindow
{
	return [NSColor colorWithCalibratedWhite:0.18 alpha:1.0];
}

@end
