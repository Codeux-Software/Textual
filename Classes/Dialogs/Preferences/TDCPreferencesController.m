/* *********************************************************************
 *                  _____         _               _
 *                 |_   _|____  _| |_ _   _  __ _| |
 *                   | |/ _ \ \/ / __| | | |/ _` | |
 *                   | |  __/>  <| |_| |_| | (_| | |
 *                   |_|\___/_/\_\\__|\__,_|\__,_|_|
 *
 * Copyright (c) 2008 - 2010 Satoshi Nakagawa <psychs AT limechat DOT net>
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

#import "NSViewHelper.h"
#import "TXMasterController.h"
#import "TXMenuController.h"
#import "TPCPathInfoPrivate.h"
#import "TPCPreferencesCloudSyncPrivate.h"
#import "TPCPreferencesCloudSyncExtensionPrivate.h"
#import "TPCPreferencesLocalPrivate.h"
#import "TPCPreferencesReload.h"
#import "TPCPreferencesUserDefaults.h"
#import "TPCThemeControllerPrivate.h"
#import "THOPluginManagerPrivate.h"
#import "IRC.h"
#import "IRCClientConfig.h"
#import "IRCClient.h"
#import "IRCConnectionConfig.h"
#import "IRCWorld.h"
#import "TLOAppStoreManagerPrivate.h"
#import "TLOEncryptionManagerPrivate.h"
#import "TLOLanguagePreferences.h"
#import "TVCMainWindowPrivate.h"
#import "TVCNotificationConfigurationViewControllerPrivate.h"
#import "TDCAlert.h"
#import "TDCInAppPurchaseDialogPrivate.h"
#import "TDCFileTransferDialogPrivate.h"
#import "TDCPreferencesNotificationConfigurationPrivate.h"
#import "TDCPreferencesControllerPrivate.h"

#if TEXTUAL_BUILT_WITH_SPARKLE_ENABLED == 1
#import <Sparkle/Sparkle.h>
#endif

NS_ASSUME_NONNULL_BEGIN

#define _scrollbackSaveLinesMin		100
#define _scrollbackSaveLinesMax		50000
#define _scrollbackVisibleLinesMin	100
#define _scrollbackVisibleLinesMax	15000
#define _inlineMediaWidthMax		2000
#define _inlineMediaWidthMin		40
#define _inlineMediaHeightMax		6000
#define _inlineMediaHeightMin		0

#define _fileTransferPortRangeMin			1024
#define _fileTransferPortRangeMax			TXMaximumTCPPort

#define _toolbarItemIndexGeneral					101
#define _toolbarItemIndexHighlights					104
#define _toolbarItemIndexNotifications				103
#define _toolbarItemIndexBehavior					102
#define _toolbarItemIndexControls					107
#define _toolbarItemIndexInterface					105
#define _toolbarItemIndexStyle						106
#define _toolbarItemIndexAddons						109
#define _toolbarItemIndexAdvanced					108

#define _toolbarItemIndexChannelManagement			108000
#define _toolbarItemIndexCommandScope				108001
#define _toolbarItemIndexFloodControl				108002
#define _toolbarItemIndexIncomingData				108003
#define _toolbarItemIndexCompatibility				108004
#define _toolbarItemIndexFileTransfers				108005
#define _toolbarItemIndexInlineMedia				108006
#define _toolbarItemIndexLogLocation				108007
#define _toolbarItemIndexDefaultIdentity			108008
#define _toolbarItemIndexDefaultIRCopMessages		108009
#define _toolbarItemIndexOffRecordMessaging			108010
#define _toolbarItemIndexHiddenPreferences			108011 // unused

#define _addonsToolbarInstalledAddonsMenuItemIndex		109000
#define _addonsToolbarItemMultiplier					995

#define _unsignedIntegerString(_value_)			[NSString stringWithUnsignedInteger:_value_]

@interface TDCPreferencesController ()
@property (nonatomic, strong) IBOutlet NSArrayController *excludeKeywordsArrayController;
@property (nonatomic, strong) IBOutlet NSArrayController *highlightKeywordsArrayController;
@property (nonatomic, strong) IBOutlet NSArrayController *installedScriptsController;
@property (nonatomic, weak) IBOutlet NSButton *addExcludeKeywordButton;
@property (nonatomic, weak) IBOutlet NSButton *highlightNicknameButton;
@property (nonatomic, weak) IBOutlet NSPopUpButton *themeSelectionButton;
@property (nonatomic, weak) IBOutlet NSPopUpButton *transcriptFolderButton;
@property (nonatomic, weak) IBOutlet NSPopUpButton *fileTransferDownloadDestinationButton;
@property (nonatomic, weak) IBOutlet NSTableView *excludeKeywordsTable;
@property (nonatomic, weak) IBOutlet NSTableView *installedScriptsTable;
@property (nonatomic, weak) IBOutlet NSTableView *highlightKeywordsTable;
@property (nonatomic, weak) IBOutlet NSTextField *fileTransferManuallyEnteredIPAddressTextField;
@property (nonatomic, strong) IBOutlet NSView *contentViewGeneral;
@property (nonatomic, strong) IBOutlet NSView *contentViewHighlights;
@property (nonatomic, strong) IBOutlet NSView *contentViewNotifications;
@property (nonatomic, strong) IBOutlet NSView *contentViewBehavior;
@property (nonatomic, strong) IBOutlet NSView *contentViewControls;
@property (nonatomic, strong) IBOutlet NSView *contentViewInterface;
@property (nonatomic, strong) IBOutlet NSView *contentViewStyle;
@property (nonatomic, strong) IBOutlet NSView *contentViewInstalledAddons;
@property (nonatomic, strong) IBOutlet NSView *contentViewChannelManagement;
@property (nonatomic, strong) IBOutlet NSView *contentViewCommandScope;
@property (nonatomic, strong) IBOutlet NSView *contentViewCompatibility;
@property (nonatomic, strong) IBOutlet NSView *contentViewFloodControl;
@property (nonatomic, strong) IBOutlet NSView *contentViewIncomingData;
@property (nonatomic, strong) IBOutlet NSView *contentViewFileTransfers;
@property (nonatomic, strong) IBOutlet NSView *contentViewInlineMedia;
@property (nonatomic, strong) IBOutlet NSView *contentViewLogLocation;
@property (nonatomic, strong) IBOutlet NSView *contentViewDefaultIdentity;
@property (nonatomic, strong) IBOutlet NSView *contentViewDefaultIRCopMessages;

#if TEXTUAL_BUILT_WITH_ADVANCED_ENCRYPTION == 1
@property (nonatomic, strong) IBOutlet NSView *contentViewOffRecordMessaging;
#endif

@property (nonatomic, strong) IBOutlet NSView *contentViewICloud;
@property (nonatomic, strong) IBOutlet NSView *contentViewHiddenPreferences;

@property (nonatomic, strong) IBOutlet NSView *contentView;
@property (nonatomic, strong) IBOutlet NSView *shareDataBetweenDevicesView;
@property (nonatomic, weak) IBOutlet NSMatrix *checkForUpdatesMatrix;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *checkForUpdatesHeightConstraint;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *shareDataBetweenDevicesViewHeightConstraint;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *contentViewHeightConstraint;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *contentViewWidthConstraint;
@property (nonatomic, strong) IBOutlet NSToolbar *navigationToolbar;
@property (nonatomic, strong) IBOutlet NSMenu *installedAddonsMenu;
@property (nonatomic, assign) BOOL reloadingTheme;
@property (nonatomic, assign) BOOL reloadingThemeBySelection;
@property (nonatomic, weak) IBOutlet NSView *notificationControllerHostView;
@property (nonatomic, strong) IBOutlet TVCNotificationConfigurationViewController *notificationController;

- (IBAction)onAddExcludeKeyword:(id)sender;
- (IBAction)onAddHighlightKeyword:(id)sender; // changed
- (IBAction)onChangedAppearance:(id)sender;
- (IBAction)onChangedCheckForUpdates:(id)sender;
- (IBAction)onChangedCheckForBetaUpdates:(id)sender;
- (IBAction)onChangedChannelViewArrangement:(id)sender;
- (IBAction)onChangedCloudSyncingServices:(id)sender;
- (IBAction)onChangedCloudSyncingServicesServersOnly:(id)sender;
- (IBAction)onChangedDisableNicknameColorHashing:(id)sender;
- (IBAction)onChangedHighlightLogging:(id)sender;
- (IBAction)onChangedHighlightType:(id)sender;
- (IBAction)onChangedInlineMediaOption:(id)sender;
- (IBAction)onChangedInputHistoryScheme:(id)sender;
- (IBAction)onChangedMainInputTextViewFontSize:(id)sender; // changed
- (IBAction)onChangedMainWindowSegmentedController:(id)sender;
- (IBAction)onChangedScrollbackSaveLimit:(id)sender;
- (IBAction)onChangedScrollbackVisibleLimit:(id)sender;
- (IBAction)onChangedServerListUnreadBadgeColor:(id)sender;
- (IBAction)onChangedTheme:(id)sender;
- (IBAction)onChangedThemeSelection:(id)sender;  // changed
- (IBAction)onChangedTranscriptFolder:(id)sender;
- (IBAction)onChangedTransparency:(id)sender;
- (IBAction)onChangedUserListModeColor:(id)sender;
- (IBAction)onChangedUserListModeSortOrder:(id)sender;
- (IBAction)onFileTransferDownloadDestinationFolderChanged:(id)sender;
- (IBAction)onFileTransferIPAddressDetectionMethodChanged:(id)sender;
- (IBAction)onManageICloudButtonClicked:(id)sender; // changed
- (IBAction)onOpenPathToCloudFolder:(id)sender;
- (IBAction)onOpenPathToScripts:(id)sender;
- (IBAction)onOpenPathToTheme:(id)sender; // changed
- (IBAction)onPrefPaneSelected:(id)sender;
- (IBAction)onPurgeOfCloudDataRequested:(id)sender;
- (IBAction)onResetServerListUnreadBadgeColorsToDefault:(id)sender;
- (IBAction)onResetUserListModeColorsToDefaults:(id)sender;
- (IBAction)onSelectNewFont:(id)sender;

#if TEXTUAL_BUILT_WITH_ADVANCED_ENCRYPTION == 1
- (IBAction)offRecordMessagingPolicyChanged:(id)sender;
#endif
@end

@implementation TDCPreferencesController

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
	(void)[RZMainBundle() loadNibNamed:@"TDCPreferences" owner:self topLevelObjects:nil];
}

- (void)awakeFromNib
{
	[super awakeFromNib];

	NSMutableArray *notifications = [NSMutableArray array];

	[notifications addObject:[TDCPreferencesNotificationConfiguration objectWithEventType:TXNotificationAddressBookMatchType]];
	[notifications addObject:@" "];
	[notifications addObject:[TDCPreferencesNotificationConfiguration objectWithEventType:TXNotificationConnectType]];
	[notifications addObject:[TDCPreferencesNotificationConfiguration objectWithEventType:TXNotificationDisconnectType]];
	[notifications addObject:@" "];
	[notifications addObject:[TDCPreferencesNotificationConfiguration objectWithEventType:TXNotificationHighlightType]];
	[notifications addObject:@" "];
	[notifications addObject:[TDCPreferencesNotificationConfiguration objectWithEventType:TXNotificationInviteType]];
	[notifications addObject:[TDCPreferencesNotificationConfiguration objectWithEventType:TXNotificationKickType]];
	[notifications addObject:@" "];
	[notifications addObject:[TDCPreferencesNotificationConfiguration objectWithEventType:TXNotificationChannelMessageType]];
	[notifications addObject:[TDCPreferencesNotificationConfiguration objectWithEventType:TXNotificationChannelNoticeType]];
	[notifications addObject:@" "];
	[notifications addObject:[TDCPreferencesNotificationConfiguration objectWithEventType:TXNotificationNewPrivateMessageType]];
	[notifications addObject:[TDCPreferencesNotificationConfiguration objectWithEventType:TXNotificationPrivateMessageType]];
	[notifications addObject:[TDCPreferencesNotificationConfiguration objectWithEventType:TXNotificationPrivateNoticeType]];
	[notifications addObject:@" "];
	[notifications addObject:[TDCPreferencesNotificationConfiguration objectWithEventType:TXNotificationUserJoinedType]];
	[notifications addObject:[TDCPreferencesNotificationConfiguration objectWithEventType:TXNotificationUserPartedType]];
	[notifications addObject:[TDCPreferencesNotificationConfiguration objectWithEventType:TXNotificationUserDisconnectedType]];
	[notifications addObject:@" "];
	[notifications addObject:[TDCPreferencesNotificationConfiguration objectWithEventType:TXNotificationFileTransferReceiveRequestedType]];
	[notifications addObject:@" "];
	[notifications addObject:[TDCPreferencesNotificationConfiguration objectWithEventType:TXNotificationFileTransferSendSuccessfulType]];
	[notifications addObject:[TDCPreferencesNotificationConfiguration objectWithEventType:TXNotificationFileTransferReceiveSuccessfulType]];
	[notifications addObject:@" "];
	[notifications addObject:[TDCPreferencesNotificationConfiguration objectWithEventType:TXNotificationFileTransferSendFailedType]];
	[notifications addObject:[TDCPreferencesNotificationConfiguration objectWithEventType:TXNotificationFileTransferReceiveFailedType]];

	self.notificationController.notifications = notifications;

	[self.notificationController attachToView:self.notificationControllerHostView];

	[self setUpToolbarItemsAndMenus];

	[self updateCheckForUpdatesMatrix];
	[self updateFileTransferDownloadDestinationFolder];
	[self updateThemeSelection];
	[self updateTranscriptFolder];

	[self onChangedHighlightType:nil];

	[self onFileTransferIPAddressDetectionMethodChanged:nil];

	self.installedScriptsTable.sortDescriptors = @[
		[NSSortDescriptor sortDescriptorWithKey:@"string" ascending:YES selector:@selector(caseInsensitiveCompare:)]
	];

	[RZNotificationCenter() addObserver:self
							   selector:@selector(onCloudSyncControllerDidChangeThemeName:)
								   name:TPCThemeControllerThemeListDidChangeNotification
								 object:nil];

#if TEXTUAL_BUILT_WITH_ICLOUD_SUPPORT == 1
	[RZNotificationCenter() addObserver:self
							   selector:@selector(onCloudSyncControllerDidChangeThemeName:)
								   name:TPCPreferencesCloudSyncDidChangeThemeNameNotification
								 object:nil];
#endif

	[RZNotificationCenter() addObserver:self
							   selector:@selector(onThemeWillReload:)
								   name:TVCMainWindowWillReloadThemeNotification
								 object:nil];

	[RZNotificationCenter() addObserver:self
							   selector:@selector(onThemeReloadComplete:)
								   name:TVCMainWindowDidReloadThemeNotification
								 object:nil];

#if TEXTUAL_BUILT_FOR_APP_STORE_DISTRIBUTION == 1
	[RZNotificationCenter() addObserver:self
							   selector:@selector(onInAppPurchaseTrialExpired:)
								   name:TDCInAppPurchaseDialogTrialExpiredNotification
								 object:nil];

	[RZNotificationCenter() addObserver:self
							   selector:@selector(onInAppPurchaseTransactionFinished:)
								   name:TDCInAppPurchaseDialogTransactionFinishedNotification
								 object:nil];
#endif

#if TEXTUAL_BUILT_WITH_ICLOUD_SUPPORT == 0
	/* Hide "Share data between devices" when iCloud support is not enabled
	 by setting the subview height to 0. Set height before calling firstPane:
	 so that firstPane: can calculate the correct total height. */
	self.shareDataBetweenDevicesViewHeightConstraint.constant = 0.0;
