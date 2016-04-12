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

#import "TPCThemeControllerPrivate.h"

#define _autoConnectDelay				1
#define _reconnectAfterWakeupDelay		8

#define _savePeriodicallyThreshold		300

NSString * const IRCWorldControllerDefaultsStorageKey = @"World Controller";
NSString * const IRCWorldControllerClientListDefaultsStorageKey = @"clients";

NSString * const IRCWorldDateHasChangedNotification = @"IRCWorldDateHasChangedNotification";

NSString * const IRCWorldClientListWasModifiedNotification = @"IRCWorldClientListWasModifiedNotification";

@interface IRCWorld ()
@property (nonatomic, assign) BOOL preferencesDidChangeTimerIsActive;
@property (nonatomic, assign) CFAbsoluteTime savePeriodicallyLastSave;
@end

@implementation IRCWorld

#pragma mark -
#pragma mark Initialization

- (instancetype)init
{
	if ((self = [super init])) {
		self.clients = [NSMutableArray new];
		
		self.textSizeMultiplier = 1.0f;

		self.preferencesDidChangeTimerIsActive = NO;

		self.savePeriodicallyLastSave = CFAbsoluteTimeGetCurrent();
	}
	
	return self;
}

- (void)dealloc
{
	[self cancelPerformRequests];
}

#pragma mark -
#pragma mark Configuration

- (void)setupConfiguration
{
	self.isPopulatingSeeds = YES;
	
	NSDictionary *config = [TPCPreferences loadWorld];

	for (NSDictionary *e in config[IRCWorldControllerClientListDefaultsStorageKey]) {
		[self createClient:e reload:YES];
	}

	if ([config boolForKey:@"soundIsMuted"]) {
		[menuController() toggleMuteOnNotificationSoundsShortcut:NSOnState];
	}

	self.isPopulatingSeeds = NO;
}

- (void)setupOtherServices
{
	[self setupMidnightTimer];

	[RZNotificationCenter() addObserver:self selector:@selector(dateChanged:) name:NSSystemClockDidChangeNotification object:nil];

	[RZNotificationCenter() addObserver:self selector:@selector(userDefaultsDidChange:) name:TPCPreferencesUserDefaultsDidChangeNotification object:nil];
}

- (NSMutableDictionary *)dictionaryValue
{
	NSMutableArray *ary = [NSMutableArray array];

	for (IRCClient *u in [self clientList]) {
		[ary addObject:[u dictionaryValue]];
	}

	NSMutableDictionary *dict = [NSMutableDictionary dictionary];
	
	dict[IRCWorldControllerClientListDefaultsStorageKey] = ary;
	
	dict[@"soundIsMuted"] = @([sharedGrowlController() areNotificationSoundsDisabled]);

	return dict;
}

- (void)save
{
	[TPCPreferences saveWorld:[self dictionaryValue]];
}

- (void)savePeriodically
{
	CFAbsoluteTime now = CFAbsoluteTimeGetCurrent();

	if ((self.savePeriodicallyLastSave + _savePeriodicallyThreshold) < now) {
		 self.savePeriodicallyLastSave = now;

		[self save];
	}
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
	if ([themeSettings() js_postPreferencesDidChangesNotifications] == NO) {
		return; // Cancel operation...
	}

	if (self.preferencesDidChangeTimerIsActive == NO) {
		self.preferencesDidChangeTimerIsActive = YES;

		[self performSelector:@selector(informaAllViewsUserDefaultsDidChange) withObject:nil afterDelay:1.0];
	}
}

