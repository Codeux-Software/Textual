// Created by Satoshi Nakagawa <psychs AT limechat DOT net> <http://github.com/psychs/limechat>
// Modifications by Codeux Software <support AT codeux DOT com> <https://github.com/codeux/Textual>
// You can redistribute it and/or modify it under the new BSD license.

@class IRCWorld, IRCClient, IRCChannel;

@interface LogController : NSObject
{
	LogView *view;
	LogPolicy *policy;
	WebScriptObject *js;
	MarkedScroller *scroller;
	LogScriptEventSink *sink;
	WebViewAutoScroll *autoScroller;

	IRCWorld *world;
	IRCClient *client;
	IRCChannel *channel;
	
	NSMenu *menu;
	NSMenu *urlMenu;
	NSMenu *addrMenu;
	NSMenu *chanMenu;
	NSMenu *memberMenu;
	
	ViewTheme *theme;
	
	NSColor *initialBackgroundColor;
	
	BOOL bottom;
	BOOL loaded;
	BOOL scrollBottom;
	BOOL becameVisible;
	BOOL movingToBottom;
	BOOL needsLimitNumberOfLines;
	
	NSInteger count;
	NSInteger maxLines;
	NSInteger scrollTop;
	NSInteger lineNumber;
	NSInteger loadingImages;
	
	NSMutableArray *lines;
	NSMutableArray *highlightedLineNumbers;

	NSString *html;
}

@property (retain) NSMutableArray *highlightedLineNumbers;
@property (readonly) LogView *view;
@property (assign) IRCWorld *world;
@property (assign) IRCClient *client;
@property (assign) IRCChannel *channel;
@property (retain) NSMenu *menu;
@property (retain) NSMenu *urlMenu;
@property (retain) NSMenu *addrMenu;
@property (retain) NSMenu *chanMenu;
@property (retain) NSMenu *memberMenu;
@property (retain) ViewTheme *theme;
@property (retain) NSColor *initialBackgroundColor;
@property (assign, setter=setMaxLines:, getter=maxLines) NSInteger maxLines;
@property (readonly) BOOL viewingBottom;
@property (retain) LogPolicy *policy;
@property (retain) LogScriptEventSink *sink;
@property (retain) MarkedScroller *scroller;
@property (retain) WebScriptObject *js;
@property (retain) WebViewAutoScroll *autoScroller;
@property (assign) BOOL becameVisible;
@property (assign) BOOL bottom;
@property (assign) BOOL movingToBottom;
@property (retain) NSMutableArray *lines;
@property (assign) NSInteger lineNumber;
@property (assign) NSInteger count;
@property (assign) BOOL needsLimitNumberOfLines;
@property (assign) BOOL loaded;
@property (assign) NSInteger loadingImages;
@property (retain) NSString *html;
@property (assign) BOOL scrollBottom;
@property (assign) NSInteger scrollTop;

- (BOOL)hasValidBodyStructure;

- (void)setUp;
- (void)restorePosition;
- (void)notifyDidBecomeVisible;

- (void)moveToTop;
- (void)moveToBottom;

- (void)setTopic:(NSString *)topic;

- (void)mark;
- (void)unmark;
- (void)goToMark;

- (void)reloadTheme;
- (void)applyOverrideStyle;

- (void)clear;

- (void)changeTextSize:(BOOL)bigger;

- (BOOL)print:(LogLine *)line;
- (BOOL)print:(LogLine *)line withHTML:(BOOL)stripHTML;

- (void)logViewOnDoubleClick:(NSString *)e;
@end