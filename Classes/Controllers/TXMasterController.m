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

		return self;
    }

    return nil;
}

#pragma mark -
#pragma mark NSApplication Delegate

- (void)awakeFromNib
{
#ifdef TEXTUAL_TRIAL_BINARY
	[TLOPopupPrompts dialogWindowWithQuestion:TXTLS(@"TrialPeriodIntroductionDialogMessage")
										title:TXTLS(@"TrialPeriodIntroductionDialogTitle")
								defaultButton:TXTLS(@"OkButton")
							  alternateButton:nil
							   suppressionKey:@"trial_period_info"
							  suppressionText:nil];
#endif

	// ---- //

	DebugLogToConsole(@"Temporary Folder: %@", [TPCPreferences applicationTemporaryFolderPath]);

	// ---- //

	if ([NSEvent modifierFlags] & NSShiftKeyMask) {
		self.ghostMode = YES;
	}

#if defined(DEBUG)
    self.ghostMode = YES; // Do not use autoconnect during debug.
#endif

	[TPCPreferences initPreferences];

	[self loadWindowState:YES];

	[self.mainWindow makeMainWindow];

	self.serverSplitView.fixedViewIndex = 0;
	self.memberSplitView.fixedViewIndex = 1;

	[self.mainWindowLoadingScreen hideAll:NO];
	[self.mainWindowLoadingScreen popLoadingConfigurationView];

	/* The most important part of this call is to get the main window
	 to the user as soon as possible. We only put what is absolutely 
	 needed above this request for the main window. The more time we
	 take to get to the main window, the longer the end user has to
	 wait for it. That is the purpose of the loading screen. To give
	 the end user acknowledgement that we are waking up and not just
	 sitting here doing nothing. 
	 
	 On a 2009 Intel i7 2.80 GHz iMac running 10.8.2 the time it took 
	 to pop our window was on average 0.058 seconds or 58 milliseconds. */
	
	[self.mainWindow makeKeyAndOrderFront:nil];
	[self.mainWindow setAlphaValue:[TPCPreferences themeTransparency]];
	
	self.themeController = [TPCThemeController new];
	[self.themeController load];

	[self.inputTextField setAllowColorInversion:YES];

	[self.inputTextField focus];
	[self.inputTextField updateTextColor];
	[self.inputTextField redrawOriginPoints];
	[self.inputTextField updateTextDirection];

	[self.inputTextField setBackgroundColor:[NSColor clearColor]];

	[self registerKeyHandlers];

	[self.formattingMenu enableWindowField:self.inputTextField];
	
	self.world = [IRCWorld new];

	self.serverSplitView.delegate = self;
	self.memberSplitView.delegate = self;

	[self.serverList updateBackgroundColor];
	[self.memberList updateBackgroundColor];

	[self.worldController setupConfiguration];

	self.serverList.delegate = self.worldController;
	self.serverList.dataSource = self.worldController;
    self.memberList.keyDelegate	= self.worldController;
	self.serverList.keyDelegate	= self.worldController;

	[self.serverList reloadData];
	
	[self.worldController setupTree];

	[self.memberList setTarget:self.menuController];
	[self.memberList setDoubleAction:@selector(memberListDoubleClicked:)];

	if ([TPCPreferences inputHistoryIsChannelSpecific] == NO) {
		self.inputHistory = [TLOInputHistory new];
	}

	self.growlController = [TLOGrowlController new];

	[RZWorkspaceNotificationCenter() addObserver:self selector:@selector(computerDidWakeUp:) name:NSWorkspaceDidWakeNotification object:nil];
	[RZWorkspaceNotificationCenter() addObserver:self selector:@selector(computerWillSleep:) name:NSWorkspaceWillSleepNotification object:nil];
	[RZWorkspaceNotificationCenter() addObserver:self selector:@selector(computerWillPowerOff:) name:NSWorkspaceWillPowerOffNotification object:nil];
	[RZWorkspaceNotificationCenter() addObserver:self selector:@selector(computerScreenDidWake:) name:NSWorkspaceScreensDidWakeNotification object:nil];
	[RZWorkspaceNotificationCenter() addObserver:self selector:@selector(computerScreenWillSleep:) name:NSWorkspaceScreensDidSleepNotification object:nil];

	[RZAppleEventManager() setEventHandler:self andSelector:@selector(handleURLEvent:withReplyEvent:) forEventClass:KInternetEventClass andEventID:KAEGetURL];

	self.pluginManager = [THOPluginManager new];
	[self.pluginManager loadPlugins];
}

