//
// AGKeychain.m
// Based on code from "Core Mac OS X and Unix Programming"
// by Mark Dalrymple and Aaron Hillegass
// http://borkware.com/corebook/source-code
//
// Created by Adam Gerson on 3/6/05.
// agerson@mac.com
//

#import "TextualApplication.h"

@implementation AGKeychain

+ (NSMutableDictionary *)newSearchDictionary:(NSString *)keychainItemName
								withItemKind:(NSString *)keychainItemKind
								 forUsername:(NSString *)username
								 serviceName:(NSString *)service
{
	NSMutableDictionary *searchDictionary = [NSMutableDictionary dictionary];

	searchDictionary[(id)kSecClass] = (id)kSecClassGenericPassword;

	searchDictionary[(id)kSecAttrLabel] = keychainItemName;
	searchDictionary[(id)kSecAttrDescription] = keychainItemKind;

	if ([username length] > 0) {
		searchDictionary[(id)kSecAttrAccount] = username;
	}

	searchDictionary[(id)kSecAttrService] = service;

	return searchDictionary;
}

+ (NSData *)searchKeychainMatching:(NSString *)keychainItemName
					  withItemKind:(NSString *)keychainItemKind
					   forUsername:(NSString *)username
					   serviceName:(NSString *)service
{
	NSMutableDictionary *searchDictionary = [AGKeychain newSearchDictionary:keychainItemName
															   withItemKind:keychainItemKind
																forUsername:username
																serviceName:service];

	searchDictionary[(id)kSecMatchLimit] = (id)kSecMatchLimitOne;
	searchDictionary[(id)kSecReturnData] = (id)kCFBooleanTrue;

	CFDataRef result = nil;

	OSStatus status = SecItemCopyMatching((__bridge CFDictionaryRef)searchDictionary, (CFTypeRef *)&result);

#pragma unused(status)

	return (__bridge_transfer NSData *)result;
}

#pragma mark -

+ (BOOL)deleteKeychainItem:(NSString *)keychainItemName
			  withItemKind:(NSString *)keychainItemKind
			   forUsername:(NSString *)username
			   serviceName:(NSString *)service
{
	NSMutableDictionary *dictionary = [AGKeychain newSearchDictionary:keychainItemName
														 withItemKind:keychainItemKind
														  forUsername:username
														  serviceName:service];

	OSStatus status = SecItemDelete((__bridge CFDictionaryRef)dictionary);

	return (status == errSecSuccess);
}

+ (BOOL)modifyOrAddKeychainItem:(NSString *)keychainItemName
				   withItemKind:(NSString *)keychainItemKind
					forUsername:(NSString *)username
				withNewPassword:(NSString *)newPassword
					serviceName:(NSString *)service
{
	NSMutableDictionary *oldDictionary = [AGKeychain newSearchDictionary:keychainItemName
															withItemKind:keychainItemKind
															 forUsername:username
															 serviceName:service];

	NSMutableDictionary *newDictionary = [NSMutableDictionary dictionary];

	NSData *encodedPassword = [newPassword dataUsingEncoding:NSUTF8StringEncoding];

	newDictionary[(id)kSecValueData] = encodedPassword;

	OSStatus status = SecItemUpdate((__bridge CFDictionaryRef)oldDictionary,
									(__bridge CFDictionaryRef)newDictionary);

	if (status == errSecItemNotFound) {
		return [AGKeychain addKeychainItem:keychainItemName
							  withItemKind:keychainItemKind
							   forUsername:username
							  withPassword:newPassword
							   serviceName:service];
	}

	return (status == errSecSuccess);
}

+ (BOOL)addKeychainItem:(NSString *)keychainItemName
		   withItemKind:(NSString *)keychainItemKind
			forUsername:(NSString *)username
		   withPassword:(NSString *)password
			serviceName:(NSString *)service
{
	NSMutableDictionary *dictionary = [AGKeychain newSearchDictionary:keychainItemName
														 withItemKind:keychainItemKind
														  forUsername:username
														  serviceName:service];

	NSData *encodedPassword = [password dataUsingEncoding:NSUTF8StringEncoding];

	dictionary[(id)kSecValueData] = encodedPassword;

	OSStatus status = SecItemAdd((__bridge CFDictionaryRef)dictionary, NULL);

	return (status == errSecSuccess);
}

+ (NSString *)getPasswordFromKeychainItem:(NSString *)keychainItemName
							 withItemKind:(NSString *)keychainItemKind
							  forUsername:(NSString *)username
							  serviceName:(NSString *)service
{
	NSData *passwordData = [AGKeychain searchKeychainMatching:keychainItemName
												 withItemKind:keychainItemKind
												  forUsername:username
												  serviceName:service];

	NSObjectIsEmptyAssertReturn(passwordData, nil);

	return [NSString stringWithData:passwordData encoding:NSUTF8StringEncoding];
}

@end
