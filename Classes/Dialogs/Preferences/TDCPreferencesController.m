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

#import "TextualApplication.h"

#define _linesMin					100
#define _linesMax					15000
#define _inlineImageWidthMax		2000
#define _inlineImageWidthMin		40
#define _inlineImageHeightMax		6000
#define _inlineImageHeightMin		0

#define _fileTransferPortRangeMin			1024
#define _fileTransferPortRangeMax			65535

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

@interface TDCPreferencesController ()
@property (nonatomic, copy) NSArray *alertSounds;
@property (nonatomic, strong) IBOutlet NSArrayController *excludeKeywordsArrayController;
@property (nonatomic, strong) IBOutlet NSArrayController *matchKeywordsArrayController;
@property (nonatomic, strong) IBOutlet NSButton *addExcludeKeywordButton;
@property (nonatomic, strong) IBOutlet NSButton *alertBounceDockIconButton;
@property (nonatomic, strong) IBOutlet NSButton *alertDisableWhileAwayButton;
@property (nonatomic, strong) IBOutlet NSButton *alertPushNotificationButton;
@property (nonatomic, strong) IBOutlet NSButton *alertSpeakEventButton;
@property (nonatomic, strong) IBOutlet NSButton *highlightNicknameButton;
@property (nonatomic, strong) IBOutlet NSPopUpButton *alertSoundChoiceButton;
@property (nonatomic, strong) IBOutlet NSPopUpButton *alertTypeChoiceButton;
@property (nonatomic, strong) IBOutlet NSPopUpButton *themeSelectionButton;
@property (nonatomic, strong) IBOutlet NSPopUpButton *transcriptFolderButton;
@property (nonatomic, strong) IBOutlet NSPopUpButton *fileTransferDownloadDestinationButton;
@property (nonatomic, strong) IBOutlet NSTableView *excludeKeywordsTable;
@property (nonatomic, strong) IBOutlet NSTableView *installedScriptsTable;
@property (nonatomic, strong) IBOutlet NSTableView *keywordsTable;
@property (nonatomic, strong) IBOutlet NSTextField *alertNotificationDestinationTextField;
@property (nonatomic, strong) IBOutlet NSTextField *fileTransferManuallyEnteredIPAddressTextField;
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
@property (nonatomic, weak) IBOutlet NSView *shareDataBetweenDevicesView;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *shareDataBetweenDevicesViewHeightConstraint;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *contentViewHeightConstraint;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *contentViewWidthConstraint;
@property (nonatomic, strong) IBOutlet NSView *mountainLionDeprecationWarningView;
@property (nonatomic, strong) IBOutlet NSToolbar *navigationToolbar;
@property (nonatomic, strong) IBOutlet NSMenu *installedAddonsMenu;
@property (nonatomic, assign) BOOL mountainLionDeprecationWarningIsVisible;

- (IBAction)onPrefPaneSelected:(id)sender;

- (IBAction)onAddKeyword:(id)sender;
- (IBAction)onAddExcludeKeyword:(id)sender;

- (IBAction)onChangedAlertSpoken:(id)sender;
- (IBAction)onChangedAlertSound:(id)sender;
- (IBAction)onChangedAlertDisableWhileAway:(id)sender;
- (IBAction)onChangedAlertBounceDockIcon:(id)sender;
- (IBAction)onChangedAlertNotification:(id)sender;
- (IBAction)onChangedAlertType:(id)sender;

- (IBAction)onChangedCloudSyncingServices:(id)sender;
- (IBAction)onChangedCloudSyncingServicesServersOnly:(id)sender;

- (IBAction)onOpenPathToCloudFolder:(id)sender;

- (IBAction)onManageiCloudButtonClicked:(id)sender;
- (IBAction)onPurgeOfCloudDataRequested:(id)sender;
- (IBAction)onPurgeOfCloudFilesRequested:(id)sender;

- (IBAction)onChangedHighlightLogging:(id)sender;
- (IBAction)onChangedHighlightType:(id)sender;
- (IBAction)onChangedInputHistoryScheme:(id)sender;
- (IBAction)onChangedMainWindowSegmentedController:(id)sender;
- (IBAction)onChangedSidebarColorInversion:(id)sender;
- (IBAction)onChangedStyle:(id)sender;
- (IBAction)onChangedTheme:(id)sender;
- (IBAction)onChangedTranscriptFolder:(id)sender;
- (IBAction)onChangedTransparency:(id)sender;
- (IBAction)onChangedUserListModeColor:(id)sender;
- (IBAction)onChangedUserListModeSortOrder:(id)sender;
- (IBAction)onChangedServerListUnreadBadgeColor:(id)sender;

- (IBAction)onChangedMainInputTextFieldFontSize:(id)sender;

- (IBAction)onHideMountainLionDeprecationWarning:(id)sender;

- (IBAction)onFileTransferIPAddressDetectionMethodChanged:(id)sender;
- (IBAction)onFileTransferDownloadDestinationFolderChanged:(id)sender;

- (IBAction)onResetUserListModeColorsToDefaults:(id)sender;
- (IBAction)onResetServerListUnreadBadgeColorsToDefault:(id)sender;

- (IBAction)onOpenPathToScripts:(id)sender;
- (IBAction)onOpenPathToThemes:(id)sender;

- (IBAction)onSelectNewFont:(id)sender;

#if TEXTUAL_BUILT_WITH_ADVANCED_ENCRYPTION == 1
- (IBAction)offRecordMessagingPolicyChanged:(id)sender;
#endif
@end

@implementation TDCPreferencesController

- (instancetype)init
{
	if ((self = [super init])) {
		[RZMainBundle() loadNibNamed:@"TDCPreferences" owner:self topLevelObjects:nil];
	}

	return self;
}

#pragma mark -
#pragma mark Utilities

