// Created by Satoshi Nakagawa <psychs AT limechat DOT net> <http://github.com/psychs/limechat>
// Modifications by Codeux Software <support AT codeux DOT com> <https://github.com/codeux/Textual>
// You can redistribute it and/or modify it under the new BSD license.

#define BOTTOM_EPSILON		0
#define TIME_BUFFER_SIZE	256

@interface NSScrollView (Private)
- (void)setAllowsHorizontalScrolling:(BOOL)value;
@end

@interface LogController (Private)
- (void)savePosition;
- (void)restorePosition;
- (void)setNeedsLimitNumberOfLines;
- (void)writeLine:(NSString *)str attributes:(NSDictionary *)attrs;
- (void)writeLineInBackground:(NSString *)aHtml attributes:(NSDictionary *)attrs;
- (NSString *)initialDocument:(NSString *)topic;
- (NSString *)generateOverrideStyle;

- (DOMDocument *)mainFrameDocument;
- (DOMNode *)html_head;
- (DOMElement *)body:(DOMDocument *)doc;
- (DOMElement *)topic:(DOMDocument *)doc;
@end

@implementation LogController

@synthesize addrMenu;
@synthesize autoScroller;
@synthesize becameVisible;
@synthesize bottom;
@synthesize chanMenu;
@synthesize channel;
@synthesize client;
@synthesize count;
@synthesize highlightedLineNumbers;
@synthesize html;
@synthesize initialBackgroundColor;
@synthesize js;
@synthesize lineNumber;
@synthesize lines;
@synthesize loaded;
@synthesize loadingImages;
@synthesize maxLines;
@synthesize memberMenu;
@synthesize menu;
@synthesize movingToBottom;
@synthesize needsLimitNumberOfLines;
@synthesize policy;
@synthesize scrollBottom;
@synthesize scrollTop;
@synthesize scroller;
@synthesize sink;
@synthesize theme;
@synthesize urlMenu;
@synthesize view;
@synthesize world;

- (id)init
{
	if ((self = [super init])) {
		bottom   = YES;
		maxLines = 300;
		
		lines				   = [NSMutableArray new];
		highlightedLineNumbers = [NSMutableArray new];
		
		[[WebPreferences standardPreferences] setCacheModel:WebCacheModelDocumentViewer];
		[[WebPreferences standardPreferences] setUsesPageCache:NO];
	}
	
	return self;
}

- (void)dealloc
{
	[NSObject cancelPreviousPerformRequestsWithTarget:self];
	
	[addrMenu drain];
	[autoScroller drain];
	[chanMenu drain];
	[highlightedLineNumbers drain];
	[html drain];
	[initialBackgroundColor drain];
	[js drain];
	[lines drain];
	[memberMenu drain];
	[menu drain];
	[policy drain];
	[scroller drain];
	[sink drain];
	[theme drain];
	[urlMenu drain];
	[view drain];
	
	[super dealloc];
}

#pragma mark -
#pragma mark Properties

- (NSInteger)maxLines
{
	return maxLines;
}

- (void)setMaxLines:(NSInteger)value
{
	if (maxLines == value) return;
	maxLines = value;
	
	if (loaded == NO) return;
	
	if (maxLines > 0 && count > maxLines) {
		[self savePosition];
		[self setNeedsLimitNumberOfLines];
	}
}

#pragma mark -
#pragma mark Utilities

- (void)setUp
{
	loaded = NO;
	
	policy = [LogPolicy new];
	sink   = [LogScriptEventSink new];
	
	policy.menuController = [world menuController];
	policy.menu			  = menu;
	policy.urlMenu		  = urlMenu;
	policy.addrMenu       = addrMenu;
	policy.chanMenu		  = chanMenu;
	policy.memberMenu     = memberMenu;
	
	sink.owner  = self;
	sink.policy = policy;
	
	if (view) {
		[view removeFromSuperview];
		[view drain];
	}
	
	view = [[LogView alloc] initWithFrame:NSZeroRect];
	
	if ([view respondsToSelector:@selector(setBackgroundColor:)]) {
		[(id)view setBackgroundColor:initialBackgroundColor];
	}
	
	view.frameLoadDelegate	  = self;
	view.UIDelegate			  = policy;
	view.policyDelegate		  = policy;
	view.resourceLoadDelegate = self;
	view.keyDelegate		  = self;
	view.resizeDelegate		  = self;
	view.autoresizingMask	  = (NSViewWidthSizable | NSViewHeightSizable);
	
	[[view mainFrame] loadHTMLString:[self initialDocument:nil] baseURL:theme.baseUrl];
}