- (void)applicationDidFinishLaunching:(NSNotification *)note
{
	if (self.worldController.clients.count < 1) {
		[self.mainWindowLoadingScreen hideAll:NO];
		[self.mainWindowLoadingScreen popWelcomeAddServerView];

		[self openWelcomeSheet:nil];
	} else {
		[self.mainWindowLoadingScreen hideLoadingConfigurationView];
		
		[self.worldController autoConnectAfterWakeup:NO];	
	}
}

- (void)applicationDidChangeScreenParameters:(NSNotification *)aNotification
{
	if (self.isInFullScreenMode) {
		/* Reset window frame if screen resolution is changed. */
		
		[self.mainWindow setFrame:[RZMainScreen() frame] display:YES animate:YES];
	} else {
		NSRect visibleRect = RZMainScreen().visibleFrame;
		NSRect windowRect = self.mainWindow.frame;
		
		BOOL redrawFrame = NO;
		
		if (visibleRect.size.height < windowRect.size.height) {
			windowRect.size.height = visibleRect.size.height;
			windowRect.origin.x = visibleRect.origin.x;
			
			redrawFrame = YES;
		}
		
		if (visibleRect.size.width < windowRect.size.width) {
			windowRect.size.width = visibleRect.size.width;
			windowRect.origin.y = visibleRect.origin.y;
			
			redrawFrame = YES;
		}
		
		if (redrawFrame) {
			[self.mainWindow setFrame:windowRect display:YES animate:YES];
		}
	}

	/* Redraw dock icon on potential screen resolution changes. */
    [self.worldController updateIcon];
}

- (void)applicationDidBecomeActive:(NSNotification *)note
{
	id sel = self.worldController.selectedItem;
    
	if (sel) {
		[sel resetState];
	}

    [self.worldController reloadTree];
    [self.worldController updateIcon];
	
	[self.inputTextField.backgroundView setWindowIsActive:YES];
}

- (void)applicationDidResignActive:(NSNotification *)note
{
	id sel = self.worldController.selectedItem;
    
	if (sel) {
		[sel resetState];
	}

    [self.worldController reloadTree];
	
	[self.inputTextField.backgroundView setWindowIsActive:NO];
}

