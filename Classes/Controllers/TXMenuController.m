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

#import "TextualApplication.h"

#if TEXTUAL_BUILT_WITH_LICENSE_MANAGER == 1
#import "TLOLicenseManager.h"
#endif

#import "TVCLogObjectsPrivate.h"

#define _activate					(c && [c isActive])
#define _notActive					(c && [c isActive] == NO)
#define _connected					(u && [u isConnected])
#define _notConnected				(u && [u isConnected] == NO && [u isConnecting] == NO)
#define _connectionLoggedIn			(u && [u isConnected] && [u isLoggedIn])
#define _connectionNotLoggedIn		(u && [u isConnected] == NO && [u isLoggedIn] == NO)
#define _isChannel					([c isPrivateMessage] == NO && [c isChannel] == YES && [c isClient] == NO)
#define _isClient					([c isPrivateMessage] == NO && [c isChannel] == NO && [c isClient] == YES)
#define _isQuery					([c isPrivateMessage] == YES && [c isChannel] == NO && [c isClient] == NO)
#define _noChannel					(c == nil)
#define _noClient					(u == nil)
#define _noClientOrChannel			(u == nil || c == nil)

#define _serverCurrentConfig		[u config]

#define _channelConfig				[c config]

#define	_popWindowViewIfExists(c)	if ([windowController() maybeBringWindowForward:(c)]) {		\
										return;													\
									}

@interface TXMenuController ()
@property (nonatomic, strong) NSMutableDictionary *openWindowList;
@property (nonatomic, copy) NSString *currentSearchPhrase;
@end

@implementation TXMenuController

- (instancetype)init
{
	if ((self = [super init])) {
		self.currentSearchPhrase = NSStringEmptyPlaceholder;
	}
	
	return self;
}

- (void)setupOtherServices
{
 	 self.fileTransferController = [TDCFileTransferDialog new];

	[self.fileTransferController startUsingDownloadDestinationFolderSecurityScopedBookmark];
}

- (void)prepareForApplicationTermination
{
	[self.fileTransferController prepareForApplicationTermination];
}

- (void)preferencesChanged
{
	[self.fileTransferController clearCachedIPAddress];
}

- (void)mainWindowSelectionDidChange
{
	[self forceAllChildrenElementsOfMenuToValidate:[NSApp mainMenu] recursively:YES];
}

- (void)forceAllChildrenElementsOfMenuToValidate:(NSMenu *)menu
{
	[self forceAllChildrenElementsOfMenuToValidate:menu recursively:YES];
}

- (void)forceAllChildrenElementsOfMenuToValidate:(NSMenu *)menu recursively:(BOOL)recursively
{
	for (NSMenuItem *item in [menu itemArray]) {
		if ([item target]) {
			if ([[item target] respondsToSelector:@selector(validateMenuItem:)]) {
				(void)[[item target] performSelector:@selector(validateMenuItem:) withObject:item];
			}
		}

		if (recursively) {
			if ([item hasSubmenu]) {
				[self forceAllChildrenElementsOfMenuToValidate:[item submenu]];
			}
		}
	}
}

- (BOOL)validateMenuItem:(NSMenuItem *)item
{
	return [self validateMenuItemTag:[item tag] forItem:item];
}

- (BOOL)validateMenuItemTag:(NSInteger)tag forItem:(NSMenuItem *)item
{
	BOOL isMainWindowMain = [mainWindow() isMainWindow];

	BOOL mainWindowHasSheet = ([mainWindow() attachedSheet] != nil);

	BOOL frontmostWindowIsMainWindow = [mainWindow() isBeneathMouse];

	BOOL returnValue = [self validateSpecificMenuItemTag:tag forItem:item];

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
								[item setHidden:YES];

								[[[item menu] itemWithTag:816] setHidden:YES]; // Menu Separator
								[[[item menu] itemWithTag:817] setHidden:YES]; // Menu Separator
								[[[item menu] itemWithTag:818] setHidden:YES]; // Menu Separator
							} else {
								[item setHidden:NO];

								[[[item menu] itemWithTag:816] setHidden:NO]; // Menu Separator
								[[[item menu] itemWithTag:817] setHidden:NO]; // Menu Separator
								[[[item menu] itemWithTag:818] setHidden:NO]; // Menu Separator
							}
						}

						/* Hide "Main Window" if Main Window is key. */
						/* Hide all other items when Main Window is NOT key. */
						if (tag == 808) { // "Main Window"
							if (isMainWindowMain) {
								[item setHidden:YES];
							} else {
								[item setHidden:NO];
							}
						}
						else // tag == 808
						{
							if (isMainWindowMain == NO) {
								[item setHidden:YES];
							} else {
								[item setHidden:NO];
							}
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

			/* If trial is expired, default everything to disabled. */
			BOOL isTrialExpired = NO;

#if TEXTUAL_BUILT_WITH_LICENSE_MANAGER == 1
			if (TLOLicenseManagerTextualIsRegistered() == NO && TLOLicenseManagerIsTrialExpired()) {
				/* Disable everything by default except tag 900 through 916. These are various
				 help menu links. See TXMenuController.h for complete list of tags. */
				if (tag < 900 || (tag > 916 && tag < 927)) {
					returnValue = NO;
				}

				/* Enable specific items after it has been disabled. */
				/* Other always-required items are enabled further 
				 below this switch statement. */
				if (tag == 102) { // "Manage license…"
					[item setHidden:NO];

					returnValue = YES;
				}

				isTrialExpired = YES;
			}
#endif

			/* If certain items are hidden because of sheet but not because of
			 the trial being expired, then enable additional items. */
			if (returnValue == NO && defaultToNoForSheet == YES && isTrialExpired == NO) {
				switch (tag) {
					case 100: // "About Textual"
					case 101: // "Preferences…"
					case 102: // "Manage license…"
					case 103: // "Check for updates…"
					{
						returnValue = YES;
					}
				}
			}

			/* These are the bare minimium of menu items that must be enabled
			 at all times because they are essential to the entire application. */
			if (returnValue == NO) {
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
					{
						returnValue = YES;
					} // case
				} // switch
			} // if returnValue == NO
		} // case 100 ... 999
	} // switch

	return returnValue;
}

