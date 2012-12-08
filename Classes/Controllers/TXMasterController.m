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

#define KInternetEventClass		1196773964
#define KAEGetURL				1196773964

#define _maximumSplitViewWidth		300
#define _minimumSplitViewWidth		120
#define _defaultSplitViewWidth		170

@implementation TXMasterController

#pragma mark -
#pragma mark NSApplication Delegate

- (void)awakeFromNib
{
	DebugLogToConsole(@"Temporary Folder: %@", [TPCPreferences applicationTemporaryFolderPath]);
	
#ifdef TXMacOSLionOrNewer
	[self.window setCollectionBehavior:NSWindowCollectionBehaviorFullScreenPrimary];
#endif
	
	if ([NSEvent modifierFlags] & NSShiftKeyMask) {
		self.ghostMode = YES;
	}
	
#if defined(DEBUG)
    self.ghostMode = YES; // Do not use autoconnect during debug
#endif
	
	[self.window makeMainWindow];
	
	[TPCPreferences setMasterController:self];
	[TPCPreferences initPreferences];

	[self.text setBackgroundColor:[NSColor clearColor]];
	
	[_NSNotificationCenter() addObserver:self selector:@selector(themeStyleDidChange:) name:TXThemePreferenceChangedNotification object:nil];
	[_NSNotificationCenter() addObserver:self selector:@selector(transparencyDidChange:) name:TXTransparencyPreferenceChangedNotification object:nil];
	[_NSNotificationCenter() addObserver:self selector:@selector(inputHistorySchemeChanged:) name:TXInputHistorySchemePreferenceChangedNotification object:nil];
	
	[_NSWorkspaceNotificationCenter() addObserver:self selector:@selector(computerDidWakeUp:) name:NSWorkspaceDidWakeNotification object:nil];
	[_NSWorkspaceNotificationCenter() addObserver:self selector:@selector(computerWillSleep:) name:NSWorkspaceWillSleepNotification object:nil];
	[_NSWorkspaceNotificationCenter() addObserver:self selector:@selector(computerWillPowerOff:) name:NSWorkspaceWillPowerOffNotification object:nil];
	
	[_NSAppleEventManager() setEventHandler:self andSelector:@selector(handleURLEvent:withReplyEvent:) forEventClass:KInternetEventClass andEventID:KAEGetURL];
	
    [self.text setFieldEditor:YES];
    
	self.serverSplitView.fixedViewIndex = 0;
	self.memberSplitView.fixedViewIndex = 1;
	
	self.viewTheme		= [TPCViewTheme new];
	self.viewTheme.name = [TPCPreferences themeName];
	
	[self loadWindowState:YES];
	
	[self.window setAlphaValue:[TPCPreferences themeTransparency]];
	
    [self.text setReturnActionWithSelector:@selector(textEntered) owner:self];
	[self.text redrawOriginPoints];
    
	[TLOLanguagePreferences setThemeForLocalization:self.viewTheme.path];
	
	IRCWorldConfig *seed = [[IRCWorldConfig alloc] initWithDictionary:[TPCPreferences loadWorld]];
	
	self.extrac = [IRCExtras new];
	self.world  = [IRCWorld new];
	
	self.world.window			= self.window;
	self.world.growl			= self.growl;
	self.world.master			= self;
	self.world.extrac			= self.extrac;
	self.world.text				= self.text;
	self.world.logBase			= self.logBase;
	self.world.memberList		= self.memberList;
	self.world.treeMenu			= self.treeMenu;
	self.world.logMenu			= self.logMenu;
	self.world.urlMenu			= self.urlMenu;
	self.world.chanMenu			= self.chanMenu;
	self.world.memberMenu		= self.memberMenu;
	self.world.viewTheme		= self.viewTheme;
	self.world.menuController	= self.menu;
	self.world.serverList		= self.serverList;
	
	[self.world setServerMenuItem:self.serverMenu];
	[self.world setChannelMenuItem:self.channelMenu];
	
	[self.world setup:seed];
	
	self.extrac.world = self.world;
	
	self.serverSplitView.delegate = self;
	self.memberSplitView.delegate = self;
	
	self.serverList.dataSource		= self.world;
	self.serverList.delegate		= self.world;
    self.memberList.keyDelegate		= self.world;
	self.serverList.keyDelegate		= self.world;
	[self.serverList reloadData];
	
	[self.world setupTree];
	
	self.menu.world			= self.world;
	self.menu.window		= self.window;
	self.menu.serverList	= self.serverList;
	self.menu.memberList	= self.memberList;
	self.menu.text			= self.text;
	self.menu.master		= self;
	
	[self.memberList setTarget:self.menu];    
	[self.memberList setDoubleAction:@selector(memberListDoubleClicked:)];
	
	[self.serverList updateBackgroundColor];
	[self.memberList updateBackgroundColor];
	
	self.growl = [TLOGrowlController new];
	self.growl.owner = self.world;
	self.world.growl = self.growl;
	
	[self.formattingMenu enableWindowField:self.text];
	
	if ([TPCPreferences inputHistoryIsChannelSpecific] == NO) {
		self.inputHistory = [TLOInputHistory new];
	}
	
	[self registerKeyHandlers];
	
	[self.viewTheme validateFilePathExistanceAndReload:YES];
	
	[NSBundle.invokeInBackgroundThread loadBundlesIntoMemory:self.world];
	
	[self buildSegmentedController];
}

