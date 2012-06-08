// Created by Satoshi Nakagawa <psychs AT limechat DOT net> <http://github.com/psychs/limechat>
// Modifications by Codeux Software <support AT codeux DOT com> <https://github.com/codeux/Textual>
// You can redistribute it and/or modify it under the new BSD license.

@class MasterController;
@class IRCClient, IRCChannel, IRCChannelConfig, IRCClientConfig;

@interface IRCWorld : NSObject <NSOutlineViewDataSource, NSOutlineViewDelegate>
{
	MainWindow			*__unsafe_unretained window;
	ViewTheme			*__weak viewTheme;
	InputTextField		*__unsafe_unretained text;
	GrowlController		*__weak growl;
	LogController		*dummyLog;
	MasterController	*__weak master;
	MenuController		*__weak menuController;
	
	ServerList *__weak serverList;
	MemberList *__weak memberList;
	
	NSBox *__weak logBase;
	
	NSMenu *__weak logMenu;
	NSMenu *__weak urlMenu;
	NSMenu *__weak addrMenu;
	NSMenu *__weak chanMenu;
	NSMenu *__weak treeMenu;
	NSMenu *__weak memberMenu;
	NSMenu *serverMenu;
	NSMenu *channelMenu;
	
	NSInteger messagesSent;
	NSInteger messagesReceived;
	
	TXFSLongInt bandwidthIn;
	TXFSLongInt bandwidthOut;
	
	IRCWorldConfig *config;
	
	NSMutableArray *clients;
	
	NSInteger itemId;
	
	BOOL soundMuted;
	BOOL reloadingTree;
	
	IRCExtras *__weak extrac;
	
	IRCTreeItem *selected;
	
	NSInteger previousSelectedClientId;
	NSInteger previousSelectedChannelId;
	
	NSArray *allLoadedBundles;
	NSArray *bundlesWithPreferences;
	
	NSDictionary *bundlesForUserInput;
	NSDictionary *bundlesForServerInput;
	NSDictionary *bundlesWithOutputRules;
}

@property (weak) ServerList *serverList;
@property (weak) MemberList *memberList;
@property (unsafe_unretained) MainWindow *window;
@property (weak) ViewTheme *viewTheme;
@property (unsafe_unretained) InputTextField *text;
@property (weak) GrowlController *growl;
@property (weak) MasterController *master;
@property (strong) LogController *dummyLog;
@property (weak) MenuController *menuController;
@property (weak) NSBox *logBase;
@property (weak) NSMenu *logMenu;
@property (weak) NSMenu *urlMenu;
@property (weak) NSMenu *addrMenu;
@property (weak) NSMenu *chanMenu;
@property (weak) NSMenu *treeMenu;
@property (weak) NSMenu *memberMenu;
@property (strong) NSMenu *serverMenu;
@property (strong) NSMenu *channelMenu;
@property (assign) NSInteger messagesSent;
@property (assign) NSInteger messagesReceived;
@property (assign) TXFSLongInt bandwidthIn;
@property (assign) TXFSLongInt bandwidthOut;
@property (strong) IRCWorldConfig *config;
@property (strong) NSMutableArray *clients;
@property (assign) NSInteger itemId;
@property (assign) BOOL soundMuted;
@property (weak) IRCExtras *extrac;
@property (strong) IRCTreeItem *selected;
@property (assign) NSInteger previousSelectedClientId;
@property (assign) NSInteger previousSelectedChannelId;
@property (strong) NSArray *allLoadedBundles;
@property (strong) NSArray *bundlesWithPreferences;
@property (strong) NSDictionary *bundlesForUserInput;
@property (strong) NSDictionary *bundlesForServerInput;
@property (strong) NSDictionary *bundlesWithOutputRules;

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
- (void)notifyOnGrowl:(NotificationType)type title:(NSString *)title desc:(NSString *)desc userInfo:(NSDictionary *)info;

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

- (LogController *)createLogWithClient:(IRCClient *)client channel:(IRCChannel *)channel;

@end
