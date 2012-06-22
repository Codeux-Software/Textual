// Created by Satoshi Nakagawa <psychs AT limechat DOT net> <http://github.com/psychs/limechat>
// Modifications by Codeux Software <support AT codeux DOT com> <https://github.com/codeux/Textual>
// You can redistribute it and/or modify it under the new BSD license.
// Converted to ARC Support on June 07, 2012

#import "TextualApplication.h"

#define _bottomEpsilon		0
#define _timeBufferSize		256

@interface NSScrollView (Private)
- (void)setAllowsHorizontalScrolling:(BOOL)value;
@end

@interface TVCLogController (Private)
- (void)savePosition;
- (void)restorePosition;
- (void)messageQueueLoop;
- (void)setNeedsLimitNumberOfLines;
- (void)writeLineInBackground:(NSString *)aHtml attributes:(NSDictionary *)attrs;
- (void)writeLine:(NSString *)aHtml attributes:(NSDictionary *)attrs;
- (NSString *)initialDocument:(NSString *)topic;
- (NSString *)generateOverrideStyle;
- (DOMNode *)html_head;
- (DOMElement *)body:(DOMDocument *)doc;
- (DOMElement *)topic:(DOMDocument *)doc;
- (NSInteger)scrollbackCorrectionInit;
- (void)loadAlternateHTML:(NSString *)newHTML;
@end

@implementation TVCLogController

@synthesize autoScroller;
@synthesize becameVisible;
@synthesize bottom;
@synthesize chanMenu;
@synthesize channel;
@synthesize client;
@synthesize count;
@synthesize html;
@synthesize js;
@synthesize lineNumber;
@synthesize loaded;
@synthesize loadingImages;
@synthesize maxLines;
@synthesize memberMenu;
@synthesize menu;
@synthesize movingToBottom;
@synthesize highlightedLineNumbers;
@synthesize needsLimitNumberOfLines;
@synthesize scrollBottom;
@synthesize scrollTop;
@synthesize policy;
@synthesize sink;
@synthesize theme;
@synthesize urlMenu;
@synthesize view;
@synthesize world;
@synthesize messageQueue;
@synthesize queueInProgress;
@synthesize messageQueueDispatch;
@synthesize lastVisitedHighlight;
@synthesize viewingBottom;

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
	maxLines = value;
	
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
					BOOL srslt = ((TVCLogMessageBlock)[self.messageQueue objectAtIndex:0])();
					
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
	[(id)self.view setBackgroundColor:self.theme.other.underlyingWindowColor];
	[[self.view mainFrame] loadHTMLString:newHTML baseURL:self.theme.baseUrl];
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
	return [self.view mainFrameDocument];
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
										  controller:nil
										  renderType:TVCLogRendererHTMLType
										  properties:[NSDictionary dictionaryWithObjectsAndKeys:NSNumberWithBOOL(YES), @"renderLinks", nil]
										  resultInfo:NULL];
			
			DOMDocument *doc = [self mainFrameDocument];
			if (PointerIsEmpty(doc)) return NO;
			
			DOMElement *topic_body = [self topic:doc];
			if (PointerIsEmpty(topic_body)) return NO;
			
			[(id)topic_body setInnerHTML:body];
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
		[body setValue:NSNumberWithInteger(0) forKey:@"scrollTop"];
	}
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
		
		[[doc body] setValue:NSNumberWithInteger((y - [self scrollbackCorrectionInit])) forKey:@"scrollTop"];
	}
}

- (void)reloadTheme
{
	if (self.loaded == NO) return;
	
	DOMDocument *doc = [self mainFrameDocument];
	if (PointerIsEmpty(doc)) return;
	
	WebScriptObject *js_api = [self.view js_api];
	
	if (js_api && [js_api isKindOfClass:[WebUndefined class]] == NO) {
		[js_api callWebScriptMethod:@"willDoThemeChange" withArguments:[NSArray array]]; 
	}
	
	DOMElement *body = [self body:doc];
	if (PointerIsEmpty(body)) return;
	
	self.html = [(id)body innerHTML];
	
	self.scrollBottom = [self viewingBottom];
	self.scrollTop    = [[[doc body] valueForKey:@"scrollTop"] integerValue];
	
	[self loadAlternateHTML:[self initialDocument:[self topicValue]]];
}

