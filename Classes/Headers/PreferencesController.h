// Created by Satoshi Nakagawa <psychs AT limechat DOT net> <http://github.com/psychs/limechat>
// Modifications by Codeux Software <support AT codeux DOT com> <https://github.com/codeux/Textual>
// You can redistribute it and/or modify it under the new BSD license.

#define TransparencyDidChangeNotification		@"TransparencyDidChangeNotification"
#define ThemeDidChangeNotification				@"ThemeDidChangeNotification"
#define ThemeStyleDidChangeNotification			@"ThemeStyleDidChangeNotification"
#define ThemeSelectedConsoleNotification		@"ThemeSelectedConsoleNotification"
#define ThemeSelectedChannelNotification		@"ThemeSelectedChannelNotification"
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
	
	NSFont *logFont;
	NSMutableArray *sounds;
	
	NSOpenPanel *transcriptFolderOpenPanel;
}

@property (assign) id delegate;
@property (assign) IRCWorld *world;
@property (retain) NSFont *logFont;
@property (retain) ScriptsWrapper *scriptsController;
@property (assign) NSString *fontDisplayName;
@property (assign) CGFloat fontPointSize;
@property (readonly) NSArray *availableSounds;
@property (readonly) NSMutableArray *sounds;
@property (retain) NSView *contentView;
@property (retain) NSView *highlightView;
@property (retain) NSView *interfaceView;
@property (retain) NSView *alertsView;
@property (retain) NSView *stylesView;
@property (retain) NSView *transfersView;
@property (retain) NSView *logView;
@property (retain) NSView *generalView;
@property (retain) NSView *scriptsView;
@property (retain) NSView *identityView;
@property (retain) NSView *updatesView;
@property (retain) NSView *floodControlView;
@property (retain) NSView *IRCopServicesView;
@property (retain) NSView *channelManagementView;
@property (retain) NSTableView *keywordsTable;
@property (retain) NSTableView *excludeWordsTable;
@property (retain) NSTableView *installedScriptsTable;
@property (retain) NSArrayController *keywordsArrayController;
@property (retain) NSArrayController *excludeWordsArrayController;
@property (retain) NSPopUpButton *transcriptFolderButton;
@property (retain) NSPopUpButton *themeButton;
@property (retain) NSMenu *installedScriptsMenu;
@property (retain) NSTextField *scriptLocationField;
@property (retain) NSToolbar *preferenceSelectToolbar;
@property (retain) NSOpenPanel *transcriptFolderOpenPanel;

- (id)initWithWorldController:(IRCWorld *)word;

- (void)show;

- (void)onAddKeyword:(id)sender;
- (void)onAddExcludeWord:(id)sender;

- (void)onTranscriptFolderChanged:(id)sender;
- (void)onChangedTheme:(id)sender;
- (void)onStyleChanged:(id)sender;
- (void)onSelectFont:(id)sender;
- (void)onOverrideFontChanged:(id)sender;
- (void)onChangedTransparency:(id)sender;
- (void)onTimestampFormatChanged:(id)sender;
- (void)onHnagingTextChange:(id)sender;
- (void)onPrefPaneSelected:(id)sender;
- (void)onWindowsWantsClosure:(id)sender;
- (void)onOpenPathToThemes:(id)sender;
- (void)onOpenPathToScripts:(id)sender;
- (void)onLayoutChanged:(id)sender;
- (void)onTextDirectionChanged:(id)sender;
- (void)onNicknameColorsDisabled:(id)sender;
- (void)onInputHistorySchemeChanged:(id)sender;
@end

@interface NSObject (PreferencesControllerDelegate)
- (void)preferencesDialogWillClose:(PreferencesController *)sender;
@end