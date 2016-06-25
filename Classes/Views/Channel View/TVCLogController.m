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

NS_ASSUME_NONNULL_BEGIN

#define _enqueueBlock(operationBlock)			\
	[self.printingQueue enqueueMessageBlock:(operationBlock) for:self description:NSStringFromSelector(_cmd) isStandalone:NO];

#define _enqueueBlockStandalone(operationBlock)			\
	[self.printingQueue enqueueMessageBlock:(operationBlock) for:self description:NSStringFromSelector(_cmd) isStandalone:YES];

@interface TVCLogControllerPrintOperationContext ()
@property (nonatomic, weak, readwrite) IRCClient *client;
@property (nonatomic, weak, readwrite, nullable) IRCChannel *channel;
@property (nonatomic, assign, readwrite, getter=isHighlight) BOOL highlight;
@property (nonatomic, copy, readwrite) TVCLogLine *logLine;
@property (nonatomic, copy, readwrite) NSString *lineNumber;
@end

@interface TVCLogController ()
@property (nonatomic, assign, readwrite, getter=viewIsLoaded) BOOL loaded;
@property (readonly, getter=viewIsSelected) BOOL selected;
@property (readonly, getter=viewIsVisible) BOOL visible;
@property (nonatomic, assign) BOOL terminating;
@property (nonatomic, assign) BOOL reloadingBacklog;
@property (nonatomic, assign) BOOL reloadingHistory;
@property (nonatomic, assign) BOOL historyLoaded;
@property (nonatomic, assign) BOOL needsLimitNumberOfLines;
@property (nonatomic, assign) NSInteger activeLineCount;
@property (nonatomic, assign) NSUInteger maximumLineCount;
@property (nonatomic, copy) NSString *lastVisitedHighlight;
@property (nonatomic, strong) NSMutableArray<NSString *> *highlightedLineNumbers;
@property (nonatomic, strong, readwrite) TVCLogView *backingView;
@property (nonatomic, strong, readwrite) IRCClient *associatedClient;
@property (nonatomic, strong, readwrite, nullable) IRCChannel *associatedChannel;
@property (nonatomic, strong, readwrite) TVCMainWindow *attachedWindow;
@property (nonatomic, strong) TVCLogControllerHistoricLogFile *historicLogFile;
@property (readonly) TVCLogControllerOperationQueue *printingQueue;
@property (readonly, copy) NSURL *baseURL;
@end

NSString * const TVCLogControllerViewFinishedLoadingNotification = @"TVCLogControllerViewFinishedLoadingNotification";

@implementation TVCLogController

#pragma mark -
#pragma mark Initialization

ClassWithDesignatedInitializerInitMethod

- (instancetype)initWithClient:(IRCClient *)client inWindow:(TVCMainWindow *)window
{
	NSParameterAssert(client != nil);
	NSParameterAssert(window != nil);

	if ((self = [super init])) {
		self.associatedClient = client;

		self.attachedWindow = window;

		[self prepareInitialState];

		[self setUp];

		return self;
	}

	return nil;
}

- (instancetype)initWithChannel:(IRCChannel *)channel inWindow:(TVCMainWindow *)window
{
	NSParameterAssert(channel != nil);
	NSParameterAssert(window != nil);

	if ((self = [super init])) {
		self.associatedClient = channel.associatedClient;
		self.associatedChannel = channel;

		self.attachedWindow = window;

		[self prepareInitialState];

		[self setUp];

		return self;
	}

	return nil;
}

- (void)prepareInitialState
{
#if TEXTUAL_BUILT_WITH_ADVANCED_ENCRYPTION == 1
	self.encrypted = self.associatedChannel.encryptionStateIsEncrypted;
#endif

	self.highlightedLineNumbers	= [NSMutableArray new];

	self.maximumLineCount = [TPCPreferences scrollbackLimit];
}

- (void)prepareForTermination:(BOOL)isTerminatingApplication
{
	self.terminating = YES;

	self.loaded = NO;

	self.backingView = nil;

	[self.printingQueue cancelOperationsForViewController:self];

	[self closeHistoricLog:(isTerminatingApplication == NO)];

	self.historicLogFile = nil;
}

- (void)prepareForApplicationTermination
{
	[self prepareForTermination:YES];
}

- (void)prepareForPermanentDestruction
{
	[self prepareForTermination:NO];
}

- (void)preferencesChanged
{
	if (self.terminating) {
		return;
	}

	self.maximumLineCount = [TPCPreferences scrollbackLimit];
}

- (void)dealloc
{
	[self cancelPerformRequests];
}

#pragma mark -
#pragma mark Create View

- (void)setUp
{
	[self buildBackingView];

	[self loadInitialDocument];

	[self openHistoricLog];
}

- (void)buildBackingView
{
	self.backingView = [[TVCLogView alloc] initWithViewController:self];
}

- (void)rebuildBackingView
{
	[self buildBackingView];

	if (self.visible) {
		[self.attachedWindow updateChannelViewBoxContentViewSelection];
	}
}

- (void)loadInitialDocument
{
	[self loadAlternateHTML:[self initialDocument]];
}

