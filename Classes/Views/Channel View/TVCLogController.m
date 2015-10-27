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

#import "THOPluginProtocolPrivate.h"

#import <objc/objc-runtime.h>

@interface TVCLogController ()
@property (nonatomic, assign) BOOL historyLoaded;
@property (nonatomic, assign) BOOL windowScriptObjectLoaded;
@property (nonatomic, assign) BOOL windowFrameObjectLoaded;
@property (nonatomic, assign) BOOL wasViewingBottomBeforeBecomingHidden;
@property (nonatomic, copy) NSString *lastVisitedHighlight;
@property (nonatomic, strong) TVCLogScriptEventSink *webViewScriptSink;
@property (nonatomic, strong) TVCWebViewAutoScroll *webViewAutoScroller;
@property (nonatomic, strong) TVCLogControllerHistoricLogFile *historicLogFile;
@property (nonatomic, assign) BOOL needsLimitNumberOfLines;
@property (nonatomic, assign) NSInteger activeLineCount;
@property (strong) NSMutableArray *highlightedLineNumbers;
@end

NSString * const TVCLogControllerViewFinishedLoadingNotification = @"TVCLogControllerViewFinishedLoadingNotification";

@implementation TVCLogController

#pragma mark -
#pragma mark Initialization

- (instancetype)init
{
	if ((self = [super init])) {
		self.highlightedLineNumbers	= [NSMutableArray new];
		
		self.lastVisitedHighlight = nil;
		
		self.activeLineCount = 0;

		self.isLoaded = NO;

		self.reloadingBacklog = NO;
		self.reloadingHistory = NO;

		self.windowFrameObjectLoaded = NO;
		self.windowScriptObjectLoaded = NO;
		
		self.needsLimitNumberOfLines = NO;

		self.maximumLineCount = 300;

		self.wasViewingBottomBeforeBecomingHidden = YES;
	}

	return self;
}

- (void)prepareForApplicationTermination
{
	[[self printingQueue] cancelOperationsForViewController:self];
	
	[self closeHistoricLog:NO];
}

- (void)prepareForPermanentDestruction
{
	[[self printingQueue] cancelOperationsForViewController:self];
	
	[self closeHistoricLog:YES]; // YES forces a file deletion.
}

- (void)preferencesChanged
{
	[self setMaximumLineCount:[TPCPreferences scrollbackLimit]];
}

- (void)dealloc
{
	[self.webView setKeyDelegate:nil];
	[self.webView setDraggingDelegate:nil];
	[self.webView setFrameLoadDelegate:nil];
	[self.webView setResourceLoadDelegate:nil];
	[self.webView setPolicyDelegate:nil];
	[self.webView setUIDelegate:nil];

	[self cancelPerformRequests];
}

#pragma mark -
#pragma mark Create View

- (void)setUp
{
	/* Update a few preferences. */
	static WebPreferences *_preferencesInitd = nil;
	
	if (_preferencesInitd == nil) {
		_preferencesInitd = [[WebPreferences alloc] initWithIdentifier:@"TVCLogControllerSharedWebPreferencesObject"];
		
		[_preferencesInitd setCacheModel:WebCacheModelDocumentViewer];
		[_preferencesInitd setUsesPageCache:NO];

		if ([_preferencesInitd respondsToSelector:@selector(setShouldRespectImageOrientation:)]) {
			(void)objc_msgSend(_preferencesInitd, @selector(setShouldRespectImageOrientation:), YES);
		}
	}
	
	/* Create view. */
	 self.webViewScriptSink = [TVCLogScriptEventSink new];
	[self.webViewScriptSink setLogController:self];

	self.webViewAutoScroller = [TVCWebViewAutoScroll new];

	 self.webView = [[TVCLogView alloc] initWithFrame:NSZeroRect];
	
	 self.webViewPolicy = [TVCLogPolicy new];
	[self.webViewPolicy setLogController:self];
	
	[self.webView setPreferences:_preferencesInitd];
	
	[self.webView setAutoresizingMask:(NSViewWidthSizable | NSViewHeightSizable)];
	
	[self.webView setCustomUserAgent:TVCLogViewCommonUserAgentString];
	
	[self.webView setKeyDelegate:self];
	[self.webView setDraggingDelegate:self];
	[self.webView setFrameLoadDelegate:self];
	[self.webView setResourceLoadDelegate:self];
	[self.webView setPolicyDelegate:self.webViewPolicy];
	[self.webView setUIDelegate:self.webViewPolicy];
	
	[self.webView setShouldUpdateWhileOffscreen:NO];
	
	[self.webView setHostWindow:mainWindow()];
	
	/* Load initial document. */
	[self loadAlternateHTML:[self initialDocument:nil]];

	/* Cache last known state of encryption. */
#if TEXTUAL_BUILT_WITH_ADVANCED_ENCRYPTION == 1
	if (self.associatedChannel) {
		self.viewIsEncrypted = [self.associatedChannel encryptionStateIsEncrypted];
	} else {
#endif

		self.viewIsEncrypted = NO;

#if TEXTUAL_BUILT_WITH_ADVANCED_ENCRYPTION == 1
	}
#endif

	/* Playback history. */
	self.historicLogFile = [TVCLogControllerHistoricLogFile new];
	
	/* Even if we aren't playing back history, we still open it
	 because theme reloads use it to playback messages. */
	[self.historicLogFile setAssociatedController:self];

	if ([TPCPreferences reloadScrollbackOnLaunch] == NO) {
		self.historyLoaded = YES;
	} else {
		if (self.historyLoaded == NO && (self.associatedChannel &&
									   ([self.associatedChannel isPrivateMessage] == NO || [TPCPreferences rememberServerListQueryStates])))
		{
			[self reloadHistory];
		}
	}
}

- (void)loadAlternateHTML:(NSString *)newHTML
{
	NSColor *windowColor = [themeSettings() underlyingWindowColor];

	if (windowColor == nil) {
		windowColor = [NSColor blackColor];
	}

	[(id)self.webView setBackgroundColor:windowColor];
	
	[[self.webView mainFrame] stopLoading];
	[[self.webView mainFrame] loadHTMLString:newHTML baseURL:[self baseURL]];
}

#pragma mark -
#pragma mark Manage Historic Log

- (void)closeHistoricLog
{
	[self closeHistoricLog:NO];
}

