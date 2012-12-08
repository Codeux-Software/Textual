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

#define _activate					(c && c.isActive)
#define _connected					(u && u.isConnected && u.isLoggedIn)
#define _isChannel					(c.isTalk == NO && c.isChannel == YES && c.isClient == NO)
#define _isClient					(c.isTalk == NO && c.isChannel == NO && c.isClient == YES)
#define _isQuery					(c.isTalk == YES && c.isChannel == NO && c.isClient == NO)
#define _noChannel					(PointerIsEmpty(c))
#define _noClient					(PointerIsEmpty(u))
#define _noClientOrChannel			(PointerIsEmpty(u) || PointerIsEmpty(c))
#define _notActive					(c && c.isActive == NO)
#define _notConnected				(u && u.isConnected == NO && u.isLoggedIn == NO && u.isConnecting == NO)

@implementation TXMenuController

- (id)init
{
	if ((self = [super init])) {
		self.currentSearchPhrase = NSStringEmptyPlaceholder;
	}
	
	return self;
}

- (void)terminate
{
	if (self.serverSheet) [self.serverSheet close];
	if (self.channelSheet) [self.channelSheet close];
	if (self.preferencesController) [self.preferencesController close];
}

- (void)validateChannelMenuSubmenus:(NSMenuItem *)item
{
	IRCChannel *c = [self.world selectedChannel];
	
	if (_isChannel) {
		[[item.menu itemWithTag:936] setHidden:NO];
		[[item.menu itemWithTag:937] setHidden:NO];
		
		[[item.menu itemWithTag:5422] setHidden:NO];
		[[item.menu itemWithTag:5422] setEnabled:YES];
		
		[[[item.menu itemWithTag:5422].submenu itemWithTag:542] setEnabled:[TPCPreferences logTranscript]];
	} else {
		[[item.menu itemWithTag:936] setHidden:BOOLReverseValue(c.isTalk)];
		[[item.menu itemWithTag:937] setHidden:BOOLReverseValue(c.isTalk)];
		
		[[item.menu itemWithTag:5422] setEnabled:NO]; 
		[[item.menu itemWithTag:5422] setHidden:YES]; 
	}	
}