#endif

#if TEXTUAL_BUILT_WITH_SPARKLE_ENABLED == 0
	self.checkForUpdatesHeightConstraint.constant = 0.0;
#endif

	[self.contentViewGeneral layoutSubtreeIfNeeded];

	[self restoreWindowFrame];
}

#pragma mark -
#pragma mark Utilities

- (void)show
{
	[self show:TDCPreferencesControllerDefaultNavigationSelection];
}

- (void)show:(TDCPreferencesControllerNavigationSelection)selection
{
	switch (selection) {
		case TDCPreferencesControllerStyleNavigationSelection:
		{
			[self _showPane:self.contentViewStyle selectedItem:_toolbarItemIndexStyle];

			break;
		}
		case TDCPreferencesControllerHiddenPreferencesNavigationSelection:
		{
			[self _showPane:self.contentViewHiddenPreferences selectedItem:_toolbarItemIndexAdvanced];

			break;
		}
		default:
		{
			[self _showPane:self.contentViewGeneral selectedItem:_toolbarItemIndexGeneral];

			break;
		}
	}
}

- (void)_showPane:(NSView *)view selectedItem:(NSInteger)selectedItem
{
	[self firstPane:view selectedItem:selectedItem];

	[super show];
}

#pragma mark -
#pragma mark NSToolbar Delegates

 - (void)setUpToolbarItemsAndMenus
{
	NSArray *plugins = sharedPluginManager().pluginsWithPreferencePanes;

	if (plugins.count > 0) {
		[self.installedAddonsMenu addItem:[NSMenuItem separatorItem]];
	}

	[plugins enumerateObjectsUsingBlock:^(THOPluginItem *plugin, NSUInteger index, BOOL *stop) {
		NSUInteger tagIndex = (index + _addonsToolbarItemMultiplier);

		NSMenuItem *pluginMenu = [NSMenuItem menuItemWithTitle:plugin.pluginPreferencesPaneMenuItemTitle
														target:self
														action:@selector(onPrefPaneSelected:)];

		pluginMenu.tag = tagIndex;

		[self.installedAddonsMenu addItem:pluginMenu];
	}];
}

 - (void)onPrefPaneSelected:(id)sender
{
#define _de(matchTag, view, selectionIndex)		\
		case (matchTag): {	\
			[self firstPane:(view) selectedItem:(selectionIndex)];	\
			break;		\
		}

	switch ([sender tag]) {

		_de(_toolbarItemIndexGeneral, self.contentViewGeneral, _toolbarItemIndexGeneral)

		_de(_toolbarItemIndexHighlights, self.contentViewHighlights, _toolbarItemIndexHighlights)
		_de(_toolbarItemIndexNotifications, self.contentViewNotifications, _toolbarItemIndexNotifications)

		_de(_toolbarItemIndexBehavior, self.contentViewBehavior, _toolbarItemIndexBehavior)
		_de(_toolbarItemIndexControls, self.contentViewControls, _toolbarItemIndexControls)
		_de(_toolbarItemIndexInterface, self.contentViewInterface, _toolbarItemIndexInterface)
		_de(_toolbarItemIndexStyle, self.contentViewStyle, _toolbarItemIndexStyle)

		_de(_toolbarItemIndexChannelManagement, self.contentViewChannelManagement, _toolbarItemIndexAdvanced)
		_de(_toolbarItemIndexCommandScope, self.contentViewCommandScope, _toolbarItemIndexAdvanced)
		_de(_toolbarItemIndexCompatibility, self.contentViewCompatibility, _toolbarItemIndexAdvanced)
		_de(_toolbarItemIndexFloodControl, self.contentViewFloodControl, _toolbarItemIndexAdvanced)
		_de(_toolbarItemIndexIncomingData, self.contentViewIncomingData, _toolbarItemIndexAdvanced)
		_de(_toolbarItemIndexFileTransfers, self.contentViewFileTransfers, _toolbarItemIndexAdvanced)
		_de(_toolbarItemIndexInlineMedia, self.contentViewInlineMedia, _toolbarItemIndexAdvanced)
		_de(_toolbarItemIndexLogLocation, self.contentViewLogLocation, _toolbarItemIndexAdvanced);
		_de(_toolbarItemIndexDefaultIdentity, self.contentViewDefaultIdentity, _toolbarItemIndexAdvanced)
		_de(_toolbarItemIndexDefaultIRCopMessages, self.contentViewDefaultIRCopMessages, _toolbarItemIndexAdvanced)

#if TEXTUAL_BUILT_WITH_ADVANCED_ENCRYPTION == 1
		_de(_toolbarItemIndexOffRecordMessaging, self.contentViewOffRecordMessaging, _toolbarItemIndexAdvanced)
#endif

		_de(_addonsToolbarInstalledAddonsMenuItemIndex, self.contentViewInstalledAddons, _toolbarItemIndexAddons)

		default:
		{
			if ([sender tag] < _addonsToolbarItemMultiplier) {
				break;
			}

			NSUInteger pluginIndex = ([sender tag] - _addonsToolbarItemMultiplier);

			THOPluginItem *plugin = sharedPluginManager().pluginsWithPreferencePanes[pluginIndex];

			NSView *preferencesView = plugin.pluginPreferencesPaneView;

			[self firstPane:preferencesView selectedItem:_toolbarItemIndexAddons];

			break;
		}
	}

#undef _de
}

