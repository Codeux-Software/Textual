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

#define KInternetEventClass		1196773964
#define KAEGetURL				1196773964

@implementation TXMasterController

- (instancetype)init
{
    if ((self = [super init])) {
		[NSObject setGlobalMasterControllerClassReference:self];
		
		// ---- //
		
#ifndef TXSystemIsMacOSYosemiteOrNewer
		if ([XRSystemInformation isUsingOSXYosemiteOrLater]) {
			NSAssert(NO, @"This copy of Textual cannot be used on Yosemite. Please rebuild against the Yosemite SDK.");
		}
#endif
		
		// ---- //
		
#if defined(DEBUG)
		self.ghostModeIsOn = YES; // Do not use autoconnect during debug.
#else
		if ([NSEvent modifierFlags] & NSShiftKeyMask) {
			self.ghostModeIsOn = YES;
			
			LogToConsole(@"Launching without autoconnecting to the configured servers.");
		}
#endif
		
		// ---- //

		if ([NSEvent modifierFlags] & NSControlKeyMask) {
			self.debugModeIsOn = YES;

			LogToConsole(@"Launching in debug mode.");
		}

		// ---- //

		return self;
    }

    return nil;
}

- (void)awakeFromNib
{
	static BOOL _awakeFromNibCalled = NO;
	
	if (_awakeFromNibCalled == NO) {
		_awakeFromNibCalled = YES;

		/* Register defaults. */
		[TPCPreferences initPreferences];
	
		/* We wait until -awakeFromNib to wake the window so that the menu
		 controller created by the main nib has time to load. */
		if ([XRSystemInformation isUsingOSXYosemiteOrLater]) {
			[RZMainBundle() loadNibNamed:@"TVCMainWindowYosemite" owner:self topLevelObjects:nil];
		} else {
			[RZMainBundle() loadNibNamed:@"TVCMainWindowMavericks" owner:self topLevelObjects:nil];
		}
	}
}

- (void)performAwakeningBeforeMainWindowDidLoad
{
#ifdef TEXTUAL_BUILT_WITH_ICLOUD_SUPPORT
	/* Cloud files are synced regardless of user preference
	 so we still have to initalize it at some point. */
	[sharedCloudManager() initializeCloudSyncSession];
#endif
	
	self.world = [IRCWorld new];
}

- (void)performAwakeningAfterMainWindowDidLoad
{
#ifndef DEBUG
	[self checkForOtherCopiesOfTextualRunning];
#endif

	[[TXSharedApplication sharedNetworkReachabilityObject] startNotifier];
	
	[RZWorkspaceNotificationCenter() addObserver:self selector:@selector(computerDidWakeUp:) name:NSWorkspaceDidWakeNotification object:nil];
	[RZWorkspaceNotificationCenter() addObserver:self selector:@selector(computerWillSleep:) name:NSWorkspaceWillSleepNotification object:nil];
	[RZWorkspaceNotificationCenter() addObserver:self selector:@selector(computerWillPowerOff:) name:NSWorkspaceWillPowerOffNotification object:nil];
	[RZWorkspaceNotificationCenter() addObserver:self selector:@selector(computerScreenDidWake:) name:NSWorkspaceScreensDidWakeNotification object:nil];
	[RZWorkspaceNotificationCenter() addObserver:self selector:@selector(computerScreenWillSleep:) name:NSWorkspaceScreensDidSleepNotification object:nil];
	
	[RZAppleEventManager() setEventHandler:self andSelector:@selector(handleURLEvent:withReplyEvent:) forEventClass:KInternetEventClass andEventID:KAEGetURL];
	
	[sharedPluginManager() loadPlugins];

	[self performBlockOnGlobalQueue:^{
		[TPCResourceManager copyResourcesToCustomAddonsFolder];
	}];

	[self prepareThirdPartyServices];
	
	[self applicationDidFinishLaunching];
}

