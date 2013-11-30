/* ********************************************************************* 
       _____        _               _    ___ ____   ____
      |_   _|___  _| |_ _   _  __ _| |  |_ _|  _ \ / ___|
       | |/ _ \ \/ / __| | | |/ _` | |   | || |_) | |
       | |  __/>  <| |_| |_| | (_| | |   | ||  _ <| |___
       |_|\___/_/\_\\__|\__,_|\__,_|_|  |___|_| \_\\____|

 Copyright (c) 2008 - 2010 Satoshi Nakagawa <psychs AT limechat DOT net>
 Copyright (c) 2010 — 2013 Codeux Software & respective contributors.
        Please see Contributors.rtfd and Acknowledgements.rtfd

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

#define _activate					(c && c.isActive)
#define _connected					(u && u.isConnected && u.isLoggedIn)
#define _isChannel					(c.isPrivateMessage == NO && c.isChannel == YES && c.isClient == NO)
#define _isClient					(c.isPrivateMessage == NO && c.isChannel == NO && c.isClient == YES)
#define _isQuery					(c.isPrivateMessage == YES && c.isChannel == NO && c.isClient == NO)
#define _noChannel					(PointerIsEmpty(c))
#define _noClient					(PointerIsEmpty(u))
#define _noClientOrChannel			(PointerIsEmpty(u) || PointerIsEmpty(c))
#define _notActive					(c && c.isActive == NO)
#define _notConnected				(u && u.isConnected == NO && u.isLoggedIn == NO && u.isConnecting == NO)

#define _disableInSheet(c)			[self changeConditionInSheet:c]

@implementation TXMenuController

- (id)init
{
	if ((self = [super init])) {
		self.openWindowList = [NSDictionary dictionary];
		
		self.currentSearchPhrase = NSStringEmptyPlaceholder;
	}
	
	return self;
}

- (void)terminate
{
	[self popWindowSheetIfExists];
}

- (void)validateChannelMenuSubmenus:(NSMenuItem *)item
{
	IRCChannel *c = [self.worldController selectedChannel];

	NSMenuItem *separator1 = [item.menu itemWithTag:936];
	NSMenuItem *separator2 = [item.menu itemWithTag:937];
	NSMenuItem *channelMenu = [item.menu itemWithTag:5422];

	NSMenuItem *logMenuItem = [channelMenu.submenu itemWithTag:542];

	if (_isChannel) {
		[separator1 setHidden:NO];
		[separator2 setHidden:NO];
		
		[channelMenu setHidden:NO];
	} else {
		[separator1 setHidden:BOOLReverseValue(c.isPrivateMessage)];
		[separator2 setHidden:BOOLReverseValue(c.isPrivateMessage)];
		
		[channelMenu setHidden:YES];
	}

	[logMenuItem setEnabled:[TPCPreferences logTranscript]];
}

- (BOOL)changeConditionInSheet:(BOOL)condition
{
	NSWindowNegateActionWithAttachedSheetR(NO);

	return condition;
}

- (BOOL)validateMenuItem:(NSMenuItem *)item
{
	return [self validateMenuItemTag:item.tag forItem:item];
}

- (BOOL)validateMenuItemTag:(NSInteger)tag forItem:(NSMenuItem *)item
{
	IRCClient *u = [self.worldController selectedClient];
	IRCChannel *c = [self.worldController selectedChannel];

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
		case 51066: // "Toggle Visbility of Member List"
		{
			return _disableInSheet(self.worldController.selectedItem.isChannel);

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
			BOOL condition = (_connected || u.isConnecting);
			
			[item setHidden:condition];
			
			return _disableInSheet((condition == NO && u.isQuitting == NO));
			
			break;
		}
		case 502: // "Disconnect"
		{
			BOOL condition = (_connected || u.isConnecting);
			
			[item setHidden:BOOLReverseValue(condition)];
			
			return _disableInSheet(condition);
			
			break;
		}
		case 503: // "Cancel Reconnect"
		{
			BOOL condition = u.isReconnecting;
			
			[item setHidden:BOOLReverseValue(condition)];
			
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
			return _disableInSheet(BOOLValueFromObject(u));
			
			break;
		}
		case 592: // "Textual Logs"
		{
			return _disableInSheet([TPCPreferences logTranscript]);
			
			break;
		}
		case 601: // "Join Channel"
		{
			[self validateChannelMenuSubmenus:item];
			
			if (_isQuery) {
				[item setHidden:YES];
				
				return _disableInSheet(NO);
			} else {
				BOOL condition = (_connected && _notActive && _isChannel);
				
				if (_connected) {
					[item setHidden:BOOLReverseValue(condition)];
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
				
				return _disableInSheet(NO);
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
				
				return _disableInSheet(NO);
			} else {
				[item setHidden:NO];
				
				return _disableInSheet(BOOLValueFromObject(u));
			}
			
			break;
		}
		case 652: // "Delete Channel"
		{
			if (_isQuery) {
				[item setTitle:TXTLS(@"DeletePrivateMessageMenuItem")];
				
				return _disableInSheet(YES);
			} else {
				[item setTitle:TXTLS(@"DeleteChannelMenuItem")];
				
				return _disableInSheet(_isChannel);
			}
			
			break;
		}
		case 691: // "Add Channel…" — Server Menu
		{
			return _disableInSheet(BOOLValueFromObject(u));
			
			break;
		}
		case 2005: // "Invite To…"
		{
			if (_notConnected || [self checkSelectedMembers:item] == NO) {
				return _disableInSheet(NO);
			}
			
			NSInteger count = 0;
			
			for (IRCChannel *e in u.channels) {
				if (NSDissimilarObjects(c, e) && e.isChannel) {
					++count;
				}
			}
			
			return _disableInSheet((count > 0));
			
			break;
		}
		case 5421: // "Query Logs"
		{
			NSMenuItem *separator1 = [item.menu itemWithTag:935];
			
			if (_isQuery) {
				[item setHidden:NO];
				
				[separator1 setHidden:YES]; 
				
				return _disableInSheet([TPCPreferences logTranscript]);
			} else {
				[item setHidden:YES];
				
				[separator1 setHidden:NO];
				
				return _disableInSheet(NO);
			}
			
			break;
		}
		case 9631: // "Close Window"
		{
			TVCMainWindow *mainWindow = self.masterController.mainWindow;
			
			if ([mainWindow isKeyWindow]) {
				TXCommandWKeyAction keyAction = [TPCPreferences commandWKeyAction];
				
				if (_noClientOrChannel && NSDissimilarObjects(keyAction, TXCommandWKeyCloseWindowAction)) {
					return NO;
				}

				switch (keyAction) {
					case TXCommandWKeyCloseWindowAction:
					{
						[item setTitle:TXTLS(@"CmdWShortcutCloseWindowType")];

						break;
					}
					case TXCommandWKeyPartChannelAction:
					{
						if (_isClient) {
							[item setTitle:TXTLS(@"CmdWShortcutCloseWindowType")];

							return NO;
						} else {
							if (_isChannel) {
								[item setTitle:TXTLS(@"CmdWShortcutLeaveChannelType")];
								
								if (_notActive) {
									return NO;
								}
							} else {
								[item setTitle:TXTLS(@"CmdWShortcutClosePrivateMessageType")];
							}
						}
						
						break;
					}
					case TXCommandWKeyDisconnectAction:
					{
						[item setTitle:TXTFLS(@"CmdWShortcutDisconnectServerType", [u altNetworkName])];
						
						if (_notConnected) {
							return NO;
						}
						
						break;
					}
					case TXCommandWKeyTerminateAction:
					{
						[item setTitle:TXTLS(@"CmdWShortcutQuitApplicationType")];
						
						break;
					}
				}
			} else {
				[item setTitle:TXTLS(@"CmdWShortcutCloseWindowType")];
			}
			
			return YES;
			
			break;
		}
		case 593: // "Highlight List"
		{
			return _disableInSheet(([TPCPreferences logHighlights] && _connected));
			
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
			NSMenuItem *allModesTaken = [item.menu itemWithTag:504813];
			NSMenuItem *allModesGiven = [item.menu itemWithTag:504913];
			
			NSArray *nicknames = [self selectedMembers:nil];
			
			if (NSObjectIsEmpty(nicknames) || nicknames.count > 1) {
				[item setHidden:NO];
				
				[allModesGiven setHidden:YES];
				[allModesTaken setHidden:YES];
				
				return _disableInSheet(YES);
			} else {
				IRCUser *m = [nicknames safeObjectAtIndex:0];
				
				switch (tag) {
					case 504910: { [item setHidden:m.o]; break; }				// +o
					case 504911: { [item setHidden:m.h]; break; }				// +h
					case 504912: { [item setHidden:m.v]; break; }				// +v
					case 504810: { [item setHidden:(m.o == NO)]; break; }		// -o
					case 504811: { [item setHidden:(m.h == NO)]; break;	}		// -h
					case 504812: { [item setHidden:(m.v == NO)]; break;	}		// -v
						
					default: { break; }
				}

				BOOL halfOpModeSupported = [u.isupport modeIsSupportedUserPrefix:@"h"];

				if (tag == 504811 || tag == 504911) {
					/* Do not provide halfop as option on servers that do not use it. */

					if (halfOpModeSupported == NO) {
						[item setHidden:YES];
					}
				}
				
				BOOL hideTakeSepItem = (m.o == NO || m.h == NO || m.v == NO);
				BOOL hideGiveSepItem = (m.o || m.h || m.v);
				
				[allModesGiven setHidden:hideTakeSepItem];
				[allModesTaken setHidden:hideGiveSepItem];

				if (tag == 504813 || tag == 504913) {
					return _disableInSheet(NO);
				}
				
				return _disableInSheet(YES);
			}
			
			break;
		}
		case 990002: // "Next Highlight"
		{
			return _disableInSheet([self.worldController.selectedViewController highlightAvailable:NO]);
			
			break;
		}
		case 990003: // "Previous Highlight"
		{
			return _disableInSheet([self.worldController.selectedViewController highlightAvailable:YES]);
			
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
	return self.worldController.selectedViewController.view;
}