- (void)loadAlternateHTML:(NSString *)newHTML
{
	NSParameterAssert(newHTML != nil);

	[self.backingView stopLoading];

	[self.backingView loadHTMLString:newHTML baseURL:self.baseURL];
}

#pragma mark -
#pragma mark Manage Historic Log

- (void)openHistoricLog
{
	self.historicLogFile = [[TVCLogControllerHistoricLogFile alloc] initWithViewController:self];

	if ([TPCPreferences reloadScrollbackOnLaunch] == NO) {
		self.historyLoaded = YES;
	} else {
		if (self.historyLoaded == NO && (self.associatedChannel &&
										(self.associatedChannel.isPrivateMessage == NO ||
										 [TPCPreferences rememberServerListQueryStates])))
		{
			[self reloadHistory];
		}
	}
}

- (void)closeHistoricLog
{
	[self closeHistoricLog:NO];
}

- (void)closeHistoricLog:(BOOL)forceReset
{
	/* The historic log file is always open regardless of whether the user asked
	 Textual to remember the history between restarts. It is always open because
	 the reloading of a theme uses it to fill in the backlog after a reload.
	 -closeHistoricLog is the point where we decide to actually save the file
	 or erase it. If the user has Textual configured to remember between restarts,
	 then we call a save before terminating. Or, we just erase the file from the
	 path that it is written to entirely. */

	if (self.encrypted || forceReset) {
		[self.historicLogFile reset]; // -reset calls -close on your behalf
	} else {
		if ([TPCPreferences reloadScrollbackOnLaunch] == NO ||
			  self.associatedChannel == nil ||
			(self.associatedChannel.isChannel == NO &&
			 [TPCPreferences rememberServerListQueryStates] == NO))
		{
			[self.historicLogFile reset];
		} else {
			[self.historicLogFile close];
		}
	}
}

#pragma mark -
#pragma mark Properties

- (void)setMaximumLineCount:(NSUInteger)maximumLineCount
{
	if (self->_maximumLineCount != maximumLineCount) {
		self->_maximumLineCount = maximumLineCount;

		[self limitNumberOfLinesIfNeeded];
	}
}

- (void)setEncrypted:(BOOL)encrypted
{
	if (self->_encrypted != encrypted) {
		self->_encrypted = encrypted;

		if (self->_encrypted) {
			[self closeHistoricLog];
		}
	}
}

- (NSString *)uniqueIdentifier
{
	if (self.associatedChannel) {
		return self.associatedChannel.uniqueIdentifier;
	} else {
		return self.associatedClient.uniqueIdentifier;
	}
}

- (NSURL *)baseURL
{
	if (themeController().usesTemporaryPath) {
		NSString *temporaryPath = themeController().temporaryPath;

		return [NSURL fileURLWithPath:temporaryPath isDirectory:YES];
	}

	return themeController().baseURL;
}

- (TVCLogControllerOperationQueue *)printingQueue
{
    return self.associatedClient.printingQueue;
}

- (BOOL)inlineMediaEnabledForView
{
	if (self.associatedChannel == nil) {
		return NO;
	}

	/* If global showInlineImages is YES, then the value of ignoreInlineImages is designed to
	 be as it is named. Disable them for specific channels. However if showInlineImages is NO
	 on a global scale, then ignoreInlineImages actually enables them for specific channels. */
	return (([TPCPreferences showInlineImages]			&& self.associatedChannel.config.ignoreInlineImages == NO) ||
			([TPCPreferences showInlineImages] == NO	&& self.associatedChannel.config.ignoreInlineImages));
}

- (BOOL)viewIsSelected
{
	return (self.attachedWindow.selectedViewController == self);
}

- (BOOL)viewIsVisible
{
	if (self.associatedChannel) {
		return [self.attachedWindow isItemVisible:self.associatedChannel];
	} else {
		return [self.attachedWindow isItemVisible:self.associatedClient];
	}
}

#pragma mark -
#pragma mark Document Append & JavaScript Controller

- (void)evaluateFunction:(NSString *)function withArguments:(nullable NSArray *)arguments
{
	[self evaluateFunction:function withArguments:arguments onQueue:YES];
}

- (void)evaluateFunction:(NSString *)function withArguments:(nullable NSArray *)arguments onQueue:(BOOL)onQueue
{
	NSParameterAssert(function != nil);

	if (self.terminating) {
		return;
	}

	if (onQueue) {
		TVCLogControllerOperationBlock scriptBlock = ^(id operation) {
			[self performBlockOnMainThread:^{
				[self _evaluateFunction:function withArguments:arguments];
			}];
		};

		_enqueueBlock(scriptBlock)
	} else {
		[self _evaluateFunction:function withArguments:arguments];
	}
}

- (void)_evaluateFunction:(NSString *)function withArguments:(nullable NSArray *)arguments
{
	NSParameterAssert(function != nil);

	if (self.loaded == NO || self.terminating) {
		return;
	}

	[self.backingView evaluateFunction:function withArguments:arguments];
}

