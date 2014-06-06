/* ********************************************************************* 
       _____        _               _    ___ ____   ____
      |_   _|___  _| |_ _   _  __ _| |  |_ _|  _ \ / ___|
       | |/ _ \ \/ / __| | | |/ _` | |   | || |_) | |
       | |  __/>  <| |_| |_| | (_| | |   | ||  _ <| |___
       |_|\___/_/\_\\__|\__,_|\__,_|_|  |___|_| \_\\____|

 Copyright (c) 2008 - 2010 Satoshi Nakagawa <psychs AT limechat DOT net>
 Copyright (c) 2010 — 2014 Codeux Software & respective contributors.
     Please see Acknowledgements.pdf for additional information.

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

#define KInternetEventClass		1196773964
#define KAEGetURL				1196773964

#define _maximumSplitViewWidth		300
#define _minimumSplitViewWidth		120
#define _defaultSplitViewWidth		170

__weak static TXMasterController *TXGlobalMasterControllerClassReference;

@implementation TXMasterController

- (id)init
{
    if ((self = [super init])) {
		TXGlobalMasterControllerClassReference = self;

		// ---- //

		if ([NSEvent modifierFlags] & NSControlKeyMask) {
			self.debugModeOn = YES;

			LogToConsole(@"Launching in debug mode.");
		}
		
#ifdef TEXTUAL_BUILT_WITH_APP_NAP_DISABLED
		// Force disable app nap as it creates a lot of problems.
		
		if ([RZProcessInfo() respondsToSelector:@selector(beginActivityWithOptions:reason:)]) {
			self.appNapProgressInformation = [RZProcessInfo() beginActivityWithOptions:NSActivityUserInitiatedAllowingIdleSystemSleep reason:@"Managing IRC"];
		}
#endif

		// ---- //

		return self;
    }

    return nil;
}

#pragma mark -
#pragma mark NSApplication Delegate

- (void)awakeFromNib
{
	DebugLogToConsole(@"Temporary Folder: %@", [TPCPreferences applicationTemporaryFolderPath]);
	DebugLogToConsole(@"Caches Folder: %@", [TPCPreferences applicationCachesFolderPath]);

	// ---- //

	if ([NSEvent modifierFlags] & NSShiftKeyMask) {
		self.ghostMode = YES;
	}

#if defined(DEBUG)
    self.ghostMode = YES; // Do not use autoconnect during debug.
#endif

	[TPCPreferences initPreferences];
	
#ifdef TEXTUAL_BUILT_WITH_ICLOUD_SUPPORT
	self.cloudSyncManager = [TPCPreferencesCloudSync new];
	
	/* Cloud files are synced regardless of user preference
	 so we still have to initalize it at some point. */
	if ([TPCPreferences featureAvailableToOSXMountainLion]) {
		[self.cloudSyncManager initializeCloudSyncSession];
	}
#endif

	[self.mainWindow setMinSize:[TPCPreferences minimumWindowSize]];
	[self.mainWindow setAllowsConcurrentViewDrawing:NO];
	[self.mainWindow makeMainWindow];

	self.serverSplitView.fixedViewIndex = 0;
	self.memberSplitView.fixedViewIndex = 1;

	[self.mainWindowLoadingScreen hideAll:NO];
	[self.mainWindowLoadingScreen popLoadingConfigurationView];

	self.mainWindowIsActive = YES;

	[self.mainWindow makeKeyAndOrderFront:nil];

	[self loadWindowState];

	[self.mainWindow setAlphaValue:[TPCPreferences themeTransparency]];
	
	/* We keep high-res mode value cached since it is costly to ask for every draw. */
	self.applicationIsRunningInHighResMode = [[self.mainWindow screen] runningInHighResolutionMode];

	 self.themeControllerPntr = [TPCThemeController new];
	[self.themeControllerPntr load];
	
	[self.menuController setupOtherServices];

	[self.inputTextField focus];
	[self.inputTextField redrawOriginPoints];
	[self.inputTextField updateTextDirection];

	[self.inputTextField setBackgroundColor:[NSColor clearColor]];

	[self registerKeyHandlers];

	[self.formattingMenu enableWindowField:self.inputTextField];

	self.speechSynthesizer = [TLOSpeechSynthesizer new];

	self.world = [IRCWorld new];

	self.serverSplitView.delegate = self;
	self.memberSplitView.delegate = self;

	[self.worldController setupConfiguration];

	self.serverList.delegate = self.worldController;
	self.serverList.dataSource = self.worldController;

    self.memberList.keyDelegate	= self.worldController;
	self.serverList.keyDelegate	= self.worldController;

	[self.memberList createBadgeRenderer];

	[self.serverList reloadData];
	
	[self.worldController setupTree];
	[self.worldController setupOtherServices];

	[self.memberList setTarget:self.menuController];
	[self.memberList setDoubleAction:@selector(memberInMemberListDoubleClicked:)];

	if ([TPCPreferences inputHistoryIsChannelSpecific] == NO) {
		_globalInputHistory = [TLOInputHistory new];
	}

	self.growlController = [TLOGrowlController new];

	[RZWorkspaceNotificationCenter() addObserver:self selector:@selector(computerDidWakeUp:) name:NSWorkspaceDidWakeNotification object:nil];
	[RZWorkspaceNotificationCenter() addObserver:self selector:@selector(computerWillSleep:) name:NSWorkspaceWillSleepNotification object:nil];
	[RZWorkspaceNotificationCenter() addObserver:self selector:@selector(computerWillPowerOff:) name:NSWorkspaceWillPowerOffNotification object:nil];
	[RZWorkspaceNotificationCenter() addObserver:self selector:@selector(computerScreenDidWake:) name:NSWorkspaceScreensDidWakeNotification object:nil];
	[RZWorkspaceNotificationCenter() addObserver:self selector:@selector(computerScreenWillSleep:) name:NSWorkspaceScreensDidSleepNotification object:nil];

	[RZNotificationCenter() addObserver:self selector:@selector(systemTintChangedNotification:) name:NSControlTintDidChangeNotification object:nil];

	[RZAppleEventManager() setEventHandler:self andSelector:@selector(handleURLEvent:withReplyEvent:) forEventClass:KInternetEventClass andEventID:KAEGetURL];

	[THOPluginManagerSharedInstance() loadPlugins];
}

