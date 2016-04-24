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

#define _enqueueBlock(operationBlock)			\
	[[self printingQueue] enqueueMessageBlock:(operationBlock) for:self description:NSStringFromSelector(_cmd) isStandalone:NO];

#define _enqueueBlockStandalone(operationBlock)			\
	[[self printingQueue] enqueueMessageBlock:(operationBlock) for:self description:NSStringFromSelector(_cmd) isStandalone:YES];

@interface TVCLogController ()
@property (nonatomic, assign) BOOL isTerminating;
@property (nonatomic, assign) BOOL historyLoaded;
@property (nonatomic, copy) NSString *lastVisitedHighlight;
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
		
		self.needsLimitNumberOfLines = NO;

		self.maximumLineCount = 300;
	}

	return self;
}

- (void)prepareForApplicationTermination
{
	self.isTerminating = YES;

	self.isLoaded = NO;

	self.backingView = nil;

	[[self printingQueue] cancelOperationsForViewController:self];
	
	[self closeHistoricLog:NO];

	self.historicLogFile = nil;
}

- (void)prepareForPermanentDestruction
{
	self.isTerminating = YES;

	self.isLoaded = NO;

	self.backingView = nil;

	[[self printingQueue] cancelOperationsForViewController:self];
	
	[self closeHistoricLog:YES]; // YES forces a file deletion.

	self.historicLogFile = nil;
}

- (void)preferencesChanged
{
	NSAssertReturn(self.isTerminating == NO);

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
	/* Load initial document. */
	[self buildBackingView];

	[self loadInitialDocument];

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
	[self openHistoricLog];
}

- (void)buildBackingView
{
	self.backingView = [[TVCLogView alloc] initWithLogController:self];
}

- (void)rebuildBackingView
{
	self.backingView = nil;

	[self buildBackingView];

	if ([self isVisible]) {
		[mainWindow() updateChannelViewBoxContentViewSelection];
	}
}

- (void)loadInitialDocument
{
	[self loadAlternateHTML:[self initialDocument]];
}

- (void)loadAlternateHTML:(NSString *)newHTML
{
	[self.backingView stopLoading];

	[self.backingView loadHTMLString:newHTML baseURL:[self baseURL]];
}

#pragma mark -
#pragma mark Manage Historic Log

