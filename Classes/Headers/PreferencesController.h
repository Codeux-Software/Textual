// Created by Satoshi Nakagawa <psychs AT limechat DOT net> <http://github.com/psychs/limechat>
// Modifications by Codeux Software <support AT codeux DOT com> <https://github.com/codeux/Textual>
// You can redistribute it and/or modify it under the new BSD license.

#define TransparencyDidChangeNotification		@"TransparencyDidChangeNotification"
#define ThemeStyleDidChangeNotification			@"ThemeStyleDidChangeNotification"
#define InputHistoryGlobalSchemeNotification	@"InputHistoryGlobalSchemeNotification"

@interface PreferencesController : NSWindowController
{
	id delegate;
	
	IRCWorld *world;
	
	IBOutlet NSView *contentView;
	IBOutlet NSView *highlightView;
	IBOutlet NSView *interfaceView;
	IBOutlet NSView *alertsView;
	IBOutlet NSView *stylesView;
	IBOutlet NSView *transfersView;
	IBOutlet NSView *logView;
	IBOutlet NSView *generalView;
	IBOutlet NSView *scriptsView;
	IBOutlet NSView *identityView;
	IBOutlet NSView *updatesView;
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
	
	IBOutlet NSPopUpButton *transcriptFolderButton;
	IBOutlet NSPopUpButton *themeButton;
	
	IBOutlet NSTextField *scriptLocationField;
	
	IBOutlet NSMenu *installedScriptsMenu;
	IBOutlet NSToolbar *preferenceSelectToolbar;
	
	ScriptsWrapper *scriptsController;
	
	NSMutableArray *sounds;
}

@property (nonatomic, assign) id delegate;
@property (nonatomic, assign) IRCWorld *world;
@property (nonatomic, retain) ScriptsWrapper *scriptsController;
@property (nonatomic, readonly) NSArray *availableSounds;
@property (nonatomic, readonly) NSMutableArray *sounds;
@property (nonatomic, retain) NSView *contentView;
@property (nonatomic, retain) NSView *highlightView;
@property (nonatomic, retain) NSView *interfaceView;
@property (nonatomic, retain) NSView *alertsView;
@property (nonatomic, retain) NSView *stylesView;
@property (nonatomic, retain) NSView *transfersView;
@property (nonatomic, retain) NSView *logView;
@property (nonatomic, retain) NSView *generalView;
@property (nonatomic, retain) NSView *scriptsView;
@property (nonatomic, retain) NSView *identityView;
@property (nonatomic, retain) NSView *updatesView;
@property (nonatomic, retain) NSView *floodControlView;
@property (nonatomic, retain) NSView *IRCopServicesView;
@property (nonatomic, retain) NSView *channelManagementView;
@property (nonatomic, retain) NSView *experimentalSettingsView;
@property (nonatomic, retain) NSButton *highlightNicknameButton;
@property (nonatomic, retain) NSButton *addExcludeWordButton;
@property (nonatomic, retain) NSTableView *keywordsTable;
@property (nonatomic, retain) NSTableView *excludeWordsTable;
@property (nonatomic, retain) NSTableView *installedScriptsTable;
@property (nonatomic, retain) NSArrayController *keywordsArrayController;
@property (nonatomic, retain) NSArrayController *excludeWordsArrayController;
@property (nonatomic, retain) NSPopUpButton *transcriptFolderButton;
@property (nonatomic, retain) NSPopUpButton *themeButton;
@property (nonatomic, retain) NSMenu *installedScriptsMenu;
@property (nonatomic, retain) NSTextField *scriptLocationField;
@property (nonatomic, retain) NSToolbar *preferenceSelectToolbar;

- (id)initWithWorldController:(IRCWorld *)word;

- (void)show;

- (void)onAddKeyword:(id)sender;
- (void)onAddExcludeWord:(id)sender;

- (void)onHighlightTypeChanged:(id)sender;
- (void)onSelectFont:(id)sender;
- (void)onStyleChanged:(id)sender;
- (void)onChangedTheme:(id)sender;
- (void)onPrefPaneSelected:(id)sender;
- (void)onOpenPathToThemes:(id)sender;
- (void)onOpenPathToScripts:(id)sender;
- (void)onChangedTransparency:(id)sender;
- (void)onTranscriptFolderChanged:(id)sender;
- (void)onHighlightLoggingChanged:(id)sender;
@end

@interface NSObject (PreferencesControllerDelegate)
- (void)preferencesDialogWillClose:(PreferencesController *)sender;
@end