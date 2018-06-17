/* *********************************************************************
 *                  _____         _               _
 *                 |_   _|____  _| |_ _   _  __ _| |
 *                   | |/ _ \ \/ / __| | | |/ _` | |
 *                   | |  __/>  <| |_| |_| | (_| | |
 *                   |_|\___/_/\_\\__|\__,_|\__,_|_|
 *
 * Copyright (c) 2010 - 2016 Codeux Software, LLC & respective contributors.
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

#import "NSObjectHelperPrivate.h"
#import "TXMasterController.h"
#import "IRCAddressBookUserTracking.h"
#import "IRCClient.h"
#import "IRCWorld.h"
#import "TPCPreferencesLocal.h"
#import "TVCMainWindowPrivate.h"
#import "TDCChannelSpotlightAppearanceInternal.h"
#import "TDCChannelSpotlightSearchResultPrivate.h"
#import "TDCChannelSpotlightSearchResultsTablePrivate.h"
#import "TDCChannelSpotlightControllerPanelPrivate.h"
#import "TDCChannelSpotlightControllerInternal.h"

NS_ASSUME_NONNULL_BEGIN

#define WindowDefaultHeight								221.0
@interface TDCChannelSpotlightController ()
@property (nonatomic, weak) TVCMainWindow *parentWindow;
@property (nonatomic, strong, readwrite) TDCChannelSpotlightAppearance *userInterfaceObjects;
@property (nonatomic, weak) IBOutlet NSVisualEffectView *visualEffectView;
@property (nonatomic, weak) IBOutlet NSTextField *noResultsLabel;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *noResultsLabelLeadingConstraint;
@property (nonatomic, weak) IBOutlet NSView *searchResultsView;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *searchResultsViewHeightConstraint;
@property (nonatomic, weak) IBOutlet NSTextField *searchField;
@property (nonatomic, weak) IBOutlet NSTableView *searchResultsTable;
@property (nonatomic, strong) IBOutlet NSArrayController *searchResultsController;
@property (nonatomic, strong) id mouseEventMonitor;
@end

@implementation TDCChannelSpotlightController

#pragma mark -
#pragma mark Initialization

ClassWithDesignatedInitializerInitMethod

- (instancetype)initWithParentWindow:(TVCMainWindow *)parentWindow
{
	NSParameterAssert(parentWindow != nil);

	if ((self = [super init])) {
		self.parentWindow = parentWindow;

		[self prepareInitialState];

		return self;
	}

	return nil;
}

- (void)prepareInitialState
{
	(void)[RZMainBundle() loadNibNamed:@"TDCChannelSpotlightController" owner:self topLevelObjects:nil];

	self.searchResultsTable.doubleAction = @selector(delegatePostSelectChannelForDoubleClickedRow:);

	self.mouseEventMonitor =
	[NSEvent addLocalMonitorForEventsMatchingMask:(NSLeftMouseDownMask |
												   NSOtherMouseDownMask |
												   NSRightMouseDownMask |
												   NSMouseEnteredMask |
												   NSKeyDownMask)
										  handler:^NSEvent *(NSEvent *event) {
											  return [self respondToLocalEvent:event];
										  }];

	if ([TPCPreferences channelNavigationIsServerSpecific]) {
		NSString *clientId = mainWindow().selectedClient.uniqueIdentifier;

		self.searchResultsController.filterPredicate = [NSPredicate predicateWithFormat:@"distance >= 0.5 && clientId LIKE[c] %@", clientId];
	} else {
		self.searchResultsController.filterPredicate = [NSPredicate predicateWithFormat:@"distance >= 0.5"];
	}

	self.searchResultsController.sortDescriptors = @[
		[NSSortDescriptor sortDescriptorWithKey:@"distance" ascending:NO selector:@selector(compare:)]
	];

	[RZNotificationCenter() addObserver:self selector:@selector(clientListChanged:) name:IRCWorldClientListWasModifiedNotification object:nil];

	[RZNotificationCenter() addObserver:self selector:@selector(channelListChanged:) name:IRCClientChannelListWasModifiedNotification object:nil];

	[RZNotificationCenter() addObserver:self selector:@selector(parentWindowAppearanceChanged:) name:TVCMainWindowAppearanceChangedNotification object:self.parentWindow];

//	[RZNotificationCenter() addObserver:self selector:@selector(parentWindowMoved:) name:NSWindowDidMoveNotification object:self.parentWindow];
	[RZNotificationCenter() addObserver:self selector:@selector(parentWindowResized:) name:NSWindowDidResizeNotification object:self.parentWindow];

	[self populateArrayController];

	[self updateBackgroundColor];

	[self.noResultsLabelLeadingConstraint archiveConstant];

	[self.searchResultsViewHeightConstraint archiveConstant];

	[self updateControlsState];
}

#pragma mark -
#pragma mark Appearance

- (void)resetWindowFrame
{
	NSRect remoteFrame = self.parentWindow.frame;

	NSRect localFrame = self.window.frame;

	localFrame.size.height = WindowDefaultHeight;

	localFrame = NSRectCenteredInRect(localFrame, remoteFrame);

	[self.window setFrame:localFrame display:NO animate:NO];
}

- (void)updateVibrancy
{
	NSAppearance *appearance = nil;

	if ([self appearsVibrantDark]) {
		appearance = [NSAppearance appearanceNamed:NSAppearanceNameVibrantDark];
	} else {
		appearance = [NSAppearance appearanceNamed:NSAppearanceNameVibrantLight];
	}

	self.visualEffectView.appearance = appearance;
}

- (void)updateBackgroundColor
{
	[self updateVibrancy];

	[self updateControlsAppearance];
}

- (void)updateControlsAppearance
{
	if ([self appearsVibrantDark]) {
		self.noResultsLabel.textColor = [self noResultsLabelTextColorVibrantDark];
	} else {
		self.noResultsLabel.textColor = [self noResultsLabelTextColorVibrantLight];
	}
}

- (void)updateControlsState
{
	NSString *searchString = self.searchField.stringValue;

	if (searchString.length == 0) {
		self.noResultsLabel.stringValue = @"";

		[self.noResultsLabelLeadingConstraint zeroOutConstant];

		[self.searchResultsViewHeightConstraint zeroOutConstant];

		return;
	}

	if (self.searchResultsCount == 0) {
		self.noResultsLabel.stringValue = @"No Results";

		[self.noResultsLabelLeadingConstraint restoreArchivedConstant];

		[self.searchResultsViewHeightConstraint zeroOutConstant];

		return;
	}

	self.noResultsLabel.stringValue = @"";

	[self.noResultsLabelLeadingConstraint zeroOutConstant];

	[self.searchResultsViewHeightConstraint restoreArchivedConstant];

	[self selectFirstSearchResultIfNecessary];
}

- (NSColor *)noResultsLabelTextColorVibrantLight
{
	return [NSColor secondaryLabelColor];
}

- (NSColor *)noResultsLabelTextColorVibrantDark
{
	return [NSColor colorWithCalibratedWhite:0.8 alpha:1.0];
}

- (BOOL)appearsVibrantDark
{
	return ((TDCChannelSpotlightControllerPanel *)self.window).usingDarkAppearance;
}

#pragma mark -
#pragma mark Appearance 

- (nullable NSEvent *)respondToLocalEvent:(NSEvent *)event
{
	switch (event.type) {
		case NSKeyDown:
		{
			return [self respondToKeyDownEvent:event];
		}
		case NSLeftMouseDown:
		case NSOtherMouseDown:
		case NSRightMouseDown:
		{
			return [self respondToMouseDownEvent:event];
		}
		default:
		{
			return nil;
		}
	}
}

- (nullable NSEvent *)respondToMouseDownEvent:(NSEvent *)event
{
	/* Allow out of focus window to reappear by passing event */
	if (self.window.isKeyWindow == NO && event.type == NSLeftMouseDown) {
		[self.window makeKeyWindow];

		return event;
	}

	/* Allow any event that occurs within child window */
	NSPoint mouseLocation = [NSEvent mouseLocation];

	NSRect windowFrame = self.window.frame;

	if (NSPointInRect(mouseLocation, windowFrame)) {
		return event;
	}

	/* Process events that occur outside of child window */
	return [self respondToMouseDownEventOutOfBounds:event atLocation:mouseLocation];
}

