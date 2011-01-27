// Created by Satoshi Nakagawa <psychs AT limechat DOT net> <http://github.com/psychs/limechat>
// Modifications by Codeux Software <support AT codeux DOT com> <https://github.com/codeux/Textual>
// You can redistribute it and/or modify it under the new BSD license.

#define AUTO_CONNECT_DELAY              1
#define RECONNECT_AFTER_WAKE_UP_DELAY	8

#define TREE_DRAG_ITEM_TYPE     @"tree"
#define TREE_DRAG_ITEM_TYPES	[NSArray arrayWithObject:TREE_DRAG_ITEM_TYPE]

@interface IRCWorld (Private)
- (void)storePreviousSelection;
- (void)changeInputTextTheme;
- (void)changeTreeTheme;
- (void)changeMemberListTheme;
@end

@implementation IRCWorld;

@synthesize addrMenu;
@synthesize allLoadedBundles;
@synthesize bandwidthIn;
@synthesize bandwidthOut;
@synthesize bundlesForServerInput;
@synthesize bundlesForUserInput;
@synthesize bundlesWithPreferences;
@synthesize chanMenu;
@synthesize channelMenu;
@synthesize chatBox;
@synthesize clients;
@synthesize config;
@synthesize dummyLog;
@synthesize extrac;
@synthesize fieldEditor;
@synthesize growl;
@synthesize itemId;
@synthesize logBase;
@synthesize logMenu;
@synthesize memberList;
@synthesize memberMenu;
@synthesize menuController;
@synthesize messagesReceived;
@synthesize messagesSent;
@synthesize previousSelectedChannelId;
@synthesize previousSelectedClientId;
@synthesize reloadingTree;
@synthesize selected;
@synthesize serverMenu;
@synthesize soundMuted;
@synthesize text;
@synthesize tree;
@synthesize treeMenu;
@synthesize urlMenu;
@synthesize viewTheme;
@synthesize window;

- (id)init
{
	if ((self = [super init])) {
		clients = [NSMutableArray new];
	}
	
	return self;
}

- (void)dealloc
{
	[NSBundle deallocBundlesFromMemory:self];
	
	[allLoadedBundles release];
	[bundlesForServerInput release];
	[bundlesForUserInput release];
	[bundlesWithPreferences release];
	[channelMenu release];
	[clients release];
	[config release];
	[dummyLog release];
	[extrac release];
	[selected release];
	[serverMenu release];	
	
	[super dealloc];
}

- (void)setup:(IRCWorldConfig *)seed
{
	config = [seed mutableCopy];
	dummyLog = [self createLogWithClient:nil channel:nil];
	
	[dummyLog retain];
	
	logBase.contentView = dummyLog.view;
	[dummyLog notifyDidBecomeVisible];
	
	for (IRCClientConfig *e in config.clients) {
		[self createClient:e reload:YES];
	}
	
	[config.clients removeAllObjects];
	
	[self changeTreeTheme];
	[self changeMemberListTheme];
	[self changeInputTextTheme];
}

- (void)setupTree
{
	[tree setTarget:self];
	[tree setDoubleAction:@selector(outlineViewDoubleClicked:)];
	[tree registerForDraggedTypes:TREE_DRAG_ITEM_TYPES];
	
	IRCClient *client = nil;;
	
	for (IRCClient *e in clients) {
		if (e.config.autoConnect) {
			client = e;
			
			break;
		}
	}
    
	if (client) {
		[tree expandItem:client];
		
		NSInteger n = [tree rowForItem:client];
		if (client.channels.count) ++n;
		
		[tree selectItemAtIndex:n];
	} else if (NSObjectIsNotEmpty(client)) {
		[tree selectItemAtIndex:0];
	}
	
	[self outlineViewSelectionDidChange:nil];
}

- (void)save
{
	[Preferences saveWorld:[self dictionaryValue]];
	[Preferences sync];
}

- (NSMutableDictionary *)dictionaryValue
{
	NSMutableDictionary *dic = [config dictionaryValue];
	NSMutableArray *ary = [NSMutableArray array];
	
	for (IRCClient *u in clients) {
		[ary addObject:[u dictionaryValue]];
	}
	
	[dic setObject:ary forKey:@"clients"];
	
	return dic;
}

- (void)setServerMenuItem:(NSMenuItem *)item
{
	if (serverMenu) return;
	
	serverMenu = [[item submenu] copy];
}

- (void)setChannelMenuItem:(NSMenuItem *)item
{
	if (channelMenu) return;

	channelMenu = [[item submenu] copy];
}