- (BOOL)queryTerminate
{
	if (self.terminating) {
		return YES;
	}
	
	if ([TPCPreferences confirmQuit]) {
		NSInteger result = [TLOPopupPrompts dialogWindowWithQuestion:TXTLS(@"ApplicationWantsToTerminatePromptMessage")
															   title:TXTLS(@"ApplicationWantsToTerminatePromptTitle") 
													   defaultButton:TXTLS(@"QuitButton") 
													 alternateButton:TXTLS(@"CancelButton")
													  suppressionKey:nil suppressionText:nil];
		
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

- (void)applicationWillTerminate:(NSNotification *)note
{
	NSAppleEventManager *em = [NSAppleEventManager sharedAppleEventManager];
	
	[em removeEventHandlerForEventClass:KInternetEventClass andEventID:KAEGetURL];

	if (self.skipTerminateSave == NO) {
		[self.worldController save];
		[self.worldController terminate];
		
		[self.menuController terminate];
		
		[self saveWindowState];
	}
	
	[TPCPreferences saveTimeIntervalSinceApplicationInstall];
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
	NSAppleEventDescriptor *desc = [event descriptorAtIndex:1];

	[IRCExtras parseIRCProtocolURI:desc.stringValue];
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
	[self.worldController prepareForSleep];
}

- (void)computerDidWakeUp:(NSNotification *)note
{
	[self.worldController autoConnectAfterWakeup:YES];
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

- (void)windowDidResize:(NSNotification *)notification
{
	[self.inputTextField resetTextFieldCellSize:YES];
}

- (void)windowDidBecomeKey:(NSNotification *)notification
{
	id sel = self.worldController.selectedItem;
	
	if (sel) {
		[sel resetState];
	}

    [self.worldController reloadTree];
    [self.worldController updateIcon];
}

- (void)windowWillEnterFullScreen:(NSNotification *)notification
{
	[self saveWindowState];
}

- (void)windowDidEnterFullScreen:(NSNotification *)notification
{
	self.isInFullScreenMode = YES;
}

- (void)windowDidExitFullScreen:(NSNotification *)notification
{
	[self loadWindowState:NO];
	
	self.isInFullScreenMode = NO;
}

- (NSSize)windowWillResize:(NSWindow *)awindow toSize:(NSSize)newSize
{
	if (NSDissimilarObjects(awindow, self.mainWindow)) {
		return newSize; 
	} else {
		if (self.isInFullScreenMode) {
			return awindow.frame.size;
		} else {
			return newSize;
		}
	}
}

- (BOOL)windowShouldZoom:(NSWindow *)awindow toFrame:(NSRect)newFrame
{
	if (NSDissimilarObjects(self.mainWindow, awindow)) {
		return YES;
	} else {
		return BOOLReverseValue(self.isInFullScreenMode);
	}
}

- (id)windowWillReturnFieldEditor:(NSWindow *)sender toObject:(id)client
{
    NSMenu	   *editorMenu = self.inputTextField.menu;
    NSMenuItem *formatMenu = self.formattingMenu.formatterMenu;
    
    if (formatMenu) {
        NSInteger fmtrIndex = [editorMenu indexOfItemWithTitle:formatMenu.title];
        
        if (fmtrIndex == -1) {
            [editorMenu addItem:[NSMenuItem separatorItem]];
            [editorMenu addItem:formatMenu];
        }
        
        [self.inputTextField setMenu:editorMenu];
    }
    
    return self.inputTextField;
}

#pragma mark -
#pragma mark Utilities

- (void)sendText:(NSString *)command
{
	NSAttributedString *as = [self.inputTextField attributedStringValue];
	
	[self.inputTextField setAttributedStringValue:[NSAttributedString emptyString]];

	if (NSObjectIsNotEmpty(as)) {
		[self.worldController inputText:as command:command];
		
		[self.inputHistory add:as];
	}
	
	if (self.completionStatus) {
		[self.completionStatus clear];
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
	if ([splitView isEqual:self.memberSplitView]) {
		NSView *leftSide = splitView.subviews[0];
        
		if ([leftSide isEqual:subview]) {
			return NO;
		}
	} else if ([splitView isEqual:self.serverSplitView]) {
		NSView *rightSide = splitView.subviews[1];
		
		if ([rightSide isEqual:subview] || NSObjectIsEmpty(self.worldController.clients)) {
			return NO;		
		} 
	}
	
	return YES;
}

#pragma mark -
#pragma mark Preferences

- (void)loadWindowState:(BOOL)honorFullscreen
{
	NSDictionary *dic = [TPCPreferences loadWindowStateWithName:@"Window -> Main Window"];
	
	if (dic) {
		NSInteger x = [dic integerForKey:@"x"];
		NSInteger y = [dic integerForKey:@"y"];
		NSInteger w = [dic integerForKey:@"w"];
		NSInteger h = [dic integerForKey:@"h"];

		BOOL fullscreen = [dic boolForKey:@"fullscreen"];
		
		[self.mainWindow setFrame:NSMakeRect(x, y, w, h) display:YES animate:self.isInFullScreenMode];
		
		[self.inputTextField setGrammarCheckingEnabled:[RZUserDefaults() boolForKey:@"TextFieldAutomaticGrammarCheck"]];
		[self.inputTextField setContinuousSpellCheckingEnabled:[RZUserDefaults() boolForKey:@"TextFieldAutomaticSpellCheck"]];
		[self.inputTextField setAutomaticSpellingCorrectionEnabled:[RZUserDefaults() boolForKey:@"TextFieldAutomaticSpellCorrection"]];
		
		self.serverSplitView.dividerPosition = [dic integerForKey:@"serverList"];
		self.memberSplitView.dividerPosition = [dic integerForKey:@"memberList"];
		
		if (self.serverSplitView.dividerPosition < _minimumSplitViewWidth) {
			self.serverSplitView.dividerPosition = _defaultSplitViewWidth;
		}
		
		if (self.memberSplitView.dividerPosition < _minimumSplitViewWidth) {
			self.memberSplitView.dividerPosition = _defaultSplitViewWidth;
		}

		if (fullscreen && honorFullscreen) {
			[self.menuController performSelector:@selector(toggleFullscreenMode:) withObject:nil afterDelay:2.0];
		}
	} else {
		NSRect rect = [RZMainScreen() visibleFrame];
		
		NSPoint p = NSMakePoint((rect.origin.x + (rect.size.width / 2)), 
								(rect.origin.y + (rect.size.height / 2)));
		
		NSInteger w = 800;
		NSInteger h = 474;
		
		rect = NSMakeRect((p.x - (w / 2)), (p.y - (h / 2)), w, h);
		
		[self.mainWindow setFrame:rect display:YES animate:self.isInFullScreenMode];

		self.serverSplitView.dividerPosition = 165;
		self.memberSplitView.dividerPosition = 120;
	}
	
	self.memberSplitViewOldPosition = self.memberSplitView.dividerPosition;
}

- (void)saveWindowState
{
	NSMutableDictionary *dic = [NSMutableDictionary dictionary];

	BOOL fullscreen = self.isInFullScreenMode;

	if (fullscreen) {
		[self.menuController toggleFullscreenMode:nil];
	}
	
	NSRect rect = self.mainWindow.frame;
	
	[dic setInteger:rect.origin.x forKey:@"x"];
	[dic setInteger:rect.origin.y forKey:@"y"];
	[dic setInteger:rect.size.width	forKey:@"w"];
	[dic setInteger:rect.size.height forKey:@"h"];
	
	if (self.serverSplitView.dividerPosition < _minimumSplitViewWidth) {
		self.serverSplitView.dividerPosition = _defaultSplitViewWidth;
	}
	
	if (self.memberSplitView.dividerPosition < _minimumSplitViewWidth) {
		if (self.memberSplitViewOldPosition < _minimumSplitViewWidth) {
			self.memberSplitView.dividerPosition = _defaultSplitViewWidth;
		} else {
			self.memberSplitView.dividerPosition = self.memberSplitViewOldPosition;
		}
	}
	
	[dic setInteger:self.serverSplitView.dividerPosition forKey:@"serverList"];
	[dic setInteger:self.memberSplitView.dividerPosition forKey:@"memberList"];

	[dic setBool:fullscreen forKey:@"fullscreen"];
	
	[RZUserDefaults() setBool:[self.inputTextField isGrammarCheckingEnabled] forKey:@"TextFieldAutomaticGrammarCheck"];
	[RZUserDefaults() setBool:[self.inputTextField isContinuousSpellCheckingEnabled] forKey:@"TextFieldAutomaticSpellCheck"];
	[RZUserDefaults() setBool:[self.inputTextField isAutomaticSpellingCorrectionEnabled] forKey:@"TextFieldAutomaticSpellCorrection"];

	if (self.terminating) {
		[TPCPreferences stopUsingTranscriptFolderSecurityScopedBookmark];
	}

	[TPCPreferences saveWindowState:dic name:@"Window -> Main Window"];
	[TPCPreferences sync];
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
	/* ************************************************************** */
	/* Start: Channel Movement Actions.								  */
	/* Design: The channel movement actions are designed to be local
	 to each server. Moving up or down a channel will keep it within
	 the list of channels associated with the selected server. All 
	 other channels are ignored.									  */
	/* ************************************************************** */
	
	if (dir == TXMoveUpKind || dir == TXMoveDownKind)
	{
		IRCTreeItem *selected = self.worldController.selectedItem;

		NSArray *scannedRows = [self.serverList rowsFromParentGroup:selected];

		PointerIsEmptyAssert(selected);

		NSInteger n = -1;

		if ([selected isClient] == NO) {
			n = [scannedRows indexOfObject:selected];
		}

		NSInteger start = n;
		NSInteger count = scannedRows.count;

		NSAssertReturn(count > 1);

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
		IRCTreeItem *selected = self.worldController.selectedItem;

		NSArray *scannedRows = [self.serverList groupItems];

		PointerIsEmptyAssert(selected);

		NSInteger n = -1;

		if ([selected isClient]) {
			n = [scannedRows indexOfObject:selected];
		}

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
	/* Design: Move to next item regardless of its type.			  */
	/* ************************************************************** */
	
	/* ************************************************************** */
	/* End: All Movement Actions.									  */
	/* ************************************************************** */

	if (dir == TXMoveAllKind && target == TXMoveDownKind)
	{
		IRCTreeItem *selected = self.worldController.selectedItem;

		PointerIsEmptyAssert(selected);

		NSInteger count = self.serverList.numberOfRows;

		NSAssertReturn(count > 1);
		
		NSInteger n = [self.serverList rowForItem:selected];

		n += 1;

		if (n >= count || n < 0) {
			n = 0;
		}

		id i = [self.serverList itemAtRow:n];

		[self.worldController select:i];
		
		return;
	}
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

- (void)selectNextSelection:(NSEvent *)e
{
	[self move:TXMoveAllKind target:TXMoveDownKind];
}

- (void)tab:(NSEvent *)e
{
	TXTabKeyAction tabKeyAction = [TPCPreferences tabKeyAction];

	if (tabKeyAction == TXTabKeyNickCompleteAction) {
		[self completeNick:YES];
	} else if (tabKeyAction == TXTabKeyUnreadChannelAction) {
		[self move:TXMoveDownKind target:TXMoveUnreadKind];
	}
}

- (void)shiftTab:(NSEvent *)e
{
	TXTabKeyAction tabKeyAction = [TPCPreferences tabKeyAction];

	if (tabKeyAction == TXTabKeyNickCompleteAction) {
		[self completeNick:NO];
	} else if (tabKeyAction == TXTabKeyUnreadChannelAction) {
		[self move:TXMoveUpKind target:TXMoveUnreadKind];
	}
}

- (void)sendMsgAction:(NSEvent *)e
{
	[self sendText:IRCPrivateCommandIndex("action")];
}

- (void)moveInputHistory:(BOOL)up checkScroller:(BOOL)scroll event:(NSEvent *)event
{
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
		s = [self.inputHistory up:[self.inputTextField attributedStringValue]];
	} else {
		s = [self.inputHistory down:[self.inputTextField attributedStringValue]];
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
	if ([self.formattingMenu boldSet]) {
		[self.formattingMenu removeBoldCharFromTextBox:nil];
	} else {
		[self.formattingMenu insertBoldCharIntoTextBox:nil];
	}
}

- (void)textFormattingItalic:(NSEvent *)e
{
	if ([self.formattingMenu italicSet]) {
		[self.formattingMenu removeItalicCharFromTextBox:nil];
	} else {
		[self.formattingMenu insertItalicCharIntoTextBox:nil];
	}
}

- (void)textFormattingUnderline:(NSEvent *)e
{
	if ([self.formattingMenu underlineSet]) {
		[self.formattingMenu removeUnderlineCharFromTextBox:nil];
	} else {
		[self.formattingMenu insertUnderlineCharIntoTextBox:nil];
	}
}

- (void)textFormattingForegroundColor:(NSEvent *)e
{
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
    if (self.isInFullScreenMode && [self.inputTextField isFocused] == NO) {
        [self.menuController toggleFullscreenMode:nil];
    } else {
        [self.inputTextField keyDown:e];
    }
}

- (void)focusWebview
{
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
	
	[self handler:@selector(textFormattingBold:)			char:'b' mods:NSCommandKeyMask];
	[self handler:@selector(textFormattingUnderline:)		char:'u' mods:(NSCommandKeyMask | NSAlternateKeyMask)];
	[self handler:@selector(textFormattingItalic:)			char:'i' mods:(NSCommandKeyMask | NSAlternateKeyMask)];
    [self handler:@selector(textFormattingForegroundColor:) char:'c' mods:(NSCommandKeyMask | NSAlternateKeyMask)];
	[self handler:@selector(textFormattingBackgroundColor:) char:'h' mods:(NSCommandKeyMask | NSAlternateKeyMask)];
	
	[self handler:@selector(inputHistoryUp:) char:'p' mods:NSControlKeyMask];
	[self handler:@selector(inputHistoryDown:) char:'n' mods:NSControlKeyMask];

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
	dic[@"characterEncodingDefault"]	= @(NSUTF8StringEncoding);

	/* Migration Assistant Dictionary Addition. */
	[dic safeSetObject:TPCPreferencesMigrationAssistantUpgradePath
				forKey:TPCPreferencesMigrationAssistantVersionKey];
	
	IRCClient *u = [self.worldController createClient:dic reload:YES];
	
	[self.worldController save];
	
	if (u.config.autoConnect) {
		[u connect];
	}
	
	[self.mainWindow makeKeyAndOrderFront:nil];
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

@end