- (nullable NSEvent *)respondToMouseDownEventOutOfBounds:(NSEvent *)event atLocation:(NSPoint)mouseLocation
{
	TVCMainWindowMouseLocation parentWindowMouseLocation = [self.parentWindow locationOfMouse:mouseLocation];

	BOOL mouseIsOverParenWindow = ((parentWindowMouseLocation & TVCMainWindowMouseLocationInsideWindow) == TVCMainWindowMouseLocationInsideWindow);
	BOOL mouseIsOverParentTitle = ((parentWindowMouseLocation & TVCMainWindowMouseLocationInsideWindowTitle) == TVCMainWindowMouseLocationInsideWindowTitle);
	BOOL mouseIsOverParentTitleControl = ((parentWindowMouseLocation & TVCMainWindowMouseLocationOnTopOfWindowTitleControl) == TVCMainWindowMouseLocationOnTopOfWindowTitleControl);

	/* If the event is occurring outside the bounds of the parent window,
	 then allow the event to proceed uninterrupted */
	if (mouseIsOverParenWindow == NO) {
		return event;
	}

	/* If the event is occurring inside the title of the parent window,
	 but not on a button (close, miniaturize, zoom), then allow the event
	 to proceed uninterrupted. This allow uses to drag the parent window
	 around without allowing the user to access controls. */
	if (mouseIsOverParentTitle) {
		if (mouseIsOverParentTitleControl) {
			return nil;
		}

		return event;
	}

	/* Close window and allow event to proceed */
	[self close];

	return event;
}

