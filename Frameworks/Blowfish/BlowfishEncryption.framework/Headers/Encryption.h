/* Copyright (c) 2011 Codeux Software <support at codeux dot com> */

@interface CSFWBlowfish : NSObject
+ (NSString *)encodeData:(NSString *)input key:(NSString *)phrase encoding:(NSStringEncoding)local;
+ (NSString *)decodeData:(NSString *)input key:(NSString *)phrase encoding:(NSStringEncoding)local;
@end