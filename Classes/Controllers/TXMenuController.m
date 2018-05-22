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

#import "NSObjectHelperPrivate.h"
#import "IRCClientConfig.h"
#import "IRCClientPrivate.h"
#import "IRCChannelPrivate.h"
#import "IRCChannelMode.h"
#import "IRCChannelUser.h"
#import "IRCExtrasPrivate.h"
#import "IRCISupportInfo.h"
#import "IRCUser.h"
#import "IRCWorldPrivate.h"
#import "IRCWorldPrivateCloudExtension.h"
#import "TVCBasicTableView.h"
#import "TVCLogController.h"
#import "TVCLogViewPrivate.h"
#import "TVCLogViewInternalWK2.h"
#import "TVCMemberList.h"
#import "TVCMainWindowPrivate.h"
#import "TVCMainWindowSplitView.h"
#import "TVCMainWindowTextView.h"
#import "TLOAppStoreManagerPrivate.h"
#import "TLOEncryptionManagerPrivate.h"
#import "TLOLanguagePreferences.h"
#import "TLOLicenseManagerPrivate.h"
#import "TLOpenLink.h"
#import "TDCAboutDialogPrivate.h"
#import "TDCAlert.h"
#import "TDCInAppPurchaseDialogPrivate.h"
#import "TDCChannelInviteSheetPrivate.h"
#import "TDCChannelModifyModesSheetPrivate.h"
#import "TDCChannelModifyTopicSheetPrivate.h"
#import "TDCChannelPropertiesSheetPrivate.h"
#import "TDCChannelSpotlightControllerPrivate.h"
#import "TDCFileTransferDialogPrivate.h"
#import "TDCInputPrompt.h"
#import "TDCLicenseManagerDialogPrivate.h"
#import "TDCNicknameColorSheetPrivate.h"
#import "TDCPreferencesControllerPrivate.h"
#import "TDCServerChangeNicknameSheetPrivate.h"
#import "TDCServerHighlightListSheetPrivate.h"
#import "TDCServerPropertiesSheetPrivate.h"
#import "TDCWelcomeSheetPrivate.h"
#import "TPCPathInfoPrivate.h"
#import "TPCPreferencesCloudSyncExtension.h"
#import "TPCPreferencesImportExport.h"
#import "TPCPreferencesLocalPrivate.h"
#import "TPCPreferencesReload.h"
#import "TPCPreferencesUserDefaults.h"
#import "TXMasterControllerPrivate.h"
#import "TXWindowControllerPrivate.h"
#import "TXMenuControllerPrivate.h"

#if TEXTUAL_BUILT_WITH_HOCKEYAPP_SDK_ENABLED == 1
#import <HockeySDK/HockeySDK.h>
#endif

#if TEXTUAL_BUILT_WITH_SPARKLE_ENABLED == 1
#import <Sparkle/Sparkle.h>
#endif

NS_ASSUME_NONNULL_BEGIN

#define _channelIsActive			(c && [c isActive])
#define _channelIsntActive			(c && [c isActive] == NO)
#define _clientIsConnected			(u && [u isConnected])
#define _clientIsntConnected		(u && [u isConnected] == NO && [u isConnecting] == NO)
#define _clientIsLoggedIn			(u && [u isConnected] && [u isLoggedIn])
#define _clientIsntLoggedIn			(u && [u isConnected] == NO && [u isLoggedIn] == NO)
#define _isClient					(u && c == nil)
#define _isChannel					(c && [c isChannel])
#define _isQuery					(c && [c isPrivateMessage])
#define _isChannelOrQuery			(_isChannel || _isQuery)
#define _isUtility					(c && [c isUtility])
#define _noChannel					(c == nil)
#define _noClient					(u == nil)
#define _noClientOrChannel			(u == nil || c == nil)

#define	_popWindowViewIfExists(c)	if ([windowController() maybeBringWindowForward:(c)]) {		\
										return;													\
									}

@interface TXMenuController ()
@property (nonatomic, assign) BOOL menuIsOpen;
@property (nonatomic, assign) BOOL menuPerformedActionLastOpen;
@property (nonatomic, weak) IRCClient *pointedClient;
@property (nonatomic, weak) IRCChannel *pointedChannel;
@property (nonatomic, copy) NSString *currentSearchPhrase;
@property (readonly, nullable) TVCLogController *selectedViewController;
@property (readonly, nullable) TVCLogView *selectedViewControllerBackingView;
@property (readonly) TDCFileTransferDialog *fileTransferController;
@property (nonatomic, strong, readwrite) IBOutlet NSMenu *channelViewChannelNameMenu;
@property (nonatomic, strong, readwrite) IBOutlet NSMenu *channelViewDefaultMenu;
@property (nonatomic, strong, readwrite) IBOutlet NSMenu *channelViewURLMenu;
@property (nonatomic, strong, readwrite) IBOutlet NSMenu *dockMenu;

#if TEXTUAL_BUILT_WITH_ADVANCED_ENCRYPTION == 1
@property (nonatomic, strong, readwrite) IBOutlet NSMenu *encryptionManagerStatusMenu;
#endif

@property (nonatomic, weak, readwrite) IBOutlet NSMenu *mainMenuNavigationChannelListMenu;
@property (nonatomic, weak, readwrite) IBOutlet NSMenuItem *mainMenuCloseWindowMenuItem;
@property (nonatomic, weak, readwrite) IBOutlet NSMenuItem *mainMenuChannelMenuItem;
@property (nonatomic, weak, readwrite) IBOutlet NSMenuItem *mainMenuServerMenuItem;
@property (nonatomic, weak, readwrite) IBOutlet NSMenuItem *mainMenuWindowMenuItem;
@property (nonatomic, strong, readwrite) IBOutlet NSMenu *mainWindowSegmentedControllerCell0Menu;
@property (nonatomic, strong, readwrite) IBOutlet NSMenu *serverListNoSelectionMenu;
@property (nonatomic, strong, readwrite) IBOutlet NSMenu *userControlMenu;
@property (nonatomic, weak, readwrite) IBOutlet NSMenuItem *muteNotificationsDockMenuItem;
@property (nonatomic, weak, readwrite) IBOutlet NSMenuItem *muteNotificationsFileMenuItem;
@property (nonatomic, weak, readwrite) IBOutlet NSMenuItem *muteNotificationsSoundsDockMenuItem;
@property (nonatomic, weak, readwrite) IBOutlet NSMenuItem *muteNotificationsSoundsFileMenuItem;
@end

@implementation TXMenuController

- (void)prepareInitialState
{
	self.currentSearchPhrase = @"";

	if ([TPCPreferences soundIsMuted]) {
		self.muteNotificationsSoundsDockMenuItem.state = NSOnState;
		self.muteNotificationsSoundsFileMenuItem.state = NSOnState;
	}

	[self setupOtherServices];

	[RZNotificationCenter() addObserver:self selector:@selector(menuItemWillPerformedAction:) name:NSMenuWillSendActionNotification object:nil];
	[RZNotificationCenter() addObserver:self selector:@selector(menuItemPerformedAction:) name:NSMenuDidSendActionNotification object:nil];
}

- (void)setupOtherServices
{
	[self.fileTransferController startUsingDownloadDestinationURL];
}

- (void)prepareForApplicationTermination
{
	[self.fileTransferController prepareForApplicationTermination];
}

- (void)preferencesChanged
{
	[self.fileTransferController clearIPAddress];
}

- (void)mainWindowSelectionDidChange
{
	if (self.menuIsOpen == NO) {
		[self resetSelectedItems];
	}

	/* When the selection changes, menus that may be dynamic are force
	 revalidated so that Command I (or other shortcuts) work with channel
	 selected, but not for the server console. */
	[self forceAllChildrenElementsOfMenuToValidate:self.mainMenuChannelMenuItem.menu recursively:YES];
	[self forceAllChildrenElementsOfMenuToValidate:self.mainMenuServerMenuItem.menu recursively:YES];
}

- (void)forceAllChildrenElementsOfMenuToValidate:(NSMenu *)menu
{
	[self forceAllChildrenElementsOfMenuToValidate:menu recursively:YES];
}

- (void)forceAllChildrenElementsOfMenuToValidate:(NSMenu *)menu recursively:(BOOL)recursively
{
	NSParameterAssert(menu != nil);

	for (NSMenuItem *menuItem in menu.itemArray) {
		id target = menuItem.target;

		if ([target respondsToSelector:@selector(validateMenuItem:)]) {
			(void)[target performSelector:@selector(validateMenuItem:) withObject:menuItem];
		}

		if (recursively) {
			if (menuItem.hasSubmenu == NO) {
				continue;
			}

			[self forceAllChildrenElementsOfMenuToValidate:menuItem.submenu];
		}
	}
}

- (BOOL)validateMenuItem:(NSMenuItem *)menuItem
{
	return [self validateMenuItem:menuItem withTag:menuItem.tag];
}

- (BOOL)validateMenuItem:(NSMenuItem *)menuItem withTag:(NSUInteger)tag
{
	NSParameterAssert(menuItem != nil);

	if (masterController().applicationIsTerminating) {
		return NO;
	}

#if TEXTUAL_BUILT_FOR_APP_STORE_DISTRIBUTION == 1
	BOOL appFinishedLaunching = masterController().applicationIsLaunched;
#endif

	BOOL isMainWindowMain = mainWindow().mainWindow;
	BOOL isMainWindowDisabled = mainWindow().disabled;
	BOOL mainWindowHasSheet = (mainWindow().attachedSheet != nil);
	BOOL frontmostWindowIsMainWindow = mainWindow().isBeneathMouse;

	BOOL returnValue = [self validateSpecificMenuItem:menuItem withTag:tag];

	switch (tag)
	{
		/* 100 through 999 matches all main menu, menu items.
		See TXMenuController.h for list of valid tags. */
		case 100 ... 999:
		case 1700 ... 1799:
		{
			/* Menu items part of the Window menu that should
			 be hidden under certain conditions. */
			if (tag >= 800 && tag <= 899) {
				switch (tag) {
					case 802: // "Toggle Visiblity of Member List"
					case 803: // "Toggle Visiblity of Server List"
					case 804: // "Toggle Window Appearance"
					case 805: // "Sort Channel List"
					case 806: // "Center Main Window"
					case 807: // "Reset Window to Default Size"
					case 808: // "Main Window"
					case 809: // "Address Book"
					case 810: // "Ignore List"
					case 812: // "Highlight List"
					{
						/* Modify separator items for the first item in switch. */
						if (tag == 802) {
							if (isMainWindowMain == NO) {
								menuItem.hidden = YES;

								[menuItem.menu itemWithTag:816].hidden = YES; // Menu Separator
								[menuItem.menu itemWithTag:817].hidden = YES; // Menu Separator
								[menuItem.menu itemWithTag:818].hidden = YES; // Menu Separator
							} else {
								menuItem.hidden = NO;

								[menuItem.menu itemWithTag:816].hidden = NO; // Menu Separator
								[menuItem.menu itemWithTag:817].hidden = NO; // Menu Separator
								[menuItem.menu itemWithTag:818].hidden = NO; // Menu Separator
							}
						}

						/* Hide "Main Window" if Main Window is key. */
						/* Hide all other items when Main Window is NOT key. */
						if (tag == 808) { // "Main Window"
							menuItem.enabled = (isMainWindowDisabled == NO);

							menuItem.hidden = isMainWindowMain;
						}
						else // tag == 808
						{
							menuItem.hidden = (isMainWindowMain == NO);
						}
					}
				} // switch
			} // if 800 <> 899

			/* When the main window is not the focused window or when we are
			 in a sheet, most items can be disabled which means at this point
			 we will default to disabled and allow the bottom logic to enable
			 only the bare essentials. */
			BOOL defaultToNoForSheet = (mainWindowHasSheet || (frontmostWindowIsMainWindow == NO && isMainWindowMain == NO));

			if (defaultToNoForSheet) {
				if (tag < 900) { // Do not disable "Help" menu
					returnValue = NO;
				}
			}

			/* If trial is expired, or app has not finished launching,
			 then default everything to disabled. */
			BOOL isTrialExpired = NO;

#if TEXTUAL_BUILT_WITH_LICENSE_MANAGER == 1 || TEXTUAL_BUILT_FOR_APP_STORE_DISTRIBUTION == 1
			if (

#if TEXTUAL_BUILT_WITH_LICENSE_MANAGER == 1
				(TLOLicenseManagerTextualIsRegistered() == NO && TLOLicenseManagerIsTrialExpired())
#elif TEXTUAL_BUILT_FOR_APP_STORE_DISTRIBUTION == 1
				appFinishedLaunching == NO
#endif

				)
			{
				/* Disable everything by default except for items that are considred
				 helpful. See TXMenuController.h for complete list of tags. */
				if (tag < 900 ||
					(tag >= 900 && tag <= 902) ||
					(tag >= 960 && tag <= 965))
				{
					returnValue = NO;
				}

				/* Enable specific items after it has been disabled. */
				/* Other always-required items are enabled further 
				 below this switch statement. */
				if (

#if TEXTUAL_BUILT_WITH_LICENSE_MANAGER == 1
					tag == 102 // "Manage license…"
#elif TEXTUAL_BUILT_FOR_APP_STORE_DISTRIBUTION == 1
					tag == 110 // "In-app Purchase…"
#endif

					)
				{
					menuItem.hidden = NO;

					returnValue = YES;
				}

				isTrialExpired = YES;
			}
#endif

			/* If certain items are hidden because of sheet but not because of
			 the trial being expired, then enable additional items. */
			if (returnValue == NO && defaultToNoForSheet && isTrialExpired == NO) {
				switch (tag) {
					case 100: // "About Textual"
					case 101: // "Preferences…"
					case 102: // "Manage license…"
					case 110: // "In-app Purchase…"
					case 109: // "Check for updates…"
					{
						returnValue = YES;
					}
				}
			}

			/* These are the bare minimium of menu items that must be enabled
			 at all times because they are essential to the entire application. */
			if (returnValue == NO && menuItem.enabled) {
				switch (tag) {
					case 100: // "About Textual"
					case 104: // "Services"
					case 105: // "Hide Textual"
					case 106: // "Hide Others"
					case 107: // "Show All"
					case 108: // "Quit Textual & IRC"
					case 202: // "Print"
					case 203: // "Close Window"
					case 300: // "Undo"
					case 301: // "Redo"
					case 302: // "Cut"
					case 303: // "Copy"
					case 304: // "Paste"
					case 305: // "Delete"
					case 306: // "Select All"
					case 311: // "Spelling"
					case 312: // "Spelling…"
					case 313: // "Check Spelling"
					case 314: // "Check Spelling as You Type"
					case 407: // "Toggle Fullscreen"
					case 800: // "Minimize"
					case 801: // "Zoom"
					case 808: // "Main Window"
					case 814: // "Bring All to Front"
					case 963: // "Export Preferences"
					{
						returnValue = YES;
					} // case
				} // switch
			} // if returnValue == NO
		} // case 100 ... 999
	} // switch

	return returnValue;
}

