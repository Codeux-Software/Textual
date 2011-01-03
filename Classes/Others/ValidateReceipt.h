// Copyright 2010 Matthew Stevens, Ruotger Skupin, Apple. All rights reserved.
// <https://github.com/roddi/ValidateStoreReceipt>

extern NSString *kReceiptBundleIdentifer;
extern NSString *kReceiptBundleIdentiferData;
extern NSString *kReceiptVersion;
extern NSString *kReceiptOpaqueValue;
extern NSString *kReceiptHash;

#define USE_SAMPLE_RECEIPT 0

CFDataRef copy_mac_address(void);
BOOL validateReceiptAtPath(NSString *path);
NSDictionary *dictionaryWithAppStoreReceipt(NSString *path);