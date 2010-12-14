// Created by Josh Goebel <dreamer3 AT gmail DOT com> <http://github.com/yyyc514/Textual>
// You can redistribute it and/or modify it under the new BSD license.

#import <Cocoa/Cocoa.h>


@interface AsyncSocket (AsyncSocketExtensions) 

- (void)useSSL;
- (void)useSystemSocksProxy;
- (void)useSocksProxyVersion:(NSInteger)version host:(NSString*)host port:(NSInteger)port user:(NSString*)user password:(NSString*)password;

@end
