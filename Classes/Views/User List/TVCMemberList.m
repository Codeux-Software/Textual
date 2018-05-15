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

#import "NSViewHelperPrivate.h"
#import "TXMasterController.h"
#import "TXMenuControllerPrivate.h"
#import "TVCMainWindow.h"
#import "TPCPreferencesLocal.h"
#import "TVCMemberListCellPrivate.h"
#import "TVCMemberListSharedUserInterfacePrivate.h"
#import "TVCMemberListUserInfoPopoverPrivate.h"
#import "TVCMemberListPrivate.h"

NS_ASSUME_NONNULL_BEGIN

NSString * const TVCMemberListDragType = @"TVCMemberListDragType";

@interface TVCMemberList ()
@property (nonatomic, strong) id userPopoverTrackingArea;
@property (nonatomic, assign) BOOL userPopoverMouseIsInView;
@property (nonatomic, assign) BOOL userPopoverTimerIsActive;
@property (nonatomic, assign) NSPoint userPopoverLastKnownLocalPoint;
@property (nonatomic, assign) NSInteger lastRowShownUserInfoPopover;
@property (nonatomic, strong, readwrite) id userInterfaceObjects;
@property (nonatomic, weak, readwrite) IBOutlet NSVisualEffectView *visualEffectView;
@property (nonatomic, weak, readwrite) IBOutlet TVCMemberListMavericksUserInterfaceBackground *backgroundView;
@property (nonatomic, strong, readwrite) IBOutlet TVCMemberListUserInfoPopover *memberListUserInfoPopover;
@end

@implementation TVCMemberList

- (nullable instancetype)initWithCoder:(NSCoder *)coder
{
	if ((self = [super initWithCoder:coder])) {
		[self prepareInitialState];

		return self;
	}

	return nil;
}

- (instancetype)initWithFrame:(NSRect)frame
{
	if ((self = [super initWithFrame:frame])) {
		[self prepareInitialState];

		return self;
	}

	return nil;
}

- (void)prepareInitialState
{
	[self updateTrackingAreas];

	[RZNotificationCenter() addObserver:self selector:@selector(windowDidResignKey:) name:NSWindowDidResignKeyNotification object:nil];
}

- (void)dealloc
{
	[RZNotificationCenter() removeObserver:self];
}

#pragma mark -
#pragma mark Additions/Removal

- (void)addItemToList:(NSUInteger)rowIndex
{
	@try {
		[self insertItemsAtIndexes:[NSIndexSet indexSetWithIndex:rowIndex]
						  inParent:nil
					 withAnimation:NSTableViewAnimationEffectNone];
	} @catch (NSException *exception) {
		LogToConsoleError("Caught exception: %{public}@", exception.reason);
		LogToConsoleCurrentStackTrace
	}
}

- (void)removeItemFromList:(id)object
{
	NSInteger rowIndex = [self rowForItem:object];

	NSAssert((rowIndex >= 0),
		@"Object does not exist on outline view");

	[self removeItemFromListAtIndex:rowIndex];
}