- (void)closeHistoricLog:(BOOL)withForcedReset
{
	/* The historic log file is always open regardless of whether the user asked
	 Textual to remember the history between restarts. It is always open because
	 the reloading of a theme uses it to fill in the backlog after a reload.

	 closeHistoricLog is the point where we decide to actually save the file
	 or erase it. If the user has Textual configured to remember between restarts,
	 then we call a save before terminating. Or, we just erase the file from the
	 path that it is written to entirely. */

	if (self.viewIsEncrypted || withForcedReset) {
		[self.historicLogFile resetData]; // -resetData calls -close on your behalf
	} else {
		if ([TPCPreferences reloadScrollbackOnLaunch] == NO ||
			  self.associatedChannel == nil ||
			([self.associatedChannel isChannel] == NO && [TPCPreferences rememberServerListQueryStates] == NO))
		{
			[self.historicLogFile resetData];
		}
		else
		{
			[self.historicLogFile close];
		}
	}
}

#pragma mark -
#pragma mark Properties

- (void)setMaximumLineCount:(NSInteger)value
{
	if (NSDissimilarObjects(self.maximumLineCount, value)) {
		_maximumLineCount = value;

		NSAssertReturn(self.isLoaded);

		if (self.maximumLineCount > 0 && self.activeLineCount > self.maximumLineCount) {
			[self setNeedsLimitNumberOfLines];
		}
	}
}

- (void)setViewIsEncrypted:(BOOL)viewIsEncrypted
{
	if (NSDissimilarObjects(_viewIsEncrypted, viewIsEncrypted)) {
		_viewIsEncrypted = viewIsEncrypted;

		if (viewIsEncrypted) {
			[self closeHistoricLog];
		}
	}
}

- (NSString *)uniqueIdentifier
{
	if (self.associatedChannel) {
		return [self.associatedChannel uniqueIdentifier];
	} else {
		return [self.associatedClient uniqueIdentifier];
	}
}

- (NSURL *)baseURL
{
	return [themeController() baseURL];
}

- (TVCLogControllerOperationQueue *)printingQueue
{
    return [self.associatedClient printingQueue];
}

- (BOOL)inlineImagesEnabledForView
{
	PointerIsEmptyAssertReturn(self.associatedChannel, NO);

	/* If global showInlineImages is YES, then the value of ignoreInlineImages is designed to
	 be as it is named. Disable them for specific channels. However if showInlineImages is NO
	 on a global scale, then ignoreInlineImages actually enables them for specific channels. */

	return (([TPCPreferences showInlineImages]			&& self.associatedChannel.config.ignoreInlineImages == NO) ||
			([TPCPreferences showInlineImages] == NO	&& self.associatedChannel.config.ignoreInlineImages));
}

- (NSInteger)scrollbackCorrectionInit
{
	return ([self.webView frame].size.height / 2);
}

- (DOMDocument *)mainFrameDocument
{
	return [[self.webView mainFrame] DOMDocument];
}

- (DOMElement *)documentBody
{
	DOMDocument *doc = [self mainFrameDocument];

	PointerIsEmptyAssertReturn(doc, nil);

	return [doc getElementById:@"body_home"];
}

- (DOMElement *)documentChannelTopicBar
{
	DOMDocument *doc = [self mainFrameDocument];

	PointerIsEmptyAssertReturn(doc, nil);

	return [doc getElementById:@"topic_bar"];
}

- (WebFrameView *)webFrameView
{
	return [[[self webView] mainFrame] frameView];
}

#pragma mark -
#pragma mark Document Append & JavaScript Controller

- (void)appendToDocumentBody:(NSString *)html
{
	DOMDocument *doc = [self mainFrameDocument];
	PointerIsEmptyAssert(doc);

	DOMElement *body = [self documentBody];
	PointerIsEmptyAssert(body);

	DOMDocumentFragment *frag = [(id)doc createDocumentFragmentWithMarkupString:html baseURL:[self baseURL]];

	[body appendChild:frag];
}

- (void)executeScriptCommand:(NSString *)command withArguments:(NSArray *)args
{
	[self executeScriptCommand:command withArguments:args onQueue:YES];
}

- (void)executeScriptCommand:(NSString *)command withArguments:(NSArray *)args onQueue:(BOOL)onQueue
{
	if (onQueue) {
		TVCLogControllerOperationBlock scriptBlock = ^(id operation) {
			NSAssertReturn([operation isCancelled] == NO);
			
			[self performBlockOnMainThread:^{
				[self executeQuickScriptCommand:command withArguments:args];
			}];
		};
		
		[[self printingQueue] enqueueMessageBlock:scriptBlock for:self];
	} else {
		[self executeQuickScriptCommand:command withArguments:args];
	}
}

- (void)executeQuickScriptCommand:(NSString *)command withArguments:(NSArray *)args
{
	WebScriptObject *js_api = [self.webView javaScriptAPI];

	if ( js_api && [js_api isKindOfClass:[WebUndefined class]] == NO) {
		[js_api callWebScriptMethod:command	withArguments:args];
	}
}

- (BOOL)viewHasValidJavaScriptAPIPointer
{
	WebScriptObject *js_api = [self.webView javaScriptAPI];

	if (js_api && [js_api isKindOfClass:[WebUndefined class]] == NO) {
		return YES;
	}

	return NO;
}

#pragma mark -
#pragma mark Channel Topic Bar

- (NSString *)topicValue
{
	DOMElement *topicBar = [self documentChannelTopicBar];

	if (topicBar == nil) {
		return NSStringEmptyPlaceholder;
	}

	return [(id)topicBar innerHTML];
}

- (void)setTopic:(NSString *)topic
{
	if (NSObjectIsEmpty(topic)) {
		topic = BLS(1122);
	}

	[[self printingQueue] enqueueMessageBlock:^(id operation) {
		NSAssertReturn([operation isCancelled] == NO);

		NSString *body = [TVCLogRenderer renderBody:topic
									  forController:self
									 withAttributes:@{
											TVCLogRendererConfigurationShouldRenderLinksAttribute : @YES,
											TVCLogRendererConfigurationLineTypeAttribute : @(TVCLogLineTopicType)
													}
										 resultInfo:NULL];

		[self performBlockOnMainThread:^{
			DOMElement *topicBar = [self documentChannelTopicBar];

			if (topicBar) {
				NSString *oldTopic = [(id)topicBar innerHTML];

				if (NSObjectsAreEqual(topic, oldTopic) == NO) {
					[(id)topicBar setInnerHTML:body];

					[self executeScriptCommand:@"topicBarValueChanged" withArguments:@[topic]];

					[self redrawFrame];
				}
			}
		}];
	} for:self];
}