- (void)firstPane:(NSView *)view selectedItem:(NSInteger)selectedItem
{
	[self.contentView attachSubview:view
			adjustedWidthConstraint:self.contentViewWidthConstraint
		   adjustedHeightConstraint:self.contentViewHeightConstraint];

	if (selectedItem >= 0) {
		self.navigationToolbar.selectedItemIdentifier = _unsignedIntegerString(selectedItem);
	} else {
		self.navigationToolbar.selectedItemIdentifier = nil;
	}
}

- (void)restoreWindowFrame
{
	NSWindow *window = self.window;

	[window saveSizeAsDefault];

	[window restoreWindowStateForClass:self.class];
}

- (void)saveWindowFrame
{
	/* When saving the final window frame, we remove the content view
	 before doing so then manually set the frame because if we were
	 to restore the original constant to the content view's height,
	 that will require a layout pass before window registers it.
	 We have no use for the content view or its constraints once
	 we know the height difference, so let's just discard it and go. */
	[self.contentView removeFromSuperview];

	NSWindow *window = self.window;

	[window restoreDefaultSizeAndDisplay:NO];

	[window saveWindowStateForClass:self.class];
}

#pragma mark -
#pragma mark KVC Properties

- (NSArray<NSDictionary *> *)installedScripts
{
	NSMutableArray *scriptsInstalled = [NSMutableArray array];

	[scriptsInstalled addObjectsFromArray:sharedPluginManager().supportedAppleScriptCommands];
	[scriptsInstalled addObjectsFromArray:sharedPluginManager().supportedUserInputCommands];

	return scriptsInstalled.stringArrayControllerObjects;
}

- (NSString *)scrollbackSaveLimit
{
	return _unsignedIntegerString([TPCPreferences scrollbackSaveLimit]);
}

- (void)setScrollbackSaveLimit:(NSString *)value
{
	[TPCPreferences setScrollbackSaveLimit:value.integerValue];
}

- (NSString *)scrollbackVisibleLimit
{
	return _unsignedIntegerString([TPCPreferences scrollbackVisibleLimit]);
}

- (void)setScrollbackVisibleLimit:(NSString *)value
{
	[TPCPreferences setScrollbackVisibleLimit:value.integerValue];
}

- (NSString *)completionSuffix
{
	return [TPCPreferences tabCompletionSuffix];
}

- (void)setCompletionSuffix:(NSString *)value
{
	[TPCPreferences setTabCompletionSuffix:value];
}

- (NSString *)inlineMediaMaxWidth
{
	return _unsignedIntegerString([TPCPreferences inlineMediaMaxWidth]);
}

- (NSString *)inlineMediaMaxHeight
{
	return _unsignedIntegerString([TPCPreferences inlineMediaMaxHeight]);
}

- (void)setInlineMediaMaxWidth:(NSString *)value
{
	[TPCPreferences setInlineMediaMaxWidth:value.integerValue];
}

- (void)setInlineMediaMaxHeight:(NSString *)value
{
	[TPCPreferences setInlineMediaMaxHeight:value.integerValue];
}

- (NSString *)themeChannelViewFontName
{
	NSFont *currentFont = [TPCPreferences themeChannelViewFont];

	return currentFont.displayName;
}

- (CGFloat)themeChannelViewFontSize
{
	return [TPCPreferences themeChannelViewFontSize];
}

- (void)setThemeChannelViewFontName:(NSString *)value
{
	return;
}

- (void)setThemeChannelViewFontSize:(CGFloat)value
{
	return;
}

- (NSString *)fileTransferPortRangeStart
{
	return _unsignedIntegerString([TPCPreferences fileTransferPortRangeStart]);
}

- (NSString *)fileTransferPortRangeEnd
{
	return _unsignedIntegerString([TPCPreferences fileTransferPortRangeEnd]);
}

- (void)setFileTransferPortRangeStart:(NSString *)value
{
	[TPCPreferences setFileTransferPortRangeStart:value.integerValue];
}

- (void)setFileTransferPortRangeEnd:(NSString *)value
{
	[TPCPreferences setFileTransferPortRangeEnd:value.integerValue];
}

#if TEXTUAL_BUILT_WITH_ADVANCED_ENCRYPTION == 1
- (void)setTextEncryptionIsOpportunistic:(BOOL)textEncryptionIsOpportunistic
{
	[TPCPreferences setTextEncryptionIsOpportunistic:textEncryptionIsOpportunistic];
}

