/* ********************************************************************* 
                  _____         _               _
                 |_   _|____  _| |_ _   _  __ _| |
                   | |/ _ \ \/ / __| | | |/ _` | |
                   | |  __/>  <| |_| |_| | (_| | |
                   |_|\___/_/\_\\__|\__,_|\__,_|_|

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

#import "TVCMainWindowPrivate.h"

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
	[self reloadAllDrawings:NO];
}

- (void)reloadAllUnreadMessageCountBadges
{
	[self reloadAllUnreadMessageCountBadges:NO];
}

- (void)updateDrawingForItem:(IRCTreeItem *)cellItem
{
	[self updateDrawingForItem:cellItem skipOcclusionCheck:NO];
}

- (void)updateMessageCountForItem:(IRCTreeItem *)cellItem
{
	[self updateMessageCountForItem:cellItem skipOcclusionCheck:NO];
}

- (void)updateMessageCountForRow:(NSInteger)rowIndex
{
	[self updateMessageCountForRow:rowIndex skipOcclusionCheck:NO];
}

- (void)updateDrawingForRow:(NSInteger)rowIndex
{
	[self updateDrawingForRow:rowIndex skipOcclusionCheck:NO];
}

- (void)reloadAllDrawings:(BOOL)skipOcclusionCheck
{
	for (NSInteger i = 0; i < [self numberOfRows]; i++) {
		[self updateDrawingForRow:i skipOcclusionCheck:skipOcclusionCheck];
	}
}

- (void)reloadAllUnreadMessageCountBadges:(BOOL)skipOcclusionCheck
{
	for (NSInteger i = 0; i < [self numberOfRows]; i++) {
		[self updateMessageCountForRow:i skipOcclusionCheck:skipOcclusionCheck];
	}
}

- (void)updateDrawingForItem:(IRCTreeItem *)cellItem skipOcclusionCheck:(BOOL)skipOcclusionCheck
{
	PointerIsEmptyAssert(cellItem);
	
	NSInteger rowIndex = [self rowForItem:cellItem];
	
	NSAssertReturn(rowIndex >= 0);
	
	[self updateDrawingForRow:rowIndex skipOcclusionCheck:skipOcclusionCheck];
}

- (void)updateMessageCountForItem:(IRCTreeItem *)cellItem skipOcclusionCheck:(BOOL)skipOcclusionCheck
{
	PointerIsEmptyAssert(cellItem);
	
	NSInteger rowIndex = [self rowForItem:cellItem];
	
	NSAssertReturn(rowIndex >= 0);
	
	[self updateMessageCountForRow:rowIndex skipOcclusionCheck:skipOcclusionCheck];
}

- (void)updateMessageCountForRow:(NSInteger)rowIndex skipOcclusionCheck:(BOOL)skipOcclusionCheck
{
	NSAssertReturn(rowIndex >= 0);
	
	if (skipOcclusionCheck || (skipOcclusionCheck == NO && [mainWindow() isOccluded] == NO)) {
		id rowView = [self viewAtColumn:0 row:rowIndex makeIfNecessary:NO];
		
		BOOL isChildItem = [rowView isKindOfClass:[TVCServerListCellChildItem class]];
		
		if (isChildItem) {
			[rowView populateMessageCountBadge];
		}
	}
}

- (void)updateDrawingForRow:(NSInteger)rowIndex skipOcclusionCheck:(BOOL)skipOcclusionCheck
{
	NSAssertReturn(rowIndex >= 0);
	
	if (skipOcclusionCheck || (skipOcclusionCheck == NO && [mainWindow() isOccluded] == NO)) {
		id rowView = [self viewAtColumn:0 row:rowIndex makeIfNecessary:NO];
		
		BOOL isGroupItem = [rowView isKindOfClass:[TVCServerListCellGroupItem class]];
		BOOL isChildItem = [rowView isKindOfClass:[TVCServerListCellChildItem class]];
		
		if (isGroupItem || isChildItem) {
			if (isGroupItem) {
				[rowView updateGroupDisclosureTriangle]; // Calls setNeedsDisplay: for item
			} else {
				[rowView setNeedsDisplay:YES];
			}
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

- (void)reloadUserInterfaceObjects
{
	Class newObjects = nil;
	
	if ([XRSystemInformation isUsingOSXYosemiteOrLater])
	{
		if ([TVCServerListSharedUserInterface yosemiteIsUsingVibrantDarkMode] == NO) {
			newObjects = [TVCServerListLightYosemiteUserInterface class];
		} else {
			newObjects = [TVCServerListDarkYosemiteUserInterface class];
		}
	}
	else
	{
		if ([TPCPreferences invertSidebarColors]) {
			newObjects = [TVCServerListMavericksDarkUserInterface class];
		} else {
			newObjects = [TVCServerListMavericksLightUserInterface class];
		}
	}
	
	self.userInterfaceObjects = nil;
	self.userInterfaceObjects = [newObjects new];
}

- (void)updateVibrancy
{
	/* Build context. */
	NSAppearance *appearance = nil;
	
	NSVisualEffectView *visaulEffectView = [self visualEffectView];
	
	/* Define appearance. */
	if ([TPCPreferences invertSidebarColors]) {
		appearance = [NSAppearance appearanceNamed:NSAppearanceNameVibrantDark];
	} else {
		appearance = [NSAppearance appearanceNamed:NSAppearanceNameVibrantLight];
	}
	
	/* Set appearance of self to inherit menu color. */
	[self setAppearance:appearance];
	
	/* Use the underlying visual effect view for real situations. */
	[visaulEffectView setAppearance:appearance];

	/* Update state of visual effect view */
	if ([TPCPreferences disableSidebarTranslucency]) {
		[visaulEffectView setState:NSVisualEffectStateInactive];
	} else {
		[visaulEffectView setState:NSVisualEffectStateFollowsWindowActiveState];
	}
}

