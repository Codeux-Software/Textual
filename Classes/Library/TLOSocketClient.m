/* ********************************************************************* 
       _____        _               _    ___ ____   ____
      |_   _|___  _| |_ _   _  __ _| |  |_ _|  _ \ / ___|
       | |/ _ \ \/ / __| | | |/ _` | |   | || |_) | |
       | |  __/>  <| |_| |_| | (_| | |   | ||  _ <| |___
       |_|\___/_/\_\\__|\__,_|\__,_|_|  |___|_| \_\\____|

 Copyright (c) 2010 — 2012 Codeux Software & respective contributors.
        Please see Contributors.pdf and Acknowledgements.pdf

 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions
 are met:

    * Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the
      documentation and/or other materials provided with the distribution.
    * Neither the name of the Textual IRC Client & Codeux Software nor the
      names of its contributors may be used to endorse or promote products
      derived from this software without specific prior written permission.

 THIS SOFTWARE IS PROVIDED BY THE AUTHOR AND CONTRIBUTORS ``AS IS'' AND
 ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 ARE DISCLAIMED. IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE LIABLE
 FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
 OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
 LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
 OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
 SUCH DAMAGE.

 *********************************************************************** */

#import "TextualApplication.h"

#define _LF	0xa
#define _CR	0xd

@implementation TLOSocketClient

- (id)init
{
	if ((self = [super init])) {
		self.buffer = [NSMutableData new];
	}

	return self;
}

- (BOOL)useNewSocketEngine
{
	return (self.useSystemSocks == NO && self.useSocks == NO &&
			[_NSUserDefaults() boolForKey:@"DisableNewSocketEngine"] == NO);
}

- (void)destroyDispatchQueue
{
    if ([self useNewSocketEngine]) {
        if (self.dispatchQueue) {
            dispatch_release(self.dispatchQueue);
            self.dispatchQueue = NULL;
        }

        if (self.socketQueue) {
            dispatch_release(self.socketQueue);
            self.socketQueue = NULL;
        }
    }
}

- (void)createDispatchQueue
{
	if ([self useNewSocketEngine]) {
		NSString *dqname = [NSString stringWithUUID];
        NSString *sqname = [NSString stringWithUUID];

		self.socketQueue = dispatch_queue_create([sqname UTF8String], NULL);
		self.dispatchQueue = dispatch_queue_create([dqname UTF8String], NULL);
	}
}

- (void)dealloc
{
	if (self.conn) {
		[self.conn setDelegate:nil];
		[self.conn disconnect];
	}

    [self destroyDispatchQueue];

	self.delegate = nil;
}

- (void)open
{
	[self createDispatchQueue];
    [self close];

	[self.buffer setLength:0];

	NSError *connError = nil;

	if ([self useNewSocketEngine]) {
        self.conn = [GCDAsyncSocket socketWithDelegate:self
										 delegateQueue:self.dispatchQueue
										   socketQueue:self.socketQueue];

        IRCClient *clin = [self.delegate delegate];

        [self.conn setPreferIPv4OverIPv6:BOOLReverseValue(clin.config.prefersIPv6)];
	} else {
		self.conn = [AsyncSocket socketWithDelegate:self];
	}

	if ([self.conn connectToHost:self.host onPort:self.port withTimeout:(-1) error:&connError] == NO) {
		LogToConsole(@"Silently ignoring connection error: %@", [connError localizedDescription]);
	}

	self.active     = YES;
	self.connecting = YES;
	self.connected  = NO;

	self.sendQueueSize = 0;
}

- (void)close
{
	if (PointerIsEmpty(self.conn)) return;

	[self.conn setDelegate:nil];
    [self.conn disconnect];

    [self destroyDispatchQueue];

	self.active	   = NO;
	self.connecting = NO;
	self.connected  = NO;

	self.sendQueueSize = 0;
}

- (NSData *)readLine
{
	NSInteger len = [self.buffer length];
	if (len < 1) return nil;

	const char *bytes = [self.buffer bytes];
	char *p = memchr(bytes, _LF, len);

	if (p == NULL) return nil;

	NSInteger n = (p - bytes);

	if (n > 0) {
		char prev = *(p - 1);

		if (prev == _CR) {
			--n;
		}
	}

	NSMutableData *result = self.buffer;

	++p;

	if (p < (bytes + len)) {
		self.buffer = [[NSMutableData alloc] initWithBytes:p length:((bytes + len) - p)];
	} else {
		self.buffer = [NSMutableData new];
	}

	[result setLength:n];

	return result;
}

- (void)write:(NSData *)data
{
	if (self.connected == NO) return;

	++self.sendQueueSize;

	[self.conn writeData:data withTimeout:(-1)	tag:0];
	[self.conn readDataWithTimeout:(-1)			tag:0];
}

- (BOOL)onSocketWillConnect:(id)sock
{
	if (self.useSystemSocks) {
		[self.conn useSystemSocksProxy];
	} else if (self.useSocks) {
		[self.conn useSocksProxyVersion:self.socksVersion
								   host:self.proxyHost
								   port:self.proxyPort
								   user:self.proxyUser
							   password:self.proxyPassword];
	} else if (self.useSSL) {
		[GCDAsyncSocket useSSLWithConnection:self.conn delegate:self.delegate];
	}

	return YES;
}

