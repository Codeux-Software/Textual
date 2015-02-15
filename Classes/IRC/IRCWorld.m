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

#import "IRCWorldPrivate.h"

#define _autoConnectDelay				1
#define _reconnectAfterWakeupDelay		8

@implementation IRCWorld

#pragma mark -
#pragma mark Initialization

- (instancetype)init
{
	if ((self = [super init])) {
		self.clients = [NSMutableArray new];
		
		self.textSizeMultiplier = 1.0;
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
		[menuController() toggleMuteOnNotificationSoundsShortcut:NSOnState];
	}

	self.isPopulatingSeeds = NO;
}

- (void)setupOtherServices
{
	[RZNotificationCenter() addObserver:self selector:@selector(userDefaultsDidChange:) name:TPCPreferencesUserDefaultsDidChangeNotification object:nil];
}

- (NSMutableDictionary *)dictionaryValue
{
	NSMutableArray *ary = [NSMutableArray array];

	for (IRCClient *u in [self clientList]) {
		[ary addObject:[u dictionaryValue]];
	}

	NSMutableDictionary *dict = [NSMutableDictionary dictionary];
	
	dict[@"clients"] = ary;
	
	dict[@"soundIsMuted"] = @([sharedGrowlController() areNotificationSoundsDisabled]);

	return dict;
}

- (void)save
{
	[TPCPreferences saveWorld:[self dictionaryValue]];
}

- (void)prepareForApplicationTermination
{
	[RZNotificationCenter() removeObserver:self];

	@synchronized(self.clients) {
		for (IRCClient *c in self.clients) {
			[c prepareForApplicationTermination];
		}
	}
}

- (void)userDefaultsDidChange:(NSNotification *)notification
{
	[self performBlockOnMainThread:^{
		[self executeScriptCommandOnAllViews:@"preferencesDidChange" arguments:@[] onQueue:YES];
	}];
}

- (void)informViewsThatTheSidebarInversionPreferenceDidChange
{
	[self executeScriptCommandOnAllViews:@"sidebarInversionPreferenceChanged" arguments:@[] onQueue:NO];
}

#pragma mark -
#pragma mark Properties

- (NSArray *)clientList
{
	__block NSArray *clientList = nil;
	
	XRPerformBlockOnSharedMutableSynchronizationDispatchQueue(^{
		@synchronized(self.clients) {
			clientList = [NSArray arrayWithArray:self.clients];
		}
	});
	
	return clientList;
}

- (void)setClientList:(NSArray *)clientList
{
	XRPerformBlockOnSharedMutableSynchronizationDispatchQueue(^{
		@synchronized(self.clients) {
			[self.clients removeAllObjects];
			
			[self.clients addObjectsFromArray:clientList];
		}
	});
}

- (NSInteger)clientCount
{
	__block NSInteger clientCount = 0;
	
	XRPerformBlockOnSharedMutableSynchronizationDispatchQueue(^{
		@synchronized(self.clients) {
			clientCount = [self.clients count];
		}
	});
	
	return clientCount;
}

#pragma mark -
#pragma mark Utilities

- (void)autoConnectAfterWakeup:(BOOL)afterWakeUp
{
	if ([masterController() ghostModeIsOn] && afterWakeUp == NO) {
		return;
	}
	
	NSInteger delay = 0;
	
	if (afterWakeUp) {
		delay += _reconnectAfterWakeupDelay;
	}
	
#define _isWakingFromSleep		(afterWakeUp	   && c.config.autoSleepModeDisconnect && c.disconnectType == IRCClientDisconnectComputerSleepMode)
#define _isAutoConnecting		(afterWakeUp == NO && c.config.autoConnect)
	
	@synchronized(self.clients) {
		for (IRCClient *c in self.clients) {
			if (_isWakingFromSleep || _isAutoConnecting) {
				[c autoConnect:delay afterWakeUp:afterWakeUp];
				
				delay += _autoConnectDelay;
			}
		}
	}
	
#undef _isWakingFromSleep
#undef _isAutoConnecting
}

