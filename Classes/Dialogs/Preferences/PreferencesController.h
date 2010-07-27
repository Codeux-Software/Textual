// Created by Satoshi Nakagawa <psychs AT limechat DOT net> <http://github.com/psychs/limechat>
// Modifications by Michael Morris <mikey AT codeux DOT com> <http://github.com/mikemac11/Textual>
// You can redistribute it and/or modify it under the new BSD license.

#import <Cocoa/Cocoa.h>

#define ThemeDidChangeNotification		 @"ThemeDidChangeNotification"
#define ThemeSelectedConsoleNotification	 @"ThemeSelectedConsoleNotification"
#define ThemeSelectedChannelNotification   @"ThemeSelectedChannelNotification"

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
	IBOutlet NSView *floodControlView;
	
	IBOutlet NSTableView* keywordsTable;
	IBOutlet NSTableView* excludeWordsTable;
	IBOutlet NSArrayController* keywordsArrayController;
	IBOutlet NSArrayController* excludeWordsArrayController;
	IBOutlet NSPopUpButton* transcriptFolderButton;
	IBOutlet NSPopUpButton* themeButton;
	IBOutlet NSTextField* scriptLocationField;
	IBOutlet NSPopUpButton* preferenceSelectButton;
	
	NSMutableArray* sounds;
	NSOpenPanel* transcriptFolderOpenPanel;
	NSFont* logFont;
}

@property (assign) id delegate;
@property (assign) NSString* fontDisplayName;
@property (assign) CGFloat fontPointSize;
@property (readonly) NSArray* availableSounds;
@property (readonly) NSMutableArray* sounds;
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
@property (retain) NSView *floodControlView;
@property (retain) NSTableView* keywordsTable;
@property (retain) NSTableView* excludeWordsTable;
@property (retain) NSArrayController* keywordsArrayController;
@property (retain) NSArrayController* excludeWordsArrayController;
@property (retain) NSPopUpButton* transcriptFolderButton;
@property (retain) NSPopUpButton* themeButton;
@property (retain) NSTextField* scriptLocationField;
@property (retain) NSPopUpButton* preferenceSelectButton;
@property (retain) NSOpenPanel* transcriptFolderOpenPanel;
@property (retain) NSFont* logFont;

- (void)show;

- (void)onAddKeyword:(id)sender;
- (void)onAddExcludeWord:(id)sender;

- (void)onTranscriptFolderChanged:(id)sender;
- (void)onChangedTheme:(id)sender;
- (void)onSelectFont:(id)sender;
- (void)onOverrideFontChanged:(id)sender;
- (void)onChangedTransparency:(id)sender;
- (void)onTimestampFormatChanged:(id)sender;
- (void)onHnagingTextChange:(id)sender;
- (void)onPrefPaneSelected:(id)sender;
- (void)onWindowsWantsClosure:(id)sender;
- (void)onOpenPathToThemes:(id)sender;
- (void)onLayoutChanged:(id)sender;
- (void)onTextDirectionChanged:(id)sender;

- (void)firstPane:(NSView *)view;
@end

@interface NSObject (PreferencesControllerDelegate)
- (void)preferencesDialogWillClose:(PreferencesController*)sender;
@end