- (void)show
{
	NSMutableArray *alertSounds = [NSMutableArray new];

	// self.alertSounds treats anything that is not a TDCPreferencesSoundWrapper as
	// an indicator that a [NSMenuItem separatorItem] should be placed in our menu.
	[alertSounds addObject:[TDCPreferencesSoundWrapper soundWrapperWithEventType:TXNotificationAddressBookMatchType]];
	[alertSounds addObject:NSStringWhitespacePlaceholder];
	[alertSounds addObject:[TDCPreferencesSoundWrapper soundWrapperWithEventType:TXNotificationConnectType]];
	[alertSounds addObject:[TDCPreferencesSoundWrapper soundWrapperWithEventType:TXNotificationDisconnectType]];
	[alertSounds addObject:NSStringWhitespacePlaceholder];
	[alertSounds addObject:[TDCPreferencesSoundWrapper soundWrapperWithEventType:TXNotificationHighlightType]];
	[alertSounds addObject:NSStringWhitespacePlaceholder];
	[alertSounds addObject:[TDCPreferencesSoundWrapper soundWrapperWithEventType:TXNotificationInviteType]];
	[alertSounds addObject:[TDCPreferencesSoundWrapper soundWrapperWithEventType:TXNotificationKickType]];
	[alertSounds addObject:NSStringWhitespacePlaceholder];
	[alertSounds addObject:[TDCPreferencesSoundWrapper soundWrapperWithEventType:TXNotificationChannelMessageType]];
	[alertSounds addObject:[TDCPreferencesSoundWrapper soundWrapperWithEventType:TXNotificationChannelNoticeType]];
	[alertSounds addObject:NSStringWhitespacePlaceholder];
	[alertSounds addObject:[TDCPreferencesSoundWrapper soundWrapperWithEventType:TXNotificationNewPrivateMessageType]];
	[alertSounds addObject:[TDCPreferencesSoundWrapper soundWrapperWithEventType:TXNotificationPrivateMessageType]];
	[alertSounds addObject:[TDCPreferencesSoundWrapper soundWrapperWithEventType:TXNotificationPrivateNoticeType]];
	[alertSounds addObject:NSStringWhitespacePlaceholder];
	[alertSounds addObject:[TDCPreferencesSoundWrapper soundWrapperWithEventType:TXNotificationFileTransferReceiveRequestedType]];
	[alertSounds addObject:NSStringWhitespacePlaceholder];
	[alertSounds addObject:[TDCPreferencesSoundWrapper soundWrapperWithEventType:TXNotificationFileTransferSendSuccessfulType]];
	[alertSounds addObject:[TDCPreferencesSoundWrapper soundWrapperWithEventType:TXNotificationFileTransferReceiveSuccessfulType]];
	[alertSounds addObject:NSStringWhitespacePlaceholder];
	[alertSounds addObject:[TDCPreferencesSoundWrapper soundWrapperWithEventType:TXNotificationFileTransferSendFailedType]];
	[alertSounds addObject:[TDCPreferencesSoundWrapper soundWrapperWithEventType:TXNotificationFileTransferReceiveFailedType]];

	[self setAlertSounds:alertSounds];

	/* Growl check. */
	BOOL growlRunning = [GrowlApplicationBridge isGrowlRunning];

	/* We only have notification center on mountain lion or newer so we have to
	 check what OS we are running on before we even doing anything. */
	if (growlRunning) {
		[[self alertNotificationDestinationTextField] setStringValue:TXTLS(@"TDCPreferencesController[1005]")];
	} else {
		[[self alertNotificationDestinationTextField] setStringValue:TXTLS(@"TDCPreferencesController[1006]")];
	}

	// Complete startup of preferences.
	[self setUpToolbarItemsAndMenus];

	[self updateThemeSelection];
    [self updateAlertSelection];
	[self updateTranscriptFolder];
	[self updateFileTransferDownloadDestinationFolder];

	[self onChangedAlertType:nil];
	[self onChangedHighlightType:nil];
	
	[self onFileTransferIPAddressDetectionMethodChanged:nil];

	[[self installedScriptsTable] setSortDescriptors:@[
		[NSSortDescriptor sortDescriptorWithKey:@"string" ascending:YES selector:@selector(caseInsensitiveCompare:)]
	]];

	[RZNotificationCenter() addObserver:self
							   selector:@selector(onCloudSyncControllerDidChangeThemeName:)
								   name:TPCThemeControllerThemeListDidChangeNotification
								 object:nil];
	
#if TEXTUAL_BUILT_WITH_ICLOUD_SUPPORT == 1
	[RZNotificationCenter() addObserver:self
							   selector:@selector(onCloudSyncControllerDidChangeThemeName:)
								   name:TPCPreferencesCloudSyncDidChangeGlobalThemeNamePreferenceNotification
								 object:nil];
#endif

	[[self window] restoreWindowStateForClass:[self class]];

	[self setMountainLionDeprecationWarningIsVisible:NO];

	if ([XRSystemInformation isUsingOSXMavericksOrLater] == NO) {
		BOOL warningViewHidden = [RZUserDefaults() boolForKey:@"TDCPreferencesControllerDidShowMountainLionDeprecationWarning"];

		if (warningViewHidden == NO) {
			[self setMountainLionDeprecationWarningIsVisible:YES];

			[[self mountainLionDeprecationWarningView] setHidden:NO];

			[self firstPane:[self mountainLionDeprecationWarningView] selectedItem:_toolbarItemIndexGeneral];
		}
	}

#if TEXTUAL_BUILT_WITH_ICLOUD_SUPPORT == 0
	/* Hide "Share data between devices" when iCloud support is not enabled
	 by setting the subview height to 0. Set height before calling firstPane: 
	 so that firstPane: can calculate the correct total height. */

	[[self shareDataBetweenDevicesViewHeightConstraint] setConstant:0.0];

	[[self contentViewGeneral] layoutSubtreeIfNeeded];
#endif

	if ([self mountainLionDeprecationWarningIsVisible] == NO) {
		[self firstPane:[self contentViewGeneral] selectedItem:_toolbarItemIndexGeneral];
	}

	[[self window] makeKeyAndOrderFront:nil];
}