#pragma mark -
#pragma mark Navigation Channel List

- (void)populateNavgiationChannelList
{
	/* Remove all previous entries. */
	[self.navigationChannelList removeAllItems];

	/* Begin populating… */
	NSInteger channelCount = 0;

	for (IRCClient *u in self.worldController.clients) {
		/* Create a menu item for the client title. */
		TXSpecialNSMenuItemHelper *newItem = [TXSpecialNSMenuItemHelper menuItemWithTitle:TXTFLS(@"NavigationChannelListClientEntryTitle", u.name) target:nil action:nil];

		[self.navigationChannelList addItem:newItem];

		/* Begin populating channels. */
		for (IRCChannel *c in u.channels) {
			/* Create the menu item. Only first ten items get a key combo. */
			if (channelCount >= 10) {
				newItem = [TXSpecialNSMenuItemHelper menuItemWithTitle:TXTFLS(@"NavigationChannelListChannelEntryTitle", c.name)
																target:self
																action:@selector(navigateToSpecificChannelInNavigationList:)];
			} else {
				NSInteger keyboardIndex = (channelCount + 1);

				if (keyboardIndex == 10) {
					keyboardIndex = 0; // Have 0 as the last item.
				}
				
				newItem = [TXSpecialNSMenuItemHelper menuItemWithTitle:TXTFLS(@"NavigationChannelListChannelEntryTitle", c.name)
																target:self
																action:@selector(navigateToSpecificChannelInNavigationList:)
														 keyEquivalent:[NSString stringWithUniChar:('0' + keyboardIndex)]
													 keyEquivalentMask:NSCommandKeyMask];
			}

			/* The tag identifies each item. */
			[newItem setUserInfo:[NSString stringWithFormat:@"%@ %@", u.config.itemUUID, c.config.itemUUID]];
			[newItem setTag:64611]; // Use same tag for each to disable during sheets.

			/* Add to the actaul navigation list. */
			[self.navigationChannelList addItem:newItem];

			/* Bump the count… */
			channelCount += 1;
		}
	}
}

- (void)navigateToSpecificChannelInNavigationList:(TXSpecialNSMenuItemHelper *)sender
{
	[self.worldController select:[self.worldController findItemFromInfo:sender.userInfo]];
}

#pragma mark -
#pragma mark Selected User(s)

- (BOOL)checkSelectedMembers:(NSMenuItem *)item
{
	return ([self.masterController.memberList countSelectedRows] > 0);
}

- (NSArray *)selectedMembers:(NSMenuItem *)sender
{
	IRCClient *u = [self.worldController selectedClient];
	IRCChannel *c = [self.worldController selectedChannel];
	
	NSMutableArray *ary = [NSMutableArray array];
	
	if (_noClientOrChannel || _notActive || _notConnected || _isClient) {
		return ary;
	} else {
		NSIndexSet *indexes = [self.masterController.memberList selectedRowIndexes];

		BOOL indexEmpty = NSObjectIsEmpty(indexes);
		BOOL pontrEmpty = NSObjectIsEmpty(self.pointedNickname);

		if (indexEmpty == NO && pontrEmpty) {
			for (NSNumber *index in [indexes arrayFromIndexSet]) {
				NSUInteger nindex = [index unsignedIntegerValue];
				
				IRCUser *m = [c memberAtIndex:nindex];
				
				if (m) {
					[ary safeAddObject:m];
				}
			}
		} else {
			if (pontrEmpty == NO) {
				IRCUser *m = [c findMember:self.pointedNickname];
				
				if (m) {
					[ary safeAddObject:m];
				}
			}
		}
	}
	
	return ary;
}

- (void)deselectMembers:(NSMenuItem *)sender
{
	self.pointedNickname = nil;
	
	[self.masterController.memberList deselectAll:nil];
}

#pragma mark -
#pragma mark Window List

/* The concept of our window list is pretty simple: Maintain a list
 of every open window or window sheet instead of maintaining a property
 in our header file for each individual one. When a window or sheet is
 added to the list, the a reference to the window is stored in the list
 with the class name of the window being the key. 
 
 When asking for a window, provide the class name. A general rule of
 Textual is that at any time only a single window of a specific class 
 can be open at any given time, and considering Textual primarly uses
 sheets; that is not an issue. */

- (void)addWindowToWindowList:(id)window
{
	[self addWindowToWindowList:window withKeyValue:NSStringFromClass([window class])];
}

- (void)addWindowToWindowList:(id)window withKeyValue:(NSString *)key
{
	PointerIsEmptyAssert(window);

	NSMutableDictionary *newList = [self.openWindowList mutableCopy];

	[newList safeSetObjectWithoutOverride:window forKey:key];

	self.openWindowList = newList;
}

