/* ********************************************************************* 
       _____        _               _    ___ ____   ____
      |_   _|___  _| |_ _   _  __ _| |  |_ _|  _ \ / ___|
       | |/ _ \ \/ / __| | | |/ _` | |   | || |_) | |
       | |  __/>  <| |_| |_| | (_| | |   | ||  _ <| |___
       |_|\___/_/\_\\__|\__,_|\__,_|_|  |___|_| \_\\____|

 Copyright (c) 2010 — 2013 Codeux Software & respective contributors.
        Please see Contributors.rtfd and Acknowledgements.rtfd

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

@interface TVCMemberList ()
@property (nonatomic, strong) id userPopoverTrackingArea;
@property (nonatomic, assign) BOOL userPopoverMouseIsInView;
@property (nonatomic, assign) BOOL userPopoverTimerIsActive;
@property (nonatomic, assign) NSPoint userPopoverLastKnonwnLocalPoint;
@property (nonatomic, assign) NSInteger lastRowShownUserInfoPopover;
@end

@implementation TVCMemberList

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
	NSPoint p = [self convertPoint:e.locationInWindow fromView:nil];

	NSInteger i = [self rowAtPoint:p];

	if (i >= 0 && NSDissimilarObjects(i, self.selectedRow)) {
		[self selectItemAtIndex:i];
	}

	return self.masterController.userControlMenu;
}

- (void)keyDown:(NSEvent *)e
{
	if (self.keyDelegate) {
		switch ([e keyCode]) {
			case 123 ... 126:
			case 116:
			case 121:
				break;
			default:
				if ([self.keyDelegate respondsToSelector:@selector(memberListViewKeyDown:)]) {
					[self.keyDelegate memberListViewKeyDown:e];
				}
				
				break;
		}
	}
}

- (void)rightMouseDown:(NSEvent *)theEvent
{
	NSWindowNegateActionWithAttachedSheet();

	[super rightMouseDown:theEvent];
}

#pragma mark -
#pragma mark Mouse Tracking

- (id)initWithFrame:(NSRect)frame
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

	self.userPopoverTrackingArea = [[NSTrackingArea alloc] initWithRect:self.frame
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
	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(popDelayedUserInfoExpansionFrame) object:nil];

	self.lastRowShownUserInfoPopover = -1;

	self.userPopoverMouseIsInView = NO;
	self.userPopoverTimerIsActive = NO;

	self.userPopoverLastKnonwnLocalPoint = NSZeroPoint;

	if ([self.masterController.memberListUserInfoPopover isShown]) {
		[self.masterController.memberListUserInfoPopover close];
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
								 object:[self.enclosingScrollView contentView]];
}

- (void)scrollViewBoundsDidChangeNotification:(NSNotification *)aNote
{
	/* Only responds to events that are related to us… */
	if ([[aNote object] isEqual:[self.enclosingScrollView contentView]]) {
		/* Get current mouse position. */
		NSPoint rawPoint = [self.window convertScreenToBase:[NSEvent mouseLocation]];
		NSPoint localPoint = [self convertPoint:rawPoint fromView:nil];
		
		/* Handle popover. */
		[self popUserInfoExpansionFrameAtPoint:localPoint ignoreTimerCheck:YES];
	}
}

#pragma mark -
#pragma mark Badge Renderer

