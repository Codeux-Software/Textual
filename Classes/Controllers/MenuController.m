// Created by Satoshi Nakagawa <psychs AT limechat DOT net> <http://github.com/psychs/limechat>
// Modifications by Codeux Software <support AT codeux DOT com> <https://github.com/codeux/Textual>
// You can redistribute it and/or modify it under the new BSD license.

#define	NO_CLIENT_OR_CHANNEL	(PointerIsEmpty(u) || PointerIsEmpty(c))
#define CONNECTED				(u && u.isConnected)
#define NOT_CONNECTED			(u && u.isConnected == NO)
#define LOGIN                   (u && u.isLoggedIn)
#define ACTIVE                  (LOGIN && c && c.isActive)
#define NOT_ACTIVE              (LOGIN && c && c.isActive == NO)
#define ACTIVE_CHANNEL			(ACTIVE && c.isChannel)
#define ACTIVE_CHANTALK			(ACTIVE && (c.isChannel || c.isTalk))
#define LOGIN_CHANTALK			(LOGIN && (PointerIsEmpty(c) || c.isChannel || c.isTalk))
#define IS_NOT_CHANNEL          (c.isChannel == NO)
#define IS_NOT_CLIENT           (c.isClient == NO)

#define MAXIMUM_SETS_PER_MODE	10

@interface MenuController (Private)
- (LogView *)currentWebView;

- (BOOL)checkSelectedMembers:(NSMenuItem *)item;
- (NSArray *)selectedMembers:(NSMenuItem *)sender;
- (void)deselectMembers:(NSMenuItem *)sender;
@end

@implementation MenuController

@synthesize aboutPanel;
@synthesize channelSheet;
@synthesize closeWindowItem;
@synthesize currentSearchPhrase;
@synthesize inviteSheet;
@synthesize isInFullScreenMode;
@synthesize master;
@synthesize memberList;
@synthesize modeSheet;
@synthesize nickSheet;
@synthesize pointedAddress;
@synthesize pointedChannelName;
@synthesize pointedNick;
@synthesize pointedUrl;
@synthesize preferencesController;
@synthesize serverSheet;
@synthesize text;
@synthesize topicSheet;
@synthesize tree;
@synthesize window;
@synthesize world;

- (id)init
{
	if ((self = [super init])) {
		currentSearchPhrase = @"";
	}
	
	return self;
}

- (void)dealloc
{
	[aboutPanel release];
	[channelSheet release];
	[currentSearchPhrase release];
	[inviteSheet release];
	[modeSheet release];
	[nickSheet release];
	[pointedAddress release];
	[pointedChannelName release];
	[pointedNick release];
	[pointedUrl release];
	[preferencesController release];
	[serverSheet release];
	[topicSheet release];	
	
	[super dealloc];
}

- (void)terminate
{
	if (serverSheet) [serverSheet close];
	if (channelSheet) [channelSheet close];
	if (preferencesController) [preferencesController close];
}

- (void)validateChannelMenuSubmenus:(NSMenuItem *)item
{
	IRCChannel *c = [world selectedChannel];
	
	if (c.isClient == NO && c.isTalk == NO && c.isChannel == YES) {
		[[[item menu] itemWithTag:936] setHidden:NO];
		[[[item menu] itemWithTag:937] setHidden:NO];
		
		[[[item menu] itemWithTag:5422] setHidden:NO];
		[[[item menu] itemWithTag:5422] setEnabled:YES];
		
		[[[[[item menu] itemWithTag:5422] submenu] itemWithTag:542] setEnabled:(c.isChannel && [Preferences logTranscript])];
	} else {
		[[[item menu] itemWithTag:936] setHidden:!c.isTalk];
		[[[item menu] itemWithTag:937] setHidden:!c.isTalk];
		
		[[[item menu] itemWithTag:5422] setEnabled:NO]; 
		[[[item menu] itemWithTag:5422] setHidden:YES]; 
	}	
}