- (BOOL)textEncryptionIsOpportunistic
{
	if ([TPCPreferences textEncryptionIsEnabled] == NO) {
		return NO;
	}

	if ([TPCPreferences textEncryptionIsRequired]) {
		return YES;
	}

	return [TPCPreferences textEncryptionIsOpportunistic];
}

- (BOOL)textEncryptionIsOpportunisticPreferenceEnabled
{
	return ([TPCPreferences textEncryptionIsEnabled] &&
			[TPCPreferences textEncryptionIsRequired] == NO);
}

- (void)setTextEncryptionIsRequired:(BOOL)textEncryptionIsRequired
{
	[TPCPreferences setTextEncryptionIsRequired:textEncryptionIsRequired];

	[self willChangeValueForKey:@"textEncryptionIsOpportunistic"];
	[self didChangeValueForKey:@"textEncryptionIsOpportunistic"];
}

- (BOOL)textEncryptionIsRequired
{
	if ([TPCPreferences textEncryptionIsEnabled] == NO) {
		return NO;
	}

	return [TPCPreferences textEncryptionIsRequired];
}

- (BOOL)textEncryptionIsRequiredPreferenceEnabled
{
	return [TPCPreferences textEncryptionIsEnabled];
}

- (void)setTextEncryptionIsEnabled:(BOOL)textEncryptionIsEnabled
{
	[TPCPreferences setTextEncryptionIsEnabled:textEncryptionIsEnabled];

	[self willChangeValueForKey:@"textEncryptionIsOpportunistic"];
	[self willChangeValueForKey:@"textEncryptionIsOpportunisticPreferenceEnabled"];
	[self willChangeValueForKey:@"textEncryptionIsRequired"];
	[self willChangeValueForKey:@"textEncryptionIsRequiredPreferenceEnabled"];

	[self didChangeValueForKey:@"textEncryptionIsOpportunistic"];
	[self didChangeValueForKey:@"textEncryptionIsOpportunisticPreferenceEnabled"];
	[self didChangeValueForKey:@"textEncryptionIsRequired"];
	[self didChangeValueForKey:@"textEncryptionIsRequiredPreferenceEnabled"];
}

- (BOOL)textEncryptionIsEnabled
{
	return [TPCPreferences textEncryptionIsEnabled];
}
#else
- (void)setTextEncryptionIsOpportunistic:(BOOL)textEncryptionIsOpportunistic
{

}

- (BOOL)textEncryptionIsOpportunistic
{

}

- (BOOL)textEncryptionIsOpportunisticPreferenceEnabled
{

}

- (void)setTextEncryptionIsRequired:(BOOL)textEncryptionIsRequired
{

}

- (BOOL)textEncryptionIsRequired
{

}

- (BOOL)textEncryptionIsRequiredPreferenceEnabled
{

}

- (void)setTextEncryptionIsEnabled:(BOOL)textEncryptionIsEnabled
{

}

- (BOOL)textEncryptionIsEnabled
{

}
#endif

- (BOOL)highlightCurrentNickname
{
	if ([TPCPreferences highlightMatchingMethod] == TXNicknameHighlightRegularExpressionMatchType) {
		return NO;
	}

	return [TPCPreferences highlightCurrentNickname];
}

- (void)setHighlightCurrentNickname:(BOOL)value
{
	[TPCPreferences setHighlightCurrentNickname:value];
}

- (BOOL)appNapEnabled
{
	return [TPCPreferences appNapEnabled];
}

- (void)setAppNapEnabled:(BOOL)appNapEnabled
{
	[TPCPreferences setAppNapEnabled:appNapEnabled];
}

- (BOOL)onlySpeakEventsForSelection
{
	return [TPCPreferences onlySpeakEventsForSelection];
}

- (void)setOnlySpeakEventsForSelection:(BOOL)onlySpeakEventsForSelection
{
	[TPCPreferences setOnlySpeakEventsForSelection:onlySpeakEventsForSelection];

	[self willChangeValueForKey:@"channelMessageSpeakChannelName"];
	[self didChangeValueForKey:@"channelMessageSpeakChannelName"];
}

- (BOOL)channelMessageSpeakChannelName
{
	if ([TPCPreferences onlySpeakEventsForSelection]) {
		return NO;
	}

	return [TPCPreferences channelMessageSpeakChannelName];
}

- (void)setChannelMessageSpeakChannelName:(BOOL)channelMessageSpeakChannelName
{
	[TPCPreferences setChannelMessageSpeakChannelName:channelMessageSpeakChannelName];
}

- (BOOL)channelMessageSpeakNickname
{
	return [TPCPreferences channelMessageSpeakNickname];
}

- (void)setChannelMessageSpeakNickname:(BOOL)channelMessageSpeakNickname
{
	[TPCPreferences setChannelMessageSpeakNickname:channelMessageSpeakNickname];
}

- (NSColor *)serverListUnreadCountBadgeHighlightColor
{
	NSColor *value = [RZUserDefaults() colorForKey:@"Server List Unread Message Count Badge Colors -> Highlight"];

	if (value == nil) {
		value = [NSColor clearColor];
	}

	return value;
}

- (void)setServerListUnreadCountBadgeHighlightColor:(NSColor *)serverListUnreadCountBadgeHighlightColor
{
	if ([serverListUnreadCountBadgeHighlightColor isEqual:[NSColor clearColor]]) {
		serverListUnreadCountBadgeHighlightColor = nil;
	}

	[RZUserDefaults() setColor:serverListUnreadCountBadgeHighlightColor
						forKey:@"Server List Unread Message Count Badge Colors -> Highlight"];
}

- (NSColor *)userListNoModeColor
{
	NSColor *value = [RZUserDefaults() colorForKey:@"User List Mode Badge Colors -> no mode"];

	if (value == nil) {
		value = [NSColor clearColor];
	}

	return value;
}

- (void)setUserListNoModeColor:(NSColor *)userListNoModeColor
{
	if ([userListNoModeColor isEqual:[NSColor clearColor]]) {
		userListNoModeColor = nil;
	}

	[RZUserDefaults() setColor:userListNoModeColor
						forKey:@"User List Mode Badge Colors -> no mode"];
}

- (BOOL)logTranscript
{
#if TEXTUAL_BUILT_FOR_APP_STORE_DISTRIBUTION == 1
	if ([self disableInAppPurchaseCheckbox:@"logTranscript"]) {
		return NO;
	}
#endif

	return [TPCPreferences logToDisk];
}

- (void)setLogTranscript:(BOOL)logTranscript
{
#if TEXTUAL_BUILT_FOR_APP_STORE_DISTRIBUTION == 1
	if ([self allowInAppPurchaseCheckboxToChange:@"logTranscript"] == NO) {
		return;
	}
#endif

	[TPCPreferences setLogToDisk:logTranscript];
}

- (BOOL)syncPreferencesToTheCloud
{
#if TEXTUAL_BUILT_WITH_ICLOUD_SUPPORT == 1
#if TEXTUAL_BUILT_FOR_APP_STORE_DISTRIBUTION == 1
	if ([self disableInAppPurchaseCheckbox:@"syncPreferencesToTheCloud"]) {
		return NO;
	}
#endif

	return [TPCPreferences syncPreferencesToTheCloud];
#else
	return NO;
#endif
}

- (void)setSyncPreferencesToTheCloud:(BOOL)syncPreferencesToTheCloud
{
#if TEXTUAL_BUILT_WITH_ICLOUD_SUPPORT == 1
#if TEXTUAL_BUILT_FOR_APP_STORE_DISTRIBUTION == 1
	if ([self allowInAppPurchaseCheckboxToChange:@"syncPreferencesToTheCloud"] == NO) {
		return;
	}
#endif

	[TPCPreferences setSyncPreferencesToTheCloud:syncPreferencesToTheCloud];
#endif
}

- (BOOL)inlineMediaLimitToBasics
{
	return [TPCPreferences inlineMediaLimitToBasics];
}

- (void)setInlineMediaLimitToBasics:(BOOL)inlineMediaLimitToBasics
{
	[TPCPreferences setInlineMediaLimitToBasics:inlineMediaLimitToBasics];

	[self willChangeValueForKey:@"inlineMediaLimitBasicsToFiles"];
	[self didChangeValueForKey:@"inlineMediaLimitBasicsToFiles"];
}

