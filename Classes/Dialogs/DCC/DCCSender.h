// Created by Satoshi Nakagawa <psychs AT limechat DOT net> <http://github.com/psychs/limechat>
// You can redistribute it and/or modify it under the new BSD license.

#import <Foundation/Foundation.h>
#import "DCCFileTransferCell.h"
#import "TCPServer.h"

@interface DCCSender : NSObject
{
	id delegate;
	NSInteger uid;
	NSString* peerNick;
	NSInteger port;
	NSString* fileName;
	NSString* fullFileName;
	long long size;
	long long processedSize;
	DCCFileTransferStatus status;
	NSString* error;
	NSImage* icon;
	NSProgressIndicator* progressBar;

	TCPServer* sock;
	TCPClient* client;
	NSFileHandle* file;
	NSMutableArray* speedRecords;
	double currentRecord;
}

@property (nonatomic, assign) id delegate;
@property (nonatomic, assign) NSInteger uid;
@property (nonatomic, retain) NSString* peerNick;
@property (nonatomic, readonly) NSInteger port;
@property (nonatomic, readonly) NSString* fileName;
@property (nonatomic, retain, setter = setFullFileName:, getter = fullFileName) NSString* fullFileName;
@property (nonatomic, readonly) long long size;
@property (nonatomic, readonly) long long processedSize;
@property (nonatomic, readonly) DCCFileTransferStatus status;
@property (nonatomic, readonly) NSString* error;
@property (nonatomic, readonly) NSImage* icon;
@property (nonatomic, retain) NSProgressIndicator* progressBar;
@property (nonatomic, readonly) double speed;
@property (nonatomic, retain) TCPServer* sock;
@property (nonatomic, retain) TCPClient* client;
@property (nonatomic, retain) NSFileHandle* file;
@property (nonatomic, retain) NSMutableArray* speedRecords;
@property double currentRecord;

- (BOOL)open;
- (void)close;
- (void)onTimer;
- (void)setAddressError;
@end

@interface NSObject (DCCSenderDelegate)
- (void)dccSenderOnListen:(DCCSender*)sender;
- (void)dccSenderOnConnect:(DCCSender*)sender;
- (void)dccSenderOnClose:(DCCSender*)sender;
- (void)dccSenderOnError:(DCCSender*)sender;
- (void)dccSenderOnComplete:(DCCSender*)sender;
@end