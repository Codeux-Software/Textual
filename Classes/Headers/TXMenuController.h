/* ********************************************************************* 
                  _____         _               _
                 |_   _|____  _| |_ _   _  __ _| |
                   | |/ _ \ \/ / __| | | |/ _` | |
                   | |  __/>  <| |_| |_| | (_| | |
                   |_|\___/_/\_\\__|\__,_|\__,_|_|

 Copyright (c) 2008 - 2010 Satoshi Nakagawa <psychs AT limechat DOT net>
 Copyright (c) 2010 - 2015 Codeux Software, LLC & respective contributors.
        Please see Acknowledgements.pdf for additional information.

 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions
 are met:

    * Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the
      documentation and/or other materials provided with the distribution.
    * Neither the name of Textual and/or "Codeux Software, LLC", nor the 
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

NS_ASSUME_NONNULL_BEGIN

@class IRCClient, IRCChannel, IRCChannelUser;

/*
	Tag Reference:

	The following tags apply to the main menu:

	001: "Textual"
	002: "File"
	003: "Edit"
	004: "View"
	005: "Server"
	006: "Channel"
	007: "Navigate"
	008: "Window"
	009: "Help"

	100: "About Textual"
	101: "Preferences…"
	102: "Manage license…"
	110: "In-app Purchase…"
	103: "Updates"
	109: "Check for updates…"
	104: "Services"
	105: "Hide Textual"
	106: "Hide Others"
	107: "Show All"
	108: "Quit Textual & IRC"

	200: "Disable All Notifications"
	201: "Disable All Notification Sounds"
	202: "Print"
	203: "Close Window"

	300: "Undo"
	301: "Redo"
	302: "Cut"
	303: "Copy"
	304: "Paste"
	305: "Delete"
	306: "Select All"
	307: "Find"
	308: "Find…"
	309: "Find Next"
	310: "Find Previous"
	311: "Spelling"
	312: "Spelling…"
	313: "Check Spelling"
	314: "Check Spelling as You Type"

	400: "Mark Scrollback"
	401: "Scrollback Marker"
	402: "Mark All as Read"
	403: "Clear Scrollback"
	405: "Increase Font Size"
	406: "Decrease Font Size"
	407: "Toggle Fullscreen"

	500: "Connect"
	510: "Connect Without Proxy"
	501: "Disconnect"
	502: "Cancel Reconnect"
	503: "Channel List…"
	504: "Change Nickname…"
	505: "Add Server…"
	506: "Duplicate Server"
	507: "Delete Server…"
	508: "Add Channel…"
	509: "Server Properties…"

	600: "Join Channel"
	601: "Leave Channel"
	602: "-"
	603: "Add Channel…"
	604: "Delete Channel"
	605: "-"
	606: "Query Logs"
	607: "Channel Properties"
	608: "View Logs"
	609: "Modify Topic"
	610: "Modes"
	611: "Moderated (+m)"
	612: "Unmoderated (-m)"
	613: "Invite Only (+i)"
	614: "Anyone Can Join (-i)"
	615: "Manage All Modes"
	616: "List of Bans"
	617: "List of Ban Exceptions"
	618: "List of Invite Exceptions"
	620: "List of Quiets"
	619: "Channel Properties"
	621: "-"
	622: "Copy Unique Identifier"

	700: "Servers"
	701: "Next Server"
	702: "Previous Server"
	703: "Next Active Server"
	704: "Previous Active Server"
	705: "Channels"
	706: "Next Channel"
	707: "Previous Channel"
	708: "Next Active Channel"
	709: "Previous Active Channel"
	710: "Next Unread Channel"
	711: "Previous Unread Channel"
	712: "Move Backward"
	713: "Move Forward"
	714: "Previous Selection"
	715: "Next Highlight"
	716: "Previous Highlight"
	717: "Channel List…"
	718: "Search channels…"
	719: "Jump to Current Session"
	720: "Jump to Present"

	800: "Minimize"
	801: "Zoom"
	815: "-"
	802: "Toggle Visiblity of Member List"
	803: "Toggle Visiblity of Server List"
	804: "Toggle Window Appearance"
	816: "-"
	805: "Sort Channel List"
	817: "-"
	806: "Center Main Window"
	807: "Reset Window to Default Size"
	818: "-"
	808: "Main Window"
	809: "Address Book"
	810: "Ignore List"
	811: "View Logs"
	812: "Highlight List"
	813: "File Transfers"
	815: "Buddy List"
	819: "-"
	814: "Bring All to Front"

	900: "Acknowledgements"
	901: "End User License Agreement"
	902: "Privacy Policy"
	903: "Connect to Help Channel"
	904: "Connect to Testing Channel"
	930: "Frequently Asked Questions"
	931: "Introduction to Writing Scripts"
	932: "Other Helpful Resources"
	933: "Knowledge Base Home"
	934: "Using iCloud with Textual"
	935: "Chat Encryption"
	936: "Command Reference"
	937: "Feature Requests"
	938: "Keyboard Shortcuts"
	939: "Memory Management"
	940: "Text Formatting"
	941: "Styling Information"
	942: "Connecting with Certificate"
	943: "Connecting to a ZNC Bouncer"
	944: "DCC File Transfer Information"
	960: "Advanced"
	961: "Enable Developer Mode"
	962: "Hidden Preferences"
	963: "Export Preferences"
	964: "Import Preferences"
	965: "Reset 'Don't Ask Me' Warnings"

	The following tags apply to the "Join Channel" menu:
	1000: "Join Channel"

	The following tags apply to the "Open URL" menu:
	1100: "Copy URL"

	The following tags apply to the "Segmented Controller" menu:
	1200: "Add Server…"
	1201: "Add Channel…"

	The following tags apply to the "Add Server" menu:
	1300: "Add Server…"

	The following tags apply to the "Encryption Manager" menu:
	1400: "What is this?"
	1401: "Start Private Conversation"
	1402: "Refresh Private Conversation"
	1403: "End Private Conversation"
	1404: "Authenticate Chat Partner"
	1405: "View List of Fingerprints"

	The following tags apply to the "User Control" menu:
	1532: "Add Ignore"
	1533: "Modify Ignore"
	1534: "Remove Ignore"
	1535: "-"
	1500: "Invite to…"
	1527: "-"
	1501: "Get Info (Whois)"
	1502: "Private Message (Query)"
	1528: "-"
	1503: "Give Op (+o)"
	1504: "Give Halfop (+h)"
	1505: "Give Voice (+v)"
	1506: "All Modes Given"
	1529: "-"
	1507: "Take Op (-o)"
	1508: "Take Halfop (-h)"
	1509: "Take Voice (-v)"
	1510: "All Modes Taken"
	1530: "-"
	1511: "Ban"
	1512: "Kick"
	1513: "Ban and Kick"
	1531: "-"
	1514: "Client-to-Client"
	1515: "Send file…"
	1516: "Lag (PING)"
	1517: "Local Time (TIME)"
	1518: "Client Version (VERSION)"
	1519: "Client Information (CLIENTINFO)"
	1520: "User Information (FINGER)"
	1521: "User Information (USERINFO)"
	1522: "IRC Operator"
	1523: "Set Virtual Host (vHost)"
	1524: "Kill from Server"
	1525: "Shun on Server"
	1526: "Ban from Server (G:Line)"

	The following tags apply to the "Channel View" menu:
	1600: "Change Nickname…"
	1601: "Search With Google"
	1602: "Look Up In Dictionary"
	1603: "Copy"
	1604: "Paste"
	1605: "-"
	1606: "Query Logs"
	1607: "Channel"

	The following tags apply to the "Dock" menu:
	1700: "Disable All Notifications"
	1701: "Disable All Notification Sounds"
 */

