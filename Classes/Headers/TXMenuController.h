/* ********************************************************************* 
       _____        _               _    ___ ____   ____
      |_   _|___  _| |_ _   _  __ _| |  |_ _|  _ \ / ___|
       | |/ _ \ \/ / __| | | |/ _` | |   | || |_) | |
       | |  __/>  <| |_| |_| | (_| | |   | ||  _ <| |___
       |_|\___/_/\_\\__|\__,_|\__,_|_|  |___|_| \_\\____|

 Copyright (c) 2008 - 2010 Satoshi Nakagawa <psychs AT limechat DOT net>
 Copyright (c) 2010 — 2014 Codeux Software & respective contributors.
     Please see Acknowledgements.pdf for additional information.

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
	50013: "Move Backward"
	52694: "Send file…"
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
	51065: "Toggle Visbility of Server List"
	51066: "Toggle Visbility of Member List"
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
	594: "File Transfers"
	601: "Join Channel"
	602: "Leave Channel"
	64611: "Channel List…"
	651: "Add Channel…"
	652: "Delete Channel"
	6666: "Disable All Notification Sounds"
	6667: "Disable All Notifications"
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
 */

@interface TXMenuController : NSObject
@property (nonatomic, strong) NSString *pointedUrl;
@property (nonatomic, strong) NSString *pointedNickname;
@property (nonatomic, strong) NSString *pointedChannelName;
@property (nonatomic, strong) NSString *currentSearchPhrase;
@property (nonatomic, strong) NSDictionary *openWindowList;
@property (nonatomic, nweak) IBOutlet NSMenu *navigationChannelList;
@property (nonatomic, strong) TDCFileTransferDialog *fileTransferController;

- (void)setupOtherServices;

- (void)preferencesChanged;

- (void)prepareForApplicationTermination;

- (NSArray *)selectedMembers:(NSMenuItem *)sender;
- (BOOL)checkSelectedMembers:(NSMenuItem *)item;
- (void)deselectMembers:(NSMenuItem *)sender;

- (BOOL)validateMenuItem:(NSMenuItem *)item;
- (BOOL)validateMenuItemTag:(NSInteger)tag forItem:(NSMenuItem *)item;

- (void)addWindowToWindowList:(id)window;
- (void)addWindowToWindowList:(id)window withKeyValue:(NSString *)key;

- (void)removeWindowFromWindowList:(NSString *)windowClass;

- (id)windowFromWindowList:(NSString *)windowClass;

- (BOOL)popWindowViewIfExists:(NSString *)windowClass;
- (void)popWindowSheetIfExists;

- (IBAction)showPreferencesDialog:(id)sender;

- (IBAction)paste:(id)sender;

- (IBAction)searchGoogle:(id)sender;

- (void)closeWindow:(id)sender;
- (void)copyLogAsHtml:(id)sender;

- (void)populateNavgiationChannelList;

- (IBAction)toggleDeveloperMode:(id)sender;
- (IBAction)resetDoNotAskMePopupWarnings:(id)sender;
- (IBAction)openDefaultIRCClientDialog:(id)sender;

- (IBAction)showHighlightSheet:(id)sender;

- (IBAction)showFileTransfersDialog:(id)sender;

- (void)showServerPropertyDialog:(IRCClient *)u withDefaultView:(NSString *)viewType andContext:(NSString *)context;

- (IBAction)markScrollback:(id)sender;
- (IBAction)clearScrollback:(id)sender;
- (IBAction)gotoScrollbackMarker:(id)sender;
- (IBAction)markAllAsRead:(id)sender;
- (IBAction)increaseLogFontSize:(id)sender;
- (IBAction)decreaseLogFontSize:(id)sender;

- (IBAction)connect:(id)sender;
- (IBAction)disconnect:(id)sender;
- (IBAction)cancelReconnection:(id)sender;
- (IBAction)showNicknameChangeDialog:(id)sender;
- (IBAction)showServerChannelList:(id)sender;
- (IBAction)addServer:(id)sender;
- (IBAction)copyServer:(id)sender;
- (IBAction)deleteServer:(id)sender;
- (IBAction)showServerPropertiesDialog:(id)sender;