#pragma mark -
#pragma mark NSToolbar Delegates

 - (void)setUpToolbarItemsAndMenus
{
	/* Extensions. */
	NSArray *bundles = [sharedPluginManager() pluginsWithPreferencePanes];

	if ([bundles count] > 0) {
		[[self installedAddonsMenu] addItem:[NSMenuItem separatorItem]];
	}

	for (THOPluginItem *plugin in bundles) {
		NSInteger tagIndex = ([bundles indexOfObject:plugin] + _addonsToolbarItemMultiplier);

		NSMenuItem *pluginMenu = [NSMenuItem menuItemWithTitle:[plugin pluginPreferencesPaneMenuItemName]
														target:self
														action:@selector(onPrefPaneSelected:)];

		[pluginMenu setTag:tagIndex];

		[[self installedAddonsMenu] addItem:pluginMenu];
	}
}

 - (void)onPrefPaneSelected:(id)sender
{
	if ([self mountainLionDeprecationWarningIsVisible]) {
		[[self navigationToolbar] setSelectedItemIdentifier:[NSString stringWithInteger:_toolbarItemIndexGeneral]];

		NSBeep();

		return;
	}

#define _de(matchTag, view, selectionIndex)			case (matchTag): { [self firstPane:(view) selectedItem:(selectionIndex)]; break; }

	switch ([sender tag]) {
		_de(_toolbarItemIndexGeneral,				[self contentViewGeneral],			_toolbarItemIndexGeneral)
		_de(_toolbarItemIndexHighlights,			[self contentViewHighlights],		_toolbarItemIndexHighlights)
		_de(_toolbarItemIndexNotifications,			[self contentViewNotifications],	_toolbarItemIndexNotifications)

		_de(_toolbarItemIndexControls,				[self contentViewControls],			_toolbarItemIndexControls)
		_de(_toolbarItemIndexInterface,				[self contentViewInterface],		_toolbarItemIndexInterface)
		_de(_toolbarItemIndexStyle,					[self contentViewStyle],			_toolbarItemIndexStyle)

		_de(_toolbarItemIndexChannelManagement,		[self contentViewChannelManagement],		_toolbarItemIndexAdvanced)
		_de(_toolbarItemIndexCommandScope,			[self contentViewCommandScope],				_toolbarItemIndexAdvanced)
		_de(_toolbarItemIndexIncomingData,			[self contentViewIncomingData],				_toolbarItemIndexAdvanced)
		_de(_toolbarItemIndexFileTransfers,			[self contentViewFileTransfers],			_toolbarItemIndexAdvanced)
		_de(_toolbarItemIndexFloodControl,			[self contentViewFloodControl],				_toolbarItemIndexAdvanced)

		_de(_toolbarItemIndexLogLocation,			[self contentViewLogLocation],				_toolbarItemIndexAdvanced);

		_de(_toolbarItemIndexDefaultIdentity,		[self contentViewDefaultIdentity],			_toolbarItemIndexAdvanced)
		_de(_toolbarItemIndexDefualtIRCopMessages,	[self contentViewDefaultIRCopMessages],		_toolbarItemIndexAdvanced)

#if TEXTUAL_BUILT_WITH_ADVANCED_ENCRYPTION == 1
		_de(_toolbarItemIndexOffRecordMessaging,	[self contentViewOffRecordMessaging],		_toolbarItemIndexAdvanced)
#endif

		_de(_toolbarItemIndexExperimentalSettings,	[self contentViewExperimentalSettings],		_toolbarItemIndexAdvanced);

		_de(_addonsToolbarInstalledAddonsMenuItemIndex,		[self contentViewInstalledAddons],	_toolbarItemIndexAddons)

		default: {
			if ([sender tag] >= _addonsToolbarItemMultiplier) {
				NSInteger pluginIndex = ([sender tag] - _addonsToolbarItemMultiplier);

				THOPluginItem *plugin = [sharedPluginManager() pluginsWithPreferencePanes][pluginIndex];

				if (plugin) {
					NSView *prefsView = [plugin pluginPreferencesPaneView];

					if (prefsView) {
						[self firstPane:prefsView selectedItem:_toolbarItemIndexAddons];
					}
				}
			}

			break;
		}
	}

#undef _de
}

- (void)firstPane:(NSView *)view selectedItem:(NSInteger)key
{
	[[self contentView] attachSubview:view
			  adjustedWidthConstraint:[self contentViewWidthConstraint]
			 adjustedHeightConstraint:[self contentViewHeightConstraint]];

	[[self navigationToolbar] setSelectedItemIdentifier:[NSString stringWithInteger:key]];
}

#pragma mark -
#pragma mark KVC Properties

- (NSArray *)installedScripts
{
	NSMutableArray *scriptsInstalled = [NSMutableArray array];

	[scriptsInstalled addObjectsFromArray:[sharedPluginManager() supportedAppleScriptCommands]];
	[scriptsInstalled addObjectsFromArray:[sharedPluginManager() supportedUserInputCommands]];

	return [scriptsInstalled stringArryControllerObjects];
}

- (NSString *)maxLogLines
{
	return [NSString stringWithInteger:[TPCPreferences scrollbackLimit]];
}

- (void)setMaxLogLines:(NSString *)value
{
	[TPCPreferences setScrollbackLimit:[value integerValue]];
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
	return [NSString stringWithInteger:[TPCPreferences inlineImagesMaxWidth]];
}

- (NSString *)inlineImageMaxHeight
{
	return [NSString stringWithInteger:[TPCPreferences inlineImagesMaxHeight]];;
}

- (void)setInlineImageMaxWidth:(NSString *)value
{
	[TPCPreferences setInlineImagesMaxWidth:[value integerValue]];
}

- (void)setInlineImageMaxHeight:(NSString *)value
{
	[TPCPreferences setInlineImagesMaxHeight:[value integerValue]];
}

- (NSString *)themeChannelViewFontName
{
	return [TPCPreferences themeChannelViewFontName];
}

- (double)themeChannelViewFontSize
{
	return [TPCPreferences themeChannelViewFontSize];
}

- (void)setThemeChannelViewFontName:(id)value
{
	return;
}

- (void)setThemeChannelViewFontSize:(id)value
{
	return;
}

- (NSString *)fileTransferPortRangeStart
{
	return [NSString stringWithInteger:[TPCPreferences fileTransferPortRangeStart]];
}

- (NSString *)fileTransferPortRangeEnd
{
	return [NSString stringWithInteger:[TPCPreferences fileTransferPortRangeEnd]];
}

- (void)setFileTransferPortRangeStart:(NSString *)value
{
	[TPCPreferences setFileTransferPortRangeStart:[value integerValue]];
}

- (void)setFileTransferPortRangeEnd:(NSString *)value
{
	[TPCPreferences setFileTransferPortRangeEnd:[value integerValue]];
}

