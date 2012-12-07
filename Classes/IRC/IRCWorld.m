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

#define _autoConnectDelay				1
#define _reconnectAfterWakeupDelay		8

#define _treeDragItemType		@"tree"
#define _treeDragItemTypes		[NSArray arrayWithObject:_treeDragItemType]

#define _treeClientHeight		21.0
#define _treeChannelHeight		18.0

@implementation IRCWorld;

- (id)init
{
	if ((self = [super init])) {
		self.clients = [NSMutableArray new];
		
		self.messageOperationQueue = [NSOperationQueue new];
		
		self.messageOperationQueue.name = @"IRCWordMessageOperationQueue";
		self.messageOperationQueue.maxConcurrentOperationCount = 1;
	}
	
	return self;
}

- (void)dealloc
{
	[NSBundle deallocBundlesFromMemory:self];
}

- (void)setup:(IRCWorldConfig *)seed
{
	self.config = [seed mutableCopy];
	self.dummyLog = [self createLogWithClient:nil channel:nil];
	
	self.logBase.contentView = self.dummyLog.view;
	[self.dummyLog notifyDidBecomeVisible];
	
	for (IRCClientConfig *e in self.config.clients) {
		[self createClient:e reload:YES];
	}
	
	[self.config.clients removeAllObjects];
}

- (void)setupTree
{
	[self.serverList setTarget:self];
	[self.serverList setDoubleAction:@selector(outlineViewDoubleClicked:)];
	[self.serverList registerForDraggedTypes:_treeDragItemTypes];
	
	IRCClient *firstSelection = nil;
	
	for (IRCClient *e in self.clients) {
		[self expandClient:e];
		
		if (e.config.autoConnect) {
			if (PointerIsNotEmpty(firstSelection)) {
				firstSelection = e;
			}
		}
	}
	
	if (firstSelection) {
		NSInteger n = [self.serverList rowForItem:firstSelection];

		if (firstSelection.channels.count) {
			++n;
		}

		[self.serverList selectItemAtIndex:n];
	} else if (NSObjectIsEmpty(firstSelection)) {
		[self.serverList selectItemAtIndex:0];
	}

	[self outlineViewSelectionDidChange:nil];
}

- (void)save
{
	[TPCPreferences saveWorld:[self dictionaryValue]];
	[TPCPreferences sync];
}

- (NSMutableDictionary *)dictionaryValue
{
	NSMutableDictionary *dic = [self.config dictionaryValue];
	
	NSMutableArray *ary = [NSMutableArray array];
	
	for (IRCClient *u in self.clients) {
		[ary safeAddObject:[u dictionaryValue]];
	}
	
	dic[@"clients"] = ary;
	
	return dic;
}

- (void)setServerMenuItem:(NSMenuItem *)item
{
	if (self.serverMenu) return;
	
	self.serverMenu = [item.submenu copy];
}

- (void)setChannelMenuItem:(NSMenuItem *)item
{
	if (self.channelMenu) return;
	
	self.channelMenu = [item.submenu copy];
}

#pragma mark -
#pragma mark Properties

- (IRCClient *)selectedClient
{
	if (PointerIsEmpty(self.selected)) return nil;
	
	return [self.selected client];
}

- (IRCChannel *)selectedChannel
{
	if (PointerIsEmpty(self.selected)) return nil;
	if ([self.selected isClient]) return nil;
	
	return (IRCChannel *)self.selected;
}

- (IRCChannel *)selectedChannelOn:(IRCClient *)c
{
	if (PointerIsEmpty(self.selected)) return nil;
	if ([self.selected isClient]) return nil;
	if (NSDissimilarObjects(self.selected.client.uid, c.uid)) return nil;
	
	return (IRCChannel *)self.selected;
}

#pragma mark -
#pragma mark Utilities

- (void)resetLoadedBundles
{
	self.allLoadedBundles		= [NSArray new];
	self.bundlesWithPreferences	= [NSArray new];
	
	self.bundlesForUserInput	= [NSDictionary new];
	self.bundlesForServerInput	= [NSDictionary new];
	self.bundlesWithOutputRules	= [NSDictionary new];
}

- (void)destroyAllEvidence
{
	for (IRCClient *u in self.clients) {
		[self clearContentsOfClient:u];

		for (IRCChannel *c in [u channels]) {
			[self clearContentsOfChannel:c inClient:u];

			[c setDockUnreadCount:0];
			[c setTreeUnreadCount:0];
			[c setKeywordCount:0];
		}
	}

	[self updateIcon];
	[self reloadTree];
	[self markAllAsRead];
}

