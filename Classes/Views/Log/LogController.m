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
- (void)writeLineInBackground:(NSString *)aHtml attributes:(NSDictionary *)attrs;
- (void)writeLine:(NSString *)aHtml attributes:(NSDictionary *)attrs;
- (NSString *)initialDocument:(NSString *)topic;
- (NSString *)generateOverrideStyle;
- (DOMNode *)html_head;
- (DOMElement *)body:(DOMDocument *)doc;
- (DOMElement *)topic:(DOMDocument *)doc;
- (void)loadAlternateHTML:(NSString *)newHTML;
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

- (id)init
{
	if ((self = [super init])) {
		bottom              = YES;
		maxLines            = 300;
		
		highlightedLineNumbers = [NSMutableArray new];
		
		[[WebPreferences standardPreferences] setCacheModel:WebCacheModelDocumentViewer];
		[[WebPreferences standardPreferences] setUsesPageCache:NO];
        
        NSString *uuid = [NSString stringWithUUID];
        
        messageQueue = dispatch_queue_create([uuid UTF8String], NULL);
	}
	
	return self;
}

- (void)dealloc
{
	[NSObject cancelPreviousPerformRequestsWithTarget:self];
	
	[js drain];
	[html drain];
	[menu drain];
	[sink drain];
	[view drain];
	[theme drain];
	[policy drain];
	[urlMenu drain];
	[addrMenu drain];
	[chanMenu drain];
	[memberMenu drain];
	[autoScroller drain];
	[highlightedLineNumbers drain];
    
    dispatch_release(messageQueue);
    messageQueue = NULL;
	
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
	
	view.frameLoadDelegate	  = self;
	view.UIDelegate			  = policy;
	view.policyDelegate		  = policy;
	view.resourceLoadDelegate = self;
	view.keyDelegate		  = self;
	view.resizeDelegate		  = self;
	view.autoresizingMask	  = (NSViewWidthSizable | NSViewHeightSizable);
	
	[self loadAlternateHTML:[self initialDocument:nil]];
}

- (void)loadAlternateHTML:(NSString *)newHTML
{
	[(id)view setBackgroundColor:theme.other.underlyingWindowColor];
	
	[[view mainFrame] loadHTMLString:newHTML baseURL:theme.baseUrl];
    
    [world focusInputText];
}

- (void)queueLoop
{
    if ([view isLoading]) {
        while ([view isLoading] && PointerIsEmpty([self mainFrameDocument])) {
            [NSThread sleepForTimeInterval:0.2];
            
            continue;
        }
    }
}

- (void)notifyDidBecomeVisible
{
	if (becameVisible == NO) {
		becameVisible = YES;
		
		[self moveToBottom];
	}
}

- (DOMDocument *)mainFrameDocument
{
	return [view mainFrameDocument];
}

- (DOMNode *)html_head
{
	DOMDocument *doc	= [self mainFrameDocument];
	DOMNodeList *nodes	= [doc getElementsByTagName:@"head"];
	DOMNode		*head	= [nodes item:0];
	
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
	if (PointerIsEmpty(doc)) return NSNullObject;
	
	return [(id)[self topic:doc] innerHTML];
}

- (void)setTopic:(NSString *)topic 
{
    dispatch_async(messageQueue, ^{
        [self queueLoop];
        
        dispatch_async(dispatch_get_main_queue(), ^{
          	if (NSObjectIsNotEmpty(topic)) {
                if ([[self topicValue] isEqualToString:topic] == NO) {
                    NSString *body = [LogRenderer renderBody:topic 
                                                  controller:nil
                                                  renderType:ASCII_TO_HTML 
                                                  properties:[NSDictionary dictionaryWithObjectsAndKeys:NSNumberWithBOOL(YES), @"renderLinks", nil]
                                                  resultInfo:NULL];
                    
                    DOMDocument *doc = [self mainFrameDocument];
                    if (PointerIsEmpty(doc)) return;
                    
                    DOMElement *topic_body = [self topic:doc];
                    if (PointerIsEmpty(topic_body)) return;
                    
                    [(id)topic_body setInnerHTML:body];
                }
            }
        });
    });
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
    dispatch_async(messageQueue, ^{
        [self queueLoop];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if (loaded == NO) return;
            
            [self savePosition];
            
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
        });
    });
}

- (void)unmark
{
    dispatch_async(messageQueue, ^{
        [self queueLoop];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if (loaded == NO) return;
            
            DOMDocument *doc = [self mainFrameDocument];
            if (PointerIsEmpty(doc)) return;
            
            DOMElement *e = [doc getElementById:@"mark"];
            
            if (e) {
                [[e parentNode] removeChild:e];
                
                --count;
            }
        });
    });
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
	
	[self loadAlternateHTML:[self initialDocument:[self topicValue]]];
}

