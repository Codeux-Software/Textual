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

#define _activate					(c && [c isActive])
#define _notActive					(c && [c isActive] == NO)
#define _connected					(u && [u isConnected] && [u isLoggedIn])
#define _notConnected				(u && [u isConnected] == NO && [u isLoggedIn] == NO && [u isConnecting] == NO)
#define _isChannel					([c isPrivateMessage] == NO && [c isChannel] == YES && [c isClient] == NO)
#define _isClient					([c isPrivateMessage] == NO && [c isChannel] == NO && [c isClient] == YES)
#define _isQuery					([c isPrivateMessage] == YES && [c isChannel] == NO && [c isClient] == NO)
#define _noChannel					(c == nil)
#define _noClient					(u == nil)
#define _noClientOrChannel			(u == nil || c == nil)

#define _serverCurrentConfig		[u config]

#define _channelConfig				[c config]

#define _disableInSheet(c)			[self changeConditionInSheet:c]

#define	_popWindowViewIfExists(c)	if ([self popWindowViewIfExists:(c)]) {		\
										return;									\
									}

@implementation TXMenuController

- (id)init
{
	if ((self = [super init])) {
		self.openWindowList = [NSDictionary dictionary];
		
		self.currentSearchPhrase = NSStringEmptyPlaceholder;
	}
	
	return self;
}

- (void)setupOtherServices
{
	TXLockMethodForOneTimeFire();
	
	if ([CSFWSystemInformation featureAvailableToOSXMountainLion]) {
		 self.fileTransferController = [TDCFileTransferDialog new];

		[self.fileTransferController startUsingDownloadDestinationFolderSecurityScopedBookmark];
	}
}

- (void)prepareForApplicationTermination
{
	[self popWindowSheetIfExists];
	
	if ([CSFWSystemInformation featureAvailableToOSXMountainLion]) {
		[self.fileTransferController prepareForApplicationTermination];
	}
}

- (void)preferencesChanged
{
	if ([CSFWSystemInformation featureAvailableToOSXMountainLion]) {
		[self.fileTransferController clearCachedIPAddress];
	}
}

- (void)validateChannelMenuSubmenus:(NSMenuItem *)item
{
	IRCChannel *c = [mainWindow() selectedChannel];

#define _channelMenuSeparatorGlobalMenuTag			937
#define _channelMenuSeparatorContextMenuTag			936
#define _channelSubmenuMenuTag						5422
#define _channelSubmenuLogsMenuTag					542
	
	NSMenuItem *separator1 = [[item menu] itemWithTag:_channelMenuSeparatorContextMenuTag];
	NSMenuItem *separator2 = [[item menu] itemWithTag:_channelMenuSeparatorGlobalMenuTag];
	NSMenuItem *channelMenu = [[item menu] itemWithTag:_channelSubmenuMenuTag];

	NSMenuItem *logMenuItem = [[channelMenu submenu] itemWithTag:_channelSubmenuLogsMenuTag];

	if (_isChannel) {
		[separator1 setHidden:NO];
		[separator2 setHidden:NO];
		
		[channelMenu setHidden:NO];
	} else {
		[separator1 setHidden:(c.isPrivateMessage == NO)];
		[separator2 setHidden:(c.isPrivateMessage == NO)];
		
		[channelMenu setHidden:YES];
	}

	[logMenuItem setEnabled:[TPCPreferences logToDiskIsEnabled]];
	
#undef _channelMenuSeparatorGlobalMenuTag
#undef _channelMenuSeparatorContextMenuTag
#undef _channelSubmenuMenuTag
#undef _channelSubmenuLogsMenuTag
}

- (BOOL)changeConditionInSheet:(BOOL)condition
{
	TVCMainWindowNegateActionWithAttachedSheetR(NO);

	return condition;
}

- (BOOL)validateMenuItem:(NSMenuItem *)item
{
	return [self validateMenuItemTag:[item tag] forItem:item];
}