- (void)addHighlightInChannel:(IRCChannel *)channel withMessage:(NSString *)message
{
	if ([TPCPreferences logAllHighlightsToQuery]) {
		message = [message trim];
		
		NSString *time  = [NSString stringWithInteger:[NSDate epochTime]];
		
		NSArray  *entry = @[channel.name, time,
		[message attributedStringWithIRCFormatting:TXDefaultListViewControllerFont]];
		
		/* We insert at head so that latest is always on top. */
		[channel.client.highlights insertObject:entry atIndex:0];
		
		if (self.menuController.highlightSheet) {
			[self.menuController.highlightSheet.table reloadData];
		}
	} else {
		if (NSObjectIsNotEmpty(channel.client.highlights)) {
			[channel.client.highlights removeAllObjects];
		}
	}
}

- (void)autoConnectAfterWakeup:(BOOL)afterWakeUp
{
	if (self.master.ghostMode && afterWakeUp == NO) return;
	
	NSInteger delay = 0;
	
	if (afterWakeUp) delay += _reconnectAfterWakeupDelay;
	
	for (IRCClient *c in self.clients) {
        if ((c.disconnectType == IRCSleepModeDisconnectMode && afterWakeUp) || afterWakeUp == NO) { 
            if (c.config.autoConnect) {
                [c autoConnect:delay];
				
                delay += _autoConnectDelay;
            }
        }
	}
}

- (void)terminate
{
	for (IRCClient *c in self.clients) {
		[c terminate];

		[c.log terminate];
	}
}

- (void)prepareForSleep
{
	for (IRCClient *c in self.clients) {
        c.disconnectType = IRCSleepModeDisconnectMode;
        
		[c quit:c.config.sleepQuitMessage];
	}
}

- (void)focusInputText
{
	[self.text focus];
}

- (BOOL)inputText:(id)str command:(NSString *)command 
{
	if (PointerIsEmpty(self.selected)) return NO;
	
	return [self.selected.client inputText:str command:command];
}

- (void)markAllAsRead
{
	[self markAllAsRead:nil];
}

- (void)markAllAsRead:(IRCClient *)limitedClient
{
	for (IRCClient *u in self.clients) {
		if (PointerIsNotEmpty(limitedClient) && NSDissimilarObjects(u, limitedClient)) {
			continue;
		}
		
		u.isUnread = NO;
		
		for (IRCChannel *c in u.channels) {
			c.isUnread = NO;
			c.dockUnreadCount = 0;
			c.treeUnreadCount = 0;
			c.keywordCount = 0;
			
			if ([TPCPreferences autoAddScrollbackMark]) {
				[c.log unmark];
				[c.log mark];
			}
		}
	}
	
	[self reloadTree];
	[self updateIcon];
}

- (void)markAllScrollbacks
{
	for (IRCClient *u in self.clients) {
		[u.log mark];
		
		for (IRCChannel *c in u.channels) {
			[c.log mark];
		}
	}
}

- (void)updateIcon
{
	if ([TPCPreferences displayDockBadge]) {
		NSInteger messageCount = 0;
		NSInteger highlightCount = 0;
		
		for (IRCClient *u in self.clients) {
			for (IRCChannel *c in u.channels) {
				if ([c.name isEqualToString:TXTLS(@"ServerNoticeTreeItemTitle")] == NO) {
					messageCount   += [c dockUnreadCount];
					highlightCount += [c keywordCount];
				}
			}
		}
		
		if (messageCount == 0 && highlightCount == 0) {
			[TVCDockIcon drawWithoutCount];
		} else {
			[TVCDockIcon drawWithHilightCount:highlightCount messageCount:messageCount];
		}
	}
}

- (void)reloadTree
{
	if (self.reloadingTree) {
		[self.serverList setNeedsDisplay];
		
		return;
	}
	
	self.reloadingTree = YES;
	
	[self.master updateSegmentedController];
	
	[self.serverList reloadData];
	
	self.reloadingTree = NO;
}

- (void)expandClient:(IRCClient *)client
{
	[self.serverList expandItem:client];
}

- (void)adjustSelection
{
	NSInteger row = [self.serverList selectedRow];
	
	if (0 <= row && self.selected && NSDissimilarObjects(self.selected, [self.serverList itemAtRow:row])) {
		[self.serverList selectItemAtIndex:[self.serverList rowForItem:self.selected]];
		
		[self reloadTree];
	}
}