- (void)maybeToggleFullscreenAfterLaunch
{
	NSDictionary *dic = [RZUserDefaults() dictionaryForKey:@"Window -> Main Window Window State"];

	if ([dic boolForKey:@"fullscreen"]) {
		[self performSelector:@selector(toggleFullscreenAfterLaunch) withObject:nil afterDelay:1.0];
	}
}

- (void)toggleFullscreenAfterLaunch
{
	NSAssertReturn([self.mainWindow isInFullscreenMode]);

	[self.mainWindow toggleFullScreen:nil];
}

- (void)applicationDidFinishLaunching:(NSNotification *)note
{
	/* Register for HockeyApp. */
	[[BITHockeyManager sharedHockeyManager] configureWithIdentifier:@"b0b1c84f339487c2e184f7d1ebfe5997"
														companyName:@"Codeux Software"
														   delegate:self];

	[[BITHockeyManager sharedHockeyManager] startManager];

	/* Update application status. */
	[self.serverList updateBackgroundColor];
	
	if (self.worldController.clients.count < 1) {
		[self.mainWindowLoadingScreen hideAll:NO];
		[self.mainWindowLoadingScreen popWelcomeAddServerView];
	} else {
		[self.mainWindowLoadingScreen hideLoadingConfigurationView];

		[self.worldController autoConnectAfterWakeup:NO];	
	}

	[self maybeToggleFullscreenAfterLaunch];

	/* Copy other resources. */
	[TPCResourceManager copyResourcesToCustomAddonsFolder];
}

- (void)systemTintChangedNotification:(NSNotification *)notification;
{
	[self.memberList reloadAllUserInterfaceElements];

	[self.serverList reloadAllDrawings];
}

- (void)reloadMainWindowFrameOnScreenChange
{
	/* Redraw dock icon on potential screen resolution changes. */
	[TVCDockIcon resetCachedCount];
	
	[self.worldController updateIcon];
	
	/* Update wether we are in high-resolution mode and redraw some stuff if we move state. */
	BOOL inHighResMode = [[self.mainWindow screen] runningInHighResolutionMode];
	
	if (NSDissimilarObjects(self.applicationIsRunningInHighResMode, inHighResMode)) {
		[self.memberList reloadAllUserInterfaceElements];
		
		[self.serverList reloadAllDrawings];
	}
	
	self.applicationIsRunningInHighResMode = inHighResMode;
}

- (void)reloadUserInterfaceItems
{
	NSAssertReturn(self.terminating == NO);
	
	[self.serverList updateBackgroundColor];
	[self.serverList reloadAllDrawingsIgnoringOtherReloads];

	[self.memberList updateBackgroundColor];
	[self.memberList reloadAllDrawings];
}

- (void)resetSelectedItemState
{
	NSAssertReturn(self.terminating == NO);

	id sel = [self.worldController selectedItem];

	if (sel) {
		[sel resetState];
	}

	[self.worldController updateIcon];
}

- (void)applicationWillResignActive:(NSNotification *)notification
{
	self.applicationIsActive = NO;
	self.applicationIsChangingActiveState = YES;
}

- (void)applicationWillBecomeActive:(NSNotification *)notification
{
	self.applicationIsActive = YES;
	self.applicationIsChangingActiveState = YES;
}

- (void)applicationDidResignActive:(NSNotification *)notification
{
	self.applicationIsChangingActiveState = NO;
	self.mainWindowIsActive = NO;

	[self reloadUserInterfaceItems];
}

- (void)applicationDidBecomeActive:(NSNotification *)notification
{
	self.applicationIsChangingActiveState = NO;

	if ([self.mainWindow isEqual:[NSApp keyWindow]]) {
		self.mainWindowIsActive = YES;
	}

	[self reloadUserInterfaceItems];
}

- (BOOL)queryTerminate
{
	if (self.terminating) {
		return YES;
	}
	
	if ([TPCPreferences confirmQuit]) {
		NSInteger result = [TLOPopupPrompts dialogWindowWithQuestion:TXTLS(@"BasicLanguage[1000][1]")
															   title:TXTLS(@"BasicLanguage[1000][2]") 
													   defaultButton:TXTLS(@"BasicLanguage[1000][3]") 
													 alternateButton:TXTLS(@"BasicLanguage[1009]")
													  suppressionKey:nil
													 suppressionText:nil];
		
		return result;
	}
	
	return YES;
}

- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender
{
	if ([self queryTerminate]) {
		self.terminating = YES;

		return NSTerminateNow;
	} else {
		return NSTerminateCancel;
	}
}

- (NSMenu *)applicationDockMenu:(NSApplication *)sender
{
	return self.dockMenu;
}

- (BOOL)isNotSafeToPerformApplicationTermination
{
#ifdef TEXTUAL_BUILT_WITH_ICLOUD_SUPPORT
	if (self.cloudSyncManager) {
		return (
				/* Clients are still disconnecting. */
				self.terminatingClientCount > 0 ||

				/* iCloud is syncing. */
				([self.cloudSyncManager isSyncingLocalKeysDownstream] ||
				 [self.cloudSyncManager isSyncingLocalKeysUpstream])
		);
	} else {
		return (self.terminatingClientCount > 0);
	}
#else
	return (self.terminatingClientCount > 0);
#endif
}