- (BOOL)validateValue:(inout __autoreleasing id *)value forKey:(NSString *)key error:(out NSError *__autoreleasing *)outError
{
	if ([key isEqualToString:@"maxLogLines"]) {
		NSInteger n = [*value integerValue];

		if (n < _linesMin) {
			*value = [NSString stringWithInteger:_linesMin];
		} else if (n > _linesMax) {
			*value = [NSString stringWithInteger:_linesMax];
		}
	} else if ([key isEqualToString:@"inlineImageMaxWidth"]) {
		NSInteger n = [*value integerValue];

		if (n < _inlineImageWidthMin) {
			*value = [NSString stringWithInteger:_inlineImageWidthMin];
		} else if (_inlineImageWidthMax < n) {
			*value = [NSString stringWithInteger:_inlineImageWidthMax];
		}
	} else if ([key isEqualToString:@"inlineImageMaxHeight"]) {
		NSInteger n = [*value integerValue];

		if (n < _inlineImageHeightMin) {
			*value = [NSString stringWithInteger:_inlineImageHeightMin];
		} else if (_inlineImageHeightMax < n) {
			*value = [NSString stringWithInteger:_inlineImageHeightMax];
		}
	} else if ([key isEqualToString:@"fileTransferPortRangeStart"]) {
		NSInteger n = [*value integerValue];
		
		NSInteger t = [TPCPreferences fileTransferPortRangeEnd];
		
		if (n < _fileTransferPortRangeMin) {
			*value = [NSString stringWithInteger:_fileTransferPortRangeMin];
		} else if (_fileTransferPortRangeMax < n) {
			*value = [NSString stringWithInteger:_fileTransferPortRangeMax];
		}
		
		n = [*value integerValue];
		
		if (n > t) {
			*value = [NSString stringWithInteger:t];
		}
	} else if ([key isEqualToString:@"fileTransferPortRangeEnd"]) {
		NSInteger n = [*value integerValue];
		
		NSInteger t = [TPCPreferences fileTransferPortRangeStart];
		
		if (n < _fileTransferPortRangeMin) {
			*value = [NSString stringWithInteger:_fileTransferPortRangeMin];
		} else if (_fileTransferPortRangeMax < n) {
			*value = [NSString stringWithInteger:_fileTransferPortRangeMax];
		}
		
		n = [*value integerValue];
		
		if (n < t) {
			*value = [NSString stringWithInteger:t];
		}
	}

	return YES;
}

#pragma mark -
#pragma mark Sounds

- (void)updateAlertSelection
{
	[[self alertSoundChoiceButton] removeAllItems];

	NSArray *alertSounds = [self availableSounds];

    for (id alertSound in alertSounds) {
		if ([alertSound isKindOfClass:[NSMenuItem class]] == NO) {
			NSMenuItem *item = [NSMenuItem new];

			[item setTitle:alertSound];

			[[[self alertSoundChoiceButton] menu] addItem:item];
		} else {
			[[[self alertSoundChoiceButton] menu] addItem:alertSound];
		}
	}

    [[self alertSoundChoiceButton] selectItemAtIndex:0];

	// ---- //

    [[self alertTypeChoiceButton] removeAllItems];

    NSArray *alerts = [self alertSounds];

    for (id alert in alerts) {
		if ([alert isKindOfClass:[TDCPreferencesSoundWrapper class]]) {
			NSMenuItem *item = [NSMenuItem new];

			[item setTitle:[alert displayName]];
			[item setTag:[alert eventType]];

			[[[self alertTypeChoiceButton] menu] addItem:item];
		} else {
			[[[self alertTypeChoiceButton] menu] addItem:[NSMenuItem separatorItem]];
		}
    }

    [[self alertTypeChoiceButton] selectItemAtIndex:0];
}

- (void)onChangedAlertType:(id)sender
{
	TXNotificationType alertType = (TXNotificationType)[[self alertTypeChoiceButton] selectedTag];

    TDCPreferencesSoundWrapper *alert = [TDCPreferencesSoundWrapper soundWrapperWithEventType:alertType];

	[[self alertSpeakEventButton] setState:[alert speakEvent]];
    [[self alertPushNotificationButton] setState:[alert pushNotification]];
    [[self alertDisableWhileAwayButton] setState:[alert disabledWhileAway]];
    [[self alertBounceDockIconButton] setState:[alert bounceDockIcon]];

	NSInteger soundObject = [[self availableSounds] indexOfObject:[alert alertSound]];
	
	if (soundObject == NSNotFound) {
		[[self alertSoundChoiceButton] selectItemAtIndex:0];
	} else {
		[[self alertSoundChoiceButton] selectItemAtIndex:soundObject];
	}
}

- (void)onChangedAlertNotification:(id)sender
{
	TXNotificationType alertType = (TXNotificationType)[[self alertTypeChoiceButton] selectedTag];

    TDCPreferencesSoundWrapper *alert = [TDCPreferencesSoundWrapper soundWrapperWithEventType:alertType];

    [alert setPushNotification:[[self alertPushNotificationButton] state]];
	
	alert = nil;
}

- (void)onChangedAlertSpoken:(id)sender
{
	TXNotificationType alertType = (TXNotificationType)[[self alertTypeChoiceButton] selectedTag];

    TDCPreferencesSoundWrapper *alert = [TDCPreferencesSoundWrapper soundWrapperWithEventType:alertType];

	[alert setSpeakEvent:[[self alertSpeakEventButton] state]];
	
	alert = nil;
}

- (void)onChangedAlertDisableWhileAway:(id)sender
{
	TXNotificationType alertType = (TXNotificationType)[[self alertTypeChoiceButton] selectedTag];

    TDCPreferencesSoundWrapper *alert = [TDCPreferencesSoundWrapper soundWrapperWithEventType:alertType];

	[alert setDisabledWhileAway:[[self alertDisableWhileAwayButton] state]];
	
	alert = nil;
}

- (void)onChangedAlertBounceDockIcon:(id)sender
{
	TXNotificationType alertType = (TXNotificationType)[[self alertTypeChoiceButton] selectedTag];
    
    TDCPreferencesSoundWrapper *alert = [TDCPreferencesSoundWrapper soundWrapperWithEventType:alertType];
    
	[alert setBounceDockIcon:[[self alertBounceDockIconButton] state]];
	
	alert = nil;
}

