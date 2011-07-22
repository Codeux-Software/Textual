// Copyright 2010 Matthew Stevens, Ruotger Skupin, Apple, Dave Carlton, Fraser Hess, anlumo. All rights reserved.
// <https://github.com/roddi/ValidateStoreReceipt>

#import "ValidateReceipt.h"

#import <IOKit/IOKitLib.h>

#import <Security/SecStaticCode.h>
#import <Security/SecRequirement.h>

#include <openssl/pkcs7.h>
#include <openssl/objects.h>
#include <openssl/sha.h>
#include <openssl/x509.h>
#include <openssl/err.h>

NSString *kReceiptBundleIdentifer = @"BundleIdentifier";
NSString *kReceiptBundleIdentiferData = @"BundleIdentifierData";
NSString *kReceiptVersion = @"Version";
NSString *kReceiptOpaqueValue = @"OpaqueValue";
NSString *kReceiptHash = @"Hash";

#define BASE_BUNDLE_ID @"com.codeux.irc.textual"

NSData *appleRootCert(void);
CFDataRef copy_mac_address(void);
NSDictionary *dictionaryWithAppStoreReceipt(NSString *path);

NSData *appleRootCert()         
{
	OSStatus status;
	SecKeychainRef keychain = nil;
	
	status = SecKeychainOpen("/System/Library/Keychains/SystemRootCertificates.keychain", &keychain);
	
	if (status) {
		if (keychain) CFRelease(keychain);
		
		return nil;
	}
	
	CFArrayRef searchList = CFArrayCreate(kCFAllocatorDefault, (const void**)&keychain, 1, &kCFTypeArrayCallBacks);

	if (keychain) CFRelease(keychain);
	
	SecKeychainSearchRef searchRef = nil;
	status = SecKeychainSearchCreateFromAttributes(searchList, kSecCertificateItemClass, NULL, &searchRef);
	
	if (status) {
		if (searchRef) CFRelease(searchRef);
		if (searchList) CFRelease(searchList);
		
		return nil;
	}
	
	SecKeychainItemRef itemRef = nil;
	NSData *resultData = nil;
	
	while (SecKeychainSearchCopyNext(searchRef, &itemRef) == noErr && PointerIsEmpty(resultData)) {
		SecKeychainAttributeList list;
		SecKeychainAttribute attributes[1];
		
		attributes[0].tag = kSecLabelItemAttr;
		
		list.count = 1;
		list.attr = attributes;
		
		SecKeychainItemCopyContent(itemRef, nil, &list, nil, nil);
		
		NSData   *nameData = [NSData dataWithBytesNoCopy:attributes[0].data length:attributes[0].length freeWhenDone:NO];
		NSString *name     = [NSString stringWithData:nameData encoding:NSUTF8StringEncoding];
		
		if ([name isEqualToString:@"Apple Root CA"]) {
			CSSM_DATA certData;
			
			status = SecCertificateGetData((SecCertificateRef)itemRef, &certData);
			
			if (status) {
				if (itemRef) CFRelease(itemRef);
			}
						
			resultData = [NSData dataWithBytes:certData.Data length:certData.Length];
			
			SecKeychainItemFreeContent(&list, NULL);
			
			if (itemRef) CFRelease(itemRef);
		}
		
        [name drain];
	}
	
	CFRelease(searchList);
	CFRelease(searchRef);
	
	return resultData;
}

