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

NS_ASSUME_NONNULL_BEGIN

#if TEXTUAL_BUILT_WITH_FORCED_BETA_LIFESPAN == 1
#define _betaTesterMaxApplicationLifespan			5184000 // 60 days
#endif

@interface TXMasterController ()
@property (nonatomic, strong, readwrite) IRCWorld *world;
@property (nonatomic, assign, readwrite) BOOL debugModeIsOn;
@property (nonatomic, assign, readwrite) BOOL ghostModeIsOn;
@property (nonatomic, assign, readwrite) BOOL applicationIsActive;
@property (nonatomic, assign, readwrite) BOOL applicationIsTerminating;
@property (nonatomic, assign, readwrite) BOOL applicationIsChangingActiveState;
@property (readonly) BOOL isSafeToPerformApplicationTermination;
@property (nonatomic, strong, readwrite) IBOutlet TVCMainWindow *mainWindow;
@property (nonatomic, weak, readwrite) IBOutlet TXMenuController *menuController;
@end

@implementation TXMasterController

#pragma mark -
#pragma mark Initialization

- (instancetype)init
{
	if ((self = [super init])) {
		[NSObject setGlobalMasterControllerClassReference:self];

		[self prepareInitialState];

		return self;
    }

	return nil;
}

- (void)prepareInitialState
{
	NSUInteger keyboardKeys = ([NSEvent modifierFlags] & NSDeviceIndependentModifierFlagsMask);

	if ((keyboardKeys & NSControlKeyMask) == NSControlKeyMask) {
		self.debugModeIsOn = YES;

		LogToConsoleDebugLoggingEnabled = YES;

		LogToConsoleInfo("Launching in debug mode")
	}

#if defined(DEBUG)
	self.ghostModeIsOn = YES; // Do not use autoconnect during debug
#else
	if ((keyboardKeys & NSShiftKeyMask) == NSShiftKeyMask) {
		self.ghostModeIsOn = YES;

		LogToConsoleInfo("Launching without autoconnecting to the configured servers")
	}
#endif
}

- (void)awakeFromNib
{
	static BOOL _awakeFromNibCalled = NO;

	if (_awakeFromNibCalled == NO) {
		_awakeFromNibCalled = YES;

		[self _awakeFromNib];
	}
}

- (void)_awakeFromNib
{
	[TPCPreferences initPreferences];

	/* We wait until -awakeFromNib to wake the window so that the menu
	 controller created by the main nib has time to load. */
	if ([XRSystemInformation isUsingOSXYosemiteOrLater]) {
		[RZMainBundle() loadNibNamed:@"TVCMainWindowYosemite" owner:self topLevelObjects:nil];
	} else {
		[RZMainBundle() loadNibNamed:@"TVCMainWindowMavericks" owner:self topLevelObjects:nil];
	}
}

- (void)performAwakeningBeforeMainWindowDidLoad
{
#if TEXTUAL_BUILT_WITH_ICLOUD_SUPPORT == 1
	/* Cloud files are synced regardless of user preference
	 so we still have to initalize it at some point. */
	[sharedCloudManager() prepareInitialState];
#endif
	
	self.world = [IRCWorld new];
}