- (void)storePreviousSelection
{
	if (PointerIsEmpty(self.selected)) {
		self.previousSelectedClientId = 0;
		self.previousSelectedChannelId = 0;
	} else if (self.selected.isClient) {
		self.previousSelectedClientId = self.selected.uid;
		self.previousSelectedChannelId = 0;
	} else {		
		self.previousSelectedClientId = self.selected.client.uid;
		self.previousSelectedChannelId = self.selected.uid;
	}
}

- (IRCTreeItem *)previouslySelectedItem
{
	if (self.previousSelectedClientId == 0) return nil;
	
	NSInteger uid = self.previousSelectedClientId;
	NSInteger cid = self.previousSelectedChannelId;
	
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
	for (IRCClient *c in self.clients) {
		[c preferencesChanged];
	}
}

- (void)notifyOnGrowl:(TXNotificationType)type title:(NSString *)title
				 desc:(NSString *)desc userInfo:(NSDictionary *)info
{
	if ([TPCPreferences growlEnabledForEvent:type] == NO) return;
	if ([TPCPreferences stopGrowlOnActive] && [self.window isOnCurrentWorkspace]) return;
	
	[self.growl notify:type title:title desc:desc userInfo:info];
}

#pragma mark -
#pragma mark Window Title

- (void)updateTitle
{
	if (PointerIsEmpty(self.selected)) {
		[self.window setTitle:[TPCPreferences applicationName]];
		
		return;
	}
	
	IRCTreeItem *sel = self.selected;
	
	IRCClient   *u;
	IRCChannel  *c;

	if (sel.isClient) {
		u = (IRCClient *)sel;
		
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
		
		[self.window setTitle:title];
	} else {		
		u = sel.client;
		c = (IRCChannel *)sel;
		
		NSMutableString *title = [NSMutableString string];
		
		if (NSObjectIsNotEmpty(u.config.network)) {
			[title appendString:u.config.network];
		} else {
			if (NSObjectIsNotEmpty(u.config.name)) {
				[title appendString:u.config.name];
			}
		}
		
		if (NSObjectIsNotEmpty(title)) {
			[title appendString:@" — "];
		}
		
		if (NSObjectIsNotEmpty(c.name)) {
			[title appendString:c.name];
		}
		
		if (c.isChannel) {
			[title appendFormat:TXTLS(@"ChannelApplicationTitleUserCount"), [c.members count]];
			
			NSString *modes = [c.mode titleString];
			
			if ([modes length] >= 2) {
				[title appendFormat:TXTLS(@"ChannelApplicationTitleModeValue"), modes];
			}
		}
		
		[self.window setTitle:title];
	}

	// ---- //

	NSURL *iconURL = [NSBundle.mainBundle bundleURL];

	if ([TPCPreferences logTranscript]) {
		NSString *writePath;

		if (c) {
			writePath = c.logFile.fileWritePath;
		} else {
			writePath = u.logFile.fileWritePath;
		}

		if ([_NSFileManager() fileExistsAtPath:writePath]) {
			iconURL = [NSURL URLWithString:writePath];
		} 
	}

	[self.window setRepresentedURL:iconURL];

	// ---- //
	
	if (u.config.useSSL) {
		[[self.window standardWindowButton:NSWindowDocumentIconButton]
		 setImage:[NSImage imageNamed:@"NSLockLockedTemplate"]];
	} else {
		[[self.window standardWindowButton:NSWindowDocumentIconButton]
		 setImage:[NSImage imageNamed:@"NSLockUnlockedTemplate"]];
	}
}

- (void)updateClientTitle:(IRCClient *)client
{
	if (PointerIsEmpty(client) || PointerIsEmpty(self.selected)) return;
	
	if (self.selected == client) {
		[self updateTitle];
	}
}

- (void)updateChannelTitle:(IRCChannel *)channel
{
	if (PointerIsEmpty(channel) || PointerIsEmpty(self.selected)) return;
	
	if (self.selected == channel) {
		[self updateTitle];
	}
}

#pragma mark -
#pragma mark Tree Items

- (IRCClient *)findClient:(NSString *)name
{
	for (IRCClient *u in self.clients) {
		if ([u.name isEqualToString:name]) {
			return u;
		}
	}
	
	return nil;
}