#pragma mark -
#pragma mark Properties

- (IRCClient *)selectedClient
{
	if (PointerIsEmpty(selected)) return nil;
	
	return [selected client];
}

- (IRCChannel *)selectedChannel
{
	if (PointerIsEmpty(selected)) return nil;
	if ([selected isClient]) return nil;
	
	return (IRCChannel *)selected;
}

- (IRCChannel *)selectedChannelOn:(IRCClient *)c
{
	if (PointerIsEmpty(selected)) return nil;
	if ([selected isClient]) return nil;
	if (selected.client.uid != c.uid) return nil;
	
	return (IRCChannel *)selected;
}

#pragma mark -
#pragma mark Utilities

- (void)resetLoadedBundles
{
	[allLoadedBundles release];
	[bundlesForUserInput release];
	[bundlesForServerInput release];
	[bundlesWithPreferences release];
	
	allLoadedBundles = [NSArray new];
	bundlesWithPreferences = [NSArray new];
	bundlesForUserInput = [NSDictionary new];
	bundlesForServerInput = [NSDictionary new];
}

- (void)autoConnectAfterWakeup:(BOOL)afterWakeUp
{
	NSInteger delay = 0;
	
	if (afterWakeUp) delay += RECONNECT_AFTER_WAKE_UP_DELAY;
	
	for (IRCClient *c in clients) {
		if (c.config.autoConnect) {
			[c autoConnect:delay];
			
			delay += AUTO_CONNECT_DELAY;
		}
	}
}

- (void)terminate
{
	for (IRCClient *c in clients) {
		[c terminate];
	}
}

- (void)prepareForSleep
{
	for (IRCClient *c in clients) {
		[c quit:c.config.sleepQuitMessage];
	}
}

- (void)focusInputText
{
	[text focus];
}

- (BOOL)inputText:(NSString *)s command:(NSString *)command
{
	if (PointerIsEmpty(selected)) return NO;
	
	return [[selected client] inputText:s command:command];
}

- (void)markAllAsRead
{
	for (IRCClient *u in clients) {
		u.isUnread = NO;
		
		for (IRCChannel *c in u.channels) {
			c.isUnread = NO;
			c.unreadCount = 0;
			c.keywordCount = 0;
		}
	}
	
	[self reloadTree];
}

- (void)markAllScrollbacks
{
	for (IRCClient *u in clients) {
		[u.log mark];
		
		for (IRCChannel *c in u.channels) {
			[c.log mark];
		}
	}
}

- (void)updateIcon
{
	if ([Preferences displayDockBadge]) {
		NSInteger messageCount = 0;
		NSInteger highlightCount = 0;
		
		for (IRCClient *u in clients) {
			for (IRCChannel *c in u.channels) {
				if ([c.name isEqualToString:TXTLS(@"NOTIFICATION_WINDOW_TITLE")] == NO &&
					[c.name isEqualToString:TXTLS(@"SERVER_NOTICES_WINDOW_TITLE")] == NO && 
					[c.name isEqualToString:TXTLS(@"HIGHLIGHTS_LOG_WINDOW_TITLE")] == NO) {
					
					messageCount += [c unreadCount];
					highlightCount += [c keywordCount];
				}
			}
		}
		
		if (messageCount == 0 && highlightCount == 0) {
			[DockIcon drawWithoutCounts];
		} else {
			[DockIcon drawWithHilightCount:highlightCount messageCount:messageCount];
		}
	}
}

- (void)reloadTree
{
	if (reloadingTree) {
		[tree setNeedsDisplay];
		
		return;
	}
	
	reloadingTree = YES;
	
	[tree reloadData];
	
	reloadingTree = NO;
}

- (void)expandClient:(IRCClient *)client
{
	[tree expandItem:client];
}

- (void)adjustSelection
{
	NSInteger row = [tree selectedRow];
	
	if (0 <= row && selected && selected != [tree itemAtRow:row]) {
		[tree selectItemAtIndex:[tree rowForItem:selected]];
	
		[self reloadTree];
	}
}

- (void)storePreviousSelection
{
	if (PointerIsEmpty(selected)) {
		previousSelectedClientId = 0;
		previousSelectedChannelId = 0;
	} else if (selected.isClient) {
		previousSelectedClientId = selected.uid;
		previousSelectedChannelId = 0;
	} else {		
		previousSelectedClientId = selected.client.uid;
		previousSelectedChannelId = selected.uid;
	}
}

