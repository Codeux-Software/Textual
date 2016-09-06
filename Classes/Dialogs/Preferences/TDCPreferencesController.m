/* ********************************************************************* 
                  _____         _               _
                 |_   _|____  _| |_ _   _  __ _| |
                   | |/ _ \ \/ / __| | | |/ _` | |
                   | |  __/>  <| |_| |_| | (_| | |
                   |_|\___/_/\_\\__|\__,_|\__,_|_|

 Copyright (c) 2008 - 2010 Satoshi Nakagawa <psychs AT limechat DOT net>
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

NS_ASSUME_NONNULL_BEGIN

#define _scrollbackLinesMin			100
#define _scrollbackLinesMax			15000
#define _inlineImageWidthMax		2000
#define _inlineImageWidthMin		40
#define _inlineImageHeightMax		6000
#define _inlineImageHeightMin		0

#define _fileTransferPortRangeMin			1024
#define _fileTransferPortRangeMax			TXMaximumTCPPort

#define _toolbarItemIndexGeneral					101
#define _toolbarItemIndexHighlights					102
#define _toolbarItemIndexNotifications				103
#define _toolbarItemIndexControls					104
#define _toolbarItemIndexInterface					105
#define _toolbarItemIndexStyle						106
#define _toolbarItemIndexAddons						107
#define _toolbarItemIndexAdvanced					108

#define _toolbarItemIndexChannelManagement			110
#define _toolbarItemIndexCommandScope				111
#define _toolbarItemIndexIncomingData				112
#define _toolbarItemIndexFileTransfers				113
#define _toolbarItemIndexFloodControl				114
#define _toolbarItemIndexLogLocation				115
#define _toolbarItemIndexDefaultIdentity			116
#define _toolbarItemIndexDefualtIRCopMessages		117
#define _toolbarItemIndexExperimentalSettings		119

#if TEXTUAL_BUILT_WITH_ADVANCED_ENCRYPTION == 1
#define _toolbarItemIndexOffRecordMessaging		    121
#endif

#define _addonsToolbarInstalledAddonsMenuItemIndex		120
#define _addonsToolbarItemMultiplier					995

#define _unsignedIntegerString(_value_)			[NSString stringWithUnsignedInteger:_value_]

@interface TDCPreferencesController ()
@property (nonatomic, copy) NSArray *alertSounds;
@property (nonatomic, strong) IBOutlet NSArrayController *excludeKeywordsArrayController;
@property (nonatomic, strong) IBOutlet NSArrayController *highlightKeywordsArrayController;
@property (nonatomic, strong) IBOutlet NSArrayController *installedScriptsController;
@property (nonatomic, weak) IBOutlet NSButton *addExcludeKeywordButton;
@property (nonatomic, weak) IBOutlet NSButton *alertBounceDockIconButton;
@property (nonatomic, weak) IBOutlet NSButton *alertBounceDockIconRepeatedlyButton;
@property (nonatomic, weak) IBOutlet NSButton *alertDisableWhileAwayButton;
@property (nonatomic, weak) IBOutlet NSButton *alertPushNotificationButton;
@property (nonatomic, weak) IBOutlet NSButton *alertSpeakEventButton;
@property (nonatomic, weak) IBOutlet NSButton *highlightNicknameButton;
@property (nonatomic, weak) IBOutlet NSPopUpButton *alertSoundChoiceButton;
@property (nonatomic, weak) IBOutlet NSPopUpButton *alertTypeChoiceButton;
@property (nonatomic, weak) IBOutlet NSPopUpButton *themeSelectionButton;
@property (nonatomic, weak) IBOutlet NSPopUpButton *transcriptFolderButton;
@property (nonatomic, weak) IBOutlet NSPopUpButton *fileTransferDownloadDestinationButton;
@property (nonatomic, weak) IBOutlet NSTableView *excludeKeywordsTable;
@property (nonatomic, weak) IBOutlet NSTableView *installedScriptsTable;
@property (nonatomic, weak) IBOutlet NSTableView *highlightKeywordsTable;
@property (nonatomic, weak) IBOutlet NSTextField *alertNotificationDestinationTextField;
@property (nonatomic, weak) IBOutlet NSTextField *fileTransferManuallyEnteredIPAddressTextField;
@property (nonatomic, strong) IBOutlet NSView *contentViewNotifications;
@property (nonatomic, strong) IBOutlet NSView *contentViewChannelManagement;
@property (nonatomic, strong) IBOutlet NSView *contentViewCommandScope;
@property (nonatomic, strong) IBOutlet NSView *contentViewControls;
@property (nonatomic, strong) IBOutlet NSView *contentViewDefaultIdentity;
@property (nonatomic, strong) IBOutlet NSView *contentViewExperimentalSettings;
@property (nonatomic, strong) IBOutlet NSView *contentViewFileTransfers;
@property (nonatomic, strong) IBOutlet NSView *contentViewFloodControl;
@property (nonatomic, strong) IBOutlet NSView *contentViewGeneral;
@property (nonatomic, strong) IBOutlet NSView *contentViewHighlights;
@property (nonatomic, strong) IBOutlet NSView *contentViewICloud;
@property (nonatomic, strong) IBOutlet NSView *contentViewDefaultIRCopMessages;
@property (nonatomic, strong) IBOutlet NSView *contentViewIncomingData;
@property (nonatomic, strong) IBOutlet NSView *contentViewInstalledAddons;
@property (nonatomic, strong) IBOutlet NSView *contentViewInterface;
@property (nonatomic, strong) IBOutlet NSView *contentViewLogLocation;

#if TEXTUAL_BUILT_WITH_ADVANCED_ENCRYPTION == 1
@property (nonatomic, strong) IBOutlet NSView *contentViewOffRecordMessaging;
#endif

@property (nonatomic, strong) IBOutlet NSView *contentViewStyle;
@property (nonatomic, strong) IBOutlet NSView *contentView;
@property (nonatomic, strong) IBOutlet NSView *shareDataBetweenDevicesView;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *shareDataBetweenDevicesViewHeightConstraint;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *contentViewHeightConstraint;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *contentViewWidthConstraint;
@property (nonatomic, strong) IBOutlet NSView *mountainLionDeprecationWarningView;
@property (nonatomic, strong) IBOutlet NSToolbar *navigationToolbar;
@property (nonatomic, strong) IBOutlet NSMenu *installedAddonsMenu;
@property (nonatomic, assign) BOOL mountainLionDeprecationWarningIsVisible;
@property (nonatomic, assign) BOOL reloadingTheme;
@property (nonatomic, assign) BOOL reloadingThemeBySelection;

- (IBAction)onAddExcludeKeyword:(id)sender;
- (IBAction)onAddHighlightKeyword:(id)sender; // changed
- (IBAction)onChangedAlertBounceDockIcon:(id)sender;
- (IBAction)onChangedAlertBounceDockIconRepeatedly:(id)sender;
- (IBAction)onChangedAlertDisableWhileAway:(id)sender;
- (IBAction)onChangedAlertNotification:(id)sender;
- (IBAction)onChangedAlertSound:(id)sender;
- (IBAction)onChangedAlertSpoken:(id)sender;
- (IBAction)onChangedAlertType:(id)sender;
- (IBAction)onChangedCloudSyncingServices:(id)sender;
- (IBAction)onChangedCloudSyncingServicesServersOnly:(id)sender;
- (IBAction)onChangedHighlightLogging:(id)sender;
- (IBAction)onChangedHighlightType:(id)sender;
- (IBAction)onChangedInlineMediaOption:(id)sender;
- (IBAction)onChangedInputHistoryScheme:(id)sender;
- (IBAction)onChangedMainInputTextViewFontSize:(id)sender; // changed
- (IBAction)onChangedMainWindowSegmentedController:(id)sender;
- (IBAction)onChangedServerListUnreadBadgeColor:(id)sender;
- (IBAction)onChangedSidebarColorInversion:(id)sender;
- (IBAction)onChangedTheme:(id)sender;
- (IBAction)onChangedThemeSelection:(id)sender;  // changed
- (IBAction)onChangedTranscriptFolder:(id)sender;
- (IBAction)onChangedTransparency:(id)sender;
- (IBAction)onChangedUserListModeColor:(id)sender;
- (IBAction)onChangedUserListModeSortOrder:(id)sender;
- (IBAction)onFileTransferDownloadDestinationFolderChanged:(id)sender;
- (IBAction)onFileTransferIPAddressDetectionMethodChanged:(id)sender;
- (IBAction)onHideMountainLionDeprecationWarning:(id)sender;
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
	NSMutableArray *alertSounds = [NSMutableArray new];

	[alertSounds addObject:@(TXNotificationAddressBookMatchType)];
	[alertSounds addObject:NSStringWhitespacePlaceholder];
	[alertSounds addObject:@(TXNotificationConnectType)];
	[alertSounds addObject:@(TXNotificationDisconnectType)];
	[alertSounds addObject:NSStringWhitespacePlaceholder];
	[alertSounds addObject:@(TXNotificationHighlightType)];
	[alertSounds addObject:NSStringWhitespacePlaceholder];
	[alertSounds addObject:@(TXNotificationInviteType)];
	[alertSounds addObject:@(TXNotificationKickType)];
	[alertSounds addObject:NSStringWhitespacePlaceholder];
	[alertSounds addObject:@(TXNotificationChannelMessageType)];
	[alertSounds addObject:@(TXNotificationChannelNoticeType)];
	[alertSounds addObject:NSStringWhitespacePlaceholder];
	[alertSounds addObject:@(TXNotificationNewPrivateMessageType)];
	[alertSounds addObject:@(TXNotificationPrivateMessageType)];
	[alertSounds addObject:@(TXNotificationPrivateNoticeType)];
	[alertSounds addObject:NSStringWhitespacePlaceholder];
	[alertSounds addObject:@(TXNotificationFileTransferReceiveRequestedType)];
	[alertSounds addObject:NSStringWhitespacePlaceholder];
	[alertSounds addObject:@(TXNotificationFileTransferSendSuccessfulType)];
	[alertSounds addObject:@(TXNotificationFileTransferReceiveSuccessfulType)];
	[alertSounds addObject:NSStringWhitespacePlaceholder];
	[alertSounds addObject:@(TXNotificationFileTransferSendFailedType)];
	[alertSounds addObject:@(TXNotificationFileTransferReceiveFailedType)];

	self.alertSounds = alertSounds;

	if ([GrowlApplicationBridge isGrowlRunning]) {
		self.alertNotificationDestinationTextField.stringValue = TXTLS(@"TDCPreferencesController[1004]");
	} else {
		self.alertNotificationDestinationTextField.stringValue = TXTLS(@"TDCPreferencesController[1005]");
	}

	[self setUpToolbarItemsAndMenus];

	[self updateAlertSelection];
	[self updateFileTransferDownloadDestinationFolder];
	[self updateThemeSelection];
	[self updateTranscriptFolder];

	[self onChangedAlertType:nil];
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
							   selector:@selector(onThemeReloadComplete:)
								   name:TVCMainWindowDidReloadThemeNotification
								 object:nil];

	self.mountainLionDeprecationWarningIsVisible = NO;

	if ([XRSystemInformation isUsingOSXMavericksOrLater] == NO) {
		BOOL warningViewHidden = [RZUserDefaults() boolForKey:@"TDCPreferencesControllerDidShowMountainLionDeprecationWarning"];

		if (warningViewHidden == NO) {
			self.mountainLionDeprecationWarningIsVisible = YES;
		}
	}

#if TEXTUAL_BUILT_WITH_ICLOUD_SUPPORT == 0
	/* Hide "Share data between devices" when iCloud support is not enabled
	 by setting the subview height to 0. Set height before calling firstPane:
	 so that firstPane: can calculate the correct total height. */
	self.shareDataBetweenDevicesViewHeightConstraint.constant = 0.0;

	[self.contentViewGeneral layoutSubtreeIfNeeded];