- (IRCClient *)findClientById:(NSInteger)uid
{
	for (IRCClient *u in self.clients) {
		if (u.uid == uid) {
			return u;
		}
	}
	
	return nil;
}

- (IRCChannel *)findChannelByClientId:(NSInteger)uid channelId:(NSInteger)cid
{
	for (IRCClient *u in self.clients) {
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
	if (self.selected == item) return;
	
	[self storePreviousSelection];
	
	if (PointerIsEmpty(item)) {
		self.selected = nil;
		
		self.logBase.contentView = self.dummyLog.view;
		[self.dummyLog notifyDidBecomeVisible];
		
		self.memberList.dataSource = nil;
		[self.memberList reloadData];
		
		self.serverList.menu = self.treeMenu;
		
		return;
	}
	
	BOOL isClient = [item isClient];
	
	IRCClient *client = (IRCClient *)[item client];
	
	if (isClient == NO) {
		[self.serverList expandItem:client];
	}
	
	NSInteger i = [self.serverList rowForItem:item];
	
	if (i >= 0) {
		[self.serverList selectItemAtIndex:i];
		
		client.lastSelectedChannel = ((isClient) ? nil : (IRCChannel *)item);
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
	if (0 <= n && n < self.clients.count) {
		IRCClient *c = [self.clients safeObjectAtIndex:n];
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

- (void)reloadTheme
{
	[self.dummyLog reloadTheme];

	self.viewTheme.name = [TPCPreferences themeName];
	
	NSMutableArray *logs = [NSMutableArray array];
	
	for (IRCClient *u in self.clients) {
		[logs safeAddObject:u.log];
		
		for (IRCChannel *c in u.channels) {
			[logs safeAddObject:c.log];
		}
	}
	
	for (TVCLogController *log in logs) {
		[log reloadTheme];
	}
	
	[self.serverList updateBackgroundColor];
	[self.memberList updateBackgroundColor];

	[self.master.serverSplitView setNeedsDisplay:YES];
	[self.master.memberSplitView setNeedsDisplay:YES];

	[self.text redrawOriginPoints];

	[TLOLanguagePreferences setThemeForLocalization:self.viewTheme.path];
}

- (void)changeTextSize:(BOOL)bigger
{
	for (IRCClient *u in self.clients) {
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
	[c resetLogView:self withChannel:c andClient:u];
	
	if (c.uid == self.selectedChannel.uid) {
		[self outlineViewSelectionDidChange:nil];
	}
	
	[c.log setTopic:c.topic];
}

- (void)clearContentsOfClient:(IRCClient *)u
{
	[u resetLogView:self withChannel:nil andClient:u];
	
	if (u.uid == self.selectedClient.uid) {
		[self outlineViewSelectionDidChange:nil];
	}
}

- (void)createConnection:(NSString *)str chan:(NSString *)channel
{
	[self.extrac createConnectionAndJoinChannel:str chan:channel];
}

- (IRCClient *)createClient:(IRCClientConfig *)seed reload:(BOOL)reload
{
	IRCClient *c = [IRCClient new];
	
	c.uid = ++self.itemId;
	c.world = self;
	
	if ([TPCPreferences inputHistoryIsChannelSpecific]) {
		c.inputHistory = [TLOInputHistory new];
	}
	
	[c setup:seed];
	
	c.log = [self createLogWithClient:c channel:nil];
	
	for (IRCChannelConfig *e in seed.channels) {
		[self createChannel:e client:c reload:NO adjust:NO];
	}
	
	[self.clients safeAddObject:c];
	
	if (reload) {
		[self reloadTree];
	}
	
	return c;
}

- (IRCChannel *)createChannel:(IRCChannelConfig *)seed
					   client:(IRCClient *)client
					   reload:(BOOL)reload
					   adjust:(BOOL)adjust
{
	IRCChannel *c = [client findChannel:seed.name];
	if (NSObjectIsNotEmpty(c.name)) return c;
	
	c = [IRCChannel new];
	
	c.uid = ++self.itemId;
	
	c.client		= client;
	c.mode.isupport = client.isupport;
	
	if ([TPCPreferences inputHistoryIsChannelSpecific]) {
		c.inputHistory = [TLOInputHistory new];
	}
	
	[c setup:seed];
	
	c.log = [self createLogWithClient:client channel:c];
	
	switch (seed.type) {
		case IRCChannelNormalType:
		{
			NSInteger n = [client indexOfTalkChannel];
			
			if (n >= 0) {
				[client.channels safeInsertObject:c atIndex:n];
			} else {
				[client.channels safeAddObject:c];
			}
			
			break;
		}
		default: [client.channels safeAddObject:c]; break;
	}
	
	if (reload) [self reloadTree];
	if (adjust) [self adjustSelection];
	
	return c;
}

- (IRCChannel *)createTalk:(NSString *)nick client:(IRCClient *)client
{
	IRCChannelConfig *seed = [IRCChannelConfig new];
	
	seed.name = nick;
	seed.type = IRCChannelPrivateMessageType;
	
	IRCChannel *c = [self createChannel:seed client:client reload:YES adjust:YES];
	
	if (client.isLoggedIn) {
		[c activate];
		
		IRCUser *m = nil;
		
		m = [IRCUser new];
		m.nick = client.myNick;
		[c addMember:m];
		
		m = [IRCUser new];
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
		i = [self.clients indexOfObjectIdenticalTo:target];
		
		NSInteger n = (i + 1);
		
		if (0 <= n && n < self.clients.count) {
			sel = [self.clients safeObjectAtIndex:n];
		}
		
		i = [self.serverList rowForItem:target];
	} else {		
		i = [self.serverList rowForItem:target];
		
		NSInteger n = (i + 1);
		
		if (0 <= n && n < [self.serverList numberOfRows]) {
			sel = [self.serverList itemAtRow:n];
		}
		
		if (sel && sel.isClient) {
			n = (i - 1);
			
			if (0 <= n && n < [self.serverList numberOfRows]) {
				sel = [self.serverList itemAtRow:n];
			}
		}
	}
	
	if (sel) {
		[self select:sel];
	} else {
		NSInteger n = (i - 1);
		
		if (0 <= n && n < [self.serverList numberOfRows]) {
			sel = [self.serverList itemAtRow:n];
		}
		
		[self select:sel];
	}
	
	if (target.isClient) {
		IRCClient *u = (IRCClient *)target;
		
		for (IRCChannel *c in u.channels) {
			[c closeDialogs];
		}
		
		[self.clients removeObjectIdenticalTo:target];
	} else {		
		[target.client.channels removeObjectIdenticalTo:target];
	}
	
	[self reloadTree];
	
	if (self.selected) {
		[self.serverList selectItemAtIndex:[self.serverList rowForItem:sel]];
	}
}

- (void)destroyClient:(IRCClient *)u
{
	[u terminate];
	[u disconnect];
	
	if (self.selected && self.selected.client == u) {
		[self selectOtherAndDestroy:u];
	} else {		
		[self.clients removeObjectIdenticalTo:u];
		
		[self reloadTree];
		[self adjustSelection];
	}
}

- (void)destroyChannel:(IRCChannel *)c
{
    [self destroyChannel:c part:YES];
}

- (void)destroyChannel:(IRCChannel *)c part:(BOOL)forcePart
{
	[c terminate];
	
	IRCClient *u = c.client;
	
	if (c.isChannel && forcePart) {
		if (u.isLoggedIn && c.isActive) {
			[u partChannel:c];
		}
	}
	
	if (u.lastSelectedChannel == c) {
		u.lastSelectedChannel = nil;
	}
	
	if (self.selected == c) {
		[self selectOtherAndDestroy:c];
	} else {
		[u.channels removeObjectIdenticalTo:c];
		
		[self reloadTree];
		[self adjustSelection];
	}
}

- (TVCLogController *)createLogWithClient:(IRCClient *)client channel:(IRCChannel *)channel
{
	TVCLogController *c = [TVCLogController new];
	
	c.menu			= self.logMenu;
	c.urlMenu		= self.urlMenu;
	c.chanMenu		= self.chanMenu;
	c.memberMenu	= self.memberMenu;
	
	c.world			= self;
	c.client		= client;
	c.channel		= channel;
	c.maxLines		= [TPCPreferences maxLogLines];
	
	c.theme			= self.viewTheme;
	
	[c setUp];
	
	[c.view setHostWindow:self.window];
	
	return c;
}

#pragma mark -
#pragma mark Log Delegate

- (void)logKeyDown:(NSEvent *)e
{
	[self focusInputText];
	
	switch (e.keyCode) {
		case TXKeyReturnCode:
		case TXKeyEnterCode:
			return;
			break;
	}
	
	[self.window sendEvent:e];
}

- (void)logDoubleClick:(NSString *)s
{
	NSArray *ary = [s componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
	
	if (NSObjectIsNotEmpty(ary)) {
		NSString *kind = [ary safeObjectAtIndex:0];
		
		if ([kind isEqualToString:@"client"]) {
			if (ary.count >= 2) {
				NSInteger uid = [ary integerAtIndex:1];
				
				IRCClient *u = [self findClientById:uid];
				
				if (u) {
					[self select:u];
				}
			}
		} else if ([kind isEqualToString:@"channel"]) {
			if (ary.count >= 3) {
				NSInteger uid = [ary integerAtIndex:1];
				NSInteger cid = [ary integerAtIndex:2];
				
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
	if (PointerIsEmpty(self.selected)) return;
	
	IRCClient *u = [self selectedClient];
	IRCChannel *c = [self selectedChannel];
	
	if (PointerIsEmpty(c)) {
		if (u.isConnecting || u.isConnected || u.isLoggedIn) {
			if ([TPCPreferences disconnectOnDoubleclick]) {
				[u quit];
			}
		} else {
			if ([TPCPreferences connectOnDoubleclick]) {
				[u connect];
			}
		}
		
		[self expandClient:u];
	} else {		
		if (u.isLoggedIn) {
			if (c.isActive) {
				if ([TPCPreferences leaveOnDoubleclick]) {
					[u partChannel:c];
				}
			} else {
				if ([TPCPreferences joinOnDoubleclick]) {
					[u joinChannel:c];
				}
			}
		}
	}
}

- (NSInteger)outlineView:(NSOutlineView *)sender numberOfChildrenOfItem:(id)item
{
	if (PointerIsEmpty(item)) return self.clients.count;
	
	return [item numberOfChildren];
}

- (BOOL)outlineView:(NSOutlineView *)sender isItemExpandable:(id)item
{
	return ([item numberOfChildren] > 0);
}

- (id)outlineView:(NSOutlineView *)outlineView child:(NSInteger)index ofItem:(IRCTreeItem *)item
{
	if (PointerIsEmpty(item)) return [self.clients safeObjectAtIndex:index];
	
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

- (CGFloat)outlineView:(NSOutlineView *)outlineView heightOfRowByItem:(IRCTreeItem *)item
{
	if (PointerIsEmpty(item) || item.isClient) {
		return _treeClientHeight;
	}
	
	return _treeChannelHeight;
}

- (void)outlineView:(NSOutlineView *)outlineView willDisplayCell:(TVCServerListCell *)cell forTableColumn:(NSTableColumn *)tableColumn item:(IRCTreeItem *)item
{
	cell.parent		= self.serverList;
	cell.cellItem	= item;
}

- (BOOL)outlineView:(NSOutlineView *)outlineView shouldExpandItem:(IRCTreeItem *)item
{
	item.isExpanded = YES;
	
	return YES;
}

- (BOOL)outlineView:(NSOutlineView *)outlineView shouldCollapseItem:(IRCTreeItem *)item
{
	item.isExpanded = NO;
	
	return YES;
}


- (void)outlineView:(NSOutlineView *)outlineView willDisplayOutlineCell:(NSButtonCell *)cell forTableColumn:(NSTableColumn *)tableColumn item:(id)item
{
	if (PointerIsEmpty(self.serverList.defaultDisclosureTriangle)) {
		self.serverList.defaultDisclosureTriangle = [cell image];
	}

	if (PointerIsEmpty(self.serverList.alternateDisclosureTriangle)) {
		self.serverList.alternateDisclosureTriangle = [cell alternateImage];
	}

	BOOL selected = (self.selected == item);

	NSImage *primary = [self.serverList disclosureTriangleInContext:YES selected:selected];
	NSImage *alterna = [self.serverList disclosureTriangleInContext:NO selected:selected];

	if ([cell.image isEqual:primary] == NO) {
		[cell setImage:primary];
		
		if (selected) {
			[cell setBackgroundStyle:NSBackgroundStyleLowered];
		} else {
			[cell setBackgroundStyle:NSBackgroundStyleRaised];
		}
	}

	if ([cell.alternateImage isEqual:alterna] == NO) {
		[cell setAlternateImage:alterna];
	}
}

- (void)outlineViewSelectionDidChange:(NSNotification *)note
{
	[_NSSpellChecker() setIgnoredWords:@[]
				inSpellDocumentWithTag:self.text.spellCheckerDocumentTag];
	
	id nextItem = [self.serverList itemAtRow:[self.serverList selectedRow]];
	
	self.selected = nextItem;
	
	if (PointerIsEmpty(self.selected)) {
		self.logBase.contentView = self.dummyLog.view;
		[self.dummyLog notifyDidBecomeVisible];
		
		self.memberList.dataSource = nil;
		self.memberList.delegate = nil;
        
		[self.memberList reloadData];
		
		self.serverList.menu = self.treeMenu;
		
		return;
	}
	
	[self.selected resetState];
	
	TVCLogController *log = [self.selected log];
	
	self.logBase.contentView = [log view];
	[log notifyDidBecomeVisible];
	
	if ([self.selected isClient]) {
		self.serverList.menu = self.serverMenu;
		
		self.memberList.dataSource = nil;
		self.memberList.delegate = nil;
		
		[self.memberList reloadData];
	} else {		
		self.serverList.menu = self.channelMenu;
		
		self.memberList.dataSource = self.selected;
		self.memberList.delegate = self.selected;
		
		[self.memberList reloadData];
	}
	
	[self.memberList deselectAll:nil];
	[self.memberList scrollRowToVisible:0];
    
    [self focusInputText];
	
	[self.selected.log.view clearSelection];
	
	if ([TPCPreferences inputHistoryIsChannelSpecific]) {
		NSAttributedString *inputValue = [self.text attributedStringValue];
		
		self.master.inputHistory = self.selected.inputHistory;
		
		IRCTreeItem *previous = [self previouslySelectedItem];
		
		TLOInputHistory *oldHistory = previous.inputHistory;
		TLOInputHistory *newHistory = self.selected.inputHistory;
		
		[oldHistory setLastHistoryItem:inputValue];
		
		[self.text setStringValue:NSStringEmptyPlaceholder];
		
		if (NSObjectIsNotEmpty(newHistory.lastHistoryItem)) {
			[self.text setAttributedStringValue:newHistory.lastHistoryItem];
		}
	}
	
	if (self.selected.isClient || self.selected.log.channel.isTalk) {
		[self.master showMemberListSplitView:NO];
	} else {
		[self.master showMemberListSplitView:YES];
	}
	
	[self updateTitle];
	[self reloadTree];
	[self updateIcon];
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
		
		s = [NSString stringWithFormat:@"%ld-%ld", c.client.uid, c.uid];
	}
	
	[pboard declareTypes:_treeDragItemTypes owner:self];
	
	[pboard setPropertyList:s forType:_treeDragItemType];
	
	return YES;
}

- (IRCTreeItem *)findItemFromInfo:(NSString *)s
{
	if ([s contains:@"-"]) {
		NSArray *ary = [s componentsSeparatedByString:@"-"];
		
		NSInteger uid = [ary integerAtIndex:0];
		NSInteger cid = [ary integerAtIndex:1];
		
		return [self findChannelByClientId:uid channelId:cid];
	} else {		
		return [self findClientById:[s integerValue]];
	}
}

- (NSDragOperation)outlineView:(NSOutlineView *)sender validateDrop:(id < NSDraggingInfo >)info proposedItem:(id)item proposedChildIndex:(NSInteger)index
{
	if (index < 0) return NSDragOperationNone;
	
	NSPasteboard *pboard = [info draggingPasteboard];
	if (PointerIsEmpty([pboard availableTypeFromArray:_treeDragItemTypes])) return NSDragOperationNone;
	
	NSString *infoStr = [pboard propertyListForType:_treeDragItemType];
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
		if (NSDissimilarObjects(item, c.client)) return NSDragOperationNone;
		
		IRCClient *toClient = (IRCClient *)item;
		
		NSArray *ary = toClient.channels;
		
		NSMutableArray *low  = [[ary subarrayWithRange:NSMakeRange(0, index)] mutableCopy];
		NSMutableArray *high = [[ary subarrayWithRange:NSMakeRange(index, (ary.count - index))] mutableCopy];
		
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

- (BOOL)outlineView:(NSOutlineView *)sender acceptDrop:(id < NSDraggingInfo >)info
			   item:(id)item childIndex:(NSInteger)index
{
	if (index < 0) return NO;
	
	NSPasteboard *pboard = [info draggingPasteboard];
	if (PointerIsEmpty([pboard availableTypeFromArray:_treeDragItemTypes])) return NO;
	
	NSString *infoStr = [pboard propertyListForType:_treeDragItemType];
	if (PointerIsEmpty(infoStr)) return NO;
	
	IRCTreeItem *i = [self findItemFromInfo:infoStr];
	if (PointerIsEmpty(i)) return NO;
	
	if (i.isClient) {
		if (item) return NO;
		
		NSMutableArray *ary = self.clients;
		NSMutableArray *low = [[ary subarrayWithRange:NSMakeRange(0, index)] mutableCopy];
		NSMutableArray *high = [[ary subarrayWithRange:NSMakeRange(index, (ary.count - index))] mutableCopy];
		
		[low removeObjectIdenticalTo:i];
		[high removeObjectIdenticalTo:i];
		
		[ary removeAllObjects];
		
		[ary addObjectsFromArray:low];
		[ary safeAddObject:i];
		[ary addObjectsFromArray:high];
		
		[self reloadTree];
		[self save];
	} else {
		if (PointerIsEmpty(item) || NSDissimilarObjects(item, i.client)) return NO;
		
		IRCClient *u = (IRCClient *)item;
		
		NSMutableArray *ary = u.channels;
		NSMutableArray *low = [[ary subarrayWithRange:NSMakeRange(0, index)] mutableCopy];
		NSMutableArray *high = [[ary subarrayWithRange:NSMakeRange(index, (ary.count - index))] mutableCopy];
		
		[low removeObjectIdenticalTo:i];
		[high removeObjectIdenticalTo:i];
		
		[ary removeAllObjects];
		
		[ary addObjectsFromArray:low];
		[ary safeAddObject:i];
		[ary addObjectsFromArray:high];
		
		[self reloadTree];
		[self save];
	}
	
	NSInteger n = [self.serverList rowForItem:self.selected];
	
	if (n >= 0) {
		[self.serverList selectItemAtIndex:n];
	}
	
	return YES;
}

- (void)memberListViewKeyDown:(NSEvent *)e
{
	[self logKeyDown:e];
}

- (void)serverListKeyDown:(NSEvent *)e
{
	[self logKeyDown:e];
}

#pragma mark -

- (void)updateReadinessState:(TVCLogController *)controller
{
	NSArray *queues = [self.messageOperationQueue operations];

	for (TKMessageBlockOperation *op in queues) {
		if (op.controller == controller) {
			[op willChangeValueForKey:@"isReady"];
			[op didChangeValueForKey:@"isReady"];
		}
	}
}

@end

#pragma mark -

@interface TKMessageBlockOperation () /* @private */
@property (nonatomic, strong) NSDictionary *context;
@end

@implementation TKMessageBlockOperation

+ (TKMessageBlockOperation *)operationWithBlock:(void(^)(void))block
								  forController:(TVCLogController *)controller
									withContext:(NSDictionary *)context
{
	if (PointerIsEmpty(controller) || PointerIsEmpty(block)) {
		return nil;
	}
	
	TKMessageBlockOperation *retval = [TKMessageBlockOperation new];

	retval.controller		= controller;
	retval.context			= context;
	
	retval.queuePriority	= retval.priority;
	retval.completionBlock	= block;
	
	return retval;
}

+ (TKMessageBlockOperation *)operationWithBlock:(void(^)(void))block
								  forController:(TVCLogController *)controller
{
	return [self operationWithBlock:block forController:controller withContext:nil];
}

- (NSOperationQueuePriority)priority
{
	id target	= self.controller.channel;
	id selected = self.controller.world.selected;

	if (PointerIsEmpty(target)) {
		target = self.controller.client;
	}

	// ---- //

	NSOperationQueuePriority retval = NSOperationQueuePriorityLow;

	// ---- //
	
	if ((target || selected) && target == selected) {
		retval = NSOperationQueuePriorityNormal;
	}

	if (NSObjectIsNotEmpty(self.context) && self.context[@"highPriority"]) {
		retval += 4L;
	}

	if (NSObjectIsNotEmpty(self.context) && self.context[@"isHistoric"]) {
		retval += 4L;
	}

	// ---- //
	
	return retval;
}

- (BOOL)isReady
{
	if (self.controller.reloadingHistory) {
		BOOL isHistoric = (NSObjectIsNotEmpty(self.context) && self.context[@"isHistoric"]);

		if (isHistoric) {
			return ([self.controller.view isLoading] == NO);
		}
	} else {
		return ([self.controller.view isLoading] == NO);
	}

	return NO;
}

@end