- (void)clear
{
	if (self.loaded == NO) return;
	
	self.html = nil;
	self.loaded = NO;
	self.count  = 0;
	
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
	
	[self restorePosition];
}

- (BOOL)highlightAvailable:(BOOL)previous
{
	if (NSObjectIsEmpty(self.highlightedLineNumbers)) {
		return NO;
	}
	
	if ([self.highlightedLineNumbers containsObject:NSNumberWithInteger(self.lastVisitedHighlight)] == NO) {
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
		
		[[doc body] setValue:NSNumberWithInteger((y -  [self scrollbackCorrectionInit])) forKey:@"scrollTop"];
	}
}

- (void)nextHighlight
{
	if (self.loaded == NO) return;
	
	DOMDocument *doc = [self mainFrameDocument];
	if (PointerIsEmpty(doc)) return;
	
	if (NSObjectIsEmpty(self.highlightedLineNumbers)) {
		return;
	}
	
	id bhli = NSNumberWithInteger(self.lastVisitedHighlight);
	
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
	
	id bhli = NSNumberWithInteger(self.lastVisitedHighlight);
	
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
	
	needsLimitNumberOfLines = YES;
	
	[self limitNumberOfLines];
}

- (BOOL)print:(TVCLogLine *)line
{
	return [self print:line withHTML:NO];
}

