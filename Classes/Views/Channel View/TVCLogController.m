/* ********************************************************************* 
       _____        _               _    ___ ____   ____
      |_   _|___  _| |_ _   _  __ _| |  |_ _|  _ \ / ___|
       | |/ _ \ \/ / __| | | |/ _` | |   | || |_) | |
       | |  __/>  <| |_| |_| | (_| | |   | ||  _ <| |___
       |_|\___/_/\_\\__|\__,_|\__,_|_|  |___|_| \_\\____|

 Copyright (c) 2010 — 2013 Codeux Software & respective contributors.
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

#define _internalPlaybackLineCountLimit			100

@interface TVCLogController ()
@property (nonatomic, readonly, uweak) TPCThemeSettings *themeSettings;
@property (nonatomic, assign) BOOL historyLoaded;
@end

@implementation TVCLogController

#pragma mark -
#pragma mark Initialization

- (id)init
{
	if ((self = [super init])) {
		self.highlightedLineNumbers	= [NSMutableArray new];

		self.activeLineCount = 0;
		self.lastVisitedHighlight = -1;

		self.isLoaded = NO;
		self.reloadingBacklog = NO;
		self.reloadingHistory = NO;
		self.needsLimitNumberOfLines = NO;

		self.maximumLineCount = 300;
	}

	return self;
}

- (void)terminate
{
	[self closeHistoricLog];
}

- (void)preferencesChanged
{
	self.maximumLineCount = [TPCPreferences maxLogLines];
}

- (void)dealloc
{
	[NSObject cancelPreviousPerformRequestsWithTarget:self];
}

#pragma mark -
#pragma mark Create View

- (void)setUp
{
	if (self.view) {
		NSAssert(NO, @"View is already initialized.");
	}

	[self openHistoricLog];

	self.policy = [TVCLogPolicy new];

	self.sink = [TVCLogScriptEventSink new];
	self.sink.owner = self;

	self.view = [[TVCLogView alloc] initWithFrame:NSZeroRect];

	self.view.autoresizingMask		= (NSViewWidthSizable | NSViewHeightSizable);
	self.view.keyDelegate			= self;
	self.view.frameLoadDelegate		= self;
	self.view.resourceLoadDelegate	= self;
	self.view.policyDelegate		= self.policy;
	self.view.UIDelegate			= self.policy;

	self.view.shouldUpdateWhileOffscreen = NO;

	[self.view.preferences setCacheModel:WebCacheModelDocumentViewer];
	[self.view.preferences setUsesPageCache:NO];

	[self loadAlternateHTML:[self initialDocument:nil]];

	/* Change the font size to the one of others for new views. */
	NSInteger math = self.worldController.textSizeMultiplier;

	[self.view setTextSizeMultiplier:math];
}

- (void)loadAlternateHTML:(NSString *)newHTML
{
	NSColor *windowColor = self.themeSettings.underlyingWindowColor;

	if (PointerIsEmpty(windowColor)) {
		windowColor = [NSColor blackColor];
	}

	[(id)self.view setBackgroundColor:windowColor];

	[self.view.mainFrame loadHTMLString:newHTML baseURL:[self baseURL]];
}

#pragma mark -
#pragma mark Manage Historic Log

- (void)openHistoricLog
{
	if (PointerIsNotEmpty(self.historicLogFile)) {
		return;
	}

	self.historicLogFile = [TLOFileLogger new];
	self.historicLogFile.flatFileStructure = YES;
	self.historicLogFile.writePlainText = NO;
	self.historicLogFile.fileWritePath = [TPCPreferences applicationCachesFolderPath];
	self.historicLogFile.maxEntryCount = _internalPlaybackLineCountLimit;

	if (PointerIsEmpty(self.channel)) {
		self.historicLogFile.filenameOverride = self.client.config.itemUUID;
	} else {
		self.historicLogFile.filenameOverride = [NSString stringWithFormat:@"%@-%@", self.client.config.itemUUID, self.channel.name];
	}

	[self.historicLogFile reopenIfNeeded];

    if ([TPCPreferences reloadScrollbackOnLaunch] == NO) {
        /* Reset our file if we do not want to load historic items. */

        [self.historicLogFile reset];
    } else {
		if (self.historyLoaded == NO && (self.channel && self.channel.isPrivateMessage == NO)) {
			[self reloadHistory];
		}
	}
}