- (BOOL)validateSpecificMenuItem:(NSMenuItem *)menuItem withTag:(NSUInteger)tag
{
	NSParameterAssert(menuItem != nil);

	IRCClient *u = mainWindow().selectedClient;
	IRCChannel *c = mainWindow().selectedChannel;

	/* Disable the entire user action menu for utility windows */
	if (tag >= 1500 && tag <= 1599 && _isUtility) {
		return NO;
	}

	switch (tag) {
		case 109: // "Check for Updates"
		{
#if TEXTUAL_BUILT_WITH_SPARKLE_ENABLED == 0
			menuItem.hidden = YES;
#endif

			return YES;
		}
		case 815: // "Buddy List"
		{
#ifdef TEXTUAL_BUILT_WITH_BUDDY_LIST_WINDOW
			menuItem.hidden = (TEXTUAL_RUNNING_ON(10.10, Yosemite) == NO);
#else 
			menuItem.hidden = YES;
#endif

			return YES;
		}
		case 609: // "Modify Topic"
		case 611: // "Moderated (+m)"
		case 612: // "Unmoderated (-m)"
		case 613: // "Invite Only (+i)"
		case 614: // "Anyone Can Join (-i)"
		case 615: // "Manage All Modes"
		case 616: // "List of Bans"
		case 617: // "List of Ban Exceptions"
		case 618: // "List of Invite Exceptions"
		case 620: // "List of Quiets"
		{
			BOOL condition = _clientIsLoggedIn;

			if (tag == 620) {
				/* +q is used by some servers as the user mode for channel owner. 
				 If this mode is a user mode, then hide the menu item. */
				menuItem.hidden = [u.supportInfo modeSymbolIsUserPrefix:@"q"];
			}

			return condition;
		}
		case 718: // "Search channels…"
		{
			menuItem.hidden = (TEXTUAL_RUNNING_ON(10.10, Yosemite) == NO);

			return YES;
		}
		case 102: // "Manage license…"
		{
#if TEXTUAL_BUILT_WITH_LICENSE_MANAGER == 0
			menuItem.hidden = YES;
#endif

			return YES;
		}
		case 110: // "In-app Purchase…"
		{
#if TEXTUAL_BUILT_FOR_APP_STORE_DISTRIBUTION == 0
			menuItem.hidden = YES;
#endif

			return YES;
		}
		case 965: // "Reset 'Don't Ask Me' Warnings"
		{
			BOOL condition = [TPCPreferences developerModeEnabled];

			menuItem.hidden = (condition == NO);

			return condition;

		}
		case 315: // "Search With Google"
		case 1601: // "Search With Google"
		{
			TVCLogView *webView = self.selectedViewControllerBackingView;

			if (webView == nil) {
				return NO;
			}

			NSString *searchProviderName = [self searchProviderName];

			menuItem.title = TXTLS(@"BasicLanguage[1020]", searchProviderName);

			return webView.hasSelection;
		}
		case 1608: // "Look Up in Dictionary"
		{
			TVCLogView *webView = self.selectedViewControllerBackingView;

			if (webView == nil) {
				return NO;
			}

			NSString *selection = webView.selection;

			NSUInteger selectionLength = selection.length;

			if (selectionLength == 0 || selectionLength > 40) {
				menuItem.title = TXTLS(@"BasicLanguage[1018]");

				return NO;
			}

			if (selectionLength > 25) {
				selection = [selection substringToIndex:24];

				selection = [NSString stringWithFormat:@"%@…", selection.trim];
			}

			menuItem.title = TXTLS(@"BasicLanguage[1019]", selection);

			return (selectionLength > 0);
		}
		case 802: // "Toggle Visiblity of Member List"
		{
			return _isChannel;
		}
		case 606: // "Query Logs"
		case 1606: // "Query Logs"
		{
			BOOL condition = _isQuery;

			menuItem.hidden = (condition == NO);

			return [TPCPreferences logToDiskIsEnabled];
		}
		case 608: // "View Logs"
		case 811: // "View Logs"
		{
			return [TPCPreferences logToDiskIsEnabled];
		}
		case 607: // "Channel Properties"
		{
			BOOL condition = _isChannel;

			menuItem.hidden = (condition == NO);

			return condition;
		}
		case 006: // "Channel" (Main Menu)
		case 1607: // "Channel" (WebView)
		{

#define _channelMenuSeparatorTag_1			602 // below "Leave Channel"
#define _channelMenuSeparatorTag_2			605 // below "Delete Channel"
#define _channelMenuSeparatorTag_3			1605 // below "Paste"
#define _channelWebkitMenuTag				1607

			NSMenu *hostMenu = nil;

			if (tag == _channelWebkitMenuTag) {
				menuItem.hidden = (_isChannel == NO);

				hostMenu = menuItem.menu;
			} else {
				hostMenu = menuItem.submenu;
			}

			[hostMenu itemWithTag:_channelMenuSeparatorTag_1].hidden = (_isChannel == NO || _clientIsntLoggedIn);
			[hostMenu itemWithTag:_channelMenuSeparatorTag_2].hidden = (_isChannelOrQuery == NO);
			[hostMenu itemWithTag:_channelMenuSeparatorTag_3].hidden = (_isChannelOrQuery == NO);

#undef _channelMenuSeparatorTag_1
#undef _channelMenuSeparatorTag_2
#undef _channelMenuSeparatorTag_3
#undef _channelWebkitMenuTag

			return YES;
		}
		case 622: // "Copy Unique Identifier"
		{

#define _channelMenuSeparatorTag			621 // below "Channel Properties"
			
			BOOL condition = ([TPCPreferences developerModeEnabled] == NO || _isChannel == NO);
			
			menuItem.hidden = condition;

			[menuItem.menu itemWithTag:_channelMenuSeparatorTag].hidden = condition;

#undef _channelMenuSeparatorTag
			
			return YES;
		}
		case 510: // "Connect Without Proxy"
		{
			NSUInteger flags = ([NSEvent modifierFlags] & NSDeviceIndependentModifierFlagsMask);

			if (flags != NSShiftKeyMask) {
				menuItem.hidden = YES;

				return NO;
			}

			if (_noClient) {
				menuItem.hidden = YES;

				return NO;
			}

			BOOL condition = (_clientIsConnected || u.isConnecting||
				u.config.proxyType == IRCConnectionSocketNoProxyType);

			menuItem.hidden = condition;

			return (condition == NO && u.isQuitting == NO);
		}
		case 500: // "Connect"
		{
			if (_noClient) {
				menuItem.hidden = NO;

				return NO;
			}

			BOOL condition = (_clientIsConnected || u.isConnecting);

			menuItem.hidden = condition;

			BOOL prefersIPv4 = u.config.connectionPrefersIPv4;

			NSUInteger flags = ([NSEvent modifierFlags] & NSDeviceIndependentModifierFlagsMask);

			if (flags == NSShiftKeyMask) {
				if (prefersIPv4 == NO) {
					prefersIPv4 = YES;

					menuItem.title = TXTLS(@"BasicLanguage[1014][2]");
				}
			} else {
				menuItem.title = TXTLS(@"BasicLanguage[1014][1]");
			}

			if (prefersIPv4) {
				menuItem.action = @selector(connectPreferringIPv4:);
			} else {
				menuItem.action = @selector(connectPreferringIPv6:);
			}

			return (condition == NO && u.isQuitting == NO);
		}
		case 501: // "Disconnect"
		{
			BOOL condition = (_clientIsConnected || u.isConnecting);

			menuItem.hidden = (condition == NO);

			return condition;
		}
		case 502: // "Cancel Reconnect"
		{
			BOOL condition = u.isReconnecting;

			menuItem.hidden = (condition == NO);

			return condition;
		}
		case 1600: // "Change Nickname…"
		case 503: // "Change Nickname…"
		case 504: // "Channel List…"
		{
			return _clientIsLoggedIn;
		}
		case 507: // "Delete Server"
		{
			return _clientIsntConnected;
		}
		case 506: // "Duplicate Server"
		case 509: // "Server Properties…"
		case 809: // "Address Book"
		case 810: // "Ignore List"
		{
			return (_noClient == NO);
		}
		case 600: // "Join Channel"
		{
			BOOL condition = (_clientIsLoggedIn && _isChannel && _channelIsntActive);

			if (_noChannel) {
				menuItem.hidden = YES;
			} else {
				menuItem.hidden = (condition == NO);
			}

			return condition;
		}
		case 601: // "Leave Channel"
		{
			BOOL condition = (_clientIsLoggedIn && _isChannel && _channelIsActive);

			if (_noChannel) {
				menuItem.hidden = YES;
			} else {
				menuItem.hidden = (condition == NO);
			}

			return condition;
		}
		case 508: // "Add Channel…"
		case 603: // "Add Channel…"
		{
			menuItem.hidden = (_isQuery || _isUtility);

			return (_noClient == NO);
		}
		case 604: // "Delete Channel"
		{
			menuItem.hidden = _noChannel;

			if (_isChannel) {
				menuItem.title = TXTLS(@"BasicLanguage[1012]");

				return YES;
			} else if (_isQuery) {
				menuItem.title = TXTLS(@"BasicLanguage[1013]");

				return YES;
			} else if (_isUtility) {
				/* Declared as different if statement in case
				 I decide to set a different label later. */
				menuItem.title = TXTLS(@"BasicLanguage[1013]");

				return YES;
			}

			return NO;
		}
		case 1201: // "Add Channel…" - Server Menu
		{
			return (_noClient == NO);
		}
		case 1500: // "Invite To…"
		{
			if ([self checkSelectedMembers:menuItem] == NO) {
				return NO;
			}

			NSUInteger channelCount = 0;

			for (IRCChannel *e in u.channelList) {
				if (c != e && e.isChannel) {
					channelCount++;
				}
			}

			return (channelCount > 0);
		}
		case 203: // "Close Window"
		{
			TXCommandWKeyAction keyAction = [TPCPreferences commandWKeyAction];

			if (keyAction == TXCommandWKeyCloseWindowAction || mainWindow().keyWindow == NO) {
				menuItem.title = TXTLS(@"BasicLanguage[1008]");

				return YES;
			}

			if (_noClient) {
				return NO;
			}

			switch (keyAction) {
				case TXCommandWKeyPartChannelAction:
				{
					if (_noChannel) {
						menuItem.title = TXTLS(@"BasicLanguage[1008]");

						return NO;
					}

					if (_isChannel) {
						menuItem.title = TXTLS(@"BasicLanguage[1010]");

						if (_channelIsntActive) {
							return NO;
						}
					} else if (_isQuery) {
						menuItem.title = TXTLS(@"BasicLanguage[1007]");
					} else if (_isUtility) {
						menuItem.title = TXTLS(@"BasicLanguage[1007]");
					}

					break;
				}
				case TXCommandWKeyDisconnectAction:
				{
					menuItem.title = TXTLS(@"BasicLanguage[1009]", u.networkNameAlt);

					if (_clientIsntConnected) {
						return NO;
					}

					break;
				}
				case TXCommandWKeyTerminateAction:
				{
					menuItem.title = TXTLS(@"BasicLanguage[1011]");

					break;
				}
				default:
				{
					break;
				}
			}

			return YES;
		}
		case 812: // "Highlight List"
		{
			if (_clientIsntConnected) {
				return NO;
			}

			return [TPCPreferences logHighlights];
		}
		case 961: // Developer Mode
		{
			if ([TPCPreferences developerModeEnabled]) {
				menuItem.state = NSOnState;
			} else {  
				menuItem.state = NSOffState;
			}

			return YES;
		}

#if TEXTUAL_BUILT_WITH_ADVANCED_ENCRYPTION == 1
		case TLOEncryptionManagerMenuItemTagAuthenticateChatPartner:
		case TLOEncryptionManagerMenuItemTagStartPrivateConversation:
		case TLOEncryptionManagerMenuItemTagRefreshPrivateConversation:
		case TLOEncryptionManagerMenuItemTagEndPrivateConversation:
		case TLOEncryptionManagerMenuItemTagViewListOfFingerprints:
		{
			/* Even if we are not logged in, we still ask the encryption manager
			 to validate the menu item first so that it can hide specific menu items. 
			 After it has done that, then we can disable if not logged in. */
			if ([TPCPreferences textEncryptionIsEnabled] == NO) {
				return NO;
			}

			BOOL valid = [sharedEncryptionManager()
						  validateMenuItem:menuItem
							   withStateOf:[u encryptionAccountNameForUser:c.name]
									  from:[u encryptionAccountNameForLocalUser]];

			if (_clientIsntLoggedIn) {
				return NO;
			}

			return valid;
		}
#endif

		case 1532: // "Add Ignore"
		{
			/* To make it as efficient as possible, we only check for ignore
			 for the "Add Ignore" menu item. When that menu item is validated,
			 we validate "Modify Ignore" and "Remove Ignore" at the same time. */
			NSArray<IRCChannelUser *> *nicknames = [self selectedMembers:menuItem];

			NSMenuItem *modifyIgnoreMenuItem = [menuItem.menu itemWithTag:1533];
			NSMenuItem *removeIgnoreMenuItem = [menuItem.menu itemWithTag:1534];

			NSString *hostmask = nicknames.firstObject.user.hostmask;

			/* If less than or more than one user is selected, then hide all
			 menu items except "Add Ignore" and disable the "Add Ignore" item. */
			if (nicknames.count != 1 || hostmask == nil) {
				modifyIgnoreMenuItem.hidden = YES;

				removeIgnoreMenuItem.hidden = YES;

				menuItem.hidden = NO;

				return NO;
			}

			/* Update visiblity depending on whether ignore is available */
			/* When this logic was first introduced, we kept a reference to
			 the ignores in the represented object of the menu item.
			 This was stopped because information about the ignore can
			 change while the menu item is still open, making the object
			 we will reference when action is performed garbage. */
			NSArray *userIgnores = [u findIgnoresForHostmask:hostmask];

			BOOL condition = (userIgnores.count == 0);

			modifyIgnoreMenuItem.hidden = condition;

			removeIgnoreMenuItem.hidden = condition;

			menuItem.hidden = (condition == NO);

			return YES;
		}
		case 1533: // "Modify Ignore"
		case 1534: // "Remove Ignore"
		{
			return YES;
		}
		case 1502: // "Private Message (Query)"
		case 1503: // "Give Op (+o)"
		case 1504: // "Give Halfop (+h)"
		case 1505: // "Give Voice (+v)"
		case 1507: // "Take Op (-o)"
		case 1508: // "Take Halfop (-h)"
		case 1509: // "Take Voice (-v)"
		{
			if (_isChannel) {
				return [self checkSelectedMembers:menuItem];
			}

			return NO;
		}
		case 1511: // "Ban"
		case 1512: // "Kick"
		case 1513: // "Ban and Kick"
		{

#define _userControlsBanKickSeparatorTag		1531

			BOOL condition = _isChannel;

			menuItem.hidden = (condition == NO);

			[menuItem.menu itemWithTag:_userControlsBanKickSeparatorTag].hidden = (condition == NO);

			if (condition) {
				return [self checkSelectedMembers:menuItem];
			}

			return NO;

#undef _userControlsBanKickSeparatorTag

		}
		case 1506: // "All Modes Given"
		{
			return NO;
		}
		case 1510: // "All Modes Taken"
		{

#define _userControlsMenuAllModesGivenMenuTag		1506
#define _userControlsMenuAllModesTakenMenuTag		1510

#define _userControlsMenuGiveModeOMenuTag			1503
#define _userControlsMenuGiveModeHMenuTag			1504
#define _userControlsMenuGiveModeVMenuTag			1505
#define _userControlsMenuGiveModeSeparatorTag		1529

#define _userControlsMenuTakeModeOMenuTag			1507
#define _userControlsMenuTakeModeHMenuTag			1508
#define _userControlsMenuTakeModeVMenuTag			1509
#define _userControlsMenuTakeModeSeparatorTag		1530

#define _ui(tag, value)				[[[menuItem menu] itemWithTag:(tag)] setHidden:(value)];

			if (_isChannel == NO) {
				_ui(_userControlsMenuAllModesTakenMenuTag, YES)
				_ui(_userControlsMenuAllModesGivenMenuTag, YES)

				_ui(_userControlsMenuGiveModeOMenuTag, YES)
				_ui(_userControlsMenuGiveModeHMenuTag, YES)
				_ui(_userControlsMenuGiveModeVMenuTag, YES)
				_ui(_userControlsMenuTakeModeOMenuTag, YES)
				_ui(_userControlsMenuTakeModeHMenuTag, YES)
				_ui(_userControlsMenuTakeModeVMenuTag, YES)

				_ui(_userControlsMenuGiveModeSeparatorTag, YES)
				_ui(_userControlsMenuTakeModeSeparatorTag, YES)

				return NO;
			} else {
				_ui(_userControlsMenuGiveModeSeparatorTag, NO)
				_ui(_userControlsMenuTakeModeSeparatorTag, NO)
			}

			NSArray *nicknames = [self selectedMembers:menuItem];

			if (nicknames.count == 1)
			{
				IRCChannelUser *user = nicknames[0];

				IRCUserRank userRanks = user.ranks;

				BOOL UserHasModeO = ((userRanks & IRCUserNormalOperatorRank) == IRCUserNormalOperatorRank);
				BOOL UserHasModeH = ((userRanks & IRCUserHalfOperatorRank) == IRCUserHalfOperatorRank);
				BOOL UserHasModeV = ((userRanks & IRCUserVoicedRank) == IRCUserVoicedRank);

				_ui(_userControlsMenuGiveModeOMenuTag, UserHasModeO)
				_ui(_userControlsMenuGiveModeVMenuTag, UserHasModeV)
				_ui(_userControlsMenuTakeModeOMenuTag, (UserHasModeO == NO))
				_ui(_userControlsMenuTakeModeVMenuTag, (UserHasModeV == NO))

				BOOL halfOpModeSupported = [u.supportInfo modeSymbolIsUserPrefix:@"h"];

				if (halfOpModeSupported == NO) {
					_ui(_userControlsMenuGiveModeHMenuTag, YES)
					_ui(_userControlsMenuTakeModeHMenuTag, YES)
				} else {
					_ui(_userControlsMenuGiveModeHMenuTag,  UserHasModeH)
					_ui(_userControlsMenuTakeModeHMenuTag, (UserHasModeH == NO))
				}

				BOOL hideTakeSepItem = (UserHasModeO == NO  || UserHasModeH == NO  || UserHasModeV == NO);
				BOOL hideGiveSepItem = (UserHasModeO || UserHasModeH || UserHasModeV);

				_ui(_userControlsMenuAllModesTakenMenuTag, hideGiveSepItem)
				_ui(_userControlsMenuAllModesGivenMenuTag, hideTakeSepItem)
			}
			else
			{
				_ui(_userControlsMenuAllModesTakenMenuTag, YES)
				_ui(_userControlsMenuAllModesGivenMenuTag, YES)

				_ui(_userControlsMenuGiveModeOMenuTag, NO)
				_ui(_userControlsMenuGiveModeHMenuTag, NO)
				_ui(_userControlsMenuGiveModeVMenuTag, NO)
				_ui(_userControlsMenuTakeModeOMenuTag, NO)
				_ui(_userControlsMenuTakeModeHMenuTag, NO)
				_ui(_userControlsMenuTakeModeVMenuTag, NO)
			}

			return NO;

#undef _ui

#undef _userControlsMenuAllModesTakenMenuTag
#undef _userControlsMenuAllModesGivenMenuTag

#undef _userControlsMenuGiveModeOMenuTag
#undef _userControlsMenuGiveModeHMenuTag
#undef _userControlsMenuGiveModeVMenuTag
#undef _userControlsMenuGiveModeSeparatorTag

#undef _userControlsMenuTakeModeOMenuTag
#undef _userControlsMenuTakeModeHMenuTag
#undef _userControlsMenuTakeModeVMenuTag
#undef _userControlsMenuTakeModeSeparatorTag

		}
		case 715: // "Next Highlight"
		case 716: // "Previous Highlight"
		{
			TVCLogController *viewController = self.selectedViewController;

			if (viewController == nil) {
				return NO;
			}

			return [viewController highlightAvailable:(tag == 716)];
		}
		case 1603: // "Copy" (WebView)
		{
			TVCLogView *webView = self.selectedViewControllerBackingView;

			if (webView == nil) {
				return NO;
			}

			return webView.hasSelection;
		}
		case 304: // "Paste"
		case 1604: // "Paste" (WebView)
		{
			NSString *currentPasteboard = RZPasteboard().stringContent;

			if (currentPasteboard.length == 0) {
				return NO;
			}

			if (mainWindow().keyWindow) {
				return mainWindowTextField().editable;
			}

			id firstResponder = [NSApp keyWindow].firstResponder;

			if ([firstResponder respondsToSelector:@selector(isEditable)]) {
				return [firstResponder isEditable];
			}

			return NO;
		}
		case 804: // "Toggle Window Appearance"
		{
			return [TPCPreferences invertSidebarColorsPreferenceUserConfigurable];
		}
		default:
		{
			return YES;
		}
	}

	return YES;
}