- (BOOL)validateMenuItemTag:(NSInteger)tag forItem:(NSMenuItem *)item
{
	IRCClient *u = [mainWindow() selectedClient];
	IRCChannel *c = [mainWindow() selectedChannel];

	switch (tag) {
		case 2433: // "Sort Channel List"
		case 32345: // "Mark Scrollback"
		case 32346: // "Scrollback Marker"
		case 32347: // "Mark All As Read"
		case 32348: // "Clear Scrollback"
		case 32349: // "Increase Font Size"
		case 32350: // "Decrease Font Size"
		case 4564: // "Find…"
		case 4565: // "Find Next"
		case 4566: // "Find Previous"
		case 50001: // "Next Server"
		case 50002: // "Previous Server"
		case 50003: // "Next Active Server"
		case 50004: // "Previous Active Server"
		case 50005: // "Next Channel"
		case 50006: // "Previous Channel"
		case 50007: // "Next Active Channel"
		case 50008: // "Previous Active Channel"
		case 50009: // "Next Unread Channel"
		case 50010: // "Previous Unread Channel"
		case 50011: // "Previous Selection"
		case 50012: // "Move Forward"
		case 50013: // "Move Backward"
		case 521: // "Add Server…"
		case 542: // "Logs"
		case 5675: // "Connect to Help Channel"
		case 5676: // "Connect to Testing Channel"
		case 6666: // "Disable All Notification Sounds"
		case 6667: // "Disable All Notifications"
		case 6876: // "Topic"
		case 6877: // "Ban List"
		case 6878: // "Ban Exceptions"
		case 6879: // "Invite Exceptions"
		case 6880: // "General Settings"
		case 6881: // "Moderated (+m)"
		case 6882: // "Unmoderated (-m)"
		case 6883: // "Invite Only (+i)"
		case 6884: // "Anyone Can Join (-i)"
		case 6885: // "Manage All Modes"
		case 51065: // "Toggle Visbility of Server List"
		case 64611: // "Channel List…"
		{
			return _disableInSheet(YES);

			break;
		}
		case 594: // "File Transfers"
		case 52694: // "Send file…"
		{
			return _disableInSheet([CSFWSystemInformation featureAvailableToOSXMountainLion]);
			
			break;
		}
		case 51066: // "Toggle Visbility of Member List"
		{
			return _disableInSheet(_isChannel);

			break;
		}
		case 331: // "Search on Google"
		{
			[self validateChannelMenuSubmenus:item];
			
			TVCLogView *web = [self currentWebView];

			PointerIsEmptyAssertReturn(web, NO);
			
			return _disableInSheet([web hasSelection]);
			
			break;
		}
		case 501: // "Connect"
		{
			BOOL condition = (_connected || [u isConnecting]);
			
			[item setHidden:condition];

			BOOL prefersIPv6 = [_serverCurrentConfig connectionPrefersIPv6];

			if ([NSEvent modifierFlags] & NSShiftKeyMask) {
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

			return _disableInSheet((condition == NO && [u isQuitting] == NO));
			
			break;
		}
		case 502: // "Disconnect"
		{
			BOOL condition = (_connected || [u isConnecting]);
			
			[item setHidden:(condition == NO)];
			
			return _disableInSheet(condition);
			
			break;
		}
		case 503: // "Cancel Reconnect"
		{
			BOOL condition = [u isReconnecting];
			
			[item setHidden:(condition == NO)];
			
			return _disableInSheet(condition);
			
			break;
		}
		case 511: // "Change Nickname…"
		case 519: // "Channel List…"
		{
			return _disableInSheet(_connected);
			
			break;
		}
		case 523: // "Delete Server"
		{
			return _disableInSheet(_notConnected);
			
			break;
		}
		case 522: // "Duplicate Server"
		case 541: // "Server Properties…"
		case 590: // "Address Book"
		case 591: // "Ignore List"
		{
			return _disableInSheet(PointerIsNotEmpty(u));
			
			break;
		}
		case 592: // "Textual Logs"
		{
			return _disableInSheet([TPCPreferences logToDiskIsEnabled]);
			
			break;
		}
		case 601: // "Join Channel"
		{
			[self validateChannelMenuSubmenus:item];
			
			if (_isQuery) {
				[item setHidden:YES];
				
				return NO;
			} else {
				BOOL condition = (_connected && _notActive && _isChannel);
				
				if (_connected) {
					[item setHidden:(condition == NO)];
				} else {
					[item setHidden:NO];
				}
				
				return _disableInSheet(condition);
			}
			
			break;
		}
		case 602: // "Leave Channel"
		{
			if (_isQuery) {
				[item setHidden:YES];
				
				return NO;
			} else {
				[item setHidden:_notActive];
				
				return _disableInSheet(_activate);
			}
			
			break;
		}
		case 651: // "Add Channel…"
		{
			if (_isQuery) {
				[item setHidden:YES];
				
				return NO;
			} else {
				[item setHidden:NO];
				
				return _disableInSheet(PointerIsNotEmpty(u));
			}
			
			break;
		}
		case 652: // "Delete Channel"
		{
			if (_isQuery) {
				[item setTitle:BLS(1025)];
				
				return _disableInSheet(YES);
			} else {
				[item setTitle:BLS(1024)];
				
				return _disableInSheet(_isChannel);
			}
			
			break;
		}
		case 691: // "Add Channel…" — Server Menu
		{
			return _disableInSheet(PointerIsNotEmpty(u));
			
			break;
		}
		case 2005: // "Invite To…"
		{
			if (_notConnected || [self checkSelectedMembers:item] == NO) {
				return NO;
			}
			
			NSInteger count = 0;
			
			for (IRCChannel *e in [u channelList]) {
				if (NSDissimilarObjects(c, e) && [e isChannel]) {
					++count;
				}
			}
			
			return _disableInSheet((count > 0));
			
			break;
		}
		case 5421: // "Query Logs"
		{
#define _channelMenuUpperSeparatorTag		935

			NSMenuItem *separator1 = [[item menu] itemWithTag:_channelMenuUpperSeparatorTag];
			
			if (_isQuery) {
				[item setHidden:NO];
				
				[separator1 setHidden:YES]; 
				
				return _disableInSheet([TPCPreferences logToDiskIsEnabled]);
			} else {
				[item setHidden:YES];
				
				[separator1 setHidden:NO];
				
				return NO;
			}

#undef _channelSubmenuLogsMenuTag
			break;
		}
		case 9631: // "Close Window"
		{
			TVCMainWindow *mainWindow = mainWindow();
			
			if ([mainWindow isKeyWindow]) {
				TXCommandWKeyAction keyAction = [TPCPreferences commandWKeyAction];
				
				if (_noClientOrChannel) {
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
						if (_isClient) {
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
			
			break;
		}
		case 593: // "Highlight List"
		{
			return _disableInSheet([TPCPreferences logHighlights] && _connected);
			
			break;
		}
        case 54092: // Developer Mode
        {
            if ([RZUserDefaults() boolForKey:TXDeveloperEnvironmentToken] == YES) {
                [item setState:NSOnState];
            } else {  
                [item setState:NSOffState];
            }
            
            return YES;
			
			break;
        }
		case 504910 ... 504912: // User, right click menu, + mode changes
		case 504810 ... 504812: // User, right click menu, - mode changes
		{
#define _userControlsMenuAllModesTakenMenuTag		504813
#define _userControlsMenuAllModesGivenMenuTag		504913
			
#define _userControlsMenuGiveModeOMenuTag			504910
#define _userControlsMenuGiveModeHMenuTag			504911
#define _userControlsMenuGiveModeVMenuTag			504912
			
#define _userControlsMenuTakeModeOMenuTag			504810
#define _userControlsMenuTakeModeHMenuTag			504811
#define _userControlsMenuTakeModeVMenuTag			504812
			
			NSMenuItem *allModesTaken = [[item menu] itemWithTag:_userControlsMenuAllModesTakenMenuTag];
			NSMenuItem *allModesGiven = [[item menu] itemWithTag:_userControlsMenuAllModesGivenMenuTag];
			
			NSArray *nicknames = [self selectedMembers:nil];
			
			if (NSObjectIsEmpty(nicknames) || [nicknames count] > 1) {
				[item setHidden:NO];
				
				[allModesGiven setHidden:YES];
				[allModesTaken setHidden:YES];
				
				return _disableInSheet(YES);
			} else {
				IRCUser *m = [nicknames objectAtIndex:0];
				
				switch (tag) {
					case _userControlsMenuGiveModeOMenuTag:
					{
						[item setHidden:[m o]];
						
						break;
					}
					case _userControlsMenuGiveModeHMenuTag:
					{
						[item setHidden:[m h]];
						
						break;
					}
					case _userControlsMenuGiveModeVMenuTag:
					{
						[item setHidden:[m v]];
						
						break;
					}
					case _userControlsMenuTakeModeOMenuTag:
					{
						[item setHidden:([m o] == NO)];
						
						break;
					}
					case _userControlsMenuTakeModeHMenuTag:
					{
						[item setHidden:([m h] == NO)];
						
						break;
					}
					case _userControlsMenuTakeModeVMenuTag:
					{
						[item setHidden:([m v] == NO)];
						
						break;
					}
					default:
					{
						break;
					}
				}

				BOOL halfOpModeSupported = [[u isupport] modeIsSupportedUserPrefix:@"h"];

				if (tag == _userControlsMenuTakeModeHMenuTag ||
					tag == _userControlsMenuGiveModeHMenuTag)
				{
					/* Do not provide halfop as option on servers that do not use it. */

					if (halfOpModeSupported == NO) {
						[item setHidden:YES];
					}
				}
				
				BOOL hideTakeSepItem = ([m o] == NO  || [m h] == NO  || [m v] == NO);
				BOOL hideGiveSepItem = ([m o] == YES || [m h] == YES || [m v] == YES);
				
				[allModesGiven setHidden:hideTakeSepItem];
				[allModesTaken setHidden:hideGiveSepItem];

				if (tag == _userControlsMenuAllModesGivenMenuTag ||
					tag == _userControlsMenuAllModesTakenMenuTag)
				{
					return NO;
				}
				
				return _disableInSheet(YES);
			}

#undef _userControlsMenuAllModesTakenMenuTag
#undef _userControlsMenuAllModesGivenMenuTag
			
#undef _userControlsMenuGiveModeOMenuTag
#undef _userControlsMenuGiveModeHMenuTag
#undef _userControlsMenuGiveModeVMenuTag
			
#undef _userControlsMenuTakeModeOMenuTag
#undef _userControlsMenuTakeModeHMenuTag
#undef _userControlsMenuTakeModeVMenuTag
			break;
		}
		case 990002: // "Next Highlight"
		{
			TVCLogController *currentView = [mainWindow() selectedViewController];

			return _disableInSheet([currentView highlightAvailable:NO]);
			
			break;
		}
		case 990003: // "Previous Highlight"
		{
			TVCLogController *currentView = [mainWindow() selectedViewController];

			return _disableInSheet([currentView highlightAvailable:YES]);
			
			break;
		}
		default:
		{
			return YES;
			
			break;
		}
	}

	return YES;
}

#pragma mark -
#pragma mark Utilities

- (TVCLogView *)currentWebView
{
	TVCLogController *currentView = [mainWindow() selectedViewController];

	return [currentView webView];
}

#pragma mark -
#pragma mark Navigation Channel List

- (void)populateNavgiationChannelList
{
#define _channelNavigationMenuEntryMenuTag		64611
	
	/* Remove all previous entries. */
	[self.navigationChannelList removeAllItems];

	/* Begin populating… */
	NSInteger channelCount = 0;

	for (IRCClient *u in [worldController() clientList]) {
		/* Create a menu item for the client title. */
		NSMenuItem *newItem = [NSMenuItem menuItemWithTitle:BLS(1183, [u name]) target:nil action:nil];

		[self.navigationChannelList addItem:newItem];

		/* Begin populating channels. */
		for (IRCChannel *c in [u channelList]) {
			/* Create the menu item. Only first ten items get a key combo. */
			if (channelCount >= 10) {
				newItem = [NSMenuItem menuItemWithTitle:BLS(1184, [c name])
												 target:self
												 action:@selector(navigateToSpecificChannelInNavigationList:)];
			} else {
				NSInteger keyboardIndex = (channelCount + 1);

				if (keyboardIndex == 10) {
					keyboardIndex = 0; // Have 0 as the last item.
				}
				
				newItem = [NSMenuItem menuItemWithTitle:BLS(1184, [c name])
												 target:self
												 action:@selector(navigateToSpecificChannelInNavigationList:)
										  keyEquivalent:[NSString stringWithUniChar:('0' + keyboardIndex)]
									  keyEquivalentMask:NSCommandKeyMask];
			}

			/* The tag identifies each item. */
			[newItem setUserInfo:[worldController() findItemFromInfoGeneratedValue:c]];
			
			[newItem setTag:_channelNavigationMenuEntryMenuTag]; // Use same tag for each to disable during sheets.

			/* Add to the actaul navigation list. */
			[self.navigationChannelList addItem:newItem];

			/* Bump the count… */
			channelCount += 1;
		}
	}
	
#undef _channelNavigationMenuEntryMenuTag
}

- (void)navigateToSpecificChannelInNavigationList:(NSMenuItem *)sender
{
	id treeItem = [worldController() findItemFromInfo:[sender userInfo]];

	if (treeItem) {
		[mainWindow() select:treeItem];
	}
}

#pragma mark -
#pragma mark Selected User(s)

- (BOOL)checkSelectedMembers:(NSMenuItem *)item
{
	return ([mainWindowMemberList() countSelectedRows] > 0);
}

- (NSArray *)selectedMembers:(NSMenuItem *)sender
{
	IRCClient *u = [mainWindow() selectedClient];
	IRCChannel *c = [mainWindow() selectedChannel];
	
	NSMutableArray *ary = [NSMutableArray array];
	
	if (_noClientOrChannel || _notActive || _notConnected || _isClient) {
		return ary;
	} else {
		NSIndexSet *indexes = [mainWindowMemberList() selectedRowIndexes];

		BOOL indexEmpty = NSObjectIsEmpty(indexes);
		BOOL pontrEmpty = NSObjectIsEmpty(self.pointedNickname);

		if (indexEmpty == NO && pontrEmpty) {
			for (NSNumber *index in [indexes arrayFromIndexSet]) {
				NSUInteger nindex = [index unsignedIntegerValue];
				
				IRCUser *m = [mainWindowMemberList() itemAtRow:nindex];
				
				if (m) {
					[ary addObject:m];
				}
			}
		} else {
			if (pontrEmpty == NO) {
				IRCUser *m = [c findMember:self.pointedNickname];
				
				if (m) {
					[ary addObject:m];
				}
			}
		}
	}
	
	return ary;
}

- (void)deselectMembers:(NSMenuItem *)sender
{
	self.pointedNickname = nil;
	
	[mainWindowMemberList() deselectAll:nil];
}

#pragma mark -
#pragma mark Window List

- (void)addWindowToWindowList:(id)window
{
	NSString *key = NSStringFromClass([window class]);

	[self addWindowToWindowList:window
				   withKeyValue:key];
}

- (void)addWindowToWindowList:(id)window withKeyValue:(NSString *)key
{
	NSMutableDictionary *newList = [self.openWindowList mutableCopy];

	[newList setObjectWithoutOverride:window forKey:key];

	self.openWindowList = newList;
}

- (id)windowFromWindowList:(NSString *)windowClass
{
	return [self.openWindowList objectForKey:windowClass];
}

- (void)removeWindowFromWindowList:(NSString *)windowClass
{
	NSMutableDictionary *newList = [self.openWindowList mutableCopy];

	[newList removeObjectForKey:windowClass];

	self.openWindowList = newList;
}

- (BOOL)popWindowViewIfExists:(NSString *)windowClass
{
	id windowObject = [self windowFromWindowList:windowClass];

	if (windowObject) {
		NSWindow *window = [windowObject window];
		
		[window makeKeyAndOrderFront:nil];

		return YES;
	}

	return NO;
}

#warning Test to make sure isEqual selection is correct.
- (void)popWindowSheetIfExists
{
	/* Close any existing sheet by canceling the previous instance of it. */
	NSWindow *attachedSheet = [mainWindow() attachedSheet];
	
	if (attachedSheet) {
		for (NSString *windowKey in self.openWindowList) {
			id windowObject = [self.openWindowList objectForKey:windowKey];

			if ([[windowObject class] isSubclassOfClass:[TDCSheetBase class]]) {
				NSWindow *ownedWindow = (id)[windowObject sheet];
				
				if ([ownedWindow isEqual:attachedSheet]) {
					[windowObject cancel:nil];
					
					return; // No need to continue.
				}
			}
		}
	}
	
	[attachedSheet close];
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
				  completionBlock:^(BOOL defaultButtonClicked, NSString *resultString) {
					  if (defaultButtonClicked) {
						  if (NSObjectIsEmpty(resultString)) {
							  self.currentSearchPhrase = NSStringEmptyPlaceholder;
						  } else {
							  if ([resultString isNotEqualTo:self.currentSearchPhrase]) {
								  self.currentSearchPhrase = resultString;
							  }
							  
							  [self performBlockOnMainThread:^{
								  [[self currentWebView] searchFor:resultString direction:YES caseSensitive:NO wrap:YES];
							  }];
						  }
					  }

					  [self removeWindowFromWindowList:@"TXMenuControllerFindPanel"];
				  }];

	[self addWindowToWindowList:dialog withKeyValue:@"TXMenuControllerFindPanel"];
}

- (void)showFindPanel:(id)sender
{
#define _findPanelOpenPanelMenuTag		4564
#define _findPanelMoveForwardMenuTag	4565

	if ([sender tag] == _findPanelOpenPanelMenuTag || NSObjectIsEmpty(self.currentSearchPhrase)) {
		[self internalOpenFindPanel:sender];
	} else {
		if ([sender tag] == _findPanelMoveForwardMenuTag) {
			[[self currentWebView] searchFor:self.currentSearchPhrase direction:YES caseSensitive:NO wrap:YES];
		} else {
			[[self currentWebView] searchFor:self.currentSearchPhrase direction:NO caseSensitive:NO wrap:YES];
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

	[self addWindowToWindowList:pc];
}

- (void)preferencesDialogWillClose:(TDCPreferencesController *)sender
{
	[worldController() preferencesChanged];

	[self removeWindowFromWindowList:@"TDCPreferencesController"];
}

#pragma mark -
#pragma mark Menu Item Actions

- (void)paste:(id)sender
{
    NSWindow *keyWindow = [NSApp keyWindow];

    if ([keyWindow isEqual:mainWindow()]) {
		[mainWindowTextField() focus];
		
		[mainWindowTextField() paste:sender];
    } else {
        if ([[keyWindow firstResponder] respondsToSelector:@selector(paste:)]) {
            [[keyWindow firstResponder] performSelector:@selector(paste:) withObject:nil];
        }
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
	[RZWorkspace() openURL:[NSURL URLWithString:@"http://www.codeux.com/textual/wiki/Writing-Scripts.wiki"]];
}

- (void)searchGoogle:(id)sender
{
	TVCLogView *web = [self currentWebView];

	PointerIsEmptyAssert(web);
	
	NSString *s = [web selection];

	NSObjectIsEmptyAssert(s);

	/* Interesting fact: The class that Textual uses to encode URI arguments
	 is develooped by Google. So we are using a Google class to search Google. */
	s = [s gtm_stringByEscapingForURLArgument];
		
	NSString *urlStr = [NSString stringWithFormat:@"http://www.google.com/search?ie=UTF-8&q=%@", s];
		
	[TLOpenLink openWithString:urlStr];
}

- (void)copyLogAsHtml:(id)sender
{
	TVCLogView *sel = [self currentWebView];

	PointerIsEmptyAssert(sel);
	
	[RZPasteboard() setStringContent:sel.contentString];
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
	
	TEXTUAL_DEPRECATED_ASSERT;
}

- (void)connectPreferringIPv6:(id)sender
{
	IRCClient *u = [mainWindow() selectedClient];
	
	if (_noClient || _connected) {
		return;
	}
	
	[u connect:IRCClientConnectNormalMode preferringIPv6:YES];

	[mainWindow() expandClient:u]; // Expand client on user opreated connect.
}

- (void)connectPreferringIPv4:(id)sender
{
	IRCClient *u = [mainWindow() selectedClient];

	if (_noClient || _connected) {
		return;
	}

	[u connect:IRCClientConnectNormalMode preferringIPv6:NO];

	[mainWindow() expandClient:u]; // Expand client on user opreated connect.
}

- (void)disconnect:(id)sender
{
	IRCClient *u = [mainWindow() selectedClient];

	if (_noClient || _notConnected) {
		return;
	}
	
	[u quit];
	[u cancelReconnect];
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
	[self popWindowSheetIfExists];
	
	IRCClient *u = [mainWindow() selectedClient];
	
	if (_noClient || _notConnected) {
		return;
	}

	TDCNickSheet *nickSheet = [TDCNickSheet new];

	[nickSheet setDelegate:self];
	[nickSheet setClientID:[u treeUUID]];
	[nickSheet setWindow:mainWindow()];
	
	[nickSheet start:[u localNickname]];

	[self addWindowToWindowList:nickSheet];
}

- (void)nickSheet:(TDCNickSheet *)sender didInputNickname:(NSString *)nickname
{
	IRCClient *u = [worldController() findClientById:[sender clientID]];
	
	if (_noClient || _notConnected) {
		return;
	}
	
	[u changeNickname:nickname];
}

- (void)nickSheetWillClose:(TDCNickSheet *)sender
{
	[self removeWindowFromWindowList:@"TDCNickSheet"];
}

#pragma mark -
#pragma mark Menu Item Actions

- (void)showServerChannelList:(id)sender
{
	IRCClient *u = [mainWindow() selectedClient];
	
	if (_noClient || _notConnected) {
		return;
	}
	
	[u createChannelListDialog];
	
	[u send:IRCPrivateCommandIndex("list"), nil];
}

- (void)addServer:(id)sender
{
	[self popWindowSheetIfExists];
	
	TDCServerSheet *d = [TDCServerSheet new];
	
	[d setClientID:nil];
	[d setDelegate:self];
	[d setWindow:mainWindow()];
	[d setConfig:[IRCClientConfig new]];

	[d start:TDCServerSheetDefaultNavigationSelection withContext:nil];

	[self addWindowToWindowList:d];
}

- (void)copyServer:(id)sender
{
	IRCClient *u = [mainWindow() selectedClient];
	
	if (_noClient) {
		return;
	}
	
	IRCClientConfig *config = [u copyOfStoredConfig];
	
	NSString *newName = [[config clientName] stringByAppendingString:@"_"];

	[config setItemUUID:[NSString stringWithUUID]];
	
	[config setClientName:newName];
	
	[config setProxyPassword:nil];
	[config setServerPassword:nil];
	[config setNicknamePassword:nil];
	
	IRCClient *n = [worldController() createClient:config reload:YES];
	
	[worldController() save];
	
	if ([_serverCurrentConfig sidebarItemExpanded]) { // Only expand new client if old was expanded already.
		[mainWindow() expandClient:n];
	}
}

- (void)deleteServer:(id)sender
{
	IRCClient *u = [mainWindow() selectedClient];
	
	if (_noClient || _connected) {
		return;
	}
	
	NSString *warningToken = @"BasicLanguage[1198][2]";
	
#ifdef TEXTUAL_BUILT_WITH_ICLOUD_SUPPORT
	if ([TPCPreferences syncPreferencesToTheCloud]) {
		if ([_serverCurrentConfig excludedFromCloudSyncing] == NO) {
			warningToken = @"BasicLanguage[1198][3]";
		}
	}
#endif
	
	BOOL result = [TLOPopupPrompts dialogWindowWithQuestion:TXTLS(warningToken)
													  title:TXTLS(@"BasicLanguage[1198][1]")
											  defaultButton:BLS(1186)
											alternateButton:BLS(1009)
											 suppressionKey:nil
											suppressionText:nil];
	
	if (result == NO) {
		return;
	}
	
	[_serverCurrentConfig destroyKeychains];
	
	[worldController() destroyClient:u];
	[worldController() save];
}

#pragma mark -
#pragma mark Server Properties

- (void)showServerPropertyDialog:(IRCClient *)u withDefaultView:(TDCServerSheetNavigationSelection)viewType andContext:(NSString *)context
{
	if (_noClient) {
		return;
	}

	[self popWindowSheetIfExists];
	
	TDCServerSheet *d = [TDCServerSheet new];

	[d setDelegate:self];
	[d setWindow:mainWindow()];
	
	[d setClientID:[u treeUUID]];
	[d setConfig:[u copyOfStoredConfig]];
	
	[d start:viewType withContext:context];

	[self addWindowToWindowList:d];
}

- (void)showServerPropertiesDialog:(id)sender
{
	[self showServerPropertyDialog:[mainWindow() selectedClient]
				   withDefaultView:TDCServerSheetDefaultNavigationSelection
						andContext:nil];
}

- (void)serverSheetOnOK:(TDCServerSheet *)sender
{
	if ([sender clientID] == nil) {
		[worldController() createClient:[sender config] reload:YES];
		
		[sender.config writeKeychainItemsToDisk];
	} else {
		IRCClient *u = [worldController() findClientById:[sender clientID]];
		
		if (_noClient) {
			return;
		}

		BOOL samencoding = (sender.config.primaryEncoding ==
							     u.config.primaryEncoding);

		[u updateConfig:[sender config]];

		if (samencoding == NO) {
			[worldController() reloadTheme];
		}
	}
	
	[worldController() save];
}

#ifdef TEXTUAL_BUILT_WITH_ICLOUD_SUPPORT
- (void)serverSheetRequestedCloudExclusionByDeletion:(TDCServerSheet *)sender
{
	[worldController() addClientToListOfDeletedClients:[[sender config] itemUUID]];
}
#endif

- (void)serverSheetWillClose:(TDCServerSheet *)sender
{
	[self removeWindowFromWindowList:@"TDCServerSheet"];
}

#pragma mark -
#pragma mark Menu Item Actions

- (void)joinChannel:(id)sender
{
	IRCClient *u = [mainWindow() selectedClient];
	IRCChannel *c = [mainWindow() selectedChannel];
	
	if (_noClientOrChannel || _isClient || _isQuery || _activate || _notConnected) {
		return;
	}

	[u setInUserInvokedJoinRequest:YES];
	
	[u joinChannel:c];
}

- (void)leaveChannel:(id)sender
{
	IRCClient *u = [mainWindow() selectedClient];
	IRCChannel *c = [mainWindow() selectedChannel];
	
	if (_noClientOrChannel || _notActive || _notConnected) {
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
	[self popWindowSheetIfExists];
	
	IRCClient *u = [mainWindow() selectedClient];
	
	if (_noClient) {
		return;
	}
	
	TDCHighlightListSheet *d = [TDCHighlightListSheet new];
	
	[d setDelegate:self];
	[d setWindow:mainWindow()];
	
	[d show];

	[self addWindowToWindowList:d];
}

- (void)highlightListSheetWillClose:(TDCHighlightListSheet *)sender
{
	[self removeWindowFromWindowList:@"TDCHighlightListSheet"];
}

#pragma mark -
#pragma mark Channel Topic Sheet

- (void)showChannelTopicDialog:(id)sender
{
	[self popWindowSheetIfExists];

	IRCClient *u = [mainWindow() selectedClient];
	IRCChannel *c = [mainWindow() selectedChannel];

	if (_noClientOrChannel || _isClient || _isQuery) {
		return;
	}

	TDCTopicSheet *t = [TDCTopicSheet new];

	[t setDelegate:self];
	[t setWindow:mainWindow()];
	
	[t setClientID:[u treeUUID]];
	[t setChannelID:[u treeUUID]];

	[t start:[c topic]];

	[self addWindowToWindowList:t];
}

- (void)topicSheet:(TDCTopicSheet *)sender onOK:(NSString *)topic
{
	IRCChannel *c = [worldController() findChannelByClientId:[sender clientID]
												   channelId:[sender channelID]];
	
	IRCClient *u = [c associatedClient];
	
	if (_noClientOrChannel || _isClient || _isQuery) {
		return;
	}
	
	if ([u encryptOutgoingMessage:&topic channel:c] == YES) {
		[u send:IRCPrivateCommandIndex("topic"), [c name], topic, nil];
	}
}

- (void)topicSheetWillClose:(TDCTopicSheet *)sender
{
	[self removeWindowFromWindowList:@"TDCTopicSheet"];
}

#pragma mark -
#pragma mark Channel Mode Sheet

- (void)showChannelModeDialog:(id)sender
{
	[self popWindowSheetIfExists];

	IRCClient *u = [mainWindow() selectedClient];
	IRCChannel *c = [mainWindow() selectedChannel];
	
	if (_noClientOrChannel || _isClient || _isQuery) {
		return;
	}
	
	TDCModeSheet *m = [TDCModeSheet new];
	
	[m setDelegate:self];
	[m setWindow:mainWindow()];
	
	[m setClientID:[u treeUUID]];
	[m setChannelID:[c treeUUID]];
	
	[m setMode:[c modeInfo]];

	[m start];

	[self addWindowToWindowList:m];
}

- (void)modeSheetOnOK:(TDCModeSheet *)sender
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

- (void)modeSheetWillClose:(TDCModeSheet *)sender
{
	[self removeWindowFromWindowList:@"TDCModeSheet"];
}

#pragma mark -
#pragma mark Menu Item Actions

- (void)addChannel:(id)sender
{
	[self popWindowSheetIfExists];
	
	IRCClient *u = [mainWindow() selectedClient];
	
	if (_noClient) {
		return;
	}
	
	TDChannelSheet *d = [TDChannelSheet new];

	[d setNewItem:YES];
	
	[d setDelegate:self];
	[d setWindow:mainWindow()];
	
	[d setClientID:[u treeUUID]];
	[d setChannelID:nil];
	
	[d setConfig:[IRCChannelConfig new]];

	[d start];

	[self addWindowToWindowList:d];
}

- (void)deleteChannel:(id)sender
{
	IRCChannel *c = [mainWindow() selectedChannel];
	
	if (_noChannel || _isClient) {
		return;
	}
	
	if (_isChannel) {
		BOOL result = [TLOPopupPrompts dialogWindowWithQuestion:TXTLS(@"BasicLanguage[1010][1]")
														  title:TXTLS(@"BasicLanguage[1010][2]") 
												  defaultButton:BLS(1186)
												alternateButton:BLS(1009)
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
	[self popWindowSheetIfExists];

	IRCClient *u = [mainWindow() selectedClient];
	IRCChannel *c = [mainWindow() selectedChannel];
	
	if (_noClientOrChannel || _isClient || _isQuery) {
		return;
	}
	
	TDChannelSheet *d = [TDChannelSheet new];

	[d setNewItem:NO];
	
	[d setDelegate:self];
	[d setWindow:mainWindow()];
	
	[d setClientID:[u treeUUID]];
	[d setChannelID:[c treeUUID]];
	
	[d setConfig:_channelConfig];

	[d start];

	[self addWindowToWindowList:d];
}

- (void)channelSheetOnOK:(TDChannelSheet *)sender
{
	if ([sender newItem]) {
		IRCClient *u = [worldController() findClientById:[sender clientID]];
		
		if (_noClient) {
			return;
		}
		
		[mainWindow() expandClient:u];
		
		[worldController() createChannel:[sender config] client:u reload:YES adjust:YES];
		
		[sender.config writeKeychainItemsToDisk];
	} else {
		IRCChannel *c = [worldController() findChannelByClientId:[sender clientID] channelId:[sender channelID]];
		
		if (_noChannel) {
			return;
		}

		NSString *oldKey = [_channelConfig encryptionKey];
		
		NSString *newKey = [sender.config temporaryEncryptionKey];
		
		BOOL oldKeyEmpty = NSObjectIsEmpty(oldKey);
		BOOL newKeyEmpty = NSObjectIsEmpty(newKey);

		[c updateConfig:[sender config]];

		if (oldKeyEmpty && newKeyEmpty == NO) {
			[[c associatedClient] printDebugInformation:BLS(1003) channel:c];
		} else if (oldKeyEmpty == NO && newKeyEmpty) {
			[[c associatedClient] printDebugInformation:BLS(1004) channel:c];
		} else if (oldKeyEmpty == NO && newKeyEmpty == NO) {
			if (NSObjectsAreEqual(oldKey, newKey) == NO) {
				[[c associatedClient] printDebugInformation:BLS(1002) channel:c];
			}
		}
	}
	
	[worldController() save];
}

- (void)channelSheetWillClose:(TDChannelSheet *)sender
{
	[self removeWindowFromWindowList:@"TDChannelSheet"];
}

#pragma mark -
#pragma mark Menu Item Actions

- (void)memberInMemberListDoubleClicked:(id)sender
{
    TVCMemberList *view = sender;
    
	NSPoint ml = [mainWindow() mouseLocationOutsideOfEventStream];
	
    NSPoint pt = [view convertPoint:ml fromView:nil];
	
    NSInteger n = [view rowAtPoint:pt];
    
    if (n >= 0) {
		TXUserDoubleClickAction action = [TPCPreferences userDoubleClickOption];
        
		if (action == TXUserDoubleClickWhoisAction) {
			[self whoisSelectedMembers:nil deselectPointedNickname:NO];
		} else if (action == TXUserDoubleClickPrivateMessageAction) {
			[self memberStartPrivateMessage:nil deselectPointedNickname:NO];
		} else if (action == TXUserDoubleClickInsertTextFieldAction) {
			[self memberInsertNameIntoTextField:nil deselectPointedNickname:NO];
		}
    }
}

- (void)memberInChannelViewDoubleClicked:(id)sender
{
    if (self.pointedNickname) {
		TXUserDoubleClickAction action = [TPCPreferences userDoubleClickOption];

		if (action == TXUserDoubleClickWhoisAction) {
			[self whoisSelectedMembers:nil deselectPointedNickname:YES];
		} else if (action == TXUserDoubleClickPrivateMessageAction) {
			[self memberStartPrivateMessage:nil deselectPointedNickname:YES];
		} else if (action == TXUserDoubleClickInsertTextFieldAction) {
			[self memberInsertNameIntoTextField:nil deselectPointedNickname:YES];
		}
    }
}

- (void)memberInsertNameIntoTextField:(id)sender
{
	/* Each double click method gets a deselectPointedNickname: sent to it
	 depending on whether it was double clicked within the channel view or
	 the member list. The purposes of this is to only deselect self.pointedNickname
	 if it was from within the channel view to allow the selection in the
	 user list to remain unchanged. */

	[self memberInsertNameIntoTextField:sender deselectPointedNickname:NO];
}

- (void)memberInsertNameIntoTextField:(id)sender deselectPointedNickname:(BOOL)deselectPointedNickname
{
	IRCClient *u = [mainWindow() selectedClient];
	IRCChannel *c = [mainWindow() selectedChannel];
    
	if (_noClient || _isClient) {
		return;
	}
    
	/* Get list of users. */
	NSMutableArray *users = [NSMutableArray array];
    
	for (IRCUser *m in [self selectedMembers:sender]) {
		[users addObject:[m nickname]];
	}
    
	/* The text field. */
	TVCMainWindowTextView *textField = mainWindowTextField();
    
	NSRange selectedRange = [textField selectedRange];
    
	NSInteger insertLocation = selectedRange.location;
    
	/* Build insert string. */
	NSString *insertString;
    
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
	NSAttributedString *stringInsert = [NSAttributedString emptyStringWithBase:insertString];
    
	NSData *stringData = [stringInsert RTFFromRange:NSMakeRange(0, [stringInsert length]) documentAttributes:nil];
    
    [textField replaceCharactersInRange:selectedRange withRTF:stringData];

	/* Close users. */
	if (deselectPointedNickname) {
		self.pointedNickname = nil;
	} else {
		[self deselectMembers:sender];
	}
	
	/* Set focus to the input textfield. */
	[textField focus];
}

- (void)memberSendWhois:(id)sender
{
	[self whoisSelectedMembers:sender deselectPointedNickname:NO];
}

- (void)whoisSelectedMembers:(id)sender deselectPointedNickname:(BOOL)deselectPointedNickname
{
	IRCClient *u = [mainWindow() selectedClient];
	IRCChannel *c = [mainWindow() selectedChannel];

	if (_noClient || _isClient) {
		return;
	}

	for (IRCUser *m in [self selectedMembers:sender]) {
		[u sendWhois:[m nickname]];
	}

	if (deselectPointedNickname) {
		self.pointedNickname = nil;
	} else {
		[self deselectMembers:sender];
	}
}

- (void)memberStartPrivateMessage:(id)sender
{
	[self memberStartPrivateMessage:sender deselectPointedNickname:NO];
}

- (void)memberStartPrivateMessage:(id)sender deselectPointedNickname:(BOOL)deselectPointedNickname
{
	IRCClient *u = [mainWindow() selectedClient];
	IRCChannel *c = [mainWindow() selectedChannel];
	
	if (_noClient || _isClient) {
		return;
	}
	
	for (IRCUser *m in [self selectedMembers:sender]) {
		IRCChannel *c = [u findChannelOrCreate:[m nickname] isPrivateMessage:YES];
		
		[mainWindow() select:c];
	}

	if (deselectPointedNickname) {
		self.pointedNickname = nil;
	} else {
		[self deselectMembers:sender];
	}
}

#pragma mark -
#pragma mark Channel Invite Sheet

- (void)memberSendInvite:(id)sender
{
	[self popWindowSheetIfExists];

	IRCClient *u = [mainWindow() selectedClient];
	IRCChannel *c = [mainWindow() selectedChannel];
	
	if (_noClientOrChannel || _notConnected) {
		return;
	}

	NSMutableArray *channels = [NSMutableArray array];
	NSMutableArray *nicknames = [NSMutableArray array];

	for (IRCUser *m in [self selectedMembers:sender]) {
		[nicknames addObject:[m nickname]];
	}
	
	for (IRCChannel *e in [u channelList]) {
		if (NSDissimilarObjects(c, e) && [e isChannel]) {
			[channels addObject:[e name]];
		}
	}

	NSObjectIsEmptyAssert(channels);
	NSObjectIsEmptyAssert(nicknames);

	TDCInviteSheet *inviteSheet = [TDCInviteSheet new];
	
	[inviteSheet setDelegate:self];
	[inviteSheet setWindow:mainWindow()];
	
	[inviteSheet setNicknames:nicknames];
	[inviteSheet setClientID:[u treeUUID]];

	[inviteSheet startWithChannels:channels];

	[self addWindowToWindowList:inviteSheet];
}

- (void)inviteSheet:(TDCInviteSheet *)sender onSelectChannel:(NSString *)channelName
{
	IRCClient *u = [worldController() findClientById:[sender clientID]];
	
	if (u && [channelName isChannelName]) {
		for (NSString *nick in [sender nicknames]) {
			[u send:IRCPrivateCommandIndex("invite"), nick, channelName, nil];
		}
	}
}

- (void)inviteSheetWillClose:(TDCInviteSheet *)sender
{
	[self removeWindowFromWindowList:@"TDCInviteSheet"];
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
	
	for (IRCUser *m in [self selectedMembers:sender]) {
		[u sendCTCPPing:[m nickname]];
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

	for (IRCUser *m in [self selectedMembers:sender]) {
		[u sendCTCPQuery:[m nickname] command:IRCPrivateCommandIndex("ctcp_finger") text:nil];
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

	for (IRCUser *m in [self selectedMembers:sender]) {
		[u sendCTCPQuery:[m nickname] command:IRCPrivateCommandIndex("ctcp_time") text:nil];
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

	for (IRCUser *m in [self selectedMembers:sender]) {
		[u sendCTCPQuery:[m nickname] command:IRCPrivateCommandIndex("ctcp_version") text:nil];
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

	for (IRCUser *m in [self selectedMembers:sender]) {
		[u sendCTCPQuery:[m nickname] command:IRCPrivateCommandIndex("ctcp_userinfo") text:nil];
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

	for (IRCUser *m in [self selectedMembers:sender]) {
		[u sendCTCPQuery:[m nickname] command:IRCPrivateCommandIndex("ctcp_clientinfo") text:nil];
	}
	
	[self deselectMembers:sender];
}

- (void)copyUrl:(id)sender
{
	NSObjectIsEmptyAssert(_pointedUrl);

	[RZPasteboard() setStringContent:_pointedUrl];
		
	_pointedUrl = nil;
}

- (void)joinClickedChannel:(id)sender
{
	NSObjectIsEmptyAssert(self.pointedChannelName);
	
	IRCClient *u = [mainWindow() selectedClient];
	
	if (_noClient || _notConnected) {
		return;
	}

	[u setInUserInvokedJoinRequest:YES];
	
	[u joinUnlistedChannel:self.pointedChannelName];
		
	self.pointedChannelName = nil;
}

- (void)showChannelIgnoreList:(id)sender
{
	[self showServerPropertyDialog:[mainWindow() selectedClient]
					withDefaultView:TDCServerSheetAddressBookNavigationSelection
						andContext:@"-"];
}

#pragma mark -
#pragma mark Welcome Sheet

- (void)openWelcomeSheet:(id)sender
{
	[self popWindowSheetIfExists];
	
	TDCWelcomeSheet *welcomeSheet = [TDCWelcomeSheet new];
	
	[welcomeSheet setDelegate:self];
	[welcomeSheet setWindow:mainWindow()];
	
	[welcomeSheet show];
	
	[self addWindowToWindowList:welcomeSheet];
}

- (void)welcomeSheet:(TDCWelcomeSheet *)sender onOK:(IRCClientConfig *)config
{
	IRCClient *u = [worldController() createClient:config reload:YES];
	
	[mainWindow() expandClient:u];
	
	[worldController() save];
	
	if (u.config.autoConnect) {
		[u connect];
	}
	
	[u selectFirstChannelInChannelList];
}

- (void)welcomeSheetWillClose:(TDCWelcomeSheet *)sender
{
	[self removeWindowFromWindowList:@"TDCWelcomeSheet"];
}

#pragma mark -
#pragma mark About Window

- (void)showAboutWindow:(id)sender
{
	_popWindowViewIfExists(@"TDCAboutPanel");
	
	TDCAboutPanel *aboutPanel = [TDCAboutPanel new];

	[aboutPanel setDelegate:self];

	[aboutPanel show];

	[self addWindowToWindowList:aboutPanel];
}

- (void)aboutPanelWillClose:(TDCAboutPanel *)sender
{
	[self removeWindowFromWindowList:@"TDCAboutPanel"];
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
	
	for (IRCUser *m in [self selectedMembers:sender]) {
		opString = [opString stringByAppendingFormat:@"%@ ", [m nickname]];
		
		currentIndex += 1;

		if (currentIndex == [[u isupport] modesCount]) {
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
	
	for (IRCUser *m in [self selectedMembers:sender]) {
		[u kick:c target:[m nickname]];
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
	
	for (IRCUser *m in [self selectedMembers:sender]) {
		[u sendCommand:[NSString stringWithFormat:@"%@ %@", IRCPublicCommandIndex("ban"), [m nickname]] completeTarget:YES target:[c name]];
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
	
	for (IRCUser *m in [self selectedMembers:sender]) {
		[u sendCommand:[NSString stringWithFormat:@"%@ %@ %@", IRCPublicCommandIndex("kickban"), [m nickname], [TPCPreferences defaultKickMessage]] completeTarget:YES target:[c name]];
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
	
	for (IRCUser *m in [self selectedMembers:sender]) {
		[u sendCommand:[NSString stringWithFormat:@"%@ %@ %@", IRCPublicCommandIndex("kill"), [m nickname], [TPCPreferences IRCopDefaultKillMessage]]];
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
	
	for (IRCUser *m in [self selectedMembers:sender]) {
        if ([[m nickname] isEqualIgnoringCase:[u localNickname]]) {
            [u printDebugInformation:BLS(1197, [u networkAddress]) channel:c];
        } else {
            [u sendCommand:[NSString stringWithFormat:@"%@ %@ %@", IRCPublicCommandIndex("gline"), [m nickname], [TPCPreferences IRCopDefaultGlineMessage]]];
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
	
	for (IRCUser *m in [self selectedMembers:sender]) {
		[u sendCommand:[NSString stringWithFormat:@"%@ %@ %@", IRCPublicCommandIndex("shun"), [m nickname], [TPCPreferences IRCopDefaultShunMessage]]];
	}
	
	[self deselectMembers:sender];
}

- (void)memberSendFileRequest:(id)sender
{
	IRCClient *u = [mainWindow() selectedClient];
	IRCChannel *c = [mainWindow() selectedChannel];
	
	if (_noClientOrChannel || _isClient || _notConnected) {
		return;
	}
	
	NSOpenPanel *d = [NSOpenPanel openPanel];
	
	[d setCanChooseFiles:YES];
	[d setCanChooseDirectories:NO];
	[d setResolvesAliases:YES];
	[d setAllowsMultipleSelection:YES];
	[d setCanCreateDirectories:NO];
	
	[d beginSheetModalForWindow:mainWindow() completionHandler:^(NSInteger returnCode) {
		if (returnCode == NSOKButton) {
			[[self.fileTransferController fileTransferTable] beginUpdates];
			
			for (IRCUser *m in [self selectedMembers:sender]) {
				for (NSURL *pathURL in [d URLs]) {
					[self.fileTransferController addSenderForClient:u nickname:[m nickname] path:[pathURL path] autoOpen:YES];
				}
			}
			
			[[self.fileTransferController fileTransferTable] endUpdates];
		}
		
		[self deselectMembers:sender];
	}];
}

- (void)memberSendDroppedFiles:(NSArray *)files row:(NSNumber *)row
{
	IRCClient *u = [mainWindow() selectedClient];
	IRCChannel *c = [mainWindow() selectedChannel];
	
	if (_noClientOrChannel || _isClient || _notConnected) {
		return;
	}
	
	IRCUser *member = [mainWindowMemberList() itemAtRow:[row integerValue]];
	
	for (NSString *pathURL in files) {
		BOOL isDirectory = NO;
		
		if ([RZFileManager() fileExistsAtPath:pathURL isDirectory:&isDirectory]) {
			if (isDirectory) {
				continue;
			}
		}
		
		[self.fileTransferController addSenderForClient:u nickname:[member nickname] path:pathURL autoOpen:YES];
	}
}

- (void)openLogLocation:(id)sender
{	
	NSURL *path = [TPCPathInfo logFileFolderLocation];
	
	if ([RZFileManager() fileExistsAtPath:[path path]]) {
		[RZWorkspace() openURL:path];
	} else {
		[TLOPopupPrompts dialogWindowWithQuestion:TXTLS(@"BasicLanguage[1110][2]")
											title:TXTLS(@"BasicLanguage[1110][1]")
									defaultButton:BLS(1186)
								  alternateButton:nil
								   suppressionKey:nil
								  suppressionText:nil];
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
		[TLOPopupPrompts dialogWindowWithQuestion:TXTLS(@"BasicLanguage[1110][2]")
											title:TXTLS(@"BasicLanguage[1110][1]")
									defaultButton:BLS(1186)
								  alternateButton:nil
								   suppressionKey:nil
								  suppressionText:nil];
	}
}

- (void)connectToTextualHelpChannel:(id)sender 
{
	[IRCExtras createConnectionAndJoinChannel:@"chat.freenode.net +6697" channel:@"#textual" autoConnect:YES focusChannel:YES];
}

- (void)connectToTextualTestingChannel:(id)sender
{
	[IRCExtras createConnectionAndJoinChannel:@"chat.freenode.net +6697" channel:@"#textual-testing" autoConnect:YES focusChannel:YES];
}

- (void)onWantHostServVhostSet:(id)sender
{
	IRCClient *u = [mainWindow() selectedClient];
	IRCChannel *c = [mainWindow() selectedChannel];
	
	if (_noClientOrChannel || _isClient) {
		return;
	}
	
	NSMutableArray *nicknames = [NSMutableArray array];
	
	for (IRCUser *m in [self selectedMembers:sender]) {
		[nicknames addObject:[m nickname]];
	}
	
	[self deselectMembers:sender];

	TVCInputPromptDialog *dialog = [TVCInputPromptDialog new];

	[dialog alertWithMessageTitle:TXTLS(@"BasicLanguage[1228][1]")
					defaultButton:BLS(1186)
				  alternateButton:BLS(1009)
				  informativeText:TXTLS(@"BasicLanguage[1228][2]")
				 defaultUserInput:nil
				  completionBlock:^(BOOL defaultButtonClicked, NSString *resultString) {
					  if (defaultButtonClicked) {
						  if (NSObjectIsNotEmpty(resultString)) {
							  for (NSString *nickname in nicknames) {
								  [u sendCommand:[NSString stringWithFormat:@"hs setall %@ %@", nickname, resultString] completeTarget:NO target:nil];
							  }
						  }
					  }
				  }];
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
	
	[u createChanBanListDialog];
	
	[u send:IRCPrivateCommandIndex("mode"), [c name], @"+b", nil];
}

- (void)showChannelBanExceptionList:(id)sender
{
	IRCClient *u = [mainWindow() selectedClient];
	IRCChannel *c = [mainWindow() selectedChannel];

	if (_noChannel || _isClient || _isQuery) {
		return;
	}
	
	[u createChanBanExceptionListDialog];
	
	[u send:IRCPrivateCommandIndex("mode"), [c name], @"+e", nil];
}

- (void)showChannelInviteExceptionList:(id)sender
{
	IRCClient *u = [mainWindow() selectedClient];
	IRCChannel *c = [mainWindow() selectedChannel];

	if (_noChannel || _isClient || _isQuery) {
		return;
	}
	
	[u createChanInviteExceptionListDialog];
	
	[u send:IRCPrivateCommandIndex("mode"), [c name], @"+I", nil];
}

- (void)openHelpMenuLinkItem:(id)sender
{
	static NSDictionary *_helpMenuLinks = nil;
	
	if (_helpMenuLinks == nil) {
		_helpMenuLinks = @{
		   @(101) : @"http://www.codeux.com/textual/wiki/3rd-Party-Addons.wiki",
		   @(102) : @"http://www.codeux.com/textual/wiki/Frequently-Asked-Questions.wiki",
		   @(103) : @"http://www.codeux.com/textual/wiki/home.wiki",
		   @(104) : @"http://www.codeux.com/textual/wiki/iCloud-Syncing.wiki",
		   @(105) : @"http://www.codeux.com/textual/wiki/Encrypted-Chat.wiki",
		   @(106) : @"http://www.codeux.com/textual/wiki/Command-Reference.wiki",
		   @(107) : @"http://www.codeux.com/textual/wiki/Support.wiki",
		   @(108) : @"http://www.codeux.com/textual/wiki/Keyboard-Shortcuts.wiki",
		   @(109) : @"http://www.codeux.com/textual/wiki/Memory-Management.wiki",
		   @(110) : @"http://www.codeux.com/textual/wiki/Text-Formatting.wiki",
		   @(111) : @"http://www.codeux.com/textual/wiki/Styles.wiki",
		   @(112) : @"http://www.codeux.com/textual/wiki/Using-CertFP.wiki",
		   @(113) : @"http://www.codeux.com/textual/wiki/Connecting-to-ZNC-Bouncer.wiki",
		   @(114) : @"http://www.codeux.com/textual/wiki/DCC-File-Transfer-Information.wiki"
		};
	}
	
	NSString *linkloc = [_helpMenuLinks objectForKey:@([sender tag])];
	
	[TLOpenLink openWithString:linkloc];
}

- (void)openMacAppStoreDownloadPage:(id)sender
{
	[TLOpenLink openWithString:@"http://www.textualapp.com/"];
}

- (void)processNavigationItem:(NSMenuItem *)sender
{
	switch ([sender tag]) {
		case 50001: { [mainWindow() selectNextServer:nil];					break;		}
		case 50002: { [mainWindow() selectPreviousServer:nil];				break;		}
		case 50003: { [mainWindow() selectNextActiveServer:nil];			break;		}
		case 50004: { [mainWindow() selectPreviousActiveServer:nil];		break;		}
		case 50005: { [mainWindow() selectNextChannel:nil];					break;		}
		case 50006: { [mainWindow() selectPreviousChannel:nil];				break;		}
		case 50007: { [mainWindow() selectNextActiveChannel:nil];			break;		}
		case 50008: { [mainWindow() selectPreviousActiveChannel:nil];		break;		}
		case 50009: { [mainWindow() selectNextUnreadChannel:nil];			break;		}
		case 50010: { [mainWindow() selectPreviousUnreadChannel:nil];		break;		}
		case 50011: { [mainWindow() selectPreviousSelection:nil];			break;		}
		case 50012: { [mainWindow() selectNextWindow:nil];					break;		}
		case 50013: { [mainWindow() selectPreviousWindow:nil];				break;		}
	}
}

- (void)showMainWindow:(id)sender 
{
	[mainWindow() makeKeyAndOrderFront:nil];
}

- (void)sortChannelListNames:(id)sender
{
	TVCServerList *serverList = mainWindowServerList();

	id oldSelection = [mainWindow() selectedItem];
	
	[mainWindow() setTemporarilyDisablePreviousSelectionUpdates:YES];

	for (IRCClient *u in [worldController() clientList]) {
		NSMutableArray *channels = [[u channelList] mutableCopy];
		
		[channels sortUsingComparator:^NSComparisonResult(id obj1, id obj2) {
			NSString *name1 = [[obj1 name] lowercaseString];
			NSString *name2 = [[obj2 name] lowercaseString];
			
			return [name1 compare:name2];
		}];
		
		[u setChannelList:channels];
		
		[u updateConfig:[u copyOfStoredConfig] fromTheCloud:NO withSelectionUpdate:NO];
		
		// Reload actual views.
		[serverList reloadItem:u reloadChildren:YES];
	}
	
	[worldController() save];
	
	[mainWindow() select:oldSelection];
	
	[mainWindow() setTemporarilyDisablePreviousSelectionUpdates:NO];
	
	[self populateNavgiationChannelList];
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
#define _toggleChannelModerationModeOffTag		6882
	
	IRCClient *u = [mainWindow() selectedClient];
	IRCChannel *c = [mainWindow() selectedChannel];

	if (_noChannel || _isClient || _isQuery) {
		return;
	}
	
	NSString *modeValue;
	
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
#define _toggleChannelInviteStatusModeOffTag		6884
	
	IRCClient *u = [mainWindow() selectedClient];
	IRCChannel *c = [mainWindow() selectedChannel];

	if (_noChannel || _isClient || _isQuery) {
		return;
	}
	
	NSString *modeValue;
	
	if ([sender tag] == _toggleChannelInviteStatusModeOffTag) {
		modeValue = @"-i";
	} else {
		modeValue = @"+i";
	}

	[u sendCommand:[NSString stringWithFormat:@"%@ %@ %@", IRCPublicCommandIndex("mode"), [c name], modeValue]];
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

- (void)openDefaultIRCClientDialog:(id)sender
{
	[TPCApplicationInfo defaultIRCClientPrompt:YES];
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
	
	[self.muteNotificationsFileMenuItem setState:state];
	[self.muteNotificationsDockMenuItem setState:state];
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
	/* Textual automatically hides and show the member list when switching between 
	 server console, channels, and queries therefore we have to tell it through a
	 property that we don't want it shown at all. */
	[mainWindowMemberList() setIsHiddenByUser:([mainWindowMemberList() isHiddenByUser] == NO)];

	/* Toggle visibility. */
	[[mainWindow() contentSplitView] toggleMemberListVisbility];
}

@end
