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

@interface TVCMemberList ()
@property (nonatomic, assign) BOOL beginUpdatesCallRunning;
@property (nonatomic, strong) id userPopoverTrackingArea;
@property (nonatomic, assign) BOOL userPopoverMouseIsInView;
@property (nonatomic, assign) BOOL userPopoverTimerIsActive;
@property (nonatomic, assign) NSPoint userPopoverLastKnonwnLocalPoint;
@property (nonatomic, assign) NSInteger lastRowShownUserInfoPopover;
@end

@implementation TVCMemberList

- (void)dealloc
{
	/* Remove notifications for scroll view. */
	[RZNotificationCenter() removeObserver:self
									  name:NSViewBoundsDidChangeNotification
									object:[self scrollViewContentView]];
}

#pragma mark -
#pragma mark Update Grouping

- (BOOL)updatesArePaging
{
	return self.beginUpdatesCallRunning;
}

- (void)beginGroupedUpdates
{
	NSAssertReturn(self.beginUpdatesCallRunning == NO);

	self.beginUpdatesCallRunning = YES;
	
	[self beginUpdates];
}

- (void)endGroupedUpdates
{
	NSAssertReturn(self.beginUpdatesCallRunning);
	
	self.beginUpdatesCallRunning = NO;
	
	[self endUpdates];
}

#pragma mark -
#pragma mark Additions/Removal

- (void)addItemToList:(NSInteger)index
{
	NSAssertReturn(index >= 0);

	[self insertItemsAtIndexes:[NSIndexSet indexSetWithIndex:index]
					  inParent:nil
				 withAnimation:NSTableViewAnimationEffectNone];
}

- (void)removeItemFromList:(id)oldObject
{
	/* Get the row. */
	NSInteger rowIndex = [self rowForItem:oldObject];

	NSAssertReturn(rowIndex >= 0);

	/* Remove object. */
	[self removeItemsAtIndexes:[NSIndexSet indexSetWithIndex:rowIndex]
					  inParent:nil
				 withAnimation:NSTableViewAnimationEffectNone];
}

#pragma mark -
#pragma mark Events

- (NSMenu *)menuForEvent:(NSEvent *)e
{
	NSIndexSet *selectedRows = [self selectedRowIndexes];

	NSPoint p = [self convertPoint:[e locationInWindow] fromView:nil];

	NSInteger i = [self rowAtPoint:p];

	if (i >= 0 && [selectedRows containsIndex:i] == NO) {
		[self selectItemAtIndex:i];
	} else if (i == -1) {
		return nil;
	}

	return [menuController() userControlMenu];
}

- (void)keyDown:(NSEvent *)e
{
	if (self.keyDelegate) {
		switch ([e keyCode]) {
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
				if ([self.keyDelegate respondsToSelector:@selector(memberListViewKeyDown:)]) {
					[self.keyDelegate memberListViewKeyDown:e];
				}
				
				break;
			}
		}
	}
}

- (void)rightMouseDown:(NSEvent *)theEvent
{
	[super rightMouseDown:theEvent];
}

#pragma mark -
#pragma mark Mouse Tracking

- (instancetype)initWithFrame:(NSRect)frame
{
	if ((self = [super initWithFrame:frame])) {
		self.userPopoverTrackingArea = [[NSTrackingArea alloc] initWithRect:frame
																	options:(NSTrackingMouseEnteredAndExited | NSTrackingMouseMoved | NSTrackingActiveInKeyWindow)
																	  owner:self
																   userInfo:nil];

		[self addTrackingArea:self.userPopoverTrackingArea];

		return self;
	}

	return nil;
}

- (void)updateTrackingAreas
{
    [self removeTrackingArea:self.userPopoverTrackingArea];
	
	self.userPopoverTrackingArea = [[NSTrackingArea alloc] initWithRect:[self frame]
																options:(NSTrackingMouseEnteredAndExited | NSTrackingMouseMoved | NSTrackingActiveInKeyWindow)
																  owner:self
															   userInfo:nil];

	[self addTrackingArea:self.userPopoverTrackingArea];
}

- (void)destroyUserInfoPopoverOnWindowKeyChange
{
	[self destroyUserInfoPopover]; // Destroy anything shown.
}

