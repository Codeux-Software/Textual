/* *********************************************************************

        Copyright (c) 2010 - 2015 Codeux Software, LLC
     Please see ACKNOWLEDGEMENT for additional information.

 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions
 are met:

 * Redistributions of source code must retain the above copyright
   notice, this list of conditions and the following disclaimer.
 * Redistributions in binary form must reproduce the above copyright
   notice, this list of conditions and the following disclaimer in the
   documentation and/or other materials provided with the distribution.
 * Neither the name of "Codeux Software, LLC", nor the names of its 
   contributors may be used to endorse or promote products derived 
   from this software without specific prior written permission.

 THIS SOFTWARE IS PROVIDED BY THE AUTHOR AND CONTRIBUTORS ``AS IS'' AND
 ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 ARE DISCLAIMED. IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE LIABLE
 FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
 OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
 LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
 OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
 SUCH DAMAGE.

 *********************************************************************** */

/* A portion of this source file contains copyrighted work derived from one or more
 3rd party, open source projects. The use of this work is hereby acknowledged. */

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

/* This source file contains modified work of the original mirc_fish_10
 project hosted at: https://github.com/flakes/mirc_fish_10/tree/master/fish_10
 The author of this project has opted to not license their software and 
 instead release it into the Public Domain. */

#import "BlowfishEncryptionBase.h"

#import "NSDataHelper.h"

#include <openssl/blowfish.h>
#include <openssl/evp.h>
#include <openssl/rand.h>
#include <openssl/bio.h>

#import <CocoaExtensions/XRBase64Encoding.h>

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

@implementation EKBlowfishEncryptionBase

+ (NSString *)encrypt:(NSString *)rawInput key:(NSString *)secretKey mode:(EKBlowfishEncryptionModeOfOperation)mode encoding:(NSStringEncoding)dataEncoding
{
	if (mode == EKBlowfishEncryptionDefaultModeOfOperation || mode == EKBlowfishEncryptionECBModeOfOperation) {
		return [self ecb_encrypt:rawInput key:secretKey encoding:dataEncoding];
	} else {
		return [self cbc_encrypt:rawInput key:secretKey encoding:dataEncoding];
	}
}

+ (NSString *)decrypt:(NSString *)rawInput key:(NSString *)secretKey mode:(EKBlowfishEncryptionModeOfOperation)mode encoding:(NSStringEncoding)dataEncoding badBytes:(NSInteger *)badByteCount
{
	if (mode == EKBlowfishEncryptionDefaultModeOfOperation || mode == EKBlowfishEncryptionECBModeOfOperation) {
		return [self ecb_decrypt:rawInput key:secretKey encoding:dataEncoding badBytes:badByteCount];
	} else {
		return [self cbc_decrypt:rawInput key:secretKey encoding:dataEncoding badBytes:badByteCount];
	}
}

#pragma mark -
#pragma mark CBC Encryption

+ (BOOL)walkBlowfishCipherForCBC:(EVP_CIPHER_CTX *)context inputStream:(unsigned char *)inputStream inputSize:(size_t)inputSize outputHandler:(NSMutableData * __autoreleasing *)outputHandler
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
			NSLog(@"[EKBlowfishEncryptionBase] Walking the cipher failed on EVP_CipherUpdate");
			
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
	} else {
		NSLog(@"[EKBlowfishEncryptionBase] Walking the cipher failed on EVP_CipherFinal_ex");
	}
	
	return success;
}

