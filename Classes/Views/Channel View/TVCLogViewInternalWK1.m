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

#include <objc/message.h>

@interface TVCLogViewInternalWK1 ()
@property (nonatomic, readwrite, strong) TVCLogPolicy *webViewPolicy;
@property (nonatomic, readwrite, strong) TVCLogScriptEventSink *webViewScriptSink;
@end

static WebPreferences *_sharedWebViewPreferences = nil;

@implementation TVCLogViewInternalWK1

#pragma mark -
#pragma mark Factory

+ (void)initialize
{
	 _sharedWebViewPreferences = [[WebPreferences alloc] initWithIdentifier:@"TVCLogViewInternalWK1SharedWebPreferencesObject"];

	[_sharedWebViewPreferences setCacheModel:WebCacheModelDocumentViewer];
	[_sharedWebViewPreferences setUsesPageCache:NO];

	if ([_sharedWebViewPreferences respondsToSelector:@selector(setShouldRespectImageOrientation:)]) {
		(void)objc_msgSend(_sharedWebViewPreferences, @selector(setShouldRespectImageOrientation:), YES);
	}
}

- (instancetype)initWithHostView:(TVCLogView *)hostView
{
	if ((self = [self initWithFrame:NSZeroRect])) {
		[self constructWebViewWithHostView:hostView];

		return self;
	}

	return nil;
}

- (void)constructWebViewWithHostView:(TVCLogView *)hostView
{
	TVCLogScriptEventSink *webViewScriptSink = [TVCLogScriptEventSink new];
	[webViewScriptSink setParentView:hostView];

	TVCLogPolicy *webViewPolicy = [TVCLogPolicy new];
	[webViewPolicy setParentView:hostView];

	[self setT_parentView:hostView];

	[self setWebViewPolicy:webViewPolicy];
	[self setWebViewScriptSink:webViewScriptSink];

	[self setPreferences:_sharedWebViewPreferences];

	[self setTranslatesAutoresizingMaskIntoConstraints:NO];

	[self setCustomUserAgent:TVCLogViewCommonUserAgentString];

	[self setFrameLoadDelegate:self];
	[self setPolicyDelegate:self];
	[self setResourceLoadDelegate:self];
	[self setUIDelegate:self];

	[self setShouldUpdateWhileOffscreen:NO];

	[self updateBackgroundColor];
}

- (void)dealloc
{
	[self setFrameLoadDelegate:nil];
	[self setPolicyDelegate:nil];
	[self setResourceLoadDelegate:nil];
	[self setUIDelegate:nil];

	[self emptyCaches:nil];
}

#pragma mark -
#pragma mark View Events

- (void)keyDown:(NSEvent *)e
{
	if ([[self t_parentView] keyDown:e inView:self] == NO) {
		[super keyDown:e];
	}
}

- (BOOL)performDragOperation:(id <NSDraggingInfo>)sender
{
	return [[self t_parentView] performDragOperation:sender];
}

#pragma mark -
#pragma mark Utilities

- (void)emptyCaches:(void (^)(void))completionHandler
{
	if (completionHandler) {
		completionHandler();
	}
}

- (void)updateBackgroundColor
{
	NSColor *windowColor = [themeSettings() underlyingWindowColor];

	if (windowColor == nil) {
		windowColor = [NSColor blackColor];
	}

	[(id)self setBackgroundColor:windowColor];
}

- (void)maybeInformDelegateWebViewFinishedLoading
{
	if (self.t_viewHasLoaded && self.t_viewHasScriptObject) {
		[[self t_parentView] performSelector:@selector(informDelegateWebViewFinishedLoading) withObject:nil afterDelay:1.2];
	}
}

- (void)findString:(NSString *)searchString movingForward:(BOOL)movingForward
{
	[self searchFor:searchString direction:movingForward caseSensitive:NO wrap:YES];
}

#pragma mark -
#pragma mark View Configuration

- (BOOL)maintainsInactiveSelection
{
	return YES;
}

#pragma mark -
#pragma mark JavaScript

- (void)_t_evaluateJavaScript:(NSString *)code completionHandler:(void (^)(id))completionHandler
{
	WebScriptObject *scriptObject = [self windowScriptObject];

	if (scriptObject == nil || [scriptObject isKindOfClass:[WebUndefined class]]) {
		if (completionHandler) {
			completionHandler(nil);
		}
	}

	id scriptResult = [scriptObject evaluateWebScript:code];

	if (scriptResult) {
		if ([scriptResult isKindOfClass:[NSNull class]] ||
			[scriptResult isKindOfClass:[WebUndefined class]])
		{
			if (completionHandler) {
				completionHandler(nil);
			}
		}
		else if ([scriptResult isKindOfClass:[WebScriptObject class]])
		{
			scriptResult = [[self t_parentView] webScriptObjectToCommon:scriptResult];
		}
	}

	if (completionHandler) {
		completionHandler(scriptResult);
	}
}

#pragma mark -
#pragma mark Web View Delegate

- (NSArray *)webView:(WebView *)sender contextMenuItemsForElement:(NSDictionary *)element defaultMenuItems:(NSArray *)defaultMenuItems
{
	return [[self webViewPolicy] webView:sender contextMenuItemsForElement:element defaultMenuItems:defaultMenuItems];
}

- (NSUInteger)webView:(WebView *)webView dragDestinationActionMaskForDraggingInfo:(id<NSDraggingInfo>)draggingInfo
{
	return [[self webViewPolicy] webView:webView dragDestinationActionMaskForDraggingInfo:draggingInfo];
}

- (void)webView:(WebView *)webView decidePolicyForNavigationAction:(NSDictionary *)actionInformation request:(NSURLRequest *)request frame:(WebFrame *)frame decisionListener:(id <WebPolicyDecisionListener>)listener
{
	[[self webViewPolicy] webView:webView decidePolicyForNavigationAction:actionInformation request:request frame:frame decisionListener:listener];
}

- (void)webView:(WebView *)sender resource:(id)identifier didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge fromDataSource:(WebDataSource *)dataSource
{
	[[self webViewPolicy] webView:sender resource:identifier didReceiveAuthenticationChallenge:challenge fromDataSource:dataSource];
}

- (void)webView:(WebView *)webView didClearWindowObject:(WebScriptObject *)windowObject forFrame:(WebFrame *)frame
{
	NSAssertReturn(self == webView);

	self.t_viewHasScriptObject = YES;

	[windowObject setValue:[self webViewScriptSink] forKey:@"TextualScriptSink"];

	[self maybeInformDelegateWebViewFinishedLoading];
}

- (void)webView:(WebView *)webView didFinishLoadForFrame:(WebFrame *)frame
{
	NSAssertReturn(self == webView);

	self.t_viewHasLoaded = YES;

	[self maybeInformDelegateWebViewFinishedLoading];

	[self updateBackgroundColor];
}

@end
