/* *********************************************************************
 *                  _____         _               _
 *                 |_   _|____  _| |_ _   _  __ _| |
 *                   | |/ _ \ \/ / __| | | |/ _` | |
 *                   | |  __/>  <| |_| |_| | (_| | |
 *                   |_|\___/_/\_\\__|\__,_|\__,_|_|
 *
 * Copyright (c) 2010 - 2016 Codeux Software, LLC & respective contributors.
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

#import "WKWebViewPrivate.h"

#include <objc/message.h>
#include <objc/runtime.h>

#import "IRCChannel.h"
#import "TPCPreferencesLocal.h"
#import "TVCLogController.h"
#import "TVCLogPolicyPrivate.h"
#import "TVCLogScriptEventSinkPrivate.h"
#import "TVCLogViewPrivate.h"
#import "TVCLogViewInternalWK2.h"

NS_ASSUME_NONNULL_BEGIN

#define _maximumProcessCount			8

@interface TVCLogViewInternalWK2 ()
@property (nonatomic, assign) BOOL t_observingLoadingProperty;
@end

@implementation TVCLogViewInternalWK2

static WKProcessPool *_sharedProcessPool = nil;
static WKUserContentController *_sharedUserContentController = nil;
static WKWebViewConfiguration *_sharedWebViewConfiguration = nil;
static TVCLogPolicy *_sharedWebPolicy = nil;
static TVCLogScriptEventSink *_sharedWebViewScriptSink = nil;

#pragma mark -
#pragma mark Factory

+ (void)_t_initialize
{
	static dispatch_once_t onceToken;

	dispatch_once(&onceToken, ^{
		[self constructProcessPool];

		_sharedWebViewConfiguration = [WKWebViewConfiguration new];

		_sharedWebViewConfiguration.processPool = _sharedProcessPool;

		BOOL runningOnSierra = TEXTUAL_RUNNING_ON_SIERRA;

		if (runningOnSierra) {
			_sharedWebViewConfiguration._allowUniversalAccessFromFileURLs = YES;
		}

		if (TEXTUAL_RUNNING_ON_ELCAPITAN) {
			WKPreferences *preferences = _sharedWebViewConfiguration.preferences;

			preferences._allowFileAccessFromFileURLs = YES;
			preferences._developerExtrasEnabled = YES;
		}

		_sharedWebViewScriptSink = [[TVCLogScriptEventSink alloc] initWithWebView:nil];

		_sharedUserContentController = [WKUserContentController new];

		[_sharedUserContentController addScriptMessageHandler:(id)_sharedWebViewScriptSink name:@"appearance"];
		[_sharedUserContentController addScriptMessageHandler:(id)_sharedWebViewScriptSink name:@"channelIsActive"];
		[_sharedUserContentController addScriptMessageHandler:(id)_sharedWebViewScriptSink name:@"channelMemberCount"];
		[_sharedUserContentController addScriptMessageHandler:(id)_sharedWebViewScriptSink name:@"channelName"];
		[_sharedUserContentController addScriptMessageHandler:(id)_sharedWebViewScriptSink name:@"channelNameDoubleClicked"];

		if (runningOnSierra == NO) {
			[_sharedUserContentController addScriptMessageHandler:(id)_sharedWebViewScriptSink name:@"displayContextMenu"];
		}

		[_sharedUserContentController addScriptMessageHandler:(id)_sharedWebViewScriptSink name:@"copySelectionWhenPermitted"];
		[_sharedUserContentController addScriptMessageHandler:(id)_sharedWebViewScriptSink name:@"encryptionAuthenticateUser"];
		[_sharedUserContentController addScriptMessageHandler:(id)_sharedWebViewScriptSink name:@"inlineMediaEnabledForView"];
		[_sharedUserContentController addScriptMessageHandler:(id)_sharedWebViewScriptSink name:@"loadInlineMedia"];
		[_sharedUserContentController addScriptMessageHandler:(id)_sharedWebViewScriptSink name:@"localUserHostmask"];
		[_sharedUserContentController addScriptMessageHandler:(id)_sharedWebViewScriptSink name:@"localUserNickname"];
		[_sharedUserContentController addScriptMessageHandler:(id)_sharedWebViewScriptSink name:@"logToConsole"];
		[_sharedUserContentController addScriptMessageHandler:(id)_sharedWebViewScriptSink name:@"networkName"];
		[_sharedUserContentController addScriptMessageHandler:(id)_sharedWebViewScriptSink name:@"nicknameColorStyleHash"];
		[_sharedUserContentController addScriptMessageHandler:(id)_sharedWebViewScriptSink name:@"nicknameDoubleClicked"];
		[_sharedUserContentController addScriptMessageHandler:(id)_sharedWebViewScriptSink name:@"notifyLinesAddedToView"];
		[_sharedUserContentController addScriptMessageHandler:(id)_sharedWebViewScriptSink name:@"notifyLinesRemovedFromView"];
		[_sharedUserContentController addScriptMessageHandler:(id)_sharedWebViewScriptSink name:@"notifyJumpToLineCallback"];
		[_sharedUserContentController addScriptMessageHandler:(id)_sharedWebViewScriptSink name:@"printDebugInformation"];
		[_sharedUserContentController addScriptMessageHandler:(id)_sharedWebViewScriptSink name:@"printDebugInformationToConsole"];
		[_sharedUserContentController addScriptMessageHandler:(id)_sharedWebViewScriptSink name:@"renderMessagesBefore"];
		[_sharedUserContentController addScriptMessageHandler:(id)_sharedWebViewScriptSink name:@"renderMessagesAfter"];
		[_sharedUserContentController addScriptMessageHandler:(id)_sharedWebViewScriptSink name:@"renderMessagesInRange"];
		[_sharedUserContentController addScriptMessageHandler:(id)_sharedWebViewScriptSink name:@"renderMessageWithSiblings"];
		[_sharedUserContentController addScriptMessageHandler:(id)_sharedWebViewScriptSink name:@"renderTemplate"];
		[_sharedUserContentController addScriptMessageHandler:(id)_sharedWebViewScriptSink name:@"retrievePreferencesWithMethodName"];
		[_sharedUserContentController addScriptMessageHandler:(id)_sharedWebViewScriptSink name:@"sendPluginPayload"];
		[_sharedUserContentController addScriptMessageHandler:(id)_sharedWebViewScriptSink name:@"serverAddress"];
		[_sharedUserContentController addScriptMessageHandler:(id)_sharedWebViewScriptSink name:@"serverChannelCount"];
		[_sharedUserContentController addScriptMessageHandler:(id)_sharedWebViewScriptSink name:@"serverIsConnected"];
		[_sharedUserContentController addScriptMessageHandler:(id)_sharedWebViewScriptSink name:@"setChannelName"];
		[_sharedUserContentController addScriptMessageHandler:(id)_sharedWebViewScriptSink name:@"setNickname"];
		[_sharedUserContentController addScriptMessageHandler:(id)_sharedWebViewScriptSink name:@"setSelection"];
		[_sharedUserContentController addScriptMessageHandler:(id)_sharedWebViewScriptSink name:@"setURLAddress"];

#if TEXTUAL_BUILT_FOR_APP_STORE_DISTRIBUTION == 1
		[_sharedUserContentController addScriptMessageHandler:(id)_sharedWebViewScriptSink name:@"showInAppPurchaseWindow"];
#endif

		[_sharedUserContentController addScriptMessageHandler:(id)_sharedWebViewScriptSink name:@"sidebarInversionIsEnabled"];
		[_sharedUserContentController addScriptMessageHandler:(id)_sharedWebViewScriptSink name:@"styleSettingsRetrieveValue"];
		[_sharedUserContentController addScriptMessageHandler:(id)_sharedWebViewScriptSink name:@"styleSettingsSetValue"];
		[_sharedUserContentController addScriptMessageHandler:(id)_sharedWebViewScriptSink name:@"topicBarDoubleClicked"];
		[_sharedUserContentController addScriptMessageHandler:(id)_sharedWebViewScriptSink name:@"finishedLayingOutView"];

		_sharedWebViewConfiguration.userContentController = _sharedUserContentController;

		_sharedWebPolicy = [TVCLogPolicy new];
	});
}

+ (void)constructProcessPool
{
	/* What we are doing here is very dirty which means it is probably a good idea
	 that we go above and beyond for error checking incase this stuff is changed. */
	WKProcessPool *sharedProcessPool = [WKProcessPool alloc];

	if ([TPCPreferences webKit2ProcessPoolSizeLimited] == NO) {
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

- (instancetype)initWithHostView:(TVCLogView *)hostView
{
	[self.class _t_initialize];

	if ((self = [self initWithFrame:NSZeroRect configuration:_sharedWebViewConfiguration])) {
		[self constructWebViewWithHostView:hostView];

		return self;
	}

	return nil;
}

- (void)constructWebViewWithHostView:(TVCLogView *)hostView
{
	NSParameterAssert(hostView != nil);

	self.t_parentView = hostView;

	self.allowsBackForwardNavigationGestures = NO;
	self.allowsMagnification = NO;

	self.translatesAutoresizingMaskIntoConstraints = NO;

	if (TEXTUAL_RUNNING_ON_ELCAPITAN) {
		self.allowsLinkPreview = [TPCPreferences webKit2PreviewLinks];

		self.customUserAgent = TVCLogViewCommonUserAgentString;
	}

	self.navigationDelegate = (id)self;

	self.UIDelegate = (id)self;
}

- (void)dealloc
{
	self.navigationDelegate = nil;

	self.UIDelegate = nil;
}

- (TVCLogPolicy *)webViewPolicy
{
	return _sharedWebPolicy;
}

#pragma mark -
#pragma mark Load Overrides

- (nullable WKNavigation *)loadFileURL:(NSURL *)URL allowingReadAccessToURL:(NSURL *)readAccessURL
{
	[self startObservingLoadingProperty];

	return [super loadFileURL:URL allowingReadAccessToURL:readAccessURL];
}

- (nullable WKNavigation *)loadHTMLString:(NSString *)string baseURL:(nullable NSURL *)baseURL
{
	[self startObservingLoadingProperty];

	return [super loadHTMLString:string baseURL:baseURL];
}

- (void)stopLoading
{
	[self stopObservingLoadingProperty];

	[super stopLoading];
}

#pragma mark -
#pragma mark View Events

- (void)keyDown:(NSEvent *)e
{
	if ([self.t_parentView keyDown:e inView:self]) {
		return;
	}

	[super keyDown:e];
}

- (BOOL)performDragOperation:(id <NSDraggingInfo>)sender
{
	return [self.t_parentView performDragOperation:sender];
}

#pragma mark -
#pragma mark Utilities

+ (void)emptyCaches
{
	[self.class emptyCaches:nil];
}

+ (void)emptyCaches:(void (^ _Nullable)(void))completionHandler
{
	WKWebsiteDataStore *wk2WebsiteDataStore = _sharedWebViewConfiguration.websiteDataStore;

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

	if (completionHandler) {
		XRPerformBlockAsynchronouslyOnMainQueue(completionHandler);
	}
}

- (void)findString:(NSString *)searchString movingForward:(BOOL)movingForward
{
	NSParameterAssert(searchString != nil);

	_WKFindOptions findOptions = (_WKFindOptionsCaseInsensitive	| _WKFindOptionsShowOverlay	| _WKFindOptionsShowFindIndicator | _WKFindOptionsWrapAround);

	if (movingForward == NO) {
		findOptions |= _WKFindOptionsBackwards;
	}

	if ([self respondsToSelector:@selector(_findString:options:maxCount:)]) {
		(void)objc_msgSend(self, @selector(_findString:options:maxCount:), searchString, findOptions, 1);
	}
}

- (void)startObservingLoadingProperty
{
	if (self.t_observingLoadingProperty) {
		return;
	}

	[self addObserver:self forKeyPath:@"loading" options:NSKeyValueObservingOptionNew context:NULL];

	self.t_observingLoadingProperty = YES;
}

- (void)stopObservingLoadingProperty
{
	if (self.t_observingLoadingProperty == NO) {
		return;
	}

	[self removeObserver:self forKeyPath:@"loading"];

	self.t_observingLoadingProperty = NO;
}

- (void)maybeInformDelegateWebViewFinishedLoading
{
	if (self.t_viewIsLoading == NO && self.t_viewIsNavigating == NO) {
		[self stopObservingLoadingProperty];

		[self.t_parentView performSelectorInCommonModes:@selector(informDelegateWebViewFinishedLoading) withObject:nil afterDelay:1.2];
	}
}

- (void)webViewClosedUnexpectedly
{
	[self.t_parentView informDelegateWebViewClosedUnexpectedly];
}

#pragma mark -
#pragma mark View Configuration

- (BOOL)maintainsInactiveSelection
{
	return YES;
}

#pragma mark -
#pragma mark JavaScript

- (void)logEvaluateJavaScriptError:(NSError *)error
{
	NSParameterAssert(error != nil);

	NSNumber *lineNumber = error.userInfo[@"WKJavaScriptExceptionLineNumber"];
	NSString *errorMessage = error.userInfo[@"WKJavaScriptExceptionMessage"];
	NSURL *sourceURL = error.userInfo[@"WKJavaScriptExceptionSourceURL"];

	NSString *channelName = self.t_parentView.viewController.associatedChannel.name;

	if (channelName == nil) {
		channelName = @"Server Console";
	}

	if (lineNumber == nil || errorMessage == nil || sourceURL == nil) {
		LogToConsoleError("JavaScript Error in %@: %@", channelName, error.localizedDescription);

		return;
	}

	LogToConsoleError("A JavaScript error occurred in %@ on line %ld of %@: %@",
		  channelName, lineNumber.unsignedIntegerValue, sourceURL.path, errorMessage);
}

- (void)_t_evaluateJavaScript:(NSString *)code completionHandler:(void (^ _Nullable)(id _Nullable))completionHandler
{
	NSParameterAssert(code != nil);

	[self evaluateJavaScript:code completionHandler:^(id result, NSError *error) {
		if (error) {
			[self logEvaluateJavaScriptError:error];
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
#pragma mark Scroll View

- (void)enableOffScreenUpdates
{

}

- (void)disableOffScreenUpdates
{

}

- (void)redrawViewIfNeeded
{

}

- (void)redrawView
{

}

- (void)resetScrollerPosition
{

}

- (void)resetScrollerPositionTo:(BOOL)scrolledToBottom
{

}

- (void)saveScrollerPosition
{

}

- (void)restoreScrollerPosition
{

}

- (void)setAutomaticScrollingEnabled:(BOOL)automaticScrollingEnabled
{

}

#pragma mark -
#pragma mark Web View Delegate

- (void)webViewWebContentProcessDidTerminate:(WKWebView *)webView
{
	NSParameterAssert(webView == self);

	[self webViewClosedUnexpectedly];
}

- (void)observeValueForKeyPath:(nullable NSString *)keyPath ofObject:(nullable id)object change:(nullable NSDictionary<NSString *, id> *)change context:(nullable void *)context
{
	NSParameterAssert(object == self);

	if ([keyPath isEqualToString:@"loading"]) {
		self.t_viewIsLoading = self.loading;

		[self maybeInformDelegateWebViewFinishedLoading];
	}
}

- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler
{
	NSParameterAssert(webView == self);

	[_sharedWebPolicy webView2:webView logView:self.t_parentView decidePolicyForNavigationAction:navigationAction decisionHandler:decisionHandler];
}

- (void)webView:(WKWebView *)webView didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition, NSURLCredential *))completionHandler
{
	NSParameterAssert(webView == self);

	[_sharedWebPolicy webView2:webView logView:self.t_parentView didReceiveAuthenticationChallenge:challenge completionHandler:completionHandler];
}

- (void)webView:(WKWebView *)webView didStartProvisionalNavigation:(WKNavigation *)navigation
{
	NSParameterAssert(webView == self);

	self.t_viewIsNavigating = YES;
}

- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation
{
	NSParameterAssert(webView == self);

	self.t_viewIsNavigating = NO;

	[self maybeInformDelegateWebViewFinishedLoading];
}

- (NSMenu *)_webView:(WKWebView *)webView contextMenu:(NSMenu *)menu forElement:(id)element
{
	NSParameterAssert(webView == self);

	return [_sharedWebPolicy webView2:webView logView:self.t_parentView contextMenuWithDefaultMenu:menu];
}

@end

#pragma mark -
#pragma mark WKView Swizzle

/* I am not proud of this, but you have to admit, WebKit2 API is very limited... */
@implementation NSView (WKiewSwizzle)

+ (void)load
{
	if (TEXTUAL_RUNNING_ON_YOSEMITE == NO) {
		return;
	}

	static dispatch_once_t onceToken;

	dispatch_once(&onceToken, ^{
		XRExchangeInstanceMethod(@"WKView", @"performDragOperation:", @"__t_priv_performDragOperation:");
	});
}

- (BOOL)__t_priv_performDragOperation:(id <NSDraggingInfo>)sender
{
	/* Override drag and drop to allow files to be sent to a user instead
	 of WebKit thinking that it should load the file as a resource. */
	NSView *superview = self.superview;

	if ([superview respondsToSelector:@selector(performDragOperation:)]) {
		return [superview performDragOperation:sender];
	}

	return [self __t_priv_performDragOperation:sender];
}

@end

NS_ASSUME_NONNULL_END