- (IRCTreeItem *)previouslySelectedItem
{
	if (previousSelectedClientId == 0 && previousSelectedClientId == 0) return nil;
	
	NSInteger uid = previousSelectedClientId;
	NSInteger cid = previousSelectedChannelId;
	
	IRCTreeItem *item;
	
	if (cid) {
		item = [self findChannelByClientId:uid channelId:cid];
	} else {		
		item = [self findClientById:uid];
	}
	
	return item;
}

- (void)selectPreviousItem
{
	IRCTreeItem *item = [self previouslySelectedItem];
	
	if (item) {
		[self select:item];
	}
}

- (void)preferencesChanged
{
	for (IRCClient *c in clients) {
		[c preferencesChanged];
	}
}

- (void)notifyOnGrowl:(GrowlNotificationType)type title:(NSString *)title desc:(NSString *)desc context:(id)context
{
	if ([Preferences stopGrowlOnActive] && [NSApp isActive]) return;
	if ([Preferences growlEnabledForEvent:type] == NO) return;
	
	[growl notify:type title:title desc:desc context:context];
}

#pragma mark -
#pragma mark Window Title

- (void)updateTitle
{
	if (PointerIsEmpty(selected)) {
		[window setTitle:[[Preferences textualInfoPlist] objectForKey:@"CFBundleName"]];
		
		return;
	}
	
	IRCTreeItem *sel = selected;
	
	if (sel.isClient) {
		IRCClient *u = (IRCClient *)sel;
		
		NSMutableString *title = [NSMutableString string];
		
		if (NSObjectIsNotEmpty(u.config.network)) {
			[title appendString:u.config.network];
		} else {
			if (NSObjectIsNotEmpty(u.config.name)) {
				[title appendString:u.config.name];
			}
		}
		
		if (NSObjectIsNotEmpty(u.config.server)) {
			if (NSObjectIsNotEmpty(title)) [title appendString:@" — "];
		
			[title appendString:u.config.server];
		} else {
			if (NSObjectIsNotEmpty(u.config.host)) {
				if (NSObjectIsNotEmpty(title)) [title appendString:@" — "];
				
				[title appendString:u.config.host];
			}
		}
		
		[window setTitle:title];
		
		[_NSNotificationCenter() postNotificationName:ThemeSelectedConsoleNotification object:nil userInfo:nil];
	} else {		
		IRCClient *u = sel.client;
		IRCChannel *c = (IRCChannel *)sel;
		
		NSMutableString *title = [NSMutableString string];
		
		if (NSObjectIsNotEmpty(u.config.network)) {
			[title appendString:u.config.network];
		} else {
			if (NSObjectIsNotEmpty(u.config.name)) {
				[title appendString:u.config.name];
			}
		}
		
		if (NSObjectIsNotEmpty(title)) [title appendString:@" — "];
		
		if (NSObjectIsNotEmpty(c.name)) {
			[title appendString:c.name];
		}
		
		if (c.isChannel) {
			[title appendFormat:TXTLS(@"CHANNEL_APPLICATION_TITLE_USERS"), [c.members count]];
			
			NSString *modes = [c.mode titleString];
			
			if (NSObjectIsNotEmpty(modes)) {
				[title appendFormat:TXTLS(@"CHANNEL_APPLICATION_TITLE_MODES"), modes];
			}
			
			[_NSNotificationCenter() postNotificationName:ThemeSelectedChannelNotification object:nil userInfo:nil];
		} else {
			[_NSNotificationCenter() postNotificationName:ThemeSelectedConsoleNotification object:nil userInfo:nil];
		}
		
		[window setTitle:title];
	}
}

- (void)updateClientTitle:(IRCClient *)client
{
	if (PointerIsEmpty(client) || PointerIsEmpty(selected)) return;
	
	if (selected == client) {
		[self updateTitle];
	}
}

- (void)updateChannelTitle:(IRCChannel *)channel
{
	if (PointerIsEmpty(channel) || PointerIsEmpty(selected)) return;
	
	if (selected == channel) {
		[self updateTitle];
	}
}

#pragma mark -
#pragma mark Tree Items

- (IRCClient *)findClient:(NSString *)name
{
	for (IRCClient *u in clients) {
		if ([u.name isEqualToString:name]) {
			return u;
		}
	}
	
	return nil;
}

- (IRCClient *)findClientById:(NSInteger)uid
{
	for (IRCClient *u in clients) {
		if (u.uid == uid) {
			return u;
		}
	}
	
	return nil;
}