- (void)onSocket:(id)sock didConnectToHost:(NSString *)ahost port:(UInt16)aport
{
	[self.conn readDataWithTimeout:(-1) tag:0];

	self.connecting = NO;
	self.connected  = YES;

	if ([self.delegate respondsToSelector:@selector(tcpClientDidConnect:)]) {
		[self.delegate tcpClientDidConnect:self];
	}

	IRCClient *clin = [self.delegate delegate];

	if (clin.rawModeEnabled) {
		LogToConsole(@"Debug Information:");
		LogToConsole(@"	Connected Host: %@", [sock connectedHost]);
		LogToConsole(@"	Connected Address: %@", [NSString stringWithData:[sock connectedAddress] encoding:NSUTF8StringEncoding]);
		LogToConsole(@"	Connected Port: %hu", [sock connectedPort]);
	}
}

- (void)onSocketDidDisconnect:(id)sock
{
	[self close];

	if ([self.delegate respondsToSelector:@selector(tcpClientDidDisconnect:)]) {
		[self.delegate tcpClientDidDisconnect:self];
	}
}

- (void)onSocket:(id)sender willDisconnectWithError:(NSError *)error
{
	if (PointerIsEmpty(error) || [error code] == errSSLClosedGraceful) {
		[self onSocketDidDisconnect:sender];
	} else {
		NSString *msg    = nil;
		NSString *domain = [error domain];

		if ([GCDAsyncSocket badSSLCertErrorFound:error]) {
			IRCClient *client = [self.delegate performSelector:@selector(delegate)];

			client.disconnectType = IRCBadSSLCertificateDisconnectMode;
		} else {
			if ([domain isEqualToString:NSPOSIXErrorDomain]) {
				msg = [GCDAsyncSocket posixErrorStringFromErrno:[error code]];
			}

			if (NSObjectIsEmpty(msg)) {
				msg = [error localizedDescription];
			}

			if ([self.delegate respondsToSelector:@selector(tcpClient:error:)]) {
				[self.delegate tcpClient:self error:msg];
			}
		}

		if ([self useNewSocketEngine]) {
			[self onSocketDidDisconnect:sender];
		}
	}
}

- (void)onSocket:(id)sock didReadData:(NSData *)data withTag:(long)tag
{
    if (PointerIsEmpty(self.delegate)) {
        return;
    }

	[self.buffer appendData:data];

	if ([self.delegate respondsToSelector:@selector(tcpClientDidReceiveData:)]) {
		[self.delegate tcpClientDidReceiveData:self];
	}

	[self.conn readDataWithTimeout:(-1) tag:0];
}

- (void)onSocket:(id)sock didWriteDataWithTag:(long)tag
{
	--self.sendQueueSize;

    if (PointerIsEmpty(self.delegate)) {
        return;
    }

	if ([self.delegate respondsToSelector:@selector(tcpClientDidSendData:)]) {
		[self.delegate tcpClientDidSendData:self];
	}
}

- (void)socket:(id)sock didConnectToHost:(NSString *)ahost port:(UInt16)aport
{
	[self.iomt onSocketWillConnect:sock];
	[self.iomt onSocket:sock didConnectToHost:ahost port:aport];
}

- (void)socketDidDisconnect:(id)sock withError:(NSError *)err
{
	[self.iomt onSocket:sock willDisconnectWithError:err];
}

- (void)socket:(id)sock didReadData:(NSData *)data withTag:(long)tag
{
	[self.iomt onSocket:sock didReadData:data withTag:tag];
}

- (void)socket:(id)sock didWriteDataWithTag:(long)tag
{
	[self.iomt onSocket:sock didWriteDataWithTag:tag];
}

#pragma mark -
#pragma mark SSL Certificate Trust Message

- (void)openSSLCertificateTrustDialog
{
	[self openSSLCertificateTrustDialog:nil];
}

- (void)openSSLCertificateTrustDialog:(NSString *)suppressKey;
{
	if ([self useNewSocketEngine]) {
		BOOL saveTrust = NSObjectIsNotEmpty(suppressKey);

		TXMasterController *master = [TPCPreferences masterController];

		NSString *defaultButton   = TXTLS(@"ContinueButton");
		NSString *alternateButton = TXTLS(@"CancelButton");

		if (saveTrust == NO) {
			defaultButton   = TXTLS(@"CloseButton");
			alternateButton = nil;
		}

		[self.conn requestSSLTrustFor:master.window
						modalDelegate:self
					   didEndSelector:@selector(SSLCertificateTrustDialogDidEnd:returnCode:contextInfo:)
						  contextInfo:(__bridge void *)(suppressKey)
						defaultButton:defaultButton
					  alternateButton:alternateButton];
	}
}

- (void)SSLCertificateTrustDialogDidEnd:(NSWindow *)sheet
							 returnCode:(NSInteger)returnCode
							contextInfo:(void *)contextInfo
{
	NSString *suppressKey = (__bridge NSString *)(contextInfo);

	if (NSObjectIsNotEmpty(suppressKey)) {
		if (returnCode == NSFileHandlingPanelOKButton) {
			[_NSUserDefaults() setBool:YES forKey:suppressKey];
		}
	}
}

@end