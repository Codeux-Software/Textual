/* ********************************************************************* 
       _____        _               _    ___ ____   ____
      |_   _|___  _| |_ _   _  __ _| |  |_ _|  _ \ / ___|
       | |/ _ \ \/ / __| | | |/ _` | |   | || |_) | |
       | |  __/>  <| |_| |_| | (_| | |   | ||  _ <| |___
       |_|\___/_/\_\\__|\__,_|\__,_|_|  |___|_| \_\\____|

 Copyright (c) 2010 — 2013 Codeux Software & respective contributors.
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

@interface IRCWorld ()
/* No value is stored in any of these properties. They are declared
 as properties so that they can be accessed using dot (.) syntax in
 Objective-C. The actual value of each property is actually delcared
 below in the getter of the property name. */

@property (nonatomic, nweak, readonly) NSBox *channelViewBox;
@property (nonatomic, nweak, readonly) TVCServerList *serverList;
@property (nonatomic, nweak, readonly) TVCMemberList *memberList;
@end

@implementation IRCWorld;

#pragma mark -
#pragma mark Initialization

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

#pragma mark -
#pragma mark Configuration

- (void)setupConfiguration
{
	self.isPopulatingSeeds = YES;
	
	NSDictionary *config = [TPCPreferences loadWorld];

	for (NSDictionary *e in config[@"clients"]) {
		[self createClient:e reload:YES];
	}

	self.isPopulatingSeeds = NO;
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
			if (PointerIsEmpty(firstSelection)) {
				firstSelection = e;
			}
		}
	}
	
	if (firstSelection) {
		NSInteger n = [self.serverList rowForItem:firstSelection];

		if (NSObjectIsNotEmpty(firstSelection.channels)) {
			++n;
		}

		[self.serverList selectItemAtIndex:n];
	} else {
		[self.serverList selectItemAtIndex:0];
	}

	[self outlineViewSelectionDidChange:nil];
}

- (NSMutableDictionary *)dictionaryValue
{
	NSMutableArray *ary = [NSMutableArray array];

	for (IRCClient *u in self.clients) {
		[ary safeAddObject:[u dictionaryValue]];
	}

	return [@{@"clients" : ary} mutableCopy];
}

- (void)save
{
	[TPCPreferences saveWorld:[self dictionaryValue]];
	[TPCPreferences sync];
}

- (void)terminate
{
	[RZPluginManager() unloadPlugins];
	
	for (IRCClient *c in self.clients) {
		[c terminate];
	}
}

#pragma mark -
#pragma mark Properties

- (IRCClient *)selectedClient
{
	PointerIsEmptyAssertReturn(self.selectedItem, nil);
	
	return self.selectedItem.client;
}

- (IRCChannel *)selectedChannel
{
	PointerIsEmptyAssertReturn(self.selectedItem, nil);

	if (self.selectedItem.isClient) {
		return nil;
	}
	
	return (IRCChannel *)self.selectedItem;
}

- (IRCChannel *)selectedChannelOn:(IRCClient *)c
{
	IRCChannel *selectedChannel = self.selectedChannel;

	PointerIsEmptyAssertReturn(selectedChannel, nil);

	if ([c.treeUUID isEqualToString:selectedChannel.client.treeUUID] == NO) {
		return nil;
	}
	
	return (IRCChannel *)self.selectedItem;
}

- (TVCLogController *)selectedViewController
{
	PointerIsEmptyAssertReturn(self.selectedItem, nil);

	return [self.selectedItem viewController];
}

- (TVCServerList *)serverList
{
	return self.masterController.serverList;
}

- (TVCMemberList *)memberList
{
	return self.masterController.memberList;
}

- (NSBox *)channelViewBox
{
	return self.masterController.channelViewBox;
}

#pragma mark -
#pragma mark Utilities

