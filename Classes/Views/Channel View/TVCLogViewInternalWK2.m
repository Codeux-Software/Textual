/* ********************************************************************* 
                  _____         _               _
                 |_   _|____  _| |_ _   _  __ _| |
                   | |/ _ \ \/ / __| | | |/ _` | |
                   | |  __/>  <| |_| |_| | (_| | |
                   |_|\___/_/\_\\__|\__,_|\__,_|_|

 Copyright (c) 2010 - 2016 Codeux Software, LLC & respective contributors.
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

#import "TVCLogObjectsPrivate.h"

#import "WKWebViewPrivate.h"

#include <objc/message.h>
#include <objc/runtime.h>

#define _maximumProcessCount			15

@implementation TVCLogViewInternalWK2

static WKWebViewConfiguration *_sharedWebViewConfiguration = nil;
static WKUserContentController *_sharedUserContentController = nil;
static WKProcessPool *_sharedProcessPool = nil;
static TVCLogScriptEventSink *_sharedWebViewScriptSink = nil;
static TVCLogPolicy *_sharedWebPolicy = nil;

#pragma mark -
#pragma mark Factory

+ (void)initialize
{
	NSAssertReturn([XRSystemInformation isUsingOSXYosemiteOrLater]);

	static dispatch_once_t onceToken;

	dispatch_once(&onceToken, ^{
		[TVCLogViewInternalWK2 constructProcessPool];

		_sharedWebViewConfiguration = [WKWebViewConfiguration new];

		[_sharedWebViewConfiguration setProcessPool:_sharedProcessPool];

		[[_sharedWebViewConfiguration preferences] setValue:@(YES) forKey:@"developerExtrasEnabled"];

		_sharedWebViewScriptSink = [TVCLogScriptEventSink new];

		_sharedUserContentController = [WKUserContentController new];

		[_sharedUserContentController addScriptMessageHandler:_sharedWebViewScriptSink name:@"channelIsJoined"];
		[_sharedUserContentController addScriptMessageHandler:_sharedWebViewScriptSink name:@"channelMemberCount"];
		[_sharedUserContentController addScriptMessageHandler:_sharedWebViewScriptSink name:@"channelName"];
		[_sharedUserContentController addScriptMessageHandler:_sharedWebViewScriptSink name:@"channelNameDoubleClicked"];
		[_sharedUserContentController addScriptMessageHandler:_sharedWebViewScriptSink name:@"displayContextMenu"];
		[_sharedUserContentController addScriptMessageHandler:_sharedWebViewScriptSink name:@"copySelectionWhenPermitted"];
		[_sharedUserContentController addScriptMessageHandler:_sharedWebViewScriptSink name:@"inlineImagesEnabledForView"];
		[_sharedUserContentController addScriptMessageHandler:_sharedWebViewScriptSink name:@"localUserHostmask"];
		[_sharedUserContentController addScriptMessageHandler:_sharedWebViewScriptSink name:@"localUserNickname"];
		[_sharedUserContentController addScriptMessageHandler:_sharedWebViewScriptSink name:@"logToConsole"];
		[_sharedUserContentController addScriptMessageHandler:_sharedWebViewScriptSink name:@"logToConsoleFile"];
		[_sharedUserContentController addScriptMessageHandler:_sharedWebViewScriptSink name:@"networkName"];
		[_sharedUserContentController addScriptMessageHandler:_sharedWebViewScriptSink name:@"nicknameColorStyleHash"];
		[_sharedUserContentController addScriptMessageHandler:_sharedWebViewScriptSink name:@"nicknameDoubleClicked"];
		[_sharedUserContentController addScriptMessageHandler:_sharedWebViewScriptSink name:@"printDebugInformation"];
		[_sharedUserContentController addScriptMessageHandler:_sharedWebViewScriptSink name:@"printDebugInformationToConsole"];
		[_sharedUserContentController addScriptMessageHandler:_sharedWebViewScriptSink name:@"retrievePreferencesWithMethodName"];
		[_sharedUserContentController addScriptMessageHandler:_sharedWebViewScriptSink name:@"serverAddress"];
		[_sharedUserContentController addScriptMessageHandler:_sharedWebViewScriptSink name:@"serverChannelCount"];
		[_sharedUserContentController addScriptMessageHandler:_sharedWebViewScriptSink name:@"serverIsConnected"];
		[_sharedUserContentController addScriptMessageHandler:_sharedWebViewScriptSink name:@"setChannelName"];
		[_sharedUserContentController addScriptMessageHandler:_sharedWebViewScriptSink name:@"setNickname"];
		[_sharedUserContentController addScriptMessageHandler:_sharedWebViewScriptSink name:@"setSelection"];
		[_sharedUserContentController addScriptMessageHandler:_sharedWebViewScriptSink name:@"setURLAddress"];
		[_sharedUserContentController addScriptMessageHandler:_sharedWebViewScriptSink name:@"sidebarInversionIsEnabled"];
		[_sharedUserContentController addScriptMessageHandler:_sharedWebViewScriptSink name:@"styleSettingsRetrieveValue"];
		[_sharedUserContentController addScriptMessageHandler:_sharedWebViewScriptSink name:@"styleSettingsSetValue"];
		[_sharedUserContentController addScriptMessageHandler:_sharedWebViewScriptSink name:@"topicBarDoubleClicked"];

		[_sharedWebViewConfiguration setUserContentController:_sharedUserContentController];

		_sharedWebPolicy = [TVCLogPolicy new];
	});
}

+ (void)constructProcessPool
{
	/* What we are doing here is very dirty which means it is probably a good idea
	 that we go above and beyond for error checking incase this stuff is changed. */
	WKProcessPool *sharedProcessPool = [WKProcessPool alloc];

	if ([RZUserDefaults() boolForKey:@"WKProcessPoolSizeIsLimited"] == NO) {
		goto create_normal_pool;
	}

	if ([sharedProcessPool respondsToSelector:@selector(_initWithConfiguration:)] == NO) {
		goto create_normal_pool;
	}

	Class processPoolConfigurationClass = objc_getClass("_WKProcessPoolConfiguration");

	if (processPoolConfigurationClass) {
		id processPoolConfiguration = [processPoolConfigurationClass new];

		if (processPoolConfiguration == nil) {
			goto create_normal_pool;
		} else if ([processPoolConfiguration respondsToSelector:@selector(setMaximumProcessCount:)] == NO) {
			goto create_normal_pool;
		}

		[processPoolConfiguration setMaximumProcessCount:_maximumProcessCount];

		_sharedProcessPool = [sharedProcessPool _initWithConfiguration:processPoolConfiguration];

		return;
	}

