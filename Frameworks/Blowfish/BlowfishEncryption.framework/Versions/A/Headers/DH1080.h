/* Copyright (c) 2011 Codeux Software <support at codeux dot com> */

#define requiredPublicKeyLength		135

@interface CFDH1080 : NSObject 
- (NSString *)generatePublicKey;
- (NSString *)secretKeyFromPublicKey:(NSString *)publicKey;
@end