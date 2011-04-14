/* Copyright (c) 2011 Codeux Software <support at codeux dot com> */

#import "DH1080.h"
#import "dh1080_be.hpp"

@implementation CFDH1080

static dhclass *keyExchanger;

- (void)dealloc
{
	if (keyExchanger) {
		free(keyExchanger);
	}
	
	[self dealloc];
}

- (NSString *)generatePublicKey
{
	std::string publicKey;
	
	keyExchanger = new dhclass;
	
	if (keyExchanger) {
		if (keyExchanger->generate()) {
			keyExchanger->get_public_key(publicKey);
			
			NSString *_publicKey = [NSString stringWithUTF8String:publicKey.c_str()];
			
			if ([_publicKey length] >= 1) {
				return _publicKey;
			}
		}
	}
	
	return nil;
}

- (NSString *)secretKeyFromPublicKey:(NSString *)publicKey
{
	std::string specialPrivateKey;
	std::string specialPublicKey([publicKey UTF8String]);
	
	dh_base64decode(specialPublicKey);

	if (specialPublicKey.size() < requiredPublicKeyLength ||
		specialPublicKey.size() > requiredPublicKeyLength) {
		
		return nil;
	}
	
	keyExchanger->set_her_key(specialPublicKey);
	
	if (keyExchanger->compute() == NO) {
		return nil;
	}
	
	keyExchanger->get_secret(specialPrivateKey);
	
	NSString *privateKey = [[NSString alloc] initWithBytes:specialPrivateKey.c_str()
													length:specialPrivateKey.length()
												 encoding:NSASCIIStringEncoding];
	
	return [privateKey autorelease];
}

@end