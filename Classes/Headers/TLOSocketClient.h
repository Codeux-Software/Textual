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

@interface TLOSocketClient : NSObject
@property (nonatomic, unsafe_unretained) id delegate;
@property (nonatomic, strong) NSMutableData *buffer; 
@property (nonatomic, strong) id conn;
@property (nonatomic, strong) NSString *host;
@property (nonatomic, assign) NSInteger port;
@property (nonatomic, assign) BOOL useSSL;
@property (nonatomic, assign) BOOL useSystemSocks;
@property (nonatomic, assign) BOOL useSocks;
@property (nonatomic, assign) NSInteger socksVersion;
@property (nonatomic, strong) NSString *proxyHost;
@property (nonatomic, assign) NSInteger proxyPort;
@property (nonatomic, strong) NSString *proxyUser;
@property (nonatomic, strong) NSString *proxyPassword;
@property (nonatomic, assign) NSInteger sendQueueSize;
@property (nonatomic, assign) BOOL active;
@property (nonatomic, assign) BOOL connecting;
@property (nonatomic, assign) BOOL connected;
@property (nonatomic, assign) dispatch_queue_t dispatchQueue;
@property (nonatomic, assign) dispatch_queue_t socketQueue;

- (void)open;
- (void)close;

- (NSData *)readLine;
- (void)write:(NSData *)data;

- (void)openSSLCertificateTrustDialog;

/* openSSLCertificateTrustDialog: results are not guaranteed 
 when supplied with a suppression key. Pass nil to it for now. */
- (void)openSSLCertificateTrustDialog:(NSString *)suppressKey;
@end

@interface NSObject (TCPClientDelegate)
- (void)tcpClientDidConnect:(TLOSocketClient *)sender;
- (void)tcpClientDidDisconnect:(TLOSocketClient *)sender;
- (void)tcpClient:(TLOSocketClient *)sender error:(NSString *)error;
- (void)tcpClientDidReceiveData:(TLOSocketClient *)sender;
- (void)tcpClientDidSendData:(TLOSocketClient *)sender;
@end
