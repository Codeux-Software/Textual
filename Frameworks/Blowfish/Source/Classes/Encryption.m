/* Copyright (c) 2011 Codeux Software <support at codeux dot com> */

#import "Encryption.h"
#import "blowfish_be.h"

@implementation CSFWBlowfish

+ (NSString *)encodeData:(NSString *)input key:(NSString *)phrase
{
	const char *message = [input UTF8String];
	const char *key = [phrase UTF8String];
	size_t keylen = [phrase length];
	
	char *resultString = fish_encrypt(key, keylen, message);
	
	NSString *cypher = [NSString stringWithUTF8String:resultString];
	
	free(resultString);
	
	return [@"+OK " stringByAppendingString:cypher];
}

+ (NSString *)decodeData:(NSString *)input key:(NSString *)phrase
{
	if ([input hasPrefix:@"+OK "] && [input length] > 4) {
		input = [input substringFromIndex:4];
	}
	
	const char *message = [input UTF8String];
	const char *key = [phrase UTF8String];
	size_t keylen = [phrase length];
	
	char *resultString = fish_decrypt(key, keylen, message);
	
	NSString *cypher = [NSString stringWithUTF8String:resultString];
	
	free(resultString);
	
	return cypher;
}

@end