- (void)destroyUserInfoPopover
{
	[self cancelPerformRequestsWithSelector:@selector(popDelayedUserInfoExpansionFrame) object:nil];

	self.lastRowShownUserInfoPopover = -1;

	self.userPopoverMouseIsInView = NO;
	self.userPopoverTimerIsActive = NO;

	self.userPopoverLastKnonwnLocalPoint = NSZeroPoint;

	if ([self.memberListUserInfoPopover isShown]) {
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

- (void)mouseExited:(NSEvent *)theEvent
{
	[self destroyUserInfoPopover];
}

- (void)mouseMoved:(NSEvent *)theEvent
{
	NSPoint localPoint = [self convertPoint:[theEvent locationInWindow] fromView:nil];

	[self popUserInfoExpansionFrameAtPoint:localPoint ignoreTimerCheck:NO];
}

- (void)popUserInfoExpansionFrameAtPoint:(NSPoint)localPoint ignoreTimerCheck:(BOOL)ignoreTimer
{
	self.userPopoverLastKnonwnLocalPoint = localPoint;

	if ([XRAccessibility isVoiceOverEnabled]) {
		/* For the best accessiblity, it is best to disable the user
		 information popover entirely with Voice Over enabled. */

		return;
	}

	if (ignoreTimer == NO && self.userPopoverTimerIsActive) {
		return; // Only allow the timer to pop it.
	}

	NSInteger row = [self rowAtPoint:localPoint];

	if (row > -1) {
		if (NSDissimilarObjects(self.lastRowShownUserInfoPopover, row)) {
			self.lastRowShownUserInfoPopover = row;

			id rowView = [self viewAtColumn:0 row:row makeIfNecessary:NO];

			[rowView drawWithExpansionFrame];
		}
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
		[self popUserInfoExpansionFrameAtPoint:self.userPopoverLastKnonwnLocalPoint ignoreTimerCheck:YES];
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

- (void)scrollViewBoundsDidChangeNotification:(NSNotification *)aNote
{
	if ([TPCPreferences memberListUpdatesUserInfoPopoverOnScroll]) {
		/* Only responds to events that are related to us... */
		if ([[aNote object] isEqual:[self scrollViewContentView]]) {
			/* Get current mouse position. */
			NSPoint mouseLocation = [NSEvent mouseLocation];
			
			NSRect fakeMouseLocation = NSMakeRect(mouseLocation.x, mouseLocation.y, 1, 1);
			
			NSRect rawPoint = [self.window convertRectFromScreen:fakeMouseLocation];
			
			NSPoint localPoint = [self convertPoint:rawPoint.origin fromView:nil];
			
			/* Handle popover. */
			[self popUserInfoExpansionFrameAtPoint:localPoint ignoreTimerCheck:YES];
		}
	}
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
	
    if ([files count] > 0 && [self draggedRow:sender] >= 0) {
        return NSDragOperationCopy;
    } else {
        return NSDragOperationNone;
    }
}

- (BOOL)prepareForDragOperation:(id <NSDraggingInfo>)sender
{
    NSArray *files = [self draggedFiles:sender];
	
    return ([files count] > 0 && [self draggedRow:sender] >= 0);
}

- (BOOL)performDragOperation:(id <NSDraggingInfo>)sender
{
    NSArray *files = [self draggedFiles:sender];
	
    if ([files count] > 0) {
        NSInteger row = [self draggedRow:sender];

        if (row >= 0) {
			[menuController() memberSendDroppedFiles:files row:@(row)];

            return YES;
        } else {
            return NO;
        }
    } else {
        return NO;
    }
}

#pragma mark -
#pragma mark Drawing Updates

- (void)updateDrawingForMember:(IRCUser *)cellItem
{
	PointerIsEmptyAssert(cellItem);
	
	NSInteger rowIndex = [self rowForItem:cellItem];
	
	NSAssertReturn(rowIndex >= 0);
	
	[self updateDrawingForRow:rowIndex];
}

#pragma mark -

- (void)reloadAllDrawings
{
	[self reloadAllDrawings:NO];
}

- (void)updateDrawingForRow:(NSInteger)rowIndex
{
	[self updateDrawingForRow:rowIndex skipOcclusionCheck:NO];
}

- (void)reloadAllDrawings:(BOOL)skipOcclusionCheck
{
	/* Reload drawings for all rows. */
	for (NSInteger i = 0; i < [self numberOfRows]; i++) {
		[self updateDrawingForRow:i skipOcclusionCheck:skipOcclusionCheck];
	}
}

- (void)updateDrawingForRow:(NSInteger)rowIndex skipOcclusionCheck:(BOOL)skipOcclusionCheck
{
	NSAssertReturn(rowIndex >= 0);
	
	if (skipOcclusionCheck || (skipOcclusionCheck == NO && [mainWindow() isOccluded] == NO)) {
		id rowView = [self viewAtColumn:0 row:rowIndex makeIfNecessary:NO];
	
		[rowView setNeedsDisplay:YES];
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

- (id)scrollViewContentView
{
	return [[self enclosingScrollView] contentView];
}

- (void)drawContextMenuHighlightForRow:(int)row
{
    // Do not draw focus ring ...
}

- (void)reloadUserInterfaceObjects
{
	Class newObjects = nil;
	
	if ([XRSystemInformation isUsingOSXYosemiteOrLater])
	{
		if ([TVCMemberListSharedUserInterface yosemiteIsUsingVibrantDarkMode] == NO) {
			newObjects = [TVCMemberListLightYosemiteUserInterface class];
		} else {
			newObjects = [TVCMemberListDarkYosemiteUserInterface class];
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
	
	/* Fake the appearance of self. */
	[self setAppearance:appearance];
	
	/* Use the underlying visual effect view for real situations. */
	[visaulEffectView setAppearance:appearance];
}

- (void)updateBackgroundColor
{
	/* When changing from vibrant light to vibrant dark we must deselect all
	 rows, change the appearance, and reselect them. If we don't do this, the
	 drawing that NSOutlineView uses for drawling vibrant light rows will stick
	 forever leaving blue on selected rows no matter how hard we try to draw. */
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
	
	[self reloadAllDrawings:YES];
}

- (void)windowDidChangeKeyState
{
	if ([XRSystemInformation isUsingOSXYosemiteOrLater] == NO) {
		[[self backgroundView] setNeedsDisplay:YES];
	}
	
	[self reloadAllDrawings:YES];
}

@end
