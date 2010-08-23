// Created by Satoshi Nakagawa <psychs AT limechat DOT net> <http://github.com/psychs/limechat>
// Modifications by Michael Morris <mikey AT codeux DOT com> <http://github.com/mikemac11/Textual>
// You can redistribute it and/or modify it under the new BSD license.

#import "MenuController.h"
#import <WebKit/WebKit.h>
#import "Preferences.h"
#import "IRC.h"
#import "IRCWorld.h"
#import "IRCClient.h"
#import "IRCChannel.h"
#import "MemberListView.h"
#import "ServerSheet.h"
#import "ChannelSheet.h"
#import "URLOpener.h"
#import "GTMNSString+URLArguments.h"
#import "NSStringHelper.h"
#import "NSDictionaryHelper.h"
#import "IRCClientConfig.h"
#import "NSPasteboardHelper.h"
#import "AboutPanel.h"
#import "NSWindowHelper.h"
#import "MasterController.h"
#import "NSObject+DDExtensions.h"

#define CONNECTED				(u && u.isConnected)
#define NOT_CONNECTED			(u && !u.isConnected)
#define LOGIN                   (u && u.isLoggedIn)
#define ACTIVE                  (LOGIN && c && c.isActive)
#define NOT_ACTIVE              (LOGIN && c && !c.isActive)
#define ACTIVE_CHANNEL			(ACTIVE && c.isChannel)
#define ACTIVE_CHANTALK			(ACTIVE && (c.isChannel || c.isTalk))
#define LOGIN_CHANTALK			(LOGIN && (!c || c.isChannel || c.isTalk))
#define IS_NOT_CHANNEL          (!c.isChannel)
#define IS_NOT_CLIENT           (!c.isClient)

@interface MenuController (Private)
- (LogView*)currentWebView;
- (BOOL)checkSelectedMembers:(NSMenuItem*)item;
@end

@implementation MenuController

@synthesize world;
@synthesize window;
@synthesize text;
@synthesize tree;
@synthesize memberList;
@synthesize pointedUrl;
@synthesize pointedAddress;
@synthesize pointedNick;
@synthesize pointedChannelName;
@synthesize currentSearchPhrase;

- (id)init
{
	if (self = [super init]) {
		ServerSheets = [NSMutableArray new];
		ChannelSheets = [NSMutableArray new];
		
		currentSearchPhrase = @"";
	}
	return self;
}

- (void)dealloc
{
	[pointedUrl release];
	[pointedAddress release];
	[pointedNick release];
	[pointedChannelName release];
	
	[preferencesController release];
	[ServerSheets release];
	[ChannelSheets release];
	
	[currentSearchPhrase release];
	
	[nickSheet release];
	[modeSheet release];
	[aboutPanel release];
	[topicSheet release];
	[inviteSheet release];
	[fileSendPanel release];
	[fileSendTargets release];
	
	[super dealloc];
}

- (void)terminate
{
	for (ServerSheet* d in ServerSheets) {
		[d close];
	}
	for (ChannelSheet* d in ChannelSheets) {
		[d close];
	}
	if (preferencesController) {
		[preferencesController close];
	}
}

- (BOOL)isNickMenu:(NSMenuItem*)item
{
	if (!item) return NO;
	NSInteger tag = item.tag;
	return 2500 <= tag && tag < 3000;
}

- (void)processChannelBarDivider:(NSMenuItem*)item chan:(BOOL)ischan
{
	NSMenu *menu = [item menu];
	NSInteger nextid = ([[item menu] indexOfItem:item] + 1);
	
	if (ischan) {
		if (![[menu itemAtIndex:nextid] isSeparatorItem]) {
			[menu insertItem:[NSMenuItem separatorItem] atIndex:nextid];
		}
	} else {
		if ([[menu itemAtIndex:nextid] isSeparatorItem]) {
			[menu removeItemAtIndex:nextid];
		}
	}
}