- (BOOL)validateSpecificMenuItemTag:(NSInteger)tag forItem:(NSMenuItem *)item
{
	IRCClient *u = [mainWindow() selectedClient];
	IRCChannel *c = [mainWindow() selectedChannel];

	switch (tag) {
		case 315: // "Search With Google"
		case 1601: // "Search With Google"
		{
			TVCLogView *web = [self currentLogControllerBackingView];

			PointerIsEmptyAssertReturn(web, NO);

			NSString *searchProviderName = [self searchProviderName];

			[item setTitle:BLS(3004, searchProviderName)];

			return [web hasSelection];
		}
		case 1608: // "Look Up in Dictionary"
		{
			TVCLogView *web = [self currentLogControllerBackingView];

			PointerIsEmptyAssertReturn(web, NO);

			NSString *selection = [web selection];

			if (NSObjectIsEmpty(selection) || [selection length] > 40) {
				[item setTitle:BLS(1296)];

				return NO;
			} else {
				if ([selection length] > 25) {
					selection = [selection substringToIndex:24];

					selection = [NSString stringWithFormat:@"%@…", [selection trim]];
				}

				[item setTitle:BLS(1297, selection)];

				return YES;
			}
		}
		case 802: // "Toggle Visiblity of Member List"
		{
			return _isChannel;
		}
		case 606: // "Query Logs"
		case 1606: // "Query Logs"
		{
			if (_isQuery) {
				[item setHidden:NO];

				return [TPCPreferences logToDiskIsEnabled];
			} else {
				[item setHidden:YES];

				return NO;
			}
		}
		case 608: // "View Logs"
		case 811: // "View Logs"
		{
			BOOL condition = [TPCPreferences logToDiskIsEnabled];

			return condition;
		}
		case 607: // "Channel Properties"
		{
			BOOL condition = _isChannel;

			[item setHidden:(condition == NO)];

			return condition;
		}
		case 006: // "Channel" (Main Menu)
		case 1607: // "Channel" (WebView)
		{
#define _channelMenuSeparatorTag_1			602
#define _channelMenuSeparatorTag_2			605
#define _channelMenuSeparatorTag_3			1605
#define _channelWebkitMenuTag				1607

			NSMenu *hostMenu = nil;

			if (tag == _channelWebkitMenuTag) {
				[item setHidden:(_isChannel == NO)];

				hostMenu = [item menu];
			} else {
				hostMenu = [item submenu];
			}

			BOOL condition2 =   _isQuery;
			BOOL condition1 = ( _isQuery || _isChannel);

			[[hostMenu itemWithTag:_channelMenuSeparatorTag_1] setHidden:condition2];

			[[hostMenu itemWithTag:_channelMenuSeparatorTag_2] setHidden:(condition1 == NO)];
			[[hostMenu itemWithTag:_channelMenuSeparatorTag_3] setHidden:(condition1 == NO)];

#undef _channelMenuSeparatorTag_1
#undef _channelMenuSeparatorTag_2
#undef _channelMenuSeparatorTag_3
#undef _channelWebkitMenuTag

			return YES;
		}
		case 500: // "Connect"
		{
			if (_noClient) {
				return NO;
			}

			BOOL condition = (_connected || [u isConnecting]);
			
			[item setHidden:condition];

			BOOL prefersIPv6 = [_serverCurrentConfig connectionPrefersIPv6];

			NSUInteger flags = ([NSEvent modifierFlags] & NSDeviceIndependentModifierFlagsMask);

			if (flags == NSAlternateKeyMask) {
				if (prefersIPv6) {
					prefersIPv6 = NO;

					[item setTitle:TXTLS(@"BasicLanguage[1233][2]")];
				} else {
					prefersIPv6 = YES;

					[item setTitle:TXTLS(@"BasicLanguage[1233][3]")];
				}
			} else {
				[item setTitle:TXTLS(@"BasicLanguage[1233][1]")];
			}

			if (prefersIPv6) {
				[item setAction:@selector(connectPreferringIPv6:)];
			} else {
				[item setAction:@selector(connectPreferringIPv4:)];
			}

			return (condition == NO && [u isQuitting] == NO);
		}
		case 501: // "Disconnect"
		{
			BOOL condition = (_connected || [u isConnecting]);
			
			[item setHidden:(condition == NO)];
			
			return condition;
		}
		case 502: // "Cancel Reconnect"
		{
			BOOL condition = [u isReconnecting];
			
			[item setHidden:(condition == NO)];
			
			return condition;
		}
		case 503: // "Change Nickname…"
		case 504: // "Channel List…"
		{
			return _connectionLoggedIn;
		}
		case 507: // "Delete Server"
		{
			return _notConnected;
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
			if (_isQuery) {
				[item setHidden:YES];
				
				return NO;
			} else {
				BOOL condition = (_connectionLoggedIn && _notActive && _isChannel);
				
				if (_connectionLoggedIn) {
					[item setHidden:(condition == NO)];
				} else {
					[item setHidden:NO];
				}
				
				return condition;
			}
		}
		case 601: // "Leave Channel"
		{
			if (_isQuery) {
				[item setHidden:YES];
				
				return NO;
			} else {
				[item setHidden:_notActive];
				
				return _activate;
			}
		}
		case 603: // "Add Channel…"
		{
			if (_isQuery) {
				[item setHidden:YES];
				
				return NO;
			} else {
				[item setHidden:NO];
				
				return (_noClient == NO);
			}
		}
		case 604: // "Delete Channel"
		{
			if (_isQuery) {
				[item setTitle:BLS(1025)];
				
				return YES;
			} else {
				[item setTitle:BLS(1024)];
				
				return _isChannel;
			}
		}
		case 1201: // "Add Channel…" - Server Menu
		{
			return (_noClient == NO);
		}
		case 1500: // "Invite To…"
		{
			if ([self checkSelectedMembers:item] == NO) {
				return NO;
			}

			NSInteger count = 0;

			for (IRCChannel *e in [u channelList]) {
				if (NSDissimilarObjects(c, e) && [e isChannel]) {
					++count;
				}
			}
			
			return (count > 0);
		}
		case 9631: // "Close Window"
		{
			TVCMainWindow *mainWindow = mainWindow();
			
			if ([mainWindow isKeyWindow]) {
				TXCommandWKeyAction keyAction = [TPCPreferences commandWKeyAction];
				
				if (_noClient) {
					if (NSDissimilarObjects(keyAction, TXCommandWKeyCloseWindowAction)) {
						return NO;
					}
				}

				switch (keyAction) {
					case TXCommandWKeyCloseWindowAction:
					{
						[item setTitle:BLS(1013)];

						break;
					}
					case TXCommandWKeyPartChannelAction:
					{
						if (_noChannel) {
							[item setTitle:BLS(1013)];

							return NO;
						} else {
							if (_isChannel) {
								[item setTitle:BLS(1015)];
								
								if (_notActive) {
									return NO;
								}
							} else {
								[item setTitle:BLS(1012)];
							}
						}
						
						break;
					}
					case TXCommandWKeyDisconnectAction:
					{
						[item setTitle:BLS(1014, [u altNetworkName])];
						
						if (_notConnected) {
							return NO;
						}
						
						break;
					}
					case TXCommandWKeyTerminateAction:
					{
						[item setTitle:BLS(1016)];
						
						break;
					}
				}
			} else {
				[item setTitle:BLS(1013)];
			}
			
			return YES;
		}
		case 812: // "Highlight List"
		{
			return ([TPCPreferences logHighlights] && _connectionLoggedIn);
		}
        case 920: // Developer Mode
        {
            if ([RZUserDefaults() boolForKey:TXDeveloperEnvironmentToken] == YES) {
                [item setState:NSOnState];
            } else {  
                [item setState:NSOffState];
            }
            
            return YES;
		}

#if TEXTUAL_BUILT_WITH_SPARKLE_ENABLED == 1
		case 926: // Download Beta Updates
		{
			if ([TPCPreferences receiveBetaUpdates] == YES) {
				[item setState:NSOnState];
			} else {
				[item setState:NSOffState];
			}

			return YES;
		}
#endif

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

			BOOL valid = [sharedEncryptionManager() validateMenuItem:item
														 withStateOf:[u encryptionAccountNameForUser:[c name]]
																from:[u encryptionAccountNameForLocalUser]];

			if (_connectionNotLoggedIn) {
				return NO;
			} else {
				return valid;
			}
		}
#endif

		case 1502: // "Private Message (Query)"
		case 1503: // "Give Op (+o)"
		case 1504: // "Give Halfop (+h)"
		case 1505: // "Give Voice (+v)"
		case 1507: // "Take Op (-o)"
		case 1508: // "Take Halfop (-h)"
		case 1509: // "Take Voice (-v)"
		{
			if (_isChannel) {
				return [self checkSelectedMembers:item];
			} else {
				return NO;
			}
		}
		case 1511: // "Ban"
		case 1512: // "Kick"
		case 1513: // "Ban and Kick"
		{

#define _userControlsBanKickSeparatorTag		1531

			BOOL condition1 = (_isChannel);

			[item setHidden:(condition1 == NO)];

			[[[item menu] itemWithTag:_userControlsBanKickSeparatorTag] setHidden:(condition1 == NO)];

			if (condition1) {
				return [self checkSelectedMembers:item];
			} else {
				return NO;
			}

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

#define _ui(tag, value)				[[[item menu] itemWithTag:(tag)] setHidden:(value)];

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

			NSArray *nicknames = [self selectedMembers:item];

			if ([nicknames count] == 1)
			{
				IRCUser *m = nicknames[0];

				IRCUserRank userRanks = [m ranks];

				BOOL UserHasModeO = ((userRanks & IRCUserNormalOperatorRank) == IRCUserNormalOperatorRank);
				BOOL UserHasModeH = ((userRanks & IRCUserHalfOperatorRank) == IRCUserHalfOperatorRank);
				BOOL UserHasModeV = ((userRanks & IRCUserVoicedRank) == IRCUserVoicedRank);

				_ui(_userControlsMenuGiveModeOMenuTag, UserHasModeO)
				_ui(_userControlsMenuGiveModeVMenuTag, UserHasModeV)
				_ui(_userControlsMenuTakeModeOMenuTag, (UserHasModeO == NO))
				_ui(_userControlsMenuTakeModeVMenuTag, (UserHasModeV == NO))

				BOOL halfOpModeSupported = [[u supportInfo] modeIsSupportedUserPrefix:@"h"];

				if (halfOpModeSupported == NO) {
					_ui(_userControlsMenuGiveModeHMenuTag, YES)
					_ui(_userControlsMenuTakeModeHMenuTag, YES)
				} else {
					_ui(_userControlsMenuGiveModeHMenuTag,  UserHasModeH)
					_ui(_userControlsMenuTakeModeHMenuTag, (UserHasModeH == NO))
				}
				
				BOOL hideTakeSepItem = (UserHasModeO == NO  || UserHasModeH == NO  || UserHasModeV == NO);
				BOOL hideGiveSepItem = (UserHasModeO == YES || UserHasModeH == YES || UserHasModeV == YES);

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
		{
			TVCLogController *currentView = [mainWindow() selectedViewController];

			return ([currentView highlightAvailable:NO]);
		}
		case 716: // "Previous Highlight"
		{
			TVCLogController *currentView = [mainWindow() selectedViewController];

			return ([currentView highlightAvailable:YES]);
		}
		case 1603: // "Copy" (WebView)
		{
			TVCLogView *web = [self currentLogControllerBackingView];

			PointerIsEmptyAssertReturn(web, NO);

			return [web hasSelection];

			break;
		}
		case 304: // "Paste"
		case 1604: // "Paste" (WebView)
		{
			NSString *currentPasteboard = [RZPasteboard() stringContent];

			if (NSObjectIsEmpty(currentPasteboard)) {
				return NO;
			}

			if ([mainWindow() isKeyWindow]) {
				return ([mainWindowTextField() isEditable]);
			} else {
				id firstResponder = [[NSApp keyWindow] firstResponder];

				if ([firstResponder respondsToSelector:@selector(isEditable)]) {
					return [firstResponder isEditable];
				} else {
					return NO;
				}
			}
		}
		case 804: // "Toggle Window Appearance"
		{
			BOOL condition = [RZUserDefaults() boolForKey:@"Theme -> Invert Sidebar Colors Preference Enabled"];

			return condition;
		}
		default:
		{
			return YES;
		}
	}

	return YES;
}

#pragma mark -
#pragma mark Utilities

- (TVCLogView *)currentLogControllerBackingView
{
	TVCLogController *currentView = [mainWindow() selectedViewController];

	return [currentView backingView];
}

#pragma mark -
#pragma mark Navigation Channel List

- (void)populateNavgiationChannelList
{
#define _channelNavigationMenuEntryMenuTag		717
	
	/* Remove all previous entries. */
	[self.navigationChannelList removeAllItems];

	/* Begin populating... */
	NSInteger channelCount = 0;

	for (IRCClient *u in [worldController() clientList]) {
		/* Create a menu item for the client title. */
		NSMenuItem *serverNewMenuItem = [NSMenuItem new];

		[serverNewMenuItem setTitle:BLS(1183, [u name])];

		NSMenu *serverNewMenu = [NSMenu new];

		[serverNewMenuItem setSubmenu:serverNewMenu];

		[self.navigationChannelList addItem:serverNewMenuItem];

		/* Begin populating channels. */
		for (IRCChannel *c in [u channelList]) {
			/* Create the menu item. Only first ten items get a key combo. */
			NSMenuItem *channelNewMenuItem = nil;

			if (channelCount >= 10) {
				channelNewMenuItem = [NSMenuItem menuItemWithTitle:BLS(1184, [c name])
															target:self
															action:@selector(navigateToSpecificChannelInNavigationList:)];
			} else {
				NSInteger keyboardIndex = (channelCount + 1);

				if (keyboardIndex == 10) {
					keyboardIndex = 0; // Have 0 as the last item.
				}
				
				channelNewMenuItem = [NSMenuItem menuItemWithTitle:BLS(1184, [c name])
															target:self
															action:@selector(navigateToSpecificChannelInNavigationList:)
													 keyEquivalent:[NSString stringWithUniChar:('0' + keyboardIndex)]
												 keyEquivalentMask:NSCommandKeyMask];
			}

			/* The tag identifies each item. */
			[channelNewMenuItem setUserInfo:[worldController() pasteboardStringForItem:c]];
			
			[channelNewMenuItem setTag:_channelNavigationMenuEntryMenuTag]; // Use same tag for each to disable during sheets.

			/* Add to the actaul navigation list. */
			[serverNewMenu addItem:channelNewMenuItem];

			/* Bump the count... */
			channelCount += 1;
		}
	}
	
#undef _channelNavigationMenuEntryMenuTag
}

- (void)navigateToSpecificChannelInNavigationList:(NSMenuItem *)sender
{
	id treeItem = [worldController() findItemFromPasteboardString:[sender userInfo]];

	if (treeItem) {
		[mainWindow() select:treeItem];
	}
}

#pragma mark -
#pragma mark Selected User(s)

- (BOOL)checkSelectedMembers:(id)sender
{
	return ([[self selectedMembers:sender] count] > 0);
}

- (NSArray *)selectedMembers:(id)sender
{
	return [self selectedMembers:sender returnStrings:NO];
}

- (NSArray *)selectedMembersNicknames:(id)sender
{
	return [self selectedMembers:sender returnStrings:YES];
}

- (id)selectedMembers:(id)sender returnStrings:(BOOL)returnStrings
{
	IRCClient *u = [mainWindow() selectedClient];
	IRCChannel *c = [mainWindow() selectedChannel];

	/* Return an empty array under certain conditions */
	if (_noClientOrChannel || _notActive || _connectionNotLoggedIn || _isClient) {
		return nil;
	}

	/* Return a specific nickname for WebView events */
	NSString *pointedNickname = nil;
	
	if ([sender isKindOfClass:[NSMenuItem class]]) {
		pointedNickname = [(NSMenuItem *)sender userInfo];
	} else {
		pointedNickname = [self pointedNickname];
	}
	
	if (pointedNickname) {
		if (returnStrings) {
			return @[pointedNickname];
		} else {
			IRCUser *m = [c findMember:pointedNickname];

			if (m) {
				return @[m];
			} else {
				return nil;
			}
		}
	}

	/* If we did not have a specific nickname, then query
	 the user list for selected rows. */
	NSMutableArray *userArray = nil;

	NSIndexSet *indexes = [mainWindowMemberList() selectedRowIndexes];

	for (NSNumber *index in [indexes arrayFromIndexSet]) {
		NSUInteger nindex = [index unsignedIntegerValue];
		
		IRCUser *m = [mainWindowMemberList() itemAtRow:nindex];
		
		if (m) {
			if (userArray == nil) {
				userArray = [NSMutableArray arrayWithCapacity:[indexes count]];
			}

			if (returnStrings) {
				[userArray addObject:[m nickname]];
			} else {
				[userArray addObject:m];
			}
		}
	}

	if (userArray) {
		return [userArray copy];
	} else {
		return nil;
	}
}

- (void)deselectMembers:(id)sender
{
	if ([sender isKindOfClass:[NSMenuItem class]]) {
		if ([[(NSMenuItem *)sender userInfo] length] > 0) {
			return; // Nothing to deselect when our sender used userInfo
		}
	}
	
	if ([self pointedNickname]) {
		[self setPointedNickname:nil];
	} else {
		[mainWindowMemberList() deselectAll:sender];
	}
}

#pragma mark -
#pragma mark Find Panel

- (void)internalOpenFindPanel:(id)sender
{
	_popWindowViewIfExists(@"TXMenuControllerFindPanel");

	TVCInputPromptDialog *dialog = [TVCInputPromptDialog new];

	[dialog alertWithMessageTitle:TXTLS(@"BasicLanguage[1026][3]")
					defaultButton:TXTLS(@"BasicLanguage[1026][1]")
				  alternateButton:BLS(1009)
				  informativeText:TXTLS(@"BasicLanguage[1026][2]")
				 defaultUserInput:self.currentSearchPhrase
				  completionBlock:^(TVCInputPromptDialog *sender, BOOL defaultButtonClicked, NSString *resultString) {
					  if (defaultButtonClicked) {
						  if (NSObjectIsEmpty(resultString)) {
							  self.currentSearchPhrase = NSStringEmptyPlaceholder;
						  } else {
							  if ([resultString isNotEqualTo:self.currentSearchPhrase]) {
								  self.currentSearchPhrase = resultString;
							  }

							  [self performBlockOnMainThread:^{
								  TVCLogView *web = [self currentLogControllerBackingView];

								  [web findString:resultString movingForward:YES];
							  }];
						  }
					  }

					  [windowController() removeWindowFromWindowList:@"TXMenuControllerFindPanel"];
				  }];

	[windowController() addWindowToWindowList:dialog withDescription:@"TXMenuControllerFindPanel"];
}

- (void)showFindPanel:(id)sender
{
#define _findPanelOpenPanelMenuTag		308
#define _findPanelMoveForwardMenuTag	309

	if ([sender tag] == _findPanelOpenPanelMenuTag || NSObjectIsEmpty(self.currentSearchPhrase)) {
		[self internalOpenFindPanel:sender];
	} else {
		TVCLogView *web = [self currentLogControllerBackingView];

		if ([sender tag] == _findPanelMoveForwardMenuTag) {
			[web findString:self.currentSearchPhrase movingForward:YES];
		} else {
			[web findString:self.currentSearchPhrase movingForward:NO];
		}
	}

#undef _findPanelOpenPanelMenuTag
#undef _findPanelMoveForwardMenuTag
}

#pragma mark -
#pragma mark Command + W Keyboard Shortcut

- (void)commandWShortcutUsed:(id)sender
{
	NSWindow *currentWindow = [NSApp keyWindow];
	
	IRCClient *u = [mainWindow() selectedClient];
	IRCChannel *c = [mainWindow() selectedChannel];

	TVCMainWindow *mainWindow = mainWindow();
	
	if ([mainWindow isKeyWindow]) {
		switch ([TPCPreferences commandWKeyAction]) {
			case TXCommandWKeyCloseWindowAction:
			{
				[mainWindow close];
				
				break;
			}
			case TXCommandWKeyPartChannelAction:
			{
				if (_noClientOrChannel || _isClient) {
					return;
				}
				
				if (_isChannel && _activate) {
					[u partChannel:c];
				} else {
					if (_isQuery) {
						[worldController() destroyChannel:c];
					}
				}
				
				break;
			}
			case TXCommandWKeyDisconnectAction:
			{
				if (_noClient || _notConnected) {
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
		}
	} else {
		[currentWindow performClose:nil];
	}
}

#pragma mark -
#pragma mark File Transfers Dialog

- (void)showFileTransfersDialog:(id)sender
{
	[self.fileTransferController show:YES restorePosition:YES];
}

#pragma mark -
#pragma mark Preferences Dialog

- (void)showPreferencesDialog:(id)sender
{
	_popWindowViewIfExists(@"TDCPreferencesController");
	
	TDCPreferencesController *pc = [TDCPreferencesController new];
	
	pc.delegate = self;
	
	[pc show];

	[windowController() addWindowToWindowList:pc];
}

- (void)preferencesDialogWillClose:(TDCPreferencesController *)sender
{
	[worldController() preferencesChanged];

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
	if ([[[NSApp keyWindow] firstResponder] respondsToSelector:@selector(copy:)]) {
		[[[NSApp keyWindow] firstResponder] performSelector:@selector(copy:) withObject:nil];
	}
}

- (void)paste:(id)sender
{
	if ([mainWindow() isKeyWindow]) {
		[mainWindowTextField() focus];

		[mainWindowTextField() paste:sender];
	} else {
		if ([[[NSApp keyWindow] firstResponder] respondsToSelector:@selector(paste:)]) {
			[[[NSApp keyWindow] firstResponder] performSelector:@selector(paste:) withObject:nil];
		}
	}
}

- (void)print:(id)sender
{
	if ([mainWindow() isKeyWindow] == NO) {
		[[NSApp keyWindow] print:sender];
	} else {
		TVCLogView *web = [self currentLogControllerBackingView];

		[web print];
	}
}

- (void)closeWindow:(id)sender
{
	[[NSApp keyWindow] performClose:nil];
}

- (void)centerMainWindow:(id)sender
{
	[mainWindow() exactlyCenterWindow];
}

- (void)onCloseCurrentPanel:(id)sender
{
	IRCChannel *c = [mainWindow() selectedChannel];
	
	if (c) {
		[worldController() destroyChannel:c];
		[worldController() save];
	}
}

- (void)showAcknowledgments:(id)sender
{
	NSString *acknowledgmentsPath = [RZMainBundle() pathForResource:@"Acknowledgments" ofType:@"pdf" inDirectory:@"Documentation"];
	
	[RZWorkspace() openFile:acknowledgmentsPath];
}

- (void)showScriptingDocumentation:(id)sender
{
	[TLOpenLink openWithString:@"https://help.codeux.com/textual/Writing-Scripts.kb"];
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
	TVCLogView *web = [self currentLogControllerBackingView];

	PointerIsEmptyAssert(web);
	
	NSString *s = [web selection];

	NSObjectIsEmptyAssert(s);

	NSPasteboard *searchPasteboard = [NSPasteboard pasteboardWithUniqueName];

	[searchPasteboard setStringContent:s];

	NSPerformService(@"Search With %WebSearchProvider@", searchPasteboard);
}

- (void)lookUpInDictionary:(id)sender
{
	TVCLogView *web = [self currentLogControllerBackingView];

	PointerIsEmptyAssert(web);

	NSString *s = [web selection];

	NSObjectIsEmptyAssert(s);

	NSString *urlStr = [NSString stringWithFormat:@"dict://%@", [s gtm_stringByEscapingForURLArgument]];

	[TLOpenLink openWithString:urlStr];
}

- (void)copyLogAsHtml:(id)sender
{
	TVCLogView *sel = [self currentLogControllerBackingView];

	PointerIsEmptyAssert(sel);

	[sel copyContentString];
}

- (void)openWebInspector:(id)sender
{
	TVCLogView *sel = [self currentLogControllerBackingView];

	PointerIsEmptyAssert(sel);

	if ([sel isUsingWebKit2] == NO) {
		NSAssert(NO, @"Missing implementation");
	}

	[(TVCLogViewInternalWK2 *)[sel webView] openWebInspector];
}

- (void)markScrollback:(id)sender
{
	TVCLogController *sel = [mainWindow() selectedViewController];

	PointerIsEmptyAssert(sel);
	
	[sel mark];
}

- (void)gotoScrollbackMarker:(id)sender
{
	TVCLogController *sel = [mainWindow() selectedViewController];

	PointerIsEmptyAssert(sel);
	
	[sel goToMark];
}

- (void)clearScrollback:(id)sender
{
	IRCClient *u = [mainWindow() selectedClient];
	IRCChannel *c = [mainWindow() selectedChannel];
	
    if (u) {
        if (c) {
            [worldController() clearContentsOfChannel:c inClient:u];
        } else {
            [worldController() clearContentsOfClient:u];
        }
    }
}

- (void)increaseLogFontSize:(id)sender
{
	[worldController() changeTextSize:YES];
}

- (void)decreaseLogFontSize:(id)sender
{
	[worldController() changeTextSize:NO];
}

- (void)markAllAsRead:(id)sender
{
	[worldController() markAllAsRead];
}

- (void)connect:(id)sender
{
	// This does nothing. Validation overrides this with one
	// of the actions from below.

	NSAssert(NO, @"This method should not be invoked directly.");
}

- (void)connectPreferringIPv6:(id)sender
{
	IRCClient *u = [mainWindow() selectedClient];
	
	if (_noClient || _connected || [u isQuitting]) {
		return;
	}
	
	[u connect:IRCClientConnectNormalMode preferringIPv6:YES];

	[mainWindow() expandClient:u]; // Expand client on user opreated connect.
}

- (void)connectPreferringIPv4:(id)sender
{
	IRCClient *u = [mainWindow() selectedClient];

	if (_noClient || _connected || [u isQuitting]) {
		return;
	}

	[u connect:IRCClientConnectNormalMode preferringIPv6:NO];

	[mainWindow() expandClient:u]; // Expand client on user opreated connect.
}

- (void)disconnect:(id)sender
{
	IRCClient *u = [mainWindow() selectedClient];

	if (_noClient || _notConnected || [u isQuitting]) {
		return;
	}
	
	[u quit];
}

- (void)cancelReconnection:(id)sender
{
	IRCClient *u = [mainWindow() selectedClient];

	if (_noClient) {
		return;
	}
	
	[u cancelReconnect];
}

#pragma mark -
#pragma mark Change Nickname Sheet

- (void)showNicknameChangeDialog:(id)sender
{
	[windowController() popMainWindowSheetIfExists];
	
	IRCClient *u = [mainWindow() selectedClient];
	
	if (_noClient || _connectionNotLoggedIn) {
		return;
	}

	TDCServerChangeNicknameSheet *nickSheet = [TDCServerChangeNicknameSheet new];

	[nickSheet setDelegate:self];
	[nickSheet setWindow:mainWindow()];

	[nickSheet setClientID:[u uniqueIdentifier]];

	[nickSheet start:[u localNickname]];

	[windowController() addWindowToWindowList:nickSheet];
}

- (void)serverChangeNicknameSheet:(TDCServerChangeNicknameSheet *)sender didInputNickname:(NSString *)nickname
{
	IRCClient *u = [worldController() findClientById:[sender clientID]];
	
	if (_noClient || _connectionNotLoggedIn) {
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
	IRCClient *u = [mainWindow() selectedClient];
	
	if (_noClient || _connectionNotLoggedIn) {
		return;
	}
	
	[u createChannelListDialog];
	
	[u send:IRCPrivateCommandIndex("list"), nil];
}

- (void)addServer:(id)sender
{
	[windowController() popMainWindowSheetIfExists];
	
	TDCServerPropertiesSheet *d = [TDCServerPropertiesSheet new];

	[d setDelegate:self];
	[d setWindow:mainWindow()];

	[d setClientID:nil];
	[d setConfig:[IRCClientConfig new]];

	[d start:TDCServerPropertiesSheetDefaultNavigationSelection withContext:nil];

	[windowController() addWindowToWindowList:d];
}

- (void)copyServer:(id)sender
{
	IRCClient *u = [mainWindow() selectedClient];
	
	if (_noClient) {
		return;
	}
	
	IRCClientConfig *config = [u copyOfStoredConfig];
	
	NSString *newName = [[config connectionName] stringByAppendingString:@"_"];

	[config setItemUUID:[NSString stringWithUUID]];
	
	[config setConnectionName:newName];
	
	[config setProxyPassword:NSStringEmptyPlaceholder];
	[config setServerPassword:NSStringEmptyPlaceholder];
	[config setNicknamePassword:NSStringEmptyPlaceholder];
	
	IRCClient *n = [worldController() createClient:config reload:YES];
	
	if ([_serverCurrentConfig sidebarItemExpanded]) { // Only expand new client if old was expanded already.
		[mainWindow() expandClient:n];
	}

	[worldController() save];
}

- (void)deleteServer:(id)sender
{
	IRCClient *u = [mainWindow() selectedClient];
	
	if (_noClient || _connectionLoggedIn) {
		return;
	}

	NSString *suppressionText = nil;

	BOOL suppressionResult = NO;

#if TEXTUAL_BUILT_WITH_ICLOUD_SUPPORT == 1
	BOOL deleteFromCloudCheckboxShown = NO;

	if ([TPCPreferences syncPreferencesToTheCloud]) {
		if ([_serverCurrentConfig excludedFromCloudSyncing] == NO) {
			deleteFromCloudCheckboxShown = YES;

			suppressionText = TXTLS(@"BasicLanguage[1198][3]");
		}
	}
#endif

	BOOL result = [TLOPopupPrompts dialogWindowWithMessage:TXTLS(@"BasicLanguage[1198][2]")
													 title:TXTLS(@"BasicLanguage[1198][1]")
											 defaultButton:BLS(1219)
										   alternateButton:BLS(1182)
											suppressionKey:nil
										   suppressionText:suppressionText
									   suppressionResponse:&suppressionResult];

	if (result == NO) {
		return;
	}

#if TEXTUAL_BUILT_WITH_ICLOUD_SUPPORT == 1
	if (deleteFromCloudCheckboxShown && suppressionResult == NO) {
		[worldController() destroyClient:u bySkippingCloud:NO];
	} else {
#endif

		[worldController() destroyClient:u bySkippingCloud:YES];

#if TEXTUAL_BUILT_WITH_ICLOUD_SUPPORT == 1
	}
#endif

	[worldController() save];
}

#pragma mark -
#pragma mark Server Properties

- (void)showServerPropertyDialog:(IRCClient *)u withDefaultView:(TDCServerPropertiesSheetNavigationSelection)viewType andContext:(NSString *)context
{
	if (_noClient) {
		return;
	}

	[windowController() popMainWindowSheetIfExists];
	
	TDCServerPropertiesSheet *d = [TDCServerPropertiesSheet new];

	[d setDelegate:self];
	[d setWindow:mainWindow()];
	
	[d setClientID:[u uniqueIdentifier]];
	[d setConfig:[u copyOfStoredConfig]];
	
	[d start:viewType withContext:context];

	[windowController() addWindowToWindowList:d];
}

- (void)showServerPropertiesDialog:(id)sender
{
	[self showServerPropertyDialog:[mainWindow() selectedClient]
				   withDefaultView:TDCServerPropertiesSheetDefaultNavigationSelection
						andContext:nil];
}

- (void)serverPropertiesSheetOnOK:(TDCServerPropertiesSheet *)sender
{
	if ([sender clientID] == nil) {
		[worldController() createClient:[sender config] reload:YES];
		
		[[sender config] writeKeychainItemsToDisk];
	} else {
		IRCClient *u = [worldController() findClientById:[sender clientID]];
		
		if (_noClient) {
			return;
		}

		BOOL samencoding = ([[sender config] primaryEncoding] ==
							     [[u config] primaryEncoding]);

		[u updateConfig:[sender config]];

		if (samencoding == NO) {
			[worldController() reloadTheme];
		}
		
		[mainWindow() reloadTreeGroup:u];
	}
	
	[worldController() save];
}

#if TEXTUAL_BUILT_WITH_ICLOUD_SUPPORT == 1
- (void)serverPropertiesSheetRequestedCloudExclusionByDeletion:(TDCServerPropertiesSheet *)sender
{
	[worldController() addClientToListOfDeletedClients:[[sender config] itemUUID]];
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
	IRCClient *u = [mainWindow() selectedClient];
	IRCChannel *c = [mainWindow() selectedChannel];
	
	if (_noClientOrChannel || _isClient || _isQuery || _activate || _connectionNotLoggedIn) {
		return;
	}

	[u setInUserInvokedJoinRequest:YES];
	
	[u joinChannel:c];
}

- (void)leaveChannel:(id)sender
{
	IRCClient *u = [mainWindow() selectedClient];
	IRCChannel *c = [mainWindow() selectedChannel];
	
	if (_noClientOrChannel || _notActive || _connectionNotLoggedIn) {
		return;
	}
	
	if (_isChannel) {
		[u partChannel:c];
	} else {
		[worldController() destroyChannel:c];
	}
}

#pragma mark -
#pragma mark Highlight Sheet

- (void)showHighlightSheet:(id)sender
{
	[windowController() popMainWindowSheetIfExists];
	
	IRCClient *u = [mainWindow() selectedClient];
	
	if (_noClient) {
		return;
	}
	
	TDCServerHighlightListSheet *d = [TDCServerHighlightListSheet new];
	
	[d setDelegate:self];
	[d setWindow:mainWindow()];
	
	[d setClientID:[u uniqueIdentifier]];
	
	[d show];

	[windowController() addWindowToWindowList:d];
}

- (void)serverHighlightListSheetWillClose:(TDCServerHighlightListSheet *)sender
{
	[windowController() removeWindowFromWindowList:sender];
}

#pragma mark -
#pragma mark Nickname Color Sheet

- (void)memberChangeColor:(NSString *)nickname
{
	[windowController() popMainWindowSheetIfExists];

	IRCClient *u = [mainWindow() selectedClient];

	if (_noClient) {
		return;
	}

	TDCNicknameColorSheet *t = [TDCNicknameColorSheet new];

	[t setDelegate:self];
	[t setWindow:mainWindow()];

	[t setNickname:nickname];

	[t start];

	[windowController() addWindowToWindowList:t];
}

- (void)nicknameColorSheetOnOK:(TDCNicknameColorSheet *)sneder
{
	[worldController() reloadTheme:NO];
}

- (void)nicknameColorSheetWillClose:(TDCNicknameColorSheet *)sender
{
	[windowController() removeWindowFromWindowList:sender];
}

#pragma mark -
#pragma mark Channel Topic Sheet

- (void)showChannelTopicDialog:(id)sender
{
	[windowController() popMainWindowSheetIfExists];

	IRCClient *u = [mainWindow() selectedClient];
	IRCChannel *c = [mainWindow() selectedChannel];

	if (_noClientOrChannel || _isClient || _isQuery) {
		return;
	}

	TDChannelModifyTopicSheet *t = [TDChannelModifyTopicSheet new];

	[t setDelegate:self];
	[t setWindow:mainWindow()];
	
	[t setClientID:[u uniqueIdentifier]];
	[t setChannelID:[c uniqueIdentifier]];

	[t start:[c topic]];

	[windowController() addWindowToWindowList:t];
}

- (void)channelModifyTopicSheet:(TDChannelModifyTopicSheet *)sender onOK:(NSString *)topic
{
	IRCChannel *c = [worldController() findChannelByClientId:[sender clientID]
												   channelId:[sender channelID]];
	
	IRCClient *u = [c associatedClient];
	
	if (_noClientOrChannel || _isClient || _isQuery) {
		return;
	}

	[u send:IRCPrivateCommandIndex("topic"), [c name], topic, nil];
}

- (void)channelModifyTopicSheetWillClose:(TDChannelModifyTopicSheet *)sender
{
	[windowController() removeWindowFromWindowList:sender];
}

#pragma mark -
#pragma mark Channel Mode Sheet

- (void)showChannelModeDialog:(id)sender
{
	[windowController() popMainWindowSheetIfExists];

	IRCClient *u = [mainWindow() selectedClient];
	IRCChannel *c = [mainWindow() selectedChannel];
	
	if (_noClientOrChannel || _isClient || _isQuery) {
		return;
	}
	
	TDChannelModifyModesSheet *m = [TDChannelModifyModesSheet new];
	
	[m setDelegate:self];
	[m setWindow:mainWindow()];
	
	[m setClientID:[u uniqueIdentifier]];
	[m setChannelID:[c uniqueIdentifier]];
	
	[m setMode:[c modeInfo]];

	[m start];

	[windowController() addWindowToWindowList:m];
}

- (void)channelModifyModesSheetOnOK:(TDChannelModifyModesSheet *)sender
{
	IRCChannel *c = [worldController() findChannelByClientId:[sender clientID]
												   channelId:[sender channelID]];
	
	IRCClient *u = [c associatedClient];
	
	if (_noClientOrChannel || _isClient || _isQuery) {
		return;
	}
	
	NSString *changeStr = [[c modeInfo] getChangeCommand:[sender mode]];

	NSObjectIsEmptyAssert(changeStr);

	[u sendLine:[NSString stringWithFormat:@"%@ %@ %@", IRCPrivateCommandIndex("mode"), [c name], changeStr]];
}

- (void)channelModifyModesSheetWillClose:(TDChannelModifyModesSheet *)sender
{
	[windowController() removeWindowFromWindowList:sender];
}

#pragma mark -
#pragma mark Menu Item Actions

- (void)addChannel:(id)sender
{
	[windowController() popMainWindowSheetIfExists];
	
	IRCClient *u = [mainWindow() selectedClient];
	
	if (_noClient) {
		return;
	}
	
	TDChannelPropertiesSheet *d = [TDChannelPropertiesSheet new];

	[d setNewItem:YES];
	
	[d setDelegate:self];
	[d setWindow:mainWindow()];
	
	[d setClientID:[u uniqueIdentifier]];
	[d setChannelID:nil];
	
	[d setConfig:[IRCChannelConfig new]];

	[d start];

	[windowController() addWindowToWindowList:d];
}

- (void)deleteChannel:(id)sender
{
	IRCChannel *c = [mainWindow() selectedChannel];
	
	if (_noChannel || _isClient) {
		return;
	}
	
	if (_isChannel) {
		BOOL result = [TLOPopupPrompts dialogWindowWithMessage:TXTLS(@"BasicLanguage[1010][1]")
														 title:TXTLS(@"BasicLanguage[1010][2]")
												 defaultButton:BLS(1219)
											   alternateButton:BLS(1182)
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

- (void)showChannelPropertiesDialog:(id)sender
{
	[windowController() popMainWindowSheetIfExists];

	IRCClient *u = [mainWindow() selectedClient];
	IRCChannel *c = [mainWindow() selectedChannel];
	
	if (_noClientOrChannel || _isClient || _isQuery) {
		return;
	}
	
	TDChannelPropertiesSheet *d = [TDChannelPropertiesSheet new];

	[d setNewItem:NO];
	[d setObserveChanges:YES];
	
	[d setDelegate:self];
	[d setWindow:mainWindow()];
	
	[d setClientID:[u uniqueIdentifier]];
	[d setChannelID:[c uniqueIdentifier]];
	
	[d setConfig:_channelConfig];

	[d start];

	[windowController() addWindowToWindowList:d];
}

- (void)channelPropertiesSheetOnOK:(TDChannelPropertiesSheet *)sender
{
	if ([sender newItem]) {
		IRCClient *u = [worldController() findClientById:[sender clientID]];
		
		if (_noClient) {
			return;
		}
		
		[mainWindow() expandClient:u];
		
		[worldController() createChannel:[sender config] client:u reload:YES adjust:YES];
		
		[[sender config] writeKeychainItemsToDisk];
	} else {
		IRCChannel *c = [worldController() findChannelByClientId:[sender clientID] channelId:[sender channelID]];
		
		if (_noChannel) {
			return;
		}

		[c updateConfig:[sender config]];
	}
	
	[worldController() save];
}

- (void)channelPropertiesSheetWillClose:(TDChannelPropertiesSheet *)sender
{
	[windowController() removeWindowFromWindowList:sender];
}

#pragma mark -
#pragma mark Menu Item Actions

- (void)memberInMemberListDoubleClicked:(id)sender
{
    TVCMemberList *view = sender;

	NSInteger n = [view rowUnderMouse];

    if (n >= 0) {
		TXUserDoubleClickAction action = [TPCPreferences userDoubleClickOption];
        
		if (action == TXUserDoubleClickWhoisAction) {
			[self whoisSelectedMembers:sender];
		} else if (action == TXUserDoubleClickPrivateMessageAction) {
			[self memberStartPrivateMessage:sender];
		} else if (action == TXUserDoubleClickInsertTextFieldAction) {
			[self memberInsertNameIntoTextField:sender];
		}
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
	IRCClient *u = [mainWindow() selectedClient];
	IRCChannel *c = [mainWindow() selectedChannel];
    
	if (_noClient || _isClient) {
		return;
	}
    
	/* Get list of users. */
	NSMutableArray *users = [NSMutableArray array];
    
	for (NSString *nickname in [self selectedMembersNicknames:sender]) {
		[users addObject:nickname];
	}
    
	/* The text field. */
	TVCMainWindowTextView *textField = mainWindowTextField();
    
	NSRange selectedRange = [textField selectedRange];
    
	NSInteger insertLocation = selectedRange.location;
    
	/* Build insert string. */
	NSString *insertString = nil;
    
	if (insertLocation > 0) {
		UniChar prev = [[textField stringValue] characterAtIndex:(insertLocation - 1)];
        
		if (prev == ' ') {
			insertString = NSStringEmptyPlaceholder;
		} else {
			insertString = NSStringWhitespacePlaceholder;
		}
	} else {
		insertString = NSStringEmptyPlaceholder;
	}
    
	insertString = [insertString stringByAppendingString:[users componentsJoinedByString:@", "]];
    
    if ([TPCPreferences tabCompletionSuffix]) {
        insertString = [insertString stringByAppendingString:[TPCPreferences tabCompletionSuffix]];
    }
    
	/* Insert names. */
	[textField replaceCharactersInRange:selectedRange withString:insertString];

	[textField resetTextColorInRange:selectedRange];
	
	/* Close users. */
	[self deselectMembers:sender];
	
	/* Set focus to the input textfield. */
	[textField focus];
}

- (void)memberSendWhois:(id)sender
{
	[self whoisSelectedMembers:sender];
}

- (void)whoisSelectedMembers:(id)sender
{
	IRCClient *u = [mainWindow() selectedClient];
	IRCChannel *c = [mainWindow() selectedChannel];

	if (_noClient || _isClient) {
		return;
	}

	for (NSString *nickname in [self selectedMembersNicknames:sender]) {
		[u sendWhois:nickname];
	}

	[self deselectMembers:sender];
}

- (void)memberStartPrivateMessage:(id)sender
{
	IRCClient *u = [mainWindow() selectedClient];
	IRCChannel *c = [mainWindow() selectedChannel];
	
	if (_noClient || _isClient) {
		return;
	}
	
	for (NSString *nickname in [self selectedMembersNicknames:sender]) {
		IRCChannel *cc = [u findChannelOrCreate:nickname isPrivateMessage:YES];
		
		[mainWindow() select:cc];
	}

	[self deselectMembers:sender];
}

#pragma mark -
#pragma mark Channel Invite Sheet

- (void)memberSendInvite:(id)sender
{
	[windowController() popMainWindowSheetIfExists];

	IRCClient *u = [mainWindow() selectedClient];
	IRCChannel *c = [mainWindow() selectedChannel];
	
	if (_noClientOrChannel || _connectionNotLoggedIn) {
		return;
	}

	NSMutableArray *channels = [NSMutableArray array];
	NSMutableArray *nicknames = [NSMutableArray array];

	for (NSString *nickname in [self selectedMembersNicknames:sender]) {
		[nicknames addObject:nickname];
	}
	
	for (IRCChannel *e in [u channelList]) {
		if (NSDissimilarObjects(c, e) && [e isChannel]) {
			[channels addObject:[e name]];
		}
	}

	NSObjectIsEmptyAssert(channels);
	NSObjectIsEmptyAssert(nicknames);

	TDChannelInviteSheet *inviteSheet = [TDChannelInviteSheet new];
	
	[inviteSheet setDelegate:self];
	[inviteSheet setWindow:mainWindow()];
	
	[inviteSheet setNicknames:nicknames];
	[inviteSheet setClientID:[u uniqueIdentifier]];

	[inviteSheet startWithChannels:channels];

	[windowController() addWindowToWindowList:inviteSheet];
}

- (void)channelInviteSheet:(TDChannelInviteSheet *)sender onSelectChannel:(NSString *)channelName
{
	IRCClient *u = [worldController() findClientById:[sender clientID]];

	if (u) {
		if ([channelName isChannelName]) {
			for (NSString *nick in [sender nicknames]) {
				[u send:IRCPrivateCommandIndex("invite"), nick, channelName, nil];
			}
		}
	}
}

- (void)channelInviteSheetWillClose:(TDChannelInviteSheet *)sender
{
	[windowController() removeWindowFromWindowList:sender];
}

#pragma mark -
#pragma mark Menu Item Actions

- (void)memberSendCTCPPing:(id)sender
{
	IRCClient *u = [mainWindow() selectedClient];
	IRCChannel *c = [mainWindow() selectedChannel];
	
	if (_noClient || _isClient) {
		return;
	}
	
	for (NSString *nickname in [self selectedMembersNicknames:sender]) {
		[u sendCTCPPing:nickname];
	}
	
	[self deselectMembers:sender];
}

- (void)memberSendCTCPFinger:(id)sender
{
	IRCClient *u = [mainWindow() selectedClient];
	IRCChannel *c = [mainWindow() selectedChannel];

	if (_noClient || _isClient) {
		return;
	}

	for (NSString *nickname in [self selectedMembersNicknames:sender]) {
		[u sendCTCPQuery:nickname command:IRCPrivateCommandIndex("ctcp_finger") text:nil];
	}

	[self deselectMembers:sender];
}

- (void)memberSendCTCPTime:(id)sender
{
	IRCClient *u = [mainWindow() selectedClient];
	IRCChannel *c = [mainWindow() selectedChannel];

	if (_noClient || _isClient) {
		return;
	}

	for (NSString *nickname in [self selectedMembersNicknames:sender]) {
		[u sendCTCPQuery:nickname command:IRCPrivateCommandIndex("ctcp_time") text:nil];
	}
	
	[self deselectMembers:sender];
}

- (void)memberSendCTCPVersion:(id)sender
{
	IRCClient *u = [mainWindow() selectedClient];
	IRCChannel *c = [mainWindow() selectedChannel];

	if (_noClient || _isClient) {
		return;
	}

	for (NSString *nickname in [self selectedMembersNicknames:sender]) {
		[u sendCTCPQuery:nickname command:IRCPrivateCommandIndex("ctcp_version") text:nil];
	}
	
	[self deselectMembers:sender];
}

- (void)memberSendCTCPUserinfo:(id)sender
{
	IRCClient *u = [mainWindow() selectedClient];
	IRCChannel *c = [mainWindow() selectedChannel];

	if (_noClient || _isClient) {
		return;
	}

	for (NSString *nickname in [self selectedMembersNicknames:sender]) {
		[u sendCTCPQuery:nickname command:IRCPrivateCommandIndex("ctcp_userinfo") text:nil];
	}
	
	[self deselectMembers:sender];
}

- (void)memberSendCTCPClientInfo:(id)sender
{
	IRCClient *u = [mainWindow() selectedClient];
	IRCChannel *c = [mainWindow() selectedChannel];

	if (_noClient || _isClient) {
		return;
	}

	for (NSString *nickname in [self selectedMembersNicknames:sender]) {
		[u sendCTCPQuery:nickname command:IRCPrivateCommandIndex("ctcp_clientinfo") text:nil];
	}
	
	[self deselectMembers:sender];
}

- (void)copyUrl:(id)sender
{
	NSString *_pointedUrl = [(NSMenuItem *)sender userInfo];
	
	NSObjectIsEmptyAssert(_pointedUrl);

	[RZPasteboard() setStringContent:_pointedUrl];
}

- (void)joinClickedChannel:(id)sender
{
	NSString *_pointedChannelName = nil;
	
	if ([sender isKindOfClass:[NSMenuItem class]]) {
		_pointedChannelName = [(NSMenuItem *)sender userInfo];
	} else if ([sender isKindOfClass:[NSString class]]) {
		_pointedChannelName = sender;
	} else {
		NSAssert(NO, @"Bad data type");
	}
	
	NSObjectIsEmptyAssert(_pointedChannelName);
	
	IRCClient *u = [mainWindow() selectedClient];
	
	if (_noClient || _connectionNotLoggedIn) {
		return;
	}

	[u setInUserInvokedJoinRequest:YES];
	
	[u joinUnlistedChannel:_pointedChannelName];
}

- (void)showChannelIgnoreList:(id)sender
{
	[self showServerPropertyDialog:[mainWindow() selectedClient]
					withDefaultView:TDCServerPropertiesSheetAddressBookNavigationSelection
						andContext:nil];
}

#pragma mark -
#pragma mark Welcome Sheet

- (void)openWelcomeSheet:(id)sender
{
	[windowController() popMainWindowSheetIfExists];
	
	TDCWelcomeSheet *welcomeSheet = [TDCWelcomeSheet new];
	
	[welcomeSheet setDelegate:self];
	[welcomeSheet setWindow:mainWindow()];
	
	[welcomeSheet show];

	[windowController() addWindowToWindowList:welcomeSheet];
}

- (void)welcomeSheet:(TDCWelcomeSheet *)sender onOK:(IRCClientConfig *)config
{
	IRCClient *u = [worldController() createClient:config reload:YES];
	
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
	
	TDCAboutDialog *aboutPanel = [TDCAboutDialog new];

	[aboutPanel setDelegate:self];

	[aboutPanel show];

	[windowController() addWindowToWindowList:aboutPanel];
}

- (void)aboutDialogWillClose:(TDCAboutDialog *)sender
{
	[windowController() removeWindowFromWindowList:sender];
}

#pragma mark -
#pragma mark Menu Item Actions

- (void)processModeChange:(id)sender mode:(NSString *)tmode 
{
	IRCClient *u = [mainWindow() selectedClient];
	IRCChannel *c = [mainWindow() selectedChannel];
	
	if (_noClientOrChannel || _isClient || _isQuery) {
		return;
	}
	
	NSString *opString = NSStringEmptyPlaceholder;
	
	NSInteger currentIndex = 0;
	
	for (NSString *nickname in [self selectedMembersNicknames:sender]) {
		opString = [opString stringByAppendingFormat:@"%@ ", nickname];
		
		currentIndex += 1;

		if (currentIndex == [[u supportInfo] modesCount]) {
			[u sendCommand:[NSString stringWithFormat:@"%@ %@", tmode, opString] completeTarget:YES target:[c name]];
			
			opString = NSStringEmptyPlaceholder;
			
			currentIndex = 0;
		}
	}
	
	if (opString) {	
		[u sendCommand:[NSString stringWithFormat:@"%@ %@", tmode, opString] completeTarget:YES target:[c name]];
	}
	
	[self deselectMembers:sender];
}

- (void)memberModeChangeOp:(id)sender 
{
	[self processModeChange:sender mode:IRCPublicCommandIndex("op")];
}

- (void)memberModeChangeDeop:(id)sender 
{ 
	[self processModeChange:sender mode:IRCPublicCommandIndex("deop")]; 
}

- (void)memberModeChangeHalfop:(id)sender 
{ 
	[self processModeChange:sender mode:IRCPublicCommandIndex("halfop")]; 
}

- (void)memberModeChangeDehalfop:(id)sender 
{ 
	[self processModeChange:sender mode:IRCPublicCommandIndex("dehalfop")]; 
}

- (void)memberModeChangeVoice:(id)sender 
{ 
	[self processModeChange:sender mode:IRCPublicCommandIndex("voice")]; 
}

- (void)memberModeChangeDevoice:(id)sender 
{ 
	[self processModeChange:sender mode:IRCPublicCommandIndex("devoice")]; 
}

- (void)memberKickFromChannel:(id)sender
{
	IRCClient *u = [mainWindow() selectedClient];
	IRCChannel *c = [mainWindow() selectedChannel];
	
	if (_noClientOrChannel || _isClient || _isQuery) {
		return;
	}
	
	for (NSString *nickname in [self selectedMembersNicknames:sender]) {
		[u kick:c target:nickname];
	}
	
	[self deselectMembers:sender];
}

- (void)memberBanFromServer:(id)sender
{
	IRCClient *u = [mainWindow() selectedClient];
	IRCChannel *c = [mainWindow() selectedChannel];

	if (_noClientOrChannel || _isClient || _isQuery) {
		return;
	}
	
	for (NSString *nickname in [self selectedMembersNicknames:sender]) {
		[u sendCommand:[NSString stringWithFormat:@"%@ %@", IRCPublicCommandIndex("ban"), nickname] completeTarget:YES target:[c name]];
	}
	
	[self deselectMembers:sender];
}

- (void)memberKickbanFromChannel:(id)sender
{
	IRCClient *u = [mainWindow() selectedClient];
	IRCChannel *c = [mainWindow() selectedChannel];

	if (_noClientOrChannel || _isClient || _isQuery) {
		return;
	}
	
	for (NSString *nickname in [self selectedMembersNicknames:sender]) {
		[u sendCommand:[NSString stringWithFormat:@"%@ %@ %@", IRCPublicCommandIndex("kickban"), nickname, [TPCPreferences defaultKickMessage]] completeTarget:YES target:[c name]];
	}
	
	[self deselectMembers:sender];
}

- (void)memberKillFromServer:(id)sender
{
	IRCClient *u = [mainWindow() selectedClient];
	IRCChannel *c = [mainWindow() selectedChannel];

	if (_noClientOrChannel || _isClient) {
		return;
	}
	
	for (NSString *nickname in [self selectedMembersNicknames:sender]) {
		[u sendCommand:[NSString stringWithFormat:@"%@ %@ %@", IRCPublicCommandIndex("kill"), nickname, [TPCPreferences IRCopDefaultKillMessage]]];
	}
	
	[self deselectMembers:sender];
}

- (void)memberGlineFromServer:(id)sender
{
	IRCClient *u = [mainWindow() selectedClient];
	IRCChannel *c = [mainWindow() selectedChannel];

	if (_noClientOrChannel || _isClient) {
		return;
	}
	
	for (NSString *nickname in [self selectedMembersNicknames:sender]) {
        if ([nickname isEqualIgnoringCase:[u localNickname]]) {
            [u printDebugInformation:BLS(1197, [u networkAddress]) channel:c];
        } else {
            [u sendCommand:[NSString stringWithFormat:@"%@ %@ %@", IRCPublicCommandIndex("gline"), nickname, [TPCPreferences IRCopDefaultGlineMessage]]];
        }
    }
	
	[self deselectMembers:sender];
}

- (void)memberShunFromServer:(id)sender
{
	IRCClient *u = [mainWindow() selectedClient];
	IRCChannel *c = [mainWindow() selectedChannel];

	if (_noClientOrChannel || _isClient) {
		return;
	}
	
	for (NSString *nickname in [self selectedMembersNicknames:sender]) {
		[u sendCommand:[NSString stringWithFormat:@"%@ %@ %@", IRCPublicCommandIndex("shun"), nickname, [TPCPreferences IRCopDefaultShunMessage]]];
	}
	
	[self deselectMembers:sender];
}

- (void)memberSendFileRequest:(id)sender
{
	IRCClient *u = [mainWindow() selectedClient];
	IRCChannel *c = [mainWindow() selectedChannel];
	
	if (_noClientOrChannel || _isClient || _connectionNotLoggedIn) {
		return;
	}
	
	NSOpenPanel *d = [NSOpenPanel openPanel];
	
	[d setCanChooseFiles:YES];
	[d setCanChooseDirectories:NO];
	[d setResolvesAliases:YES];
	[d setAllowsMultipleSelection:YES];
	[d setCanCreateDirectories:NO];
	
	[d beginSheetModalForWindow:mainWindow() completionHandler:^(NSInteger returnCode) {
		if (returnCode == NSModalResponseOK) {
			[[self.fileTransferController fileTransferTable] beginUpdates];
			
			for (NSString *nickname in [self selectedMembersNicknames:sender]) {
				for (NSURL *pathURL in [d URLs]) {
					(void)[self.fileTransferController addSenderForClient:u nickname:nickname path:[pathURL path] autoOpen:YES];
				}
			}
			
			[[self.fileTransferController fileTransferTable] endUpdates];
		}
		
		[self deselectMembers:sender];
	}];
}

- (void)memberSendDroppedFilesToSelectedChannel:(NSArray *)files
{
	IRCClient *u = [mainWindow() selectedClient];
	IRCChannel *c = [mainWindow() selectedChannel];
	
	if (_noClientOrChannel || _isChannel || _isClient || _connectionNotLoggedIn) {
		return;
	}

	[self memberSendDroppedFiles:files to:[c name]];
}

- (void)memberSendDroppedFiles:(NSArray *)files row:(NSNumber *)row
{
	IRCClient *u = [mainWindow() selectedClient];
	IRCChannel *c = [mainWindow() selectedChannel];
	
	if (_noClientOrChannel || _isClient || _connectionNotLoggedIn) {
		return;
	}
	
	IRCUser *member = [mainWindowMemberList() itemAtRow:[row integerValue]];
	
	[self memberSendDroppedFiles:files to:[member nickname]];
}

- (void)memberSendDroppedFiles:(NSArray *)files to:(NSString *)nickname
{
	IRCClient *u = [mainWindow() selectedClient];

	for (NSString *pathURL in files) {
		BOOL isDirectory = NO;

		if ([RZFileManager() fileExistsAtPath:pathURL isDirectory:&isDirectory]) {
			if (isDirectory) {
				continue;
			}
		}

		(void)[self.fileTransferController addSenderForClient:u nickname:nickname path:pathURL autoOpen:YES];
	}
}

- (void)openLogLocation:(id)sender
{	
	NSURL *path = [TPCPathInfo logFileFolderLocation];
	
	if ([RZFileManager() fileExistsAtPath:[path path]]) {
		[RZWorkspace() openURL:path];
	} else {
		[TLOPopupPrompts dialogWindowWithMessage:TXTLS(@"BasicLanguage[1110][2]")
										   title:TXTLS(@"BasicLanguage[1110][1]")
								   defaultButton:BLS(1186)
								 alternateButton:nil];
	}
}

- (void)openChannelLogs:(id)sender
{
	IRCClient *u = [mainWindow() selectedClient];
	IRCChannel *c = [mainWindow() selectedChannel];

	if (_noClientOrChannel || _isClient) {
		return;
	}
	
	NSURL *path = [c logFilePath];
	
	if ([RZFileManager() fileExistsAtPath:[path path]]) {
		[RZWorkspace() openURL:path];
	} else {
		[TLOPopupPrompts dialogWindowWithMessage:TXTLS(@"BasicLanguage[1110][2]")
										   title:TXTLS(@"BasicLanguage[1110][1]")
								   defaultButton:BLS(1186)
								 alternateButton:nil
								  suppressionKey:nil
								 suppressionText:nil];
	}
}

- (void)connectToTextualHelpChannel:(id)sender 
{
	[IRCExtras createConnectionAndJoinChannel:@"chat.freenode.net +6697" channel:@"#textual" autoConnect:YES focusChannel:YES mergeConnectionIfPossible:YES];
}

- (void)connectToTextualTestingChannel:(id)sender
{
	[IRCExtras createConnectionAndJoinChannel:@"chat.freenode.net +6697" channel:@"#textual-testing" autoConnect:YES focusChannel:YES mergeConnectionIfPossible:YES];
}

- (void)onWantHostServVhostSet:(id)sender
{
	IRCClient *u = [mainWindow() selectedClient];
	IRCChannel *c = [mainWindow() selectedChannel];
	
	if (_noClientOrChannel || _isClient) {
		return;
	}
	
	NSMutableArray *nicknames = [NSMutableArray array];
	
	for (NSString *nickname in [self selectedMembersNicknames:sender]) {
		[nicknames addObject:nickname];
	}
	
	[self deselectMembers:sender];

	TVCInputPromptDialog *dialog = [TVCInputPromptDialog new];

	[dialog alertWithMessageTitle:TXTLS(@"BasicLanguage[1228][1]")
					defaultButton:BLS(1186)
				  alternateButton:BLS(1009)
				  informativeText:TXTLS(@"BasicLanguage[1228][2]")
				 defaultUserInput:nil
				  completionBlock:^(TVCInputPromptDialog *sender, BOOL defaultButtonClicked, NSString *resultString) {
					  if (defaultButtonClicked) {
						  if (NSObjectIsNotEmpty(resultString)) {
							  for (NSString *nickname in nicknames) {
								  [u sendCommand:[NSString stringWithFormat:@"hs setall %@ %@", nickname, resultString] completeTarget:NO target:nil];
							  }
						  }
					  }
					  
					  [windowController() removeWindowFromWindowList:sender];
				  }];
	
	[windowController() addWindowToWindowList:dialog];
}

- (void)showSetVhostPrompt:(id)sender
{
	[self onWantHostServVhostSet:sender];
}

- (void)showChannelBanList:(id)sender
{
	IRCClient *u = [mainWindow() selectedClient];
	IRCChannel *c = [mainWindow() selectedChannel];
	
	if (_noChannel || _isClient || _isQuery) {
		return;
	}
	
	[u createChannelBanListSheet];
	
	[u send:IRCPrivateCommandIndex("mode"), [c name], @"+b", nil];
}

- (void)showChannelBanExceptionList:(id)sender
{
	IRCClient *u = [mainWindow() selectedClient];
	IRCChannel *c = [mainWindow() selectedChannel];

	if (_noChannel || _isClient || _isQuery) {
		return;
	}
	
	[u createChannelBanExceptionListSheet];
	
	[u send:IRCPrivateCommandIndex("mode"), [c name], @"+e", nil];
}

- (void)showChannelInviteExceptionList:(id)sender
{
	IRCClient *u = [mainWindow() selectedClient];
	IRCChannel *c = [mainWindow() selectedChannel];

	if (_noChannel || _isClient || _isQuery) {
		return;
	}
	
	[u createChannelInviteExceptionListSheet];
	
	[u send:IRCPrivateCommandIndex("mode"), [c name], @"+I", nil];
}

- (void)openHelpMenuLinkItem:(id)sender
{
	NSDictionary *_helpMenuLinks = @{
	   @(901) : @"https://help.codeux.com/textual/Privacy-Policy.kb",
	   @(902) : @"https://help.codeux.com/textual/Frequently-Asked-Questions.kb",
	   @(905) : @"https://help.codeux.com/textual/home.kb",
	   @(906) : @"https://help.codeux.com/textual/iCloud-Syncing.kb",
	   @(907) : @"https://help.codeux.com/textual/Off-the-Record-Messaging.kb",
	   @(908) : @"https://help.codeux.com/textual/Command-Reference.kb",
	   @(909) : @"https://help.codeux.com/textual/Support.kb",
	   @(910) : @"https://help.codeux.com/textual/Keyboard-Shortcuts.kb",
	   @(911) : @"https://help.codeux.com/textual/Memory-Management.kb",
	   @(912) : @"https://help.codeux.com/textual/Text-Formatting.kb",
	   @(913) : @"https://help.codeux.com/textual/Styles.kb",
	   @(914) : @"https://help.codeux.com/textual/Using-CertFP.kb",
	   @(915) : @"https://help.codeux.com/textual/Connecting-to-ZNC-Bouncer.kb",
	   @(916) : @"https://help.codeux.com/textual/DCC-File-Transfer-Information.kb",
	   @(927) : @"https://help.codeux.com/textual/End-User-License-Agreement.kb"
	};
	
	NSString *linkloc = _helpMenuLinks[@([sender tag])];
	
	[TLOpenLink openWithString:linkloc];
}

- (void)openMacAppStoreDownloadPage:(id)sender
{
	[TLOpenLink openWithString:@"https://www.textualapp.com/mac-app-store"];
}

- (void)openFastSpringStoreWebpage:(id)sender
{
	[TLOpenLink openWithString:@"https://www.textualapp.com/fastspring-store"];
}

- (void)processNavigationItem:(id)sender
{
	switch ([sender tag]) {
		case 701: { [mainWindow() selectNextServer:nil];					break;		}
		case 702: { [mainWindow() selectPreviousServer:nil];				break;		}
		case 703: { [mainWindow() selectNextActiveServer:nil];				break;		}
		case 704: { [mainWindow() selectPreviousActiveServer:nil];			break;		}
		case 706: { [mainWindow() selectNextChannel:nil];					break;		}
		case 707: { [mainWindow() selectPreviousChannel:nil];				break;		}
		case 708: { [mainWindow() selectNextActiveChannel:nil];				break;		}
		case 709: { [mainWindow() selectPreviousActiveChannel:nil];			break;		}
		case 710: { [mainWindow() selectNextUnreadChannel:nil];				break;		}
		case 711: { [mainWindow() selectPreviousUnreadChannel:nil];			break;		}
		case 712: { [mainWindow() selectPreviousWindow:nil];				break;		}
		case 713: { [mainWindow() selectNextWindow:nil];					break;		}
		case 714: { [mainWindow() selectPreviousSelection:nil];				break;		}
	}
}

- (void)showMainWindow:(id)sender 
{
	[mainWindow() makeKeyAndOrderFront:nil];
}

- (void)sortChannelListNames:(id)sender
{
	for (IRCClient *u in [worldController() clientList]) {
		NSMutableArray *channels = [[u channelList] mutableCopy];
		
		[channels sortUsingComparator:^NSComparisonResult(id obj1, id obj2) {
			NSString *name1 = [[obj1 name] lowercaseString];
			NSString *name2 = [[obj2 name] lowercaseString];
			
			return [name1 compare:name2];
		}];
		
		[u setChannelList:channels];
		
		[u updateConfig:[u copyOfStoredConfig]];
	}
	
	[worldController() save];
}

- (void)resetWindowSize:(id)sender
{
	if ([mainWindow() isInFullscreenMode]) {
		[mainWindow() toggleFullScreen:sender];
	}

	[mainWindow() setFrame:[mainWindow() defaultWindowFrame] display:YES animate:YES];

	[mainWindow() exactlyCenterWindow];
}

- (void)forceReloadTheme:(id)sender
{
	[worldController() reloadTheme];
}

- (void)toggleChannelModerationMode:(id)sender
{
#define _toggleChannelModerationModeOffTag		612
	
	IRCClient *u = [mainWindow() selectedClient];
	IRCChannel *c = [mainWindow() selectedChannel];

	if (_noChannel || _isClient || _isQuery) {
		return;
	}
	
	NSString *modeValue = nil;
	
	if ([sender tag] == _toggleChannelModerationModeOffTag) {
		modeValue = @"-m";
	} else {
		modeValue = @"+m";
	}

	[u sendCommand:[NSString stringWithFormat:@"%@ %@ %@", IRCPublicCommandIndex("mode"), [c name], modeValue]];

#undef _toggleChannelModerationModeOffTag
}

- (void)toggleChannelInviteMode:(id)sender
{
#define _toggleChannelInviteStatusModeOffTag		614
	
	IRCClient *u = [mainWindow() selectedClient];
	IRCChannel *c = [mainWindow() selectedChannel];

	if (_noChannel || _isClient || _isQuery) {
		return;
	}
	
	NSString *modeValue = nil;
	
	if ([sender tag] == _toggleChannelInviteStatusModeOffTag) {
		modeValue = @"-i";
	} else {
		modeValue = @"+i";
	}

	[u sendCommand:[NSString stringWithFormat:@"%@ %@ %@", IRCPublicCommandIndex("mode"), [c name], modeValue]];

#undef _toggleChannelInviteStatusModeOffTag
}

- (void)toggleDeveloperMode:(id)sender
{
    if ([sender state] == NSOnState) {
        [RZUserDefaults() setBool:NO forKey:TXDeveloperEnvironmentToken];
        
        [sender setState:NSOffState];
    } else {
        [RZUserDefaults() setBool:YES forKey:TXDeveloperEnvironmentToken];
        
        [sender setState:NSOnState];
    }
}

- (void)resetDoNotAskMePopupWarnings:(id)sender
{
	NSDictionary *allSettings =	[RZUserDefaults() dictionaryRepresentation];

	for (NSString *key in allSettings) {
		if ([key hasPrefix:TLOPopupPromptSuppressionPrefix]) {
			[RZUserDefaults() setBool:NO forKey:key];
		}
	}
}

- (void)onNextHighlight:(id)sender
{
	id treeItem = [mainWindow() selectedViewController];

	if ( treeItem) {
		[treeItem nextHighlight];
	}
}

- (void)onPreviousHighlight:(id)sender
{
	id treeItem = [mainWindow() selectedViewController];
	
	if ( treeItem) {
		[treeItem previousHighlight];
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
	[TPCPreferencesImportExport import];
}

- (void)exportPreferences:(id)sender
{
	[TPCPreferencesImportExport export];
}

#pragma mark -
#pragma mark Encryption 

#if TEXTUAL_BUILT_WITH_ADVANCED_ENCRYPTION == 1
#define _encryptionNotEnabled		([TPCPreferences textEncryptionIsEnabled] == NO)

- (void)encryptionStartPrivateConversation:(id)sender
{
	IRCClient *u = [mainWindow() selectedClient];
	IRCChannel *c = [mainWindow() selectedChannel];

	if (_encryptionNotEnabled || _noClientOrChannel || _isClient || _isChannel || _connectionNotLoggedIn) {
		return;
	}

	[sharedEncryptionManager() beginConversationWith:[u encryptionAccountNameForUser:[c name]]
												from:[u encryptionAccountNameForLocalUser]];
}

- (void)encryptionRefreshPrivateConversation:(id)sender
{
	IRCClient *u = [mainWindow() selectedClient];
	IRCChannel *c = [mainWindow() selectedChannel];

	if (_encryptionNotEnabled || _noClientOrChannel || _isClient || _isChannel || _connectionNotLoggedIn) {
		return;
	}

	[sharedEncryptionManager() refreshConversationWith:[u encryptionAccountNameForUser:[c name]]
												  from:[u encryptionAccountNameForLocalUser]];
}

- (void)encryptionEndPrivateConversation:(id)sender
{
	IRCClient *u = [mainWindow() selectedClient];
	IRCChannel *c = [mainWindow() selectedChannel];

	if (_encryptionNotEnabled || _noClientOrChannel || _isClient || _isChannel || _connectionNotLoggedIn) {
		return;
	}

	[sharedEncryptionManager() endConversationWith:[u encryptionAccountNameForUser:[c name]]
											  from:[u encryptionAccountNameForLocalUser]];
}

- (void)encryptionAuthenticateChatPartner:(id)sender
{
	IRCClient *u = [mainWindow() selectedClient];
	IRCChannel *c = [mainWindow() selectedChannel];

	if (_encryptionNotEnabled || _noClientOrChannel || _isClient || _isChannel || _connectionNotLoggedIn) {
		return;
	}

	[sharedEncryptionManager() authenticateUser:[u encryptionAccountNameForUser:[c name]]
										   from:[u encryptionAccountNameForLocalUser]];
}

- (void)encryptionListFingerprints:(id)sender
{
	[sharedEncryptionManager() presentListOfFingerprints];
}

- (void)encryptionWhatIsThisInformation:(id)sender
{
	[TLOpenLink openWithString:@"https://help.codeux.com/textual/Off-the-Record-Messaging.kb"];
}

#undef _encryptionNotEnabled
#endif

#pragma mark -
#pragma mark Toggle Mute

- (void)toggleMuteOnAllNotifcationsShortcut:(NSInteger)state
{
	if (state == NSOnState) {
		[sharedGrowlController() setAreNotificationsDisabled:YES];
	} else {
		[sharedGrowlController() setAreNotificationsDisabled:NO];
	}

	[self.muteNotificationsFileMenuItem setState:state];
	[self.muteNotificationsDockMenuItem setState:state];
}

- (void)toggleMuteOnNotificationSoundsShortcut:(NSInteger)state
{
	if (state == NSOnState) {
		[sharedGrowlController() setAreNotificationSoundsDisabled:YES];
	} else {
		[sharedGrowlController() setAreNotificationSoundsDisabled:NO];
	}
	
	[self.muteNotificationsSoundsDockMenuItem setState:state];
	[self.muteNotificationsSoundsFileMenuItem setState:state];
}

- (void)toggleMuteOnNotificationSounds:(id)sender
{
    if ([sharedGrowlController() areNotificationSoundsDisabled]) {
		[self toggleMuteOnNotificationSoundsShortcut:NSOffState];
    } else {
		[self toggleMuteOnNotificationSoundsShortcut:NSOnState];
    }
}

- (void)toggleMuteOnAllNotifcations:(id)sender
{
	if ([sharedGrowlController() areNotificationsDisabled]) {
		[self toggleMuteOnAllNotifcationsShortcut:NSOffState];
	} else {
		[self toggleMuteOnAllNotifcationsShortcut:NSOnState];
	}
}

#pragma mark -
#pragma mark Splitview Toggles

- (void)toggleServerListVisibility:(id)sender
{
	[[mainWindow() contentSplitView] toggleServerListVisbility];
}

- (void)toggleMemberListVisibility:(id)sender
{
	[mainWindowMemberList() setIsHiddenByUser:([mainWindowMemberList() isHiddenByUser] == NO)];

	[[mainWindow() contentSplitView] toggleMemberListVisbility];
}

#pragma mark -
#pragma mark Appearance Toggle

- (void)toggleMainWindowAppearance:(id)sender
{
	if ([TPCPreferences invertSidebarColors]) {
		[RZUserDefaults() setBool:NO forKey:@"InvertSidebarColors"];
	} else {
		[RZUserDefaults() setBool:YES forKey:@"InvertSidebarColors"];
	}
	
	[TPCPreferences performReloadActionForActionType:TPCPreferencesKeyReloadMainWindowAppearanceAction];
}

#pragma mark -
#pragma mark License Manager

- (void)manageLicense:(id)sender
{
	[self manageLicense:sender activateLicenseKey:nil licenseKeyPassedByArgument:NO];
}

- (void)manageLicense:(id)sender activateLicenseKey:(NSString *)licenseKey
{
	[self manageLicense:sender activateLicenseKey:licenseKey licenseKeyPassedByArgument:NO];
}

- (void)manageLicense:(id)sender activateLicenseKey:(NSString *)licenseKey licenseKeyPassedByArgument:(BOOL)licenseKeyPassedByArgument
{
#if TEXTUAL_BUILT_WITH_LICENSE_MANAGER == 1
	_popWindowViewIfExists(@"TDCLicenseManagerDialog");

	TDCLicenseManagerDialog *licensePanel = [TDCLicenseManagerDialog new];

	[licensePanel setDelegate:self];

	[licensePanel show];

	if (licenseKey) {
		[licensePanel setIsSilentOnSuccess:licenseKeyPassedByArgument];

		[licensePanel activateLicenseKey:licenseKey];
	}

	[windowController() addWindowToWindowList:licensePanel];
#endif
}

#if TEXTUAL_BUILT_WITH_LICENSE_MANAGER == 1
- (void)licenseManagerDialogWillClose:(TDCLicenseManagerDialog *)sender
{
	[windowController() removeWindowFromWindowList:sender];
}
#endif

#pragma mark -
#pragma mark Developer Tools

- (void)simulateCrash:(id)sender
{
#if TEXTUAL_BUILT_WITH_HOCKEYAPP_SDK_ENABLED == 1
	[[[BITHockeyManager sharedHockeyManager] crashManager] generateTestCrash];
#endif
}

#pragma mark -
#pragma mark Sparkle Framework

- (void)toggleBetaUpdates:(id)sender
{
#if TEXTUAL_BUILT_WITH_SPARKLE_ENABLED == 1
	if ([sender state] == NSOnState) {
		[RZUserDefaults() setBool:NO forKey:@"ReceiveBetaUpdates"];

		[sender setState:NSOffState];
	} else {
		[RZUserDefaults() setBool:YES forKey:@"ReceiveBetaUpdates"];

		[sender setState:NSOnState];
	}

	[TPCPreferences performReloadActionForActionType:TPCPreferencesKeyReloadSparkleFrameworkFeedURLAction];

	if ([TPCPreferences receiveBetaUpdates]) {
		[self checkForUpdates:sender];
	}
#endif
}

- (void)checkForUpdates:(id)sender
{
#if TEXTUAL_BUILT_WITH_SPARKLE_ENABLED == 1
	[[SUUpdater sharedUpdater] checkForUpdates:sender];
#endif
}

@end

@implementation TXMenuControllerMainWindowProxy

- (void)openFastSpringStoreWebpage:(id)sender
{
	[menuController() openFastSpringStoreWebpage:sender];
}

- (void)openMacAppStoreWebpage:(id)sender
{
	[menuController() openMacAppStoreDownloadPage:sender];
}

- (void)manageLicense:(id)sender
{
	[menuController() manageLicense:sender];
}

- (void)openWelcomeSheet:(id)sender
{
	[menuController() openWelcomeSheet:sender];
}

@end
