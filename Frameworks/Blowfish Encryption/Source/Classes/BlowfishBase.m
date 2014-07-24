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

/* This source file contains modified work of the original Dirt IRC proxy
 project hosted at: https://github.com/flakes/mirc_fish_10/tree/master/fish_10
 The author of this project has opted to not license their software and 
 instead release it into the Public Domain. */

#import "BlowfishBase.h"
#import "NSDataHelper.h"
#import "Base64Encoding.h"

#include <openssl/blowfish.h>
#include <openssl/evp.h>
#include <openssl/rand.h>

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

+ (NSString *)encrypt:(NSString *)rawInput key:(NSString *)secretKey algorithm:(CSFWBlowfishEncryptionAlgorithm)algorithm encoding:(NSStringEncoding)dataEncoding
{
	if (algorithm == CSFWBlowfishEncryptionDefaultAlgorithm || algorithm == CSFWBlowfishEncryptionECBAlgorithm) {
		return [self ecb_encrypt:rawInput key:secretKey encoding:dataEncoding];
	} else {
		return [self cbc_encrypt:rawInput key:secretKey encoding:dataEncoding];
	}
}

+ (NSString *)decrypt:(NSString *)rawInput key:(NSString *)secretKey algorithm:(CSFWBlowfishEncryptionAlgorithm)algorithm encoding:(NSStringEncoding)dataEncoding badBytes:(NSInteger *)badByteCount
{
	if (algorithm == CSFWBlowfishEncryptionDefaultAlgorithm || algorithm == CSFWBlowfishEncryptionECBAlgorithm) {
		return [self ecb_decrypt:rawInput key:secretKey encoding:dataEncoding badBytes:badByteCount];
	} else {
		return [self cbc_decrypt:rawInput key:secretKey encoding:dataEncoding badBytes:badByteCount];
	}
}

#pragma mark -
#pragma mark CBC Encryption

+ (BOOL)walkBlowfishCypherForCBC:(EVP_CIPHER_CTX *)context inputStream:(unsigned char *)inputStream inputSize:(size_t)inputSize outputHandler:(NSMutableData **)outputHandler
{
	/* Define basic context. */
	size_t _bytesLeft = inputSize;
	
	const unsigned char *_inputPointer = inputStream;
	
	unsigned char _temporaryBuffer[256];
	
	int _outLength;
	
	/* Begin looping blocks. */
	while (_bytesLeft > 0) {
		int _inSize = (int)_bytesLeft;
		
		if (_inSize > 256) {
			_inSize = 256;
		}
		
		if (EVP_CipherUpdate(context, _temporaryBuffer, &_outLength, _inputPointer, _inSize) == 0) {
			return NO;
		}
		
		[*outputHandler appendBytes:_temporaryBuffer length:_outLength];
		
		_bytesLeft -= _inSize;
		
		_inputPointer += _inSize;
	}
	
	/* Finish looping. */
	BOOL success = (EVP_CipherFinal_ex(context, _temporaryBuffer, &_outLength) == 1);
	
	if (success) {
		[*outputHandler appendBytes:_temporaryBuffer length:_outLength];
	}
	
	return success;
}

+ (NSString *)cbc_encrypt:(NSString *)rawInput key:(NSString *)secretKey encoding:(NSStringEncoding)dataEncoding
{
	if ([secretKey length] <= 0 || [rawInput length] <= 0) {
		return nil;
	}
	
	const char *message	= [rawInput	 cStringUsingEncoding:dataEncoding];
	const char *secrkey	= [secretKey cStringUsingEncoding:dataEncoding];
	
	size_t keylen = strlen(secrkey);
	size_t msglen = strlen(message);

	/* =============================================== */
	
	EVP_CIPHER_CTX context;
	
	const unsigned char iv[8] = {0};
	
	if (keylen > 56) {
		keylen = 56;
	} else {
		keylen = keylen;
	}
	
	/* =============================================== */
	
	/* Create structure for encryption. */
	EVP_CIPHER_CTX_init(&context);
	
	EVP_CipherInit_ex(&context, EVP_bf_cbc(), NULL, NULL, NULL, 1);
	
	/* Set options for encryption. */
	EVP_CIPHER_CTX_set_key_length(&context, (int)keylen);
	
	EVP_CIPHER_CTX_set_padding(&context, 0);
	
	/* Build session context. */
	EVP_CipherInit_ex(&context, NULL, NULL, (const unsigned char *)secrkey, iv, 1);
	
	/* Prepare buffer. */
	size_t bufferSize = msglen;
	
	if (bufferSize % 8) {
		bufferSize += (8 - (bufferSize % 8));
	}
	
	bufferSize += 8;
	
	/* =============================================== */
	
	/* Create buffer. */
	unsigned char *inputStream = malloc(bufferSize);
	
	memset(inputStream, 0, bufferSize);
	
	/* General IV. */
	unsigned char realIv[8];
	
	if (RAND_bytes(realIv, 8) == 0) {
		RAND_pseudo_bytes(realIv, 8);
	}
	
	/* Copy seed information. */
	memcpy( inputStream, realIv, 8);
	memcpy((inputStream + 8), message, msglen);
	
	/* =============================================== */
	
	/* Out output stream. */
	NSMutableData *outputHandler = [NSMutableData data];
	
	/* Perform encryption. */
	BOOL result = [BlowfishBase walkBlowfishCypherForCBC:&context inputStream:inputStream inputSize:bufferSize outputHandler:&outputHandler];
	
	EVP_CIPHER_CTX_cleanup(&context);
	
	free(inputStream);

	if (result) {
		return [CSFWBase64Encoding encodeData:outputHandler];
	} else {
		return nil;
	}
}


