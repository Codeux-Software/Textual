// Copyright 2010 Matthew Stevens, Ruotger Skupin, Apple. All rights reserved.
// <https://github.com/roddi/ValidateStoreReceipt>

TEXTUAL_EXTERN NSString *kReceiptBundleIdentifer;
TEXTUAL_EXTERN NSString *kReceiptBundleIdentiferData;
TEXTUAL_EXTERN NSString *kReceiptVersion;
TEXTUAL_EXTERN NSString *kReceiptOpaqueValue;
TEXTUAL_EXTERN NSString *kReceiptHash;

BOOL validateReceiptAtPath(NSString *path);
BOOL validateBinarySignature(NSString *authority);