- (void)applicationWillTerminate:(NSNotification *)note
{
	[self.mainWindow setDelegate:nil];

	[RZRunningApplication() hide];

	[RZWorkspaceNotificationCenter() removeObserver:self];

	[RZNotificationCenter() removeObserver:self];

	[RZAppleEventManager() removeEventHandlerForEventClass:KInternetEventClass andEventID:KAEGetURL];

#ifdef TEXTUAL_BUILT_WITH_ICLOUD_SUPPORT
	BOOL onMountainLionOrLater = [TPCPreferences featureAvailableToOSXMountainLion];

	if (onMountainLionOrLater) {
		[self.cloudSyncManager setApplicationIsTerminating:YES];
	}
#endif
	
	if (self.skipTerminateSave == NO) {
		[self saveWindowState];
	}
	
	[[self menuController] prepareForApplicationTermination];

	if (self.skipTerminateSave == NO) {
		self.terminatingClientCount = [[[self worldController] clients] count];

		[[self worldController] prepareForApplicationTermination];
		[[self worldController] save];

		while ([self isNotSafeToPerformApplicationTermination]) {
			[RZMainRunLoop() runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];
		}
	}
	
	[THOPluginManagerSharedInstance() unloadPlugins];
	
	[TPCPreferences saveTimeIntervalSinceApplicationInstall];

#ifdef TEXTUAL_BUILT_WITH_ICLOUD_SUPPORT
	if (onMountainLionOrLater) {
		[self.cloudSyncManager closeCloudSyncSession];
	}
#endif
	
#ifdef TEXTUAL_BUILT_WITH_APP_NAP_DISABLED
	if ([RZProcessInfo() respondsToSelector:@selector(endActivity:)]) {
		[RZProcessInfo() endActivity:self.appNapProgressInformation];
	}
#endif
}

- (BOOL)applicationShouldHandleReopen:(NSApplication *)sender hasVisibleWindows:(BOOL)flag
{
	[self.mainWindow makeKeyAndOrderFront:nil];

	return YES;
}

#pragma mark -
#pragma mark NSWorkspace Notifications

- (void)handleURLEvent:(NSAppleEventDescriptor *)event
		withReplyEvent:(NSAppleEventDescriptor *)replyEvent
{
	NSWindowNegateActionWithAttachedSheet();

	NSAppleEventDescriptor *desc = [event descriptorAtIndex:1];

	[IRCExtras parseIRCProtocolURI:desc.stringValue withDescriptor:event];
}

- (void)computerScreenWillSleep:(NSNotification *)note
{
	[self.worldController prepareForScreenSleep];
}

- (void)computerScreenDidWake:(NSNotification *)note
{
	[self.worldController awakeFomScreenSleep];
}

- (void)computerWillSleep:(NSNotification *)note
{
	[self.worldController prepareForSleep]; // Tell world to prepare.

	[self.speechSynthesizer setIsStopped:YES]; // Stop speaking during sleep.
	[self.speechSynthesizer clearQueue]; // Destroy pending spoken items.
}

- (void)computerDidWakeUp:(NSNotification *)note
{
	[self.speechSynthesizer setIsStopped:NO]; // We can speak again!

	[self.worldController autoConnectAfterWakeup:YES]; // Wake clients up…
}

- (void)computerWillPowerOff:(NSNotification *)note
{
	self.terminating = YES;
	
	[NSApp terminate:nil];
}

- (BOOL)applicationShouldOpenUntitledFile:(NSApplication *)sender
{
	[self.mainWindow makeKeyAndOrderFront:nil];
	
	return YES;
}

#pragma mark -
#pragma mark NSWindow Delegate

- (void)windowDidChangeScreen:(NSNotification *)notification
{
	[self reloadMainWindowFrameOnScreenChange];
}

- (void)windowDidBecomeKey:(NSNotification *)notification
{
	self.mainWindowIsActive = YES;

	if (self.applicationIsChangingActiveState == NO) {
		[self reloadUserInterfaceItems];
	}

	[self resetSelectedItemState];
}

- (void)windowDidResignKey:(NSNotification *)notification
{
	self.mainWindowIsActive = NO;

	if (self.applicationIsChangingActiveState == NO) {
		[self reloadUserInterfaceItems];
	}

	[self.memberList destroyUserInfoPopoverOnWindowKeyChange];
}

- (BOOL)window:(NSWindow *)window shouldPopUpDocumentPathMenu:(NSMenu *)menu
{
	/* Return NO so that we can use the document icon feature to show an icon
	 for an SSL unlock and lock locked and not allow user to click it. */

	return NO;
}

- (BOOL)window:(NSWindow *)window shouldDragDocumentWithEvent:(NSEvent *)event from:(NSPoint)dragImageLocation withPasteboard:(NSPasteboard *)pasteboard
{
	return NO;
}

- (void)windowDidResize:(NSNotification *)notification
{
	[self.inputTextField resetTextFieldCellSize:YES];
}

- (BOOL)windowShouldZoom:(NSWindow *)awindow toFrame:(NSRect)newFrame
{
	if (NSDissimilarObjects(self.mainWindow, awindow)) {
		return YES;
	} else {
		return BOOLReverseValue([self.mainWindow isInFullscreenMode]);
	}
}

- (NSSize)window:(NSWindow *)window willUseFullScreenContentSize:(NSSize)proposedSize
{
	return proposedSize;
}

- (NSApplicationPresentationOptions)window:(NSWindow *)window willUseFullScreenPresentationOptions:(NSApplicationPresentationOptions)proposedOptions
{
    return (NSApplicationPresentationFullScreen | NSApplicationPresentationHideDock | NSApplicationPresentationAutoHideMenuBar);
}

- (id)windowWillReturnFieldEditor:(NSWindow *)sender toObject:(id)client
{
	static BOOL formattingMenuSet;

	if (formattingMenuSet == NO) {
		NSMenu *editorMenu = [self.inputTextField menu];

		NSMenuItem *formatMenu = [self.formattingMenu formatterMenu];
		
		if (formatMenu) {
			NSInteger fmtrIndex = [editorMenu indexOfItemWithTitle:[formatMenu title]];
			
			if (fmtrIndex == -1) {
				[editorMenu addItem:[NSMenuItem separatorItem]];
				[editorMenu addItem:formatMenu];
			}
			
			[self.inputTextField setMenu:editorMenu];
		}

		formattingMenuSet = YES;
	}
    
    return self.inputTextField;
}

