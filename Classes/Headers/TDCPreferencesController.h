// Created by Satoshi Nakagawa <psychs AT limechat DOT net> <http://github.com/psychs/limechat>
// Modifications by Codeux Software <support AT codeux DOT com> <https://github.com/codeux/Textual>
// You can redistribute it and/or modify it under the new BSD license.
// Converted to ARC Support on June 09, 2012

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
@property (nonatomic, strong) NSButton *toggleDarkenedThemeCheck;
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