- (void)appendToDocumentBody:(NSString *)html
{
	NSParameterAssert(html != nil);

	[self _evaluateFunction:@"Textual.documentBodyAppend" withArguments:@[html]];
}

#pragma mark -
#pragma mark Channel Topic Bar

- (void)setInitialTopic
{
	NSString *topic = self.associatedChannel.topic;

	[self setTopic:topic];
}

- (void)setTopic:(nullable NSString *)topic
{
	if (self.terminating) {
		return;
	}

	TVCLogControllerOperationBlock operationBlock = ^(id operation) {
		NSString *topicString = nil;

		if (topic == nil || topic.length == 0) {
			topicString = TXTLS(@"IRC[1038]");
		} else {
			topicString = topic;
		}

		NSString *topicTemplate = [TVCLogRenderer renderBody:topicString
										   forViewController:self
											  withAttributes:@{
													TVCLogRendererConfigurationRenderLinksAttribute : @YES,
													TVCLogRendererConfigurationLineTypeAttribute : @(TVCLogLineTopicType)
															}
												  resultInfo:NULL];

		[self performBlockOnMainThread:^{
			[self _evaluateFunction:@"Textual.setTopicBarValue" withArguments:@[topicString, topicTemplate]];
		}];
	};

	_enqueueBlock(operationBlock)
}

#pragma mark -
#pragma mark Move to Bottom/Top

- (void)moveToTop
{
	[self _evaluateFunction:@"Textual.scrollToTopOfView" withArguments:@[@(YES)]];
}

- (void)moveToBottom
{
	[self _evaluateFunction:@"Textual.scrollToBottomOfView" withArguments:@[@(YES)]];
}

#pragma mark -
#pragma mark Add/Remove History Mark

- (void)mark
{
	NSString *markTemplate = [TVCLogRenderer renderTemplate:@"historyIndicator"];

	[self _evaluateFunction:@"Textual.historyIndicatorAdd" withArguments:@[markTemplate]];
}

- (void)unmark
{
	[self _evaluateFunction:@"Textual.historyIndicatorRemove" withArguments:nil];
}

- (void)goToMark
{
	[self _evaluateFunction:@"Textual.scrollToHistoryIndicator" withArguments:nil];
}

#pragma mark -
#pragma mark Reload Scrollback

- (void)appendHistoricMessageFragment:(NSString *)html isReload:(BOOL)isReload
{
	NSParameterAssert(html != nil);

	[self _evaluateFunction:@"Textual.documentBodyAppendHistoric" withArguments:@[html, @(isReload)]];
}

/* reloadOldLines: is supposed to be called from inside a queue. */
- (void)reloadOldLines:(NSArray<NSData *> *)oldLines markHistoric:(BOOL)markHistoric
{
	NSParameterAssert(oldLines != nil);

	NSMutableArray<NSString *> *lineNumbers = [NSMutableArray array];

	NSMutableString *patchedAppend = [NSMutableString string];

	NSMutableData *newHistoricArchive = [NSMutableData data];

	NSMutableArray<THOPluginDidPostNewMessageConcreteObject *> *pluginObjects = nil;

	for (NSData *chunkedData in oldLines) {
		TVCLogLineMutable *logLine = [[TVCLogLineMutable alloc] initWithJSONData:chunkedData];

		if (logLine == nil) {
			continue;
		}

		if (markHistoric) {
			logLine.isHistoric = YES;
		}

		/* Render result info HTML */
		NSDictionary<NSString *, id> *resultInfo = nil;

		NSString *html = [self renderLogLine:logLine resultInfo:&resultInfo];

		if (html == nil) {
			LogToConsoleError("Failed to render log line %{public}@", logLine.description)

			continue;
		}

		[patchedAppend appendString:html];

		/* Record information about rendering */
		NSString *lineNumber = logLine.uniqueIdentifier;

		[lineNumbers addObject:lineNumber];

		/* Add reference to plugin concrete object */
		THOPluginDidPostNewMessageConcreteObject *pluginObject = resultInfo[@"pluginConcreteObject"];

		if (pluginObject) {
			if (pluginObjects == nil) {
				pluginObjects = [NSMutableArray array];
			}

			[pluginObjects addObject:pluginObject];
		}

		/* Create a new entry for result */
		[newHistoricArchive appendData:logLine.jsonRepresentation];

		[newHistoricArchive appendData:[NSData lineFeed]];

		/* Record highlights */
		BOOL highlighted = [resultInfo boolForKey:TVCLogRendererResultsKeywordMatchFoundAttribute];

		if (highlighted) {
			@synchronized(self.highlightedLineNumbers) {
				[self.highlightedLineNumbers addObject:lineNumber];
			}
		}
	}

	/* Record new entries */
	[self.historicLogFile reset];

	[self.historicLogFile writeNewEntryWithData:newHistoricArchive];

	/* Render the result in WebKit */
	[self performBlockOnMainThread:^{
		self.activeLineCount += lineNumbers.count;

		[self appendHistoricMessageFragment:patchedAppend isReload:(markHistoric == NO)];

		[self mark];

		[self _evaluateFunction:@"Textual.newMessagePostedToViewInt" withArguments:@[lineNumbers]];
	}];

	/* Inform plugins of new content */
	for (THOPluginDidPostNewMessageConcreteObject *pluginObject in pluginObjects) {
		pluginObject.isProcessedInBulk = YES;

		[THOPluginDispatcher didPostNewMessage:pluginObject forViewController:self];
	}
}