- (void)clear
{
	if (loaded == NO) return;
	
	self.html = nil;
	
	loaded = NO;
	count  = 0;
	
	[self loadAlternateHTML:[self initialDocument:[self topicValue]]];
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
	
	BOOL highlighted = NO;
	
	BOOL isText	     = (type == LINE_TYPE_PRIVMSG || type == LINE_TYPE_NOTICE || type == LINE_TYPE_ACTION);
	BOOL isNormalMsg = (type == LINE_TYPE_PRIVMSG || type == LINE_TYPE_ACTION);
    BOOL drawLinks   = BOOLReverseValue([[URLParser bannedURLRegexLineTypes] containsObject:lineTypeString]);
	
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
							controller:((isNormalMsg) ? self : nil) 
							renderType:ASCII_TO_HTML 
							properties:inputDictionary 
							resultInfo:&outputDictionary];
		
		urlRanges   = [outputDictionary arrayForKey:@"URLRanges"];
		highlighted = [outputDictionary boolForKey:@"wordMatchFound"];
	} else {
		body = line.body;
	}
    
    BOOL oldRenderAbs = (theme.other.renderingEngineVersion == 0.0);
    BOOL oldRenderEst = (theme.other.renderingEngineVersion == 1.2);
    BOOL oldRenderAlt = (theme.other.renderingEngineVersion == 1.1 || oldRenderEst);
    BOOL modernRender = (theme.other.renderingEngineVersion == 2.1);
	
	NSMutableString *s = [NSMutableString string];
	
    if (oldRenderAbs || oldRenderAlt) {
        if (line.memberType == MEMBER_TYPE_MYSELF) {
            [s appendFormat:@"<p type=\"%@\">", [LogLine memberTypeString:line.memberType]];
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
        
        [s appendFormat:@"<%@ class=\"sender\" ondblclick=\"Textual.on_dblclick_nick()\" oncontextmenu=\"Textual.on_nick()\" type=\"%@\" nick=\"%@\"", htmltag, [LogLine memberTypeString:line.memberType], line.nickInfo];
		
        if (line.memberType == MEMBER_TYPE_NORMAL && [Preferences disableNicknameColors] == NO) {
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
    
	if (isNormalMsg && NSObjectIsNotEmpty(urlRanges) && [Preferences showInlineImages]) {
        if (([channel isChannel] && channel.config.inlineImages == NO) || [channel isTalk]) {
            NSString *imageUrl  = nil;
            
            NSMutableArray *postedUrls = [NSMutableArray array];
            
            for (NSValue *rangeValue in urlRanges) {
                NSString *url = [line.body safeSubstringWithRange:[rangeValue rangeValue]];
                
                imageUrl = [ImageURLParser imageURLForURL:url];
                
                if (imageUrl) {
                    if ([postedUrls containsObject:imageUrl]) {
                        continue;
                    } else {
                        [postedUrls safeAddObject:imageUrl];
                    }
                    
                    [s appendFormat:@"<a href=\"%@\" onclick=\"return Textual.hide_inline_image(this)\"><img src=\"%@\" class=\"inlineimage\" style=\"max-width: %ipx;\" /></a>", url, imageUrl, [Preferences inlineImagesMaxWidth]];
                }
            }
        }
	}
	
	NSMutableDictionary *attrs = [NSMutableDictionary dictionary];
    
    if (oldRenderAbs || oldRenderAlt) {
        [s appendString:@"</span></p>"];
        
        [attrs setObject:[LogLine lineTypeString:type] forKey:@"type"];
    } else {
        [s appendFormat:@"</div>"];
        
        NSString *typeattr = [LogLine lineTypeString:type];
        
        if (line.memberType == MEMBER_TYPE_MYSELF) {
            typeattr = [typeattr stringByAppendingFormat:@" %@", [LogLine memberTypeString:line.memberType]];
        }
        
        [attrs setObject:typeattr forKey:@"type"];
    }
    
	[attrs setObject:((highlighted) ? @"true" : @"false")		forKey:@"highlight"];
	[attrs setObject:((isText) ? @"line text" : @"line event")	forKey:@"class"];
    
    [self writeLine:s attributes:attrs];
    
	if (highlighted) {
		NSString *messageBody;
		NSString *nicknameBody = [line.nick trim];
		
		if (type == LINE_TYPE_ACTION) {
			if ([nicknameBody hasSuffix:@":"]) {
				messageBody = [NSString stringWithFormat:@"• %@ %@", nicknameBody, line.body];
			} else {
				messageBody = [NSString stringWithFormat:@"• %@: %@", nicknameBody, line.body];
			}
		} else {
			messageBody = [NSString stringWithFormat:@"%@ %@", nicknameBody, line.body];
		}
		
		[world addHighlightInChannel:channel withMessage:messageBody];
	}
	
	return highlighted;
}

- (void)writeLine:(NSString *)aHtml attributes:(NSDictionary *)attrs
{
    dispatch_async(messageQueue, ^{
        [self queueLoop];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self savePosition];
            
            ++lineNumber;
            ++count;
            
            DOMDocument *doc  = [self mainFrameDocument];
            DOMElement  *body = [self body:doc];
            DOMElement  *div  = [doc createElement:@"div"];
            
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
            
            WebScriptObject *js_api = [view js_api];
            
            if (js_api && [js_api isKindOfClass:[WebUndefined class]] == NO) {
                [js_api callWebScriptMethod:@"newMessagePostedToDisplay" 
                              withArguments:[NSArray arrayWithObjects:NSNumberWithInteger(lineNumber), nil]];  
            }
        });
    });
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
	} else {
		[bodyAttrs appendString:@" dir=\"ltr\""];
    }
	
	NSMutableString *s = [NSMutableString string];
	
	NSString *override_style = [self generateOverrideStyle];
	
	[s appendFormat:@"<html %@><head>", bodyAttrs];
	[s appendString:@"<meta http-equiv=\"Content-Type\" content=\"text/html; charset=utf-8\">"];
	
	NSTimeInterval ti = [NSDate timeIntervalSinceReferenceDate];
	
	[s appendFormat:@"<link rel=\"stylesheet\" type=\"text/css\" href=\"design.css?%d\" />", ti];
	[s appendFormat:@"<script src=\"%@\" type=\"text/javascript\"></script>", theme.core_js.filename];
	[s appendFormat:@"<script src=\"scripts.js?%d\" type=\"text/javascript\"></script>", ti];
	
	if (override_style) {
		[s appendFormat:@"<style type=\"text/css\" id=\"textual_override_style\">%@</style>", override_style];
	}
	
	[s appendFormat:@"</head><body %@>", bodyAttrs];
	
	if (NSObjectIsNotEmpty(html)) {
		[s appendFormat:@"<div id=\"body_home\">%@</div>", html];
	} else {
		[s appendString:@"<div id=\"body_home\"></div>"];
	}
	
	if (channel && (channel.isChannel || channel.isTalk)) {
		if (NSObjectIsNotEmpty(topic)) {
			[s appendFormat:@"<div id=\"topic_bar\">%@</div></body>", topic];
		} else {
			[s appendFormat:@"<div id=\"topic_bar\">%@</div></body>", TXTLS(@"NO_TOPIC_DEFAULT_TOPIC")];
		}
	}
	
	[s appendString:@"</html>"];
	
	[html drain];
	html = nil;
	
	return s;
}