- (void)notifyDidBecomeVisible
{
	if (becameVisible == NO) {
		becameVisible = YES;
		
		[self moveToBottom];
	}
}

- (BOOL)hasValidBodyStructure
{
	return (PointerIsEmpty([self mainFrameDocument]) == NO);
}

- (DOMDocument *)mainFrameDocument
{
	return [view mainFrameDocument];
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
	if (PointerIsEmpty(doc)) return @"";
	
	return [(id)[self topic:doc] innerHTML];
}

- (BOOL)setTopicWithoutDelay:(NSString *)topic
{
	if (NSObjectIsNotEmpty(topic)) {
		if ([[self topicValue] isEqualToString:topic] == NO) {
			NSString *body = [LogRenderer renderBody:topic 
										  controller:nil
										  renderType:ASCII_TO_HTML 
										  properties:[NSDictionary dictionaryWithObjectsAndKeys:NSNumberWithBOOL(YES), @"renderLinks", nil]
										  resultInfo:NULL];
			
			DOMDocument *doc = [self mainFrameDocument];
			if (PointerIsEmpty(doc)) return NO;
			
			DOMElement *topic_body = [self topic:doc];
			if (PointerIsEmpty(topic_body)) return NO;
			
			[(id)topic_body setInnerHTML:body];
		}
	}
	
	return YES;
}

- (void)setTopic:(NSString *)topic 
{
	if ([self setTopicWithoutDelay:topic] == NO) {
		[self performSelector:@selector(setTopicWithoutDelay:) withObject:topic afterDelay:2.0];
	}
}

- (void)moveToTop
{
	if (loaded == NO) return;
	
	DOMDocument *doc = [self mainFrameDocument];
	if (PointerIsEmpty(doc)) return;
	
	DOMElement *body = [doc body];
	
	if (body) {
		[body setValue:NSNumberWithInteger(0) forKey:@"scrollTop"];
	}
}

- (void)moveToBottom
{
	movingToBottom = NO;
	
	if (loaded == NO) return;
	
	DOMDocument *doc = [self mainFrameDocument];
	if (PointerIsEmpty(doc)) return;
	
	DOMElement *body = [doc body];
	
	if (body) {
		[body setValue:[body valueForKey:@"scrollHeight"] forKey:@"scrollTop"];
	}
}

- (BOOL)viewingBottom
{
	if (loaded == NO)   return YES;
	if (movingToBottom) return YES;
	
	DOMDocument *doc = [self mainFrameDocument];
	if (PointerIsEmpty(doc)) return NO;
	
	DOMHTMLElement *body = [doc body];
	
	if (body) {
		NSInteger viewHeight = view.frame.size.height;
		
		NSInteger height = [[body valueForKey:@"scrollHeight"] integerValue];
		NSInteger top    = [[body valueForKey:@"scrollTop"] integerValue];
		
		if (viewHeight == 0) return YES;
		
		return (top + viewHeight >= height - BOTTOM_EPSILON);
	}
	
	return NO;
}

- (void)savePosition
{
	if (loadingImages == 0) {
		bottom = [self viewingBottom];
	}
}

- (void)restorePosition
{
	[self moveToBottom];
}

- (void)mark
{
	if (loaded == NO) return;
	
	[self savePosition];
	[self unmark];
	
	DOMDocument *doc = [self mainFrameDocument];
	if (PointerIsEmpty(doc)) return;
	
	DOMElement *body = [self body:doc];
	
	if (body) {
		DOMElement *e = [doc createElement:@"div"];
		
		[e setAttribute:@"id" value:@"mark"];
		
		[body appendChild:e];
		
		++count;
		
		[self restorePosition];
	}
}

