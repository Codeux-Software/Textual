// Created by Satoshi Nakagawa <psychs AT limechat DOT net> <http://github.com/psychs/limechat>
// Modifications by Codeux Software <support AT codeux DOT com> <https://github.com/codeux/Textual>
// You can redistribute it and/or modify it under the new BSD license.
// Converted to ARC Support on Thursday, June 08, 2012

#define KInternetEventClass		1196773964
#define KAEGetURL				1196773964

#define maximumSplitViewWidth	300
#define minimumSplitViewWidth	120
#define defaultSplitViewWidth	170

@interface MasterController (Private)
- (void)setColumnLayout;
- (void)registerKeyHandlers;
@end

@implementation MasterController

@synthesize addServerButton;
@synthesize chanMenu;
@synthesize channelMenu;
@synthesize completionStatus;
@synthesize extrac;
@synthesize formattingMenu;
@synthesize ghostMode;
@synthesize growl;
@synthesize inputHistory;
@synthesize logBase;
@synthesize logMenu;
@synthesize memberList;
@synthesize memberSplitView;
@synthesize memberSplitViewOldPosition;
@synthesize memberMenu;
@synthesize menu;
@synthesize serverList;
@synthesize serverMenu;
@synthesize serverSplitView;
@synthesize terminating;
@synthesize text;
@synthesize treeMenu;
@synthesize urlMenu;
@synthesize viewTheme;
@synthesize welcomeSheet;
@synthesize window;
@synthesize world;

#pragma mark -
#pragma mark NSApplication Delegate

- (void)awakeFromNib
{
#ifdef _MAC_OS_LION_OR_NEWER
	[self.window setCollectionBehavior:NSWindowCollectionBehaviorFullScreenPrimary];
#endif
	
	if ([NSEvent modifierFlags] & NSShiftKeyMask) {
		self.ghostMode = YES;
	}
	
#if defined(DEBUG)
    ghostMode = YES; // Do not use autoconnect during debug
#endif
	
	[self.window makeMainWindow];
	
	[Preferences initPreferences];
	
	[self.text setBackgroundColor:[NSColor clearColor]];
	
	[[ViewTheme invokeInBackgroundThread] createUserDirectory:NO];
	
	[_NSNotificationCenter() addObserver:self selector:@selector(themeStyleDidChange:) name:ThemeStyleDidChangeNotification object:nil];
	[_NSNotificationCenter() addObserver:self selector:@selector(transparencyDidChange:) name:TransparencyDidChangeNotification object:nil];
	[_NSNotificationCenter() addObserver:self selector:@selector(inputHistorySchemeChanged:) name:InputHistoryGlobalSchemeNotification object:nil];
	
	[_NSWorkspaceNotificationCenter() addObserver:self selector:@selector(computerDidWakeUp:) name:NSWorkspaceDidWakeNotification object:nil];
	[_NSWorkspaceNotificationCenter() addObserver:self selector:@selector(computerWillSleep:) name:NSWorkspaceWillSleepNotification object:nil];
	[_NSWorkspaceNotificationCenter() addObserver:self selector:@selector(computerWillPowerOff:) name:NSWorkspaceWillPowerOffNotification object:nil];
	
	[_NSAppleEventManager() setEventHandler:self andSelector:@selector(handleURLEvent:withReplyEvent:) forEventClass:KInternetEventClass andEventID:KAEGetURL];
	
    [self.text setFieldEditor:YES];
    
	self.serverSplitView.fixedViewIndex = 0;
	self.memberSplitView.fixedViewIndex = 1;
	
	self.viewTheme	   = [ViewTheme new];
	self.viewTheme.name = [Preferences themeName];
	
	[self loadWindowState];
	
	[self.window setAlphaValue:[Preferences themeTransparency]];
	
    [self.text setReturnActionWithSelector:@selector(textEntered) owner:self];
    
	[LanguagePreferences setThemeForLocalization:self.viewTheme.path];
	
	IRCWorldConfig *seed = [[IRCWorldConfig alloc] initWithDictionary:[Preferences loadWorld]];
	
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
	
	self.growl = [GrowlController new];
	self.growl.owner = self.world;
	self.world.growl = self.growl;
	
	[self.formattingMenu enableWindowField:self.text];
	
	if ([Preferences inputHistoryIsChannelSpecific] == NO) {
		self.inputHistory = [InputHistory new];
	}
	
	[self registerKeyHandlers];
	
	[self.viewTheme validateFilePathExistanceAndReload:YES];
	
	[[NSBundle invokeInBackgroundThread] loadBundlesIntoMemory:self.world];
}