- (void)closeHistoricLog
{
	PointerIsEmptyAssert(self.historicLogFile);

	/* The historic log file is always open regardless of whether the user asked
	 Textual to remember the history between restarts. It is always open because
	 the reloading of a theme uses it to fill in the backlog after a reload.

	 closeHistoricLog is the point where we decide to actually save the file
	 or erase it. If the user has Textual configured to remember between restarts,
	 then we call a save before terminating. Or, we just erase the file from the
	 path that it is written to entirely. */

	if ([TPCPreferences reloadScrollbackOnLaunch] && (self.channel.isChannel && self.channel)) {
		[self.historicLogFile updateCache];
	} else {
		[self.historicLogFile reset];
	}

	self.historicLogFile = nil;
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

- (TPCThemeSettings *)themeSettings
{
	return self.masterController.themeController.customSettings;
}

- (NSURL *)baseURL
{
	return self.masterController.themeController.baseURL;
}

- (TVCLogControllerOperationQueue *)operationQueue
{
    return self.client.operationQueue;
}

- (NSString *)operationQueueHash
{
	if (self.channel) {
		return self.channel.treeUUID;
	}

	return self.client.treeUUID;
}

- (NSInteger)scrollbackCorrectionInit
{
	return (self.view.frame.size.height / 2);
}

- (DOMDocument *)mainFrameDocument
{
	return [self.view.mainFrame DOMDocument];
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

- (void)internalExecuteScriptCommand:(NSString *)command withArguments:(NSArray *)args
{
	WebScriptObject *js_api = [self.view javaScriptAPI];

	if (js_api && [js_api isKindOfClass:[WebUndefined class]] == NO) {
		[js_api callWebScriptMethod:command	withArguments:args];
	}
}

- (void)executeScriptCommand:(NSString *)command withArguments:(NSArray *)args
{
	[self executeScriptCommand:command withArguments:args onQueue:YES];
}

- (void)executeScriptCommand:(NSString *)command withArguments:(NSArray *)args onQueue:(BOOL)addToQueue
{
	void (^printBlock)(NSDictionary *context) = (TVCLogControllerOperationBlock)^{
		dispatch_sync(dispatch_get_main_queue(), ^{
			[self internalExecuteScriptCommand:command withArguments:args];
		});
	};

	if (addToQueue) {
		[self.operationQueue enqueueMessageBlock:(id)printBlock for:self];
	} else {
		printBlock(nil);
	}
}

#pragma mark -
#pragma mark Channel Topic Bar

- (NSString *)topicValue
{
	DOMElement *topicBar = [self documentChannelTopicBar];

	PointerIsEmptyAssertReturn(topicBar, NSStringEmptyPlaceholder);

	return [(id)topicBar innerHTML];
}

- (void)setTopic:(NSString *)topic
{
	if (NSObjectIsEmpty(topic)) {
		topic = TXTLS(@"IRCChannelEmptyTopic");
	}

	[self.operationQueue enqueueMessageBlock:^(NSDictionary *context) {
		dispatch_sync(dispatch_get_main_queue(), ^{
			if ([self.topicValue isEqualToString:topic] == NO)
			{
				DOMElement *topicBar = [self documentChannelTopicBar];

				PointerIsEmptyAssert(topicBar);

				NSString *body = [TVCLogRenderer renderBody:topic
												 controller:self
												 renderType:TVCLogRendererHTMLType
												 properties:@{@"renderLinks" : NSNumberWithBOOL(YES)}
												 resultInfo:NULL];

				[(id)topicBar setInnerHTML:body];

				[self internalExecuteScriptCommand:@"topicBarValueChanged" withArguments:@[topic]];
			}
		});
	} for:self];
}

#pragma mark -
#pragma mark Move to Bottom/Top

- (void)moveToTop
{
	NSAssertReturn(self.isLoaded);

	DOMDocument *doc = [self mainFrameDocument];
	PointerIsEmptyAssert(doc);

	DOMElement *body = [doc body];
	PointerIsEmptyAssert(body);

	[body setValue:@0 forKey:@"scrollTop"];

	[self internalExecuteScriptCommand:@"viewPositionMovedToTop" withArguments:@[]];
}

- (void)moveToBottom
{
	NSAssertReturn(self.isLoaded);

	/* Do not move during reloads. */
	NSAssertReturn(self.reloadingBacklog == NO);
	NSAssertReturn(self.reloadingHistory == NO);

	DOMDocument *doc = [self mainFrameDocument];
	PointerIsEmptyAssert(doc);

	DOMElement *body = [doc body];
	PointerIsEmptyAssert(body);

	[body setValue:[body valueForKey:@"scrollHeight"] forKey:@"scrollTop"];

	[self internalExecuteScriptCommand:@"viewPositionMovedToBottom" withArguments:@[]];
}

- (BOOL)viewingBottom
{
	NSAssertReturnR(self.isLoaded, NO);

	DOMDocument *doc = [self mainFrameDocument];
	PointerIsEmptyAssertReturn(doc, NO);

	DOMElement *body = [doc body];
	PointerIsEmptyAssertReturn(body, NO);

	NSInteger viewHeight = self.view.frame.size.height;

	NSInteger height = [[body valueForKey:@"scrollHeight"] integerValue];
	NSInteger scrtop = [[body valueForKey:@"scrollTop"] integerValue];

	NSAssertReturnR((viewHeight > 0), YES);

	return ((scrtop + viewHeight) >= height);
}

#pragma mark -
#pragma mark Add/Remove History Mark

- (void)mark
{
	[self.operationQueue enqueueMessageBlock:^(NSDictionary *context) {
		dispatch_sync(dispatch_get_main_queue(), ^{
			NSAssertReturn(self.isLoaded);

			DOMDocument *doc = [self mainFrameDocument];
			PointerIsEmptyAssert(doc);

			DOMElement *e = [doc getElementById:@"mark"];

			while (e) {
				[e.parentNode removeChild:e];

				e = [doc getElementById:@"mark"];
			}

			NSString *html = [TVCLogRenderer renderTemplate:@"historyIndicator"];

			[self appendToDocumentBody:html];
			
			[self internalExecuteScriptCommand:@"historyIndicatorAddedToView" withArguments:@[]];
		});
	} for:self];
}

- (void)unmark
{
	[self.operationQueue enqueueMessageBlock:^(NSDictionary *context) {
		dispatch_sync(dispatch_get_main_queue(), ^{
			NSAssertReturn(self.isLoaded);

			DOMDocument *doc = [self mainFrameDocument];
			PointerIsEmptyAssert(doc);

			DOMElement *e = [doc getElementById:@"mark"];

			while (e) {
				[e.parentNode removeChild:e];

				e = [doc getElementById:@"mark"];
			}

			[self internalExecuteScriptCommand:@"historyIndicatorRemovedFromView" withArguments:@[]];
		});
	} for:self];
}

- (void)goToMark
{
	if ([self jumpToElementID:@"mark"]) {
		[self internalExecuteScriptCommand:@"viewPositionMovedToHistoryIndicator" withArguments:@[]];
	}
}

#pragma mark -
#pragma mark Reload Scrollback

/* reloadOldLines: is supposed to be called from inside a queue. */
- (NSInteger)reloadOldLines:(BOOL)markHistoric
{
	/* What lines are we reloading? */
	NSDictionary *oldLines = self.historicLogFile.data;

	/* We have what we are going to load. Reset the old. */
	[self.historicLogFile reset];

	NSObjectIsEmptyAssertReturn(oldLines, 0);

	/* Sort the data we are going to reload and insert it into our
	 cache queue. After that, we will process the cache. */
	NSArray *keys = oldLines.sortedDictionaryKeys;

	for (NSString *key in keys) {
		TVCLogLine *line = [[TVCLogLine alloc] initWithDictionary:[oldLines objectForKey:key]];

		PointerIsEmptyAssertLoopContinue(line);

		if (markHistoric) {
			line.isHistoric = YES;
		}

		/* Special write tells print: that we want our write cached, not sent to the queue. */
		[self print:line specialWrite:YES completionBlock:NULL];
	}

	if (oldLines.count >= 1) {
		/* We have reached our next step. Now we will go through the cached operations and
		 build a string which will be appended to our document body. We build one big string
		 here instead of inserting one at a time. Quicker.(?) */
		NSMutableString *bodyAppend = [NSMutableString string];

		NSMutableArray *postedLineNumbers = [NSMutableArray array];

		NSArray *cachedOperations = [self.operationQueue cachedOperationsFor:self];

		/* Start HTML Loop. */
		for (NSArray *blockInfo in cachedOperations) {
			NSAssertReturnLoopContinue(blockInfo.count == 2);

			/* Execute the actual block. */
			/* Command+F "messageBlock_1" for details about this array. */
			NSArray *blockResult = ((TVCLogMessageBlock)blockInfo[0])();

			NSNumber *lineNumber = blockResult[0];

			PointerIsEmptyAssertLoopContinue(lineNumber);

			[postedLineNumbers safeAddObject:lineNumber];

			[bodyAppend appendString:blockResult[1]];
		}

		/* Append the HTML to WebKit. */
		dispatch_sync(dispatch_get_main_queue(), ^{
			[self appendToDocumentBody:bodyAppend];
			[self moveToTop]; // Keep view at top for the "loading screen" message.
			// This probably not best. What if a style has the screen alinged to the
			// bottom of the view?

			/* Post line numbers. */
			for (NSNumber *line in postedLineNumbers) {
				[self internalExecuteScriptCommand:@"newMessagePostedToView" withArguments:@[line]];
			}
		});

		/* Destroy cached items. */
		[self.operationQueue destroyCachedOperationsFor:self];

		/* Tell caller how much lines we reloaded. They might want to know
		 so that a mark can be added after them. Ya know? */
		return oldLines.count;
	}
	
	return 0;
}

- (void)reloadHistory
{
	self.reloadingHistory = YES;

	[self.operationQueue enqueueMessageBlock:^(NSDictionary *context) {
		NSInteger reloadCount =	[self reloadOldLines:YES];
		
		if (reloadCount >= 1) {
            [self mark];
		}

		self.reloadingHistory = NO;
		self.historyLoaded = YES;
	} for:self];
}

- (void)reloadTheme
{
	NSAssertReturn(self.reloadingHistory == NO);

	self.reloadingBacklog = YES;
	
	[self clearWithReset:NO];

	[self.operationQueue enqueueMessageBlock:^(NSDictionary *context) {
		NSInteger reloadCount =	[self reloadOldLines:NO];

		if (reloadCount >= 1) {
            [self mark];
		}

		self.reloadingBacklog = NO;

		[self executeScriptCommand:@"viewFinishedReload" withArguments:@[] onQueue:NO];
	} for:self];
}

#pragma mark -
#pragma mark Utilities

- (void)jumpToLine:(NSInteger)line
{
	NSString *lid = [NSString stringWithFormat:@"line%ld", line];

	if ([self jumpToElementID:lid]) {
		[self internalExecuteScriptCommand:@"viewPositionMovedToLine" withArguments:@[@(line)]];
	}
}

- (BOOL)jumpToElementID:(NSString *)elementID
{
	NSAssertReturnR(self.isLoaded, NO);

	DOMDocument *doc = [self mainFrameDocument];
	PointerIsEmptyAssertReturn(doc, NO);

	DOMElement *e = [doc getElementById:elementID];
	PointerIsEmptyAssertReturn(e, NO);

	NSInteger y = 0;

	DOMElement *t = e;

	while (t) {
		if ([t isKindOfClass:[DOMElement class]]) {
			y += [[t valueForKey:@"offsetTop"] integerValue];
		}

		t = (id)[t parentNode];
	}

	[doc.body setValue:@(y -  [self scrollbackCorrectionInit]) forKey:@"scrollTop"];

	return YES;
}

- (void)notifyDidBecomeVisible
{
	[self moveToBottom];
}

- (void)changeTextSize:(BOOL)bigger
{
	if (bigger) {
		[self.view makeTextLarger:nil];
	} else {
		[self.view makeTextSmaller:nil];
	}

	[self internalExecuteScriptCommand:@"viewFontSizeChanged" withArguments:@[@(bigger)]];
}

#pragma mark -
#pragma mark Manage Highlights

- (BOOL)highlightAvailable:(BOOL)previous
{
	NSObjectIsEmptyAssertReturn(self.highlightedLineNumbers, NO);

	if ([self.highlightedLineNumbers containsObject:@(self.lastVisitedHighlight)] == NO) {
		self.lastVisitedHighlight = [self.highlightedLineNumbers integerAtIndex:0];
	}

	if (previous && [self.highlightedLineNumbers integerAtIndex:0] == self.lastVisitedHighlight) {
		return NO;
	}

	if ((previous == NO) && [self.highlightedLineNumbers.lastObject integerValue] == self.lastVisitedHighlight) {
		return NO;
	}

	return YES;
}

- (void)nextHighlight
{
	NSAssertReturn(self.isLoaded);

	DOMDocument *doc = [self mainFrameDocument];
	PointerIsEmptyAssert(doc);

	NSObjectIsEmptyAssert(self.highlightedLineNumbers);

	id bhli = @(self.lastVisitedHighlight);

	if ([self.highlightedLineNumbers containsObject:bhli]) {
		NSInteger hli_ci = [self.highlightedLineNumbers indexOfObject:bhli];
		NSInteger hli_ei = [self.highlightedLineNumbers indexOfObject:self.highlightedLineNumbers.lastObject];

		if (hli_ci == hli_ei) {
			// Return method since the last highlight we
			// visited was the end of array. Nothing ahead.
		} else {
			self.lastVisitedHighlight = [self.highlightedLineNumbers integerAtIndex:(hli_ci + 1)];
		}
	} else {
		self.lastVisitedHighlight = [self.highlightedLineNumbers integerAtIndex:0];
	}

	[self jumpToLine:self.lastVisitedHighlight];
}

- (void)previousHighlight
{
	NSAssertReturn(self.isLoaded);

	DOMDocument *doc = [self mainFrameDocument];
	PointerIsEmptyAssert(doc);

	NSObjectIsEmptyAssert(self.highlightedLineNumbers);

	id bhli = @(self.lastVisitedHighlight);

	if ([self.highlightedLineNumbers containsObject:bhli]) {
		NSInteger hli_ci = [self.highlightedLineNumbers indexOfObject:bhli];

		if (hli_ci == 0) {
			// Return method since the last highlight we
			// visited was the start of array. Nothing ahead.
		} else {
			self.lastVisitedHighlight = [self.highlightedLineNumbers integerAtIndex:(hli_ci - 1)];
		}
	} else {
		self.lastVisitedHighlight = [self.highlightedLineNumbers integerAtIndex:0];
	}

	[self jumpToLine:self.lastVisitedHighlight];
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
	NSObjectIsEmptyAssert(self.highlightedLineNumbers);

	NSMutableArray *newList = [NSMutableArray array];

	for (NSNumber *lineNumber in self.highlightedLineNumbers) {
		NSString *lid = [NSString stringWithFormat:@"line%ld", lineNumber.integerValue];

		DOMElement *e = [doc getElementById:lid];

		/* If the element does not exist, then it means
		 that we removed it up above. */
		if (e) {
			[newList safeAddObject:lineNumber];
		}
	}

	self.highlightedLineNumbers = newList;
}

- (void)setNeedsLimitNumberOfLines
{
	if (self.needsLimitNumberOfLines) {
		return;
	}

	_needsLimitNumberOfLines = YES;

	[self limitNumberOfLines];
}

- (void)clearWithReset:(BOOL)resetQueue
{
	if (resetQueue) {
		[self.historicLogFile reset];
	}

	self.activeLineCount = 0;
	self.lastVisitedHighlight = -1;

	self.isLoaded = NO;
	//self.reloadingBacklog = NO;
	//self.reloadingHistory = NO;
	self.needsLimitNumberOfLines = NO;

	[self loadAlternateHTML:[self initialDocument:self.topicValue]];
}

- (void)clear
{
	[self clearWithReset:YES];
}

#pragma mark -
#pragma mark Print

- (NSString *)renderedBodyForTranscriptLog:(TVCLogLine *)line
{
	NSObjectIsEmptyAssertReturn(line.messageBody, nil);

	NSMutableString *s = [NSMutableString string];

	if (NSObjectIsNotEmpty(line.receivedAt)) {
		NSString *time = [line formattedTimestamp];

		[s appendString:time];
	}

	if (NSObjectIsNotEmpty(line.nickname)) {
		NSString *nick = [line formattedNickname:self.channel];
		
		[s appendString:nick];
		
		if ([nick hasSuffix:NSStringWhitespacePlaceholder] == NO) {
			[s appendString:NSStringWhitespacePlaceholder];
		}
	}

	[s appendString:line.messageBody];

	return [s stripIRCEffects];
}

#pragma mark -

- (void)print:(TVCLogLine *)logLine
{
	[self print:logLine specialWrite:NO completionBlock:NULL];
}

- (void)print:(TVCLogLine *)logLine completionBlock:(void(^)(BOOL highlighted))completionBlock
{
	[self print:logLine specialWrite:NO completionBlock:completionBlock];
}

/* isSpecial tells the printed line to be written into the cache queue. See TVCLogControllerOperationQueue.m
 for more information on how the actual cached queue is used. Also see -reloadOldLines: in this class. Special
 writes are designed to be used interanlly. Do not try and call this anywhere else. */
- (void)print:(TVCLogLine *)logLine specialWrite:(BOOL)isSpecial completionBlock:(void(^)(BOOL highlighted))completionBlock
{
	void (^printBlock)(NSDictionary *context) = (TVCLogControllerOperationBlock)^{
		TVCLogLine *line = logLine;
		
		NSObjectIsEmptyAssert(line.messageBody);

		// ************************************************************************** /
		// Render our body.                                                           /
		// ************************************************************************** /

		TVCLogLineType type = line.lineType;

		NSString *renderedBody = nil;
		NSString *lineTypeStng = [TVCLogLine lineTypeString:type];

		BOOL highlighted = NO;

		BOOL isPlainText = (type == TVCLogLinePrivateMessageType || type == TVCLogLineNoticeType || type == TVCLogLineActionType);
		BOOL isNormalMsg = (type == TVCLogLinePrivateMessageType || type == TVCLogLineActionType);

		BOOL drawLinks = BOOLReverseValue([TLOLinkParser.bannedURLRegexLineTypes containsObject:lineTypeStng]);

		NSArray *urlRanges;
		NSArray *mentionedUsers;

		// ---- //

		NSMutableDictionary *inputDictionary = [NSMutableDictionary dictionary];
		NSMutableDictionary *outputDictionary = [NSMutableDictionary dictionary];

		[inputDictionary safeSetObject:line.highlightKeywords forKey:@"highlightKeywords"];
		[inputDictionary safeSetObject:line.excludeKeywords forKey:@"excludeKeywords"];
		[inputDictionary safeSetObject:line.nickname forKey:@"nickname"];

		[inputDictionary setBool:drawLinks forKey:@"renderLinks"];
		[inputDictionary setBool:isNormalMsg forKey:@"isNormalMessage"];

		renderedBody = [TVCLogRenderer renderBody:line.messageBody
									   controller:self
									   renderType:TVCLogRendererHTMLType
									   properties:inputDictionary
									   resultInfo:&outputDictionary];

		urlRanges = [outputDictionary arrayForKey:@"URLRanges"];
		highlighted = [outputDictionary boolForKey:@"wordMatchFound"];
		mentionedUsers = [outputDictionary arrayForKey:@"mentionedUsers"];

		// ************************************************************************** /
		// Draw to display.                                                                /
		// ************************************************************************** /

		NSMutableDictionary *specialAttributes = [NSMutableDictionary new];

		specialAttributes[@"activeStyleAbsolutePath"] = [self baseURL].absoluteString;
		specialAttributes[@"applicationResourcePath"] = [TPCPreferences applicationResourcesFolderPath];

		NSMutableDictionary *attributes = specialAttributes;

		// ************************************************************************** /
		// Find all inline media.                                                     /
		// ************************************************************************** /

		NSMutableDictionary *inlineImageLinks = [NSMutableDictionary dictionary];

		if (isNormalMsg && [TPCPreferences showInlineImages]) {
			if (self.channel.config.ignoreInlineImages == NO) {
				for (NSValue *linkRange in urlRanges) {
					NSString *nurl = [line.messageBody safeSubstringWithRange:linkRange.rangeValue];
					NSString *iurl = [TVCImageURLParser imageURLFromBase:nurl];

					NSObjectIsEmptyAssertLoopContinue(iurl);

					if ([inlineImageLinks containsKey:iurl]) {
						continue;
					} else {
						[inlineImageLinks safeSetObject:nurl forKey:iurl];
					}
				}
			}
		}

		attributes[@"inlineMediaAvailable"] = @(NSObjectIsNotEmpty(inlineImageLinks));
		attributes[@"inlineMediaArray"]		= [NSMutableArray array];

		for (NSString *iurl in inlineImageLinks) {
			NSString *nurl = [inlineImageLinks objectForKey:iurl];

			[(id)attributes[@"inlineMediaArray"] addObject:@{
				 @"preferredMaximumWidth"	: @([TPCPreferences inlineImagesMaxWidth]),
				 @"anchorLink"				: [nurl stringWithValidURIScheme],
				 @"imageURL"				: [iurl stringWithValidURIScheme],
			 }];
		}

		// ---- //

		if (NSObjectIsNotEmpty(line.receivedAt)) {
			NSString *time = [line formattedTimestamp];

			attributes[@"formattedTimestamp"] = time;
		}

		// ---- //

		if (NSObjectIsNotEmpty(line.nickname)) {
			attributes[@"isNicknameAvailable"] = @(YES);

			attributes[@"nicknameColorNumber"]			= @(line.nicknameColorNumber);
			attributes[@"nicknameColorHashingEnabled"]	= @([TPCPreferences disableNicknameColorHashing] == NO);

			attributes[@"formattedNickname"]	= [line formattedNickname:self.channel].trim;

			attributes[@"nickname"]				= line.nickname;
			attributes[@"nicknameType"]			= [TVCLogLine memberTypeString:line.memberType];
		} else {
			attributes[@"isNicknameAvailable"] = @(NO);
		}

		// ---- //

		attributes[@"lineType"] = lineTypeStng;

		attributes[@"rawCommand"] = line.rawCommand;

		// ---- //

		NSString *classRep = NSStringEmptyPlaceholder;

		if (isPlainText) {
			classRep = @"text";
		} else {
			classRep = @"event";
		}

		if (line.isHistoric) {
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

		attributes[@"message"]				= line.messageBody;
		attributes[@"formattedMessage"]		= renderedBody;

		attributes[@"isRemoteMessage"]	= @(line.memberType == TVCLogMemberNormalType);
		attributes[@"isHighlight"]		= @(highlighted);

		// ---- //

		if (line.isEncrypted) {
			attributes[@"isEncrypted"] = @(line.isEncrypted);

			attributes[@"encryptedMessageLockTemplate"]	= [TVCLogRenderer renderTemplate:@"encryptedMessageLock" attributes:specialAttributes];
		}

		// ---- //

		attributes[@"configuredServerName"] = self.client.config.clientName;

		// ************************************************************************** /
		// Write to WebKit.															  /
		// ************************************************************************** /

		[self handlePrintBlockAppend:line withAttributes:attributes specialWrite:isSpecial];
		
		// ************************************************************************** /
		// Finish up.																  /
		// ************************************************************************** /

		if (highlighted && isSpecial == NO) {
			[self.worldController addHighlightInChannel:self.channel withLogLine:line];
		}
		
		/* Why reinvent the wheel with conversation detection. LogRenderer does that
		 automatically when color hashing UUID option is turned on. Which is default */
		if (NSObjectIsNotEmpty(mentionedUsers)) {
			dispatch_async(dispatch_get_main_queue(), ^{
				if (logLine.memberType == TVCLogMemberLocalUserType) {
					[mentionedUsers makeObjectsPerformSelector:@selector(outgoingConversation)];
				} else {
					[mentionedUsers makeObjectsPerformSelector:@selector(conversation)];
				}
			});
		}

		PointerIsEmptyAssert(completionBlock);
		
		dispatch_sync(dispatch_get_main_queue(), ^{
			/* Small rant:
				Well, this is not really a rant, but more of a discussion. 
			 
				I do not know why I comment all the stuff that I do now. I used to never 
				comment anything ever, but now I comment almost everything. I think it do
				it without thinking now just to remind myself of what something does as a
				future reference when doing work. Some stuff part of Textual is very complex
				these days compared to when it was originally forked. 
			 
				I mean, take a look at the print: call alone. How much it does just to put
				a message to the screen.
			 
				I think I like pretending Textual is bigger than it actually is. Like it is
				some big project. It really isn't. There is a law someone stated about that.
				I do not remember what it was who or said it, but it was something along the
				lines of: The more software is developed, the more it will tend to copy 
				projects larger than its own. 
			 
				I don't know where I am going with this discussion. I just think I write a 
				lot of comments. */
			
			completionBlock(highlighted);
		});
	};

	if (isSpecial) {
		printBlock(nil); // Call directly. Do not add queue item within a queue item.
	} else {
		[self.operationQueue enqueueMessageBlock:(id)printBlock for:self];
	}
}

- (void)handlePrintBlockAppend:(TVCLogLine *)line withAttributes:(NSMutableDictionary *)attributes specialWrite:(BOOL)isSpecial
{
	/* These go up, always. */
	self.activeLineNumber += 1;
	self.activeLineCount += 1;

	/* Reference for the blocks. */
	NSInteger newLinenNumber = self.activeLineNumber;

	/* 
		messageBlock_1 does several actions. The main action it does is convert the actual input line into
		the template HTML to append to WebKit. It also adds the line to the historic log as well as updating
		the list of highlighted line numbers. The return value is an array with two objects: 

		@[<LINE NUMBER>, <HTML>] 
	*/
	
	NSArray *(^messageBlock_1)(void) = (TVCLogMessageBlock)^{
		attributes[@"lineNumber"] = @(newLinenNumber);

		NSString *templateName = [self.themeSettings templateNameWithLineType:line.lineType];

		NSString *html = [TVCLogRenderer renderTemplate:templateName attributes:attributes];

		NSObjectIsEmptyAssertReturn(html, nil);

		if ([attributes[@"highlightAttributeRepresentation"] isEqualToString:@"true"]) {
			[self.highlightedLineNumbers safeAddObject:@(newLinenNumber)];
		}

		[self.historicLogFile writePropertyListEntry:[line dictionaryValue]
											   toKey:[@(newLinenNumber) integerWithLeadingZero:10]];

		return (__bridge void *)@[@(newLinenNumber), html];
	};

	/* What are we doing with what? */
	if (isSpecial) {
		[self.operationQueue enqueueMessageCachedBlock:[messageBlock_1 copy] for:self context:@{}];
	} else {
		/* Process it. */
		NSArray *blockInfo = messageBlock_1();
		
		dispatch_sync(dispatch_get_main_queue(), ^{
			/* WebKit wants everything on main. */
			
			[self appendToDocumentBody:blockInfo[1]];
			
			[self internalExecuteScriptCommand:@"newMessagePostedToView" withArguments:@[blockInfo[0]]];

			/* Limit lines. */
			if (isSpecial == NO) {
				if (self.maximumLineCount > 0 && (self.activeLineCount - 10) > self.maximumLineCount) {
					[self setNeedsLimitNumberOfLines];
				}
			}
		});
	}
}

#pragma mark -
#pragma mark Initial Document

- (NSString *)initialDocument:(NSString *)topic
{
	NSMutableDictionary *templateTokens = [self generateOverrideStyle];

	// ---- //

	templateTokens[@"activeStyleAbsolutePath"]	= [self baseURL].absoluteString;
	templateTokens[@"applicationResourcePath"]	= [TPCPreferences applicationResourcesFolderPath];

	templateTokens[@"cacheToken"]				= [NSString stringWithInteger:TXRandomNumber(5000)];

    templateTokens[@"configuredServerName"]     = self.client.config.clientName;

	templateTokens[@"userConfiguredTextEncoding"] = [NSString charsetRepFromStringEncoding:self.client.config.primaryEncoding];

    // ---- //

	if (self.channel) {
		templateTokens[@"isChannelView"]        = @(self.channel.isChannel);
        templateTokens[@"isPrivateMessageView"] = @(self.channel.isPrivateMessage);

		templateTokens[@"channelName"]	  = [TVCLogRenderer escapeString:self.channel.name];
		templateTokens[@"viewTypeToken"]  = [self.channel channelTypeString];

		if (NSObjectIsEmpty(topic)) {
			templateTokens[@"formattedTopicValue"] = TXTLS(@"IRCChannelEmptyTopic");
		} else {
			templateTokens[@"formattedTopicValue"] = topic;
		}
	} else {
		templateTokens[@"viewTypeToken"] = @"server";
	}

	// ---- //

	if ([TPCPreferences rightToLeftFormatting]) {
		templateTokens[@"textDirectionToken"] = @"rtl";
	} else {
		templateTokens[@"textDirectionToken"] = @"ltr";
	}

	// ---- //

	return [TVCLogRenderer renderTemplate:@"baseLayout" attributes:templateTokens];
}

- (NSMutableDictionary *)generateOverrideStyle
{
	NSMutableDictionary *templateTokens = [NSMutableDictionary dictionary];

	// ---- //

	NSFont *channelFont = self.themeSettings.channelViewFont;

	if (PointerIsEmpty(channelFont)) {
		channelFont = [TPCPreferences themeChannelViewFont];
	}

	templateTokens[@"userConfiguredFontName"] =   channelFont.fontName;
	templateTokens[@"userConfiguredFontSize"] = @(channelFont.pointSize * (72.0 / 96.0));

	// ---- //

	NSInteger indentOffset = self.themeSettings.indentationOffset;

	if (indentOffset == TXThemeDisabledIndentationOffset || [TPCPreferences rightToLeftFormatting]) {
		templateTokens[@"nicknameIndentationAvailable"] = @(NO);
	} else {
		templateTokens[@"nicknameIndentationAvailable"] = @(YES);

		NSString *time = TXFormattedTimestampWithOverride([NSDate date], [TPCPreferences themeTimestampFormat], self.themeSettings.timestampFormat);

		NSSize textSize = [time sizeWithAttributes:@{NSFontAttributeName : channelFont}];

		templateTokens[@"predefinedTimestampWidth"] = @(textSize.width + indentOffset);
	}

	// ---- //

	return templateTokens;
}

#pragma mark -

- (void)setUpScroller
{
	WebFrameView *frame = [self.view.mainFrame frameView];
	PointerIsEmptyAssert(frame);

	// ---- //

	if (PointerIsEmpty(self.autoScroller)) {
		self.autoScroller = [TVCWebViewAutoScroll new];
	}

	self.autoScroller.webFrame = frame;

	// ---- //

	NSScrollView *scrollView = nil;

	for (NSView *v in frame.subviews) {
		if ([v isKindOfClass:[NSScrollView class]]) {
			scrollView = (NSScrollView *)v;

			break;
		}
	}

	PointerIsEmptyAssert(scrollView);

	[scrollView setHasHorizontalScroller:NO];
	[scrollView setHasVerticalScroller:YES];
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
	LogToConsole(@"Log [%@] for channel [%@] on [%@] failed to load with error: %@",
				 [self description], [self.channel description], [self.client description], [error localizedDescription]);
}

- (void)webView:(WebView *)sender resource:(id)identifier didFailLoadingWithError:(NSError *)error fromDataSource:(WebDataSource *)dataSource
{
	LogToConsole(@"Resource [%@] in log [%@] failed loading for channel [%@] on [%@] with error: %@",
				 identifier, [self description], [self.channel description], [self.client description], [error localizedDescription]);
}

- (void)webView:(WebView *)sender didFailProvisionalLoadWithError:(NSError *)error forFrame:(WebFrame *)frame
{
	LogToConsole(@"Log [%@] for channel [%@] on [%@] failed provisional load with error: %@",
				 [self description], [self.channel description], [self.client description], [error localizedDescription]);
}

- (void)postViwLoadedJavaScript:(NSNumber *)loopCount
{
	/* Check for a valid script object. */

	WebScriptObject *js_api = [self.view javaScriptAPI];

	if (PointerIsEmpty(js_api) || [js_api isKindOfClass:[WebUndefined class]]) {
		NSInteger loopDepth = ([loopCount integerValue] + 1);

		/* The JavaScript object is not available yet, so instead of looking dumb
		 and letting our loading screen stay up forever because we cannot tell the 
		 style we are finished loading, we will instead loop this method a few times
		 using a timer hoping the object appears. */

		if (loopDepth <= 8) {
			[self performSelector:@selector(postViwLoadedJavaScript:)
					   withObject:@(loopDepth)
					   afterDelay:0.4]; // Post event every 400ms, 1/5 second.
		}

		return;
	}

	/* Post events. */
	NSString *viewType = @"server";

	if (self.channel) {
		viewType = [self.channel channelTypeString];
	}

	[self internalExecuteScriptCommand:@"viewInitiated" withArguments:@[
		NSStringNilValueSubstitute(viewType),
		NSStringNilValueSubstitute(self.client.config.itemUUID),
		NSStringNilValueSubstitute(self.channel.config.itemUUID),
		NSStringNilValueSubstitute(self.channel.name)
	 ]];

	if (self.reloadingBacklog == NO) {
		[self internalExecuteScriptCommand:@"viewFinishedLoading" withArguments:@[]];
	}
}

- (void)webView:(WebView *)sender didClearWindowObject:(WebScriptObject *)windowObject forFrame:(WebFrame *)frame
{
	[windowObject setValue:self.sink forKey:@"app"];
}

- (void)webView:(WebView *)sender didFinishLoadForFrame:(WebFrame *)frame
{
	[self postViwLoadedJavaScript:@(0)];
	
	self.isLoaded = YES;

	[self.operationQueue updateReadinessState:self];

	[self setUpScroller];
	[self moveToBottom];
}

#pragma mark -
#pragma mark LogView Delegate

- (void)logViewKeyDown:(NSEvent *)e
{
	[self.worldController logKeyDown:e];
}

- (void)logViewOnDoubleClick:(NSString *)e
{
	[self.worldController logDoubleClick:e];
}

@end