- (BOOL)validateMenuItem:(NSMenuItem *)item
{
	IRCClient* u = world.selectedClient;
	IRCChannel* c = world.selectedChannel;
	
	NSInteger tag = item.tag;
	
	switch (tag) {
		case 313:	// paste
		{
			if (![[NSPasteboard generalPasteboard] hasStringContent]) {
				return NO;
			}
			NSWindow* win = [NSApp keyWindow];
			if (!win) return NO;
			id t = [win firstResponder];
			if (!t) return NO;
			if (win == window) {
				return YES;
			}
			else if ([t respondsToSelector:@selector(paste:)]) {
				if ([t respondsToSelector:@selector(validateMenuItem:)]) {
					return [t validateMenuItem:item];
				}
				return YES;
			}
			break;
		}
		case 331:	// search in google
		{
			LogView* web = [self currentWebView];
			if (!web) return NO;
			return [web hasSelection];
			break;
		}
		case 332:	// paste my address
		{
			if (![window isKeyWindow]) return NO;
			id t = [window firstResponder];
			if (!t) return NO;
			IRCClient* u = world.selectedClient;
			if (!u || !u.myAddress) return NO;
			return YES;
			break;
		}
		case 501:	// connect
			return NOT_CONNECTED;
			break;
		case 502:	// disconnect
			return u && (u.isConnected || u.isConnecting);
			break;
		case 503:	// cancel isReconnecting
			return u && u.isReconnecting;
			break;
		case 511:	// nick
		case 519:	// channel list
			return LOGIN;
			break;
		case 522:	// copy server
			return u != nil;
			break;
		case 523:	// delete server
			return NOT_CONNECTED;
			break;
		case 541:	// server property
			return u != nil;
			break;
		case 542:	// channel logs
			return ([Preferences logTranscript] && c.isChannel);
			break;
		case 592:	// textual logs
			return [Preferences logTranscript];
			break;
		case 601:	// join
			if (c.isTalk) {
				[item setHidden:YES];
				
				return NO;
			} else {
				[item setHidden:NO];
				
				return LOGIN && NOT_ACTIVE && c.isChannel;
			}
			break;
		case 602:	// leave
			if (c.isTalk) {
				[item setHidden:YES];
				[[[item menu] itemWithTag:935] setHidden:YES];
				
				return NO;
			} else {
				[item setHidden:NO];
				[[[item menu] itemWithTag:935] setHidden:NO];
				
				return ACTIVE;
			}
			break;
		case 611:	// mode
			return ACTIVE_CHANNEL;
			break;
		case 612:	// topic
			return ACTIVE_CHANNEL;
			break;
		case 691:	// add channel - server menu
			return u != nil;
			break;
		case 651:	// add channel
			if (c.isTalk) {
				[item setHidden:YES];
				
				return NO;
			} else {
				[item setHidden:NO];
				
				return u != nil;
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
		case 2005:	// invite
		{
			if (!LOGIN || ![self checkSelectedMembers:item]) return NO;
			NSInteger count = 0;
			for (IRCChannel* e in u.channels) {
				if (e != c && e.isChannel) {
					++count;
				}
			}
			return count > 0;
			break;
		}
		case 5421: // query logs
			if (c.isTalk) {
				[item setHidden:NO];
				[[[item menu] itemWithTag:5422] setHidden:YES];
				return ([Preferences logTranscript] && c.isTalk);
			} else {
				[[[item menu] itemWithTag:5422] setHidden:NO];
				[[[item menu] itemWithTag:5422] setEnabled:c.isChannel];
				[item setHidden:YES];
				return NO;
			}
			break;
		default:
			return YES;
			break;
	}
	
	return YES;
}

- (void)_onWantFindPanel:(id)sender
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	NSString *newPhrase = promptForInput(TXTLS(@"FIND_SEARCH_PHRASE_PROPMT_MESSAGE"), 
										 TXTLS(@"FIND_SEARCH_PRHASE_PROMPT_TITLE"), 
										 TXTLS(@"FIND_SEARCH_PHRASE_PROMPT_BUTTON"), 
										 nil, currentSearchPhrase);
	
	if (newPhrase == nil) {
		[currentSearchPhrase release];
		currentSearchPhrase = @"";
	} else {
		if ([newPhrase isNotEqualTo:currentSearchPhrase]) {
			[currentSearchPhrase release];
			currentSearchPhrase = [newPhrase retain];
		}
	}
	
	[[[self currentWebView] invokeOnMainThread] searchFor:currentSearchPhrase direction:YES caseSensitive:NO wrap:YES];
	
	[pool release];
}

- (void)onWantFindPanel:(id)sender
{
	if ([sender tag] == 1 || currentSearchPhrase == nil) {
		[self performSelectorInBackground:@selector(_onWantFindPanel:) withObject:sender];
	} else {
		if ([sender tag] == 2) {
			[[self currentWebView] searchFor:currentSearchPhrase direction:YES caseSensitive:NO wrap:YES];
		} else {
			[[self currentWebView] searchFor:currentSearchPhrase direction:NO caseSensitive:NO wrap:YES];
		}
	}
}

#pragma mark -
#pragma mark Utilities

- (LogView*)currentWebView
{
	return world.selected.log.view;
}

- (BOOL)checkSelectedMembers:(NSMenuItem*)item
{
	if ([self isNickMenu:item]) {
		return pointedNick != nil;
	} else {
		return [memberList countSelectedRows] > 0;
	}
}