- (BOOL)inlineMediaLimitBasicsToFiles
{
	/* Show value as enabled when basics is disabled */
	if ([TPCPreferences inlineMediaLimitToBasics] == NO) {
		return NO; // UI negates bool so return NO for YES
	}

	return [TPCPreferences inlineMediaLimitBasicsToFiles];
}

- (void)setInlineMediaLimitBasicsToFiles:(BOOL)inlineMediaLimitBasicsToFiles
{
	[TPCPreferences setInlineMediaLimitBasicsToFiles:inlineMediaLimitBasicsToFiles];
}

- (BOOL)validateValue:(inout id *)value forKey:(NSString *)key error:(out NSError **)outError
{
	if ([key isEqualToString:@"scrollbackSaveLimit"]) {
		NSInteger valueInteger = [*value integerValue];

		if (valueInteger < _scrollbackSaveLinesMin) {
			*value = _unsignedIntegerString(_scrollbackSaveLinesMin);
		} else if (valueInteger > _scrollbackSaveLinesMax) {
			*value = _unsignedIntegerString(_scrollbackSaveLinesMax);
		}
	} else if ([key isEqualToString:@"scrollbackVisibleLimit"]) {
		NSInteger valueInteger = [*value integerValue];

		if (valueInteger < _scrollbackVisibleLinesMin && valueInteger != 0) {
			*value = _unsignedIntegerString(_scrollbackVisibleLinesMin);
		} else if (valueInteger > _scrollbackVisibleLinesMax) {
			*value = _unsignedIntegerString(_scrollbackVisibleLinesMax);
		}
	} else if ([key isEqualToString:@"inlineMediaMaxWidth"]) {
		NSInteger valueInteger = [*value integerValue];

		if (valueInteger < _inlineMediaWidthMin) {
			*value = _unsignedIntegerString(_inlineMediaWidthMin);
		} else if (_inlineMediaWidthMax < valueInteger) {
			*value = _unsignedIntegerString(_inlineMediaWidthMax);
		}
	} else if ([key isEqualToString:@"inlineMediaMaxHeight"]) {
		NSInteger valueInteger = [*value integerValue];

		if (valueInteger < _inlineMediaHeightMin) {
			*value = _unsignedIntegerString(_inlineMediaHeightMin);
		} else if (_inlineMediaHeightMax < valueInteger) {
			*value = _unsignedIntegerString(_inlineMediaHeightMax);
		}
	} else if ([key isEqualToString:@"fileTransferPortRangeStart"]) {
		NSInteger valueInteger = [*value integerValue];

		NSUInteger valueRangeEnd = [TPCPreferences fileTransferPortRangeEnd];

		if (valueInteger < _fileTransferPortRangeMin) {
			*value = _unsignedIntegerString(_fileTransferPortRangeMin);
		} else if (_fileTransferPortRangeMax < valueInteger) {
			*value = _unsignedIntegerString(_fileTransferPortRangeMax);
		}

		valueInteger = [*value integerValue];

		if (valueInteger > valueRangeEnd) {
			*value = _unsignedIntegerString(valueRangeEnd);
		}
	} else if ([key isEqualToString:@"fileTransferPortRangeEnd"]) {
		NSInteger valueInteger = [*value integerValue];

		NSUInteger valueRangeStart = [TPCPreferences fileTransferPortRangeStart];

		if (valueInteger < _fileTransferPortRangeMin) {
			*value = _unsignedIntegerString(_fileTransferPortRangeMin);
		} else if (_fileTransferPortRangeMax < valueInteger) {
			*value = _unsignedIntegerString(_fileTransferPortRangeMax);
		}

		valueInteger = [*value integerValue];

		if (valueInteger < valueRangeStart) {
			*value = _unsignedIntegerString(valueRangeStart);
		}
	}

	return YES;
}

#pragma mark -
#pragma mark File Transfer Destination Folder Popup

- (BOOL)panel:(id)sender validateURL:(NSURL *)url error:(NSError **)outError
{
	NSString *cloudPath = [[TPCPathInfo userHome] stringByAppendingPathComponent:@"/Library/Mobile Documents/"];

	if ([url.path hasPrefix:cloudPath]) {
		if (outError) {
			NSMutableDictionary *userInfo = [NSMutableDictionary dictionary];

			userInfo[NSURLErrorKey] = url;

			userInfo[NSLocalizedDescriptionKey] = TXTLS(@"TDCPreferencesController[1010][1]");

			userInfo[NSLocalizedRecoverySuggestionErrorKey] = TXTLS(@"TDCPreferencesController[1010][2]");

			*outError = [NSError errorWithDomain:TXErrorDomain code:27984 userInfo:userInfo];
		}

		return NO;
	}

	return YES;
}

- (void)updateFileTransferDownloadDestinationFolder
{
	TDCFileTransferDialog *transferController = [TXSharedApplication sharedFileTransferDialog];

	NSURL *path = transferController.downloadDestinationURL;

	NSMenuItem *item = [self.fileTransferDownloadDestinationButton itemAtIndex:0];

	if (path == nil) {
		item.image = nil;

		item.title = TXTLS(@"TDCPreferencesController[1003]");
	} else {
		NSImage *icon = [RZWorkspace() iconForFile:path.path];

		item.image = icon;

		icon.size = NSMakeSize(16, 16);

		item.title = path.lastPathComponent;
	}
}

- (void)onFileTransferDownloadDestinationFolderChanged:(id)sender
{
	TDCFileTransferDialog *transferController = [TXSharedApplication sharedFileTransferDialog];

	if (self.fileTransferDownloadDestinationButton.selectedTag == 2) {
		NSOpenPanel *d = [NSOpenPanel openPanel];

		d.delegate = (id)self;

		d.allowsMultipleSelection = NO;
		d.canChooseDirectories = YES;
		d.canChooseFiles = NO;
		d.canCreateDirectories = YES;
		d.resolvesAliases = YES;

		d.prompt = TXTLS(@"Prompts[0006]");

		[d beginSheetModalForWindow:self.window completionHandler:^(NSInteger returnCode) {
			[self.fileTransferDownloadDestinationButton selectItemAtIndex:0];

			if (returnCode != NSModalResponseOK) {
				return;
			}

			NSURL *path = d.URLs[0];

			NSError *bookmarkError = nil;

			NSData *bookmark = [path bookmarkDataWithOptions:NSURLBookmarkCreationWithSecurityScope
							  includingResourceValuesForKeys:nil
											   relativeToURL:nil
													   error:&bookmarkError];

			if (bookmark == nil) {
				LogToConsoleError("Error creating bookmark for URL (%{public}@): %{public}@",
				  path, bookmarkError.localizedDescription);
			}

			[transferController setDownloadDestinationURL:bookmark];

			[self updateFileTransferDownloadDestinationFolder];
		}];
	}
	else if (self.fileTransferDownloadDestinationButton.selectedTag == 3)
	{
		[self.fileTransferDownloadDestinationButton selectItemAtIndex:0];

		[transferController setDownloadDestinationURL:nil];

		[self updateFileTransferDownloadDestinationFolder];
	}
}

#pragma mark -
#pragma mark Transcript Folder Popup

- (void)updateTranscriptFolder
{
	NSURL *path = [TPCPathInfo transcriptFolderURL];

	NSMenuItem *item = [self.transcriptFolderButton itemAtIndex:0];

	if (path == nil) {
		item.image = nil;

		item.title = TXTLS(@"TDCPreferencesController[1002]");
	} else {
		NSImage *icon = [RZWorkspace() iconForFile:path.path];

		item.image = icon;

		icon.size = NSMakeSize(16, 16);

		item.title = path.lastPathComponent;
	}
}

- (void)onChangedTranscriptFolder:(id)sender
{
	if (self.transcriptFolderButton.selectedTag == 2) {
		NSOpenPanel *d = [NSOpenPanel openPanel];

		d.delegate = (id)self;

		d.allowsMultipleSelection = NO;
		d.canChooseDirectories = YES;
		d.canChooseFiles = NO;
		d.canCreateDirectories = YES;
		d.resolvesAliases = YES;

		d.prompt = TXTLS(@"Prompts[0006]");

		[d beginSheetModalForWindow:self.window completionHandler:^(NSInteger returnCode) {
			[self.transcriptFolderButton selectItemAtIndex:0];

			if (returnCode != NSModalResponseOK) {
				return;
			}

			NSURL *path = d.URLs[0];

			NSError *bookmarkError = nil;

			NSData *bookmark = [path bookmarkDataWithOptions:NSURLBookmarkCreationWithSecurityScope
							  includingResourceValuesForKeys:nil
											   relativeToURL:nil
													   error:&bookmarkError];

			if (bookmark == nil) {
				LogToConsoleError("Error creating bookmark for URL (%{public}@): %{public}@",
					  path, bookmarkError.localizedDescription);

				return;
			}

			[self setTranscriptFolderURL:bookmark];
		}];
	}
	else if (self.transcriptFolderButton.selectedTag == 3)
	{
		[self.transcriptFolderButton selectItemAtIndex:0];

		[self setTranscriptFolderURL:nil];
	}
}