- (void)checkForOtherCopiesOfTextualRunning
{
	NSArray *textualFourRunning = [NSRunningApplication runningApplicationsWithBundleIdentifier:@"com.codeux.irc.textual"];
	NSArray *textualFiveRunning = [NSRunningApplication runningApplicationsWithBundleIdentifier:@"com.codeux.irc.textual5"];
	
	if ([textualFourRunning count] > 0 || [textualFiveRunning count] > 1) {
		BOOL continueLaunch = [TLOPopupPrompts dialogWindowWithQuestion:TXTLS(@"BasicLanguage[1237][2]")
																  title:TXTLS(@"BasicLanguage[1237][1]")
														  defaultButton:TXTLS(@"BasicLanguage[1237][3]")
														alternateButton:TXTLS(@"BasicLanguage[1237][4]")
														 suppressionKey:nil
														suppressionText:nil];
		
		if (continueLaunch == NO) {
			self.skipTerminateSave = YES;
			self.applicationIsTerminating = YES;
			
			[RZSharedApplication() terminate:nil];
		}
	}
}

#pragma mark -
#pragma mark NSApplication Delegate

- (void)prepareThirdPartyServices
{
#if TEXTUAL_BUILT_WITH_HOCKEYAPP_SDK_ENABLED == 1 || TEXTUAL_BUILT_WITH_SPARKLE_ENABLED == 1
	NSDictionary *resourcesDict = [[RZMainBundle() infoDictionary] dictionaryForKey:@"3rd-party Definitions"];
#endif

#if TEXTUAL_BUILT_WITH_HOCKEYAPP_SDK_ENABLED == 1
	NSDictionary *hockeyAppData = [resourcesDict dictionaryForKey:@"HockeyApp Framework"];

	DebugLogToConsole(@"HockeyApp application identifier: %@", hockeyAppData);

	[[BITHockeyManager sharedHockeyManager] configureWithIdentifier:hockeyAppData[@"Application Identifier"] delegate:self];
	[[BITHockeyManager sharedHockeyManager] startManager];
#endif

	// ---

#if TEXTUAL_BUILT_WITH_SPARKLE_ENABLED == 1
	NSDictionary *sparkleData = [resourcesDict dictionaryForKey:@"Sparkle Framework"];

	NSDictionary *feeds = [sparkleData dictionaryForKey:@"SUFeedURL"];

	NSString *feedURL = [feeds objectForKey:[TPCApplicationInfo applicationBuildScheme]];

	DebugLogToConsole(@"Sparkle Framework feed URL: %@", feedURL);

	if (feedURL) {
		[[SUUpdater sharedUpdater] setFeedURL:[NSURL URLWithString:feedURL]];

		[[SUUpdater sharedUpdater] setAutomaticallyChecksForUpdates:[sparkleData boolForKey:@"SUEnableAutomaticChecks"]];
		[[SUUpdater sharedUpdater] setAutomaticallyDownloadsUpdates:[sparkleData boolForKey:@"SUAllowsAutomaticUpdates"]];

		[[SUUpdater sharedUpdater] setSendsSystemProfile:[sparkleData boolForKey:@"SUEnableSystemProfiling"]];

		[[SUUpdater sharedUpdater] setUpdateCheckInterval:[sparkleData boolForKey:@"SUScheduledCheckInterval"]];

		[[SUUpdater sharedUpdater] checkForUpdatesInBackground];
	}
#endif
}