#pragma mark -
#pragma mark Move to Bottom/Top

- (void)moveToTop
{
	NSAssertReturn(self.isLoaded);

	DOMDocument *doc = [self mainFrameDocument];
	PointerIsEmptyAssert(doc);

	DOMElement *body = [doc getElementById:@"body_home"];
	PointerIsEmptyAssert(body);

	[(DOMElement *)[body firstChild] scrollIntoView:YES];

	[self executeQuickScriptCommand:@"viewPositionMovedToTop" withArguments:@[]];
}

- (void)moveToBottom
{
	NSAssertReturn(self.isLoaded);

	DOMDocument *doc = [self mainFrameDocument];
	PointerIsEmptyAssert(doc);

	DOMElement *body = [doc getElementById:@"body_home"];
	PointerIsEmptyAssert(body);

	[(DOMElement *)[body lastElementChild] scrollIntoViewIfNeeded:YES];

	[self executeQuickScriptCommand:@"viewPositionMovedToBottom" withArguments:@[]];
}

- (BOOL)viewingBottom
{
	NSAssertReturnR(self.isLoaded, NO);

	DOMDocument *doc = [self mainFrameDocument];
	PointerIsEmptyAssertReturn(doc, NO);

	DOMElement *body = [doc getElementById:@"body_home"];
	PointerIsEmptyAssertReturn(body, NO);

	NSInteger offsetHeight = [body offsetHeight];
	NSInteger scrollHeight = [body scrollHeight];
	NSInteger scrollTop = [body scrollTop];

	BOOL isNotAtBottom = (scrollTop < (scrollHeight - offsetHeight));

	return (isNotAtBottom == NO);
}

#pragma mark -
#pragma mark Add/Remove History Mark

- (void)mark
{
	NSAssertReturn(self.isLoaded);

	DOMDocument *doc = [self mainFrameDocument];
	PointerIsEmptyAssert(doc);

	DOMElement *e = [doc getElementById:@"mark"];

	while (e) {
		[[e parentNode] removeChild:e];

		e = [doc getElementById:@"mark"];
	}

	NSString *html = [TVCLogRenderer renderTemplate:@"historyIndicator"];

	[self appendToDocumentBody:html];
	
	[self executeQuickScriptCommand:@"historyIndicatorAddedToView" withArguments:@[]];
}

- (void)unmark
{
	NSAssertReturn(self.isLoaded);

	DOMDocument *doc = [self mainFrameDocument];
	PointerIsEmptyAssert(doc);

	DOMElement *e = [doc getElementById:@"mark"];

	while (e) {
		[[e parentNode] removeChild:e];

		e = [doc getElementById:@"mark"];
	}

	[self executeQuickScriptCommand:@"historyIndicatorRemovedFromView" withArguments:@[]];
}

- (void)goToMark
{
	if ([self jumpToElementID:@"mark"]) {
		[self executeQuickScriptCommand:@"viewPositionModToHistoryIndicator" withArguments:@[]];
	}
}

#pragma mark -
#pragma mark Reload Scrollback

- (void)appendHistoricMessageFragment:(NSString *)html toHistoricMessagesDiv:(BOOL)toHistoricMessagesDiv
{
	/* This method looks for #historic_messages and appends to that if it
	 exists. If it does not exist, then it looks for #body_home. This div 
	 should exist, but if it does not, then the method is cancelled.
	 
	 The appended fragment is placed above the first child node of the
	 container, or is simply appended to the container if no child exists. */

	DOMDocument *doc = [self mainFrameDocument];
	PointerIsEmptyAssert(doc);

	DOMElement *body = nil;

	if (toHistoricMessagesDiv) {
		body = [doc getElementById:@"historic_messages"];
	}

	if (body == nil) {
		body = [self documentBody];
	}

	PointerIsEmptyAssert(body);

	DOMNodeList *childNodes = [body childNodes];

	DOMDocumentFragment *frag = [(id)doc createDocumentFragmentWithMarkupString:html baseURL:[self baseURL]];

	if ([childNodes length] < 1) {
		[body appendChild:frag];
	} else {
		[body insertBefore:frag refChild:[childNodes item:0]];
	}
}

/* reloadOldLines: is supposed to be called from inside a queue. */
- (void)reloadOldLines:(BOOL)markHistoric withOldLines:(NSArray *)oldLines
{
	/* What lines are we reloading? */
	NSObjectIsEmptyAssert(oldLines);

	/* Misc. data. */
	NSMutableArray *lineNumbers = [NSMutableArray array];

	NSMutableString *patchedAppend = [NSMutableString string];

	NSMutableData *newHistoricArchive = [NSMutableData data];

	/* Begin processing. */
	for (NSData *chunkedData in oldLines) {
		TVCLogLine *line = (id)[[TVCLogLine alloc] initWithRawJSONData:chunkedData];

		PointerIsEmptyAssertLoopContinue(line);

		if (markHistoric) {
			[line setIsHistoric:YES];
		}

		/* Render everything. */
		NSDictionary *resultInfo = nil;

		NSString *html = [self renderLogLine:line resultInfo:&resultInfo];

		NSObjectIsEmptyAssertLoopContinue(html);

		/* Gather result information. */
		NSString *lineNumber = resultInfo[@"lineNumber"];

		[patchedAppend appendString:html];

		[lineNumbers addObject:@[lineNumber, resultInfo]];

		/* Write to JSON data. */
		NSData *jsondata = [line jsonDictionaryRepresentation];

		[newHistoricArchive appendData:jsondata];
		[newHistoricArchive appendData:[NSData lineFeed]];

		/* Was it a highlight? */
		BOOL highlighted = [resultInfo boolForKey:TVCLogRendererResultsKeywordMatchFoundAttribute];

		if (highlighted) {
			@synchronized(self.highlightedLineNumbers) {
				[self.highlightedLineNumbers addObject:lineNumber];
			}
		}
	}

	/* Update historic archive. */
	[self.historicLogFile writeNewEntryWithRawData:newHistoricArchive];

	/* Update WebKit. */
	[self performBlockOnMainThread:^{
		[self appendHistoricMessageFragment:patchedAppend toHistoricMessagesDiv:markHistoric];

		[self mark];

		for (NSArray *lineInfo in lineNumbers) {
			/* Update count. */
			self.activeLineCount += 1;

			/* Line info. */
			NSString *lineNumber = lineInfo[0];

			/* Inform the style of the addition. */
			[self executeQuickScriptCommand:@"newMessagePostedToView" withArguments:@[lineNumber]];
			
			/* Inform plugins. */
			if ([sharedPluginManager() supportsFeature:THOPluginItemSupportsNewMessagePostedEvent]) {
				NSDictionary *resultInfo = lineInfo[1];

				THOPluginDidPostNewMessageConcreteObject *pluginConcreteObject = resultInfo[@"pluginConcreteObject"];

				[pluginConcreteObject setIsProcessedInBulk:YES];

				[sharedPluginManager() postNewMessageEventForViewController:self withObject:pluginConcreteObject];
			}
		}
	}];
}