- (void)openHistoricLog
{
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

- (void)setMaximumLineCount:(NSInteger)maximumLineCount
{
	if (_maximumLineCount != maximumLineCount) {
		_maximumLineCount = maximumLineCount;

		NSAssertReturn(self.isLoaded);

		if (self.maximumLineCount > 0 && self.activeLineCount > self.maximumLineCount) {
			[self setNeedsLimitNumberOfLines];
		}
	}
}

- (void)setViewIsEncrypted:(BOOL)viewIsEncrypted
{
	if (_viewIsEncrypted != viewIsEncrypted) {
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
	if ([themeController() usesTemporaryPath] == NO) {
		return [themeController() baseURL];
	} else {
		NSString *temporaryPath = [themeController() temporaryPath];

		return [NSURL fileURLWithPath:temporaryPath];
	}
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

- (BOOL)isSelected
{
	return ([mainWindow() selectedViewController] == self);
}

- (BOOL)isVisible
{
	if (self.associatedChannel) {
		return [mainWindow() isItemVisible:self.associatedChannel];
	} else {
		return [mainWindow() isItemVisible:self.associatedClient];
	}
}

#pragma mark -
#pragma mark Document Append & JavaScript Controller

- (void)evaluateFunction:(NSString *)function withArguments:(NSArray *)arguments
{
	[self evaluateFunction:function withArguments:arguments onQueue:YES];
}

- (void)evaluateFunction:(NSString *)function withArguments:(NSArray *)arguments onQueue:(BOOL)onQueue
{
	NSAssertReturn(self.isTerminating == NO);

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

- (void)_evaluateFunction:(NSString *)function withArguments:(NSArray *)arguments
{
	NSAssertReturn(self.isLoaded);
	NSAssertReturn(self.isTerminating == NO);

	[self.backingView evaluateFunction:function withArguments:arguments];
}

- (void)appendToDocumentBody:(NSString *)html
{
	[self _evaluateFunction:@"Textual.documentBodyAppend" withArguments:@[html]];
}

#pragma mark -
#pragma mark Channel Topic Bar

- (void)setInitialTopic
{
	PointerIsEmptyAssert(self.associatedChannel);

	NSString *topic = [self.associatedChannel topic];

	if (NSObjectIsEmpty(topic) == NO) {
		[self setTopic:topic];
	}
}

- (void)setTopic:(NSString *)topic
{
	NSAssertReturn(self.isTerminating == NO);

	TVCLogControllerOperationBlock operationBlock = ^(id operation) {
		NSString *topicString = nil;

		if (NSObjectIsEmpty(topic)) {
			topicString = TXTLS(@"IRC[1038]");
		} else {
			topicString = topic;
		}

		NSString *topicTemplate = [TVCLogRenderer renderBody:topicString
											   forController:self
											  withAttributes:@{
													TVCLogRendererConfigurationShouldRenderLinksAttribute : @YES,
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
	[self _evaluateFunction:@"Textual.documentBodyAppendHistoric" withArguments:@[html, @(isReload)]];
}

/* reloadOldLines: is supposed to be called from inside a queue. */
- (void)reloadOldLines:(BOOL)markHistoric withOldLines:(NSArray *)oldLines
{
	NSObjectIsEmptyAssert(oldLines);

	/* Only create lines if plugins need them. Else, its just useless memroy. */
	NSMutableArray *lines = nil;

	if ([sharedPluginManager() supportsFeature:THOPluginItemSupportsNewMessagePostedEvent]) {
		lines = [NSMutableArray array];
	}

	/* Create temporary stores and begin process data */
	NSMutableArray *lineNumbers = [NSMutableArray array];

	NSMutableString *patchedAppend = [NSMutableString string];

	NSMutableData *newHistoricArchive = [NSMutableData data];

	for (NSData *chunkedData in oldLines) {
		/* Convert JSON information to a format that Textual understands */
		TVCLogLine *line = (id)[[TVCLogLine alloc] initWithRawJSONData:chunkedData];

		PointerIsEmptyAssertLoopContinue(line);

		/* Set historic */
		if (markHistoric) {
			[line setIsHistoric:YES];
		}

		/* Render result info HTML */
		NSDictionary *resultInfo = nil;

		NSString *html = [self renderLogLine:line resultInfo:&resultInfo];

		NSObjectIsEmptyAssertLoopContinue(html);

		[patchedAppend appendString:html];

		/* Record information about rendering */
		NSString *lineNumber = resultInfo[@"lineNumber"];

		[lineNumbers addObject:lineNumber];

		if (lines) {
			[lines addObject:resultInfo];
		}

		/* Create a new entry for result */
		NSData *jsondata = [line jsonDictionaryRepresentation];

		[newHistoricArchive appendData:jsondata];

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
	[self.historicLogFile writeNewEntryWithRawData:newHistoricArchive];

	/* Render the result in WebKit */
	[self performBlockOnMainThread:^{
		self.activeLineCount += [lineNumbers count];

		[self appendHistoricMessageFragment:patchedAppend isReload:(markHistoric == NO)];

		[self mark];

		[self _evaluateFunction:@"Textual.newMessagePostedToViewInt" withArguments:@[lineNumbers]];
	}];

	/* Inform plugins of new content */
	for (NSDictionary *resultInfo in lines) {
		THOPluginDidPostNewMessageConcreteObject *pluginConcreteObject = resultInfo[@"pluginConcreteObject"];

		[pluginConcreteObject setIsProcessedInBulk:YES];

		[sharedPluginManager() postNewMessageEventForViewController:self withObject:pluginConcreteObject];
	}
}

- (void)reloadHistory
{
	NSAssertReturn(self.isTerminating == NO);

	self.historyLoaded = YES;

	if (self.viewIsEncrypted == NO)
	{
		self.reloadingHistory = YES;

		TVCLogControllerOperationBlock operationBlock = ^(id operation) {
			NSArray *objects = [self.historicLogFile listEntriesWithFetchLimit:100];

			[self.historicLogFile resetData];

			[self reloadHistoryCompletionBlock:objects];
		};

		_enqueueBlockStandalone(operationBlock)
	}
}

- (void)reloadHistoryCompletionBlock:(NSArray *)objects
{
	[self reloadOldLines:YES withOldLines:objects];

	self.reloadingHistory = NO;
}

- (void)reloadTheme
{
	NSAssertReturn(self.isTerminating == NO);

	if (self.reloadingHistory == NO) {
		self.reloadingBacklog = YES;

		[self clearWithReset:NO];

		if (self.viewIsEncrypted == NO)
		{
			TVCLogControllerOperationBlock operationBlock = ^(id operation) {
				NSArray *objects = [self.historicLogFile listEntriesWithFetchLimit:1000];
				
				[self.historicLogFile resetData];
				
				[self reloadThemeCompletionBlock:objects];
			};

			_enqueueBlockStandalone(operationBlock)
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

	self.reloadingBacklog = NO;
}

#pragma mark -
#pragma mark Utilities

- (void)jumpToLine:(NSString *)lineNumber
{
	[self jumpToLine:lineNumber completionHandler:nil];
}

- (void)jumpToLine:(NSString *)lineNumber completionHandler:(void (^)(BOOL))completionHandler
{
	[self.backingView booleanByEvaluatingFunction:@"Textual.scrollToLine"
								  withArguments:@[lineNumber]
							  completionHandler:completionHandler];
}

- (void)notifyDidBecomeVisible /* When the view is switched to. */
{
	[self _evaluateFunction:@"Textual.notifyDidBecomeVisible" withArguments:nil];
}

- (void)notifySelectionChanged
{
	BOOL isSelected = [self isSelected];

	[self _evaluateFunction:@"Textual.notifySelectionChanged" withArguments:@[@(isSelected)]];
}

- (void)notifyDidBecomeHidden
{
	[self _evaluateFunction:@"Textual.notifyDidBecomeHidden" withArguments:nil];
}

- (void)changeTextSize:(BOOL)bigger
{
	double sizeMultiplier = [worldController() textSizeMultiplier];

	[self _evaluateFunction:@"Textual.changeTextSizeMultiplier" withArguments:@[@(sizeMultiplier)]];

	[self _evaluateFunction:@"Textual.viewFontSizeChanged" withArguments:@[@(bigger)]];
}

#pragma mark -
#pragma mark Manage Highlights

- (BOOL)highlightAvailable:(BOOL)previous
{
	NSAssertReturnR(self.isLoaded, NO);
	NSAssertReturnR((self.isTerminating == NO), NO);

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
	NSAssertReturn(self.isTerminating == NO);
	
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
	NSAssertReturn(self.isTerminating == NO);

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

- (NSInteger)numberOfLines
{
	return self.activeLineCount;
}

- (void)limitNumberOfLines
{
	NSAssertReturn(self.isTerminating == NO);

	self.needsLimitNumberOfLines = NO;

	NSInteger n = (self.activeLineCount - self.maximumLineCount);

	if (self.isLoaded == NO || n <= 0 || self.activeLineCount <= 0) {
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

		self.isLoaded = NO;
	 // self.reloadingBacklog = NO;
	 // self.reloadingHistory = NO;
		self.needsLimitNumberOfLines = NO;

		if ([self.backingView isUsingWebKit2] != [TPCPreferences webKit2Enabled]) {
			[self rebuildBackingView];
		}

		[self loadInitialDocument];
	}];
}

- (void)clear
{
	NSAssertReturn(self.isTerminating == NO);

	[self clearWithReset:YES];
}

- (void)clearBackingView
{
	NSAssertReturn(self.isTerminating == NO);

	[self rebuildBackingView];

	[self clearWithReset:YES];
}

#pragma mark -
#pragma mark Print

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
	NSAssertReturn(self.isTerminating == NO);

	/* Continue with a normal print job. */
	TVCLogControllerOperationBlock printBlock = ^(id operation) {
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

					[self.associatedClient cacheHighlightInChannel:self.associatedChannel withLogLine:logLine lineNumber:lineNumber];
				}

				/* Do the actual append to WebKit. */
				[self appendToDocumentBody:html];

				/* Inform the style of the new append. */
				[self _evaluateFunction:@"Textual.newMessagePostedToViewInt" withArguments:@[lineNumber]];
				
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

				/* Finish up. */
				PointerIsEmptyAssert(completionBlock);

				completionBlock(highlighted);
			}];
		}
	};

	_enqueueBlock(printBlock)
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

	specialAttributes[@"activeStyleAbsolutePath"] = [[self baseURL] path];
	
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

			attributes[@"nicknameColorStyleOverride"] = @([line nicknameColorStyleOverride]);

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
	[self _evaluateFunction:@"Textual.toggleInlineImageReally" withArguments:@[uniqueID]];
}

- (void)isNotSafeToPresentImageWithID:(NSString *)uniqueID
{
	;
}

#pragma mark -
#pragma mark Initial Document

- (BOOL)usesCustomScrollers
{
	BOOL onlyShowDuringScrolling = [TXUserInterface onlyShowScrollbarWhileScrolling];

	BOOL usesCustomScrollers = [TPCPreferences themeChannelViewUsesCustomScrollers];

	BOOL usingWebKit2 = [self.backingView isUsingWebKit2];

	return (onlyShowDuringScrolling == NO && usesCustomScrollers && usingWebKit2);
}

- (NSString *)initialDocument
{
	NSMutableDictionary *templateTokens = [self generateOverrideStyle];

	// ---- //

	templateTokens[@"activeStyleAbsolutePath"]	= [[self baseURL] path];
	
	templateTokens[@"applicationResourcePath"]	= [TPCPathInfo applicationResourcesFolderPath];

    templateTokens[@"configuredServerName"]     = [self.associatedClient altNetworkName];

	templateTokens[@"userConfiguredTextEncoding"] = [NSString charsetRepFromStringEncoding:self.associatedClient.config.primaryEncoding];

	templateTokens[@"usesCustomScrollers"] = @([self usesCustomScrollers]);

    // ---- //

	if (self.associatedChannel) {
		templateTokens[@"isChannelView"]        = @([self.associatedChannel isChannel]);
        templateTokens[@"isPrivateMessageView"] = @([self.associatedChannel isPrivateMessage]);

		templateTokens[@"channelName"]	  = [TVCLogRenderer escapeString:[self.associatedChannel name]];
		
		templateTokens[@"viewTypeToken"]  = [self.associatedChannel channelTypeString];
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
#pragma mark LogView Delegate

- (void)logViewWebViewFinishedLoading
{
	/* Post events. */
	NSString *viewType = @"server";

	if (self.associatedChannel) {
		viewType = [self.associatedChannel channelTypeString];
	}

	self.isLoaded = YES;

	[self _evaluateFunction:@"Textual.viewInitiated" withArguments:@[
		 NSDictionaryNilValue(viewType),
		 NSDictionaryNilValue([self.associatedClient uniqueIdentifier]),
		 NSDictionaryNilValue([self.associatedChannel uniqueIdentifier]),
		 NSDictionaryNilValue([self.associatedChannel name])
	]];

	double textSizeMultiplier = [worldController() textSizeMultiplier];

	[self _evaluateFunction:@"Textual.viewFinishedLoadingInt"
					  withArguments:@[@([self isVisible]),
									  @([self isSelected]),
									  @(self.reloadingBacklog),
									  @(textSizeMultiplier)]];

	[self setInitialTopic];

	[RZNotificationCenter() postNotificationName:TVCLogControllerViewFinishedLoadingNotification object:self];

	[[self printingQueue] updateReadinessState:self];
}

- (void)logViewWebViewClosedUnexpectedly
{
	[self clearBackingView];
}

- (void)logViewWebViewKeyDown:(NSEvent *)e
{
	[mainWindow() redirectKeyDown:e];
}

- (void)logViewWebViewRecievedDropWithFile:(NSString *)filename
{
	[menuController() memberSendDroppedFilesToSelectedChannel:@[filename]];
}

@end
