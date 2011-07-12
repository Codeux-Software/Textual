// Created by Satoshi Nakagawa <psychs AT limechat DOT net> <http://github.com/psychs/limechat>
// Modifications by Codeux Software <support AT codeux DOT com> <https://github.com/codeux/Textual>
// You can redistribute it and/or modify it under the new BSD license.

#define KInternetEventClass	1196773964
#define KAEGetURL			1196773964

@interface MasterController (Private)
- (void)setColumnLayout;
- (void)registerKeyHandlers;
@end

@implementation MasterController

@synthesize addrMenu;
@synthesize chanMenu;
@synthesize channelMenu;
@synthesize chatBox;
@synthesize completionStatus;
@synthesize extrac;
@synthesize fieldEditor;
@synthesize formattingMenu;
@synthesize ghostMode;
@synthesize growl;
@synthesize infoSplitter;
@synthesize inputHistory;
@synthesize leftTreeBase;
@synthesize logBase;
@synthesize logMenu;
@synthesize memberList;
@synthesize memberMenu;
@synthesize menu;
@synthesize rightTreeBase;
@synthesize rootSplitter;
@synthesize serverMenu;
@synthesize terminating;
@synthesize text;
@synthesize tree;
@synthesize treeMenu;
@synthesize treeScrollView;
@synthesize treeSplitter;
@synthesize urlMenu;
@synthesize viewTheme;
@synthesize WelcomeSheetDisplay;
@synthesize window;
@synthesize world;

- (void)dealloc
{
	[completionStatus drain];
	[extrac drain];
	[fieldEditor drain];
	[formattingMenu drain];
	[growl drain];
	[inputHistory drain];
	[viewTheme drain];
	[WelcomeSheetDisplay drain];
	[world drain];	
	
	[super dealloc];
}

#pragma mark -
#pragma mark NSApplication Delegate