- (void)setTranscriptFolderURL:(nullable NSData *)transcriptFolderURL
{
	[TPCPathInfo setTranscriptFolderURL:transcriptFolderURL];

	[TPCPreferences performReloadAction:TPCPreferencesReloadLogTranscriptsAction];

	[self updateTranscriptFolder];
}

#pragma mark -
#pragma mark Theme

- (void)updateThemeSelection
{
	[self.themeSelectionButton removeAllItems];

	NSString *currentThemeName = themeController().name;

	TPCThemeControllerStorageLocation currentStorageLocation = themeController().storageLocation;

	[TPCThemeController enumerateAvailableThemesWithBlock:^(NSString *themeName, TPCThemeControllerStorageLocation storageLocation, BOOL multipleVaraints, BOOL *stop) {
		NSString *displayName = themeName;

		if (multipleVaraints) {
			displayName = [NSString stringWithFormat:@"%@ — (%@)",
				themeName, [TPCThemeController descriptionForStorageLocation:storageLocation]];
		}

		NSMenuItem *item = [NSMenuItem menuItemWithTitle:displayName target:nil action:nil];

		item.representedObject =
		@{
		  @"themeName" : themeName,
		  @"storageLocation" : @(storageLocation)
		};

		if ([currentThemeName isEqualToString:themeName] &&
			currentStorageLocation == storageLocation)
		{
			item.tag = 100; // Tag for item to select
		}

		[self.themeSelectionButton.menu addItem:item];
	}];

	[self.themeSelectionButton selectItemWithTag:100];
}

- (void)onChangedThemeSelection:(id)sender
{
	NSMenuItem *selectedItem = self.themeSelectionButton.selectedItem;

	NSDictionary *context = selectedItem.representedObject;

	NSString *newThemeName = context[@"themeName"];

	TPCThemeControllerStorageLocation newStorageLocation = [context unsignedIntegerForKey:@"storageLocation"];

	NSString *newTheme = [TPCThemeController buildFilename:newThemeName forStorageLocation:newStorageLocation];

	NSString *currentTheme = [TPCPreferences themeName];

	if ([currentTheme isEqualToString:newTheme]) {
		return;
	}

	[TPCPreferences setThemeName:newTheme];

	self.reloadingThemeBySelection = YES;

	[self onChangedTheme:nil];
}

- (void)onChangedThemeSelectionReloadComplete:(NSNotification *)notification
{
	NSMutableString *forcedValuesMutable = [NSMutableString string];

	if ([TPCPreferences themeNicknameFormatPreferenceUserConfigurable] == NO) {
		[forcedValuesMutable appendString:TXTLS(@"TDCPreferencesController[1009][1]")];

		[forcedValuesMutable appendString:@"\n"];
	}

	if ([TPCPreferences themeTimestampFormatPreferenceUserConfigurable] == NO) {
		[forcedValuesMutable appendString:TXTLS(@"TDCPreferencesController[1009][2]")];

		[forcedValuesMutable appendString:@"\n"];
	}

	if ([TPCPreferences themeChannelViewFontPreferenceUserConfigurable] == NO) {
		[forcedValuesMutable appendString:TXTLS(@"TDCPreferencesController[1009][4]")];

		[forcedValuesMutable appendString:@"\n"];
	}

	NSString *forcedValues = forcedValuesMutable.trim;

	if (forcedValues.length == 0) {
		return;
	}

	NSString *currentTheme = [TPCPreferences themeName];

	NSString *themeName = [TPCThemeController extractThemeName:currentTheme];

	[TDCAlert alertSheetWithWindow:[NSApp keyWindow]
							  body:TXTLS(@"TDCPreferencesController[1008][2]", themeName, forcedValues)
							 title:TXTLS(@"TDCPreferencesController[1008][1]")
					 defaultButton:TXTLS(@"Prompts[0005]")
				   alternateButton:nil
					   otherButton:nil
					suppressionKey:@"theme_override_info"
				   suppressionText:nil
				   completionBlock:nil];
}

- (void)onSelectNewFont:(id)sender
{
	NSFont *currentFont = [TPCPreferences themeChannelViewFont];

	[RZFontManager() setSelectedFont:currentFont isMultiple:NO];

	[RZFontManager() orderFrontFontPanel:self];

	RZFontManager().action = @selector(onChangedChannelViewFont:);
}

- (void)onChangedChannelViewFont:(NSFontManager *)sender
{
	NSFont *currentFont = [TPCPreferences themeChannelViewFont];

	NSFont *newFont = [sender convertFont:currentFont];

	[self willChangeValueForKey:@"themeChannelViewFontName"];
	[self willChangeValueForKey:@"themeChannelViewFontSize"];

	[TPCPreferences setThemeChannelViewFontName:newFont.fontName];
	[TPCPreferences setThemeChannelViewFontSize:newFont.pointSize];

	[self didChangeValueForKey:@"themeChannelViewFontName"];
	[self didChangeValueForKey:@"themeChannelViewFontSize"];

	[self onChangedTheme:nil];
}

- (void)onChangedTransparency:(id)sender
{
	[mainWindow() updateAlphaValueToReflectPreferences];
}

#pragma mark -
#pragma mark Updates

- (void)updateCheckForUpdatesMatrix
{
	// Tags:
	// 0 = Don't check for updates
	// 1 = Just notify if there are updates
	// 2 = Automatically download and install updates

#if TEXTUAL_BUILT_WITH_SPARKLE_ENABLED == 1
	SUUpdater *updater = [SUUpdater sharedUpdater];

	if (updater.automaticallyDownloadsUpdates) {
		[self.checkForUpdatesMatrix selectCellWithTag:2];
	} else if (updater.automaticallyChecksForUpdates) {
		[self.checkForUpdatesMatrix selectCellWithTag:1];
	} else {
		[self.checkForUpdatesMatrix selectCellWithTag:0];
	}
#endif
}

- (void)onChangedCheckForUpdates:(id)sender
{
#if TEXTUAL_BUILT_WITH_SPARKLE_ENABLED == 1
	NSInteger selectedTag = self.checkForUpdatesMatrix.selectedTag;

	SUUpdater *updater = [SUUpdater sharedUpdater];

	if (selectedTag == 2) {
		updater.automaticallyChecksForUpdates = YES;
		updater.automaticallyDownloadsUpdates = YES;
	} else if (selectedTag == 1) {
		updater.automaticallyChecksForUpdates = YES;
		updater.automaticallyDownloadsUpdates = NO;
	} else {
		updater.automaticallyChecksForUpdates = NO;
		updater.automaticallyDownloadsUpdates = NO;
	}
#endif
}

- (void)onChangedCheckForBetaUpdates:(id)sender
{
#if TEXTUAL_BUILT_WITH_SPARKLE_ENABLED == 1
	[TPCPreferences performReloadAction:TPCPreferencesReloadSparkleFrameworkFeedURLAction];

	if ([TPCPreferences receiveBetaUpdates]) {
		[menuController() checkForUpdates:nil];
	}
#endif
}

#pragma mark -
#pragma mark Actions

- (void)onChangedDisableNicknameColorHashing:(id)sender
{
	[self onChangedTheme:nil];
}

#if TEXTUAL_BUILT_WITH_ADVANCED_ENCRYPTION == 1
- (void)offRecordMessagingPolicyChanged:(id)sender
{
	[TPCPreferences performReloadAction:TPCPreferencesReloadEncryptionPolicyAction];
}
#endif

- (void)onChangedHighlightType:(id)sender
{
	[self willChangeValueForKey:@"highlightCurrentNickname"];
	[self didChangeValueForKey:@"highlightCurrentNickname"];

	if ([TPCPreferences highlightMatchingMethod] == TXNicknameHighlightRegularExpressionMatchType) {
		self.highlightNicknameButton.enabled = NO;
	} else {
		self.highlightNicknameButton.enabled = YES;
	}
}

