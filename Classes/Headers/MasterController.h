// Created by Satoshi Nakagawa <psychs AT limechat DOT net> <http://github.com/psychs/limechat>
// Modifications by Codeux Software <support AT codeux DOT com> <https://github.com/codeux/Textual>
// You can redistribute it and/or modify it under the new BSD license.

@interface MasterController : NSObject
{
	IBOutlet ChatBox *chatBox;
	IBOutlet MainWindow *window;
	IBOutlet MenuController *menu;
	IBOutlet InputTextField *text;
	IBOutlet ServerTreeView *tree;
	IBOutlet MemberListView *memberList;
	
	IBOutlet NSBox *logBase;
	
	IBOutlet NSScrollView *treeScrollView;
	
	IBOutlet NSView *leftTreeBase;
	IBOutlet NSView *rightTreeBase;
	
	IBOutlet ThinSplitView *rootSplitter;
	IBOutlet ThinSplitView *infoSplitter;
	IBOutlet ThinSplitView *treeSplitter;
	
	IBOutlet NSMenuItem *serverMenu;
	IBOutlet NSMenuItem *channelMenu;
	
	IBOutlet NSMenu *logMenu;
	IBOutlet NSMenu *urlMenu;
	IBOutlet NSMenu *treeMenu;
	IBOutlet NSMenu *addrMenu;
	IBOutlet NSMenu *chanMenu;
	IBOutlet NSMenu *memberMenu;
	
	IBOutlet IRCTextFormatterMenu *formattingMenu;
	
	IRCWorld *world;
	IRCExtras *extrac;
	ViewTheme *viewTheme;
	GrowlController *growl;
	InputHistory *inputHistory;
	FieldEditorTextView *fieldEditor;
	WelcomeSheet *WelcomeSheetDisplay;
	NickCompletionStatus *completionStatus;
	
	BOOL ghostMode;
	BOOL terminating;
}

@property (assign) BOOL ghostMode;
@property (assign) BOOL terminating;
@property (retain) ChatBox *chatBox;
@property (retain) MainWindow *window;
@property (retain) MenuController *menu;
@property (retain) InputTextField *text;
@property (retain) ServerTreeView *tree;
@property (retain) MemberListView *memberList;
@property (retain) NSBox *logBase;
@property (retain) NSScrollView *treeScrollView;
@property (retain) NSView *leftTreeBase;
@property (retain) NSView *rightTreeBase;
@property (retain) ThinSplitView *rootSplitter;
@property (retain) ThinSplitView *infoSplitter;
@property (retain) ThinSplitView *treeSplitter;
@property (retain) NSMenuItem *serverMenu;
@property (retain) NSMenuItem *channelMenu;
@property (retain) NSMenu *logMenu;
@property (retain) NSMenu *urlMenu;
@property (retain) NSMenu *treeMenu;
@property (retain) NSMenu *addrMenu;
@property (retain) NSMenu *chanMenu;
@property (retain) NSMenu *memberMenu;
@property (retain) IRCWorld *world;
@property (retain) IRCExtras *extrac;
@property (retain) ViewTheme *viewTheme;
@property (retain) GrowlController *growl;
@property (retain) InputHistory *inputHistory;
@property (retain) FieldEditorTextView *fieldEditor;
@property (retain) WelcomeSheet *WelcomeSheetDisplay;
@property (retain) IRCTextFormatterMenu *formattingMenu;
@property (retain) NickCompletionStatus *completionStatus;

- (void)loadWindowState;
- (void)saveWindowState;

- (void)textEntered:(id)sender;

- (void)selectNextServer:(NSEvent *)e;
- (void)selectNextChannel:(NSEvent *)e;
- (void)selectNextSelection:(NSEvent *)e;
- (void)selectPreviousServer:(NSEvent *)e;
- (void)selectPreviousChannel:(NSEvent *)e;
- (void)selectNextActiveServer:(NSEvent *)e;
- (void)selectNextUnreadChannel:(NSEvent *)e;
- (void)selectNextActiveChannel:(NSEvent *)e;
- (void)selectPreviousSelection:(NSEvent *)e;
- (void)selectPreviousActiveServer:(NSEvent *)e;
- (void)selectPreviousUnreadChannel:(NSEvent *)e;
- (void)selectPreviousActiveChannel:(NSEvent *)e;

@end