//
// AGKeychain.h
// Based on code from "Core Mac OS X and Unix Programming"
// by Mark Dalrymple and Aaron Hillegass
// http://borkware.com/corebook/source-code
//
// Created by Adam Gerson on 3/6/05.
// agerson@mac.com
//

#import "TextualApplication.h"

@interface AGKeychain : NSObject
+ (BOOL)deleteKeychainItem:(NSString *)keychainItemName 
			  withItemKind:(NSString *)keychainItemKind 
			   forUsername:(NSString *)username
			   serviceName:(NSString *)service;

+ (BOOL)modifyOrAddKeychainItem:(NSString *)keychainItemName 
				   withItemKind:(NSString *)keychainItemKind 
					forUsername:(NSString *)username 
				withNewPassword:(NSString *)newPassword
					serviceName:(NSString *)service;

+ (BOOL)addKeychainItem:(NSString *)keychainItemName 
		   withItemKind:(NSString *)keychainItemKind 
			forUsername:(NSString *)username 
		   withPassword:(NSString *)password
			serviceName:(NSString *)service;

+ (NSString *)getPasswordFromKeychainItem:(NSString *)keychainItemName 
							 withItemKind:(NSString *)keychainItemKind 
							  forUsername:(NSString *)username
							  serviceName:(NSString *)service;
@end
