// Created by Josh Goebel <dreamer3 AT gmail DOT com> <http://github.com/yyyc514/Textual>
// You can redistribute it and/or modify it under the new BSD license.
// Converted to ARC Support on June 08, 2012

#import "RLMAsyncSocket.h"

@interface GCDAsyncSocket (GCDsyncSocketExtensions)
+ (id)socketWithDelegate:(id)aDelegate delegateQueue:(dispatch_queue_t)dq socketQueue:(dispatch_queue_t)sq;

+ (void)useSSLWithConnection:(id)socket delegate:(id)theDelegate;

+ (BOOL)badSSLCertErrorFound:(NSError *)error;
+ (NSString *)posixErrorStringFromErrno:(NSInteger)code;
@end

@interface AsyncSocket (RLMAsyncSocketExtensions)
+ (id)socketWithDelegate:(id)delegate;

- (void)useSystemSocksProxy;
- (void)useSocksProxyVersion:(NSInteger)version 
						host:(NSString *)host 
						port:(NSInteger)port 
						user:(NSString *)user 
					password:(NSString *)password;
@end