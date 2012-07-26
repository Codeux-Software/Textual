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

#define _WebMenuItemTagInspectElementLion			2024
#define _WebMenuItemTagInspectElementMountainLion	2025

#define _WebMenuItemTagIRCopServices	42354

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
			} else if ([item tag] == _WebMenuItemTagInspectElementLion ||
					   [item tag] == _WebMenuItemTagInspectElementMountainLion) {
			
				inspectElementItem = item;
			}
		}
		
		for (NSMenuItem *item in [self.menu itemArray]) {
			if ([item tag] == _WebMenuItemTagInspectElementLion ||
				[item tag] == _WebMenuItemTagInspectElementMountainLion) {

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