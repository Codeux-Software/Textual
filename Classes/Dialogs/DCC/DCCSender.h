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

@property (assign) id delegate;
@property (assign) NSInteger uid;
@property (retain) NSString* peerNick;
@property (readonly) NSInteger port;
@property (readonly) NSString* fileName;
@property (retain, setter = setFullFileName:, getter = fullFileName) NSString* fullFileName;
@property (readonly) long long size;
@property (readonly) long long processedSize;
@property (readonly) DCCFileTransferStatus status;
@property (readonly) NSString* error;
@property (readonly) NSImage* icon;
@property (retain) NSProgressIndicator* progressBar;
@property (readonly) double speed;
@property (retain) TCPServer* sock;
@property (retain) TCPClient* client;
@property (retain) NSFileHandle* file;
@property (retain) NSMutableArray* speedRecords;
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