- (void)unmark
{
	if (loaded == NO) return;
	
	DOMDocument *doc = [self mainFrameDocument];
	if (PointerIsEmpty(doc)) return;
	
	DOMElement *e = [doc getElementById:@"mark"];
	
	if (e) {
		[[e parentNode] removeChild:e];
		
		--count;
	}
}

- (void)goToMark
{
	if (loaded == NO) return;
	
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
		
		[[doc body] setValue:NSNumberWithInteger((y - 20)) forKey:@"scrollTop"];
	}
}

- (void)reloadTheme
{
	if (loaded == NO) return;
	
	DOMDocument *doc = [self mainFrameDocument];
	if (PointerIsEmpty(doc)) return;
	
	WebScriptObject *js_api = [view js_api];
	
	if (js_api && [js_api isKindOfClass:[WebUndefined class]] == NO) {
		[js_api callWebScriptMethod:@"willDoThemeChange" withArguments:[NSArray array]]; 
	}
	
	DOMElement *body = [self body:doc];
	if (PointerIsEmpty(body)) return;
	
	self.html = [(id)body innerHTML];
	
	scrollBottom = [self viewingBottom];
	scrollTop    = [[[doc body] valueForKey:@"scrollTop"] integerValue];
	
	[[view mainFrame] loadHTMLString:[self initialDocument:[self topicValue]] baseURL:theme.baseUrl];
	
	[scroller setNeedsDisplay];
}

- (void)clear
{
	if (loaded == NO) return;
	
	self.html = nil;
	
	loaded = NO;
	count  = 0;
	
	[[view mainFrame] loadHTMLString:[self initialDocument:[self topicValue]] baseURL:theme.baseUrl];
	
	[scroller setNeedsDisplay];
}

- (void)changeTextSize:(BOOL)bigger
{
	[self savePosition];
	
	if (bigger) {
		[view makeTextLarger:nil];
	} else {
		[view makeTextSmaller:nil];
	}
	
	[self restorePosition];
}

- (void)limitNumberOfLines
{
	needsLimitNumberOfLines = NO;
	
	NSInteger n = (count - maxLines);
	if (loaded == NO || n <= 0 || count <= 0) return;
	
	DOMDocument *doc = [self mainFrameDocument];
	if (PointerIsEmpty(doc)) return;
	
	DOMElement *body = [self body:doc];
	if (PointerIsEmpty(body)) return;
	
	DOMNodeList *nodeList = [body childNodes];
	if (PointerIsEmpty(nodeList)) return;
	
	n = (nodeList.length - maxLines);
	
	for (NSInteger i = (n - 1); i >= 0; --i) {
		[body removeChild:[nodeList item:i]];
	}
	
	if (NSObjectIsNotEmpty(highlightedLineNumbers)) {
		DOMNodeList *nodeList = [body childNodes];
		
		if (nodeList.length) {
			DOMNode *firstNode = [nodeList item:0];
			
			if (firstNode) {
				NSString *lineId = [firstNode valueForKey:@"id"];
				
				if (lineId && lineId.length > 4) {
					NSString *lineNumStr = [lineId safeSubstringFromIndex:4];
					NSInteger lineNum    = [lineNumStr integerValue];
					
					while (NSObjectIsNotEmpty(highlightedLineNumbers)) {
						NSInteger i = [highlightedLineNumbers integerAtIndex:0];
						
						if (lineNum <= i) break;
						
						[highlightedLineNumbers safeRemoveObjectAtIndex:0];
					}
				}
			}
		} else {
			[highlightedLineNumbers removeAllObjects];
		}
	}
	
	count -= n;
	
	if (count < 0) count = 0;
	
	[scroller setNeedsDisplay];
}

- (void)setNeedsLimitNumberOfLines
{
	if (needsLimitNumberOfLines) return;
	
	needsLimitNumberOfLines = YES;
	
	[self limitNumberOfLines];
}

- (BOOL)print:(LogLine *)line
{
	return [self print:line withHTML:NO];
}