create_normal_pool:
	_sharedProcessPool = [sharedProcessPool init];
}

+ (instancetype)createNewInstanceWithHostView:(TVCLogView *)hostView
{
	TVCLogViewInternalWK2 *webView = [[TVCLogViewInternalWK2 alloc] initWithFrame:NSZeroRect configuration:_sharedWebViewConfiguration];

	[webView setT_parentView:hostView];

	[webView setAllowsBackForwardNavigationGestures:NO];
	[webView setAllowsMagnification:YES];

	[webView setTranslatesAutoresizingMaskIntoConstraints:NO];

	if ([XRSystemInformation isUsingOSXElCapitanOrLater]) {
		[webView setAllowsLinkPreview:YES];

		[webView setCustomUserAgent:TVCLogViewCommonUserAgentString];
	}

	[webView setNavigationDelegate:webView];

	[webView setUIDelegate:webView];

	[webView addObserver:webView forKeyPath:@"loading" options:NSKeyValueObservingOptionNew context:NULL];

	return webView;
}

- (void)dealloc
{
	[self removeObserver:self forKeyPath:@"loading"];

	[self setNavigationDelegate:nil];

	[self setUIDelegate:nil];
}

- (TVCLogPolicy *)webViewPolicy
{
	return _sharedWebPolicy;
}

#pragma mark -
#pragma mark View Events

- (void)keyDown:(NSEvent *)e
{
	[[self t_parentView] keyDown:e inView:self];
}

- (BOOL)performDragOperation:(id <NSDraggingInfo>)sender
{
	return [[self t_parentView] performDragOperation:sender];
}

#pragma mark -
#pragma mark Utilities

- (void)emptyCaches:(void (^)(void))completionHandler
{
	if ([XRSystemInformation isUsingOSXElCapitanOrLater]) {
		WKWebsiteDataStore *wk2WebsiteDataStore = [_sharedWebViewConfiguration websiteDataStore];

		if ( wk2WebsiteDataStore) {
			NSSet *itemsToRemove = [NSSet setWithArray:@[
				WKWebsiteDataTypeDiskCache,
				WKWebsiteDataTypeMemoryCache
			]];

			[wk2WebsiteDataStore removeDataOfTypes:itemsToRemove
									 modifiedSince:[NSDate distantPast]
								 completionHandler:completionHandler];

			return;
		}
	}

	if (completionHandler) {
		completionHandler();
	}
}