#pragma mark -
#pragma mark CBC Encryption

+ (NSString *)cbc_decrypt:(NSString *)rawInput key:(NSString *)secretKey encoding:(NSStringEncoding)dataEncoding badBytes:(NSInteger *)badByteCount
{
	if ([secretKey length] <= 0 || [rawInput length] <= 0) {
		*badByteCount = 0;
		
		return nil;
	}
	
	/* Decode encoded data. */
	NSData *decodedMessage = [CSFWBase64Encoding decodeData:rawInput];
	
	/* Check if message is fragment. */
	if ((([decodedMessage length] % 8) == 0 && [decodedMessage length] > 8) == NO) {
		*badByteCount = 0;
		
		return nil; // Cancel operation.
	}
	
	/* Begin decoding message. */
	const char *message	= [decodedMessage bytes];
	
	const char *secrkey	= [secretKey cStringUsingEncoding:dataEncoding];
	
	size_t keylen = strlen(secrkey);
	size_t msglen = strlen(message);
	
	/* =============================================== */
	
	EVP_CIPHER_CTX context;
	
	const unsigned char iv[8] = {0};
	
	if (keylen > 56) {
		keylen = 56;
	} else {
		keylen = keylen;
	}
	
	/* Create structure for encryption. */
	EVP_CIPHER_CTX_init(&context);
	
	EVP_CipherInit_ex(&context, EVP_bf_cbc(), NULL, NULL, NULL, 0);
	
	/* Set options for encryption. */
	EVP_CIPHER_CTX_set_key_length(&context, (int)keylen);
	
	EVP_CIPHER_CTX_set_padding(&context, 0);
	
	/* Build session context. */
	EVP_CipherInit_ex(&context, NULL, NULL, (const unsigned char *)secrkey, iv, 0);
	
	/* =============================================== */
	
	/* Out output stream. */
	NSMutableData *outputHandler = [NSMutableData data];
	
	/* Perform encryption. */
	BOOL result = [BlowfishBase walkBlowfishCypherForCBC:&context inputStream:(unsigned char *)message inputSize:msglen outputHandler:&outputHandler];
	
	EVP_CIPHER_CTX_cleanup(&context);
	
	/* Return result. */
	// if (result) {
		if ([outputHandler length] > 8) {
			[outputHandler replaceBytesInRange:NSMakeRange(0, 8) withBytes:NULL length:0];
			
			NSData *finalData = nil;
			
			if (dataEncoding == NSUTF8StringEncoding) {
				finalData = [outputHandler repairedCharacterBufferForUTF8Encoding:badByteCount];
			} else {
				finalData =  outputHandler;
				
				*badByteCount = 0;
			}
			
			NSString *cypher = [[NSString alloc] initWithData:outputHandler encoding:dataEncoding];
			
			return cypher;
		} else {
			return nil;
		}
	// } else {
	//	return nil;
	// }
}

#pragma mark -
#pragma mark ECB Decryption

+ (NSString *)ecb_encrypt:(NSString *)rawInput key:(NSString *)secretKey encoding:(NSStringEncoding)dataEncoding
{
	if ([secretKey length] <= 0 || [rawInput length] <= 0) {
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

	if ([cypher length] <= 0) {
		return nil;
	}
	
    return cypher;
}

#pragma mark -
#pragma mark ECB Decryption

+ (NSString *)ecb_decrypt:(NSString *)rawInput key:(NSString *)secretKey encoding:(NSStringEncoding)dataEncoding badBytes:(NSInteger *)badByteCount
{
	if ([secretKey length] <= 0 || [rawInput length] <= 0) {
		*badByteCount = 0;
		
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

	NSData *rawData = [NSData dataWithBytes:decrypted length:strlen(decrypted)];
	
	if (dataEncoding == NSUTF8StringEncoding) {
		rawData = [rawData repairedCharacterBufferForUTF8Encoding:badByteCount];
	} else {
		*badByteCount = 0;
	}
	
	NSString *cypher = [[NSString alloc] initWithData:rawData encoding:dataEncoding];

	free(decrypted);

	// ========================================== //

	if ([cypher length] <= 0) {
		return nil;
	}
	
    return cypher;
}

@end