@interface TXMenuController : NSObject
@property (readonly, strong) NSMenu *channelViewChannelNameMenu;
@property (readonly, strong) NSMenu *channelViewDefaultMenu;
@property (readonly, strong) NSMenu *channelViewURLMenu;

@property (readonly, strong) NSMenu *dockMenu;

#if TEXTUAL_BUILT_WITH_ADVANCED_ENCRYPTION == 1
@property (readonly,strong) NSMenu *encryptionManagerStatusMenu;
#endif

@property (readonly, weak) NSMenu *mainMenuNavigationChannelListMenu;
@property (readonly, weak) NSMenuItem *mainMenuCloseWindowMenuItem;
@property (readonly, weak) NSMenuItem *mainMenuChannelMenuItem;
@property (readonly, weak) NSMenuItem *mainMenuServerMenuItem;

@property (readonly, strong) NSMenu *mainWindowSegmentedControllerCell0Menu;

@property (readonly, strong) NSMenu *serverListNoSelectionMenu;

@property (readonly, strong) NSMenu *userControlMenu;

@property (readonly, weak) NSMenuItem *muteNotificationsDockMenuItem;
@property (readonly, weak) NSMenuItem *muteNotificationsFileMenuItem;
@property (readonly, weak) NSMenuItem *muteNotificationsSoundsDockMenuItem;
@property (readonly, weak) NSMenuItem *muteNotificationsSoundsFileMenuItem;