- (IRCChannel *)findChannelByClientId:(NSInteger)uid channelId:(NSInteger)cid
{
	for (IRCClient *u in clients) {
		if (u.uid == uid) {
			for (IRCChannel *c in u.channels) {
				if (c.uid == cid) {
					return c;
				}
			}
			
			break;
		}
	}
	
	return nil;
}

- (void)select:(id)item
{
	if (selected == item) return;
	
	[self storePreviousSelection];
	
	if (PointerIsEmpty(item)) {
		self.selected = nil;
		
		logBase.contentView = dummyLog.view;
		[dummyLog notifyDidBecomeVisible];
		
		memberList.dataSource = nil;
		[memberList reloadData];
		
		tree.menu = treeMenu;
		
		return;
	}
	
	BOOL isClient = [item isClient];
	
	IRCClient *client = (IRCClient *)[item client];
	
	if (isClient == NO) {
		[tree expandItem:client];
	}
	
	NSInteger i = [tree rowForItem:item];
	
	if (i >= 0) {
		[tree selectItemAtIndex:i];
	
		client.lastSelectedChannel = ((isClient) ? nil : (IRCChannel *)item);
	
		[self focusInputText];
	}
}

- (void)selectChannelAt:(NSInteger)n
{
	IRCClient *c = [self selectedClient];
	if (PointerIsEmpty(c)) return;
	
	if (n == 0) {
		[self select:c];
	} else {		
		--n;
		
		if (0 <= n && n < c.channels.count) {
			IRCChannel *e = [c.channels safeObjectAtIndex:n];
			
			[self select:e];
		}
	}
}

- (void)selectClientAt:(NSInteger)n
{
	if (0 <= n && n < clients.count) {
		IRCClient *c = [clients safeObjectAtIndex:n];
		IRCChannel *e = c.lastSelectedChannel;
		
		if (e) {
			[self select:e];
		} else {
			[self select:c];
		}
	}
}

#pragma mark -
#pragma mark Theme

- (void)updateThemeStyle
{
	NSMutableArray *logs = [NSMutableArray array];
	
	for (IRCClient *u in clients) {
		[logs addObject:u.log];
		
		for (IRCChannel *c in u.channels) {
			[logs addObject:c.log];
		}
	}
	
	for (LogController *log in logs) {
		[log applyOverrideStyle];
	}
}

- (void)reloadTheme
{
	viewTheme.name = [Preferences themeName];
	
	NSMutableArray *logs = [NSMutableArray array];
	
	for (IRCClient *u in clients) {
		[logs addObject:u.log];
		
		for (IRCChannel *c in u.channels) {
			[logs addObject:c.log];
		}
	}
	
	for (LogController *log in logs) {
		[log reloadTheme];
	}
	
	[self changeTreeTheme];
	[self changeMemberListTheme];
	[self changeInputTextTheme];
	
	[window setBackgroundColor:viewTheme.other.underlyingWindowColor];	
	
	[LanguagePreferences setThemeForLocalization:viewTheme.path];
}

- (void)changeInputTextTheme
{
	[chatBox setInputTextFont:viewTheme.other.inputTextFont];
	
	[text setTextColor:viewTheme.other.inputTextColor];
	[text setBackgroundColor:viewTheme.other.inputTextBgColor];
	
	[fieldEditor setInsertionPointColor:viewTheme.other.inputTextColor];
}

- (void)changeTreeTheme
{
	[tree setFont:viewTheme.other.treeFont];
	
	[tree themeChanged];
	[tree setNeedsDisplay];
}

- (void)changeMemberListTheme
{
	[memberList setFont:viewTheme.other.memberListFont];
	
	[[[[memberList tableColumns] safeObjectAtIndex:0] dataCell] themeChanged];
	
	[memberList themeChanged];
	[memberList setNeedsDisplay];
}

- (void)changeTextSize:(BOOL)bigger
{
	for (IRCClient *u in clients) {
		[u.log changeTextSize:bigger];
		
		for (IRCChannel *c in u.channels) {
			[c.log changeTextSize:bigger];
		}
	}
}

#pragma mark -
#pragma mark Factory

- (void)clearContentsOfChannel:(IRCChannel *)c inClient:(IRCClient *)u
{
	[c resetLogView:self withChannel:nil andClient:u];
	
	if (c.uid == [[self selectedChannel] uid]) {
		[self outlineViewSelectionDidChange:nil];
	}
	
	[c.log setTopic:c.topic];
}

- (void)clearContentsOfClient:(IRCClient *)u
{
	[u resetLogView:self withChannel:nil andClient:u];
	
	if (u.uid == [[self selectedClient] uid]) {
		[self outlineViewSelectionDidChange:nil];
	}
}

