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

+ (BOOL)canWriteToCloud
{
	if (&kSecAttrSynchronizable) {
		return YES;
	} else {
		return NO;
	}
}

+ (BOOL)synchronizePasswords
{
	if (&kSecAttrSynchronizable) {
#ifdef TEXTUAL_BUILT_WITH_ICLOUD_SUPPORT
		return NO;
#else
		return NO;
#endif
	} else {
		return NO;
	}
}

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

#pragma mark -

+ (BOOL)deleteKeychainItem:(NSString *)keychainItemName
			  withItemKind:(NSString *)keychainItemKind
			   forUsername:(NSString *)username
			   serviceName:(NSString *)service
{
	return [self deleteKeychainItem:keychainItemName
					   withItemKind:keychainItemKind
						forUsername:username
						serviceName:service
						  fromCloud:[self synchronizePasswords]];
}

+ (BOOL)deleteKeychainItem:(NSString *)keychainItemName
			  withItemKind:(NSString *)keychainItemKind
			   forUsername:(NSString *)username
			   serviceName:(NSString *)service
				 fromCloud:(BOOL)deleteFromCloud
{
	NSMutableDictionary *dictionary = [AGKeychain newSearchDictionary:keychainItemName
														 withItemKind:keychainItemKind
														  forUsername:username
														  serviceName:service];
	
	if (deleteFromCloud) {
		dictionary[(id)kSecAttrSynchronizable] = (id)kCFBooleanTrue;
	}
	
	OSStatus status = SecItemDelete((__bridge CFDictionaryRef)dictionary);

	return (status == errSecSuccess);
}

+ (void)migrateKeychainItemBasedOnCloudPreferences:(NSString *)keychainItemName
									  withItemKind:(NSString *)keychainItemKind
									   forUsername:(NSString *)username
									   serviceName:(NSString *)service
{
	[self migrateKeychainItemBasedOnCloudPreferences:keychainItemName
										withItemKind:keychainItemKind
										 forUsername:username
										 serviceName:service
									  migrateToCloud:[self synchronizePasswords]];
}

+ (void)migrateKeychainItemToCloud:(NSString *)keychainItemName
					  withItemKind:(NSString *)keychainItemKind
					   forUsername:(NSString *)username
					   serviceName:(NSString *)service
{
	[self migrateKeychainItemBasedOnCloudPreferences:keychainItemName
										withItemKind:keychainItemKind
										 forUsername:username
										 serviceName:service
									  migrateToCloud:YES];
}

+ (void)migrateKeychainItemFromCloud:(NSString *)keychainItemName
						withItemKind:(NSString *)keychainItemKind
						 forUsername:(NSString *)username
						 serviceName:(NSString *)service
{
	[self migrateKeychainItemBasedOnCloudPreferences:keychainItemName
										withItemKind:keychainItemKind
										 forUsername:username
										 serviceName:service
									  migrateToCloud:NO];
}

+ (void)migrateKeychainItemBasedOnCloudPreferences:(NSString *)keychainItemName
									  withItemKind:(NSString *)keychainItemKind
									   forUsername:(NSString *)username
									   serviceName:(NSString *)service
									migrateToCloud:(BOOL)migrateToCloud
{
	/* Do not do anything if OS does not support it. */
	if ([self canWriteToCloud] == NO) {
		return; // Cancel operation.
	}
	
	/* First we find any keychain item on the cloud. */
	OSStatus localPasswordReturnCode = noErr;
	
	NSString *localPassword = [AGKeychain getPasswordFromKeychainItem:keychainItemName
														 withItemKind:keychainItemKind
														  forUsername:username
														  serviceName:service
															fromCloud:NO
												   returnedStatusCode:&localPasswordReturnCode];
	
	/* Now we get the iCloud value if there is any. */
	OSStatus remotePasswordReturnCode = noErr;
	
	NSString *remotePassword = [AGKeychain getPasswordFromKeychainItem:keychainItemName
														  withItemKind:keychainItemKind
														   forUsername:username
														   serviceName:service
															 fromCloud:YES
													returnedStatusCode:&remotePasswordReturnCode];
	
	/* Now that we have the values, we modify them based on preferences. */
	NSString *newPassword = nil;
	
	if (migrateToCloud) {
		if (localPasswordReturnCode == noErr) {
			newPassword = localPassword;
			
			[self deleteKeychainItem:keychainItemName
						withItemKind:keychainItemKind
						 forUsername:username
						 serviceName:service
						   fromCloud:NO];
		}
	} else {
		if (remotePasswordReturnCode == noErr) {
			newPassword = remotePassword;
			
			[self deleteKeychainItem:keychainItemName
						withItemKind:keychainItemKind
						 forUsername:username
						 serviceName:service
						   fromCloud:YES];
		}
	}
	
	/* Populate or modify new item. */
	if (newPassword) {
		[self modifyOrAddKeychainItem:keychainItemName
						 withItemKind:keychainItemKind
						  forUsername:username
					  withNewPassword:newPassword
						  serviceName:service
							 forCloud:migrateToCloud];
	}
	
	/* Destroy these right away. */
	newPassword = nil;
	localPassword = nil;
	remotePassword = nil;
}