- (BOOL)print:(TVCLogLine *)line withHTML:(BOOL)rawHTML
{
	if (NSObjectIsEmpty(line.body)) return NO;

	if ([NSThread isMainThread] == NO) {
		return [self.iomt print:line withHTML:rawHTML];
	}
	
	TVCLogLineType type = line.lineType;
	
	NSString *body			 = nil;
	NSString *lineTypeString = [TVCLogLine lineTypeString:type];
	
	BOOL highlighted = NO;
	
	BOOL isText	     = (type == TVCLogLinePrivateMessageType || type == TVCLogLineNoticeType || type == TVCLogLineActionType);
	BOOL isNormalMsg = (type == TVCLogLinePrivateMessageType || type == TVCLogLineActionType);
	BOOL drawLinks   = BOOLReverseValue([[TLOLinkParser bannedURLRegexLineTypes] containsObject:lineTypeString]);
	
	NSArray *urlRanges = [NSArray array];
	
	if (rawHTML == NO) {
		NSMutableDictionary *inputDictionary  = [NSMutableDictionary dictionary];
		NSMutableDictionary *outputDictionary = [NSMutableDictionary dictionary];
		
		if (NSObjectIsNotEmpty(line.keywords)) {
			[inputDictionary setObject:line.keywords forKey:@"keywords"];
		}
		
		if (NSObjectIsNotEmpty(line.excludeWords)) {
			[inputDictionary setObject:line.excludeWords forKey:@"excludeWords"];
		}
		
		[inputDictionary setBool:drawLinks forKey:@"renderLinks"];
		
		body = [LVCLogRenderer renderBody:line.body
							controller:((isNormalMsg) ? self : nil) 
							renderType:TVCLogRendererHTMLType 
							properties:inputDictionary 
							resultInfo:&outputDictionary];
		
		urlRanges   = [outputDictionary arrayForKey:@"URLRanges"];
		highlighted = [outputDictionary boolForKey:@"wordMatchFound"];
	} else {
		body = line.body;
	}
	
	BOOL oldRenderAbs = (self.theme.other.renderingEngineVersion == 0.0);
	BOOL oldRenderEst = (self.theme.other.renderingEngineVersion == 1.2);
	BOOL oldRenderAlt = (self.theme.other.renderingEngineVersion == 1.1 || oldRenderEst);
	BOOL modernRender = (self.theme.other.renderingEngineVersion == 2.1);
	
	NSMutableString *s = [NSMutableString string];
	
	if (oldRenderAbs || oldRenderAlt) {
		if (line.memberType == TVCLogMemberLocalUserType) {
			[s appendFormat:@"<p type=\"%@\">", [TVCLogLine memberTypeString:line.memberType]];
		} else {
			[s appendFormat:@"<p>"];
		}
	}
	
	if (NSObjectIsEmpty(line.time) && rawHTML == NO) {
		return NO;
	}
	
	if (oldRenderAbs || oldRenderAlt) {
		if (line.time) {
			[s appendFormat:@"<span class=\"time\">%@</span>",  logEscape(line.time)];
		}
	} else {
		[s appendFormat:@"<div class=\"time\">%@</div>",  logEscapeWithNil(line.time)];
	}
	
	if (oldRenderAlt) {
		[s appendFormat:@"<span class=\"message\" type=\"%@\">", lineTypeString];
	}
	
	if (line.nick) {
		NSString *htmltag = ((modernRender) ? @"div" : @"span");
		
		[s appendFormat:@"<%@ class=\"sender\" ondblclick=\"Textual.on_dblclick_nick()\" oncontextmenu=\"Textual.on_nick()\" type=\"%@\" nick=\"%@\"", htmltag, [TVCLogLine memberTypeString:line.memberType], line.nickInfo];
		
		if (line.memberType == TVCLogMemberNormalType && [TPCPreferences disableNicknameColors] == NO) {
			[s appendFormat:@" colornumber=\"%d\"", line.nickColorNumber];
		}
		
		[s appendFormat:@">%@</%@> ", logEscape(line.nick), htmltag];
	} else {
		if (modernRender) { 
			[s appendString:@"<div class=\"sender\"></div>"];
		} else {
			if (oldRenderEst) {
				[s appendString:@"<span class=\"sender\">&nbsp;</span>"];
			}
		}
	}
	
	if (modernRender) {
		[s appendFormat:@"<div class=\"message\">%@", body];
	} else {
		if (oldRenderAbs) { 
			[s appendFormat:@"<span class=\"message\" type=\"%@\">%@", lineTypeString, body];
		} else {
			[s appendString:body];
		}
	}
	
	if (isNormalMsg && NSObjectIsNotEmpty(urlRanges) && [TPCPreferences showInlineImages]) {
		if (([self.channel isChannel] && self.channel.config.ignoreInlineImages == NO) || [self.channel isTalk]) {
			NSString *imageUrl  = nil;
			
			NSMutableArray *postedUrls = [NSMutableArray array];
			
			for (NSValue *rangeValue in urlRanges) {
				NSString *url = [line.body safeSubstringWithRange:[rangeValue rangeValue]];
				
				imageUrl = [TVCImageURLParser imageURLFromBase:url];
				
				if (imageUrl) {
					if ([postedUrls containsObject:imageUrl]) {
						continue;
					} else {
						[postedUrls safeAddObject:imageUrl];
					}
					
					[s appendFormat:@"<a href=\"%@\" onclick=\"return Textual.hide_inline_image(this)\"><img src=\"%@\" class=\"inlineimage\" style=\"max-width: %dpx;\" title=\"%@\" /></a>", url, imageUrl, [TPCPreferences inlineImagesMaxWidth], TXTLS(@"LogViewHideInlineImageMessage")];
				}
			}
		}
	}
	
	NSMutableDictionary *attrs = [NSMutableDictionary dictionary];
	
	if (oldRenderAbs || oldRenderAlt) {
		[s appendString:@"</span></p>"];
		
		[attrs setObject:[TVCLogLine lineTypeString:type] forKey:@"type"];
	} else {
		[s appendFormat:@"</div>"];
		
		NSString *typeattr = [TVCLogLine lineTypeString:type];
		
		if (line.memberType == TVCLogMemberLocalUserType) {
			typeattr = [typeattr stringByAppendingFormat:@" %@", [TVCLogLine memberTypeString:line.memberType]];
		}
		
		[attrs setObject:typeattr forKey:@"type"];
	}
	
	[attrs setObject:((highlighted) ? @"true" : @"false")		forKey:@"highlight"];
	[attrs setObject:((isText) ? @"line text" : @"line event")	forKey:@"class"];
	
	[self writeLine:s attributes:attrs];
	
	if (highlighted) {
		NSString *messageBody;
		NSString *nicknameBody = [line.nick trim];
		
		if (type == TVCLogLineActionType) {
			if ([nicknameBody hasSuffix:@":"]) {
				messageBody = [NSString stringWithFormat:@"• %@ %@", nicknameBody, line.body];
			} else {
				messageBody = [NSString stringWithFormat:@"• %@: %@", nicknameBody, line.body];
			}
		} else {
			messageBody = [NSString stringWithFormat:@"%@ %@", nicknameBody, line.body];
		}
		
		[self.world addHighlightInChannel:self.channel withMessage:messageBody];
	}
	
	return highlighted;
}