- (void)menuWillOpen:(NSMenu *)menu
{
	self.menuIsOpen = YES;

	self.pointedClient = mainWindow().selectedClient;
	self.pointedChannel = mainWindow().selectedChannel;

	self.menuPerformedActionLastOpen = NO;
}

- (void)menuDidClose:(NSMenu *)menu
{
	self.menuIsOpen = NO;

	/* This delegate callback is received before -menuItemPerformedAction:
	 is called. So that our selected items can be reset if the user did 
	 not perform an action, we call -menuClosedTimer the next time the 
	 main queue comes around. The action is performed on the current pass
	 which means this prevents a race. */
	XRPerformBlockAsynchronouslyOnMainQueue(^{
		[self menuClosedTimer];
	});
}

- (void)menuClosedTimer
{
	if (self.menuPerformedActionLastOpen) {
		return;
	}

	[self resetSelectedItems];
}

- (void)menuItemWillPerformedAction:(NSNotification *)aNote
{
	NSMenuItem *menuItem = aNote.userInfo[@"MenuItem"];

	if (menuItem.target != self) {
		return;
	}

	self.menuPerformedActionLastOpen = YES;
}

- (void)menuItemPerformedAction:(NSNotification *)aNote
{
	NSMenuItem *menuItem = aNote.userInfo[@"MenuItem"];

	if (menuItem.target != self) {
		return;
	}

	[self resetSelectedItems];
}

#pragma mark -
#pragma mark Properties

- (TDCFileTransferDialog *)fileTransferController
{
	return [TXSharedApplication sharedFileTransferDialog];
}

#pragma mark -
#pragma mark Selected Client and Selected Channel

- (void)resetSelectedItems
{
	self.pointedClient = nil;
	self.pointedChannel = nil;
}

- (nullable IRCClient *)selectedClient
{
	IRCClient *pointedClient = self.pointedClient;

	if (pointedClient) {
		return pointedClient;
	}

	return mainWindow().selectedClient;
}

- (nullable IRCChannel *)selectedChannel
{
	IRCChannel *pointedChannel = self.pointedChannel;

	if (pointedChannel) {
		return pointedChannel;
	}

	return mainWindow().selectedChannel;
}

- (nullable TVCLogController *)selectedViewController
{
	IRCChannel *selectedChannel = self.selectedChannel;

	if (selectedChannel) {
		return selectedChannel.viewController;
	}

	return self.selectedClient.viewController;
}

- (nullable TVCLogView *)selectedViewControllerBackingView
{
	TVCLogController *viewController = self.selectedViewController;

	return viewController.backingView;
}

#pragma mark -
#pragma mark Navigation Channel List

- (void)populateNavigationChannelList
{
#define _channelNavigationMenuEntryMenuTag		717

	[self.mainMenuNavigationChannelListMenu removeAllItems];

	NSUInteger channelCount = 0;

	for (IRCClient *u in worldController().clientList) {
		NSMenu *channelSubmenu = [NSMenu new];

		NSMenuItem *clientMenuItem = [NSMenuItem new];

		clientMenuItem.title = TXTLS(@"BasicLanguage[1021]", u.name);

		clientMenuItem.submenu = channelSubmenu;

		[self.mainMenuNavigationChannelListMenu addItem:clientMenuItem];

		for (IRCChannel *c in u.channelList) {
			NSMenuItem *channelMenuItem = nil;

			if (channelCount >= 10) {
				channelMenuItem = [NSMenuItem menuItemWithTitle:TXTLS(@"BasicLanguage[1022]", c.name)
														 target:self
														 action:@selector(navigateToChannelInNavigationList:)];
			} else {
				NSUInteger keyboardIndex = (channelCount + 1);

				if (keyboardIndex == 10) {
					keyboardIndex = 0; // Have 0 as the last item.
				}

				channelMenuItem = [NSMenuItem menuItemWithTitle:TXTLS(@"BasicLanguage[1022]", c.name)
														 target:self
														 action:@selector(navigateToChannelInNavigationList:)
												  keyEquivalent:[NSString stringWithUniChar:('0' + keyboardIndex)]
											  keyEquivalentMask:NSCommandKeyMask];
			}

			channelMenuItem.tag = _channelNavigationMenuEntryMenuTag;

			channelMenuItem.userInfo = [worldController() pasteboardStringForItem:c];

			[channelSubmenu addItem:channelMenuItem];

			channelCount += 1;
		}
	}

#undef _channelNavigationMenuEntryMenuTag
}

- (void)navigateToChannelInNavigationList:(NSMenuItem *)sender
{
	IRCTreeItem *treeItem = [worldController() findItemWithPasteboardString:sender.userInfo];

	if (treeItem) {
		[mainWindow() select:treeItem];
	}
}

#pragma mark -
#pragma mark Selected User(s)

- (BOOL)checkSelectedMembers:(id)sender
{
	return ([self selectedMembers:sender].count > 0);
}

- (NSArray<IRCChannelUser *> *)selectedMembers:(id)sender
{
	return [self selectedMembers:sender returnStrings:NO];
}

