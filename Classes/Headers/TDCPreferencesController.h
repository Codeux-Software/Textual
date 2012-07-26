/* ********************************************************************* 
       _____        _               _    ___ ____   ____
      |_   _|___  _| |_ _   _  __ _| |  |_ _|  _ \ / ___|
       | |/ _ \ \/ / __| | | |/ _` | |   | || |_) | |
       | |  __/>  <| |_| |_| | (_| | |   | ||  _ <| |___
       |_|\___/_/\_\\__|\__,_|\__,_|_|  |___|_| \_\\____|

 Copyright (c) 2010 — 2012 Codeux Software & respective contributors.
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

#define TXThemePreferenceChangedNotification				@"TXThemePreferenceChangedNotification"
#define TXTransparencyPreferenceChangedNotification			@"TXTransparencyPreferenceChangedNotification"
#define TXInputHistorySchemePreferenceChangedNotification	@"TXInputHistorySchemePreferenceChangedNotification"

@interface TDCPreferencesController : NSWindowController
@property (nonatomic, weak) IRCWorld *world;
@property (nonatomic, unsafe_unretained) id delegate;
@property (nonatomic, weak) NSArray *availableSounds;
@property (nonatomic, weak) NSMutableArray *sounds;
@property (nonatomic, strong) NSView *contentView;
@property (nonatomic, strong) NSView *highlightView;
@property (nonatomic, strong) NSView *interfaceView;
@property (nonatomic, strong) NSView *alertsView;
@property (nonatomic, strong) NSView *stylesView;
@property (nonatomic, strong) NSView *logView;
@property (nonatomic, strong) NSView *generalView;
@property (nonatomic, strong) NSView *scriptsView;
@property (nonatomic, strong) NSView *identityView;
@property (nonatomic, strong) NSView *floodControlView;
@property (nonatomic, strong) NSView *IRCopServicesView;
@property (nonatomic, strong) NSView *channelManagementView;
@property (nonatomic, strong) NSView *experimentalSettingsView;
@property (nonatomic, strong) NSButton *highlightNicknameButton;
@property (nonatomic, strong) NSButton *addExcludeWordButton;
@property (nonatomic, strong) NSTableView *keywordsTable;
@property (nonatomic, strong) NSTableView *excludeWordsTable;
@property (nonatomic, strong) NSTableView *installedScriptsTable;
@property (nonatomic, strong) NSArrayController *keywordsArrayController;
@property (nonatomic, strong) NSArrayController *excludeWordsArrayController;
@property (nonatomic, strong) NSPopUpButton *transcriptFolderButton;
@property (nonatomic, strong) NSPopUpButton *themeButton;
@property (nonatomic, strong) NSPopUpButton *alertButton;
@property (nonatomic, strong) NSPopUpButton *alertSoundButton;
@property (nonatomic, strong) NSButton *useGrowlButton;
@property (nonatomic, strong) NSButton *disableAlertWhenAwayButton;
@property (nonatomic, strong) NSMenu *installedScriptsMenu;
@property (nonatomic, strong) NSTextField *scriptLocationField;
@property (nonatomic, strong) NSToolbar *preferenceSelectToolbar;
@property (nonatomic, strong) TDCPreferencesScriptWrapper *scriptsController;

- (id)initWithWorldController:(IRCWorld *)word;

- (void)show;

- (void)onAddKeyword:(id)sender;
- (void)onAddExcludeWord:(id)sender;

- (void)onHighlightTypeChanged:(id)sender;
- (void)onSelectFont:(id)sender;

#ifdef TXUserScriptsFolderAvailable
- (void)onDownloadExtraAddons:(id)sender;
#endif

- (void)onUseGrowl:(id)sender;
- (void)onStyleChanged:(id)sender;
- (void)onChangedTheme:(id)sender;
- (void)onChangeAlert:(id)sender;
- (void)onAlertWhileAway:(id)sender;
- (void)onChangeAlertSound:(id)sender;
- (void)onTranscriptFolderChanged:(id)sender;
- (void)onHighlightLoggingChanged:(id)sender;
- (void)onChangedTransparency:(id)sender;
- (void)onPrefPaneSelected:(id)sender;
- (void)onOpenPathToThemes:(id)sender;
- (void)onOpenPathToScripts:(id)sender;
@end

@interface NSObject (TXPreferencesControllerDelegate)
- (void)preferencesDialogWillClose:(TDCPreferencesController *)sender;
@end
