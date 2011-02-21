// Created by Josh Goebel <dreamer3 AT gmail DOT com> <http://github.com/yyyc514/Textual>
// You can redistribute it and/or modify it under the new BSD license.

@class IRCClient;

@interface GCDAsyncSocket (GCDAsyncSocketExtensions)
+ (id)socketWithDelegate:(id)aDelegate delegateQueue:(dispatch_queue_t)dq socketQueue:(dispatch_queue_t)sq;

- (void)useSSL;
@end 

@interface AsyncSocket (RLMAsyncSocketExtensions)
+ (id)socketWithDelegate:(id)delegate;

- (void)useSSL;
- (void)useSystemSocksProxy;
- (void)useSocksProxyVersion:(NSInteger)version 
						host:(NSString *)host 
						port:(NSInteger)port 
						user:(NSString *)user 
					password:(NSString *)password;

+ (NSString *)posixErrorStringFromErrno:(NSInteger)code;
@end