#pragma mark -
#pragma mark Properties

- (TLOInputHistory *)globalInputHistory
{
	if ([TPCPreferences inputHistoryIsChannelSpecific] == NO) {
		return _globalInputHistory;
	} else {
		return [[self.worldController selectedItem] inputHistory];
	}
}

#pragma mark -
#pragma mark Utilities

- (void)sendText:(NSString *)command
{
	NSAttributedString *as = [self.inputTextField attributedStringValue];

	[self.inputTextField setAttributedStringValue:[NSAttributedString emptyString]];

	if ([as length] > 0) {
		[self.worldController inputText:as command:command];
		
		[self.globalInputHistory add:as];
	}
	
	if (self.completionStatus) {
		[self.completionStatus clear:YES];
	}
}

- (void)textEntered
{
	[self sendText:IRCPrivateCommandIndex("privmsg")];
}

#pragma mark -
#pragma mark Split Views

- (void)showMemberListSplitView:(BOOL)showList
{
	self.memberSplitViewOldPosition = self.memberSplitView.dividerPosition;
	
	if (showList) {
		NSView *rightView = [self.memberSplitView.subviews safeObjectAtIndex:1];
		
		self.memberSplitView.viewIsHidden = NO;
		self.memberSplitView.viewIsInverted = NO;
		
		if ([self.memberSplitView isSubviewCollapsed:rightView] == NO) {
			if (self.memberSplitViewOldPosition < _minimumSplitViewWidth) {
				self.memberSplitViewOldPosition = _minimumSplitViewWidth;
			}
			
			self.memberSplitView.dividerPosition = self.memberSplitViewOldPosition;
		}
	} else {
		if (self.memberSplitView.viewIsHidden == NO) {
			self.memberSplitView.viewIsHidden = YES;
			self.memberSplitView.viewIsInverted = YES;
		}
	}
}

- (void)showServerListSplitView:(BOOL)showList
{
	self.serverListSplitViewOldPosition = self.serverSplitView.dividerPosition;

	if (showList) {
		NSView *leftView = [self.serverSplitView.subviews safeObjectAtIndex:0];

		self.serverSplitView.viewIsHidden = NO;

		if ([self.serverSplitView isSubviewCollapsed:leftView] == NO) {
			if (self.serverListSplitViewOldPosition < _minimumSplitViewWidth) {
				self.serverListSplitViewOldPosition = _minimumSplitViewWidth;
			}

			self.serverSplitView.dividerPosition = self.serverListSplitViewOldPosition;
		}
	} else {
		if (self.serverSplitView.viewIsHidden == NO) {
			self.serverSplitView.viewIsHidden = YES;
		}
	}
}

- (NSRect)splitView:(NSSplitView *)splitView effectiveRect:(NSRect)proposedEffectiveRect forDrawnRect:(NSRect)drawnRect ofDividerAtIndex:(NSInteger)dividerIndex
{
	if ([splitView isEqual:self.memberSplitView]) {
		if (self.memberSplitView.viewIsHidden) {
			return NSZeroRect;
		}
	} else if ([splitView isEqual:self.serverSplitView]) {
		if (self.serverSplitView.viewIsHidden) {
			return NSZeroRect;
		}
	}

	return proposedEffectiveRect;
}

- (CGFloat)splitView:(NSSplitView *)splitView constrainMaxCoordinate:(CGFloat)proposedMax ofSubviewAt:(NSInteger)dividerIndex
{
	if ([splitView isEqual:self.memberSplitView]) {
		NSView *leftSide = splitView.subviews[0];
		NSView *rightSide = splitView.subviews[1];
		
		NSInteger leftWidth  = leftSide.bounds.size.width;
		NSInteger rightWidth = rightSide.bounds.size.width;
		
		return ((leftWidth + rightWidth) - _minimumSplitViewWidth);
	}
	
	return _maximumSplitViewWidth;
}

- (CGFloat)splitView:(NSSplitView *)splitView constrainMinCoordinate:(CGFloat)proposedMax ofSubviewAt:(NSInteger)dividerIndex
{
	if ([splitView isEqual:self.memberSplitView]) {
		NSView *leftSide = splitView.subviews[0];
		NSView *rightSide = splitView.subviews[1];

		NSInteger leftWidth  = leftSide.bounds.size.width;
		NSInteger rightWidth = rightSide.bounds.size.width;
		
		return ((leftWidth + rightWidth) - _maximumSplitViewWidth);
	}
	
	return _minimumSplitViewWidth;
}

- (BOOL)splitView:(NSSplitView *)splitView canCollapseSubview:(NSView *)subview
{
	return NO;
}

#pragma mark -
#pragma mark Preferences

- (void)loadWindowState
{
	[self.mainWindow restoreWindowStateUsingKeyword:@"Main Window"];

	NSDictionary *dic = [RZUserDefaults() dictionaryForKey:@"Window -> Main Window Window State"];

	if (dic) {
		if ([dic containsKey:@"serverList"] == NO) {
			self.serverSplitView.dividerPosition = 165;
		} else {
			self.serverSplitView.dividerPosition = [dic integerForKey:@"serverList"];

			if (self.serverSplitView.dividerPosition < _minimumSplitViewWidth) {
				self.serverSplitView.dividerPosition = _defaultSplitViewWidth;
			}
		}

		if ([dic containsKey:@"memberList"] == NO) {
			self.memberSplitView.dividerPosition = 120;
		} else {
			self.memberSplitView.dividerPosition = [dic integerForKey:@"memberList"];
			
			if (self.memberSplitView.dividerPosition < _minimumSplitViewWidth) {
				self.memberSplitView.dividerPosition = _defaultSplitViewWidth;
			}
		}
	} else {
		self.serverSplitView.dividerPosition = 165;
		self.memberSplitView.dividerPosition = 120;
	}

	self.serverListSplitViewOldPosition = [self.serverSplitView dividerPosition];
	self.memberSplitViewOldPosition = [self.memberSplitView dividerPosition];
}