- (id)windowFromWindowList:(NSString *)windowClass
{
	NSObjectIsEmptyAssertReturn(windowClass, nil);

	return [self.openWindowList objectForKey:windowClass];
}

- (void)removeWindowFromWindowList:(NSString *)windowClass
{
	NSObjectIsEmptyAssert(windowClass);

	NSMutableDictionary *newList = [self.openWindowList mutableCopy];

	[newList removeObjectForKey:windowClass];

	self.openWindowList = newList;
}

- (BOOL)popWindowViewIfExists:(NSString *)windowClass
{
	id windowObject = [self windowFromWindowList:windowClass];

	if (windowObject) {
		NSWindow *window = [windowObject window];

		PointerIsEmptyAssertReturn(window, NO);
		
		[window makeKeyAndOrderFront:nil];

		return YES;
	}

	return NO;
}

- (void)popWindowSheetIfExists
{
	/* Close any existing sheet by canceling the previous instance of it. */
	for (NSString *windowKey in self.openWindowList) {
		id windowObject = [self.openWindowList objectForKey:windowKey];

		if ([[windowObject class] isSubclassOfClass:[TDCSheetBase class]]) {
			if ([windowObject respondsToSelector:@selector(cancel:)]) {
				[windowObject performSelector:@selector(cancel:) withObject:nil];

                return;
			}
		}
	}

    /* If our sheet was not one we delegate, then force close it using "close" */
    /* We only handle sheets on the main window. */
    NSWindow *attachedSheet = [self.masterController.mainWindow attachedSheet];

    PointerIsEmptyAssert(attachedSheet);

    [attachedSheet close];
}

#pragma mark -
#pragma mark Find Panel

- (void)internalOpenFindPanel:(id)sender
{
    NSAssertReturn([self popWindowViewIfExists:@"TXMenuControllerFindPanel"] == NO);

	TVCInputPromptDialog *dialog = [TVCInputPromptDialog new];

	[dialog alertWithMessageTitle:TXTLS(@"FindSearchPanelPromptTitle")
					defaultButton:TXTLS(@"FindSearchPanelPromptButton")
				  alternateButton:TXTLS(@"CancelButton")
				  informativeText:TXTLS(@"FindSearchPanelPromptMessage")
				 defaultUserInput:self.currentSearchPhrase
				  completionBlock:^(BOOL defaultButtonClicked, NSString *resultString) {
					  if (defaultButtonClicked) {
						  if (NSObjectIsEmpty(resultString)) {
							  self.currentSearchPhrase = NSStringEmptyPlaceholder;
						  } else {
							  if ([resultString isNotEqualTo:self.currentSearchPhrase]) {
								  self.currentSearchPhrase = resultString;
							  }

							  dispatch_async(dispatch_get_main_queue(), ^{
								  [[self currentWebView] searchFor:resultString direction:YES caseSensitive:NO wrap:YES];
							  });
						  }
					  }

					  [self removeWindowFromWindowList:@"TXMenuControllerFindPanel"];
				  }];

	[self addWindowToWindowList:dialog withKeyValue:@"TXMenuControllerFindPanel"];
}

- (void)showFindPanel:(id)sender
{
	if ([sender tag] == 4564 || NSObjectIsEmpty(self.currentSearchPhrase)) {
		[self internalOpenFindPanel:sender];
	} else {
		if ([sender tag] == 4565) {
			[[self currentWebView] searchFor:self.currentSearchPhrase direction:YES caseSensitive:NO wrap:YES];
		} else {
			[[self currentWebView] searchFor:self.currentSearchPhrase direction:NO caseSensitive:NO wrap:YES];
		}
	}
}

#pragma mark -
#pragma mark Command + W Keyboard Shortcut

- (void)commandWShortcutUsed:(id)sender
{
	NSWindow *currentWindow = [NSApp keyWindow];
	
	IRCClient *u = [self.worldController selectedClient];
	IRCChannel *c = [self.worldController selectedChannel];

	TVCMainWindow *mainWindow = self.masterController.mainWindow;
	
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
						[self.worldController destroyChannel:c];
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
#pragma mark Preferences Dialog

- (void)showPreferencesDialog:(id)sender
{
	/* Another part of the new window list concept. We call popWindowViewIfExists:
	 to check whether the window with this class name already exists. If it does,
	 then we bring the window forward and return YES for doing so. NSAssertReturn
	 is checking whether its input is equal to NO. So we are pretty much reversing
	 our value from the window list by checking it against NO itself. It is confusing
	 I know. We are basically popping the window or creating one if it does not exist. */
	
	NSAssertReturn([self popWindowViewIfExists:@"TDCPreferencesController"] == NO);
	
	TDCPreferencesController *pc = [TDCPreferencesController new];
	
	pc.delegate = self;
	
	[pc show];

	[self addWindowToWindowList:pc];
}

- (void)preferencesDialogWillClose:(TDCPreferencesController *)sender
{
	[self.worldController preferencesChanged];

	/* The window closed. Now remove it from our window list. */
	[self removeWindowFromWindowList:@"TDCPreferencesController"];
}

#pragma mark -
#pragma mark Menu Item Actions

- (void)paste:(id)sender
{
    NSWindow *keyWindow = [NSApp keyWindow];

    if ([keyWindow isEqual:self.masterController.mainWindow]) {
        [self.masterController.inputTextField focus];
        [self.masterController.inputTextField paste:sender];
    } else {
        if ([keyWindow.firstResponder respondsToSelector:@selector(paste:)]) {
            [keyWindow.firstResponder performSelector:@selector(paste:) withObject:nil];
        }
    }
}

- (void)closeWindow:(id)sender
{
	[[NSApp keyWindow] performClose:nil];
}

- (void)centerMainWindow:(id)sender
{
	[[NSApp mainWindow] exactlyCenterWindow];
}

- (void)onCloseCurrentPanel:(id)sender
{
	IRCChannel *c = [self.worldController selectedChannel];
	
	if (c) {
		[self.worldController destroyChannel:c];
		[self.worldController save];
	}
}

- (void)showAcknowledgments:(id)sender
{
	NSString *acknowledgmentsPath = [RZMainBundle() pathForResource:@"Acknowledgments" ofType:@"rtfd" inDirectory:@"Documentation"];
	
	[RZWorkspace() openFile:acknowledgmentsPath];
}

- (void)showContributors:(id)sender
{
	NSString *contributorsPath = [RZMainBundle() pathForResource:@"Contributors" ofType:@"rtfd" inDirectory:@"Documentation"];
	
	[RZWorkspace() openFile:contributorsPath]];
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
	IRCTreeItem *sel = self.worldController.selectedItem;

	PointerIsEmptyAssert(sel);
	
	[sel.viewController mark];
}

- (void)gotoScrollbackMarker:(id)sender
{
	IRCTreeItem *sel = self.worldController.selectedItem;

	PointerIsEmptyAssert(sel);
	
	[sel.viewController goToMark];
}

- (void)clearScrollback:(id)sender
{
	IRCClient *u = [self.worldController selectedClient];
	IRCChannel *c = [self.worldController selectedChannel];
	
    if (u) {
        if (c) {
            [self.worldController clearContentsOfChannel:c inClient:u];
        } else {
            [self.worldController clearContentsOfClient:u];
        }
    }
}

