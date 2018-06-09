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

#import "NSViewHelperPrivate.h"
#import "TXMasterController.h"
#import "TXMenuControllerPrivate.h"
#import "TVCMainWindowPrivate.h"
#import "TPCPreferencesLocal.h"
#import "TVCServerListAppearancePrivate.h"
#import "TVCServerListCellPrivate.h"
#import "TVCServerListPrivate.h"

NS_ASSUME_NONNULL_BEGIN

NSString * const TVCServerListDragType = @"TVCServerListDragType";

@interface TVCServerList ()
@property (nonatomic, strong, readwrite) TVCServerListAppearance *userInterfaceObjects;
@property (nonatomic, weak, readwrite) IBOutlet NSVisualEffectView *visualEffectView;
@property (nonatomic, weak, readwrite) IBOutlet TVCServerListMavericksBackgroundBox *backgroundView;
@property (nonatomic, assign, readwrite) BOOL leftMouseIsDownInView;
@end

@implementation TVCServerList

#pragma mark -
#pragma mark Additions/Removal

- (void)addItemToList:(NSUInteger)rowIndex inParent:(nullable id)parent
{
	[self insertItemsAtIndexes:[NSIndexSet indexSetWithIndex:rowIndex]
					  inParent:parent
				 withAnimation:(NSTableViewAnimationEffectFade | NSTableViewAnimationSlideRight)];

	if (parent) {
		[self reloadItem:parent];
	}
}

- (void)removeItemFromList:(id)object
{
	NSParameterAssert(object != nil);

	NSInteger rowIndex = [self rowForItem:object];

	NSAssert((rowIndex >= 0),
		@"Object does not exist on outline view");

	id parentItem = [self parentForItem:object];

	if (parentItem) {
		NSArray *childrenItems = [self itemsFromParentGroup:parentItem];

		rowIndex = [childrenItems indexOfObject:object];
	} else {
		NSArray *groupItems = self.groupItems;

		rowIndex = [groupItems indexOfObject:object];
	}

	NSIndexSet *indexSet = [NSIndexSet indexSetWithIndex:rowIndex];

	[self removeItemsAtIndexes:indexSet
					  inParent:parentItem
				 withAnimation:(NSTableViewAnimationEffectFade | NSTableViewAnimationSlideLeft)];

	if (parentItem) {
		[self reloadItem:parentItem];
	}
}

