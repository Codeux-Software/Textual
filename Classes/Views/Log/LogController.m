// Created by Satoshi Nakagawa <psychs AT limechat DOT net> <http://github.com/psychs/limechat>
// Modifications by Codeux Software <support AT codeux DOT com> <https://github.com/codeux/Textual>
// You can redistribute it and/or modify it under the new BSD license.

#define BOTTOM_EPSILON	0
#define TIME_BUFFER_SIZE	256

@interface NSScrollView (Private)
- (void)setAllowsHorizontalScrolling:(BOOL)value;
@end

@interface LogController (Private)
- (void)savePosition;
- (void)restorePosition;
- (void)setNeedsLimitNumberOfLines;
- (void)writeLine:(NSString *)str attributes:(NSDictionary *)attrs;
- (NSString *)initialDocument:(NSString *)topic;
- (NSString *)generateOverrideStyle;
@end

@implementation LogController

@synthesize view;
@synthesize world;
@synthesize client;
@synthesize channel;
@synthesize menu;
@synthesize urlMenu;
@synthesize addrMenu;
@synthesize chanMenu;
@synthesize memberMenu;
@synthesize theme;
@synthesize maxLines;
@synthesize initialBackgroundColor;
@synthesize highlightedLineNumbers;
@synthesize policy;
@synthesize sink;
@synthesize scroller;
@synthesize js;
@synthesize autoScroller;
@synthesize becameVisible;
@synthesize bottom;
@synthesize movingToBottom;
@synthesize lines;
@synthesize lineNumber;
@synthesize count;
@synthesize needsLimitNumberOfLines;
@synthesize loaded;
@synthesize loadingImages;
@synthesize html;
@synthesize scrollBottom;
@synthesize scrollTop;

- (id)init
{
	if ((self = [super init])) {
		bottom = YES;
		maxLines = 300;
		lines = [NSMutableArray new];
		highlightedLineNumbers = [NSMutableArray new];
		
		[[WebPreferences standardPreferences] setCacheModel:WebCacheModelDocumentViewer];
		[[WebPreferences standardPreferences] setUsesPageCache:NO];
	}
	return self;
}

- (void)dealloc
{
	[NSObject cancelPreviousPerformRequestsWithTarget:self];
	
	[view release];
	[policy release];
	[sink release];
	[scroller release];
	[js release];
	[autoScroller release];
	
	[menu release];
	[urlMenu release];
	[addrMenu release];
	[chanMenu release];
	[memberMenu release];
	[theme release];
	[initialBackgroundColor release];
	[highlightedLineNumbers release];
	
	[lines release];
	
	[html release];
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
	
	if (!loaded) return;
	
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
	policy.menuController = [world menuController];
	policy.menu = menu;
	policy.urlMenu = urlMenu;
	policy.addrMenu = addrMenu;
	policy.chanMenu = chanMenu;
	policy.memberMenu = memberMenu;
	
	sink = [LogScriptEventSink new];
	sink.owner = self;
	sink.policy = policy;
	
	if (view) {
		[view removeFromSuperview];
		[view release];
	}
	
	view = [[LogView alloc] initWithFrame:NSZeroRect];
	if ([view respondsToSelector:@selector(setBackgroundColor:)]) {
		[(id)view setBackgroundColor:initialBackgroundColor];
	}
	view.frameLoadDelegate = self;
	view.UIDelegate = policy;
	view.policyDelegate = policy;
	view.resourceLoadDelegate = self;
	view.keyDelegate = self;
	view.resizeDelegate = self;
	view.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
	[[view mainFrame] loadHTMLString:[self initialDocument:nil] baseURL:theme.baseUrl];
}

- (void)notifyDidBecomeVisible
{
	if (!becameVisible) {
		becameVisible = YES;
		[self moveToBottom];
	}
}