- (void)addHighlightInChannel:(IRCChannel *)channel withLogLine:(TVCLogLine *)logLine
{
	PointerIsEmptyAssert(channel);
	PointerIsEmptyAssert(logLine);
	
	if ([TPCPreferences logHighlights]) {
		/* Render message. */
		NSString *messageBody;
		NSString *nicknameBody = [logLine formattedNickname:channel];

		if (logLine.lineType == TVCLogLineActionType) {
			if ([nicknameBody hasSuffix:@":"]) {
				messageBody = [NSString stringWithFormat:TXNotificationHighlightLogAlternativeActionFormat, nicknameBody, logLine.messageBody];
			} else {
				messageBody = [NSString stringWithFormat:TXNotificationHighlightLogStandardActionFormat, nicknameBody, logLine.messageBody];
			}
		} else {
			messageBody = [NSString stringWithFormat:TXNotificationHighlightLogStandardMessageFormat, nicknameBody, logLine.messageBody];
		}

		/* Create entry. */
		NSArray *entry = @[channel.name, @([NSDate epochTime]), [messageBody.trim attributedStringWithIRCFormatting:TXDefaultListViewControllerFont]];
		
		/* We insert at head so that latest is always on top. */
		[channel.client.highlights insertObject:entry atIndex:0];

		/* Reload table if the window is open. */
		id highlightSheet = [self.masterController.menuController windowFromWindowList:@"TDCHighlightSheet"];

		if (highlightSheet) {
			[highlightSheet reloadTable];
		}
	} else {
		[channel.client.highlights removeAllObjects];
	}
}

- (void)autoConnectAfterWakeup:(BOOL)afterWakeUp
{
	if (self.masterController.ghostMode && afterWakeUp == NO) {
		return;
	}
	
	NSInteger delay = 0;
	
	if (afterWakeUp) {
		delay += _reconnectAfterWakeupDelay;
	}
	
	for (IRCClient *c in self.clients) {
        if ((afterWakeUp && c.disconnectType == IRCDisconnectComputerSleepMode && c.config.autoSleepModeDisconnect) || afterWakeUp == NO) {
            if (c.config.autoConnect) {
                [c autoConnect:delay];
				
                delay += _autoConnectDelay;
            }
        }
	}
}

- (void)prepareForSleep
{
	for (IRCClient *c in self.clients) {
		if (c.config.autoSleepModeDisconnect) {
			c.disconnectType = IRCDisconnectComputerSleepMode;
        
			[c quit:c.config.sleepModeLeavingComment];
		}
	}
}

- (void)inputText:(id)str command:(NSString *)command
{
	PointerIsEmptyAssert(self.selectedItem);

	[self.selectedItem.client inputText:str command:command];
}

- (void)destroyAllEvidence
{
	for (IRCClient *u in self.clients) {
		[self clearContentsOfClient:u];

		for (IRCChannel *c in u.channels) {
			[self clearContentsOfChannel:c inClient:u];
		}
	}

	[self reloadTree];
	[self markAllAsRead];
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
		
		for (IRCChannel *c in u.channels) {
			[c resetState];
		}
	}
	
	[self reloadTree];
	[self markAllScrollbacks];
}

- (void)markAllScrollbacks
{
	NSAssertReturn([TPCPreferences autoAddScrollbackMark]);
	
	for (IRCClient *u in self.clients) {
		[u.viewController mark];
		
		for (IRCChannel *c in u.channels) {
			[c.viewController mark];
		}
	}
}

- (void)updateIcon
{
	NSAssertReturn([TPCPreferences displayDockBadge]);
	
	NSInteger messageCount = 0;
	NSInteger highlightCount = 0;
	
	for (IRCClient *u in self.clients) {
		for (IRCChannel *c in u.channels) {
			if ([c.name isEqualToString:TXTLS(@"ServerNoticeTreeItemTitle")]) {
				continue;
			}
			
			messageCount += c.dockUnreadCount;
			highlightCount += c.nicknameHighlightCount;
		}
	}
	
	if (messageCount == 0 && highlightCount == 0) {
		[TVCDockIcon drawWithoutCount];
	} else {
		[TVCDockIcon drawWithHilightCount:highlightCount messageCount:messageCount];
	}
}

- (void)reloadLoadingScreen
{
	if (self.isPopulatingSeeds == NO) {
		if (self.clients.count <= 0) {
			[self.masterController.mainWindowLoadingScreen hideAll:NO];
			[self.masterController.mainWindowLoadingScreen popWelcomeAddServerView];
		} else {
			[self.masterController.mainWindowLoadingScreen hideAll:YES];
		}
	}
}

- (void)reloadTree
{
	if (self.isReloadingTree) {
		[self.serverList setNeedsDisplay];
		
		return;
	}
	
	self.isReloadingTree = YES;
	
	[self.serverList reloadData];

	[self updateTitle];
	[self updateIcon];
	
	[self.masterController updateSegmentedController];

	self.isReloadingTree = NO;
}

