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

- (id)userInterfaceObjects
{
	if ([CSFWSystemInformation featureAvailableToOSXYosemite])
	{
		if ([TVCServerListSharedUserInterface yosemiteIsUsingVibrantDarkMode] == NO) {
			return [TVCServerListLightYosemiteUserInterface class];
		} else {
			return [TVCServerListDarkYosemiteUserInterface class];
		}
	}
	else
	{
		if ([TPCPreferences invertSidebarColors]) {
			return [TVCServerListMavericksDarkUserInterface class];
		} else {
			return [TVCServerListMavericksLightUserInterface class];
		}
	}
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
	
	/* Fake the appearance of self. */
	[self setAppearance:appearance];
	
	/* Use the underlying visual effect view for real situations. */
	[visaulEffectView setAppearance:appearance];
}

- (void)updateBackgroundColor
{
	if ([CSFWSystemInformation featureAvailableToOSXYosemite])
	{
		/* When changing from vibrant light to vibrant dark we must deselect all
		 rows, change the appearance, and reselect them. If we don't do this, the
		 drawing that NSOutlineView uses for drawling vibrant light rows will stick
		 forever leaving blue on selected rows no matter how hard we try to draw. */
		[mainWindow() setTemporarilyDisablePreviousSelectionUpdates:YES];
		[mainWindow() setTemporarilyIgnoreOutlineViewSelectionChanges:YES];
		
		NSIndexSet *selectedRows = [self selectedRowIndexes];
		
		[self deselectAll:nil];
		
		[self updateVibrancy];
		
		[self selectRowIndexes:selectedRows byExtendingSelection:NO];
		
		[mainWindow() setTemporarilyDisablePreviousSelectionUpdates:NO];
		[mainWindow() setTemporarilyIgnoreOutlineViewSelectionChanges:NO];
	}
	else
	{
		if ([TPCPreferences invertSidebarColors]) {
			[self setBackgroundColor:nil];
		} else {
			[self setBackgroundColor:[NSColor sourceListBackgroundColor]];
		}
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