- (void)saveWindowState
{
	NSMutableDictionary *dic = [NSMutableDictionary dictionary];
	
	if (self.serverSplitView.dividerPosition < _minimumSplitViewWidth) {
		if (self.serverListSplitViewOldPosition < _minimumSplitViewWidth) {
			self.serverSplitView.dividerPosition = _defaultSplitViewWidth;
		} else {
			self.serverSplitView.dividerPosition = self.serverListSplitViewOldPosition;
		}
	}
	
	if (self.memberSplitView.dividerPosition < _minimumSplitViewWidth) {
		if (self.memberSplitViewOldPosition < _minimumSplitViewWidth) {
			self.memberSplitView.dividerPosition = _defaultSplitViewWidth;
		} else {
			self.memberSplitView.dividerPosition = self.memberSplitViewOldPosition;
		}
	}

	[dic setBool:[self.mainWindow isInFullscreenMode] forKey:@"fullscreen"];

	[self.mainWindow saveWindowStateUsingKeyword:@"Main Window"];
	
	[dic setInteger:self.serverSplitView.dividerPosition forKey:@"serverList"];
	[dic setInteger:self.memberSplitView.dividerPosition forKey:@"memberList"];

	[RZUserDefaults() setObject:dic forKey:@"Window -> Main Window Window State"];
}

#pragma mark -
#pragma mark Nick Completion

- (void)completeNick:(BOOL)forward
{
	if (PointerIsEmpty(self.completionStatus)) {
		self.completionStatus = [TLONickCompletionStatus new];
	}

	[self.completionStatus completeNick:forward];
}

#pragma mark -
#pragma mark Keyboard Navigation

typedef enum TXMoveKind : NSInteger {
	TXMoveUpKind,      // Channel
	TXMoveDownKind,    // Channel
	TXMoveLeftKind,    // Server
	TXMoveRightKind,   // Server
	TXMoveAllKind,     // Move to next item.
	TXMoveActiveKind,  // Move to next active item.
	TXMoveUnreadKind,  // Move to next unread item. 
} TXMoveKind;

- (void)move:(TXMoveKind)dir target:(TXMoveKind)target
{
	NSWindowNegateActionWithAttachedSheet();

	IRCTreeItem *selected = self.worldController.selectedItem;

	PointerIsEmptyAssert(selected);

	/* ************************************************************** */
	/* Start: Channel Movement Actions.								  */
	/* Design: Switch channel regardless of server location. This
	 was the behavior used by version 2.1.1 and was cut out in 3.0.0
	 to favor server specific navigation, but everybody would not 
	 stop complaining so here you go… */
	/* ************************************************************** */

	BOOL moveBetweenServers = [TPCPreferences channelNavigationIsServerSpecific];

	if ((dir == TXMoveUpKind || dir == TXMoveDownKind) && moveBetweenServers == NO) {
		NSInteger count = self.serverList.numberOfRows;

		NSAssertReturn(count > 1);

		NSInteger n = [self.serverList rowForItem:selected];
		NSInteger start = n;

		while (1 == 1) {
			if (dir == TXMoveDownKind) {
				n += 1;
			} else {
				n -= 1;
			}

			if (n >= count || n < 0) {
				if (dir == TXMoveUpKind && n < 0) {
					n = (count - 1);
				} else {
					n = 0;
				}
			}

			if (n == start) break;

			id i = [self.serverList itemAtRow:n];

			if ([i isClient]) {
				continue;
			}

			if ([i isChannel] || [i isPrivateMessage]) {
				if (target == TXMoveAllKind) {
					[self.worldController select:i];

					break;
				} else if (target == TXMoveActiveKind) {
					if ([i isActive]) {
						[self.worldController select:i];

						break;
					}
				} else if (target == TXMoveUnreadKind) {
					if ([i isUnread]) {
						[self.worldController select:i];

						break;
					}
				}
			}
		}

		return;
	}

	/* ************************************************************** */
	/* End: Channel Movement Actions.								  */
	/* ************************************************************** */

	/* ************************************************************** */
	/* Start: Channel Movement Actions.								  */
	/* Design: The channel movement actions are designed to be local
	 to each server. Moving up or down a channel will keep it within
	 the list of channels associated with the selected server. All 
	 other channels are ignored.									  */
	/* ************************************************************** */
	
	if (dir == TXMoveUpKind || dir == TXMoveDownKind)
	{
		NSArray *scannedRows = [self.serverList rowsFromParentGroup:selected];
		scannedRows = [@[[selected client]] arrayByAddingObjectsFromArray:scannedRows];

		NSInteger n = [scannedRows indexOfObject:selected];

		NSInteger start = n;
		NSInteger count = scannedRows.count;

		while (1 == 1) {
			if (dir == TXMoveDownKind) {
				n += 1;
			} else {
				n -= 1;
			}

			if (n >= count || n < 0) {
				if (dir == TXMoveUpKind && n < 0) {
					n = (count - 1);
				} else {
					n = 0;
				}
			}

			if (n == start) {
				break;
			}

			id i = [scannedRows objectAtIndex:n];

			if ([i isChannel] || [i isPrivateMessage]) {
				if (target == TXMoveAllKind) {
					[self.worldController select:i];

					break;
				} else if (target == TXMoveActiveKind) {
					if ([i isActive]) {
						[self.worldController select:i];

						break;
					}
				} else if (target == TXMoveUnreadKind) {
					if ([i isUnread]) {
						[self.worldController select:i];

						break;
					}
				}
			}
		}

		return;
	}

	/* ************************************************************** */
	/* End: Channel Movement Actions.								  */
	/* ************************************************************** */

	/* ************************************************************** */
	/* Start: Server Movement Actions.								  */
	/* Design: Unlike channel movement, server movement is much more
	 simple. We only have to switch between each server depdngin on 
	 the type of movement asked for.								  */
	/* ************************************************************** */

	if (dir == TXMoveLeftKind || dir == TXMoveRightKind)
	{
		selected = selected.client;

		NSArray *scannedRows = [self.serverList groupItems];

		NSInteger n = [scannedRows indexOfObject:selected];

		NSInteger start = n;
		NSInteger count = scannedRows.count;

		NSAssertReturn(count > 1);

		while (1 == 1) {
			if (dir == TXMoveRightKind) {
				n += 1;
			} else {
				n -= 1;
			}

			if (n >= count || n < 0) {
				if (dir == TXMoveLeftKind && n < 0) {
					n = (count - 1);
				} else {
					n = 0;
				}
			}

			if (n == start) {
				break;
			}

			id i = [scannedRows objectAtIndex:n];

			if (target == TXMoveAllKind) {
				[self.worldController select:i];

				break;
			} else if (target == TXMoveActiveKind) {
				if ([i isActive]) {
					[self.worldController select:i];

					break;
				}
			}
		}
		
		return;
	}

	/* ************************************************************** */
	/* End: Server Movement Actions.								  */
	/* ************************************************************** */
	
	/* ************************************************************** */
	/* Start: All Movement Actions.									  */
	/* Design: Move to next or previous item regardless of its type.  */
	/* ************************************************************** */

	if (dir == TXMoveAllKind)
	{
		NSInteger count = self.serverList.numberOfRows;

		NSAssertReturn(count > 1);

		NSInteger n = [self.serverList rowForItem:selected];

		if (target == TXMoveUpKind) {
			n -= 1;
		} else if (target == TXMoveDownKind) {
			n += 1;
		}

		if (n >= count || n < 0) {
			if (target == TXMoveUpKind && n < 0) {
				n = (count - 1);
			} else {
				n = 0;
			}
		}

		id i = [self.serverList itemAtRow:n];

		[self.worldController select:i];
		
		return;
	}
	
	/* ************************************************************** */
	/* End: All Movement Actions.									  */
	/* ************************************************************** */
}

