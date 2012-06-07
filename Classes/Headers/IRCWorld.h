// Created by Satoshi Nakagawa <psychs AT limechat DOT net> <http://github.com/psychs/limechat>
// Modifications by Codeux Software <support AT codeux DOT com> <https://github.com/codeux/Textual>
// You can redistribute it and/or modify it under the new BSD license.

@class MasterController;
@class IRCClient, IRCChannel, IRCChannelConfig, IRCClientConfig;

@interface IRCWorld : NSObject <NSOutlineViewDataSource, NSOutlineViewDelegate>
{
	MainWindow			*__weak window;
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

@property (nonatomic, weak) ServerList *serverList;
@property (nonatomic, weak) MemberList *memberList;
@property (nonatomic, weak) MainWindow *window;
@property (nonatomic, weak) ViewTheme *viewTheme;
@property (nonatomic, unsafe_unretained) InputTextField *text;
@property (nonatomic, weak) GrowlController *growl;
@property (nonatomic, weak) MasterController *master;
@property (nonatomic, strong) LogController *dummyLog;
@property (nonatomic, weak) MenuController *menuController;
@property (nonatomic, weak) NSBox *logBase;
@property (nonatomic, weak) NSMenu *logMenu;
@property (nonatomic, weak) NSMenu *urlMenu;
@property (nonatomic, weak) NSMenu *addrMenu;
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