- (NSString *)generateOverrideStyle
{
	NSMutableString *sf = [NSMutableString string];
	
	OtherTheme *other = world.viewTheme.other;
	
	NSFont *channelFont = other.channelViewFont;
	
	NSString *name = [channelFont fontName];
    
	NSInteger rsize = [channelFont pointSize];
	NSDoubleN dsize = ([channelFont pointSize] * (72.0 / 96.0));
	
	[sf appendString:@"html, body, body[type], body {"];
	[sf appendFormat:@"font-family:'%@';", name];
	[sf appendFormat:@"font-size:%fpt;", dsize];
	[sf appendString:@"}"];
    
    if (other.indentationOffset == THEME_DISABLED_INDENTATION_OFFSET || [Preferences rightToLeftFormatting]) {
        return sf;
    } else {
        NSFont	     *font		 = [NSFont fontWithName:name size:round(rsize)];
        NSString	 *time		 = TXFormattedTimestampWithOverride([Preferences themeTimestampFormat], other.timestampFormat);
        NSDictionary *attributes = [NSDictionary dictionaryWithObject:font forKey:NSFontAttributeName];	
        
        NSSize    textSize  = [time sizeWithAttributes:attributes]; 
        NSInteger textWidth = (textSize.width + other.indentationOffset);
        
        [sf appendString:@"body div#body_home p {"];
        [sf appendFormat:@"margin-left: %ipx;", textWidth];
        [sf appendFormat:@"text-indent: -%ipx;", textWidth];  
        [sf appendString:@"}"];
        
        [sf appendString:@"body .time {"];
        [sf appendFormat:@"width: %ipx;", textWidth];
        [sf appendString:@"}"];
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
    [scrollView setHasVerticalScroller:YES];
	
	if ([scrollView respondsToSelector:@selector(setAllowsHorizontalScrolling:)]) {
		[(id)scrollView setAllowsHorizontalScrolling:NO];
	}
	
#ifdef _RUNNING_MAC_OS_LION
	if ([Preferences applicationRanOnLion]) {
		[scrollView setHorizontalScrollElasticity:NSScrollElasticityNone];
		[scrollView setVerticalScrollElasticity:NSScrollElasticityNone];
	}
#endif
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

@end