- (void)applicationDidFinishLaunching:(NSNotification *)note
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
	
	[self.window makeKeyAndOrderFront:nil];

	[self.world focusInputText];

	// ---- //
	
	if (self.world.clients.count < 1) {
		self.welcomeSheet = [TDCWelcomeSheet new];
		self.welcomeSheet.delegate = self;
		self.welcomeSheet.window = self.window;
		[self.welcomeSheet show];
	} else {
		[self.world autoConnectAfterWakeup:NO];	
	}
}

- (void)applicationDidChangeScreenParameters:(NSNotification *)aNotification
{
	if (self.menu.isInFullScreenMode) {
		/* Reset window frame if screen resolution is changed. */
		
		[self.window setFrame:[_NSMainScreen() frame] display:YES animate:YES];
	} else {
		NSRect visibleRect = [_NSMainScreen() visibleFrame];
		NSRect windowRect  = self.window.frame;
		
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
			[self.window setFrame:windowRect display:YES animate:YES];
		}
	}

	/* Redraw dock icon on potential screen resolution changes. */

	[self.world updateIcon];
}

- (void)applicationDidBecomeActive:(NSNotification *)note
{
	id sel = self.world.selected;
    
	if (sel) {
		[sel resetState];
		
		[self.world updateIcon];
	}
	
    [self.world reloadTree];
	
	[_text.backgroundView setWindowIsActive:YES];
}

- (void)applicationDidResignActive:(NSNotification *)note
{
	id sel = self.world.selected;
    
	if (sel) {
		[sel resetState];
		
		[self.world updateIcon];
	}
    
    [self.world reloadTree];
	
	[_text.backgroundView setWindowIsActive:NO];
}

- (BOOL)applicationShouldHandleReopen:(NSApplication *)sender hasVisibleWindows:(BOOL)flag
{
	[self.window makeKeyAndOrderFront:nil];
	
	return YES;
}

- (void)applicationDidReceiveHotKey:(id)sender
{
	if ([self.window isVisible] == NO || [NSApp isActive] == NO) {
		if (NSObjectIsEmpty(self.world.clients)) {
			[NSApp activateIgnoringOtherApps:YES];
			
			[self.window makeKeyAndOrderFront:nil];
			
			[self.text focus];
		}
	} else {
		[NSApp hide:nil];
	}
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
		
		if (result == NO) {
			return NO;
		}
	}
	
	return YES;
}

- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender
{
	if ([self queryTerminate]) {
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
		[self.world save];
		[self.world terminate];
		[self.menu terminate];
		
		[self saveWindowState];
	}
	
	[TPCPreferences updateTotalRunTime];
}

#pragma mark -
#pragma mark NSWorkspace Notifications

- (void)handleURLEvent:(NSAppleEventDescriptor *)event
		withReplyEvent:(NSAppleEventDescriptor *)replyEvent
{
	NSString *url = [[event descriptorAtIndex:1] stringValue];
	
    [self.extrac parseIRCProtocolURI:url];
}

- (void)computerWillSleep:(NSNotification *)note
{
	[self.world prepareForSleep];
}

- (void)computerDidWakeUp:(NSNotification *)note
{
	[self.world autoConnectAfterWakeup:YES];
}

- (void)computerWillPowerOff:(NSNotification *)note
{
	self.terminating = YES;
	
	[NSApp terminate:nil];
}

- (BOOL)applicationShouldOpenUntitledFile:(NSApplication *)sender
{
	[self.window makeKeyAndOrderFront:nil];
	
	return YES;
}

#pragma mark -
#pragma mark NSWindow Delegate

- (void)windowDidResize:(NSNotification *)notification
{
	[self.text resetTextFieldCellSize:YES];
}

- (void)windowDidBecomeKey:(NSNotification *)notification
{
	id sel = self.world.selected;
	
	if (sel) {
		[sel resetState];
		
		[self.world updateIcon];
	}
	
    [self.world reloadTree];
}

- (void)windowWillEnterFullScreen:(NSNotification *)notification
{
	[self saveWindowState];
}

- (void)windowDidEnterFullScreen:(NSNotification *)notification
{
	self.menu.isInFullScreenMode = YES;
}

- (void)windowDidExitFullScreen:(NSNotification *)notification
{
	[self loadWindowState:NO];
	
	self.menu.isInFullScreenMode = NO;
}

- (NSSize)windowWillResize:(NSWindow *)awindow toSize:(NSSize)newSize
{
	if (NSDissimilarObjects(awindow, self.window)) {
		return newSize; 
	} else {
		if (self.menu.isInFullScreenMode) {
			return [awindow frame].size;
		} else {
			return newSize;
		}
	}
}

- (BOOL)windowShouldZoom:(NSWindow *)awindow toFrame:(NSRect)newFrame
{
	if (NSDissimilarObjects(self.window, awindow)) {
		return YES;
	} else {
		return BOOLReverseValue(self.menu.isInFullScreenMode);
	}
}

- (id)windowWillReturnFieldEditor:(NSWindow *)sender toObject:(id)client
{
    NSMenu	   *editorMenu = self.text.menu;
    NSMenuItem *formatMenu = self.formattingMenu.formatterMenu;
    
    if (formatMenu) {
        NSInteger fmtrIndex = [editorMenu indexOfItemWithTitle:[formatMenu title]];
        
        if (fmtrIndex == -1) {
            [editorMenu addItem:[NSMenuItem separatorItem]];
            [editorMenu addItem:formatMenu];
        }
        
        [self.text setMenu:editorMenu];
    }
    
    return self.text;
}