- (void)performAwakeningAfterMainWindowDidLoad
{
#ifndef DEBUG
	/* This check can take a few cycles which means its performed
	 after the main window has loaded so the user has that to
	 stare at while its wound up. */
	[self checkForOtherCopiesOfTextualRunning];
#endif

	[IRCCommandIndex populateCommandIndex];

	[self prepareNetworkReachabilityNotifier];
	
	[RZWorkspaceNotificationCenter() addObserver:self selector:@selector(computerDidWakeUp:) name:NSWorkspaceDidWakeNotification object:nil];
	[RZWorkspaceNotificationCenter() addObserver:self selector:@selector(computerWillSleep:) name:NSWorkspaceWillSleepNotification object:nil];
	[RZWorkspaceNotificationCenter() addObserver:self selector:@selector(computerWillPowerOff:) name:NSWorkspaceWillPowerOffNotification object:nil];
	[RZWorkspaceNotificationCenter() addObserver:self selector:@selector(computerScreenDidWake:) name:NSWorkspaceScreensDidWakeNotification object:nil];
	[RZWorkspaceNotificationCenter() addObserver:self selector:@selector(computerScreenWillSleep:) name:NSWorkspaceScreensDidSleepNotification object:nil];
	
	[RZAppleEventManager() setEventHandler:self andSelector:@selector(handleURLEvent:withReplyEvent:) forEventClass:kInternetEventClass andEventID:kAEGetURL];

	[NSColorPanel setPickerMask:(NSColorPanelRGBModeMask | NSColorPanelGrayModeMask | NSColorPanelColorListModeMask | NSColorPanelWheelModeMask | NSColorPanelCrayonModeMask)];

	[sharedPluginManager() loadPlugins];

	[self performBlockOnGlobalQueue:^{
		[TPCResourceManager copyResourcesToApplicationSupportFolder];
	}];

#if TEXTUAL_BUILT_WITH_LICENSE_MANAGER == 1
	[self prepareLicenseManager];
#endif

	[self prepareThirdPartyServices];

	[self applicationDidFinishLaunching];
}

#pragma mark -
#pragma mark Services

- (void)prepareThirdPartyServiceHockeyAppFramework
{
#if TEXTUAL_BUILT_WITH_HOCKEYAPP_SDK_ENABLED == 1
	NSDictionary *hockeyAppData = [TPCResourceManager loadContentsOfPropertyListInResources:@"3rdPartyStaticStoreHockeyAppFramework"];

	NSString *applicationIdentifier = hockeyAppData[@"Application Identifier"];

	[[BITHockeyManager sharedHockeyManager] configureWithIdentifier:applicationIdentifier delegate:(id)self];

	[[BITHockeyManager sharedHockeyManager] startManager];

	[self hockeyAppToggleCollectAnonymousStatistics];
#endif
}

- (void)hockeyAppToggleCollectAnonymousStatistics
{
	[self hockeyAppToggleCollectAnonymousStatisticsAndAskPermission:YES];
}

- (void)hockeyAppToggleCollectAnonymousStatisticsAndAskPermission:(BOOL)askPermission
{
#if TEXTUAL_HOCKEYAPP_SDK_METRICS_ENABLED == 1
	if ([TPCPreferences collectAnonymousStatistics]) {
		[BITHockeyManager sharedHockeyManager].disableMetricsManager = NO;
	} else {
		if (askPermission) {
			[self hockeyAppAskPermissionToCollectAnonymousStatistics];
		}

#endif

#if TEXTUAL_BUILT_WITH_HOCKEYAPP_SDK_ENABLED == 1
		[BITHockeyManager sharedHockeyManager].disableMetricsManager = YES;
#endif

#if TEXTUAL_HOCKEYAPP_SDK_METRICS_ENABLED == 1
	}
#endif
}

#if TEXTUAL_HOCKEYAPP_SDK_METRICS_ENABLED == 1
- (void)hockeyAppAskPermissionToCollectAnonymousStatistics
{
	if ([TPCPreferences collectAnonymousStatisticsPermissionAsked]) {
		return;
	}

	[TLOPopupPrompts sheetWindowWithWindow:self.mainWindow
									  body:TXTLS(@"Prompts[1135][2]")
									 title:TXTLS(@"Prompts[1135][1]")
							 defaultButton:TXTLS(@"Prompts[1135][3]")
						   alternateButton:TXTLS(@"Prompts[1135][4]")
							   otherButton:TXTLS(@"Prompts[1135][5]")
						   completionBlock:^(TLOPopupPromptReturnType buttonClicked, NSAlert *originalAlert, BOOL suppressionResponse)
							{
								if (buttonClicked == TLOPopupPromptReturnPrimaryType ||
									buttonClicked == TLOPopupPromptReturnSecondaryType)
								{
									[TPCPreferences setCollectAnonymousStatistics:(buttonClicked == TLOPopupPromptReturnPrimaryType)];

									[TPCPreferences setCollectAnonymousStatisticsPermissionAsked:YES];
								}
								else if (buttonClicked == TLOPopupPromptReturnOtherType)
								{
									[TPCPreferences setCollectAnonymousStatistics:NO];

									[TLOpenLink openWithString:@"https://www.hockeyapp.net/features/user-metrics/"];
								}

								[self hockeyAppToggleCollectAnonymousStatisticsAndAskPermission:NO];
						   }];
}
#endif