- (void)onChangedAlertSound:(id)sender
{
	TXNotificationType alertType = (TXNotificationType)[[self alertTypeChoiceButton] selectedTag];

    TDCPreferencesSoundWrapper *alert = [TDCPreferencesSoundWrapper soundWrapperWithEventType:alertType];

	[alert setAlertSound:[[self alertSoundChoiceButton] titleOfSelectedItem]];
	
	alert = nil;
}

- (NSArray *)availableSounds
{
	NSString *systemSoundFolder = @"/System/Library/Sounds";

	NSURL *userSoundFolderURL = [RZFileManager() URLForDirectory:NSLibraryDirectory
														inDomain:NSUserDomainMask
											   appropriateForURL:nil
														  create:YES
														   error:NULL];

	NSString *userSoundFolder = [[userSoundFolderURL relativePath] stringByAppendingPathComponent:@"/Sounds"];

	NSArray *soundPathList = [TPCPathInfo buildPathArray:userSoundFolder, systemSoundFolder, nil];

	NSMutableArray *soundList = [NSMutableArray array];

	[soundList addObject:@"Beep"]; // For NSBeep()

	for (NSString *path in soundPathList) {
		NSArray *directoryContents = [RZFileManager() contentsOfDirectoryAtPath:path error:NULL];

		for (NSString *s in directoryContents) {
			if ([s contains:@"."]) {
				[soundList addObject:[s stringByDeletingPathExtension]];
			} else {
				[soundList addObject:s];
			}
		}
	}

	[soundList sortedArrayUsingSelector:@selector(compare:)];

	[soundList insertObject:[TDCPreferencesSoundWrapper localizedEmptySoundSelectionLabel] atIndex:0];
	[soundList insertObject:[NSMenuItem separatorItem] atIndex:1];

	return [soundList copy];
}

#pragma mark -
#pragma mark File Transfer Destination Folder Popup

- (BOOL)panel:(id)sender validateURL:(NSURL *)url error:(NSError *__autoreleasing *)outError
{
	/* The path is hardcoded because we run this check on all build schemes with means
	 the value of our ubiquitous container URL will not be available in all situations. */
	NSString *cloudPath = [[TPCPathInfo userHomeDirectoryPathOutsideSandbox] stringByAppendingPathComponent:@"/Library/Mobile Documents/"];

	if ([[url relativePath] hasPrefix:cloudPath]) {
		if (outError) {
			NSMutableDictionary *userInfo = [NSMutableDictionary dictionary];

			[userInfo setObject:url forKey:NSURLErrorKey];
			[userInfo setObject:TXTLS(@"TDCPreferencesController[1016][1]") forKey:NSLocalizedDescriptionKey];
			[userInfo setObject:TXTLS(@"TDCPreferencesController[1016][2]") forKey:NSLocalizedRecoverySuggestionErrorKey];

			*outError = [NSError errorWithDomain:NSCocoaErrorDomain code:27984 userInfo:userInfo];
		}

		return NO;
	} else {
		return YES;
	}
}

- (void)updateFileTransferDownloadDestinationFolder
{
	TDCFileTransferDialog *transferController = [menuController() fileTransferController];

	NSURL *path = [transferController downloadDestination];
	
	NSMenuItem *item = [[self fileTransferDownloadDestinationButton] itemAtIndex:0];
	
	if (path == nil) {
		[item setTitle:TXTLS(@"TDCPreferencesController[1004]")];
		
		[item setImage:nil];
	} else {
		NSImage *icon = [RZWorkspace() iconForFile:[path path]];
		
		[icon setSize:NSMakeSize(16, 16)];
		
		[item setImage:icon];
		[item setTitle:[path lastPathComponent]];
	}
}

- (void)onFileTransferDownloadDestinationFolderChanged:(id)sender
{
	TDCFileTransferDialog *transferController = [menuController() fileTransferController];

	if ([[self fileTransferDownloadDestinationButton] selectedTag] == 2) {
		NSOpenPanel *d = [NSOpenPanel openPanel];

		[d setDelegate:self];
		[d setCanChooseFiles:NO];
		[d setResolvesAliases:YES];
		[d setCanChooseDirectories:YES];
		[d setCanCreateDirectories:YES];
		[d setAllowsMultipleSelection:NO];
		
		[d setPrompt:BLS(1225)];
		
		[d beginSheetModalForWindow:self.window completionHandler:^(NSInteger returnCode) {
			[[self fileTransferDownloadDestinationButton] selectItemAtIndex:0];
			
			if (returnCode == NSModalResponseOK) {
				NSURL *pathURL = [d URLs][0];
				
				NSError *error = nil;
				
				NSData *bookmark = [pathURL bookmarkDataWithOptions:NSURLBookmarkCreationWithSecurityScope
									 includingResourceValuesForKeys:nil
													  relativeToURL:nil
															  error:&error];
				
				if (error) {
					LogToConsole(@"Error creating bookmark for URL (%@): %@", pathURL, [error localizedDescription]);
				} else {
					[transferController setDownloadDestinationFolder:bookmark];
				}
				
				[self updateFileTransferDownloadDestinationFolder];
			}
		}];
	}
	else if ([[self fileTransferDownloadDestinationButton] selectedTag] == 3)
	{
		[[self fileTransferDownloadDestinationButton] selectItemAtIndex:0];

		[transferController setDownloadDestinationFolder:nil];

		[self updateFileTransferDownloadDestinationFolder];
	}
}

#pragma mark -
#pragma mark Transcript Folder Popup

- (void)updateTranscriptFolder
{
	NSURL *path = [TPCPathInfo logFileFolderLocation];

	NSMenuItem *item = [[self transcriptFolderButton] itemAtIndex:0];

	if (path == nil) {
		[item setTitle:TXTLS(@"TDCPreferencesController[1003]")];
		
		[item setImage:nil];
	} else {
		NSImage *icon = [RZWorkspace() iconForFile:[path path]];

		[icon setSize:NSMakeSize(16, 16)];

		[item setImage:icon];
		[item setTitle:[path lastPathComponent]];
	}
}

