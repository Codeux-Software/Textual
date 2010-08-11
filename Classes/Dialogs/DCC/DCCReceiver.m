// Created by Satoshi Nakagawa <psychs AT limechat DOT net> <http://github.com/psychs/limechat>
// You can redistribute it and/or modify it under the new BSD license.

#import "DCCReceiver.h"

#define DOWNLOADING_PREFIX	@"__download__"
#define RECORDS_LEN			10

@interface DCCReceiver (Private)
- (void)openFile;
- (void)closeFile;
@end

@implementation DCCReceiver

@synthesize delegate;
@synthesize uid;
@synthesize peerNick;
@synthesize host;
@synthesize port;
@synthesize size;
@synthesize processedSize;
@synthesize status;
@synthesize error;
@synthesize downloadFileName;
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
	[host release];
	[error release];
	[path release];
	[fileName release];
	[downloadFileName release];
	[icon release];
	[progressBar release];
	
	[sock close];
	[sock autorelease];
	[file release];
	[speedRecords release];
	[super dealloc];
}

- (NSString*)path
{
	return path;
}

- (void)setPath:(NSString *)value
{
	if (path != value) {
		[path release];
		path = [[value stringByExpandingTildeInPath] retain];
	}
}

- (NSString*)fileName
{
	return fileName;
}

- (void)setFileName:(NSString *)value
{
	if (fileName != value) {
		[fileName release];
		fileName = [value retain];
		
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

- (void)open
{
	if (sock) {
		[self close];
	}
	
	currentRecord = 0;
	[speedRecords removeAllObjects];

	sock = [TCPClient new];
	sock.delegate = self;
	sock.host = host;
	sock.port = port;
	[sock open];
}

- (void)close
{
	[sock close];
	[sock autorelease];
	sock = nil;
	
	[self closeFile];
	
	if (status != DCC_ERROR && status != DCC_COMPLETE) {
		status = DCC_STOP;
	}
	
	[delegate dccReceiveOnClose:self];
}

- (void)onTimer
{
	if (status != DCC_RECEIVING) return;
	
	[speedRecords addObject:[NSNumber numberWithDouble:currentRecord]];
	if (speedRecords.count > RECORDS_LEN) [speedRecords safeRemoveObjectAtIndex:0];
	currentRecord = 0;
}

- (void)openFile
{
	if (file) return;
	
	NSString* base = [fileName stringByDeletingPathExtension];
	NSString* ext = [fileName pathExtension];
	
	NSFileManager* fm = [NSFileManager defaultManager];
	NSString* fullName = [path stringByAppendingPathComponent:[NSString stringWithFormat:@"%@%@", DOWNLOADING_PREFIX, fileName]];
	
	NSInteger i = 0;
	while ([fm fileExistsAtPath:fullName]) {
		fullName = [path stringByAppendingPathComponent:[NSString stringWithFormat:@"%@%@_%d.%@", DOWNLOADING_PREFIX, base, i, ext]];
		++i;
	}
	
	NSString* dir = [fullName stringByDeletingLastPathComponent];
	[fm createDirectoryAtPath:dir withIntermediateDirectories:YES attributes:nil error:NULL];
	[fm createFileAtPath:fullName contents:[NSData data] attributes:nil];
	
	[file release];
	file = [[NSFileHandle fileHandleForUpdatingAtPath:fullName] retain];
	
	[downloadFileName release];
	downloadFileName = [fullName retain];
}

- (void)closeFile
{
	if (!file) return;
	
	[file closeFile];
	[file release];
	file = nil;
	
	if (status == DCC_COMPLETE) {
		NSString* base = [fileName stringByDeletingPathExtension];
		NSString* ext = [fileName pathExtension];
		NSString* fullName = [path stringByAppendingPathComponent:fileName];

		NSFileManager* fm = [NSFileManager defaultManager];
		
		NSInteger i = 0;
		while ([fm fileExistsAtPath:fullName]) {
			fullName = [path stringByAppendingPathComponent:[NSString stringWithFormat:@"%@_%d.%@", base, i, ext]];
			++i;
		}
		
		[fm moveItemAtPath:downloadFileName toPath:fullName error:nil];
		[downloadFileName release];
		downloadFileName = [fullName retain];
	}
}

#pragma mark -
#pragma mark TCPClient Delegate

- (void)tcpClientDidConnect:(TCPClient*)sender
{
	processedSize = 0;
	status = DCC_RECEIVING;
	
	[self openFile];
	
	[delegate dccReceiveOnOpen:self];
}

- (void)tcpClientDidDisconnect:(TCPClient*)sender
{
	if (status == DCC_COMPLETE || status == DCC_ERROR) return;
	
	status = DCC_ERROR;
	[error release];
	error = TXTLS(@"DCC_DISCONNECTED");
	[self close];
	
	[delegate dccReceiveOnError:self];
}

- (void)tcpClient:(TCPClient*)sender error:(NSString*)err
{
	if (status == DCC_COMPLETE || status == DCC_ERROR) return;
	
	status = DCC_ERROR;
	[error release];
	error = [err retain];
	[self close];
	
	[delegate dccReceiveOnError:self];
}

- (void)tcpClientDidReceiveData:(TCPClient*)sender
{
	NSData* data = [sock read];
	processedSize += data.length;
	currentRecord += data.length;

	if (data.length) {
		[file writeData:data];
	}
	
	uint32_t rsize = processedSize & 0xFFFFFFFF;
	unsigned char ack[4];
	ack[0] = (rsize >> 24) & 0xFF;
	ack[1] = (rsize >> 16) & 0xFF;
	ack[2] = (rsize >>  8) & 0xFF;
	ack[3] = rsize & 0xFF;
	[sock write:[NSData dataWithBytes:ack length:4]];
	
	progressBar.doubleValue = processedSize;
	[progressBar setNeedsDisplay:YES];
	
	if (processedSize >= size) {
		status = DCC_COMPLETE;
		[self close];
		[delegate dccReceiveOnComplete:self];
	}
}

- (void)tcpClientDidSendData:(TCPClient*)sender
{
}

@synthesize sock;
@synthesize file;
@synthesize speedRecords;
@synthesize currentRecord;
@end