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

@property (nonatomic, assign) id delegate;
@property (nonatomic, assign) IRCWorld* world;
@property (nonatomic, assign) NSWindow* mainWindow;
@property (nonatomic, assign) BOOL loaded;
@property (nonatomic, retain) NSMutableArray* receivers;
@property (nonatomic, retain) NSMutableArray* senders;
@property (nonatomic, retain) Timer* timer;
@property (nonatomic, retain) ListView* receiverTable;
@property (nonatomic, retain) ListView* senderTable;
@property (nonatomic, retain) ThinSplitView* splitter;
@property (nonatomic, retain) NSButton* clearButton;

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