- (NSArray<NSString *> *)selectedMembersNicknames:(id)sender
{
	return [self selectedMembers:sender returnStrings:YES];
}

- (NSArray *)selectedMembers:(id)sender returnStrings:(BOOL)returnStrings
{
	IRCClient *u = self.selectedClient;
	IRCChannel *c = self.selectedChannel;

	if (_noClientOrChannel || _clientIsntLoggedIn || _channelIsntActive) {
		return @[];
	}

	/* Return a specific nickname for WebView events */
	NSString *pointedNickname = nil;

	if ([sender isKindOfClass:[NSMenuItem class]]) {
		pointedNickname = ((NSMenuItem *)sender).userInfo;
	} else {
		pointedNickname = self.pointedNickname;
	}

	if (pointedNickname) {
		if (returnStrings) {
			return @[pointedNickname];
		}

		IRCChannelUser *user = [c findMember:pointedNickname];

		if (user) {
			return @[user];
		}

		return @[];
	}

	/* If we did not have a specific nickname, then query
	 the user list for selected rows. */
	NSMutableArray *userArray = [NSMutableArray array];

	NSIndexSet *selectedRows = mainWindowMemberList().selectedRowIndexes;

	[selectedRows enumerateIndexesUsingBlock:^(NSUInteger index, BOOL *stop) {
		IRCChannelUser *user = [mainWindowMemberList() itemAtRow:index];

		if (returnStrings) {
			[userArray addObject:user.user.nickname];
		} else {
			[userArray addObject:user];
		}
	}];

	return [userArray copy];
}

- (void)deselectMembers:(id)sender
{
	if ([sender isKindOfClass:[NSMenuItem class]]) {
		if (((NSMenuItem *)sender).userInfo.length > 0) {
			return; // Nothing to deselect when our sender used userInfo
		}
	}

	if (self.pointedNickname) {
		self.pointedNickname = nil;

		return;
	}

	[mainWindowMemberList() deselectAll:sender];
}

#pragma mark -
#pragma mark Find Panel

- (void)_showFindPromptOpenDialog:(id)sender
{
	_popWindowViewIfExists(@"TXMenuControllerFindPrompt");

	void (^promptCompletionBlock)(NSString *) = ^(NSString *resultString)
	{
		if ([self.currentSearchPhrase isEqualToString:resultString]) {
			return;
		}

		self.currentSearchPhrase = resultString;

		TVCLogView *webView = self.selectedViewControllerBackingView;

		[webView findString:resultString movingForward:YES];
	};

	NSString *resultString = nil;

	TVCAlertResponse response =
	[TDCInputPrompt promptWithMessage:TXTLS(@"Prompts[1106][2]")
								title:TXTLS(@"Prompts[1106][1]")
						defaultButton:TXTLS(@"Prompts[1106][3]")
					  alternateButton:TXTLS(@"Prompts[0004]")
						prefillString:self.currentSearchPhrase
						 resultString:&resultString];

	if (response == TVCAlertResponseFirstButton) {
		promptCompletionBlock(resultString);
	}
}

- (void)showFindPrompt:(id)sender
{
#define _findPromptOpenDialogMenuTag	308
#define _findPromptMoveForwardMenuTag	309

	if ([sender tag] == _findPromptOpenDialogMenuTag || self.currentSearchPhrase.length == 0) {
		[self _showFindPromptOpenDialog:sender];

		return;
	}

	TVCLogView *webView = self.selectedViewControllerBackingView;

	if ([sender tag] == _findPromptMoveForwardMenuTag) {
		[webView findString:self.currentSearchPhrase movingForward:YES];
	} else {
		[webView findString:self.currentSearchPhrase movingForward:NO];
	}

#undef _findPromptOpenDialogMenuTag
#undef _findPromptMoveForwardMenuTag
}

#pragma mark -
#pragma mark Command + W Keyboard Shortcut

- (void)closeWindow:(id)sender
{
	TXCommandWKeyAction keyAction = [TPCPreferences commandWKeyAction];

	if (keyAction == TXCommandWKeyCloseWindowAction || mainWindow().keyWindow == NO) {
		NSWindow *windowToClose = [NSApp keyWindow];

		if (windowToClose == nil) {
			windowToClose = [NSApp mainWindow];
		}

		if (windowToClose) {
			[windowToClose performClose:sender];
		}

		return;
	}

	IRCClient *u = self.selectedClient;
	IRCChannel *c = self.selectedChannel;

	if (_noClient) {
		return;
	}

	switch (keyAction) {
		case TXCommandWKeyPartChannelAction:
		{
			if (_noChannel) {
				return;
			}

			if (_isChannel) {
				if (_channelIsntActive) {
					return;
				}

				[u partChannel:c];
			} else {
				[worldController() destroyChannel:c];
			}

			break;
		}
		case TXCommandWKeyDisconnectAction:
		{
			if (_clientIsntConnected) {
				return;
			}

			[u quit];

			break;
		}
		case TXCommandWKeyTerminateAction:
		{
			[NSApp terminate:nil];

			break;
		}
		default:
		{
			break;
		}
	}
}

#pragma mark -
#pragma mark File Transfers Dialog

- (void)showFileTransfersWindow:(id)sender
{
	[self.fileTransferController show:YES restorePosition:YES];
}

#pragma mark -
#pragma mark Preferences Dialog

- (void)showPreferencesWindow:(id)sender
{
	[self showPreferencesWindowWithSelection:TDCPreferencesControllerDefaultNavigationSelection];
}

- (void)showStylePreferences:(id)sender
{
	[self showPreferencesWindowWithSelection:TDCPreferencesControllerStyleNavigationSelection];
}

- (void)showHiddenPreferences:(id)sender
{
	[self showPreferencesWindowWithSelection:TDCPreferencesControllerHiddenPreferencesNavigationSelection];
}

- (void)showPreferencesWindowWithSelection:(TDCPreferencesControllerNavigationSelection)selection
{
	_popWindowViewIfExists(@"TDCPreferencesController");

	TDCPreferencesController *controller =
	[TDCPreferencesController new];

	controller.delegate = (id)self;

	[controller show:selection];

	[windowController() addWindowToWindowList:controller];
}

- (void)preferencesDialogWillClose:(TDCPreferencesController *)sender
{
	[TPCPreferences performReloadAction:(TPCPreferencesReloadHighlightKeywordsAction |
										 TPCPreferencesReloadPreferencesChangedAction)];

	[windowController() removeWindowFromWindowList:sender];
}

#pragma mark -
#pragma mark Menu Item Actions

- (void)emptyAction:(id)sender
{
	;
}

- (void)copy:(id)sender
{
	id firstResponder = [NSApp keyWindow].firstResponder;

	if ([firstResponder respondsToSelector:@selector(copy:)]) {
		[firstResponder performSelector:@selector(copy:) withObject:sender];
	}
}

- (void)paste:(id)sender
{
	if (mainWindow().keyWindow) {
		[mainWindowTextField() focus];

		[mainWindowTextField() paste:sender];

		return;
	}

	id firstResponder = [NSApp keyWindow].firstResponder;

	if ([firstResponder respondsToSelector:@selector(paste:)]) {
		[firstResponder performSelector:@selector(paste:) withObject:sender];
	}
}

- (void)print:(id)sender
{
	if (mainWindow().keyWindow) {
		TVCLogView *webView = self.selectedViewControllerBackingView;

		if (webView == nil) {
			return;
		}

		[webView print];

		return;
	}

	id firstResponder = [NSApp keyWindow].firstResponder;

	if ([firstResponder respondsToSelector:@selector(print:)]) {
		[firstResponder performSelector:@selector(print:) withObject:sender];
	}
}

- (void)centerMainWindow:(id)sender
{
	[mainWindow() exactlyCenterWindow];
}

- (void)showAcknowledgements:(id)sender
{
	NSString *AcknowledgementsPath = [RZMainBundle() pathForResource:@"Acknowledgements" ofType:@"pdf" inDirectory:@"Documentation"];

	(void)[RZWorkspace() openFile:AcknowledgementsPath];
}

- (void)showScriptingDocumentation:(id)sender
{
	[TLOpenLink openWithString:@"https://help.codeux.com/textual/Writing-Scripts.kb" inBackground:NO];
}

- (NSString *)searchProviderName
{
	NSDictionary *preferredWebServices =
	[[NSUserDefaults standardUserDefaults] dictionaryForKey:@"NSPreferredWebServices"];

	NSDictionary *defaultSearchProvider = [preferredWebServices dictionaryForKey:@"NSWebServicesProviderWebSearch"];

	NSString *searchProviderName = [defaultSearchProvider stringForKey:@"NSDefaultDisplayName"];

	if (searchProviderName == nil) {
		return @"Google";
	}

	return searchProviderName;
}

- (void)searchGoogle:(id)sender
{
	TVCLogView *webView = self.selectedViewControllerBackingView;

	if (webView == nil) {
		return;
	}

	NSString *selection = webView.selection;

	if (selection.length == 0) {
		return;
	}

	NSPasteboard *searchPasteboard = [NSPasteboard pasteboardWithUniqueName];

	searchPasteboard.stringContent = selection;

	NSPerformService(@"Search With %WebSearchProvider@", searchPasteboard);
}

- (void)lookUpInDictionary:(id)sender
{
	TVCLogView *webView = self.selectedViewControllerBackingView;

	if (webView == nil) {
		return;
	}

	NSString *selection = webView.selection;

	if (selection.length == 0) {
		return;
	}

	NSString *urlString = [NSString stringWithFormat:@"dict://%@", selection.percentEncodedString];

	[TLOpenLink openWithString:urlString];
}

- (void)copyLogAsHtml:(id)sender
{
	TVCLogView *webView = self.selectedViewControllerBackingView;

	if (webView == nil) {
		return;
	}

	[webView copyContentString];
}

- (void)openWebInspector:(id)sender
{
	TVCLogView *webView = self.selectedViewControllerBackingView;

	if (webView == nil) {
		return;
	}

	NSAssert(webView.isUsingWebKit2,
		@"Missing implementation");

	[(TVCLogViewInternalWK2 *)webView.webView openWebInspector];
}

- (void)markScrollback:(id)sender
{
	TVCLogController *viewController = self.selectedViewController;

	if (viewController == nil) {
		return;
	}

	[viewController mark];
}

- (void)gotoScrollbackMarker:(id)sender
{
	TVCLogController *viewController = self.selectedViewController;

	if (viewController == nil) {
		return;
	}

	[viewController goToMark];
}

- (void)jumpToCurrentSession:(id)sender
{
	TVCLogController *viewController = self.selectedViewController;

	if (viewController == nil) {
		return;
	}

	[viewController jumpToCurrentSession];
}

- (void)jumpToPresent:(id)sender
{
	TVCLogController *viewController = self.selectedViewController;

	if (viewController == nil) {
		return;
	}

	[viewController jumpToPresent];
}

- (void)clearScrollback:(id)sender
{
	IRCClient *u = self.selectedClient;
	IRCChannel *c = self.selectedChannel;

	if (_noClient) {
		return;
	}

	if (c) {
		[mainWindow() clearContentsOfChannel:c];
	} else {
		[mainWindow() clearContentsOfClient:u];
	}
}

- (void)increaseLogFontSize:(id)sender
{
	[mainWindow() changeTextSize:YES];
}

- (void)decreaseLogFontSize:(id)sender
{
	[mainWindow() changeTextSize:NO];
}

- (void)markAllAsRead:(id)sender
{
	[mainWindow() markAllAsRead];
}

- (void)connect:(id)sender
{
	NSAssert(NO, @"This method should not be invoked directly");
}

- (void)connectPreferringIPv6:(id)sender
{
	IRCClient *u = self.selectedClient;

	if (_noClient || _clientIsConnected || u.isQuitting) {
		return;
	}

	[u connect:IRCClientConnectNormalMode preferIPv4:NO bypassProxy:NO];

	[mainWindow() expandClient:u];
}

- (void)connectPreferringIPv4:(id)sender
{
	IRCClient *u = self.selectedClient;

	if (_noClient || _clientIsConnected || u.isQuitting) {
		return;
	}

	[u connect:IRCClientConnectNormalMode preferIPv4:YES bypassProxy:NO];

	[mainWindow() expandClient:u];
}

- (void)connectBypassingProxy:(id)sender
{
	IRCClient *u = self.selectedClient;

	if (_noClient || _clientIsConnected || u.isQuitting) {
		return;
	}

	[u connect:IRCClientConnectNormalMode preferIPv4:u.config.connectionPrefersIPv4 bypassProxy:YES];

	[mainWindow() expandClient:u];
}

- (void)disconnect:(id)sender
{
	IRCClient *u = self.selectedClient;

	if (_noClient || _clientIsntConnected || u.isQuitting) {
		return;
	}

	[u quit];
}

- (void)cancelReconnection:(id)sender
{
	IRCClient *u = self.selectedClient;

	if (_noClient) {
		return;
	}

	[u cancelReconnect];
}

#pragma mark -
#pragma mark Change Nickname Sheet

- (void)showServerChangeNicknameSheet:(id)sender
{
	[windowController() popMainWindowSheetIfExists];

	IRCClient *u = self.selectedClient;

	if (_noClient || _clientIsntLoggedIn) {
		return;
	}

	TDCServerChangeNicknameSheet *sheet =
	[[TDCServerChangeNicknameSheet alloc] initWithClient:u];

	sheet.delegate = (id)self;

	sheet.window = mainWindow();

	[sheet start];

	[windowController() addWindowToWindowList:sheet];
}

