// Created by Satoshi Nakagawa <psychs AT limechat DOT net> <http://github.com/psychs/limechat>
// Modifications by Codeux Software <support AT codeux DOT com> <https://github.com/codeux/Textual>
// You can redistribute it and/or modify it under the new BSD license.
// Converted to ARC Support on June 07, 2012

#import "TextualApplication.h"

#define _WebMenuItemTagInspectElement	2024
#define _WebMenuItemTagIRCopServices		42354

@implementation TVCLogPolicy

- (void)webView:(WebView *)sender mouseDidMoveOverElement:(NSDictionary *)elementInformation
  modifierFlags:(NSUInteger)modifierFlags
{
	if ([TPCPreferences copyOnSelect]) {
		NSEvent *currentEvent = [NSApp currentEvent];
		
		if ((currentEvent.modifierFlags & NSCommandKeyMask) == NSCommandKeyMask) {
			return;
		}
		
		if (currentEvent.type == NSLeftMouseUp) {
			DOMRange *range = [sender selectedDOMRange];
			
			if (PointerIsEmpty(range)) return;
			if ([(id)sender hasSelection] == NO) return;
			
			[NSApp sendAction:@selector(copy:) to:[NSApp mainWindow].firstResponder from:self];
			
			[sender setSelectedDOMRange:nil affinity:NSSelectionAffinityUpstream];
		}
	}
}

- (NSUInteger)webView:(WebView *)sender dragDestinationActionMaskForDraggingInfo:(id)draggingInfo
{
	return WebDragDestinationActionNone;
}

- (void)channelDoubleClicked
{
	self.menuController.pointedChannelName = self.chan;
	self.chan = nil;
	
	[self.menuController joinClickedChannel:nil];
}

- (void)nicknameDoubleClicked
{
	self.menuController.pointedNick = self.nick;
	self.nick = nil;
	
	[self.menuController memberListDoubleClicked:nil];
}

- (NSArray *)webView:(WebView *)sender contextMenuItemsForElement:(NSDictionary *)element
	defaultMenuItems:(NSArray *)defaultMenuItems
{
	NSMutableArray *ary = [NSMutableArray array];
	
	if (self.url) {
		self.menuController.pointedUrl = self.url;
		self.url = nil;
		
		for (NSMenuItem *item in [self.urlMenu itemArray]) {
			[ary safeAddObject:[item copy]];
		}
		
		return ary;
	} else if (self.nick) {
		self.menuController.pointedNick = self.nick;
		self.nick = nil;
		
		BOOL isIRCop = self.menuController.world.selectedClient.IRCopStatus;
		
		for (NSMenuItem *item in [self.memberMenu itemArray]) {
			if ([item tag] == _WebMenuItemTagIRCopServices && isIRCop == NO) {
				continue;
			}
			
			[ary safeAddObject:[item copy]];
		}
		
		return ary;
	} else if (self.chan) {
		self.menuController.pointedChannelName = self.chan;
		self.chan = nil;
		
		for (NSMenuItem *item in [self.chanMenu itemArray]) {
			[ary safeAddObject:[item copy]];
		}
		
		return ary;
	} else if (self.menu) {
		NSMenuItem *inspectElementItem		= nil;
		NSMenuItem *lookupInDictionaryItem	= nil;
		
		for (NSMenuItem *item in defaultMenuItems) {
			if ([item tag] == WebMenuItemTagLookUpInDictionary) {
				lookupInDictionaryItem = item;
			} else if ([item tag] == _WebMenuItemTagInspectElement) {
				inspectElementItem = item;
			}
		}
		
		for (NSMenuItem *item in [self.menu itemArray]) {
			if ([item tag] == _WebMenuItemTagInspectElement) {
				if (lookupInDictionaryItem) {
					[ary safeAddObject:[lookupInDictionaryItem copy]];
				}
			} else {
				[ary safeAddObject:[item copy]];
			}
		}
		
		if ([_NSUserDefaults() boolForKey:TXDeveloperEnvironmentToken]) {
			[ary safeAddObject:[NSMenuItem separatorItem]];
			
			if (inspectElementItem) {
				[ary safeAddObject:[inspectElementItem copy]];
			}
			
			NSMenuItem *copyHTML = [[NSMenuItem alloc] initWithTitle:TXTLS(@"CopyLogAsHTMLMenuItem") 
															   action:@selector(copyLogAsHtml:) keyEquivalent:NSStringEmptyPlaceholder];
			
			NSMenuItem *reloadTheme = [[NSMenuItem alloc] initWithTitle:TXTLS(@"ForceReloadThemeMenuItem") 
																  action:@selector(forceReloadTheme:) keyEquivalent:NSStringEmptyPlaceholder];
			
			[copyHTML	 setTarget:self.menuController];
			[reloadTheme setTarget:self.menuController];
		
			[ary safeAddObject:copyHTML];
			[ary safeAddObject:reloadTheme];
		}
		
		return ary;
	} else {
		return @[];
	}
	
	return defaultMenuItems;
}

- (void)webView:(WebView *)webView decidePolicyForNavigationAction:(NSDictionary *)actionInformation
		request:(NSURLRequest *)request frame:(WebFrame *)frame decisionListener:(id < WebPolicyDecisionListener >)listener
{
	NSInteger action = [actionInformation integerForKey:WebActionNavigationTypeKey];
	
	switch (action) {
		case WebNavigationTypeLinkClicked:
			[listener ignore];
			
			[TLOpenLink open:actionInformation[WebActionOriginalURLKey]];
			
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