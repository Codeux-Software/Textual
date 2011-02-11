// Created by Satoshi Nakagawa <psychs AT limechat DOT net> <http://github.com/psychs/limechat>
// Modifications by Codeux Software <support AT codeux DOT com> <https://github.com/codeux/Textual>
// You can redistribute it and/or modify it under the new BSD license.

#define WebMenuItemTagInspectElement	2024
#define WebMenuItemTagIRCopServices		42354

#define DeveloperEnvironmentToken		@"TextualDeveloperEnvironment"

@implementation LogPolicy

@synthesize menuController;
@synthesize menu;
@synthesize urlMenu;
@synthesize addrMenu;
@synthesize memberMenu;
@synthesize chanMenu;
@synthesize url;
@synthesize addr;
@synthesize nick;
@synthesize chan;

- (void)dealloc
{
	[url drain];
	[addr drain];
	[nick drain];
	[chan drain];
	[menu drain];
	[urlMenu drain];
	[addrMenu drain];
	[chanMenu drain];
	[memberMenu drain];
	
	[super dealloc];
}

- (void)webView:(WebView *)sender mouseDidMoveOverElement:(NSDictionary *)elementInformation modifierFlags:(NSUInteger)modifierFlags
{
	if ([Preferences copyOnSelect]) {
		if (([[NSApp currentEvent] modifierFlags] & NSCommandKeyMask) == NSCommandKeyMask) return;
		
		if ([[NSApp currentEvent] type] == NSLeftMouseUp) {
			DOMRange *range = [sender selectedDOMRange];
			
			if (PointerIsEmpty(range)) return;
			if ([(LogView *)sender hasSelection] == NO) return;
			
			[NSApp sendAction:@selector(copy:) to:[[NSApp mainWindow] firstResponder] from:self];
			
			[sender setSelectedDOMRange:nil affinity:NSSelectionAffinityUpstream];
		}
	}
}

- (NSUInteger)webView:(WebView *)sender dragDestinationActionMaskForDraggingInfo:(id)draggingInfo
{
	return WebDragDestinationActionNone;
}

- (NSArray *)webView:(WebView *)sender contextMenuItemsForElement:(NSDictionary *)element defaultMenuItems:(NSArray *)defaultMenuItems
{
	NSMutableArray *ary = [NSMutableArray array];
	
	if (url) {
		menuController.pointedUrl = url;
		
		[url autorelease];
		url = nil;
		
		for (NSMenuItem *item in [urlMenu itemArray]) {
			[ary safeAddObject:[[item copy] autorelease]];
		}
		
		return ary;
	} else if (addr) {
		menuController.pointedAddress = addr;
		
		[addr autorelease];
		addr = nil;
		
		for (NSMenuItem *item in [addrMenu itemArray]) {
			[ary safeAddObject:[[item copy] autorelease]];
		}
		
		return ary;
	} else if (nick) {
		menuController.pointedNick = nick;
		
		[nick autorelease];
		nick = nil;
		
		NSMenuItem *userOptions = [[NSMenuItem new] autorelease];
		
		[userOptions setTitle:TXTFLS(@"USER_OPTIONS_MENU_ITEM", menuController.pointedNick)];
		
		[ary safeAddObject:userOptions];
		[ary safeAddObject:[NSMenuItem separatorItem]];
		
		BOOL isIRCop = [[menuController.world selectedClient] IRCopStatus];
		
		for (NSMenuItem *item in [memberMenu itemArray]) {
			if ([item tag] == WebMenuItemTagIRCopServices && isIRCop == NO) continue;
			
			[ary safeAddObject:[[item copy] autorelease]];
		}
		
		return ary;
	} else if (chan) {
		menuController.pointedChannelName = chan;
		
		[chan autorelease];
		chan = nil;
		
		for (NSMenuItem *item in [chanMenu itemArray]) {
			[ary safeAddObject:[[item copy] autorelease]];
		}
		
		return ary;
	} else if (menu) {
		NSMenuItem *inspectElementItem = nil;
		NSMenuItem *lookupInDictionaryItem = nil;
		
		for (NSMenuItem *item in defaultMenuItems) {
			if ([item tag] == WebMenuItemTagLookUpInDictionary) {
				lookupInDictionaryItem = item;
			} else if ([item tag] == WebMenuItemTagInspectElement) {
				inspectElementItem = item;
			}
		}
		
		for (NSMenuItem *item in [menu itemArray]) {
			if ([item tag] == WebMenuItemTagInspectElement) {
				if (lookupInDictionaryItem) {
					[ary safeAddObject:[[lookupInDictionaryItem copy] autorelease]];
				}
			} else {
				[ary safeAddObject:[[item copy] autorelease]];
			}
		}
		
		if ([_NSUserDefaults() boolForKey:DeveloperEnvironmentToken]) {
			[ary safeAddObject:[NSMenuItem separatorItem]];
			
			if (inspectElementItem) {
				[ary safeAddObject:[[inspectElementItem copy] autorelease]];
			}
			
			NSMenuItem *copyHTML = [[[NSMenuItem alloc] initWithTitle:TXTLS(@"COPY_LOG_AS_HTML_MENU_ITEM") 
															   action:@selector(onCopyLogAsHtml:) keyEquivalent:@""] autorelease];
			
			NSMenuItem *reloadTheme = [[[NSMenuItem alloc] initWithTitle:TXTLS(@"FORCE_RELOAD_THEME_MENU_ITEM") 
																  action:@selector(onWantThemeForceReloaded:) keyEquivalent:@""] autorelease];
			
			[copyHTML setTarget:menuController];
			[reloadTheme setTarget:menuController];
		
			[ary safeAddObject:copyHTML];
			[ary safeAddObject:reloadTheme];
		}
		
		return ary;
	} else {
		return [NSArray array];
	}
	
	return defaultMenuItems;
}

- (void)webView:(WebView *)webView decidePolicyForNavigationAction:(NSDictionary *)actionInformation request:(NSURLRequest *)request frame:(WebFrame *)frame decisionListener:(id < WebPolicyDecisionListener >)listener
{
	NSInteger action = [[actionInformation objectForKey:WebActionNavigationTypeKey] integerValue];
	
	switch (action) {
		case WebNavigationTypeLinkClicked:
			[listener ignore];
			
			[URLOpener open:[actionInformation objectForKey:WebActionOriginalURLKey]];
			
			break;
		case WebNavigationTypeOther:
			[listener use];
			break;
		default:
			[listener ignore];
			break;
	}
}

@end