- (void)serverChangeNicknameSheet:(TDCServerChangeNicknameSheet *)sender didInputNickname:(NSString *)nickname
{
	IRCClient *u = sender.client;

	if (_noClient || _clientIsntLoggedIn) {
		return;
	}

	[u changeNickname:nickname];
}

- (void)serverChangeNicknameSheetWillClose:(TDCServerChangeNicknameSheet *)sender
{
	[windowController() removeWindowFromWindowList:sender];
}

#pragma mark -
#pragma mark Menu Item Actions

- (void)showServerChannelList:(id)sender
{
	IRCClient *u = self.selectedClient;

	if (_noClient || _clientIsntLoggedIn) {
		return;
	}

	[u createChannelListDialog];

	[u requestChannelList];
}

- (void)addServer:(id)sender
{
	[windowController() popMainWindowSheetIfExists];

	TDCServerPropertiesSheet *sheet =
	[[TDCServerPropertiesSheet alloc] initWithClient:nil];

	sheet.delegate = self;

	sheet.window = mainWindow();

	[sheet startWithSelection:TDCServerPropertiesSheetDefaultNavigationSelection context:nil];

	[windowController() addWindowToWindowList:sheet];
}

- (void)duplicateServer:(id)sender
{
	IRCClient *u = self.selectedClient;

	if (_noClient) {
		return;
	}

	IRCClientConfigMutable *config = [u.config uniqueCopyMutable];

	config.connectionName = [config.connectionName stringByAppendingString:@"_"];

	IRCClient *newClient = [worldController() createClientWithConfig:config reload:YES];

	if (newClient.config.sidebarItemExpanded) { // Only expand new client if old was expanded already.
		[mainWindow() expandClient:newClient];
	}

	[worldController() save];
}

- (void)deleteServer:(id)sender
{
	IRCClient *u = self.selectedClient;

	if (_noClient || _clientIsConnected) {
		return;
	}

	NSString *suppressionText = nil;

	BOOL suppressionResult = NO;

#if TEXTUAL_BUILT_WITH_ICLOUD_SUPPORT == 1
	BOOL deleteFromCloudCheckboxShown = NO;

	if ([TPCPreferences syncPreferencesToTheCloud]) {
		if (u.config.excludedFromCloudSyncing == NO) {
			deleteFromCloudCheckboxShown = YES;

			suppressionText = TXTLS(@"Prompts[1107][3]");
		}
	}
#endif

	BOOL result = [TDCAlert modalAlertWithMessage:TXTLS(@"Prompts[1107][2]")
											title:TXTLS(@"Prompts[1107][1]")
									defaultButton:TXTLS(@"Prompts[0001]")
								  alternateButton:TXTLS(@"Prompts[0002]")
								   suppressionKey:nil
								  suppressionText:suppressionText
							  suppressionResponse:&suppressionResult];

	if (result == NO) {
		return;
	}

#if TEXTUAL_BUILT_WITH_ICLOUD_SUPPORT == 1
	if (deleteFromCloudCheckboxShown && suppressionResult == NO) {
		[worldController() destroyClient:u skipCloud:NO];
	} else {
#endif

		[worldController() destroyClient:u skipCloud:YES];

#if TEXTUAL_BUILT_WITH_ICLOUD_SUPPORT == 1
	}
#endif

	[worldController() save];
}

#pragma mark -
#pragma mark Server Properties

- (void)showServerPropertiesSheetForClient:(IRCClient *)client withSelection:(TDCServerPropertiesSheetNavigationSelection)selection context:(nullable id)context
{
	NSParameterAssert(client != nil);

	[windowController() popMainWindowSheetIfExists];

	TDCServerPropertiesSheet *sheet = [[TDCServerPropertiesSheet alloc] initWithClient:client];

	sheet.delegate = self;

	sheet.window = mainWindow();

	[sheet startWithSelection:selection context:context];

	[windowController() addWindowToWindowList:sheet];
}

- (void)showServerPropertiesSheet:(id)sender
{
	IRCClient *u = self.selectedClient;

	if (_noClient) {
		return;
	}

	[self showServerPropertiesSheetForClient:u
							   withSelection:TDCServerPropertiesSheetDefaultNavigationSelection
									 context:nil];
}

- (void)serverPropertiesSheet:(TDCServerPropertiesSheet *)sender onOk:(IRCClientConfig *)config
{
	IRCClient *u = sender.client;

	if (u == nil) {
		u = [worldController() createClientWithConfig:config reload:YES];

		return;
	}

	BOOL sameEncoding = (config.primaryEncoding == u.config.primaryEncoding);

	[u updateConfig:config];

	if (sameEncoding == NO) {
		[mainWindow() reloadTheme];
	}

	[mainWindow() reloadTreeGroup:u];

	[worldController() save];
}

#if TEXTUAL_BUILT_WITH_ICLOUD_SUPPORT == 1
- (void)serverPropertiesSheet:(TDCServerPropertiesSheet *)sender removeClientFromCloud:(NSString *)clientId
{
	[worldController() cloud_addClientToListOfDeletedClients:clientId];
}
#endif

- (void)serverPropertiesSheetWillClose:(TDCServerPropertiesSheet *)sender
{
	[windowController() removeWindowFromWindowList:sender];
}

#pragma mark -
#pragma mark Menu Item Actions

- (void)joinChannel:(id)sender
{
	IRCClient *u = self.selectedClient;
	IRCChannel *c = self.selectedChannel;

	if (_noClientOrChannel || _clientIsntLoggedIn || _isChannel == NO || _channelIsActive) {
		return;
	}

	u.inUserInvokedJoinRequest = YES;

	[u joinChannel:c];
}

- (void)leaveChannel:(id)sender
{
	IRCClient *u = self.selectedClient;
	IRCChannel *c = self.selectedChannel;

	if (_noClientOrChannel || (_isChannel && (_clientIsntLoggedIn || _channelIsntActive))) {
		return;
	}

	if (_isChannel) {
		[u partChannel:c];

		return;
	}

	[worldController() destroyChannel:c];
}

#pragma mark -
#pragma mark Highlight Sheet

- (void)showServerHighlightList:(id)sender
{
	[windowController() popMainWindowSheetIfExists];

	IRCClient *u = self.selectedClient;

	if (_noClient) {
		return;
	}

	TDCServerHighlightListSheet *sheet =
	[[TDCServerHighlightListSheet alloc] initWithClient:u];

	sheet.delegate = (id)self;

	sheet.window = mainWindow();

	[sheet start];

	[windowController() addWindowToWindowList:sheet];
}

- (void)serverHighlightListSheetWillClose:(TDCServerHighlightListSheet *)sender
{
	[windowController() removeWindowFromWindowList:sender];
}

#pragma mark -
#pragma mark Nickname Color Sheet

- (void)memberChangeColor:(NSString *)nickname
{
	NSParameterAssert(nickname != nil);

	[windowController() popMainWindowSheetIfExists];

	IRCClient *u = self.selectedClient;

	if (_noClient) {
		return;
	}

	TDCNicknameColorSheet *sheet =
	[[TDCNicknameColorSheet alloc] initWithNickname:nickname];

	sheet.delegate = (id)self;

	sheet.window = mainWindow();

	[sheet start];

	[windowController() addWindowToWindowList:sheet];
}

- (void)nicknameColorSheetOnOk:(TDCNicknameColorSheet *)sneder
{
	[mainWindow() reloadTheme];
}

- (void)nicknameColorSheetWillClose:(TDCNicknameColorSheet *)sender
{
	[windowController() removeWindowFromWindowList:sender];
}

#pragma mark -
#pragma mark Channel Topic Sheet

- (void)showChannelModifyTopicSheet:(id)sender
{
	[windowController() popMainWindowSheetIfExists];

	IRCClient *u = self.selectedClient;
	IRCChannel *c = self.selectedChannel;

	if (_noClientOrChannel || _isChannel == NO) {
		return;
	}

	TDCChannelModifyTopicSheet *sheet =
	[[TDCChannelModifyTopicSheet alloc] initWithChannel:c];

	sheet.delegate = (id)self;

	sheet.window = mainWindow();

	[sheet start];

	[windowController() addWindowToWindowList:sheet];
}

- (void)channelModifyTopicSheet:(TDCChannelModifyTopicSheet *)sender onOk:(NSString *)topic
{
	IRCClient *u = sender.client;
	IRCChannel *c = sender.channel;

	if (_noClientOrChannel || _clientIsntLoggedIn || _isChannel == NO) {
		return;
	}

	[u sendTopicTo:topic inChannel:c];
}

- (void)channelModifyTopicSheetWillClose:(TDCChannelModifyTopicSheet *)sender
{
	[windowController() removeWindowFromWindowList:sender];
}

#pragma mark -
#pragma mark Channel Mode Sheet

- (void)showChannelModifyModesSheet:(id)sender
{
	[windowController() popMainWindowSheetIfExists];

	IRCClient *u = self.selectedClient;
	IRCChannel *c = self.selectedChannel;

	if (_noClientOrChannel || _isChannel == NO) {
		return;
	}

	TDCChannelModifyModesSheet *sheet =
	[[TDCChannelModifyModesSheet alloc] initWithChannel:c];

	sheet.delegate = (id)self;

	sheet.window = mainWindow();

	[sheet start];

	[windowController() addWindowToWindowList:sheet];
}

- (void)channelModifyModesSheet:(TDCChannelModifyModesSheet *)sender onOk:(IRCChannelModeContainer *)modes
{
	IRCClient *u = sender.client;
	IRCChannel *c = sender.channel;

	if (_noClientOrChannel || _clientIsntLoggedIn || _isChannel == NO) {
		return;
	}

	NSString *changeString = [c.modeInfo getChangeCommand:modes];

	if (changeString.length == 0) {
		return;
	}

	[u sendModes:changeString withParameters:nil inChannel:c];
}

- (void)channelModifyModesSheetWillClose:(TDCChannelModifyModesSheet *)sender
{
	[windowController() removeWindowFromWindowList:sender];
}

#pragma mark -
#pragma mark Channel Spotlight

- (void)showChannelSpotlightWindow:(id)sender
{
	NSAssert(TEXTUAL_RUNNING_ON(10.10, Yosemite),
		@"This feature requires OS X Yosemite or later");

	_popWindowViewIfExists(@"TDCChannelSpotlightController");

#if TEXTUAL_BUILT_FOR_APP_STORE_DISTRIBUTION == 1
	if (TLOAppStoreTextualIsRegistered() == NO && TLOAppStoreIsTrialExpired()) {
		[[TXSharedApplication sharedInAppPurchaseDialog] showFeatureIsLimitedMessageInWindow:mainWindow()];

		return;
	}
#endif

	TDCChannelSpotlightController *dialog =
	[[TDCChannelSpotlightController alloc] initWithParentWindow:mainWindow()];

	dialog.delegate = (id)self;

	[dialog show];

	[windowController() addWindowToWindowList:dialog];
}

- (void)channelSpotlightController:(TDCChannelSpotlightController *)sender selectChannel:(IRCChannel *)channel
{
	[mainWindow() select:channel];
}

- (void)channelSpotlightControllerWillClose:(TDCChannelSpotlightController *)sender
{
	[windowController() removeWindowFromWindowList:sender];
}

#pragma mark -
#pragma mark Menu Item Actions

- (void)addChannel:(id)sender
{
	[windowController() popMainWindowSheetIfExists];

	IRCClient *u = self.selectedClient;

	if (_noClient) {
		return;
	}

	TDCChannelPropertiesSheet *sheet =
	[[TDCChannelPropertiesSheet alloc] initWithClient:u];

	sheet.delegate = self;

	sheet.window = mainWindow();

	[sheet start];

	[windowController() addWindowToWindowList:sheet];
}

- (void)deleteChannel:(id)sender
{
	IRCChannel *c = self.selectedChannel;

	if (_noChannel) {
		return;
	}

	if (_isChannel) {
		BOOL result = [TDCAlert modalAlertWithMessage:TXTLS(@"Prompts[1103][2]")
												title:TXTLS(@"Prompts[1103][1]")
										defaultButton:TXTLS(@"Prompts[0001]")
									  alternateButton:TXTLS(@"Prompts[0002]")
									   suppressionKey:@"delete_channel"
									  suppressionText:nil];

		if (result == NO) {
			return;
		}
	}

	[worldController() destroyChannel:c];

	[worldController() save];
}

#pragma mark -
#pragma mark Channel Properties

- (void)showChannelPropertiesSheet:(id)sender
{
	[windowController() popMainWindowSheetIfExists];

	IRCClient *u = self.selectedClient;
	IRCChannel *c = self.selectedChannel;

	if (_noClientOrChannel || _isChannel == NO) {
		return;
	}

	TDCChannelPropertiesSheet *sheet =
	[[TDCChannelPropertiesSheet alloc] initWithChannel:c];

	sheet.delegate = self;

	sheet.window = mainWindow();

	[sheet start];

	[windowController() addWindowToWindowList:sheet];
}

- (void)channelPropertiesSheet:(TDCChannelPropertiesSheet *)sender onOk:(IRCChannelConfig *)config
{
	IRCClient *u = sender.client;

	if (_noClient) {
		return;
	}

	IRCChannel *c = sender.channel;

	if (c == nil) {
		c = [worldController() createChannelWithConfig:config onClient:u];

		[mainWindow() expandClient:u];

		return;
	}

	[c updateConfig:config];

	[worldController() save];
}

- (void)channelPropertiesSheetWillClose:(TDCChannelPropertiesSheet *)sender
{
	[windowController() removeWindowFromWindowList:sender];
}

#pragma mark -
#pragma mark Menu Item Actions

