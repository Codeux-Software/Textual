// Created by Satoshi Nakagawa <psychs AT limechat DOT net> <http://github.com/psychs/limechat>
// Modifications by Codeux Software <support AT codeux DOT com> <https://github.com/codeux/Textual>
// You can redistribute it and/or modify it under the new BSD license.

@class MasterController;
@class IRCClient, IRCChannel, IRCChannelConfig, IRCClientConfig;

@interface IRCWorld : NSObject <NSOutlineViewDataSource, NSOutlineViewDelegate>
{
	ChatBox *chatBox;
	MainWindow *window;
	ViewTheme *viewTheme;
	ServerTreeView *tree;
	InputTextField *text;
	GrowlController *growl;
	LogController *dummyLog;
	MasterController *master;
	MemberListView *memberList;
	MenuController *menuController;
	FieldEditorTextView *fieldEditor;
	
	NSBox *logBase;
	
	NSMenu *logMenu;
	NSMenu *urlMenu;
	NSMenu *addrMenu;
	NSMenu *chanMenu;
	NSMenu *treeMenu;
	NSMenu *memberMenu;
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
	
	IRCExtras *extrac;
	
	IRCTreeItem *selected;
	
	NSInteger previousSelectedClientId;
	NSInteger previousSelectedChannelId;
	
	NSArray *allLoadedBundles;
	NSArray *bundlesWithPreferences;
	
	NSDictionary *bundlesForUserInput;
	NSDictionary *bundlesForServerInput;
	NSDictionary *bundlesWithOutputRules;
}

@property (assign) ChatBox *chatBox;
@property (assign) MainWindow *window;
@property (assign) ViewTheme *viewTheme;
@property (assign) ServerTreeView *tree;
@property (assign) InputTextField *text;
@property (assign) GrowlController *growl;
@property (assign) MasterController *master;
@property (retain) LogController *dummyLog;
@property (assign) MemberListView *memberList;
@property (assign) MenuController *menuController;
@property (assign) FieldEditorTextView *fieldEditor;
@property (assign) NSBox *logBase;
@property (assign) NSMenu *logMenu;
@property (assign) NSMenu *urlMenu;
@property (assign) NSMenu *addrMenu;
@property (assign) NSMenu *chanMenu;
@property (assign) NSMenu *treeMenu;
@property (assign) NSMenu *memberMenu;
@property (retain) NSMenu *serverMenu;
@property (retain) NSMenu *channelMenu;
@property (assign) NSInteger messagesSent;
@property (assign) NSInteger messagesReceived;
@property (assign) TXFSLongInt bandwidthIn;
@property (assign) TXFSLongInt bandwidthOut;
@property (retain) IRCWorldConfig *config;
@property (assign) NSMutableArray *clients;
@property (assign) NSInteger itemId;
@property (assign) BOOL soundMuted;
@property (assign) BOOL reloadingTree;
@property (assign) IRCExtras *extrac;
@property (retain) IRCTreeItem *selected;
@property (assign) NSInteger previousSelectedClientId;
@property (assign) NSInteger previousSelectedChannelId;
@property (retain) NSArray *allLoadedBundles;
@property (retain) NSArray *bundlesWithPreferences;
@property (retain) NSDictionary *bundlesForUserInput;
@property (retain) NSDictionary *bundlesForServerInput;
@property (retain) NSDictionary *bundlesWithOutputRules;

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
- (BOOL)inputText:(NSString *)s command:(NSString *)command;

- (void)markAllAsRead;
- (void)markAllScrollbacks;

- (void)updateIcon;

- (void)reloadTree;
- (void)adjustSelection;
- (void)expandClient:(IRCClient *)client;

- (void)updateTitle;
- (void)updateClientTitle:(IRCClient *)client;
- (void)updateChannelTitle:(IRCChannel *)channel;

- (void)notifyOnGrowl:(GrowlNotificationType)type title:(NSString *)title desc:(NSString *)desc context:(id)context;

- (void)preferencesChanged;
- (void)reloadTheme;
- (void)updateThemeStyle;
- (void)changeTextSize:(BOOL)bigger;

- (IRCClient *)createClient:(IRCClientConfig *)seed reload:(BOOL)reload;
- (IRCChannel *)createChannel:(IRCChannelConfig *)seed client:(IRCClient *)client reload:(BOOL)reload adjust:(BOOL)adjust;
- (IRCChannel *)createTalk:(NSString *)nick client:(IRCClient *)client;

- (void)destroyChannel:(IRCChannel *)channel;
- (void)destroyClient:(IRCClient *)client;

- (void)logKeyDown:(NSEvent *)e;
- (void)logDoubleClick:(NSString *)s;

- (void)createConnection:(NSString *)str chan:(NSString *)channel;

- (void)clearContentsOfClient:(IRCClient *)u;
- (void)clearContentsOfChannel:(IRCChannel *)c inClient:(IRCClient *)u;

- (LogController *)createLogWithClient:(IRCClient *)client channel:(IRCChannel *)channel;

@end