- (void)reloadHistory
{
	self.historyLoaded = YES;

	if (self.viewIsEncrypted == NO)
	{
		self.reloadingHistory = YES;

		[[self printingQueue] enqueueMessageBlock:^(id operation) {
			if ([operation isCancelled] == NO) {
				NSArray *objects = [self.historicLogFile listEntriesWithFetchLimit:100];

				[self.historicLogFile resetData];

				[self reloadHistoryCompletionBlock:objects];
			} else {
				[self reloadHistoryCompletionBlock:nil];
			}
		 } for:self isStandalone:YES];
	}
}

- (void)reloadHistoryCompletionBlock:(NSArray *)objects
{
	[self reloadOldLines:YES withOldLines:objects];

	[self performBlockOnMainThread:^{
		[self moveToBottom];

		[self maybeRedrawFrame];
	}];

	self.reloadingHistory = NO;
}

- (void)reloadTheme
{
	if (self.reloadingHistory == NO) {
		self.reloadingBacklog = YES;

		[self clearWithReset:NO];

		if (self.viewIsEncrypted == NO)
		{
			[[self printingQueue] enqueueMessageBlock:^(id operation) {
				if ([operation isCancelled] == NO) {
					NSArray *objects = [self.historicLogFile listEntriesWithFetchLimit:1000];
					
					[self.historicLogFile resetData];
					
					[self reloadThemeCompletionBlock:objects];
				} else {
					[self reloadThemeCompletionBlock:nil];
				}
			} for:self isStandalone:YES];
		}
		else
		{
			self.reloadingBacklog = NO;
		}
	}
}

- (void)reloadThemeCompletionBlock:(NSArray *)objects
{
	[self reloadOldLines:NO withOldLines:objects];

	[self performBlockOnMainThread:^{
		[self moveToBottom];

		[self maybeRedrawFrame];
	}];

	self.reloadingBacklog = NO;
}

#pragma mark -
#pragma mark Utilities

- (void)jumpToLine:(NSString *)line
{
	NSString *lid = [NSString stringWithFormat:@"line-%@", line];

	if ([self jumpToElementID:lid]) {
		[self executeQuickScriptCommand:@"viewPositionMovedToLine" withArguments:@[line]];
	}
}

- (BOOL)jumpToElementID:(NSString *)elementID
{
	NSAssertReturnR(self.isLoaded, NO);

	DOMDocument *doc = [self mainFrameDocument];
	PointerIsEmptyAssertReturn(doc, NO);

	DOMElement *body = [doc getElementById:@"body_home"];
	PointerIsEmptyAssertReturn(body, NO);
	
	DOMElement *e = [doc getElementById:elementID];
	PointerIsEmptyAssertReturn(e, NO);

	[e scrollIntoViewIfNeeded:YES];

	return YES;
}

- (void)notifyDidBecomeVisible /* When the view is switched to. */
{
	NSValue *wasViewingBottom = @(self.wasViewingBottomBeforeBecomingHidden);

	[self executeQuickScriptCommand:@"notifyDidBecomeVisible" withArguments:@[wasViewingBottom]];

	[self maybeRedrawFrame];
}

- (void)notifyDidBecomeHidden
{
	self.wasViewingBottomBeforeBecomingHidden = [[self webViewAutoScroller] viewingBottom];
}

- (void)changeTextSize:(BOOL)bigger
{
	if (bigger) {
		[self.webView makeTextLarger:nil];
	} else {
		[self.webView makeTextSmaller:nil];
	}

	[self executeQuickScriptCommand:@"viewFontSizeChanged" withArguments:@[@(bigger)]];
}

#pragma mark -
#pragma mark Manage Highlights

- (BOOL)highlightAvailable:(BOOL)previous
{
	NSAssertReturnR(self.isLoaded, NO);

	@synchronized(self.highlightedLineNumbers) {
		NSObjectIsEmptyAssertReturn(self.highlightedLineNumbers, NO);

		NSUInteger lastHighlightIndex = NSNotFound;

		if ([self.highlightedLineNumbers containsObject:self.lastVisitedHighlight]) {
			lastHighlightIndex = [self.highlightedLineNumbers indexOfObject:self.lastVisitedHighlight];
		}

		if (previous == NO) {
			if (lastHighlightIndex == ([self.highlightedLineNumbers count] - 1)) {
				return NO;
			} else {
				return YES;
			}
		} else {
			if (lastHighlightIndex == 0) {
				return NO;
			} else {
				return YES;
			}
		}

		return NO;
	}
}

- (void)nextHighlight
{
	NSAssertReturn(self.isLoaded);

	DOMDocument *doc = [self mainFrameDocument];
	PointerIsEmptyAssert(doc);
	
	@synchronized(self.highlightedLineNumbers) {
		NSObjectIsEmptyAssert(self.highlightedLineNumbers);

		if ([self.highlightedLineNumbers containsObject:self.lastVisitedHighlight]) {
			NSUInteger hli_ci = [self.highlightedLineNumbers indexOfObject:self.lastVisitedHighlight];

			if (hli_ci == ([self.highlightedLineNumbers count] - 1)) {
				// Return method since the last highlight we
				// visited was the end of array. Nothing ahead.

				return;
			} else {
				self.lastVisitedHighlight = self.highlightedLineNumbers[(hli_ci + 1)];
			}
		} else {
			self.lastVisitedHighlight = self.highlightedLineNumbers[0];
		}

		[self jumpToLine:self.lastVisitedHighlight];
	}
}

- (void)previousHighlight
{
	NSAssertReturn(self.isLoaded);

	DOMDocument *doc = [self mainFrameDocument];
	PointerIsEmptyAssert(doc);
	
	@synchronized(self.highlightedLineNumbers) {
		NSObjectIsEmptyAssert(self.highlightedLineNumbers);

		if ([self.highlightedLineNumbers containsObject:self.lastVisitedHighlight]) {
			NSInteger hli_ci = [self.highlightedLineNumbers indexOfObject:self.lastVisitedHighlight];

			if (hli_ci == 0) {
				// Return method since the last highlight we
				// visited was the start of array. Nothing ahead.

				return;
			} else {
				self.lastVisitedHighlight = self.highlightedLineNumbers[(hli_ci - 1)];
			}
		} else {
			self.lastVisitedHighlight = self.highlightedLineNumbers[0];
		}

		[self jumpToLine:self.lastVisitedHighlight];
	}
}

