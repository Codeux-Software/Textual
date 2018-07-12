/* *********************************************************************
 *                  _____         _               _
 *                 |_   _|____  _| |_ _   _  __ _| |
 *                   | |/ _ \ \/ / __| | | |/ _` | |
 *                   | |  __/>  <| |_| |_| | (_| | |
 *                   |_|\___/_/\_\\__|\__,_|\__,_|_|
 *
 * Copyright (c) 2008 - 2010 Satoshi Nakagawa <psychs AT limechat DOT net>
 * Copyright (c) 2010 - 2015 Codeux Software, LLC & respective contributors.
 *       Please see Acknowledgements.pdf for additional information.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *
 *  * Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 *  * Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 *  * Neither the name of Textual, "Codeux Software, LLC", nor the
 *    names of its contributors may be used to endorse or promote products
 *    derived from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE AUTHOR AND CONTRIBUTORS ``AS IS'' AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED. IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE LIABLE
 * FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
 * OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
 * LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
 * OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
 * SUCH DAMAGE.
 *
 *********************************************************************** */

#import "TXMasterController.h"
#import "TXMenuControllerPrivate.h"
#import "IRCChannel.h"
#import "TDCAlert.h"
#import "TLOLocalization.h"
#import "TLOpenLink.h"
#import "TPCPreferencesLocal.h"
#import "TPCThemeController.h"
#import "TVCLogController.h"
#import "TVCLogViewPrivate.h"
#import "TVCLogPolicyPrivate.h"

NS_ASSUME_NONNULL_BEGIN

/* Specific menu items are gathered and inserted at specific locations */
#define _WebKit1MenuItemTagInspectElement			2024
#define _WebKit1MenuItemTagLookupInDictionary		WebMenuItemTagLookUpInDictionary
#define _WebKit1MenuItemTagSearchWithGoogle			WebMenuItemTagSearchWeb

#define _WebKit2MenuItemTagInspectElement			57
#define _WebKit2MenuItemTagLookupInDictionary		22
#define _WebKit2MenuItemTagSearchWithGoogle			21

@implementation TVCLogPolicy