- (IBAction)onNextHighlight:(id)sender;
- (IBAction)onPreviousHighlight:(id)sender;

- (IBAction)joinChannel:(id)sender;
- (IBAction)leaveChannel:(id)sender;
- (IBAction)showChannelTopicDialog:(id)sender;
- (IBAction)showChannelModeDialog:(id)sender;
- (IBAction)addChannel:(id)sender;
- (IBAction)deleteChannel:(id)sender;
- (IBAction)showChannelPropertiesDialog:(id)sender;

- (void)memberListDoubleClicked:(id)sender;

- (IBAction)memberSendWhois:(id)sender;
- (IBAction)memberStartPrivateMessage:(id)sender;
- (IBAction)memberSendInvite:(id)sender;
- (IBAction)memberSendCTCPPing:(id)sender;
- (IBAction)memberSendCTCPTime:(id)sender;
- (IBAction)memberSendCTCPVersion:(id)sender;
- (IBAction)memberSendCTCPUserinfo:(id)sender;
- (IBAction)memberSendCTCPClientInfo:(id)sender;
- (IBAction)memberSendCTCPFinger:(id)sender;
- (IBAction)memberSendFileRequest:(id)sender;
- (IBAction)memberModeChangeOp:(id)sender;
- (IBAction)memberModeChangeDeop:(id)sender;
- (IBAction)memberModeChangeHalfop:(id)sender;
- (IBAction)memberModeChangeDehalfop:(id)sender;
- (IBAction)memberModeChangeVoice:(id)sender;
- (IBAction)memberModeChangeDevoice:(id)sender;
- (IBAction)memberKickFromChannel:(id)sender;
- (IBAction)memberBanFromServer:(id)sender;
- (IBAction)memberKickbanFromChannel:(id)sender;
- (IBAction)memberKillFromServer:(id)sender;
- (IBAction)memberGlineFromServer:(id)sender;
- (IBAction)memberShunFromServer:(id)sender;

- (void)memberSendDroppedFiles:(NSArray *)files row:(NSNumber *)row;

- (IBAction)copyUrl:(id)sender;

- (IBAction)joinClickedChannel:(id)sender;

- (IBAction)toggleChannelModerationMode:(id)sender;
- (IBAction)toggleChannelInviteMode:(id)sender;

- (IBAction)sortChannelListNames:(id)sender;
- (IBAction)resetWindowSize:(id)sender;
- (IBAction)showMainWindow:(id)sender;
- (IBAction)showChannelIgnoreList:(id)sender;
- (IBAction)showAboutWindow:(id)sender;
- (IBAction)openLogLocation:(id)sender;
- (IBAction)openChannelLogs:(id)sender;
- (IBAction)connectToTextualHelpChannel:(id)sender;
- (IBAction)connectToTextualTestingChannel:(id)sender;
- (IBAction)showSetVhostPrompt:(id)sender;
- (IBAction)showFindPanel:(id)sender;
- (IBAction)showChannelBanList:(id)sender;
- (IBAction)showChannelBanExceptionList:(id)sender;
- (IBAction)showChannelInviteExceptionList:(id)sender;

- (void)openMacAppStoreDownloadPage:(id)sender;

- (IBAction)commandWShortcutUsed:(id)sender;
- (IBAction)openHelpMenuLinkItem:(id)sender;
- (IBAction)showAcknowledgments:(id)sender;
- (IBAction)showScriptingDocumentation:(id)sender;
- (IBAction)processNavigationItem:(id)sender;
- (IBAction)centerMainWindow:(id)sender;

- (void)forceReloadTheme:(id)sender;

- (IBAction)importPreferences:(id)sender;
- (IBAction)exportPreferences:(id)sender;

- (IBAction)toggleServerListVisibility:(id)sender;
- (IBAction)toggleMemberListVisibility:(id)sender;

- (IBAction)toggleMuteOnNotificationSounds:(id)sender;
- (IBAction)toggleMuteOnAllNotifcations:(id)sender;

- (void)toggleMuteOnAllNotifcationsShortcut:(NSInteger)state;
- (void)toggleMuteOnNotificationSoundsShortcut:(NSInteger)state;
@end
