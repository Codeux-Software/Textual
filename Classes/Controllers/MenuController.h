// Created by Satoshi Nakagawa <psychs AT limechat DOT net> <http://github.com/psychs/limechat>
// Modifications by Codeux Software <support AT codeux DOT com> <https://github.com/codeux/Textual>
// You can redistribute it and/or modify it under the new BSD license.

@class MasterController;

@interface MenuController : NSObject
{
	IBOutlet NSMenuItem *closeWindowItem;
	
	IRCWorld *world;
	MainWindow *window;
	InputTextField *text;
	ServerTreeView *tree;
	MasterController *master;
	MemberListView *memberList;
	
	NSString *pointedUrl;
	NSString *pointedAddress;
	NSString *pointedNick;
	NSString *pointedChannelName;
	NSString *currentSearchPhrase;
	
	PreferencesController *preferencesController;
	ServerSheet *serverSheet;
	ChannelSheet *channelSheet;
	NickSheet *nickSheet;
	ModeSheet *modeSheet;
	TopicSheet *topicSheet;
	InviteSheet *inviteSheet;
	AboutPanel *aboutPanel;
	
	BOOL isInFullScreenMode;
}

@property (nonatomic, assign) IRCWorld *world;
@property (nonatomic, assign) MainWindow *window;
@property (nonatomic, assign) InputTextField *text;
@property (nonatomic, assign) ServerTreeView *tree;
@property (nonatomic, assign) MasterController *master;
@property (nonatomic, assign) MemberListView *memberList;
@property (nonatomic, retain) NSString *pointedUrl;
@property (nonatomic, retain) NSString *pointedAddress;
@property (nonatomic, retain) NSString *pointedNick;
@property (nonatomic, retain) NSString *pointedChannelName;
@property (nonatomic, retain) NSString *currentSearchPhrase;
@property (nonatomic, retain) NSMenuItem *closeWindowItem;
@property (nonatomic, retain) PreferencesController *preferencesController;
@property (nonatomic, retain) ChannelSheet *channelSheet;
@property (nonatomic, retain) NickSheet *nickSheet;
@property (nonatomic, retain) ModeSheet *modeSheet;
@property (nonatomic, retain) TopicSheet *topicSheet;
@property (nonatomic, retain) ServerSheet *serverSheet;
@property (nonatomic, retain) InviteSheet *inviteSheet;
@property (nonatomic, retain) AboutPanel *aboutPanel;
@property (nonatomic, assign) BOOL isInFullScreenMode;

- (void)terminate;
- (void)showServerPropertyDialog:(IRCClient *)client ignore:(BOOL)ignore;

- (void)onPreferences:(id)sender;
- (void)onCloseWindow:(id)sender;

- (void)onPaste:(id)sender;
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

- (void)onWantChannelModerated:(id)sender;
- (void)onWantChannelVoiceOnly:(id)sender;

- (void)commandWShortcutUsed:(id)sender;

- (void)wantsFullScreenModeToggled:(id)sender;

- (void)processNavigationItem:(NSMenuItem *)sender;
@end