#pragma mark -
#pragma mark Utilities

- (void)sendText:(NSString *)command
{
	NSAttributedString *as = [self.text attributedStringValue];
	
	[self.text setAttributedStringValue:[NSAttributedString emptyString]];
	
	if ([TPCPreferences inputHistoryIsChannelSpecific]) {
		self.world.selected.inputHistory.lastHistoryItem = nil;
	}
	
	if (NSObjectIsNotEmpty(as)) {
		if ([self.world inputText:as command:command]) {
			[self.inputHistory add:as];
		}
	}
	
	if (self.completionStatus) {
		[self.completionStatus clear];
	}
}

- (void)textEntered
{
	[self sendText:IRCPrivateCommandIndex("privmsg")];
}

- (void)showMemberListSplitView:(BOOL)showList
{
	self.memberSplitViewOldPosition = self.memberSplitView.position;
	
	if (showList) {
		NSView *rightView = [[self.memberSplitView subviews] safeObjectAtIndex:1];
		
		self.memberSplitView.hidden	 = NO;
		self.memberSplitView.inverted = NO;
		
		if ([self.memberSplitView isSubviewCollapsed:rightView] == NO) {
			if (self.memberSplitViewOldPosition < _minimumSplitViewWidth) {
				self.memberSplitViewOldPosition = _minimumSplitViewWidth;
			}
			
			self.memberSplitView.position = self.memberSplitViewOldPosition;
		}
	} else {
		if (self.memberSplitView.hidden == NO) {
			self.memberSplitView.hidden   = YES;
			self.memberSplitView.inverted = YES;
		}
	}
}

#pragma mark -
#pragma mark Preferences

- (CGFloat)splitView:(NSSplitView *)splitView
constrainMaxCoordinate:(CGFloat)proposedMax
		 ofSubviewAt:(NSInteger)dividerIndex
{
	if ([splitView isEqual:self.memberSplitView]) {
		NSView *leftSide  = [splitView subviews][0];
		NSView *rightSide = [splitView subviews][1];
		
		NSInteger leftWidth  = [leftSide bounds].size.width;
		NSInteger rightWidth = [rightSide bounds].size.width;
		
		return ((leftWidth + rightWidth) - _minimumSplitViewWidth);
	}
	
	return _maximumSplitViewWidth;
}

- (CGFloat)splitView:(NSSplitView *)splitView
constrainMinCoordinate:(CGFloat)proposedMax
		 ofSubviewAt:(NSInteger)dividerIndex
{
	if ([splitView isEqual:self.memberSplitView]) {
		NSView *leftSide  = [splitView subviews][0];
		NSView *rightSide = [splitView subviews][1];
		
		NSInteger leftWidth  = [leftSide bounds].size.width;
		NSInteger rightWidth = [rightSide bounds].size.width;
		
		return ((leftWidth + rightWidth) - _maximumSplitViewWidth);
	}
	
	return _minimumSplitViewWidth;
}

- (BOOL)splitView:(NSSplitView *)splitView canCollapseSubview:(NSView *)subview
{
	if ([splitView isEqual:self.memberSplitView]) {
		NSView *leftSide = [splitView subviews][0];
        
		if ([leftSide isEqual:subview]) {
			return NO;
		}
	} else if ([splitView isEqual:self.serverSplitView]) {
		NSView *rightSide = [splitView subviews][1];
		
		if ([rightSide isEqual:subview] || NSObjectIsEmpty(self.world.clients)) {
			return NO;		
		} 
	}
	
	return YES;
}

- (void)loadWindowState
{
	[self loadWindowState:NO];
}

- (void)loadWindowState:(BOOL)honorFullscreen
{
	NSDictionary *dic = [TPCPreferences loadWindowStateWithName:@"Window -> Main Window"];
	
	if (dic) {
		NSInteger x = [dic integerForKey:@"x"];
		NSInteger y = [dic integerForKey:@"y"];
		NSInteger w = [dic integerForKey:@"w"];
		NSInteger h = [dic integerForKey:@"h"];

		BOOL fullscreen = [dic boolForKey:@"fullscreen"];
		
		[self.window setFrame:NSMakeRect(x, y, w, h) display:YES animate:self.menu.isInFullScreenMode];
		
		[self.text setGrammarCheckingEnabled:[_NSUserDefaults() boolForKey:@"TextFieldAutomaticGrammarCheck"]];
		[self.text setContinuousSpellCheckingEnabled:[_NSUserDefaults() boolForKey:@"TextFieldAutomaticSpellCheck"]];
		[self.text setAutomaticSpellingCorrectionEnabled:[_NSUserDefaults() boolForKey:@"TextFieldAutomaticSpellCorrection"]];
		
		self.serverSplitView.position = [dic integerForKey:@"serverList"];
		self.memberSplitView.position = [dic integerForKey:@"memberList"];
		
		if (self.serverSplitView.position < _minimumSplitViewWidth) {
			self.serverSplitView.position = _defaultSplitViewWidth;
		}
		
		if (self.memberSplitView.position < _minimumSplitViewWidth) {
			self.memberSplitView.position = _defaultSplitViewWidth;
		}

		if (fullscreen && honorFullscreen) {
			[self.menu performSelector:@selector(toggleFullscreenMode:) withObject:nil afterDelay:2.0];
		}
	} else {
		NSScreen *screen = [NSScreen mainScreen];
		
		if (screen) {
			NSRect rect = [screen visibleFrame];
			
			NSPoint p = NSMakePoint((rect.origin.x + (rect.size.width / 2)), 
									(rect.origin.y + (rect.size.height / 2)));
			
			NSInteger w = 800;
			NSInteger h = 474;
			
			rect = NSMakeRect((p.x - (w / 2)), (p.y - (h / 2)), w, h);
			
			[self.window setFrame:rect display:YES animate:self.menu.isInFullScreenMode];
		}
		
		self.serverSplitView.position = 165;
		self.memberSplitView.position = 120;
	}
	
	self.memberSplitViewOldPosition = self.memberSplitView.position;
}

