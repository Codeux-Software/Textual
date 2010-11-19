// Created by Satoshi Nakagawa <psychs AT limechat DOT net> <http://github.com/psychs/limechat>
// Modifications by Michael Morris <mikey AT codeux DOT com> <http://github.com/mikemac11/Textual>
// You can redistribute it and/or modify it under the new BSD license.

#import <Cocoa/Cocoa.h>
#import "MainWindow.h"
#import "ServerTreeView.h"
#import "InputTextField.h"
#import "ChatBox.h"
#import "FieldEditorTextView.h"
#import "MemberListView.h"
#import "LogController.h"
#import "IRCWorldConfig.h"
#import "IRCClientConfig.h"
#import "IRCChannelConfig.h"
#import "MenuController.h"
#import "ViewTheme.h"
#import "IRCTreeItem.h"
#import "GrowlController.h"
#import "IconManager.h"
#import "IRCExtras.h"
#import "GlobalModels.h"

@interface IRCWorld : NSObject <NSOutlineViewDataSource, NSOutlineViewDelegate>
{
	MainWindow* window;
	GrowlController* growl;
	ServerTreeView* tree;
	InputTextField* text;
	NSBox* logBase;
	ChatBox* chatBox;
	FieldEditorTextView* fieldEditor;
	MemberListView* memberList;
	MenuController* menuController;
	ViewTheme* viewTheme;
	IconManager *iconManager;
	IRCExtras* extrac;
	NSMenu* serverMenu;
	NSMenu* channelMenu;
	NSMenu* treeMenu;
	NSMenu* logMenu;
	NSMenu* urlMenu;
	NSMenu* addrMenu;
	NSMenu* chanMenu;
	NSMenu* memberMenu;
	
	NSInteger messagesSent;
	NSInteger messagesReceived;
	TXFSLongInt bandwidthIn;
	TXFSLongInt bandwidthOut;
	
	LogController* dummyLog;
	
	IRCWorldConfig* config;
	NSMutableArray* clients;
	
	NSInteger itemId;
	BOOL reloadingTree;
	IRCTreeItem* selected;
	
	BOOL soundMuted;
	
	NSInteger previousSelectedClientId;
	NSInteger previousSelectedChannelId;
	
	NSMutableArray *allLoadedBundles;
	NSMutableDictionary *bundlesForUserInput;
	NSMutableDictionary *bundlesForServerInput;
}

@property (nonatomic, retain) NSMutableArray *allLoadedBundles;
@property (nonatomic, retain) NSMutableDictionary *bundlesForUserInput;
@property (nonatomic, retain) NSMutableDictionary *bundlesForServerInput;
@property (nonatomic, assign) NSInteger messagesSent;
@property (nonatomic, assign) NSInteger messagesReceived;
@property (nonatomic, assign) TXFSLongInt bandwidthIn;
@property (nonatomic, assign) TXFSLongInt bandwidthOut;
@property (nonatomic, assign) IRCExtras* extrac;
@property (nonatomic, assign) MainWindow* window;
@property (nonatomic, assign) GrowlController* growl;
@property (nonatomic, assign) ServerTreeView* tree;
@property (nonatomic, assign) InputTextField* text;
@property (nonatomic, assign) NSBox*logBase;
@property (nonatomic, assign) ChatBox* chatBox;
@property (nonatomic, assign) FieldEditorTextView* fieldEditor;
@property (nonatomic, assign) MemberListView* memberList;
@property (nonatomic, assign) MenuController* menuController;
@property (nonatomic, assign) ViewTheme* viewTheme;
@property (nonatomic, assign) NSMenu* treeMenu;
@property (nonatomic, assign) NSMenu* logMenu;
@property (nonatomic, assign) NSMenu* urlMenu;
@property (nonatomic, assign) NSMenu* addrMenu;
@property (nonatomic, assign) NSMenu* chanMenu;
@property (nonatomic, assign) NSMenu* memberMenu;
@property (nonatomic, readonly) NSMutableArray* clients;
@property (nonatomic, assign) BOOL soundMuted;
@property (nonatomic, retain) IRCTreeItem* selected;
@property (nonatomic, readonly) IRCClient* selectedClient;
@property (nonatomic, readonly) IRCChannel* selectedChannel;
@property (nonatomic, retain) IconManager *iconManager;
@property (nonatomic, retain) NSMenu* serverMenu;
@property (nonatomic, retain) NSMenu* channelMenu;
@property (nonatomic, retain) LogController* dummyLog;
@property (nonatomic, retain) IRCWorldConfig* config;
@property (nonatomic) NSInteger itemId;
@property (nonatomic, assign) BOOL reloadingTree;
@property (nonatomic) NSInteger previousSelectedClientId;
@property (nonatomic) NSInteger previousSelectedChannelId;

- (void)setup:(IRCWorldConfig*)seed;
- (void)setupTree;
- (void)save;
- (NSMutableDictionary*)dictionaryValue;

- (void)setServerMenuItem:(NSMenuItem*)item;
- (void)setChannelMenuItem:(NSMenuItem*)item;

- (void)resetLoadedBundles;

- (IRCChannel*)selectedChannelOn:(IRCClient*)c;

- (void)onTimer;
- (void)autoConnectAfterWakeup:(BOOL)afterWakeUp;
- (void)terminate;
- (void)prepareForSleep;

- (IRCClient*)findClient:(NSString*)name;
- (IRCClient*)findClientById:(NSInteger)uid;
- (IRCChannel*)findChannelByClientId:(NSInteger)uid channelId:(NSInteger)cid;

- (void)select:(id)item;
- (void)selectChannelAt:(NSInteger)n;
- (void)selectClientAt:(NSInteger)n;
- (void)selectPreviousItem;

- (void)focusInputText;
- (BOOL)inputText:(NSString*)s command:(NSString*)command;

- (void)markAllAsRead;
- (void)markAllScrollbacks;

- (void)updateIcon;
- (void)updateAppIcon:(NSInteger)hlcount msgcount:(NSInteger)pmcount;

- (void)reloadTree;
- (void)adjustSelection;
- (void)expandClient:(IRCClient*)client;

- (void)updateTitle;
- (void)updateClientTitle:(IRCClient*)client;
- (void)updateChannelTitle:(IRCChannel*)channel;

- (void)notifyOnGrowl:(GrowlNotificationType)type title:(NSString*)title desc:(NSString*)desc context:(id)context;

- (void)preferencesChanged;
- (void)reloadTheme;
- (void)changeTextSize:(BOOL)bigger;

- (IRCClient*)createClient:(IRCClientConfig*)seed reload:(BOOL)reload;
- (IRCChannel*)createChannel:(IRCChannelConfig*)seed client:(IRCClient*)client reload:(BOOL)reload adjust:(BOOL)adjust;
- (IRCChannel*)createTalk:(NSString*)nick client:(IRCClient*)client;

- (void)destroyChannel:(IRCChannel*)channel;
- (void)destroyClient:(IRCClient*)client;

- (void)logKeyDown:(NSEvent*)e;
- (void)logDoubleClick:(NSString*)s;

- (void)createConnection:(NSString*)str chan:(NSString*)channel;

- (void)clearContentsOflient:(IRCClient*)u;
- (void)clearContentsOfChannel:(IRCChannel*)c inClient:(IRCClient*)u;

- (LogController*)createLogWithClient:(IRCClient*)client channel:(IRCChannel*)channel;
@end