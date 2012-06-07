// Created by Satoshi Nakagawa <psychs AT limechat DOT net> <http://github.com/psychs/limechat>
// Modifications by Codeux Software <support AT codeux DOT com> <https://github.com/codeux/Textual>
// You can redistribute it and/or modify it under the new BSD license.

@class IRCWorld, IRCClient, IRCChannel;

typedef BOOL (^MessageBlock)(void);

@interface LogController : NSObject
{
	LogView *view;
	LogPolicy *policy;
	WebScriptObject *js;
	LogScriptEventSink *sink;
	WebViewAutoScroll *autoScroller;
    
	IRCWorld *__weak world;
	IRCClient *__weak client;
	IRCChannel *__weak channel;
	
	NSMenu *menu;
	NSMenu *urlMenu;
	NSMenu *addrMenu;
	NSMenu *chanMenu;
	NSMenu *memberMenu;
	
	ViewTheme *theme;
	
	BOOL bottom;
	BOOL loaded;
	BOOL scrollBottom;
	BOOL becameVisible;
	BOOL movingToBottom;
	BOOL queueInProgress;
	BOOL needsLimitNumberOfLines;
	
	NSInteger count;
	NSInteger maxLines;
	NSInteger scrollTop;
	NSInteger lineNumber;
	NSInteger loadingImages;
	NSInteger lastVisitedHighlight;
	
	NSMutableArray *messageQueue;
	NSMutableArray *highlightedLineNumbers;
	
	dispatch_queue_t messageQueueDispatch;
    
	NSString *html;
}

@property (nonatomic, assign) NSInteger lastVisitedHighlight;
@property (nonatomic, assign) BOOL queueInProgress;
@property (nonatomic, assign) dispatch_queue_t messageQueueDispatch;
@property (nonatomic, readonly) LogView *view;
@property (nonatomic, weak) IRCWorld *world;
@property (nonatomic, weak) IRCClient *client;
@property (nonatomic, weak) IRCChannel *channel;
@property (nonatomic, assign) BOOL bottom;
@property (nonatomic, assign) BOOL loaded;
@property (nonatomic, strong) NSMenu *menu;
@property (nonatomic, strong) NSMenu *urlMenu;
@property (nonatomic, strong) NSMenu *addrMenu;
@property (nonatomic, strong) NSMenu *chanMenu;
@property (nonatomic, strong) NSMenu *memberMenu;
@property (nonatomic, strong) ViewTheme *theme;
@property (nonatomic, assign, setter=setMaxLines:, getter=maxLines) NSInteger maxLines;
@property (nonatomic, readonly) BOOL viewingBottom;
@property (nonatomic, strong) LogPolicy *policy;
@property (nonatomic, strong) WebScriptObject *js;
@property (nonatomic, strong) LogScriptEventSink *sink;
@property (nonatomic, strong) WebViewAutoScroll *autoScroller;
@property (nonatomic, assign) BOOL becameVisible;
@property (nonatomic, assign) BOOL movingToBottom;
@property (nonatomic, assign) NSInteger lineNumber;
@property (nonatomic, assign) NSInteger count;
@property (nonatomic, assign) BOOL needsLimitNumberOfLines;
@property (nonatomic, assign) NSInteger loadingImages;
@property (nonatomic, strong) NSString *html;
@property (nonatomic, assign) BOOL scrollBottom;
@property (nonatomic, assign) NSInteger scrollTop;
@property (nonatomic, strong) NSMutableArray *messageQueue;
@property (nonatomic, strong) NSMutableArray *highlightedLineNumbers;

- (void)setUp;
- (void)restorePosition;
- (void)notifyDidBecomeVisible;

- (void)nextHighlight;
- (void)previousHighlight;
- (BOOL)highlightAvailable:(BOOL)previous;

- (DOMDocument *)mainFrameDocument;

- (void)moveToTop;
- (void)moveToBottom;

- (void)destroyViewLoop;
- (void)createViewLoop;

- (void)setTopic:(NSString *)topic;

- (void)mark;
- (void)unmark;
- (void)goToMark;

- (void)reloadTheme;
- (void)clear;

- (void)changeTextSize:(BOOL)bigger;

- (BOOL)print:(LogLine *)line;
- (BOOL)print:(LogLine *)line withHTML:(BOOL)stripHTML;

- (void)logViewOnDoubleClick:(NSString *)e;
@end