#pragma mark -
#pragma mark Manage Scrollback Size

- (void)limitNumberOfLines
{
	self.needsLimitNumberOfLines = NO;

	NSInteger n = (self.activeLineCount - self.maximumLineCount);

	if (self.isLoaded == NO || n <= 0 || self.activeLineCount <= 0) {
		return;
	}

	DOMDocument *doc = [self mainFrameDocument];
	PointerIsEmptyAssert(doc);

	DOMElement *body = [self documentBody];
	PointerIsEmptyAssert(body);

	DOMNodeList *nodeList = [body childNodes];
	PointerIsEmptyAssert(nodeList);

	n = (nodeList.length - self.maximumLineCount);

	/* Remove old lines. */
	for (NSInteger i = (n - 1); i >= 0; --i) {
		[body removeChild:[nodeList item:(unsigned)i]];
	}

	self.activeLineCount -= n;

	if (self.activeLineCount < 0) {
		self.activeLineCount = 0;
	}

	/* Update highlight index. */
	@synchronized(self.highlightedLineNumbers) {
		NSObjectIsEmptyAssert(self.highlightedLineNumbers);

		NSMutableArray *newList = [NSMutableArray array];

		for (NSString *lineNumber in self.highlightedLineNumbers) {
			NSString *lid = [NSString stringWithFormat:@"line-%@", lineNumber];

			DOMElement *e = [doc getElementById:lid];

			/* If the element does not exist, then it means
			 that we removed it up above. */
			if (e) {
				[newList addObject:lineNumber];
			}
		}

		self.highlightedLineNumbers = [newList mutableCopy];
	}
}

- (void)setNeedsLimitNumberOfLines
{
	if (self.needsLimitNumberOfLines) {
		return;
	}

	self.needsLimitNumberOfLines = YES;

	[self limitNumberOfLines];
}

- (void)clearWithReset:(BOOL)resetQueue
{
	[self performBlockOnMainThread:^{
		[[self printingQueue] cancelOperationsForViewController:self];

		if (resetQueue) {
			[self.historicLogFile resetData];
		}
		
		@synchronized(self.highlightedLineNumbers) {
			[self.highlightedLineNumbers removeAllObjects];
		}
		
		self.activeLineCount = 0;
		self.lastVisitedHighlight = nil;

		self.windowFrameObjectLoaded = NO;
		self.windowScriptObjectLoaded = NO;

		self.isLoaded = NO;
	 // self.reloadingBacklog = NO;
	 // self.reloadingHistory = NO;
		self.needsLimitNumberOfLines = NO;

		self.wasViewingBottomBeforeBecomingHidden = YES;

		[self loadAlternateHTML:[self initialDocument:[self topicValue]]];
	}];
}

- (void)clear
{
	[self clearWithReset:YES];
}

#pragma mark -
#pragma mark Print

- (void)redrawFrame
{
	if ([mainWindow() selectedViewController] == self) {
		[self.webViewAutoScroller forceFrameRedraw];
	}
}

- (void)maybeRedrawFrame
{
	/* The WebView is layer backed which means it is not redrawn unless it is told to do so. 
	 TVCWebViewAutoScroll automatically tells it to do so if it scrolled programmatically or
	 by the end user. When there is not enough content to scroll, the WebView is not redrawn
	 because there is never a scroll event triggered. Therefore, this call exists to tell 
	 TVCWebViewAutoScroll that we are interested in a redraw and it will then take appropriate
	 actions depending on whether one is necessary or not. */

	if ([mainWindow() selectedViewController] == self) {
		if ([self.webViewAutoScroller canScroll] == NO) {
			[self.webViewAutoScroller forceFrameRedraw];
		}
	}
}

- (NSString *)uniquePrintIdentifier
{
	NSString *randomUUID = [NSString stringWithUUID]; // Example: 68753A44-4D6F-1226-9C60-0050E4C00067

	return [randomUUID substringFromIndex:19]; // Example: 9C60-0050E4C00067
}

- (void)print:(TVCLogLine *)logLine
{
	[self print:logLine completionBlock:NULL];
}

- (void)print:(TVCLogLine *)logLine completionBlock:(void(^)(BOOL highlighted))completionBlock
{
	/* Continue with a normal print job. */
	TVCLogControllerOperationBlock printBlock = ^(id operation) {
		NSAssertReturn([operation isCancelled] == NO);

		/* Render everything. */
		NSDictionary *resultInfo = nil;
		
		NSString *html = [self renderLogLine:logLine resultInfo:&resultInfo];

		if (html) {
			/* Increment by one. */
			self.activeLineCount += 1;

			/* Gather result information. */
			BOOL highlighted = [resultInfo boolForKey:TVCLogRendererResultsKeywordMatchFoundAttribute];

			NSString *lineNumber = resultInfo[@"lineNumber"];
		  //NSString *renderTime = [resultInfo objectForKey:@"lineRenderTime"];

			NSArray *mentionedUsers = [resultInfo arrayForKey:TVCLogRendererResultsListOfUsersFoundAttribute];

			NSDictionary *inlineImageMatches = [resultInfo dictionaryForKey:@"InlineImagesToValidate"];
			
			[self performBlockOnMainThread:^{
				/* Record highlights. */
				if (highlighted) {
					@synchronized(self.highlightedLineNumbers) {
						[self.highlightedLineNumbers addObject:lineNumber];
					}

					[self.associatedClient cacheHighlightInChannel:self.associatedChannel withLogLine:logLine];
				}

				/* Do the actual append to WebKit. */
				[self appendToDocumentBody:html];

				/* Inform the style of the new append. */
				[self executeQuickScriptCommand:@"newMessagePostedToView" withArguments:@[lineNumber]];
				
				/* Inform plugins. */
				if ([sharedPluginManager() supportsFeature:THOPluginItemSupportsNewMessagePostedEvent]) {
					[sharedPluginManager() postNewMessageEventForViewController:self withObject:resultInfo[@"pluginConcreteObject"]];
				}

				/* Limit lines. */
				if (self.maximumLineCount > 0 && (self.activeLineCount - 10) > self.maximumLineCount) {
					/* Only cut lines if our number is divisible by 5. This makes it so every
					 line is not using resources. */
					
					if ((self.activeLineCount % 5) == 0) {
						[self setNeedsLimitNumberOfLines];
					}
				}

				/* Begin processing inline images. */
				/* We go through the inline image list here and pass to the loader now so that
				 we know the links have hit the webview before we even try loading them. */
				for (NSString *uniqueKey in inlineImageMatches) {
					TVCImageURLoader *loader = [TVCImageURLoader new];

					[loader setDelegate:self];

					[loader assesURL:inlineImageMatches[uniqueKey] withID:uniqueKey];
				}
				
				/* Log this log line. */
				/* If the channel is encrypted, then we refuse to write to
				 the actual historic log so there is no trace of the chatter
				 on the disk in the form of an unencrypted cache file. */
				/* Doing it this way does break the ability to reload chatter
				 in the view as well as playback on restart, but the added
				 security can be seen as a bonus. */
				if (self.viewIsEncrypted == NO) {
					[self.historicLogFile writeNewEntryForLogLine:logLine];
				}

				/* Using informationi provided by conversation tracking we can update our internal
				 array of favored nicknames for nick completion. */
				if ([logLine memberType] == TVCLogLineMemberLocalUserType) {
					[mentionedUsers makeObjectsPerformSelector:@selector(outgoingConversation)];
				} else {
					[mentionedUsers makeObjectsPerformSelector:@selector(conversation)];
				}

				/* Maybe redraw our frame. */
				[self maybeRedrawFrame];

				/* Finish up. */
				PointerIsEmptyAssert(completionBlock);

				completionBlock(highlighted);
			}];
		}
	};

	[[self printingQueue] enqueueMessageBlock:printBlock for:self];
}