- (NSArray*)selectedMembers:(NSMenuItem*)sender
{
	IRCChannel* c = world.selectedChannel;
	if (!c) {
		if ([self isNickMenu:sender]) {
			IRCUser* m = [[IRCUser new] autorelease];
			m.nick = pointedNick;
			return [NSArray arrayWithObject:m];
		} else {
			return [NSArray array];
		}
	} else {
		NSMutableArray* ary = [NSMutableArray array];
		NSIndexSet* indexes = [memberList selectedRowIndexes];
		for (NSUInteger i=[indexes firstIndex]; i!=NSNotFound; i=[indexes indexGreaterThanIndex:i]) {
			IRCUser* m = [c memberAtIndex:i];
			[ary addObject:m];
		}
		
		if ([ary isEqualToArray:[NSMutableArray array]]) {
			IRCUser* m = [c findMember:pointedNick];
			if (m) {
				return [NSArray arrayWithObject:m];
			} else {
				return [NSArray array];
			}
		}
		
		return ary;
	}
}

- (void)deselectMembers:(NSMenuItem*)sender
{
	if (![self isNickMenu:sender]) {
		[memberList deselectAll:nil];
	}
}

#pragma mark -
#pragma mark Menu Items

- (void)onPreferences:(id)sender
{
	if (!preferencesController) {
		preferencesController = [PreferencesController new];
		preferencesController.delegate = self;
		preferencesController.world = world;
	}
	[preferencesController show];
}

- (void)preferencesDialogWillClose:(PreferencesController*)sender
{
	[world preferencesChanged];
}

- (void)onDcc:(id)sender
{
	[world.dcc show:YES];
}

- (void)onCloseWindow:(id)sender
{
	[[NSApp keyWindow] performClose:nil];
}

- (void)onWantMainWindowCentered:(id)sender;
{
	[[NSApp mainWindow] centerWindow];
}

- (void)onCloseCurrentPanel:(id)sender
{
	IRCClient* u = world.selectedClient;
	IRCChannel* c = world.selectedChannel;
	if (u && c) {
		[world destroyChannel:c];
		[world save];
	}
}

