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

@property (retain) NSString* peerNick;
@property (assign) long long processedSize;
@property (assign) long long size;
@property (assign) long long speed;
@property (assign) long long timeRemaining;
@property (assign) DCCFileTransferStatus status;
@property (retain) NSString* error;
@property (retain) NSProgressIndicator* progressBar;
@property (retain) NSImage* icon;
@property (assign) BOOL sendingItem;
@end