- (nullable NSEvent *)respondToKeyDownEvent:(NSEvent *)event
{
	switch (event.keyCode) {
		case 2: // d
		{
			/* Close dialog using keyboard shortcut used to open it */
			NSUInteger keyboardKeys = (event.modifierFlags & NSDeviceIndependentModifierFlagsMask);

			if (keyboardKeys == NSCommandKeyMask) {
				[self close];

				return nil;
			}

			return event;
		}
		case 18 ... 23: // 0-9 (top row)
		case 25 ... 26:
		case 28 ... 29:
		case 82 ... 92: // 0-9 (number pad)
		{
			NSUInteger keyboardKeys = (event.modifierFlags & NSDeviceIndependentModifierFlagsMask);

			keyboardKeys &= ~NSNumericPadKeyMask;

			if (keyboardKeys == NSCommandKeyMask) {
				return [self handleCommandNumberEvent:event];
			}

			return event;
		}
		case 36: // return
		case 76: // enter
		{
			[self delegatePostSelectChannelForSelectedRow];

			return nil;
		}
		case 53: // escape
		{
			[self close];

			return nil;
		}
		case 126: // arrow up
		case 125: // arrow down
		case 116: // page up
		case 121: // page down
		{
			return [self handlePageUpDownEvent:event];
		}
	}

	return event;
}

- (nullable NSEvent *)handlePageUpDownEvent:(NSEvent *)event
{
	NSUInteger searchResultsCount = self.searchResultsCount;

	if (searchResultsCount == 0) {
		return nil;
	}

	NSInteger selectedRow = self.searchResultsTable.selectedRow;

	// Wrap around table when we reach the top or bottom
	if (event.keyCode == 126 || event.keyCode == 116) { // up
		if (selectedRow == 0) {
			[self.searchResultsTable selectItemAtIndex:(searchResultsCount - 1)];

			return nil;
		}
	} else if (event.keyCode == 125 || event.keyCode == 121) { // down
		if (selectedRow == (searchResultsCount - 1)) {
			[self.searchResultsTable selectItemAtIndex:0];

			return nil;
		}
	}

	[self.searchResultsTable keyDown:event];

	return nil;
}

- (nullable NSEvent *)handleCommandNumberEvent:(NSEvent *)event
{
	 NSInteger numberPressed = event.characters.integerValue;

	if (numberPressed < 0 || numberPressed > 9) {
		return event;
	}

	NSInteger arrayIndex = (numberPressed - 1);

	if (arrayIndex < 0) {
		arrayIndex = 9;
	}

	[self delegatePostSelectChannelForSearchResultAtIndex:arrayIndex];

	return nil;
}

- (void)delegatePostSelectChannelForDoubleClickedRow:(id)sender
{
	NSInteger clickedRow = self.searchResultsTable.clickedRow;

	[self delegatePostSelectChannelForSearchResultAtIndex:clickedRow];
}

- (void)delegatePostSelectChannelForSelectedRow
{
	NSInteger selectedRow = self.searchResultsTable.selectedRow;

	[self delegatePostSelectChannelForSearchResultAtIndex:selectedRow];
}

- (void)delegatePostSelectChannelForSearchResultAtIndex:(NSInteger)searchResultIndex
{
	NSArray<TDCChannelSpotlightSearchResult *> *searchResults = self.searchResultsFiltered;

	if (searchResultIndex < 0 || searchResultIndex >= searchResults.count) {
		return;
	}

	TDCChannelSpotlightSearchResult *searchResult = searchResults[searchResultIndex];

	IRCChannel *channel = searchResult.channel;

	[self delegatePostSelectChannel:channel];
}