- (void)prepareForSleep
{
	@synchronized(self.clients) {
		for (IRCClient *c in self.clients) {
			if (c.isLoggedIn) {
				if (c.config.autoSleepModeDisconnect) {
					c.disconnectType = IRCClientDisconnectComputerSleepMode;
			
					[c quit:c.config.sleepModeLeavingComment];
				}
			}
		}
	}
}

- (void)prepareForScreenSleep
{
    NSAssertReturn([TPCPreferences setAwayOnScreenSleep]);
	
	@synchronized(self.clients) {
		for (IRCClient *c in self.clients) {
			[c toggleAwayStatus:YES];
		}
	}
}

- (void)awakeFomScreenSleep
{
    NSAssertReturn([TPCPreferences setAwayOnScreenSleep]);
	
	@synchronized(self.clients) {
		for (IRCClient *c in self.clients) {
			[c toggleAwayStatus:NO];
		}
	}
}


- (void)reachabilityChanged:(BOOL)reachable
{
	@synchronized(self.clients) {
		for (IRCClient *u in self.clients) {
			[u reachabilityChanged:reachable];
		}
	}
}

- (void)destroyAllEvidence
{
	@synchronized(self.clients) {
		for (IRCClient *u in self.clients) {
			[self clearContentsOfClient:u];

			for (IRCChannel *c in u.channelList) {
				[self clearContentsOfChannel:c inClient:u];
			}
		}
	}

	[mainWindow() reloadTree];
	
	[self markAllAsRead];
}

- (void)markAllAsRead
{
	[self markAllAsRead:nil];
}

- (void)markAllAsRead:(IRCClient *)limitedClient
{
	BOOL markScrollback = [TPCPreferences autoAddScrollbackMark];
	
	@synchronized(self.clients) {
		for (IRCClient *u in self.clients) {
			if (limitedClient && NSDissimilarObjects(u, limitedClient)) {
				continue;
			}

			if (markScrollback) {
				[u.viewController mark];
			}
			
			for (IRCChannel *c in u.channelList) {
				[c resetState];

				if (markScrollback) {
					[c.viewController mark];
				}
			}
		}
	}

	if (limitedClient) {
		[mainWindow() reloadTreeGroup:limitedClient];
	} else {
		[mainWindow() reloadTree];
	}

	[TVCDockIcon updateDockIcon];
}

- (void)markAllScrollbacks
{
	NSAssertReturn([TPCPreferences autoAddScrollbackMark]);
	
	@synchronized(self.clients) {
		for (IRCClient *u in self.clients) {
			[u.viewController mark];
			
			for (IRCChannel *c in u.channelList) {
				[c.viewController mark];
			}
		}
	}
}

- (void)preferencesChanged
{
	[menuController() preferencesChanged];
	
	@synchronized(self.clients) {
		for (IRCClient *c in self.clients) {
			[c preferencesChanged];
		}
	}

	/* Redraw dock icon on changes. There is possiblity the downstream
	 preferencesChanged made modifications for the counts so we must 
	 honor those by attempting a redraw. */
	if ([TPCPreferences displayDockBadge] == NO) {
		[TVCDockIcon drawWithoutCount];
	} else {
		[TVCDockIcon resetCachedCount];

		[TVCDockIcon updateDockIcon];
	}
}

#pragma mark -
#pragma mark Tree Items

- (IRCClient *)findClientById:(NSString *)uid
{
	@synchronized(self.clients) {
		for (IRCClient *u in self.clients)
		{
			if ([uid isEqualToString:[u treeUUID]] || [uid isEqualToString:[u uniqueIdentifier]])
			{
				return u;
			}
		}
	}
	
	return nil;
}

- (IRCChannel *)findChannelByClientId:(NSString *)uid channelId:(NSString *)cid
{
	IRCClient *u = [self findClientById:uid];
	
	if (u) {
		for (IRCChannel *c in u.channelList)
		{
			if ([cid isEqualToString:[c treeUUID]] || [cid isEqualToString:[c uniqueIdentifier]])
			{
				return c;
			}
		}
	}
	
	return nil;
}

