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

+ (BOOL)deleteKeychainItem:(NSString *)keychainItemName
			  withItemKind:(NSString *)keychainItemKind
			   forUsername:(NSString *)username
			   serviceName:(NSString *)service
				 fromCloud:(BOOL)deleteFromCloud; // Deletes from cloud if configured to do so in preferences.

+ (BOOL)modifyOrAddKeychainItem:(NSString *)keychainItemName 
				   withItemKind:(NSString *)keychainItemKind 
					forUsername:(NSString *)username 
				withNewPassword:(NSString *)newPassword
					serviceName:(NSString *)service;

+ (BOOL)modifyOrAddKeychainItem:(NSString *)keychainItemName
				   withItemKind:(NSString *)keychainItemKind
					forUsername:(NSString *)username
				withNewPassword:(NSString *)newPassword
					serviceName:(NSString *)service
					   forCloud:(BOOL)modifyForCloud; // Modifies for cloud if configured to do so in preferences.

+ (BOOL)addKeychainItem:(NSString *)keychainItemName 
		   withItemKind:(NSString *)keychainItemKind 
			forUsername:(NSString *)username 
		   withPassword:(NSString *)password
			serviceName:(NSString *)service; // Adds to cloud if configured to do so in preferences.

+ (BOOL)addKeychainItem:(NSString *)keychainItemName
		   withItemKind:(NSString *)keychainItemKind
			forUsername:(NSString *)username
		   withPassword:(NSString *)password
			serviceName:(NSString *)service
			  ontoCloud:(BOOL)addToCloud;

+ (NSString *)getPasswordFromKeychainItem:(NSString *)keychainItemName 
							 withItemKind:(NSString *)keychainItemKind 
							  forUsername:(NSString *)username
							  serviceName:(NSString *)service; // Finds on cloud if configured to do so in preferences.

+ (NSString *)getPasswordFromKeychainItem:(NSString *)keychainItemName
							 withItemKind:(NSString *)keychainItemKind
							  forUsername:(NSString *)username
							  serviceName:(NSString *)service
								fromCloud:(BOOL)searchForOnCloud // If NO, then only local item is returned.
					   returnedStatusCode:(OSStatus *)statusCode;

/* Migrates keychain items from login keychain to iCloud keychain and
 back depending on user preferences. Textual will call this itself when
 the user changes the preference so there is no reason for anyone other
 than Textual to call it. */
+ (void)migrateKeychainItemBasedOnCloudPreferences:(NSString *)keychainItemName
									  withItemKind:(NSString *)keychainItemKind
									   forUsername:(NSString *)username
									   serviceName:(NSString *)service;

+ (void)migrateKeychainItemToCloud:(NSString *)keychainItemName
					  withItemKind:(NSString *)keychainItemKind
					   forUsername:(NSString *)username
					   serviceName:(NSString *)service;

+ (void)migrateKeychainItemFromCloud:(NSString *)keychainItemName
						withItemKind:(NSString *)keychainItemKind
						 forUsername:(NSString *)username
						 serviceName:(NSString *)service;
@end