- (void)reloadHistory
{
	if (self.terminating) {
		return;
	}

	if (self.encrypted) {
		self.historyLoaded = YES;

		return;
	}

	self.reloadingHistory = YES;

	TVCLogControllerOperationBlock operationBlock = ^(id operation) {
		NSArray *objects = [self.historicLogFile listEntriesWithFetchLimit:100];

		[self reloadHistoryCompletionBlock:objects];
	};

	_enqueueBlockStandalone(operationBlock)
}

- (void)reloadHistoryCompletionBlock:(NSArray<NSData *> *)objects
{
	NSParameterAssert(objects != nil);

	[self reloadOldLines:objects markHistoric:YES];

	self.reloadingHistory = NO;

	self.historyLoaded = YES;
}

- (void)reloadTheme
{
	if (self.terminating) {
		return;
	}

	if (self.reloadingHistory) {
		return;
	}

	self.reloadingBacklog = YES;

	[self clearWithReset:NO];

	if (self.encrypted) {
		self.reloadingBacklog = NO;

		return;
	}

	TVCLogControllerOperationBlock operationBlock = ^(id operation) {
		NSArray *objects = [self.historicLogFile listEntriesWithFetchLimit:1000];
		
		[self.historicLogFile reset];
		
		[self reloadThemeCompletionBlock:objects];
	};

	_enqueueBlockStandalone(operationBlock)
}

- (void)reloadThemeCompletionBlock:(NSArray<NSData *> *)objects
{
	NSParameterAssert(objects != nil);

	[self reloadOldLines:objects markHistoric:NO];

	self.reloadingBacklog = NO;
}

#pragma mark -
#pragma mark Utilities

- (void)jumpToLine:(NSString *)lineNumber
{
	[self jumpToLine:lineNumber completionHandler:nil];
}

- (void)jumpToLine:(NSString *)lineNumber completionHandler:(void (^ _Nullable)(BOOL result))completionHandler
{
	NSParameterAssert(lineNumber != nil);

	[self.backingView booleanByEvaluatingFunction:@"Textual.scrollToLine"
								  withArguments:@[lineNumber]
							  completionHandler:completionHandler];
}

- (void)notifyDidBecomeVisible /* When the view is switched to */
{
	[self _evaluateFunction:@"Textual.notifyDidBecomeVisible" withArguments:nil];
}

- (void)notifySelectionChanged
{
	[self _evaluateFunction:@"Textual.notifySelectionChanged" withArguments:@[@(self.selected)]];
}

- (void)notifyDidBecomeHidden
{
	[self _evaluateFunction:@"Textual.notifyDidBecomeHidden" withArguments:nil];
}

- (void)changeTextSize:(BOOL)bigger
{
	double sizeMultiplier = worldController().textSizeMultiplier;

	[self _evaluateFunction:@"Textual.changeTextSizeMultiplier" withArguments:@[@(sizeMultiplier)]];

	[self _evaluateFunction:@"Textual.viewFontSizeChanged" withArguments:@[@(bigger)]];
}

#pragma mark -
#pragma mark Manage Highlights