- (BOOL)print:(LogLine *)line withHTML:(BOOL)rawHTML
{
	if (NSObjectIsEmpty(line.body)) return NO;
	
	LogLineType type = line.lineType;
	
	NSString *body			 = nil;
	NSString *lineTypeString = [LogLine lineTypeString:type];
	
	BOOL highlighted     = NO;
	BOOL showInlineImage = NO;
	
	BOOL isText			 = (type == LINE_TYPE_PRIVMSG || type == LINE_TYPE_NOTICE || type == LINE_TYPE_ACTION);
	BOOL drawLinks		 = BOOLReverseValue([[URLParser bannedURLRegexLineTypes] containsObject:lineTypeString]);
	
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
		
		body = [LogRenderer renderBody:line.body
							controller:((type == LINE_TYPE_PRIVMSG || type == LINE_TYPE_ACTION) ? self : nil) 
							renderType:ASCII_TO_HTML 
							properties:inputDictionary 
							resultInfo:&outputDictionary];
		
		urlRanges   = [outputDictionary arrayForKey:@"URLRanges"];
		highlighted = [outputDictionary boolForKey:@"wordMatchFound"];
	} else {
		body = line.body;
	}
	
	if (loaded == NO) {
		[lines safeAddObject:line];
		
		return highlighted;
	}
	
	NSMutableString *s = [NSMutableString string];
	
	if (line.memberType == MEMBER_TYPE_MYSELF) {
		[s appendFormat:@"<p type=\"%@\">", [LogLine memberTypeString:line.memberType]];
	} else {
		[s appendFormat:@"<p>"];
	}
	
	if (NSObjectIsEmpty(line.time) && rawHTML == NO) {
		return NO;
	}
	
	if (line.time)  [s appendFormat:@"<span class=\"time\">%@</span>",  logEscape(line.time)];
	if (line.place) [s appendFormat:@"<span class=\"place\">%@</span>", logEscape(line.place)];
	
	if (line.nick) {
		[s appendFormat:@"<span class=\"sender\" ondblclick=\"Textual.on_dblclick_nick()\" oncontextmenu=\"Textual.on_nick()\" type=\"%@\"", [LogLine memberTypeString:line.memberType]];
		
		if (line.memberType == MEMBER_TYPE_NORMAL && [Preferences disableNicknameColors] == NO) {
			[s appendFormat:@" colornumber=\"%d\"", line.nickColorNumber];
		}
		
		[s appendFormat:@">%@</span> ", logEscape(line.nick)];
	}
	
	if (isText && NSObjectIsNotEmpty(urlRanges) && [Preferences showInlineImages]) {
		NSString *imagePageUrl = nil;
		NSString *imageUrl     = nil;
		
		for (NSValue *rangeValue in urlRanges) {
			NSString *url = [line.body safeSubstringWithRange:[rangeValue rangeValue]];
			
			imageUrl = [ImageURLParser imageURLForURL:url];
			
			if (imageUrl) {
				imagePageUrl = url;
				
				break;
			}
		}
		
		if (imageUrl) {
			showInlineImage = YES;
			
			[s appendFormat:@"<span class=\"message\" type=\"%@\">%@<br/>",													 lineTypeString, body];
			[s appendFormat:@"<a href=\"%@\"><img src=\"%@\" class=\"inlineimage\" style=\"max-width:%ipx;\"/></a></span>", imagePageUrl, imageUrl, [Preferences inlineImagesMaxWidth]];
		}
	}
	
	if (showInlineImage == NO) {
		[s appendFormat:@"<span class=\"message\" type=\"%@\">%@</span>", lineTypeString, body];
	}
	
	[s appendFormat:@"</p>"];
	
	NSMutableDictionary *attrs = [NSMutableDictionary dictionary];
	
	[attrs setObject:[LogLine lineTypeString:type]				forKey:@"type"];
	[attrs setObject:((highlighted) ? @"true" : @"false")		forKey:@"highlight"];
	[attrs setObject:((isText) ? @"line text" : @"line event")	forKey:@"class"];
	
	if (line.nickInfo) {
		[attrs setObject:line.nickInfo forKey:@"nick"];
	}
	
	[[self invokeInBackgroundThread] writeLineInBackground:s attributes:attrs];
	
	if (highlighted && [Preferences logAllHighlightsToQuery]) {
		IRCChannel *hlc = [client findChannelOrCreate:TXTLS(@"HIGHLIGHTS_LOG_WINDOW_TITLE") useTalk:YES];
		
		line.body			= TXTFLS(@"IRC_USER_WAS_HIGHLIGHTED", [channel name], line.body);
		line.keywords		= nil;
		line.excludeWords	= nil;
		
		[hlc print:line];
		[hlc setIsUnread:YES];
		
		[world reloadTree];
	}
	
	return highlighted;
}