- (void)createConnection:(NSString *)str chan:(NSString *)channel
{
	[extrac createConnectionAndJoinChannel:str chan:channel];
}

- (IRCClient *)createClient:(IRCClientConfig *)seed reload:(BOOL)reload
{
	IRCClient *c = [[IRCClient new] autorelease];
	
	c.uid = itemId++;
	c.world = self;
	
	if ([Preferences inputHistoryIsChannelSpecific]) {
		c.inputHistory = [InputHistory new];
		c.currentInputHistory = nil;
	}
	
	c.log = [self createLogWithClient:c channel:nil];
	
	[c setup:seed];
	
	for (IRCChannelConfig *e in seed.channels) {
		[self createChannel:e client:c reload:NO adjust:NO];
	}
	
	[clients addObject:c];
	
	if (reload) {
		[self reloadTree];
	}
	
	return c;
}

- (IRCChannel *)createChannel:(IRCChannelConfig *)seed client:(IRCClient *)client reload:(BOOL)reload adjust:(BOOL)adjust
{
	IRCChannel *c = [client findChannel:seed.name];
	if (NSObjectIsNotEmpty(c.name)) return c;
	
	c = [[IRCChannel new] autorelease];

	c.uid = itemId++;
	c.client = client;
	c.mode.isupport = client.isupport;
	
	if ([Preferences inputHistoryIsChannelSpecific]) {
		c.inputHistory = [InputHistory new];
		c.currentInputHistory = nil;
	}
	
	[c setup:seed];
	
	c.log = [self createLogWithClient:client channel:c];
	
	switch (seed.type) {
		case CHANNEL_TYPE_CHANNEL:
		{
			NSInteger n = [client indexOfTalkChannel];
			
			if (n >= 0) {
				[client.channels insertObject:c atIndex:n];
			} else {
				[client.channels addObject:c];
			}
			
			break;
		}
		default:
			[client.channels addObject:c];
			break;
	}
	
	if (reload) [self reloadTree];
	if (adjust) [self adjustSelection];
	
	return c;
}

- (IRCChannel *)createTalk:(NSString *)nick client:(IRCClient *)client
{
	IRCChannelConfig *seed = [[IRCChannelConfig new] autorelease];
	
	seed.name = nick;
	seed.type = CHANNEL_TYPE_TALK;
	
	IRCChannel *c = [self createChannel:seed client:client reload:YES adjust:YES];
	
	if (client.isLoggedIn) {
		[c activate];
		
		IRCUser *m = nil;
		
		m = [[IRCUser new] autorelease];
		m.nick = client.myNick;
		[c addMember:m];
		
		m = [[IRCUser new] autorelease];
		m.nick = c.name;
		[c addMember:m];
	}
	
	return c;
}

- (void)selectOtherAndDestroy:(IRCTreeItem *)target
{
	NSInteger i = 0;
	
	IRCTreeItem *sel = nil;
	
	if (target.isClient) {
		i = [clients indexOfObjectIdenticalTo:target];
		
		NSInteger n = (i + 1);
		
		if (0 <= n && n < clients.count) {
			sel = [clients safeObjectAtIndex:n];
		}
		
		i = [tree rowForItem:target];
	} else {		
		i = [tree rowForItem:target];
		
		NSInteger n = (i + 1);
		
		if (0 <= n && n < [tree numberOfRows]) {
			sel = [tree itemAtRow:n];
		}
		
		if (sel && sel.isClient) {
			n = (i - 1);
			
			if (0 <= n && n < [tree numberOfRows]) {
				sel = [tree itemAtRow:n];
			}
		}
	}
	
	if (sel) {
		[self select:sel];
	} else {
		NSInteger n = (i - 1);
		
		if (0 <= n && n < [tree numberOfRows]) {
			sel = [tree itemAtRow:n];
		}
		
		[self select:sel];
	}
	
	if (target.isClient) {
		IRCClient *u = (IRCClient *)target;
		
		for (IRCChannel *c in u.channels) {
			[c closeDialogs];
		}
		
		[clients removeObjectIdenticalTo:target];
	} else {		
		[target.client.channels removeObjectIdenticalTo:target];
	}
	
	[self reloadTree];
	
	if (selected) {
		[tree selectItemAtIndex:[tree rowForItem:sel]];
	}
}

- (void)destroyClient:(IRCClient *)u
{
	[[u retain] autorelease];
	
	[u terminate];
	[u disconnect];
	
	if (selected && selected.client == u) {
		[self selectOtherAndDestroy:u];
	} else {		
		[clients removeObjectIdenticalTo:u];
		
		[self reloadTree];
		[self adjustSelection];
	}
}

