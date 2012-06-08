// Created by Satoshi Nakagawa <psychs AT limechat DOT net> <http://github.com/psychs/limechat>
// Modifications by Codeux Software <support AT codeux DOT com> <https://github.com/codeux/Textual>
// You can redistribute it and/or modify it under the new BSD license.
// Converted to ARC Support on Thursday, June 07, 2012

@class IRCWorld, IRCClient, IRCChannel;

typedef BOOL (^MessageBlock)(void);

@interface LogController : NSObject
@property (assign) NSInteger lastVisitedHighlight;
@property (assign) BOOL queueInProgress;
@property (assign) dispatch_queue_t messageQueueDispatch;
@property (strong) LogView *view;
@property (weak) IRCWorld *world;
@property (weak) IRCClient *client;
@property (weak) IRCChannel *channel;
@property (assign) BOOL bottom;
@property (assign) BOOL loaded;
@property (strong) NSMenu *menu;
@property (strong) NSMenu *urlMenu;
@property (strong) NSMenu *addrMenu;
@property (strong) NSMenu *chanMenu;
@property (strong) NSMenu *memberMenu;
@property (strong) ViewTheme *theme;
@property (nonatomic, assign) NSInteger maxLines;
@property (nonatomic, assign) BOOL viewingBottom;
@property (strong) LogPolicy *policy;
@property (strong) WebScriptObject *js;
@property (strong) LogScriptEventSink *sink;
@property (strong) WebViewAutoScroll *autoScroller;
@property (assign) BOOL becameVisible;
@property (assign) BOOL movingToBottom;
@property (assign) NSInteger lineNumber;
@property (assign) NSInteger count;
@property (assign) BOOL needsLimitNumberOfLines;
@property (assign) NSInteger loadingImages;
@property (strong) NSString *html;
@property (assign) BOOL scrollBottom;
@property (assign) NSInteger scrollTop;
@property (strong) NSMutableArray *messageQueue;
@property (strong) NSMutableArray *highlightedLineNumbers;

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