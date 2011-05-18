//
// AGKeychain.m
// Based on code from "Core Mac OS X and Unix Programming"
// by Mark Dalrymple and Aaron Hillegass
// http://borkware.com/corebook/source-code
//
// Created by Adam Gerson on 3/6/05.
// agerson@mac.com
//

@implementation AGKeychain

+ (BOOL)checkForExistanceOfKeychainItem:(NSString *)keychainItemName 
						   withItemKind:(NSString *)keychainItemKind 
							forUsername:(NSString *)username
							serviceName:(NSString *)service
{
	NSInteger numberOfItemsFound = 0;
	
	SecKeychainItemRef item;
	SecKeychainSearchRef search;
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
	attributes[3].length = [service length];
	
	list.count = 4;
	list.attr = attributes;
	
	result = SecKeychainSearchCreateFromAttributes(NULL, kSecGenericPasswordItemClass, &list, &search);
	
	if (result == noErr) {
		// Cool
	}
	
	while (SecKeychainSearchCopyNext(search, &item) == noErr) {
		CFRelease(item);
		
		numberOfItemsFound++;
	}
	
	CFRelease(search);
	
	return numberOfItemsFound;
}

+ (BOOL)deleteKeychainItem:(NSString *)keychainItemName 
			  withItemKind:(NSString *)keychainItemKind 
			   forUsername:(NSString *)username
			   serviceName:(NSString *)service
{
	BOOL status = NO;
	
	NSInteger numberOfItemsFound = 0;
	
	SecKeychainItemRef item;
	SecKeychainSearchRef search;
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
	attributes[3].length = [service length];
	
	list.count = 4;
	list.attr = attributes;
	
	result = SecKeychainSearchCreateFromAttributes(NULL, kSecGenericPasswordItemClass, &list, &search);
	
	if (result == noErr) {
		// Cool
	}
	
	while (SecKeychainSearchCopyNext(search, &item) == noErr) {
		numberOfItemsFound++;
	}
	
	if (numberOfItemsFound) {
		if (SecKeychainItemDelete(item)) {
			status = YES;
		}
		
		CFRelease(item);
	}
	
	CFRelease(search);
	
	return status;
}

+ (BOOL)modifyOrAddKeychainItem:(NSString *)keychainItemName 
				   withItemKind:(NSString *)keychainItemKind 
					forUsername:(NSString *)username 
				withNewPassword:(NSString *)newPassword
					withComment:(NSString *)comment
					serviceName:(NSString *)service
{
	SecKeychainItemRef item;
	SecKeychainSearchRef search;
	SecKeychainAttributeList list;
	SecKeychainAttribute attributes[5];
	
	OSErr result;
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
	
	attributes[4].tag = kSecCommentItemAttr;
	attributes[4].data = (void *)[comment UTF8String];
	attributes[4].length = [comment length];
	
	list.count = 4;
	list.attr = attributes;
	
	result = SecKeychainSearchCreateFromAttributes(NULL, kSecGenericPasswordItemClass, &list, &search);
	
	if (result == noErr) {
		// Cool
	}
	
	result = SecKeychainSearchCopyNext(search, &item);
	
	list.count = 5;
	
	if (result == errSecItemNotFound) {
		status = SecKeychainItemCreateFromContent(kSecGenericPasswordItemClass, &list, [newPassword length], 
												  [newPassword UTF8String], NULL,NULL, &item);
	} else {
		status = SecKeychainItemModifyContent(item, &list, [newPassword length], [newPassword UTF8String]);
		
		CFRelease(item);
	}
	
	CFRelease(search);
	
	return BOOLReverseValue(status);
}

+ (BOOL)addKeychainItem:(NSString *)keychainItemName 
		   withItemKind:(NSString *)keychainItemKind 
			forUsername:(NSString *)username 
		   withPassword:(NSString *)password
			serviceName:(NSString *)service
{	
	SecKeychainItemRef item;
	SecKeychainAttributeList list;
	SecKeychainAttribute attributes[4];
	
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
	
	status = SecKeychainItemCreateFromContent(kSecGenericPasswordItemClass, &list, [password length], 
											  [password UTF8String], NULL,NULL, &item);
	
	return BOOLReverseValue(status);
}

+ (NSString *)getPasswordFromKeychainItem:(NSString *)keychainItemName 
							 withItemKind:(NSString *)keychainItemKind 
							  forUsername:(NSString *)username
							  serviceName:(NSString *)service
						withLegacySupport:(BOOL)legacy
{
	SecKeychainItemRef item;
	SecKeychainSearchRef search;
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
	attributes[3].length = ((legacy) ? [keychainItemName length] : [service length]);
	
	list.count = 4;
	list.attr = attributes;
	
	result = SecKeychainSearchCreateFromAttributes(NULL, kSecGenericPasswordItemClass, &list, &search);
	
	if (result == noErr) {
		// Cool
	}
	
	NSString *password = NSNullObject;
	
	if (SecKeychainSearchCopyNext(search, &item) == noErr) {
		password = [self getPasswordFromSecKeychainItemRef:item];
		
		if (NSObjectIsEmpty(password)) {
			password = NSNullObject;
		}	
		
		CFRelease(item);
	}
	
	CFRelease(search);
	
	return password;
}

+ (NSString *)getPasswordFromSecKeychainItemRef:(SecKeychainItemRef)item
{
	UInt32 length;
	char *password;
	
	NSString *fpass = NSNullObject;
	
	OSStatus status = SecKeychainItemCopyContent(item, NULL, NULL, &length, (void **)&password);
	
	if (status == noErr) {
		if (PointerIsEmpty(password) == NO) {
			char passwordBuffer[1024];
			strncpy(passwordBuffer, password, length);
			passwordBuffer[length] = '\0';
			
			fpass = [NSString stringWithUTF8String:passwordBuffer];
		}
		
		if (password) {
			SecKeychainItemFreeContent(NULL, password);
		}
	} else {
		fpass = NSNullObject;
	}
	
	return fpass;
}

@end