- (struct DOMHTMLElement *)html_head
{
	DOMHTMLDocument *doc = (DOMHTMLDocument *)[view mainFrameDocument];
	DOMNodeList *nodes = [doc getElementsByTagName:@"head"];
	DOMHTMLElement *head = (DOMHTMLElement *)[nodes item:0];
	return (struct DOMHTMLElement *)head;
}

- (struct DOMHTMLElement *)body:(DOMHTMLDocument *)doc 
{
	return (struct DOMHTMLElement *)[doc getElementById:@"body_home"];
}

- (struct DOMHTMLElement *)topic:(DOMHTMLDocument *)doc 
{
	return (struct DOMHTMLElement *)[doc getElementById:@"topic_bar"];
}

- (NSString *)topicValue
{
	DOMHTMLDocument *doc = (DOMHTMLDocument *)[view mainFrameDocument];
	if (!doc) return @"";
	return [(DOMHTMLElement *)[self topic:doc] innerHTML];
}

- (BOOL)setTopicWithoutDelay:(NSString *)topic
{
	if ([topic length] >= 1) {
		if ([[self topicValue] isEqualToString:topic]) return YES;
		
		NSString *body = [LogRenderer renderBody:topic
										 nolinks:NO
										keywords:nil
									excludeWords:nil
								  exactWordMatch:NO
									 highlighted:NULL
									   URLRanges:NULL];
		
		DOMHTMLDocument *doc = (DOMHTMLDocument *)[view mainFrameDocument];
		if (!doc) return NO;
		DOMHTMLElement *topic_body = (DOMHTMLElement *)[self topic:doc];
		if (!topic_body) return NO;
		
		[topic_body setInnerHTML:body];
	}
	
	return YES;
}

- (void)setTopicWithDelay:(NSString *)topic
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	[NSThread sleepForTimeInterval:2.0];
	[[self invokeOnMainThread] setTopicWithoutDelay:topic];
	
	[pool release];
}

- (void)setTopic:(NSString *)topic 
{
	if ([self setTopicWithoutDelay:topic] == NO) {
		[[self invokeInBackgroundThread] setTopicWithDelay:topic];
	}
}

- (void)moveToTop
{
	if (!loaded) return;
	DOMHTMLDocument *doc = (DOMHTMLDocument *)[view mainFrameDocument];
	if (!doc) return;
	DOMHTMLElement *body = [doc body];
	[body setValue:[NSNumber numberWithInteger:0] forKey:@"scrollTop"];
}

- (void)moveToBottom
{
	movingToBottom = NO;
	
	if (!loaded) return;
	DOMHTMLDocument *doc = (DOMHTMLDocument *)[view mainFrameDocument];
	if (!doc) return;
	DOMHTMLElement *body = [doc body];
	[body setValue:[body valueForKey:@"scrollHeight"] forKey:@"scrollTop"];
}

- (BOOL)viewingBottom
{
	if (!loaded) return YES;
	if (movingToBottom) return YES;
	
	DOMHTMLDocument *doc = (DOMHTMLDocument *)[view mainFrameDocument];
	if (!doc) return YES;
	DOMHTMLElement *body = [doc body];
	NSInteger viewHeight = view.frame.size.height;
	NSInteger height = [[body valueForKey:@"scrollHeight"] integerValue];
	NSInteger top = [[body valueForKey:@"scrollTop"] integerValue];
	
	if (viewHeight == 0) return YES;
	return top + viewHeight >= height - BOTTOM_EPSILON;
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
	if (!loaded) return;
	
	[self savePosition];
	[self unmark];
	
	DOMHTMLDocument *doc = (DOMHTMLDocument *)[view mainFrameDocument];
	if (!doc) return;
	DOMHTMLElement *body = (DOMHTMLElement *)[self body:doc];
	DOMHTMLElement *e = (DOMHTMLElement *)[doc createElement:@"div"];
	[e setAttribute:@"id" value:@"mark"];
	[body appendChild:e];
	++count;
	
	[self restorePosition];
}