- (void)writeLineInBackground:(NSString *)aHtml attributes:(NSDictionary *)attrs
{
	NSInteger loopProtect = 0;
	
	while ([view isLoading]) {
		[NSThread sleepForTimeInterval:0.1];
		
		loopProtect++;
		
		if (loopProtect >= 30) {
			break;
		}
		
		continue;
	}
	
	[[self iomt] writeLine:aHtml attributes:attrs];
}

- (void)writeLine:(NSString *)aHtml attributes:(NSDictionary *)attrs
{
	[self savePosition];
	
	++lineNumber;
	++count;
	
	DOMDocument *doc  = [self mainFrameDocument];
	DOMElement  *body = [self body:doc];
	if (PointerIsEmpty(body)) return;
	
	DOMElement *div = [doc createElement:@"div"];
	
	[(id)div setInnerHTML:aHtml];
	
	for (NSString *key in attrs) {
		NSString *value = [attrs objectForKey:key];
		
		[div setAttribute:key value:value];
	}
	
	[div setAttribute:@"id" value:[NSString stringWithFormat:@"line%d", lineNumber]];
	
	[body appendChild:div];
	
	if (maxLines > 0 && (count - 10) > maxLines) {
		[self setNeedsLimitNumberOfLines];
	}
	
	if ([[attrs objectForKey:@"highlight"] isEqualToString:@"true"]) {
		[highlightedLineNumbers safeAddObject:[NSNumber numberWithInt:lineNumber]];
	}
	
	if (scroller) {
		[scroller setNeedsDisplay];
	}
	
	WebScriptObject *js_api = [view js_api];
	
	if (js_api && [js_api isKindOfClass:[WebUndefined class]] == NO) {
		[js_api callWebScriptMethod:@"newMessagePostedToDisplay" 
					  withArguments:[NSArray arrayWithObjects:NSNumberWithInteger(lineNumber), nil]];  
	}
}

- (NSString *)initialDocument:(NSString *)topic
{
	NSMutableString *bodyAttrs = [NSMutableString string];
	
	if (channel) {
		[bodyAttrs appendFormat:@"type=\"%@\"", [channel channelTypeString]];
		
		if ([channel isChannel]) {
			[bodyAttrs appendFormat:@" channelname=\"%@\"", logEscape([channel name])];
		}
	} else {
		[bodyAttrs appendString:@"type=\"server\""];
	}
	
	if ([Preferences rightToLeftFormatting]) {
		[bodyAttrs appendString:@" dir=\"rtl\""];
	}
	
	NSMutableString *s = [NSMutableString string];
	
	NSString *override_style = [self generateOverrideStyle];
	
	[s appendFormat:@"<html %@>", bodyAttrs];
	[s appendString:@"<head>"];
	[s appendString:@"<meta http-equiv=\"Content-Type\" content=\"text/html; charset=utf-8\">"];
	
	NSTimeInterval ti = [NSDate timeIntervalSinceReferenceDate];
	
	[s appendFormat:@"<link rel=\"stylesheet\" type=\"text/css\" href=\"design.css?%d\" />", ti];
	[s appendFormat:@"<script type=\"text/javascript\">\n%@\n</script>", [[theme core_js] content]];
	[s appendFormat:@"<script src=\"scripts.js?%d\" type=\"text/javascript\"></script>", ti];
	
	if (override_style) {
		[s appendFormat:@"<style type=\"text/css\" id=\"textual_override_style\">%@</style>", override_style];
	}
	
	[s appendString:@"</head>"];
	[s appendFormat:@"<body %@>", bodyAttrs];
	[s appendString:@"<div id=\"body_home\"></div>"];
	
	if (NSObjectIsNotEmpty(topic)) {
		[s appendFormat:@"<div id=\"topic_bar\">%@</div></body>", topic];
	} else {
		[s appendFormat:@"<div id=\"topic_bar\">%@</div></body>", TXTLS(@"NO_TOPIC_DEFAULT_TOPIC")];
	}
	
	[s appendString:@"</html>"];
	
	return s;
}