- (void)prepareThirdPartyServiceSparkleFramework
{
#if TEXTUAL_BUILT_WITH_SPARKLE_ENABLED == 1
	NSDictionary *sparkleData = [TPCResourceManager loadContentsOfPropertyListInResources:@"3rdPartyStaticStoreSparkleFramework"];

	BOOL receiveBetaUpdates = [TPCPreferences receiveBetaUpdates];

	if (receiveBetaUpdates == NO) {
		[RZUserDefaults() setObject:sparkleData[@"SUFeedURL"] forKey:@"SUFeedURL"];
	} else {
		[RZUserDefaults() setObject:sparkleData[@"SUFeedURL-beta"] forKey:@"SUFeedURL"];
	}

	SUUpdater *updater = [SUUpdater sharedUpdater];

	updater.delegate = (id)self;

	if (receiveBetaUpdates == NO) {
		updater.updateCheckInterval = [sparkleData boolForKey:@"SUScheduledCheckInterval"];
	} else {
		updater.updateCheckInterval = [sparkleData boolForKey:@"SUScheduledCheckInterval-beta"];
	}

	[updater checkForUpdatesInBackground];
#endif
}

- (void)prepareThirdPartyServices
{
	[self prepareThirdPartyServiceHockeyAppFramework];

	[self prepareThirdPartyServiceSparkleFramework];
}

- (void)prepareNetworkReachabilityNotifier
{
	OELReachability *notifier = [TXSharedApplication sharedNetworkReachabilityNotifier];

	notifier.reachableBlock = ^(OELReachability *reachability) {
		[self.world noteReachabilityChanged:YES];
	};

	notifier.unreachableBlock = ^(OELReachability *reachability) {
		[self.world noteReachabilityChanged:NO];
	};

	[notifier startNotifier];
}

#if TEXTUAL_BUILT_WITH_LICENSE_MANAGER == 1
- (void)prepareLicenseManager
{
	TLOLicenseManagerSetup();

	[TDCLicenseManagerDialog applicationDidFinishLaunching];
}
#endif

- (void)checkForOtherCopiesOfTextualRunning
{
	BOOL foundOneMatchForSelf = NO;

	for (NSRunningApplication *application in RZWorkspace().runningApplications) {
		if ([application.bundleIdentifier isEqualToString:@"com.codeux.apps.textual"] ||
			[application.bundleIdentifier isEqualToString:@"com.codeux.irc.textual"] ||
			[application.bundleIdentifier isEqualToString:@"com.codeux.irc.textual5"] ||
			[application.bundleIdentifier isEqualToString:@"com.codeux.irc.textual5.trial"])
		{
			if ([application.bundleIdentifier isEqualToString:[TPCApplicationInfo applicationBundleIdentifier]]) {
				if (foundOneMatchForSelf == NO) {
					foundOneMatchForSelf = YES;

					continue;
				}
			}

			BOOL continueLaunch = [TLOPopupPrompts dialogWindowWithMessage:TXTLS(@"Prompts[1115][2]")
																	 title:TXTLS(@"Prompts[1115][1]")
															 defaultButton:TXTLS(@"Prompts[0001]")
														   alternateButton:TXTLS(@"Prompts[0002]")];

			if (continueLaunch == NO) {
				[self forceTerminate];
			}

			break;
		}
	}
}

#pragma mark -
#pragma mark NSApplication Terminate Procedure

