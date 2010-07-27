// Created by Satoshi Nakagawa <psychs AT limechat DOT net> <http://github.com/psychs/limechat>
// You can redistribute it and/or modify it under the new BSD license.

#import "DCCSender.h"
#import "Preferences.h"

#define RECORDS_LEN			10

@interface DCCSender (Private)
- (BOOL)doOpen;
- (void)openFile;
- (void)closeFile;
- (void)send;

@end

@implementation DCCSender

@synthesize delegate;
@synthesize uid;
@synthesize peerNick;
@synthesize port;
@synthesize fileName;
@synthesize size;
@synthesize processedSize;
@synthesize status;
@synthesize error;
@synthesize icon;
@synthesize progressBar;

- (id)init
{
	if (self = [super init]) {
		speedRecords = [NSMutableArray new];
	}
	return self;
}

- (void)dealloc
{
	[peerNick release];
	[fileName release];
	[fullFileName release];
	[error release];
	[icon release];
	[progressBar release];
	[file release];
	[speedRecords release];
	[super dealloc];
}

- (NSString *)fullFileName
{
	return fullFileName;
}

- (void)setFullFileName:(NSString *)value
{
	if (fullFileName != value) {
		[fullFileName release];
		fullFileName = [value retain];
		
		NSFileManager* fm = [NSFileManager defaultManager];
		NSDictionary* attr = [fm attributesOfItemAtPath:fullFileName error:NULL];
		if (attr) {
			NSNumber* sizeNum = [attr objectForKey:NSFileSize];
			size = [sizeNum longLongValue];
		} else {
			size = 0;
		}
		
		[fileName release];
		fileName = [[fullFileName lastPathComponent] retain];
		
		[icon release];
		icon = [[[NSWorkspace sharedWorkspace] iconForFileType:[fileName pathExtension]] retain];
	}
}

- (double)speed
{
	if (!speedRecords.count) return 0;
	
	double sum = 0;
	for (NSNumber* num in speedRecords) {
		sum += [num doubleValue];
	}
	return sum / speedRecords.count;
}

- (BOOL)open
{
	port = [Preferences dccFirstPort];
	
	while (![self doOpen]) {
		++port;
		if ([Preferences dccLastPort] < port) {
			status = DCC_ERROR;
			[error release];
			error = TXTLS(@"DCC_SEND_NO_PORTS");
			
			[delegate dccSenderOnError:self];
			return NO;
		}
	}
	
	return YES;
}

- (void)close
{
	if (sock) {
		[client autorelease];
		client = nil;
		
		[sock closeAllClients];
		[sock close];
		[sock autorelease];
		sock = nil;
	}
	
	[self closeFile];
	
	if (status != DCC_ERROR && status != DCC_COMPLETE) {
		status = DCC_STOP;
	}
	
	[delegate dccSenderOnClose:self];
}

- (void)onTimer
{
	if (status != DCC_SENDING) return;
	
	[speedRecords addObject:[NSNumber numberWithDouble:currentRecord]];
	if (speedRecords.count > RECORDS_LEN) [speedRecords removeObjectAtIndex:0];
	currentRecord = 0;
	
	[self send];
}

- (void)setAddressError
{
	status = DCC_ERROR;
	[error release];
	error = TXTLS(@"DCC_SEND_UNKNOWN_IP_ADDRESS");
	[delegate dccSenderOnError:self];
}

- (BOOL)doOpen
{
	if (sock) {
		[self close];
	}
	
	status = DCC_INIT;
	processedSize = 0;
	currentRecord = 0;
	[speedRecords removeAllObjects];
	
	sock = [TCPServer new];
	sock.delegate = self;
	sock.port = port;
	BOOL res = [sock open];
	if (!res) return NO;
	
	status = DCC_LISTENING;
	[self openFile];
	if (!file) return NO;
	
	[delegate dccSenderOnListen:self];
	return YES;
}

- (void)openFile
{
	if (file) {
		[self closeFile];
	}
	
	file = [[NSFileHandle fileHandleForReadingAtPath:fullFileName] retain];
	if (!file) {
		status = DCC_ERROR;
		[error release];
		error = TXTLS(@"DCC_SEND_FILE_OPEN_FAIL");
		[self close];
		[delegate dccSenderOnError:self];
	}
}

- (void)closeFile
{
	if (!file) return;
	
	[file closeFile];
	[file release];
	file = nil;
}

#define MAX_QUEUE_SIZE	2
#define BUF_SIZE		(1024 * 64)
#define RATE_LIMIT		(1024 * 1024 * 5)

- (void)send
{
	if (status == DCC_COMPLETE) return;
	if (processedSize >= size) return;
	if (!client) return;
	
	while (1) {
		if (currentRecord >= RATE_LIMIT) return;
		if (client.sendQueueSize >= MAX_QUEUE_SIZE) return;
		if (processedSize >= size) {
			[self closeFile];
			return;
		}
		
		NSData* data = [file readDataOfLength:BUF_SIZE];
		processedSize += data.length;
		currentRecord += data.length;
		[client write:data];
		
		[progressBar setDoubleValue:processedSize];
		[progressBar setNeedsDisplay:YES];
	}
}

#pragma mark -
#pragma mark TCPServer Delegate

- (void)tcpServer:(TCPServer*)sender didAccept:(TCPClient*)aClient
{
}

- (void)tcpServer:(TCPServer*)sender didConnect:(TCPClient*)aClient
{
	if (sock) {
		[sock close];
	}
	
	[client release];
	client = [aClient retain];
	status = DCC_SENDING;
	[delegate dccSenderOnConnect:self];
	
	[self send];
}

- (void)tcpServer:(TCPServer*)sender client:(TCPClient*)aClient error:(NSString*)err
{
	if (status == DCC_COMPLETE || status == DCC_ERROR) return;
	
	status = DCC_ERROR;
	[error release];
	error = [err retain];
	[self close];
	[delegate dccSenderOnError:self];
}

- (void)tcpServer:(TCPServer*)sender didDisconnect:(TCPClient*)aClient
{
	if (processedSize >= size) {
		status = DCC_COMPLETE;
		[self close];
		return;
	}
	
	if (status == DCC_COMPLETE || status == DCC_ERROR) return;
	
	status = DCC_ERROR;
	[error release];
	error = TXTLS(@"DCC_DISCONNECTED");
	[self close];
	[delegate dccSenderOnError:self];
}

- (void)tcpServer:(TCPServer*)sender didReceiveData:(TCPClient*)aClient
{
	[aClient read];
}

- (void)tcpServer:(TCPServer*)sender didSendData:(TCPClient*)aClient
{
	if (processedSize >= size) {
		if (!client.sendQueueSize) {
			status = DCC_COMPLETE;
			[delegate dccSenderOnComplete:self];
		}
	} else {
		[self send];
	}
}

@synthesize sock;
@synthesize client;
@synthesize file;
@synthesize speedRecords;
@synthesize currentRecord;
@end