#endif
}

#pragma mark -
#pragma mark Utilities

- (void)show
{
	[self.window restoreWindowStateForClass:self.class];

	if (self.mountainLionDeprecationWarningIsVisible) {
		self.mountainLionDeprecationWarningView.hidden = NO;

		[self firstPane:self.mountainLionDeprecationWarningView selectedItem:_toolbarItemIndexGeneral];
	} else {
		[self firstPane:self.contentViewGeneral selectedItem:_toolbarItemIndexGeneral];
	}

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
	if (self.mountainLionDeprecationWarningIsVisible) {
		self.navigationToolbar.selectedItemIdentifier = _unsignedIntegerString(_toolbarItemIndexGeneral);

		NSBeep();

		return;
	}

#define _de(matchTag, view, selectionIndex)		\
		case (matchTag): {	\
			[self firstPane:(view) selectedItem:(selectionIndex)];	\
			break;		\
		}

	switch ([sender tag]) {

		_de(_toolbarItemIndexGeneral, self.contentViewGeneral, _toolbarItemIndexGeneral)

		_de(_toolbarItemIndexHighlights, self.contentViewHighlights, _toolbarItemIndexHighlights)
		_de(_toolbarItemIndexNotifications, self.contentViewNotifications, _toolbarItemIndexNotifications)

		_de(_toolbarItemIndexControls, self.contentViewControls, _toolbarItemIndexControls)
		_de(_toolbarItemIndexInterface, self.contentViewInterface, _toolbarItemIndexInterface)
		_de(_toolbarItemIndexStyle, self.contentViewStyle, _toolbarItemIndexStyle)

		_de(_toolbarItemIndexChannelManagement, self.contentViewChannelManagement, _toolbarItemIndexAdvanced)
		_de(_toolbarItemIndexCommandScope, self.contentViewCommandScope, _toolbarItemIndexAdvanced)
		_de(_toolbarItemIndexIncomingData, self.contentViewIncomingData, _toolbarItemIndexAdvanced)
		_de(_toolbarItemIndexFileTransfers, self.contentViewFileTransfers, _toolbarItemIndexAdvanced)
		_de(_toolbarItemIndexFloodControl, self.contentViewFloodControl, _toolbarItemIndexAdvanced)
		_de(_toolbarItemIndexLogLocation, self.contentViewLogLocation, _toolbarItemIndexAdvanced);
		_de(_toolbarItemIndexDefaultIdentity, self.contentViewDefaultIdentity, _toolbarItemIndexAdvanced)
		_de(_toolbarItemIndexDefualtIRCopMessages, self.contentViewDefaultIRCopMessages, _toolbarItemIndexAdvanced)

#if TEXTUAL_BUILT_WITH_ADVANCED_ENCRYPTION == 1
		_de(_toolbarItemIndexOffRecordMessaging, self.contentViewOffRecordMessaging, _toolbarItemIndexAdvanced)
#endif

		_de(_toolbarItemIndexExperimentalSettings, self.contentViewExperimentalSettings, _toolbarItemIndexAdvanced)

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

- (void)resetWindowFrameToDefault
{
	NSRect windowFrame = self.window.frame;

	NSRect contentViewFrame = self.contentView.frame;
	NSRect contentViewGeneralFrame = self.contentViewGeneral.frame;

	for (NSView *subview in self.contentView.subviews) {
		[subview removeFromSuperview];
	}

	CGFloat contentViewHeightDifference = (NSHeight(contentViewFrame) - NSHeight(contentViewGeneralFrame));

	windowFrame.size.height -= contentViewHeightDifference;

	windowFrame.origin.y += contentViewHeightDifference;

	[self.window setFrame:windowFrame display:NO];
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

- (NSString *)scrollbackLimit
{
	return _unsignedIntegerString([TPCPreferences scrollbackLimit]);
}

- (void)setScrollbackLimit:(NSString *)value
{
	[TPCPreferences setScrollbackLimit:value.integerValue];
}

- (NSString *)completionSuffix
{
	return [TPCPreferences tabCompletionSuffix];
}

- (void)setCompletionSuffix:(NSString *)value
{
	[TPCPreferences setTabCompletionSuffix:value];
}

- (NSString *)inlineImageMaxWidth
{
	return _unsignedIntegerString([TPCPreferences inlineImagesMaxWidth]);
}

- (NSString *)inlineImageMaxHeight
{
	return _unsignedIntegerString([TPCPreferences inlineImagesMaxHeight]);
}

- (void)setInlineImageMaxWidth:(NSString *)value
{
	[TPCPreferences setInlineImagesMaxWidth:value.integerValue];
}

- (void)setInlineImageMaxHeight:(NSString *)value
{
	[TPCPreferences setInlineImagesMaxHeight:value.integerValue];
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
- (BOOL)textEncryptionIsOpportunistic
{
	if ([TPCPreferences textEncryptionIsRequired]) {
		return YES;
	}

	return [TPCPreferences textEncryptionIsOpportunistic];
}

- (void)setTextEncryptionIsOpportunistic:(BOOL)value
{
	[TPCPreferences setTextEncryptionIsOpportunistic:value];
}
#else
- (BOOL)textEncryptionIsOpportunistic
{
	return NO;
}

- (void)setTextEncryptionIsOpportunistic:(BOOL)value
{
	;
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

- (BOOL)validateValue:(inout id *)value forKey:(NSString *)key error:(out NSError **)outError
{
	if ([key isEqualToString:@"scrollbackLimit"]) {
		NSInteger valueInteger = [*value integerValue];

		if (valueInteger < _scrollbackLinesMin) {
			*value = _unsignedIntegerString(_scrollbackLinesMin);
		} else if (valueInteger > _scrollbackLinesMax) {
			*value = _unsignedIntegerString(_scrollbackLinesMax);
		}
	} else if ([key isEqualToString:@"inlineImageMaxWidth"]) {
		NSInteger valueInteger = [*value integerValue];

		if (valueInteger < _inlineImageWidthMin) {
			*value = _unsignedIntegerString(_inlineImageWidthMin);
		} else if (_inlineImageWidthMax < valueInteger) {
			*value = _unsignedIntegerString(_inlineImageWidthMax);
		}
	} else if ([key isEqualToString:@"inlineImageMaxHeight"]) {
		NSInteger valueInteger = [*value integerValue];

		if (valueInteger < _inlineImageHeightMin) {
			*value = _unsignedIntegerString(_inlineImageHeightMin);
		} else if (_inlineImageHeightMax < valueInteger) {
			*value = _unsignedIntegerString(_inlineImageHeightMax);
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
#pragma mark Sounds

- (void)updateAlertSelection
{
    [self.alertTypeChoiceButton removeAllItems];

    NSArray *alerts = self.alertSounds;

    for (id alert in alerts) {
		if ([alert isKindOfClass:[NSNumber class]]) {
			 TDCPreferencesSoundWrapper *alertWrapper =
			[TDCPreferencesSoundWrapper soundWrapperWithEventType:[alert unsignedIntegerValue]];

			NSMenuItem *item = [NSMenuItem new];

			item.tag = alertWrapper.eventType;

			item.title = alertWrapper.displayName;

			[self.alertTypeChoiceButton.menu addItem:item];
		} else {
			[self.alertTypeChoiceButton.menu addItem:[NSMenuItem separatorItem]];
		}
    }

    [self.alertTypeChoiceButton selectItemAtIndex:0];

	/* ======================================== */

	[self.alertSoundChoiceButton removeAllItems];

	NSArray *alertSounds = [self availableSounds];

    for (id alertSound in alertSounds) {
		if ([alertSound isKindOfClass:[NSMenuItem class]] == NO) {
			NSMenuItem *item = [NSMenuItem new];

			item.title = alertSound;

			[self.alertSoundChoiceButton.menu addItem:item];
		} else {
			[self.alertSoundChoiceButton.menu addItem:alertSound];
		}
	}

    [self.alertSoundChoiceButton selectItemAtIndex:0];
}

- (void)onChangedAlertType:(id)sender
{
	TXNotificationType alertType = (TXNotificationType)self.alertTypeChoiceButton.selectedTag;

    TDCPreferencesSoundWrapper *alert = [TDCPreferencesSoundWrapper soundWrapperWithEventType:alertType];

	self.alertSpeakEventButton.state = alert.speakEvent;
    self.alertBounceDockIconButton.state = alert.bounceDockIcon;
    self.alertBounceDockIconRepeatedlyButton.enabled = (self.alertBounceDockIconButton.state == NSOnState);
    self.alertBounceDockIconRepeatedlyButton.state = alert.bounceDockIconRepeatedly;
    self.alertDisableWhileAwayButton.state = alert.disabledWhileAway;
    self.alertPushNotificationButton.state = alert.pushNotification;

	NSUInteger soundIndex = [[self availableSounds] indexOfObject:alert.alertSound];
	
	if (soundIndex == NSNotFound) {
		[self.alertSoundChoiceButton selectItemAtIndex:0];
	} else {
		[self.alertSoundChoiceButton selectItemAtIndex:soundIndex];
	}
}

- (void)onChangedAlertNotification:(id)sender
{
	TXNotificationType alertType = (TXNotificationType)self.alertTypeChoiceButton.selectedTag;

    TDCPreferencesSoundWrapper *alert = [TDCPreferencesSoundWrapper soundWrapperWithEventType:alertType];

    alert.pushNotification = self.alertPushNotificationButton.state;
}

- (void)onChangedAlertSpoken:(id)sender
{
	TXNotificationType alertType = (TXNotificationType)self.alertTypeChoiceButton.selectedTag;

    TDCPreferencesSoundWrapper *alert = [TDCPreferencesSoundWrapper soundWrapperWithEventType:alertType];

	alert.speakEvent = self.alertSpeakEventButton.state;
}

- (void)onChangedAlertDisableWhileAway:(id)sender
{
	TXNotificationType alertType = (TXNotificationType)self.alertTypeChoiceButton.selectedTag;

    TDCPreferencesSoundWrapper *alert = [TDCPreferencesSoundWrapper soundWrapperWithEventType:alertType];

	alert.disabledWhileAway = self.alertDisableWhileAwayButton.state;
}

- (void)onChangedAlertBounceDockIcon:(id)sender
{
	TXNotificationType alertType = (TXNotificationType)self.alertTypeChoiceButton.selectedTag;
    
    TDCPreferencesSoundWrapper *alert = [TDCPreferencesSoundWrapper soundWrapperWithEventType:alertType];
    
	alert.bounceDockIcon = self.alertBounceDockIconButton.state;
    
	self.alertBounceDockIconRepeatedlyButton.enabled = (self.alertBounceDockIconButton.state == NSOnState);
}

- (void)onChangedAlertBounceDockIconRepeatedly:(id)sender
{
	TXNotificationType alertType = (TXNotificationType)self.alertTypeChoiceButton.selectedTag;
    
	TDCPreferencesSoundWrapper *alert = [TDCPreferencesSoundWrapper soundWrapperWithEventType:alertType];
    
	alert.bounceDockIconRepeatedly = self.alertBounceDockIconRepeatedlyButton.state;
}

- (void)onChangedAlertSound:(id)sender
{
	TXNotificationType alertType = (TXNotificationType)self.alertTypeChoiceButton.selectedTag;

    TDCPreferencesSoundWrapper *alert = [TDCPreferencesSoundWrapper soundWrapperWithEventType:alertType];

	alert.alertSound = self.alertSoundChoiceButton.titleOfSelectedItem;
}

- (NSArray *)availableSounds
{
	NSMutableArray *sounds = [NSMutableArray array];

	[sounds addObject:[TDCPreferencesSoundWrapper localizedAlertEmptySoundTitle]];

	[sounds addObject:[NSMenuItem separatorItem]];

	[sounds addObjectsFromArray:[TLOSoundPlayer uniqueListOfSounds]];

	return [sounds copy];
}

#pragma mark -
#pragma mark File Transfer Destination Folder Popup

- (BOOL)panel:(id)sender validateURL:(NSURL *)url error:(NSError **)outError
{
	NSString *cloudPath = [[TPCPathInfo userHomeFolderPath] stringByAppendingPathComponent:@"/Library/Mobile Documents/"];

	if ([url.relativePath hasPrefix:cloudPath]) {
		if (outError) {
			NSMutableDictionary *userInfo = [NSMutableDictionary dictionary];

			userInfo[NSURLErrorKey] = url;

			userInfo[NSLocalizedDescriptionKey] = TXTLS(@"TDCPreferencesController[1010][1]");

			userInfo[NSLocalizedRecoverySuggestionErrorKey] = TXTLS(@"TDCPreferencesController[1010][2]");

			*outError = [NSError errorWithDomain:NSCocoaErrorDomain code:27984 userInfo:userInfo];
		}

		return NO;
	}

	return YES;
}

- (void)updateFileTransferDownloadDestinationFolder
{
	TDCFileTransferDialog *transferController = menuController().fileTransferController;

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
	TDCFileTransferDialog *transferController = menuController().fileTransferController;

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
						path, bookmarkError.localizedDescription)
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
						path, bookmarkError.localizedDescription)

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

	NSDictionary *themes = [TPCThemeController dictionaryOfAllThemes];

	NSArray *themeNamesSorted = themes.sortedDictionaryKeys;

	for (NSString *themeName in themeNamesSorted) {
		NSString *themeSource = themes[themeName];

		NSMenuItem *item = [NSMenuItem menuItemWithTitle:themeName target:nil action:nil];

		item.userInfo = themeSource;

		[self.themeSelectionButton.menu addItem:item];
	}

	[self.themeSelectionButton selectItemWithTitle:themeController().name];
}

- (void)onChangedThemeSelection:(id)sender
{
	NSMenuItem *selectedItem = self.themeSelectionButton.selectedItem;

	NSString *newThemeName = selectedItem.title;

	 TPCThemeControllerStorageLocation expectedStorageLocation =
	[TPCThemeController expectedStorageLocationOfThemeWithName:selectedItem.userInfo];
	
	NSString *newTheme = [TPCThemeController buildFilename:newThemeName forStorageLocation:expectedStorageLocation];
	
	NSString *currentTheme = [TPCPreferences themeName];
	
	if ([currentTheme isEqual:newTheme]) {
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

		[forcedValuesMutable appendString:NSStringNewlinePlaceholder];
	}

	if ([TPCPreferences themeTimestampFormatPreferenceUserConfigurable] == NO) {
		[forcedValuesMutable appendString:TXTLS(@"TDCPreferencesController[1009][2]")];

		[forcedValuesMutable appendString:NSStringNewlinePlaceholder];
	}

	if ([TPCPreferences themeChannelViewFontPreferenceUserConfigurable] == NO) {
		[forcedValuesMutable appendString:TXTLS(@"TDCPreferencesController[1009][4]")];

		[forcedValuesMutable appendString:NSStringNewlinePlaceholder];
	}

	if ([TPCPreferences invertSidebarColorsPreferenceUserConfigurable] == NO) {
		[forcedValuesMutable appendString:TXTLS(@"TDCPreferencesController[1009][3]")];

		[forcedValuesMutable appendString:NSStringNewlinePlaceholder];
	}

	NSString *forcedValues = forcedValuesMutable.trim;

	if (forcedValues.length == 0) {
		return;
	}

	NSString *currentTheme = [TPCPreferences themeName];

	NSString *themeName = [TPCThemeController extractThemeName:currentTheme];

	[TLOPopupPrompts sheetWindowWithWindow:[NSApp keyWindow]
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
#pragma mark Actions

#if TEXTUAL_BUILT_WITH_ADVANCED_ENCRYPTION == 1
- (void)offRecordMessagingPolicyChanged:(id)sender
{
	[sharedEncryptionManager() updatePolicy];

	[self willChangeValueForKey:@"textEncryptionIsOpportunistic"];
	[self didChangeValueForKey:@"textEncryptionIsOpportunistic"];
}
#endif

- (void)onHideMountainLionDeprecationWarning:(id)sender
{
	self.mountainLionDeprecationWarningIsVisible = NO;

	self.mountainLionDeprecationWarningView.hidden = YES;

	[RZUserDefaults() setBool:YES forKey:@"TDCPreferencesControllerDidShowMountainLionDeprecationWarning"];

	[self firstPane:self.contentViewGeneral selectedItem:_toolbarItemIndexGeneral];
}

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
		if (u.config.proxyType == IRCConnectionSocketTorBrowserType) {
			presentDialog = YES;
		}
	}

	if (presentDialog == NO) {
		NSUInteger applicationIndex =
		[RZWorkspace().runningApplications indexOfObjectPassingTest:^BOOL(NSRunningApplication *application, NSUInteger index, BOOL *stop) {
			return
			(NSObjectsAreEqual(application.localizedName, @"TorBrowser") ||
			 NSObjectsAreEqual(application.localizedName, @"Tor Browser"));
		}];

		presentDialog = (applicationIndex != NSNotFound);
	}

	if (presentDialog == NO) {
		return;
	}

	BOOL clickResult =
	[TLOPopupPrompts dialogWindowWithMessage:TXTLS(@"Prompts[1111][2]")
									   title:TXTLS(@"Prompts[1111][1]")
							   defaultButton:TXTLS(@"Prompts[0005]")
							 alternateButton:TXTLS(@"Prompts[1111][3]")];

	if (clickResult == NO) {
		[TDCPreferencesController openProxySettingsInSystemPreferences];
	}
}

+ (void)openProxySettingsInSystemPreferences
{
	AEDesc aeDesc = { typeNull, NULL };

	OSStatus aeDescStatus = AECreateDesc('ptru', "Proxies", 7,  &aeDesc);

	if (aeDescStatus != noErr) {
		LogToConsoleError("aeDescStatus returned value other than noErr: %{public}i", aeDescStatus)

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
	if ([TPCPreferences showInlineImages]) {
		[TDCPreferencesController showTorAnonymityNetworkInlineMediaWarning];
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

#if TEXTUAL_BUILT_WITH_ICLOUD_SUPPORT == 1
	[sharedCloudManager() removeObjectForKeyNextUpstreamSync:@"User List Mode Badge Colors -> +y"];
	[sharedCloudManager() removeObjectForKeyNextUpstreamSync:@"User List Mode Badge Colors -> +q"];
	[sharedCloudManager() removeObjectForKeyNextUpstreamSync:@"User List Mode Badge Colors -> +a"];
	[sharedCloudManager() removeObjectForKeyNextUpstreamSync:@"User List Mode Badge Colors -> +o"];
	[sharedCloudManager() removeObjectForKeyNextUpstreamSync:@"User List Mode Badge Colors -> +h"];
	[sharedCloudManager() removeObjectForKeyNextUpstreamSync:@"User List Mode Badge Colors -> +v"];
#endif

	[self onChangedUserListModeColor:nil];
}

- (void)onResetServerListUnreadBadgeColorsToDefault:(id)sender
{
	[RZUserDefaults() setObject:nil forKey:@"Server List Unread Message Count Badge Colors -> Highlight"];

#if TEXTUAL_BUILT_WITH_ICLOUD_SUPPORT == 1
	[sharedCloudManager() removeObjectForKeyNextUpstreamSync:@"Server List Unread Message Count Badge Colors -> Highlight"];
#endif
	
	[self onChangedServerListUnreadBadgeColor:sender];
}

- (void)onChangedInputHistoryScheme:(id)sender
{
	[TPCPreferences performReloadAction:TPCPreferencesReloadInputHistoryScopeAction];
}

- (void)onChangedSidebarColorInversion:(id)sender
{
	[TPCPreferences performReloadAction:TPCPreferencesReloadMainWindowAppearanceAction];
}

- (void)onChangedTheme:(id)sender
{
	self.reloadingTheme = YES;

	[TPCPreferences performReloadAction:(TPCPreferencesReloadStyleWithTableViewsAction | TPCPreferencesReloadTextDirectionAction)];
}

- (void)onThemeReloadComplete:(NSNotification *)notification
{
	if (self.reloadingTheme) {
		self.reloadingTheme = NO;
	} else {
		return;
	}

	if (self.reloadingThemeBySelection) {
		self.reloadingThemeBySelection = NO;

		[self onChangedThemeSelectionReloadComplete:notification];
	}
}

- (void)onChangedMainWindowSegmentedController:(id)sender
{
	[TPCPreferences performReloadAction:TPCPreferencesReloadTextFieldSegmentedControllerOriginAction];
}

- (void)onChangedUserListModeColor:(id)sender
{
	[TPCPreferences performReloadAction:(TPCPreferencesReloadMemberListUserBadgesAction | TPCPreferencesReloadMemberListAction)];
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

- (void)onOpenPathToCloudFolder:(id)sender
{
#if TEXTUAL_BUILT_WITH_ICLOUD_SUPPORT == 1
	[TPCPathInfo openApplicationUbiquitousContainerPath];
#endif
}

- (void)onOpenPathToScripts:(id)sender
{
	[RZWorkspace() openFile:[TPCPathInfo applicationSupportFolderPathInGroupContainer]];
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
- (void)onPurgeOfCloudDataRequestedCallback:(TLOPopupPromptReturnType)returnCode
{
	if (returnCode != TLOPopupPromptReturnPrimaryType) {
		return;
	}

	[sharedCloudManager() purgeDataStoredWithCloud];

	NSError *deleteThemesError = nil;

	if ([RZFileManager() removeItemAtPath:[TPCPathInfo cloudCustomThemeFolderPath] error:&deleteThemesError] == NO) {
		LogToConsoleError("Delete Error: %{public}@",
				deleteThemesError.localizedDescription)
	}
}
#endif

- (void)onPurgeOfCloudDataRequested:(id)sender
{
#if TEXTUAL_BUILT_WITH_ICLOUD_SUPPORT == 1
	[TLOPopupPrompts sheetWindowWithWindow:NSApp.keyWindow
									  body:TXTLS(@"TDCPreferencesController[1001][2]")
									 title:TXTLS(@"TDCPreferencesController[1001][1]")
							 defaultButton:TXTLS(@"Prompts[0001]")
						   alternateButton:TXTLS(@"Prompts[0002]")
							   otherButton:nil
						   completionBlock:^(TLOPopupPromptReturnType buttonClicked, NSAlert *originalAlert, BOOL suppressionResponse) {
							   [self onPurgeOfCloudDataRequestedCallback:buttonClicked];
						   }];
#endif
}

- (void)openPathToThemesCallback:(TLOPopupPromptReturnType)returnCode withOriginalAlert:(NSAlert *)originalAlert
{
	if (returnCode == TLOPopupPromptReturnSecondaryType) {
		[self openPathToTheme];
	}

	if (returnCode == TLOPopupPromptReturnPrimaryType) {
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
		[TLOPopupPrompts sheetWindowWithWindow:NSApp.keyWindow
										  body:TXTLS(@"TDCPreferencesController[1007][2]")
										 title:TXTLS(@"TDCPreferencesController[1007][1]")
								 defaultButton:TXTLS(@"Prompts[0001]")
							   alternateButton:TXTLS(@"Prompts[0002]")
								   otherButton:nil
							   completionBlock:^(TLOPopupPromptReturnType buttonClicked, NSAlert *originalAlert, BOOL suppressionResponse) {
								   [self openPathToThemesCallback:buttonClicked withOriginalAlert:originalAlert];
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

	self.window.alphaValue = 0.0;

	[self resetWindowFrameToDefault];

	[self.window saveWindowStateForClass:self.class];

	if ([self.delegate respondsToSelector:@selector(preferencesDialogWillClose:)]) {
		[self.delegate preferencesDialogWillClose:self];
	}
}

@end

NS_ASSUME_NONNULL_END
