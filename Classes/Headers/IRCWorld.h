// Created by Satoshi Nakagawa <psychs AT limechat DOT net> <http://github.com/psychs/limechat>
// Modifications by Codeux Software <support AT codeux DOT com> <https://github.com/codeux/Textual>
// You can redistribute it and/or modify it under the new BSD license.

#import "TextualApplication.h"

@interface IRCWorld : NSObject <NSOutlineViewDataSource, NSOutlineViewDelegate>
@property (nonatomic, weak) TVCServerList *serverList;
@property (nonatomic, weak) TVCMemberList *memberList;
@property (nonatomic, unsafe_unretained) TVCMainWindow *window;
@property (nonatomic, unsafe_unretained) TVCInputTextField *text;
@property (nonatomic, weak) TPCViewTheme *viewTheme;
@property (nonatomic, weak) TLOGrowlController *growl;
@property (nonatomic, weak) TXMasterController *master;
@property (nonatomic, strong) TVCLogController *dummyLog;
@property (nonatomic, weak) TXMenuController *menuController;
@property (nonatomic, weak) NSBox *logBase;
@property (nonatomic, weak) NSMenu *logMenu;
@property (nonatomic, weak) NSMenu *urlMenu;
@property (nonatomic, weak) NSMenu *chanMenu;
@property (nonatomic, weak) NSMenu *treeMenu;
@property (nonatomic, weak) NSMenu *memberMenu;
@property (nonatomic, strong) NSMenu *serverMenu;
@property (nonatomic, strong) NSMenu *channelMenu;
@property (nonatomic, assign) NSInteger messagesSent;
@property (nonatomic, assign) NSInteger messagesReceived;
@property (nonatomic, assign) TXFSLongInt bandwidthIn;
@property (nonatomic, assign) TXFSLongInt bandwidthOut;
@property (nonatomic, strong) IRCWorldConfig *config;
@property (nonatomic, strong) NSMutableArray *clients;
@property (nonatomic, assign) NSInteger itemId;
@property (nonatomic, assign) BOOL soundMuted;
@property (nonatomic, assign) BOOL reloadingTree;
@property (nonatomic, weak) IRCExtras *extrac;
@property (nonatomic, strong) IRCTreeItem *selected;
@property (nonatomic, assign) NSInteger previousSelectedClientId;
@property (nonatomic, assign) NSInteger previousSelectedChannelId;
@property (nonatomic, strong) NSArray *allLoadedBundles;
@property (nonatomic, strong) NSArray *bundlesWithPreferences;
@property (nonatomic, strong) NSDictionary *bundlesForUserInput;
@property (nonatomic, strong) NSDictionary *bundlesForServerInput;
@property (nonatomic, strong) NSDictionary *bundlesWithOutputRules;

- (void)setup:(IRCWorldConfig *)seed;
- (void)setupTree;
- (void)save;

- (NSMutableDictionary *)dictionaryValue;

- (void)setServerMenuItem:(NSMenuItem *)item;
- (void)setChannelMenuItem:(NSMenuItem *)item;

- (void)resetLoadedBundles;

- (void)autoConnectAfterWakeup:(BOOL)afterWakeUp;
- (void)terminate;
- (void)prepareForSleep;

- (IRCClient *)findClient:(NSString *)name;
- (IRCClient *)findClientById:(NSInteger)uid;
- (IRCChannel *)findChannelByClientId:(NSInteger)uid channelId:(NSInteger)cid;

- (void)select:(id)item;
- (void)selectChannelAt:(NSInteger)n;
- (void)selectClientAt:(NSInteger)n;
- (void)selectPreviousItem;

- (IRCClient *)selectedClient;
- (IRCChannel *)selectedChannel;
- (IRCChannel *)selectedChannelOn:(IRCClient *)c;

- (IRCTreeItem *)previouslySelectedItem;

- (void)focusInputText;
- (BOOL)inputText:(id)str command:(NSString *)command;

- (void)markAllAsRead;
- (void)markAllScrollbacks;

- (void)updateIcon;

- (void)reloadTree;
- (void)adjustSelection;
- (void)expandClient:(IRCClient *)client;

- (void)updateTitle;
- (void)updateClientTitle:(IRCClient *)client;
- (void)updateChannelTitle:(IRCChannel *)channel;

- (void)addHighlightInChannel:(IRCChannel *)channel withMessage:(NSString *)message;
- (void)notifyOnGrowl:(TXNotificationType)type title:(NSString *)title desc:(NSString *)desc userInfo:(NSDictionary *)info;

- (void)preferencesChanged;
- (void)reloadTheme;
- (void)changeTextSize:(BOOL)bigger;

- (IRCClient *)createClient:(IRCClientConfig *)seed reload:(BOOL)reload;
- (IRCChannel *)createChannel:(IRCChannelConfig *)seed client:(IRCClient *)client reload:(BOOL)reload adjust:(BOOL)adjust;
- (IRCChannel *)createTalk:(NSString *)nick client:(IRCClient *)client;

- (void)destroyChannel:(IRCChannel *)c part:(BOOL)forcePart;
- (void)destroyChannel:(IRCChannel *)c;
- (void)destroyClient:(IRCClient *)client;

- (void)logKeyDown:(NSEvent *)e;
- (void)logDoubleClick:(NSString *)s;

- (void)createConnection:(NSString *)str chan:(NSString *)channel;

- (void)clearContentsOfClient:(IRCClient *)u;
- (void)clearContentsOfChannel:(IRCChannel *)c inClient:(IRCClient *)u;

- (TVCLogController *)createLogWithClient:(IRCClient *)client channel:(IRCChannel *)channel;
@end