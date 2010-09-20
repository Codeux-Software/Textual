// Created by Satoshi Nakagawa <psychs AT limechat DOT net> <http://github.com/psychs/limechat>
// Modifications by Michael Morris <mikey AT codeux DOT com> <http://github.com/mikemac11/Textual>
// You can redistribute it and/or modify it under the new BSD license.

#import <Cocoa/Cocoa.h>
#import "MainWindow.h"
#import "InputTextField.h"
#import "ServerTreeView.h"
#import "MemberListView.h"
#import "PreferencesController.h"
#import "NickSheet.h"
#import "ModeSheet.h"
#import "TopicSheet.h"
#import "InviteSheet.h"
#import "AboutPanel.h"
#import "MasterController.h"

@class IRCWorld;
@class IRCClient;
@class IRCExtras;
@class MasterController;

@interface MenuController : NSObject
{
	IBOutlet NSMenuItem* closeWindowItem;
	
	IRCWorld* world;
	MainWindow* window;
	InputTextField* text;
	ServerTreeView* tree;
	MasterController* master;
	MemberListView* memberList;
	
	NSString* pointedUrl;
	NSString* pointedAddress;
	NSString* pointedNick;
	NSString* pointedChannelName;
	NSString* currentSearchPhrase;
	
	PreferencesController* preferencesController;
	NSMutableArray* ServerSheets;
	NSMutableArray* ChannelSheets;
	NickSheet* nickSheet;
	ModeSheet* modeSheet;
	TopicSheet* topicSheet;
	InviteSheet* inviteSheet;
	AboutPanel* aboutPanel;
	NSOpenPanel* fileSendPanel;
	NSArray* fileSendTargets;
	NSInteger fileSendUID;
}

@property (nonatomic, assign) IRCWorld* world;
@property (nonatomic, assign) MainWindow* window;
@property (nonatomic, assign) InputTextField* text;
@property (nonatomic, assign) ServerTreeView* tree;
@property (nonatomic, assign) MasterController* master;
@property (nonatomic, assign) MemberListView* memberList;
@property (nonatomic, retain) NSString* pointedUrl;
@property (nonatomic, retain) NSString* pointedAddress;
@property (nonatomic, retain) NSString* pointedNick;
@property (nonatomic, retain) NSString* pointedChannelName;
@property (nonatomic, retain) NSString* currentSearchPhrase;
@property (nonatomic, retain) NSMenuItem* closeWindowItem;
@property (nonatomic, retain) PreferencesController* preferencesController;
@property (nonatomic, retain) NSMutableArray* ServerSheets;
@property (nonatomic, retain) NSMutableArray* ChannelSheets;
@property (nonatomic, retain) NickSheet* nickSheet;
@property (nonatomic, retain) ModeSheet* modeSheet;
@property (nonatomic, retain) TopicSheet* topicSheet;
@property (nonatomic, retain) InviteSheet* inviteSheet;
@property (nonatomic, retain) AboutPanel* aboutPanel;
@property (nonatomic, retain) NSOpenPanel* fileSendPanel;
@property (nonatomic, retain) NSArray* fileSendTargets;
@property (nonatomic) NSInteger fileSendUID;

- (void)terminate;
- (void)showServerPropertyDialog:(IRCClient*)client ignore:(BOOL)ignore;

- (void)onPreferences:(id)sender;
- (void)onDcc:(id)sender;

- (NSArray*)selectedMembers:(NSMenuItem*)sender;
- (void)deselectMembers:(NSMenuItem*)sender;

- (void)onCloseWindow:(id)sender;

- (void)onPaste:(id)sender;
- (void)onPasteMyAddress:(id)sender;
- (void)onSearchWeb:(id)sender;
- (void)onCopyLogAsHtml:(id)sender;

- (void)onMarkScrollback:(id)sender;
- (void)onClearMark:(id)sender;
- (void)onGoToMark:(id)sender;
- (void)onMarkAllAsRead:(id)sender;
- (void)onMarkAllAsReadAndMarkAllScrollbacks:(id)sender;

- (void)onConnect:(id)sender;
- (void)onDisconnect:(id)sender;
- (void)onCancelReconnecting:(id)sender;
- (void)onNick:(id)sender;
- (void)onChannelList:(id)sender;
- (void)onAddServer:(id)sender;
- (void)onCopyServer:(id)sender;
- (void)onDeleteServer:(id)sender;
- (void)onServerProperties:(id)sender;

- (void)onJoin:(id)sender;
- (void)onLeave:(id)sender;
- (void)onTopic:(id)sender;
- (void)onMode:(id)sender;
- (void)onAddChannel:(id)sender;
- (void)onDeleteChannel:(id)sender;
- (void)onChannelProperties:(id)sender;

- (void)memberListDoubleClicked:(id)sender;
- (void)onMemberWhois:(id)sender;
- (void)onMemberTalk:(id)sender;
- (void)onMemberInvite:(id)sender;
- (void)onMemberSendFile:(id)sender;
- (void)onMemberPing:(id)sender;
- (void)onMemberTime:(id)sender;
- (void)onMemberVersion:(id)sender;
- (void)onMemberUserInfo:(id)sender;
- (void)onMemberClientInfo:(id)sender;
- (void)onMemberOp:(id)sender;
- (void)onMemberDeOp:(id)sender;
- (void)onMemberHalfOp:(id)sender;
- (void)onMemberDeHalfOp:(id)sender;
- (void)onMemberVoice:(id)sender;
- (void)onMemberDeVoice:(id)sender;
- (void)onMemberKick:(id)sender;
- (void)onMemberBan:(id)sender;
- (void)onMemberBanKick:(id)sender;
- (void)onMemberKill:(id)sender;
- (void)onMemberGline:(id)sender;
- (void)onMemberShun:(id)sender;

- (void)onCopyUrl:(id)sender;
- (void)onJoinChannel:(id)sender;
- (void)onCopyAddress:(id)sender;

- (void)onWantChannelListSorted:(id)sender;
- (void)onWantMainWindowShown:(id)sender;
- (void)onWantIgnoreListShown:(id)sender;
- (void)onWantAboutWindowShown:(id)sender;
- (void)onWantToReadTextualLogs:(id)sender;
- (void)onWantToReadChannelLogs:(id)sender;
- (void)onWantTextualConnnectToHelp:(id)sender;
- (void)onWantHostServVhostSet:(id)sender;
- (void)onWantFindPanel:(id)sender;
- (void)onWantChannelBanList:(id)sender;
- (void)onWantChannelBanExceptionList:(id)sender;
- (void)onWantMainWindowCentered:(id)sender;

- (void)openHelpMenuLinkItem:(id)sender;

- (void)onWantThemeForceReloaded:(id)sender;

- (void)processNavigationItem:(NSMenuItem *)sender;
@end