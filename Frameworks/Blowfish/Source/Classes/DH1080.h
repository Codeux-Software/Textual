/* Copyright (c) 2012 Codeux Software <support at codeux dot com> */

@interface CFDH1080 : NSObject 
- (NSString *)generatePublicKey;
- (NSString *)secretKeyFromPublicKey:(NSString *)publicKey;
@end