- (void)unmark
{
	if (!loaded) return;
	
	DOMHTMLDocument *doc = (DOMHTMLDocument *)[view mainFrameDocument];
	if (!doc) return;
	DOMHTMLElement *e = (DOMHTMLElement *)[doc getElementById:@"mark"];
	if (e) {
		[(DOMHTMLElement *)[e parentNode] removeChild:e];
		--count;
	}
}

- (void)goToMark
{
	if (!loaded) return;
	
	DOMHTMLDocument *doc = (DOMHTMLDocument *)[view mainFrameDocument];
	if (!doc) return;
	DOMHTMLElement *e = (DOMHTMLElement *)[doc getElementById:@"mark"];
	if (e) {
		NSInteger y = 0;
		DOMHTMLElement *t = e;
		while (t) {
			if ([t isKindOfClass:[DOMHTMLElement class]]) {
				y += [[t valueForKey:@"offsetTop"] integerValue];
			}
			t = (DOMHTMLElement *)[t parentNode];
		}
		[[doc body] setValue:[NSNumber numberWithInteger:y - 20] forKey:@"scrollTop"];
	}
}

- (void)reloadTheme
{
	if (!loaded) return;
	
	DOMHTMLDocument *doc = (DOMHTMLDocument *)[view mainFrameDocument];
	if (!doc) return;
	
	// we need to give the theme a chance to do any cleanup 
	// before we try and get the body_html tag in the next statement
	[[view js_api] callWebScriptMethod:@"willDoThemeChange" withArguments:[NSArray array]]; 
		
	DOMHTMLElement *body = (DOMHTMLElement *)[self body:doc];
	if (!body) return;
	
	self.html = [body innerHTML];
	scrollBottom = [self viewingBottom];
	scrollTop = [[[doc body] valueForKey:@"scrollTop"] integerValue];
	
	[[view mainFrame] loadHTMLString:[self initialDocument:[self topicValue]] baseURL:theme.baseUrl];
	[scroller setNeedsDisplay];
}