- (void)onChangedTranscriptFolder:(id)sender
{
	if ([[self transcriptFolderButton] selectedTag] == 2) {
		NSOpenPanel *d = [NSOpenPanel openPanel];

		[d setDelegate:self];
		[d setCanChooseFiles:NO];
		[d setResolvesAliases:YES];
		[d setCanChooseDirectories:YES];
		[d setCanCreateDirectories:YES];
		[d setAllowsMultipleSelection:NO];
		
		[d setPrompt:BLS(1225)];

		[d beginSheetModalForWindow:self.window completionHandler:^(NSInteger returnCode) {
			[[self transcriptFolderButton] selectItemAtIndex:0];

			if (returnCode == NSModalResponseOK) {
				NSURL *pathURL = [d URLs][0];

				NSError *error = nil;

				NSData *bookmark = [pathURL bookmarkDataWithOptions:NSURLBookmarkCreationWithSecurityScope
									 includingResourceValuesForKeys:nil
													  relativeToURL:nil
															  error:&error];

				if (error) {
					LogToConsole(@"Error creating bookmark for URL (%@): %@", pathURL, [error localizedDescription]);
				} else {
					[TPCPathInfo setLogFileFolderLocation:bookmark];
				}

				[self updateTranscriptFolder];
			}
		}];
	}
	else if ([[self transcriptFolderButton] selectedTag] == 3)
	{
		[[self transcriptFolderButton] selectItemAtIndex:0];
		
		[TPCPathInfo setLogFileFolderLocation:nil];
		
		[self updateTranscriptFolder];
	}
}

#pragma mark -
#pragma mark Theme

- (void)updateThemeSelection
{
	[[self themeSelectionButton] removeAllItems];
	
	NSDictionary *allThemes = [themeController() dictionaryOfAllThemes];

	NSArray *allThemesKeys = [allThemes sortedDictionaryKeys];
	
	for (NSString *themeName in allThemesKeys) {
		NSString *themeType = allThemes[themeName];
		
		NSMenuItem *cell = [NSMenuItem menuItemWithTitle:themeName target:nil action:nil];
		
		[cell setUserInfo:themeType];
		
		[[[self themeSelectionButton] menu] addItem:cell];
	}

	[[self themeSelectionButton] selectItemWithTitle:[themeController() name]];
}

- (void)onChangedTheme:(id)sender
{
	NSMenuItem *item = [[self themeSelectionButton] selectedItem];

	TPCThemeControllerStorageLocation storageLocation = [TPCThemeController expectedStorageLocationOfThemeWithName:[item userInfo]];
	
	NSString *newThemeName = [TPCThemeController buildFilename:[item title] forStorageLocation:storageLocation];
	
	NSString *oldThemeName = [TPCPreferences themeName];
	
	if ([oldThemeName isEqual:newThemeName]) {
		return; // Do not reselect the same theme...
	}

	[TPCPreferences setThemeName:newThemeName];

	[self onChangedStyle:nil];

	// ---- //

	NSMutableString *sf = [NSMutableString string];

	if (NSObjectIsNotEmpty([themeSettings() nicknameFormat])) {
		[sf appendString:TXTLS(@"TDCPreferencesController[1015][1]")];
		[sf appendString:NSStringNewlinePlaceholder];
	}

	if (NSObjectIsNotEmpty([themeSettings() timestampFormat])) {
		[sf appendString:TXTLS(@"TDCPreferencesController[1015][2]")];
		[sf appendString:NSStringNewlinePlaceholder];
	}

	if ([themeSettings() channelViewFont]) {
		[sf appendString:TXTLS(@"TDCPreferencesController[1015][4]")];
		[sf appendString:NSStringNewlinePlaceholder];
	}

	if ([themeSettings() forceInvertSidebarColors]) {
		[sf appendString:TXTLS(@"TDCPreferencesController[1015][3]")];
		[sf appendString:NSStringNewlinePlaceholder];
	}

	NSString *tsf = [sf trim];

	NSObjectIsEmptyAssert(tsf);

	[TLOPopupPrompts sheetWindowWithWindow:[NSApp keyWindow]
									  body:TXTLS(@"TDCPreferencesController[1014][2]", [item title], tsf)
									 title:TXTLS(@"TDCPreferencesController[1014][1]")
							 defaultButton:BLS(1186)
						   alternateButton:nil
							   otherButton:nil
							suppressionKey:@"theme_override_info"
						   suppressionText:nil
						   completionBlock:nil];
}

- (void)onSelectNewFont:(id)sender
{
	NSFont *logfont = [TPCPreferences themeChannelViewFont];

	[RZFontManager() setSelectedFont:logfont isMultiple:NO];
	
	[RZFontManager() orderFrontFontPanel:self];
	
	[RZFontManager() setAction:@selector(changeItemFont:)];
}

- (void)changeItemFont:(NSFontManager *)sender
{
	NSFont *logfont = [TPCPreferences themeChannelViewFont];

	NSFont *newFont = [sender convertFont:logfont];

	[TPCPreferences setThemeChannelViewFontName:[newFont fontName]];
	[TPCPreferences setThemeChannelViewFontSize:[newFont pointSize]];

	[self setValue:  [newFont fontName]		forKey:@"themeChannelViewFontName"];
	[self setValue:@([newFont pointSize])	forKey:@"themeChannelViewFontSize"];

	[self onChangedStyle:nil];
}

- (void)onChangedTransparency:(id)sender
{
	[mainWindow() setAlphaValue:[TPCPreferences themeTransparency]];
}

#pragma mark -
#pragma mark Actions

#if TEXTUAL_BUILT_WITH_ADVANCED_ENCRYPTION == 1
- (void)offRecordMessagingPolicyChanged:(id)sender
{
	[sharedEncryptionManager() updatePolicy];
}
#endif

- (void)onHideMountainLionDeprecationWarning:(id)sender
{
	[[self mountainLionDeprecationWarningView] setHidden:YES];

	[RZUserDefaults() setBool:YES forKey:@"TDCPreferencesControllerDidShowMountainLionDeprecationWarning"];

	[self setMountainLionDeprecationWarningIsVisible:NO];

	[self firstPane:[self contentViewGeneral] selectedItem:_toolbarItemIndexGeneral];
}

- (void)onChangedHighlightType:(id)sender
{
    if ([TPCPreferences highlightMatchingMethod] == TXNicknameHighlightRegularExpressionMatchType) {
        [[self highlightNicknameButton] setHidden:YES];
    } else {
        [[self highlightNicknameButton] setHidden:NO];
    }
	
	[[self addExcludeKeywordButton] setEnabled:YES];

	[[self excludeKeywordsTable] setEnabled:YES];
}