NSDictionary *dictionaryWithAppStoreReceipt(NSString *path)
{
	NSData *rootCertData = appleRootCert();
	
    enum ATTRIBUTES 
	{
        ATTR_START = 1,
        BUNDLE_ID,
        VERSION,
        OPAQUE_VALUE,
        HASH,
        ATTR_END
    };
    
	ERR_load_PKCS7_strings();
	ERR_load_X509_strings();
	OpenSSL_add_all_digests();
	
	const char *receiptPath = [[path stringByStandardizingPath] fileSystemRepresentation];
    FILE *fp = fopen(receiptPath, "rb");
	
    if (fp == NULL) return nil;
    
    PKCS7 *p7 = d2i_PKCS7_fp(fp, NULL);
    fclose(fp);
	
	if (p7 == NULL) return nil;
    
    if (!PKCS7_type_is_signed(p7)) {
        PKCS7_free(p7);
        return nil;
    }
    
    if (!PKCS7_type_is_data(p7->d.sign->contents)) {
        PKCS7_free(p7);
        return nil;
    }
    
	int verifyReturnValue = 0;
	X509_STORE *store = X509_STORE_new();
	
	if (store) {
		unsigned char const *data = (unsigned char const *)rootCertData.bytes;
		X509 *appleCA = d2i_X509(NULL, &data, rootCertData.length);
		
		if (appleCA) {
			BIO *payload = BIO_new(BIO_s_mem());
			X509_STORE_add_cert(store, appleCA);

			if (payload) {
				verifyReturnValue = PKCS7_verify(p7,NULL,store,NULL,payload,0);
				BIO_free(payload);
			}

			X509_free(appleCA);
		}
		
		X509_STORE_free(store);
	}
	
	EVP_cleanup();
	
	if (verifyReturnValue != 1) {
        PKCS7_free(p7);
		return nil;	
	}
	
    ASN1_OCTET_STRING *octets = p7->d.sign->contents->d.data;  
	
    unsigned char const *p = octets->data;
    unsigned char const *end = p + octets->length;
    
    long length = 0;
    int type = 0;
    int xclass = 0;
    
    ASN1_get_object(&p, &length, &type, &xclass, end - p);
	
    if (type != V_ASN1_SET) {
        PKCS7_free(p7);
        return nil;
    }
    
    NSMutableDictionary *info = [NSMutableDictionary dictionary];
    
    while (p < end) {
        ASN1_get_object(&p, &length, &type, &xclass, end - p);
		
        if (type != V_ASN1_SEQUENCE) break;
        
        const unsigned char *seq_end = p + length;
        
        int attr_type = 0;
        int attr_version = 0;
        
        ASN1_get_object(&p, &length, &type, &xclass, seq_end - p);
		
        if (type == V_ASN1_INTEGER && length == 1) {
            attr_type = p[0];
        }
		
        p += length;
        
        ASN1_get_object(&p, &length, &type, &xclass, seq_end - p);
		
        if (type == V_ASN1_INTEGER && length == 1) {
            attr_version = p[0];
			attr_version = attr_version;
        }
		
        p += length;
        
        if (attr_type > ATTR_START && attr_type < ATTR_END) {
            NSString *key;
            
            ASN1_get_object(&p, &length, &type, &xclass, seq_end - p);\
			
            if (type == V_ASN1_OCTET_STRING) {
                if (attr_type == BUNDLE_ID || attr_type == OPAQUE_VALUE || attr_type == HASH) {
                    NSData *data = [NSData dataWithBytes:p length:length];
                    
                    switch (attr_type) {
                        case BUNDLE_ID:
                            key = kReceiptBundleIdentiferData;
                            break;
                        case OPAQUE_VALUE:
                            key = kReceiptOpaqueValue;
                            break;
                        case HASH:
                            key = kReceiptHash;
                            break;
                    }
                    
                    [info setObject:data forKey:key];
                }
                
                if (attr_type == BUNDLE_ID || attr_type == VERSION) {
                    int str_type = 0;
                    long str_length = 0;
                    unsigned char const *str_p = p;
					
                    ASN1_get_object(&str_p, &str_length, &str_type, &xclass, seq_end - str_p);
					
                    if (str_type == V_ASN1_UTF8STRING) {
                        NSString *string = [NSString stringWithBytes:str_p length:str_length encoding:NSUTF8StringEncoding];
						
                        switch (attr_type) {
                            case BUNDLE_ID:
                                key = kReceiptBundleIdentifer;
                                break;
                            case VERSION:
                                key = kReceiptVersion;
                                break;
                        }
                        
                        [info setObject:string forKey:key];
                    }
                }
            }
			
            p += length;
        }
        
        while (p < seq_end) {
            ASN1_get_object(&p, &length, &type, &xclass, seq_end - p);
			
            p += length;
        }
    }
    
    PKCS7_free(p7);
    
    return info;
}

