// Created by Satoshi Nakagawa <psychs AT limechat DOT net> <http://github.com/psychs/limechat>
// Modifications by Codeux Software <support AT codeux DOT com> <https://github.com/codeux/Textual>
// You can redistribute it and/or modify it under the new BSD license.
// Converted to ARC Support on June 08, 2012

#import "TextualApplication.h"

@interface TXMenuController : NSObject
@property (nonatomic, weak) IRCWorld *world;
@property (nonatomic, weak) TXMasterController *master;
@property (nonatomic, weak) TVCServerList *serverList;
@property (nonatomic, weak) TVCMemberList *memberList;
@property (nonatomic, unsafe_unretained) TVCMainWindow *window;
@property (nonatomic, unsafe_unretained) TVCInputTextField *text;
@property (nonatomic, strong) NSString *pointedUrl;
@property (nonatomic, strong) NSString *pointedNick;
@property (nonatomic, strong) NSString *pointedChannelName;
@property (nonatomic, strong) NSString *currentSearchPhrase;
@property (nonatomic, strong) NSMenuItem *closeWindowItem;
@property (nonatomic, assign) BOOL findPanelOpened;
@property (nonatomic, strong) TDChannelSheet *channelSheet;
@property (nonatomic, strong) TDCNickSheet *nickSheet;
@property (nonatomic, strong) TDCModeSheet *modeSheet;
@property (nonatomic, strong) TDCAboutPanel *aboutPanel;
@property (nonatomic, strong) TDCTopicSheet *topicSheet;
@property (nonatomic, strong) TDCServerSheet *serverSheet;
@property (nonatomic, strong) TDCInviteSheet *inviteSheet;
@property (nonatomic, strong) TDCHighlightSheet *highlightSheet;
@property (nonatomic, strong) TDCPreferencesController *preferencesController;
@property (nonatomic, assign) BOOL isInFullScreenMode;

- (void)terminate;

- (NSArray *)selectedMembers:(NSMenuItem *)sender;
- (BOOL)checkSelectedMembers:(NSMenuItem *)item;
- (void)deselectMembers:(NSMenuItem *)sender;

- (void)showPreferencesDialog:(id)sender;

- (void)performPaste:(id)sender;
- (void)searchGoogle:(id)sender;
- (void)closeWindow:(id)sender;
- (void)copyLogAsHtml:(id)sender;

- (void)toggleDeveloperMode:(id)sender;

- (void)showHighlightSheet:(id)sender;
- (void)showServerPropertyDialog:(IRCClient *)u ignore:(NSString *)imask;

- (void)markScrollback:(id)sender;
- (void)clearScrollback:(id)sender;
- (void)gotoScrollbackMarker:(id)sender;
- (void)markAllAsRead:(id)sender;
- (void)increaseLogFontSize:(id)sender;
- (void)decreaseLogFontSize:(id)sender;

- (void)connect:(id)sender;
- (void)disconnect:(id)sender;
- (void)cancelReconnection:(id)sender;
- (void)showNicknameChangeDialog:(id)sender;
- (void)showServerChannelList:(id)sender;
- (void)addServer:(id)sender;
- (void)copyServer:(id)sender;
- (void)deleteServer:(id)sender;
- (void)showServerPropertiesDialog:(id)sender;

- (void)onNextHighlight:(id)sender;
- (void)onPreviousHighlight:(id)sender;

- (void)joinChannel:(id)sender;
- (void)leaveChannel:(id)sender;
- (void)showChannelTopicDialog:(id)sender;
- (void)showChannelModeDialog:(id)sender;
- (void)addChannel:(id)sender;
- (void)deleteChannel:(id)sender;
- (void)showChannelPropertiesDialog:(id)sender;

- (void)memberListDoubleClicked:(id)sender;
- (void)memberSendWhois:(id)sender;
- (void)memberStartQuery:(id)sender;
- (void)memberSendInvite:(id)sender;
- (void)memberSendCTCPPing:(id)sender;
- (void)memberSendCTCPTime:(id)sender;
- (void)memberSendCTCPVersion:(id)sender;
- (void)memberSendCTCPUserinfo:(id)sender;
- (void)memberSendCTCPClientInfo:(id)sender;
- (void)memberModeChangeOp:(id)sender;
- (void)memberModeChangeDeop:(id)sender;
- (void)memberModeChangeHalfop:(id)sender;
- (void)memberModeChangeDehalfop:(id)sender;
- (void)memberModeChangeVoice:(id)sender;
- (void)memberModeChangeDevoice:(id)sender;
- (void)memberKickFromChannel:(id)sender;
- (void)memberBanFromServer:(id)sender;
- (void)memberKickbanFromChannel:(id)sender;
- (void)memberKillFromServer:(id)sender;
- (void)memberGlineFromServer:(id)sender;
- (void)memberShunFromServer:(id)sender;

- (void)copyUrl:(id)sender;
- (void)joinClickedChannel:(id)sender;

- (void)toggleChannelModerationMode:(id)sender;
- (void)toggleChannelInviteMode:(id)sender;

- (void)sortChannelListNames:(id)sender;
- (void)showMainWindow:(id)sender;
- (void)showChannelIgnoreList:(id)sender;
- (void)showAboutWindow:(id)sender;
- (void)openLogLocation:(id)sender;
- (void)openChannelLogs:(id)sender;
- (void)connectToTextualHelpChannel:(id)sender;
- (void)showSetVhostPrompt:(id)sender;
- (void)showFindPanel:(id)sender;
- (void)showChannelBanList:(id)sender;
- (void)showChannelBanExceptionList:(id)sender;
- (void)showChannelInviteExceptionList:(id)sender;

- (void)commandWShortcutUsed:(id)sender;
- (void)openHelpMenuLinkItem:(id)sender;
- (void)showContributors:(id)sender;
- (void)showAcknowledgments:(id)sender;
- (void)processNavigationItem:(id)sender;
- (void)toggleFullscreenMode:(id)sender;
- (void)centerMainWindow:(id)sender;

- (void)forceReloadTheme:(id)sender;
@end