- (BOOL)validateMenuItem:(NSMenuItem *)item
{
	IRCClient *u = [world selectedClient];
	IRCChannel *c = [world selectedChannel];
	
	NSInteger tag = item.tag;
	
	switch (tag) {
		case 313:	// paste
		{
			if ([[NSPasteboard generalPasteboard] hasStringContent] == NO) {
				return NO;
			}
			
			NSWindow *win = [NSApp keyWindow];
			if (PointerIsEmpty(win)) return NO;
			
			id t = [win firstResponder];
			if (PointerIsEmpty(t)) return NO;
			
			if (win == window) {
				return YES;
			} else if ([t respondsToSelector:@selector(paste:)]) {
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
			
			LogView *web = [self currentWebView];
			if (PointerIsEmpty(web)) return NO;
			
			return [web hasSelection];
			break;
		}
		case 501:	// connect
		{
			[item setHidden:BOOLReverseValue(NOT_CONNECTED)];
			
			return NOT_CONNECTED;
			break;
		}
		case 502:	// disconnect
		{
			BOOL condition = (u && (u.isConnected || u.isConnecting));
			
			[item setHidden:BOOLReverseValue(condition)];
			
			return condition;
			break;
		}
		case 503:	// cancel isReconnecting
		{
			BOOL condition = (u && u.isReconnecting);
			
			[item setHidden:BOOLReverseValue(condition)];
			
			return condition;
			break;
		}
		case 511:	// nick
		case 519:	// channel list
			return LOGIN;
			break;
		case 522:	// copy server
			return (u != nil);
			break;
		case 523:	// delete server
			return NOT_CONNECTED;
			break;
		case 541:	// server property
			return (u != nil);
			break;
		case 592:	// textual logs
			return [Preferences logTranscript];
			break;
		case 601:	// join
			[self validateChannelMenuSubmenus:item];
			
			if (c.isTalk) {
				[item setHidden:YES];
				
				return NO;
			} else {
				BOOL condition = (LOGIN && NOT_ACTIVE && c.isChannel);
				
				[item setHidden:((LOGIN) ? BOOLReverseValue(condition) : NO)];
				
				return condition;
			}
			break;
		case 602:	// leave
			if (c.isTalk) {
				[item setHidden:YES];
				
				return NO;
			} else {
				[item setHidden:BOOLReverseValue(ACTIVE)];
				
				return ACTIVE;
			}
			
			break;
		case 611:	// mode
			return ACTIVE_CHANNEL;
			break;
		case 612:	// topic
			return ACTIVE_CHANNEL;
			break;
		case 651:	// add channel
			if (c.isTalk) {
				[item setHidden:YES];
				
				return NO;
			} else {
				[item setHidden:NO];
				
				return (u != nil);
			}
			
			break;
		case 652:	// delete channel
			if (c.isTalk) {
				[item setTitle:TXTLS(@"DELETE_QUERY_MENU_ITEM")];
				
				return YES;
			} else {
				[item setTitle:TXTLS(@"DELETE_CHANNEL_MENU_ITEM")];
				
				return c.isChannel;
			}
			
			break;
		case 691:	// add channel - server menu
			return (u != nil);
			break;
		case 2005:	// invite
		{
			if (LOGIN == NO || [self checkSelectedMembers:item] == NO) return NO;
			
			NSInteger count = 0;
			
			for (IRCChannel *e in u.channels) {
				if (e != c && e.isChannel) {
					++count;
				}
			}
			
			return (count > 0);
			break;
		}
		case 5421: // query logs
			if (c.isTalk) {
				[item setHidden:NO];
				
				[[[item menu] itemWithTag:935] setHidden:YES]; // Divider
				
				return ([Preferences logTranscript] && c.isTalk);
			} else {
				[item setHidden:YES];
				
				[[[item menu] itemWithTag:935] setHidden:NO]; // Divider
				
				return NO;
			}
			
			break;
		case 9631: // close window
		{
			if ([window isKeyWindow]) {
				IRCClient *u = [world selectedClient];
				IRCChannel *c = [world selectedChannel];
				
				if (PointerIsEmpty(u)) return NO;
				
				switch ([Preferences cmdWResponseType]) {
					case CMDWKEY_SHORTCUT_CLOSE:
						[item setTitle:TXTLS(@"CMDWKEY_SHORTCUT_CLOSE_WINDOW")];
						break;
					case CMDWKEY_SHORTCUT_PARTC:
					{
						if (c.isChannel == NO && c.isTalk == NO) {
							[item setTitle:TXTLS(@"CMDWKEY_SHORTCUT_CLOSE_WINDOW")];
							return NO;
						} else {
							if (c.isChannel) {
								[item setTitle:TXTLS(@"CMDWKEY_SHORTCUT_PART_CHANNEL")];
								
								if (c.isActive == NO) {
									return NO;
								}
							} else {
								[item setTitle:TXTLS(@"CMDWKEY_SHORTCUT_LEAVE_QUERY")];
							}
						}
						
						break;
					}
					case CMDWKEY_SHORTCUT_DISCT:
					{
						NSString *textc = ((PointerIsEmpty(u.config.server)) ? u.config.name : u.config.server);
						
						[item setTitle:[NSString stringWithFormat:TXTLS(@"CMDWKEY_SHORTCUT_DISCONNECT"), textc]];
						
						if (u.isConnected == NO) return NO;
						
						break;
					}
					case CMDWKEY_SHORTCUT_QUITA:
						[item setTitle:TXTLS(@"CMDWKEY_SHORTCUT_QUIT_APPLICATION")];
						break;
				}
			} else {
				[item setTitle:TXTLS(@"CMDWKEY_SHORTCUT_CLOSE_WINDOW")];
			}
			
			return YES;
		}
		default:
			return YES;
			break;
	}
	
	return YES;
}

- (void)_onWantFindPanel:(id)sender
{
	NSAutoreleasePool *pool = [NSAutoreleasePool new];
	
	NSString *newPhrase = [PopupPrompts dialogWindowWithInput:TXTLS(@"FIND_SEARCH_PHRASE_PROPMT_MESSAGE")
														title:TXTLS(@"FIND_SEARCH_PRHASE_PROMPT_TITLE")
												defaultButton:TXTLS(@"FIND_SEARCH_PHRASE_PROMPT_BUTTON")
											  alternateButton:TXTLS(@"CANCEL_BUTTON") 
												 defaultInput:currentSearchPhrase];
	
	if (PointerIsEmpty(newPhrase)) {
		[currentSearchPhrase release];
		currentSearchPhrase = @"";
	} else {
		if ([newPhrase isNotEqualTo:currentSearchPhrase]) {
			[currentSearchPhrase release];
			currentSearchPhrase = [newPhrase retain];
		}
	}
	
	[[[self currentWebView] invokeOnMainThread] searchFor:currentSearchPhrase 
												direction:YES 
											caseSensitive:NO 
													 wrap:YES];
	
	[pool release];
}

- (void)onWantFindPanel:(id)sender
{
	if ([sender tag] == 1 || PointerIsEmpty(currentSearchPhrase)) {
		[[self invokeInBackgroundThread] _onWantFindPanel:sender];
	} else {
		if ([sender tag] == 2) {
			[[self currentWebView] searchFor:currentSearchPhrase 
								   direction:YES 
							   caseSensitive:NO 
										wrap:YES];
		} else {
			[[self currentWebView] searchFor:currentSearchPhrase 
								   direction:NO 
							   caseSensitive:NO 
										wrap:YES];
		}
	}
}

#pragma mark -
#pragma mark Utilities

- (LogView *)currentWebView
{
	return world.selected.log.view;
}

- (BOOL)checkSelectedMembers:(NSMenuItem *)item
{
	return ([memberList countSelectedRows] > 0);
}

- (NSArray *)selectedMembers:(NSMenuItem *)sender
{
	IRCChannel *c = [world selectedChannel];
	
	if (PointerIsEmpty(c)) {
		return [NSArray array];
	} else {
		NSMutableArray *ary = [NSMutableArray array];
		NSIndexSet *indexes = [memberList selectedRowIndexes];
		
		for (NSUInteger i = [indexes firstIndex]; i != NSNotFound; i = [indexes indexGreaterThanIndex:i]) {
			IRCUser *m = [c memberAtIndex:i];
			
			[ary addObject:m];
		}
		
		if ([ary isEqualToArray:[NSMutableArray array]]) {
			IRCUser *m = [c findMember:pointedNick];
			
			if (m) {
				return [NSArray arrayWithObject:m];
			} else {
				return [NSArray array];
			}
		}
		
		return ary;
	}
}

- (void)deselectMembers:(NSMenuItem *)sender
{
	[memberList deselectAll:nil];
}

#pragma mark -
#pragma mark Menu Items

- (void)commandWShortcutUsed:(id)sender
{
	NSWindow *currentWindow = [NSApp keyWindow];
	
	if ([window isKeyWindow]) {
		switch ([Preferences cmdWResponseType]) {
			case CMDWKEY_SHORTCUT_CLOSE:
				[window close];
				break;
			case CMDWKEY_SHORTCUT_PARTC:
			{
				IRCClient *u = [world selectedClient];
				IRCChannel *c = [world selectedChannel];
				
				if (NO_CLIENT_OR_CHANNEL) return;
				
				if (c.isChannel && c.isActive) {
					[u partChannel:c];
				} else {
					if (c.isTalk) {
						[world destroyChannel:c];
					}
				}
				
				break;
			}
			case CMDWKEY_SHORTCUT_DISCT:
				[[world selectedClient] quit];
				break;
			case CMDWKEY_SHORTCUT_QUITA:
				[NSApp terminate:nil];
				break;
		}
	} else {
		[currentWindow performClose:nil];
	}
}

- (void)onPreferences:(id)sender
{
	if (PointerIsEmpty(preferencesController)) {
		preferencesController = [PreferencesController alloc];
		preferencesController.delegate = self;
		preferencesController.world = world;
		[preferencesController init];
	}
	
	[preferencesController show];
}

- (void)preferencesDialogWillClose:(PreferencesController *)sender
{
	[world preferencesChanged];
}

- (void)onCloseWindow:(id)sender
{
	[[NSApp keyWindow] performClose:nil];
}

- (void)onWantMainWindowCentered:(id)sender;
{
	[[NSApp mainWindow] exactlyCenterWindow];
}

- (void)onCloseCurrentPanel:(id)sender
{
	IRCChannel *c = [world selectedChannel];
	
	if (c) {
		[world destroyChannel:c];
		[world save];
	}
}

- (void)onShowAcknowledgments:(id)sender
{
	[_NSWorkspace() openURL:[NSURL fileURLWithPath:[[Preferences whereResourcePath] 
													stringByAppendingPathComponent:@"Acknowledgments.pdf"]]];
}

- (void)onPaste:(id)sender
{
	NSPasteboard *pb = [NSPasteboard generalPasteboard];
	if ([pb hasStringContent] == NO) return;
	
	NSWindow *win = [NSApp keyWindow];
	if (PointerIsEmpty(win)) return;
	
	id t = [win firstResponder];
	if (PointerIsEmpty(t)) return;
	
	if (win == window) {
		NSString *s = [pb stringContent];
		if (NSObjectIsEmpty(s)) return;
		
		if ([t isKindOfClass:[NSTextView class]] == NO) {
			[world focusInputText];
		}
		
		NSText *e = [win fieldEditor:NO forObject:text];
		
		[e paste:nil];
	} else {
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
}

- (void)onSearchWeb:(id)sender
{
	LogView *web = [self currentWebView];
	if (PointerIsEmpty(web)) return;
	
	NSString *s = [web selection];
	
	if (NSObjectIsNotEmpty(s)) {
		s = [s gtm_stringByEscapingForURLArgument];
		
		NSString *urlStr = [NSString stringWithFormat:@"http://www.google.com/search?ie=UTF-8&q=%@", s];
		
		[URLOpener open:[NSURL URLWithString:urlStr]];
	}
}

- (void)onCopyLogAsHtml:(id)sender
{
	IRCTreeItem *sel = world.selected;
	if (!sel) return;
	NSString *s = [sel.log.view contentString];
	[[NSPasteboard generalPasteboard] setStringContent:s];
}

- (void)onMarkScrollback:(id)sender
{
	IRCTreeItem *sel = world.selected;
	if (!sel) return;
	[sel.log mark];
}

- (void)onClearMark:(id)sender
{
	IRCTreeItem *sel = world.selected;
	if (!sel) return;
	[sel.log unmark];
}

- (void)onGoToMark:(id)sender
{
	IRCTreeItem *sel = world.selected;
	if (!sel) return;
	[sel.log goToMark];
}

- (void)onMarkAllAsRead:(id)sender
{
	[world markAllAsRead];
}

- (void)onMarkAllAsReadAndMarkAllScrollbacks:(id)sender
{
	[world markAllAsRead];
	[world markAllScrollbacks];
}

- (void)onConnect:(id)sender
{
	IRCClient *u = [world selectedClient];
	if (!u) return;
	[u connect];
}

- (void)onDisconnect:(id)sender
{
	IRCClient *u = [world selectedClient];
	if (!u) return;
	[u quit];
	[u cancelReconnect];
}

- (void)onCancelReconnecting:(id)sender
{
	IRCClient *u = [world selectedClient];
	if (!u) return;
	[u cancelReconnect];
}

- (void)onNick:(id)sender
{
	if (nickSheet) return;
	
	IRCClient *u = [world selectedClient];
	if (!u) return;
	
	nickSheet = [NickSheet new];
	nickSheet.delegate = self;
	nickSheet.window = window;
	nickSheet.uid = u.uid;
	[nickSheet start:u.myNick];
}

- (void)nickSheet:(NickSheet *)sender didInputNick:(NSString *)newNick
{
	NSInteger uid = sender.uid;
	IRCClient *u = [world findClientById:uid];
	if (!u) return;
	[u changeNick:newNick];
}

- (void)nickSheetWillClose:(NickSheet *)sender
{
	self.nickSheet = nil;
}

- (void)onChannelList:(id)sender
{
	IRCClient *u = [world selectedClient];
	if (!u) return;
	[u createChannelListDialog];
	[u send:IRCCI_LIST, nil];
}

- (void)onAddServer:(id)sender
{
	if (serverSheet) {
		[serverSheet show];
		return;
	}	
	
	ServerSheet *d = [[ServerSheet new] autorelease];
	d.delegate = self;
	d.window = window;
	d.config = [[IRCClientConfig new] autorelease];
	d.uid = -1;
	[d startWithIgnoreTab:NO];
	self.serverSheet = d;
}

- (void)onCopyServer:(id)sender
{
	IRCClient *u = [world selectedClient];
	if (!u) return;
	
	IRCClientConfig *config = u.storedConfig;
	config.name = [config.name stringByAppendingString:@"_"];
	config.guid = [NSString stringWithUUID];
	
	IRCClient *n = [world createClient:config reload:YES];
	[world expandClient:n];
	[world save];
}

- (void)onDeleteServer:(id)sender
{
	IRCClient *u = [world selectedClient];
	if (!u || u.isConnected) return;
	
	
	
	BOOL result = [PopupPrompts dialogWindowWithQuestion:TXTLS(@"WANT_SERVER_DELETE_MESSAGE")
												   title:TXTLS(@"WANT_SERVER_DELETE_TITLE")
										   defaultButton:TXTLS(@"OK_BUTTON") 
										 alternateButton:TXTLS(@"CANCEL_BUTTON")
										  suppressionKey:@"Preferences.prompts.delete_server"
										 suppressionText:nil];
	
	if (result == NO) {
		return;
	}
	
	[u.config destroyKeychains];
	
	[world destroyClient:u];
	[world save];
}

- (void)showServerPropertyDialog:(IRCClient *)u ignore:(BOOL)ignore
{
	if (!u) return;
	
	if (serverSheet) {
		[serverSheet show];
		return;
	}
	
	ServerSheet *d = [[ServerSheet new] autorelease];
	d.delegate = self;
	d.window = window;
	d.config = u.storedConfig;
	d.uid = u.uid;
	d.client = u;
	[d startWithIgnoreTab:ignore];
	self.serverSheet = d;
}

- (void)onServerProperties:(id)sender
{
	[self showServerPropertyDialog:[world selectedClient] ignore:NO];
}

- (void)ServerSheetOnOK:(ServerSheet *)sender
{
	if (sender.uid < 0) {
		[world createClient:sender.config reload:YES];
	} else {
		IRCClient *u = [world findClientById:sender.uid];
		if (!u) return;
		[u updateConfig:sender.config];
	}
	
	[world save];
}

- (void)ServerSheetWillClose:(ServerSheet *)sender
{
	self.serverSheet = nil;
}

- (void)onJoin:(id)sender
{
	IRCClient *u = [world selectedClient];
	IRCChannel *c = [world selectedChannel];
	if (!u || !c || !u.isLoggedIn || c.isActive || !c.isChannel) return;
	[u joinChannel:c];
}

- (void)onLeave:(id)sender
{
	IRCClient *u = [world selectedClient];
	IRCChannel *c = [world selectedChannel];
	if (!u || !c || !u.isLoggedIn || !c.isActive) return;
	if (c.isChannel) {
		[u partChannel:c];
	} else {
		[world destroyChannel:c];
	}
}

- (void)onTopic:(id)sender
{
	IRCClient *u = [world selectedClient];
	IRCChannel *c = [world selectedChannel];
	if (NO_CLIENT_OR_CHANNEL || IS_NOT_CHANNEL) return;
	
	TopicSheet *t = [TopicSheet new];
	t.delegate = self;
	t.window = window;
	t.uid = u.uid;
	t.cid = c.uid;
	[t start:c.topic];
	self.topicSheet = t;
}

- (void)topicSheet:(TopicSheet *)sender onOK:(NSString *)topic
{
	IRCChannel *c = [world findChannelByClientId:sender.uid channelId:sender.cid];
	IRCClient *u = c.client;
	if (NO_CLIENT_OR_CHANNEL || IS_NOT_CHANNEL) return;
	
	if ([u encryptOutgoingMessage:&topic channel:c] == YES) {
		[u send:IRCCI_TOPIC, c.name, topic, nil];
	}
}

- (void)topicSheetWillClose:(TopicSheet *)sender
{
	self.topicSheet = nil;
}

- (void)onMode:(id)sender
{
	IRCClient *u = [world selectedClient];
	IRCChannel *c = [world selectedChannel];
	if (NO_CLIENT_OR_CHANNEL || IS_NOT_CHANNEL) return;
	
	ModeSheet *m = [ModeSheet new];
	m.delegate = self;
	m.window = window;
	m.uid = u.uid;
	m.cid = c.uid;
	m.mode = [[c.mode mutableCopy] autorelease];
	m.channelName = c.name;
	self.modeSheet = m;
	[modeSheet start];
}

- (void)modeSheetOnOK:(ModeSheet *)sender
{
	IRCChannel *c = [world findChannelByClientId:sender.uid channelId:sender.cid];
	IRCClient *u = c.client;
	if (NO_CLIENT_OR_CHANNEL || IS_NOT_CHANNEL) return;
	
	NSString *changeStr = [c.mode getChangeCommand:sender.mode];
	if (changeStr.length) {
		NSString *line = [NSString stringWithFormat:@"%@ %@ %@", IRCCI_MODE, c.name, changeStr];
		[u sendLine:line];
	}
}

- (void)modeSheetWillClose:(ModeSheet *)sender
{
	self.modeSheet = nil;
}

- (void)onAddChannel:(id)sender
{
	if (channelSheet) {
		[channelSheet show];
		return;
	}
	
	IRCClient *u = [world selectedClient];
	if (!u) return;
	
	IRCChannel *c = [world selectedChannel];
	IRCChannelConfig *config;
	if (c && c.isChannel) {
		config = [[c.config mutableCopy] autorelease];
	} else {
		config = [[IRCChannelConfig new] autorelease];
	}
	config.name = @"";
	
	ChannelSheet *d = [[ChannelSheet new] autorelease];
	d.delegate = self;
	d.window = window;
	d.config = config;
	d.uid = u.uid;
	d.cid = -1;
	[d start];
	self.channelSheet = d;
}

- (void)onDeleteChannel:(id)sender
{
	IRCChannel *c = [world selectedChannel];
	if (!c) return;
	
	if ([c isChannel]) {
		BOOL result = [PopupPrompts dialogWindowWithQuestion:TXTLS(@"WANT_CHANNEL_DELETE_MESSAGE") 
													   title:TXTLS(@"WANT_CHANNEL_DELETE_TITLE") 
											   defaultButton:TXTLS(@"OK_BUTTON") 
											 alternateButton:TXTLS(@"CANCEL_BUTTON") 
											  suppressionKey:@"Preferences.prompts.delete_channel"
											 suppressionText:nil];
		
		if (result == NO) {
			return;
		}
	}
	
	[world destroyChannel:c];
	[world save];
}

- (void)onChannelProperties:(id)sender
{
	if (channelSheet) {
		[channelSheet show];
		return;
	}
	
	IRCClient *u = [world selectedClient];
	IRCChannel *c = [world selectedChannel];
	if (NO_CLIENT_OR_CHANNEL || IS_NOT_CHANNEL) return;
	
	ChannelSheet *d = [[ChannelSheet new] autorelease];
	d.delegate = self;
	d.window = window;
	d.config = [[c.config mutableCopy] autorelease];
	d.uid = u.uid;
	d.cid = c.uid;
	[d start];
	self.channelSheet = d;
	
}

- (void)ChannelSheetOnOK:(ChannelSheet *)sender
{
	if (sender.cid < 0) {
		IRCClient *u = [world findClientById:sender.uid];
		if (!u) return;
		[world createChannel:sender.config client:u reload:YES adjust:YES];
		[world expandClient:u];
		[world save];
	} else {
		IRCChannel *c = [world findChannelByClientId:sender.uid channelId:sender.cid];
		if (!c) return;
		
		if (NSObjectIsEmpty(c.config.encryptionKey) && NSObjectIsNotEmpty(sender.config.encryptionKey)) {
			[c.client printBoth:c type:LINE_TYPE_DEBUG text:TXTLS(@"BLOWFISH_ENCRYPTION_STARTED")];
		} else if (NSObjectIsNotEmpty(c.config.encryptionKey) && NSObjectIsEmpty(sender.config.encryptionKey)) {
			[c.client printBoth:c type:LINE_TYPE_DEBUG text:TXTLS(@"BLOWFISH_ENCRYPTION_STOPPED")];
		} else if (NSObjectIsNotEmpty(c.config.encryptionKey) && NSObjectIsNotEmpty(sender.config.encryptionKey)) {
			if ([c.config.encryptionKey isEqualToString:sender.config.encryptionKey] == NO) {
				[c.client printBoth:c type:LINE_TYPE_DEBUG text:TXTLS(@"BLOWFISH_ENCRYPTION_KEY_CHANGED")];
			}
		}
		
		[c updateConfig:sender.config];
	}
	
	[world save];
}

- (void)ChannelSheetWillClose:(ChannelSheet *)sender
{
	self.channelSheet = nil;
}

- (void)whoisSelectedMembers:(id)sender deselect:(BOOL)deselect
{
	IRCClient *u = [world selectedClient];
	if (!u) return;
	
	NSArray *nicknames = [self selectedMembers:sender];
	
	if (pointedNick && [nicknames isEqual:[NSArray array]]) {
		[u sendWhois:pointedNick];
	} else {
		for (IRCUser *m in nicknames) {
			[u sendWhois:m.nick];
		}
	}
	
	if (deselect) {
		[self deselectMembers:sender];
	}
	
	pointedNick = nil;
}

- (void)memberListDoubleClicked:(id)sender
{
	MemberListView *view = sender;
	NSPoint pt = [window mouseLocationOutsideOfEventStream];
	pt = [view convertPoint:pt fromView:nil];
	NSInteger n = [view rowAtPoint:pt];
	if (n >= 0) {
		if ([[view selectedRowIndexes] count] > 0) {
			[view selectItemAtIndex:n];
		}
		
		switch ([Preferences userDoubleClickOption]) {
			case USERDC_ACTION_WHOIS: 
				[self whoisSelectedMembers:nil deselect:NO];
				break;
			case USERDC_ACTION_QUERY: 
				[self onMemberTalk:nil];
				break;
		}
	}
}

- (void)onMemberWhois:(id)sender
{
	[self whoisSelectedMembers:sender deselect:YES];
}

- (void)onMemberTalk:(id)sender
{
	IRCClient *u = [world selectedClient];
	if (!u) return;
	
	for (IRCUser *m in [self selectedMembers:sender]) {
		IRCChannel *c = [u findChannel:m.nick];
		if (!c) {
			c = [world createTalk:m.nick client:u];
		}
		[world select:c];
	}
	
	[self deselectMembers:sender];
}

- (void)onMemberInvite:(id)sender
{
	if (inviteSheet) return;
	
	IRCClient *u = [world selectedClient];
	IRCChannel *c = [world selectedChannel];
	if (!u || !u.isLoggedIn || !c) return;
	
	NSMutableArray *nicks = [NSMutableArray array];
	for (IRCUser *m in [self selectedMembers:sender]) {
		[nicks addObject:m.nick];
	}
	
	NSMutableArray *channels = [NSMutableArray array];
	for (IRCChannel *e in u.channels) {
		if (c != e && e.isChannel) {
			[channels addObject:e.name];
		}
	}
	
	if (!channels.count) return;
	
	inviteSheet = [InviteSheet new];
	inviteSheet.delegate = self;
	inviteSheet.window = window;
	inviteSheet.nicks = nicks;
	inviteSheet.uid = u.uid;
	[inviteSheet startWithChannels:channels];
}

- (void)inviteSheet:(InviteSheet *)sender onSelectChannel:(NSString *)channelName
{
	IRCClient *u = [world findClientById:sender.uid];
	if (!u) return;
	
	for (NSString *nick in sender.nicks) {
		[u send:IRCCI_INVITE, nick, channelName, nil];
	}
}

- (void)inviteSheetWillClose:(InviteSheet *)sender
{
	self.inviteSheet = nil;
}

- (void)onMemberPing:(id)sender
{
	IRCClient *u = [world selectedClient];
	if (!u) return;
	
	for (IRCUser *m in [self selectedMembers:sender]) {
		[u sendCTCPPing:m.nick];
	}
	
	[self deselectMembers:sender];
}

- (void)onMemberTime:(id)sender
{
	IRCClient *u = [world selectedClient];
	if (!u) return;
	
	for (IRCUser *m in [self selectedMembers:sender]) {
		[u sendCTCPQuery:m.nick command:IRCCI_TIME text:nil];
	}
	
	[self deselectMembers:sender];
}

- (void)onMemberVersion:(id)sender
{
	IRCClient *u = [world selectedClient];
	if (!u) return;
	
	for (IRCUser *m in [self selectedMembers:sender]) {
		[u sendCTCPQuery:m.nick command:IRCCI_VERSION text:nil];
	}
	
	[self deselectMembers:sender];
}

- (void)onMemberUserInfo:(id)sender
{
	IRCClient *u = [world selectedClient];
	if (!u) return;
	
	for (IRCUser *m in [self selectedMembers:sender]) {
		[u sendCTCPQuery:m.nick command:IRCCI_USERINFO text:nil];
	}
	
	[self deselectMembers:sender];
}

- (void)onMemberClientInfo:(id)sender
{
	IRCClient *u = [world selectedClient];
	if (!u) return;
	
	for (IRCUser *m in [self selectedMembers:sender]) {
		[u sendCTCPQuery:m.nick command:IRCCI_CLIENTINFO text:nil];
	}
	
	[self deselectMembers:sender];
}

- (void)onCopyUrl:(id)sender
{
	if (!pointedUrl) return;
	[[NSPasteboard generalPasteboard] setStringContent:pointedUrl];
	self.pointedUrl = nil;
}

- (void)onJoinChannel:(id)sender
{
	if (!pointedChannelName) return;
	IRCClient *u = [world selectedClient];
	if (!u || !u.isLoggedIn) return;
	[u send:IRCCI_JOIN, pointedChannelName, nil];
}

- (void)onCopyAddress:(id)sender
{
	if (!pointedAddress) return;
	[[NSPasteboard generalPasteboard] setStringContent:pointedAddress];
	self.pointedAddress = nil;
}

- (void)onWantChannelListSorted:(id)sender
{
	for (IRCClient *u in [world clients]) {
		NSArray *clientChannels = [[[[NSArray arrayWithArray:u.channels] sortedArrayUsingFunction:channelDataSort context:nil] mutableCopy] autorelease];
		
		[u.channels removeAllObjects];
		
		for (IRCChannel *c in clientChannels) {
			[u.channels addObject:c];
		}
		
		[u updateConfig:[u storedConfig]];
		[u.world save];
	}
}

- (void)onWantMainWindowShown:(id)sender 
{
	[window makeKeyAndOrderFront:nil];
}

- (void)onWantIgnoreListShown:(id)sender
{
	[self showServerPropertyDialog:[world selectedClient] ignore:YES];
}

- (void)wantsFullScreenModeToggled:(id)sender
{
	if (isInFullScreenMode == NO) {
		[master saveWindowState];
		[NSApp setPresentationOptions:(NSApplicationPresentationHideDock | NSApplicationPresentationAutoHideMenuBar)];
		[[window standardWindowButton:NSWindowZoomButton] setHidden:YES];
		[[window standardWindowButton:NSWindowCloseButton] setHidden:YES];
		[[window standardWindowButton:NSWindowMiniaturizeButton] setHidden:YES];
		[window setFrame:[window frameRectForContentRect:[[window screen] frame]] display:YES animate:YES];
	} else {
		[[window standardWindowButton:NSWindowZoomButton] setHidden:NO];
		[[window standardWindowButton:NSWindowCloseButton] setHidden:NO];
		[[window standardWindowButton:NSWindowMiniaturizeButton] setHidden:NO];
		[master loadWindowState];
		[NSApp setPresentationOptions:NSApplicationPresentationDefault];
	}
	
	isInFullScreenMode = BOOLReverseValue(isInFullScreenMode);
}

- (void)onWantAboutWindowShown:(id)sender
{
	if (aboutPanel) {
		[aboutPanel show];
		return;
	}
	aboutPanel = [AboutPanel new];
	aboutPanel.delegate = self;
	[aboutPanel show];
}

- (void)aboutPanelWillClose:(AboutPanel *)sender
{
	self.aboutPanel = nil;
}

- (void)processModeChange:(id)sender mode:(NSString *)tmode 
{
	IRCClient *u = [world selectedClient];
	IRCChannel *c = [world selectedChannel];
	
	if (!u || !c.isChannel) return;
	
	NSArray *nicknames = [self selectedMembers:sender];
	
	if (pointedNick && [nicknames isEqual:[NSArray array]]) {
		IRCUser *us = [c findMember:pointedNick];
		
		if (us) {
			[u sendCommand:[NSString stringWithFormat:@"%@ %@", tmode, us.nick] completeTarget:YES target:c.name];
		}
	} else {
		NSString *opString = @"";
		NSInteger currentIndex = 0;
		
		for (IRCUser *m in nicknames) {
			opString = [opString stringByAppendingFormat:@"%@ ", m.nick];
			
			currentIndex++;
			
			if (currentIndex == MAXIMUM_SETS_PER_MODE) {
				[u sendCommand:[NSString stringWithFormat:@"%@ %@", tmode, opString] completeTarget:YES target:c.name];
				currentIndex = 0;
				opString = @"";
			}
		}
		
		if (opString) {	
			[u sendCommand:[NSString stringWithFormat:@"%@ %@", tmode, opString] completeTarget:YES target:c.name];
		}
		
		[self deselectMembers:sender];
	}
	
	pointedNick = nil;
}

- (void)onMemberOp:(id)sender { [self processModeChange:sender mode:@"OP"]; }
- (void)onMemberDeOp:(id)sender { [self processModeChange:sender mode:@"DEOP"]; }
- (void)onMemberHalfOp:(id)sender { [self processModeChange:sender mode:@"HALFOP"]; }
- (void)onMemberDeHalfOp:(id)sender { [self processModeChange:sender mode:@"DEHALFOP"]; }
- (void)onMemberVoice:(id)sender { [self processModeChange:sender mode:@"VOICE"]; }
- (void)onMemberDeVoice:(id)sender { [self processModeChange:sender mode:@"DEVOICE"]; }

- (void)onMemberKick:(id)sender
{
	IRCClient *u = [world selectedClient];
	IRCChannel *c = [world selectedChannel];
	
	if (!u || !c.isChannel) return;
	
	NSArray *nicknames = [self selectedMembers:sender];
	
	if (pointedNick && [nicknames isEqual:[NSArray array]]) {
		IRCUser *us = [c findMember:pointedNick];
		
		if (us) {
			[u kick:c target:us.nick];
		}
	} else {
		for (IRCUser *m in nicknames) {
			[u kick:c target:m.nick];
		}
		
		[self deselectMembers:sender];
	}
	
	pointedNick = nil;
}

- (void)onMemberBan:(id)sender
{
	IRCClient *u = [world selectedClient];
	IRCChannel *c = [world selectedChannel];
	
	if (!u || !c.isChannel) return;
	
	NSArray *nicknames = [self selectedMembers:sender];
	
	if (pointedNick && [nicknames isEqual:[NSArray array]]) {
		IRCUser *us = [c findMember:pointedNick];
		
		if (us) {
			[u sendCommand:[NSString stringWithFormat:@"BAN %@", us.nick] completeTarget:YES target:c.name];
		}
	} else {
		for (IRCUser *m in nicknames) {
			[u sendCommand:[NSString stringWithFormat:@"BAN %@", m.nick] completeTarget:YES target:c.name];
		}
		
		[self deselectMembers:sender];
	}
	
	pointedNick = nil;
}

- (void)onMemberBanKick:(id)sender
{
	IRCClient *u = [world selectedClient];
	IRCChannel *c = [world selectedChannel];
	
	if (!u || !c.isChannel) return;
	
	NSArray *nicknames = [self selectedMembers:sender];
	
	if (pointedNick && [nicknames isEqual:[NSArray array]]) {
		IRCUser *us = [c findMember:pointedNick];
		
		if (us) {
			[u sendCommand:[NSString stringWithFormat:@"KICKBAN %@ %@", us.nick, [Preferences defaultKickMessage]] completeTarget:YES target:c.name];
		}
	} else {
		for (IRCUser *m in nicknames) {
			[u sendCommand:[NSString stringWithFormat:@"KICKBAN %@ %@", m.nick, [Preferences defaultKickMessage]] completeTarget:YES target:c.name];
		}
		
		[self deselectMembers:sender];
	}
	
	pointedNick = nil;
}

- (void)onMemberKill:(id)sender
{
	IRCClient *u = [world selectedClient];
	IRCChannel *c = [world selectedChannel];
	
	if (!u || !c.isChannel) return;
	
	NSArray *nicknames = [self selectedMembers:sender];
	
	if (pointedNick && [nicknames isEqual:[NSArray array]]) {
		[u sendCommand:[NSString stringWithFormat:@"KILL %@ %@", pointedNick, [Preferences IRCopDefaultKillMessage]] completeTarget:NO target:nil];
	} else {
		for (IRCUser *m in nicknames) {
			[u sendCommand:[NSString stringWithFormat:@"KILL %@ %@", m.nick, [Preferences IRCopDefaultKillMessage]] completeTarget:NO target:nil];
		}
		
		[self deselectMembers:sender];
	}
	
	pointedNick = nil;
}

- (void)onMemberGline:(id)sender
{
	IRCClient *u = [world selectedClient];
	IRCChannel *c = [world selectedChannel];
	
	if (!u || !c.isChannel) return;
	
	NSArray *nicknames = [self selectedMembers:sender];
	
	if (pointedNick && [nicknames isEqual:[NSArray array]]) {
		[u sendCommand:[NSString stringWithFormat:@"GLINE %@ %@", pointedNick, [Preferences IRCopDefaultGlineMessage]] completeTarget:NO target:nil];
	} else {
		for (IRCUser *m in nicknames) {
			[u sendCommand:[NSString stringWithFormat:@"GLINE %@ %@", m.nick, [Preferences IRCopDefaultGlineMessage]] completeTarget:NO target:nil];
		}
		
		[self deselectMembers:sender];
	}
	
	pointedNick = nil;
}

- (void)onMemberShun:(id)sender
{
	IRCClient *u = [world selectedClient];
	IRCChannel *c = [world selectedChannel];
	
	if (!u || !c.isChannel) return;
	
	NSArray *nicknames = [self selectedMembers:sender];
	
	if (pointedNick && [nicknames isEqual:[NSArray array]]) {
		[u sendCommand:[NSString stringWithFormat:@"SHUN %@ %@", pointedNick, [Preferences IRCopDefaultShunMessage]] completeTarget:NO target:nil];
	} else {
		for (IRCUser *m in nicknames) {
			[u sendCommand:[NSString stringWithFormat:@"SHUN %@ %@", m.nick, [Preferences IRCopDefaultShunMessage]] completeTarget:NO target:nil];
		}
		
		[self deselectMembers:sender];
	}
	
	pointedNick = nil;
}

- (void)onWantToReadTextualLogs:(id)sender
{	
	NSString *path = [[Preferences transcriptFolder] stringByExpandingTildeInPath];
	
	if ([_NSFileManager() fileExistsAtPath:path]) {
		[_NSWorkspace() openURL:[NSURL fileURLWithPath:path]];
	} else {
		NSRunAlertPanel(TXTLS(@"LOG_PATH_DOESNT_EXIST_TITLE"), TXTLS(@"LOG_PATH_DOESNT_EXIST_MESSAGE"), TXTLS(@"OK_BUTTON"), nil, nil);	
	}
}

- (void)onWantToReadChannelLogs:(id)sender;
{
	IRCClient *u = [world selectedClient];
	IRCChannel *c = [world selectedChannel];
	if (NO_CLIENT_OR_CHANNEL || IS_NOT_CHANNEL) return;
	
	NSString *path = [[Preferences transcriptFolder] stringByExpandingTildeInPath];
	path = [path stringByAppendingPathComponent:[NSString stringWithFormat:@"/%@/%@/%@/", u.name, ((c.isTalk) ? @"Queries" : @"Channels"), c.name]];
	
	if ([_NSFileManager() fileExistsAtPath:path]) {
		[_NSWorkspace() openURL:[NSURL fileURLWithPath:path]];
	} else {
		NSRunAlertPanel(TXTLS(@"LOG_PATH_DOESNT_EXIST_TITLE"), TXTLS(@"LOG_PATH_DOESNT_EXIST_MESSAGE"), TXTLS(@"OK_BUTTON"), nil, nil);	
	}
}

- (void)onWantTextualConnnectToHelp:(id)sender 
{
	[world createConnection:@"irc.wyldryde.org +6697" chan:@"#textual"];
}

- (void)__onWantHostServVhostSet:(id)sender andVhost:(NSString *)vhost
{
	if ([vhost length] >= 1 && vhost != nil) {
		IRCClient *u = [world selectedClient];
		IRCChannel *c = [world selectedChannel];
		
		if (!u || !c.isChannel) return;
		
		NSArray *nicknames = [self selectedMembers:sender];
		
		if (pointedNick && [nicknames isEqual:[NSArray array]]) {
			[u sendCommand:[NSString stringWithFormat:@"hs setall %@ %@", pointedNick, vhost] completeTarget:NO target:nil];
		} else {
			for (IRCUser *m in nicknames) {
				[u sendCommand:[NSString stringWithFormat:@"hs setall %@ %@", m.nick, vhost] completeTarget:NO target:nil];
			}
			
			[self deselectMembers:sender];
		}
	}
	
	pointedNick = nil;	
}

- (void)_onWantHostServVhostSet:(id)sender
{
	NSAutoreleasePool *pool = [NSAutoreleasePool new];
	
	NSString *vhost = [PopupPrompts dialogWindowWithInput:TXTLS(@"WANT_SERVER_DELETE_MESSAGE")
													title:TXTLS(@"WANT_SERVER_DELETE_TITLE") 
											defaultButton:TXTLS(@"OK_BUTTON")  
										  alternateButton:TXTLS(@"CANCEL_BUTTON") 
											 defaultInput:nil];
	
	[[self invokeOnMainThread] __onWantHostServVhostSet:sender andVhost:vhost];
	
	[pool release];
}

- (void)onWantHostServVhostSet:(id)sender
{
	[[self invokeInBackgroundThread] _onWantHostServVhostSet:sender];
}

- (void)onWantChannelBanList:(id)sender
{
	[[world selectedClient] createChanBanListDialog];
	[[world selectedClient] send:IRCCI_MODE, [[world selectedChannel] name], @"+b", nil];
}

- (void)onWantChannelBanExceptionList:(id)sender
{
	[[world selectedClient] createChanBanExceptionListDialog];
	[[world selectedClient] send:IRCCI_MODE, [[world selectedChannel] name], @"+e", nil];
}

- (void)openHelpMenuLinkItem:(id)sender
{
	switch ([sender tag]) {
		case 101:
			[_NSWorkspace() openURL:[NSURL URLWithString:@"https://wiki.github.com/codeux/Textual/"]];
			break;
		case 103:
			[_NSWorkspace() openURL:[NSURL URLWithString:@"https://wiki.github.com/codeux/Textual/text-formatting"]];
			break;
		case 104:
			[_NSWorkspace() openURL:[NSURL URLWithString:@"https://wiki.github.com/codeux/Textual/command-reference"]];
			break;
		case 105:
			[_NSWorkspace() openURL:[NSURL URLWithString:@"https://wiki.github.com/codeux/Textual/memory-management"]];
			break;
		case 106:
			[_NSWorkspace() openURL:[NSURL URLWithString:@"https://wiki.github.com/codeux/Textual/styles"]];
			break;
		case 108:
			[_NSWorkspace() openURL:[NSURL URLWithString:@"https://wiki.github.com/codeux/Textual/feature-requests"]];
			break;
		case 110:
			[_NSWorkspace() openURL:[NSURL URLWithString:@"http://codeux.com/textual/forum/"]];
			break;
	}
}

- (void)processNavigationItem:(NSMenuItem *)sender
{
	switch ([sender tag]) {
		case 50001:
			[master selectNextServer:nil];
			break;
		case 50002:
			[master selectPreviousServer:nil];
			break;
		case 50003:
			[master selectNextActiveServer:nil];
			break;
		case 50004:
			[master selectPreviousActiveServer:nil];
			break;
		case 50005:
			[master selectNextChannel:nil];
			break;
		case 50006:
			[master selectPreviousChannel:nil];
			break;
		case 50007:
			[master selectNextActiveChannel:nil];
			break;
		case 50008:
			[master selectPreviousActiveChannel:nil];
			break;
		case 50009:
			[master selectNextUnreadChannel:nil];
			break;
		case 50010:
			[master selectPreviousUnreadChannel:nil];
			break;
		case 50011:
			[master selectPreviousSelection:nil];
			break;
		case 50012:
			[master selectNextSelection:nil];
			break;
	}
}

- (void)onWantThemeForceReloaded:(id)sender
{
	[_NSNotificationCenter() postNotificationName:ThemeDidChangeNotification object:nil userInfo:nil];
}

- (void)onWantChannelModerated:(id)sender
{
	if ([[world selectedChannel] isChannel] == NO) return;
	
	if ([sender tag] == 1) {
		[[world selectedClient] sendCommand:[NSString stringWithFormat:@"MODE %@ -m", [[world selectedChannel] name]]];
	} else {
		[[world selectedClient] sendCommand:[NSString stringWithFormat:@"MODE %@ +m", [[world selectedChannel] name]]];
	}
}

- (void)onWantChannelVoiceOnly:(id)sender
{
	if ([[world selectedChannel] isChannel] == NO) return;
	
	if ([sender tag] == 1) {
		[[world selectedClient] sendCommand:[NSString stringWithFormat:@"MODE %@ -i", [[world selectedChannel] name]]];
	} else {
		[[world selectedClient] sendCommand:[NSString stringWithFormat:@"MODE %@ +i", [[world selectedChannel] name]]];
	}
}

@end