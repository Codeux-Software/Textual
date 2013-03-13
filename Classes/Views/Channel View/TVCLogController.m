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

@interface TVCLogController ()
@property (nonatomic, readonly, uweak) TPCThemeSettings *themeSettings;
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
	self.historicLogFile.fileWritePath = [TPCPreferences applicationTemporaryFolderPath];
	self.historicLogFile.maxEntryCount = [TPCPreferences maxLogLines];

	if (PointerIsEmpty(self.channel)) {
		self.historicLogFile.filenameOverride = self.client.config.itemUUID;
	} else {
		self.historicLogFile.filenameOverride = [NSString stringWithFormat:@"%@-%@", self.client.config.itemUUID, self.channel.name];
	}

	[self.historicLogFile reopenIfNeeded];

    if ([TPCPreferences reloadScrollbackOnLaunch] == NO) {
        /* Reset our file if we do not want to load historic items. */

        [self.historicLogFile reset];
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

	if ([TPCPreferences reloadScrollbackOnLaunch] && (self.channel.isChannel || PointerIsEmpty(self.channel))) {
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

		self.historicLogFile.maxEntryCount = value;
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

- (void)executeScriptCommand:(NSString *)command withArguments:(NSArray *)args
{
	TVCLogMessageBlock (^messageBlock)(void) = [^{
		WebScriptObject *js_api = [self.view javaScriptAPI];

		if (js_api && [js_api isKindOfClass:[WebUndefined class]] == NO) {
			[js_api callWebScriptMethod:command	withArguments:args];
		}

		return nil;
	} copy];

    [self.operationQueue enqueueMessageBlock:messageBlock fromSender:self withContext:nil];
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

	TVCLogMessageBlock (^messageBlock)(void) = [^{
		if ([self.topicValue isEqualToString:topic] == NO)
		{
			DOMElement *topicBar = [self documentChannelTopicBar];

			PointerIsEmptyAssertReturn(topicBar, nil);

			NSString *body = [TVCLogRenderer renderBody:topic
											 controller:self
											 renderType:TVCLogRendererHTMLType
											 properties:@{@"renderLinks" : NSNumberWithBOOL(YES)}
											 resultInfo:NULL];

			[(id)topicBar setInnerHTML:body];

			[self executeScriptCommand:@"topicBarValueChanged" withArguments:@[topic]];
		}

		return nil;
	} copy];

    [self.operationQueue enqueueMessageBlock:messageBlock fromSender:self];
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

	[self executeScriptCommand:@"viewPositionMovedToTop" withArguments:@[]];
}

- (void)moveToBottom
{
	NSAssertReturn(self.isLoaded);

	DOMDocument *doc = [self mainFrameDocument];
	PointerIsEmptyAssert(doc);

	DOMElement *body = [doc body];
	PointerIsEmptyAssert(body);

	[body setValue:[body valueForKey:@"scrollHeight"] forKey:@"scrollTop"];

	[self executeScriptCommand:@"viewPositionMovedToBottom" withArguments:@[]];
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
	TVCLogMessageBlock (^messageBlock)(void) = [^{
		NSAssertReturnR(self.isLoaded, nil);

		DOMDocument *doc = [self mainFrameDocument];
		PointerIsEmptyAssertReturn(doc, nil);

		DOMElement *e = [doc getElementById:@"mark"];

		while (e) {
			[e.parentNode removeChild:e];

			e = [doc getElementById:@"mark"];
		}

		[self executeScriptCommand:@"historyIndicatorAddedToView" withArguments:@[]];

		NSString *html = [TVCLogRenderer renderTemplate:@"historyIndicator"];

		return (__bridge void *)html;
	} copy];

    [self.operationQueue enqueueMessageBlock:messageBlock fromSender:self];
}

- (void)unmark
{
	TVCLogMessageBlock (^messageBlock)(void) = [^{
		NSAssertReturnR(self.isLoaded, nil);

		DOMDocument *doc = [self mainFrameDocument];
		PointerIsEmptyAssertReturn(doc, nil);

		DOMElement *e = [doc getElementById:@"mark"];

		while (e) {
			[e.parentNode removeChild:e];

			e = [doc getElementById:@"mark"];
		}

		[self executeScriptCommand:@"historyIndicatorRemovedFromView" withArguments:@[]];

		return nil;
	} copy];

    [self.operationQueue enqueueMessageBlock:messageBlock fromSender:self];
}

- (void)goToMark
{
	if ([self jumpToElementID:@"mark"]) {
		[self executeScriptCommand:@"viewPositionMovedToHistoryIndicator" withArguments:@[]];
	}
}

#pragma mark -
#pragma mark Reload Scrollback

/* reloadOldLines: is supposed to be called from inside a queue. */
- (NSString *)reloadOldLines:(BOOL)markHistoric
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
		[self print:line withHTML:(line.lineType == TVCLogLineRawHTMLType) specialWrite:YES];
	}

	/* We have reached our next step. Now we will go through the cached operations and
	 build a string which will be appended to our document body. We build one big string
	 here instead of inserting one at a time. Quicker.(?) */
	
	if (oldLines.count >= 1) {
		NSMutableString *bodyAppend = [NSMutableString string];

		for (NSArray *blockInfo in self.operationQueue.cachedOperations) {
			NSAssertReturnLoopContinue(blockInfo.count == 3);

			TVCLogController *controller = blockInfo[1];

			/* Our queue may contain items from other controllers. We only
			 want our items so let us compare each item. */
			
			if (controller == self) {
				id blockResult = ((TVCLogMessageBlock)blockInfo[0])();

				if ([blockResult isKindOfClass:[NSString class]]) {
					[bodyAppend appendString:blockResult];
				}
			}
		}
		
		/* Destroy cached items. */
		[self.operationQueue destroyCachedOperationsFor:self];
		
		/* We are supposed to be in a secondary thread so tell Webkit on
		 the main thread that we want to append. Do not try this on anything
		 that is not the main thread. Webkit will beat you with a stick. */

		return bodyAppend;
	}

	return nil;
}

