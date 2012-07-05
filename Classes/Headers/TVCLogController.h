// Created by Satoshi Nakagawa <psychs AT limechat DOT net> <http://github.com/psychs/limechat>
// Modifications by Codeux Software <support AT codeux DOT com> <https://github.com/codeux/Textual>
// You can redistribute it and/or modify it under the new BSD license.

#import "TextualApplication.h"

typedef BOOL (^TVCLogMessageBlock)(void);

@interface TVCLogController : NSObject
@property (nonatomic, strong) NSString *html;
@property (nonatomic, weak) IRCWorld *world;
@property (nonatomic, weak) IRCClient *client;
@property (nonatomic, weak) IRCChannel *channel;
@property (nonatomic, strong) NSMenu *menu;
@property (nonatomic, strong) NSMenu *urlMenu;
@property (nonatomic, strong) NSMenu *chanMenu;
@property (nonatomic, strong) NSMenu *memberMenu;
@property (nonatomic, strong) TPCViewTheme *theme;
@property (nonatomic, strong) TVCLogView *view;
@property (nonatomic, strong) TVCLogPolicy *policy;
@property (nonatomic, strong) TVCLogScriptEventSink *sink;
@property (nonatomic, strong) TVCWebViewAutoScroll *autoScroller;
@property (nonatomic, strong) WebScriptObject *js;
@property (nonatomic, assign) BOOL bottom;
@property (nonatomic, assign) BOOL loaded;
@property (nonatomic, assign) BOOL queueInProgress;
@property (nonatomic, assign) BOOL viewingBottom;
@property (nonatomic, assign) BOOL scrollBottom;
@property (nonatomic, assign) BOOL becameVisible;
@property (nonatomic, assign) BOOL movingToBottom;
@property (nonatomic, assign) BOOL needsLimitNumberOfLines;
@property (nonatomic, assign) NSInteger count;
@property (nonatomic, assign) NSInteger scrollTop;
@property (nonatomic, assign) NSInteger maxLines;
@property (nonatomic, assign) NSInteger lineNumber;
@property (nonatomic, assign) NSInteger loadingImages;
@property (nonatomic, assign) NSInteger lastVisitedHighlight;
@property (nonatomic, strong) NSMutableArray *messageQueue;
@property (nonatomic, strong) NSMutableArray *highlightedLineNumbers;
@property (nonatomic, assign) dispatch_queue_t messageQueueDispatch;

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

- (BOOL)print:(TVCLogLine *)line;
- (BOOL)print:(TVCLogLine *)line withHTML:(BOOL)stripHTML;

- (NSString *)renderedBodyForTranscriptLog:(TVCLogLine *)line;

- (void)logViewOnDoubleClick:(NSString *)e;
@end