- (void)memberAddIgnore:(id)sender
{
	IRCClient *u = self.selectedClient;
	IRCChannel *c = self.selectedChannel;

	if (_noClientOrChannel) {
		return;
	}

	NSArray *nicknames = [self selectedMembersNicknames:sender];

	if (nicknames.count == 0) {
		return;
	}

	[self deselectMembers:sender];

	NSString *command = [NSString stringWithFormat:@"ignore %@", nicknames[0]];

	[u sendCommand:command completeTarget:YES target:c.name];
}

- (void)memberRemoveIgnore:(id)sender
{
	IRCClient *u = self.selectedClient;
	IRCChannel *c = self.selectedChannel;

	if (_noClientOrChannel) {
		return;
	}

	NSArray *nicknames = [self selectedMembersNicknames:sender];

	if (nicknames.count == 0) {
		return;
	}

	[self deselectMembers:sender];

	NSString *command = [NSString stringWithFormat:@"unignore %@", nicknames[0]];

	[u sendCommand:command completeTarget:YES target:c.name];
}

- (void)memberModifyIgnore:(id)sender
{
	IRCClient *u = self.selectedClient;

	if (_noClient) {
		return;
	}

	NSArray<IRCChannelUser *> *nicknames = [self selectedMembers:sender];

	[self deselectMembers:sender];
	
	/* User's hostmask and other information can change between the point
	 the menu item is opened and the point the action is performed.
	 We therefore perform a new query for ignores when performing action. */
	NSString *hostmask = nicknames.firstObject.user.hostmask;
	
	if (nicknames.count != 1 || hostmask == nil) {
		return;
	}
	
	NSArray *userIgnores = [u findIgnoresForHostmask:hostmask];
	
	/* If we have more than one user ignore, then open
	 the address book instead of a specific ignore. */
	if (userIgnores.count == 1) {
		[self showServerPropertiesSheetForClient:u
								   withSelection:TDCServerPropertiesSheetNewIgnoreEntryNavigationSelection
										 context:userIgnores[0]];
	} else {
		[self showServerPropertiesSheetForClient:u
								   withSelection:TDCServerPropertiesSheetAddressBookNavigationSelection
										 context:nil];
	}
}

#pragma mark -
#pragma mark Menu Item Actions

- (void)memberInMemberListDoubleClicked:(id)sender
{
	NSInteger rowBeneathMouse = mainWindowMemberList().rowBeneathMouse;

	if (rowBeneathMouse < 0) {
		return;
	}

	TXUserDoubleClickAction action = [TPCPreferences userDoubleClickOption];

	if (action == TXUserDoubleClickWhoisAction) {
		[self whoisSelectedMembers:sender];
	} else if (action == TXUserDoubleClickPrivateMessageAction) {
		[self memberStartPrivateMessage:sender];
	} else if (action == TXUserDoubleClickInsertTextFieldAction) {
		[self memberInsertNameIntoTextField:sender];
	}
}

- (void)memberInChannelViewDoubleClicked:(id)sender
{
	TXUserDoubleClickAction action = [TPCPreferences userDoubleClickOption];

	if (action == TXUserDoubleClickWhoisAction) {
		[self whoisSelectedMembers:sender];
	} else if (action == TXUserDoubleClickPrivateMessageAction) {
		[self memberStartPrivateMessage:sender];
	} else if (action == TXUserDoubleClickInsertTextFieldAction) {
		[self memberInsertNameIntoTextField:sender];
	}
}

- (void)memberInsertNameIntoTextField:(id)sender
{
	IRCClient *u = self.selectedClient;
	IRCChannel *c = self.selectedChannel;

	if (_noClientOrChannel) {
		return;
	}

	NSArray *nicknames = [self selectedMembersNicknames:sender];

	if (nicknames.count == 0) {
		return;
	}

	[self deselectMembers:sender];

	TVCMainWindowTextView *textView = mainWindowTextField();

	NSRange selectedRange = textView.selectedRange;

	NSMutableString *stringToInsert = [NSMutableString string];

	if (selectedRange.location > 0) {
		UniChar previousCharacter = [textView.stringValue characterAtIndex:(selectedRange.location - 1)];

		if (previousCharacter != ' ') {
			[stringToInsert appendString:@" "];
		}
	}

	NSString *nicknamesString = [nicknames componentsJoinedByString:@", "];

	[stringToInsert appendString:nicknamesString];

	NSString *completionSuffix = [TPCPreferences tabCompletionSuffix];

	if (completionSuffix != nil) {
		[stringToInsert appendString:completionSuffix];
	}

	[textView replaceCharactersInRange:selectedRange withString:stringToInsert];

	[textView resetFontColorInRange:selectedRange];

	[textView focus];
}

- (void)memberSendWhois:(id)sender
{
	[self whoisSelectedMembers:sender];
}

- (void)whoisSelectedMembers:(id)sender
{
	IRCClient *u = self.selectedClient;
	IRCChannel *c = self.selectedChannel;

	if (_noClientOrChannel) {
		return;
	}

	for (NSString *nickname in [self selectedMembersNicknames:sender]) {
		[u sendWhois:nickname];
	}

	[self deselectMembers:sender];
}

- (void)memberStartPrivateMessage:(id)sender
{
	IRCClient *u = self.selectedClient;
	IRCChannel *c = self.selectedChannel;

	if (_noClientOrChannel) {
		return;
	}

	for (NSString *nickname in [self selectedMembersNicknames:sender]) {
		IRCChannel *query = [u findChannelOrCreate:nickname isPrivateMessage:YES];

		[mainWindow() select:query];
	}

	[self deselectMembers:sender];
}

#pragma mark -
#pragma mark Channel Invite Sheet

- (void)memberSendInvite:(id)sender
{
	[windowController() popMainWindowSheetIfExists];

	IRCClient *u = self.selectedClient;
	IRCChannel *c = self.selectedChannel;

	if (_noClientOrChannel || _clientIsntLoggedIn || _isChannel == NO || _channelIsntActive) {
		return;
	}

	NSArray *nicknames = [self selectedMembersNicknames:sender];

	if (nicknames.count == 0) {
		return;
	}

	[self deselectMembers:sender];

	NSMutableArray<NSString *> *channels = [NSMutableArray array];

	for (IRCChannel *e in u.channelList) {
		if (c != e && e.isChannel) {
			[channels addObject:e.name];
		}
	}

	if (channels.count == 0) {
		return;
	}

	TDCChannelInviteSheet *sheet =
	[[TDCChannelInviteSheet alloc] initWithNicknames:nicknames onClient:u];

	sheet.delegate = (id)self;

	sheet.window = mainWindow();

	[sheet startWithChannels:channels];

	[windowController() addWindowToWindowList:sheet];
}

- (void)channelInviteSheet:(TDCChannelInviteSheet *)sender onSelectChannel:(NSString *)channelName
{
	IRCClient *u = sender.client;

	if (_noClient || _clientIsntLoggedIn) {
		return;
	}

	for (NSString *nickname in sender.nicknames) {
		[u sendInviteTo:nickname toJoinChannelNamed:channelName];
	}
}

- (void)channelInviteSheetWillClose:(TDCChannelInviteSheet *)sender
{
	[windowController() removeWindowFromWindowList:sender];
}

#pragma mark -
#pragma mark Menu Item Actions

- (void)memberSendCTCPPing:(id)sender
{
	IRCClient *u = self.selectedClient;
	IRCChannel *c = self.selectedChannel;

	if (_noClientOrChannel) {
		return;
	}

	for (NSString *nickname in [self selectedMembersNicknames:sender]) {
		[u sendCTCPPing:nickname];
	}

	[self deselectMembers:sender];
}

- (void)memberSendCTCPFinger:(id)sender
{
	IRCClient *u = self.selectedClient;
	IRCChannel *c = self.selectedChannel;

	if (_noClientOrChannel) {
		return;
	}

	for (NSString *nickname in [self selectedMembersNicknames:sender]) {
		[u sendCTCPQuery:nickname command:@"FINGER" text:nil];
	}

	[self deselectMembers:sender];
}

- (void)memberSendCTCPTime:(id)sender
{
	IRCClient *u = self.selectedClient;
	IRCChannel *c = self.selectedChannel;

	if (_noClientOrChannel) {
		return;
	}

	for (NSString *nickname in [self selectedMembersNicknames:sender]) {
		[u sendCTCPQuery:nickname command:@"TIME" text:nil];
	}

	[self deselectMembers:sender];
}

- (void)memberSendCTCPVersion:(id)sender
{
	IRCClient *u = self.selectedClient;
	IRCChannel *c = self.selectedChannel;

	if (_noClientOrChannel) {
		return;
	}

	for (NSString *nickname in [self selectedMembersNicknames:sender]) {
		[u sendCTCPQuery:nickname command:@"VERSION" text:nil];
	}

	[self deselectMembers:sender];
}

- (void)memberSendCTCPUserinfo:(id)sender
{
	IRCClient *u = self.selectedClient;
	IRCChannel *c = self.selectedChannel;

	if (_noClientOrChannel) {
		return;
	}

	for (NSString *nickname in [self selectedMembersNicknames:sender]) {
		[u sendCTCPQuery:nickname command:@"USERINFO" text:nil];
	}

	[self deselectMembers:sender];
}

- (void)memberSendCTCPClientInfo:(id)sender
{
	IRCClient *u = self.selectedClient;
	IRCChannel *c = self.selectedChannel;

	if (_noClientOrChannel) {
		return;
	}

	for (NSString *nickname in [self selectedMembersNicknames:sender]) {
		[u sendCTCPQuery:nickname command:@"CLIENTINFO" text:nil];
	}

	[self deselectMembers:sender];
}

- (void)copyUrl:(id)sender
{
	NSString *pointedUrl = ((NSMenuItem *)sender).userInfo;

	if (pointedUrl.length == 0) {
		return;
	}

	RZPasteboard().stringContent = pointedUrl;
}

- (void)joinChannelClicked:(id)sender
{
	NSParameterAssert(sender != nil);

	NSString *pointedChannelName = nil;

	if ([sender isKindOfClass:[NSMenuItem class]]) {
		pointedChannelName = ((NSMenuItem *)sender).userInfo;
	} else if ([sender isKindOfClass:[NSString class]]) {
		pointedChannelName = sender;
	} else {
		NSAssert(NO, @"Bad data type");
	}

	if (pointedChannelName == nil) {
		return;
	}

	IRCClient *u = self.selectedClient;

	if (_noClient || _clientIsntLoggedIn) {
		return;
	}

	u.inUserInvokedJoinRequest = YES;

	[u joinUnlistedChannel:pointedChannelName];
}

- (void)showAddressBook:(id)sender
{
	IRCClient *u = self.selectedClient;

	if (_noClient) {
		return;
	}

	[self showServerPropertiesSheetForClient:u
							   withSelection:TDCServerPropertiesSheetAddressBookNavigationSelection
									 context:nil];
}

- (void)showIgnoreList:(id)sender
{
	[self showAddressBook:sender];
}

#pragma mark -
#pragma mark Welcome Sheet

- (void)showWelcomeSheet:(id)sender
{
	[windowController() popMainWindowSheetIfExists];

	TDCWelcomeSheet *sheet =
	[[TDCWelcomeSheet alloc] initWithWindow:mainWindow()];

	sheet.delegate = (id)self;

	[sheet start];

	[windowController() addWindowToWindowList:sheet];
}

- (void)welcomeSheet:(TDCWelcomeSheet *)sender onOk:(IRCClientConfig *)config
{
	IRCClient *u = [worldController() createClientWithConfig:config reload:YES];

	[mainWindow() expandClient:u];

	[worldController() save];

	[u connect];

	[u selectFirstChannelInChannelList];
}

- (void)welcomeSheetWillClose:(TDCWelcomeSheet *)sender
{
	[windowController() removeWindowFromWindowList:sender];
}

#pragma mark -
#pragma mark About Window

- (void)showAboutWindow:(id)sender
{
	_popWindowViewIfExists(@"TDCAboutDialog");

	TDCAboutDialog *dialog = [TDCAboutDialog new];

	dialog.delegate = (id)self;

	[dialog show];

	[windowController() addWindowToWindowList:dialog];
}

- (void)aboutDialogWillClose:(TDCAboutDialog *)sender
{
	[windowController() removeWindowFromWindowList:sender];
}

#pragma mark -
#pragma mark Buddy List

- (void)showBuddyListWindow:(id)sender
{
#ifdef TEXTUAL_BUILT_WITH_BUDDY_LIST_WINDOW
	_popWindowViewIfExists(@"TDCBuddyListDialog");

	TDCBuddyListDialog *dialog = [TDCBuddyListDialog new];

	dialog.delegate = (id)self;

	[dialog show];

	[windowController() addWindowToWindowList:dialog];
#endif
}

#ifdef TEXTUAL_BUILT_WITH_BUDDY_LIST_WINDOW
- (void)buddyListDialogWillClose:(TDCBuddyListDialog *)sender
{
	[windowController() removeWindowFromWindowList:sender];
}
#endif

#pragma mark -
#pragma mark Menu Item Actions

- (void)processModeChange:(id)sender usingCommand:(NSString *)modeCommand
{
	IRCClient *u = self.selectedClient;
	IRCChannel *c = self.selectedChannel;

	if (_noClientOrChannel || _clientIsntLoggedIn || _isChannel == NO) {
		return;
	}

	NSArray *nicknames = [self selectedMembersNicknames:sender];

	[self deselectMembers:sender];

	NSString *nicknamesString = [nicknames componentsJoinedByString:@" "];

	NSString *command = [NSString stringWithFormat:@"%@ %@", modeCommand, nicknamesString];

	[u sendCommand:command completeTarget:YES target:c.name];
}

- (void)memberModeGiveOp:(id)sender
{
	[self processModeChange:sender usingCommand:@"OP"];
}

- (void)memberModeTakeOp:(id)sender
{ 
	[self processModeChange:sender usingCommand:@"DEOP"];
}