- (NSString *)renderLogLine:(TVCLogLine *)line resultInfo:(NSDictionary * __autoreleasing *)resultInfo
{
	NSObjectIsEmptyAssertReturn([line messageBody], nil);

	// ************************************************************************** /
	// Render our body.                                                           /
	// ************************************************************************** /

	TVCLogLineType type = [line lineType];

	NSString *renderedBody = nil;
	NSString *lineTypeStng = [line lineTypeString];

	BOOL drawLinks = ([[TLOLinkParser bannedLineTypes] containsObject:lineTypeStng] == NO);

	// ---- //

	NSMutableDictionary *rendererAttributes = [NSMutableDictionary dictionary];

	NSDictionary *rendererResults = nil;

	[rendererAttributes maybeSetObject:[line highlightKeywords] forKey:TVCLogRendererConfigurationHighlightKeywordsAttribute];
	[rendererAttributes maybeSetObject:[line excludeKeywords] forKey:TVCLogRendererConfigurationExcludedKeywordsAttribute];
	
	[rendererAttributes setBool:drawLinks forKey:TVCLogRendererConfigurationShouldRenderLinksAttribute];

	[rendererAttributes setInteger:[line lineType] forKey:TVCLogRendererConfigurationLineTypeAttribute];
	[rendererAttributes setInteger:[line memberType] forKey:TVCLogRendererConfigurationMemberTypeAttribute];

	renderedBody = [TVCLogRenderer renderBody:[line messageBody]
								forController:self
							   withAttributes:rendererAttributes
								   resultInfo:&rendererResults];

	if (renderedBody == nil) {
		return nil;
	}

	NSMutableDictionary *resultData = [rendererResults mutableCopy];

	BOOL highlighted = NO;

	if ([line memberType] == TVCLogLineMemberNormalType) {
		highlighted = [rendererResults boolForKey:TVCLogRendererResultsKeywordMatchFoundAttribute];
	}

	NSDictionary *inlineImageMatches = [rendererResults dictionaryForKey:TVCLogRendererResultsUniqueListOfAllLinksInBodyAttribute];

	// ************************************************************************** /
	// Draw to display.                                                                /
	// ************************************************************************** /

	NSMutableDictionary *specialAttributes = [NSMutableDictionary new];

	specialAttributes[@"activeStyleAbsolutePath"] = [[self baseURL] absoluteString];
	
	specialAttributes[@"applicationResourcePath"] = [TPCPathInfo applicationResourcesFolderPath];

	NSMutableDictionary *attributes = specialAttributes;

	// ************************************************************************** /
	// Find all inline media.                                                     /
	// ************************************************************************** /

	if ([self inlineImagesEnabledForView] == NO) {
		attributes[@"inlineMediaAvailable"] = @(NO);
	} else {
		NSMutableArray *inlineImageLinks = [NSMutableArray array];

		NSMutableDictionary *inlineImagesToValidate = [NSMutableDictionary dictionary];

		if (type == TVCLogLinePrivateMessageType || type == TVCLogLineActionType)
		{
			if ([self inlineImagesEnabledForView]) {
				for (NSString *uniqueKey in inlineImageMatches) {
					NSString *nurl = (id)inlineImageMatches[uniqueKey];

					NSString *iurl = [TVCImageURLParser imageURLFromBase:nurl];

					NSObjectIsEmptyAssertLoopContinue(iurl);

					inlineImagesToValidate[uniqueKey] = iurl;

					[inlineImageLinks addObject:@{
						  @"preferredMaximumWidth"		: @([TPCPreferences inlineImagesMaxWidth]),
						  @"anchorInlineImageUniqueID"	: uniqueKey,
						  @"anchorLink"					: nurl,
						  @"imageURL"					: iurl,
					}];
				}
			}
		}

		attributes[@"inlineMediaAvailable"] = @(NSObjectIsEmpty(inlineImageLinks) == NO);
		
		attributes[@"inlineMediaArray"]		= inlineImageLinks;

		resultData[@"InlineImagesToValidate"] = inlineImagesToValidate;
	}

	// ---- //

	if ([line receivedAt]) {
		NSString *time = [line formattedTimestamp];

		if (time) {
			attributes[@"timestamp"] = @([[line receivedAt] timeIntervalSince1970]);

			attributes[@"formattedTimestamp"] = time;
		}
	}

	// ---- //

	if (NSObjectIsNotEmpty([line nickname])) {
		NSString *nickname = [line formattedNickname:self.associatedChannel];
		
		if (nickname == nil) {
			attributes[@"isNicknameAvailable"] = @(NO);
		} else {
			attributes[@"isNicknameAvailable"] = @(YES);
			
			attributes[@"nicknameColorNumber"] = [line nicknameColorStyle];
			attributes[@"nicknameColorStyle"] = [line nicknameColorStyle];

			attributes[@"nicknameColorHashingEnabled"] = @([TPCPreferences disableNicknameColorHashing] == NO);

			attributes[@"nicknameColorHashingIsStyleBased"] = @([themeSettings() nicknameColorStyle] != TPCThemeSettingsNicknameColorLegacyStyle);
			
			attributes[@"formattedNickname"] = [nickname trim];
			
			attributes[@"nickname"]	= [line nickname];
			attributes[@"nicknameType"]	= [line memberTypeString];
		}
	} else {
		attributes[@"isNicknameAvailable"] = @(NO);
	}

	// ---- //

	attributes[@"lineType"] = lineTypeStng;

	attributes[@"rawCommand"] = [line rawCommand];

	// ---- //

	NSString *classRep = nil;

	if (type == TVCLogLinePrivateMessageType || type == TVCLogLineNoticeType || type == TVCLogLineActionType) {
		classRep = @"text";
	} else {
		classRep = @"event";
	}

	if ([line isHistoric]) {
		classRep = [classRep stringByAppendingString:@" historic"];
	}

	attributes[@"lineClassAttributeRepresentation"] = classRep;

	// ---- //

	if (highlighted) {
		attributes[@"highlightAttributeRepresentation"] = @"true";
	} else {
		attributes[@"highlightAttributeRepresentation"] = @"false";
	}

	// ---- //

	attributes[@"message"]				= [line messageBody];
	attributes[@"formattedMessage"]		= renderedBody;

	attributes[@"isRemoteMessage"]	= @([line memberType] == TVCLogLineMemberNormalType);
	attributes[@"isHighlight"]		= @(highlighted);

	// ---- //

	if ([line isEncrypted]) {
		attributes[@"isEncrypted"] = @([line isEncrypted]);

		attributes[@"encryptedMessageLockTemplate"]	= [TVCLogRenderer renderTemplate:@"encryptedMessageLock" attributes:specialAttributes];
	}

	// ---- //

	NSString *serverName = [self.associatedClient altNetworkName];
	
	if (serverName) {
		attributes[@"configuredServerName"] = serverName;
	}
	
	// ---- //

	NSString *newLinenNumber = [self uniquePrintIdentifier];
	
	NSString *lineRenderTime = [NSString stringWithDouble:[NSDate unixTime]];

	attributes[@"lineNumber"] = newLinenNumber;
	attributes[@"lineRenderTime"] = lineRenderTime;
	
	resultData[@"lineNumber"] = newLinenNumber;

	if ([sharedPluginManager() supportsFeature:THOPluginItemSupportsNewMessagePostedEvent]) {
		THOPluginDidPostNewMessageConcreteObject *pluginConcreteObject = [THOPluginDidPostNewMessageConcreteObject new];

		[pluginConcreteObject setKeywordMatchFound:highlighted];

		[pluginConcreteObject setLineType:[line lineType]];
		[pluginConcreteObject setMemberType:[line memberType]];

		[pluginConcreteObject setSenderNickname:[line nickname]];

		[pluginConcreteObject setReceivedAt:[line receivedAt]];

		[pluginConcreteObject setLineNumber:newLinenNumber];

		[pluginConcreteObject setMessageContents:rendererResults[TVCLogRendererResultsOriginalBodyWithoutEffectsAttribute]];

		[pluginConcreteObject setListOfHyperlinks:rendererResults[TVCLogRendererResultsRangesOfAllLinksInBodyAttribute]];
		[pluginConcreteObject setListOfUsers:rendererResults[TVCLogRendererResultsOriginalBodyWithoutEffectsAttribute]];

		resultData[@"pluginConcreteObject"] = pluginConcreteObject;
	}
	
	// ************************************************************************** /
	// Return information.											              /
	// ************************************************************************** /

	if ( resultInfo) {
		*resultInfo = resultData;
	}

	// ************************************************************************** /
	// Render the actual HTML.												      /
	// ************************************************************************** /

	NSString *templateName = [themeSettings() templateNameWithLineType:[line lineType]];

	NSString *html = [TVCLogRenderer renderTemplate:templateName attributes:attributes];

	return html;
}

