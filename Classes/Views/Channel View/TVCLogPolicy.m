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

#import "TVCLogObjectsPrivate.h"

/* The actual tag value for the Inspect Element item is in a private
 enum in WebKit so we have to define it based on whatever version of
 WebKit is on the OS. */
#define _WebMenuItemTagInspectElementLion			2024
#define _WebMenuItemTagInspectElementMountainLion	2025

#define _WebMenuItemTagSearchInGoogle		1601 // Tag for Textual's menu, not WebKit
#define _WebMenuItemTagLookUpDictionary		1608 // Tag for Textual's meny, not WebKit

@implementation TVCLogPolicy

- (id)constructContextMenuInWebView:(TVCLogView *)webView defaultMenuItems:(NSArray *)defaultMenuItems
{
	TVCLogController *logController = [webView logController];

	BOOL isWebKit2 = [webView isUsingWebKit2];

	id newMenu = nil;

	if (isWebKit2) {
		newMenu = [[NSMenu alloc] initWithTitle:@"Context Menu"];
	} else {
		newMenu = [NSMutableArray array];
	}

#define _addItem(_itemValue_)		if (isWebKit2) {						\
										[newMenu addItem:(_itemValue_)];	\
									} else {								\
										[newMenu addObject:(_itemValue_)];	\
									}

	if ([logController associatedChannel] == nil) {
		self.nickname = nil;
	}

	if (self.anchorURL)
	{
		NSMenu *urlMenu = [menuController() tcopyURLMenu];

		for (NSMenuItem *item in [urlMenu itemArray]) {
			NSMenuItem *newItem = [item copy];

			[newItem setUserInfo:self.anchorURL recursively:YES];

			_addItem(newItem)
		}

		self.anchorURL = nil;
	}
	else if (self.nickname)
	{
		NSMenu *memberMenu = [menuController() userControlMenu];

		for (NSMenuItem *item in [memberMenu itemArray]) {
			NSMenuItem *newItem = [item copy];

			[newItem setUserInfo:self.nickname recursively:YES];

			_addItem(newItem)
		}

		self.nickname = nil;
	}
	else if (self.channelName)
	{
		NSMenu *chanMenu = [menuController() joinChannelMenu];

		for (NSMenuItem *item in [chanMenu itemArray]) {
			NSMenuItem *newItem = [item copy];

			[newItem setUserInfo:self.channelName recursively:YES];

			_addItem(newItem)
		}

		self.channelName = nil;
	}
	else
	{
		NSMenu *menu = [menuController() channelViewMenu];

		NSMenuItem *inspectElementItem		= nil;
		NSMenuItem *lookupInDictionaryItem	= nil;

		if (isWebKit2 == NO) {
			for (NSMenuItem *item in defaultMenuItems) {
				if ([item tag] == WebMenuItemTagLookUpInDictionary) {
					lookupInDictionaryItem = item;
				} else if ([item tag] == _WebMenuItemTagInspectElementLion ||
						   [item tag] == _WebMenuItemTagInspectElementMountainLion)
				{
					inspectElementItem = item;
				}
			}
		}

		for (NSMenuItem *item in [menu itemArray]) {
			NSMenuItem *newItem = [item copy];

			if (isWebKit2 == NO) {
				if ([newItem tag] == _WebMenuItemTagLookUpDictionary) {
					continue;
				}
			}

			_addItem(newItem);

			if ([newItem tag] == _WebMenuItemTagSearchInGoogle) {
				if (lookupInDictionaryItem) {
					_addItem(lookupInDictionaryItem)
				}
			}
		}

		if ([RZUserDefaults() boolForKey:TXDeveloperEnvironmentToken]) {
			_addItem([NSMenuItem separatorItem])

			_addItem(
			 [NSMenuItem menuItemWithTitle:BLS(1018)
									target:menuController()
									action:@selector(copyLogAsHtml:)])

			_addItem(
			 [NSMenuItem menuItemWithTitle:BLS(1019)
									target:menuController()
									action:@selector(forceReloadTheme:)])

			if (isWebKit2) {
				_addItem(
				 [NSMenuItem menuItemWithTitle:BLS(1295)
										target:menuController()
										action:@selector(openWebInspector:)])
			} else {
				if (inspectElementItem) {
					_addItem(inspectElementItem)
				}
			}
		}
	}

	return newMenu;
}