- (void)destroyChannel:(IRCChannel *)c
{
	[[c retain] autorelease];
	
	[c terminate];
	
	IRCClient *u = c.client;
	
	if (c.isChannel) {
		if (u.isLoggedIn && c.isActive) {
			[u partChannel:c];
		}
	}
	
	if (u.lastSelectedChannel == c) {
		u.lastSelectedChannel = nil;
	}
	
	if (selected == c) {
		[self selectOtherAndDestroy:c];
	} else {
		[u.channels removeObjectIdenticalTo:c];
		
		[self reloadTree];
		[self adjustSelection];
	}
}

- (LogController *)createLogWithClient:(IRCClient *)client channel:(IRCChannel *)channel
{
	LogController *c = [LogController new];
	
	c.menu = logMenu;
	c.urlMenu = urlMenu;
	c.addrMenu = addrMenu;
	c.chanMenu = chanMenu;
	c.memberMenu = memberMenu;
	
	c.world = self;
	c.client = client;
	c.channel = channel;
	c.maxLines = [Preferences maxLogLines];
	
	c.theme = viewTheme;
	c.initialBackgroundColor = [viewTheme.other inputTextBgColor];
	
	[c setUp];
	
	[c.view setHostWindow:window];
	
	return [c autorelease];
}

#pragma mark -
#pragma mark Log Delegate

- (void)logKeyDown:(NSEvent *)e
{
	[window makeFirstResponder:text];
	
	[self focusInputText];
	
	switch (e.keyCode) {
		case KEY_RETURN:
		case KEY_ENTER:
			return;
	}
	
	[window sendEvent:e];
}

- (void)logDoubleClick:(NSString *)s
{
	NSArray *ary = [s componentsSeparatedByString:@" "];

	if (NSObjectIsNotEmpty(ary)) {
		NSString *kind = [ary safeObjectAtIndex:0];
		
		if ([kind isEqualToString:@"client"]) {
			if (ary.count >= 2) {
				NSInteger uid = [[ary safeObjectAtIndex:1] integerValue];
				
				IRCClient *u = [self findClientById:uid];
				
				if (u) {
					[self select:u];
				}
			}
		} else if ([kind isEqualToString:@"channel"]) {
			if (ary.count >= 3) {
				NSInteger uid = [[ary safeObjectAtIndex:1] integerValue];
				NSInteger cid = [[ary safeObjectAtIndex:2] integerValue];
			
				IRCChannel *c = [self findChannelByClientId:uid channelId:cid];
				
				if (c) {
					[self select:c];
				}
			}
		}
	}
}

#pragma mark -
#pragma mark NSOutlineView Delegate

- (void)outlineViewDoubleClicked:(id)sender
{
	if (PointerIsEmpty(selected)) return;
	
	IRCClient *u = [self selectedClient];
	IRCChannel *c = [self selectedChannel];
	
	if (PointerIsEmpty(c)) {
		if (u.isConnecting || u.isConnected || u.isLoggedIn) {
			if ([Preferences disconnectOnDoubleclick]) {
				[u quit];
			}
		} else {
			if ([Preferences connectOnDoubleclick]) {
				[u connect];
			}
		}
	} else {		
		if (u.isLoggedIn) {
			if (c.isActive) {
				if ([Preferences leaveOnDoubleclick]) {
					[u partChannel:c];
				}
			} else {
				if ([Preferences joinOnDoubleclick]) {
					[u joinChannel:c];
				}
			}
		}
	}
}

- (NSInteger)outlineView:(NSOutlineView *)sender numberOfChildrenOfItem:(id)item
{
	if (PointerIsEmpty(item)) return clients.count;
	
	return [item numberOfChildren];
}

- (BOOL)outlineView:(NSOutlineView *)sender isItemExpandable:(id)item
{
	return ([item numberOfChildren] > 0);
}

- (id)outlineView:(NSOutlineView *)outlineView child:(NSInteger)index ofItem:(IRCTreeItem *)item
{
	if (PointerIsEmpty(item)) return [clients safeObjectAtIndex:index];
	
	return [item childAtIndex:index];
}

- (id)outlineView:(NSOutlineView *)outlineView objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(id)item
{
	return [item label];
}

- (void)outlineViewSelectionIsChanging:(NSNotification *)note
{	
	[self storePreviousSelection];
}