- (void)isSafeToPresentImageWithID:(NSString *)uniqueID
{
	[self.webViewScriptSink toggleInlineImage:uniqueID];
}

- (void)isNotSafeToPresentImageWithID:(NSString *)uniqueID
{
	;
}

#pragma mark -
#pragma mark Initial Document

- (NSString *)initialDocument:(NSString *)topic
{
	NSMutableDictionary *templateTokens = [self generateOverrideStyle];

	// ---- //

	templateTokens[@"activeStyleAbsolutePath"]	= [[self baseURL] absoluteString];
	
	templateTokens[@"applicationResourcePath"]	= [TPCPathInfo applicationResourcesFolderPath];

	templateTokens[@"cacheToken"]				= [themeController() sharedCacheID];

    templateTokens[@"configuredServerName"]     = [self.associatedClient altNetworkName];

	templateTokens[@"userConfiguredTextEncoding"] = [NSString charsetRepFromStringEncoding:self.associatedClient.config.primaryEncoding];

    // ---- //

	if (self.associatedChannel) {
		templateTokens[@"isChannelView"]        = @([self.associatedChannel isChannel]);
        templateTokens[@"isPrivateMessageView"] = @([self.associatedChannel isPrivateMessage]);

		templateTokens[@"channelName"]	  = [TVCLogRenderer escapeString:[self.associatedChannel name]];
		
		templateTokens[@"viewTypeToken"]  = [self.associatedChannel channelTypeString];

		if (topic == nil || [topic length] == 0) {
			templateTokens[@"formattedTopicValue"] = BLS(1122);
		} else {
			templateTokens[@"formattedTopicValue"] = topic;
		}
	} else {
		templateTokens[@"viewTypeToken"] = @"server";
	}
	
	templateTokens[@"sidebarInversionIsEnabled"] = @([TPCPreferences invertSidebarColors]);

	// ---- //

	if ([TPCPreferences rightToLeftFormatting]) {
		templateTokens[@"textDirectionToken"] = @"rtl";
	} else {
		templateTokens[@"textDirectionToken"] = @"ltr";
	}
	
	// ---- //
	
	templateTokens[@"operatingSystemVersion"] = [XRSystemInformation systemStandardVersion];
	
	// ---- //

	return [TVCLogRenderer renderTemplate:@"baseLayout" attributes:templateTokens];
}