- (void)expandClient:(IRCClient *)client
{
	[self.serverList expandItem:client];
}

- (void)adjustSelection
{
	NSInteger selectedRow = [self.serverList selectedRow];
	NSInteger selectionRow = [self.serverList rowForItem:self.selectedItem];

	if (0 <= selectedRow && NSDissimilarObjects(selectedRow, selectionRow)) {
		[self.serverList selectItemAtIndex:selectionRow];
		
		[self reloadTree];
	}
}

- (void)storePreviousSelection
{
	if (PointerIsEmpty(self.selectedItem)) {
		self.previousSelectedClientId = nil;
		self.previousSelectedChannelId = nil;
	} else if (self.selectedItem.isClient) {
		self.previousSelectedClientId = self.selectedItem.treeUUID;
		self.previousSelectedChannelId = 0;
	} else {		
		self.previousSelectedClientId = self.selectedItem.client.treeUUID;
		self.previousSelectedChannelId = self.selectedItem.treeUUID;
	}
}

- (IRCTreeItem *)previouslySelectedItem
{
	NSObjectIsEmptyAssertReturn(self.previousSelectedClientId, nil);
	
	NSString *uid = self.previousSelectedClientId;
	NSString *cid = self.previousSelectedChannelId;
	
	IRCTreeItem *item;
	
	if (NSObjectIsEmpty(cid)) {
		item = [self findClientById:uid];
	} else {
		item = [self findChannelByClientId:uid channelId:cid];
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

#pragma mark -
#pragma mark Window Title

- (void)updateTitle
{
	NSWindow *mainWindow = self.masterController.mainWindow;

	id selectedItem = self.selectedItem;
	
	if (PointerIsEmpty(selectedItem)) {
		[mainWindow setTitle:[TPCPreferences applicationName]];
		[mainWindow setRepresentedURL:nil]; // Hide lock.
		
		return;
	}
	
	IRCClient *client = self.selectedClient;
	IRCChannel *channel = self.selectedChannel;
	
	NSMutableString *title = [NSMutableString string];

	if ([selectedItem isClient]) {
		NSString *networkName = [client networkName];
		NSString *networkAddress = [client networkAddress];

		if (NSObjectIsEmpty(networkName)) {
			[title appendString:client.name];
		} else {
			[title appendString:networkName];
		}
		
		if (NSObjectIsNotEmpty(title)) {
			[title appendString:@" — "];
		}

		if (NSObjectIsEmpty(networkAddress)) {
			[title appendString:client.config.serverAddress];
		} else {
			[title appendString:networkAddress];
		}
	} else {
		NSString *networkName = [client networkName];

		if (NSObjectIsEmpty(networkName)) {
			[title appendString:client.name];
		} else {
			[title appendString:networkName];
		}
		
		if (NSObjectIsNotEmpty(title)) {
			[title appendString:@" — "];
		}
		
		if (NSObjectIsNotEmpty(channel.name)) {
			[title appendString:channel.name];
		}
		
		if (channel.isChannel) {
			[title appendFormat:TXTLS(@"ChannelApplicationTitleUserCount"), channel.numberOfMembers];
			
			NSString *modes = [channel.modeInfo titleString];
			
			if (modes.length >= 2) {
				[title appendFormat:TXTLS(@"ChannelApplicationTitleModeValue"), modes];
			}
		}
	}

	[mainWindow setTitle:title];
	[mainWindow setRepresentedURL:[NSBundle.mainBundle bundleURL]];

	if (client.config.connectionUsesSSL) {
		[[mainWindow standardWindowButton:NSWindowDocumentIconButton] setImage:[NSImage imageNamed:@"NSLockLockedTemplate"]];
	} else {
		[[mainWindow standardWindowButton:NSWindowDocumentIconButton] setImage:[NSImage imageNamed:@"NSLockUnlockedTemplate"]];
	}
}

#pragma mark -
#pragma mark Tree Items

- (IRCClient *)findClientById:(NSString *)uid
{
	for (IRCClient *u in self.clients) {
		if ([u.treeUUID isEqualToString:uid]) {
			return u;
		}
	}
	
	return nil;
}

- (IRCChannel *)findChannelByClientId:(NSString *)uid channelId:(NSString *)cid
{
	for (IRCClient *u in self.clients) {
		if ([u.treeUUID isEqualToString:uid]) {
			for (IRCChannel *c in u.channels) {
				if ([c.treeUUID isEqualToString:cid]) {
					return c;
				}
			}
		}
	}
	
	return nil;
}

- (void)select:(id)item
{
	if (self.selectedItem == item) {
		return;
	}
	
	[self storePreviousSelection];
	
	if (PointerIsEmpty(item)) {
		self.selectedItem = nil;

		[self.channelViewBox setContentView:nil];

		[self.memberList setDataSource:nil];
		[self.memberList reloadData];
		
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

		if (isClient) {
			client.lastSelectedChannel = nil;
		} else {
			client.lastSelectedChannel = (IRCChannel *)item;
		}
	}
}

#pragma mark -
#pragma mark Theme

- (void)reloadTheme
{
	[self.masterController.themeController load];

	for (IRCClient *u in self.clients) {
		[u.viewController reloadTheme];
		
		for (IRCChannel *c in u.channels) {
			[c.viewController reloadTheme];
		}
	}
	
	[self.serverList updateBackgroundColor];
	[self.memberList updateBackgroundColor];

	[self.masterController.serverSplitView setNeedsDisplay:YES];
	[self.masterController.memberSplitView setNeedsDisplay:YES];

	[self.masterController.inputTextField redrawOriginPoints];
	[self.masterController.inputTextField updateTextColor];
}

- (void)changeTextSize:(BOOL)bigger
{
	for (IRCClient *u in self.clients) {
		[u.viewController changeTextSize:bigger];
		
		for (IRCChannel *c in u.channels) {
			[c.viewController changeTextSize:bigger];
		}
	}
}

#pragma mark -
#pragma mark Factory

- (void)clearContentsOfChannel:(IRCChannel *)c inClient:(IRCClient *)u
{
	[c resetState];

	[c.viewController clear];
	[c.viewController notifyDidBecomeVisible];

	if ([c.treeUUID isEqualToString:self.selectedChannel.treeUUID]) {
		[self outlineViewSelectionDidChange:nil];
	}
	
	[c.viewController setTopic:c.topic];
}

- (void)clearContentsOfClient:(IRCClient *)u
{
	[u resetState];

	[u.viewController clear];
	[u.viewController notifyDidBecomeVisible];

	if ([u.treeUUID isEqualToString:self.selectedClient.treeUUID]) {
		[self outlineViewSelectionDidChange:nil];
	}
}

- (IRCClient *)createClient:(id)seed reload:(BOOL)reload
{
	IRCClient *c = [IRCClient new];
	
	[c setup:seed];

	PointerIsEmptyAssertReturn(c.config, nil);
	
	c.viewController = [self createLogWithClient:c channel:nil];

	if ([TPCPreferences inputHistoryIsChannelSpecific]) {
		c.inputHistory = [TLOInputHistory new];
	}

	for (IRCChannelConfig *e in c.config.channelList) {
		[self createChannel:e client:c reload:NO adjust:NO];
	}
	
	[self.clients safeAddObject:c];
	
	if (reload) {
		[self reloadTree];
	}

	[self reloadLoadingScreen];
	
	return c;
}

- (IRCChannel *)createChannel:(IRCChannelConfig *)seed client:(IRCClient *)client reload:(BOOL)reload adjust:(BOOL)adjust
{
	PointerIsEmptyAssertReturn(client, nil);
	
	IRCChannel *c = [client findChannel:seed.channelName];

	if (NSObjectIsNotEmpty(c.name)) {
		return c;
	}

	c = [IRCChannel new];
	
	c.client = client;

	if ([TPCPreferences inputHistoryIsChannelSpecific]) {
		c.inputHistory = [TLOInputHistory new];
	}
	
	c.modeInfo.isupport = client.isupport;
	
	[c setup:seed];
	
	c.viewController = [self createLogWithClient:client channel:c];

	if (seed.type == IRCChannelNormalType) {
		NSInteger n = [client indexOfFirstPrivateMessage];

		if (n >= 0) {
			[client.channels safeInsertObject:c atIndex:n];
		} else {
			[client.channels safeAddObject:c];
		}
	} else {
		[client.channels safeAddObject:c];
	}
	
	if (reload) {
		[self reloadTree];
	}
	
	if (adjust) {
		[self adjustSelection];
	}
	
	return c;
}

- (IRCChannel *)createPrivateMessage:(NSString *)nick client:(IRCClient *)client
{
	PointerIsEmptyAssertReturn(client, nil);
	
	NSObjectIsEmptyAssertReturn(nick, nil);
	
	IRCChannelConfig *seed = [IRCChannelConfig new];
	
	seed.channelName = nick;
	seed.type = IRCChannelPrivateMessageType;
	
	IRCChannel *c = [self createChannel:seed client:client reload:YES adjust:YES];
	
	if (client.isLoggedIn) {
		[c activate];
		
		IRCUser *m = nil;
		
		m = [IRCUser new];
		m.nickname = client.localNickname;
		[c addMember:m];
		
		m = [IRCUser new];
		m.nickname = c.name;
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
		[self.clients removeObjectIdenticalTo:target];
	} else {		
		[target.client.channels removeObjectIdenticalTo:target];
	}
	
	[self reloadTree];
	
	if (self.selectedItem) {
		[self.serverList selectItemAtIndex:[self.serverList rowForItem:sel]];
	}
}

- (void)destroyClient:(IRCClient *)u
{
	[u terminate];
	[u disconnect];
	
	if (self.selectedItem && self.selectedItem.client == u) {
		[self selectOtherAndDestroy:u];
	} else {		
		[self.clients removeObjectIdenticalTo:u];
		
		[self reloadTree];
		[self adjustSelection];
	}

	[self reloadLoadingScreen];
}

- (void)destroyChannel:(IRCChannel *)c
{
    [self destroyChannel:c part:YES];
}

- (void)destroyChannel:(IRCChannel *)c part:(BOOL)forcePart
{
	IRCClient *u = c.client;
	
	if (c.isChannel && forcePart) {
		if (u.isLoggedIn && c.isActive) {
			[u partChannel:c];
		}
	}
    
	[c terminate];
	
	if (u.lastSelectedChannel == c) {
		u.lastSelectedChannel = nil;
	}
	
	if (self.selectedItem == c) {
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

	c.client = client;
	c.channel = channel;
	c.maximumLineCount = [TPCPreferences maxLogLines];
	
	[c setUp];
	
	[c.view setHostWindow:self.masterController.mainWindow];
	
	return c;
}

#pragma mark -
#pragma mark Log Delegate

- (void)logKeyDown:(NSEvent *)e
{
	[self.masterController.inputTextField focus];

	if (e.keyCode == TXKeyReturnCode ||
		e.keyCode == TXKeyEnterCode)
	{
		return;
	}

	[self.masterController.mainWindow sendEvent:e];
}

- (void)logDoubleClick:(NSString *)s
{
	NSArray *ary = [s componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];

	NSObjectIsEmptyAssert(ary);

	NSString *kind = [ary safeObjectAtIndex:0];
	
	if ([kind isEqualToString:@"client"]) {
		if (ary.count >= 2) {
			NSString *uid = [ary objectAtIndex:1];
			
			IRCClient *u = [self findClientById:uid];
			
			if (u) {
				[self select:u];
			}
		}
	} else if ([kind isEqualToString:@"channel"]) {
		if (ary.count >= 3) {
			NSString *uid = [ary objectAtIndex:1];
			NSString *cid = [ary objectAtIndex:2];
			
			IRCChannel *c = [self findChannelByClientId:uid channelId:cid];
			
			if (c) {
				[self select:c];
			}
		}
	}
}

#pragma mark -
#pragma mark NSOutlineView Delegate

- (void)outlineViewDoubleClicked:(id)sender
{
	PointerIsEmptyAssert(self.selectedItem);
	
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
	PointerIsEmptyAssertReturn(item, self.clients.count);
	
	return [item numberOfChildren];
}

- (BOOL)outlineView:(NSOutlineView *)sender isItemExpandable:(id)item
{
	return ([item numberOfChildren] > 0);
}

- (id)outlineView:(NSOutlineView *)outlineView child:(NSInteger)index ofItem:(IRCTreeItem *)item
{
	PointerIsEmptyAssertReturn(item, self.clients[index]);
	
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
	cell.cellItem = item;
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

	BOOL selected = (self.selectedItem == item);

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
	TVCInputTextField *textField = self.masterController.inputTextField;
	
	[RZSpellChecker() setIgnoredWords:@[] inSpellDocumentWithTag:textField.spellCheckerDocumentTag];
	
	id nextItem = [self.serverList itemAtRow:self.serverList.selectedRow];
	
	self.selectedItem = nextItem;
	
	if (PointerIsEmpty(self.selectedItem)) {
		[self.channelViewBox setContentView:nil];
		
		self.memberList.dataSource = nil;
		self.memberList.delegate = nil;
        
		[self.memberList reloadData];
		
		self.serverList.menu = self.masterController.addServerMenu;
		
		return;
	}
	
	[self.selectedItem resetState];
	
	TVCLogController *log = self.selectedViewController;

	[self.channelViewBox setContentView:log.view];
	
	[log notifyDidBecomeVisible];
	
	if ([self.selectedItem isClient]) {
		self.serverList.menu = self.masterController.serverMenuItem.submenu;
		
		self.memberList.dataSource = nil;
		self.memberList.delegate = nil;
		
		[self.memberList reloadData];
	} else {		
		self.serverList.menu = self.masterController.channelMenuItem.submenu;
		
		self.memberList.dataSource = self.selectedItem;
		self.memberList.delegate = self.selectedItem;
		
		[self.memberList reloadData];
	}
	
	[self.memberList deselectAll:nil];
	[self.memberList scrollRowToVisible:0];
    
    [textField focus];
	
	[log.view clearSelection];
	
	if ([TPCPreferences inputHistoryIsChannelSpecific]) {
		NSAttributedString *inputValue = [textField attributedStringValue];
		
		self.masterController.inputHistory = self.selectedItem.inputHistory;
		
		IRCTreeItem *previous = [self previouslySelectedItem];
		
		TLOInputHistory *oldHistory = previous.inputHistory;
		TLOInputHistory *newHistory = self.selectedItem.inputHistory;
		
		[oldHistory setLastHistoryItem:inputValue];
		
		[textField setStringValue:NSStringEmptyPlaceholder];
		
		if (NSObjectIsNotEmpty(newHistory.lastHistoryItem)) {
			[textField setAttributedStringValue:newHistory.lastHistoryItem];
		}
	}

	IRCChannel *channel = (IRCChannel *)self.selectedItem;
	
	if (self.selectedItem.isClient || channel.isPrivateMessage) {
		[self.masterController showMemberListSplitView:NO];
	} else {
		[self.masterController showMemberListSplitView:YES];
	}

	[self updateIcon];
	[self updateTitle];

    if (self.previouslySelectedItem && [self.serverList isGroupItem:self.previouslySelectedItem]) {
        /* Draw the view again if our previous selection was a server.
         This is done to redraw the disclosure triangles in dark mode. */
        
        [self.serverList setNeedsDisplay];
    }
}

- (BOOL)outlineView:(NSOutlineView *)sender writeItems:(NSArray *)items toPasteboard:(NSPasteboard *)pboard
{
	NSObjectIsEmptyAssertReturn(items, NO);
	
	IRCTreeItem *i = [items safeObjectAtIndex:0];

	NSString *s = i.treeUUID;
	
	if (i.isClient == NO) {
		s = [NSString stringWithFormat:@"%@-%@", i.client.treeUUID, i.treeUUID];
	}
	
	[pboard declareTypes:_treeDragItemTypes owner:self];
	
	[pboard setPropertyList:s forType:_treeDragItemType];
	
	return YES;
}

- (IRCTreeItem *)findItemFromInfo:(NSString *)s
{
	NSObjectIsEmptyAssertReturn(s, nil);
	
	if ([s contains:@"-"]) {
		NSArray *ary = [s componentsSeparatedByString:@"-"];

		NSString *uid = [ary objectAtIndex:0];
		NSString *cid = [ary objectAtIndex:1];
		
		return [self findChannelByClientId:uid channelId:cid];
	} else {
		return [self findClientById:s];
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
	
	NSInteger n = [self.serverList rowForItem:self.selectedItem];
	
	if (n >= 0) {
		[self.masterController.serverList selectItemAtIndex:n];
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
	PointerIsEmptyAssertReturn(block, nil);
	PointerIsEmptyAssertReturn(controller, nil);
	
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
	id target = self.controller.channel;

	if (PointerIsEmpty(target)) {
		target = self.controller.client;
	}

	id selected = self.worldController.selectedItem;
	
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
