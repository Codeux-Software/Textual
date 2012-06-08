// Created by Satoshi Nakagawa <psychs AT limechat DOT net> <http://github.com/psychs/limechat>
// Modifications by Codeux Software <support AT codeux DOT com> <https://github.com/codeux/Textual>
// You can redistribute it and/or modify it under the new BSD license.

#define TransparencyDidChangeNotification		@"TransparencyDidChangeNotification"
#define ThemeStyleDidChangeNotification			@"ThemeStyleDidChangeNotification"
#define InputHistoryGlobalSchemeNotification	@"InputHistoryGlobalSchemeNotification"

@interface PreferencesController : NSWindowController
{
	id __unsafe_unretained delegate;
	
	IRCWorld *__weak world;
	
	IBOutlet NSView *contentView;
	IBOutlet NSView *highlightView;
	IBOutlet NSView *interfaceView;
	IBOutlet NSView *alertsView;
	IBOutlet NSView *stylesView;
	IBOutlet NSView *logView;
	IBOutlet NSView *generalView;
	IBOutlet NSView *scriptsView;
	IBOutlet NSView *identityView;
	IBOutlet NSView *floodControlView;
	IBOutlet NSView *IRCopServicesView;
	IBOutlet NSView *channelManagementView;
    IBOutlet NSView *experimentalSettingsView;
	
    IBOutlet NSButton *highlightNicknameButton;
    IBOutlet NSButton *addExcludeWordButton;
	
	IBOutlet NSTableView *keywordsTable;
	IBOutlet NSTableView *excludeWordsTable;
	IBOutlet NSTableView *installedScriptsTable;
	
	IBOutlet NSArrayController *keywordsArrayController;
	IBOutlet NSArrayController *excludeWordsArrayController;
	
	IBOutlet NSPopUpButton *themeButton;
    IBOutlet NSPopUpButton *alertButton;
	IBOutlet NSPopUpButton *alertSoundButton;
	IBOutlet NSPopUpButton *transcriptFolderButton;

    IBOutlet NSButton *useGrowlButton;
    IBOutlet NSButton *disableAlertWhenAwayButton;
	
	IBOutlet NSTextField *scriptLocationField;
	
	IBOutlet NSMenu *installedScriptsMenu;
	IBOutlet NSToolbar *preferenceSelectToolbar;
	
	ScriptsWrapper *scriptsController;
	
	NSMutableArray *sounds;
}

@property (unsafe_unretained) id delegate;
@property (weak) IRCWorld *world;
@property (strong) ScriptsWrapper *scriptsController;
@property (weak, readonly) NSArray *availableSounds;
@property (weak, readonly) NSMutableArray *sounds;
@property (strong) NSView *contentView;
@property (strong) NSView *highlightView;
@property (strong) NSView *interfaceView;
@property (strong) NSView *alertsView;
@property (strong) NSView *stylesView;
@property (strong) NSView *logView;
@property (strong) NSView *generalView;
@property (strong) NSView *scriptsView;
@property (strong) NSView *identityView;
@property (strong) NSView *floodControlView;
@property (strong) NSView *IRCopServicesView;
@property (strong) NSView *channelManagementView;
@property (strong) NSView *experimentalSettingsView;
@property (strong) NSButton *highlightNicknameButton;
@property (strong) NSButton *addExcludeWordButton;
@property (strong) NSTableView *keywordsTable;
@property (strong) NSTableView *excludeWordsTable;
@property (strong) NSTableView *installedScriptsTable;
@property (strong) NSArrayController *keywordsArrayController;
@property (strong) NSArrayController *excludeWordsArrayController;
@property (strong) NSPopUpButton *transcriptFolderButton;
@property (strong) NSPopUpButton *themeButton;
@property (strong) NSPopUpButton *alertButton;
@property (strong) NSPopUpButton *alertSoundButton;
@property (strong) NSButton *useGrowlButton;
@property (strong) NSButton *disableAlertWhenAwayButton;
@property (strong) NSMenu *installedScriptsMenu;
@property (strong) NSTextField *scriptLocationField;
@property (strong) NSToolbar *preferenceSelectToolbar;

- (id)initWithWorldController:(IRCWorld *)word;

- (void)show;

- (void)onAddKeyword:(id)sender;
- (void)onAddExcludeWord:(id)sender;

- (void)onHighlightTypeChanged:(id)sender;
- (void)onSelectFont:(id)sender;

#ifdef _USES_APPLICATION_SCRIPTS_FOLDER
- (void)onDownloadExtraAddons:(id)sender;
#endif

- (void)onStyleChanged:(id)sender;
- (void)onChangedTheme:(id)sender;
- (void)onPrefPaneSelected:(id)sender;
- (void)onOpenPathToThemes:(id)sender;
- (void)onOpenPathToScripts:(id)sender;
- (void)onChangedTransparency:(id)sender;
- (void)onHighlightLoggingChanged:(id)sender;
- (void)onChangeAlert:(id)sender;
- (void)onUseGrowl:(id)sender;
- (void)onAlertWhileAway:(id)sender;
- (void)onChangeAlertSound:(id)sender;
- (void)onTranscriptFolderChanged:(id)sender;
@end

@interface NSObject (PreferencesControllerDelegate)
- (void)preferencesDialogWillClose:(PreferencesController *)sender;
@end