- (void)outlineViewSelectionDidChange:(NSNotification *)note
{
	id nextItem = [tree itemAtRow:[tree selectedRow]];
	
	self.selected = nextItem;
	
	if (PointerIsEmpty(selected)) {
		logBase.contentView = dummyLog.view;
		[dummyLog notifyDidBecomeVisible];
		
		memberList.dataSource = nil;
		memberList.delegate = nil;
		[memberList reloadData];
		
		tree.menu = treeMenu;
		
		return;
	}
	
	[selected resetState];
	
	LogController *log = [selected log];
	
	logBase.contentView = [log view];
	[log notifyDidBecomeVisible];
	
	if ([selected isClient]) {
		tree.menu = serverMenu;
		
		memberList.dataSource = nil;
		memberList.delegate = nil;
		[memberList reloadData];
	} else {		
		tree.menu = channelMenu;
		
		memberList.dataSource = selected;
		memberList.delegate = selected;
		[memberList reloadData];
	}
	
	[memberList deselectAll:nil];
	[memberList scrollRowToVisible:0];
	
	[selected.log.view clearSelection];
	
	if ([Preferences inputHistoryIsChannelSpecific]) {
		NSString *inputValue = [text stringValue];
		
		menuController.master.inputHistory = selected.inputHistory;
		
		IRCTreeItem *previous = [self previouslySelectedItem];
		
		if (NSObjectIsNotEmpty(inputValue)) {
			if (previous.currentInputHistory) {
				[previous.currentInputHistory release];
				previous.currentInputHistory = nil;
			}
			
			previous.currentInputHistory = [inputValue retain];
		}
		
		[text setStringValue:@""];
		
		if (NSObjectIsNotEmpty(selected.currentInputHistory)) {
			[text setStringValue:selected.currentInputHistory];
		}
	}
	
	[[NSSpellChecker sharedSpellChecker] closeSpellDocumentWithTag:[fieldEditor spellCheckerDocumentTag]];
	
	[self updateTitle];
	[self reloadTree];
	[self updateIcon];
	[self focusInputText];
}

- (void)outlineView:(NSOutlineView *)outlineView willDisplayCell:(id)cell forTableColumn:(NSTableColumn *)tableColumn item:(id)item
{
	IRCTreeItem *i = item;
	
	NSColor *color = nil;
	
	if (i.isKeyword) {
		color = viewTheme.other.treeHighlightColor;
	} else if (i.isNewTalk) {
		color = viewTheme.other.treeNewTalkColor;
	} else if (i.isUnread) {
		color = viewTheme.other.treeUnreadColor;
	} else if (i.isActive) {
		if (i == [tree itemAtRow:[tree selectedRow]]) {
			color = viewTheme.other.treeSelActiveColor;
		} else {
			color = viewTheme.other.treeActiveColor;
		}
	} else {
		if (i == [tree itemAtRow:[tree selectedRow]]) {
			color = viewTheme.other.treeSelInactiveColor;
		} else {
			color = viewTheme.other.treeInactiveColor;
		}
	}
	
	[cell setTextColor:color];
}

- (void)serverTreeViewAcceptsFirstResponder
{
	[self focusInputText];
}

- (BOOL)outlineView:(NSOutlineView *)sender writeItems:(NSArray *)items toPasteboard:(NSPasteboard *)pboard
{
	if (NSObjectIsEmpty(items)) return NO;
	
	NSString *s;
	
	IRCTreeItem *i = [items safeObjectAtIndex:0];
	
	if (i.isClient) {
		IRCClient *u = (IRCClient *)i;
		
		s = [NSString stringWithInteger:u.uid];
	} else {		
		IRCChannel *c = (IRCChannel *)i;
		
		s = [NSString stringWithFormat:@"%d-%d", c.client.uid, c.uid];
	}
	
	[pboard declareTypes:TREE_DRAG_ITEM_TYPES owner:self];
	[pboard setPropertyList:s forType:TREE_DRAG_ITEM_TYPE];
	
	return YES;
}

- (IRCTreeItem *)findItemFromInfo:(NSString *)s
{
	if ([s contains:@"-"]) {
		NSArray *ary = [s componentsSeparatedByString:@"-"];
		
		NSInteger uid = [[ary safeObjectAtIndex:0] integerValue];
		NSInteger cid = [[ary safeObjectAtIndex:1] integerValue];
		
		return [self findChannelByClientId:uid channelId:cid];
	} else {		
		return [self findClientById:[s integerValue]];
	}
}