- (NSArray<NSMenuItem *> *)constructContextMenuItemsForWebView:(TVCLogView *)webView defaultMenuItems:(NSArray<NSMenuItem *> *)defaultMenuItems
{
	TVCLogController *viewController = webView.viewController;

	BOOL isWebKit2 = webView.isUsingWebKit2;

	NSMutableArray<NSMenuItem *> *menuItems = [NSMutableArray array];

	if (self.anchorURL)
	{
		NSMenu *urlMenu = menuController().channelViewURLMenu;

		for (NSMenuItem *item in urlMenu.itemArray) {
			NSMenuItem *newItem = [item copy];

			[newItem setUserInfo:self.anchorURL recursively:YES];

			[menuItems addObject:newItem];
		}

		self.anchorURL = nil;
	}
	else if (self.nickname)
	{
		if (viewController.associatedChannel == nil ||
			viewController.associatedChannel.isUtility)
		{
			NSMenuItem *noActionMenuItem =
			[[NSMenuItem alloc] initWithTitle:TXTLS(@"BasicLanguage[7kc-mo]")
									   action:nil
								keyEquivalent:@""];

			[menuItems addObject:noActionMenuItem];
		} else {
			NSMenu *memberMenu = menuController().userControlMenu;

			for (NSMenuItem *item in memberMenu.itemArray) {
				NSMenuItem *newItem = [item copy];

				[newItem setUserInfo:self.nickname recursively:YES];

				[menuItems addObject:newItem];
			}
		}

		self.nickname = nil;
	}
	else if (self.channelName)
	{
		NSMenu *chanMenu = menuController().channelViewChannelNameMenu;

		for (NSMenuItem *item in chanMenu.itemArray) {
			NSMenuItem *newItem = [item copy];

			[newItem setUserInfo:self.channelName recursively:YES];

			[menuItems addObject:newItem];
		}

		self.channelName = nil;
	}
	else
	{
		NSMenu *menu = menuController().channelViewGeneralMenu;

		NSMenuItem *inspectElementItem = nil;
		NSMenuItem *lookupInDictionaryItem = nil;
		NSMenuItem *searchWithGoogleItem = nil;

		for (NSMenuItem *item in defaultMenuItems) {
			if ((item.tag == _WebKit1MenuItemTagLookupInDictionary && isWebKit2 == NO) ||
				(item.tag == _WebKit2MenuItemTagLookupInDictionary && isWebKit2))
			{
				lookupInDictionaryItem = [item copy];
			} else if ((item.tag == _WebKit1MenuItemTagInspectElement && isWebKit2 == NO) ||
					   (item.tag == _WebKit2MenuItemTagInspectElement && isWebKit2))
			{
				inspectElementItem = [item copy];
			} else if ((item.tag == _WebKit1MenuItemTagSearchWithGoogle && isWebKit2 == NO) ||
					   (item.tag == _WebKit2MenuItemTagSearchWithGoogle && isWebKit2))
			{
				searchWithGoogleItem = [item copy];
			}
		}

		for (NSMenuItem *item in menu.itemArray) {
			NSMenuItem *newItem = [item copy];

			if (newItem.tag == MTWKGeneralSearchWithGoogle) {
				if (searchWithGoogleItem != nil) {
					[menuItems addObject:searchWithGoogleItem];

					continue;
				}
			} else if (newItem.tag == MTWKGeneralLookUpInDictionary) {
				if (lookupInDictionaryItem != nil) {
					[menuItems addObject:lookupInDictionaryItem];

					continue;
				}
			}

			[menuItems addObject:newItem];
		}

		if ([TPCPreferences developerModeEnabled]) {
			[menuItems addObject:[NSMenuItem separatorItem]];

			[menuItems addObject:
			 [NSMenuItem menuItemWithTitle:TXTLS(@"BasicLanguage[6cw-ni]")
									target:menuController()
									action:@selector(copyLogAsHtml:)]];

			[menuItems addObject:
			 [NSMenuItem menuItemWithTitle:TXTLS(@"BasicLanguage[ngd-ms]")
									target:menuController()
									action:@selector(forceReloadTheme:)]];

			if (inspectElementItem == nil) {
				if (isWebKit2) {
					[menuItems addObject:
					 [NSMenuItem menuItemWithTitle:TXTLS(@"BasicLanguage[tfj-m9]")
											target:menuController()
											action:@selector(openWebInspector:)]];
				}
			} else {
				[menuItems addObject:inspectElementItem];
			}
		}
	}

	return [menuItems copy];
}

- (NSMenu *)constructContextMenuForWebView:(TVCLogView *)webView withDefaultMenuItems:(NSArray<NSMenuItem *> *)defaultMenuItems
{
	NSMenu *contextMenu = [[NSMenu alloc] initWithTitle:TXLocalizationNotNeeded(@"Context Menu")];

	NSArray *menuItems = [self constructContextMenuItemsForWebView:webView defaultMenuItems:defaultMenuItems];

	for (NSMenuItem *menuItem in menuItems) {
		[contextMenu addItem:menuItem];
	}

	return contextMenu;
}

- (void)displayContextMenuInWebView:(TVCLogView *)webView
{
	if (webView.isUsingWebKit2 == NO) {
		return;
	}

	NSMenu *contextMenu = [self constructContextMenuForWebView:webView withDefaultMenuItems:@[]];

	NSView *webViewBacking = webView.webView;

	NSWindow *webViewWindow = webViewBacking.window;

	NSPoint mouseLocationGlobal = [NSEvent mouseLocation];

	NSRect mouseLocationLocal =
	[webViewWindow convertRectFromScreen:NSMakeRect(mouseLocationGlobal.x, mouseLocationGlobal.y, 0, 0)];

	NSEvent *event = [NSEvent mouseEventWithType:NSRightMouseUp
										location:mouseLocationLocal.origin
								   modifierFlags:0
									   timestamp:0
									windowNumber:webViewWindow.windowNumber
										 context:nil
									 eventNumber:0
									  clickCount:0
										pressure:0];

	[NSMenu popUpContextMenu:contextMenu withEvent:event forView:webViewBacking];
}

#pragma mark -
#pragma mark WebKit Delegate

- (NSArray<NSMenuItem *> *)webView1:(WebView *)webView logView:(TVCLogView *)logView contextMenuWithDefaultMenuItems:(NSArray *)defaultMenuItems
{
	return [self constructContextMenuItemsForWebView:logView defaultMenuItems:defaultMenuItems];
}

