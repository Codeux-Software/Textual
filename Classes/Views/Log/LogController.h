#import <Cocoa/Cocoa.h>
#import "LogView.h"
#import "LogPolicy.h"
#import "LogScriptEventSink.h"
#import "LogLine.h"
#import "MarkedScroller.h"
#import "ViewTheme.h"
#import "WebViewAutoScroll.h"

@class IRCWorld;
@class IRCClient;
@class IRCChannel;

@interface LogController : NSObject
{
	LogView* view;
	LogPolicy* policy;
	LogScriptEventSink* sink;
	MarkedScroller* scroller;
	WebScriptObject* js;
	WebViewAutoScroll* autoScroller;

	IRCWorld* world;
	IRCClient* client;
	IRCChannel* channel;
	NSMenu* menu;
	NSMenu* urlMenu;
	NSMenu* addrMenu;
	NSMenu* chanMenu;
	NSMenu* memberMenu;
	ViewTheme* theme;
	NSInteger maxLines;
	NSColor* initialBackgroundColor;
	NSMutableArray* highlightedLineNumbers;
	
	BOOL becameVisible;
	BOOL bottom;
	BOOL movingToBottom;
	NSMutableArray* lines;
	NSInteger lineNumber;
	NSInteger count;
	BOOL needsLimitNumberOfLines;
	BOOL loaded;
	NSInteger loadingImages;
	NSString* prevNickInfo;
	NSString* html;
	BOOL scrollBottom;
	NSInteger scrollTop;
}

@property (retain) NSMutableArray* highlightedLineNumbers;
@property (readonly) LogView* view;
@property (assign) IRCWorld* world;
@property (assign) IRCClient* client;
@property (assign) IRCChannel* channel;
@property (retain) NSMenu* menu;
@property (retain) NSMenu* urlMenu;
@property (retain) NSMenu* addrMenu;
@property (retain) NSMenu* chanMenu;
@property (retain) NSMenu* memberMenu;
@property (retain) ViewTheme* theme;
@property (retain) NSColor* initialBackgroundColor;
@property (assign, setter=setMaxLines:, getter=maxLines) NSInteger maxLines;
@property (readonly) BOOL viewingBottom;
@property (retain) LogPolicy* policy;
@property (retain) LogScriptEventSink* sink;
@property (retain) MarkedScroller* scroller;
@property (retain) WebScriptObject* js;
@property (retain) WebViewAutoScroll* autoScroller;
@property BOOL becameVisible;
@property BOOL bottom;
@property BOOL movingToBottom;
@property (retain) NSMutableArray* lines;
@property NSInteger lineNumber;
@property NSInteger count;
@property BOOL needsLimitNumberOfLines;
@property BOOL loaded;
@property NSInteger loadingImages;
@property (retain) NSString* prevNickInfo;
@property (retain) NSString* html;
@property BOOL scrollBottom;
@property NSInteger scrollTop;

- (void)setUp;
- (void)notifyDidBecomeVisible;

- (void)moveToTop;
- (void)moveToBottom;

- (void)setTopic:(NSString *)topic;

- (void)mark;
- (void)unmark;
- (void)goToMark;
- (void)reloadTheme;
- (void)clear;
- (void)changeTextSize:(BOOL)bigger;

- (BOOL)print:(LogLine*)line;

- (void)logViewOnDoubleClick:(NSString*)e;

- (void)restorePosition;
@end