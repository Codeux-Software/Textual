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

#pragma mark -

+ (NSMutableDictionary *)newSearchDictionary:(NSString *)keychainItemName
								withItemKind:(NSString *)keychainItemKind
								 forUsername:(NSString *)username
								 serviceName:(NSString *)service
{
	NSMutableDictionary *searchDictionary = [NSMutableDictionary dictionary];

	[searchDictionary setObject:(id)kSecClassGenericPassword forKey:(id)kSecClass];

	[searchDictionary setObject:keychainItemName	forKey:(id)kSecAttrLabel];
	[searchDictionary setObject:keychainItemKind	forKey:(id)kSecAttrDescription];

	if (NSObjectIsNotEmpty(username)) {
		[searchDictionary setObject:username			forKey:(id)kSecAttrAccount];
	}

	[searchDictionary setObject:service				forKey:(id)kSecAttrService];

	return searchDictionary;
}

+ (NSData *)searchKeychainCopyMatching:(NSString *)keychainItemName
						  withItemKind:(NSString *)keychainItemKind
						   forUsername:(NSString *)username
						   serviceName:(NSString *)service
{
	NSMutableDictionary *searchDictionary = [AGKeychain newSearchDictionary:keychainItemName
															   withItemKind:keychainItemKind
																forUsername:username
																serviceName:service];
	
	[searchDictionary setObject:(id)kSecMatchLimitOne	forKey:(id)kSecMatchLimit];
	[searchDictionary setObject:(id)kCFBooleanTrue		forKey:(id)kSecReturnData];

	CFDataRef result = nil;

	OSStatus status = SecItemCopyMatching((__bridge CFDictionaryRef)searchDictionary,
										  (CFTypeRef *)&result);

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

	// ---- //
	
	OSStatus status = SecItemDelete((__bridge CFDictionaryRef)dictionary);
	
	if (status == errSecSuccess) {
		return YES;
	}

	return NO;
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

	// ---- //

	NSData *encodedPassword = [newPassword dataUsingEncoding:NSUTF8StringEncoding];
	
	[newDictionary setObject:encodedPassword forKey:(id)kSecValueData];

	// ---- //

	OSStatus status = SecItemUpdate((__bridge CFDictionaryRef)oldDictionary,
									(__bridge CFDictionaryRef)newDictionary);

	if (status == errSecItemNotFound) {
		return [AGKeychain addKeychainItem:keychainItemName
							  withItemKind:keychainItemKind
							   forUsername:username
							  withPassword:newPassword
							   serviceName:service];
	}
	
	if (status == errSecSuccess) {
		return YES;
	}
	
	return NO;
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

	// ---- //
	
	[dictionary setObject:encodedPassword forKey:(id)kSecValueData];

	// ---- //

	OSStatus status = SecItemAdd((__bridge CFDictionaryRef)dictionary, NULL);
	
	if (status == errSecSuccess) {
		return YES;
	}
	
	return NO;
}

+ (NSString *)getPasswordFromKeychainItem:(NSString *)keychainItemName
							 withItemKind:(NSString *)keychainItemKind 
							  forUsername:(NSString *)username
							  serviceName:(NSString *)service
{
	NSData *passwordData = [AGKeychain searchKeychainCopyMatching:keychainItemName
													 withItemKind:keychainItemKind
													  forUsername:username
													  serviceName:service];
	
	if (PointerIsNotEmpty(passwordData)) {
		return [NSString stringWithData:passwordData encoding:NSUTF8StringEncoding];
	}

	return NSStringEmptyPlaceholder;
}

@end