- (BOOL)highlightAvailable:(BOOL)previous
{
	if (self.loaded == NO || self.terminating) {
		return NO;
	}

	@synchronized(self.highlightedLineNumbers) {
		if (self.highlightedLineNumbers.count == 0) {
			return NO;
		}

		NSUInteger lastHighlightIndex = NSNotFound;

		if ([self.highlightedLineNumbers containsObject:self.lastVisitedHighlight]) {
			lastHighlightIndex = [self.highlightedLineNumbers indexOfObject:self.lastVisitedHighlight];
		}

		if (previous == NO) {
			if (lastHighlightIndex == (self.highlightedLineNumbers.count - 1)) {
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
	if (self.loaded == NO || self.terminating) {
		return;
	}
	
	@synchronized(self.highlightedLineNumbers) {
		if (self.highlightedLineNumbers.count == 0) {
			return;
		}

		if ([self.highlightedLineNumbers containsObject:self.lastVisitedHighlight]) {
			NSUInteger hli_ci = [self.highlightedLineNumbers indexOfObject:self.lastVisitedHighlight];

			if (hli_ci == (self.highlightedLineNumbers.count - 1)) {
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
	if (self.loaded == NO || self.terminating) {
		return;
	}

	@synchronized(self.highlightedLineNumbers) {
		if (self.highlightedLineNumbers.count == 0) {
			return;
		}

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

- (NSUInteger)numberOfLines
{
	return self.activeLineCount;
}

- (void)limitNumberOfLines
{
	if (self.loaded == NO || self.terminating) {
		return;
	}

	self.needsLimitNumberOfLines = NO;

	NSInteger n = (self.activeLineCount - self.maximumLineCount);

	if (n <= 0 || self.activeLineCount <= 0) {
		return;
	}

	self.activeLineCount -= n;

	if (self.activeLineCount < 0) {
		self.activeLineCount = 0;
	}

	[self.backingView arrayByEvaluatingFunction:@"Textual.reduceNumberOfLines"
								withArguments:@[@(n)]
							completionHandler:^(NSArray *result) {
								if (result == nil) {
									return;
								}

								@synchronized(self.highlightedLineNumbers) {
									[self.highlightedLineNumbers removeObjectsInArray:result];
								}
							}];
}

- (void)limitNumberOfLinesIfNeeded
{
	if (self.loaded == NO || self.terminating) {
		return;
	}

	if (self.maximumLineCount > 0 && self.activeLineCount > self.maximumLineCount) {
		[self setNeedsLimitNumberOfLines];
	}
}

- (void)setNeedsLimitNumberOfLines
{
	if (self.loaded == NO || self.terminating) {
		return;
	}

	if (self.needsLimitNumberOfLines) {
		return;
	}

	self.needsLimitNumberOfLines = YES;

	[self limitNumberOfLines];
}

- (void)clearWithReset:(BOOL)resetQueue
{
	[self performBlockOnMainThread:^{
		[self.printingQueue cancelOperationsForViewController:self];

		if (resetQueue) {
			[self.historicLogFile reset];
		}
		
		@synchronized(self.highlightedLineNumbers) {
			[self.highlightedLineNumbers removeAllObjects];
		}
		
		self.activeLineCount = 0;

		self.lastVisitedHighlight = nil;

		self.loaded = NO;

		self.needsLimitNumberOfLines = NO;

		if (self.backingView.isUsingWebKit2 != [TPCPreferences webKit2Enabled]) {
			[self rebuildBackingView];
		}

		[self loadInitialDocument];
	}];
}

- (void)clear
{
	if (self.terminating) {
		return;
	}

	[self clearWithReset:YES];
}

- (void)clearBackingView
{
	if (self.terminating) {
		return;
	}

	[self rebuildBackingView];

	[self clearWithReset:YES];
}

#pragma mark -
#pragma mark Print

- (void)print:(TVCLogLine *)logLine
{
	[self print:logLine completionBlock:NULL];
}

- (void)print:(TVCLogLine *)logLine completionBlock:(nullable TVCLogControllerPrintOperationCompletionBlock)completionBlock
{
	NSParameterAssert(logLine != nil);

	if (self.terminating) {
		return;
	}

	if ([logLine isKindOfClass:[TVCLogLineMutable class]]) {
		logLine = [logLine copy];
	}

	TVCLogControllerOperationBlock printBlock = ^(id operation) {
		NSDictionary<NSString *, id> *resultInfo = nil;
		
		NSString *html = [self renderLogLine:logLine resultInfo:&resultInfo];

		if (html == nil) {
			LogToConsoleError("Failed to render log line %{public}@", logLine.description)

			return;
		}

		self.activeLineCount += 1;

		NSString *lineNumber = logLine.uniqueIdentifier;

		NSDictionary<NSString *, NSString *> *listOfInlineImages = [resultInfo dictionaryForKey:@"InlineImagesToValidate"];

		NSSet<IRCUser *> *listOfUsers = resultInfo[TVCLogRendererResultsListOfUsersFoundAttribute];

		BOOL highlighted = [resultInfo boolForKey:TVCLogRendererResultsKeywordMatchFoundAttribute];
		
		[self performBlockOnMainThread:^{
			if (highlighted) {
				@synchronized(self.highlightedLineNumbers) {
					[self.highlightedLineNumbers addObject:lineNumber];
				}

				[self.associatedClient cacheHighlightInChannel:self.associatedChannel withLogLine:logLine];
			}

			[self appendToDocumentBody:html];

			[self _evaluateFunction:@"Textual.newMessagePostedToViewInt" withArguments:@[lineNumber]];

			if ([sharedPluginManager() supportsFeature:THOPluginItemSupportsNewMessagePostedEvent]) {
				[THOPluginDispatcher didPostNewMessage:resultInfo[@"pluginConcreteObject"] forViewController:self];
			}

			/* Only cut lines if our number is divisible by 5. This makes it so every
			 line is not using resources. */
			if ((self.activeLineCount % 5) == 0) {
				[self limitNumberOfLinesIfNeeded];
			}

			/* Begin processing inline images */
			/* We go through the inline image list here and pass to the loader now so that
			 we know the links have hit the webview before we even try loading them. */
			[listOfInlineImages enumerateKeysAndObjectsUsingBlock:^(NSString *uniqueId, NSString *imageUrl, BOOL *stop) {
				TVCImageURLoader *imageLoader = [TVCImageURLoader new];

				imageLoader.delegate = (id)self;

				[imageLoader assesURL:imageUrl withId:uniqueId];
			}];
			
			/* Log this log line */
			/* If the channel is encrypted, then we refuse to write to
			 the actual historic log so there is no trace of the chatter
			 on the disk in the form of an unencrypted cache file. */
			/* Doing it this way does break the ability to reload chatter
			 in the view as well as playback on restart, but the added
			 security can be seen as a bonus. */
			if (self.encrypted == NO) {
				[self.historicLogFile writeNewEntryWithLogLine:logLine];
			}

			/* Using informationi provided by conversation tracking we can update 
			 our internal array of favored nicknames for nick completion. */
			if (logLine.memberType == TVCLogLineMemberLocalUserType) {
				[listOfUsers.allObjects makeObjectsPerformSelector:@selector(outgoingConversation)];
			} else {
				[listOfUsers.allObjects makeObjectsPerformSelector:@selector(conversation)];
			}

			if (completionBlock == nil) {
				return;
			}

			 TVCLogControllerPrintOperationContext *contextObject =
			[TVCLogControllerPrintOperationContext new];

			contextObject.client = self.associatedClient;
			contextObject.channel = self.associatedChannel;
			contextObject.highlight = highlighted;
			contextObject.logLine = logLine;
			contextObject.lineNumber = lineNumber;

			completionBlock(contextObject);
		}];
	};

	_enqueueBlock(printBlock)
}

- (nullable NSString *)renderLogLine:(TVCLogLine *)logLine resultInfo:(NSDictionary<NSString *, id> **)resultInfo
{
	NSParameterAssert(logLine != nil);

	// ************************************************************************** /

	TVCLogLineType lineType = logLine.lineType;

	NSString *lineTypeString = logLine.lineTypeString;

	BOOL renderLinks = ([[TLOLinkParser bannedLineTypes] containsObject:lineTypeString] == NO);

	NSMutableDictionary<NSString *, id> *rendererAttributes = [NSMutableDictionary dictionary];

	[rendererAttributes maybeSetObject:logLine.excludeKeywords forKey:TVCLogRendererConfigurationExcludedKeywordsAttribute];
	[rendererAttributes maybeSetObject:logLine.highlightKeywords forKey:TVCLogRendererConfigurationHighlightKeywordsAttribute];
	
	[rendererAttributes setBool:renderLinks forKey:TVCLogRendererConfigurationRenderLinksAttribute];

	[rendererAttributes setUnsignedInteger:logLine.lineType forKey:TVCLogRendererConfigurationLineTypeAttribute];
	[rendererAttributes setUnsignedInteger:logLine.memberType forKey:TVCLogRendererConfigurationMemberTypeAttribute];

	NSDictionary<NSString *, id> *rendererResults = nil;

	NSString *renderedBody =
	[TVCLogRenderer renderBody:logLine.messageBody
			 forViewController:self
				withAttributes:rendererAttributes
					resultInfo:&rendererResults];

	if (renderedBody == nil) {
		return nil;
	}

	NSMutableDictionary<NSString *, id> *resultInfoTemp = [rendererResults mutableCopy];

	BOOL highlighted = [rendererResults boolForKey:TVCLogRendererResultsKeywordMatchFoundAttribute];

	NSArray<AHHyperlinkScannerResult *> *linksInBody = rendererResults[TVCLogRendererResultsListOfLinksInBodyAttribute];

	// ************************************************************************** /

	NSMutableDictionary<NSString *, id> *pathAttributes = [NSMutableDictionary new];

	pathAttributes[@"activeStyleAbsolutePath"] = self.baseURL.path;
	
	pathAttributes[@"applicationResourcePath"] = [TPCPathInfo applicationResourcesFolderPath];

	NSMutableDictionary<NSString *, id> *templateAttributes = [pathAttributes mutableCopy];

	// ************************************************************************** /

	if (self.inlineMediaEnabledForView == NO ||
		(lineType != TVCLogLinePrivateMessageType && lineType != TVCLogLineActionType))
	{
		templateAttributes[@"inlineMediaAvailable"] = @(NO);
	}
	else
	{
		// Array of attributes for template to render HTML for each image
		NSMutableArray<NSDictionary *> *inlineImageAttributes = [NSMutableArray array];

		// Array to keep track of images so that duplicates aren't processed
		NSMutableArray<NSString *> *inlineImagesProcessed = [NSMutableArray array];

		// Array of images whoes content will be loaded to ensure they are actually images
		NSMutableDictionary<NSString *, NSString *> *inlineImagesToValidate = [NSMutableDictionary dictionary];

		for (AHHyperlinkScannerResult *link in linksInBody) {
			NSString *imageUrl = [TVCImageURLParser imageURLFromBase:link.stringValue];

			if (imageUrl == nil) {
				continue;
			}

			if ([inlineImagesProcessed containsObject:imageUrl]) {
				continue;
			}

			[inlineImageAttributes addObject:@{
				  @"preferredMaximumWidth"		: @([TPCPreferences inlineImagesMaxWidth]),
				  @"anchorInlineImageUniqueID"	: link.uniqueIdentifier,
				  @"anchorLink"					: link.stringValue,
				  @"imageURL"					: imageUrl,
			}];

			[inlineImagesProcessed addObject:imageUrl];

			inlineImagesToValidate[link.uniqueIdentifier] = imageUrl;
		}

		templateAttributes[@"inlineMediaArray"]	= inlineImageAttributes;
		
		templateAttributes[@"inlineMediaAvailable"] = @(inlineImagesProcessed.count > 0);

		resultInfoTemp[@"InlineImagesToValidate"] = inlineImagesToValidate;
	}

	// ---- //

	templateAttributes[@"timestamp"] = @(logLine.receivedAt.timeIntervalSince1970);

	templateAttributes[@"formattedTimestamp"] = logLine.formattedTimestamp;

	// ---- //

	NSString *nickname = [logLine formattedNicknameInChannel:self.associatedChannel];

	if (nickname.length == 0) {
		templateAttributes[@"isNicknameAvailable"] = @(NO);
	} else {
		templateAttributes[@"isNicknameAvailable"] = @(YES);
		
		templateAttributes[@"nicknameColorNumber"] = logLine.nicknameColorStyle;
		templateAttributes[@"nicknameColorStyle"] = logLine.nicknameColorStyle;

		templateAttributes[@"nicknameColorStyleOverride"] = @(logLine.nicknameColorStyleOverride);

		templateAttributes[@"nicknameColorHashingEnabled"] = @([TPCPreferences disableNicknameColorHashing] == NO);

		templateAttributes[@"nicknameColorHashingIsStyleBased"] = @(themeSettings().nicknameColorStyle != TPCThemeSettingsNicknameColorLegacyStyle);
		
		templateAttributes[@"formattedNickname"] = nickname.trim;
		
		templateAttributes[@"nickname"]	= logLine.nickname;
		templateAttributes[@"nicknameType"]	= logLine.memberTypeString;
	}

	// ---- //

	templateAttributes[@"lineType"] = lineTypeString;

	templateAttributes[@"command"] = logLine.command;
	templateAttributes[@"rawCommand"] = logLine.command; // Legacy key

	// ---- //

	NSString *classAttribute = nil;

	if (lineType == TVCLogLinePrivateMessageType || lineType == TVCLogLineActionType || lineType == TVCLogLineNoticeType) {
		classAttribute = @"text";
	} else {
		classAttribute = @"event";
	}

	if (logLine.isHistoric) {
		classAttribute = [classAttribute stringByAppendingString:@" historic"];
	}

	templateAttributes[@"lineClassAttributeRepresentation"] = classAttribute;

	// ---- //

	if (highlighted) {
		templateAttributes[@"highlightAttributeRepresentation"] = @"true";
	} else {
		templateAttributes[@"highlightAttributeRepresentation"] = @"false";
	}

	// ---- //

	templateAttributes[@"message"] = logLine.messageBody;

	templateAttributes[@"formattedMessage"]	= renderedBody;

	templateAttributes[@"isHighlight"] = @(highlighted);

	templateAttributes[@"isRemoteMessage"] = @(logLine.memberType == TVCLogLineMemberNormalType);

	// ---- //

	if (logLine.isEncrypted) {
		templateAttributes[@"isEncrypted"] = @(YES);

		templateAttributes[@"encryptedMessageLockTemplate"] =
		[TVCLogRenderer renderTemplate:@"encryptedMessageLock" attributes:pathAttributes];
	}

	// ---- //

	NSString *serverName = self.associatedClient.altNetworkName;
	
	if (serverName) {
		templateAttributes[@"configuredServerName"] = serverName;
	}
	
	// ---- //

	templateAttributes[@"lineNumber"] = logLine.uniqueIdentifier;

	templateAttributes[@"lineRenderTime"] = @([NSDate timeIntervalSince1970]);

	// ************************************************************************** /

	if ([sharedPluginManager() supportsFeature:THOPluginItemSupportsNewMessagePostedEvent]) {
		 THOPluginDidPostNewMessageConcreteObject *pluginConcreteObject =
		[THOPluginDidPostNewMessageConcreteObject new];

		pluginConcreteObject.keywordMatchFound = highlighted;

		pluginConcreteObject.lineType = lineType;
		pluginConcreteObject.memberType = logLine.memberType;

		pluginConcreteObject.senderNickname = logLine.nickname;

		pluginConcreteObject.receivedAt = logLine.receivedAt;

		pluginConcreteObject.lineNumber = logLine.uniqueIdentifier;

		pluginConcreteObject.messageContents = rendererResults[TVCLogRendererResultsOriginalBodyWithoutEffectsAttribute];

		pluginConcreteObject.listOfHyperlinks = linksInBody;

		pluginConcreteObject.listOfUsers = rendererResults[TVCLogRendererResultsListOfUsersFoundAttribute];

		resultInfoTemp[@"pluginConcreteObject"] = pluginConcreteObject;
	}

	// ************************************************************************** /

	if ( resultInfo) {
		*resultInfo = resultInfoTemp;
	}

	// ************************************************************************** /

	NSString *templateName = [themeSettings() templateNameWithLineType:lineType];

	NSString *html = [TVCLogRenderer renderTemplate:templateName attributes:templateAttributes];

	return html;
}

- (void)isSafeToPresentImageWithId:(NSString *)uniqueId
{
	[self _evaluateFunction:@"Textual.toggleInlineImageReally" withArguments:@[uniqueId]];
}

- (void)isNotSafeToPresentImageWithId:(NSString *)uniqueId
{
	;
}

#pragma mark -
#pragma mark Initial Document

- (BOOL)usesCustomScrollers
{
	BOOL onlyShowDuringScrolling = [TXUserInterface onlyShowScrollbarWhileScrolling];

	BOOL usesCustomScrollers = [TPCPreferences themeChannelViewUsesCustomScrollers];

	BOOL usingWebKit2 = self.backingView.isUsingWebKit2;

	return (onlyShowDuringScrolling == NO && usesCustomScrollers && usingWebKit2);
}

- (NSString *)initialDocument
{
	NSMutableDictionary *templateTokens = [self generateOverrideStyle];

	templateTokens[@"activeStyleAbsolutePath"] = self.baseURL.path;
	
	templateTokens[@"applicationResourcePath"] = [TPCPathInfo applicationResourcesFolderPath];

    templateTokens[@"configuredServerName"] = self.associatedClient.altNetworkName;

	templateTokens[@"operatingSystemVersion"] = [XRSystemInformation systemStandardVersion];

	templateTokens[@"sidebarInversionIsEnabled"] = @([TPCPreferences invertSidebarColors]);

	templateTokens[@"userConfiguredTextEncoding"] = [NSString charsetRepFromStringEncoding:self.associatedClient.config.primaryEncoding];

	templateTokens[@"usesCustomScrollers"] = @([self usesCustomScrollers]);

	if (self.associatedChannel) {
		templateTokens[@"isChannelView"] = @(self.associatedChannel.isChannel);
        templateTokens[@"isPrivateMessageView"] = @(self.associatedChannel.isPrivateMessage);

		templateTokens[@"channelName"] = self.associatedChannel.name;
		
		templateTokens[@"viewTypeToken"] = self.associatedChannel.channelTypeString;
	} else {
		templateTokens[@"viewTypeToken"] = @"server";
	}

	if ([TPCPreferences rightToLeftFormatting]) {
		templateTokens[@"textDirectionToken"] = @"rtl";
	} else {
		templateTokens[@"textDirectionToken"] = @"ltr";
	}

	return [TVCLogRenderer renderTemplate:@"baseLayout" attributes:templateTokens];
}

- (NSMutableDictionary<NSString *, id> *)generateOverrideStyle
{
	NSMutableDictionary<NSString *, id> *templateTokens = [NSMutableDictionary dictionary];

	// ---- //

	NSFont *channelFont = themeSettings().themeChannelViewFont;

	if (channelFont == nil) {
		channelFont = [TPCPreferences themeChannelViewFont];
	}

	templateTokens[@"userConfiguredFontName"] =   channelFont.fontName;
	templateTokens[@"userConfiguredFontSize"] = @(channelFont.pointSize * (72.0 / 96.0));

	// ---- //

	NSInteger indentOffset = themeSettings().indentationOffset;

	if (indentOffset == TPCThemeSettingsDisabledIndentationOffset || [TPCPreferences rightToLeftFormatting]) {
		templateTokens[@"nicknameIndentationAvailable"] = @(NO);
	} else {
		templateTokens[@"nicknameIndentationAvailable"] = @(YES);
		
		NSString *timeFormat = themeSettings().themeTimestampFormat;
		
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
#pragma mark LogView Delegate

- (void)logViewWebViewFinishedLoading
{
	NSString *viewType = nil;

	if (self.associatedChannel) {
		viewType = self.associatedChannel.channelTypeString;
	} else {
		viewType = @"server";
	}

	self.loaded = YES;

	[self _evaluateFunction:@"Textual.viewInitiated" withArguments:@[
		 NSDictionaryNilValue(viewType),
		 NSDictionaryNilValue(self.associatedClient.uniqueIdentifier),
		 NSDictionaryNilValue(self.associatedChannel.uniqueIdentifier),
		 NSDictionaryNilValue(self.associatedChannel.name)
	]];

	double textSizeMultiplier = worldController().textSizeMultiplier;

	[self _evaluateFunction:@"Textual.viewFinishedLoadingInt"
					  withArguments:@[@(self.selected),
									  @(self.visible),
									  @(self.reloadingBacklog),
									  @(textSizeMultiplier)]];

	[self setInitialTopic];

	[RZNotificationCenter() postNotificationName:TVCLogControllerViewFinishedLoadingNotification object:self];

	[self.printingQueue updateReadinessState:self];
}

- (void)logViewWebViewClosedUnexpectedly
{
	[self clearBackingView];
}

- (void)logViewWebViewKeyDown:(NSEvent *)e
{
	[self.attachedWindow redirectKeyDown:e];
}

- (void)logViewWebViewRecievedDropWithFile:(NSString *)filename
{
	[menuController() memberSendDroppedFilesToSelectedChannel:@[filename]];
}

@end

#pragma mark -

@implementation TVCLogControllerPrintOperationContext
@end

NS_ASSUME_NONNULL_END