- (void)delegatePostSelectChannel:(IRCChannel *)channel
{
	NSParameterAssert(channel != nil);

	if ([self.delegate respondsToSelector:@selector(channelSpotlightController:selectChannel:)]) {
		[self.delegate channelSpotlightController:self selectChannel:channel];
	}

	[self close];
}

#pragma mark -
#pragma mark Window Management

- (void)close
{
	[self.window close];
}

- (void)show
{
	if (self.window.parentWindow == nil) { // allow -show to be called multiple times
		[self.parentWindow addChildWindow:self.window ordered:NSWindowAbove];
	}

	[self.window makeKeyWindow];

	[self resetWindowFrame];
}

#pragma mark -
#pragma mark Search Field

- (NSString *)searchString
{
	return self.searchField.stringValue;
}

#pragma mark -
#pragma mark Search Results

- (void)selectFirstSearchResultIfNecessary
{
	NSInteger selectedRow = self.searchResultsTable.selectedRow;

	if (selectedRow < 0) {
		[self.searchResultsTable selectItemAtIndex:0];
	}
}

- (NSArray<TDCChannelSpotlightSearchResult *> *)searchResults
{
	return self.searchResultsController.content;
}

- (NSArray<TDCChannelSpotlightSearchResult *> *)searchResultsFiltered
{
	return self.searchResultsController.arrangedObjects;
}

- (NSUInteger)searchResultsCount
{
	return ((NSArray *)self.searchResultsController.arrangedObjects).count;
}

- (NSInteger)selectedSearchResult
{
	return self.searchResultsTable.selectedRow;
}

- (void)recalculateDistanceForSearchResults
{
	NSString *searchString = self.searchField.stringValue;

	NSArray<TDCChannelSpotlightSearchResult *> *searchResults = self.searchResults;

	for (TDCChannelSpotlightSearchResult *searchResult in searchResults) {
		[searchResult recalculateDistanceWith:searchString];
	}

	[self updateControlsState];
}

- (void)populateArrayController
{
	NSPredicate *filterPredicate = self.searchResultsController.filterPredicate;

	self.searchResultsController.filterPredicate = nil;

	NSString *searchString = self.searchField.stringValue;

	NSMutableArray<TDCChannelSpotlightSearchResult *> *searchResults = [NSMutableArray array];

	for (IRCClient *client in worldController().clientList) {
		for (IRCChannel *channel in client.channelList) {
			TDCChannelSpotlightSearchResult *searchResult = [self searchResultForChannel:channel];

			[searchResult recalculateDistanceWith:searchString];

			[searchResults addObject:searchResult];
		}
	}

	[self.searchResultsController removeAllArrangedObjects];

	[self.searchResultsController addObjects:searchResults];

	self.searchResultsController.filterPredicate = filterPredicate;
}

- (TDCChannelSpotlightSearchResult *)searchResultForChannel:(IRCChannel *)channel
{
	NSParameterAssert(channel != nil);

	TDCChannelSpotlightSearchResult *searchResult = [[TDCChannelSpotlightSearchResult alloc] initWithChannel:channel];

	return searchResult;
}

#pragma mark -
#pragma mark Table View Delegate

- (nullable NSTableRowView *)tableView:(NSTableView *)tableView rowViewForRow:(NSInteger)row
{
	return [[TDCChannelSpotlightSearchResultRowView alloc] initWithFrame:NSZeroRect];
}

#pragma mark -
#pragma mark Notifications

- (void)clientListChanged:(id)sender
{
	[self populateArrayController];
}

- (void)channelListChanged:(id)sender
{
	[self populateArrayController];
}

- (void)controlTextDidChange:(NSNotification *)notification
{
	if (notification.object == self.searchField) {
		[self recalculateDistanceForSearchResults];
	}
}

- (void)parentWindowAppearanceChanged:(NSNotification *)notification
{
	[self updateBackgroundColor];
}

/*
- (void)parentWindowMoved:(NSNotification *)notification
{
	[self resetWindowFrame];
}
*/

- (void)parentWindowResized:(NSNotification *)notification
{
	[self resetWindowFrame];
}

- (void)windowWillClose:(NSNotification *)notification
{
	[NSEvent removeMonitor:self.mouseEventMonitor];

	self.mouseEventMonitor = nil;

	[RZNotificationCenter() removeObserver:self];

	[self.parentWindow removeChildWindow:self.window];

	if ([self.delegate respondsToSelector:@selector(channelSpotlightControllerWillClose:)]) {
		[self.delegate channelSpotlightControllerWillClose:self];
	}
}

@end

NS_ASSUME_NONNULL_END