- (void)increaseLogFontSize:(id)sender
{
	[self.worldController changeTextSize:YES];
}

- (void)decreaseLogFontSize:(id)sender
{
	[self.worldController changeTextSize:NO];
}

- (void)markAllAsRead:(id)sender
{
	[self.worldController markAllAsRead];
}

- (void)connect:(id)sender
{
	IRCClient *u = [self.worldController selectedClient];
	
	if (_noClient || _connected) {
		return;
	}
	
	[u connect];

	[self.worldController expandClient:u]; // Expand client on user opreated connect.
}

- (void)disconnect:(id)sender
{
	IRCClient *u = [self.worldController selectedClient];

	if (_noClient || _notConnected) {
		return;
	}
	
	[u quit];
	[u cancelReconnect];
}

- (void)cancelReconnection:(id)sender
{
	IRCClient *u = [self.worldController selectedClient];

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
	
	IRCClient *u = [self.worldController selectedClient];
	
	if (_noClient || _notConnected) {
		return;
	}

	TDCNickSheet *nickSheet = [TDCNickSheet new];

	nickSheet.delegate = self;
	nickSheet.clientID = u.treeUUID;
	nickSheet.window = self.masterController.mainWindow;
	
	[nickSheet start:u.localNickname];

	[self addWindowToWindowList:nickSheet];
}

- (void)nickSheet:(TDCNickSheet *)sender didInputNickname:(NSString *)nickname
{
	IRCClient *u = [self.worldController findClientById:sender.clientID];
	
	if (_noClient || _notConnected) {
		return;
	}
	
	[u changeNick:nickname];
}

- (void)nickSheetWillClose:(TDCNickSheet *)sender
{
	[self removeWindowFromWindowList:@"TDCNickSheet"];
}

#pragma mark -
#pragma mark Menu Item Actions

- (void)showServerChannelList:(id)sender
{
	IRCClient *u = [self.worldController selectedClient];
	
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

	d.clientID = nil;
	d.delegate = self;
	d.config = [IRCClientConfig new];
	d.window = self.masterController.mainWindow;

    [d start:nil withContext:nil];

	[self addWindowToWindowList:d];
}

- (void)copyServer:(id)sender
{
	IRCClient *u = [self.worldController selectedClient];
	
	if (_noClient) {
		return;
	}
	
	IRCClientConfig *config = u.storedConfig.mutableCopy;

	config.itemUUID = [NSString stringWithUUID];
	config.clientName = [config.clientName stringByAppendingString:@"_"];
	
	IRCClient *n = [self.worldController createClient:config reload:YES];
	
	[self.worldController save];
	
	if (u.config.sidebarItemExpanded) { // Only expand new client if old was expanded already.
		[self.worldController expandClient:n];
	}
}

- (void)deleteServer:(id)sender
{
	IRCClient *u = [self.worldController selectedClient];
	
	if (_noClient || _connected) {
		return;
	}
	
	NSString *warningToken = @"ServerDeletePromptNormalMessage";
	
#ifdef TEXTUAL_BUILT_WITH_ICLOUD_SUPPORT
	if ([TPCPreferences syncPreferencesToTheCloud]) {
		if (u.config.excludedFromCloudSyncing == NO) {
			warningToken = @"ServerDeletePromptCloudMessage";
		}
	}
#endif
	
	BOOL result = [TLOPopupPrompts dialogWindowWithQuestion:TXTLS(warningToken)
													  title:TXTLS(@"ServerDeletePromptTitle")
											  defaultButton:TXTLS(@"OkButton") 
											alternateButton:TXTLS(@"CancelButton")
											 suppressionKey:nil
											suppressionText:nil];
	
	if (result == NO) {
		return;
	}
	
	[u.config destroyKeychains];
	
	[self.worldController destroyClient:u];
	[self.worldController save];
}

#pragma mark -
#pragma mark Server Properties

- (void)showServerPropertyDialog:(IRCClient *)u withDefaultView:(NSString *)viewType andContext:(NSString *)context
{
	if (_noClient) {
		return;
	}

	[self popWindowSheetIfExists];
	
	TDCServerSheet *d = [TDCServerSheet new];

	d.delegate = self;
	d.clientID = u.treeUUID;
	d.config = u.storedConfig.mutableCopy;
	d.window = self.masterController.mainWindow;
	
	[d start:viewType withContext:context];

	[self addWindowToWindowList:d];
}

- (void)showServerPropertiesDialog:(id)sender
{
	[self showServerPropertyDialog:self.worldController.selectedClient withDefaultView:nil andContext:nil];
}

- (void)serverSheetOnOK:(TDCServerSheet *)sender
{
	if (NSObjectIsEmpty(sender.clientID)) {
		[self.worldController createClient:sender.config reload:YES];
	} else {
		IRCClient *u = [self.worldController findClientById:sender.clientID];
		
		if (_noClient) {
			return;
		}

		BOOL samencoding = (sender.config.primaryEncoding == u.config.primaryEncoding);

		[u updateConfig:sender.config];

		if (samencoding == NO) {
			[self.worldController reloadTheme];
		}
	}
	
	[self.worldController save];
}

#ifdef TEXTUAL_BUILT_WITH_ICLOUD_SUPPORT
- (void)serverSheetRequestedCloudExclusionByDeletion:(TDCServerSheet *)sender
{
	[self.worldController addClientToListOfDeletedClients:sender.config.itemUUID];
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
	IRCClient *u = [self.worldController selectedClient];
	IRCChannel *c = [self.worldController selectedChannel];
	
	if (_noClientOrChannel || _isClient || _isQuery || _activate || _notConnected) {
		return;
	}

	u.inUserInvokedJoinRequest = YES;
	
	[u joinChannel:c];
}

- (void)leaveChannel:(id)sender
{
	IRCClient *u = [self.worldController selectedClient];
	IRCChannel *c = [self.worldController selectedChannel];
	
	if (_noClientOrChannel || _notActive || _notConnected) {
		return;
	}
	
	if (_isChannel) {
		[u partChannel:c];
	} else {
		[self.worldController destroyChannel:c];
	}
}

#pragma mark -
#pragma mark Highlight Sheet

- (void)showHighlightSheet:(id)sender
{
	[self popWindowSheetIfExists];
	
	IRCClient *u = [self.worldController selectedClient];
	
	if (_noClient) {
		return;
	}
	
	TDCHighlightListSheet *d = [TDCHighlightListSheet new];
	
	d.delegate = self;
	d.window = self.masterController.mainWindow;
	
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

	IRCClient *u = [self.worldController selectedClient];
	IRCChannel *c = [self.worldController selectedChannel];

	if (_noClientOrChannel || _isClient || _isQuery) {
		return;
	}

	TDCTopicSheet *t = [TDCTopicSheet new];

	t.delegate = self;
	t.clientID = u.treeUUID;
	t.channelID = c.treeUUID;
	t.window = self.masterController.mainWindow;

	[t start:c.topic];

	[self addWindowToWindowList:t];
}