- (void)saveWindowState
{
	NSMutableDictionary *dic = [NSMutableDictionary dictionary];

	BOOL fullscreen = self.menu.isInFullScreenMode;

	if (fullscreen) {
		[self.menu toggleFullscreenMode:nil];
	}
	
	NSRect rect = self.window.frame;
	
	[dic setInteger:rect.origin.x		forKey:@"x"];
	[dic setInteger:rect.origin.y		forKey:@"y"];
	[dic setInteger:rect.size.width		forKey:@"w"];
	[dic setInteger:rect.size.height	forKey:@"h"];
	
	if (self.serverSplitView.position < _minimumSplitViewWidth) {
		self.serverSplitView.position = _defaultSplitViewWidth;
	}
	
	if (self.memberSplitView.position < _minimumSplitViewWidth) {
		if (self.memberSplitViewOldPosition < _minimumSplitViewWidth) {
			self.memberSplitView.position = _defaultSplitViewWidth;
		} else {
			self.memberSplitView.position = self.memberSplitViewOldPosition;
		}
	}
	
	[dic setInteger:self.serverSplitView.position forKey:@"serverList"];
	[dic setInteger:self.memberSplitView.position forKey:@"memberList"];

	[dic setBool:fullscreen forKey:@"fullscreen"];
	
	[_NSUserDefaults() setBool:[self.text isGrammarCheckingEnabled]				forKey:@"TextFieldAutomaticGrammarCheck"];
	[_NSUserDefaults() setBool:[self.text isContinuousSpellCheckingEnabled]		forKey:@"TextFieldAutomaticSpellCheck"];
	[_NSUserDefaults() setBool:[self.text isAutomaticSpellingCorrectionEnabled]	forKey:@"TextFieldAutomaticSpellCorrection"];
	
	[TPCPreferences stopUsingTranscriptFolderBookmarkResources];
	[TPCPreferences saveWindowState:dic name:@"Window -> Main Window"];
	[TPCPreferences sync];
}

- (void)themeStyleDidChange:(NSNotification *)note
{
	NSMutableString *sf = [NSMutableString string];
	
	[self.world reloadTheme];
	
	if (NSObjectIsNotEmpty(self.viewTheme.other.nicknameFormat)) {
		[sf appendString:TXTLS(@"ThemeChangeOverridePromptNicknameFormat")];
		[sf appendString:NSStringNewlinePlaceholder];
	}
	
	if (NSObjectIsNotEmpty(self.viewTheme.other.timestampFormat)) {
		[sf appendString:TXTLS(@"ThemeChangeOverridePromptTimestampFormat")];
		[sf appendString:NSStringNewlinePlaceholder];
	}
	
	if (self.viewTheme.other.channelViewFont) {
		[sf appendString:TXTLS(@"ThemeChangeOverridePromptChannelFont")];
		[sf appendString:NSStringNewlinePlaceholder];
	}
	
	if (self.viewTheme.other.forceInvertSidebarColors) {
		[sf appendString:TXTLS(@"ThemeChangeOverridePromptWindowColors")];
		[sf appendString:NSStringNewlinePlaceholder];
	}
	
	[self.text updateTextDirection];
	
	sf = (NSMutableString *)[sf trim];
	
	if (NSObjectIsNotEmpty(sf)) {		
		NSString *theme = [TPCViewTheme extractThemeName:[TPCPreferences themeName]];
		
		TLOPopupPrompts *prompt = [TLOPopupPrompts new];
		
		[prompt sheetWindowWithQuestion:[NSApp keyWindow]
								 target:[TLOPopupPrompts class]
								 action:@selector(popupPromptNilSelector:)
								   body:TXTFLS(@"ThemeChangeOverridePromptMessage", theme, sf)
								  title:TXTLS(@"ThemeChangeOverridePromptTitle")
						  defaultButton:TXTLS(@"OkButton")
						alternateButton:nil 
							otherButton:nil
						 suppressionKey:@"theme_override_info" 
						suppressionText:nil];
	}
}

- (void)transparencyDidChange:(NSNotification *)note
{
	[self.window setAlphaValue:[TPCPreferences themeTransparency]];
}

- (void)inputHistorySchemeChanged:(NSNotification *)note
{
	if (self.inputHistory) {
		self.inputHistory = nil;
	}
	
	for (IRCClient *c in self.world.clients) {
		if (c.inputHistory) {
			c.inputHistory = nil;
		}
		
		if ([TPCPreferences inputHistoryIsChannelSpecific]) {
			c.inputHistory = [TLOInputHistory new];
		}
		
		for (IRCChannel *u in c.channels) {
			if (u.inputHistory) {
				u.inputHistory = nil;
			}
			
			if ([TPCPreferences inputHistoryIsChannelSpecific]) {
				u.inputHistory = [TLOInputHistory new];
			}
		}
	}
	
	if ([TPCPreferences inputHistoryIsChannelSpecific] == NO) {
		self.inputHistory = [TLOInputHistory new];
	}
}