- (void)awakeFromNib
{
	if ([NSEvent modifierFlags] & NSShiftKeyMask) {
		ghostMode = YES;
	}
	
#ifdef _RUNNING_MAC_OS_LION
	[window setCollectionBehavior:NSWindowCollectionBehaviorFullScreenPrimary];
#endif
	
	[window makeMainWindow];
	
	[Preferences initPreferences];
	
	[[ViewTheme invokeInBackgroundThread] createUserDirectory:NO];
	
	[_NSNotificationCenter() addObserver:self selector:@selector(themeDidChange:) name:ThemeDidChangeNotification object:nil];
	[_NSNotificationCenter() addObserver:self selector:@selector(themeStyleDidChange:) name:ThemeStyleDidChangeNotification object:nil];
	[_NSNotificationCenter() addObserver:self selector:@selector(themeEnableRightMenu:) name:ThemeSelectedChannelNotification object:nil];
	[_NSNotificationCenter() addObserver:self selector:@selector(themeDisableRightMenu:) name:ThemeSelectedConsoleNotification object:nil];
	[_NSNotificationCenter() addObserver:self selector:@selector(transparencyDidChange:) name:TransparencyDidChangeNotification object:nil];
	[_NSNotificationCenter() addObserver:self selector:@selector(inputHistorySchemeChanged:) name:InputHistoryGlobalSchemeNotification object:nil];
	
	[_NSWorkspaceNotificationCenter() addObserver:self selector:@selector(computerDidWakeUp:) name:NSWorkspaceDidWakeNotification object:nil];
	[_NSWorkspaceNotificationCenter() addObserver:self selector:@selector(computerWillSleep:) name:NSWorkspaceWillSleepNotification object:nil];
	[_NSWorkspaceNotificationCenter() addObserver:self selector:@selector(computerWillPowerOff:) name:NSWorkspaceWillPowerOffNotification object:nil];
	
	[_NSAppleEventManager() setEventHandler:self andSelector:@selector(handleURLEvent:withReplyEvent:) forEventClass:KInternetEventClass andEventID:KAEGetURL];
	
	rootSplitter.fixedViewIndex = 1;
	infoSplitter.fixedViewIndex = 1;
	
	fieldEditor = [[FieldEditorTextView alloc] initWithFrame:NSZeroRect];
	[fieldEditor setFieldEditor:YES];
	fieldEditor.pasteDelegate = self;
	
	[text setFocusRingType:NSFocusRingTypeNone];
	
	viewTheme	   = [ViewTheme new];
	viewTheme.name = [Preferences themeName];
	
	tree.theme = viewTheme.other;
	memberList.theme = viewTheme.other;
	
	MemberListViewCell *cell = [MemberListViewCell initWithTheme:viewTheme.other];
	[[[memberList tableColumns] safeObjectAtIndex:0] setDataCell:cell];
	
	[self loadWindowState];
	[self setColumnLayout];
	
	[window setAlphaValue:[Preferences themeTransparency]];
	[window setBackgroundColor:viewTheme.other.underlyingWindowColor];
	
	[rootSplitter setDividerColor:viewTheme.other.underlyingWindowColor];
	[infoSplitter setDividerColor:viewTheme.other.underlyingWindowColor];
	[treeSplitter setDividerColor:viewTheme.other.underlyingWindowColor];
	
	[LanguagePreferences setThemeForLocalization:viewTheme.path];
	
	IRCWorldConfig *seed = [[[IRCWorldConfig alloc] initWithDictionary:[Preferences loadWorld]] autodrain];
	
	extrac = [IRCExtras new];
	world  = [IRCWorld new];
	
	world.window = window;
	world.growl = growl;
	world.tree = tree;
	world.master = self;
	world.extrac = extrac;
	world.text = text;
	world.logBase = logBase;
	world.chatBox = chatBox;
	world.fieldEditor = fieldEditor;
	world.memberList = memberList;
	world.treeMenu = treeMenu;
	world.logMenu = logMenu;
	world.urlMenu = urlMenu;
	world.addrMenu = addrMenu;
	world.chanMenu = chanMenu;
	world.memberMenu = memberMenu;
	world.viewTheme = viewTheme;
	world.menuController = menu;
	
	[world setServerMenuItem:serverMenu];
	[world setChannelMenuItem:channelMenu];
	
	[world setup:seed];
	
	extrac.world = world;
	
	tree.dataSource = world;
	tree.delegate = world;
	tree.responderDelegate = world;
	[tree reloadData];
	
	[world setupTree];
	
	menu.world = world;
	menu.window = window;
	menu.tree = tree;
	menu.memberList = memberList;
	menu.text = text;
	menu.master = self;
	
	memberList.target = menu;
	memberList.keyDelegate = world;
	memberList.dropDelegate = world;
	
	[memberList setDoubleAction:@selector(memberListDoubleClicked:)];
	
	growl = [GrowlController new];
	growl.owner = world;
	world.growl = growl;
	
	[growl registerToGrowl];
	
	[formattingMenu enableWindowField:text];
	
	if ([Preferences inputHistoryIsChannelSpecific] == NO) {
		inputHistory = [InputHistory new];
	}
	
	[self registerKeyHandlers];
	
	[viewTheme validateFilePathExistanceAndReload:YES];
	
	[[NSBundle invokeInBackgroundThread] loadBundlesIntoMemory:world];
}

- (void)applicationDidFinishLaunching:(NSNotification *)note
{
	[window makeFirstResponder:text];
	[window makeKeyAndOrderFront:nil];
	
	if (world.clients.count < 1) {
		WelcomeSheetDisplay = [WelcomeSheet new];
		WelcomeSheetDisplay.delegate = self;
		WelcomeSheetDisplay.window = window;
		[WelcomeSheetDisplay show];
	} else {
		[world autoConnectAfterWakeup:NO];	
	}
	
#ifdef IS_TRIAL_BINARY
	[[PopupPrompts invokeInBackgroundThread] dialogWindowWithQuestion:TXTLS(@"TRIAL_BUILD_INTRO_DIALOG_MESSAGE")
																title:TXTLS(@"TRIAL_BUILD_INTRO_DIALOG_TITLE")
														defaultButton:TXTLS(@"OK_BUTTON") 
													  alternateButton:nil
													   suppressionKey:@"Preferences.prompts.trial_period_info" 
													  suppressionText:nil];
#endif
	
}

- (void)applicationDidBecomeActive:(NSNotification *)note
{
	id sel = world.selected;
    
	if (sel) {
		[sel resetState];
		
		[world updateIcon];
	}
	
	[tree setNeedsDisplay];
}

- (void)applicationDidResignActive:(NSNotification *)note
{
	[tree setNeedsDisplay];
}

- (BOOL)applicationShouldHandleReopen:(NSApplication *)sender hasVisibleWindows:(BOOL)flag
{
	[window makeKeyAndOrderFront:nil];
	
	[text focus];
	
	return YES;
}