- (void)displayContextMenuInWebView:(TVCLogView *)webView
{
	NSAssertReturn([webView isUsingWebKit2] == YES);

	NSMenu *newMenu = [self constructContextMenuInWebView:webView defaultMenuItems:nil];

	NSView *webViewBacking = [webView webView];

	NSWindow *webViewWindow = [webViewBacking window];

	NSPoint mouseLocationGlobal = [NSEvent mouseLocation];

	NSRect mouseLocationLocal =
	[webViewWindow convertRectFromScreen:NSMakeRect(mouseLocationGlobal.x, mouseLocationGlobal.y, 0, 0)];

	NSEvent *event = [NSEvent mouseEventWithType:NSRightMouseUp
										location:mouseLocationLocal.origin
								   modifierFlags:0
									   timestamp:0
									windowNumber:[webViewWindow windowNumber]
										 context:nil
									 eventNumber:0
									  clickCount:0
										pressure:0];

	[NSMenu popUpContextMenu:newMenu withEvent:event forView:webViewBacking];
}

#pragma mark -
#pragma mark WebKit Delegate

- (NSArray *)webView:(WebView *)sender contextMenuItemsForElement:(NSDictionary *)element defaultMenuItems:(NSArray *)defaultMenuItems
{
	return [self constructContextMenuInWebView:[self parentView] defaultMenuItems:defaultMenuItems];
}

- (void)webView:(WebView *)sender resource:(id)identifier didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge fromDataSource:(WebDataSource *)dataSource
{
	[[challenge sender] cancelAuthenticationChallenge:challenge];
}

- (NSUInteger)webView:(WebView *)webView dragDestinationActionMaskForDraggingInfo:(id<NSDraggingInfo>)draggingInfo
{
	NSPasteboard *pboard = [draggingInfo draggingPasteboard];

	if ([[pboard types] containsObject:NSFilenamesPboardType]) {
		return WebDragDestinationActionAny;
	}

	return WebDragDestinationActionNone;
}

- (void)webView:(WebView *)webView decidePolicyForNavigationAction:(NSDictionary *)actionInformation request:(NSURLRequest *)request frame:(WebFrame *)frame decisionListener:(id <WebPolicyDecisionListener>)listener
{
	NSInteger action = [actionInformation integerForKey:WebActionNavigationTypeKey];

	if (action == WebNavigationTypeLinkClicked) {
		[listener ignore];

		NSURL *actionURL = actionInformation[WebActionOriginalURLKey];

		[self openWebpage:actionURL];
	} else {
		[listener use];
	}
}

#pragma mark -
#pragma mark WebKit2 Delegate

- (void)webView:(WKWebView *)webView didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition disposition, NSURLCredential *credential))completionHandler
{
	NSString *authenticationMethod = [[challenge protectionSpace] authenticationMethod];

	if ([authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust]) {
		completionHandler(NSURLSessionAuthChallengePerformDefaultHandling, nil);
	} else {
		completionHandler(NSURLSessionAuthChallengeCancelAuthenticationChallenge, nil);
	}
}

- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler
{
	WKNavigationType action = [navigationAction navigationType];

	if (action == WKNavigationTypeLinkActivated) {
		decisionHandler(WKNavigationActionPolicyCancel);

		NSURL *actionURL = [[navigationAction request] URL];

		[self openWebpage:actionURL];
	} else {
		decisionHandler(WKNavigationActionPolicyAllow);
	}
}

#pragma mark -
#pragma mark Shared

- (void)channelNameDoubleClicked
{
	[menuController() joinClickedChannel:self.channelName];

	self.channelName = nil;
}

- (void)nicknameDoubleClicked
{
	[menuController() setPointedNickname:self.nickname];

	self.nickname = nil;

	[menuController() memberInChannelViewDoubleClicked:nil];
}

- (void)topicBarDoubleClicked
{
	[menuController() showChannelTopicDialog:nil];
}

- (void)openWebpage:(NSURL *)webpageURL
{
	if (NSObjectsAreEqual([webpageURL scheme], @"http") ||
		NSObjectsAreEqual([webpageURL scheme], @"https") ||
		NSObjectsAreEqual([webpageURL scheme], @"textual"))
	{
		[TLOpenLink open:webpageURL];

		return;
	}

	NSString *applicationName = [RZWorkspace() nameOfApplicationToOpenURL:webpageURL];

	BOOL openLink =
	[TLOPopupPrompts dialogWindowWithMessage:TXTLS(@"BasicLanguage[1290][2]", [webpageURL absoluteString])
									   title:TXTLS(@"BasicLanguage[1290][1]", applicationName)
							   defaultButton:TXTLS(@"BasicLanguage[1290][3]")
							 alternateButton:TXTLS(@"BasicLanguage[1009]")
							  suppressionKey:@"open_non_http_url_warning"
							 suppressionText:nil];

	if (openLink == NO) {
		return;
	}

	[TLOpenLink open:webpageURL];
}

@end