#pragma mark -
#pragma mark Nick Completion

- (void)completeNick:(BOOL)forward
{
	IRCClient *client = [self.world selectedClient];
	IRCChannel *channel = [self.world selectedChannel];
	
	if (PointerIsEmpty(client)) {
		return;
	}
	
	if ([self.text isFocused] == NO) {
		[self.world focusInputText];
	}
	
	NSText *fe = [self.window fieldEditor:YES forObject:self.text];
	if (PointerIsEmpty(fe)) return;
	
	NSRange selectedRange = [fe selectedRange];
	if (selectedRange.location == NSNotFound) return;
	
	if (PointerIsEmpty(self.completionStatus)) {
		self.completionStatus = [TLONickCompletionStatus new];
	}
	
	TLONickCompletionStatus *status = self.completionStatus;
    
	NSString *s = [self.text stringValue];
	
	if ([status.text isEqualToString:s]
		&& NSDissimilarObjects(status.range.location, NSNotFound)
		&& NSMaxRange(status.range) == selectedRange.location
		&& selectedRange.length == 0) {
		
		selectedRange = status.range;
	}
	
	BOOL head = YES;
	
	NSString *pre = [s safeSubstringToIndex:selectedRange.location];
	NSString *sel = [s safeSubstringWithRange:selectedRange];
	
	for (NSInteger i = (pre.length - 1); i >= 0; --i) {
		UniChar c = [pre characterAtIndex:i];
		
		if (c == ' ') {
			++i;
			
			if (i == pre.length) return;
			
			head = NO;
			pre = [pre safeSubstringFromIndex:i];
			
			break;
		}
	}
	
	if (NSObjectIsEmpty(pre)) return;
	
	BOOL channelMode = NO;
	BOOL commandMode = NO;
	
	UniChar c = [pre characterAtIndex:0];
	
	if (head && c == '/') {
		commandMode = YES;
		
		pre = [pre safeSubstringFromIndex:1];
		
		if (NSObjectIsEmpty(pre)) return;
	} else if (c == '@') {
		if (PointerIsEmpty(channel)) return;
		
		pre = [pre safeSubstringFromIndex:1];
		
		if (NSObjectIsEmpty(pre)) return;
	} else if (c == '#') {
		channelMode = YES;
		
		if (NSObjectIsEmpty(pre)) return;
	}
	
	NSString *current = [pre stringByAppendingString:sel];
	
	NSInteger len = current.length;
	
	for (NSInteger i = 0; i < len; ++i) {
		UniChar c = [current characterAtIndex:i];
		
		if (NSDissimilarObjects(c, ' ') && NSDissimilarObjects(c, ':')) {
			;
		} else {
			current = [current safeSubstringToIndex:i];
			
			break;
		}
	}
	
	if (NSObjectIsEmpty(current)) return;
	
	NSString *lowerPre     = [pre lowercaseString];
	NSString *lowerCurrent = [current lowercaseString];
	
	NSArray		   *lowerChoices;
	NSMutableArray *choices;
	
	if (commandMode) {
		choices = [NSMutableArray array];
        
		for (NSString *command in [TPCPreferences publicIRCCommandList]) {
			[choices safeAddObject:[command lowercaseString]];
		}
		
		for (NSString *command in [self.world bundlesForUserInput].allKeys) {
			NSString *cmdl = [command lowercaseString];
			
			if ([choices containsObject:cmdl] == NO) {
				[choices safeAddObject:cmdl];
			}
		}
		
#ifdef TXUserScriptsFolderAvailable
		NSArray *scriptPaths = @[
		NSStringNilValueSubstitute([TPCPreferences bundledScriptFolderPath]),
		NSStringNilValueSubstitute([TPCPreferences customScriptFolderPath]),
		NSStringNilValueSubstitute([TPCPreferences systemUnsupervisedScriptFolderPath])
		];
#else
		NSArray *scriptPaths = @[
		NSStringNilValueSubstitute([TPCPreferences whereScriptsLocalPath]),
		NSStringNilValueSubstitute([TPCPreferences whereScriptsPath])
		];
#endif
		
		for (NSString *path in scriptPaths) {
			if (NSObjectIsNotEmpty(path)) {
				NSArray *resourceFiles = [_NSFileManager() contentsOfDirectoryAtPath:path error:NULL];
				
				if (NSObjectIsNotEmpty(resourceFiles)) {
					for (NSString *file in resourceFiles) {
						if ([file hasPrefix:@"."] || [file hasSuffix:@".rtf"]) {
							continue;
						}
						
						NSArray  *parts = [NSArray arrayWithArray:[file componentsSeparatedByString:@"."]];
						NSString *cmdl  = [[parts stringAtIndex:0] lowercaseString];
						
						if ([choices containsObject:cmdl] == NO) {
							[choices safeAddObject:cmdl];
						}
					}
				}
			}
		}
        
		lowerChoices = choices;
	} else if (channelMode) {
		NSMutableArray *channels      = [NSMutableArray array];
		NSMutableArray *lowerChannels = [NSMutableArray array];
		
		IRCClient *u = [self.world selectedClient];
		
		for (IRCChannel *c in u.channels) {
			[channels      safeAddObject:c.name];
			[lowerChannels safeAddObject:[c.name lowercaseString]];
		}
		
		choices      = channels;
		lowerChoices = lowerChannels;
	} else {
		NSMutableArray *users = [channel.members mutableCopy];
		[users sortUsingSelector:@selector(compareUsingWeights:)];
		
		NSMutableArray *nicks      = [NSMutableArray array];
		NSMutableArray *lowerNicks = [NSMutableArray array];
		
		for (IRCUser *m in users) {
			[nicks      safeAddObject:m.nick];
			[lowerNicks safeAddObject:[m.nick lowercaseString]];
		}
		
		[nicks      safeAddObject:@"NickServ"];
		[nicks      safeAddObject:@"RootServ"];
		[nicks      safeAddObject:@"OperServ"];
		[nicks      safeAddObject:@"HostServ"];
		[nicks      safeAddObject:@"ChanServ"];
		[nicks      safeAddObject:@"MemoServ"];
		[nicks      safeAddObject:[TPCPreferences applicationName]];
		
		[lowerNicks safeAddObject:@"nickserv"];
		[lowerNicks safeAddObject:@"rootserv"];
		[lowerNicks safeAddObject:@"operserv"];
		[lowerNicks safeAddObject:@"hostserv"];
		[lowerNicks safeAddObject:@"chanserv"];
		[lowerNicks safeAddObject:[TPCPreferences applicationName]];
		
		choices      = nicks;
		lowerChoices = lowerNicks;
	}
	
	NSMutableArray *currentChoices      = [NSMutableArray array];
	NSMutableArray *currentLowerChoices = [NSMutableArray array];
	
	NSInteger i = 0;
	
	for (NSString *s in lowerChoices) {
		if ([s hasPrefix:lowerPre]) {
			[currentLowerChoices safeAddObject:s];
			[currentChoices      safeAddObject:[choices safeObjectAtIndex:i]];
		}
		
		++i;
	}
	
	if (currentChoices.count < 1) return;
	
	NSString *t = nil;
	
	NSUInteger index = [currentLowerChoices indexOfObject:lowerCurrent];
	
	if (index == NSNotFound) {
		t = [currentChoices safeObjectAtIndex:0];
	} else {
		if (forward) {
			++index;
			
			if (currentChoices.count <= index) {
				index = 0;
			}
		} else {
			if (index == 0) {
				index = (currentChoices.count - 1);
			} else {
				--index;
			}
		}
		
		t = [currentChoices safeObjectAtIndex:index];
	}
	
	[_NSSpellChecker() ignoreWord:t inSpellDocumentWithTag:self.text.spellCheckerDocumentTag];
	
	if ((commandMode || channelMode) || head == NO) {
		t = [t stringByAppendingString:NSStringWhitespacePlaceholder];
	} else {
		if (NSObjectIsNotEmpty([TPCPreferences completionSuffix])) {
			t = [t stringByAppendingString:[TPCPreferences completionSuffix]];
		}
	}
	
	NSRange r = selectedRange;
	
	r.location -= pre.length;
	r.length += pre.length;
	
	[fe replaceCharactersInRange:r withString:t];
	[fe scrollRangeToVisible:fe.selectedRange];
	
	r.location += t.length;
	r.length = 0;
	
	fe.selectedRange = r;
	
	if (currentChoices.count == 1) {
		[status clear];
	} else {
		selectedRange.length = (t.length - pre.length);
		
		status.text = [self.text stringValue];
		status.range = selectedRange;
	}
}