- (void)updateBackgroundColor
{
	/* When changing from vibrant light to vibrant dark we must deselect all
	 rows, change the appearance, and reselect them. If we don't do this, the
	 drawing that NSOutlineView uses for drawling vibrant light rows will stick
	 forever leaving blue on selected rows no matter how hard we try to draw. */
	[mainWindow() setIgnoreOutlineViewSelectionChanges:YES];
	
	[self setAllowsEmptySelection:YES];
	
	NSIndexSet *selectedRows = [self selectedRowIndexes];
	
	[self deselectAll:nil];
	
	if ([XRSystemInformation isUsingOSXYosemiteOrLater]) {
		[self updateVibrancy];
	}
	
	[self reloadUserInterfaceObjects];
	
	if ([XRSystemInformation isUsingOSXYosemiteOrLater] == NO) {
		if ([TPCPreferences invertSidebarColors]) {
			[[self enclosingScrollView] setScrollerKnobStyle:NSScrollerKnobStyleLight];
		} else {
			[[self enclosingScrollView] setScrollerKnobStyle:NSScrollerKnobStyleDark];
		}
	}
	
	[self setNeedsDisplay:YES];
	
	[self selectRowIndexes:selectedRows byExtendingSelection:NO];
	
	[self setAllowsEmptySelection:NO];
	
	[mainWindow() setIgnoreOutlineViewSelectionChanges:NO];
	
	[self reloadAllDrawings:YES];
}

- (void)windowDidChangeKeyState
{
	if ([XRSystemInformation isUsingOSXYosemiteOrLater] == NO) {
		[[self backgroundView] setNeedsDisplay:YES];
	}

	[self reloadAllDrawings:YES];
}

#pragma mark -
#pragma mark Events

- (NSMenu *)menuForEvent:(NSEvent *)theEvent
{
	NSPoint mouseLocation = [self convertPoint:[theEvent locationInWindow] fromView:nil];

	NSInteger rowUnderMouse = [self rowAtPoint:mouseLocation];

	if (rowUnderMouse >= 0 && rowUnderMouse != [self selectedRow]) {
		[self selectItemAtIndex:rowUnderMouse];
	}

	if (rowUnderMouse == (-1)) {
		return [menuController() addServerMenu];
	}

	return [self menu];
}

- (void)mouseDown:(NSEvent *)theEvent
{
	/* When certain keys are held, send the event upstream or ignore
	 if the window is not in focus. */
	NSUInteger keyboardKeys = ([theEvent modifierFlags] & NSDeviceIndependentModifierFlagsMask);

	if ((keyboardKeys & NSCommandKeyMask) == NSCommandKeyMask ||
		(keyboardKeys & NSShiftKeyMask) == NSShiftKeyMask)
	{
		if ([[self window] isKeyWindow]) {
			[super mouseDown:theEvent];
		}

		return;
	}

	/* If the event is double click, then send logic straight to super */
	if ([theEvent clickCount] > 1) {
		[super mouseDown:theEvent];

		return;
	}

	/* If the item clicked is selected, then switch group selection to it. */
	NSPoint mouseLocation = [self convertPoint:[theEvent locationInWindow] fromView:nil];

	NSInteger rowUnderMouse = [self rowAtPoint:mouseLocation];

	if (rowUnderMouse >= 0) {
		if ([self isRowSelected:rowUnderMouse]) {
			IRCTreeItem *itemUnderMouse = [self itemAtRow:rowUnderMouse];

			(void)[mainWindow() selectItemInSelectedItems:itemUnderMouse];

			return;
		}
	}

	/* Send action to super */
	[super mouseDown:theEvent];
}

- (void)rightMouseDown:(NSEvent *)theEvent
{
	[super rightMouseDown:theEvent];
}

- (void)keyDown:(NSEvent *)e
{
	if (self.keyDelegate) {
		switch ([e keyCode]) {
			case 125: // down arrow
			case 126: // up arrow
			case 123: // left arrow
			case 124: // right arrow
			case 116: // page up
			case 121: // page down
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
