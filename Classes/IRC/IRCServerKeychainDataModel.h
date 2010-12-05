// Created by Michael Morris <mikey AT codeux DOT com> <http://github.com/mikemac11/Textual>
// You can redistribute it and/or modify it under the new BSD license.

#import <Cocoa/Cocoa.h>
#import "AGKeychain.h"

@interface IRCServerKeychainDataModel : NSObject 

+ (NSString *)nicknamePassword:(NSString *)currentPassword 
					  withGUID:(NSString *)guid 
					   andCUID:(NSInteger)cuid;
+ (NSString*)serverPassword:(NSString *)currentPassword
				   withGUID:(NSString *)guid 
					andCUID:(NSInteger)cuid;

+ (void)setNicknamePassword:(NSString *)password 
				   withHost:(NSString *)host 
					andGUID:(NSString *)guid; 
+ (void)setServerPassword:(NSString *)password 
				 withHost:(NSString *)host
				  andGUID:(NSString *)guid;

+ (void)destroyKeychains:(NSString *)guid;

@end