- (void)editTableView:(NSTableView *)tableView
{
	NSInteger rowSelection = ([tableView numberOfRows] - 1);

	[tableView scrollRowToVisible:rowSelection];

	[tableView editColumn:0 row:rowSelection withEvent:nil select:YES];
}

- (void)onAddKeyword:(id)sender
{
	[[self matchKeywordsArrayController] add:nil];

	XRPerformBlockAsynchronouslyOnMainQueue(^{
		[self editTableView:[self keywordsTable]];
	});
}

- (void)onAddExcludeKeyword:(id)sender
{
	[[self excludeKeywordsArrayController] add:nil];

	XRPerformBlockAsynchronouslyOnMainQueue(^{
		[self editTableView:[self excludeKeywordsTable]];
	});
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

	[self onChangedUserListModeColor:sender];
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
	[TPCPreferences performReloadActionForActionType:TPCPreferencesKeyReloadInputHistoryScopeAction];
}

- (void)onChangedSidebarColorInversion:(id)sender
{
	[TPCPreferences performReloadActionForActionType:TPCPreferencesKeyReloadMainWindowAppearanceAction];
}

- (void)onChangedStyle:(id)sender
{
	[TPCPreferences performReloadActionForActionType:(TPCPreferencesKeyReloadStyleWithTableViewsAction | TPCPreferencesKeyReloadTextDirectionAction)];
}

- (void)onChangedMainWindowSegmentedController:(id)sender
{
	[TPCPreferences performReloadActionForActionType:TPCPreferencesKeyReloadTextFieldSegmentedControllerOriginAction];
}

- (void)onChangedUserListModeColor:(id)sender
{
	[TPCPreferences performReloadActionForActionType:(TPCPreferencesKeyReloadMemberListUserBadgesAction | TPCPreferencesKeyReloadMemberListAction)];
}

- (void)onChangedMainInputTextFieldFontSize:(id)sender
{
	[TPCPreferences performReloadActionForActionType:TPCPreferencesKeyReloadTextFieldFontSizeAction];
}

- (void)onFileTransferIPAddressDetectionMethodChanged:(id)sender
{
	TXFileTransferIPAddressDetectionMethod detectionMethod = [TPCPreferences fileTransferIPAddressDetectionMethod];
	
	[[self fileTransferManuallyEnteredIPAddressTextField] setEnabled:(detectionMethod == TXFileTransferIPAddressManualDetectionMethod)];
}

- (void)onChangedHighlightLogging:(id)sender
{
	[TPCPreferences performReloadActionForActionType:TPCPreferencesKeyReloadHighlightLoggingAction];
}

- (void)onChangedUserListModeSortOrder:(id)sender
{
	[TPCPreferences performReloadActionForActionType:TPCPreferencesKeyReloadMemberListSortOrderAction];
}

- (void)onChangedServerListUnreadBadgeColor:(id)sender
{
	[TPCPreferences performReloadActionForActionType:TPCPreferencesKeyReloadServerListUnreadBadgesAction];
}

- (void)onOpenPathToCloudFolder:(id)sender
{
#if TEXTUAL_BUILT_WITH_ICLOUD_SUPPORT == 1
	[TPCPathInfo openApplicationUbiquitousContainer];
#endif
}

- (void)onOpenPathToScripts:(id)sender
{
	[RZWorkspace() openFile:[TPCPathInfo applicationGroupContainerApplicationSupportPath]];
}

- (void)onManageiCloudButtonClicked:(id)sender
{
#if TEXTUAL_BUILT_WITH_ICLOUD_SUPPORT == 1
	[self firstPane:[self contentViewICloud] selectedItem:_toolbarItemIndexAdvanced];
#endif
}