- (BOOL)validateMenuItem:(NSMenuItem *)item
{
	IRCClient   *u = [self.world selectedClient];
	IRCChannel  *c = [self.world selectedChannel];
	
	NSInteger tag = item.tag;
	
	switch (tag) {
		case 313:	// paste
		{
			if (NSObjectIsEmpty([_NSPasteboard() stringContent])) {
				return NO;
			}
			
			NSWindow *win = [NSApp keyWindow];
			if (PointerIsEmpty(win)) return NO;
			
			id t = [win firstResponder];
			if (PointerIsEmpty(t)) return NO;
			
			if ([t respondsToSelector:@selector(paste:)]) {
				if ([t respondsToSelector:@selector(validateMenuItem:)]) {
					return [t validateMenuItem:item];
				}
				
				return YES;
			}
			
			break;
		}
		case 331:	// search in google
		{
			[self validateChannelMenuSubmenus:item];
			
			TVCLogView *web = [self currentWebView];
			if (PointerIsEmpty(web)) return NO;
			
			return [web hasSelection];
			break;
		}
		case 501:	// connect
		{
			BOOL condition = (_connected || u.isConnecting);
			
			[item setHidden:condition];
			
			return BOOLReverseValue(condition);
			break;
		}
		case 502:	// disconnect
		{
			BOOL condition = (u && (_connected || u.isConnecting));
			
			[item setHidden:BOOLReverseValue(condition)];
			
			return condition;
			break;
		}
		case 503:	// cancel isReconnecting
		{
			BOOL condition = (u && [u isReconnecting]);
			
			[item setHidden:BOOLReverseValue(condition)];
			
			return condition;
			break;
		}
		case 511:	// nick
		case 519:	// channel list
		{
			return _connected;
			break;
		}
		case 522:	// copy server
		{
			return BOOLValueFromObject(u);
			break;
		}
		case 523:	// delete server
		{
			return _notConnected;
			break;
		}
		case 541:	// server property
		{
			return BOOLValueFromObject(u);
			break;
		}
		case 592:	// textual logs
		{
			return [TPCPreferences logTranscript];
			break;
		}
		case 601:	// join
		{
			[self validateChannelMenuSubmenus:item];
			
			if (_isQuery) {
				[item setHidden:YES];
				
				return NO;
			} else {
				BOOL condition = (_connected && _notActive && _isChannel);
				
				if (_connected) {
					[item setHidden:BOOLReverseValue(condition)];
				} else {
					[item setHidden:NO];
				}
				
				return condition;
			}
			
			break;
		}
		case 602:	// leave
		{
			if (_isQuery) {
				[item setHidden:YES];
				
				return NO;
			} else {
				[item setHidden:_notActive];
				
				return _activate;
			}
			
			break;
		}
		case 611:	// mode
		{
			return _activate;
			break;
		}
		case 612:	// topic
		{
			return _activate;
			break;
		}
		case 651:	// add channel
		{
			if (_isQuery) {
				[item setHidden:YES];
				
				return NO;
			} else {
				[item setHidden:NO];
				
				return BOOLValueFromObject(u);
			}
			
			break;
		}
		case 652:	// delete channel
		{
			if (_isQuery) {
				[item setTitle:TXTLS(@"DeleteQueryMenuItem")];
				
				return YES;
			} else {
				[item setTitle:TXTLS(@"DeleteChannelMenuItem")];
				
				return _isChannel;
			}
			
			break;
		}
		case 691:	// add channel - server menu
		{
			return BOOLValueFromObject(u);
			break;
		}
		case 2005:	// invite
		{
			if (_notConnected || [self checkSelectedMembers:item] == NO) return NO;
			
			NSInteger count = 0;
			
			for (IRCChannel *e in u.channels) {
				if (NSDissimilarObjects(c, e) && e.isChannel) {
					++count;
				}
			}
			
			return (count > 0);
			break;
		}
		case 5421: // query logs
		{
			if (_isQuery) {
				[item setHidden:NO];
				
				[[item.menu itemWithTag:935] setHidden:YES]; 
				
				return [TPCPreferences logTranscript];
			} else {
				[item setHidden:YES];
				
				[[item.menu itemWithTag:935] setHidden:NO];
				
				return NO;
			}
			
			break;
		}
		case 9631: // close window
		{
			if ([self.window isKeyWindow]) {
				IRCClient *u = [self.world selectedClient];
				IRCChannel *c = [self.world selectedChannel];
				
				if (_noClientOrChannel) return YES;
				
				switch ([TPCPreferences cmdWResponseType]) {
					case TXCmdWShortcutCloseWindowType:
					{
						[item setTitle:TXTLS(@"CmdWShortcutCloseWindowType")];
						
						break;
					}
					case TXCmdWShortcutPartChannelType:
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
								[item setTitle:TXTLS(@"CmdWShortcutCloseQueryType")];
							}
						}
						
						break;
					}
					case TXCmdWShortcutDisconnectType:
					{
						[item setTitle:TXTFLS(@"CmdWShortcutDisconnectServerType", ((u.config.server) ?: u.config.name))];
						
						if (_notConnected) return NO;
						
						break;
					}
					case TXCmdWShortcutTerminateType:
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
		case 593: // Highlights
		{
			return ([TPCPreferences logAllHighlightsToQuery] && _connected);
			break;
		}
        case 54092: // Developer Mode
        {
            if ([_NSUserDefaults() boolForKey:TXDeveloperEnvironmentToken] == YES) {
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
			NSArray *nicknames = [self selectedMembers:nil];
			
			if (NSObjectIsEmpty(nicknames) || nicknames.count > 1) {
				[item setHidden:NO];
				
				[[item.menu itemWithTag:504913] setHidden:YES];
				[[item.menu itemWithTag:504813] setHidden:YES];
				
				return YES;
			} else {
				IRCUser *m = [nicknames safeObjectAtIndex:0];
				
				switch (tag) {
					case 504910: [item setHidden:m.o]; break; // +o
					case 504911: [item setHidden:m.h]; break;  // +h
					case 504912: [item setHidden:m.v]; break;  // +v
					case 504810: [item setHidden:(m.o == NO)]; break; // -o
					case 504811: [item setHidden:(m.h == NO)]; break; // -h
					case 504812: [item setHidden:(m.v == NO)]; break; // -v
						
					default: break;
				}
				
				BOOL hideTakeSepItem = (m.o == NO || m.h == NO || m.v == NO);
				BOOL hideGiveSepItem = (m.o || m.h || m.v);
				
				[[item.menu itemWithTag:504913] setHidden:hideTakeSepItem];
				[[item.menu itemWithTag:504813] setHidden:hideGiveSepItem];
				
				return YES;
			}
			break;
		}
		case 990002: // Next Highlight
		{
			return [self.world.selected.log highlightAvailable:NO];
			break;
		}
		case 990003: // Previous Highlight
		{
			return [self.world.selected.log highlightAvailable:YES];
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
	return self.world.selected.log.view;
}

- (BOOL)checkSelectedMembers:(NSMenuItem *)item
{
	return ([self.memberList countSelectedRows] > 0);
}

- (NSArray *)selectedMembers:(NSMenuItem *)sender
{
	IRCClient *u = [self.world selectedClient];
	IRCChannel *c = [self.world selectedChannel];
	
	NSMutableArray *ary = [NSMutableArray array];
	
	if (_noClientOrChannel || _notActive || _notConnected || _isClient) {
		return ary;
	} else {
		NSIndexSet *indexes = [self.memberList selectedRowIndexes];
		
		if (NSObjectIsNotEmpty(indexes) && NSObjectIsEmpty(self.pointedNick)) {
			for (NSNumber *index in [indexes arrayFromIndexSet]) {
				NSUInteger nindex = [index unsignedIntegerValue];
				
				IRCUser *m = [c memberAtIndex:nindex];
				
				if (m) {
					[ary safeAddObject:m];
				}
			}
		} else {
			if (NSObjectIsNotEmpty(self.pointedNick)) {
				IRCUser *m = [c findMember:self.pointedNick];
				
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
	self.pointedNick = nil;
	
	[self.memberList deselectAll:nil];
}

#pragma mark -
#pragma mark Menu Items

- (void)_onWantFindPanel:(id)sender
{
	if (self.findPanelOpened) {
		return;
	}

	self.findPanelOpened = YES;

	NSString *newPhrase = [TLOPopupPrompts dialogWindowWithInput:TXTLS(@"FindSearchPanelPromptMessage")
														   title:TXTLS(@"FindSearchPanelPromptTitle")
												   defaultButton:TXTLS(@"FindSearchPanelPromptButton")
												 alternateButton:TXTLS(@"CancelButton") 
													defaultInput:self.currentSearchPhrase];

	self.findPanelOpened = NO;

	if (NSObjectIsEmpty(newPhrase)) {
		self.currentSearchPhrase = NSStringEmptyPlaceholder;
	} else {
		if ([newPhrase isNotEqualTo:self.currentSearchPhrase]) {
			self.currentSearchPhrase = newPhrase;
		}

		dispatch_async(dispatch_get_main_queue(), ^{
			[[self currentWebView] searchFor:newPhrase direction:YES caseSensitive:NO wrap:YES];
		});
	}
}

- (void)showFindPanel:(id)sender
{
	if ([sender tag] == 1 || NSObjectIsEmpty(self.currentSearchPhrase)) {
		[self.invokeInBackgroundThread _onWantFindPanel:sender];
	} else {
		if ([sender tag] == 2) {
			[[self currentWebView] searchFor:self.currentSearchPhrase direction:YES caseSensitive:NO wrap:YES];
		} else {
			[[self currentWebView] searchFor:self.currentSearchPhrase direction:NO caseSensitive:NO wrap:YES];
		}
	}
}

- (void)commandWShortcutUsed:(id)sender
{
	NSWindow *currentWindow = [NSApp keyWindow];
	
	IRCClient *u = [self.world selectedClient];
	IRCChannel *c = [self.world selectedChannel];
	
	if ([self.window isKeyWindow]) {
		switch ([TPCPreferences cmdWResponseType]) {
			case TXCmdWShortcutCloseWindowType:
			{
				[self.window close];
				
				break;
			}
			case TXCmdWShortcutPartChannelType:
			{
				if (_noClientOrChannel || _isClient) return;
				
				if (_isChannel && _activate) {
					[u partChannel:c];
				} else {
					if (_isQuery) {
						[self.world destroyChannel:c];
					}
				}
				
				break;
			}
			case TXCmdWShortcutDisconnectType:
			{
				if (_noClient || _notConnected) return;
				
				[u quit];
				
				break;
			}
			case TXCmdWShortcutTerminateType:
			{
				[NSApp terminate:nil];
				
				break;
			}
		}
	} else {
		[currentWindow performClose:nil];
	}
}

- (void)showPreferencesDialog:(id)sender
{
	if (self.preferencesController) {
		[self.preferencesController show];
		
		return;
	}
	
	TDCPreferencesController *pc = [TDCPreferencesController alloc];
	
	pc.delegate = self;
	pc.world = self.world;
	
	self.preferencesController = pc;
	
	(void)[self.preferencesController initWithWorldController:self.world];
	
	[self.preferencesController show];
}

- (void)preferencesDialogWillClose:(TDCPreferencesController *)sender
{
	[self.world preferencesChanged];
	
	self.preferencesController = nil;
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
	IRCChannel *c = [self.world selectedChannel];
	
	if (c) {
		[self.world destroyChannel:c];
		[self.world save];
	}
}

- (void)showAcknowledgments:(id)sender
{
	[_NSWorkspace() openURL:[NSURL fileURLWithPath:[[TPCPreferences applicationResourcesFolderPath] stringByAppendingPathComponent:@"Documentation/Acknowledgments.pdf"]]];
}

- (void)showContributors:(id)sender
{
	[_NSWorkspace() openURL:[NSURL fileURLWithPath:[[TPCPreferences applicationResourcesFolderPath] stringByAppendingPathComponent:@"Documentation/Contributors.pdf"]]];
}

- (void)performPaste:(id)sender
{
	NSWindow *win = [NSApp keyWindow];
	if (PointerIsEmpty(win)) return;
	
	id t = [win firstResponder];
	if (PointerIsEmpty(t)) return;
	
	if (self.window == [NSApp keyWindow]) {
		if (PointerIsEmpty([self.window attachedSheet])) {
			[self.text focus];
			[self.text paste:self];
			
			return;
		}
	}
	
	if ([t respondsToSelector:@selector(paste:)]) {
		BOOL validated = YES;
		
		if ([t respondsToSelector:@selector(validateMenuItem:)]) {
			validated = [t validateMenuItem:sender];
		}
		
		if (validated) {
			[t paste:sender];
		}
	}
}

- (void)searchGoogle:(id)sender
{
	TVCLogView *web = [self currentWebView];
	if (PointerIsEmpty(web)) return;
	
	NSString *s = [web selection];
	
	if (NSObjectIsNotEmpty(s)) {
		s = [s gtm_stringByEscapingForURLArgument];
		
		NSString *urlStr = [NSString stringWithFormat:@"http://www.google.com/search?ie=UTF-8&q=%@", s];
		
		[TLOpenLink openWithString:urlStr];
	}
}

- (void)copyLogAsHtml:(id)sender
{
	IRCTreeItem *sel = self.world.selected;
	
	if (PointerIsEmpty(sel)) return;
	
	[_NSPasteboard() setStringContent:[sel.log.view contentString]];
}

- (void)markScrollback:(id)sender
{
	IRCTreeItem *sel = self.world.selected;
	
	if (PointerIsEmpty(sel)) return;
	
	[sel.log unmark];
	[sel.log mark];
}

- (void)gotoScrollbackMarker:(id)sender
{
	IRCTreeItem *sel = self.world.selected;
	
	if (PointerIsEmpty(sel)) return;
	
	[sel.log goToMark];
}

- (void)clearScrollback:(id)sender
{
	IRCClient *u = [self.world selectedClient];
	IRCChannel *c = [self.world selectedChannel];
	
    if (u) {
        if (c) {
            [self.world clearContentsOfChannel:c inClient:u];
            
			[c setDockUnreadCount:0];
			[c setTreeUnreadCount:0];
            [c setKeywordCount:0];
        } else {
            [self.world clearContentsOfClient:u];
            
			[u setDockUnreadCount:0];
			[u setTreeUnreadCount:0];
            [u setKeywordCount:0];
        }
        
        [self.world updateIcon];
    }
}

- (void)increaseLogFontSize:(id)sender
{
	[self.world changeTextSize:YES];
}

- (void)decreaseLogFontSize:(id)sender
{
	[self.world changeTextSize:NO];
}

- (void)markAllAsRead:(id)sender
{
	[self.world markAllAsRead];
}

- (void)connect:(id)sender
{
	IRCClient *u = [self.world selectedClient];
	
	if (_noClient || _connected) return;
	
	[u connect];

	[self.world expandClient:u]; // Expand client on user opreated connect.
}

- (void)disconnect:(id)sender
{
	IRCClient *u = [self.world selectedClient];
	
	if (_noClient || _notConnected) return;
	
	[u quit];
	[u cancelReconnect];
}

- (void)cancelReconnection:(id)sender
{
	IRCClient *u = [self.world selectedClient];
	
	if (_noClient) return;
	
	[u cancelReconnect];
}

- (void)showNicknameChangeDialog:(id)sender
{
	if (self.nickSheet) return;
	
	IRCClient *u = [self.world selectedClient];
	
	if (_noClient || _notConnected) return;
	
	self.nickSheet = [TDCNickSheet new];
	self.nickSheet.delegate = self;
	self.nickSheet.window = self.window;
	self.nickSheet.uid = u.uid;
	
	[self.nickSheet start:u.myNick];
}

- (void)nickSheet:(TDCNickSheet *)sender didInputNick:(NSString *)newNick
{
	IRCClient *u = [self.world findClientById:sender.uid];
	
	if (_noClient || _notConnected) return;
	
	[u changeNick:newNick];
}

- (void)nickSheetWillClose:(TDCNickSheet *)sender
{
	self.nickSheet = nil;
}

- (void)showServerChannelList:(id)sender
{
	IRCClient *u = [self.world selectedClient];
	
	if (_noClient || _notConnected) return;
	
	[u createChannelListDialog];
	[u send:IRCPrivateCommandIndex("list"), nil];
}

- (void)addServer:(id)sender
{
	if (self.serverSheet) return;
	
	TDCServerSheet *d = [TDCServerSheet new];
	
	d.delegate = self;
	d.window = self.window;
	d.config = [IRCClientConfig new];
	d.uid = -1;
	
	[d startWithIgnoreTab:NSStringEmptyPlaceholder];
	
	self.serverSheet = d;
}

- (void)copyServer:(id)sender
{
	IRCClient *u = [self.world selectedClient];
	
	if (_noClient) return;
	
	IRCClientConfig *config = u.storedConfig;
	
	config.name  = [config.name stringByAppendingString:@"_"];
	config.guid  = [NSString stringWithUUID];
	config.cuid += 1;
	
	IRCClient *n = [self.world createClient:config reload:YES];
	
	[self.world save];
	
	if (u.isExpanded) { // Only expand new client if old was expanded already.
		[self.world expandClient:n];
	}
}

- (void)deleteServer:(id)sender
{
	IRCClient *u = [self.world selectedClient];
	
	if (_noClient || _connected) return;
	
	BOOL result = [TLOPopupPrompts dialogWindowWithQuestion:TXTLS(@"ServerDeletePromptMessage")
													  title:TXTLS(@"ServerDeletePromptTitle")
											  defaultButton:TXTLS(@"OkButton") 
											alternateButton:TXTLS(@"CancelButton")
											 suppressionKey:@"delete_server"
											suppressionText:nil];
	
	if (result == NO) {
		return;
	}
	
	[u.config destroyKeychains];

	NSString *supkey;

	supkey = TXPopupPromptSuppressionPrefix;
	supkey = [supkey stringByAppendingString:@"cert_trust_error."];
	supkey = [supkey stringByAppendingString:u.config.guid];

	[_NSUserDefaults() removeObjectForKey:supkey];
	
	[self.world destroyClient:u];
	[self.world save];
}

- (void)showServerPropertyDialog:(IRCClient *)u ignore:(NSString *)imask
{
	if (_noClient) return;
	if (self.serverSheet) return;
	
	TDCServerSheet *d = [TDCServerSheet new];
	
	d.delegate = self;
	d.window = self.window;
	d.config = u.storedConfig;
	d.uid = u.uid;
	d.client = u;
	
	[d startWithIgnoreTab:imask];
	
	self.serverSheet = d;
}

- (void)showServerPropertiesDialog:(id)sender
{
	[self showServerPropertyDialog:[self.world selectedClient] ignore:NSStringEmptyPlaceholder];
}

- (void)serverSheetOnOK:(TDCServerSheet *)sender
{
	if (sender.uid < 0) {
		[self.world createClient:sender.config reload:YES];
	} else {
		IRCClient *u = [self.world findClientById:sender.uid];
		
		if (_noClient) return;
		
		[u updateConfig:sender.config];
	}
	
	[self.world save];
}

- (void)serverSheetWillClose:(TDCServerSheet *)sender
{
	self.serverSheet = nil;
}

- (void)joinChannel:(id)sender
{
	IRCClient *u = [self.world selectedClient];
	IRCChannel *c = [self.world selectedChannel];
	
	if (_noClientOrChannel || _isClient || _isQuery || _activate || _notConnected) return;
	
	[u joinChannel:c];
}

- (void)leaveChannel:(id)sender
{
	IRCClient *u = [self.world selectedClient];
	IRCChannel *c = [self.world selectedChannel];
	
	if (_noClientOrChannel || _notActive || _notConnected) return;
	
	if (_isChannel) {
		[u partChannel:c];
	} else {
		[self.world destroyChannel:c];
	}
}

- (void)showHighlightSheet:(id)sender
{
	if (self.highlightSheet) return;
	
	IRCClient *u = [self.world selectedClient];
	
	if (_noClient) return;
	
	TDCHighlightSheet *d = [TDCHighlightSheet new];
	
	d.delegate = self;
	d.window = self.window;
	d.list = u.highlights;
	
	[self.window closeExistingSheet];
	
	[d show];
	
	self.highlightSheet = d;
}

- (void)highlightSheetWillClose:(TDCHighlightSheet *)sender
{
	self.highlightSheet = nil;
}

- (void)showChannelTopicDialog:(id)sender
{
	if (self.topicSheet) return;
	
	IRCClient *u = [self.world selectedClient];
	IRCChannel *c = [self.world selectedChannel];
	
	if (_noClientOrChannel || _isClient || _isQuery) return;
	
	TDCTopicSheet *t = [TDCTopicSheet new];
	
	t.delegate = self;
	t.window = self.window;
	t.uid = u.uid;
	t.cid = c.uid;
	
	[t start:c.topic];
	
	self.topicSheet = t;
}

- (void)topicSheet:(TDCTopicSheet *)sender onOK:(NSString *)topic
{
	IRCChannel *c = [self.world findChannelByClientId:sender.uid channelId:sender.cid];
	IRCClient *u = c.client;
	
	if (_noClientOrChannel || _isClient || _isQuery) return;
	
	if ([u encryptOutgoingMessage:&topic channel:c] == YES) {
		[u send:IRCPrivateCommandIndex("topic"), c.name, topic, nil];
	}
}

- (void)topicSheetWillClose:(TDCTopicSheet *)sender
{
	self.topicSheet = nil;
}

- (void)showChannelModeDialog:(id)sender
{
	if (self.modeSheet) return;
	
	IRCClient *u = [self.world selectedClient];
	IRCChannel *c = [self.world selectedChannel];
	
	if (_noClientOrChannel || _isClient || _isQuery) return;
	
	TDCModeSheet *m = [TDCModeSheet new];
	
	m.delegate = self;
	m.window = self.window;
	m.uid = u.uid;
	m.cid = c.uid;
	m.channelName = c.name;
	m.mode = c.mode;
	
	[m start];
	
	self.modeSheet = m;
}

- (void)modeSheetOnOK:(TDCModeSheet *)sender
{
	IRCChannel *c = [self.world findChannelByClientId:sender.uid channelId:sender.cid];
	IRCClient *u = c.client;
	
	if (_noClientOrChannel || _isClient || _isQuery) return;
	
	NSString *changeStr = [c.mode getChangeCommand:sender.mode];
	
	if (NSObjectIsNotEmpty(changeStr)) {
		[u sendLine:[NSString stringWithFormat:@"%@ %@ %@", IRCPrivateCommandIndex("mode"), c.name, changeStr]];
	}
}

- (void)modeSheetWillClose:(TDCModeSheet *)sender
{
	self.modeSheet = nil;
}

- (void)addChannel:(id)sender
{
	if (self.channelSheet) return;
	
	IRCClient *u = [self.world selectedClient];
	
	if (_noClient) return;
	
	TDChannelSheet *d = [TDChannelSheet new];
	
	d.delegate = self;
	d.window = self.window;
	d.config = [IRCChannelConfig new];
	d.uid = u.uid;
	d.cid = -1;
	
	[d start];
	
	self.channelSheet = d;
}

- (void)deleteChannel:(id)sender
{
	IRCChannel *c = [self.world selectedChannel];
	
	if (_noChannel || _isClient) return;
	
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
	
	[self.world destroyChannel:c];
	[self.world save];
}

- (void)showChannelPropertiesDialog:(id)sender
{
	if (self.channelSheet) return;
	
	IRCClient *u = [self.world selectedClient];
	IRCChannel *c = [self.world selectedChannel];
	
	if (_noClientOrChannel || _isClient || _isQuery) return;
	
	TDChannelSheet *d = [TDChannelSheet new];
	
	d.delegate = self;
	d.window = self.window;
	d.config = [c.config mutableCopy];
	d.uid = u.uid;
	d.cid = c.uid;
	
	[d start];
	
	self.channelSheet = d;
}

- (void)channelSheetOnOK:(TDChannelSheet *)sender
{
	if (sender.cid < 0) {
		IRCClient *u = [self.world findClientById:sender.uid];
		
		if (_noClient) return;
		
		[self.world createChannel:sender.config client:u reload:YES adjust:YES];
		[self.world expandClient:u];
	} else {
		IRCChannel *c = [self.world findChannelByClientId:sender.uid channelId:sender.cid];
		
		if (_noChannel) return;
		
		if (NSObjectIsEmpty(c.config.encryptionKey) &&
			NSObjectIsNotEmpty(sender.config.encryptionKey)) {
			
			[c.client printDebugInformation:TXTLS(@"BlowfishEncryptionStarted") channel:c];
		} else if (NSObjectIsNotEmpty(c.config.encryptionKey) &&
				   NSObjectIsEmpty(sender.config.encryptionKey)) {
			
			[c.client printDebugInformation:TXTLS(@"BlowfishEncryptionStopped") channel:c];
		} else if (NSObjectIsNotEmpty(c.config.encryptionKey) &&
				   NSObjectIsNotEmpty(sender.config.encryptionKey)) {
			
			if ([c.config.encryptionKey isEqualToString:sender.config.encryptionKey] == NO) {
				[c.client printDebugInformation:TXTLS(@"BlowfishEncryptionKeyChanged") channel:c];
			}
		}
		
		[c updateConfig:sender.config];
	}
	
	[self.world save];
}

- (void)channelSheetWillClose:(TDChannelSheet *)sender
{
	self.channelSheet = nil;
}

- (void)whoisSelectedMembers:(id)sender deselect:(BOOL)deselect
{
	IRCClient *u = [self.world selectedClient];
	IRCChannel *c = [self.world selectedChannel];
	
	if (_noClient || _isClient) return;
	
	for (IRCUser *m in [self selectedMembers:sender]) {
		[u sendWhois:m.nick];
	}
	
	if (deselect) {
		[self deselectMembers:sender];
	}
}

- (void)memberListDoubleClicked:(id)sender
{
    TVCMemberList *view = sender;
    
    NSPoint pt;
    NSInteger n;
    
    pt = [self.window mouseLocationOutsideOfEventStream];
    pt = [view convertPoint:pt fromView:nil];
    
    n = [view rowAtPoint:pt];
    
    if (n >= 0) {
        if (NSObjectIsNotEmpty([view selectedRowIndexes])) {
            [view selectItemAtIndex:n];
        }
        
        switch ([TPCPreferences userDoubleClickOption]) {
            case TXUserDoubleClickWhoisAction: [self whoisSelectedMembers:nil deselect:NO]; break;
            case TXUserDoubleClickQueryAction: [self memberStartQuery:nil]; break;
        }
    }
}

- (void)memberSendWhois:(id)sender
{
	[self whoisSelectedMembers:sender deselect:YES];
}

- (void)memberStartQuery:(id)sender
{
	IRCClient *u = [self.world selectedClient];
	IRCChannel *c = [self.world selectedChannel];
	
	if (_noClient || _isClient) return;
	
	for (IRCUser *m in [self selectedMembers:sender]) {
		IRCChannel *c = [u findChannel:m.nick];
		
		if (_noChannel) {
			c = [self.world createTalk:m.nick client:u];
		}
		
		[self.world select:c];
	}
	
	[self deselectMembers:sender];
}

- (void)memberSendInvite:(id)sender
{
	if (self.inviteSheet) return;
	
	IRCClient *u = [self.world selectedClient];
	IRCChannel *c = [self.world selectedChannel];
	
	if (_noClientOrChannel || _notConnected) return;
	
	NSMutableArray *nicks = [NSMutableArray array];
	NSMutableArray *channels = [NSMutableArray array];
	
	for (IRCUser *m in [self selectedMembers:sender]) {
		[nicks safeAddObject:m.nick];
	}
	
	for (IRCChannel *e in u.channels) {
		if (NSDissimilarObjects(c, e) && e.isChannel) {
			[channels safeAddObject:e.name];
		}
	}
	
	if (NSObjectIsEmpty(channels)) return;
	
	self.inviteSheet = [TDCInviteSheet new];
	self.inviteSheet.delegate = self;
	self.inviteSheet.window = self.window;
	self.inviteSheet.nicks = nicks;
	self.inviteSheet.uid = u.uid;
	
	[self.inviteSheet startWithChannels:channels];
}

- (void)inviteSheet:(TDCInviteSheet *)sender onSelectChannel:(NSString *)channelName
{
	IRCClient *u = [self.world findClientById:sender.uid];
	
	if (u && NSObjectIsNotEmpty(channelName)) {
		for (NSString *nick in sender.nicks) {
			[u send:IRCPrivateCommandIndex("invite"), nick, channelName, nil];
		}
	}
}

- (void)inviteSheetWillClose:(TDCInviteSheet *)sender
{
	self.inviteSheet = nil;
}

- (void)memberSendCTCPPing:(id)sender
{
	IRCClient *u = [self.world selectedClient];
	IRCChannel *c = [self.world selectedChannel];
	
	if (_noClient || _isClient) return;
	
	for (IRCUser *m in [self selectedMembers:sender]) {
		[u sendCTCPPing:m.nick];
	}
	
	[self deselectMembers:sender];
}

- (void)memberSendCTCPTime:(id)sender
{
	IRCClient *u = [self.world selectedClient];
	IRCChannel *c = [self.world selectedChannel];
	
	if (_noClient || _isClient) return;
	
	for (IRCUser *m in [self selectedMembers:sender]) {
		[u sendCTCPQuery:m.nick command:IRCPrivateCommandIndex("ctcp_time") text:nil];
	}
	
	[self deselectMembers:sender];
}

- (void)memberSendCTCPVersion:(id)sender
{
	IRCClient *u = [self.world selectedClient];
	IRCChannel *c = [self.world selectedChannel];
	
	if (_noClient || _isClient) return;
	
	for (IRCUser *m in [self selectedMembers:sender]) {
		[u sendCTCPQuery:m.nick command:IRCPrivateCommandIndex("ctcp_version") text:nil];
	}
	
	[self deselectMembers:sender];
}

- (void)memberSendCTCPUserinfo:(id)sender
{
	IRCClient *u = [self.world selectedClient];
	IRCChannel *c = [self.world selectedChannel];
	
	if (_noClient || _isClient) return;
	
	for (IRCUser *m in [self selectedMembers:sender]) {
		[u sendCTCPQuery:m.nick command:IRCPrivateCommandIndex("ctcp_userinfo") text:nil];
	}
	
	[self deselectMembers:sender];
}

- (void)memberSendCTCPClientInfo:(id)sender
{
	IRCClient *u = [self.world selectedClient];
	IRCChannel *c = [self.world selectedChannel];
	
	if (_noClient || _isClient) return;
	
	for (IRCUser *m in [self selectedMembers:sender]) {
		[u sendCTCPQuery:m.nick command:IRCPrivateCommandIndex("ctcp_clientinfo") text:nil];
	}
	
	[self deselectMembers:sender];
}

- (void)copyUrl:(id)sender
{
	if (NSObjectIsNotEmpty(self.pointedUrl)) {
		[_NSPasteboard() setStringContent:self.pointedUrl];
		
		self.pointedUrl = nil;
	}
}

- (void)joinClickedChannel:(id)sender
{
	IRCClient *u = [self.world selectedClient];
	
	if (_noClient || _notConnected) return;
	
	if (NSObjectIsNotEmpty(self.pointedChannelName)) {
		[u joinUnlistedChannel:self.pointedChannelName];
		
        self.pointedChannelName = nil;
	}
}

- (void)showChannelIgnoreList:(id)sender
{
	[self showServerPropertyDialog:[self.world selectedClient] ignore:@"-"];
}

- (void)showAboutWindow:(id)sender
{
	if (self.aboutPanel) {
		[self.aboutPanel show];
		return;
	}
	
	self.aboutPanel = [TDCAboutPanel new];
	self.aboutPanel.delegate = self;
	[self.aboutPanel show];
}

- (void)aboutPanelWillClose:(TDCAboutPanel *)sender
{
	self.aboutPanel = nil;
}

- (void)processModeChange:(id)sender mode:(NSString *)tmode 
{
	IRCClient *u = [self.world selectedClient];
	IRCChannel *c = [self.world selectedChannel];
	
	if (_noClientOrChannel || _isClient || _isQuery) return;
	
	NSString *opString = NSStringEmptyPlaceholder;
	
	NSInteger currentIndex = 0;
	
	for (IRCUser *m in [self selectedMembers:sender]) {
		opString = [opString stringByAppendingFormat:@"%@ ", m.nick];
		
		currentIndex++;
		
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
	IRCClient *u = [self.world selectedClient];
	IRCChannel *c = [self.world selectedChannel];
	
	if (_noClientOrChannel || _isClient || _isQuery) return;
	
	for (IRCUser *m in [self selectedMembers:sender]) {
		[u kick:c target:m.nick];
	}
	
	[self deselectMembers:sender];
}

- (void)memberBanFromServer:(id)sender
{
	IRCClient *u = [self.world selectedClient];
	IRCChannel *c = [self.world selectedChannel];
	
	if (_noClientOrChannel || _isClient || _isQuery) return;
	
	for (IRCUser *m in [self selectedMembers:sender]) {
		[u sendCommand:[NSString stringWithFormat:@"%@ %@", IRCPublicCommandIndex("ban"), m.nick] completeTarget:YES target:c.name];
	}
	
	[self deselectMembers:sender];
}

- (void)memberKickbanFromChannel:(id)sender
{
	IRCClient *u = [self.world selectedClient];
	IRCChannel *c = [self.world selectedChannel];
	
	if (_noClientOrChannel || _isClient || _isQuery) return;
	
	for (IRCUser *m in [self selectedMembers:sender]) {
		[u sendCommand:[NSString stringWithFormat:@"%@ %@ %@",
						IRCPublicCommandIndex("kickban"), m.nick, [TPCPreferences defaultKickMessage]]
		completeTarget:YES target:c.name];
	}
	
	[self deselectMembers:sender];
}

- (void)memberKillFromServer:(id)sender
{
	IRCClient *u = [self.world selectedClient];
	IRCChannel *c = [self.world selectedChannel];
	
	if (_noClientOrChannel || _isClient) return;
	
	for (IRCUser *m in [self selectedMembers:sender]) {
		[u sendCommand:[NSString stringWithFormat:@"%@ %@ %@",
						IRCPublicCommandIndex("kill"), m.nick, [TPCPreferences IRCopDefaultKillMessage]]];
	}
	
	[self deselectMembers:sender];
}

- (void)memberGlineFromServer:(id)sender
{
	IRCClient *u = [self.world selectedClient];
	IRCChannel *c = [self.world selectedChannel];
	
	if (_noClientOrChannel || _isClient) return;
	
	for (IRCUser *m in [self selectedMembers:sender]) {
        if ([m.nick isEqualNoCase:u.myNick]) {
            [u printDebugInformation:TXTFLS(@"SelfBanDetectedMessage", u.config.server) channel:c];
        } else {
            [u sendCommand:[NSString stringWithFormat:@"%@ %@ %@",
							IRCPublicCommandIndex("gline"), m.nick, [TPCPreferences IRCopDefaultGlineMessage]]];
        }
    }
	
	[self deselectMembers:sender];
}

- (void)memberShunFromServer:(id)sender
{
	IRCClient *u = [self.world selectedClient];
	IRCChannel *c = [self.world selectedChannel];
	
	if (_noClientOrChannel || _isClient) return;
	
	for (IRCUser *m in [self selectedMembers:sender]) {
		[u sendCommand:[NSString stringWithFormat:@"%@ %@ %@",
						IRCPublicCommandIndex("shun"), m.nick, [TPCPreferences IRCopDefaultShunMessage]]];
	}
	
	[self deselectMembers:sender];
}

- (void)openLogLocation:(id)sender
{	
	NSString *path = [TPCPreferences transcriptFolder];
	
	if ([_NSFileManager() fileExistsAtPath:path]) {
		[_NSWorkspace() openURL:[NSURL fileURLWithPath:path]];
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
	IRCClient *u = [self.world selectedClient];
	IRCChannel *c = [self.world selectedChannel];
	
	if (_noClientOrChannel || _isClient) return;
	
	NSString *path = [c.logFile buildPath];
	
	if ([_NSFileManager() fileExistsAtPath:path]) {
		[_NSWorkspace() openURL:[NSURL fileURLWithPath:path]];
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
	[self.world createConnection:@"chat.freenode.net +6697" chan:@"#textual"];
}

- (void)connectToTextualTestingChannel:(id)sender
{
	[self.world createConnection:@"chat.freenode.net +6697" chan:@"#textual-testing"];
}

- (void)__onWantHostServVhostSet:(id)sender andVhost:(NSString *)vhost
{
	if (NSObjectIsNotEmpty(vhost)) {
		IRCClient *u = [self.world selectedClient];
		IRCChannel *c = [self.world selectedChannel];
		
		if (_noClient || _isClient) return;
		
		NSArray *nicknames = [self selectedMembers:sender];
		
		for (IRCUser *m in nicknames) {
			[u sendCommand:[NSString stringWithFormat:@"hs setall %@ %@", m.nick, vhost] completeTarget:NO target:nil];
		}
	}
	
	[self deselectMembers:sender];
}

- (void)_onWantHostServVhostSet:(id)sender
{
	NSString *vhost = [TLOPopupPrompts dialogWindowWithInput:TXTLS(@"SetUserVhostPromptMessage")
													   title:TXTLS(@"SetUserVhostPromptTitle") 
											   defaultButton:TXTLS(@"OkButton")  
											 alternateButton:TXTLS(@"CancelButton") 
												defaultInput:nil];
	
	[self.iomt __onWantHostServVhostSet:sender andVhost:vhost];
}

- (void)showSetVhostPrompt:(id)sender
{
	[self.invokeInBackgroundThread _onWantHostServVhostSet:sender];
}

- (void)showChannelBanList:(id)sender
{
	IRCChannel *c = [self.world selectedChannel];
	
	if (_noChannel || _isClient || _isQuery) return;
	
	[[self.world selectedClient] createChanBanListDialog];
	[[self.world selectedClient] send:IRCPrivateCommandIndex("mode"), [c name], @"+b", nil];
}

- (void)showChannelBanExceptionList:(id)sender
{
	IRCChannel *c = [self.world selectedChannel];
	
	if (_noChannel || _isClient || _isQuery) return;
	
	[[self.world selectedClient] createChanBanExceptionListDialog];
	[[self.world selectedClient] send:IRCPrivateCommandIndex("mode"), [c name], @"+e", nil];
}

- (void)showChannelInviteExceptionList:(id)sender
{
	IRCChannel *c = [self.world selectedChannel];
	
	if (_noChannel || _isClient || _isQuery) return;
	
	[[self.world selectedClient] createChanInviteExceptionListDialog];
	[[self.world selectedClient] send:IRCPrivateCommandIndex("mode"), [c name], @"+I", nil];
}

- (void)openHelpMenuLinkItem:(id)sender
{
	switch ([sender tag]) {
		case 101: [_NSWorkspace() openURL:[NSURL URLWithString:@"https://wiki.github.com/codeux/Textual/"]]; break;
		case 103: [_NSWorkspace() openURL:[NSURL URLWithString:@"https://wiki.github.com/codeux/Textual/text-formatting"]]; break;
		case 104: [_NSWorkspace() openURL:[NSURL URLWithString:@"https://wiki.github.com/codeux/Textual/command-reference"]]; break;
		case 105: [_NSWorkspace() openURL:[NSURL URLWithString:@"https://wiki.github.com/codeux/Textual/memory-management"]]; break;
		case 106: [_NSWorkspace() openURL:[NSURL URLWithString:@"https://wiki.github.com/codeux/Textual/styles"]]; break;
		case 108: [_NSWorkspace() openURL:[NSURL URLWithString:@"https://wiki.github.com/codeux/Textual/feature-requests"]]; break;
	}
}

- (void)processNavigationItem:(NSMenuItem *)sender
{
	switch ([sender tag]) {
		case 50001: [self.master selectNextServer:nil]; break;
		case 50002: [self.master selectPreviousServer:nil]; break;
		case 50003: [self.master selectNextActiveServer:nil]; break;
		case 50004: [self.master selectPreviousActiveServer:nil]; break;
		case 50005: [self.master selectNextChannel:nil]; break;
		case 50006: [self.master selectPreviousChannel:nil]; break;
		case 50007: [self.master selectNextActiveChannel:nil]; break;
		case 50008: [self.master selectPreviousActiveChannel:nil]; break;
		case 50009: [self.master selectNextUnreadChannel:nil]; break;
		case 50010: [self.master selectPreviousUnreadChannel:nil]; break;
		case 50011: [self.master selectPreviousSelection:nil]; break;
		case 50012: [self.master selectNextSelection:nil]; break;
	}
}

- (void)showMainWindow:(id)sender 
{
	[self.window makeKeyAndOrderFront:nil];
}

- (void)toggleFullscreenMode:(id)sender
{
#ifdef TXMacOSLionOrNewer
	if ([TPCPreferences featureAvailableToOSXLion]) {
		if (self.isInFullScreenMode) {
			[self.window toggleFullScreen:sender];
			
			[self.master loadWindowState:NO];
		} else {
			[self.master saveWindowState];
			
			[self.window toggleFullScreen:sender];
		}
	} else {
#endif
		
		if (self.isInFullScreenMode == NO) {
			[self.master saveWindowState];
			
			[NSApp setPresentationOptions:(NSApplicationPresentationHideDock | NSApplicationPresentationAutoHideMenuBar)];
			
			[[self.window standardWindowButton:NSWindowZoomButton] setHidden:YES];
			[[self.window standardWindowButton:NSWindowCloseButton] setHidden:YES];
			[[self.window standardWindowButton:NSWindowMiniaturizeButton] setHidden:YES];
			
			[self.window setShowsResizeIndicator:NO];
			
			[self.window setFrame:[self.window frameRectForContentRect:[[self.window screen] frame]]
						  display:YES animate:YES];
		} else {
			[[self.window standardWindowButton:NSWindowZoomButton] setHidden:NO];
			[[self.window standardWindowButton:NSWindowCloseButton] setHidden:NO];
			[[self.window standardWindowButton:NSWindowMiniaturizeButton] setHidden:NO];
			
			[self.window setShowsResizeIndicator:YES];
			[self.master loadWindowState:NO];
			
			[NSApp setPresentationOptions:NSApplicationPresentationDefault];
		}
		
#ifdef TXMacOSLionOrNewer
	}
#endif
	
	self.isInFullScreenMode = BOOLReverseValue(self.isInFullScreenMode);
}

- (void)sortChannelListNames:(id)sender
{
	for (IRCClient *u in [self.world clients]) {
		NSArray *clientChannels = [u.channels sortedArrayUsingFunction:channelDataSort context:nil];
		
		[u.channels removeAllObjects];
		
		for (IRCChannel *c in clientChannels) {
			[u.channels safeAddObject:c];
		}
		
		[u updateConfig:[u storedConfig]];
	}
	
	[self.world save];
}

- (void)forceReloadTheme:(id)sender
{
	[_NSNotificationCenter() postNotificationName:TXThemePreferenceChangedNotification object:nil userInfo:nil];
}

- (void)toggleChannelModerationMode:(id)sender
{
	IRCChannel *c = [self.world selectedChannel];
	
	if (_noChannel || _isClient || _isQuery) return;
	
	[[self.world selectedClient] sendCommand:[NSString stringWithFormat:@"%@ %@ %@",
											  IRCPublicCommandIndex("mode"), [c name], (([sender tag] == 1) ? @"-m" : @"+m")]];
}

- (void)toggleChannelInviteMode:(id)sender
{
	IRCChannel *c = [self.world selectedChannel];
	
	if (_noChannel || _isClient || _isQuery) return;
	
	[[self.world selectedClient] sendCommand:[NSString stringWithFormat:@"%@ %@ %@",
											  IRCPublicCommandIndex("mode"), [c name], (([sender tag] == 1) ? @"-i" : @"+i")]];
}

- (void)toggleDeveloperMode:(id)sender
{
    if ([sender state] == NSOnState) {
        [_NSUserDefaults() setBool:NO forKey:TXDeveloperEnvironmentToken];
        
        [sender setState:NSOffState];
    } else {
        [_NSUserDefaults() setBool:YES forKey:TXDeveloperEnvironmentToken];
        
        [sender setState:NSOnState];
    }
}

- (void)loadExtensionsIntoMemory:(id)sender
{
	[NSBundle.invokeInBackgroundThread loadBundlesIntoMemory:self.world];
}

- (void)unloadExtensionsFromMemory:(id)sender
{
	[NSBundle.invokeInBackgroundThread deallocBundlesFromMemory:self.world];
}

- (void)resetDoNotAskMePopupWarnings:(id)sender
{
	NSDictionary *allSettings =	[_NSUserDefaults() dictionaryRepresentation];

	for (NSString *key in allSettings) {
		if ([key hasPrefix:TXPopupPromptSuppressionPrefix]) {
			[_NSUserDefaults() setBool:NO forKey:key];
		}
	}
}

- (void)onNextHighlight:(id)sender
{
	[self.world.selected.log nextHighlight];
}

- (void)onPreviousHighlight:(id)sender
{
	[self.world.selected.log previousHighlight];
}

@end