@property (readonly, weak) IRCClient *selectedClient;
@property (readonly, weak) IRCChannel *selectedChannel;

- (NSArray<IRCChannelUser *> *)selectedMembers:(id)sender;
- (NSArray<NSString *> *)selectedMembersNicknames:(id)sender;
- (void)deselectMembers:(id)sender;

- (IBAction)copy:(id)sender;
- (IBAction)paste:(id)sender;

- (IBAction)print:(id)sender;

- (IBAction)closeWindow:(id)sender;

- (IBAction)contactSupport:(id)sender;

- (IBAction)addChannel:(id)sender;
- (IBAction)deleteChannel:(id)sender;

- (IBAction)addServer:(id)sender;
- (IBAction)duplicateServer:(id)sender;
- (IBAction)deleteServer:(id)sender;

- (IBAction)joinChannel:(id)sender;
- (IBAction)leaveChannel:(id)sender;

- (IBAction)connect:(id)sender;
- (IBAction)connectBypassingProxy:(id)sender;

- (IBAction)connectToTextualHelpChannel:(id)sender;
- (IBAction)connectToTextualTestingChannel:(id)sender;

- (IBAction)disconnect:(id)sender;
- (IBAction)cancelReconnection:(id)sender;

- (IBAction)clearScrollback:(id)sender;

- (IBAction)markAllAsRead:(id)sender;

- (IBAction)decreaseLogFontSize:(id)sender;
- (IBAction)increaseLogFontSize:(id)sender;

- (IBAction)jumpToCurrentSession:(id)sender;
- (IBAction)jumpToPresent:(id)sender;

- (IBAction)gotoScrollbackMarker:(id)sender;
- (IBAction)markScrollback:(id)sender;

- (IBAction)exportPreferences:(id)sender;
- (IBAction)importPreferences:(id)sender;

- (IBAction)memberAddIgnore:(id)sender;
- (IBAction)memberModifyIgnore:(id)sender;
- (IBAction)memberRemoveIgnore:(id)sender;

- (IBAction)memberBanFromChannel:(id)sender;
- (IBAction)memberKickFromChannel:(id)sender;
- (IBAction)memberKickbanFromChannel:(id)sender;

- (IBAction)memberModeGiveHalfop:(id)sender;
- (IBAction)memberModeGiveOp:(id)sender;
- (IBAction)memberModeGiveVoice:(id)sender;
- (IBAction)memberModeTakeHalfop:(id)sender;
- (IBAction)memberModeTakeOp:(id)sender;
- (IBAction)memberModeTakeVoice:(id)sender;

- (IBAction)memberSendCTCPClientInfo:(id)sender;
- (IBAction)memberSendCTCPFinger:(id)sender;
- (IBAction)memberSendCTCPPing:(id)sender;
- (IBAction)memberSendCTCPTime:(id)sender;
- (IBAction)memberSendCTCPUserinfo:(id)sender;
- (IBAction)memberSendCTCPVersion:(id)sender;

- (IBAction)memberSendFileRequest:(id)sender;

- (IBAction)memberSendInvite:(id)sender;
- (IBAction)memberSendWhois:(id)sender;

- (IBAction)memberBanFromServer:(id)sender;
- (IBAction)memberKillFromServer:(id)sender;
- (IBAction)memberShunOnServer:(id)sender;