- (NSString *)findItemFromInfoGeneratedValue:(IRCTreeItem *)item
{
	NSString *s;
	
	if ([item isClient] == NO) {
		s = [NSString stringWithFormat:@"%@ %@", item.treeUUID, item.associatedClient.treeUUID];
	} else {
		s = [NSString stringWithFormat:@"%@", item.treeUUID];
	}
	
	return s;
}

- (IRCTreeItem *)findItemFromInfo:(NSString *)s
{
	NSObjectIsEmptyAssertReturn(s, nil);
	
	if ([s contains:@" "]) {
		NSArray *ary = [s split:@" "];
		
		NSString *uid = ary[1];
		NSString *cid = ary[0];
		
		return [self findChannelByClientId:uid channelId:cid];
	} else {
		return [self findClientById:s];
	}
}

#pragma mark -
#pragma mark Theme

- (void)reloadTheme
{
	[self reloadTheme:YES];
}

- (void)reloadTheme:(BOOL)reloadUserInterface
{
	[themeController() reload];
	
	@synchronized(self.clients) {
		for (IRCClient *u in self.clients) {
			[u.viewController reloadTheme];

			for (IRCChannel *c in u.channelList) {
				[c.viewController reloadTheme];
			}
		}
	}

	if (reloadUserInterface) {
		[mainWindow() updateBackgroundColor];
		
		[mainWindowTextField() redrawOriginPoints];
	}
}

- (void)changeTextSize:(BOOL)bigger
{
	/* These defines are from WebKit herself. */
#define MinimumZoomMultiplier       0.5f
#define MaximumZoomMultiplier       3.0f
#define ZoomMultiplierRatio         1.2f
	
	float newMultiplier = self.textSizeMultiplier;
	
	if (bigger) {
		newMultiplier *= ZoomMultiplierRatio;
		
		if (newMultiplier > MaximumZoomMultiplier) {
			return; // Do not perform an action.
		} else {
			self.textSizeMultiplier = newMultiplier;
		}
	} else {
		newMultiplier /= ZoomMultiplierRatio;
		
		if (self.textSizeMultiplier < MinimumZoomMultiplier) {
			return; // Do not perform an action.
		} else {
			self.textSizeMultiplier = newMultiplier;
		}
	}
	
	@synchronized(self.clients) {
		for (IRCClient *u in self.clients) {
			[u.viewController changeTextSize:bigger];
			
			for (IRCChannel *c in u.channelList) {
				[c.viewController changeTextSize:bigger];
			}
		}
	}
	
#undef MinimumZoomMultiplier
#undef MaximumZoomMultiplier
#undef ZoomMultiplierRatio
}

#pragma mark -
#pragma mark JavaScript

- (void)executeScriptCommandOnAllViews:(NSString *)command arguments:(NSArray *)args
{
	[self executeScriptCommandOnAllViews:command arguments:args onQueue:YES];
}