- (void)reloadHistory
{
	self.reloadingHistory = YES;

	TVCLogMessageBlock (^messageBlock)(void) = [^{
		NSString *reloadedLines = [self reloadOldLines:YES];

		if (reloadedLines) {
            [self mark];
		}
		
		self.reloadingHistory = NO;

		[self executeScriptCommand:@"viewFinishedLoading" withArguments:@[]];

		return reloadedLines;
	} copy];

    [self.operationQueue enqueueMessageBlock:messageBlock fromSender:self];
}

- (void)reloadTheme
{
	NSAssertReturn(self.reloadingHistory == NO);

	[self clearWithReset:NO];

	self.reloadingBacklog = YES;

	TVCLogMessageBlock (^messageBlock)(void) = [^{
		NSString *reloadedLines = [self reloadOldLines:NO];

        if (reloadedLines) {
            [self mark];
        }

		self.reloadingBacklog = NO;

		[self executeScriptCommand:@"viewFinishedReload" withArguments:@[]];

		return reloadedLines;
	} copy];

    [self.operationQueue enqueueMessageBlock:messageBlock fromSender:self];
}

#pragma mark -
#pragma mark Utilities

- (void)jumpToLine:(NSInteger)line
{
	NSString *lid = [NSString stringWithFormat:@"line%ld", line];

	if ([self jumpToElementID:lid]) {
		[self executeScriptCommand:@"viewPositionMovedToLine" withArguments:@[@(line)]];
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

	[self executeScriptCommand:@"viewFontSizeChanged" withArguments:@[@(bigger)]];
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
	self.reloadingBacklog = NO;
	self.reloadingHistory = NO;
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

- (BOOL)print:(TVCLogLine *)line
{
	return [self print:line withHTML:NO specialWrite:NO];
}

- (BOOL)print:(TVCLogLine *)line withHTML:(BOOL)stripHTML
{
	return [self print:line withHTML:stripHTML specialWrite:NO];
}

- (BOOL)print:(TVCLogLine *)line withHTML:(BOOL)rawHTML specialWrite:(BOOL)isSpecial
{
	NSObjectIsEmptyAssertReturn(line.messageBody, NO);

	if (rawHTML) {
		line.lineType = TVCLogLineRawHTMLType;
	}

	if ([NSThread isMainThread] == NO) {
		return [self.iomt print:line withHTML:rawHTML specialWrite:isSpecial];
	}

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

	NSArray *urlRanges = @[];

	// ---- //

	if (rawHTML == NO) {
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
	} else {
		renderedBody = line.messageBody;
	}

	// ************************************************************************** /
	// Draw to display.                                                                /
	// ************************************************************************** /

	NSMutableDictionary *specialAttributes = [NSMutableDictionary dictionary];

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
			@"imageURL"					: [iurl stringWithValidURIScheme],
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

    // ---- //

	[self writeLine:line attributes:attributes specialWrite:isSpecial];

	// ************************************************************************** /
	// Log highlight (if any).                                                    /
	// ************************************************************************** /

	if (highlighted && isSpecial == NO) {
		[self.worldController addHighlightInChannel:self.channel withLogLine:line];
	}

	return highlighted;
}

- (void)writeLine:(TVCLogLine *)line attributes:(NSMutableDictionary *)attributes specialWrite:(BOOL)isSpecial
{
	TVCLogMessageBlock (^messageBlock)(void) = [^{
		DOMElement *body = [self documentBody];
		PointerIsEmptyAssertReturn(body, nil);

		// ---- //

		self.activeLineNumber += 1;
		self.activeLineCount += 1;

		attributes[@"lineNumber"] = @(self.activeLineNumber);

		// ---- //

		NSString *html = [TVCLogRenderer renderTemplate:[self.themeSettings templateNameWithLineType:line.lineType]
											 attributes:attributes];

		NSObjectIsEmptyAssertReturn(html, nil);

		// ---- //

		if (isSpecial == NO) {
			if (self.maximumLineCount > 0 && (self.activeLineCount - 10) > self.maximumLineCount) {
				[self setNeedsLimitNumberOfLines];
			}
		}

		if ([attributes[@"highlightAttributeRepresentation"] isEqualToString:@"true"]) {
			[self.highlightedLineNumbers safeAddObject:@(self.activeLineNumber)];
		}

		[self executeScriptCommand:@"newMessagePostedToView" withArguments:@[@(self.activeLineNumber)]];

		[self.historicLogFile writePropertyListEntry:[line dictionaryValue]
											   toKey:[@(self.activeLineNumber) integerWithLeadingZero:10]];

		return (__bridge void *)html;
	} copy];

	[self.operationQueue enqueueMessageBlock:messageBlock
                                  fromSender:self
                                 withContext:@{@"cacheOperation" : @(isSpecial)}];
}

- (void)handleMessageBlock:(id)messageBlock withContext:(NSDictionary *)context
{
	// Internally, TVCLogMessageBlock should only return a NSString absolute value.

	dispatch_sync(dispatch_get_main_queue(), ^{
		id stslt = ((TVCLogMessageBlock)messageBlock)();

        if ([stslt isKindOfClass:[NSString class]]) {
            if (NSObjectIsNotEmpty(stslt)) {
                [self appendToDocumentBody:stslt];
            }
        }
	});
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

	if ([TPCPreferences useLogAntialiasing] == NO) {
		templateTokens[@"windowAntialiasingDisabled"] = @(YES);
	}

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

- (void)webView:(WebView *)sender resource:(id)identifier didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge fromDataSource:(WebDataSource *)dataSource
{
    [[challenge sender] cancelAuthenticationChallenge:challenge];
}

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

- (void)webView:(WebView *)sender didClearWindowObject:(WebScriptObject *)windowObject forFrame:(WebFrame *)frame
{
	[windowObject setValue:self.sink forKey:@"app"];
}

- (void)webView:(WebView *)sender didFinishLoadForFrame:(WebFrame *)frame
{
	NSString *viewType = @"server";
    
	if (self.channel) {
		viewType = [self.channel channelTypeString];
	}
    
	[self executeScriptCommand:@"viewInitiated" withArguments:@[
		 NSStringNilValueSubstitute(viewType),
		 NSStringNilValueSubstitute(self.client.config.itemUUID),
		 NSStringNilValueSubstitute(self.channel.config.itemUUID),
		 NSStringNilValueSubstitute(self.channel.name)
	 ]];
    
	if ([TPCPreferences reloadScrollbackOnLaunch] && self.reloadingBacklog == NO) {
		[self reloadHistory];
	} else {
		if (self.reloadingBacklog == NO) {
			[self executeScriptCommand:@"viewFinishedLoading" withArguments:@[]];
		}
	}
	
	[self.operationQueue updateReadinessState];

	self.isLoaded = YES;

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