- (void)selectPreviousChannel:(NSEvent *)e
{
	[self move:TXMoveUpKind target:TXMoveAllKind];
}

- (void)selectNextChannel:(NSEvent *)e
{
	[self move:TXMoveDownKind target:TXMoveAllKind];
}

- (void)selectPreviousUnreadChannel:(NSEvent *)e
{
	[self move:TXMoveUpKind target:TXMoveUnreadKind];
}

- (void)selectNextUnreadChannel:(NSEvent *)e
{
	[self move:TXMoveDownKind target:TXMoveUnreadKind];
}

- (void)selectPreviousActiveChannel:(NSEvent *)e
{
	[self move:TXMoveUpKind target:TXMoveActiveKind];
}

- (void)selectNextActiveChannel:(NSEvent *)e
{
	[self move:TXMoveDownKind target:TXMoveActiveKind];
}

- (void)selectPreviousServer:(NSEvent *)e
{
	[self move:TXMoveLeftKind target:TXMoveAllKind];
}

- (void)selectNextServer:(NSEvent *)e
{
	[self move:TXMoveRightKind target:TXMoveAllKind];
}

- (void)selectPreviousActiveServer:(NSEvent *)e
{
	[self move:TXMoveLeftKind target:TXMoveActiveKind];
}

- (void)selectNextActiveServer:(NSEvent *)e
{
	[self move:TXMoveRightKind target:TXMoveActiveKind];
}

- (void)selectPreviousSelection:(NSEvent *)e
{
	[self.worldController selectPreviousItem];
}

- (void)selectNextWindow:(NSEvent *)e
{
	[self move:TXMoveAllKind target:TXMoveDownKind];
}

- (void)selectPreviousWindow:(NSEvent *)e
{
	[self move:TXMoveAllKind target:TXMoveUpKind];
}

- (void)tab:(NSEvent *)e
{
	NSWindowNegateActionWithAttachedSheet();

	TXTabKeyAction tabKeyAction = [TPCPreferences tabKeyAction];

	if (tabKeyAction == TXTabKeyNickCompleteAction) {
		[self completeNick:YES];
	} else if (tabKeyAction == TXTabKeyUnreadChannelAction) {
		[self move:TXMoveDownKind target:TXMoveUnreadKind];
	}
}

- (void)shiftTab:(NSEvent *)e
{
	NSWindowNegateActionWithAttachedSheet();

	TXTabKeyAction tabKeyAction = [TPCPreferences tabKeyAction];

	if (tabKeyAction == TXTabKeyNickCompleteAction) {
		[self completeNick:NO];
	} else if (tabKeyAction == TXTabKeyUnreadChannelAction) {
		[self move:TXMoveUpKind target:TXMoveUnreadKind];
	}
}

- (void)sendControlEnterMessageMaybe:(NSEvent *)e
{
	if ([TPCPreferences controlEnterSnedsMessage]) {
		[self textEntered];
	} else {
		[self.inputTextField keyDownToSuper:e];
	}
}

- (void)sendMsgAction:(NSEvent *)e
{
	NSWindowNegateActionWithAttachedSheet();

	if ([TPCPreferences commandReturnSendsMessageAsAction]) {
		[self sendText:IRCPrivateCommandIndex("action")];
	} else {
		[self textEntered];
	}
}