- (void)memberModeGiveHalfop:(id)sender
{ 
	[self processModeChange:sender usingCommand:@"HALFOP"];
}

- (void)memberModeTakeHalfop:(id)sender
{ 
	[self processModeChange:sender usingCommand:@"DEHALFOP"];
}

- (void)memberModeGiveVoice:(id)sender
{ 
	[self processModeChange:sender usingCommand:@"VOICE"];
}

- (void)memberModeTakeVoice:(id)sender
{ 
	[self processModeChange:sender usingCommand:@"DEVOICE"];
}

- (void)memberKickFromChannel:(id)sender
{
	IRCClient *u = self.selectedClient;
	IRCChannel *c = self.selectedChannel;

	if (_noClientOrChannel || _clientIsntLoggedIn || _isChannel == NO) {
		return;
	}

	for (NSString *nickname in [self selectedMembersNicknames:sender]) {
		[u kick:nickname inChannel:c];
	}

	[self deselectMembers:sender];
}

- (void)memberBanFromChannel:(id)sender
{
	IRCClient *u = self.selectedClient;
	IRCChannel *c = self.selectedChannel;

	if (_noClientOrChannel || _clientIsntLoggedIn || _isChannel == NO) {
		return;
	}

	for (NSString *nickname in [self selectedMembersNicknames:sender]) {
		NSString *command = [NSString stringWithFormat:@"BAN %@", nickname];

		[u sendCommand:command completeTarget:YES target:c.name];
	}

	[self deselectMembers:sender];
}

- (void)memberKickbanFromChannel:(id)sender
{
	IRCClient *u = self.selectedClient;
	IRCChannel *c = self.selectedChannel;

	if (_noClientOrChannel || _clientIsntLoggedIn || _isChannel == NO) {
		return;
	}

	for (NSString *nickname in [self selectedMembersNicknames:sender]) {
		NSString *command = [NSString stringWithFormat:@"KICKBAN %@ %@", nickname, [TPCPreferences defaultKickMessage]];

		[u sendCommand:command completeTarget:YES target:c.name];
	}

	[self deselectMembers:sender];
}

- (void)memberKillFromServer:(id)sender
{
	IRCClient *u = self.selectedClient;
	IRCChannel *c = self.selectedChannel;

	if (_noClientOrChannel || _clientIsntLoggedIn) {
		return;
	}

	for (NSString *nickname in [self selectedMembersNicknames:sender]) {
		NSString *command = [NSString stringWithFormat:@"KILL %@ %@", nickname, [TPCPreferences IRCopDefaultKillMessage]];

		[u sendCommand:command];
	}

	[self deselectMembers:sender];
}

- (void)memberBanFromServer:(id)sender
{
	IRCClient *u = self.selectedClient;
	IRCChannel *c = self.selectedChannel;

	if (_noClientOrChannel || _clientIsntLoggedIn) {
		return;
	}

	for (NSString *nickname in [self selectedMembersNicknames:sender]) {
		if ([nickname isEqualIgnoringCase:u.userNickname]) {
			[u printDebugInformation:TXTLS(@"IRC[1004]", u.serverAddress) inChannel:c];

			continue;
		}

		NSString *command = [NSString stringWithFormat:@"GLINE %@ %@", nickname, [TPCPreferences IRCopDefaultGlineMessage]];

		[u sendCommand:command];
	}

	[self deselectMembers:sender];
}

- (void)memberShunOnServer:(id)sender
{
	IRCClient *u = self.selectedClient;
	IRCChannel *c = self.selectedChannel;

	if (_noClientOrChannel || _clientIsntLoggedIn) {
		return;
	}

	for (NSString *nickname in [self selectedMembersNicknames:sender]) {
		NSString *command = [NSString stringWithFormat:@"SHUN %@ %@", nickname, [TPCPreferences IRCopDefaultShunMessage]];

		[u sendCommand:command];
	}

	[self deselectMembers:sender];
}

- (void)memberSendFileRequest:(id)sender
{
	IRCClient *u = self.selectedClient;
	IRCChannel *c = self.selectedChannel;

	if (_noClientOrChannel || _clientIsntLoggedIn) {
		return;
	}

	NSArray *nicknames = [self selectedMembersNicknames:sender];

	if (nicknames.count == 0) {
		return;
	}

	[self deselectMembers:sender];

	NSOpenPanel *openPanel = [NSOpenPanel openPanel];

	openPanel.allowsMultipleSelection = YES;
	openPanel.canChooseDirectories = NO;
	openPanel.canChooseFiles = YES;
	openPanel.canCreateDirectories = NO;
	openPanel.resolvesAliases = YES;

	[openPanel beginSheetModalForWindow:mainWindow() completionHandler:^(NSInteger returnCode) {
		if (returnCode != NSModalResponseOK) {
			return;
		}

		[self.fileTransferController.fileTransferTable beginUpdates];

		for (NSString *nickname in nicknames) {
			for (NSURL *path in openPanel.URLs) {
				(void)[self.fileTransferController addSenderForClient:u nickname:nickname path:path.path autoOpen:YES];
			}
		}

		[self.fileTransferController.fileTransferTable endUpdates];
	}];
}

- (void)memberSendDroppedFilesToSelectedChannel:(NSArray<NSString *> *)files
{
	IRCClient *u = self.selectedClient;
	IRCChannel *c = self.selectedChannel;

	if (_noClientOrChannel || _clientIsntLoggedIn || _isQuery == NO) {
		return;
	}

	[self memberSendDroppedFiles:files to:c.name];
}

- (void)memberSendDroppedFiles:(NSArray<NSString *> *)files row:(NSUInteger)row
{
	IRCClient *u = self.selectedClient;
	IRCChannel *c = self.selectedChannel;

	if (_noClientOrChannel || _clientIsntLoggedIn || _isQuery == NO) {
		return;
	}

	IRCChannelUser *member = [mainWindowMemberList() itemAtRow:row];

	[self memberSendDroppedFiles:files to:member.user.nickname];
}

- (void)memberSendDroppedFiles:(NSArray<NSString *> *)files to:(NSString *)nickname
{
	NSParameterAssert(files != nil);
	NSParameterAssert(nickname != nil);

	IRCClient *u = self.selectedClient;

	if (_noClient || _clientIsntLoggedIn) {
		return;
	}

	[self.fileTransferController.fileTransferTable beginUpdates];

	for (NSString *file in files) {
		BOOL isDirectory = NO;

		if ([RZFileManager() fileExistsAtPath:file isDirectory:&isDirectory] == NO) {
			continue;
		} else {
			if (isDirectory) {
				continue;
			}
		}

		(void)[self.fileTransferController addSenderForClient:u nickname:nickname path:file autoOpen:YES];
	}

	[self.fileTransferController.fileTransferTable endUpdates];
}

- (void)openLogLocation:(id)sender
{	
	NSURL *path = [TPCPathInfo transcriptFolderURL];

	if ([RZFileManager() fileExistsAtURL:path]) {
		(void)[RZWorkspace() openURL:path];

		return;
	}

	[TDCAlert modalAlertWithMessage:TXTLS(@"Prompts[1104][2]")
							  title:TXTLS(@"Prompts[1104][1]")
					  defaultButton:TXTLS(@"Prompts[0005]")
					alternateButton:nil];
}

- (void)openChannelLogs:(id)sender
{
	IRCClient *u = self.selectedClient;
	IRCChannel *c = self.selectedChannel;

	if (_noClientOrChannel) {
		return;
	}

	NSURL *path = c.logFilePath;

	if ([RZFileManager() fileExistsAtURL:path]) {
		(void)[RZWorkspace() openURL:path];

		return;
	}

	[TDCAlert modalAlertWithMessage:TXTLS(@"Prompts[1104][2]")
							  title:TXTLS(@"Prompts[1104][1]")
					  defaultButton:TXTLS(@"Prompts[0005]")
					alternateButton:nil];
}

- (void)connectToTextualHelpChannel:(id)sender 
{
	[IRCExtras createConnectionToServer:@"chat.freenode.net +6697" channelList:@"#textual" connectWhenCreated:YES mergeConnectionIfPossible:YES selectFirstChannelAdded:YES];
}

- (void)connectToTextualTestingChannel:(id)sender
{
	[IRCExtras createConnectionToServer:@"chat.freenode.net +6697" channelList:@"#textual-testing" connectWhenCreated:YES mergeConnectionIfPossible:YES selectFirstChannelAdded:YES];
}

- (void)_showSetVhostPromptOpenDialog:(id)sender
{
	IRCClient *u = self.selectedClient;
	IRCChannel *c = self.selectedChannel;

	if (_noClientOrChannel || _clientIsntLoggedIn) {
		return;
	}

	NSArray *nicknames = [self selectedMembersNicknames:sender];

	if (nicknames.count == 0) {
		return;
	}

	[self deselectMembers:sender];

	void (^promptCompletionBlock)(NSString *) = ^(NSString *resultString)
	{
		if (resultString.length == 0) {
			return;
		}

		NSString *vhost = resultString.trimAndGetFirstToken;

		for (NSString *nickname in nicknames) {
			NSString *command = [NSString stringWithFormat:@"hs setall %@ %@", nickname, vhost];

			[u sendCommand:command completeTarget:NO target:nil];
		}
	};

	NSString *vhost = nil;

	TVCAlertResponse response =
	[TDCInputPrompt promptWithMessage:TXTLS(@"Prompts[1102][2]")
								title:TXTLS(@"Prompts[1102][1]")
						defaultButton:TXTLS(@"Prompts[0005]")
					  alternateButton:TXTLS(@"Prompts[0004]")
						prefillString:nil
						 resultString:&vhost];

	if (response == TVCAlertResponseFirstButton) {
		promptCompletionBlock(vhost);
	}
}

- (void)showSetVhostPrompt:(id)sender
{
	[self _showSetVhostPromptOpenDialog:sender];
}

- (void)showChannelBanList:(id)sender
{
	IRCClient *u = self.selectedClient;
	IRCChannel *c = self.selectedChannel;

	if (_noClientOrChannel || _clientIsntLoggedIn || _isChannel == NO) {
		return;
	}

	[u createChannelBanListSheet];

	[u sendModes:@"+b" withParameters:nil inChannel:c];
}

- (void)showChannelBanExceptionList:(id)sender
{
	IRCClient *u = self.selectedClient;
	IRCChannel *c = self.selectedChannel;

	if (_noClientOrChannel || _clientIsntLoggedIn || _isChannel == NO) {
		return;
	}

	[u createChannelBanExceptionListSheet];

	[u sendModes:@"+e" withParameters:nil inChannel:c];
}

- (void)showChannelInviteExceptionList:(id)sender
{
	IRCClient *u = self.selectedClient;
	IRCChannel *c = self.selectedChannel;

	if (_noClientOrChannel || _clientIsntLoggedIn || _isChannel == NO) {
		return;
	}

	[u createChannelInviteExceptionListSheet];

	[u sendModes:@"+I" withParameters:nil inChannel:c];
}

- (void)showChannelQuietList:(id)sender
{
	IRCClient *u = self.selectedClient;
	IRCChannel *c = self.selectedChannel;

	if (_noClientOrChannel || _clientIsntLoggedIn || _isChannel == NO) {
		return;
	}

	[u createChannelQuietListSheet];

	[u sendModes:@"+q" withParameters:nil inChannel:c];
}

- (void)openHelpMenuItem:(id)sender
{
	NSDictionary *_helpMenuLinks = @{
	   @(901) : @"https://help.codeux.com/textual/End-User-License-Agreement.kb",
	   @(902) : @"https://help.codeux.com/textual/Privacy-Policy.kb",
	   @(930) : @"https://help.codeux.com/textual/Frequently-Asked-Questions.kb",
	   @(933) : @"https://help.codeux.com/textual/home.kb",
	   @(934) : @"https://help.codeux.com/textual/iCloud-Syncing.kb",
	   @(935) : @"https://help.codeux.com/textual/Off-the-Record-Messaging.kb",
	   @(936) : @"https://help.codeux.com/textual/Command-Reference.kb",
	   @(937) : @"https://help.codeux.com/textual/Support.kb",
	   @(938) : @"https://help.codeux.com/textual/Keyboard-Shortcuts.kb",
	   @(939) : @"https://help.codeux.com/textual/Memory-Management.kb",
	   @(940) : @"https://help.codeux.com/textual/Text-Formatting.kb",
	   @(941) : @"https://help.codeux.com/textual/Styles.kb",
	   @(942) : @"https://help.codeux.com/textual/Using-CertFP.kb",
	   @(943) : @"https://help.codeux.com/textual/Connecting-to-ZNC-Bouncer.kb",
	   @(944) : @"https://help.codeux.com/textual/DCC-File-Transfer-Information.kb"
	};

	NSString *link = _helpMenuLinks[@([sender tag])];

	[TLOpenLink openWithString:link inBackground:NO];
}

- (void)openMacAppStoreWebpage:(id)sender
{
	[TLOpenLink openWithString:@"https://www.textualapp.com/mac-app-store" inBackground:NO];
}

- (void)openStandaloneStoreWebpage:(id)sender
{
	[TLOpenLink openWithString:@"https://www.textualapp.com/standalone-store" inBackground:NO];
}

- (void)contactSupport:(id)sender
{
	[TLOpenLink openWithString:@"https://contact.codeux.com/" inBackground:NO];
}