- (void)webView1:(WebView *)webView logView:(TVCLogView *)logView resource:(id)identifier didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge fromDataSource:(WebDataSource *)dataSource
{
	[challenge.sender cancelAuthenticationChallenge:challenge];
}

- (NSUInteger)webView1:(WebView *)webView logView:(TVCLogView *)logView dragDestinationActionMaskForDraggingInfo:(id<NSDraggingInfo>)draggingInfo
{
	NSPasteboard *pboard = [draggingInfo draggingPasteboard];

	if ([pboard.types containsObject:NSFilenamesPboardType]) {
		return WebDragDestinationActionAny;
	}

	return WebDragDestinationActionNone;
}

- (void)webView1:(WebView *)webView logView:(TVCLogView *)logView decidePolicyForNavigationAction:(NSDictionary *)actionInformation request:(NSURLRequest *)request frame:(WebFrame *)frame decisionListener:(id<WebPolicyDecisionListener>)listener
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

- (void)webView2:(WKWebView *)webView logView:(TVCLogView *)logView didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition, NSURLCredential * _Nonnull))completionHandler
{
	NSString *authenticationMethod = challenge.protectionSpace.authenticationMethod;

	if ([authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust]) {
		completionHandler(NSURLSessionAuthChallengePerformDefaultHandling, nil);
	} else {
		completionHandler(NSURLSessionAuthChallengeCancelAuthenticationChallenge, nil);
	}
}

- (void)webView2:(WKWebView *)webView logView:(TVCLogView *)logView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler
{
	WKNavigationType action = navigationAction.navigationType;

	if (action == WKNavigationTypeLinkActivated) {
		NSURL *actionURL = navigationAction.request.URL;

		decisionHandler(WKNavigationActionPolicyCancel);

		[self openWebpage:actionURL];
	} else {
		decisionHandler(WKNavigationActionPolicyAllow);
	}
}

- (NSMenu *)webView2:(WKWebView *)webView logView:(TVCLogView *)logView contextMenuWithDefaultMenu:(NSMenu *)defaultMenu
{
	return [self constructContextMenuForWebView:logView withDefaultMenuItems:defaultMenu.itemArray];
}

#pragma mark -
#pragma mark Shared

- (void)channelNameDoubleClicked
{
	[menuController() joinChannelClicked:self.channelName];

	self.channelName = nil;
}

- (void)nicknameDoubleClicked
{
	menuController().pointedNickname = self.nickname;

	[menuController() memberInChannelViewDoubleClicked:nil];

	self.nickname = nil;
}

- (void)topicBarDoubleClicked
{
	[menuController() showChannelModifyTopicSheet:nil];
}

- (void)openWebpage:(NSURL *)webpageURL
{
	NSParameterAssert(webpageURL != nil);

	BOOL openInBackground = [TPCPreferences openBrowserInBackground];

	NSUInteger keyboardKeys = ([NSEvent modifierFlags] & NSDeviceIndependentModifierFlagsMask);

	if ((keyboardKeys & NSCommandKeyMask) == NSCommandKeyMask) {
		openInBackground = !openInBackground;
	}

	if ([webpageURL.scheme isEqualToString:@"http"] ||
		[webpageURL.scheme isEqualToString:@"https"] ||
		[webpageURL.scheme isEqualToString:@"textual"])
	{
		[TLOpenLink open:webpageURL inBackground:openInBackground];

		return;
	}

	NSString *applicationName = [RZWorkspace() nameOfApplicationToOpenURL:webpageURL];

	BOOL openLink =
	[TDCAlert modalAlertWithMessage:TXTLS(@"Prompts[5oq-vv]", webpageURL.absoluteString)
							  title:TXTLS(@"Prompts[2ul-cl]", applicationName)
					  defaultButton:TXTLS(@"Prompts[mvh-ms]")
					alternateButton:TXTLS(@"Prompts[99q-gg]")
					 suppressionKey:@"open_non_http_url_warning"
					suppressionText:nil];

	if (openLink == NO) {
		return;
	}

	[TLOpenLink open:webpageURL inBackground:openInBackground];
}

@end

NS_ASSUME_NONNULL_END