- (void)applicationDidFinishLaunching
{
	if ([worldController() clientCount] < 1) {
		[mainWindowLoadingScreen() hideAll:NO];
		[mainWindowLoadingScreen() popWelcomeAddServerView];
	} else {
		[mainWindowLoadingScreen() hideLoadingConfigurationView];

		[worldController() autoConnectAfterWakeup:NO];
	}

	[mainWindow() maybeToggleFullscreenAfterLaunch];
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

- (BOOL)queryTerminate
{
	if (self.applicationIsTerminating) {
		return YES;
	}
	
	if ([TPCPreferences confirmQuit]) {
		BOOL result = [TLOPopupPrompts dialogWindowWithQuestion:TXTLS(@"BasicLanguage[1000][1]")
														  title:TXTLS(@"BasicLanguage[1000][2]")
												  defaultButton:TXTLS(@"BasicLanguage[1000][3]")
												alternateButton:BLS(1009)
												 suppressionKey:nil
												suppressionText:nil];

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

- (NSMenu *)applicationDockMenu:(NSApplication *)sender
{
	return [menuController() dockMenu];
}

- (BOOL)isNotSafeToPerformApplicationTermination
{
#ifdef TEXTUAL_BUILT_WITH_ICLOUD_SUPPORT
	if (sharedCloudManager()) {
		return (
				/* Clients are still disconnecting. */
				self.terminatingClientCount > 0 ||

				/* iCloud is syncing. */
				([sharedCloudManager() isSyncingLocalKeysDownstream] ||
				 [sharedCloudManager() isSyncingLocalKeysUpstream])
		);
	} else {
		return (self.terminatingClientCount > 0);
	}
#else
	return (self.terminatingClientCount > 0);
#endif
}

- (void)performApplicationTerminationStepOne
{
	[self setApplicationIsTerminating:YES];

	[mainWindow() prepareForApplicationTermination];
	
	[[NSApplication sharedApplication] setDelegate:nil];
	
	[RZWorkspaceNotificationCenter() removeObserver:self];

	[RZNotificationCenter() removeObserver:self];

	[RZAppleEventManager() removeEventHandlerForEventClass:KInternetEventClass andEventID:KAEGetURL];
	
	[[TXSharedApplication sharedNetworkReachabilityObject] stopNotifier];
	
#ifdef TEXTUAL_BUILT_WITH_ICLOUD_SUPPORT
	[sharedCloudManager() setApplicationIsTerminating:YES];
#endif
	
	[menuController() prepareForApplicationTermination];

	if (self.skipTerminateSave == NO) {
		self.terminatingClientCount = [worldController() clientCount];

		[worldController() prepareForApplicationTermination];
		[worldController() save];

		while ([self isNotSafeToPerformApplicationTermination])
		{
			[RZMainRunLoop() runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];
		}
	}

	[sharedPluginManager() unloadPlugins];
	
	[TXSharedApplication releaseSharedMutableSynchronizationSerialQueue];
	
	[TPCApplicationInfo saveTimeIntervalSinceApplicationInstall];

#ifdef TEXTUAL_BUILT_WITH_ICLOUD_SUPPORT
	[sharedCloudManager() closeCloudSyncSession];
#endif
	
	[NSApp replyToApplicationShouldTerminate:YES];
}

- (BOOL)applicationShouldHandleReopen:(NSApplication *)sender hasVisibleWindows:(BOOL)flag
{
	if (self.applicationIsTerminating == NO) {
		[self.mainWindow makeKeyAndOrderFront:nil];
	}

	return YES;
}

#pragma mark -
#pragma mark NSWorkspace Notifications

- (void)handleURLEvent:(NSAppleEventDescriptor *)event
		withReplyEvent:(NSAppleEventDescriptor *)replyEvent
{
	TVCMainWindowNegateActionWithAttachedSheet();
	
	NSAppleEventDescriptor *desc = [event descriptorAtIndex:1];

	[IRCExtras parseIRCProtocolURI:[desc stringValue] withDescriptor:event];
}

- (void)computerScreenWillSleep:(NSNotification *)note
{
	[worldController() prepareForScreenSleep];
}

- (void)computerScreenDidWake:(NSNotification *)note
{
	[worldController() awakeFomScreenSleep];
}

- (void)computerWillSleep:(NSNotification *)note
{
	[worldController() prepareForSleep]; // Tell world to prepare.

	[[TXSharedApplication sharedSpeechSynthesizer] setIsStopped:YES]; // Stop speaking during sleep.
	[[TXSharedApplication sharedSpeechSynthesizer] clearQueue]; // Destroy pending spoken items.
}

- (void)computerDidWakeUp:(NSNotification *)note
{
	[[TXSharedApplication sharedSpeechSynthesizer] setIsStopped:NO]; // We can speak again!

	[worldController() autoConnectAfterWakeup:YES]; // Wake clients up…
}

- (void)computerWillPowerOff:(NSNotification *)note
{
	self.applicationIsTerminating = YES;
	
	[NSApp terminate:nil];
}

- (BOOL)applicationShouldOpenUntitledFile:(NSApplication *)sender
{
	if (self.applicationIsTerminating == NO) {
		[self.mainWindow makeKeyAndOrderFront:nil];
	}
	
	return YES;
}

@end