#if TEXTUAL_BUILT_WITH_FORCED_BETA_LIFESPAN == 1
- (void)presentBetaTesterDialog
{
	NSTimeInterval currentTime = [NSDate timeIntervalSince1970];

	NSTimeInterval buildTime = [TXBundleBuildDate doubleValue];

	NSTimeInterval timeSpent = (currentTime - buildTime);
	NSTimeInterval timeRemaining = (_betaTesterMaxApplicationLifespan - timeSpent);

	if (timeSpent > _betaTesterMaxApplicationLifespan) {
		(void)[TLOPopupPrompts dialogWindowWithMessage:TXTLS(@"Prompts[1120][2]")
												 title:TXTLS(@"Prompts[1120][1]")
										 defaultButton:TXTLS(@"Prompts[0005]")
									   alternateButton:nil];

		[self forceTerminate];
	} else {
		NSString *formattedTime = TXHumanReadableTimeInterval(timeRemaining, YES, (NSDayCalendarUnit | NSHourCalendarUnit | NSMinuteCalendarUnit | NSSecondCalendarUnit));

		(void)[TLOPopupPrompts dialogWindowWithMessage:TXTLS(@"Prompts[1119][2]", formattedTime)
												 title:TXTLS(@"Prompts[1119][1]")
										 defaultButton:TXTLS(@"Prompts[0005]")
									   alternateButton:nil];
	}
}
#endif

#pragma mark -
#pragma mark NSApplication Delegate

- (void)applicationDidFinishLaunching
{
#if TEXTUAL_BUILT_WITH_FORCED_BETA_LIFESPAN == 1
	[self presentBetaTesterDialog];

	[self.mainWindow makeKeyAndOrderFront:nil];
#endif

	if ([self.mainWindow reloadLoadingScreen]) {
		[self.world autoConnectAfterWakeup:NO];
	}

	[self.mainWindow maybeToggleFullscreenAfterLaunch];
}

- (void)applicationWillResignActive:(NSNotification *)notification
{
	self.applicationIsChangingActiveState = YES;
}

- (void)applicationWillBecomeActive:(NSNotification *)notification
{
	self.applicationIsChangingActiveState = YES;
}

- (void)applicationDidResignActive:(NSNotification *)notification
{
	self.applicationIsActive = NO;
	self.applicationIsChangingActiveState = NO;
}

- (void)applicationDidBecomeActive:(NSNotification *)notification
{
	self.applicationIsActive = YES;
	self.applicationIsChangingActiveState = NO;
}

- (BOOL)applicationShouldHandleReopen:(NSApplication *)sender hasVisibleWindows:(BOOL)flag
{
	if (self.applicationIsTerminating) {
		return NO;
	}

	[self.mainWindow makeKeyAndOrderFront:nil];

	return YES;
}

- (BOOL)applicationShouldOpenUntitledFile:(NSApplication *)sender
{
	if (self.applicationIsTerminating) {
		return NO;
	}

	[self.mainWindow makeKeyAndOrderFront:nil];

	return YES;
}

#pragma mark -
#pragma mark NSApplication Terminate Procedure

- (NSMenu *)applicationDockMenu:(NSApplication *)sender
{
	return self.menuController.dockMenu;
}

- (BOOL)queryTerminate
{
	if (self.applicationIsTerminating) {
		return YES;
	}
	
	if ([TPCPreferences confirmQuit]) {
		BOOL result = [TLOPopupPrompts dialogWindowWithMessage:TXTLS(@"Prompts[1101][2]")
														 title:TXTLS(@"Prompts[1101][1]")
												 defaultButton:TXTLS(@"Prompts[1101][3]")
											   alternateButton:TXTLS(@"Prompts[0004]")];

		return result;
	}
	
	return YES;
}

- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender
{
	if ([self queryTerminate]) {
		XRPerformBlockAsynchronouslyOnMainQueue(^{
			[self performApplicationTerminationStepOne];
		});
		
		return NSTerminateLater;
	} else {
		return NSTerminateCancel;
	}
}

- (BOOL)isSafeToPerformApplicationTermination
{
#if TEXTUAL_BUILT_WITH_ICLOUD_SUPPORT == 1
	if (sharedCloudManager()) {
		return (
			/* Clients are still disconnecting */
			self.terminatingClientCount == 0 ||

			/* iCloud is syncing */
			[sharedCloudManager() isTerminated]
		);
	}
#endif

	return (self.terminatingClientCount == 0);
}