+ (NSString *)cbc_encrypt:(NSString *)rawInput key:(NSString *)secretKey encoding:(NSStringEncoding)dataEncoding
{
	if ([secretKey length] <= 0 || [rawInput length] <= 0) {
		NSLog(@"[EKBlowfishEncryptionBase] Received bad input with a empty value or empty key.");
		
		return nil;
	}
	
	const char *message	= [rawInput	 cStringUsingEncoding:dataEncoding];
	const char *secrkey	= [secretKey cStringUsingEncoding:dataEncoding];
	
	if (message == NULL) {
		NSLog(@"[EKBlowfishEncryptionBase] C string value of message could not be created.");
		
		return nil;
	}
	
	if (secrkey == NULL) {
		NSLog(@"[EKBlowfishEncryptionBase] C string value of the secret key could not be created.");
		
		return nil;
	}
	
	size_t keylen = strlen(secrkey);
	size_t msglen = strlen(message);

	/* =============================================== */
	
	EVP_CIPHER_CTX context;
	
	const unsigned char iv[8] = {0};

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
	BOOL result = [EKBlowfishEncryptionBase walkBlowfishCipherForCBC:&context inputStream:inputStream inputSize:bufferSize outputHandler:&outputHandler];
	
	EVP_CIPHER_CTX_cleanup(&context);

	free(inputStream);

	if (result) {
		return [XRBase64Encoding encodeData:outputHandler];
	} else {
		NSLog(@"[EKBlowfishEncryptionBase] Walking the cipher returned NO.");
		
		return nil;
	}
}

#pragma mark -
#pragma mark CBC Decryption

+ (NSString *)cbc_decrypt:(NSString *)rawInput key:(NSString *)secretKey encoding:(NSStringEncoding)dataEncoding badBytes:(NSInteger *)badByteCount
{
	*badByteCount = 0;
		
	if ([secretKey length] <= 0 || [rawInput length] <= 0) {
		NSLog(@"[EKBlowfishEncryptionBase] Received bad input with a empty value or empty key.");
		
		return nil;
	}
	
	/* Decode encoded data. */
	NSData *decodedMessage = [EKBlowfishEncryptionBase base64DecodedCDCData:rawInput];
	
	NSInteger trueLength = [decodedMessage length];

	/* Check if message is fragment. */
	if (trueLength <= 8) {
		NSLog(@"[EKBlowfishEncryptionBase] Received corrupt input with a length less than 8.");
		
		return nil; // Cancel operation.
	}
	
	/* Begin decoding message. */
	BOOL beenCut = (trueLength % 8);
	
	if (beenCut) {
		NSLog(@"[EKBlowfishEncryptionBase] WARNING: Received input not divisible by 8. Moving to last block which is. This may lose data.");
		
		trueLength = (trueLength - (trueLength % 8));
	}
	
	unsigned char *message = malloc(trueLength);
	
	[decodedMessage getBytes:message length:trueLength];
	
	const char *secrkey	= [secretKey cStringUsingEncoding:dataEncoding];
	
	size_t keylen = strlen(secrkey);
	
	size_t msglen = trueLength;

	/* =============================================== */
	
	EVP_CIPHER_CTX context;
	
	const unsigned char iv[8] = {0};
	
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
	BOOL result = [EKBlowfishEncryptionBase walkBlowfishCipherForCBC:&context inputStream:message inputSize:msglen outputHandler:&outputHandler];
	
	EVP_CIPHER_CTX_cleanup(&context);
	
	free(message);
	
	/* Return result. */
	if (result) {
		if ([outputHandler length] > 8) {
			[outputHandler replaceBytesInRange:NSMakeRange(0, 8) withBytes:NULL length:0];
			
			[outputHandler removeBadCharacters];
			
			NSData *finalData = nil;
			
			if (dataEncoding == NSUTF8StringEncoding) {
				finalData = [outputHandler repairedCharacterBufferForUTF8Encoding:badByteCount];
			} else {
				finalData =  outputHandler;
			}
			
			NSString *cipher = [[NSString alloc] initWithData:finalData encoding:dataEncoding];

			return cipher;
		} else {
			NSLog(@"[EKBlowfishEncryptionBase] outputHandler returned a result with a length less or equal to 8.");
			
			return nil;
		}
	} else {
		NSLog(@"[EKBlowfishEncryptionBase] Walking the cipher returned NO.");
		
		return nil;
	}
}

#pragma mark -
#pragma mark CDC Utilities

