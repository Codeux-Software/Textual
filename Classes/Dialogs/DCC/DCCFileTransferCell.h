// Created by Satoshi Nakagawa <psychs AT limechat DOT net> <http://github.com/psychs/limechat>
// You can redistribute it and/or modify it under the new BSD license.

#import <Foundation/Foundation.h>

typedef enum {
	DCC_INIT,
	DCC_ERROR,
	DCC_STOP,
	DCC_CONNECTING,
	DCC_LISTENING,
	DCC_RECEIVING,
	DCC_SENDING,
	DCC_COMPLETE,
} DCCFileTransferStatus;

@interface DCCFileTransferCell : NSCell
{
	NSString* peerNick;
	long long processedSize;
	long long size;
	long long speed;
	long long timeRemaining;
	DCCFileTransferStatus status;
	NSString* error;
	
	NSProgressIndicator* progressBar;
	NSImage* icon;
	BOOL sendingItem;
}

@property (nonatomic, retain) NSString* peerNick;
@property (nonatomic, assign) long long processedSize;
@property (nonatomic, assign) long long size;
@property (nonatomic, assign) long long speed;
@property (nonatomic, assign) long long timeRemaining;
@property (nonatomic, assign) DCCFileTransferStatus status;
@property (nonatomic, retain) NSString* error;
@property (nonatomic, retain) NSProgressIndicator* progressBar;
@property (nonatomic, retain) NSImage* icon;
@property (nonatomic, assign) BOOL sendingItem;
@end