- (void)moveInputHistory:(BOOL)up checkScroller:(BOOL)scroll event:(NSEvent *)event
{
	NSWindowNegateActionWithAttachedSheet();

	if (scroll) {
		NSInteger nol = [self.inputTextField numberOfLines];
		
		if (nol >= 2) {
			BOOL atTop = [self.inputTextField isAtTopOfView];
			BOOL atBottom = [self.inputTextField isAtBottomOfView];
			
			if ((atTop && event.keyCode == TXKeyDownArrowCode) ||
				(atBottom && event.keyCode == TXKeyUpArrowCode) ||
				(atTop == NO && atBottom == NO)) {
				
				[self.inputTextField keyDownToSuper:event];
				
				return;
			}
		}
	}
	
	NSAttributedString *s;
	
	if (up) {
		s = [self.globalInputHistory up:[self.inputTextField attributedStringValue]];
	} else {
		s = [self.globalInputHistory down:[self.inputTextField attributedStringValue]];
	}
	
	if (s) {
        [self.inputTextField setAttributedStringValue:s];
		[self.inputTextField resetTextFieldCellSize:NO];
		[self.inputTextField focus];
	}
}

- (void)inputHistoryUp:(NSEvent *)e
{
	[self moveInputHistory:YES checkScroller:NO event:e];
}

- (void)inputHistoryDown:(NSEvent *)e
{
	[self moveInputHistory:NO checkScroller:NO event:e];
}

- (void)inputHistoryUpWithScrollCheck:(NSEvent *)e
{
	[self moveInputHistory:YES checkScroller:YES event:e];
}

- (void)inputHistoryDownWithScrollCheck:(NSEvent *)e
{
	[self moveInputHistory:NO checkScroller:YES event:e];
}

- (void)textFormattingBold:(NSEvent *)e
{
	NSWindowNegateActionWithAttachedSheet();

	if ([self.formattingMenu boldSet]) {
		[self.formattingMenu removeBoldCharFromTextBox:nil];
	} else {
		[self.formattingMenu insertBoldCharIntoTextBox:nil];
	}
}

- (void)textFormattingItalic:(NSEvent *)e
{
	NSWindowNegateActionWithAttachedSheet();

	if ([self.formattingMenu italicSet]) {
		[self.formattingMenu removeItalicCharFromTextBox:nil];
	} else {
		[self.formattingMenu insertItalicCharIntoTextBox:nil];
	}
}

- (void)textFormattingUnderline:(NSEvent *)e
{
	NSWindowNegateActionWithAttachedSheet();

	if ([self.formattingMenu underlineSet]) {
		[self.formattingMenu removeUnderlineCharFromTextBox:nil];
	} else {
		[self.formattingMenu insertUnderlineCharIntoTextBox:nil];
	}
}

- (void)textFormattingForegroundColor:(NSEvent *)e
{
	NSWindowNegateActionWithAttachedSheet();

	if ([self.formattingMenu foregroundColorSet]) {
		[self.formattingMenu removeForegroundColorCharFromTextBox:nil];
	} else {
		NSRect fieldRect = [self.formattingMenu.textField frame];
		
		fieldRect.origin.y -= 200;
		fieldRect.origin.x += 100;
		
		[self.formattingMenu.foregroundColorMenu popUpMenuPositioningItem:nil atLocation:fieldRect.origin inView:self.formattingMenu.textField];
	}
}

- (void)textFormattingBackgroundColor:(NSEvent *)e
{
	NSWindowNegateActionWithAttachedSheet();

	if ([self.formattingMenu foregroundColorSet]) {
		if ([self.formattingMenu backgroundColorSet]) {
			[self.formattingMenu removeForegroundColorCharFromTextBox:nil];
		} else {
			NSRect fieldRect = [self.formattingMenu.textField frame];
			
			fieldRect.origin.y -= 200;
			fieldRect.origin.x += 100;
			
			[self.formattingMenu.backgroundColorMenu popUpMenuPositioningItem:nil atLocation:fieldRect.origin inView:self.formattingMenu.textField];
		}
	}
}

- (void)exitFullscreenMode:(NSEvent *)e
{
    if ([self.mainWindow isInFullscreenMode] && [self.inputTextField isFocused] == NO) {
        [self.mainWindow toggleFullScreen:nil];
    } else {
        [self.inputTextField keyDown:e];
    }
}

- (void)speakPendingNotifications:(NSEvent *)e
{
	[self.speechSynthesizer stopSpeakingAndMoveForward];
}

- (void)focusWebview
{
	NSWindowNegateActionWithAttachedSheet();
	
    [self.mainWindow makeFirstResponder:self.worldController.selectedViewController.view];
}

- (void)handler:(SEL)sel code:(NSInteger)keyCode mods:(NSUInteger)mods
{
	[self.mainWindow registerKeyHandler:sel key:keyCode modifiers:mods];
}

- (void)handler:(SEL)sel char:(UniChar)c mods:(NSUInteger)mods
{
	[self.mainWindow registerKeyHandler:sel character:c modifiers:mods];
}

- (void)inputHandler:(SEL)sel code:(NSInteger)keyCode mods:(NSUInteger)mods
{
	[self.inputTextField registerKeyHandler:sel key:keyCode modifiers:mods];
}

- (void)inputHandler:(SEL)sel char:(UniChar)c mods:(NSUInteger)mods
{
	[self.inputTextField registerKeyHandler:sel character:c modifiers:mods];
}

