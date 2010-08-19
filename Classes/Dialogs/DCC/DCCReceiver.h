// Created by Satoshi Nakagawa <psychs AT limechat DOT net> <http://github.com/psychs/limechat>
// You can redistribute it and/or modify it under the new BSD license.

#import <Foundation/Foundation.h>
#import "DCCFileTransferCell.h"
#import "TCPClient.h"

@interface DCCReceiver : NSObject
{
	id delegate;
	NSInteger uid;
	NSString* peerNick;
	NSString* host;
	NSInteger port;
	long long size;
	long long processedSize;
	DCCFileTransferStatus status;
	NSString* error;
	NSString* path;
	NSString* fileName;
	NSString* downloadFileName;
	NSImage* icon;
	NSProgressIndicator* progressBar;
	
	TCPClient* sock;
	NSFileHandle* file;
	NSMutableArray* speedRecords;
	double currentRecord;
}

@property (nonatomic, assign) id delegate;
@property (nonatomic, assign) NSInteger uid;
@property (nonatomic, retain) NSString* peerNick;
@property (nonatomic, retain) NSString* host;
@property (nonatomic, assign) NSInteger port;
@property (nonatomic, assign) long long size;
@property (nonatomic, readonly) long long processedSize;
@property (nonatomic, readonly) DCCFileTransferStatus status;
@property (nonatomic, readonly) NSString* error;
@property (nonatomic, retain, setter = setPath:, getter = path) NSString* path;
@property (nonatomic, retain, setter = setFileName:, getter = fileName) NSString* fileName;
@property (nonatomic, readonly) NSString* downloadFileName;
@property (nonatomic, readonly) NSImage* icon;
@property (nonatomic, retain) NSProgressIndicator* progressBar;
@property (nonatomic, readonly) double speed;
@property (nonatomic, retain) TCPClient* sock;
@property (nonatomic, retain) NSFileHandle* file;
@property (nonatomic, retain) NSMutableArray* speedRecords;
@property double currentRecord;

- (void)open;
- (void)close;
- (void)onTimer;
@end

@interface NSObject (DCCReceiverDelegate)
- (void)dccReceiveOnOpen:(DCCReceiver*)sender;
- (void)dccReceiveOnClose:(DCCReceiver*)sender;
- (void)dccReceiveOnError:(DCCReceiver*)sender;
- (void)dccReceiveOnComplete:(DCCReceiver*)sender;
@end