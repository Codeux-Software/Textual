//
// AGKeychain.h
// Based on code from "Core Mac OS X and Unix Programming"
// by Mark Dalrymple and Aaron Hillegass
// http://borkware.com/corebook/source-code
//
// Created by Adam Gerson on 3/6/05.
// agerson@mac.com
//

@interface AGKeychain : NSObject

+ (NSString *)getPasswordFromSecKeychainItemRef:(SecKeychainItemRef)item;

+ (BOOL)checkForExistanceOfKeychainItem:(NSString *)keychainItemName 
						   withItemKind:(NSString *)keychainItemKind 
							forUsername:(NSString *)username
							serviceName:(NSString *)service;

+ (BOOL)deleteKeychainItem:(NSString *)keychainItemName 
			  withItemKind:(NSString *)keychainItemKind 
			   forUsername:(NSString *)username
			   serviceName:(NSString *)service;

+ (BOOL)modifyOrAddKeychainItem:(NSString *)keychainItemName 
				   withItemKind:(NSString *)keychainItemKind 
					forUsername:(NSString *)username 
				withNewPassword:(NSString *)newPassword
					withComment:(NSString *)comment
					serviceName:(NSString *)service;

+ (BOOL)addKeychainItem:(NSString *)keychainItemName 
		   withItemKind:(NSString *)keychainItemKind 
			forUsername:(NSString *)username 
		   withPassword:(NSString *)password
			serviceName:(NSString *)service;

+ (NSString *)getPasswordFromKeychainItem:(NSString *)keychainItemName 
							 withItemKind:(NSString *)keychainItemKind 
							  forUsername:(NSString *)username
							  serviceName:(NSString *)service
						withLegacySupport:(BOOL)legacy;

@end