- (void)applicationDidFinishLaunching:(NSNotification *)note
{
    [self.world focusInputText];
    
	[self.window makeKeyAndOrderFront:nil];
	
	if (self.world.clients.count < 1) {
		self.welcomeSheet = [WelcomeSheet new];
		self.welcomeSheet.delegate = self;
		self.welcomeSheet.window = self.window;
		[self.welcomeSheet show];
	} else {
		[self.world autoConnectAfterWakeup:NO];	
	}
	
#ifdef IS_TRIAL_BINARY
	[[PopupPrompts invokeInBackgroundThread] dialogWindowWithQuestion:TXTLS(@"TRIAL_BUILD_INTRO_DIALOG_MESSAGE")
																title:TXTLS(@"TRIAL_BUILD_INTRO_DIALOG_TITLE")
														defaultButton:TXTLS(@"OK_BUTTON") 
													  alternateButton:nil
														  otherButton:nil
													   suppressionKey:@"trial_period_info"
													  suppressionText:nil];
#endif
	
}

- (void)applicationDidBecomeActive:(NSNotification *)note
{
	id sel = self.world.selected;
    
	if (sel) {
		[sel resetState];
		
		[self.world updateIcon];
	}
	
    [self.world reloadTree];
}

- (void)applicationDidResignActive:(NSNotification *)note
{
	id sel = self.world.selected;
    
	if (sel) {
		[sel resetState];
		
		[self.world updateIcon];
	}
    
    [self.world reloadTree];
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
	
	if ([Preferences confirmQuit]) {
		NSInteger result = [PopupPrompts dialogWindowWithQuestion:TXTLS(@"WANT_QUIT_MESSAGE")
															title:TXTLS(@"WANT_QUIT_TITLE") 
													defaultButton:TXTLS(@"QUIT_BUTTON") 
												  alternateButton:TXTLS(@"CANCEL_BUTTON") 
													  otherButton:nil
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
	
	[self.world save];
	[self.world terminate];
	[self.menu terminate];
	[self saveWindowState];
	
	[Preferences updateTotalRunTime];
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
	[self loadWindowState];
	
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
    NSMenu	   *editorMenu = [self.text menu];
    NSMenuItem *formatMenu = [self.formattingMenu formatterMenu];
    
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
	
	if ([Preferences inputHistoryIsChannelSpecific]) {
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
	[self sendText:IRCCI_PRIVMSG];
}

- (void)showMemberListSplitView:(BOOL)showList
{
	self.memberSplitViewOldPosition = self.memberSplitView.position;
	
	if (showList) {
		NSView *rightView = [[self.memberSplitView subviews] safeObjectAtIndex:1];
		
		self.memberSplitView.hidden	 = NO;
		self.memberSplitView.inverted = NO;
		
		if ([self.memberSplitView isSubviewCollapsed:rightView] == NO) {
			if (self.memberSplitViewOldPosition < minimumSplitViewWidth) {
				self.memberSplitViewOldPosition = minimumSplitViewWidth;
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
		NSView *leftSide  = [[splitView subviews] objectAtIndex:0];
		NSView *rightSide = [[splitView subviews] objectAtIndex:1];
		
		NSInteger leftWidth  = [leftSide bounds].size.width;
		NSInteger rightWidth = [rightSide bounds].size.width;
		
		return ((leftWidth + rightWidth) - minimumSplitViewWidth);
	}
	
	return maximumSplitViewWidth;
}

- (CGFloat)splitView:(NSSplitView *)splitView
constrainMinCoordinate:(CGFloat)proposedMax
		 ofSubviewAt:(NSInteger)dividerIndex
{
	if ([splitView isEqual:self.memberSplitView]) {
		NSView *leftSide  = [[splitView subviews] objectAtIndex:0];
		NSView *rightSide = [[splitView subviews] objectAtIndex:1];
		
		NSInteger leftWidth  = [leftSide bounds].size.width;
		NSInteger rightWidth = [rightSide bounds].size.width;
		
		return ((leftWidth + rightWidth) - maximumSplitViewWidth);
	}
	
	return minimumSplitViewWidth;
}

- (BOOL)splitView:(NSSplitView *)splitView canCollapseSubview:(NSView *)subview
{
	if ([splitView isEqual:self.memberSplitView]) {
		NSView *leftSide = [[splitView subviews] objectAtIndex:0];
        
		if ([leftSide isEqual:subview]) {
			return NO;
		}
	} else if ([splitView isEqual:self.serverSplitView]) {
		NSView *rightSide = [[splitView subviews] objectAtIndex:1];
		
		if ([rightSide isEqual:subview] || NSObjectIsEmpty(self.world.clients)) {
			return NO;		
		} 
	}
	
	return YES;
}

- (void)loadWindowState
{
	NSDictionary *dic = [Preferences loadWindowStateWithName:@"MainWindow"];
	
	if (dic) {
		NSInteger x = [dic integerForKey:@"x"];
		NSInteger y = [dic integerForKey:@"y"];
		NSInteger w = [dic integerForKey:@"w"];
		NSInteger h = [dic integerForKey:@"h"];
		
		[self.window setFrame:NSMakeRect(x, y, w, h) display:YES animate:self.menu.isInFullScreenMode];
		
		[self.text setGrammarCheckingEnabled:[_NSUserDefaults() boolForKey:@"GrammarChecking"]];
		[self.text setContinuousSpellCheckingEnabled:[_NSUserDefaults() boolForKey:@"SpellChecking"]];
		[self.text setAutomaticSpellingCorrectionEnabled:[_NSUserDefaults() boolForKey:@"AutoSpellCorrection"]];
		
		self.serverSplitView.position = [dic integerForKey:@"serverList"];
		self.memberSplitView.position = [dic integerForKey:@"memberList"];
		
		if (self.serverSplitView.position < minimumSplitViewWidth) {
			self.serverSplitView.position = defaultSplitViewWidth;
		}
		
		if (self.memberSplitView.position < minimumSplitViewWidth) {
			self.memberSplitView.position = defaultSplitViewWidth;
		}
	} else {
		NSScreen *screen = [NSScreen mainScreen];
		
		if (screen) {
			NSRect rect = [screen visibleFrame];
			
			NSPoint p = NSMakePoint((rect.origin.x + (rect.size.width / 2)), 
									(rect.origin.y + (rect.size.height / 2)));
			
			NSInteger w = 800;
			NSInteger h = 418;
			
			rect = NSMakeRect((p.x - (w / 2)), (p.y - (h / 2)), w, h);
			
			[self.window setFrame:rect display:YES animate:self.menu.isInFullScreenMode];
		}
		
		self.serverSplitView.position = 170;
		self.memberSplitView.position = 170;
	}
	
	self.memberSplitViewOldPosition = self.memberSplitView.position;
}

- (void)saveWindowState
{
	NSMutableDictionary *dic = [NSMutableDictionary dictionary];
	
	if (self.menu.isInFullScreenMode) {
		[self.menu wantsFullScreenModeToggled:nil];
	}
	
	NSRect rect = self.window.frame;
	
	[dic setInteger:rect.origin.x		forKey:@"x"];
	[dic setInteger:rect.origin.y		forKey:@"y"];
	[dic setInteger:rect.size.width		forKey:@"w"];
	[dic setInteger:rect.size.height	forKey:@"h"];
	
	if (self.serverSplitView.position < minimumSplitViewWidth) {
		self.serverSplitView.position = defaultSplitViewWidth;
	}
	
	if (self.memberSplitView.position < minimumSplitViewWidth) {
		if (self.memberSplitViewOldPosition < minimumSplitViewWidth) {
			self.memberSplitView.position = defaultSplitViewWidth;
		} else {
			self.memberSplitView.position = self.memberSplitViewOldPosition;
		}
	}
	
	[dic setInteger:self.serverSplitView.position forKey:@"serverList"];
	[dic setInteger:self.memberSplitView.position forKey:@"memberList"];
	
	[_NSUserDefaults() setBool:[self.text isGrammarCheckingEnabled]				forKey:@"GrammarChecking"];
	[_NSUserDefaults() setBool:[self.text isContinuousSpellCheckingEnabled]		forKey:@"SpellChecking"];
	[_NSUserDefaults() setBool:[self.text isAutomaticSpellingCorrectionEnabled]	forKey:@"AutoSpellCorrection"];
	
	[Preferences saveWindowState:dic name:@"MainWindow"];
	[Preferences sync];
}

- (void)themeStyleDidChange:(NSNotification *)note
{
	NSMutableString *sf = [NSMutableString string];
	
	[self.world reloadTheme];
	
	if (self.viewTheme.other.nicknameFormat) {
		[sf appendString:TXTLS(@"THEME_CHANGE_OVERRIDE_PROMPT_NICKNAME_FORMAT")];
		[sf appendString:NSNewlineCharacter];
	}
	
	if (self.viewTheme.other.timestampFormat) {
		[sf appendString:TXTLS(@"THEME_CHANGE_OVERRIDE_PROMPT_TIMESTAMP_FORMAT")];
		[sf appendString:NSNewlineCharacter];
	}
	
	if (self.viewTheme.other.channelViewFontOverrode) {
		[sf appendString:TXTLS(@"THEME_CHANGE_OVERRIDE_PROMPT_CHANNEL_FONT")];
		[sf appendString:NSNewlineCharacter];
	}
	
	if ([Preferences rightToLeftFormatting]) {
		[self.text setBaseWritingDirection:NSWritingDirectionRightToLeft];
	} else {
		[self.text setBaseWritingDirection:NSWritingDirectionLeftToRight];
	}
	
	sf = (NSMutableString *)[sf trim];
	
	if (NSObjectIsNotEmpty(sf)) {		
		NSString *theme = [ViewTheme extractThemeName:[Preferences themeName]];
		
		[PopupPrompts sheetWindowWithQuestion:[NSApp keyWindow] 
									   target:[PopupPrompts class]
									   action:@selector(popupPromptNULLSelector:) 
										 body:TXTFLS(@"THEME_CHANGE_OVERRIDE_PROMPT_MESSAGE", theme, sf)
										title:TXTLS(@"THEME_CHANGE_OVERRIDE_PROMPT_TITLE")
								defaultButton:TXTLS(@"OK_BUTTON")
							  alternateButton:nil 
								  otherButton:nil
							   suppressionKey:@"theme_override_info" 
							  suppressionText:nil];
	}
}

- (void)transparencyDidChange:(NSNotification *)note
{
	[self.window setAlphaValue:[Preferences themeTransparency]];
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
		
		if ([Preferences inputHistoryIsChannelSpecific]) {
			c.inputHistory = [InputHistory new];
		}
		
		for (IRCChannel *u in c.channels) {
			if (u.inputHistory) {
				u.inputHistory = nil;
			}
			
			if ([Preferences inputHistoryIsChannelSpecific]) {
				u.inputHistory = [InputHistory new];
			}
		}
	}
	
	if ([Preferences inputHistoryIsChannelSpecific] == NO) {
		self.inputHistory = [InputHistory new];
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
		self.completionStatus = [NickCompletionStatus new];
	}
	
	NickCompletionStatus *status = self.completionStatus;
    
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
        
		for (NSString *command in [Preferences commandIndexList].allKeys) {
			[choices safeAddObject:[command lowercaseString]];
		}
		
		for (NSString *command in [self.world bundlesForUserInput].allKeys) {
			NSString *cmdl = [command lowercaseString];
			
			if ([choices containsObject:cmdl] == NO) {
				[choices safeAddObject:cmdl];
			}
		}
		
		NSArray *scriptPaths = [NSArray arrayWithObjects:
								
#ifdef _USES_APPLICATION_SCRIPTS_FOLDER
								[Preferences whereScriptsUnsupervisedPath],
#endif
								
								[Preferences whereScriptsLocalPath],
								[Preferences whereScriptsPath], nil];
		
		for (NSString *path in scriptPaths) {
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
		[nicks      safeAddObject:[Preferences applicationName]];
		
		[lowerNicks safeAddObject:@"nickserv"];
		[lowerNicks safeAddObject:@"rootserv"];
		[lowerNicks safeAddObject:@"operserv"];
		[lowerNicks safeAddObject:@"hostserv"];
		[lowerNicks safeAddObject:@"chanserv"];
		[lowerNicks safeAddObject:[Preferences applicationName]];
		
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
	
	[[NSSpellChecker sharedSpellChecker] ignoreWord:t
							 inSpellDocumentWithTag:[self.text spellCheckerDocumentTag]];
	
	if ((commandMode || channelMode) || head == NO) {
		t = [t stringByAppendingString:NSWhitespaceCharacter];
	} else {
		if (NSObjectIsNotEmpty([Preferences completionSuffix])) {
			t = [t stringByAppendingString:[Preferences completionSuffix]];
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

typedef enum {
	MOVE_UP,
	MOVE_DOWN,
	MOVE_LEFT,
	MOVE_RIGHT,
	MOVE_ALL,
	MOVE_ACTIVE,
	MOVE_UNREAD,
} MoveKind;

- (void)move:(MoveKind)dir target:(MoveKind)target
{
	if (dir == MOVE_UP || dir == MOVE_DOWN) {
		id sel = self.world.selected;
		if (PointerIsEmpty(sel)) return;
		
		NSInteger n = [self.serverList rowForItem:sel];
		if (n < 0) return;
		
		NSInteger start = n;
		NSInteger count = [self.serverList numberOfRows];
		
		if (count <= 1) return;
		
		while (1 == 1) {
			if (dir == MOVE_UP) {
				--n;
				
				if (n < 0) n = (count - 1);
			} else {
				++n;
				
				if (count <= n) n = 0;
			}
			
			if (n == start) break;
			
			id i = [self.serverList itemAtRow:n];
			
			if (i) {
				if (target == MOVE_ACTIVE) {
					if ([i isClient] == NO && [i isActive]) {
						[self.world select:i];
						
						break;
					}
				} else if (target == MOVE_UNREAD) {
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
	} else if (dir == MOVE_LEFT || dir == MOVE_RIGHT) {
		IRCClient *client = [self.world selectedClient];
		if (PointerIsEmpty(client)) return;
		
		NSUInteger pos = [self.world.clients indexOfObjectIdenticalTo:client];
		if (pos == NSNotFound) return;
		
		NSInteger n = pos;
		NSInteger start = n;
		
		NSInteger count = self.world.clients.count;
		if (count <= 1) return;
		
		while (1 == 1) {
			if (dir == MOVE_LEFT) {
				--n;
				
				if (n < 0) n = (count - 1);
			} else {
				++n;
				
				if (count <= n) n = 0;
			}
			
			if (n == start) break;
			
			client = [self.world.clients safeObjectAtIndex:n];
			
			if (client) {
				if (target == MOVE_ACTIVE) {
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
	[self move:MOVE_UP target:MOVE_ALL];
}

- (void)selectNextChannel:(NSEvent *)e
{
	[self move:MOVE_DOWN target:MOVE_ALL];
}

- (void)selectPreviousUnreadChannel:(NSEvent *)e
{
	[self move:MOVE_UP target:MOVE_UNREAD];
}

- (void)selectNextUnreadChannel:(NSEvent *)e
{
	[self move:MOVE_DOWN target:MOVE_UNREAD];
}

- (void)selectPreviousActiveChannel:(NSEvent *)e
{
	[self move:MOVE_UP target:MOVE_ACTIVE];
}

- (void)selectNextActiveChannel:(NSEvent *)e
{
	[self move:MOVE_DOWN target:MOVE_ACTIVE];
}

- (void)selectPreviousServer:(NSEvent *)e
{
	[self move:MOVE_LEFT target:MOVE_ALL];
}

- (void)selectNextServer:(NSEvent *)e
{
	[self move:MOVE_RIGHT target:MOVE_ALL];
}

- (void)selectPreviousActiveServer:(NSEvent *)e
{
	[self move:MOVE_LEFT target:MOVE_ACTIVE];
}

- (void)selectNextActiveServer:(NSEvent *)e
{
	[self move:MOVE_RIGHT target:MOVE_ACTIVE];
}

- (void)selectPreviousSelection:(NSEvent *)e
{
	[self.world selectPreviousItem];
}

- (void)selectNextSelection:(NSEvent *)e
{
	[self move:MOVE_DOWN target:MOVE_ALL];
}

- (void)tab:(NSEvent *)e
{
	switch ([Preferences tabAction]) {
		case TAB_COMPLETE_NICK: [self completeNick:YES];					break;
		case TAB_UNREAD:		[self move:MOVE_DOWN target:MOVE_UNREAD];	break;
		default: break;
	}
}

- (void)shiftTab:(NSEvent *)e
{
	switch ([Preferences tabAction]) {
		case TAB_COMPLETE_NICK: [self completeNick:NO];					break;
		case TAB_UNREAD:		[self move:MOVE_UP target:MOVE_UNREAD]; break;
		default: break;
	}
}

- (void)sendMsgAction:(NSEvent *)e
{
	[self sendText:IRCCI_ACTION];
}

- (void)_moveInputHistory:(BOOL)up checkScroller:(BOOL)scroll event:(NSEvent *)event
{
	if (scroll) {
		NSInteger nol = [self.text numberOfLines];
		
		if (nol >= 2) {
			BOOL atTop    = [self.text isAtTopfView];
			BOOL atBottom = [self.text isAtBottomOfView];
			
			if ((atTop && event.keyCode == KEY_DOWN) ||
				(atBottom && event.keyCode == KEY_UP) ||
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
        
        if ([self.text respondsToSelector:@selector(resetTextFieldCellSize)]) {
            [self.text resetTextFieldCellSize];
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
        [self.menu wantsFullScreenModeToggled:nil];
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
    
    [self handler:@selector(exitFullscreenMode:) code:KEY_ESCAPE mods:0];
	
	[self handler:@selector(tab:)		code:KEY_TAB mods:0];
	[self handler:@selector(shiftTab:)	code:KEY_TAB mods:NSShiftKeyMask];
	
	[self handler:@selector(sendMsgAction:) code:KEY_ENTER	mods:NSCommandKeyMask];
	[self handler:@selector(sendMsgAction:) code:KEY_RETURN mods:NSCommandKeyMask];
	
	[self handler:@selector(selectPreviousSelection:) code:KEY_TAB mods:NSAlternateKeyMask];
	
	[self handler:@selector(textFormattingBold:)			char:'b' mods:NSCommandKeyMask];
	[self handler:@selector(textFormattingUnderline:)		char:'u' mods:(NSCommandKeyMask | NSAlternateKeyMask)];
	[self handler:@selector(textFormattingItalic:)			char:'i' mods:(NSCommandKeyMask | NSAlternateKeyMask)];
    [self handler:@selector(textFormattingForegroundColor:) char:'c' mods:(NSCommandKeyMask | NSAlternateKeyMask)];
	[self handler:@selector(textFormattingBackgroundColor:) char:'h' mods:(NSCommandKeyMask | NSAlternateKeyMask)];
	
	[self handler:@selector(inputHistoryUp:)	char:'p' mods:NSControlKeyMask];
	[self handler:@selector(inputHistoryDown:)	char:'n' mods:NSControlKeyMask];
    
    [self inputHandler:@selector(focusWebview) char:'l' mods:(NSControlKeyMask | NSCommandKeyMask)];
    
	[self inputHandler:@selector(inputHistoryUpWithScrollCheck:) code:KEY_UP mods:0];
	[self inputHandler:@selector(inputHistoryUpWithScrollCheck:) code:KEY_UP mods:NSAlternateKeyMask];
	
	[self inputHandler:@selector(inputHistoryDownWithScrollCheck:) code:KEY_DOWN mods:0];
	[self inputHandler:@selector(inputHistoryDownWithScrollCheck:) code:KEY_DOWN mods:NSAlternateKeyMask];
}

#pragma mark -
#pragma mark WelcomeSheet Delegate

- (void)WelcomeSheet:(WelcomeSheet *)sender onOK:(NSDictionary *)config
{
	NSMutableArray *channels = [NSMutableArray array];
	NSMutableDictionary *dic = [NSMutableDictionary dictionary];
	
	for (NSString *s in [config objectForKey:@"channels"]) {
		if ([s isChannelName]) {
			[channels safeAddObject:[NSDictionary dictionaryWithObjectsAndKeys:s, @"name", 
									 NSNumberWithBOOL(YES), @"auto_join", 
									 NSNumberWithBOOL(YES), @"growl", nil]];	
		}
	}
	
	NSString *host = [config objectForKey:@"host"];
	NSString *nick = [config objectForKey:@"nick"];
	
	[dic setObject:host forKey:@"host"];
	[dic setObject:host forKey:@"name"];
	[dic setObject:nick forKey:@"nick"];
	[dic setObject:channels forKey:@"channels"];
	[dic setObject:[config objectForKey:@"autoConnect"] forKey:@"auto_connect"];
	[dic setObject:[NSNumber numberWithLong:NSUTF8StringEncoding] forKey:@"encoding"];
	
	[self.window makeKeyAndOrderFront:nil];
	
	IRCClientConfig *c = [[IRCClientConfig alloc] initWithDictionary:dic];
	IRCClient		*u = [self.world createClient:c reload:YES];
	
	[self.world save];
	
	if (c.autoConnect) {
		[u connect];
	}
}

- (void)WelcomeSheetWillClose:(WelcomeSheet *)sender
{
	self.welcomeSheet = nil;
}

@end
