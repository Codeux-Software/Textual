/* ********************************************************************* 
       _____        _               _    ___ ____   ____
      |_   _|___  _| |_ _   _  __ _| |  |_ _|  _ \ / ___|
       | |/ _ \ \/ / __| | | |/ _` | |   | || |_) | |
       | |  __/>  <| |_| |_| | (_| | |   | ||  _ <| |___
       |_|\___/_/\_\\__|\__,_|\__,_|_|  |___|_| \_\\____|

 Copyright (c) 2010 — 2012 Codeux Software & respective contributors.
        Please see Contributors.pdf and Acknowledgements.pdf

 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions
 are met:

    * Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the
      documentation and/or other materials provided with the distribution.
    * Neither the name of the Textual IRC Client & Codeux Software nor the
      names of its contributors may be used to endorse or promote products
      derived from this software without specific prior written permission.

 THIS SOFTWARE IS PROVIDED BY THE AUTHOR AND CONTRIBUTORS ``AS IS'' AND
 ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 ARE DISCLAIMED. IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE LIABLE
 FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
 OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
 LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
 OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
 SUCH DAMAGE.

 *********************************************************************** */

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
- (void)loadExtensionsIntoMemory:(id)sender;
- (void)unloadExtensionsFromMemory:(id)sender;
- (void)resetDoNotAskMePopupWarnings:(id)sender;

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
- (void)connectToTextualTestingChannel:(id)sender;
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