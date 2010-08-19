// Created by Satoshi Nakagawa <psychs AT limechat DOT net> <http://github.com/psychs/limechat>
// Modifications by Michael Morris <mikey AT codeux DOT com> <http://github.com/mikemac11/Textual>
// You can redistribute it and/or modify it under the new BSD license.

#import <Cocoa/Cocoa.h>
#import "MainWindow.h"
#import "ServerTreeView.h"
#import "MemberListView.h"
#import "InputTextField.h"
#import "ChatBox.h"
#import "ThinSplitView.h"
#import "FieldEditorTextView.h"
#import "IRCWorld.h"
#import "IRC.h"
#import "InputHistory.h"
#import "MenuController.h"
#import "ViewTheme.h"
#import "NickCompletinStatus.h"
#import "DCCController.h"
#import "GrowlController.h"
#import "WelcomeSheet.h"
#import "IRCExtras.h"

@interface MasterController : NSObject
{
	IBOutlet MainWindow* window;
	IBOutlet ServerTreeView* tree;
	IBOutlet NSBox* logBase;
	IBOutlet MemberListView* memberList;
	IBOutlet InputTextField* text;
	IBOutlet ChatBox* chatBox;
	IBOutlet NSScrollView* treeScrollView;
	IBOutlet NSView* leftTreeBase;
	IBOutlet NSView* rightTreeBase;
	IBOutlet ThinSplitView* rootSplitter;
	IBOutlet ThinSplitView* infoSplitter;
	IBOutlet ThinSplitView* treeSplitter;
	IBOutlet MenuController* menu;
	IBOutlet NSMenuItem* formattingMenu;
	IBOutlet NSMenuItem* serverMenu;
	IBOutlet NSMenuItem* channelMenu;
	IBOutlet NSMenu* memberMenu;
	IBOutlet NSMenu* treeMenu;
	IBOutlet NSMenu* logMenu;
	IBOutlet NSMenu* urlMenu;
	IBOutlet NSMenu* addrMenu;
	IBOutlet NSMenu* chanMenu;
	
	IRCExtras* extrac;
	WelcomeSheet* WelcomeSheetDisplay;
	GrowlController* growl;
	DCCController* dcc;
	FieldEditorTextView* fieldEditor;
	IRCWorld* world;
	ViewTheme* viewTheme;
	InputHistory* inputHistory;
	NickCompletinStatus* completionStatus;
	
	BOOL terminating;
	BOOL terminatingWithAuthority;
}

@property (nonatomic, retain) MainWindow* window;
@property (nonatomic, retain) ServerTreeView* tree;
@property (nonatomic, retain) NSBox* logBase;
@property (nonatomic, retain) MemberListView* memberList;
@property (nonatomic, retain) InputTextField* text;
@property (nonatomic, retain) ChatBox* chatBox;
@property (nonatomic, retain) NSScrollView* treeScrollView;
@property (nonatomic, retain) NSView* leftTreeBase;
@property (nonatomic, retain) NSView* rightTreeBase;
@property (nonatomic, retain) ThinSplitView* rootSplitter;
@property (nonatomic, retain) ThinSplitView* infoSplitter;
@property (nonatomic, retain) ThinSplitView* treeSplitter;
@property (nonatomic, retain) MenuController* menu;
@property (nonatomic, retain) NSMenuItem* serverMenu;
@property (nonatomic, retain) NSMenuItem* channelMenu;
@property (nonatomic, retain) NSMenu* memberMenu;
@property (nonatomic, retain) NSMenu* treeMenu;
@property (nonatomic, retain) NSMenu* logMenu;
@property (nonatomic, retain) NSMenu* urlMenu;
@property (nonatomic, retain) NSMenu* addrMenu;
@property (nonatomic, retain) NSMenu* chanMenu;
@property (nonatomic, retain) NSMenuItem* formattingMenu;
@property (nonatomic, retain) IRCExtras* extrac;
@property (nonatomic, retain) WelcomeSheet* WelcomeSheetDisplay;
@property (nonatomic, retain) GrowlController* growl;
@property (nonatomic, retain) DCCController* dcc;
@property (nonatomic, retain) FieldEditorTextView* fieldEditor;
@property (nonatomic, retain) IRCWorld* world;
@property (nonatomic, retain) ViewTheme* viewTheme;
@property (nonatomic, retain) InputHistory* inputHistory;
@property (nonatomic, retain) NickCompletinStatus* completionStatus;
@property (nonatomic) BOOL terminating;
@property (nonatomic) BOOL terminatingWithAuthority;

- (IBAction)insertColorCharIntoTextBox:(id)sender;
- (IBAction)insertBoldCharIntoTextBox:(id)sender;
- (IBAction)insertItalicCharIntoTextBox:(id)sender;
- (IBAction)insertUnderlineCharIntoTextBox:(id)sender;

- (void)textEntered:(id)sender;

- (void)selectPreviousChannel:(NSEvent*)e;
- (void)selectNextChannel:(NSEvent*)e;
- (void)selectPreviousUnreadChannel:(NSEvent*)e;
- (void)selectNextUnreadChannel:(NSEvent*)e;
- (void)selectPreviousActiveChannel:(NSEvent*)e;
- (void)selectNextActiveChannel:(NSEvent*)e;
- (void)selectNextServer:(NSEvent*)e;
- (void)selectPreviousActiveServer:(NSEvent*)e;
- (void)selectNextActiveServer:(NSEvent*)e;
- (void)selectPreviousSelection:(NSEvent*)e;
- (void)selectPreviousServer:(NSEvent*)e;
- (void)selectNextSelection:(NSEvent*)e;
@end