CFDataRef copy_mac_address(void)
{
    kern_return_t kernResult;
    mach_port_t master_port;
    CFMutableDictionaryRef matchingDict;
    io_iterator_t iterator;
    io_object_t service;
    CFDataRef macAddress = nil;
	
    kernResult = IOMasterPort(MACH_PORT_NULL, &master_port);
	
    if (kernResult != KERN_SUCCESS) {
        printf("IOMasterPort returned %d\n", kernResult);
        return nil;
    }
	
    matchingDict = IOBSDNameMatching(master_port, 0, "en0");
	
    if (!matchingDict) {
        printf("IOBSDNameMatching returned empty dictionary\n");
        return nil;
    }
	
    kernResult = IOServiceGetMatchingServices(master_port, matchingDict, &iterator);
	
    if (kernResult != KERN_SUCCESS) {
        printf("IOServiceGetMatchingServices returned %d\n", kernResult);
        return nil;
    }
	
    while ((service = IOIteratorNext(iterator)) != 0) {
        io_object_t parentService;
		
        kernResult = IORegistryEntryGetParentEntry(service, kIOServicePlane, &parentService);
		
        if (kernResult == KERN_SUCCESS)  {
            if (macAddress) CFRelease(macAddress);
			
            macAddress = IORegistryEntryCreateCFProperty(parentService, CFSTR("IOMACAddress"), kCFAllocatorDefault, 0);
			
            IOObjectRelease(parentService);
        } else {
            printf("IORegistryEntryGetParentEntry returned %d\n", kernResult);
        }
		
        IOObjectRelease(service);
    }
	
    return macAddress;
}

BOOL validateBinarySignature(NSString *authority)
{
	OSStatus status = noErr;
	
	SecStaticCodeRef staticCode = NULL;
	SecRequirementRef req = NULL;
	
	NSString *requirementString = [NSString stringWithFormat:@"anchor trusted and certificate leaf [subject.CN] = \"%@\"", authority];
	
	status = SecStaticCodeCreateWithPath((CFURLRef)[[NSBundle mainBundle] bundleURL], kSecCSDefaultFlags, &staticCode);
	DevNullDestroyObject(YES, status);
	
	status = SecRequirementCreateWithString((CFStringRef)requirementString, kSecCSDefaultFlags, &req);
	DevNullDestroyObject(YES, status);
	
	status = SecStaticCodeCheckValidity(staticCode, kSecCSDefaultFlags, req);
	
	if (status == noErr) {
		return YES;
	}
	
	return NO;
}

BOOL validateReceiptAtPath(NSString *path)
{
	// This validation process is actually very pointless considering
	// Textual is open source, but some security is better than none.
	
	NSDictionary *receipt = dictionaryWithAppStoreReceipt(path);
	
	if (PointerIsEmpty(receipt)) return NO;
	
	NSData *guidData = nil;
	NSString *bundleVersion = nil;
	NSString *bundleIdentifer = nil;
	
	guidData = (id)copy_mac_address();
	[guidData autodrain];

	if (PointerIsEmpty(guidData)) return NO;
	
	bundleVersion = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
	bundleIdentifer = [[NSBundle mainBundle] bundleIdentifier];
	
	NSMutableData *input = [NSMutableData data];
	
	[input appendData:guidData];
	[input appendData:[receipt objectForKey:kReceiptOpaqueValue]];
	[input appendData:[receipt objectForKey:kReceiptBundleIdentiferData]];
	
	NSMutableData *hash = [NSMutableData dataWithLength:SHA_DIGEST_LENGTH];
	SHA1([input bytes], [input length], [hash mutableBytes]);

	if ([bundleIdentifer isEqualToString:[receipt objectForKey:kReceiptBundleIdentifer]] &&
		[bundleVersion isEqualToString:[receipt objectForKey:kReceiptVersion]] &&
		[hash isEqualToData:[receipt objectForKey:kReceiptHash]]) {
		
		if (validateBinarySignature(@"Apple Mac OS Application Signing") == YES) {
			return YES;
		} else {
			return validateBinarySignature(@"3rd Party Mac Developer Application: BestTechie Holdings, Inc.");
		}
	}

	return NO;
}
