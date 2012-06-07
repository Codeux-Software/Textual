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

@property (nonatomic, assign) BOOL ghostMode;
@property (nonatomic, assign) BOOL terminating;
@property (nonatomic, strong) NSBox *logBase;
@property (nonatomic, strong) MainWindow *window;
@property (nonatomic, strong) MenuController *menu;
@property (nonatomic, strong) InputTextField *text;
@property (nonatomic, strong) ServerList *serverList;
@property (nonatomic, strong) MemberList *memberList;
@property (nonatomic, strong) ThinSplitView *serverSplitView;
@property (nonatomic, strong) ThinSplitView *memberSplitView;
@property (nonatomic, strong) NSMenuItem *serverMenu;
@property (nonatomic, strong) NSMenuItem *channelMenu;
@property (nonatomic, strong) NSButton *addServerButton;
@property (nonatomic, strong) NSMenu *logMenu;
@property (nonatomic, strong) NSMenu *urlMenu;
@property (nonatomic, strong) NSMenu *treeMenu;
@property (nonatomic, strong) NSMenu *addrMenu;
@property (nonatomic, strong) NSMenu *chanMenu;
@property (nonatomic, strong) NSMenu *memberMenu;
@property (nonatomic, strong) IRCWorld *world;
@property (nonatomic, strong) IRCExtras *extrac;
@property (nonatomic, strong) ViewTheme *viewTheme;
@property (nonatomic, strong) GrowlController *growl;
@property (nonatomic, strong) WelcomeSheet *welcomeSheet;
@property (nonatomic, strong) InputHistory *inputHistory;
@property (nonatomic, strong) IRCTextFormatterMenu *formattingMenu;
@property (nonatomic, strong) NickCompletionStatus *completionStatus;
@property (nonatomic, assign) NSInteger memberSplitViewOldPosition;

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