- (void)applyOverrideStyle
{
	NSString *os = [self generateOverrideStyle];
	
	DOMDocument *doc = [self mainFrameDocument];
	DOMElement  *e   = [doc getElementById:@"textual_override_style"];
	
	if (e) {
		[[e parentNode] removeChild:e];
	}
	
	if (os) {
		DOMNode *head = [self html_head];
		
		if (head) {
			DOMElement *style = [doc createElement:@"style"];
			
			[style setAttribute:@"id" value:@"textual_override_style"];
			[style setAttribute:@"type" value:@"text/css"];
			
			[(id)style setInnerHTML:os];
			
			[head appendChild:style];
		}
	}
}

- (NSString *)generateOverrideStyle
{
	NSMutableString *sf = [NSMutableString string];
	
	OtherTheme *other = world.viewTheme.other;
	
	NSString *name  = [Preferences themeLogFontName];
	NSInteger rsize = [Preferences themeLogFontSize];
	double    size  = ([Preferences themeLogFontSize] * (72.0 / 96.0));
	
	if (other.overrideChannelFont) {
		NSFont *channelFont = other.overrideChannelFont;
		
		name  = [channelFont fontName];
		rsize = [channelFont pointSize];
		size  = ([channelFont pointSize] * (72.0 / 96.0));
	} 
	
	[sf appendString:@"html, body, body[type], body {"];
	[sf appendFormat:@"font-family:'%@';", name];
	[sf appendFormat:@"font-size:%fpt;", size];
	[sf appendString:@"}"];
	
	if ([Preferences rightToLeftFormatting] == NO) {
		if (other.overrideMessageIndentWrap == YES && other.indentWrappedMessages == NO) return sf;
		
		if ([Preferences indentOnHang]) {
			NSFont	     *font		 = [NSFont fontWithName:name size:round(rsize)];
			NSDictionary *attributes = [NSDictionary dictionaryWithObject:font forKey:NSFontAttributeName];	
			
			NSSize    textSize  = [TXFormattedTimestampWithOverride([Preferences themeTimestampFormat], other.timestampFormat) sizeWithAttributes:attributes]; 
			NSInteger textWidth = (textSize.width + (6 + other.nicknameFormatFixedWidth));
			
			[sf appendString:@"body div#body_home p {"];
			[sf appendFormat:@"margin-left: %ipx;", textWidth];
			[sf appendFormat:@"text-indent: -%ipx;", textWidth];  
			[sf appendString:@"}"];
			
			[sf appendString:@"body .time {"];
			[sf appendFormat:@"width: %fpx;", (textSize.width + 6)];
			[sf appendString:@"}"];
		}
	}
	
	return sf;
}

- (void)setUpScroller
{
	WebFrameView *frame = [[view mainFrame] frameView];
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
	
	if ([scrollView respondsToSelector:@selector(setAllowsHorizontalScrolling:)]) {
		[(id)scrollView setAllowsHorizontalScrolling:NO];
	}
	
	NSScroller *old = [scrollView verticalScroller];
	
	if (old && [old isKindOfClass:[MarkedScroller class]] == NO) {
		if (scroller) {
			[scroller removeFromSuperview];
			[scroller drain];
		}
		
		scroller = [[MarkedScroller alloc] initWithFrame:NSMakeRect(-16, -64, 16, 64)];
		scroller.dataSource = self;
		
		[scroller setDoubleValue:[old doubleValue]];
		[scroller setKnobProportion:[old knobProportion]];
		
		[scrollView setVerticalScroller:scroller];
	}
}

