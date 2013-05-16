/* ********************************************************************* 
       _____        _               _    ___ ____   ____
      |_   _|___  _| |_ _   _  __ _| |  |_ _|  _ \ / ___|
       | |/ _ \ \/ / __| | | |/ _` | |   | || |_) | |
       | |  __/>  <| |_| |_| | (_| | |   | ||  _ <| |___
       |_|\___/_/\_\\__|\__,_|\__,_|_|  |___|_| \_\\____|

 Copyright (c) 2010 — 2013 Codeux Software & respective contributors.
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

/*
	Tag Reference:

	The tag used for each menu item was usually randomly picked
	during development. Do not try and look for any relation
	from one tag to another as they have none. They are simply
	a unique way to identify a specific menu item.

	2001: "Get Info (Whois)"
	2002: "Private Message (Query)"
	2005: "Invite To…"
	2024: "Look Up In Dictionary"
	2433: "Sort Channel List"
	3001: "Copy URL"
	313: "Paste"
	32345: "Mark Scrollback"
	32346: "Scrollback Marker"
	32347: "Mark All As Read"
	32348: "Clear Scrollback"
	32349: "Increase Font Size"
	32350: "Decrease Font Size"
	3301: "Join Channel"
	331: "Search on Google"
	4564: "Find…"
	4565: "Find Next"
	4566: "Find Previous"
	50001: "Next Server"
	50002: "Previous Server"
	50003: "Next Active Server"
	50004: "Previous Active Server"
	50005: "Next Channel"
	50006: "Previous Channel"
	50007: "Next Active Channel"
	50008: "Previous Active Channel"
	50009: "Next Unread Channel"
	50010: "Previous Unread Channel"
	50011: "Previous Selection"
	50012: "Move Forward"
	501: "Connect"
	502: "Disconnect"
	503: "Cancel Reconnect"
	504810: "Take Op (-o)"
	504811: "Take Halfop (-h)"
	504812: "Take Voice (-v)"
	504813: "All Modes Taken"
	504910: "Give Op (+o)"
	504911: "Give Halfop (+h)"
	504912: "Give Voice (+v)"
	504913: "All Modes Given"
	511: "Change Nickname…"
	519: "Channel List…"
	521: "Add Server…"
	522: "Duplicate Server"
	523: "Delete Server…"
	54092: "Enable Developer Mode"
	541: "Server Properties…"
	5421: "Query Logs"
	5422: "Channel" (Submenu)
	542: "Logs"
	549: "Copy"
	5675: "Connect to Help Channel"
	5676: "Connect to Testing Channel"
	589: "Main Window"
	590: "Address Book"
	591: "Ignore List"
	592: "Textual Logs"
	593: "Highlight List"
	601: "Join Channel"
	602: "Leave Channel"
	651: "Add Channel…"
	652: "Delete Channel"
	6666: "Mute Sound"
	6876: "Topic"
	6877: "Ban List"
	6878: "Ban Exceptions"
	6879: "Invite Exceptions"
	6880: "General Settings"
	6881: "Moderated (+m)"
	6882: "Unmoderated (-m)"
	6883: "Invite Only (+i)"
	6884: "Anyone Can Join (-i)"
	6885: "Manage All Modes"
	691: "Add Channel…"
	935: Menu Separator
	936: Menu Separator
	937: Menu Separator
	9631: "Close Window"
	990002: "Next Highlight"
	990003: "Previous Highlight"
    6666: "Mute Sound"
 */

@interface TXMenuController : NSObject
@property (nonatomic, strong) NSString *pointedUrl;
@property (nonatomic, strong) NSString *pointedNickname;
@property (nonatomic, strong) NSString *pointedChannelName;
@property (nonatomic, strong) NSString *currentSearchPhrase;
@property (nonatomic, assign) BOOL findPanelOpened;
@property (nonatomic, strong) NSDictionary *openWindowList;

@property (nonatomic, nweak) NSMenuItem *muteSound;

- (void)terminate;

- (NSArray *)selectedMembers:(NSMenuItem *)sender;
- (BOOL)checkSelectedMembers:(NSMenuItem *)item;
- (void)deselectMembers:(NSMenuItem *)sender;

- (BOOL)validateMenuItem:(NSMenuItem *)item;
- (BOOL)validateMenuItemTag:(NSInteger)tag forItem:(NSMenuItem *)item;

- (void)addWindowToWindowList:(id)window;
- (void)removeWindowFromWindowList:(NSString *)windowClass;

- (id)windowFromWindowList:(NSString *)windowClass;

- (BOOL)popWindowViewIfExists:(NSString *)windowClass;
- (void)popWindowSheetIfExists;

- (void)showPreferencesDialog:(id)sender;

- (void)paste:(id)sender;

- (void)searchGoogle:(id)sender;
- (void)closeWindow:(id)sender;
- (void)copyLogAsHtml:(id)sender;

- (void)toggleDeveloperMode:(id)sender;
- (void)loadExtensionsIntoMemory:(id)sender;
- (void)unloadExtensionsFromMemory:(id)sender;
- (void)resetDoNotAskMePopupWarnings:(id)sender;
- (void)openDefaultIRCClientDialog:(id)sender;

- (void)showHighlightSheet:(id)sender;

- (void)showServerPropertyDialog:(IRCClient *)u withDefaultView:(NSString *)viewType andContext:(NSString *)context;

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
- (void)memberStartPrivateMessage:(id)sender;
- (void)memberSendInvite:(id)sender;
- (void)memberSendCTCPPing:(id)sender;
- (void)memberSendCTCPTime:(id)sender;
- (void)memberSendCTCPVersion:(id)sender;
- (void)memberSendCTCPUserinfo:(id)sender;
- (void)memberSendCTCPClientInfo:(id)sender;
- (void)memberSendCTCPFinger:(id)sender;
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
- (void)resetWindowSize:(id)sender;
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
- (void)openMacAppStoreDownloadPage:(id)sender;
- (void)showContributors:(id)sender;
- (void)showAcknowledgments:(id)sender;
- (void)showScriptingDocumentation:(id)sender;
- (void)processNavigationItem:(id)sender;
- (void)toggleFullscreenMode:(id)sender;
- (void)centerMainWindow:(id)sender;

- (void)forceReloadTheme:(id)sender;

- (void)importPreferences:(id)sender;
- (void)exportPreferences:(id)sender;
@end