#pragma mark -
#pragma mark Keyboard Navigation

typedef enum TXMoveKind : NSInteger {
	TXMoveUpKind,
	TXMoveDownKind,
	TXMoveLeftKind,
	TXMoveRightKind,
	TXMoveAllKind,
	TXMoveActiveKind,
	TXMoveUnreadKind,
} TXMoveKind;

- (void)move:(TXMoveKind)dir target:(TXMoveKind)target
{
	if (dir == TXMoveUpKind || dir == TXMoveDownKind) {
		id sel = self.world.selected;
		if (PointerIsEmpty(sel)) return;
		
		NSInteger n = [self.serverList rowForItem:sel];
		if (n < 0) return;
		
		NSInteger start = n;
		NSInteger count = [self.serverList numberOfRows];
		
		if (count <= 1) return;
		
		while (1 == 1) {
			if (dir == TXMoveUpKind) {
				--n;
				
				if (n < 0) n = (count - 1);
			} else {
				++n;
				
				if (count <= n) n = 0;
			}
			
			if (n == start) break;
			
			id i = [self.serverList itemAtRow:n];
			
			if (i) {
				if (target == TXMoveActiveKind) {
					if ([i isClient] == NO && [i isActive]) {
						[self.world select:i];
						
						break;
					}
				} else if (target == TXMoveUnreadKind) {
					if ([i isUnread]) {
						[self.world select:i];
						
						break;
					}
				} else {
					[self.world select:i];
					
					break;
				}
			}
		}
	} else if (dir == TXMoveLeftKind || dir == TXMoveRightKind) {
		IRCClient *client = [self.world selectedClient];
		if (PointerIsEmpty(client)) return;
		
		NSUInteger pos = [self.world.clients indexOfObjectIdenticalTo:client];
		if (pos == NSNotFound) return;
		
		NSInteger n = pos;
		NSInteger start = n;
		
		NSInteger count = self.world.clients.count;
		if (count <= 1) return;
		
		while (1 == 1) {
			if (dir == TXMoveLeftKind) {
				--n;
				
				if (n < 0) n = (count - 1);
			} else {
				++n;
				
				if (count <= n) n = 0;
			}
			
			if (n == start) break;
			
			client = [self.world.clients safeObjectAtIndex:n];
			
			if (client) {
				if (target == TXMoveActiveKind) {
					if (client.isLoggedIn) {
						id t = ((client.lastSelectedChannel) ?: (id)client);
						
						[self.world select:t];
						
						break;
					}
				} else {
					id t = ((client.lastSelectedChannel) ?: (id)client);
					
					[self.world select:t];
					
					break;
				}
			}
		}
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
	[self.world selectPreviousItem];
}

- (void)selectNextSelection:(NSEvent *)e
{
	[self move:TXMoveDownKind target:TXMoveAllKind];
}

- (void)tab:(NSEvent *)e
{
	switch ([TPCPreferences tabAction]) {
		case TXTabKeyActionNickCompleteType: [self completeNick:YES];					break;
		case TXTabKeyActionUnreadChannelType:		[self move:TXMoveDownKind target:TXMoveUnreadKind];	break;
		default: break;
	}
}

- (void)shiftTab:(NSEvent *)e
{
	switch ([TPCPreferences tabAction]) {
		case TXTabKeyActionNickCompleteType: [self completeNick:NO];					break;
		case TXTabKeyActionUnreadChannelType:		[self move:TXMoveUpKind target:TXMoveUnreadKind]; break;
		default: break;
	}
}

- (void)sendMsgAction:(NSEvent *)e
{
	[self sendText:IRCPrivateCommandIndex("action")];
}

- (void)_moveInputHistory:(BOOL)up checkScroller:(BOOL)scroll event:(NSEvent *)event
{
	if (scroll) {
		NSInteger nol = [self.text numberOfLines];
		
		if (nol >= 2) {
			BOOL atTop    = [self.text isAtTopOfView];
			BOOL atBottom = [self.text isAtBottomOfView];
			
			if ((atTop && event.keyCode == TXKeyDownArrowCode) ||
				(atBottom && event.keyCode == TXKeyUpArrowCode) ||
				(atTop == NO && atBottom == NO)) {
				
				[self.text keyDownToSuper:event];
				
				return;
			}
		}
	}
	
	NSAttributedString *s;
	
	if (up) {
		s = [self.inputHistory up:[self.text attributedStringValue]];
	} else {
		s = [self.inputHistory down:[self.text attributedStringValue]];
	}
	
	if (s) {
        [self.text setAttributedStringValue:s];
		
		[self.world focusInputText];
        
        if ([self.text respondsToSelector:@selector(resetTextFieldCellSize:)]) {
            [self.text resetTextFieldCellSize:NO];
        }
	}
}

- (void)inputHistoryUp:(NSEvent *)e
{
	[self _moveInputHistory:YES checkScroller:NO event:e];
}

- (void)inputHistoryDown:(NSEvent *)e
{
	[self _moveInputHistory:NO checkScroller:NO event:e];
}

- (void)inputHistoryUpWithScrollCheck:(NSEvent *)e
{
	[self _moveInputHistory:YES checkScroller:YES event:e];
}

- (void)inputHistoryDownWithScrollCheck:(NSEvent *)e
{
	[self _moveInputHistory:NO checkScroller:YES event:e];
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
		
		[self.formattingMenu.foregroundColorMenu popUpMenuPositioningItem:nil
															   atLocation:fieldRect.origin
																   inView:self.formattingMenu.textField];
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
			
			[self.formattingMenu.backgroundColorMenu popUpMenuPositioningItem:nil
																   atLocation:fieldRect.origin
																	   inView:self.formattingMenu.textField];
		}
	}
}