- (void)executeScriptCommandOnAllViews:(NSString *)command arguments:(NSArray *)args onQueue:(BOOL)onQueue
{
	if ([masterController() applicationIsTerminating] == NO) {
		@synchronized(self.clients) {
			for (IRCClient *u in self.clients) {
				[u.viewController executeScriptCommand:command withArguments:args onQueue:onQueue];

				for (IRCChannel *c in u.channelList) {
					[c.viewController executeScriptCommand:command withArguments:args onQueue:onQueue];
				}
			}
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
	
	[c.viewController setTopic:c.topic];

	[mainWindow() reloadTreeItem:c];
}

- (void)clearContentsOfClient:(IRCClient *)u
{
	[u resetState];

	[u.viewController clear];
	[u.viewController notifyDidBecomeVisible];

	[mainWindow() reloadTreeItem:u];
}

- (IRCClient *)createClient:(id)seed reload:(BOOL)reload
{
	/* We are very strict about this. */
	if (seed == nil) {
		NSAssert(NO, @"nil configuration seed.");
	}
	
	/* Create new client. */
	IRCClient *c = [IRCClient new];
	
	/* Populate new seed. */
	[c setup:seed];

	/* Assign factories. */
	c.viewController = [self createLogWithClient:c channel:nil];

	c.printingQueue = [TVCLogControllerOperationQueue new];

	/* Create all channels. */
	for (IRCChannelConfig *e in c.config.channelList) {
		[self createChannel:e client:c reload:NO adjust:NO];
	}
	
	/* Populate client list and tree view. */
	@synchronized(self.clients) {
		[self.clients addObject:c];
	
		if (reload) {
			NSInteger index = [self.clients indexOfObject:c];

			[mainWindowServerList() addItemToList:index inParent:nil];
		}
		
		/* Finsih up creation. */
		if ([self.clients count] == 1 && self.isPopulatingSeeds == NO) {
			/* If our client count is 1, then it means we just added our
			 first client ever. We want to force the selection to this
			 because if we had no client beforehand, then we did not have
			 any selection at all. */
			
			[mainWindow() select:c];
		}
	}

	[mainWindow() reloadLoadingScreen];

	[menuController() populateNavgiationChannelList];
	
	return c;
}

- (IRCChannel *)createChannel:(IRCChannelConfig *)seed client:(IRCClient *)client reload:(BOOL)reload adjust:(BOOL)adjust
{
	/* We are very strict about this. */
	if (seed == nil) {
		NSAssert(NO, @"nil configuration seed.");
	}
	
	if (client == nil) {
		NSAssert(NO, @"nil associated client.");
	}
	
	/* Check if channel already exists. */
	IRCChannel *c = [client findChannel:seed.channelName];

	if (c) {
		return c;
	}
	
	/* Create new channel. */
	c = [IRCChannel new];
	
	/* Make sure we can trace our origin. */
	c.associatedClient = client;
	
	c.modeInfo.supportInfo = client.supportInfo;
	
	/* Setup new channel. */
	[c setup:seed];
	
	c.viewController = [self createLogWithClient:client channel:c];

	/* Insert ourself into a specific index if we are query. */
	[client addChannel:c];
	
	/* Reload server list. */
	if (reload) {
		NSInteger index = [client.channelList indexOfObject:c];

		[mainWindowServerList() addItemToList:index inParent:client];
	}

	if (adjust) {
	/* Update selection. */
		[mainWindow() adjustSelection];

		/* Populate channel list. */
		[menuController() populateNavgiationChannelList];
	}
	
	return c;
}

- (IRCChannel *)createPrivateMessage:(NSString *)nick client:(IRCClient *)client
{
	/* Be very strict. */
	if (NSObjectIsEmpty(nick)) {
		NSAssert(NO, @"empty nickname value.");
	}
	
	/* Create base configuration. */
	IRCChannelConfig *seed = [IRCChannelConfig new];
	
	seed.type = IRCChannelPrivateMessageType;
	seed.channelName = nick;
	
	/* Create channel. */
	IRCChannel *c = [self createChannel:seed client:client reload:YES adjust:YES];
	
	/* Active? */
	if ([client isLoggedIn]) {
		[c activate];
	}
	
	return c;
}

- (void)selectOtherAndDestroy:(IRCTreeItem *)target
{
	@synchronized(self.clients) {
		NSInteger i = 0;
		
		IRCTreeItem *sel = nil;
		
		if ([target isClient]) {
			i = [self.clients indexOfObjectIdenticalTo:target];
			
			NSUInteger n = (i + 1);
			
			if (n < [self.clients count]) {
				sel = self.clients[n];
			}
			
			i = [mainWindowServerList() rowForItem:target];
		} else {		
			i = [mainWindowServerList() rowForItem:target];
			
			NSInteger n = (i + 1);
			
			if (0 <= n && n < [mainWindowServerList() numberOfRows]) {
				sel = [mainWindowServerList() itemAtRow:n];
			}
			
			if (sel && [sel isClient]) {
				n = (i - 1);
				
				if (0 <= n && n < [mainWindowServerList() numberOfRows]) {
					sel = [mainWindowServerList() itemAtRow:n];
				}
			}
		}
		
		if (sel) {
			[mainWindow() select:sel];
		} else {
			NSInteger n = (i - 1);
			
			if (0 <= n && n < [mainWindowServerList() numberOfRows]) {
				sel = [mainWindowServerList() itemAtRow:n];
			}
			
			[mainWindow() select:sel];
		}
		
		if ([target isClient]) {
			[self.clients removeObjectIdenticalTo:target];
		} else {
			IRCClient *u = [target associatedClient];
			
			[u removeChannel:(id)target];
		}

		[mainWindowServerList() removeItemFromList:target];
		
		id selectedItem = [mainWindow() selectedItem];
		
		if (selectedItem) {
			[mainWindowServerList() selectItemAtIndex:[mainWindowServerList() rowForItem:sel]];
		}
	}
}

- (void)destroyClient:(IRCClient *)u
{
	[self destroyClient:u bySkippingCloud:NO];
}

- (void)destroyClient:(IRCClient *)u bySkippingCloud:(BOOL)skipCloud
{
	/* It is not safe to destroy the client while connected. Therefore,
	 we set a block to be performed on disconnect. */
	if ([u isConnecting] || [u isConnected]) {
		__weak IRCWorld *weakSelf = self;
		__weak IRCClient *weakClient = u;
		
		[u setDisconnectCallback:^{
			[weakSelf destroyClient:weakClient bySkippingCloud:skipCloud];
		}];
		
		[u quit]; // Obviously we need to terminate it
		
		return; // Do not continue with operation. 
	} else {
		[u prepareForPermanentDestruction];
	}
	
#ifdef TEXTUAL_BUILT_WITH_ICLOUD_SUPPORT
	if (skipCloud == NO) {
		[self destroyClientInCloud:u];
	}
#endif
	
	id selectedItem = [mainWindow() selectedItem];
	
	if (selectedItem && [selectedItem associatedClient] == u) {
		[self selectOtherAndDestroy:u];
	} else {
		@synchronized(self.clients) {
			[self.clients removeObjectIdenticalTo:u];
		}
		
		[mainWindowServerList() removeItemFromList:u];

		[mainWindow() adjustSelection];
	}

	[mainWindow() reloadLoadingScreen];

	[menuController() populateNavgiationChannelList];
}

- (void)destroyChannel:(IRCChannel *)c
{
    [self destroyChannel:c part:YES];
}

- (void)destroyChannel:(IRCChannel *)c part:(BOOL)forcePart
{
	IRCClient *u = [c associatedClient];
	
	if ([u isLoggedIn] && [c isActive]) {
		if ([c isChannel]) {
			if (forcePart) {
				[u partChannel:c];
			}
		}
	}
	
	[u willDestroyChannel:c];
    
	[c prepareForPermanentDestruction];
	
	if (u.lastSelectedChannel == c) {
		u.lastSelectedChannel = nil;
	}
	
	[[TXSharedApplication sharedInputHistoryManager] destroy:c];
	
	if ([mainWindow() selectedItem] == c) {
		[self selectOtherAndDestroy:c];
	} else {
		[u removeChannel:c];

		[mainWindowServerList() removeItemFromList:c];

		[mainWindow() adjustSelection];
	}

	[menuController() populateNavgiationChannelList];
}

- (TVCLogController *)createLogWithClient:(IRCClient *)client channel:(IRCChannel *)channel
{
	TVCLogController *c = [TVCLogController new];

	c.associatedClient = client;
	c.associatedChannel = channel;
	
	c.maximumLineCount = [TPCPreferences scrollbackLimit];
	
	[c setUp];
	
	[c.webView setHostWindow:mainWindow()];
	
	return c;
}

#pragma mark -
#pragma mark Log Delegate

- (void)logKeyDown:(NSEvent *)e
{
	[mainWindowTextField() focus];

	if ([e keyCode] == TXKeyReturnCode ||
		[e keyCode] == TXKeyEnterCode)
	{
		return;
	}

	[mainWindowTextField() keyDown:e];
}

@end