- (void)onPaste:(id)sender
{
	NSPasteboard* pb = [NSPasteboard generalPasteboard];
	if (![pb hasStringContent]) return;
	
	NSWindow* win = [NSApp keyWindow];
	if (!win) return;
	id t = [win firstResponder];
	if (!t) return;
	
	if (win == window) {
		NSString* s = [pb stringContent];
		if (!s.length) return;
		
		if (![t isKindOfClass:[NSTextView class]]) {
			[world focusInputText];
		}
		NSText* e = [win fieldEditor:NO forObject:text];
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

- (void)onPasteMyAddress:(id)sender
{
	if (![window isKeyWindow]) return;
	
	id t = [window firstResponder];
	if (!t) return;
	
	IRCClient* u = world.selectedClient;
	if (!u || !u.myAddress) return;
	
	if (![t isKindOfClass:[NSTextView class]]) {
		[world focusInputText];
	}
	NSText* fe = [window fieldEditor:NO forObject:text];
	[fe replaceCharactersInRange:[fe selectedRange] withString:u.myAddress];
	[fe scrollRangeToVisible:[fe selectedRange]];
}

- (void)onSearchWeb:(id)sender
{
	LogView* web = [self currentWebView];
	if (!web) return;
	NSString* s = [web selection];
	if (s.length) {
		s = [s gtm_stringByEscapingForURLArgument];
		NSString* urlStr = [NSString stringWithFormat:@"http://www.google.com/search?ie=UTF-8&q=%@", s];
		[URLOpener open:[NSURL URLWithString:urlStr]];
	}
}

- (void)onCopyLogAsHtml:(id)sender
{
	IRCTreeItem* sel = world.selected;
	if (!sel) return;
	NSString* s = [sel.log.view contentString];
	[[NSPasteboard generalPasteboard] setStringContent:s];
}

- (void)onMarkScrollback:(id)sender
{
	IRCTreeItem* sel = world.selected;
	if (!sel) return;
	[sel.log mark];
}

- (void)onClearMark:(id)sender
{
	IRCTreeItem* sel = world.selected;
	if (!sel) return;
	[sel.log unmark];
}

- (void)onGoToMark:(id)sender
{
	IRCTreeItem* sel = world.selected;
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
	IRCClient* u = world.selectedClient;
	if (!u) return;
	[u connect];
}

- (void)onDisconnect:(id)sender
{
	IRCClient* u = world.selectedClient;
	if (!u) return;
	[u quit];
	[u cancelReconnect];
}

- (void)onCancelReconnecting:(id)sender
{
	IRCClient* u = world.selectedClient;
	if (!u) return;
	[u cancelReconnect];
}

- (void)onNick:(id)sender
{
	if (nickSheet) return;
	
	IRCClient* u = world.selectedClient;
	if (!u) return;
	
	nickSheet = [NickSheet new];
	nickSheet.delegate = self;
	nickSheet.window = window;
	nickSheet.uid = u.uid;
	[nickSheet start:u.myNick];
}

- (void)nickSheet:(NickSheet*)sender didInputNick:(NSString*)newNick
{
	NSInteger uid = sender.uid;
	IRCClient* u = [world findClientById:uid];
	if (!u) return;
	[u changeNick:newNick];
}

- (void)nickSheetWillClose:(NickSheet*)sender
{
	[nickSheet release];
	nickSheet = nil;
}

- (void)onChannelList:(id)sender
{
	IRCClient* u = world.selectedClient;
	if (!u) return;
	[u createChannelListDialog];
}

- (void)onAddServer:(id)sender
{
	ServerSheet* d = [[ServerSheet new] autorelease];
	d.delegate = self;
	d.window = window;
	d.config = [[IRCClientConfig new] autorelease];
	d.uid = -1;
	[ServerSheets addObject:d];
	[d startWithIgnoreTab:NO];
}

- (void)onCopyServer:(id)sender
{
	IRCClient* u = world.selectedClient;
	if (!u) return;
	
	IRCClientConfig* config = u.storedConfig;
	config.name = [config.name stringByAppendingString:@"_"];
	config.cuid = TXRandomThousandNumber();
	
	[config verifyKeychainsExistsOrAdd];
	
	IRCClient* n = [world createClient:config reload:YES];
	[world expandClient:n];
	[world save];
}

- (void)onDeleteServer:(id)sender
{
	IRCClient* u = world.selectedClient;
	if (!u || u.isConnected) return;
	
	BOOL result = promptWithSuppression(TXTLS(@"WANT_SERVER_DELETE_MESSAGE"), 
										TXTLS(@"WANT_SERVER_DELETE_TITLE"), 
										nil, nil, @"Preferences.prompts.delete_server", nil);
	
	if (result == NO) {
		return;
	}
	
	[u.config destroyKeychains];
	
	[world destroyClient:u];
	[world save];
}

- (void)showServerPropertyDialog:(IRCClient*)u ignore:(BOOL)ignore
{
	if (!u) return;
	
	if (u.propertyDialog) {
		[u.propertyDialog show];
		return;
	}
	
	ServerSheet* d = [[ServerSheet new] autorelease];
	d.delegate = self;
	d.window = window;
	d.config = u.storedConfig;
	d.uid = u.uid;
	d.client = u;
	[ServerSheets addObject:d];
	[d startWithIgnoreTab:ignore];
}

- (void)onServerProperties:(id)sender
{
	[self showServerPropertyDialog:world.selectedClient ignore:NO];
}

- (void)ServerSheetOnOK:(ServerSheet*)sender
{
	if (sender.uid < 0) {
		[world createClient:sender.config reload:YES];
	} else {
		IRCClient* u = [world findClientById:sender.uid];
		if (!u) return;
		[u updateConfig:sender.config];
	}
	[world save];
}

- (void)ServerSheetWillClose:(ServerSheet*)sender
{
	[ServerSheets removeObjectIdenticalTo:sender];
	
	IRCClient* u = world.selectedClient;
	if (!u) return;
	u.propertyDialog = nil;
}

- (void)onJoin:(id)sender
{
	IRCClient* u = world.selectedClient;
	IRCChannel* c = world.selectedChannel;
	if (!u || !c || !u.isLoggedIn || c.isActive || !c.isChannel) return;
	[u joinChannel:c];
}

- (void)onLeave:(id)sender
{
	IRCClient* u = world.selectedClient;
	IRCChannel* c = world.selectedChannel;
	if (!u || !c || !u.isLoggedIn || !c.isActive) return;
	if (c.isChannel) {
		[u partChannel:c];
	} else {
		[world destroyChannel:c];
	}
}

- (void)onTopic:(id)sender
{
	IRCClient* u = world.selectedClient;
	IRCChannel* c = world.selectedChannel;
	if (!u || !c) return;
	if (topicSheet) return;
	
	topicSheet = [TopicSheet new];
	topicSheet.delegate = self;
	topicSheet.window = window;
	topicSheet.uid = u.uid;
	topicSheet.cid = c.uid;
	[topicSheet start:c.topic];
}

- (void)topicSheet:(TopicSheet*)sender onOK:(NSString*)topic
{
	IRCClient* u = [world findClientById:sender.uid];
	IRCChannel* c = [world findChannelByClientId:sender.uid channelId:sender.cid];
	if (!u || !c) return;
	
	[u send:TOPIC, c.name, topic, nil];
}

- (void)topicSheetWillClose:(TopicSheet*)sender
{
	topicSheet = nil;
}

- (void)onMode:(id)sender
{
	IRCClient* u = world.selectedClient;
	IRCChannel* c = world.selectedChannel;
	if (!u || !c) return;
	if (modeSheet) return;
	
	modeSheet = [ModeSheet new];
	modeSheet.delegate = self;
	modeSheet.window = window;
	modeSheet.uid = u.uid;
	modeSheet.cid = c.uid;
	modeSheet.mode = [[c.mode mutableCopy] autorelease];
	modeSheet.channelName = c.name;
	[modeSheet start];
}

- (void)modeSheetOnOK:(ModeSheet*)sender
{
	IRCClient* u = [world findClientById:sender.uid];
	IRCChannel* c = [world findChannelByClientId:sender.uid channelId:sender.cid];
	if (!u || !c) return;
	
	NSString* changeStr = [c.mode getChangeCommand:sender.mode];
	if (changeStr.length) {
		NSString* line = [NSString stringWithFormat:@"%@ %@ %@", MODE, c.name, changeStr];
		[u sendLine:line];
	}
	
	modeSheet = nil;
}

- (void)modeSheetWillClose:(ModeSheet*)sender
{
	modeSheet = nil;
}

- (void)onAddChannel:(id)sender
{
	IRCClient* u = world.selectedClient;
	IRCChannel* c = world.selectedChannel;
	if (!u) return;
	
	IRCChannelConfig* config;
	if (c && c.isChannel) {
		config = [[c.config mutableCopy] autorelease];
	} else {
		config = [[IRCChannelConfig new] autorelease];
	}
	config.name = @"";
	
	ChannelSheet* d = [[ChannelSheet new] autorelease];
	d.delegate = self;
	d.window = window;
	d.config = config;
	d.uid = u.uid;
	d.cid = -1;
	[ChannelSheets addObject:d];
	[d start];
}

- (void)onDeleteChannel:(id)sender
{
	IRCChannel* c = world.selectedChannel;
	if (!c) return;
	
	if ([c isChannel]) {
		BOOL result = promptWithSuppression(TXTLS(@"WANT_CHANNEL_DELETE_MESSAGE"), 
											TXTLS(@"WANT_CHANNEL_DELETE_TITLE"), 
											nil, nil, @"Preferences.prompts.delete_channel", nil);
		
		if (result == NO) {
			return;
		}
	}
	
	[world destroyChannel:c];
	[world save];
}

- (void)onChannelProperties:(id)sender
{
	IRCClient* u = world.selectedClient;
	IRCChannel* c = world.selectedChannel;
	if (!u || !c) return;
	
	if (c.propertyDialog) {
		[c.propertyDialog show];
		return;
	}
	
	ChannelSheet* d = [[ChannelSheet new] autorelease];
	d.delegate = self;
	d.window = window;
	d.config = [[c.config mutableCopy] autorelease];
	d.uid = u.uid;
	d.cid = c.uid;
	[ChannelSheets addObject:d];
	[d start];
}

- (void)ChannelSheetOnOK:(ChannelSheet*)sender
{
	if (sender.cid < 0) {
		IRCClient* u = [world findClientById:sender.uid];
		if (!u) return;
		[world createChannel:sender.config client:u reload:YES adjust:YES];
		[world expandClient:u];
		[world save];
	} else {
		IRCChannel* c = [world findChannelByClientId:sender.uid channelId:sender.cid];
		if (!c) return;
		[c updateConfig:sender.config];
	}
	
	[world save];
}

- (void)ChannelSheetWillClose:(ChannelSheet*)sender
{
	if (sender.cid >= 0) {
		IRCChannel* c = [world findChannelByClientId:sender.uid channelId:sender.cid];
		c.propertyDialog = nil;
	}
	
	[ChannelSheets removeObjectIdenticalTo:sender];
}

- (void)whoisSelectedMembers:(id)sender deselect:(BOOL)deselect
{
	IRCClient* u = world.selectedClient;
	if (!u) return;
	
	NSArray *nicknames = [self selectedMembers:sender];
	
	if (pointedNick && [nicknames isEqual:[NSArray array]]) {
		[u sendWhois:pointedNick];
	} else {
		for (IRCUser* m in nicknames) {
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
	MemberListView* view = sender;
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
	IRCClient* u = world.selectedClient;
	if (!u) return;
	
	for (IRCUser* m in [self selectedMembers:sender]) {
		IRCChannel* c = [u findChannel:m.nick];
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
	
	IRCClient* u = world.selectedClient;
	IRCChannel* c = world.selectedChannel;
	if (!u || !u.isLoggedIn || !c) return;
	
	NSMutableArray* nicks = [NSMutableArray array];
	for (IRCUser* m in [self selectedMembers:sender]) {
		[nicks addObject:m.nick];
	}
	
	NSMutableArray* channels = [NSMutableArray array];
	for (IRCChannel* e in u.channels) {
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

- (void)inviteSheet:(InviteSheet*)sender onSelectChannel:(NSString*)channelName
{
	IRCClient* u = [world findClientById:sender.uid];
	if (!u) return;
	
	for (NSString* nick in sender.nicks) {
		[u send:INVITE, nick, channelName, nil];
	}
}

- (void)inviteSheetWillClose:(InviteSheet*)sender
{
	inviteSheet = nil;
}

- (void)onMemberSendFile:(id)sender
{
	if (fileSendPanel) {
		[fileSendPanel cancel:nil];
	}
	
	IRCClient* u = world.selectedClient;
	if (!u) return;
	
	[fileSendTargets release];
	fileSendTargets = [[self selectedMembers:sender] retain];
	
	if (!fileSendTargets.count) return;
	
	fileSendUID = u.uid;
	
	NSOpenPanel* d = [NSOpenPanel openPanel];
	[d setCanChooseFiles:YES];
	[d setCanChooseDirectories:NO];
	[d setResolvesAliases:YES];
	[d setAllowsMultipleSelection:YES];
	[d setCanCreateDirectories:NO];
	[d beginForDirectory:@"~/Desktop" file:nil types:nil modelessDelegate:self didEndSelector:@selector(fileSendPanelDidEnd:returnCode:contextInfo:) contextInfo:nil];
	
	[fileSendPanel release];
	fileSendPanel = [d retain];
}

- (void)fileSendPanelDidEnd:(NSOpenPanel *)panel returnCode:(NSInteger)returnCode contextInfo:(void  *)contextInfo
{
	if (returnCode == NSOKButton) {
		NSArray* files = [panel filenames];
		
		for (IRCUser* m in fileSendTargets) {
			for (NSString* fname in files) {
				[world.dcc addSenderWithUID:fileSendUID nick:m.nick fileName:fname autoOpen:YES];
			}
		}
	}
	
	[fileSendPanel release];
	fileSendPanel = nil;
	
	[fileSendTargets release];
	fileSendTargets = nil;
}

- (void)onMemberPing:(id)sender
{
	IRCClient* u = world.selectedClient;
	if (!u) return;
	
	for (IRCUser* m in [self selectedMembers:sender]) {
		[u sendCTCPPing:m.nick];
	}
	
	[self deselectMembers:sender];
}

- (void)onMemberTime:(id)sender
{
	IRCClient* u = world.selectedClient;
	if (!u) return;
	
	for (IRCUser* m in [self selectedMembers:sender]) {
		[u sendCTCPQuery:m.nick command:TIME text:nil];
	}
	
	[self deselectMembers:sender];
}

- (void)onMemberVersion:(id)sender
{
	IRCClient* u = world.selectedClient;
	if (!u) return;
	
	for (IRCUser* m in [self selectedMembers:sender]) {
		[u sendCTCPQuery:m.nick command:VERSION text:nil];
	}
	
	[self deselectMembers:sender];
}

- (void)onMemberUserInfo:(id)sender
{
	IRCClient* u = world.selectedClient;
	if (!u) return;
	
	for (IRCUser* m in [self selectedMembers:sender]) {
		[u sendCTCPQuery:m.nick command:USERINFO text:nil];
	}
	
	[self deselectMembers:sender];
}

- (void)onMemberClientInfo:(id)sender
{
	IRCClient* u = world.selectedClient;
	if (!u) return;
	
	for (IRCUser* m in [self selectedMembers:sender]) {
		[u sendCTCPQuery:m.nick command:CLIENTINFO text:nil];
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
	IRCClient* u = world.selectedClient;
	if (!u || !u.isLoggedIn) return;
	[u send:JOIN, pointedChannelName, nil];
}

- (void)onCopyAddress:(id)sender
{
	if (!pointedAddress) return;
	[[NSPasteboard generalPasteboard] setStringContent:pointedAddress];
	self.pointedAddress = nil;
}

- (void)onWantChannelListSorted:(id)sender
{
	for (IRCClient* u in [world clients]) {
		NSArray *clientChannels = [[[[NSArray arrayWithArray:u.channels] sortedArrayUsingFunction:channelDataSort context:nil] mutableCopy] autorelease];
		
		[u.channels removeAllObjects];
		
		for (IRCChannel* c in clientChannels) {
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
	[self showServerPropertyDialog:world.selectedClient ignore:YES];
}

- (void)onWantAboutWindowShown:(id)sender
{
	aboutPanel = [AboutPanel new];
	aboutPanel.delegate = self;
	[aboutPanel show];
}

- (void)aboutPanelWillClose:(AboutPanel*)sender
{
	[aboutPanel release];
	aboutPanel = nil;
}

- (void)processModeChange:(id)sender mode:(NSString *)tmode 
{
	IRCClient* u = world.selectedClient;
	IRCChannel* c = world.selectedChannel;
	
	if (!u || !c.isChannel) return;
	
	NSArray *nicknames = [self selectedMembers:sender];
	
	if (pointedNick && [nicknames isEqual:[NSArray array]]) {
		IRCUser *us = [c findMember:pointedNick];
		
		if (us) {
			[u sendCommand:[NSString stringWithFormat:@"%@ %@", tmode, us.nick] completeTarget:YES target:c.name];
		}
	} else {
		NSString *opString = [@"" autorelease];
		
		for (IRCUser* m in nicknames) {
			opString = [opString stringByAppendingFormat:@"%@ ", m.nick];
		}
		
		[u sendCommand:[NSString stringWithFormat:@"%@ %@", tmode, opString] completeTarget:YES target:c.name];
		
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
	IRCClient* u = world.selectedClient;
	IRCChannel* c = world.selectedChannel;
	
	if (!u || !c.isChannel) return;
	
	NSArray *nicknames = [self selectedMembers:sender];
	
	if (pointedNick && [nicknames isEqual:[NSArray array]]) {
		IRCUser *us = [c findMember:pointedNick];
		
		if (us) {
			[u kick:c target:us.nick];
		}
	} else {
		for (IRCUser* m in nicknames) {
			[u kick:c target:m.nick];
		}
		
		[self deselectMembers:sender];
	}
	
	pointedNick = nil;
}

- (void)onMemberBan:(id)sender
{
	IRCClient* u = world.selectedClient;
	IRCChannel* c = world.selectedChannel;
	
	if (!u || !c.isChannel) return;
	
	NSArray *nicknames = [self selectedMembers:sender];
	
	if (pointedNick && [nicknames isEqual:[NSArray array]]) {
		IRCUser *us = [c findMember:pointedNick];
		
		if (us) {
			[u sendCommand:[NSString stringWithFormat:@"BAN %@", us.nick] completeTarget:YES target:c.name];
		}
	} else {
		for (IRCUser* m in nicknames) {
			[u sendCommand:[NSString stringWithFormat:@"BAN %@", m.nick] completeTarget:YES target:c.name];
		}
		
		[self deselectMembers:sender];
	}
	
	pointedNick = nil;
}

- (void)onMemberBanKick:(id)sender
{
	IRCClient* u = world.selectedClient;
	IRCChannel* c = world.selectedChannel;
	
	if (!u || !c.isChannel) return;
	
	NSArray *nicknames = [self selectedMembers:sender];
	
	if (pointedNick && [nicknames isEqual:[NSArray array]]) {
		IRCUser *us = [c findMember:pointedNick];
		
		if (us) {
			[u sendCommand:[NSString stringWithFormat:@"KICKBAN %@ %@", us.nick, TXTLS(@"KICK_REASON")] completeTarget:YES target:c.name];
		}
	} else {
		for (IRCUser* m in nicknames) {
			[u sendCommand:[NSString stringWithFormat:@"KICKBAN %@ %@", m.nick, TXTLS(@"KICK_REASON")] completeTarget:YES target:c.name];
		}
		
		[self deselectMembers:sender];
	}
	
	pointedNick = nil;
}

- (void)onMemberKill:(id)sender
{
	IRCClient* u = world.selectedClient;
	IRCChannel* c = world.selectedChannel;
	
	if (!u || !c.isChannel) return;
	
	NSArray *nicknames = [self selectedMembers:sender];
	
	if (pointedNick && [nicknames isEqual:[NSArray array]]) {
		[u sendCommand:[NSString stringWithFormat:@"KILL %@ %@", pointedNick, [Preferences IRCopDefaultKillMessage]] completeTarget:NO target:nil];
	} else {
		for (IRCUser* m in nicknames) {
			[u sendCommand:[NSString stringWithFormat:@"KILL %@ %@", m.nick, [Preferences IRCopDefaultKillMessage]] completeTarget:NO target:nil];
		}
		
		[self deselectMembers:sender];
	}
	
	pointedNick = nil;
}

- (void)onMemberGline:(id)sender
{
	IRCClient* u = world.selectedClient;
	IRCChannel* c = world.selectedChannel;
	
	if (!u || !c.isChannel) return;
	
	NSArray *nicknames = [self selectedMembers:sender];
	
	if (pointedNick && [nicknames isEqual:[NSArray array]]) {
		[u sendCommand:[NSString stringWithFormat:@"GLINE %@ %@", pointedNick, [Preferences IRCopDefaultGlineMessage]] completeTarget:NO target:nil];
	} else {
		for (IRCUser* m in nicknames) {
			[u sendCommand:[NSString stringWithFormat:@"GLINE %@ %@", m.nick, [Preferences IRCopDefaultGlineMessage]] completeTarget:NO target:nil];
		}
		
		[self deselectMembers:sender];
	}
	
	pointedNick = nil;
}

- (void)onMemberShun:(id)sender
{
	IRCClient* u = world.selectedClient;
	IRCChannel* c = world.selectedChannel;
	
	if (!u || !c.isChannel) return;
	
	NSArray *nicknames = [self selectedMembers:sender];
	
	if (pointedNick && [nicknames isEqual:[NSArray array]]) {
		[u sendCommand:[NSString stringWithFormat:@"SHUN %@ %@", pointedNick, [Preferences IRCopDefaultShunMessage]] completeTarget:NO target:nil];
	} else {
		for (IRCUser* m in nicknames) {
			[u sendCommand:[NSString stringWithFormat:@"SHUN %@ %@", m.nick, [Preferences IRCopDefaultShunMessage]] completeTarget:NO target:nil];
		}
		
		[self deselectMembers:sender];
	}
	
	pointedNick = nil;
}

- (void)onWantToReadTextualLogs:(id)sender
{	
	NSString* path = [[Preferences transcriptFolder] stringByExpandingTildeInPath];
	
	if ([[NSFileManager defaultManager] fileExistsAtPath:path]) {
		[[NSWorkspace sharedWorkspace] openURL:[NSURL fileURLWithPath:path]];
	} else {
		NSRunAlertPanel(TXTLS(@"LOG_PATH_DOESNT_EXIST_TITLE"), TXTLS(@"LOG_PATH_DOESNT_EXIST_MESSAGE"), TXTLS(@"OK_BUTTON"), nil, nil);	
	}
}

- (void)onWantToReadChannelLogs:(id)sender;
{
	IRCClient* u = world.selectedClient;
	IRCChannel* c = world.selectedChannel;
	if (!u || !c) return;
	
	NSString* path = [[Preferences transcriptFolder] stringByExpandingTildeInPath];
	path = [path stringByAppendingPathComponent:[NSString stringWithFormat:@"/%@/%@/%@/", u.name, ((c.isTalk) ? @"Queries" : @"Channels"), c.name]];
	
	if ([[NSFileManager defaultManager] fileExistsAtPath:path]) {
		[[NSWorkspace sharedWorkspace] openURL:[NSURL fileURLWithPath:path]];
	} else {
		NSRunAlertPanel(TXTLS(@"LOG_PATH_DOESNT_EXIST_TITLE"), TXTLS(@"LOG_PATH_DOESNT_EXIST_MESSAGE"), TXTLS(@"OK_BUTTON"), nil, nil);	
	}
}

- (void)onWantTextualConnnectToHelp:(id)sender 
{
	[world createConnection:@"irc.wyldryde.org +6697" chan:@"#textual"];
}

- (void)__onWantHostServVhostSet:(id)sender andVhost:(NSString*)vhost
{
	if ([vhost length] >= 1 && vhost != nil) {
		IRCClient* u = world.selectedClient;
		IRCChannel* c = world.selectedChannel;
		
		if (!u || !c.isChannel) return;
		
		NSArray *nicknames = [self selectedMembers:sender];
		
		if (pointedNick && [nicknames isEqual:[NSArray array]]) {
			[u sendCommand:[NSString stringWithFormat:@"hs setall %@ %@", pointedNick, vhost] completeTarget:NO target:nil];
		} else {
			for (IRCUser* m in nicknames) {
				[u sendCommand:[NSString stringWithFormat:@"hs setall %@ %@", m.nick, vhost] completeTarget:NO target:nil];
			}
			
			[self deselectMembers:sender];
		}
	}
	
	pointedNick = nil;	
}

- (void)_onWantHostServVhostSet:(id)sender
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	NSString *vhost = promptForInput(TXTLS(@"SET_USER_VHOST_PROMPT_MESSAGE"), 
									 TXTLS(@"SET_USER_VHOST_PROMPT_TITLE"), nil, nil, nil);
	
	[[self invokeOnMainThread] __onWantHostServVhostSet:sender andVhost:vhost];
	
	[pool release];
}

- (void)onWantHostServVhostSet:(id)sender
{
	[self performSelectorInBackground:@selector(_onWantHostServVhostSet:) withObject:sender];
}

- (void)onWantChannelBanList:(id)sender
{
	[world.selectedClient createChanBanListDialog];
	[world.selectedClient send:MODE, [[world selectedChannel] name], @"+b", nil];
}

- (void)openHelpMenuLinkItem:(id)sender
{
	switch ([sender tag]) {
		case 101:
			[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://wiki.github.com/mikemac11/Textual/"]];
			break;
		case 102: 
			[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://github.com/mikemac11/Textual"]];
			break;
		case 103:
			[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://wiki.github.com/mikemac11/Textual/text-formatting"]];
			break;
		default:
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
		default:
			break;
	}
}

@synthesize closeWindowItem;
@synthesize preferencesController;
@synthesize ServerSheets;
@synthesize ChannelSheets;
@synthesize nickSheet;
@synthesize modeSheet;
@synthesize topicSheet;
@synthesize inviteSheet;
@synthesize aboutPanel;
@synthesize fileSendPanel;
@synthesize fileSendTargets;
@synthesize fileSendUID;
@synthesize master;
@end