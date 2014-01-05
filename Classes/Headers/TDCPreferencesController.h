/* *********************************************************************
       _____        _               _    ___ ____   ____
      |_   _|___  _| |_ _   _  __ _| |  |_ _|  _ \ / ___|
       | |/ _ \ \/ / __| | | |/ _` | |   | || |_) | |
       | |  __/>  <| |_| |_| | (_| | |   | ||  _ <| |___
       |_|\___/_/\_\\__|\__,_|\__,_|_|  |___|_| \_\\____|

 Copyright (c) 2008 - 2010 Satoshi Nakagawa <psychs AT limechat DOT net>
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

@interface TDCPreferencesController : NSWindowController
@property (nonatomic, uweak) id delegate;
@property (nonatomic, strong) NSMutableArray *alertSounds;
@property (nonatomic, nweak) IBOutlet NSArrayController *excludeKeywordsArrayController;
@property (nonatomic, nweak) IBOutlet NSArrayController *matchKeywordsArrayController;
@property (nonatomic, nweak) IBOutlet NSButton *addExcludeKeywordButton;
@property (nonatomic, nweak) IBOutlet NSButton *alertBounceDockIconButton;
@property (nonatomic, nweak) IBOutlet NSButton *alertDisableWhileAwayButton;
@property (nonatomic, nweak) IBOutlet NSButton *alertPushNotificationButton;
@property (nonatomic, nweak) IBOutlet NSButton *alertSpeakEventButton;
@property (nonatomic, nweak) IBOutlet NSButton *highlightNicknameButton;
@property (nonatomic, nweak) IBOutlet NSButton *setAsDefaultIRCClientButton;
@property (nonatomic, nweak) IBOutlet NSButton *syncPreferencesToTheCloudButton;
@property (nonatomic, nweak) IBOutlet NSMenu *installedScriptsMenu;
@property (nonatomic, nweak) IBOutlet NSPopUpButton *alertSoundChoiceButton;
@property (nonatomic, nweak) IBOutlet NSPopUpButton *alertTypeChoiceButton;
@property (nonatomic, nweak) IBOutlet NSPopUpButton *themeSelectionButton;
@property (nonatomic, nweak) IBOutlet NSPopUpButton *transcriptFolderButton;
@property (nonatomic, nweak) IBOutlet NSPopUpButton *fileTransferDownloadDestinationButton;
@property (nonatomic, nweak) IBOutlet NSTableView *excludeKeywordsTable;
@property (nonatomic, nweak) IBOutlet NSTableView *installedScriptsTable;
@property (nonatomic, nweak) IBOutlet NSTableView *keywordsTable;
@property (nonatomic, nweak) IBOutlet NSTextField *alertNotificationDestinationTextField;
@property (nonatomic, nweak) IBOutlet NSTextField *fileTransferManuallyEnteredIPAddressField;
@property (nonatomic, nweak) IBOutlet NSToolbar *preferenceSelectToolbar;
@property (nonatomic, nweak) IBOutlet NSToolbarItem *alertToolbarItem;
@property (nonatomic, nweak) IBOutlet NSView *contentView;
@property (nonatomic, strong) IBOutlet NSView *IRCopServicesView;
@property (nonatomic, strong) IBOutlet NSView *alertsView;
@property (nonatomic, strong) IBOutlet NSView *channelManagementView;
@property (nonatomic, strong) IBOutlet NSView *commandScopeSettingsView;
@property (nonatomic, strong) IBOutlet NSView *experimentalSettingsView;
@property (nonatomic, strong) IBOutlet NSView *fileTransferView;
@property (nonatomic, strong) IBOutlet NSView *floodControlView;
@property (nonatomic, strong) IBOutlet NSView *generalView;
@property (nonatomic, strong) IBOutlet NSView *highlightView;
@property (nonatomic, strong) IBOutlet NSView *iCloudSyncView;
@property (nonatomic, strong) IBOutlet NSView *identityView;
@property (nonatomic, strong) IBOutlet NSView *installedAddonsView;
@property (nonatomic, strong) IBOutlet NSView *interfaceView;
@property (nonatomic, strong) IBOutlet NSView *incomingDataView;
@property (nonatomic, strong) IBOutlet NSView *logLocationView;
@property (nonatomic, strong) IBOutlet NSView *stylesView;
@property (nonatomic, strong) TDCPreferencesScriptWrapper *scriptsController;

- (void)show;

- (IBAction)onPrefPaneSelected:(id)sender;

- (IBAction)onAddKeyword:(id)sender;
- (IBAction)onAddExcludeKeyword:(id)sender;

- (IBAction)setTextualAsDefaultIRCClient:(id)sender;

- (IBAction)onChangedAlertSpoken:(id)sender;
- (IBAction)onChangedAlertSound:(id)sender;
- (IBAction)onChangedAlertDisableWhileAway:(id)sender;
- (IBAction)onChangedAlertBounceDockIcon:(id)sender;
- (IBAction)onChangedAlertNotification:(id)sender;
- (IBAction)onChangedAlertType:(id)sender;

- (IBAction)onChangedCloudSyncingServices:(id)sender;
- (IBAction)onChangedCloudSyncingServicesServersOnly:(id)sender;

- (IBAction)onOpenPathToCloudFolder:(id)sender;

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

- (IBAction)onChangedMainInputTextFieldFontSize:(id)sender;

- (IBAction)onFileTransferIPAddressDetectionMethodChanged:(id)sender;
- (IBAction)onFileTransferDownloadDestinationFolderChanged:(id)sender;

- (IBAction)onResetUserListModeColorsToDefaults:(id)sender;

- (IBAction)onOpenPathToScripts:(id)sender;
- (IBAction)onOpenPathToThemes:(id)sender;

- (IBAction)onPurgeOfCloudDataRequested:(id)sender;
- (IBAction)onPurgeOfCloudFilesRequested:(id)sender;

- (IBAction)onSelectNewFont:(id)sender;
@end

@interface NSObject (TDCPreferencesControllerDelegate)
- (void)preferencesDialogWillClose:(TDCPreferencesController *)sender;
@end
