/* ********************************************************************* 
                  _____         _               _
                 |_   _|____  _| |_ _   _  __ _| |
                   | |/ _ \ \/ / __| | | |/ _` | |
                   | |  __/>  <| |_| |_| | (_| | |
                   |_|\___/_/\_\\__|\__,_|\__,_|_|

 Copyright (c) 2010 - 2017 Codeux Software, LLC & respective contributors.
        Please see Acknowledgements.pdf for additional information.

 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions
 are met:

    * Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the
      documentation and/or other materials provided with the distribution.
    * Neither the name of Textual and/or "Codeux Software, LLC", nor the 
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

/* *** XPC PROTOCOL HEADERS ARE PRIVATE *** */

#import "GCDAsyncSocketTrustPanel.h"

NS_ASSUME_NONNULL_BEGIN

@class IRCConnectionConfig;

typedef void (^RCMSecureConnectionInformationCompletionBlock)(
											  NSString * _Nullable policyName,
											  SSLProtocol protocolVersion,
											  SSLCipherSuite cipherSuites,
											  NSArray<NSData *> *certificateChain);

#pragma mark -
#pragma mark Server Protocol

/* The server protocol is what the daemon responds to. */
@protocol RCMConnectionManagerServerProtocol
@required

- (void)openWithConfig:(IRCConnectionConfig *)config;
- (void)close;

/* -sendData: does not append \r\n. It is assumed client does that. */
- (void)sendData:(NSData *)data;
- (void)sendData:(NSData *)data bypassQueue:(BOOL)bypassQueue;

- (void)exportSecureConnectionInformation:(NS_NOESCAPE RCMSecureConnectionInformationCompletionBlock)completionBlock;

- (void)enforceFloodControl;

- (void)clearSendQueue;

#pragma mark -
#pragma mark Resource Usage

- (void)enableAppNap;
- (void)disableAppNap;

- (void)enableSuddenTermination;
- (void)disableSuddenTermination;
@end

#pragma mark -
#pragma mark Client Protocol

/* The client protocol is what Textual (the client) implements
 so that the daemon can communicate state with it. */
@protocol RCMConnectionManagerClientProtocol
@required

- (void)ircConnectionWillConnectToProxy:(NSString *)proxyHost port:(uint16_t)proxyPort;

/* host is nil if we are connected to a proxy because we do not have enough context
 at the point this delegate method is called to know where the proxy itself connected. */
- (void)ircConnectionDidConnectToHost:(nullable NSString *)host;
- (void)ircConnectionDidSecureConnectionWithProtocolVersion:(SSLProtocol)protocolVersion
												cipherSuite:(SSLCipherSuite)cipherSuite;
- (void)ircConnectionDidCloseReadStream;
- (void)ircConnectionDidError:(NSString *)error;
- (void)ircConnectionDidDisconnectWithError:(nullable NSError *)disconnectError;
- (void)ircConnectionDidReceiveData:(NSData *)data;
- (void)ircConnectionRequestInsecureCertificateTrust:(GCDAsyncSocketTrustResponseCompletionBlock)trustBlock;
- (void)ircConnectionWillSendData:(NSData *)data;
- (void)ircConnectionDidSendData;
@end

NS_ASSUME_NONNULL_END