+ (BOOL)modifyOrAddKeychainItem:(NSString *)keychainItemName
				   withItemKind:(NSString *)keychainItemKind
					forUsername:(NSString *)username
				withNewPassword:(NSString *)newPassword
					serviceName:(NSString *)service
{
	return [self modifyOrAddKeychainItem:keychainItemName
							withItemKind:keychainItemKind
							 forUsername:username
						 withNewPassword:newPassword
							 serviceName:service
								forCloud:[self synchronizePasswords]];
}

+ (BOOL)modifyOrAddKeychainItem:(NSString *)keychainItemName
				   withItemKind:(NSString *)keychainItemKind
					forUsername:(NSString *)username
				withNewPassword:(NSString *)newPassword
					serviceName:(NSString *)service
					   forCloud:(BOOL)modifyForCloud
{
	NSMutableDictionary *oldDictionary = [AGKeychain newSearchDictionary:keychainItemName
															withItemKind:keychainItemKind
															 forUsername:username
															 serviceName:service];
	
	if (modifyForCloud) {
		oldDictionary[(id)kSecAttrSynchronizable] = (id)kCFBooleanTrue;
	}
	
	NSMutableDictionary *newDictionary = [NSMutableDictionary dictionary];

	if (newPassword) {
		NSData *encodedPassword = [newPassword dataUsingEncoding:NSUTF8StringEncoding];

		newDictionary[(id)kSecValueData] = encodedPassword;
	}
	
	if (modifyForCloud) {
		newDictionary[(id)kSecAttrSynchronizable] = (id)kCFBooleanTrue;
	}

	OSStatus status = SecItemUpdate((__bridge CFDictionaryRef)oldDictionary,
									(__bridge CFDictionaryRef)newDictionary);

	if (status == errSecItemNotFound) {
		if ([newPassword length] > 0) {
			return [AGKeychain addKeychainItem:keychainItemName
								  withItemKind:keychainItemKind
								   forUsername:username
								  withPassword:newPassword
								   serviceName:service];
		}
	}

	return (status == errSecSuccess);
}

+ (BOOL)addKeychainItem:(NSString *)keychainItemName
		   withItemKind:(NSString *)keychainItemKind
			forUsername:(NSString *)username
		   withPassword:(NSString *)password
			serviceName:(NSString *)service
{
	return [self addKeychainItem:keychainItemName
					withItemKind:keychainItemKind
					 forUsername:username
					withPassword:password
					 serviceName:service
					   ontoCloud:[self synchronizePasswords]];
}

+ (BOOL)addKeychainItem:(NSString *)keychainItemName
		   withItemKind:(NSString *)keychainItemKind
			forUsername:(NSString *)username
		   withPassword:(NSString *)password
			serviceName:(NSString *)service
			  ontoCloud:(BOOL)addToCloud
{
	NSMutableDictionary *dictionary = [AGKeychain newSearchDictionary:keychainItemName
														 withItemKind:keychainItemKind
														  forUsername:username
														  serviceName:service];
	
	if (addToCloud) {
		dictionary[(id)kSecAttrSynchronizable] = (id)kCFBooleanTrue;
	}
	
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
	return [AGKeychain getPasswordFromKeychainItem:keychainItemName
									  withItemKind:keychainItemKind
									   forUsername:username
									   serviceName:service
										 fromCloud:[self synchronizePasswords]
								returnedStatusCode:NULL];
}

+ (NSString *)getPasswordFromKeychainItem:(NSString *)keychainItemName
							 withItemKind:(NSString *)keychainItemKind
							  forUsername:(NSString *)username
							  serviceName:(NSString *)service
								fromCloud:(BOOL)searchForOnCloud
					   returnedStatusCode:(OSStatus *)statusCode
{
	NSMutableDictionary *searchDictionary = [AGKeychain newSearchDictionary:keychainItemName
															   withItemKind:keychainItemKind
																forUsername:username
																serviceName:service];
	
	searchDictionary[(id)kSecMatchLimit] = (id)kSecMatchLimitOne;
	searchDictionary[(id)kSecReturnData] = (id)kCFBooleanTrue;
	
	if (searchForOnCloud) {
		searchDictionary[(id)kSecAttrSynchronizable] = (id)kCFBooleanTrue;
	}
	
	CFDataRef result = nil;
	
	OSStatus status = SecItemCopyMatching((__bridge CFDictionaryRef)searchDictionary, (CFTypeRef *)&result);
	
	if ( statusCode) {
		*statusCode = status;
	}
	
	NSData *passwordData = (__bridge_transfer NSData *)result;
	
	NSObjectIsEmptyAssertReturn(passwordData, nil);
	
	return [NSString stringWithData:passwordData encoding:NSUTF8StringEncoding];
}

@end
