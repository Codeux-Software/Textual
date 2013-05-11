/* ********************************************************************* 
       _____        _               _    ___ ____   ____
      |_   _|___  _| |_ _   _  __ _| |  |_ _|  _ \ / ___|
       | |/ _ \ \/ / __| | | |/ _` | |   | || |_) | |
       | |  __/>  <| |_| |_| | (_| | |   | ||  _ <| |___
       |_|\___/_/\_\\__|\__,_|\__,_|_|  |___|_| \_\\____|

 Copyright (c) 2010 — 2013 Codeux Software & respective contributors.
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

@interface IRCConnection : NSObject
@property (nonatomic, nweak) IRCClient *client;
@property (nonatomic, strong) TLOTimer *floodTimer;
@property (nonatomic, assign) BOOL isConnected;
@property (nonatomic, assign) BOOL isConnecting;
@property (nonatomic, assign) BOOL isReadyToSend;
@property (nonatomic, assign) BOOL isSending;
@property (nonatomic, assign) BOOL connectionPrefersIPv6;
@property (nonatomic, assign) BOOL connectionUsesSSL;
@property (nonatomic, assign) BOOL connectionUsesNormalSocks;
@property (nonatomic, assign) BOOL connectionUsesSystemSocks;
@property (nonatomic, assign) BOOL connectionUsesFloodControl;
@property (nonatomic, assign) NSInteger floodControlDelayInterval;
@property (nonatomic, assign) NSInteger floodControlMaximumMessageCount;
@property (nonatomic, assign) NSInteger floodControlCurrentMessageCount;
@property (nonatomic, strong) NSString *serverAddress;
@property (nonatomic, assign) NSInteger serverPort;
@property (nonatomic, strong) NSString *proxyAddress;
@property (nonatomic, strong) NSString *proxyPassword;
@property (nonatomic, strong) NSString *proxyUsername;
@property (nonatomic, assign) NSInteger proxyPort;
@property (nonatomic, assign) NSInteger proxySocksVersion;
@property (nonatomic, strong) NSMutableArray *sendQueue;

/* IRCConnectionSocket.m properties. */

@property (nonatomic, assign) dispatch_queue_t dispatchQueue;
@property (nonatomic, assign) dispatch_queue_t socketQueue;
@property (nonatomic, strong) NSMutableData *socketBuffer;

/* Textual cannot pass proxy information to the GCD version of the
 AsyncSocket library because it does not give us access to the
 CFWrite and CFRead streams of the underlying socket. If the
 server has a proxy configured, then we have to use the old
 run loop version of AsyncSocket. That is why socketConnection
 is type "id" because depending on the settings of the owning
 client; it can be two different classes.

 IRCConnectionSocket is smart enough to automatically handle
 the connection between either class. It is not recommended
 for any extension developer to reference this property as
 talking to it directly may result in unexpected behavior. */
@property (nonatomic, strong) id socketConnection;

- (void)open;
- (void)close;

- (void)sendLine:(NSString *)line;

- (void)clearSendQueue;

- (NSString *)convertFromCommonEncoding:(NSData *)data;
- (NSData *)convertToCommonEncoding:(NSString *)data;
@end

@interface NSObject (IRCConnectionDelegate)
- (void)ircConnectionDidConnect:(IRCConnection *)sender;
- (void)ircConnectionDidDisconnect:(IRCConnection *)sender;
- (void)ircConnectionDidError:(NSString *)error;
- (void)ircConnectionDidReceive:(NSString *)data;
- (void)ircConnectionWillSend:(NSString *)line;
@end
