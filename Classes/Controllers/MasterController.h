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
	IBOutlet NSMenuItem *formattingMenu;
	
	IBOutlet NSMenu *logMenu;
	IBOutlet NSMenu *urlMenu;
	IBOutlet NSMenu *treeMenu;
	IBOutlet NSMenu *addrMenu;
	IBOutlet NSMenu *chanMenu;
	IBOutlet NSMenu *memberMenu;
	
	IRCExtras *extrac;
	WelcomeSheet *WelcomeSheetDisplay;
	GrowlController *growl;
	FieldEditorTextView *fieldEditor;
	IRCWorld *world;
	ViewTheme *viewTheme;
	InputHistory *inputHistory;
	NickCompletionStatus *completionStatus;
	
	BOOL terminating;
}

@property (nonatomic, retain) MainWindow *window;
@property (nonatomic, retain) ServerTreeView *tree;
@property (nonatomic, retain) NSBox *logBase;
@property (nonatomic, retain) MemberListView *memberList;
@property (nonatomic, retain) InputTextField *text;
@property (nonatomic, retain) ChatBox *chatBox;
@property (nonatomic, retain) NSScrollView *treeScrollView;
@property (nonatomic, retain) NSView *leftTreeBase;
@property (nonatomic, retain) NSView *rightTreeBase;
@property (nonatomic, retain) ThinSplitView *rootSplitter;
@property (nonatomic, retain) ThinSplitView *infoSplitter;
@property (nonatomic, retain) ThinSplitView *treeSplitter;
@property (nonatomic, retain) MenuController *menu;
@property (nonatomic, retain) NSMenuItem *serverMenu;
@property (nonatomic, retain) NSMenuItem *channelMenu;
@property (nonatomic, retain) NSMenu *memberMenu;
@property (nonatomic, retain) NSMenu *treeMenu;
@property (nonatomic, retain) NSMenu *logMenu;
@property (nonatomic, retain) NSMenu *urlMenu;
@property (nonatomic, retain) NSMenu *addrMenu;
@property (nonatomic, retain) NSMenu *chanMenu;
@property (nonatomic, retain) NSMenuItem *formattingMenu;
@property (nonatomic, retain) IRCExtras *extrac;
@property (nonatomic, retain) WelcomeSheet *WelcomeSheetDisplay;
@property (nonatomic, retain) GrowlController *growl;
@property (nonatomic, retain) FieldEditorTextView *fieldEditor;
@property (nonatomic, retain) IRCWorld *world;
@property (nonatomic, retain) ViewTheme *viewTheme;
@property (nonatomic, retain) InputHistory *inputHistory;
@property (nonatomic, retain) NickCompletionStatus *completionStatus;
@property (nonatomic, assign) BOOL terminating;

- (void)loadWindowState;

- (IBAction)insertColorCharIntoTextBox:(id)sender;
- (IBAction)insertBoldCharIntoTextBox:(id)sender;
- (IBAction)insertItalicCharIntoTextBox:(id)sender;
- (IBAction)insertUnderlineCharIntoTextBox:(id)sender;

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