/* ********************************************************************* 
				  _____         _               _
				 |_   _|____  _| |_ _   _  __ _| |
				   | |/ _ \ \/ / __| | | |/ _` | |
				   | |  __/>  <| |_| |_| | (_| | |
				   |_|\___/_/\_\\__|\__,_|\__,_|_|

 Copyright (c) 2010 — 2014 Codeux Software & respective contributors.
     Please see Acknowledgements.pdf for additional information.
 
 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions
 are met:

    * Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the
      documentation and/or other materials provided with the distribution.
    * Neither the name of Textual and/or Codeux Software, nor the names of 
      its contributors may be used to endorse or promote products derived 
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

/* This source file contains modified work of the original Dirt IRC proxy
 project hosted at: http://sourceforge.net/projects/dirtirc */

// Copyright (c) 2005-2013 Mathias Karlsson
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//
// Please see License.txt for further information.

#import "DH1080Base.h"
#import "Base64Encoding.h"

/* OpenSSL Header Files. */
#include <openssl/sha.h>
#include <openssl/dh.h>
#include <openssl/bn.h>

/* Private Interface. */
@interface DH1080Base ()
@property (nonatomic, strong) NSData *secretValue;
@property (nonatomic, unsafe_unretained) DH *DHStatus;
@property (nonatomic, unsafe_unretained) BIGNUM *publicBigNum;
@end

/* Static Values. */

/* 
	fishPrimeB64 is the exact value of the prime used by the original
	DH1080 implementation. DH->p and DH->g need to be the same value
	for each user involved in a Diffie-Hellman key exchange. Therefore,
	to ensure compatibility with existing users, we have used the same
	prime value (DH->p) as well as using "2" for DH->g. 

	DH1080Base also matches the Base64 format for encoding and decoding. 
*/
static NSString *fishPrimeB64 = @"++ECLiPSE+is+proud+to+present+latest+FiSH+release+featuring+even+more+security+for+you+++shouts+go+out+to+TMG+for+helping+to+generate+this+cool+sophie+germain+prime+number++++/C32L";

/* Static Definitions. */
#define ISNO(s)				   (s == NO)

#define DHAssertNO(c)		if (c == NO)	{ NSAssert(NO, @"DH1080 Key Exchange Failure."); }
#define DHAssertYES(c)		if (c)			{ NSAssert(NO, @"DH1080 Key Exchange Failure."); }

/* Implementation. */
@implementation DH1080Base

#pragma mark -

- (id)init
{
    if ((self = [super init])) {
		self.DHStatus	  = 0;
		self.publicBigNum = 0;

		[self initalizeKeyExchange];

		return self;
	}

	return nil;
}

- (void)dealloc
{
    [self resetStatus];
    [self resetPublicInformation];
}

- (void)resetPublicInformation
{
	if (ISNO(self.publicBigNum == 0)) {
		BN_free(self.publicBigNum);

		self.publicBigNum = 0;
	}
}

- (void)resetStatus
{
	if (ISNO(self.DHStatus == 0)) {
		DH_free(self.DHStatus);

		self.DHStatus = 0;
	}
}

#pragma mark -

- (void)initalizeKeyExchange
{
	DHAssertNO(self.DHStatus == 0);

	self.DHStatus = DH_new();
	
	DHAssertYES(self.DHStatus == 0);

	DHAssertNO(self.DHStatus->g == 0);
	DHAssertNO(self.DHStatus->p == 0);
	
	NSData *primeData = [self base64Decode:fishPrimeB64];

	self.DHStatus->g = BN_new();
	self.DHStatus->p = BN_new();

	BN_dec2bn(&self.DHStatus->g, "2");

	DHAssertNO([primeData length] >= 1);
	
	BIGNUM *ret = BN_bin2bn((unsigned char *)[primeData bytes], (int)[primeData length], self.DHStatus->p);

	DHAssertYES(ret == 0);
	DHAssertYES(self.DHStatus->g == 0);
	DHAssertYES(self.DHStatus->p == 0);

	int check, codes;

	check = DH_check(self.DHStatus, &codes);

	DHAssertNO(check == 1);
	DHAssertNO(codes == 0);

	int genr = DH_generate_key(self.DHStatus);

	DHAssertNO(genr == 1);
}