- (void)registerKeyHandlers
{
	[self.mainWindow setKeyHandlerTarget:self];
	[self.inputTextField setKeyHandlerTarget:self];
    
    [self handler:@selector(exitFullscreenMode:) code:TXKeyEscapeCode mods:0];
	
	[self handler:@selector(tab:) code:TXKeyTabCode mods:0];
	[self handler:@selector(shiftTab:) code:TXKeyTabCode mods:NSShiftKeyMask];
	
	[self handler:@selector(selectPreviousSelection:) code:TXKeyTabCode mods:NSAlternateKeyMask];
	
	[self handler:@selector(textFormattingBold:)			char:'b' mods: NSCommandKeyMask];
	[self handler:@selector(textFormattingUnderline:)		char:'u' mods:(NSCommandKeyMask | NSAlternateKeyMask)];
	[self handler:@selector(textFormattingItalic:)			char:'i' mods:(NSCommandKeyMask | NSAlternateKeyMask)];
    [self handler:@selector(textFormattingForegroundColor:) char:'c' mods:(NSCommandKeyMask | NSAlternateKeyMask)];
	[self handler:@selector(textFormattingBackgroundColor:) char:'h' mods:(NSCommandKeyMask | NSAlternateKeyMask)];

	[self handler:@selector(speakPendingNotifications:) char:'.' mods:NSCommandKeyMask];

	[self handler:@selector(inputHistoryUp:) char:'p' mods:NSControlKeyMask];
	[self handler:@selector(inputHistoryDown:) char:'n' mods:NSControlKeyMask];

	[self inputHandler:@selector(sendControlEnterMessageMaybe:) code:TXKeyEnterCode mods:NSControlKeyMask];
	
	[self inputHandler:@selector(sendMsgAction:) code:TXKeyReturnCode mods:NSCommandKeyMask];
	[self inputHandler:@selector(sendMsgAction:) code:TXKeyEnterCode mods:NSCommandKeyMask];
	
    [self inputHandler:@selector(focusWebview) char:'l' mods:(NSAlternateKeyMask | NSCommandKeyMask)];
    
	[self inputHandler:@selector(inputHistoryUpWithScrollCheck:) code:TXKeyUpArrowCode mods:0];
	[self inputHandler:@selector(inputHistoryUpWithScrollCheck:) code:TXKeyUpArrowCode mods:NSAlternateKeyMask];
	
	[self inputHandler:@selector(inputHistoryDownWithScrollCheck:) code:TXKeyDownArrowCode mods:0];
	[self inputHandler:@selector(inputHistoryDownWithScrollCheck:) code:TXKeyDownArrowCode mods:NSAlternateKeyMask];
}

#pragma mark -
#pragma mark WindowSegmentedController Delegate

- (void)reloadSegmentedControllerOrigin
{
	[self.inputTextField redrawOriginPoints];
}

- (void)updateSegmentedController
{
	if ([TPCPreferences hideMainWindowSegmentedController] == NO) {
		[self.mainWindowButtonController setEnabled:(self.worldController.clients.count >= 1)];
		
		/* Selection Settings. */
		IRCClient *u = self.worldController.selectedClient;
		IRCChannel *c = self.worldController.selectedChannel;
		
		if (PointerIsEmpty(c)) {
			[self.mainWindowButtonController setMenu:self.serverMenuItem.submenu forSegment:1];
		} else {
			[self.mainWindowButtonController setMenu:self.channelMenuItem.submenu forSegment:1];
		}

		[self.mainWindowButtonController setMenu:self.segmentedControllerMenu forSegment:0];
		
		/* Open Address Book. */
		[self.mainWindowButtonController setEnabled:(PointerIsNotEmpty(u) && u.isConnected) forSegment:2];
	}
}

#pragma mark -
#pragma mark WelcomeSheet Delegate

- (void)openWelcomeSheet:(id)sender
{
	[self.menuController popWindowSheetIfExists];
	
	TDCWelcomeSheet *welcomeSheet = [TDCWelcomeSheet new];

	welcomeSheet.delegate = self;
	welcomeSheet.window = self.mainWindow;
	
	[welcomeSheet show];

	[self.menuController addWindowToWindowList:welcomeSheet];
}

- (void)welcomeSheet:(TDCWelcomeSheet *)sender onOK:(NSDictionary *)config
{
	NSMutableDictionary *dic = [NSMutableDictionary dictionary];
	
	NSString *serverad = config[@"serverAddress"];
	NSString *nickname = config[@"identityNickname"];

	NSMutableArray *channels = [NSMutableArray array];

	for (NSString *s in config[@"channelList"]) {
		[channels safeAddObject:[IRCChannelConfig seedDictionary:s]];
	}
	
	dic[@"serverAddress"]				= serverad;
	dic[@"connectionName"]				= serverad;
	dic[@"identityNickname"]			= nickname;
	dic[@"channelList"]					= channels;
	dic[@"connectOnLaunch"]				= config[@"connectOnLaunch"];
	dic[@"characterEncodingDefault"]	= @(TXDefaultPrimaryTextEncoding);
	
	IRCClient *u = [self.worldController createClient:dic reload:YES];

	[self.worldController expandClient:u];
	[self.worldController save];
	
	if (u.config.autoConnect) {
		[u connect];
	}
	
	[self.mainWindow makeKeyAndOrderFront:nil];

	NSObjectIsEmptyAssert(u.channels);

	[self.worldController select:u.channels[0]];
}

- (void)welcomeSheetWillClose:(TDCWelcomeSheet *)sender
{
	[self.menuController removeWindowFromWindowList:@"TDCWelcomeSheet"];
}

@end

@implementation NSObject (TXMasterControllerObjectExtension)

- (TXMasterController *)masterController
{
	return TXGlobalMasterControllerClassReference;
}

+ (TXMasterController *)masterController
{
	return TXGlobalMasterControllerClassReference;
}

- (IRCWorld *)worldController
{
	return [TXGlobalMasterControllerClassReference world];
}

+ (IRCWorld *)worldController
{
	return [TXGlobalMasterControllerClassReference world];
}

- (TPCThemeController *)themeController
{
	return [TXGlobalMasterControllerClassReference themeControllerPntr];
}

+ (TPCThemeController *)themeController
{
	return [TXGlobalMasterControllerClassReference themeControllerPntr];
}

- (TXMenuController *)menuController
{
	return [TXGlobalMasterControllerClassReference menuController];
}

+ (TXMenuController *)menuController
{
	return [TXGlobalMasterControllerClassReference menuController];
}

@end