- (void)writeLine:(NSString *)aHtml attributes:(NSDictionary *)attrs
{
	TVCLogMessageBlock (^messageBlock)(void) = [^{
		[self savePosition];
		
		++self.lineNumber;
		++self.count;
		
		DOMDocument *doc = [self mainFrameDocument];
		if (PointerIsEmpty(doc)) return NO;
		
		DOMElement *body = [self body:doc];
		if (PointerIsEmpty(body)) return NO;
		
		DOMElement *div = [doc createElement:@"div"];
		
		[(id)div setInnerHTML:aHtml];
		
		for (NSString *key in attrs) {
			NSString *value = [attrs objectForKey:key];
			
			[div setAttribute:key value:value];
		}
		
		[div setAttribute:@"id" value:[NSString stringWithFormat:@"line%d", self.lineNumber]];
		
		[body appendChild:div];
		
		if (self.maxLines > 0 && (self.count - 10) > self.maxLines) {
			[self setNeedsLimitNumberOfLines];
		}
		
		if ([[attrs objectForKey:@"highlight"] isEqualToString:@"true"]) {
			[self.highlightedLineNumbers safeAddObject:[NSNumber numberWithInteger:self.lineNumber]];
		}
		
		WebScriptObject *js_api = [self.view js_api];
		
		if (js_api && [js_api isKindOfClass:[WebUndefined class]] == NO) {
			[js_api callWebScriptMethod:@"newMessagePostedToDisplay" 
						  withArguments:[NSArray arrayWithObjects:NSNumberWithInteger(self.lineNumber), nil]];  
		} 
		
		return YES;
	} copy];
	
	[self.messageQueue safeAddObject:messageBlock];
	[self createViewLoop];
}

- (NSString *)initialDocument:(NSString *)topic
{
	NSMutableString *bodyAttrs = [NSMutableString string];
	
	if (self.channel) {
		[bodyAttrs appendFormat:@"type=\"%@\"", [self.channel channelTypeString]];
		
		if ([self.channel isChannel]) {
			[bodyAttrs appendFormat:@" channelname=\"%@\"", logEscape([self.channel name])];
		}
	} else {
		[bodyAttrs appendString:@"type=\"server\""];
	}
	
	if ([TPCPreferences rightToLeftFormatting]) {
		[bodyAttrs appendString:@" dir=\"rtl\""];
	} else {
		[bodyAttrs appendString:@" dir=\"ltr\""];
	}
	
	NSMutableString *s = [NSMutableString string];
	
	NSString *override_style = [self generateOverrideStyle];
	
	[s appendFormat:@"<html %@><head>", bodyAttrs];
	[s appendString:@"<meta http-equiv=\"Content-Type\" content=\"text/html; charset=utf-8\">"];
	
	NSString *ti = [NSString stringWithUUID];
	
	[s appendFormat:@"<link rel=\"stylesheet\" type=\"text/css\" href=\"design.css?u=%@\" />", ti];
	[s appendFormat:@"<script src=\"%@\" type=\"text/javascript\"></script>", self.theme.core_js.filename];
	[s appendFormat:@"<script src=\"scripts.js?u=%@\" type=\"text/javascript\"></script>", ti];
	
	if (override_style) {
		[s appendFormat:@"<style type=\"text/css\" id=\"textual_override_style\">%@</style>", override_style];
	}
	
	[s appendFormat:@"</head><body %@>", bodyAttrs];
	
	if (NSObjectIsNotEmpty(self.html)) {
		[s appendFormat:@"<div id=\"body_home\">%@</div>", self.html];
	} else {
		[s appendString:@"<div id=\"body_home\"></div>"];
	}
	
	if (self.channel && (self.channel.isChannel || self.channel.isTalk)) {
		if (NSObjectIsNotEmpty(topic)) {
			[s appendFormat:@"<div id=\"topic_bar\">%@</div></body>", topic];
		} else {
			[s appendFormat:@"<div id=\"topic_bar\">%@</div></body>", TXTLS(@"IRCChannelEmptyTopic")];
		}
	}
	
	[s appendString:@"</html>"];
	
	self.html = nil;
	
	return s;
}