#pragma mark -

- (void)computeKey
{
	DHAssertYES(self.DHStatus	 == 0);
	DHAssertYES(self.DHStatus->g == 0);
	DHAssertYES(self.DHStatus->p == 0);
	
	DHAssertYES(self.publicBigNum == 0);

	NSInteger size = DH_size(self.DHStatus);

	DHAssertNO(size == DH1080RequiredKeyLength);

	unsigned char key[DH1080RequiredKeyLength];

	NSInteger num = DH_compute_key(key, self.publicBigNum, self.DHStatus);

	DHAssertNO(num == size);
	
	NSData *secretValue = [[NSData alloc] initWithBytes:key length:sizeof(key)];

	DHAssertNO([secretValue length] >= 1);

	self.secretValue = secretValue;
}

- (void)setKeyForComputation:(NSData *)publicKey
{
	if (self.publicBigNum == 0) {
		self.publicBigNum = BN_new();
	}

	DHAssertYES(self.publicBigNum == 0);

	BIGNUM *ret = BN_bin2bn((unsigned char *)[publicKey bytes], (int)[publicKey length], self.publicBigNum);

	DHAssertYES(ret == 0);
	DHAssertYES(self.publicBigNum == 0);
}

#pragma mark -

- (NSString *)secretStringValue
{
	NSData *secretValue = [self secretValue];

	DHAssertNO(secretValue.length >= 1);
	
	unsigned char sha_md[32];
	
	SHA256((unsigned char *)[secretValue bytes], (int)[secretValue length], sha_md);

	NSData *secretHash = [[NSData alloc] initWithBytes:sha_md length:sizeof(sha_md)];

	DHAssertNO([secretHash length] >= 1);

    return [self base64Encode:secretHash];
}

- (NSString *)publicKeyValue:(NSData *)publicInput
{
	DHAssertNO([publicInput length] >= 1);

	return [self base64Encode:publicInput];
}

- (NSData *)rawPublicKey
{
	DHAssertYES(self.DHStatus	 == 0);
	DHAssertYES(self.DHStatus->g == 0);
	DHAssertYES(self.DHStatus->p == 0);

	NSInteger size = DH_size(self.DHStatus);

	DHAssertNO(size == DH1080RequiredKeyLength);

	unsigned char key[DH1080RequiredKeyLength];

	BN_bn2bin(self.DHStatus->pub_key, key);

	NSData *publicInput = [[NSData alloc] initWithBytes:key length:sizeof(key)];

	DHAssertNO([publicInput length] >= 1);

	return publicInput;
}

#pragma mark -

- (NSString *)base64Encode:(NSData *)input
{
	NSString *output = [CSFWBase64Encoding encodeData:input];

	DHAssertNO([output length] >= 1);

	BOOL equalFound = NO;

	while (YES) {
		NSRange equalRange = [output rangeOfString:@"="];

		if (equalRange.location == NSNotFound) {
			if (equalFound == NO) {
				output = [output stringByAppendingString:@"A"];
			}

			break;
		} else {
			equalFound = YES;

			output = [output substringWithRange:NSMakeRange(0, ([output length] - 1))];
		}
	}

	return output;
}

- (NSData *)base64Decode:(NSString *)input
{
	NSInteger inputLength = [input length];

	DHAssertNO([input length] >= 1);

	NSString *ecv = [input substringFromIndex:(inputLength - 1)];

	if ((inputLength % 4) == 1 && [ecv isEqualToString:@"A"]) {
		input = [input substringToIndex:(inputLength - 1)];
	}

	while ((([input length] % 4) == 0) == NO) {
		input = [input stringByAppendingString:@"="];
	}
	
	return [CSFWBase64Encoding decodeData:input];
}

@end