- (void)clear
{
	if (!loaded) return;

	self.html = nil;
	loaded = NO;
	count = 0;
	
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
	
	NSInteger n = count - maxLines;
	if (!loaded || n <= 0 || count <= 0) return;
	
	DOMHTMLDocument *doc = (DOMHTMLDocument *)[view mainFrameDocument];
	if (!doc) return;
	DOMHTMLElement *body = (DOMHTMLElement *)[self body:doc];
	DOMNodeList *nodeList = [body childNodes];
	
	n = nodeList.length - maxLines;
	for (NSInteger i = (n - 1); i >= 0; --i) {
		[body removeChild:[nodeList item:i]];
	}
	
	if (highlightedLineNumbers.count > 0) {
		DOMNodeList *nodeList = [body childNodes];
		if (nodeList.length) {
			DOMHTMLElement *firstNode = (DOMHTMLElement *)[nodeList item:0];
			if (firstNode) {
				NSString *lineId = [firstNode valueForKey:@"id"];
				if (lineId && lineId.length > 4) {
					NSString *lineNumStr = [lineId substringFromIndex:4];
					NSInteger lineNum = [lineNumStr integerValue];
					while (highlightedLineNumbers.count) {
						NSInteger i = [[highlightedLineNumbers objectAtIndex:0] integerValue];
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
	if ([line.body length] < 1) return NO;
	
	BOOL key = NO;
	NSString *body = nil;
	NSArray *urlRanges = nil;
	
	BOOL showInlineImage = NO;
	LogLineType type = line.lineType;
	NSString *lineTypeString = [LogLine lineTypeString:type];
	BOOL isText = type == LINE_TYPE_PRIVMSG || type == LINE_TYPE_NOTICE || type == LINE_TYPE_ACTION;
	
	if (rawHTML == NO) {
		body = [LogRenderer renderBody:line.body
							   nolinks:[[URLParser bannedURLRegexLineTypes] containsObject:lineTypeString]
							  keywords:line.keywords
						  excludeWords:line.excludeWords
						exactWordMatch:([Preferences keywordMatchingMethod] == KEYWORD_MATCH_EXACT)
						   highlighted:&key
							 URLRanges:&urlRanges];
	} else {
		body = line.body;
	}
	
	if (!loaded) {
		[lines addObject:line];
		return key;
	}
	
	NSMutableString *s = [NSMutableString string];
	
	if (line.memberType == MEMBER_TYPE_MYSELF) {
		[s appendFormat:@"<p type=\"%@\">", [LogLine memberTypeString:line.memberType]];
	} else {
		[s appendFormat:@"<p>"];
	}
	
	if (line.time) [s appendFormat:@"<span class=\"time\">%@</span>", logEscape(line.time)];
	if (line.place) [s appendFormat:@"<span class=\"place\">%@</span>", logEscape(line.place)];
	if (line.nick) {
		[s appendFormat:@"<span class=\"sender\" oncontextmenu=\"Textual.on_nick()\" type=\"%@\"", [LogLine memberTypeString:line.memberType]];
		if (line.memberType == MEMBER_TYPE_NORMAL && [Preferences disableNicknameColors] == NO) [s appendFormat:@" colornumber=\"%d\"", line.nickColorNumber];
		[s appendFormat:@">%@</span> ", logEscape(line.nick)];
	}
	
	if (isText && urlRanges.count && [Preferences showInlineImages]) {
		NSString *imagePageUrl = nil;
		NSString *imageUrl = nil;
		
		for (NSValue *rangeValue in urlRanges) {
			NSString *url = [line.body substringWithRange:[rangeValue rangeValue]];
			imageUrl = [ImageURLParser imageURLForURL:url];
			if (imageUrl) {
				imagePageUrl = url;
				break;
			}
		}
		
		if (imageUrl) {
			showInlineImage = YES;
			[s appendFormat:@"<span class=\"message\" type=\"%@\">%@<br/>", lineTypeString, body];
			[s appendFormat:@"<a href=\"%@\"><img src=\"%@\" class=\"inlineimage\" style=\"max-width: %ipx;\"/></a></span>", imagePageUrl, imageUrl, [Preferences inlineImagesMaxWidth]];
		}
	}
	
	if (!showInlineImage) {
		[s appendFormat:@"<span class=\"message\" type=\"%@\">%@</span>", lineTypeString, body];
	}
	
	[s appendFormat:@"</p>"];
	
	NSString *klass = isText ? @"line text" : @"line event";
	
	NSMutableDictionary *attrs = [NSMutableDictionary dictionary];
	[attrs setObject:klass forKey:@"class"];
	[attrs setObject:[LogLine lineTypeString:type] forKey:@"type"];
	[attrs setObject:(key ? @"true" : @"false") forKey:@"highlight"];
	if (line.nickInfo) {
		[attrs setObject:line.nickInfo forKey:@"nick"];
	}
	
	[self writeLine:s attributes:attrs];
	
	if (key && [Preferences logAllHighlightsToQuery]) {
		IRCChannel *hlc = [client findChannelOrCreate:TXTLS(@"HIGHLIGHTS_LOG_WINDOW_TITLE") useTalk:YES];
		
		line.body = [NSString stringWithFormat:TXTLS(@"IRC_USER_WAS_HIGHLIGHTED"), [channel name], line.body];
		line.keywords = nil;
		line.excludeWords = nil;
		
		[hlc print:line];
		
		[hlc setIsUnread:YES];
		[world reloadTree];
	}
	
	return key;
}

- (void)writeLine:(NSString *)aHtml attributes:(NSDictionary *)attrs
{
	[self savePosition];
	
	++lineNumber;
	++count;
	
	DOMHTMLDocument *doc = (DOMHTMLDocument *)[[view mainFrame] DOMDocument];
	if (!doc) return;
	DOMHTMLElement *body = (DOMHTMLElement *)[self body:doc];
	DOMHTMLElement *div = (DOMHTMLElement *)[doc createElement:@"div"];
	[div setInnerHTML:aHtml];
	
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
		[highlightedLineNumbers addObject:[NSNumber numberWithInt:lineNumber]];
	}
	
	if (scroller) {
		[scroller setNeedsDisplay];
	}
	[[view js_api] callWebScriptMethod:@"newMessagePostedToDisplay" 
									 withArguments:[NSArray arrayWithObjects:[NSNumber numberWithInteger:lineNumber], nil]];  
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
	
	[s appendString:@"<!DOCTYPE html PUBLIC \"-//W3C//DTD XHTML 1.0 Strict//EN\" \"http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd\">"];
	[s appendFormat:@"<html %@>", bodyAttrs];
	[s appendString:
	 @"<head>"
	 @"<meta http-equiv=\"Content-Type\" content=\"text/html; charset=utf-8\">"
	 ];
	
	// used to ensure our js and css is always current because WebView likes
	// to cache it even though we tell it not to
	NSTimeInterval ti = [NSDate timeIntervalSinceReferenceDate];
	[s appendFormat:@"<link rel=\"stylesheet\" type=\"text/css\" href=\"design.css?%d\" />", ti];
	[s appendFormat:@"<script type=\"text/javascript\">\n%@\n</script>", [[theme core_js] content]];
	[s appendFormat:@"<script src=\"scripts.js?%d\" type=\"text/javascript\"></script>",ti];
	if (override_style) [s appendFormat:@"<style type=\"text/css\" id=\"textual_override_style\">%@</style>", override_style];
	[s appendString:@"</head>"];
	[s appendFormat:@"<body %@>", bodyAttrs];
	[s appendString:@"<div id=\"body_home\"></div>"];
	if ([topic length] >= 1) {
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

	// remove our previous style overrides
	DOMHTMLDocument *doc = (DOMHTMLDocument *)[view mainFrameDocument];
	DOMHTMLElement *e = (DOMHTMLElement *)[doc getElementById:@"textual_override_style"];
	if (e) {
		[(DOMHTMLElement *)[e parentNode] removeChild:e];
	}
		
	// apply new style overrides
	if (os) {
		DOMHTMLElement *head = (DOMHTMLElement *)[self html_head];
		
		if (head) {
			DOMHTMLElement *style = (DOMHTMLElement *)[doc createElement:@"style"];
			
			[style setAttribute:@"id" value:@"textual_override_style"];
			[style setAttribute:@"type" value:@"text/css"];
			[style setInnerHTML:os];
			
			[head appendChild:style];
		}
	}
}

- (NSString *)generateOverrideStyle
{
	NSMutableString *sf = [NSMutableString string];
	
	OtherTheme *other = world.viewTheme.other;
	
	NSString *name = [Preferences themeLogFontName];
	NSInteger rsize = [Preferences themeLogFontSize];
	double size = ([Preferences themeLogFontSize] * (72.0 / 96.0));
	
	if (other.overrideChannelFont) {
		NSFont *channelFont = other.overrideChannelFont;
		
		name = [channelFont fontName];
		rsize = [channelFont pointSize];
		size = ([channelFont pointSize] * (72.0 / 96.0));
	} 
	
	[sf appendString:@"html, body, body[type], body {"];
	[sf appendFormat:@"font-family:'%@';", name];
	[sf appendFormat:@"font-size:%fpt;", size];
	[sf appendString:@"}"];
	
	// ====================================================== //
	
	if ([Preferences rightToLeftFormatting] == NO) {
		if (other.overrideMessageIndentWrap == YES && other.indentWrappedMessages == NO) return sf;
		
		if ([Preferences indentOnHang]) {
			NSFont *font = [NSFont fontWithName:name size:round(rsize)];
			NSDictionary *attributes = [NSDictionary dictionaryWithObject:font forKey:NSFontAttributeName];	
			NSSize textSize = [TXFormattedTimestampWithOverride([Preferences themeTimestampFormat], other.timestampFormat) sizeWithAttributes:attributes]; 
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
	if (!frame) return;
	
	NSScrollView *scrollView = nil;
	for (NSView *v in [frame subviews]) {
		if ([v isKindOfClass:[NSScrollView class]]) {
			scrollView = (NSScrollView *)v;
			break;
		}
	}
	
	if (!scrollView) return;
	
	[scrollView setHasHorizontalScroller:NO];
	if ([scrollView respondsToSelector:@selector(setAllowsHorizontalScrolling:)]) {
		[(id)scrollView setAllowsHorizontalScrolling:NO];
	}
	
	NSScroller *old = [scrollView verticalScroller];
	if (old && ![old isKindOfClass:[MarkedScroller class]]) {
		if (scroller) {
			[scroller removeFromSuperview];
			[scroller release];
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
	[js release];
	js = [windowObject retain];
	[js setValue:sink forKey:@"app"];
}

- (void)webView:(WebView *)sender didFinishLoadForFrame:(WebFrame *)frame
{
	loaded = YES;
	loadingImages = 0;
	[self setUpScroller];
	
	if (!autoScroller) {
		autoScroller = [WebViewAutoScroll new];
	}
	autoScroller.webFrame = view.mainFrame.frameView;
	
	if (html) {
		DOMHTMLDocument *doc = (DOMHTMLDocument *)[frame DOMDocument];
		if (doc) {
			DOMHTMLElement *body = (DOMHTMLElement *)[self body:doc];
			[body setInnerHTML:html];
			self.html = nil;
			
			if (scrollBottom) {
				[self moveToBottom];
			} else if (scrollTop) {
				[body setValue:[NSNumber numberWithInteger:scrollTop] forKey:@"scrollTop"];
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
	
	DOMHTMLDocument *doc = (DOMHTMLDocument *)[frame DOMDocument];
	if (!doc) return;
	DOMHTMLElement *body = (DOMHTMLElement *)[self body:doc];
	DOMHTMLElement *e = (DOMHTMLElement *)[body firstChild];
	
	while (e) {
		DOMHTMLElement *next = (DOMHTMLElement *)[e nextSibling];
		
		if (![e isKindOfClass:[DOMHTMLDivElement class]] && ![e isKindOfClass:[DOMHTMLHRElement class]]) {
			[body removeChild:e];
		}
		
		e = next;
	}
	
	// we need to give the theme a chance to do any special change theme housekeeping
	[[view js_api] callWebScriptMethod:@"doneThemeChange" withArguments:[NSArray array]]; 
} 

- (id)webView:(WebView *)sender identifierForInitialRequest:(NSURLRequest *)request fromDataSource:(WebDataSource *)dataSource
{
	NSString *scheme = [[[request URL] scheme] lowercaseString];
	if ([scheme isEqualToString:@"http"] || [scheme isEqualToString:@"https"]) {
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
	
	DOMHTMLDocument *doc = (DOMHTMLDocument *)[view mainFrameDocument];
	if (doc) {
		for (NSNumber *n in highlightedLineNumbers) {
			NSString *key = [NSString stringWithFormat:@"line%d", [n integerValue]];
			DOMHTMLElement *e = (DOMHTMLElement *)[doc getElementById:key];
			if (e) {
				NSInteger pos = [[e valueForKey:@"offsetTop"] integerValue] + [[e valueForKey:@"offsetHeight"] integerValue] / 2;
				[result addObject:[NSNumber numberWithInt:pos]];
			}
		}
	}
	
	return result;
}

- (NSColor *)markedScrollerColor:(MarkedScroller *)sender
{
	return [NSColor redColor];
}

@end