- (void)moveItemAtIndex:(NSInteger)fromIndex inParent:(nullable id)oldParent toIndex:(NSInteger)toIndex inParent:(nullable id)newParent
{
	if (fromIndex < toIndex) {
		[super moveItemAtIndex:fromIndex inParent:oldParent toIndex:(toIndex - 1) inParent:newParent];
	} else {
		[super moveItemAtIndex:fromIndex inParent:oldParent toIndex:toIndex inParent:newParent];
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
	for (NSUInteger i = 0; i < self.numberOfRows; i++) {
		[self updateDrawingForRow:i skipOcclusionCheck:skipOcclusionCheck];
	}
}

- (void)reloadAllUnreadMessageCountBadges:(BOOL)skipOcclusionCheck
{
	for (NSUInteger i = 0; i < self.numberOfRows; i++) {
		[self updateMessageCountForRow:i skipOcclusionCheck:skipOcclusionCheck];
	}
}

- (void)updateDrawingForItem:(IRCTreeItem *)cellItem skipOcclusionCheck:(BOOL)skipOcclusionCheck
{
	NSParameterAssert(cellItem != nil);

	NSInteger rowIndex = [self rowForItem:cellItem];

	[self updateDrawingForRow:rowIndex skipOcclusionCheck:skipOcclusionCheck];
}

- (void)updateMessageCountForItem:(IRCTreeItem *)cellItem skipOcclusionCheck:(BOOL)skipOcclusionCheck
{
	NSParameterAssert(cellItem != nil);

	NSInteger rowIndex = [self rowForItem:cellItem];

	[self updateMessageCountForRow:rowIndex skipOcclusionCheck:skipOcclusionCheck];
}

- (void)updateMessageCountForRow:(NSInteger)rowIndex skipOcclusionCheck:(BOOL)skipOcclusionCheck
{
	if (rowIndex < 0) {
		return;
	}

	if (skipOcclusionCheck == NO && self.mainWindow.occluded) {
		return;
	}

	__kindof TVCServerListCell *rowView = [self viewAtColumn:0 row:rowIndex makeIfNecessary:NO];

	BOOL isChildItem = [rowView isKindOfClass:[TVCServerListCellChildItem class]];

	if (isChildItem) {
		[rowView populateMessageCountBadge];
	}
}

- (void)updateDrawingForRow:(NSInteger)rowIndex skipOcclusionCheck:(BOOL)skipOcclusionCheck
{
	if (rowIndex < 0) {
		return;
	}

	if (skipOcclusionCheck == NO && self.mainWindow.occluded) {
		return;
	}

	__kindof TVCServerListCell *rowView = [self viewAtColumn:0 row:rowIndex makeIfNecessary:NO];

	BOOL isGroupItem = [rowView isKindOfClass:[TVCServerListCellGroupItem class]];

	if (isGroupItem) {
		[rowView updateGroupDisclosureTriangle]; // Calls setNeedsDisplay: for item
	} else {
		rowView.needsDisplay = YES;
	}
}

- (BOOL)allowsVibrancy
{
	return YES;
}

- (void)reloadUserInterfaceObjects
{
	/* We assign a strong reference to these instead of returning the original
	 value every time so that there are no race conditions for when it changes. */

	self.userInterfaceObjects = self.mainWindow.userInterfaceObjects.serverList;
}

- (void)updateVibrancy
{
	NSAppearance *appearance = nil;

	if (self.mainWindow.usingDarkAppearance) {
		appearance = [NSAppearance appearanceNamed:NSAppearanceNameVibrantDark];
	} else {
		appearance = [NSAppearance appearanceNamed:NSAppearanceNameVibrantLight];
	}

	self.appearance = appearance;

	NSVisualEffectView *visaulEffectView = self.visualEffectView;

	visaulEffectView.appearance = appearance;

	if ([TPCPreferences disableSidebarTranslucency]) {
		visaulEffectView.state = NSVisualEffectStateInactive;
	} else {
		visaulEffectView.state = NSVisualEffectStateFollowsWindowActiveState;
	}

#ifdef TXSystemIsOSXMojaveOrLater
	visaulEffectView.material = NSVisualEffectMaterialSidebar;
#endif
}

- (void)updateBackgroundColor
{
	/* When changing from vibrant light to vibrant dark we must deselect all
	 rows, change the appearance, and reselect them. If we don't do this, the
	 drawing that NSOutlineView uses for drawling vibrant light rows will stick
	 forever leaving blue on selected rows no matter how hard we try to draw. */
	self.mainWindow.ignoreOutlineViewSelectionChanges = YES;

	self.allowsEmptySelection = YES;

	NSIndexSet *selectedRows = self.selectedRowIndexes;

	[self deselectAll:nil];

	if (TEXTUAL_RUNNING_ON_YOSEMITE) {
		[self updateVibrancy];
	}

	[self reloadUserInterfaceObjects];

	if (TEXTUAL_RUNNING_ON_YOSEMITE == NO) {
		if (self.mainWindow.usingDarkAppearance) {
			self.enclosingScrollView.scrollerKnobStyle = NSScrollerKnobStyleLight;
		} else {
			self.enclosingScrollView.scrollerKnobStyle = NSScrollerKnobStyleDark;
		}
	}

	self.needsDisplay = YES;

	[self selectRowIndexes:selectedRows byExtendingSelection:NO];

	self.allowsEmptySelection = NO;

	self.mainWindow.ignoreOutlineViewSelectionChanges = NO;

	[self reloadAllDrawings:YES];
}

- (void)windowDidChangeKeyState
{
	if (self.backgroundView) {
		self.backgroundView.needsDisplay = YES;
	}

	[self reloadAllDrawings:YES];
}

#pragma mark -
#pragma mark Events

- (nullable NSMenu *)menuForEvent:(NSEvent *)theEvent
{
	NSInteger rowBeneathMouse = self.rowBeneathMouse;

	if (rowBeneathMouse >= 0) {
		if (rowBeneathMouse != self.selectedRow || self.numberOfSelectedRows > 1) {
			[self selectItemAtIndex:rowBeneathMouse];
		}
	} else {
		return menuController().serverListNoSelectionMenu;
	}

	return self.menu;
}

- (void)mouseDown:(NSEvent *)theEvent
{
	self.leftMouseIsDownInView = YES;

	[super mouseDown:theEvent];
}

- (void)mouseUp:(NSEvent *)theEvent
{
	self.leftMouseIsDownInView = NO;

	[super mouseUp:theEvent];
}

- (void)keyDown:(NSEvent *)e
{
	if (self.keyDelegate == nil) {
		return;
	}

	switch (e.keyCode) {
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
			[self.keyDelegate serverListKeyDown:e];

			break;
		}
	}
}

@end

NS_ASSUME_NONNULL_END
