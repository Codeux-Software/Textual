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

@property (retain) MainWindow* window;
@property (retain) ServerTreeView* tree;
@property (retain) NSBox* logBase;
@property (retain) MemberListView* memberList;
@property (retain) InputTextField* text;
@property (retain) ChatBox* chatBox;
@property (retain) NSScrollView* treeScrollView;
@property (retain) NSView* leftTreeBase;
@property (retain) NSView* rightTreeBase;
@property (retain) ThinSplitView* rootSplitter;
@property (retain) ThinSplitView* infoSplitter;
@property (retain) ThinSplitView* treeSplitter;
@property (retain) MenuController* menu;
@property (retain) NSMenuItem* serverMenu;
@property (retain) NSMenuItem* channelMenu;
@property (retain) NSMenu* memberMenu;
@property (retain) NSMenu* treeMenu;
@property (retain) NSMenu* logMenu;
@property (retain) NSMenu* urlMenu;
@property (retain) NSMenu* addrMenu;
@property (retain) NSMenu* chanMenu;
@property (retain) IRCExtras* extrac;
@property (retain) WelcomeSheet* WelcomeSheetDisplay;
@property (retain) GrowlController* growl;
@property (retain) DCCController* dcc;
@property (retain) FieldEditorTextView* fieldEditor;
@property (retain) IRCWorld* world;
@property (retain) ViewTheme* viewTheme;
@property (retain) InputHistory* inputHistory;
@property (retain) NickCompletinStatus* completionStatus;
@property BOOL terminating;
@property BOOL terminatingWithAuthority;
@end