- (void)informaAllViewsUserDefaultsDidChange
{
	self.preferencesDidChangeTimerIsActive = NO;

	[self evaluateFunctionOnAllViews:@"preferencesDidChange" arguments:@[] onQueue:YES];
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

			[self postClientListWasModifiedNotification];
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

- (void)postClientListWasModifiedNotification
{
	[RZNotificationCenter() postNotificationName:IRCWorldClientListWasModifiedNotification object:self];
}

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
			if (c.config.autoSleepModeDisconnect) {
				if (c.isLoggedIn) {
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
			if (limitedClient) {
				if (NSDissimilarObjects(u, limitedClient)) {
					continue;
				}
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

- (void)preferencesChanged
{
	[menuController() preferencesChanged];
	
	@synchronized(self.clients) {
		for (IRCClient *c in self.clients) {
			[c preferencesChanged];
		}
	}

	if ([TPCPreferences displayDockBadge] == NO) {
		[TVCDockIcon drawWithoutCount];
	} else {
		[TVCDockIcon resetCachedCount];

		[TVCDockIcon updateDockIcon];
	}

	[TVCImageURLoader invalidateInternalCache];
}

- (void)setupMidnightTimer
{
	[self setupMidnightTimerWithNotification:NO];
}

- (void)setupMidnightTimerWithNotification:(BOOL)fireNotification
{
	/* Ask for the day, month, and year from the current calender. */
	/* We are not asking for time which means that it will default to zero. */
	NSDateComponents *currentDayComponents = [RZCurrentCalender() components:(NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit) fromDate:[NSDate date]];

	NSDate *lastMidnight = [RZCurrentCalender() dateFromComponents:currentDayComponents];

	/* Create date components one day in the future. */
	/* All other values default to zero. */
	NSDateComponents *futureDayComponents = [NSDateComponents new];

	[futureDayComponents setDay:1];

	/* With the current date and future components, calculate
	 the date on which our midnight timer will land. */
	NSDate *nextMidnight = [RZCurrentCalender() dateByAddingComponents:futureDayComponents toDate:lastMidnight options:0];

	/* Create timer for midnight in future. */
	/* We set the tolerance for the timer to absolute zero so that
	 we are confident that OS X will not reschedule it. */
	NSTimer *midnightTimer = [[NSTimer alloc]
							  initWithFireDate:nextMidnight
							  interval:0.0
							  target:self
							  selector:@selector(dateChanged:)
							  userInfo:nil
							  repeats:NO];

	if ([XRSystemInformation isUsingOSXMavericksOrLater]) {
		[midnightTimer setTolerance:0.0];
	}

	/* Schedule the timer on the run loop which will retain reference. */
	[RZCurrentRunLoop() addTimer:midnightTimer forMode:NSDefaultRunLoopMode];

	/* Post notification if needed. */
	if (fireNotification) {
		[RZNotificationCenter() postNotificationName:IRCWorldDateHasChangedNotification object:nil userInfo:nil];

		[self evaluateFunctionOnAllViews:@"Textual.dateChanged"
							   arguments:@[@([currentDayComponents year]),
										   @([currentDayComponents month]),
										   @([currentDayComponents day])]
								 onQueue:NO];
	}
}

- (void)dateChanged:(id)sender
{
	/* We call the notifications in the timer so we do not have to ask for the
	 current day components two times. */

	[self setupMidnightTimerWithNotification:YES];
}

#pragma mark -
#pragma mark Tree Items

- (IRCTreeItem *)findItemByTreeId:(NSString *)uid
{
	@synchronized(self.clients) {
		for (IRCClient *u in self.clients) {
			if ([uid isEqualToString:[u treeUUID]]) {
				return u;
			}

			for (IRCChannel *c in u.channelList) {
				if ([uid isEqualToString:[c treeUUID]]) {
					return c;
				}
			}
		}
	}

	return nil;
}

- (IRCClient *)findClientById:(NSString *)uid
{
	@synchronized(self.clients) {
		for (IRCClient *u in self.clients) {
			if ([uid isEqualToString:[u treeUUID]] ||
				[uid isEqualToString:[u uniqueIdentifier]])
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
		for (IRCChannel *c in u.channelList) {
			if ([cid isEqualToString:[c treeUUID]] ||
				[cid isEqualToString:[c uniqueIdentifier]])
			{
				return c;
			}
		}
	}
	
	return nil;
}

- (NSString *)pasteboardStringForItem:(IRCTreeItem *)item
{
	NSString *s = nil;

	if ([item isClient] == NO) {
		s = [NSString stringWithFormat:@"%@ %@", [item treeUUID], [[item associatedClient] treeUUID]];
	} else {
		s = [NSString stringWithFormat:@"%@", [item treeUUID]];
	}

	return s;
}

- (IRCTreeItem *)findItemFromPasteboardString:(NSString *)s
{
	NSObjectIsEmptyAssertReturn(s, nil);

	if ([s contains:NSStringWhitespacePlaceholder]) {
		NSArray *ary = [s split:NSStringWhitespacePlaceholder];

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
		
		if (newMultiplier < MinimumZoomMultiplier) {
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

- (void)evaluateFunctionOnAllViews:(NSString *)function arguments:(NSArray *)arguments
{
	[self evaluateFunctionOnAllViews:function arguments:arguments onQueue:YES];
}

- (void)evaluateFunctionOnAllViews:(NSString *)function arguments:(NSArray *)arguments onQueue:(BOOL)onQueue
{
	if ([masterController() applicationIsTerminating]) {
		return;
	}

	@synchronized(self.clients) {
		for (IRCClient *u in self.clients) {
			[u.viewController evaluateFunction:function withArguments:arguments onQueue:onQueue];

			for (IRCChannel *c in u.channelList) {
				[c.viewController evaluateFunction:function withArguments:arguments onQueue:onQueue];
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

	[mainWindow() reloadTreeItem:c];
}

- (void)clearContentsOfClient:(IRCClient *)u
{
	[u resetState];

	[u.viewController clear];

	[mainWindow() reloadTreeItem:u];
}

- (IRCClient *)createClient:(id)seed reload:(BOOL)reload
{
	if (seed == nil) {
		NSAssert(NO, @"nil configuration seed.");
	}

	IRCClient *c = [IRCClient new];

	[c setup:seed];

	c.viewController = [self createLogWithClient:c channel:nil];

	c.printingQueue = [TVCLogControllerOperationQueue new];

	for (IRCChannelConfig *e in [[c config] channelList]) {
		[self createChannel:e client:c reload:NO adjust:NO];
	}

	@synchronized(self.clients) {
		[self.clients addObject:c];
	
		if (reload) {
			NSInteger index = [self.clients indexOfObject:c];

			[mainWindowServerList() addItemToList:index inParent:nil];
		}

		if (self.isPopulatingSeeds == NO) {
			if ([self.clients count] == 1) {
				[mainWindow() select:c];
			}
		}
	}

	(void)[mainWindow() reloadLoadingScreen];

	[menuController() populateNavgiationChannelList];

	[self postClientListWasModifiedNotification];

	return c;
}

- (IRCChannel *)createChannel:(IRCChannelConfig *)seed client:(IRCClient *)client reload:(BOOL)reload adjust:(BOOL)adjust
{
	if (seed == nil) {
		NSAssert(NO, @"nil configuration seed.");
	}
	
	if (client == nil) {
		NSAssert(NO, @"nil associated client.");
	}

	IRCChannel *c = [IRCChannel new];

	[c setAssociatedClient:client];

	[c setup:seed];
	
	c.viewController = [self createLogWithClient:client channel:c];

	[client addChannel:c];

	if (reload) {
		NSInteger index = [client.channelList indexOfObject:c];

		[mainWindowServerList() addItemToList:index inParent:client];
	}

	if (adjust) {
		[mainWindow() adjustSelection];

		[menuController() populateNavgiationChannelList];
	}
	
	return c;
}

- (IRCChannel *)createPrivateMessage:(NSString *)nickname client:(IRCClient *)client
{
	if (NSObjectIsEmpty(nickname)) {
		NSAssert(NO, @"empty nickname value.");
	}

	IRCChannelConfig *seed = [IRCChannelConfig new];

	[seed setChannelName:nickname];
	[seed setType:IRCChannelPrivateMessageType];

	IRCChannel *c = [self createChannel:seed client:client reload:YES adjust:YES];

	if ([client isLoggedIn]) {
		[c activate];
	}
	
	return c;
}

- (void)selectOtherBeforeDestroy:(IRCTreeItem *)target
{
	if ([target isClient]) {
		[mainWindow() deselectGroup:target];
	} else {
		[mainWindow() deselect:target];
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
	}

	[self selectOtherBeforeDestroy:u];

	[u prepareForPermanentDestruction];

	[u setPrintingQueue:nil];
	
#if TEXTUAL_BUILT_WITH_ICLOUD_SUPPORT == 1
	if (skipCloud == NO) {
		[self destroyClientInCloud:u];
	}
#endif

	[mainWindowServerList() removeItemFromList:u];

	@synchronized(self.clients) {
		[self.clients removeObjectIdenticalTo:u];
	}

	[self postClientListWasModifiedNotification];

	(void)[mainWindow() reloadLoadingScreen];

	[menuController() populateNavgiationChannelList];
}

- (void)destroyChannel:(IRCChannel *)c
{
	[self destroyChannel:c reload:YES part:YES];
}

- (void)destroyChannel:(IRCChannel *)c reload:(BOOL)reload
{
	[self destroyChannel:c reload:reload part:YES];
}

- (void)destroyChannel:(IRCChannel *)c reload:(BOOL)reload part:(BOOL)forcePart
{
	IRCClient *u = [c associatedClient];
	
	if (forcePart) {
		[u partChannel:c];
	}

	if (reload) {
		[self selectOtherBeforeDestroy:c];
	}

	[u willDestroyChannel:c];
    
	[c prepareForPermanentDestruction];
	
	if (u.lastSelectedChannel == c) {
		u.lastSelectedChannel = nil;
	}

	if (reload) {
		[mainWindowServerList() removeItemFromList:c];

		[u removeChannel:c];

		[mainWindow() adjustSelection];

		[menuController() populateNavgiationChannelList];
	}
}

- (TVCLogController *)createLogWithClient:(IRCClient *)client channel:(IRCChannel *)channel
{
	TVCLogController *c = [TVCLogController new];

	[c setAssociatedClient:client];
	[c setAssociatedChannel:channel];

	[c setMaximumLineCount:[TPCPreferences scrollbackLimit]];
	
	[c setUp];
	
	return c;
}

@end