- (void)applicationDidReceiveHotKey:(id)sender
{
	if ([window isVisible] == NO || [NSApp isActive] == NO) {
		if (NSObjectIsEmpty(world.clients)) {
			[NSApp activateIgnoringOtherApps:YES];
			
			[window makeKeyAndOrderFront:nil];
			
			[text focus];
		}
	} else {
		[NSApp hide:nil];
	}
}

- (BOOL)queryTerminate
{
	if (terminating) {
		return YES;
	}
	
	if ([Preferences confirmQuit]) {
		NSInteger result = [PopupPrompts dialogWindowWithQuestion:TXTLS(@"WANT_QUIT_MESSAGE")
															title:TXTLS(@"WANT_QUIT_TITLE") 
													defaultButton:TXTLS(@"QUIT_BUTTON") 
												  alternateButton:TXTLS(@"CANCEL_BUTTON") 
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
	
	[world save];
	[world terminate];
	
	[menu terminate];
	
	[self saveWindowState];
	
	[Preferences updateTotalRunTime];
}

#pragma mark -
#pragma mark NSWorkspace Notifications

- (NSSize)windowWillResize:(NSWindow *)awindow toSize:(NSSize)newSize
{
	if (awindow != window) {
		return newSize; 
	} else {
		if (menu.isInFullScreenMode) {
			return [awindow frame].size;
		} else {
			return newSize;
		}
	}
}

- (BOOL)windowShouldZoom:(NSWindow *)awindow toFrame:(NSRect)newFrame
{
	if (window != awindow) {
		return YES;
	} else {
		return BOOLReverseValue(menu.isInFullScreenMode);
	}
}

- (void)handleURLEvent:(NSAppleEventDescriptor *)event withReplyEvent:(NSAppleEventDescriptor *)replyEvent
{
	NSString *url = [[[event descriptorAtIndex:1] stringValue] decodeURIFragement];
	
	if ([url hasPrefix:@"irc://"]) {
		url = [url safeSubstringFromIndex:6];
		
		NSArray *chunks = nil;
		
		NSInteger port = 6667;
		
		NSString *server  = nil;
		NSString *channel = nil;
		
		if ([url contains:@"/"]) {
			chunks = [url componentsSeparatedByString:@"/"];
			
			server  = [chunks safeObjectAtIndex:0];
			channel = [chunks safeObjectAtIndex:1];
			
			if ([channel contains:@" "]) {
				channel = [channel safeSubstringToIndex:[channel stringPosition:@" "]];
			}
			
			if ([channel hasPrefix:@"#"] == NO) {
				channel = [@"#" stringByAppendingString:channel];
			}
			
			if ([channel contains:@","]) {
				chunks = [channel componentsSeparatedByString:@","];
				
				channel = [chunks safeObjectAtIndex:0];
			}
		} else {
			server = url;
		}
		
		if ([server contains:@":"]) {
			chunks = [server componentsSeparatedByString:@":"];
			
			server = [chunks safeObjectAtIndex:0];
			port   = [chunks integerAtIndex:1];
		}
		
		[world createConnection:[NSString stringWithFormat:@"%@ %i", server, port] chan:channel];
	}
}

- (void)computerWillSleep:(NSNotification *)note
{
	[world prepareForSleep];
}

- (void)computerDidWakeUp:(NSNotification *)note
{
	[world autoConnectAfterWakeup:YES];
}

- (void)computerWillPowerOff:(NSNotification *)note
{
	terminating = YES;
	
	[NSApp terminate:nil];
}

- (BOOL)applicationShouldOpenUntitledFile:(NSApplication *)sender
{
	[window makeKeyAndOrderFront:nil];
	
	[text focus];
	
	return YES;
}

#pragma mark -
#pragma mark NSWindow Delegate

- (void)windowWillEnterFullScreen:(NSNotification *)notification
{
	[self saveWindowState];
}

- (void)windowDidEnterFullScreen:(NSNotification *)notification
{
	menu.isInFullScreenMode = YES;
}

- (void)windowDidExitFullScreen:(NSNotification *)notification
{
	[self loadWindowState];
	
	menu.isInFullScreenMode = NO;
}

- (id)windowWillReturnFieldEditor:(NSWindow *)sender toObject:(id)client
{
	if (client == text) {
		NSMenu	   *editorMenu = [fieldEditor menu];
		NSMenuItem *formatMenu = [formattingMenu formatterMenu];
		
		if (formatMenu) {
			NSInteger fontIndex = -1;
			NSInteger fmtrIndex = [editorMenu indexOfItemWithTitle:[formatMenu title]];
			
			if (fmtrIndex == -1) {
				for (NSMenuItem *mitem in [editorMenu itemArray]) {
					NSMenu *sumenu = [mitem submenu];
					
					if (PointerIsEmpty(sumenu) == NO) {
						for (NSMenuItem *nitem in [sumenu itemArray]) {
							NSString *naction = NSStringFromSelector([nitem action]);
							
							if ([naction isEqualToString:@"orderFrontFontPanel:"]) {
								fontIndex = [editorMenu indexOfItem:mitem];
							}
						}
					}
				}
				
				[editorMenu addItem:[NSMenuItem separatorItem]];
				[editorMenu addItem:formatMenu];
				
				if (fontIndex >= 0) {
					[editorMenu removeItemAtIndex:fontIndex];
				}
			}
			
			[fieldEditor setMenu:editorMenu];
		}
		
		return fieldEditor;
	}
	
	return nil;
}

#pragma mark -
#pragma mark FieldEditorTextView Delegates

- (BOOL)fieldEditorTextViewPaste:(id)sender
{
	id field = [window selectedTextField];
	
	if (PointerIsEmpty(field) == NO) {
		if ([sender isKindOfClass:[NSString class]]) {
			if ([sender isEqual:@"reset"]) {
				[field focus];
			}
		}
		
		NSRange selectedRang = [field selectedRange];
		
		if ([field allowsEditingTextAttributes]) {
			if ([field respondsToSelector:@selector(pasteFilteredAttributedString:)]) {
				TextField *tfield = field;
				
				[tfield pasteFilteredAttributedString:selectedRang];
				
				return YES;
			}
		}
	} else {
		[text focus];
		
		if ([sender isKindOfClass:[NSString class]]) {
			if ([sender isEqual:@"reset"]) {
				return NO;
			}
		}
		
		return [self fieldEditorTextViewPaste:@"reset"];
	}
	
	return NO;
}

#pragma mark -
#pragma mark Utilities

- (void)sendText:(NSString *)command
{
	NSAttributedString *as = [text attributedStringValue];
	
	NSString *s = [as attributedStringToASCIIFormatting];
	
	[text setAttributedStringValue:[NSAttributedString emptyString]];
	[text setTextColor:[text textColor]];
	[text removeAllUndoActions];
	
	if ([Preferences inputHistoryIsChannelSpecific]) {
		world.selected.inputHistory.lastHistoryItem = nil;
	}
	
	if (NSObjectIsNotEmpty(s)) {
		if ([world inputText:s command:command]) {
			[inputHistory add:as];
		}
	}
	
	[text focus];
	
	if (completionStatus) {
		[completionStatus clear];
	}
}

- (void)textEntered:(id)sender
{
	[self sendText:IRCCI_PRIVMSG];
}

- (void)setColumnLayout
{
	infoSplitter.hidden = YES;
	infoSplitter.inverted = YES;
	
	[leftTreeBase addSubview:treeScrollView];
	
	if (treeSplitter.position < 1) treeSplitter.position = 130;
	
	treeScrollView.frame = leftTreeBase.bounds;
}

#pragma mark -
#pragma mark Root Splitter Console Toggle

- (void)themeEnableRightMenu:(NSNotification *)note 
{
	rootSplitter.hidden = NO;
	rootSplitter.inverted = NO;
}

- (void)themeDisableRightMenu:(NSNotification *)note 
{
	rootSplitter.hidden = YES;
	rootSplitter.inverted = YES;
	
	if (rootSplitter.position < 10) {
		rootSplitter.position = 130;
	}
}

#pragma mark -
#pragma mark Preferences

- (void)loadWindowState
{
	NSDictionary *dic = [Preferences loadWindowStateWithName:@"MainWindow"];
	
	rootSplitter.position = 130;
	
	if (dic) {
		NSInteger x = [dic integerForKey:@"x"];
		NSInteger y = [dic integerForKey:@"y"];
		NSInteger w = [dic integerForKey:@"w"];
		NSInteger h = [dic integerForKey:@"h"];
		
		[window setFrame:NSMakeRect(x, y, w, h) display:YES animate:menu.isInFullScreenMode];
		
		[fieldEditor setContinuousSpellCheckingEnabled:[_NSUserDefaults() boolForKey:@"SpellChecking"]];
		
		infoSplitter.position = [dic integerForKey:@"info"];
		treeSplitter.position = [dic integerForKey:@"tree"];
	} else {
		NSScreen *screen = [NSScreen mainScreen];
		
		if (screen) {
			NSRect rect = [screen visibleFrame];
			
			NSPoint p = NSMakePoint((rect.origin.x + (rect.size.width / 2)), 
									(rect.origin.y + (rect.size.height / 2)));
			
			NSInteger w = 1024;
			NSInteger h = 768;
			
			rect = NSMakeRect((p.x - (w / 2)), (p.y - (h / 2)), w, h);
			
			[window setFrame:rect display:YES animate:menu.isInFullScreenMode];
		}
		
		infoSplitter.position = 250;
		treeSplitter.position = 140;
	}
}

- (void)saveWindowState
{
	NSMutableDictionary *dic = [NSMutableDictionary dictionary];
	
	if (menu.isInFullScreenMode) {
		[menu wantsFullScreenModeToggled:nil];
	}
	
	NSRect rect = window.frame;
	
	[dic setInteger:rect.origin.x forKey:@"x"];
	[dic setInteger:rect.origin.y forKey:@"y"];
	[dic setInteger:rect.size.width forKey:@"w"];
	[dic setInteger:rect.size.height forKey:@"h"];
	
	[dic setInteger:infoSplitter.position forKey:@"info"];
	[dic setInteger:treeSplitter.position forKey:@"tree"];
	
	[_NSUserDefaults() setBool:[fieldEditor isContinuousSpellCheckingEnabled] forKey:@"SpellChecking"];
	
	[Preferences saveWindowState:dic name:@"MainWindow"];
	[Preferences sync];
}

- (void)themeOverrideAlertSheetCallback:(NSAlert *)alert returnCode:(int)returnCode contextInfo:(void *)contextInfo
{	
	[_NSUserDefaults() setBool:[[alert suppressionButton] state] forKey:@"Preferences.prompts.theme_override_info"];
}

- (void)themeDidChange:(NSNotification *)note
{
	NSMutableString *sf = [NSMutableString string];
	
	[world reloadTheme];
	
	[self setColumnLayout];
	
	[rootSplitter setDividerColor:viewTheme.other.underlyingWindowColor];
	[infoSplitter setDividerColor:viewTheme.other.underlyingWindowColor];
	[treeSplitter setDividerColor:viewTheme.other.underlyingWindowColor];
	
	if (viewTheme.other.nicknameFormat) {
		[sf appendString:TXTLS(@"THEME_CHANGE_OVERRIDE_PROMPT_NICKNAME_FORMAT")];
		[sf appendString:@"\n"];
	}
	
	if (viewTheme.other.timestampFormat) {
		[sf appendString:TXTLS(@"THEME_CHANGE_OVERRIDE_PROMPT_TIMESTAMP_FORMAT")];
		[sf appendString:@"\n"];
	}
	
	if (viewTheme.other.overrideChannelFont) {
		[sf appendString:TXTLS(@"THEME_CHANGE_OVERRIDE_PROMPT_CHANNEL_FONT")];
		[sf appendString:@"\n"];
	}
	
	if (viewTheme.other.overrideMessageIndentWrap) {
		[sf appendString:TXTLS(@"THEME_CHANGE_OVERRIDE_PROMPT_INDENT_WRAPPED")];
		[sf appendString:@"\n"];
	}
	
	sf = (NSMutableString *)[sf trim];
	
	if (NSObjectIsNotEmpty(sf)) {		
		NSString *theme = [ViewTheme extractThemeName:[Preferences themeName]];
		
		[PopupPrompts sheetWindowWithQuestion:[NSApp keyWindow] 
									   target:self 
									   action:@selector(themeOverrideAlertSheetCallback:returnCode:contextInfo:) 
										 body:TXTFLS(@"THEME_CHANGE_OVERRIDE_PROMPT_MESSAGE", theme, sf)
										title:TXTLS(@"THEME_CHANGE_OVERRIDE_PROMPT_TITLE")
								defaultButton:TXTLS(@"OK_BUTTON")
							  alternateButton:nil 
							   suppressionKey:@"Preferences.prompts.theme_override_info" 
							  suppressionText:nil];
	}
}

- (void)themeStyleDidChange:(NSNotification *)note
{
	[world updateThemeStyle];
}

- (void)transparencyDidChange:(NSNotification *)note
{
	[window setAlphaValue:[Preferences themeTransparency]];
}

- (void)inputHistorySchemeChanged:(NSNotification *)note
{
	if (inputHistory) {
		[inputHistory drain];
		inputHistory = nil;
	}
	
	for (IRCClient *c in world.clients) {
		if (c.inputHistory) {
			[c.inputHistory drain];
			c.inputHistory = nil;
		}
		
		if ([Preferences inputHistoryIsChannelSpecific]) {
			c.inputHistory = [InputHistory new];
		}
		
		for (IRCChannel *u in c.channels) {
			if (u.inputHistory) {
				[u.inputHistory drain];
				u.inputHistory = nil;
			}
			
			if ([Preferences inputHistoryIsChannelSpecific]) {
				u.inputHistory = [InputHistory new];
			}
		}
	}
	
	if ([Preferences inputHistoryIsChannelSpecific] == NO) {
		inputHistory = [InputHistory new];
	}
}

#pragma mark -
#pragma mark Nick Completion

- (void)completeNick:(BOOL)forward
{
	IRCClient *client = [world selectedClient];
	IRCChannel *channel = [world selectedChannel];
	
	if (PointerIsEmpty(client)) return;
	
	if ([window firstResponder] != [window fieldEditor:NO forObject:text]) {
		[world focusInputText];
	}
	
	NSText *fe = [window fieldEditor:YES forObject:text];
	if (PointerIsEmpty(fe)) return;
	
	NSRange selectedRange = [fe selectedRange];
	if (selectedRange.location == NSNotFound) return;
	
	if (PointerIsEmpty(completionStatus)) {
		completionStatus = [NickCompletionStatus new];
	}
	
	NickCompletionStatus *status = completionStatus;
	
	NSString *s = text.stringValue;
	
	if ([status.text isEqualToString:s]
		&& status.range.location != NSNotFound
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
		
		if (c != ' ' && c != ':') {
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
		
		NSArray *resourceFiles = [_NSFileManager() contentsOfDirectoryAtPath:[Preferences whereScriptsPath] error:NULL];
		
		for (NSString *command in [[Preferences commandIndexList] allKeys]) {
			[choices safeAddObject:[command lowercaseString]];
		}
		
		for (NSString *command in [[world bundlesForUserInput] allKeys]) {
			NSString *cmdl = [command lowercaseString];
			
			if ([choices containsObject:cmdl] == NO) {
				[choices safeAddObject:cmdl];
			}
		}
		
		for (NSString *file in resourceFiles) {
			if ([file hasSuffix:@".scpt"]) {
				NSString *cmdl = [[file safeSubstringToIndex:([file length] - 5)] lowercaseString];
				
				if ([choices containsObject:cmdl] == NO) {
					[choices safeAddObject:cmdl];
				}
			}
		}
        
        resourceFiles = [_NSFileManager() contentsOfDirectoryAtPath:[Preferences whereScriptsLocalPath] error:NULL];
		
		for (NSString *file in resourceFiles) {
			if ([file hasSuffix:@".scpt"]) {
				NSString *cmdl = [[file safeSubstringToIndex:([file length] - 5)] lowercaseString];
				
				if ([choices containsObject:cmdl] == NO) {
					[choices safeAddObject:cmdl];
				}
			}
		}
        
		lowerChoices = choices;
	} else if (channelMode) {
		NSMutableArray *channels      = [NSMutableArray array];
		NSMutableArray *lowerChannels = [NSMutableArray array];
		
		IRCClient *u = [world selectedClient];
		
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
		[lowerNicks safeAddObject:@"nickserv"];
		
		[nicks      safeAddObject:@"RootServ"];
		[lowerNicks safeAddObject:@"rootserv"];
		
		[nicks      safeAddObject:@"OperServ"];
		[lowerNicks safeAddObject:@"operserv"];
		
		[nicks      safeAddObject:@"HostServ"];
		[lowerNicks safeAddObject:@"hostserv"];
		
		[nicks      safeAddObject:@"ChanServ"];
		[lowerNicks safeAddObject:@"chanserv"];
		
		[nicks      safeAddObject:@"MemoServ"];
		[lowerNicks safeAddObject:@"Memoserv"];
		
		choices      = nicks;
		lowerChoices = lowerNicks;
		
		[users drain];
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
	
	[[NSSpellChecker sharedSpellChecker] ignoreWord:t inSpellDocumentWithTag:[fieldEditor spellCheckerDocumentTag]];
	
	if ((commandMode || channelMode) || head == NO) {
		t = [t stringByAppendingString:@" "];
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
		
		status.text = text.stringValue;
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
		id sel = world.selected;
		if (PointerIsEmpty(sel)) return;
		
		NSInteger n = [tree rowForItem:sel];
		if (n < 0) return;
		
		NSInteger start = n;
		NSInteger count = [tree numberOfRows];
		
		if (count <= 1) return;
		
		while (1) {
			if (dir == MOVE_UP) {
				--n;
				
				if (n < 0) n = (count - 1);
			} else {
				++n;
				
				if (count <= n) n = 0;
			}
			
			if (n == start) break;
			
			id i = [tree itemAtRow:n];
			
			if (i) {
				if (target == MOVE_ACTIVE) {
					if ([i isClient] == NO && [i isActive]) {
						[world select:i];
						
						break;
					}
				} else if (target == MOVE_UNREAD) {
					if ([i isUnread]) {
						[world select:i];
						
						break;
					}
				} else {
					[world select:i];
					
					break;
				}
			}
		}
	} else if (dir == MOVE_LEFT || dir == MOVE_RIGHT) {
		IRCClient *client = [world selectedClient];
		if (PointerIsEmpty(client)) return;
		
		NSUInteger pos = [world.clients indexOfObjectIdenticalTo:client];
		if (pos == NSNotFound) return;
		
		NSInteger n = pos;
		NSInteger start = n;
		
		NSInteger count = world.clients.count;
		if (count <= 1) return;
		
		while (1) {
			if (dir == MOVE_LEFT) {
				--n;
				
				if (n < 0) n = (count - 1);
			} else {
				++n;
				
				if (count <= n) n = 0;
			}
			
			if (n == start) break;
			
			client = [world.clients safeObjectAtIndex:n];
			
			if (client) {
				if (target == MOVE_ACTIVE) {
					if (client.isLoggedIn) {
						id t = ((client.lastSelectedChannel) ?: (id)client);
						
						[world select:t];
						
						break;
					}
				} else {
					id t = ((client.lastSelectedChannel) ?: (id)client);
					
					[world select:t];
					
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
	[world selectPreviousItem];
}

- (void)selectNextSelection:(NSEvent *)e
{
	[self move:MOVE_DOWN target:MOVE_ALL];
}

- (void)tab:(NSEvent *)e
{
	switch ([Preferences tabAction]) {
		case TAB_COMPLETE_NICK:
			[self completeNick:YES];
			break;
		case TAB_UNREAD:
			[self move:MOVE_DOWN target:MOVE_UNREAD];
			break;
		default: break;
	}
}

- (void)shiftTab:(NSEvent *)e
{
	switch ([Preferences tabAction]) {
		case TAB_COMPLETE_NICK:
			[self completeNick:NO];
			break;
		case TAB_UNREAD:
			[self move:MOVE_UP target:MOVE_UNREAD];
			break;
		default: break;
	}
}

- (void)sendMsgAction:(NSEvent *)e
{
	[self sendText:IRCCI_ACTION];
}

- (void)inputHistoryUp:(NSEvent *)e
{
	NSAttributedString *s = [inputHistory up:[text attributedStringValue]];
	
	if (s) {
		[text setFilteredAttributedStringValue:s];
		
		[world focusInputText];
	}
}

- (void)inputHistoryDown:(NSEvent *)e
{
	NSAttributedString *s = [inputHistory down:[text attributedStringValue]];
	
	if (s) {
		[text setFilteredAttributedStringValue:s];
		
		[world focusInputText];
	}
}

- (void)textFormattingBold:(NSEvent *)e
{
	if ([formattingMenu boldSet]) {
		[formattingMenu removeBoldCharFromTextBox:nil];
	} else {
		[formattingMenu insertBoldCharIntoTextBox:nil];
	}
}

- (void)textFormattingItalic:(NSEvent *)e
{
	if ([formattingMenu italicSet]) {
		[formattingMenu removeItalicCharFromTextBox:nil];
	} else {
		[formattingMenu insertItalicCharIntoTextBox:nil];
	}
}

- (void)textFormattingUnderline:(NSEvent *)e
{
	if ([formattingMenu underlineSet]) {
		[formattingMenu removeUnderlineCharFromTextBox:nil];
	} else {
		[formattingMenu insertUnderlineCharIntoTextBox:nil];
	}
}

- (void)textFormattingForegroundColor:(NSEvent *)e
{
	if ([formattingMenu foregroundColorSet]) {
		[formattingMenu removeForegroundColorCharFromTextBox:nil];
	} else {
		NSRect fieldRect = [formattingMenu.textField frame];
		
		fieldRect.origin.y -= 200;
		fieldRect.origin.x += 100;
		
		[formattingMenu.foregroundColorMenu popUpMenuPositioningItem:nil
														  atLocation:fieldRect.origin
															  inView:[formattingMenu.textField currentEditor]];
	}
}

- (void)textFormattingBackgroundColor:(NSEvent *)e
{
	if ([formattingMenu foregroundColorSet]) {
		if ([formattingMenu backgroundColorSet]) {
			[formattingMenu removeForegroundColorCharFromTextBox:nil];
		} else {
			NSRect fieldRect = [formattingMenu.textField frame];
			
			fieldRect.origin.y -= 200;
			fieldRect.origin.x += 100;
			
			[formattingMenu.backgroundColorMenu popUpMenuPositioningItem:nil
															  atLocation:fieldRect.origin
																  inView:[formattingMenu.textField currentEditor]];
		}
	}
}

- (void)handler:(SEL)sel code:(NSInteger)keyCode mods:(NSUInteger)mods
{
	[window registerKeyHandler:sel key:keyCode modifiers:mods];
}

- (void)inputHandler:(SEL)sel code:(NSInteger)keyCode mods:(NSUInteger)mods
{
	[fieldEditor registerKeyHandler:sel key:keyCode modifiers:mods];
}

- (void)inputHandler:(SEL)sel char:(UniChar)c mods:(NSUInteger)mods
{
	[fieldEditor registerKeyHandler:sel character:c modifiers:mods];
}

- (void)handler:(SEL)sel char:(UniChar)c mods:(NSUInteger)mods
{
	[window registerKeyHandler:sel character:c modifiers:mods];
}

- (void)registerKeyHandlers
{
	[window setKeyHandlerTarget:self];
	[fieldEditor setKeyHandlerTarget:self];
	
	[self handler:@selector(tab:) code:KEY_TAB mods:0];
	[self handler:@selector(shiftTab:) code:KEY_TAB mods:NSShiftKeyMask];
	
	[self handler:@selector(sendMsgAction:) code:KEY_ENTER mods:NSCommandKeyMask];
	[self handler:@selector(sendMsgAction:) code:KEY_RETURN mods:NSCommandKeyMask];
	
	[self handler:@selector(textFormattingBold:) char:'b' mods:NSCommandKeyMask];
	[self handler:@selector(textFormattingItalic:) char:'i' mods:NSCommandKeyMask];
	[self handler:@selector(textFormattingUnderline:) char:'u' mods:NSCommandKeyMask];
    [self handler:@selector(textFormattingForegroundColor:) char:'c' mods:(NSCommandKeyMask | NSShiftKeyMask)];
	[self handler:@selector(textFormattingBackgroundColor:) char:'c' mods:(NSCommandKeyMask | NSShiftKeyMask | NSAlternateKeyMask)];
	
	[self handler:@selector(inputHistoryUp:) char:'p' mods:NSControlKeyMask];
	[self handler:@selector(inputHistoryDown:) char:'n' mods:NSControlKeyMask];

	[self inputHandler:@selector(inputHistoryUp:) code:KEY_UP mods:0];
	[self inputHandler:@selector(inputHistoryUp:) code:KEY_UP mods:NSAlternateKeyMask];
	
	[self inputHandler:@selector(inputHistoryDown:) code:KEY_DOWN mods:0];
	[self inputHandler:@selector(inputHistoryDown:) code:KEY_DOWN mods:NSAlternateKeyMask];
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
	
	[window makeKeyAndOrderFront:nil];
	
	IRCClientConfig *c = [[[IRCClientConfig alloc] initWithDictionary:dic] autodrain];
	IRCClient *u = [world createClient:c reload:YES];
	
	[world save];
	
	if (c.autoConnect) {
		[u connect];
	}
}

- (void)WelcomeSheetWillClose:(WelcomeSheet *)sender
{
	[WelcomeSheetDisplay drain];
	WelcomeSheetDisplay = nil;
}

@end