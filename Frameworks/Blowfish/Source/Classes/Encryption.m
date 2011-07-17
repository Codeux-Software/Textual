/* Copyright (c) 2011 Codeux Software <support at codeux dot com> */

#import "Encryption.h"
#import "blowfish_be.h"

@implementation CSFWBlowfish

+ (NSString *)encodeData:(NSString *)input key:(NSString *)phrase encoding:(NSStringEncoding)local
{
	const char *message = [input cStringUsingEncoding:local];
	const char *key = [phrase cStringUsingEncoding:local];
	size_t keylen = [phrase length];
	
	char *resultString = fish_encrypt(key, keylen, message);
	
	NSString *cypher = [NSString stringWithCString:resultString encoding:local];
	
	free(resultString);
	
	return [@"+OK " stringByAppendingString:cypher];
}

+ (NSString *)decodeData:(NSString *)input key:(NSString *)phrase encoding:(NSStringEncoding)local
{
	if ([input hasPrefix:@"+OK "] && [input length] > 4) {
		input = [input substringFromIndex:4];
	}
	
	const char *message = [input cStringUsingEncoding:local];
	const char *key = [phrase cStringUsingEncoding:local];
	size_t keylen = [phrase length];
	
	char *resultString = fish_decrypt(key, keylen, message);
	
	NSString *cypher = [NSString stringWithCString:resultString encoding:local];
	
	free(resultString);
	
	return cypher;
}

@end