//
// AGKeychain.m
// Based on code from "Core Mac OS X and Unix Programming"
// by Mark Dalrymple and Aaron Hillegass
// http://borkware.com/corebook/source-code
//
// Created by Adam Gerson on 3/6/05.
// agerson@mac.com
//

#import "AGKeychain.h"

#import <Security/Security.h>
#import <CoreFoundation/CoreFoundation.h>

@implementation AGKeychain

+ (BOOL)checkForExistanceOfKeychainItem:(NSString *)keychainItemName 
						   withItemKind:(NSString *)keychainItemKind 
							forUsername:(NSString *)username
							serviceName:(NSString *)service
{
	SecKeychainSearchRef search;
	SecKeychainItemRef item;
	SecKeychainAttributeList list;
	SecKeychainAttribute attributes[4];
	OSErr result;
	NSInteger numberOfItemsFound = 0;
	
	attributes[0].tag = kSecAccountItemAttr;
	attributes[0].data = (void *)[username UTF8String];
	attributes[0].length = [username length];
	
	attributes[1].tag = kSecDescriptionItemAttr;
	attributes[1].data = (void *)[keychainItemKind UTF8String];
	attributes[1].length = [keychainItemKind length];
	
	attributes[2].tag = kSecLabelItemAttr;
	attributes[2].data = (void *)[keychainItemName UTF8String];
	attributes[2].length = [keychainItemName length];
	
	attributes[3].tag = kSecServiceItemAttr;
	attributes[3].data = (void *)[service UTF8String];
	attributes[3].length = [service length];
	
	list.count = 4;
	list.attr = attributes;
	
	result = SecKeychainSearchCreateFromAttributes(NULL, kSecGenericPasswordItemClass, &list, &search);
	
	if (result == noErr) {
		// Cool
	}
	
	while (SecKeychainSearchCopyNext (search, &item) == noErr) {
		TXCFSpecialRelease (item);
		numberOfItemsFound++;
	}
	
	TXCFSpecialRelease(search);
	return numberOfItemsFound;
}

+ (BOOL)deleteKeychainItem:(NSString *)keychainItemName 
			  withItemKind:(NSString *)keychainItemKind 
			   forUsername:(NSString *)username
			   serviceName:(NSString *)service
{
	SecKeychainAttribute attributes[4];
	SecKeychainAttributeList list;
	SecKeychainItemRef item;
	SecKeychainSearchRef search;
	BOOL status = NO;
	OSErr result;
	NSInteger numberOfItemsFound = 0;
	
	attributes[0].tag = kSecAccountItemAttr;
	attributes[0].data = (void *)[username UTF8String];
	attributes[0].length = [username length];
	
	attributes[1].tag = kSecDescriptionItemAttr;
	attributes[1].data = (void *)[keychainItemKind UTF8String];
	attributes[1].length = [keychainItemKind length];
	
	attributes[2].tag = kSecLabelItemAttr;
	attributes[2].data = (void *)[keychainItemName UTF8String];
	attributes[2].length = [keychainItemName length];
	
	attributes[3].tag = kSecServiceItemAttr;
	attributes[3].data = (void *)[service UTF8String];
	attributes[3].length = [service length];
	
	list.count = 4;
	list.attr = attributes;
	
	result = SecKeychainSearchCreateFromAttributes(NULL, kSecGenericPasswordItemClass, &list, &search);
	
	if (result == noErr) {
		// Cool
	}
	
	while (SecKeychainSearchCopyNext (search, &item) == noErr) {
		numberOfItemsFound++;
	}
	
	if (numberOfItemsFound) {
		if (SecKeychainItemDelete(item)) {
			status = YES;
		}
		TXCFSpecialRelease(item);
	}
	
	TXCFSpecialRelease(search);
	
	return status;
}

+ (BOOL)modifyOrAddKeychainItem:(NSString *)keychainItemName 
				   withItemKind:(NSString *)keychainItemKind 
					forUsername:(NSString *)username 
				withNewPassword:(NSString *)newPassword
					withComment:(NSString *)comment
					serviceName:(NSString *)service
{
	SecKeychainAttribute attributes[5];
	SecKeychainAttributeList list;
	SecKeychainItemRef item;
	SecKeychainSearchRef search;
	OSStatus status;
	OSErr result;
	
	attributes[0].tag = kSecAccountItemAttr;
	attributes[0].data = (void *)[username UTF8String];
	attributes[0].length = [username length];
	
	attributes[1].tag = kSecDescriptionItemAttr;
	attributes[1].data = (void *)[keychainItemKind UTF8String];
	attributes[1].length = [keychainItemKind length];
	
	attributes[2].tag = kSecLabelItemAttr;
	attributes[2].data = (void *)[keychainItemName UTF8String];
	attributes[2].length = [keychainItemName length];
	
	attributes[3].tag = kSecServiceItemAttr;
	attributes[3].data = (void *)[service UTF8String];
	attributes[3].length = [service length];
	
	attributes[4].tag = kSecCommentItemAttr;
	attributes[4].data = (void *)[comment UTF8String];
	attributes[4].length = [comment length];
	
	list.count = 4;
	list.attr = attributes;
	
	result = SecKeychainSearchCreateFromAttributes(NULL, kSecGenericPasswordItemClass, &list, &search);
	
	if (result == noErr) {
		// Cool
	}
	
	result = SecKeychainSearchCopyNext (search, &item);
	list.count = 5;
	if (result == errSecItemNotFound) {
		status = SecKeychainItemCreateFromContent(kSecGenericPasswordItemClass, &list, [newPassword length], [newPassword UTF8String], NULL,NULL, &item);
	} else {
		status = SecKeychainItemModifyContent(item, &list, [newPassword length], [newPassword UTF8String]);
		TXCFSpecialRelease(item);
	}
	
	TXCFSpecialRelease(search);
	
	return !status;
}

