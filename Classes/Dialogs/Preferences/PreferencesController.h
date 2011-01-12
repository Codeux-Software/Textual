// Created by Satoshi Nakagawa <psychs AT limechat DOT net> <http://github.com/psychs/limechat>
// Modifications by Codeux Software <support AT codeux DOT com> <https://github.com/codeux/Textual>
// You can redistribute it and/or modify it under the new BSD license.

#define TransparencyDidChangeNotification		@"TransparencyDidChangeNotification"
#define ThemeDidChangeNotification				@"ThemeDidChangeNotification"
#define ThemeStyleDidChangeNotification			@"ThemeStyleDidChangeNotification"
#define SparkleFeedURLChangeNotification		@"SparkleFeedURLChangeNotification"
#define ThemeSelectedConsoleNotification		@"ThemeSelectedConsoleNotification"
#define ThemeSelectedChannelNotification		@"ThemeSelectedChannelNotification"
#define InputHistoryGlobalSchemeNotification	@"InputHistoryGlobalSchemeNotification"

@interface PreferencesController : NSWindowController
{
	id delegate;
	
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
	IBOutlet NSToolbar *preferenceSelectToolbar;
	IBOutlet NSMenu *installedScriptsMenu;
	
	ScriptsWrapper *scriptsController;
	
	NSFont *logFont;
	IRCWorld *world;
	NSMutableArray *sounds;
	NSOpenPanel *transcriptFolderOpenPanel;
}

@property (nonatomic, assign) id delegate;
@property (nonatomic, assign) IRCWorld *world;
@property (nonatomic, retain) NSFont *logFont;
@property (nonatomic, retain) ScriptsWrapper *scriptsController;
@property (nonatomic, assign) NSString *fontDisplayName;
@property (nonatomic, assign) CGFloat fontPointSize;
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
@property (nonatomic, retain) NSOpenPanel *transcriptFolderOpenPanel;

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