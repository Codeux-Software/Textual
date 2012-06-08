// Created by Satoshi Nakagawa <psychs AT limechat DOT net> <http://github.com/psychs/limechat>
// Modifications by Codeux Software <support AT codeux DOT com> <https://github.com/codeux/Textual>
// You can redistribute it and/or modify it under the new BSD license.

@interface MasterController : NSObject <NSSplitViewDelegate>
{
	IBOutlet ThinSplitView *serverSplitView;
	IBOutlet ThinSplitView *memberSplitView;
	
	IBOutlet MainWindow *window;
	IBOutlet MenuController *menu;
	IBOutlet InputTextField *text;
	
	IBOutlet MemberList *memberList;
	IBOutlet ServerList *serverList;
	
	IBOutlet NSBox *logBase;
	
	IBOutlet NSMenuItem *serverMenu;
	IBOutlet NSMenuItem *channelMenu;
	
	IBOutlet NSMenu *logMenu;
	IBOutlet NSMenu *urlMenu;
	IBOutlet NSMenu *treeMenu;
	IBOutlet NSMenu *addrMenu;
	IBOutlet NSMenu *chanMenu;
	IBOutlet NSMenu *memberMenu;
	
	IBOutlet NSButton *addServerButton;
	
	IBOutlet IRCTextFormatterMenu *formattingMenu;
	
	IRCWorld *world;
	IRCExtras *extrac;
	ViewTheme *viewTheme;
	GrowlController *growl;
	WelcomeSheet *welcomeSheet;
	InputHistory *inputHistory;
	NickCompletionStatus *completionStatus;
	
	BOOL ghostMode;
	BOOL terminating;
	
	NSInteger memberSplitViewOldPosition;
}

@property (assign) BOOL ghostMode;
@property (assign) BOOL terminating;
@property (strong) NSBox *logBase;
@property (strong) MainWindow *window;
@property (strong) MenuController *menu;
@property (strong) InputTextField *text;
@property (strong) ServerList *serverList;
@property (strong) MemberList *memberList;
@property (strong) ThinSplitView *serverSplitView;
@property (strong) ThinSplitView *memberSplitView;
@property (strong) NSMenuItem *serverMenu;
@property (strong) NSMenuItem *channelMenu;
@property (strong) NSButton *addServerButton;
@property (strong) NSMenu *logMenu;
@property (strong) NSMenu *urlMenu;
@property (strong) NSMenu *treeMenu;
@property (strong) NSMenu *addrMenu;
@property (strong) NSMenu *chanMenu;
@property (strong) NSMenu *memberMenu;
@property (strong) IRCWorld *world;
@property (strong) IRCExtras *extrac;
@property (strong) ViewTheme *viewTheme;
@property (strong) GrowlController *growl;
@property (strong) WelcomeSheet *welcomeSheet;
@property (strong) InputHistory *inputHistory;
@property (strong) IRCTextFormatterMenu *formattingMenu;
@property (strong) NickCompletionStatus *completionStatus;
@property (assign) NSInteger memberSplitViewOldPosition;

- (void)loadWindowState;
- (void)saveWindowState;
- (void)showMemberListSplitView:(BOOL)showList;

- (void)textEntered;

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