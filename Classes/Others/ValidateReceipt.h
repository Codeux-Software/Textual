// Copyright 2010 Matthew Stevens, Ruotger Skupin, Apple. All rights reserved.
// <https://github.com/roddi/ValidateStoreReceipt>

extern NSString *kReceiptBundleIdentifer;
extern NSString *kReceiptBundleIdentiferData;
extern NSString *kReceiptVersion;
extern NSString *kReceiptOpaqueValue;
extern NSString *kReceiptHash;

BOOL validateReceiptAtPath(NSString *path);
BOOL validateBinarySignature(NSString *authority);