- (IBAction)memberStartPrivateMessage:(id)sender;

- (IBAction)onNextHighlight:(id)sender;
- (IBAction)onPreviousHighlight:(id)sender;

- (IBAction)openStandaloneStoreWebpage:(id)sender;
- (IBAction)openMacAppStoreWebpage:(id)sender;

- (IBAction)openChannelLogs:(id)sender;
- (IBAction)openLogLocation:(id)sender;

- (IBAction)centerMainWindow:(id)sender;
- (IBAction)resetMainWindowFrame:(id)sender;

- (IBAction)showAcknowledgements:(id)sender;
- (IBAction)showScriptingDocumentation:(id)sender;

- (IBAction)showAboutWindow:(id)sender;
- (IBAction)showAddressBook:(id)sender;
- (IBAction)showBuddyListWindow:(id)sender;
- (IBAction)showChannelBanExceptionList:(id)sender;
- (IBAction)showChannelBanList:(id)sender;
- (IBAction)showChannelInviteExceptionList:(id)sender;
- (IBAction)showChannelQuietList:(id)sender;
- (IBAction)showChannelModifyModesSheet:(id)sender;
- (IBAction)showChannelModifyTopicSheet:(id)sender;
- (IBAction)showChannelPropertiesSheet:(id)sender;
- (IBAction)showChannelSpotlightWindow:(id)sender NS_AVAILABLE_MAC(10_10);
- (IBAction)showFileTransfersWindow:(id)sender;
- (IBAction)showFindPrompt:(id)sender;
- (IBAction)showHiddenPreferences:(id)sender;
- (IBAction)showIgnoreList:(id)sender;
- (IBAction)showMainWindow:(id)sender;
- (IBAction)showPreferencesWindow:(id)sender;
- (IBAction)showServerChangeNicknameSheet:(id)sender;
- (IBAction)showServerChannelList:(id)sender;
- (IBAction)showServerHighlightList:(id)sender;
- (IBAction)showServerPropertiesSheet:(id)sender;
- (IBAction)showSetVhostPrompt:(id)sender;
- (IBAction)showStylePreferences:(id)sender;
- (IBAction)showWelcomeSheet:(id)sender;

- (IBAction)sortChannelListNames:(id)sender;

- (IBAction)toggleChannelInviteMode:(id)sender;
- (IBAction)toggleChannelModerationMode:(id)sender;

- (IBAction)toggleFullscreen:(id)sender;

- (IBAction)toggleMainWindowAppearance:(id)sender;

- (IBAction)toggleDeveloperMode:(id)sender;

- (IBAction)toggleServerListVisibility:(id)sender;
- (IBAction)toggleMemberListVisibility:(id)sender;

- (IBAction)toggleMuteOnNotifications:(id)sender;
- (IBAction)toggleMuteOnNotificationSounds:(id)sender;

- (IBAction)manageLicense:(id)sender;
- (IBAction)manageInAppPurchase:(id)sender;

- (IBAction)simulateCrash:(id)sender;

#if TEXTUAL_BUILT_WITH_ADVANCED_ENCRYPTION == 1
- (IBAction)encryptionWhatIsThisInformation:(id)sender;
- (IBAction)encryptionStartPrivateConversation:(id)sender;
- (IBAction)encryptionRefreshPrivateConversation:(id)sender;
- (IBAction)encryptionEndPrivateConversation:(id)sender;
- (IBAction)encryptionAuthenticateChatPartner:(id)sender;
- (IBAction)encryptionListFingerprints:(id)sender;
#endif

- (IBAction)copyUniqueIdentifier:(id)sender;

- (IBAction)copyUrl:(id)sender;

- (IBAction)lookUpInDictionary:(id)sender;
- (IBAction)searchGoogle:(id)sender;
- (IBAction)copyLogAsHtml:(id)sender;
- (IBAction)forceReloadTheme:(id)sender;
- (IBAction)openWebInspector:(id)sender;

- (IBAction)checkForUpdates:(id)sender;

- (IBAction)resetDoNotAskMePopupWarnings:(id)sender;
@end

NS_ASSUME_NONNULL_END