- (void)exitFullscreenMode:(NSEvent *)e
{
    if (self.menu.isInFullScreenMode && [self.text isFocused] == NO) {
        [self.menu toggleFullscreenMode:nil];
    } else {
        [self.text keyDown:e];
    }
}

- (void)focusWebview
{
    [self.window makeFirstResponder:self.world.selected.log.view];
}

- (void)handler:(SEL)sel code:(NSInteger)keyCode mods:(NSUInteger)mods
{
	[self.window registerKeyHandler:sel key:keyCode modifiers:mods];
}

- (void)inputHandler:(SEL)sel code:(NSInteger)keyCode mods:(NSUInteger)mods
{
	[self.text registerKeyHandler:sel key:keyCode modifiers:mods];
}

- (void)inputHandler:(SEL)sel char:(UniChar)c mods:(NSUInteger)mods
{
	[self.text registerKeyHandler:sel character:c modifiers:mods];
}

- (void)handler:(SEL)sel char:(UniChar)c mods:(NSUInteger)mods
{
	[self.window registerKeyHandler:sel character:c modifiers:mods];
}

- (void)registerKeyHandlers
{
	[self.window	setKeyHandlerTarget:self];
	[self.text      setKeyHandlerTarget:self];
    
    [self handler:@selector(exitFullscreenMode:) code:TXKeyEscapeCode mods:0];
	
	[self handler:@selector(tab:)		code:TXKeyTabCode mods:0];
	[self handler:@selector(shiftTab:)	code:TXKeyTabCode mods:NSShiftKeyMask];
	
	[self handler:@selector(sendMsgAction:) code:TXKeyEnterCode	mods:NSCommandKeyMask];
	[self handler:@selector(sendMsgAction:) code:TXKeyEnterCode mods:NSCommandKeyMask];
	
	[self handler:@selector(selectPreviousSelection:) code:TXKeyTabCode mods:NSAlternateKeyMask];
	
	[self handler:@selector(textFormattingBold:)			char:'b' mods:NSCommandKeyMask];
	[self handler:@selector(textFormattingUnderline:)		char:'u' mods:(NSCommandKeyMask | NSAlternateKeyMask)];
	[self handler:@selector(textFormattingItalic:)			char:'i' mods:(NSCommandKeyMask | NSAlternateKeyMask)];
    [self handler:@selector(textFormattingForegroundColor:) char:'c' mods:(NSCommandKeyMask | NSAlternateKeyMask)];
	[self handler:@selector(textFormattingBackgroundColor:) char:'h' mods:(NSCommandKeyMask | NSAlternateKeyMask)];
	
	[self handler:@selector(inputHistoryUp:)	char:'p' mods:NSControlKeyMask];
	[self handler:@selector(inputHistoryDown:)	char:'n' mods:NSControlKeyMask];
    
    [self inputHandler:@selector(focusWebview) char:'l' mods:(NSControlKeyMask | NSCommandKeyMask)];
    
	[self inputHandler:@selector(inputHistoryUpWithScrollCheck:) code:TXKeyUpArrowCode mods:0];
	[self inputHandler:@selector(inputHistoryUpWithScrollCheck:) code:TXKeyUpArrowCode mods:NSAlternateKeyMask];
	
	[self inputHandler:@selector(inputHistoryDownWithScrollCheck:) code:TXKeyDownArrowCode mods:0];
	[self inputHandler:@selector(inputHistoryDownWithScrollCheck:) code:TXKeyDownArrowCode mods:NSAlternateKeyMask];
}

