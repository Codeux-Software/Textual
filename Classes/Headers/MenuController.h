// Created by Satoshi Nakagawa <psychs AT limechat DOT net> <http://github.com/psychs/limechat>
// Modifications by Codeux Software <support AT codeux DOT com> <https://github.com/codeux/Textual>
// You can redistribute it and/or modify it under the new BSD license.
// Converted to ARC Support on Thursday, June 08, 2012

@class MasterController;

@interface MenuController : NSObject
@property (nonatomic, weak) IRCWorld *world;
@property (nonatomic, unsafe_unretained ) MainWindow *window;
@property (nonatomic, unsafe_unretained) InputTextField *text;
@property (nonatomic, weak) MasterController *master;
@property (nonatomic, weak) ServerList *serverList;
@property (nonatomic, weak) MemberList *memberList;
@property (nonatomic, strong) NSString *pointedUrl;
@property (nonatomic, strong) NSString *pointedNick;
@property (nonatomic, strong) NSString *pointedChannelName;
@property (nonatomic, strong) NSString *currentSearchPhrase;
@property (nonatomic, strong) NSMenuItem *closeWindowItem;
@property (nonatomic, strong) PreferencesController *preferencesController;
@property (nonatomic, strong) ChannelSheet *channelSheet;
@property (nonatomic, strong) NickSheet *nickSheet;
@property (nonatomic, strong) ModeSheet *modeSheet;
@property (nonatomic, strong) TopicSheet *topicSheet;
@property (nonatomic, strong) ServerSheet *serverSheet;
@property (nonatomic, strong) InviteSheet *inviteSheet;
@property (nonatomic, strong) AboutPanel *aboutPanel;
@property (nonatomic, strong) HighlightSheet *highlightSheet;
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
- (void)onClearScrollback:(id)sender;
- (void)onGotoScrollbackMark:(id)sender;
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

- (void)onNextHighlight:(id)sender;
- (void)onPreviousHighlight:(id)sender;

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
- (void)onShowContributors:(id)sender;
- (void)onShowAcknowledgments:(id)sender;
- (void)processNavigationItem:(id)sender;
- (void)wantsFullScreenModeToggled:(id)sender;
- (void)onWantMainWindowCentered:(id)sender;

- (void)onWantThemeForceReloaded:(id)sender;
@end