+ (NSData *)base64DecodedCDCData:(NSString *)rawInput
{
	NSData *data = [rawInput dataUsingEncoding:NSASCIIStringEncoding];
	
	BIO *command = BIO_new(BIO_f_base64());
	
	BIO_set_flags(command, BIO_FLAGS_BASE64_NO_NL);
	
	BIO *context = BIO_new_mem_buf((void *)[data bytes], (int)[data length]);
	
	context = BIO_push(command, context);
 
	NSMutableData *decodedMessage = [NSMutableData data];
	
#define BUFFSIZE 256
	int len;
	
	char inbuf[BUFFSIZE];
	
	while ((len = BIO_read(context, inbuf, BUFFSIZE)) > 0) {
		[decodedMessage appendBytes:inbuf length:len];
	}
 
	BIO_free_all(context);
#undef BUFFSIZE
	
	return decodedMessage;
}

#pragma mark -
#pragma mark ECB Decryption

+ (NSString *)ecb_encrypt:(NSString *)rawInput key:(NSString *)secretKey encoding:(NSStringEncoding)dataEncoding
{
	if ([secretKey length] <= 0 || [rawInput length] <= 0) {
		NSLog(@"[EKBlowfishEncryptionBase] Received bad input with a empty value or empty key.");
		
		return nil;
	}
	
	const char *message	= [rawInput	 cStringUsingEncoding:dataEncoding];
	const char *secrkey	= [secretKey cStringUsingEncoding:dataEncoding];
	
	if (message == NULL) {
		NSLog(@"[EKBlowfishEncryptionBase] C string value of message could not be created.");
		
		return nil;
	}
	
	if (secrkey == NULL) {
		NSLog(@"[EKBlowfishEncryptionBase] C string value of the secret key could not be created.");
		
		return nil;
	}
	
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
		NSLog(@"[EKBlowfishEncryptionBase] Malloc block for encrypted segment returned NULL result.");

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

	NSString *cipher = [NSString stringWithCString:encrypted encoding:dataEncoding];

	free(encrypted);

	/* =============================================== */

	if ([cipher length] <= 0) {
		return nil;
	}
	
    return cipher;
}

#pragma mark -
#pragma mark ECB Decryption

+ (NSString *)ecb_decrypt:(NSString *)rawInput key:(NSString *)secretKey encoding:(NSStringEncoding)dataEncoding badBytes:(NSInteger *)badByteCount
{
	*badByteCount = 0;
		
	if ([secretKey length] <= 0 || [rawInput length] <= 0) {
		NSLog(@"[EKBlowfishEncryptionBase] Received bad input with a empty value or empty key.");
		
		return nil;
	}

	const char *message	= [rawInput	 cStringUsingEncoding:dataEncoding];
	const char *secrkey	= [secretKey cStringUsingEncoding:dataEncoding];
	
	if (message == NULL) {
		NSLog(@"[EKBlowfishEncryptionBase] C string value of message could not be created.");
		
		return nil;
	}
	
	if (secrkey == NULL) {
		NSLog(@"[EKBlowfishEncryptionBase] C string value of the secret key could not be created.");
		
		return nil;
	}
	
	size_t keylen = strlen(secrkey);
	size_t msglen = strlen(message);

	/* =============================================== */

	BF_KEY bfkey;
	
    BF_set_key(&bfkey, (int)keylen, (const unsigned char *)secrkey);

    char *decrypted = malloc((msglen + 1));
	
    char *end = decrypted;

	if (decrypted == NULL) {
		NSLog(@"[EKBlowfishEncryptionBase] Malloc block for encrypted segment returned NULL result.");

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
	
	rawData = [rawData dataByRemovingBadCharacters];
	
	if (dataEncoding == NSUTF8StringEncoding) {
		rawData = [rawData repairedCharacterBufferForUTF8Encoding:badByteCount];
	} else {
		*badByteCount = 0;
	}
	
	NSString *cipher = [[NSString alloc] initWithData:rawData encoding:dataEncoding];

	free(decrypted);

	// ========================================== //

	if ([cipher length] <= 0) {
		return nil;
	}
	
    return cipher;
}

@end