- (void)editTableView:(NSTableView *)tableView
{
	NSInteger rowSelection = (tableView.numberOfRows - 1);

	[tableView scrollRowToVisible:rowSelection];

	[tableView editColumn:0 row:rowSelection withEvent:nil select:YES];
}

- (void)onAddHighlightKeyword:(id)sender
{
	[self.highlightKeywordsArrayController add:nil];

	XRPerformBlockAsynchronouslyOnMainQueue(^{
		[self editTableView:self.highlightKeywordsTable];
	});
}

- (void)onAddExcludeKeyword:(id)sender
{
	[self.excludeKeywordsArrayController add:nil];

	XRPerformBlockAsynchronouslyOnMainQueue(^{
		[self editTableView:self.excludeKeywordsTable];
	});
}

+ (void)showTorAnonymityNetworkInlineMediaWarning
{
	BOOL presentDialog = NO;

	for (IRCClient *u in worldController().clientList) {
		if (u.config.proxyType != IRCConnectionSocketNoProxyType) {
			presentDialog = YES;
			
			break;
		}
	}

	if (presentDialog == NO) {
		NSUInteger applicationIndex =
		[RZWorkspace().runningApplications indexOfObjectPassingTest:^BOOL(NSRunningApplication *application, NSUInteger index, BOOL *stop) {
			return
			([application.localizedName isEqualToString:@"TorBrowser"] ||
			 [application.localizedName isEqualToString:@"Tor Browser"]);
		}];

		presentDialog = (applicationIndex != NSNotFound);
	}

	if (presentDialog == NO) {
		return;
	}

	BOOL clickResult =
	[TDCAlert modalAlertWithMessage:TXTLS(@"Prompts[1111][2]")
							  title:TXTLS(@"Prompts[1111][1]")
					  defaultButton:TXTLS(@"Prompts[0005]")
					alternateButton:TXTLS(@"Prompts[1111][3]")];

	if (clickResult == NO) {
		[self openProxySettingsInSystemPreferences];
	}
}

+ (void)openProxySettingsInSystemPreferences
{
	AEDesc aeDesc = { typeNull, NULL };

	OSStatus aeDescStatus = AECreateDesc('ptru', "Proxies", 7,  &aeDesc);

	if (aeDescStatus != noErr) {
		LogToConsoleError("aeDescStatus returned value other than noErr: %{public}i", aeDescStatus);

		return;
	}

	NSURL *prefPaneURL = [NSURL fileURLWithPath:@"/System/Library/PreferencePanes/Network.prefPane"];

	LSLaunchURLSpec launchSpec = { 0 };

	launchSpec.appURL = NULL;
	launchSpec.asyncRefCon = NULL;
	launchSpec.itemURLs = (__bridge CFArrayRef)@[prefPaneURL];
	launchSpec.launchFlags = (kLSLaunchAsync | kLSLaunchDontAddToRecents);
	launchSpec.passThruParams = &aeDesc;

	(void)LSOpenFromURLSpec(&launchSpec, NULL);
}

- (void)onChangedInlineMediaOption:(id)sender
{
	if ([TPCPreferences showInlineMedia]) {
		[self.class showTorAnonymityNetworkInlineMediaWarning];
	}

	[self onChangedTheme:nil];
}

- (void)onResetUserListModeColorsToDefaults:(id)sender
{
	[RZUserDefaults() setObject:nil forKey:@"User List Mode Badge Colors -> +y"];
	[RZUserDefaults() setObject:nil forKey:@"User List Mode Badge Colors -> +q"];
	[RZUserDefaults() setObject:nil forKey:@"User List Mode Badge Colors -> +a"];
	[RZUserDefaults() setObject:nil forKey:@"User List Mode Badge Colors -> +o"];
	[RZUserDefaults() setObject:nil forKey:@"User List Mode Badge Colors -> +h"];
	[RZUserDefaults() setObject:nil forKey:@"User List Mode Badge Colors -> +v"];
	[RZUserDefaults() setObject:nil forKey:@"User List Mode Badge Colors -> no mode"];

#if TEXTUAL_BUILT_WITH_ICLOUD_SUPPORT == 1
	[sharedCloudManager() removeObjectForKeyNextUpstreamSync:@"User List Mode Badge Colors -> +y"];
	[sharedCloudManager() removeObjectForKeyNextUpstreamSync:@"User List Mode Badge Colors -> +q"];
	[sharedCloudManager() removeObjectForKeyNextUpstreamSync:@"User List Mode Badge Colors -> +a"];
	[sharedCloudManager() removeObjectForKeyNextUpstreamSync:@"User List Mode Badge Colors -> +o"];
	[sharedCloudManager() removeObjectForKeyNextUpstreamSync:@"User List Mode Badge Colors -> +h"];
	[sharedCloudManager() removeObjectForKeyNextUpstreamSync:@"User List Mode Badge Colors -> +v"];
	[sharedCloudManager() removeObjectForKeyNextUpstreamSync:@"User List Mode Badge Colors -> no mode"];
#endif

	[self onChangedUserListModeColor:nil];
}

- (void)onResetServerListUnreadBadgeColorsToDefault:(id)sender
{
	[self willChangeValueForKey:@"serverListUnreadCountBadgeHighlightColor"];

	[RZUserDefaults() setObject:nil forKey:@"Server List Unread Message Count Badge Colors -> Highlight"];

	[self didChangeValueForKey:@"serverListUnreadCountBadgeHighlightColor"];

#if TEXTUAL_BUILT_WITH_ICLOUD_SUPPORT == 1
	[sharedCloudManager() removeObjectForKeyNextUpstreamSync:@"Server List Unread Message Count Badge Colors -> Highlight"];
#endif

	[self onChangedServerListUnreadBadgeColor:sender];
}

- (void)onChangedInputHistoryScheme:(id)sender
{
	[TPCPreferences performReloadAction:TPCPreferencesReloadInputHistoryScopeAction];
}

- (void)onChangedAppearance:(id)sender
{
	[TPCPreferences performReloadAction:TPCPreferencesReloadAppearanceAction];
}

- (void)onChangedTheme:(id)sender
{
	[TPCPreferences performReloadAction:(TPCPreferencesReloadStyleAction | TPCPreferencesReloadTextDirectionAction)];
}

- (void)onThemeWillReload:(NSNotification *)notification
{
	self.reloadingTheme = YES;
}

- (void)onThemeReloadComplete:(NSNotification *)notification
{
	self.reloadingTheme = NO;

	if (self.reloadingThemeBySelection) {
		self.reloadingThemeBySelection = NO;

		[self onChangedThemeSelectionReloadComplete:notification];
	}
}

- (void)onChangedChannelViewArrangement:(id)sender
{
	[TPCPreferences performReloadAction:TPCPreferencesReloadChannelViewArrangementAction];
}

- (void)onChangedMainWindowSegmentedController:(id)sender
{
	[TPCPreferences performReloadAction:TPCPreferencesReloadTextFieldSegmentedControllerOriginAction];
}

- (void)onChangedUserListModeColor:(id)sender
{
	static NSDictionary<NSNumber *, NSString *> *preferenceMap = nil;

	static dispatch_once_t onceToken;

	dispatch_once(&onceToken, ^{
		preferenceMap = @{
			@(10) 	: @"User List Mode Badge Colors -> +y",
			@(9) 	: @"User List Mode Badge Colors -> +q",
			@(8) 	: @"User List Mode Badge Colors -> +a",
			@(7) 	: @"User List Mode Badge Colors -> +o",
			@(6) 	: @"User List Mode Badge Colors -> +h",
			@(5) 	: @"User List Mode Badge Colors -> +v",
			@(4) 	: @"User List Mode Badge Colors -> no mode"
		};
	});

	NSString *preferenceKey = preferenceMap[@([sender tag])];

	/* -onResetUserListModeColorsToDefaults: passes nil sender */
	if (preferenceKey == nil) {
		[TPCPreferences performReloadAction:(TPCPreferencesReloadMemberListUserBadgesAction | TPCPreferencesReloadMemberListAction)];
	} else {
		[TPCPreferences performReloadAction:TPCPreferencesReloadMemberListUserBadgesAction forKey:preferenceKey];
	}
}

- (void)onChangedMainInputTextViewFontSize:(id)sender
{
	[TPCPreferences performReloadAction:TPCPreferencesReloadTextFieldFontSizeAction];
}

- (void)onFileTransferIPAddressDetectionMethodChanged:(id)sender
{
	TXFileTransferIPAddressDetectionMethod detectionMethod = [TPCPreferences fileTransferIPAddressDetectionMethod];

	self.fileTransferManuallyEnteredIPAddressTextField.enabled = (detectionMethod == TXFileTransferIPAddressManualDetectionMethod);
}