- (NSString *)generateOverrideStyle
{
	NSMutableString *sf = [NSMutableString string];
	
	TPCOtherTheme *other = self.world.viewTheme.other;
	
	NSFont *channelFont = other.channelViewFont;
	
	NSString *name = [channelFont fontName];
	
	NSInteger rsize = [channelFont pointSize];
	TXNSDouble dsize = ([channelFont pointSize] * (72.0 / 96.0));
	
	[sf appendString:@"html, body, body[type], body {"];
	[sf appendFormat:@"font-family:'%@';", name];
	[sf appendFormat:@"font-size:%fpt;", dsize];
	[sf appendString:@"}"];
	
	if (other.indentationOffset == TXThemeDisabledIndentationOffset || [TPCPreferences rightToLeftFormatting]) {
		return sf;
	} else {
		NSFont	     *font		 = [NSFont fontWithName:name size:round(rsize)];
		NSString	 *time		 = TXFormattedTimestampWithOverride([NSDate date], [TPCPreferences themeTimestampFormat], other.timestampFormat);
		NSDictionary *attributes = [NSDictionary dictionaryWithObject:font forKey:NSFontAttributeName];	
		
		NSSize    textSize  = [time sizeWithAttributes:attributes]; 
		NSInteger textWidth = (textSize.width + other.indentationOffset);
		
		[sf appendString:@"body div#body_home p {"];
		[sf appendFormat:@"margin-left: %dpx;", textWidth];
		[sf appendFormat:@"text-indent: -%dpx;", textWidth];
		[sf appendString:@"}"];
		
		[sf appendString:@"body .time {"];
		[sf appendFormat:@"width: %dpx;", textWidth];
		[sf appendString:@"}"];
	}

	if ([TPCPreferences useLogAntialiasing] == NO) {
		[sf appendString:@"body {"];
		[sf appendString:@"-webkit-font-smoothing: none;"];
		[sf appendString:@"}"];
	}
	
	return sf;
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
		[(id)scrollView setAllowsHorizontalScrolling:NO];
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

- (void)webView:(WebView *)sender didFinishLoadForFrame:(WebFrame *)frame
{
	self.loaded		  = YES;
	self.loadingImages = 0;
	
	[self setUpScroller];
	
	if (PointerIsEmpty(self.autoScroller)) {
		self.autoScroller = [TVCWebViewAutoScroll new];
	}
	
	self.autoScroller.webFrame = view.mainFrame.frameView;
	
	if (self.html) {
		DOMDocument *doc = [frame DOMDocument];
		
		if (doc) {
			DOMElement *body = [self body:doc];
			
			[(id)body setInnerHTML:self.html];
			
			self.html = nil;
			
			if (self.scrollBottom) {
				[self moveToBottom];
			} else if (self.scrollTop) {
				[body setValue:NSNumberWithInteger(self.scrollTop) forKey:@"scrollTop"];
			}
		}
	} else {
		[self moveToBottom];
		
		self.bottom = YES;
	}
	
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
	
	WebScriptObject *js_api = [self.view js_api];
	
	if (js_api && [js_api isKindOfClass:[WebUndefined class]] == NO) {
		[js_api callWebScriptMethod:@"doneThemeChange" withArguments:[NSArray array]]; 
	}
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