- (void)topicSheet:(TDCTopicSheet *)sender onOK:(NSString *)topic
{
	IRCChannel *c = [self.worldController findChannelByClientId:sender.clientID channelId:sender.channelID];
	IRCClient *u = c.client;
	
	if (_noClientOrChannel || _isClient || _isQuery) {
		return;
	}
	
	if ([u encryptOutgoingMessage:&topic channel:c] == YES) {
		[u send:IRCPrivateCommandIndex("topic"), c.name, topic, nil];
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

	IRCClient *u = [self.worldController selectedClient];
	IRCChannel *c = [self.worldController selectedChannel];
	
	if (_noClientOrChannel || _isClient || _isQuery) {
		return;
	}
	
	TDCModeSheet *m = [TDCModeSheet new];
	
	m.delegate = self;
	m.clientID = u.treeUUID;
	m.channelID = c.treeUUID;
	m.mode = c.modeInfo.mutableCopy;
	m.window = self.masterController.mainWindow;

	[m start];

	[self addWindowToWindowList:m];
}

- (void)modeSheetOnOK:(TDCModeSheet *)sender
{
	IRCChannel *c = [self.worldController findChannelByClientId:sender.clientID channelId:sender.channelID];
	IRCClient *u = c.client;
	
	if (_noClientOrChannel || _isClient || _isQuery) {
		return;
	}
	
	NSString *changeStr = [c.modeInfo getChangeCommand:sender.mode];

	NSObjectIsEmptyAssert(changeStr);

	[u sendLine:[NSString stringWithFormat:@"%@ %@ %@", IRCPrivateCommandIndex("mode"), c.name, changeStr]];
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
	
	IRCClient *u = [self.worldController selectedClient];
	
	if (_noClient) {
		return;
	}
	
	TDChannelSheet *d = [TDChannelSheet new];

	d.newItem = YES;
	d.delegate = self;
	d.clientID = u.treeUUID;
	d.channelID = nil;
	d.config = [IRCChannelConfig new];
	d.window = self.masterController.mainWindow;

	[d start];

	[self addWindowToWindowList:d];
}

- (void)deleteChannel:(id)sender
{
	IRCChannel *c = [self.worldController selectedChannel];
	
	if (_noChannel || _isClient) {
		return;
	}
	
	if (_isChannel) {
		BOOL result = [TLOPopupPrompts dialogWindowWithQuestion:TXTLS(@"ChannelDeletePromptMessage") 
														  title:TXTLS(@"ChannelDeletePromptTitle") 
												  defaultButton:TXTLS(@"OkButton") 
												alternateButton:TXTLS(@"CancelButton")
												 suppressionKey:@"delete_channel"
												suppressionText:nil];
		
		if (result == NO) {
			return;
		}
	}
	
	[self.worldController destroyChannel:c];
	[self.worldController save];
}

#pragma mark -
#pragma mark Channel Properties

- (void)showChannelPropertiesDialog:(id)sender
{
	[self popWindowSheetIfExists];

	IRCClient *u = [self.worldController selectedClient];
	IRCChannel *c = [self.worldController selectedChannel];
	
	if (_noClientOrChannel || _isClient || _isQuery) {
		return;
	}
	
	TDChannelSheet *d = [TDChannelSheet new];

	d.newItem = NO;
	d.delegate = self;
	d.clientID = u.treeUUID;
	d.channelID = c.treeUUID;
	d.config = c.config.mutableCopy;
	d.window = self.masterController.mainWindow;

	[d start];

	[self addWindowToWindowList:d];
}

- (void)channelSheetOnOK:(TDChannelSheet *)sender
{
	if (sender.newItem) {
		IRCClient *u = [self.worldController findClientById:sender.clientID];
		
		if (_noClient) {
			return;
		}
		
		[self.worldController createChannel:sender.config client:u reload:YES adjust:YES];
		[self.worldController expandClient:u];
	} else {
		IRCChannel *c = [self.worldController findChannelByClientId:sender.clientID channelId:sender.channelID];
		
		if (_noChannel) {
			return;
		}
		
		[c updateConfig:sender.config];
	}
	
	[self.worldController save];
}

- (void)channelSheetWillClose:(TDChannelSheet *)sender
{
	[self removeWindowFromWindowList:@"TDChannelSheet"];
}

#pragma mark -
#pragma mark Menu Item Actions

- (void)whoisSelectedMembers:(id)sender deselect:(BOOL)deselect
{
	IRCClient *u = [self.worldController selectedClient];
	IRCChannel *c = [self.worldController selectedChannel];
	
	if (_noClient || _isClient) {
		return;
	}
	
	for (IRCUser *m in [self selectedMembers:sender]) {
		[u sendWhois:m.nickname];
	}
	
	if (deselect) {
		[self deselectMembers:sender];
	}
}

- (void)memberListDoubleClicked:(id)sender
{
    TVCMemberList *view = sender;
    
	NSPoint ml = [self.masterController.mainWindow mouseLocationOutsideOfEventStream];
    NSPoint pt = [view convertPoint:ml fromView:nil];
	
    NSInteger n = [view rowAtPoint:pt];
    
    if (n >= 0) {
        
		TXUserDoubleClickAction action = [TPCPreferences userDoubleClickOption];
        
		if (action == TXUserDoubleClickWhoisAction) {
			[self whoisSelectedMembers:nil deselect:NO];
		} else if (action == TXUserDoubleClickPrivateMessageAction) {
			[self memberStartPrivateMessage:nil];
		} else if (action == TXUserDoubleClickInsertTextFieldAction) {
			[self memberInsertNameIntoTextField:nil];
		}
    }
}

- (void)memberInsertNameIntoTextField:(id)sender
{
	IRCClient *u = [self.worldController selectedClient];
	IRCChannel *c = [self.worldController selectedChannel];
    
	if (_noClient || _isClient) {
		return;
	}
    
	/* Get list of users. */
	NSMutableArray *users = [NSMutableArray array];
    
	for (IRCUser *m in [self selectedMembers:sender]) {
		[users safeAddObject:m.nickname];
	}
    
	/* The text field. */
	TVCInputTextField *textField = self.masterController.inputTextField;
    
	NSRange selectedRange = textField.selectedRange;
    
	NSInteger insertLocation = selectedRange.location;
    
	/* Build insert string. */
	NSString *insertString;
    
	if (insertLocation > 0) {
		UniChar prev = [textField.stringValue characterAtIndex:(insertLocation - 1)];
        
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
	[self deselectMembers:sender];
	
	/* Set focus to the input textfield. */
	[textField focus];
}

- (void)memberSendWhois:(id)sender
{
	[self whoisSelectedMembers:sender deselect:YES];
}

- (void)memberStartPrivateMessage:(id)sender
{
	IRCClient *u = [self.worldController selectedClient];
	IRCChannel *c = [self.worldController selectedChannel];
	
	if (_noClient || _isClient) {
		return;
	}
	
	for (IRCUser *m in [self selectedMembers:sender]) {
		IRCChannel *c = [u findChannel:m.nickname];
		
		if (_noChannel) {
			c = [self.worldController createPrivateMessage:m.nickname client:u];
		}
		
		[self.worldController select:c];
	}
	
	[self deselectMembers:sender];
}

#pragma mark -
#pragma mark Channel Invite Sheet

- (void)memberSendInvite:(id)sender
{
	[self popWindowSheetIfExists];

	IRCClient *u = [self.worldController selectedClient];
	IRCChannel *c = [self.worldController selectedChannel];
	
	if (_noClientOrChannel || _notConnected) {
		return;
	}

	NSMutableArray *channels = [NSMutableArray array];
	NSMutableArray *nicknames = [NSMutableArray array];

	for (IRCUser *m in [self selectedMembers:sender]) {
		[nicknames safeAddObject:m.nickname];
	}
	
	for (IRCChannel *e in u.channels) {
		if (NSDissimilarObjects(c, e) && e.isChannel) {
			[channels safeAddObject:e.name];
		}
	}

	NSObjectIsEmptyAssert(channels);
	NSObjectIsEmptyAssert(nicknames);

	TDCInviteSheet *inviteSheet = [TDCInviteSheet new];
	
	inviteSheet.delegate = self;
	inviteSheet.clientID = u.treeUUID;
	inviteSheet.nicknames = nicknames;
	inviteSheet.window = self.masterController.mainWindow;

	[inviteSheet startWithChannels:channels];

	[self addWindowToWindowList:inviteSheet];
}

- (void)inviteSheet:(TDCInviteSheet *)sender onSelectChannel:(NSString *)channelName
{
	IRCClient *u = [self.worldController findClientById:sender.clientID];
	
	if (u && [channelName isChannelName]) {
		for (NSString *nick in sender.nicknames) {
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
	IRCClient *u = [self.worldController selectedClient];
	IRCChannel *c = [self.worldController selectedChannel];
	
	if (_noClient || _isClient) {
		return;
	}
	
	for (IRCUser *m in [self selectedMembers:sender]) {
		[u sendCTCPPing:m.nickname];
	}
	
	[self deselectMembers:sender];
}

- (void)memberSendCTCPFinger:(id)sender
{
	IRCClient *u = [self.worldController selectedClient];
	IRCChannel *c = [self.worldController selectedChannel];

	if (_noClient || _isClient) {
		return;
	}

	for (IRCUser *m in [self selectedMembers:sender]) {
		[u sendCTCPQuery:m.nickname command:IRCPrivateCommandIndex("ctcp_finger") text:nil];
	}

	[self deselectMembers:sender];
}

- (void)memberSendCTCPTime:(id)sender
{
	IRCClient *u = [self.worldController selectedClient];
	IRCChannel *c = [self.worldController selectedChannel];

	if (_noClient || _isClient) {
		return;
	}

	for (IRCUser *m in [self selectedMembers:sender]) {
		[u sendCTCPQuery:m.nickname command:IRCPrivateCommandIndex("ctcp_time") text:nil];
	}
	
	[self deselectMembers:sender];
}

- (void)memberSendCTCPVersion:(id)sender
{
	IRCClient *u = [self.worldController selectedClient];
	IRCChannel *c = [self.worldController selectedChannel];

	if (_noClient || _isClient) {
		return;
	}

	for (IRCUser *m in [self selectedMembers:sender]) {
		[u sendCTCPQuery:m.nickname command:IRCPrivateCommandIndex("ctcp_version") text:nil];
	}
	
	[self deselectMembers:sender];
}

- (void)memberSendCTCPUserinfo:(id)sender
{
	IRCClient *u = [self.worldController selectedClient];
	IRCChannel *c = [self.worldController selectedChannel];

	if (_noClient || _isClient) {
		return;
	}

	for (IRCUser *m in [self selectedMembers:sender]) {
		[u sendCTCPQuery:m.nickname command:IRCPrivateCommandIndex("ctcp_userinfo") text:nil];
	}
	
	[self deselectMembers:sender];
}

- (void)memberSendCTCPClientInfo:(id)sender
{
	IRCClient *u = [self.worldController selectedClient];
	IRCChannel *c = [self.worldController selectedChannel];

	if (_noClient || _isClient) {
		return;
	}

	for (IRCUser *m in [self selectedMembers:sender]) {
		[u sendCTCPQuery:m.nickname command:IRCPrivateCommandIndex("ctcp_clientinfo") text:nil];
	}
	
	[self deselectMembers:sender];
}

- (void)copyUrl:(id)sender
{
	NSObjectIsEmptyAssert(self.pointedUrl);

	[RZPasteboard() setStringContent:self.pointedUrl];
		
	self.pointedUrl = nil;
}

- (void)joinClickedChannel:(id)sender
{
	IRCClient *u = [self.worldController selectedClient];
	
	if (_noClient || _notConnected) {
		return;
	}

	NSObjectIsEmptyAssert(self.pointedChannelName);

	u.inUserInvokedJoinRequest = YES;
	
	[u joinUnlistedChannel:self.pointedChannelName];
		
	self.pointedChannelName = nil;
}

- (void)showChannelIgnoreList:(id)sender
{
	[self showServerPropertyDialog:self.worldController.selectedClient withDefaultView:@"addressBook" andContext:@"-"];
}

#pragma mark -
#pragma mark About Window

- (void)showAboutWindow:(id)sender
{
	NSAssertReturn([self popWindowViewIfExists:@"TDCAboutPanel"] == NO);

	TDCAboutPanel *aboutPanel = [TDCAboutPanel new];

	aboutPanel.delegate = self;

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
	IRCClient *u = [self.worldController selectedClient];
	IRCChannel *c = [self.worldController selectedChannel];
	
	if (_noClientOrChannel || _isClient || _isQuery) {
		return;
	}
	
	NSString *opString = NSStringEmptyPlaceholder;
	
	NSInteger currentIndex = 0;
	
	for (IRCUser *m in [self selectedMembers:sender]) {
		opString = [opString stringByAppendingFormat:@"%@ ", m.nickname];
		
		currentIndex += 1;
		
		if (currentIndex == TXMaximumNodesPerModeCommand) {
			[u sendCommand:[NSString stringWithFormat:@"%@ %@", tmode, opString] completeTarget:YES target:c.name];
			
			opString = NSStringEmptyPlaceholder;
			
			currentIndex = 0;
		}
	}
	
	if (opString) {	
		[u sendCommand:[NSString stringWithFormat:@"%@ %@", tmode, opString] completeTarget:YES target:c.name];
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
	IRCClient *u = [self.worldController selectedClient];
	IRCChannel *c = [self.worldController selectedChannel];
	
	if (_noClientOrChannel || _isClient || _isQuery) {
		return;
	}
	
	for (IRCUser *m in [self selectedMembers:sender]) {
		[u kick:c target:m.nickname];
	}
	
	[self deselectMembers:sender];
}

- (void)memberBanFromServer:(id)sender
{
	IRCClient *u = [self.worldController selectedClient];
	IRCChannel *c = [self.worldController selectedChannel];

	if (_noClientOrChannel || _isClient || _isQuery) {
		return;
	}
	
	for (IRCUser *m in [self selectedMembers:sender]) {
		[u sendCommand:[NSString stringWithFormat:@"%@ %@", IRCPublicCommandIndex("ban"), m.nickname] completeTarget:YES target:c.name];
	}
	
	[self deselectMembers:sender];
}

- (void)memberKickbanFromChannel:(id)sender
{
	IRCClient *u = [self.worldController selectedClient];
	IRCChannel *c = [self.worldController selectedChannel];

	if (_noClientOrChannel || _isClient || _isQuery) {
		return;
	}
	
	for (IRCUser *m in [self selectedMembers:sender]) {
		[u sendCommand:[NSString stringWithFormat:@"%@ %@ %@", IRCPublicCommandIndex("kickban"), m.nickname, [TPCPreferences defaultKickMessage]] completeTarget:YES target:c.name];
	}
	
	[self deselectMembers:sender];
}

- (void)memberKillFromServer:(id)sender
{
	IRCClient *u = [self.worldController selectedClient];
	IRCChannel *c = [self.worldController selectedChannel];

	if (_noClientOrChannel || _isClient) {
		return;
	}
	
	for (IRCUser *m in [self selectedMembers:sender]) {
		[u sendCommand:[NSString stringWithFormat:@"%@ %@ %@", IRCPublicCommandIndex("kill"), m.nickname, [TPCPreferences IRCopDefaultKillMessage]]];
	}
	
	[self deselectMembers:sender];
}

- (void)memberGlineFromServer:(id)sender
{
	IRCClient *u = [self.worldController selectedClient];
	IRCChannel *c = [self.worldController selectedChannel];

	if (_noClientOrChannel || _isClient) {
		return;
	}
	
	for (IRCUser *m in [self selectedMembers:sender]) {
        if ([m.nickname isEqualIgnoringCase:u.localNickname]) {
            [u printDebugInformation:TXTFLS(@"SelfBanDetectedMessage", [u networkAddress]) channel:c];
        } else {
            [u sendCommand:[NSString stringWithFormat:@"%@ %@ %@", IRCPublicCommandIndex("gline"), m.nickname, [TPCPreferences IRCopDefaultGlineMessage]]];
        }
    }
	
	[self deselectMembers:sender];
}

- (void)memberShunFromServer:(id)sender
{
	IRCClient *u = [self.worldController selectedClient];
	IRCChannel *c = [self.worldController selectedChannel];

	if (_noClientOrChannel || _isClient) {
		return;
	}
	
	for (IRCUser *m in [self selectedMembers:sender]) {
		[u sendCommand:[NSString stringWithFormat:@"%@ %@ %@", IRCPublicCommandIndex("shun"), m.nickname, [TPCPreferences IRCopDefaultShunMessage]]];
	}
	
	[self deselectMembers:sender];
}

- (void)openLogLocation:(id)sender
{	
	NSURL *path = [TPCPreferences transcriptFolder];
	
	if ([RZFileManager() fileExistsAtPath:[path path]]) {
		[RZWorkspace() openURL:path];
	} else {
		[TLOPopupPrompts dialogWindowWithQuestion:TXTLS(@"LogPathDoesNotExistMessage")
											title:TXTLS(@"LogPathDoesNotExistTitle")
									defaultButton:TXTLS(@"OkButton") 
								  alternateButton:nil
								   suppressionKey:nil
								  suppressionText:nil];
	}
}

- (void)openChannelLogs:(id)sender
{
	IRCClient *u = [self.worldController selectedClient];
	IRCChannel *c = [self.worldController selectedChannel];

	if (_noClientOrChannel || _isClient) {
		return;
	}
	
	NSURL *path = [c.logFile buildPath];
	
	if ([RZFileManager() fileExistsAtPath:[path path]]) {
		[RZWorkspace() openURL:path];
	} else {
		[TLOPopupPrompts dialogWindowWithQuestion:TXTLS(@"LogPathDoesNotExistMessage")
											title:TXTLS(@"LogPathDoesNotExistTitle")
									defaultButton:TXTLS(@"OkButton")
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

- (void)onWantHostServVhostSet:(id)sender andVhost:(NSString *)vhost
{
	NSObjectIsEmptyAssert(vhost);

	IRCClient *u = [self.worldController selectedClient];
	IRCChannel *c = [self.worldController selectedChannel];

	if (_noClientOrChannel || _isClient) {
		return;
	}
		
	NSArray *nicknames = [self selectedMembers:sender];
	
	for (IRCUser *m in nicknames) {
		[u sendCommand:[NSString stringWithFormat:@"hs setall %@ %@", m.nickname, vhost] completeTarget:NO target:nil];
	}

	[self deselectMembers:sender];
}

- (void)onWantHostServVhostSet:(id)sender
{
    NSAssertReturn([self popWindowViewIfExists:@"TXMenuControllerSetUserVhostPanel"] == NO);

	TVCInputPromptDialog *dialog = [TVCInputPromptDialog new];

	[dialog alertWithMessageTitle:TXTLS(@"SetUserVhostPromptTitle")
					defaultButton:TXTLS(@"OkButton")
				  alternateButton:TXTLS(@"CancelButton")
				  informativeText:TXTLS(@"SetUserVhostPromptMessage")
				 defaultUserInput:nil
				  completionBlock:^(BOOL defaultButtonClicked, NSString *resultString) {
					  if (defaultButtonClicked) {
						  [self onWantHostServVhostSet:sender andVhost:resultString];
					  }

					  [self removeWindowFromWindowList:@"TXMenuControllerSetUserVhostPanel"];
				  }];

	[self addWindowToWindowList:dialog withKeyValue:@"TXMenuControllerSetUserVhostPanel"];
}

- (void)showSetVhostPrompt:(id)sender
{
	[self onWantHostServVhostSet:sender];
}

- (void)showChannelBanList:(id)sender
{
	IRCChannel *c = [self.worldController selectedChannel];
	
	if (_noChannel || _isClient || _isQuery) {
		return;
	}
	
	[c.client createChanBanListDialog];
	[c.client send:IRCPrivateCommandIndex("mode"), [c name], @"+b", nil];
}

- (void)showChannelBanExceptionList:(id)sender
{
	IRCChannel *c = [self.worldController selectedChannel];

	if (_noChannel || _isClient || _isQuery) {
		return;
	}
	
	[c.client createChanBanExceptionListDialog];
	[c.client send:IRCPrivateCommandIndex("mode"), [c name], @"+e", nil];
}

- (void)showChannelInviteExceptionList:(id)sender
{
	IRCChannel *c = [self.worldController selectedChannel];

	if (_noChannel || _isClient || _isQuery) {
		return;
	}
	
	[c.client createChanInviteExceptionListDialog];
	[c.client send:IRCPrivateCommandIndex("mode"), [c name], @"+I", nil];
}

- (void)openHelpMenuLinkItem:(id)sender
{
	switch ([sender tag]) {
		case 101: { [RZWorkspace() openURL:[NSURL URLWithString:@"http://www.codeux.com/textual/wiki/"]]; break;											}
		case 103: { [RZWorkspace() openURL:[NSURL URLWithString:@"http://www.codeux.com/textual/wiki/Text-Formatting.wiki"]]; break;						}
		case 104: { [RZWorkspace() openURL:[NSURL URLWithString:@"http://www.codeux.com/textual/wiki/Command-Reference.wiki"]]; break;						}
		case 105: { [RZWorkspace() openURL:[NSURL URLWithString:@"http://www.codeux.com/textual/wiki/Memory-Management.wiki"]]; break;						}
		case 106: { [RZWorkspace() openURL:[NSURL URLWithString:@"http://www.codeux.com/textual/wiki/Styles.wiki"]]; break;									}
		case 108: { [RZWorkspace() openURL:[NSURL URLWithString:@"http://www.codeux.com/textual/wiki/Support.wiki"]]; break;								}
		case 208: { [RZWorkspace() openURL:[NSURL URLWithString:@"http://www.codeux.com/textual/wiki/DCC-File-Transfer-Information.wiki"]];	break;			}
		case 209: { [RZWorkspace() openURL:[NSURL URLWithString:@"http://www.codeux.com/textual/wiki/Keyboard-Shortcuts.wiki"]]; break;						}
		case 210: { [RZWorkspace() openURL:[NSURL URLWithString:@"http://www.codeux.com/textual/wiki/IRC-URL-Scheme.wiki"]]; break;							}
	}
}

- (void)openMacAppStoreDownloadPage:(id)sender
{
	[RZWorkspace() openURL:[NSURL URLWithString:@"http://www.textualapp.com/"]];
}

- (void)processNavigationItem:(NSMenuItem *)sender
{
	switch ([sender tag]) {
		case 50001: { [self.masterController selectNextServer:nil]; break;					}
		case 50002: { [self.masterController selectPreviousServer:nil]; break;				}
		case 50003: { [self.masterController selectNextActiveServer:nil]; break;			}
		case 50004: { [self.masterController selectPreviousActiveServer:nil]; break;		}
		case 50005: { [self.masterController selectNextChannel:nil]; break;					}
		case 50006: { [self.masterController selectPreviousChannel:nil]; break;				}
		case 50007: { [self.masterController selectNextActiveChannel:nil]; break;			}
		case 50008: { [self.masterController selectPreviousActiveChannel:nil]; break;		}
		case 50009: { [self.masterController selectNextUnreadChannel:nil]; break;			}
		case 50010: { [self.masterController selectPreviousUnreadChannel:nil]; break;		}
		case 50011: { [self.masterController selectPreviousSelection:nil]; break;			}
		case 50012: { [self.masterController selectNextWindow:nil]; break;				}
		case 50013: { [self.masterController selectPreviousWindow:nil]; break;				}
	}
}

- (void)showMainWindow:(id)sender 
{
	[self.masterController.mainWindow makeKeyAndOrderFront:nil];
}

- (void)toggleFullscreenMode:(id)sender
{
	if (self.masterController.isInFullScreenMode) {
		[self.masterController.mainWindow toggleFullScreen:sender];

		[self.masterController loadWindowState:NO];
	} else {
		[self.masterController saveWindowState];
		
		[self.masterController.mainWindow toggleFullScreen:sender];
	}

	self.masterController.isInFullScreenMode = BOOLReverseValue(self.masterController.isInFullScreenMode);
}

- (void)sortChannelListNames:(id)sender
{
	TVCServerList *serverList = self.masterController.serverList;

	id oldSelection = self.worldController.selectedItem;

	for (IRCClient *u in self.worldController.clients) {
		BOOL isExpanded = u.config.sidebarItemExpanded;
		
		if (isExpanded) {
			[serverList.animator collapseItem:u];
		}

		NSArray *clientChannels = [u.channels sortedArrayUsingFunction:IRCChannelDataSort context:nil];
		
		[u.channels removeAllObjects];
		
		for (IRCChannel *c in clientChannels) {
			[u.channels safeAddObject:c];
		}
		
		[u updateConfig:u.storedConfig];

		if (isExpanded) {
			[serverList.animator expandItem:u];
		}
	}

	[self.worldController select:oldSelection];
	[self.worldController save];
	
	[self populateNavgiationChannelList];
}

- (void)resetWindowSize:(id)sender
{
	if (self.masterController.mainWindow.isInFullscreenMode) {
		[self toggleFullscreenMode:sender];
	}

	[self.masterController.mainWindow setFrame:TPCPreferences.defaultWindowFrame
									   display:YES
									   animate:YES];

	[self.masterController saveWindowState];
}

- (void)forceReloadTheme:(id)sender
{
	[self.worldController reloadTheme];
}

- (void)toggleChannelModerationMode:(id)sender
{
	IRCChannel *c = [self.worldController selectedChannel];

	if (_noChannel || _isClient || _isQuery) {
		return;
	}

	[c.client sendCommand:[NSString stringWithFormat:@"%@ %@ %@", IRCPublicCommandIndex("mode"), [c name], (([sender tag] == 6882) ? @"-m" : @"+m")]];
}

- (void)toggleChannelInviteMode:(id)sender
{
	IRCChannel *c = [self.worldController selectedChannel];

	if (_noChannel || _isClient || _isQuery) {
		return;
	}

	[c.client sendCommand:[NSString stringWithFormat:@"%@ %@ %@", IRCPublicCommandIndex("mode"), [c name], (([sender tag] == 6884) ? @"-i" : @"+i")]];
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

- (void)loadExtensionsIntoMemory:(id)sender
{
	[RZPluginManager() loadPlugins];
}

- (void)unloadExtensionsFromMemory:(id)sender
{
	[RZPluginManager() unloadPlugins];
}

- (void)resetDoNotAskMePopupWarnings:(id)sender
{
	NSDictionary *allSettings =	[RZUserDefaults() dictionaryRepresentation];

	for (NSString *key in allSettings) {
		if ([key hasPrefix:TXPopupPromptSuppressionPrefix]) {
			[RZUserDefaults() setBool:NO forKey:key];
		}
	}
}

- (void)openDefaultIRCClientDialog:(id)sender
{
	[TPCPreferences defaultIRCClientPrompt:YES];
}

- (void)onNextHighlight:(id)sender
{
	[self.worldController.selectedViewController nextHighlight];
}

- (void)onPreviousHighlight:(id)sender
{
	[self.worldController.selectedViewController previousHighlight];
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
		self.worldController.areNotificationsDisabled = YES;
	} else {
		self.worldController.areNotificationsDisabled = NO;
	}

	NSMenu *fileMenu = [[[NSApp mainMenu] itemWithTag:2] submenu];
	NSMenu *dockMenu =  [[NSApp delegate] applicationDockMenu:NSApp];

	[[fileMenu itemWithTag:6667] setState:state];
	[[dockMenu itemWithTag:6667] setState:state];
}

- (void)toggleMuteOnNotificationSoundsShortcut:(NSInteger)state
{
	if (state == NSOnState) {
		self.worldController.isSoundMuted = YES;
	} else {
		self.worldController.isSoundMuted = NO;
	}

	NSMenu *fileMenu = [[[NSApp mainMenu] itemWithTag:2] submenu];
	NSMenu *dockMenu =  [[NSApp delegate] applicationDockMenu:NSApp];

	[[fileMenu itemWithTag:6666] setState:state];
	[[dockMenu itemWithTag:6666] setState:state];
}

- (void)toggleMuteOnNotificationSounds:(id)sender
{
    if ([self.worldController isSoundMuted]) {
		[self toggleMuteOnNotificationSoundsShortcut:NSOffState];
    } else {
		[self toggleMuteOnNotificationSoundsShortcut:NSOnState];
    }
}

- (void)toggleMuteOnAllNotifcations:(id)sender
{
	if ([self.worldController areNotificationsDisabled]) {
		[self toggleMuteOnAllNotifcationsShortcut:NSOffState];
	} else {
		[self toggleMuteOnAllNotifcationsShortcut:NSOnState];
	}
}

#pragma mark -
#pragma mark Splitview Toggles

- (void)toggleServerListVisibility:(id)sender
{
	[self.masterController showServerListSplitView:self.masterController.serverSplitView.viewIsHidden];
}

- (void)toggleMemberListVisibility:(id)sender
{
	self.masterController.memberList.setHiddenByUser = BOOLReverseValue(self.masterController.memberList.setHiddenByUser);

	[self.masterController showMemberListSplitView:self.masterController.memberSplitView.viewIsHidden];
}

@end