- (void)onChangedHighlightLogging:(id)sender
{
	[TPCPreferences performReloadAction:TPCPreferencesReloadHighlightLoggingAction];
}

- (void)onChangedUserListModeSortOrder:(id)sender
{
	[TPCPreferences performReloadAction:TPCPreferencesReloadMemberListSortOrderAction];
}

- (void)onChangedServerListUnreadBadgeColor:(id)sender
{
	[TPCPreferences performReloadAction:TPCPreferencesReloadServerListUnreadBadgesAction];
}

- (void)onChangedScrollbackSaveLimit:(id)sender
{
	[TPCPreferences performReloadAction:TPCPreferencesReloadScrollbackSaveLimitAction];
}

- (void)onChangedScrollbackVisibleLimit:(id)sender
{
	[TPCPreferences performReloadAction:TPCPreferencesReloadScrollbackVisibleLimitAction];
}

- (void)onOpenPathToCloudFolder:(id)sender
{
#if TEXTUAL_BUILT_WITH_ICLOUD_SUPPORT == 1
	[TPCPathInfo openApplicationUbiquitousContainer];
#endif
}

- (void)onOpenPathToScripts:(id)sender
{
	[RZWorkspace() openFile:[TPCPathInfo groupContainerApplicationSupport]];
}

- (void)onManageICloudButtonClicked:(id)sender
{
#if TEXTUAL_BUILT_WITH_ICLOUD_SUPPORT == 1
	[self firstPane:self.contentViewICloud selectedItem:_toolbarItemIndexAdvanced];
#endif
}

- (void)onChangedCloudSyncingServices:(id)sender
{
#if TEXTUAL_BUILT_WITH_ICLOUD_SUPPORT == 1
	if ([TPCPreferences syncPreferencesToTheCloud] == NO) {
		[sharedCloudManager() resetDataToSync];
	} else {
		[RZUbiquitousKeyValueStore() synchronize];

		[sharedCloudManager() syncEverythingNextSync];

		[sharedCloudManager() synchronizeFromCloud];
	}
#endif
}

- (void)onChangedCloudSyncingServicesServersOnly:(id)sender
{
#if TEXTUAL_BUILT_WITH_ICLOUD_SUPPORT == 1
	if ([TPCPreferences syncPreferencesToTheCloud] == NO) {
		return;
	}

	if ([TPCPreferences syncPreferencesToTheCloudLimitedToServers]) {
		return;
	}

	[RZUbiquitousKeyValueStore() synchronize];

	[sharedCloudManager() synchronizeFromCloud];
#endif
}

#if TEXTUAL_BUILT_WITH_ICLOUD_SUPPORT == 1
- (void)onPurgeOfCloudDataRequestedCallback:(TDCAlertResponse)returnCode
{
	if (returnCode != TDCAlertResponseDefaultButton) {
		return;
	}

	[sharedCloudManager() purgeDataStoredWithCloud];

	NSError *deleteThemesError = nil;

	if ([RZFileManager() removeItemAtPath:[TPCPathInfo cloudCustomThemes] error:&deleteThemesError] == NO) {
		LogToConsoleError("Delete Error: %{public}@",
			  deleteThemesError.localizedDescription);
	}
}
#endif

- (void)onPurgeOfCloudDataRequested:(id)sender
{
#if TEXTUAL_BUILT_WITH_ICLOUD_SUPPORT == 1
	[TDCAlert alertSheetWithWindow:[NSApp keyWindow]
							  body:TXTLS(@"TDCPreferencesController[1001][2]")
							 title:TXTLS(@"TDCPreferencesController[1001][1]")
					 defaultButton:TXTLS(@"Prompts[0001]")
				   alternateButton:TXTLS(@"Prompts[0002]")
					   otherButton:nil
				   completionBlock:^(TDCAlertResponse buttonClicked, BOOL suppressed, id underlyingAlert) {
					   [self onPurgeOfCloudDataRequestedCallback:buttonClicked];
				   }];
#endif
}

- (void)openPathToThemesCallback:(TDCAlertResponse)returnCode withOriginalAlert:(NSAlert *)originalAlert
{
	NSParameterAssert(originalAlert != nil);

	if (returnCode == TDCAlertResponseAlternateButton) {
		[self openPathToTheme];
	}

	if (returnCode == TDCAlertResponseDefaultButton) {
		[originalAlert.window orderOut:nil];

		BOOL copyingToCloud = NO;

#if TEXTUAL_BUILT_WITH_ICLOUD_SUPPORT == 1
		if (sharedCloudManager().ubiquitousContainerIsAvailable) {
			copyingToCloud = YES;
		}
#endif

		if (copyingToCloud) {
			[themeController() copyActiveThemeToDestinationLocation:TPCThemeControllerStorageCloudLocation reloadOnCopy:YES openOnCopy:YES];
		} else {
			[themeController() copyActiveThemeToDestinationLocation:TPCThemeControllerStorageCustomLocation reloadOnCopy:YES openOnCopy:YES];
		}
	}
}

- (void)onOpenPathToTheme:(id)sender
{
	if (themeController().bundledTheme) {
		[TDCAlert alertSheetWithWindow:NSApp.keyWindow
								  body:TXTLS(@"TDCPreferencesController[1007][2]")
								 title:TXTLS(@"TDCPreferencesController[1007][1]")
						 defaultButton:TXTLS(@"Prompts[0001]")
					   alternateButton:TXTLS(@"Prompts[0002]")
						   otherButton:nil
					   completionBlock:^(TDCAlertResponse buttonClicked, BOOL suppressed, id underlyingAlert) {
						   [self openPathToThemesCallback:buttonClicked withOriginalAlert:underlyingAlert];
					   }];

		return;
	}

	[self openPathToTheme];
}

- (void)openPathToTheme
{
	NSString *filepath = themeController().path;

	[RZWorkspace() openFile:filepath];
}

#pragma mark -
#pragma mark In-App Purchase

#if TEXTUAL_BUILT_FOR_APP_STORE_DISTRIBUTION == 1
- (BOOL)disableInAppPurchaseCheckbox:(NSString *)defaultsKey
{
	NSParameterAssert(defaultsKey != nil);

	return (TLOAppStoreTextualIsRegistered() == NO && TLOAppStoreIsTrialExpired());
}

- (BOOL)allowInAppPurchaseCheckboxToChange:(NSString *)defaultsKey
{
	NSParameterAssert(defaultsKey != nil);

	if ([self disableInAppPurchaseCheckbox:defaultsKey]) {
		[self showInAppPurchaseFeatureIsDisabledMessage];

		/* Undo change user made by faking change to property
		 on next pass to main thread. We have to do this next
		 pass because KVO wont recognize the change when the
		 change is made within itself. */
		XRPerformBlockAsynchronouslyOnMainQueue(^{
			[self willChangeValueForKey:defaultsKey]; // Refresh check box back to NO
			[self didChangeValueForKey:defaultsKey];
		});

		return NO;
	}

	return YES;
}

- (void)showInAppPurchaseFeatureIsDisabledMessage
{
	[[TXSharedApplication sharedInAppPurchaseDialog] showFeatureIsLimitedMessageInWindow:self.window];
}

- (void)reloadInAppPurchaseDependentPreferences
{
	[self willChangeValueForKey:@"logTranscript"];
	[self didChangeValueForKey:@"logTranscript"];

	[self willChangeValueForKey:@"syncPreferencesToTheCloud"];
	[self didChangeValueForKey:@"syncPreferencesToTheCloud"];
}

- (void)onInAppPurchaseTrialExpired:(NSNotification *)notification
{
	[self reloadInAppPurchaseDependentPreferences];
}

- (void)onInAppPurchaseTransactionFinished:(NSNotification *)notification
{
	[self reloadInAppPurchaseDependentPreferences];
}
#endif

#pragma mark -
#pragma mark Cloud Work

- (void)onCloudSyncControllerDidChangeThemeName:(NSNotification *)aNote
{
	[self updateThemeSelection];
}

#pragma mark -
#pragma mark NSWindow Delegate

- (void)windowWillClose:(NSNotification *)note
{
	[RZNotificationCenter() removeObserver:self];

	[self saveWindowFrame];

	if ([self.delegate respondsToSelector:@selector(preferencesDialogWillClose:)]) {
		[self.delegate preferencesDialogWillClose:self];
	}
}

@end

NS_ASSUME_NONNULL_END