- (void)createBadgeRenderer
{
	if (PointerIsEmpty(self.badgeRenderer)) {
		self.badgeRenderer = [TVCMemberListCellBadge new];

		[self.badgeRenderer invalidateBadgeImageCacheAndRebuild];
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
	/* Reload drawings for all rows. */
	for (NSInteger i = 0; i < [self numberOfRows]; i++) {
		[self updateDrawingForRow:i];
	}

	/* Set display. */
	[self setNeedsDisplay:YES];
}

- (void)reloadAllUserInterfaceElements
{
	/* Destroy badge cache and create new. */
	[self.badgeRenderer invalidateBadgeImageCacheAndRebuild];

	/* Update background color. */
	[self updateBackgroundColor];

	/* Clear selection and re-draw it. */
	NSIndexSet *selectedRows = [self selectedRowIndexes];

	for (NSInteger i = 0; i < [self numberOfRows]; i++) {
		[self updateSelectionDrawingForRow:i byEnabling:[selectedRows containsIndex:i] forcefully:YES];
	}

	/* Set display. */
	[self setNeedsDisplay:YES];
}

- (void)reloadSelectionDrawingBySelectingItemsInIndexSet:(NSIndexSet *)rows
{
	PointerIsEmptyAssert(rows);

	for (NSInteger i = 0; i < [self numberOfRows]; i++) {
		[self updateSelectionDrawingForRow:i byEnabling:[rows containsIndex:i] forcefully:NO];
	}
}

- (void)reloadSelectionDrawingForRow:(NSInteger)row
{
	NSIndexSet *selectedRows = [self selectedRowIndexes];

	[self updateSelectionDrawingForRow:row byEnabling:[selectedRows containsIndex:row] forcefully:YES];
}

- (void)updateDrawingForRow:(NSInteger)rowIndex
{
	NSAssertReturn(rowIndex >= 0);

	id rowView = [self viewAtColumn:0 row:rowIndex makeIfNecessary:NO];

	[rowView updateDrawing];
}

- (void)updateSelectionDrawingForRow:(NSInteger)rowIndex byEnabling:(BOOL)isSelected forcefully:(BOOL)forceRedraw
{
	NSAssertReturn(rowIndex >= 0);

	TVCMemberListCell *rowView = [self viewAtColumn:0 row:rowIndex makeIfNecessary:NO];

	if (rowView.rowIsSelected && isSelected && forceRedraw == NO) {
		return; // We do not have to do anything…
	}

	/* Update the actual drawing. */
	[rowView disableSelectionBackgroundImage];

	if (isSelected) {
		[rowView enableSelectionBackgroundImage];

		rowView.rowIsSelected = YES;
	} else {
		rowView.rowIsSelected = NO;
	}

	[rowView updateDrawing]; // Redraw on selection changes.
}

- (void)updateBackgroundColor
{
	if ([TPCPreferences invertSidebarColors] || self.masterController.mainWindowIsActive == NO) {
		[self setBackgroundColor:[NSColor clearColor]];

		[self.scrollView setBackgroundColor:self.properBackgroundColor];
	} else {
		[self setBackgroundColor:self.properBackgroundColor];

		[self.scrollView setBackgroundColor:[NSColor clearColor]];
	}

	[self setNeedsDisplay:YES];
}

- (NSScrollView *)scrollView
{
	return (id)self.superview.superview;
}

- (void)drawContextMenuHighlightForRow:(int)row
{
    // Do not draw focus ring …
}

/* We handle frameOfCellAtColumn:row: to make it so our selected cell background
  draw stretches all the way from one end to the other of our list. */
- (NSRect)frameOfCellAtColumn:(NSInteger)column row:(NSInteger)row
{
	NSRect nrect = [super frameOfCellAtColumn:column row:row];

	id childItem = [self itemAtRow:row];

	nrect.origin.x = 0;

	if ([self isGroupItem:childItem]) {
		nrect.size.width += 25;
	} else {
		nrect.size.width += 39;
	}

	/* Mavericks changed this math a little… */
	if ([TPCPreferences featureAvailableToOSXMavericks]) {
		nrect.size.width += 3;
	}

	return nrect;
}

#pragma mark -
#pragma mark User Interface Design Elements

- (NSColor *)properBackgroundColor
{
	if (self.masterController.mainWindowIsActive) {
		return [self activeWindowListBackgroundColor];
	} else {
		return [self inactiveWindowListBackgroundColor];
	}
}

- (NSColor *)activeWindowListBackgroundColor
{
	return [NSColor defineUserInterfaceItem:[NSColor sourceListBackgroundColor]
							   invertedItem:[NSColor internalCalibratedRed:38.0 green:38.0 blue:38.0 alpha:1.0]];
}

- (NSColor *)inactiveWindowListBackgroundColor
{
	return [NSColor defineUserInterfaceItem:[NSColor internalCalibratedRed:237.0 green:237.0 blue:237.0 alpha:1.0]
							   invertedItem:[NSColor internalCalibratedRed:38.0 green:38.0 blue:38.0 alpha:1.0]];
}

- (NSColor *)userMarkBadgeBackgroundColor_XGraphite
{
	return [NSColor defineUserInterfaceItem:[NSColor internalCalibratedRed:132 green:147 blue:163 alpha:1.0]
							   invertedItem:[NSColor internalCalibratedRed:48 green:48 blue:48 alpha:1.0]];
}

- (NSColor *)userMarkBadgeBackgroundColor_XAqua
{
	return [NSColor defineUserInterfaceItem:[NSColor internalCalibratedRed:152 green:168 blue:202 alpha:1.0]
							   invertedItem:[NSColor internalCalibratedRed:48 green:48 blue:48 alpha:1.0]];
}

- (NSColor *)userMarkBadgeBackgroundColor_YDefault // InspIRCd-2.0
{
	return [NSColor internalCalibratedRed:162 green:86 blue:58 alpha:1.0];
}

- (NSColor *)userMarkBadgeBackgroundColor_QDefault
{
	return [NSColor internalCalibratedRed:186 green:0 blue:0 alpha:1.0];
}

- (NSColor *)userMarkBadgeBackgroundColor_ADefault
{
	return [NSColor internalCalibratedRed:157 green:0 blue:89 alpha:1.0];
}

- (NSColor *)userMarkBadgeBackgroundColor_ODefault
{
	return [NSColor internalCalibratedRed:90 green:51 blue:156 alpha:1.0];
}

- (NSColor *)userMarkBadgeBackgroundColor_HDefault
{
	return [NSColor internalCalibratedRed:17 green:125 blue:19 alpha:1.0];
}

- (NSColor *)userMarkBadgeBackgroundColor_VDefault
{
    return [NSColor internalCalibratedRed:51 green:123 blue:156 alpha:1.0];
}

- (NSColor *)userMarkBadgeBackgroundColor_Y // InspIRCd-2.0
{
	return [RZUserDefaults() colorForKey:@"User List Mode Badge Colors —> +y"];
}

- (NSColor *)userMarkBadgeBackgroundColor_Q
{
	return [RZUserDefaults() colorForKey:@"User List Mode Badge Colors —> +q"];
}

- (NSColor *)userMarkBadgeBackgroundColor_A
{
	return [RZUserDefaults() colorForKey:@"User List Mode Badge Colors —> +a"];
}

- (NSColor *)userMarkBadgeBackgroundColor_O
{
	return [RZUserDefaults() colorForKey:@"User List Mode Badge Colors —> +o"];
}

- (NSColor *)userMarkBadgeBackgroundColor_H
{
	return [RZUserDefaults() colorForKey:@"User List Mode Badge Colors —> +h"];
}

- (NSColor *)userMarkBadgeBackgroundColor_V
{
	return [RZUserDefaults() colorForKey:@"User List Mode Badge Colors —> +v"];
}

- (NSColor *)userMarkBadgeSelectedBackgroundColor
{
	return [NSColor whiteColor];
}

- (NSColor *)userMarkBadgeNormalTextColor
{
	return [NSColor whiteColor];
}

- (NSColor *)userMarkBadgeSelectedTextColor
{
	return [NSColor defineUserInterfaceItem:[NSColor internalCalibratedRed:158 green:169 blue:197 alpha:1.0]
							   invertedItem:[NSColor internalCalibratedRed:36.0 green:36.0 blue:36.0 alpha:1.0]];
}

- (NSColor *)userMarkBadgeShadowColor
{
	return [NSColor defineUserInterfaceItem:[NSColor colorWithCalibratedWhite:1.00 alpha:0.60]
							   invertedItem:[NSColor internalCalibratedRed:60.0 green:60.0 blue:60.0 alpha:1.0]];
}

- (NSFont *)userMarkBadgeFont
{
	return [RZFontManager() fontWithFamily:@"Helvetica" traits:NSBoldFontMask weight:15 size:11.0];
}

- (NSInteger)userMarkBadgeMargin
{
	return 5.0;
}

- (NSInteger)userMarkBadgeWidth
{
	return 18.0;
}

- (NSInteger)userMarkBadgeHeight
{
	return 14.0;
}

- (NSPoint)userMarkBadgeTextOrigin_Normal
{
	return NSMakePoint(7, 5);
}

- (NSPoint)userMarkBadgeTextOrigin_AtSign /* @ */
{
	return NSMakePoint(5, 4);
}

- (NSPoint)userMarkBadgeTextOrigin_AndSign /* & */
{
	return NSMakePoint(6, 4);
}

- (NSPoint)userMarkBadgeTextOrigin_PercentSign /* % */
{
	return NSMakePoint(5, 4);
}

- (NSPoint)userMarkBadgeTextOrigin_ExclamationMark /* ! */
{
	return NSMakePoint(7, 4);
}

- (NSFont *)normalCellFont
{
	if ([TPCPreferences useLargeFontForSidebars]) {
		return [NSFont fontWithName:@"LucidaGrande" size:12.0];
	} else {
		return [NSFont fontWithName:@"LucidaGrande" size:11.0];
	}
}

- (NSFont *)selectedCellFont
{
	if ([TPCPreferences useLargeFontForSidebars]) {
		return [NSFont fontWithName:@"LucidaGrande-Bold" size:12.0];
	} else {
		return [NSFont fontWithName:@"LucidaGrande-Bold" size:11.0];
	}
}

- (NSColor *)normalCellTextColor
{
	return [NSColor defineUserInterfaceItem:[NSColor blackColor]
							   invertedItem:[NSColor internalCalibratedRed:225.0 green:224.0 blue:224.0 alpha:1.0]];
}

- (NSColor *)awayUserCellTextColor
{
	return [NSColor defineUserInterfaceItem:[NSColor colorWithCalibratedWhite:0.0 alpha:0.6]
							   invertedItem:[NSColor internalCalibratedRed:225.0 green:224.0 blue:224.0 alpha:0.6]];
}

- (NSColor *)selectedCellTextColor
{
	return [NSColor defineUserInterfaceItem:[NSColor whiteColor]
							   invertedItem:[NSColor internalCalibratedRed:36.0 green:36.0 blue:36.0 alpha:1.0]];
}

- (NSColor *)normalCellTextShadowColor
{
	return [NSColor defineUserInterfaceItem:[NSColor colorWithSRGBRed:1.0 green:1.0 blue:1.0 alpha:0.6]
							   invertedItem:[NSColor colorWithCalibratedWhite:0.00 alpha:0.90]];
}

- (NSColor *)normalSelectedCellTextShadowColorForActiveWindow
{
	return [NSColor defineUserInterfaceItem:[NSColor colorWithCalibratedWhite:0.00 alpha:0.48]
							   invertedItem:[NSColor colorWithCalibratedWhite:1.00 alpha:0.30]];
}

- (NSColor *)normalSelectedCellTextShadowColorForInactiveWindow
{
	return [NSColor defineUserInterfaceItem:[NSColor colorWithCalibratedWhite:0.00 alpha:0.30]
							   invertedItem:[NSColor colorWithCalibratedWhite:1.00 alpha:0.30]];
}

- (NSColor *)graphiteSelectedCellTextShadowColorForActiveWindow
{
	return [NSColor internalCalibratedRed:17 green:73 blue:126 alpha:1.00];
}

@end
