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

	if ([config boolForKey:@"soundIsMuted"]) {
		[self muteSound];
	} else {
		[self unmuteSound];
	}

	self.isPopulatingSeeds = NO;
}

- (void)setupTree
{
	/* Set double click action. */
	[self.serverList setTarget:self];
	[self.serverList setDoubleAction:@selector(outlineViewDoubleClicked:)];

	/* Inform the table we want drag events. */
	[self.serverList registerForDraggedTypes:_treeDragItemTypes];

	/* Prepare our first selection. */
	IRCClient *firstSelection = nil;
	
	for (IRCClient *e in self.clients) {
        if (e.config.sidebarItemExpanded) {
            [self expandClient:e];
            
            if (e.config.autoConnect) {
                if (PointerIsEmpty(firstSelection)) {
                    firstSelection = e;
                }
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

	[self.serverList updateBackgroundColor];
	[self.memberList updateBackgroundColor];
}

- (NSMutableDictionary *)dictionaryValue
{
	NSMutableArray *ary = [NSMutableArray array];

	for (IRCClient *u in self.clients) {
		[ary safeAddObject:[u dictionaryValue]];
	}

	NSMutableDictionary *dict = [NSMutableDictionary dictionary];
	
	[dict safeSetObject:ary						forKey:@"clients"];
	[dict safeSetObject:@(self.isSoundMuted)	forKey:@"soundIsMuted"];

	return dict;
}

- (void)save
{
	[TPCPreferences saveWorld:[self dictionaryValue]];
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
		NSString *nicknameBody = [logLine formattedNickname:channel].trim;

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
		NSArray *entry = @[channel.name, @([NSDate epochTime]), [messageBody attributedStringWithIRCFormatting:TXDefaultListViewControllerFont]];
		
		/* We insert at head so that latest is always on top. */
		[channel.client.highlights insertObject:entry atIndex:0];

		/* Reload table if the window is open. */
		id highlightSheet = [self.masterController.menuController windowFromWindowList:@"TDCHighlightListSheet"];

		if (highlightSheet) {
            [highlightSheet performSelector:@selector(reloadTable) withObject:nil afterDelay:2.0];
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
                [c autoConnect:delay afterWakeUp:afterWakeUp];
				
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

- (void)prepareForScreenSleep
{
    NSAssertReturn([TPCPreferences setAwayOnScreenSleep]);

	for (IRCClient *c in self.clients) {
        [c toggleAwayStatus:YES];
	}
}

- (void)awakeFomScreenSleep
{
    NSAssertReturn([TPCPreferences setAwayOnScreenSleep]);

	for (IRCClient *c in self.clients) {
        [c toggleAwayStatus:NO];
	}
}

- (void)inputText:(id)str command:(NSString *)command
{
	PointerIsEmptyAssert(self.selectedItem);

    str = [RZPluginManager() processInterceptedUserInput:str command:command];

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

	if (limitedClient) {
		[self reloadTreeGroup:limitedClient];
	} else {
		[self reloadTree];
	}

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

- (void)reloadTreeItem:(IRCTreeItem *)item
{
	[self.serverList updateDrawingForItem:item];
}

- (void)reloadTreeGroup:(IRCTreeItem *)item
{
	[self.serverList updateDrawingForItem:item];

	for (IRCChannel *channel in item.client.channels) {
		[self reloadTreeItem:channel];
	}
}

- (void)reloadTree
{
	[self.serverList reloadAllDrawings];
}

- (void)expandClient:(IRCClient *)client
{
	[self.serverList.animator expandItem:client];
}

- (void)adjustSelection
{
	NSInteger selectedRow = [self.serverList selectedRow];
	NSInteger selectionRow = [self.serverList rowForItem:self.selectedItem];

	if (0 <= selectedRow && NSDissimilarObjects(selectedRow, selectionRow)) {
		[self.serverList selectItemAtIndex:selectionRow];
	}
}

- (void)storePreviousSelection
{
	if (PointerIsEmpty(self.selectedItem)) {
		self.previousSelectedClientId = nil;
		self.previousSelectedChannelId = nil;
	} else if (self.selectedItem.isClient) {
		self.previousSelectedClientId = self.selectedItem.treeUUID;
		self.previousSelectedChannelId = nil;
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
	
	IRCTreeItem *item = nil;
	
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

- (void)updateTitleFor:(IRCTreeItem *)item
{
	if (self.selectedItem == item) {
		[self updateTitle];
	}
}

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
		[title appendString:client.altNetworkName];
		[title appendString:@" — "];
        
		NSString *networkAddress = [client networkAddress];

		if (NSObjectIsEmpty(networkAddress)) {
			[title appendString:client.config.serverAddress];
		} else {
			[title appendString:networkAddress];
		}
	} else {
		[title appendString:client.altNetworkName];
		[title appendString:@" — "];

        if (channel.isPrivateMessage) {
            /* Textual defines the topic of a private message as the user host. */
            NSString *hostmask = channel.topic;

            if ([hostmask isHostmask] == NO) {
                [title appendString:channel.name];
            } else {
                [title appendString:hostmask];
            }
        }
		
		if (channel.isChannel) {
			[title appendString:channel.name];
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
		if ([u.treeUUID isEqualToString:uid] || [u.config.itemUUID isEqualToString:uid]) {
			return u;
		}
	}
	
	return nil;
}

- (IRCChannel *)findChannelByClientId:(NSString *)uid channelId:(NSString *)cid
{
	for (IRCClient *u in self.clients) {
		if ([u.treeUUID isEqualToString:uid] || [u.config.itemUUID isEqualToString:uid]) {
			for (IRCChannel *c in u.channels) {
				if ([c.treeUUID isEqualToString:cid] || [c.config.itemUUID isEqualToString:cid]) {
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
		[self.serverList.animator expandItem:client];
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

	[self.serverList reloadAllDrawingsIgnoringOtherReloads];
	[self.serverList updateBackgroundColor];
	
	[self.memberList updateBackgroundColor];

	[self.masterController.serverSplitView setNeedsDisplay:YES];
	[self.masterController.memberSplitView setNeedsDisplay:YES];

	[self.masterController.inputTextField redrawOriginPoints];
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

- (NSInteger)textSizeMultiplier
{
	/* The text size multiplier is used when creating new views to match
	 existing font size changes using cmd+=/- which is dynamic in the 
	 changeTextSize: call above. We get the multiplier by asking the
	 first view that exists in Textual what its multiplier is. If there
	 is no first view, then we default to 1.0 which is 100%. */

	IRCClient *c = [self.clients safeObjectAtIndex:0];

	if (c) {
		return c.viewController.view.textSizeMultiplier;
	}

	return 1;
}

#pragma mark -
#pragma mark JavaScript

- (void)executeScriptCommandOnAllViews:(NSString *)command arguments:(NSArray *)args
{
	for (IRCClient *u in self.clients) {
		[u.viewController executeScriptCommand:command withArguments:args];

		for (IRCChannel *c in u.channels) {
			[c.viewController executeScriptCommand:command withArguments:args];
		}
	}
}

#pragma mark -
#pragma mark Factory

- (void)clearContentsOfChannel:(IRCChannel *)c inClient:(IRCClient *)u
{
	[c resetState];

	[c.operationQueue destroyOperationsForChannel:c];

	[c.viewController clear];
	[c.viewController notifyDidBecomeVisible];

	if ([c.treeUUID isEqualToString:self.selectedChannel.treeUUID]) {
		[self outlineViewSelectionDidChange:nil];
	}
	
	[c.viewController setTopic:c.topic];

	[self reloadTreeItem:c];
}

- (void)clearContentsOfClient:(IRCClient *)u
{
	[u resetState];

	[u.operationQueue destroyOperationsForClient:u];

	[u.viewController clear];
	[u.viewController notifyDidBecomeVisible];

	if ([u.treeUUID isEqualToString:self.selectedClient.treeUUID]) {
		[self outlineViewSelectionDidChange:nil];
	}

	[self reloadTreeItem:u];
}

- (IRCClient *)createClient:(id)seed reload:(BOOL)reload
{
	IRCClient *c = [IRCClient new];
	
	[c setup:seed];

	PointerIsEmptyAssertReturn(c.config, nil);

	c.viewController = [self createLogWithClient:c channel:nil];
    c.operationQueue = [TVCLogControllerOperationQueue new];

	if ([TPCPreferences inputHistoryIsChannelSpecific]) {
		c.inputHistory = [TLOInputHistory new];
	}

	for (IRCChannelConfig *e in c.config.channelList) {
		[self createChannel:e client:c reload:NO adjust:NO];
	}
	
	[self.clients safeAddObject:c];
	
	if (reload) {
		NSInteger index = [self.clients indexOfObject:c];

		[self.serverList addItemToList:index inParent:nil];
	}

	if (self.clients.count == 1) {
		/* If our client count is 1, then it means we just added our
		 first client ever. We want to force the selection to this 
		 because if we had no client beforehand, then we did not have
		 any selection at all. */

		[self select:c];
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
		NSInteger index = [client.channels indexOfObject:c];

		[self.serverList addItemToList:index inParent:client];
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
	
	seed.type = IRCChannelPrivateMessageType;
	seed.channelName = nick;
	
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

	[self.serverList removeItemFromList:target];
	
	if (self.selectedItem) {
		[self.serverList selectItemAtIndex:[self.serverList rowForItem:sel]];
	}
}

- (void)destroyClient:(IRCClient *)u
{
	[u terminate];
	
	if (self.selectedItem && self.selectedItem.client == u) {
		[self selectOtherAndDestroy:u];
	} else {		
		[self.clients removeObjectIdenticalTo:u];

		[self.serverList removeItemFromList:u];

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

		[self.serverList removeItemFromList:c];

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

- (CGFloat)outlineView:(NSOutlineView *)outlineView heightOfRowByItem:(IRCTreeItem *)item
{
	if (PointerIsEmpty(item) || item.isClient) {
		return _treeClientHeight;
	}
	
	return _treeChannelHeight;
}

- (NSTableRowView *)outlineView:(NSOutlineView *)outlineView rowViewForItem:(id)item
{
	TVCserverlistRowCell *rowView = [[TVCserverlistRowCell alloc] initWithFrame:NSZeroRect];

	return rowView;
}

- (NSView *)outlineView:(NSOutlineView *)outlineView viewForTableColumn:(NSTableColumn *)tableColumn item:(IRCTreeItem *)item
{
	/* Ask our view controller what we are. */
	if (PointerIsEmpty(item.viewController.channel)) {
		/* We are a group item. A client. */

		NSView *newView = [outlineView makeViewWithIdentifier:@"GroupView" owner:self];

		if ([newView isKindOfClass:[TVCServerListCellGroupItem class]]) {
			TVCServerListCellGroupItem *groupItem = (TVCServerListCellGroupItem *)newView;

			[groupItem setCellItem:item];
		}

		return newView;
	} else {
		/* We are a child item. A channel. */
		NSView *newView = [outlineView makeViewWithIdentifier:@"ChildView" owner:self];

		if ([newView isKindOfClass:[TVCServerListCellChildItem class]]) {
			TVCServerListCellChildItem *childItem = (TVCServerListCellChildItem *)newView;

			[childItem setCellItem:item];
		}

		return newView;
	}

	return nil;
}

- (void)outlineView:(NSOutlineView *)outlineView didAddRowView:(NSTableRowView *)rowView forRow:(NSInteger)row
{
	[self.serverList updateDrawingForRow:row skipDrawingCheck:YES];
}

- (BOOL)outlineView:(NSOutlineView *)outlineView shouldExpandItem:(IRCTreeItem *)item
{
	[item.client.config setSidebarItemExpanded:YES];

	return YES;
}

- (BOOL)outlineView:(NSOutlineView *)outlineView shouldCollapseItem:(IRCTreeItem *)item
{
	[item.client.config setSidebarItemExpanded:NO];

	return YES;
}

- (void)outlineViewItemWillCollapse:(NSNotification *)notification
{
	PointerIsEmptyAssert(self.selectedChannel);

	/* If the item being collapsed is the one our selected channel is on,
	 then move selection to the console of the collapsed server. */
	id itemBeingCollapsed = [notification.userInfo objectForKey:@"NSObject"];

	if (itemBeingCollapsed == self.selectedClient) {
		[self select:self.selectedClient];
	}
}

- (void)outlineViewSelectionDidChange:(NSNotification *)note
{
	[self storePreviousSelection];
	
	TVCInputTextField *textField = self.masterController.inputTextField;
	
	[RZSpellChecker() setIgnoredWords:@[] inSpellDocumentWithTag:textField.spellCheckerDocumentTag];
	
	id nextItem = [self.serverList itemAtRow:self.serverList.selectedRow];

	[self.selectedItem resetState]; // Reset state of old item.
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
	[self.memberList updateBackgroundColor];
    
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

	[self.masterController updateSegmentedController];

	[self updateIcon];
	[self updateTitle];

	[self.serverList updateDrawingForItem:self.selectedItem skipDrawingCheck:YES];
	[self.serverList updateDrawingForItem:self.previouslySelectedItem skipDrawingCheck:YES];
}

- (BOOL)outlineView:(NSOutlineView *)sender writeItems:(NSArray *)items toPasteboard:(NSPasteboard *)pboard
{
	NSObjectIsEmptyAssertReturn(items, NO);
	
	IRCTreeItem *i = [items safeObjectAtIndex:0];

	NSString *s = i.treeUUID;
	
	if (i.isClient == NO) {
		s = [NSString stringWithFormat:@"%@ %@", i.client.treeUUID, i.treeUUID];
	}
	
	[pboard declareTypes:_treeDragItemTypes owner:self];
	
	[pboard setPropertyList:s forType:_treeDragItemType];
	
	return YES;
}

- (IRCTreeItem *)findItemFromInfo:(NSString *)s
{
	NSObjectIsEmptyAssertReturn(s, nil);
	
	if ([s contains:@" "]) {
		NSArray *ary = [s split:@" "];

		NSString *uid = [ary objectAtIndex:0];
		NSString *cid = [ary objectAtIndex:1];
		
		return [self findChannelByClientId:uid channelId:cid];
	} else {
		return [self findClientById:s];
	}
}

- (NSDragOperation)outlineView:(NSOutlineView *)sender validateDrop:(id < NSDraggingInfo >)info proposedItem:(id)item proposedChildIndex:(NSInteger)index
{
    NSAssertReturnR((index >= 0), NSDragOperationNone);
	
	NSPasteboard *pboard = [info draggingPasteboard];
    PointerIsEmptyAssertReturn([pboard availableTypeFromArray:_treeDragItemTypes], NSDragOperationNone);
	
	NSString *infoStr = [pboard propertyListForType:_treeDragItemType];
    PointerIsEmptyAssertReturn(infoStr, NSDragOperationNone);
	
	IRCTreeItem *i = [self findItemFromInfo:infoStr];
    PointerIsEmptyAssertReturn(i, NSDragOperationNone);
	
	if (i.isClient) {
		if (item) {
			return NSDragOperationNone;
		}
	} else {
        PointerIsEmptyAssertReturn(item, NSDragOperationNone);
		
		IRCChannel *c = (IRCChannel *)i;
        
		if (NSDissimilarObjects(item, c.client)) {
            return NSDragOperationNone;
        }
		
		IRCClient *toClient = (IRCClient *)item;
		
		NSArray *ary = toClient.channels;
		
		NSMutableArray *low = [[ary subarrayWithRange:NSMakeRange(0, index)] mutableCopy];
		NSMutableArray *high = [[ary subarrayWithRange:NSMakeRange(index, (ary.count - index))] mutableCopy];
		
		[low removeObjectIdenticalTo:c];
		[high removeObjectIdenticalTo:c];
		
		if (c.isChannel) {
			if (NSObjectIsNotEmpty(low)) {
				IRCChannel *prev = [low lastObject];

                NSAssertReturnR(prev.isChannel, NSDragOperationNone);
			}
		} else {
			if (NSObjectIsNotEmpty(high)) {
				IRCChannel *next = [high safeObjectAtIndex:0];

                NSAssertReturnR((next.isChannel == NO), NSDragOperationNone);
			}
		}
	}
	
	return NSDragOperationGeneric;
}

- (BOOL)outlineView:(NSOutlineView *)sender acceptDrop:(id <NSDraggingInfo>)info item:(id)item childIndex:(NSInteger)index
{
    NSAssertReturnR((index >= 0), NSDragOperationNone);

	NSPasteboard *pboard = [info draggingPasteboard];
    PointerIsEmptyAssertReturn([pboard availableTypeFromArray:_treeDragItemTypes], NSDragOperationNone);

	NSString *infoStr = [pboard propertyListForType:_treeDragItemType];
    PointerIsEmptyAssertReturn(infoStr, NSDragOperationNone);

	IRCTreeItem *i = [self findItemFromInfo:infoStr];
    PointerIsEmptyAssertReturn(i, NSDragOperationNone);
	
	if (i.isClient) {
		if (item) {
            return NO;
        }
		
		NSMutableArray *ary = self.clients;
        
		NSMutableArray *low = [[ary subarrayWithRange:NSMakeRange(0, index)] mutableCopy];
		NSMutableArray *high = [[ary subarrayWithRange:NSMakeRange(index, (ary.count - index))] mutableCopy];

		NSInteger originalIndex = [ary indexOfObject:i];

		[low removeObjectIdenticalTo:i];
		[high removeObjectIdenticalTo:i];
		
		[ary removeAllObjects];
		
		[ary addObjectsFromArray:low];
		[ary safeAddObject:i];
		[ary addObjectsFromArray:high];

		NSArray *childItems = [self.serverList groupItems];

		NSObjectIsEmptyAssertReturn(childItems, NO);

		NSInteger oldIndex = [childItems indexOfObject:i];
		NSInteger newIndex = 0;

		id lastObject = low.lastObject;

		if (lastObject) {
			newIndex = [childItems indexOfObject:lastObject];

			if (originalIndex <= oldIndex && newIndex < (childItems.count - 1)) {
				newIndex += 1;
			}
		}

		if (oldIndex == newIndex) {
			return NO;
		}

		[self.serverList moveItemAtIndex:oldIndex inParent:nil toIndex:newIndex inParent:nil];
		
		[self save];
	} else {
		if (PointerIsEmpty(item) || NSDissimilarObjects(item, i.client)) {
            return NO;
        }
		
		IRCClient *u = (IRCClient *)item;
		
		NSMutableArray *ary = u.channels;
        
		NSMutableArray *low = [[ary subarrayWithRange:NSMakeRange(0, index)] mutableCopy];
		NSMutableArray *high = [[ary subarrayWithRange:NSMakeRange(index, (ary.count - index))] mutableCopy];

		NSInteger originalIndex = [ary indexOfObject:i];
		
		[low removeObjectIdenticalTo:i];
		[high removeObjectIdenticalTo:i];
		
		[ary removeAllObjects];
		
		[ary addObjectsFromArray:low];
		[ary safeAddObject:i];
		[ary addObjectsFromArray:high];

		NSArray *childItems = [self.serverList rowsFromParentGroup:u];

		NSObjectIsEmptyAssertReturn(childItems, NO);

		NSInteger oldIndex = [childItems indexOfObject:i];
		NSInteger newIndex = 0;
		
		id lastObject = low.lastObject;

		if (lastObject) {
			newIndex  = [childItems indexOfObject:lastObject];
			newIndex += 1;
			
			if (newIndex > originalIndex) {
				newIndex -= 1;
			}
		}

		if (oldIndex == newIndex) {
			return NO;
		}

		[self.serverList moveItemAtIndex:oldIndex inParent:u toIndex:newIndex inParent:u];

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
#pragma mark Mute Sound

- (void)muteSound
{
    [self setIsSoundMuted:YES];
	
    [self.masterController.menuController.muteSound setState:NSOnState];
}

- (void)unmuteSound
{
    [self setIsSoundMuted:NO];
	
    [self.masterController.menuController.muteSound setState:NSOffState];
}

@end
