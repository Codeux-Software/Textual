/* ********************************************************************* 
       _____        _               _    ___ ____   ____
      |_   _|___  _| |_ _   _  __ _| |  |_ _|  _ \ / ___|
       | |/ _ \ \/ / __| | | |/ _` | |   | || |_) | |
       | |  __/>  <| |_| |_| | (_| | |   | ||  _ <| |___
       |_|\___/_/\_\\__|\__,_|\__,_|_|  |___|_| \_\\____|

 Copyright (c) 2010 — 2012 Codeux Software & respective contributors.
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

#define _bottomEpsilon		0

@implementation TVCLogController

- (id)init
{
	if ((self = [super init])) {
		self.bottom        = YES;
		self.maxLines      = 300;
		
		self.messageQueue			= [NSMutableArray new];
		self.highlightedLineNumbers	= [NSMutableArray new];
		
		[[WebPreferences standardPreferences] setCacheModel:WebCacheModelDocumentViewer];
		[[WebPreferences standardPreferences] setUsesPageCache:NO];
	}
	
	return self;
}

- (void)dealloc
{
	[NSObject cancelPreviousPerformRequestsWithTarget:self];
	
	self.queueInProgress = NO;
	[self destroyViewLoop];
}

#pragma mark -
#pragma mark Properties

- (void)setMaxLines:(NSInteger)value
{
	if (self.maxLines == value) return;
	_maxLines = value;
	
	if (self.loaded == NO) return;
	
	if (self.maxLines > 0 && self.count > self.maxLines) {
		[self savePosition];
		[self setNeedsLimitNumberOfLines];
	}
}

#pragma mark -
#pragma mark Utilities

- (void)setUp
{
	self.loaded = NO;
	
	self.policy = [TVCLogPolicy new];
	self.sink   = [TVCLogScriptEventSink new];
	
	self.lastVisitedHighlight = -1;
	
	self.policy.menuController = [self.world menuController];
	self.policy.menu			= self.menu;
	self.policy.urlMenu			= self.urlMenu;
	self.policy.chanMenu		= self.chanMenu;
	self.policy.memberMenu		= self.memberMenu;
	
	self.sink.owner  = self;
	self.sink.policy = self.policy;
	
	if (self.view) {
		[self.view removeFromSuperview];
	}
	
	self.view = [[TVCLogView alloc] initWithFrame:NSZeroRect];
	
	self.view.frameLoadDelegate			= self;
	self.view.UIDelegate				= self.policy;
	self.view.policyDelegate			= self.policy;
	self.view.resourceLoadDelegate		= self;
	self.view.keyDelegate				= self;
	self.view.resizeDelegate			= self;
	self.view.autoresizingMask			= (NSViewWidthSizable | NSViewHeightSizable);

	[self.view setShouldUpdateWhileOffscreen:NO];
	
	[self loadAlternateHTML:[self initialDocument:nil]];
	
	self.queueInProgress = NO;
}

- (void)destroyViewLoop
{
	if (self.queueInProgress) {
		return;
	}
	
	if (PointerIsNotEmpty(self.messageQueueDispatch)) {
		dispatch_release(self.messageQueueDispatch);
		self.messageQueueDispatch = NULL;
	}
}

- (void)createViewLoop
{
	if (self.queueInProgress) {
		return;
	} else {
		self.queueInProgress = YES;
	}
	
	if (PointerIsEmpty(self.messageQueueDispatch)) {
		NSString *uuid = [NSString stringWithUUID];
		
		self.messageQueueDispatch = dispatch_queue_create([uuid UTF8String], NULL);
	}
	
	dispatch_async(self.messageQueueDispatch, ^{
		[self messageQueueLoop];
	});
}

- (void)messageQueueLoop
{
	while (NSObjectIsNotEmpty(self.messageQueue)) {
		if (self.channel) {
			[NSThread sleepForTimeInterval:[TPCPreferences viewLoopChannelDelay]];
		} else {
			[NSThread sleepForTimeInterval:[TPCPreferences viewLoopConsoleDelay]];
		}
		
		if ([self.view isLoading] == NO) {
			dispatch_async(dispatch_get_main_queue(), ^{
				if (NSObjectIsNotEmpty(self.messageQueue)) {
					BOOL srslt = ((TVCLogMessageBlock)(self.messageQueue)[0])();
					
					if (srslt) {						
						[self.messageQueue removeObjectAtIndex:0];
					}
				}
			});
		}
	}
	
	self.queueInProgress = NO;
}

- (void)loadAlternateHTML:(NSString *)newHTML
{
	NSColor *windowColor = self.theme.other.underlyingWindowColor;

	if (PointerIsEmpty(windowColor)) {
		windowColor = [NSColor blackColor];
	}

	[(id)self.view setBackgroundColor:windowColor];

	[[self.view mainFrame] loadHTMLString:newHTML baseURL:self.theme.baseUrl];
}

- (void)executeScriptCommand:(NSString *)command withArguments:(NSArray *)args
{
	WebScriptObject *js_api = [self.view js_api];

	if (js_api && [js_api isKindOfClass:[WebUndefined class]] == NO) {
		[js_api callWebScriptMethod:command	withArguments:args];
	}
}

- (NSInteger)scrollbackCorrectionInit
{
	return (self.view.frame.size.height / 2);
}

- (void)notifyDidBecomeVisible
{
	if (self.becameVisible == NO) {
		self.becameVisible = YES;
		
		[self moveToBottom];
	}
}

- (DOMDocument *)mainFrameDocument
{
	return [self.view.mainFrame DOMDocument];
}

- (DOMNode *)html_head
{
	DOMDocument *doc = [self mainFrameDocument];

	DOMNodeList *nodes = [doc getElementsByTagName:@"head"];

	DOMNode *head = [nodes item:0];
	
	return head;
}

- (DOMElement *)body:(DOMDocument *)doc 
{
	return [doc getElementById:@"body_home"];
}

- (DOMElement *)topic:(DOMDocument *)doc 
{
	return [doc getElementById:@"topic_bar"];
}

- (NSString *)topicValue
{
	DOMDocument *doc = [self mainFrameDocument];
	if (PointerIsEmpty(doc)) return NSStringEmptyPlaceholder;
	
	return [(id)[self topic:doc] innerHTML];
}

- (void)setTopic:(NSString *)topic 
{
	if (NSObjectIsEmpty(topic)) {
		topic = TXTLS(@"IRCChannelEmptyTopic");
	}
	
	TVCLogMessageBlock (^messageBlock)(void) = [^{
		if ([[self topicValue] isEqualToString:topic] == NO) {
			NSString *body = [LVCLogRenderer renderBody:topic
											 controller:self
											 renderType:TVCLogRendererHTMLType
											 properties:@{@"renderLinks": NSNumberWithBOOL(YES)}
											 resultInfo:NULL];
			
			DOMDocument *doc = [self mainFrameDocument];
			if (PointerIsEmpty(doc)) return NO;
			
			DOMElement *topic_body = [self topic:doc];
			if (PointerIsEmpty(topic_body)) return NO;
			
			[(id)topic_body setInnerHTML:body];

			[self executeScriptCommand:@"topicBarValueChanged" withArguments:@[topic]];
		}
		
		return YES;
	} copy];
	
	[self.messageQueue safeAddObject:messageBlock];
	
	[self createViewLoop];
}

- (void)moveToTop
{
	if (self.loaded == NO) return;
	
	DOMDocument *doc = [self mainFrameDocument];
	if (PointerIsEmpty(doc)) return;
	
	DOMElement *body = [doc body];
	
	if (body) {
		[body setValue:@0 forKey:@"scrollTop"];
	}

	[self executeScriptCommand:@"viewPositionMovedToTop" withArguments:@[]];
}

- (void)moveToBottom
{
	self.movingToBottom = NO;
	
	if (self.loaded == NO) return;
	
	DOMDocument *doc = [self mainFrameDocument];
	if (PointerIsEmpty(doc)) return;
	
	DOMElement *body = [doc body];
	
	if (body) {
		[body setValue:[body valueForKey:@"scrollHeight"] forKey:@"scrollTop"];
	}

	[self executeScriptCommand:@"viewPositionMovedToBottom" withArguments:@[]];
}

- (BOOL)viewingBottom
{
	if (self.loaded == NO)   return YES;
	if (self.movingToBottom) return YES;
	
	DOMDocument *doc = [self mainFrameDocument];
	if (PointerIsEmpty(doc)) return NO;
	
	DOMHTMLElement *body = [doc body];
	
	if (body) {
		NSInteger viewHeight = self.view.frame.size.height;
		
		NSInteger height = [[body valueForKey:@"scrollHeight"] integerValue];
		NSInteger top    = [[body valueForKey:@"scrollTop"] integerValue];
		
		if (viewHeight == 0) return YES;
		
		return ((top + viewHeight) >= (height - _bottomEpsilon));
	}
	
	return NO;
}

- (void)savePosition
{
	if (self.loadingImages == 0) {
		self.bottom = [self viewingBottom];
	}
}

- (void)restorePosition
{
	[self moveToBottom];
}

- (void)mark
{
	TVCLogMessageBlock (^messageBlock)(void) = [^{
		if (self.loaded == NO) return NO;
		
		[self savePosition];
		
		DOMDocument *doc = [self mainFrameDocument];
		if (PointerIsEmpty(doc)) return NO;
		
		DOMElement *body = [self body:doc];
		
		if (body) {
			DOMElement *e = [doc createElement:@"div"];
			
			[e setAttribute:@"id" value:@"mark"];
			
			[body appendChild:e];
			
			++self.count;
			
			[self restorePosition];
		}

		[self executeScriptCommand:@"historyIndicatorAddedToView" withArguments:@[]];
		
		return YES;
	} copy];

	[self.messageQueue safeAddObject:messageBlock];
	
	[self createViewLoop];
}

- (void)unmark
{
	TVCLogMessageBlock (^messageBlock)(void) = [^{
		if (self.loaded == NO) return NO;
		
		DOMDocument *doc = [self mainFrameDocument];
		if (PointerIsEmpty(doc)) return NO;
		
		DOMElement *e = [doc getElementById:@"mark"];
		
		if (e) {
			[[e parentNode] removeChild:e];
			
			--self.count;
		}

		[self executeScriptCommand:@"historyIndicatorRemovedFromView" withArguments:@[]];

		return YES;
	} copy];

	[self.messageQueue safeAddObject:messageBlock];
	
	[self createViewLoop];
}

- (void)goToMark
{
	if (self.loaded == NO) return;
	
	DOMDocument *doc = [self mainFrameDocument];
	if (PointerIsEmpty(doc)) return;
	
	DOMElement *e = [doc getElementById:@"mark"];
	
	if (e) {
		NSInteger y = 0;
		DOMElement *t = e;
		
		while (t) {
			if ([t isKindOfClass:[DOMElement class]]) {
				y += [[t valueForKey:@"offsetTop"] integerValue];
			}
			
			t = (id)[t parentNode];
		}
		
		[[doc body] setValue:@(y - [self scrollbackCorrectionInit]) forKey:@"scrollTop"];
	}

	[self executeScriptCommand:@"viewPositionMovedToHistoryIndicator" withArguments:@[]];
}

- (void)reloadTheme
{
	DOMDocument *doc = [self mainFrameDocument];
	if (PointerIsEmpty(doc)) return;

	DOMElement *body = [self body:doc];
	if (PointerIsEmpty(body)) return;

	self.html = [(id)body innerHTML];

	self.scrollBottom = [self viewingBottom];
	self.scrollTop    = [[[doc body] valueForKey:@"scrollTop"] integerValue];

	[self loadAlternateHTML:[self initialDocument:[self topicValue]]];
}

- (void)clear
{
	self.html = nil;
	self.loaded = NO;
	self.count  = 0;

	[self executeScriptCommand:@"viewContentsBeingCleared" withArguments:@[]];
	
	[self loadAlternateHTML:[self initialDocument:[self topicValue]]];
}

- (void)changeTextSize:(BOOL)bigger
{
	[self savePosition];
	
	if (bigger) {
		[self.view makeTextLarger:nil];
	} else {
		[self.view makeTextSmaller:nil];
	}

	[self executeScriptCommand:@"viewFontSizeChanged" withArguments:@[@(bigger)]];
	
	[self restorePosition];
}

- (BOOL)highlightAvailable:(BOOL)previous
{
	if (NSObjectIsEmpty(self.highlightedLineNumbers)) {
		return NO;
	}
	
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

- (void)jumpToLine:(NSInteger)line 
{
	NSString *lid = [NSString stringWithFormat:@"line%d", line];
	
	if (self.loaded == NO) return;
	
	DOMDocument *doc = [self mainFrameDocument];
	if (PointerIsEmpty(doc)) return;
	
	DOMElement *e = [doc getElementById:lid];
	
	if (e) {
		NSInteger y = 0;
		DOMElement *t = e;
		
		while (t) {
			if ([t isKindOfClass:[DOMElement class]]) {
				y += [[t valueForKey:@"offsetTop"] integerValue];
			}
			
			t = (id)[t parentNode];
		}
		
		[[doc body] setValue:@(y -  [self scrollbackCorrectionInit]) forKey:@"scrollTop"];
	}

	[self executeScriptCommand:@"viewPositionMovedToLine" withArguments:@[@(line)]];
}

- (void)nextHighlight
{
	if (self.loaded == NO) return;
	
	DOMDocument *doc = [self mainFrameDocument];
	if (PointerIsEmpty(doc)) return;
	
	if (NSObjectIsEmpty(self.highlightedLineNumbers)) {
		return;
	}
	
	id bhli = @(self.lastVisitedHighlight);
	
	if ([self.highlightedLineNumbers containsObject:bhli]) {
		NSInteger hli_ci = [self.highlightedLineNumbers indexOfObject:bhli];
		NSInteger hli_ei = [self.highlightedLineNumbers indexOfObject:self.highlightedLineNumbers.lastObject];
		
		if (NSDissimilarObjects(hli_ci, hli_ei) == NO) {
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
	if (self.loaded == NO) return;
	
	DOMDocument *doc = [self mainFrameDocument];
	if (PointerIsEmpty(doc)) return;
	
	if (NSObjectIsEmpty(self.highlightedLineNumbers)) {
		return;
	}
	
	id bhli = @(self.lastVisitedHighlight);
	
	if ([self.highlightedLineNumbers containsObject:bhli]) {
		NSInteger hli_ci = [self.highlightedLineNumbers indexOfObject:bhli];
		
		if (NSDissimilarObjects(hli_ci, 0) == NO) {
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

- (void)limitNumberOfLines
{
	self.needsLimitNumberOfLines = NO;
	
	NSInteger n = (self.count - self.maxLines);
	if (self.loaded == NO || n <= 0 || self.count <= 0) return;
	
	DOMDocument *doc = [self mainFrameDocument];
	if (PointerIsEmpty(doc)) return;
	
	DOMElement *body = [self body:doc];
	if (PointerIsEmpty(body)) return;
	
	DOMNodeList *nodeList = [body childNodes];
	if (PointerIsEmpty(nodeList)) return;
	
	n = (nodeList.length - self.maxLines);
	
	for (NSInteger i = (n - 1); i >= 0; --i) {
		[body removeChild:[nodeList item:(unsigned)i]];
	}
	
	if (NSObjectIsNotEmpty(self.highlightedLineNumbers)) {
		DOMNodeList *nodeList = [body childNodes];
		
		if (nodeList.length) {
			DOMNode *firstNode = [nodeList item:0];
			
			if (firstNode) {
				NSString *lineId = [firstNode valueForKey:@"id"];
				
				if (lineId && lineId.length > 4) {
					NSString *lineNumStr = [lineId safeSubstringFromIndex:4];
					NSInteger lineNum    = [lineNumStr integerValue];
					
					while (NSObjectIsNotEmpty(self.highlightedLineNumbers)) {
						NSInteger i = [self.highlightedLineNumbers integerAtIndex:0];
						
						if (lineNum <= i) break;
						
						[self.highlightedLineNumbers safeRemoveObjectAtIndex:0];
					}
				}
			}
		} else {
			[self.highlightedLineNumbers removeAllObjects];
		}
	}
	
	self.count -= n;
	
	if (self.count < 0) self.count = 0;
}

- (void)setNeedsLimitNumberOfLines
{
	if (self.needsLimitNumberOfLines) return;
	
	_needsLimitNumberOfLines = YES;
	
	[self limitNumberOfLines];
}

- (NSString *)renderedBodyForTranscriptLog:(TVCLogLine *)line
{
	if (NSObjectIsEmpty(line.body)) {
		return nil;
	}
	
	NSMutableString *s = [NSMutableString string];
	
	if (NSObjectIsNotEmpty(line.time)) {
		[s appendString:line.time];
		[s appendString:NSStringEmptyPlaceholder];
	}
	
	if (NSObjectIsNotEmpty(line.nick)) {
		[s appendString:line.nick];
		[s appendString:NSStringEmptyPlaceholder];
	} 

	[s appendString:line.body];

	return [s stripEffects];
}

- (BOOL)print:(TVCLogLine *)line
{
	return [self print:line withHTML:NO];
}

- (BOOL)print:(TVCLogLine *)line withHTML:(BOOL)rawHTML
{
	if (NSObjectIsEmpty(line.body)) {
		return NO;
	}

	if (rawHTML) {
		line.lineType = TVCLogLineRawHTMLType;
	}

	if ([NSThread isMainThread] == NO) {
		return [self.iomt print:line withHTML:rawHTML];
	}

	// ************************************************************************** /
	// Render our body.                                                           /
	// ************************************************************************** /
	
	TVCLogLineType type = line.lineType;
	
	NSString *body			 = nil;
	NSString *lineTypeString = [TVCLogLine lineTypeString:type];
	
	BOOL highlighted = NO;
	
	BOOL isText	     = (type == TVCLogLinePrivateMessageType || type == TVCLogLineNoticeType || type == TVCLogLineActionType);
	BOOL isNormalMsg = (type == TVCLogLinePrivateMessageType || type == TVCLogLineActionType);
	BOOL drawLinks   = BOOLReverseValue([TLOLinkParser.bannedURLRegexLineTypes containsObject:lineTypeString]);
	
	NSArray *urlRanges = @[];

	// ---- //
	
	if (rawHTML == NO) {
		NSMutableDictionary *inputDictionary  = [NSMutableDictionary dictionary];
		NSMutableDictionary *outputDictionary = [NSMutableDictionary dictionary];

		if (NSObjectIsNotEmpty(line.keywords)) {
			inputDictionary[@"keywords"] = line.keywords;
		}

		if (NSObjectIsNotEmpty(line.excludeWords)) {
			inputDictionary[@"excludeWords"] = line.excludeWords;
		}

		[inputDictionary setBool:drawLinks forKey:@"renderLinks"];
		[inputDictionary setBool:isNormalMsg forKey:@"isNormalMessage"];

		body = [LVCLogRenderer renderBody:line.body
							   controller:self
							   renderType:TVCLogRendererHTMLType
							   properties:inputDictionary
							   resultInfo:&outputDictionary];

		urlRanges   = [outputDictionary arrayForKey:@"URLRanges"];
		highlighted = [outputDictionary boolForKey:@"wordMatchFound"];
	} else {
		body = line.body;
	}

	// ************************************************************************** /
	// Find all inline media.                                                     /
	// ************************************************************************** /

	NSMutableDictionary *inlineImageLinks = [NSMutableDictionary dictionary];

	if (isNormalMsg && NSObjectIsNotEmpty(urlRanges) && [TPCPreferences showInlineImages]) {
		if (([self.channel isChannel] && self.channel.config.ignoreInlineImages == NO) || [self.channel isTalk]) {
			NSString *imageUrl  = nil;

			for (NSValue *rangeValue in urlRanges) {
				NSString *url = [line.body safeSubstringWithRange:[rangeValue rangeValue]];

				imageUrl = [TVCImageURLParser imageURLFromBase:url];

				if (imageUrl) {
					if ([inlineImageLinks containsKey:imageUrl]) {
						continue;
					} else {
						[inlineImageLinks setObject:url forKey:imageUrl];
					}
				}
			}
		}
	}

	// ************************************************************************** /
	// Draw to display.                                                                /
	// ************************************************************************** /

	NSMutableDictionary *attributes = [NSMutableDictionary dictionary];

	// ---- //

	attributes[@"inlineMediaAvailable"] = @(NSObjectIsNotEmpty(inlineImageLinks));
	attributes[@"inlineMediaArray"]		= [NSMutableArray array];

	for (NSString *imageUrl in inlineImageLinks) {
		NSString *url = [inlineImageLinks objectForKey:imageUrl];

		[(id)attributes[@"inlineMediaArray"] addObject:@{
			@"imageURL"					: imageUrl,
			@"anchorLink"				: url,
			@"preferredMaximumWidth"	: @([TPCPreferences inlineImagesMaxWidth]),
			@"localizedHideImageTitle"	: TXTLS(@"LogViewHideInlineImageMessage"),
		 }];
	}

	// ---- //

	attributes[@"isNicknameAvailable"] = @(NO);

	// ---- //

	if (NSObjectIsNotEmpty(line.time)) {
		attributes[@"formattedTimestamp"] = line.time;
	}

	// ---- //

	if (line.nick) {
		attributes[@"isNicknameAvailable"] = @(YES);

		attributes[@"nicknameColorNumber"]			= @(line.nickColorNumber);
		attributes[@"nicknameColorHashingEnabled"]	= @([TPCPreferences disableNicknameColors] == NO);

		attributes[@"formattedNickname"]	= line.nick.trim;

		attributes[@"nickname"]				= line.nickInfo;
		attributes[@"nicknameType"]			= [TVCLogLine memberTypeString:line.memberType];
	}

	// ---- //

	attributes[@"lineType"] = [TVCLogLine lineTypeString:line.lineType];

	attributes[@"lineClassAttributeRepresentation"] = ((isText)			? @"text" : @"event");
	attributes[@"highlightAttributeRepresentation"] = ((highlighted)	? @"true" : @"false");

	attributes[@"message"]				= line.body;
	attributes[@"formattedMessage"]		= body;

	attributes[@"isRemoteMessage"]	= @(line.memberType == TVCLogMemberNormalType);
	attributes[@"isHighlight"]		= @(highlighted);

	// ---- //

	id templateRaw = [self.theme.other templateWithLineType:line.lineType];

	[self writeLine:templateRaw attributes:attributes];

	// ************************************************************************** /
	// Log highlight (if any).                                                    /
	// ************************************************************************** /
	
	if (highlighted) {
		NSString *messageBody;
		NSString *nicknameBody = [line.nick trim];
		
		if (type == TVCLogLineActionType) {
			if ([nicknameBody hasSuffix:@":"]) {
				messageBody = [NSString stringWithFormat:TXNotificationHighlightLogAlternativeActionFormat, nicknameBody, line.body];
			} else {
				messageBody = [NSString stringWithFormat:TXNotificationHighlightLogStandardActionFormat, nicknameBody, line.body];
			}
		} else {
			messageBody = [NSString stringWithFormat:TXNotificationHighlightLogStandardMessageFormat, nicknameBody, line.body];
		}
		
		[self.world addHighlightInChannel:self.channel withMessage:messageBody];
	}
	
	return highlighted;
}

- (void)writeLine:(id)line attributes:(NSMutableDictionary *)attrs
{
	TVCLogMessageBlock (^messageBlock)(void) = [^{
		[self savePosition];
		
		++self.lineNumber;
		++self.count;

		// ---- //
		
		DOMDocument *doc = [self mainFrameDocument];
		if (PointerIsEmpty(doc)) return NO;
		
		DOMElement *body = [self body:doc];
		if (PointerIsEmpty(body)) return NO;

		// ---- //

		if ([line isKindOfClass:GRMustacheTemplate.class]) {
			attrs[@"lineNumber"] = @(self.lineNumber);

			// ---- //

			NSString *aHtml = [line renderObject:attrs];

			if (NSObjectIsEmpty(aHtml)) {
				return NO;
			}

			// ---- //

			DOMDocumentFragment *frag = [(id)doc createDocumentFragmentWithMarkupString:aHtml
																				baseURL:self.theme.baseUrl];
			[body appendChild:frag];
		}

		// ---- //
		
		if (self.maxLines > 0 && (self.count - 10) > self.maxLines) {
			[self setNeedsLimitNumberOfLines];
		}
		
		if ([attrs[@"highlightAttributeRepresentation"] isEqualToString:@"true"]) {
			[self.highlightedLineNumbers safeAddObject:@(self.lineNumber)];
		}
		
		[self executeScriptCommand:@"newMessagePostedToDisplay" withArguments:@[@(self.lineNumber)]];

		// ---- //
		
		return YES;
	} copy];
	
	[self.messageQueue safeAddObject:messageBlock];
	
	[self createViewLoop];
}

- (NSString *)initialDocument:(NSString *)topic
{
	NSMutableDictionary *templateTokens = [self generateOverrideStyle];

	// ---- //

	templateTokens[@"cacheToken"]				= [NSString stringWithUUID];

	templateTokens[@"activeStyleAbsolutePath"]	= self.theme.other.path;
	templateTokens[@"applicationResourcePath"]	= [TPCPreferences whereResourcePath];

	templateTokens[@"existingBody"]				= NSStringNilValueSubstitute(self.html);

	// ---- //
	
	if (self.channel) {
		templateTokens[@"isChannelView"]	= @(YES);
		
		templateTokens[@"channelName"]		= logEscape(self.channel.name);
		templateTokens[@"viewTypeToken"]	= [self.channel channelTypeString];

		if (NSObjectIsNotEmpty(topic)) {
			templateTokens[@"formattedTopicValue"] = topic;
		} else {
			templateTokens[@"formattedTopicValue"] = TXTLS(@"IRCChannelEmptyTopic");
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

	return TXRenderStyleTemplate(@"baseLayout", templateTokens, self);
}

- (NSMutableDictionary *)generateOverrideStyle
{
	NSMutableDictionary *templateTokens = [NSMutableDictionary dictionary];
	
	TPCOtherTheme *other = self.world.viewTheme.other;

	// ---- //
	
	NSFont *channelFont = other.channelViewFont;

	if (PointerIsEmpty(channelFont)) {
		channelFont = [TPCPreferences themeChannelViewFont];
	}
	
	NSString *name = [channelFont fontName];
	CGFloat  rsize = [channelFont pointSize];

	templateTokens[@"userConfiguredFontName"] = name;
	templateTokens[@"userConfiguredFontSize"] = @(rsize * (72.0 / 96.0));

	// ---- //

	if ([TPCPreferences useLogAntialiasing] == NO) {
		templateTokens[@"windowAntialiasingDisabled"] = @(YES);
	}

	// ---- //

	NSInteger indentOffset = other.indentationOffset;
	
	if (indentOffset == TXThemeDisabledIndentationOffset || [TPCPreferences rightToLeftFormatting]) {
		templateTokens[@"nicknameIndentationAvailable"] = @(NO);
	} else {
		templateTokens[@"nicknameIndentationAvailable"] = @(YES);
		
		NSString *time = TXFormattedTimestampWithOverride([NSDate date], [TPCPreferences themeTimestampFormat], other.timestampFormat);
		
		NSDictionary *attributes = @{NSFontAttributeName: channelFont};
		
		NSSize    textSize  = [time sizeWithAttributes:attributes]; 
		NSInteger textWidth = (textSize.width + indentOffset);

		templateTokens[@"predefinedTimestampWidth"] = @(textWidth);
	}

	// ---- //

	return templateTokens;
}

- (void)setUpScroller
{
	WebFrameView *frame = [[self.view mainFrame] frameView];
	if (PointerIsEmpty(frame)) return;
	
	NSScrollView *scrollView = nil;
	
	for (NSView *v in [frame subviews]) {
		if ([v isKindOfClass:[NSScrollView class]]) {
			scrollView = (NSScrollView *)v;
			
			break;
		}
	}
	
	if (PointerIsEmpty(scrollView)) return;
	
	[scrollView setHasHorizontalScroller:NO];
	[scrollView setHasVerticalScroller:YES];
	
	if ([scrollView respondsToSelector:@selector(setAllowsHorizontalScrolling:)]) {
		[scrollView performSelector:@selector(setAllowsHorizontalScrolling:) withObject:NO];
	}
	
#ifdef TXMacOSLionOrNewer
	if ([TPCPreferences featureAvailableToOSXLion]) {
		[scrollView setHorizontalScrollElasticity:NSScrollElasticityNone];
		[scrollView setVerticalScrollElasticity:NSScrollElasticityNone];
	}
#endif
}

#pragma mark -
#pragma mark WebView Delegate

- (void)webView:(WebView *)sender didClearWindowObject:(WebScriptObject *)windowObject forFrame:(WebFrame *)frame
{
	self.js = windowObject;
	
	[self.js setValue:self.sink forKey:@"app"];
}

- (void)webView:(WebView *)sender didFailLoadWithError:(NSError *)error forFrame:(WebFrame *)frame
{
	NSLog(@"Log [%@] for channel [%@] on [%@] failed to load with error: %@",
		  [self description], [self.channel description], [self.client description], [error localizedDescription]);
}

- (void)webView:(WebView *)sender resource:(id)identifier didFailLoadingWithError:(NSError *)error fromDataSource:(WebDataSource *)dataSource
{
	NSLog(@"Resource [%@] in log [%@] failed loading for channel [%@] on [%@] with error: %@",
			identifier, [self description], [self.channel description], [self.client description], [error localizedDescription]);
}

- (void)webView:(WebView *)sender didFailProvisionalLoadWithError:(NSError *)error forFrame:(WebFrame *)frame
{
	NSLog(@"Log [%@] for channel [%@] on [%@] failed provisional load with error: %@",
		  [self description], [self.channel description], [self.client description], [error localizedDescription]);
}

- (void)webView:(WebView *)sender didFinishLoadForFrame:(WebFrame *)frame
{
	[self executeScriptCommand:@"viewFinishedLoading" withArguments:@[]];

	self.loaded	= YES;
	self.loadingImages = 0;
	
	[self setUpScroller];
	
	if (PointerIsEmpty(self.autoScroller)) {
		self.autoScroller = [TVCWebViewAutoScroll new];
	}
	
	self.autoScroller.webFrame = self.view.mainFrame.frameView;
	
	[self moveToBottom];
	self.bottom = YES;
	
	DOMDocument *doc = [frame DOMDocument];
	if (PointerIsEmpty(doc)) return;
	
	DOMElement *body = [self body:doc];
	DOMNode    *e    = [body firstChild];
	
	while (e) {
		DOMNode *next = [e nextSibling];
		
		if ([e isKindOfClass:[DOMHTMLDivElement class]] == NO && 
			[e isKindOfClass:[DOMHTMLHRElement class]] == NO) {
			
			[body removeChild:e];
		}
		
		e = next;
	}

	NSString *viewType = @"server";

	if (self.channel && self.channel.isChannel) {
		viewType = @"channel";
	} else if (self.channel && self.channel.isTalk) {
		viewType = @"talk";
	}

	[self executeScriptCommand:@"viewInitiated" withArguments:@[
	 NSStringNilValueSubstitute(viewType),
	 NSStringNilValueSubstitute(self.client.config.guid),
	 NSStringNilValueSubstitute(self.channel.config.guid),
	 NSStringNilValueSubstitute(self.channel.name)
	 ]];
}

- (id)webView:(WebView *)sender identifierForInitialRequest:(NSURLRequest *)request fromDataSource:(WebDataSource *)dataSource
{
	NSString *scheme = [request.URL.scheme lowercaseString];
	
	if ([scheme isEqualToString:@"http"] || 
		[scheme isEqualToString:@"https"]) {
		
		if (self.loadingImages == 0) {
			[self savePosition];
		}
		
		++self.loadingImages;
		
		return self;
	}
	
	return nil;
}

- (void)webView:(WebView *)sender resource:(id)identifier didFinishLoadingFromDataSource:(WebDataSource *)dataSource
{
	if (identifier) {
		if (self.loadingImages > 0) {
			--self.loadingImages;
		}
		
		if (self.loadingImages == 0) {
			[self restorePosition];
		}
	}
}

#pragma mark -
#pragma mark LogView Delegate

- (void)logViewKeyDown:(NSEvent *)e
{
	[self.world logKeyDown:e];
}

- (void)logViewOnDoubleClick:(NSString *)e
{
	[self.world logDoubleClick:e];
}

- (void)logViewWillResize
{
	[self savePosition];
}

- (void)logViewDidResize
{
	[self restorePosition];
}

@end