- (void)performNavigationAction:(id)sender
{
	IRCClient *u = self.selectedClient;

	if (_noClient) {
		return;
	}

	switch ([sender tag]) {
		case 701: { [mainWindow() selectNextServer:sender];					break; }
		case 702: { [mainWindow() selectPreviousServer:sender];				break; }
		case 703: { [mainWindow() selectNextActiveServer:sender];			break; }
		case 704: { [mainWindow() selectPreviousActiveServer:sender];		break; }
		case 706: { [mainWindow() selectNextChannel:sender];				break; }
		case 707: { [mainWindow() selectPreviousChannel:sender];			break; }
		case 708: { [mainWindow() selectNextActiveChannel:sender];			break; }
		case 709: { [mainWindow() selectPreviousActiveChannel:sender];		break; }
		case 710: { [mainWindow() selectNextUnreadChannel:sender];			break; }
		case 711: { [mainWindow() selectPreviousUnreadChannel:sender];		break; }
		case 712: { [mainWindow() selectPreviousWindow:sender];				break; }
		case 713: { [mainWindow() selectNextWindow:sender];					break; }
		case 714: { [mainWindow() selectPreviousSelection:sender];			break; }
	}
}

- (void)showMainWindow:(id)sender 
{
	[mainWindow() makeKeyAndOrderFront:sender];
}

- (void)sortChannelListNames:(id)sender
{
	for (IRCClient *u in worldController().clientList) {
		NSMutableArray *channelList = [u.channelList mutableCopy];

		[channelList sortUsingComparator:^NSComparisonResult(IRCChannel *channel1, IRCChannel *channel2) {
			if (channel1.isChannel && channel2.isChannel == NO) {
				return NSOrderedAscending;
			}

			NSString *name1 = channel1.name.lowercaseString;
			NSString *name2 = channel2.name.lowercaseString;

			return [name1 compare:name2];
		}];

		if ([channelList isEqualToArray:u.channelList]) {
			continue;
		}

		u.channelList = channelList;

		[u reloadServerListItems];
	}

	[worldController() save];
}

- (void)resetMainWindowFrame:(id)sender
{
	if (mainWindow().inFullscreenMode) {
		[mainWindow() toggleFullScreen:sender];
	}

	[mainWindow() setFrame:[mainWindow() defaultWindowFrame] display:YES animate:YES];

	[mainWindow() exactlyCenterWindow];
}

- (void)forceReloadTheme:(id)sender
{
	[mainWindow() reloadTheme];
}

- (void)toggleChannelModerationMode:(id)sender
{
#define _toggleChannelModerationModeOffTag		612

	IRCClient *u = self.selectedClient;
	IRCChannel *c = self.selectedChannel;

	if (_noClientOrChannel || _clientIsntLoggedIn || _isChannel == NO) {
		return;
	}

	NSString *modeSymbol = nil;

	if ([sender tag] == _toggleChannelModerationModeOffTag) {
		modeSymbol = @"-m";
	} else {
		modeSymbol = @"+m";
	}

	[u sendModes:modeSymbol withParameters:nil inChannel:c];

#undef _toggleChannelModerationModeOffTag
}

- (void)toggleChannelInviteMode:(id)sender
{
#define _toggleChannelInviteStatusModeOffTag		614

	IRCClient *u = self.selectedClient;
	IRCChannel *c = self.selectedChannel;

	if (_noClientOrChannel || _clientIsntLoggedIn || _isChannel == NO) {
		return;
	}

	NSString *modeSymbol = nil;

	if ([sender tag] == _toggleChannelInviteStatusModeOffTag) {
		modeSymbol = @"-i";
	} else {
		modeSymbol = @"+i";
	}

	[u sendModes:modeSymbol withParameters:nil inChannel:c];

#undef _toggleChannelInviteStatusModeOffTag
}

- (void)toggleDeveloperMode:(id)sender
{
	[TPCPreferences setDeveloperModeEnabled:([TPCPreferences developerModeEnabled] == NO)];

	[TPCPreferences performReloadAction:TPCPreferencesReloadIRCCommandCacheAction];
}

- (void)resetDoNotAskMePopupWarnings:(id)sender
{
	NSDictionary *settings = [RZUserDefaults() dictionaryRepresentation];

	for (NSString *key in settings) {
		if ([key hasPrefix:TDCAlertSuppressionPrefix] == NO) {
			continue;
		}

		[RZUserDefaults() setBool:NO forKey:key];
	}
}

- (void)onNextHighlight:(id)sender
{
	TVCLogController *viewController = self.selectedViewController;

	if (viewController) {
		[viewController nextHighlight];
	}
}

- (void)onPreviousHighlight:(id)sender
{
	TVCLogController *viewController = self.selectedViewController;

	if (viewController) {
		[viewController previousHighlight];
	}
}

- (void)toggleFullscreen:(id)sender
{
	[[NSApp keyWindow] toggleFullScreen:sender];
}

#pragma mark -
#pragma mark Import/Export

- (void)importPreferences:(id)sender
{
	[TPCPreferencesImportExport importInWindow:mainWindow()];
}

- (void)exportPreferences:(id)sender
{
	[TPCPreferencesImportExport exportInWindow:mainWindow()];
}

#pragma mark -
#pragma mark Encryption 

#if TEXTUAL_BUILT_WITH_ADVANCED_ENCRYPTION == 1
#define _encryptionNotEnabled		([TPCPreferences textEncryptionIsEnabled] == NO)

- (void)encryptionStartPrivateConversation:(id)sender
{
	IRCClient *u = self.selectedClient;
	IRCChannel *c = self.selectedChannel;

	if (_encryptionNotEnabled || _noClientOrChannel || _clientIsntLoggedIn || _isQuery == NO) {
		return;
	}

	[sharedEncryptionManager() beginConversationWith:[u encryptionAccountNameForUser:c.name]
												from:[u encryptionAccountNameForLocalUser]];
}

- (void)encryptionRefreshPrivateConversation:(id)sender
{
	IRCClient *u = self.selectedClient;
	IRCChannel *c = self.selectedChannel;

	if (_encryptionNotEnabled || _noClientOrChannel || _clientIsntLoggedIn || _isQuery == NO) {
		return;
	}

	[sharedEncryptionManager() refreshConversationWith:[u encryptionAccountNameForUser:c.name]
												  from:[u encryptionAccountNameForLocalUser]];
}

- (void)encryptionEndPrivateConversation:(id)sender
{
	IRCClient *u = self.selectedClient;
	IRCChannel *c = self.selectedChannel;

	if (_encryptionNotEnabled || _noClientOrChannel || _clientIsntLoggedIn || _isQuery == NO) {
		return;
	}

	[sharedEncryptionManager() endConversationWith:[u encryptionAccountNameForUser:c.name]
											  from:[u encryptionAccountNameForLocalUser]];
}

- (void)encryptionAuthenticateChatPartner:(id)sender
{
	IRCClient *u = self.selectedClient;
	IRCChannel *c = self.selectedChannel;

	if (_encryptionNotEnabled || _noClientOrChannel || _clientIsntLoggedIn || _isQuery == NO) {
		return;
	}

	[sharedEncryptionManager() authenticateUser:[u encryptionAccountNameForUser:c.name]
										   from:[u encryptionAccountNameForLocalUser]];
}

- (void)encryptionListFingerprints:(id)sender
{
	[sharedEncryptionManager() presentListOfFingerprints];
}

- (void)encryptionWhatIsThisInformation:(id)sender
{
	[TLOpenLink openWithString:@"https://help.codeux.com/textual/Off-the-Record-Messaging.kb" inBackground:NO];
}

#undef _encryptionNotEnabled
#endif

#pragma mark -
#pragma mark Toggle Mute

- (void)toggleMuteOnNotificationsShortcut:(NSInteger)state
{
	sharedGrowlController().areNotificationsDisabled = (state == NSOnState);

	self.muteNotificationsFileMenuItem.state = state;

	self.muteNotificationsDockMenuItem.state = state;
}

- (void)toggleMuteOnNotificationSoundsShortcut:(NSInteger)state
{
	[TPCPreferences setSoundIsMuted:(state == NSOnState)];

	self.muteNotificationsSoundsDockMenuItem.state = state;

	self.muteNotificationsSoundsFileMenuItem.state = state;
}

- (void)toggleMuteOnNotificationSounds:(id)sender
{
	if ([TPCPreferences soundIsMuted]) {
		[self toggleMuteOnNotificationSoundsShortcut:NSOffState];
	} else {
		[self toggleMuteOnNotificationSoundsShortcut:NSOnState];
	}
}

- (void)toggleMuteOnNotifications:(id)sender
{
	if (sharedGrowlController().areNotificationsDisabled) {
		[self toggleMuteOnNotificationsShortcut:NSOffState];
	} else {
		[self toggleMuteOnNotificationsShortcut:NSOnState];
	}
}

#pragma mark -
#pragma mark Splitview Toggles

- (void)toggleServerListVisibility:(id)sender
{
	[mainWindow().contentSplitView toggleServerListVisibility];
}

- (void)toggleMemberListVisibility:(id)sender
{
	mainWindowMemberList().isHiddenByUser = (mainWindowMemberList().isHiddenByUser == NO);

	[mainWindow().contentSplitView toggleMemberListVisibility];
}

#pragma mark -
#pragma mark Appearance Toggle

- (void)toggleMainWindowAppearance:(id)sender
{
	[TPCPreferences setInvertSidebarColors:([TPCPreferences invertSidebarColors] == NO)];

	[TPCPreferences performReloadAction:TPCPreferencesReloadMainWindowAppearanceAction];
}

#pragma mark -
#pragma mark License Manager

- (void)manageLicense:(id)sender
{
#if TEXTUAL_BUILT_WITH_LICENSE_MANAGER == 1
	[self manageLicense:sender activateLicenseKey:nil licenseKeyPassedByArgument:NO];
#endif
}

#if TEXTUAL_BUILT_WITH_LICENSE_MANAGER == 1
- (void)manageLicense:(id)sender activateLicenseKey:(nullable NSString *)licenseKey
{
	[self manageLicense:sender activateLicenseKey:licenseKey licenseKeyPassedByArgument:NO];
}

- (void)manageLicense:(id)sender activateLicenseKeyWithURL:(NSURL *)licenseKeyURL
{
	NSParameterAssert(licenseKeyURL != nil);

	NSString *path = licenseKeyURL.path;

	if (path == nil) {
		return;
	}

	NSCharacterSet *slashCharacterSet = [NSCharacterSet characterSetWithCharactersInString:@"/"];

	NSString *licenseKey = [path stringByTrimmingCharactersInSet:slashCharacterSet];

	if (licenseKey.length == 0) {
		return;
	}

	[self manageLicense:sender activateLicenseKey:licenseKey licenseKeyPassedByArgument:NO];
}

- (void)manageLicense:(id)sender activateLicenseKey:(nullable NSString *)licenseKey licenseKeyPassedByArgument:(BOOL)licenseKeyPassedByArgument
{
	TDCLicenseManagerDialog *licenseDialog = [TXSharedApplication sharedLicenseManagerDialog];

	[licenseDialog show];

	if (licenseKey) {
		[licenseDialog activateLicenseKey:licenseKey silently:licenseKeyPassedByArgument];
	}
}
#endif

#pragma mark -
#pragma mark In-app Purchase

- (void)manageInAppPurchase:(id)sender
{
#if TEXTUAL_BUILT_FOR_APP_STORE_DISTRIBUTION == 1
	[[TXSharedApplication sharedInAppPurchaseDialog] show];
#endif
}

#pragma mark -
#pragma mark Developer Tools

- (void)simulateCrash:(id)sender
{
#if TEXTUAL_BUILT_WITH_HOCKEYAPP_SDK_ENABLED == 1
	[[BITHockeyManager sharedHockeyManager].crashManager generateTestCrash];
#endif
}

#pragma mark -
#pragma mark Sparkle Framework

- (void)checkForUpdates:(id)sender
{
#if TEXTUAL_BUILT_WITH_SPARKLE_ENABLED == 1
	[[SUUpdater sharedUpdater] checkForUpdates:sender];
#endif
}

#pragma mark -
#pragma mark Navigation

- (void)copyUniqueIdentifier:(id)sender
{
	IRCChannel *c = self.selectedChannel;

	if (_noChannel) {
		return;
	}
	
	[RZPasteboard() setStringContent:c.uniqueIdentifier];
}

- (void)navigateToTreeItemAtURL:(NSURL *)url
{
	NSParameterAssert(url != nil);

	NSString *path = url.path;
	
	if (path == nil) {
		return;
	}
	
	NSCharacterSet *slashCharacterSet = [NSCharacterSet characterSetWithCharactersInString:@"/"];
	
	NSString *identifier = [path stringByTrimmingCharactersInSet:slashCharacterSet];
	
	if (identifier.length == 0) {
		return;
	}
	
	[self navigateToTreeItemWithIdentifier:identifier];
}

- (void)navigateToTreeItemWithIdentifier:(NSString *)identifier
{
	NSParameterAssert(identifier != nil);
	
	/* Do not use assert for this condition so we
	 don't crash user when we open a malformed URL. */
	if (identifier.length != 36) {
		return;
	}
	
	IRCTreeItem *item = [worldController() findItemWithId:identifier];
	
	if (item == nil) {
		return;
	}
	
	[self navigateToTreeItem:item];
}

- (void)navigateToTreeItem:(IRCTreeItem *)item
{
	NSParameterAssert(item != nil);
	
	[mainWindow() select:item];
}

@end

#pragma mark -

@implementation TXMenuControllerMainWindowProxy

- (void)openStandaloneStoreWebpage:(id)sender
{
	[menuController() openStandaloneStoreWebpage:sender];
}

- (void)openMacAppStoreWebpage:(id)sender
{
	[menuController() openMacAppStoreWebpage:sender];
}

- (void)manageLicense:(id)sender
{
	[menuController() manageLicense:sender];
}

- (void)showWelcomeSheet:(id)sender
{
	[menuController() showWelcomeSheet:sender];
}

@end

NS_ASSUME_NONNULL_END
