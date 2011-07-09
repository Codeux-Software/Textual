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
	MasterController *master;
	
	ServerList *serverList;
	MemberList *memberList;
	
	NSString *pointedUrl;
	NSString *pointedAddress;
	NSString *pointedNick;
	NSString *pointedChannelName;
	NSString *currentSearchPhrase;
	
	NickSheet *nickSheet;
	ModeSheet *modeSheet;
	AboutPanel *aboutPanel;
	TopicSheet *topicSheet;
	InviteSheet *inviteSheet;
	ServerSheet *serverSheet;
	ChannelSheet *channelSheet;
	HighlightSheet *highlightSheet;
	PreferencesController *preferencesController;
	
	BOOL isInFullScreenMode;
}

@property (nonatomic, assign) IRCWorld *world;
@property (nonatomic, assign) MainWindow *window;
@property (nonatomic, assign) InputTextField *text;
@property (nonatomic, assign) MasterController *master;
@property (nonatomic, assign) ServerList *serverList;
@property (nonatomic, assign) MemberList *memberList;
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
@property (nonatomic, retain) HighlightSheet *highlightSheet;
@property (nonatomic, assign) BOOL isInFullScreenMode;

- (void)terminate;

- (NSArray *)selectedMembers:(NSMenuItem *)sender;
- (BOOL)checkSelectedMembers:(NSMenuItem *)item;
- (void)deselectMembers:(NSMenuItem *)sender;

- (void)onPreferences:(id)sender;
- (void)onCloseWindow:(id)sender;

- (void)onPaste:(id)sender;
- (void)onSearchWeb:(id)sender;
- (void)onCopyLogAsHtml:(id)sender;

- (void)toggleDeveloperMode:(id)sender;

- (void)showHighlightSheet:(id)sender;
- (void)showServerPropertyDialog:(IRCClient *)u ignore:(NSString *)imask;

- (void)onMarkScrollback:(id)sender;
- (void)onMarkAllAsRead:(id)sender;
- (void)onIncreaseFontSize:(id)sender;
- (void)onDecreaseFontSize:(id)sender;

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

- (void)onWantChannelModerated:(id)sender;
- (void)onWantChannelVoiceOnly:(id)sender;

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
- (void)onWantChannelInviteExceptionList:(id)sender;

- (void)commandWShortcutUsed:(id)sender;
- (void)openHelpMenuLinkItem:(id)sender;
- (void)onShowAcknowledgments:(id)sender;
- (void)processNavigationItem:(id)sender;
- (void)wantsFullScreenModeToggled:(id)sender;
- (void)onWantMainWindowCentered:(id)sender;

- (void)onWantThemeForceReloaded:(id)sender;

@end