- (NSDragOperation)outlineView:(NSOutlineView *)sender validateDrop:(id < NSDraggingInfo >)info proposedItem:(id)item proposedChildIndex:(NSInteger)index
{
	if (index < 0) return NSDragOperationNone;
	
	NSPasteboard *pboard = [info draggingPasteboard];
	if (PointerIsEmpty([pboard availableTypeFromArray:TREE_DRAG_ITEM_TYPES])) return NSDragOperationNone;
	
	NSString *infoStr = [pboard propertyListForType:TREE_DRAG_ITEM_TYPE];
	if (PointerIsEmpty(infoStr)) return NSDragOperationNone;
	
	IRCTreeItem *i = [self findItemFromInfo:infoStr];
	if (PointerIsEmpty(i)) return NSDragOperationNone;
	
	if (i.isClient) {
		if (item) {
			return NSDragOperationNone;
		}
	} else {
		if (PointerIsEmpty(item)) return NSDragOperationNone;
	
		IRCChannel *c = (IRCChannel *)i;
		if (c.client != item) return NSDragOperationNone;
		
		IRCClient *toClient = (IRCClient *)item;
		
		NSArray *ary = toClient.channels;
		
		NSMutableArray *low = [[[ary subarrayWithRange:NSMakeRange(0, index)] mutableCopy] autorelease];
		NSMutableArray *high = [[[ary subarrayWithRange:NSMakeRange(index, (ary.count - index))] mutableCopy] autorelease];
		
		[low removeObjectIdenticalTo:c];
		[high removeObjectIdenticalTo:c];
		
		if (c.isChannel) {
			if (NSObjectIsNotEmpty(low)) {
				IRCChannel *prev = [low lastObject];
				
				if (prev.isChannel == NO) return NSDragOperationNone;
			}
		} else {
			if (NSObjectIsNotEmpty(high)) {
				IRCChannel *next = [high safeObjectAtIndex:0];
				
				if (next.isChannel) return NSDragOperationNone;
			}
		}
	}
	
	return NSDragOperationGeneric;
}

- (BOOL)outlineView:(NSOutlineView *)sender acceptDrop:(id < NSDraggingInfo >)info item:(id)item childIndex:(NSInteger)index
{
	if (index < 0) return NO;
	
	NSPasteboard *pboard = [info draggingPasteboard];
	if (PointerIsEmpty([pboard availableTypeFromArray:TREE_DRAG_ITEM_TYPES])) return NO;

	NSString *infoStr = [pboard propertyListForType:TREE_DRAG_ITEM_TYPE];
	if (PointerIsEmpty(infoStr)) return NO;
	
	IRCTreeItem *i = [self findItemFromInfo:infoStr];
	if (PointerIsEmpty(i)) return NO;
	
	if (i.isClient) {
		if (item) return NO;
		
		NSMutableArray *ary = clients;
		NSMutableArray *low = [[[ary subarrayWithRange:NSMakeRange(0, index)] mutableCopy] autorelease];
		NSMutableArray *high = [[[ary subarrayWithRange:NSMakeRange(index, (ary.count - index))] mutableCopy] autorelease];
		
		[low removeObjectIdenticalTo:i];
		[high removeObjectIdenticalTo:i];
		
		[[i retain] autorelease];
		
		[ary removeAllObjects];
		
		[ary addObject:i];
		[ary addObjectsFromArray:low];
		[ary addObjectsFromArray:high];
		
		[self reloadTree];
		[self save];
	} else {
		if (PointerIsEmpty(item) || item != i.client) return NO;
		
		IRCClient *u = (IRCClient *)item;
	
		NSMutableArray *ary = u.channels;
		NSMutableArray *low = [[[ary subarrayWithRange:NSMakeRange(0, index)] mutableCopy] autorelease];
		NSMutableArray *high = [[[ary subarrayWithRange:NSMakeRange(index, (ary.count - index))] mutableCopy] autorelease];
		
		[low removeObjectIdenticalTo:i];
		[high removeObjectIdenticalTo:i];
		
		[[i retain] autorelease];
		
		[ary removeAllObjects];
		
		[ary addObject:i];
		[ary addObjectsFromArray:low];
		[ary addObjectsFromArray:high];
		
		[self reloadTree];
		[self save];
	}
	
	NSInteger n = [tree rowForItem:selected];

	if (n >= 0) {
		[tree selectItemAtIndex:n];
	}
	
	return YES;
}

#pragma mark -
#pragma mark memberListView Delegate

- (void)memberListViewKeyDown:(NSEvent *)e
{
	[self logKeyDown:e];
}

- (void)memberListViewDropFiles:(NSArray *)files row:(NSNumber *)row
{
	return;
}

@end