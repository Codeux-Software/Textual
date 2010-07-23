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

@property (assign) id delegate;
@property (assign) NSInteger uid;
@property (retain) NSString* peerNick;
@property (retain) NSString* host;
@property (assign) NSInteger port;
@property (assign) long long size;
@property (readonly) long long processedSize;
@property (readonly) DCCFileTransferStatus status;
@property (readonly) NSString* error;
@property (retain, setter = setPath:, getter = path) NSString* path;
@property (retain, setter = setFileName:, getter = fileName) NSString* fileName;
@property (readonly) NSString* downloadFileName;
@property (readonly) NSImage* icon;
@property (retain) NSProgressIndicator* progressBar;
@property (readonly) double speed;
@property (retain) TCPClient* sock;
@property (retain) NSFileHandle* file;
@property (retain) NSMutableArray* speedRecords;
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