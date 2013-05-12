/* ********************************************************************* 
       _____        _               _    ___ ____   ____
      |_   _|___  _| |_ _   _  __ _| |  |_ _|  _ \ / ___|
       | |/ _ \ \/ / __| | | |/ _` | |   | || |_) | |
       | |  __/>  <| |_| |_| | (_| | |   | ||  _ <| |___
       |_|\___/_/\_\\__|\__,_|\__,_|_|  |___|_| \_\\____|

 Copyright (c) 2010 — 2013 Codeux Software & respective contributors.
        Please see Contributors.pdf and Acknowledgements.pdf

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
@property (nonatomic, nweak) NSView *alertsView;
@property (nonatomic, nweak) NSView *channelManagementView;
@property (nonatomic, nweak) NSView *commandScopeSettingsView;
@property (nonatomic, nweak) NSView *contentView;
@property (nonatomic, nweak) NSView *experimentalSettingsView;
@property (nonatomic, nweak) NSView *floodControlView;
@property (nonatomic, nweak) NSView *generalView;
@property (nonatomic, nweak) NSView *highlightView;
@property (nonatomic, nweak) NSView *identityView;
@property (nonatomic, nweak) NSView *installedAddonsView;
@property (nonatomic, nweak) NSView *interfaceView;
@property (nonatomic, nweak) NSView *logLocationView;
@property (nonatomic, nweak) NSView *stylesView;
@property (nonatomic, nweak) NSView *IRCopServicesView;
@property (nonatomic, nweak) NSArrayController *excludeKeywordsArrayController;
@property (nonatomic, nweak) NSArrayController *matchKeywordsArrayController;
@property (nonatomic, nweak) NSButton *addExcludeKeywordButton;
@property (nonatomic, nweak) NSButton *alertSpeakEventButton;
@property (nonatomic, nweak) NSButton *alertDisableWhileAwayButton;
@property (nonatomic, nweak) NSButton *alertPushNotificationButton;
@property (nonatomic, nweak) NSButton *highlightNicknameButton;
@property (nonatomic, nweak) NSButton *setAsDefaultIRCClientButton;
@property (nonatomic, nweak) NSMenu *installedScriptsMenu;
@property (nonatomic, nweak) NSPopUpButton *alertSoundChoiceButton;
@property (nonatomic, nweak) NSPopUpButton *alertTypeChoiceButton;
@property (nonatomic, nweak) NSPopUpButton *themeSelectionButton;
@property (nonatomic, nweak) NSPopUpButton *transcriptFolderButton;
@property (nonatomic, nweak) NSTableView *excludeKeywordsTable;
@property (nonatomic, nweak) NSTableView *installedScriptsTable;
@property (nonatomic, nweak) NSTableView *keywordsTable;
@property (nonatomic, nweak) NSToolbar *preferenceSelectToolbar;
@property (nonatomic, nweak) NSToolbarItem *alertToolbarItem;
@property (nonatomic, strong) TDCPreferencesScriptWrapper *scriptsController;

- (void)show;

- (void)onPrefPaneSelected:(id)sender;

- (void)onAddKeyword:(id)sender;
- (void)onAddExcludeKeyword:(id)sender;

- (void)onDownloadExtraAddons:(id)sender;

- (void)setTextualAsDefaultIRCClient:(id)sender;

- (void)onChangedAlertSpoken:(id)sender;
- (void)onChangedAlertSound:(id)sender;
- (void)onChangedAlertDisableWhileAway:(id)sender;
- (void)onChangedAlertNotification:(id)sender;
- (void)onChangedAlertType:(id)sender;

- (void)onChangedHighlightLogging:(id)sender;
- (void)onChangedHighlightType:(id)sender;
- (void)onChangedInputHistoryScheme:(id)sender;
- (void)onChangedMainWindowSegmentedController:(id)sender;
- (void)onChangedSidebarColorInversion:(id)sender;
- (void)onChangedStyle:(id)sender;
- (void)onChangedTheme:(id)sender;
- (void)onChangedTranscriptFolder:(id)sender;
- (void)onChangedTransparency:(id)sender;
- (void)onChangedUserListModeColor:(id)sender;
- (void)onChangedUserListModeSortOrder:(id)sender;

- (void)onResetUserListModeColorsToDefaults:(id)sender;

- (void)onOpenPathToScripts:(id)sender;
- (void)onOpenPathToThemes:(id)sender;

- (void)onSelectNewFont:(id)sender;
@end

@interface NSObject (TDCPreferencesControllerDelegate)
- (void)preferencesDialogWillClose:(TDCPreferencesController *)sender;
@end
