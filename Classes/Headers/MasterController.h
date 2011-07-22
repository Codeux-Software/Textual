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
@property (nonatomic, retain) NSBox *logBase;
@property (nonatomic, retain) MainWindow *window;
@property (nonatomic, retain) MenuController *menu;
@property (nonatomic, retain) InputTextField *text;
@property (nonatomic, retain) ServerList *serverList;
@property (nonatomic, retain) MemberList *memberList;
@property (nonatomic, retain) ThinSplitView *serverSplitView;
@property (nonatomic, retain) ThinSplitView *memberSplitView;
@property (nonatomic, retain) NSMenuItem *serverMenu;
@property (nonatomic, retain) NSMenuItem *channelMenu;
@property (nonatomic, retain) NSButton *addServerButton;
@property (nonatomic, retain) NSMenu *logMenu;
@property (nonatomic, retain) NSMenu *urlMenu;
@property (nonatomic, retain) NSMenu *treeMenu;
@property (nonatomic, retain) NSMenu *addrMenu;
@property (nonatomic, retain) NSMenu *chanMenu;
@property (nonatomic, retain) NSMenu *memberMenu;
@property (nonatomic, retain) IRCWorld *world;
@property (nonatomic, retain) IRCExtras *extrac;
@property (nonatomic, retain) ViewTheme *viewTheme;
@property (nonatomic, retain) GrowlController *growl;
@property (nonatomic, retain) WelcomeSheet *welcomeSheet;
@property (nonatomic, retain) InputHistory *inputHistory;
@property (nonatomic, retain) IRCTextFormatterMenu *formattingMenu;
@property (nonatomic, retain) NickCompletionStatus *completionStatus;
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