- (void)removeItemFromListAtIndex:(NSUInteger)rowIndex
{
	[self removeItemsAtIndexes:[NSIndexSet indexSetWithIndex:rowIndex]
					  inParent:nil
				 withAnimation:NSTableViewAnimationEffectNone];
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
#pragma mark Mouse Tracking

- (void)updateTrackingAreas
{
	if (self.userPopoverTrackingArea) {
		[self removeTrackingArea:self.userPopoverTrackingArea];
	}

	self.userPopoverTrackingArea =
	[[NSTrackingArea alloc] initWithRect:self.frame
								 options:(NSTrackingMouseEnteredAndExited | NSTrackingMouseMoved | NSTrackingActiveInActiveApp)
								   owner:self
								userInfo:nil];

	[self addTrackingArea:self.userPopoverTrackingArea];
}

- (void)destroyUserInfoPopoverOnWindowKeyChange
{
	[self destroyUserInfoPopover]; // Destroy anything shown
}

- (void)destroyUserInfoPopover
{
	[self cancelPerformRequestsWithSelector:@selector(popDelayedUserInfoExpansionFrame) object:nil];

	self.lastRowShownUserInfoPopover = (-1);

	self.userPopoverMouseIsInView = NO;
	self.userPopoverTimerIsActive = NO;

	self.userPopoverLastKnownLocalPoint = NSZeroPoint;

	if (self.memberListUserInfoPopover.shown) {
		[self.memberListUserInfoPopover close];
	}
}

- (void)mouseEntered:(NSEvent *)theEvent
{
	self.userPopoverMouseIsInView = YES;

	if (self.userPopoverTimerIsActive == NO) {
		self.userPopoverTimerIsActive = YES;

		[self performSelector:@selector(popDelayedUserInfoExpansionFrame) withObject:nil afterDelay:1.0];
	}
}

- (void)windowDidResignKey:(NSNotification *)notification
{
	if (notification.object != self.window) {
		return;
	}

	[self destroyUserInfoPopoverOnWindowKeyChange];
}

- (void)mouseExited:(NSEvent *)theEvent
{
	[self destroyUserInfoPopover];
}

- (void)mouseMoved:(NSEvent *)theEvent
{
	NSPoint localPoint = [self convertPoint:theEvent.locationInWindow fromView:nil];

	[self popUserInfoExpansionFrameAtPoint:localPoint ignoreTimerCheck:NO];
}

- (void)popUserInfoExpansionFrameAtPoint:(NSPoint)localPoint ignoreTimerCheck:(BOOL)ignoreTimer
{
	self.userPopoverLastKnownLocalPoint = localPoint;

	if ([XRAccessibility isVoiceOverEnabled]) {
		return;
	}

	if (self.userPopoverTimerIsActive && ignoreTimer == NO) {
		return; // Only allow the timer to pop it
	}

	if (self.window.keyWindow == NO) {
		return;
	}

	NSInteger row = [self rowAtPoint:localPoint];

	if (row < 0) {
		return;
	}

	if (self.lastRowShownUserInfoPopover != row) {
		self.lastRowShownUserInfoPopover = row;

		id rowView = [self viewAtColumn:0 row:row makeIfNecessary:NO];

		[rowView drawWithExpansionFrame];
	}
}

- (void)popDelayedUserInfoExpansionFrame
{
	/* Basically we delay the expansion frame (also known as the popover)
	 by one second from the time the user enters the frame so that if they
	 are just moving the mouse through it to another portion of the window
	 we do not try to show a popover. We only want to show a popover if the
	 user has some intention of being in the list. */

	if (self.userPopoverMouseIsInView) {
		[self popUserInfoExpansionFrameAtPoint:self.userPopoverLastKnownLocalPoint ignoreTimerCheck:YES];
	}

	self.userPopoverTimerIsActive = NO;
}

#pragma mark -
#pragma mark Scroll View

- (void)awakeFromNib
{
	[RZNotificationCenter() addObserver:self
							   selector:@selector(scrollViewBoundsDidChangeNotification:)
								   name:NSViewBoundsDidChangeNotification
								 object:[self scrollViewContentView]];

	[self registerForDraggedTypes:@[NSFilenamesPboardType]];
}

- (void)scrollViewBoundsDidChangeNotification:(NSNotification *)notification
{
	if ([TPCPreferences memberListUpdatesUserInfoPopoverOnScroll] == NO) {
		return;
	}

	if (notification.object != [self scrollViewContentView]) {
		return;
	}

	NSPoint mouseLocation = [NSEvent mouseLocation];

	NSRect mouseLocationFaked = NSMakeRect(mouseLocation.x, mouseLocation.y, 1.0, 1.0);

	NSRect remotePoint = [self.window convertRectFromScreen:mouseLocationFaked];

	NSPoint localPoint = [self convertPoint:remotePoint.origin fromView:nil];

	[self popUserInfoExpansionFrameAtPoint:localPoint ignoreTimerCheck:YES];
}

- (id)scrollViewContentView
{
	return self.enclosingScrollView.contentView;
}

#pragma mark -
#pragma mark Drag and Drop

- (NSInteger)draggedRow:(id <NSDraggingInfo>)sender
{
	NSPoint p = [self convertPoint:[sender draggingLocation] fromView:nil];

	return [self rowAtPoint:p];
}

- (NSArray *)draggedFiles:(id <NSDraggingInfo>)sender
{
	return [[sender draggingPasteboard] propertyListForType:NSFilenamesPboardType];
}

- (NSDragOperation)draggingEntered:(id <NSDraggingInfo>)sender
{
	return [self draggingUpdated:sender];
}

- (NSDragOperation)draggingUpdated:(id <NSDraggingInfo>)sender
{
	NSArray *files = [self draggedFiles:sender];

	if (files.count > 0 && [self draggedRow:sender] >= 0) {
		return NSDragOperationCopy;
	} else {
		return NSDragOperationNone;
	}
}

- (BOOL)prepareForDragOperation:(id <NSDraggingInfo>)sender
{
	NSArray *files = [self draggedFiles:sender];

	return (files.count > 0 && [self draggedRow:sender] >= 0);
}

- (BOOL)performDragOperation:(id <NSDraggingInfo>)sender
{
	NSArray *files = [self draggedFiles:sender];

	if (files.count > 0) {
		NSInteger row = [self draggedRow:sender];

		if (row >= 0) {
			[menuController() memberSendDroppedFiles:files row:row];

			return YES;
		}
	}

	return NO;
}

#pragma mark -
#pragma mark Drawing Updates

- (void)reloadAllDrawings
{
	[self reloadAllDrawings:NO];
}

- (void)reloadAllDrawings:(BOOL)skipOcclusionCheck
{
	for (NSUInteger i = 0; i < self.numberOfRows; i++) {
		[self updateDrawingForRow:i skipOcclusionCheck:skipOcclusionCheck];
	}
}

- (void)updateDrawingForMember:(IRCChannelUser *)cellItem
{
	NSParameterAssert(cellItem != nil);

	NSInteger rowIndex = [self rowForItem:cellItem];

	[self updateDrawingForRow:rowIndex];
}

- (void)updateDrawingForRow:(NSInteger)rowIndex
{
	[self updateDrawingForRow:rowIndex skipOcclusionCheck:NO];
}

- (void)updateDrawingForRow:(NSInteger)rowIndex skipOcclusionCheck:(BOOL)skipOcclusionCheck
{
	if (rowIndex < 0) {
		return;
	}

	if (skipOcclusionCheck == NO && self.mainWindow.occluded) {
		return;
	}

	TVCMemberListCell *rowView = [self viewAtColumn:0 row:rowIndex makeIfNecessary:NO];

	rowView.needsDisplay = YES;
}

- (void)drawContextMenuHighlightForRow:(int)row
{
	// Do not draw focus ring ...
}

- (BOOL)allowsVibrancy
{
	return YES;
}

- (void)reloadUserInterfaceObjects
{
	Class newObjects = NULL;

	if (TEXTUAL_RUNNING_ON(10.10, Yosemite))
	{
		if ([TPCPreferences invertSidebarColors]) {
			newObjects = [TVCMemberListDarkYosemiteUserInterface class];
		} else {
			newObjects = [TVCMemberListLightYosemiteUserInterface class];
		}
	}
	else
	{
		if ([TPCPreferences invertSidebarColors]) {
			newObjects = [TVCMemberListMavericksDarkUserInterface class];
		} else {
			newObjects = [TVCMemberListMavericksLightUserInterface class];
		}
	}

	[self.userInterfaceObjects invalidateAllUserMarkBadgeCaches];

	self.userInterfaceObjects = [[newObjects alloc] initWithMemberList:self];
}

- (void)updateVibrancy
{
	NSAppearance *appearance = nil;

	if ([TPCPreferences invertSidebarColors]) {
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
}

- (void)updateBackgroundColor
{
	/* When changing from vibrant light to vibrant dark we must deselect all
	 rows, change the appearance, and reselect them. If we don't do this, the
	 drawing that NSOutlineView uses for drawling vibrant light rows will stick
	 forever leaving blue on selected rows no matter how hard we try to draw. */
	NSIndexSet *selectedRows = self.selectedRowIndexes;

	[self deselectAll:nil];

	if (TEXTUAL_RUNNING_ON(10.10, Yosemite)) {
		[self updateVibrancy];
	}

	[self reloadUserInterfaceObjects];

	if (TEXTUAL_RUNNING_ON(10.10, Yosemite) == NO) {
		if ([TPCPreferences invertSidebarColors]) {
			self.enclosingScrollView.scrollerKnobStyle = NSScrollerKnobStyleLight;
		} else {
			self.enclosingScrollView.scrollerKnobStyle = NSScrollerKnobStyleDark;
		}
	}

	self.needsDisplay = YES;

	[self selectRowIndexes:selectedRows byExtendingSelection:NO];

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
		if ([self.selectedRowIndexes containsIndex:rowBeneathMouse] == NO) {
			[self selectItemAtIndex:rowBeneathMouse];
		}

		return menuController().userControlMenu;
	}

	return nil;
}

- (void)keyDown:(NSEvent *)e
{
	if (self.keyDelegate == nil) {
		return;
	}

	switch (e.keyCode) {
		case 125: // down arrow
		case 126: // up arrow
		{
			[super keyDown:e];

			break;
		}
		case 123: // left arrow
		case 124: // right arrow
		case 116: // page up
		case 121: // page down
		{
			break;
		}
		default:
		{
			[self.keyDelegate memberListKeyDown:e];

			break;
		}
	}
}

@end

NS_ASSUME_NONNULL_END