#pragma mark -
#pragma mark WebView Delegate

- (void)webView:(WebView *)sender didClearWindowObject:(WebScriptObject *)windowObject forFrame:(WebFrame *)frame
{
	[js drain];
	js = [windowObject retain];
	
	[js setValue:sink forKey:@"app"];
}

- (void)webView:(WebView *)sender didFinishLoadForFrame:(WebFrame *)frame
{
	loaded		  = YES;
	loadingImages = 0;
	
	[self setUpScroller];
	
	if (PointerIsEmpty(autoScroller)) {
		autoScroller = [WebViewAutoScroll new];
	}
	
	autoScroller.webFrame = view.mainFrame.frameView;
	
	if (html) {
		DOMDocument *doc = [frame DOMDocument];
		
		if (doc) {
			DOMElement *body = [self body:doc];
			
			[(id)body setInnerHTML:html];
			
			self.html = nil;
			
			if (scrollBottom) {
				[self moveToBottom];
			} else if (scrollTop) {
				[body setValue:NSNumberWithInteger(scrollTop) forKey:@"scrollTop"];
			}
		}
	} else {
		[self moveToBottom];
		
		bottom = YES;
	}
	
	for (LogLine *line in lines) {
		[self print:line];
	}
	
	[lines removeAllObjects];
	
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
	
	WebScriptObject *js_api = [view js_api];
	
	if (js_api && [js_api isKindOfClass:[WebUndefined class]] == NO) {
		[js_api callWebScriptMethod:@"doneThemeChange" withArguments:[NSArray array]]; 
	}
}

- (id)webView:(WebView *)sender identifierForInitialRequest:(NSURLRequest *)request fromDataSource:(WebDataSource *)dataSource
{
	NSString *scheme = [[[request URL] scheme] lowercaseString];
	
	if ([scheme isEqualToString:@"http"] || 
		[scheme isEqualToString:@"https"]) {
		
		if (loadingImages == 0) {
			[self savePosition];
		}
		
		++loadingImages;
		
		return self;
	}
	
	return nil;
}

- (void)webView:(WebView *)sender resource:(id)identifier didFinishLoadingFromDataSource:(WebDataSource *)dataSource
{
	if (identifier) {
		if (loadingImages > 0) {
			--loadingImages;
		}
		
		if (loadingImages == 0) {
			[self restorePosition];
		}
	}
}

#pragma mark -
#pragma mark LogView Delegate

- (void)logViewKeyDown:(NSEvent *)e
{
	[world logKeyDown:e];
}

- (void)logViewOnDoubleClick:(NSString *)e
{
	[world logDoubleClick:e];
}

- (void)logViewWillResize
{
	[self savePosition];
}

- (void)logViewDidResize
{
	[self restorePosition];
}

#pragma mark -
#pragma mark MarkedScroller Delegate

- (NSArray *)markedScrollerPositions:(MarkedScroller *)sender
{
	NSMutableArray *result = [NSMutableArray array];
	
	DOMDocument *doc = [self mainFrameDocument];
	if (PointerIsEmpty(doc)) return [NSArray array];
	
	if (doc) {
		for (NSNumber *n in highlightedLineNumbers) {
			NSString *key = [NSString stringWithFormat:@"line%d", [n integerValue]];
			
			DOMElement *e = [doc getElementById:key];
			
			if (e) {
				NSInteger offsetTop    = [[e valueForKey:@"offsetTop"] integerValue];
				NSInteger offsetHeight = [[e valueForKey:@"offsetHeight"] integerValue];
				
				NSInteger pos = (offsetTop + (offsetHeight / 2));
				
				[result safeAddObject:NSNumberWithInteger(pos)];
			}
		}
	}
	
	return result;
}

- (NSColor *)markedScrollerColor:(MarkedScroller *)sender
{
	if ([Preferences applicationRanOnLion]) {
		return [NSColor greenColor];
	}
	
	return [NSColor redColor];
}

@end