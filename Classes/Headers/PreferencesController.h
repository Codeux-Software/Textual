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

@property (nonatomic, unsafe_unretained) id delegate;
@property (nonatomic, weak) IRCWorld *world;
@property (nonatomic, strong) ScriptsWrapper *scriptsController;
@property (weak, nonatomic, readonly) NSArray *availableSounds;
@property (weak, nonatomic, readonly) NSMutableArray *sounds;
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
