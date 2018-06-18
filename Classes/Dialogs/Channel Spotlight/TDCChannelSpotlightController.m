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
#import "TLOLicenseManagerPrivate.h"
#import "TLOLanguagePreferences.h"
#import "TVCMainWindowPrivate.h"
#import "TDCInAppPurchaseDialogPrivate.h"
#import "TDCLicenseManagerDialogPrivate.h"
#import "TDCChannelSpotlightAppearanceInternal.h"
#import "TDCChannelSpotlightSearchResultPrivate.h"
#import "TDCChannelSpotlightSearchResultsTablePrivate.h"
#import "TDCChannelSpotlightControlsPrivate.h"
#import "TDCChannelSpotlightControllerInternal.h"

NS_ASSUME_NONNULL_BEGIN

@interface TDCChannelSpotlightController () <NSTableViewDataSource, NSTableViewDelegate>
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

- (instancetype)init
{
	if ((self = [super init])) {
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
	[NSEvent addLocalMonitorForEventsMatchingMask:NSKeyDownMask
										  handler:^NSEvent *(NSEvent *event) {
											  return [self respondToKeyDownEvent:event];
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
	[RZNotificationCenter() addObserver:self selector:@selector(applicationAppearanceChanged:) name:TXApplicationAppearanceChangedNotification object:nil];

#if TEXTUAL_BUILT_WITH_LICENSE_MANAGER == 1
	[RZNotificationCenter() addObserver:self selector:@selector(licenseManagerDeactivatedLicense:) name:TDCLicenseManagerDeactivatedLicenseNotification object:nil];
	[RZNotificationCenter() addObserver:self selector:@selector(licenseManagerTrialExpired:) name:TDCLicenseManagerTrialExpiredNotification object:nil];
#endif

#if TEXTUAL_BUILT_FOR_APP_STORE_DISTRIBUTION == 1
	[RZNotificationCenter() addObserver:self selector:@selector(onInAppPurchaseTrialExpired:) name:TDCInAppPurchaseDialogTrialExpiredNotification object:nil];
#endif

	[self populateArrayController];

	[self applicationAppearanceChanged];

	[self.noResultsLabelLeadingConstraint archiveConstant];

	[self.searchResultsViewHeightConstraint archiveConstant];

	[self updateControlsState];
}

#pragma mark -
#pragma mark Appearance

- (void)applicationAppearanceChanged:(NSNotification *)notification
{
	[self applicationAppearanceChanged];
}

- (void)applicationAppearanceChanged
{
	TDCChannelSpotlightAppearance *appearance = [[TDCChannelSpotlightAppearance alloc] initWithWindow:(id)self.window];

	self.userInterfaceObjects = appearance;

	[self updateVibrancyWithAppearance:appearance];

	[self updateControlsWithAppearance:appearance];

	[self updateSearchResultsSelection];
}

- (void)updateVibrancyWithAppearance:(TDCChannelSpotlightAppearance *)appearance
{
	NSParameterAssert(appearance != nil);

	NSAppearance *appKitAppearance = appearance.appKitAppearance;

	if (appearance.appKitAppearanceInherited == NO) {
		self.visualEffectView.appearance = appKitAppearance;

		return;
	}

	self.window.appearance = appKitAppearance;
}

- (void)updateControlsWithAppearance:(TDCChannelSpotlightAppearance *)appearance
{
	NSParameterAssert(appearance != nil);

	self.searchField.textColor = appearance.searchFieldTextColor;

	self.noResultsLabel.textColor = appearance.searchFieldNoResultsTextColor;
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
		self.noResultsLabel.stringValue = TXTLS(@"TDCChannelSpotlightController[1008]");

		[self.noResultsLabelLeadingConstraint restoreArchivedConstant];

		[self.searchResultsViewHeightConstraint zeroOutConstant];

		return;
	}

	self.noResultsLabel.stringValue = @"";

	[self.noResultsLabelLeadingConstraint zeroOutConstant];

	[self.searchResultsViewHeightConstraint restoreArchivedConstant];

	[self selectFirstSearchResultIfNecessary];
}

- (void)updateSearchResultsSelection
{
	NSTableView *table = self.searchResultsTable;

	[table invalidateBackgroundForSelection];
}

#pragma mark -
#pragma mark Appearance

- (nullable NSEvent *)respondToKeyDownEvent:(NSEvent *)event
{
	if (self.window.isKeyWindow == NO) {
		return event;
	}

	switch (event.keyCode) {
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
			[self clearSearchStringOrClose];

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

- (void)clearSearchStringOrClose
{
	/* Mimic Spotlight behavior by clearing search string
	 on first escape and closing on second escape. */
	if (self.searchField.stringValue.length > 0) {
		self.searchField.stringValue = @"";

		[self searchStringChanged];

		return;
	}

	[self close];
}

- (void)close
{
	[self.window close];
}

- (void)show
{
#warning TODO: Remember window position

	[self.window makeKeyAndOrderFront:nil];
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

- (void)searchStringChanged
{
	[self recalculateDistanceForSearchResults];
}

#pragma mark -
#pragma mark Table View Delegate

- (nullable NSTableRowView *)tableView:(NSTableView *)tableView rowViewForRow:(NSInteger)row
{
	return [[TDCChannelSpotlightSearchResultRowView alloc] initWithController:self];
}

#pragma mark -
#pragma mark Notifications

- (void)clientListChanged:(id)sender
{
	[self populateArrayController];

	[self updateControlsState];
}

- (void)channelListChanged:(id)sender
{
	[self populateArrayController];

	[self updateControlsState];
}

- (void)controlTextDidChange:(NSNotification *)notification
{
	if (notification.object == self.searchField) {
		[self searchStringChanged];
	}
}

#if TEXTUAL_BUILT_WITH_LICENSE_MANAGER == 1
- (void)licenseManagerDeactivatedLicense:(NSNotification *)notification
{
	if (TLOLicenseManagerIsTrialExpired() == NO) {
		return;
	}

	[self close];
}

- (void)licenseManagerTrialExpired:(NSNotification *)notification
{
	[self close];
}
#endif

#if TEXTUAL_BUILT_FOR_APP_STORE_DISTRIBUTION == 1
- (void)onInAppPurchaseTrialExpired:(NSNotification *)notification
{
	[self close];
}
#endif

- (void)windowWillClose:(NSNotification *)notification
{
	[NSEvent removeMonitor:self.mouseEventMonitor];

	self.mouseEventMonitor = nil;

	[RZNotificationCenter() removeObserver:self];

	if ([self.delegate respondsToSelector:@selector(channelSpotlightControllerWillClose:)]) {
		[self.delegate channelSpotlightControllerWillClose:self];
	}
}

@end

NS_ASSUME_NONNULL_END
