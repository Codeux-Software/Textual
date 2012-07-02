// Created by Satoshi Nakagawa <psychs AT limechat DOT net> <http://github.com/psychs/limechat>
// Modifications by Codeux Software <support AT codeux DOT com> <https://github.com/codeux/Textual>
// You can redistribute it and/or modify it under the new BSD license.

#import "TextualApplication.h"

@interface TXMasterController : NSObject <NSSplitViewDelegate>
@property (nonatomic, assign) BOOL ghostMode;
@property (nonatomic, assign) BOOL terminating;
@property (nonatomic, strong) NSBox *logBase;
@property (nonatomic, strong) TXMenuController *menu;
@property (nonatomic, strong) TVCMainWindow *window;
@property (nonatomic, strong) TVCMainWindowSegmentedControl *windowButtonController;
@property (nonatomic, strong) TVCMainWindowSegmentedCell *windowButtonControllerCell;
@property (nonatomic, strong) TVCInputTextField *text;
@property (nonatomic, strong) TVCServerList *serverList;
@property (nonatomic, strong) TVCMemberList *memberList;
@property (nonatomic, strong) TVCThinSplitView *serverSplitView;
@property (nonatomic, strong) TVCThinSplitView *memberSplitView;
@property (nonatomic, strong) TVCTextFormatterMenu *formattingMenu;
@property (nonatomic, strong) NSMenuItem *serverMenu;
@property (nonatomic, strong) NSMenuItem *channelMenu;
@property (nonatomic, strong) NSButton *addServerButton;
@property (nonatomic, strong) NSMenu *logMenu;
@property (nonatomic, strong) NSMenu *urlMenu;
@property (nonatomic, strong) NSMenu *treeMenu;
@property (nonatomic, strong) NSMenu *chanMenu;
@property (nonatomic, strong) NSMenu *memberMenu;
@property (nonatomic, strong) IRCWorld *world;
@property (nonatomic, strong) IRCExtras *extrac;
@property (nonatomic, strong) TPCViewTheme *viewTheme;
@property (nonatomic, strong) TDCWelcomeSheet *welcomeSheet;
@property (nonatomic, strong) TLOGrowlController *growl;
@property (nonatomic, strong) TLOInputHistory *inputHistory;
@property (nonatomic, strong) TLONickCompletionStatus *completionStatus;
@property (nonatomic, assign) NSInteger memberSplitViewOldPosition;

- (void)loadWindowState;
- (void)saveWindowState;
- (void)showMemberListSplitView:(BOOL)showList;

- (void)updateSegmentedController;

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