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
#import "DCCController.h"
#import "GrowlController.h"
#import "IconManager.h"
#import "IRCExtras.h"

@interface IRCWorld : NSObject 
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
	DCCController* dcc;
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
	
	LogController* dummyLog;
	
	IRCWorldConfig* config;
	NSMutableArray* clients;
	
	NSInteger itemId;
	BOOL reloadingTree;
	IRCTreeItem* selected;
	
	NSInteger previousSelectedClientId;
	NSInteger previousSelectedChannelId;
	
	NSDictionary *bundlesForUserInput;
	NSDictionary *bundlesForServerInput;
}

@property (retain) NSDictionary *bundlesForUserInput;
@property (retain) NSDictionary *bundlesForServerInput;
@property (assign) IRCExtras* extrac;
@property (assign) MainWindow* window;
@property (assign) GrowlController* growl;
@property (assign) ServerTreeView* tree;
@property (assign) InputTextField* text;
@property (assign) NSBox*logBase;
@property (assign) ChatBox* chatBox;
@property (assign) FieldEditorTextView* fieldEditor;
@property (assign) MemberListView* memberList;
@property (assign) MenuController* menuController;
@property (assign) DCCController* dcc;
@property (assign) ViewTheme* viewTheme;
@property (assign) NSMenu* treeMenu;
@property (assign) NSMenu* logMenu;
@property (assign) NSMenu* urlMenu;
@property (assign) NSMenu* addrMenu;
@property (assign) NSMenu* chanMenu;
@property (assign) NSMenu* memberMenu;
@property (readonly) NSMutableArray* clients;
@property (retain) IRCTreeItem* selected;
@property (readonly) IRCClient* selectedClient;
@property (readonly) IRCChannel* selectedChannel;
@property (retain) IconManager *iconManager;
@property (retain) NSMenu* serverMenu;
@property (retain) NSMenu* channelMenu;
@property (retain) LogController* dummyLog;
@property (retain) IRCWorldConfig* config;
@property NSInteger itemId;
@property BOOL reloadingTree;
@property NSInteger previousSelectedClientId;
@property NSInteger previousSelectedChannelId;

- (void)setup:(IRCWorldConfig*)seed;
- (void)setupTree;
- (void)save;
- (NSMutableDictionary*)dictionaryValue;

- (void)setServerMenuItem:(NSMenuItem*)item;
- (void)setChannelMenuItem:(NSMenuItem*)item;

- (void)onTimer;
- (void)autoConnect:(BOOL)afterWakeUp;
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
@end