- (void)onChangedCloudSyncingServices:(id)sender
{
#if TEXTUAL_BUILT_WITH_ICLOUD_SUPPORT == 1
	if ([TPCPreferences syncPreferencesToTheCloud] == NO) {
		[TLOPopupPrompts sheetWindowWithWindow:[NSApp keyWindow]
										  body:TXTLS(@"TDCPreferencesController[1000][2]")
										 title:TXTLS(@"TDCPreferencesController[1000][1]")
								 defaultButton:BLS(1186)
							   alternateButton:nil
								   otherButton:nil
								suppressionKey:nil
							   suppressionText:nil
							   completionBlock:nil];

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
	if ([TPCPreferences syncPreferencesToTheCloud]) {
		if ([TPCPreferences syncPreferencesToTheCloudLimitedToServers] == NO) {
			[RZUbiquitousKeyValueStore() synchronize];

			[sharedCloudManager() synchronizeFromCloud];
		}
	}
#endif
}

#if TEXTUAL_BUILT_WITH_ICLOUD_SUPPORT == 1
- (void)onPurgeOfCloudDataRequestedCallback:(TLOPopupPromptReturnType)returnCode withOriginalAlert:(NSAlert *)originalAlert
{
	if (returnCode == TLOPopupPromptReturnSecondaryType) {
		[sharedCloudManager() purgeDataStoredWithCloud];
	}
}

- (void)onPurgeOfCloudFilesRequestedCallback:(TLOPopupPromptReturnType)returnCode withOriginalAlert:(NSAlert *)originalAlert
{
	if (returnCode == TLOPopupPromptReturnSecondaryType) {
		NSString *path = [sharedCloudManager() ubiquitousContainerURLPath];
		
		/* Try to see if we even have a path... */
		if (path == nil) {
			LogToConsole(@"Cannot empty iCloud files at this time because iCloud is not available.");
			
			return;
		}
		
		/* Delete styles folder. */
		NSError *delError = nil;
		
		[RZFileManager() removeItemAtPath:[TPCPathInfo cloudCustomThemeFolderPath] error:&delError];
		
		if (delError) {
			LogToConsole(@"Delete Error: %@", [delError localizedDescription]);
		}
		
		/* Delete local caches. */
		[RZFileManager() removeItemAtPath:[TPCPathInfo cloudCustomThemeCachedFolderPath] error:&delError];
		
		if (delError) {
			LogToConsole(@"Delete Error: %@", [delError localizedDescription]);
		}
		
		// We do not call performValidationForKeyValues here because the
		// metadata query will do that for us once we change the direcoty by deleting.
	}
}
#endif

- (void)onPurgeOfCloudFilesRequested:(id)sender
{
#if TEXTUAL_BUILT_WITH_ICLOUD_SUPPORT == 1
	[TLOPopupPrompts sheetWindowWithWindow:[NSApp keyWindow]
									  body:TXTLS(@"TDCPreferencesController[1001][2]")
									 title:TXTLS(@"TDCPreferencesController[1001][1]")
							 defaultButton:BLS(1009)
						   alternateButton:BLS(1017)
							   otherButton:nil
							suppressionKey:nil
						   suppressionText:nil
						   completionBlock:^(TLOPopupPromptReturnType buttonClicked, NSAlert *originalAlert) {
							   [self onPurgeOfCloudFilesRequestedCallback:buttonClicked withOriginalAlert:originalAlert];
						   }];
#endif
}

- (void)onPurgeOfCloudDataRequested:(id)sender
{
#if TEXTUAL_BUILT_WITH_ICLOUD_SUPPORT == 1
	[TLOPopupPrompts sheetWindowWithWindow:[NSApp keyWindow]
									  body:TXTLS(@"TDCPreferencesController[1002][2]")
									 title:TXTLS(@"TDCPreferencesController[1002][1]")
							 defaultButton:BLS(1009)
						   alternateButton:BLS(1017)
							   otherButton:nil
							suppressionKey:nil
						   suppressionText:nil
						   completionBlock:^(TLOPopupPromptReturnType buttonClicked, NSAlert *originalAlert) {
							   [self onPurgeOfCloudDataRequestedCallback:buttonClicked withOriginalAlert:originalAlert];
						   }];
#endif
}

- (void)openPathToThemesCallback:(TLOPopupPromptReturnType)returnCode withOriginalAlert:(NSAlert *)originalAlert
{
	if (returnCode == TLOPopupPromptReturnPrimaryType) {
		NSString *oldpath = [themeController() actualPath];
		
		[RZWorkspace() openFile:oldpath];
	}

	if (returnCode == TLOPopupPromptReturnOtherType) {
		[[originalAlert window] orderOut:nil];

		BOOL copyingToCloud = NO;

#if TEXTUAL_BUILT_WITH_ICLOUD_SUPPORT == 1
		if ([sharedCloudManager() ubiquitousContainerIsAvailable]) {
			copyingToCloud = YES;
		}
#endif
		
		if (copyingToCloud) {
			[themeController() copyActiveStyleToDestinationLocation:TPCThemeControllerStorageCloudLocation reloadOnCopy:YES openNewPathOnCopy:YES];
		} else {
			[themeController() copyActiveStyleToDestinationLocation:TPCThemeControllerStorageCustomLocation reloadOnCopy:YES openNewPathOnCopy:YES];
		}
	}
}

- (void)onOpenPathToThemes:(id)sender
{
    if ([themeController() isBundledTheme]) {
		NSString *dialogMessage = nil;
		NSString *copyButton = nil;
		
#if TEXTUAL_BUILT_WITH_ICLOUD_SUPPORT == 1
		if ([sharedCloudManager() ubiquitousContainerIsAvailable]) {
			dialogMessage = @"TDCPreferencesController[1011]";
			copyButton = @"TDCPreferencesController[1009]";
		} else {
#endif

			dialogMessage = @"TDCPreferencesController[1010]";
			copyButton = @"TDCPreferencesController[1008]";

#if TEXTUAL_BUILT_WITH_ICLOUD_SUPPORT == 1
		}
#endif

		[TLOPopupPrompts sheetWindowWithWindow:[NSApp keyWindow]
										  body:TXTLS(dialogMessage)
										 title:TXTLS(@"TDCPreferencesController[1013]")
								 defaultButton:BLS(1017)
							   alternateButton:BLS(1009)
								   otherButton:TXTLS(copyButton)
								suppressionKey:nil
							   suppressionText:nil
							   completionBlock:^(TLOPopupPromptReturnType buttonClicked, NSAlert *originalAlert) {
								   [self openPathToThemesCallback:buttonClicked withOriginalAlert:originalAlert];
							   }];
		
		return;
    } else {
#if TEXTUAL_BUILT_WITH_ICLOUD_SUPPORT == 1
		BOOL containerAvlb = [sharedCloudManager() ubiquitousContainerIsAvailable];
		
		if (containerAvlb) {
			if ([themeController() storageLocation] == TPCThemeControllerStorageCustomLocation) {
				/* If the theme exists in app support folder, but cloud syncing is available,
				 then offer to sync it to the cloud. */

				[TLOPopupPrompts sheetWindowWithWindow:[NSApp keyWindow]
												  body:TXTLS(@"TDCPreferencesController[1012]")
												 title:TXTLS(@"TDCPreferencesController[1013]")
										 defaultButton:BLS(1017)
									   alternateButton:BLS(1009)
										   otherButton:TXTLS(@"TDCPreferencesController[1009]")
										suppressionKey:nil
									   suppressionText:nil
									   completionBlock:^(TLOPopupPromptReturnType buttonClicked, NSAlert *originalAlert) {
										   [self openPathToThemesCallback:buttonClicked withOriginalAlert:originalAlert];
									   }];

				return;
			}
		} else {
			if ([themeController() storageLocation] == TPCThemeControllerStorageCloudLocation) {
				/* If the current theme is stored in the cloud, but our container is not available, then
				 we have to tell the user we can't open the files right now. */

				[TLOPopupPrompts sheetWindowWithWindow:[NSApp keyWindow]
												  body:TXTLS(@"BasicLanguage[1102][2]")
												 title:TXTLS(@"BasicLanguage[1102][1]")
										 defaultButton:BLS(1186)
									   alternateButton:nil
										   otherButton:nil
										suppressionKey:nil
									   suppressionText:nil
									   completionBlock:nil];
				
				return;
			}
		}
#endif
		
		/* pathOfTheme... is called to ignore the cloud cache location. */
		NSString *filepath = [themeController() actualPath];
		
		[RZWorkspace() openFile:filepath];
    }
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

	[TPCPreferences cleanUpHighlightKeywords];

	[[self window] setAlphaValue:0.0];

	[self firstPane:[self contentViewGeneral] selectedItem:(-1)];

	[[self window] saveWindowStateForClass:[self class]];

	if ([[self delegate] respondsToSelector:@selector(preferencesDialogWillClose:)]) {
		[[self delegate] preferencesDialogWillClose:self];
	}
}

@end