- (void)openWebInspector
{
	WKView *webViewParent = (id)[self subviews][0];

	WKPageRef pageRef = [webViewParent pageRef];

	WKInspectorRef inspectorRef = WKPageGetInspector(pageRef);

	WKInspectorShow(inspectorRef);
}

- (void)findString:(NSString *)searchString movingForward:(BOOL)movingForward
{
	_WKFindOptions findOptions = (_WKFindOptionsCaseInsensitive	| _WKFindOptionsShowOverlay	| _WKFindOptionsShowFindIndicator | _WKFindOptionsWrapAround);

	if (movingForward == NO) {
		findOptions |= _WKFindOptionsBackwards;
	}

	if ([self respondsToSelector:@selector(_findString:options:maxCount:)]) {
		(void)objc_msgSend(self, @selector(_findString:options:maxCount:), searchString, findOptions, 1);
	}
}

- (void)maybeInformDelegateWebViewFinishedLoading
{
	if (self.t_viewIsLoading == NO && self.t_viewIsNavigating == NO) {
		[[self t_parentView] performSelector:@selector(informDelegateWebViewFinishedLoading) withObject:nil afterDelay:1.2];
	}
}

- (void)webViewClosedUnexpectedly
{
	[[self t_parentView] informDelegateWebViewClosedUnexpectedly];
}

#pragma mark -
#pragma mark View Configuration

- (BOOL)maintainsInactiveSelection
{
	return YES;
}

#pragma mark -
#pragma mark JavaScript

- (void)executeJavaScript:(NSString *)code completionHandler:(void (^)(id))completionHandler
{
	[self evaluateJavaScript:code completionHandler:^(id result, NSError *error) {
		if (error) {
			LogToConsole(@"Error: %@", [error localizedDescription]);
		}

		if (result) {
			if ([result isKindOfClass:[NSNull class]] ||
				[result isKindOfClass:[WebUndefined class]])
			{
				if (completionHandler) {
					completionHandler(nil);
				}
			}
		}

		if (completionHandler) {
			completionHandler(result);
		}
	}];
}

#pragma mark -
#pragma mark Web View Delegate

- (void)webViewWebContentProcessDidTerminate:(WKWebView *)webView
{
	NSAssertReturn(self == webView);

	[self webViewClosedUnexpectedly];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context
{
	NSAssertReturn(self == object);

	if ([keyPath isEqualToString:@"loading"]) {
		self.t_viewIsLoading = [self isLoading];

		[self maybeInformDelegateWebViewFinishedLoading];
	}
}

- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler
{
	[_sharedWebPolicy webView:webView decidePolicyForNavigationAction:navigationAction decisionHandler:decisionHandler];
}

- (void)webView:(WKWebView *)webView didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition, NSURLCredential *))completionHandler
{
	[_sharedWebPolicy webView:webView didReceiveAuthenticationChallenge:challenge completionHandler:completionHandler];
}

- (void)webView:(WKWebView *)webView didStartProvisionalNavigation:(WKNavigation *)navigation
{
	NSAssertReturn(self == webView);

	self.t_viewIsNavigating = YES;
}

- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation
{
	NSAssertReturn(self == webView);

	self.t_viewIsNavigating = NO;

	[self maybeInformDelegateWebViewFinishedLoading];
}

@end

#pragma mark -
#pragma mark WKView Swizzle

/* I am not proud of this, but you have to admit, WebKit2 API is very limited... */
@implementation NSView (WKiewSwizzle)

+ (void)load
{
	NSAssertReturn([XRSystemInformation isUsingOSXYosemiteOrLater]);

	static dispatch_once_t onceToken;

	dispatch_once(&onceToken, ^{
		XRExchangeImplementation(@"WKView", @"updateLayer", @"__t_priv_updateLayer");

		XRExchangeImplementation(@"WKView", @"performDragOperation:", @"__t_priv_performDragOperation:");
	});
}

- (BOOL)__t_priv_performDragOperation:(id <NSDraggingInfo>)sender
{
	/* Override drag and drop to allow files to be sent to a user instead
	 of WebKit thinking that it should load the file as a resource. */
	NSView *superview = [self superview];

	if ([superview respondsToSelector:@selector(performDragOperation:)]) {
		return [superview performDragOperation:sender];
	}

	return NO;
}

- (void)__t_priv_updateLayer
{
	/* Set the style defined background color for the layer. */
	NSColor *windowColor = [themeSettings() underlyingWindowColor];

	if (windowColor == nil) {
		windowColor = [NSColor blackColor];
	}

	[[self layer] setBackgroundColor:[windowColor CGColor]];
}

@end