- (NSMutableDictionary *)generateOverrideStyle
{
	NSMutableDictionary *templateTokens = [NSMutableDictionary dictionary];

	// ---- //

	NSFont *channelFont = [themeSettings() channelViewFont];

	if (channelFont == nil) {
		channelFont = [TPCPreferences themeChannelViewFont];
	}

	templateTokens[@"userConfiguredFontName"] =   [channelFont fontName];
	templateTokens[@"userConfiguredFontSize"] = @([channelFont pointSize] * (72.0 / 96.0));

	// ---- //

	NSInteger indentOffset = [themeSettings() indentationOffset];

	if (indentOffset == TPCThemeSettingsDisabledIndentationOffset || [TPCPreferences rightToLeftFormatting]) {
		templateTokens[@"nicknameIndentationAvailable"] = @(NO);
	} else {
		templateTokens[@"nicknameIndentationAvailable"] = @(YES);
		
		NSString *timeFormat = [themeSettings() timestampFormat];
		
		if (timeFormat == nil) {
			timeFormat = [TPCPreferences themeTimestampFormat];
		}

		NSString *time = TXFormattedTimestamp([NSDate date], timeFormat);

		NSSize textSize = [time sizeWithAttributes:@{NSFontAttributeName : channelFont}];

		templateTokens[@"predefinedTimestampWidth"] = @(textSize.width + indentOffset);
	}

	// ---- //

	return templateTokens;
}

#pragma mark -
#pragma mark WebView Delegate

/* Thanks to ePirat for this patch. It disables authentication dialogs for inline images. */
- (void)webView:(WebView *)sender resource:(id)identifier didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge fromDataSource:(WebDataSource *)dataSource
{
    [[challenge sender] cancelAuthenticationChallenge:challenge];
}

/* These failure calls have never been tested against. They are only here because the delegate provides them. */
- (void)webView:(WebView *)sender didFailLoadWithError:(NSError *)error forFrame:(WebFrame *)frame
{
	DebugLogToConsole(@"Log [%@] for channel [%@] on [%@] failed to load with error: %@",
				 [self description], [self.associatedChannel description], [self.associatedClient description], [error localizedDescription]);
}

- (void)webView:(WebView *)sender resource:(id)identifier didFailLoadingWithError:(NSError *)error fromDataSource:(WebDataSource *)dataSource
{
	DebugLogToConsole(@"Resource [%@] in log [%@] failed loading for channel [%@] on [%@] with error: %@",
				 identifier, [self description], [self.associatedChannel description], [self.associatedClient description], [error localizedDescription]);
}

- (void)webView:(WebView *)sender didFailProvisionalLoadWithError:(NSError *)error forFrame:(WebFrame *)frame
{
	DebugLogToConsole(@"Log [%@] for channel [%@] on [%@] failed provisional load with error: %@",
				 [self description], [self.associatedChannel description], [self.associatedClient description], [error localizedDescription]);
}

- (void)postViewLoadedJavaScriptPostflight
{
	/* Post events. */
	NSString *viewType = @"server";

	if (self.associatedChannel) {
		viewType = [self.associatedChannel channelTypeString];
	}

	self.isLoaded = YES;

	[self executeQuickScriptCommand:@"viewInitiated" withArguments:@[
		 NSDictionaryNilValue(viewType),
		 NSDictionaryNilValue([self.associatedClient uniqueIdentifier]),
		 NSDictionaryNilValue([self.associatedChannel uniqueIdentifier]),
		 NSDictionaryNilValue([self.associatedChannel name])
	]];

	if (self.reloadingBacklog == NO) {
		[self executeQuickScriptCommand:@"viewFinishedLoading" withArguments:@[]];
	} else {
		[self executeQuickScriptCommand:@"viewFinishedReload" withArguments:@[]];
	}

	[RZNotificationCenter() postNotificationName:TVCLogControllerViewFinishedLoadingNotification object:self];

	[self setUpScroller];

	[[self printingQueue] updateReadinessState:self];

	/* Change the font size to the one of others for new views. */
	float math = [worldController() textSizeMultiplier];

	[self.webView setTextSizeMultiplier:math];
}

- (void)postViwLoadedJavaScript
{
	if ([self viewHasValidJavaScriptAPIPointer]) {
		[self postViewLoadedJavaScriptPostflight];
	} else {
		/* Even though our window script object and view frame may be loaded,
		 there are times when our core.js API is not available right away.
		 In those cases, we cycle a timer until it is available. */

		[self performSelector:@selector(postViwLoadedJavaScript) withObject:nil afterDelay:1.0];
	}
}

- (void)webView:(WebView *)sender didClearWindowObject:(WebScriptObject *)windowObject forFrame:(WebFrame *)frame
{
	if (self.windowScriptObjectLoaded == NO) {
		self.windowScriptObjectLoaded = YES;

		[windowObject setValue:self.webViewScriptSink forKey:@"app"];

		/* If the view was already declared as loaded, then that means our 
		 script object came behind our actual load. Therefore, we declare
		 ourself loaded here since it wasn't done in other delegate method. */
		if (self.windowFrameObjectLoaded) {
			[self postViwLoadedJavaScript];
		}
	}
}

- (void)webView:(WebView *)sender didFinishLoadForFrame:(WebFrame *)frame
{
	if (self.windowFrameObjectLoaded == NO) {
		self.windowFrameObjectLoaded = YES;

		/* Only post view loaded from here if we have a web script object.
		 Otherwise, we wait until we have that before doing anything. */
		if (self.windowScriptObjectLoaded) {
			[self postViwLoadedJavaScript];
		}
	}
}

- (void)setUpScroller
{
	WebFrameView *frame = [[self.webView mainFrame] frameView];

	PointerIsEmptyAssert(frame);

	[self.webViewAutoScroller setWebFrame:frame];

	// ---- //

	NSScrollView *scrollView = nil;

	for (NSView *v in [frame subviews]) {
		if ([v isKindOfClass:[NSScrollView class]]) {
			scrollView = (NSScrollView *)v;

			break;
		}
	}

	PointerIsEmptyAssert(scrollView);

	[scrollView setHasHorizontalScroller:NO];
	[scrollView setHasVerticalScroller:NO];
}

#pragma mark -
#pragma mark LogView Delegate

- (void)logViewKeyDown:(NSEvent *)e
{
	[worldController() logKeyDown:e];
}

- (void)logViewRecievedDropWithFile:(NSString *)filename
{
	/* TVCLogPolicy guarantees that this delegate method is only called for private messages. */
	
	[menuController() memberSendDroppedFilesToSelectedChannel:@[filename]];
}

@end