#pragma mark -
#pragma mark WindowSegmentedController Delegate

- (void)updateSegmentedController
{
	if ([TPCPreferences hideMainWindowSegmentedController] == NO) {
		[self.windowButtonController setEnabled:(self.world.clients.count >= 1)];
		
		/* Selection Settings. */
		IRCClient *u = self.world.selectedClient;
		IRCChannel *c = self.world.selectedChannel;
		
		if (PointerIsEmpty(c)) {
			[self.windowButtonController setMenu:self.serverMenu.submenu forSegment:1];
		} else {
			[self.windowButtonController setMenu:self.channelMenu.submenu forSegment:1];
		}
		
		/* Open Address Book. */
		[self.windowButtonController setEnabled:(PointerIsNotEmpty(u) && u.isConnected) forSegment:2];
	}
}

- (void)buildSegmentedController
{
	self.windowButtonControllerCell.menuController = self.menu;
	
	[self.windowButtonController setEnabled:(self.world.clients.count >= 1)];
	
	/* Add Server/Channel Segment. */
	NSMenu *segAddButton = [NSMenu new];
	
	NSMenuItem *addServer  = [self.treeMenu itemAtIndex:0].copy;
	NSMenuItem *addChannel = [self.channelMenu.submenu itemWithTag:651].copy;
	
	[segAddButton addItem:addServer];
	[segAddButton addItem:[NSMenuItem separatorItem]];
	[segAddButton addItem:addChannel];
	
	[self.windowButtonController setMenu:segAddButton.copy forSegment:0];
	
	[self updateSegmentedController];
}

#pragma mark -
#pragma mark WelcomeSheet Delegate

- (void)welcomeSheet:(TDCWelcomeSheet *)sender onOK:(NSDictionary *)config
{
	NSMutableArray *channels = [NSMutableArray array];
	
	NSMutableDictionary *dic = [NSMutableDictionary dictionary];
	
	for (NSString *s in config[@"channelList"]) {
		if ([s isChannelName]) {
			[channels safeAddObject:@{@"channelName": s,
			 @"joinOnConnect": NSNumberWithBOOL(YES), 
			 @"enableNotifications": NSNumberWithBOOL(YES),
TPCPreferencesMigrationAssistantVersionKey : TPCPreferencesMigrationAssistantUpgradePath}];
		}
	}
	
	NSString *host = config[@"serverAddress"];
	NSString *nick = config[@"identityNickname"];
	
	dic[@"serverAddress"] = host;
	dic[@"connectionName"] = host;
	dic[@"identityNickname"] = nick;
	dic[@"channelList"] = channels;
	dic[@"connectOnLaunch"] = config[@"connectOnLaunch"];
	dic[@"characterEncodingDefault"] = NSNumberWithLong(NSUTF8StringEncoding);
	
	/* Migration Assistant Dictionary Addition. */
	[dic safeSetObject:TPCPreferencesMigrationAssistantUpgradePath
				forKey:TPCPreferencesMigrationAssistantVersionKey];
	
	[self.window makeKeyAndOrderFront:nil];
	
	IRCClientConfig *c = [[IRCClientConfig alloc] initWithDictionary:dic];
	IRCClient		*u = [self.world createClient:c reload:YES];
	
	[self.world save];
	
	if (c.autoConnect) {
		[u connect];
	}
}

- (void)welcomeSheetWillClose:(TDCWelcomeSheet *)sender
{
	self.welcomeSheet = nil;
}

@end