- (void)performApplicationTerminationStepOne
{
	self.applicationIsTerminating = YES;

	[self.mainWindow prepareForApplicationTermination];
	
	[[NSApplication sharedApplication] setDelegate:nil];
	
	[RZWorkspaceNotificationCenter() removeObserver:self];

	[RZNotificationCenter() removeObserver:self];

	[RZAppleEventManager() removeEventHandlerForEventClass:kInternetEventClass andEventID:kAEGetURL];

	[[TXSharedApplication sharedNetworkReachabilityNotifier] stopNotifier];

	[[TXSharedApplication sharedSpeechSynthesizer] setIsStopped:YES];

#if TEXTUAL_BUILT_WITH_ICLOUD_SUPPORT == 1
	[sharedCloudManager() prepareForApplicationTermination];
#endif

#if TEXTUAL_BUILT_WITH_ADVANCED_ENCRYPTION == 1
	[sharedEncryptionManager() prepareForApplicationTermination];
#endif

	[self.menuController prepareForApplicationTermination];

	[TVCLogControllerHistoricLogFile prepareForPermanentDestruction];

	[self performApplicationTerminationStepTwo];
}

- (void)performApplicationTerminationStepTwo
{
	if (self.applicationIsTerminating == NO) {
		return;
	}

	self.terminatingClientCount = worldController().clientCount;

	[self.world prepareForApplicationTermination];

	if (self.isSafeToPerformApplicationTermination) {
		[self performApplicationTerminationStepThree];

		return;
	}

	[self performBlockOnGlobalQueue:^{
		while (self.isSafeToPerformApplicationTermination == NO) {
			[NSThread sleepForTimeInterval:0.5];
		}

		[self performApplicationTerminationStepThree];
	}];
}

- (void)performApplicationTerminationStepThree
{
	if (self.applicationIsTerminating == NO) {
		return;
	}

	if (self.skipTerminateSave == NO) {
		[self.world save];
	}

	[sharedPluginManager() unloadPlugins];

	[windowController() prepareForApplicationTermination];

	[themeController() prepareForApplicationTermination];

	dispatch_suspend([TXSharedApplication sharedMutableSynchronizationSerialQueue]);
	
	[TPCApplicationInfo saveTimeIntervalSinceApplicationInstall];

	[sharedApplicationCache() removeAllObjects];
	
	[NSApp replyToApplicationShouldTerminate:YES];
}

- (void)forceTerminate
{
	self.applicationIsTerminating = YES;

	[RZSharedApplication() terminate:nil];
}

- (void)forceTerminateWithoutSave
{
	self.skipTerminateSave = YES;

	[self forceTerminate];
}

#pragma mark -
#pragma mark NSWorkspace Notifications

- (void)handleURLEvent:(NSAppleEventDescriptor *)event
		withReplyEvent:(NSAppleEventDescriptor *)replyEvent
{
	NSAppleEventDescriptor *description = [event descriptorAtIndex:1];

	NSString *stringValue = description.stringValue;

	[IRCExtras parseIRCProtocolURI:stringValue withDescriptor:event];
}

- (void)computerScreenWillSleep:(NSNotification *)note
{
	[self.world prepareForScreenSleep];
}

- (void)computerScreenDidWake:(NSNotification *)note
{
	[self.world wakeFomScreenSleep];
}

- (void)computerWillSleep:(NSNotification *)note
{
	[self.world prepareForSleep];

	[[TXSharedApplication sharedSpeechSynthesizer] setIsStopped:YES];
	[[TXSharedApplication sharedSpeechSynthesizer] clearQueue];
}

- (void)computerDidWakeUp:(NSNotification *)note
{
	[[TXSharedApplication sharedSpeechSynthesizer] setIsStopped:NO];

	[self.world autoConnectAfterWakeup:YES];
}

- (void)computerWillPowerOff:(NSNotification *)note
{
	[self forceTerminate];
}

#pragma mark -
#pragma mark Sparkle Delegate

#if TEXTUAL_BUILT_WITH_SPARKLE_ENABLED == 1
- (void)updaterWillRelaunchApplication:(SUUpdater *)updater
{
	self.applicationIsTerminating = YES;
}
#endif

@end

NS_ASSUME_NONNULL_END