+ (BOOL)addKeychainItem:(NSString *)keychainItemName 
		   withItemKind:(NSString *)keychainItemKind 
			forUsername:(NSString *)username 
		   withPassword:(NSString *)password
			serviceName:(NSString *)service
{	
	SecKeychainAttribute attributes[4];
	SecKeychainAttributeList list;
	SecKeychainItemRef item;
	OSStatus status;
	
	attributes[0].tag = kSecAccountItemAttr;
	attributes[0].data = (void *)[username UTF8String];
	attributes[0].length = [username length];
	
	attributes[1].tag = kSecDescriptionItemAttr;
	attributes[1].data = (void *)[keychainItemKind UTF8String];
	attributes[1].length = [keychainItemKind length];
	
	attributes[2].tag = kSecLabelItemAttr;
	attributes[2].data = (void *)[keychainItemName UTF8String];
	attributes[2].length = [keychainItemName length];
	
	attributes[3].tag = kSecServiceItemAttr;
	attributes[3].data = (void *)[service UTF8String];
	attributes[3].length = [service length];
	
	list.count = 4;
	list.attr = attributes;
	
	status = SecKeychainItemCreateFromContent(kSecGenericPasswordItemClass, &list, [password length], [password UTF8String], NULL,NULL, &item);
	
	return !status;
}

+ (NSString *)getPasswordFromKeychainItem:(NSString *)keychainItemName 
							 withItemKind:(NSString *)keychainItemKind 
							  forUsername:(NSString *)username
							  serviceName:(NSString *)service
						withLegacySupport:(BOOL)legacy
{
	SecKeychainSearchRef search;
	SecKeychainItemRef item;
	SecKeychainAttributeList list;
	SecKeychainAttribute attributes[4];
	OSErr result;
	
	attributes[0].tag = kSecAccountItemAttr;
	attributes[0].data = (void *)[username UTF8String];
	attributes[0].length = [username length];
	
	attributes[1].tag = kSecDescriptionItemAttr;
	attributes[1].data = (void *)[keychainItemKind UTF8String];
	attributes[1].length = [keychainItemKind length];
	
	attributes[2].tag = kSecLabelItemAttr;
	attributes[2].data = (void *)[keychainItemName UTF8String];
	attributes[2].length = [keychainItemName length];
	
	attributes[3].tag = kSecServiceItemAttr;
	attributes[3].data = (void *)[service UTF8String];
	
	// Legacy support makes it so the longstanding bug in the keychain length
	// does not break keychain movement from Textual version 1.0 to 2.0
	
	attributes[3].length = ((legacy) ? [keychainItemName length] : [service length]);
	
	list.count = 4;
	list.attr = attributes;
	
	result = SecKeychainSearchCreateFromAttributes(NULL, kSecGenericPasswordItemClass, &list, &search);
	
	if (result == noErr) {
		// Cool
	}
	
	NSString *password = @"";
	
	if (SecKeychainSearchCopyNext (search, &item) == noErr) {
		password = [self getPasswordFromSecKeychainItemRef:item];
		
		if (!password) {
			password = @"";
		}	
		
		TXCFSpecialRelease(item);
	}
	
	TXCFSpecialRelease(search);
	
	return password;
}

+ (NSString *)getPasswordFromSecKeychainItemRef:(SecKeychainItemRef)item
{
	UInt32 length;
	char *password;
	OSStatus status;
	NSString *fpass = @"";
	
	status = SecKeychainItemCopyContent(item, NULL, NULL, &length, 
										(void **)&password);
	
	if (status == noErr) {
		if (password != NULL) {
			char passwordBuffer[1024];
			
			if (length > 1023) {
				length = 1023; 
			}
			
			strncpy (passwordBuffer, password, length);
			passwordBuffer[length] = '\0';
			fpass = [NSString stringWithUTF8String:passwordBuffer];
		}
	} else {
		fpass = @"";
	}
	
	if (password) {
		SecKeychainItemFreeContent(NULL, password);
	}
	
	return fpass;
}

@end