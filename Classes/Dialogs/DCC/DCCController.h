// Created by Satoshi Nakagawa <psychs AT limechat DOT net> <http://github.com/psychs/limechat>
// You can redistribute it and/or modify it under the new BSD license.

#import <Foundation/Foundation.h>
#import "ThinSplitView.h"
#import "ListView.h"
#import "Timer.h"

@class IRCWorld;
@class IRCClient;

@interface DCCController : NSWindowController
{
	id delegate;
	IRCWorld* world;
	NSWindow* mainWindow;
	
	BOOL loaded;
	NSMutableArray* receivers;
	NSMutableArray* senders;
	
	Timer* timer;
	
	IBOutlet ListView* receiverTable;
	IBOutlet ListView* senderTable;
	IBOutlet ThinSplitView* splitter;
	IBOutlet NSButton* clearButton;
}

@property (assign) id delegate;
@property (assign) IRCWorld* world;
@property (assign) NSWindow* mainWindow;
@property BOOL loaded;
@property (retain) NSMutableArray* receivers;
@property (retain) NSMutableArray* senders;
@property (retain) Timer* timer;
@property (retain) ListView* receiverTable;
@property (retain) ListView* senderTable;
@property (retain) ThinSplitView* splitter;
@property (retain) NSButton* clearButton;

- (void)show:(BOOL)key;
- (void)close;
- (void)terminate;
- (void)nickChanged:(NSString*)nick toNick:(NSString*)toNick client:(IRCClient*)client;

- (void)addReceiverWithUID:(NSInteger)uid nick:(NSString*)nick host:(NSString*)host port:(NSInteger)port path:(NSString*)path fileName:(NSString*)fileName size:(long long)size;
- (void)addSenderWithUID:(NSInteger)uid nick:(NSString*)nick fileName:(NSString*)fileName autoOpen:(BOOL)autoOpen;
- (NSInteger)countReceivingItems;
- (NSInteger)countSendingItems;

- (void)clear:(id)sender;

- (void)startReceiver:(id)sender;
- (void)stopReceiver:(id)sender;
- (void)deleteReceiver:(id)sender;
- (void)openReceiver:(id)sender;
- (void)revealReceivedFileInFinder:(id)sender;

- (void)startSender:(id)sender;
- (void)stopSender:(id)sender;
- (void)deleteSender:(id)sender;
@end