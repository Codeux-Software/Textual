/*
	Copyright (c) 2010 Samuel Lidén Borell <samuel@slbdata.se>

	Permission is hereby granted, free of charge, to any person obtaining a copy
	of this software and associated documentation files (the "Software"), to deal
	in the Software without restriction, including without limitation the rights
	to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
	copies of the Software, and to permit persons to whom the Software is
	furnished to do so, subject to the following conditions:

	The above copyright notice and this permission notice shall be included in
	all copies or substantial portions of the Software.

	THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
	IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
	FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
	AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
	LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
	OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
	THE SOFTWARE.
*/

#import "BlowfishBase.h"

#include <openssl/blowfish.h>

/* =============================================== */

#define IB 64

static const char fish_base64[64] = "./0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ";

static const signed char fish_unbase64[256] = {
    IB,IB,IB,IB,IB,IB,IB,IB,  IB,IB,IB,IB,IB,IB,IB,IB,
    IB,IB,IB,IB,IB,IB,IB,IB,  IB,IB,IB,IB,IB,IB,IB,IB,
    IB,IB,IB,IB,IB,IB,IB,IB,  IB,IB,IB,IB,IB,IB, 0, 1,
	2, 3, 4, 5, 6, 7, 8, 9,   10,11,IB,IB,IB,IB,IB,IB,
    IB,38,39,40,41,42,43,44,  45,46,47,48,49,50,51,52,
    53,54,55,56,57,58,59,60,  61,62,63,IB,IB,IB,IB,IB,
    IB,12,13,14,15,16,17,18,  19,20,21,22,23,24,25,26,
    27,28,29,30,31,32,33,34,  35,36,37,IB,IB,IB,IB,IB,
};

#define GET_BYTES(dest, source) do { \
	*((dest)++) = ((source) >> 24) & 0xFF; \
	*((dest)++) = ((source) >> 16) & 0xFF; \
	*((dest)++) = ((source) >> 8) & 0xFF; \
	*((dest)++) = (source) & 0xFF; \
} while (0);

/* =============================================== */

#pragma mark -
#pragma mark Implementation.

@implementation BlowfishBase

#pragma mark -
#pragma mark Encryption.

+ (NSString *)encrypt:(NSString *)rawInput key:(NSString *)secretKey encoding:(NSStringEncoding)dataEncoding
{
	if (secretKey.length <= 0 || rawInput.length <= 0) {
		return nil;
	}
	
	const char *message	= [rawInput	 cStringUsingEncoding:dataEncoding];
	const char *secrkey	= [secretKey cStringUsingEncoding:dataEncoding];

	size_t keylen = strlen(secrkey);
	size_t msglen = strlen(message);

	/* =============================================== */

	BF_KEY bfkey;
    BF_set_key(&bfkey, (int)keylen, (const unsigned char *)secrkey);

	NSInteger mallocSize = msglen;

	mallocSize -= 1;
	mallocSize /= 8;
	mallocSize *= 12;
	mallocSize += 12;
	mallocSize += 1;
	
    char *encrypted = malloc(mallocSize);
    char *end = encrypted;

    if (encrypted == NULL) {
		return nil;
	}

    while (*message) {
        BF_LONG binary[2] = {0, 0};
		
        unsigned char c;

        for (size_t i = 0; i < 8; i++) {
            c = message[i];
			
            binary[i >> 2] |= (c << (8 * (3 - (i & 3))));
			
            if (c == '\0') {
				break;
			}
        }

        message += 8;

        BF_encrypt(binary, &bfkey);

        unsigned char bit = 0;
        unsigned char word = 1;

        for (int i = 0; i < 12; i++) {
            unsigned char d = fish_base64[((binary[word] >> bit) & 63)];

			*(end++) = d;
			
            bit += 6;

			if (i == 5) {
                bit = 0;
                word = 0;
            }
        }

        if (c == '\0') {
			break;
		}
    }

    *end = '\0';

	/* =============================================== */

	NSString *cypher = [NSString stringWithCString:encrypted encoding:dataEncoding];

	free(encrypted);

	/* =============================================== */

	if (cypher.length <= 0) {
		return nil;
	}
	
    return cypher;
}

#pragma mark -
#pragma mark Decryption.

+ (NSString *)decrypt:(NSString *)rawInput key:(NSString *)secretKey encoding:(NSStringEncoding)dataEncoding;
{
	if (secretKey.length <= 0 || rawInput.length <= 0) {
		return nil;
	}

	const char *message	= [rawInput	 cStringUsingEncoding:dataEncoding];
	const char *secrkey	= [secretKey cStringUsingEncoding:dataEncoding];

	size_t keylen = strlen(secrkey);
	size_t msglen = strlen(message);

	/* =============================================== */

	BF_KEY bfkey;
    BF_set_key(&bfkey, (int)keylen, (const unsigned char *)secrkey);

    char *decrypted = malloc((msglen + 1));
    char *end = decrypted;

    if (decrypted == NULL) {
		return nil;
	}

	BOOL breakloop = NO;

    while (*message) {
        BF_LONG binary[2] = {0, 0};
		
        unsigned char bit = 0;
        unsigned char word = 1;

        for (size_t i = 0; i < 12; i++) {
            unsigned char d = fish_unbase64[(const unsigned char)*(message++)];

            if (d == IB) {
				breakloop = YES;

				break;
			}
			
            binary[word] |= (d << bit);
			
            bit += 6;

            if (i == 5) {
                bit = 0;
                word = 0;
            }
        }

		if (breakloop) { // Old implementation used "goto" for this. eww…
			break;
		}

        BF_decrypt(binary, &bfkey);

        GET_BYTES(end, binary[0]);
        GET_BYTES(end, binary[1]);
    }

    *end = '\0';
	
	// ========================================== //

	NSString *cypher = [NSString stringWithCString:decrypted encoding:dataEncoding];

	free(decrypted);

	// ========================================== //

	if ([cypher length] <= 0) {
		return nil;
	}
	
    return cypher;
}

@end
