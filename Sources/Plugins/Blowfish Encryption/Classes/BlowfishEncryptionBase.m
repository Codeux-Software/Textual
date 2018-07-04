/* *********************************************************************
 *
 *         Copyright (c) 2015 - 2018 Codeux Software, LLC
 *     Please see ACKNOWLEDGEMENT for additional information.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *
 *  * Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 *  * Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 *  * Neither the name of "Codeux Software, LLC", nor the names of its
 *    contributors may be used to endorse or promote products derived
 *    from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE AUTHOR AND CONTRIBUTORS ``AS IS'' AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED. IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE LIABLE
 * FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
 * OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
 * LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
 * OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
 * SUCH DAMAGE.
 *
 *********************************************************************** */

/* A portion of this source file contains copyrighted work derived from one or more
 3rd party, open source projects. The use of this work is hereby acknowledged. */

// Copyright (c) 2005-2013 Mathias Karlsson
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//
// Please see LICENSE-GPLv2.txt for further information.

#import "BlowfishEncryptionBase.h"

#import "NSDataHelper.h"

#import <CocoaExtensions/XRBase64Encoding.h>

#import <CommonCrypto/CommonCrypto.h>
#import <CommonCrypto/CommonRandom.h>

static const char blowfish_ecb_base64_chars[64] = "./0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ";

#pragma mark -
#pragma mark Implementation.

@implementation EKBlowfishEncryptionBase

+ (NSUInteger)estiminatedLengthOfEncodedDataOfLength:(NSUInteger)dataLength
{
	/* The returned estimation is the result of base64 encoded,
	 properly padded encryption block up to input length. */
	NSUInteger blockLength = dataLength;

	NSUInteger blockLengthRemainder = (blockLength % kCCBlockSizeBlowfish);

	if (blockLengthRemainder != 0) {
		blockLength += (kCCBlockSizeBlowfish - blockLengthRemainder);
	}

	return (ceil(blockLength / 3) * 4);
}

+ (NSString *)encrypt:(NSString *)rawInput key:(NSString *)secretKey mode:(EKBlowfishEncryptionModeOfOperation)mode encoding:(NSStringEncoding)dataEncoding
{
	if (mode == EKBlowfishEncryptionDefaultModeOfOperation || mode == EKBlowfishEncryptionECBModeOfOperation) {
		return [self ecb_encrypt:rawInput key:secretKey encoding:dataEncoding];
	} else {
		return [self cbc_encrypt:rawInput key:secretKey encoding:dataEncoding];
	}
}

+ (NSString *)decrypt:(NSString *)rawInput key:(NSString *)secretKey mode:(EKBlowfishEncryptionModeOfOperation)mode encoding:(NSStringEncoding)dataEncoding lostBytes:(NSInteger *)lostBytes
{
	if (mode == EKBlowfishEncryptionDefaultModeOfOperation || mode == EKBlowfishEncryptionECBModeOfOperation) {
		return [self ecb_decrypt:rawInput key:secretKey encoding:dataEncoding lostBytes:lostBytes];
	} else {
		return [self cbc_decrypt:rawInput key:secretKey encoding:dataEncoding];
	}
}

NSData *_commonCryptoIninitializationVector()
{
	uint8_t ininitializationVector[kCCBlockSizeBlowfish] = {0};

	CCRNGStatus cryptorRandomBytesStatus =
	CCRandomGenerateBytes(&ininitializationVector, 8);

	if (cryptorRandomBytesStatus == kCCSuccess) {
		return [NSData dataWithBytes:ininitializationVector length:kCCBlockSizeBlowfish];
	} else {
		return nil;
	}
}

NSData *_performCommonCryptoOperation(CCOperation ccInOperation,
									  CCAlgorithm ccInOperationAlgorithm,
									  CCMode ccInOperationMode,
									  BOOL ccInOperationUsesPadding,
									  NSData *ccIninitializationVector,
									  NSData *ccInSecretKey,
									  NSData *ccInRelatedData)
{
	/* Perform basic validation on input data. */
	if (ccInSecretKey == nil || ccInRelatedData == nil) {
		return nil;
	}

	/* Validate key length is within an expected range. */
	switch (ccInOperationAlgorithm) {
		case kCCAlgorithmAES128:
		{
			if ([ccInSecretKey length] != kCCKeySizeAES128 &&
				[ccInSecretKey length] != kCCKeySizeAES192 &&
				[ccInSecretKey length] != kCCKeySizeAES256)
			{
				return nil;
			}

			break;
		}
		case kCCAlgorithmDES:
		{
			if ([ccInSecretKey length] != kCCKeySizeDES) {
				return nil;
			}

			break;
		}
		case kCCAlgorithm3DES:
		{
			if ([ccInSecretKey length] != kCCKeySize3DES) {
				return nil;
			}

			break;
		}
		case kCCAlgorithmCAST:
		{
			if ([ccInSecretKey length] < kCCKeySizeMinCAST ||
				[ccInSecretKey length] > kCCKeySizeMaxCAST)
			{
				return nil;
			}

			break;
		}
		case kCCAlgorithmRC4:
		{
			if ([ccInSecretKey length] < kCCKeySizeMinRC4 ||
				[ccInSecretKey length] > kCCKeySizeMaxRC4)
			{
				return nil;
			}

			break;
		}
		case kCCAlgorithmRC2:
		{
			if ([ccInSecretKey length] < kCCKeySizeMinRC2 ||
				[ccInSecretKey length] > kCCKeySizeMaxRC2)
			{
				return nil;
			}

			break;
		}
		case kCCAlgorithmBlowfish:
		{
			if (/* [ccInSecretKey length] < kCCKeySizeMinBlowfish || */
				[ccInSecretKey length] > kCCKeySizeMaxBlowfish)
			{
				return nil;
			}

			break;
		}
	}

	/* Attempt to create a cryptor reference using input. */
	CCPadding ccInPadding;

	if (ccInOperationUsesPadding) {
		ccInPadding = ccPKCS7Padding;
	} else {
		ccInPadding = ccNoPadding;
	}

	CCCryptorRef cryptorRef;

	CCCryptorStatus cryptorCreateStatus =
	CCCryptorCreateWithMode(ccInOperation,
							ccInOperationMode,
							ccInOperationAlgorithm,
							ccInPadding,
							[ccIninitializationVector bytes],
							[ccInSecretKey bytes],
							[ccInSecretKey length],
							NULL,
							0,
							0,
							0,
							&cryptorRef);

	if (cryptorCreateStatus != kCCSuccess) {
		return nil;
	}

	/* Create output buffer using expected output length. */
	BOOL willCallCryptorFinal = (ccInPadding == ccPKCS7Padding || ccInOperationAlgorithm == kCCAlgorithmRC4);

	size_t outputBufferSize = CCCryptorGetOutputLength(cryptorRef, [ccInRelatedData length], willCallCryptorFinal);

	NSMutableData *outputBuffer = [NSMutableData dataWithLength:outputBufferSize];;

	/* Perform update operation on the cryptor. */
	size_t cryptorUpdateDataOutMoved = 0;

	CCCryptorStatus cryptorUpdateStatus =
	CCCryptorUpdate(cryptorRef,
					[ccInRelatedData bytes],
					[ccInRelatedData length],
					[outputBuffer mutableBytes],
					[outputBuffer length],
					&cryptorUpdateDataOutMoved);

	if (cryptorUpdateStatus != kCCSuccess) {
		goto cleanup_function;
	}

	/* Perform final operation on the cryptor. */
	size_t totalBytesWritten = cryptorUpdateDataOutMoved;

	if (willCallCryptorFinal) {
		void *cryptorFinalDataOut = ([outputBuffer mutableBytes] + cryptorUpdateDataOutMoved);

		size_t cryptorFinalDataOutSize = ([outputBuffer length] - cryptorUpdateDataOutMoved);

		CCCryptorStatus cryptorFinalStatus =
		CCCryptorFinal(cryptorRef,
					   cryptorFinalDataOut,
					   cryptorFinalDataOutSize,
					   &cryptorUpdateDataOutMoved);

		if (cryptorFinalStatus != kCCSuccess) {
			goto cleanup_function;
		}

		totalBytesWritten += cryptorUpdateDataOutMoved;

		[outputBuffer setLength:totalBytesWritten];
	}

cleanup_function:
	if (cryptorRef) {
		CCCryptorRelease(cryptorRef);
	}
	
	return outputBuffer;
}

#pragma mark -
#pragma mark CBC Encryption

+ (NSString *)cbc_encrypt:(NSString *)rawInput key:(NSString *)secretKey encoding:(NSStringEncoding)dataEncoding
{
	NSData *secretKeyData = [secretKey dataUsingEncoding:dataEncoding];

	NSData *rawInputData = [rawInput dataUsingEncoding:dataEncoding paddedByBytes:kCCBlockSizeBlowfish];

	NSData *ininitializationVectorData = _commonCryptoIninitializationVector();

	if (ininitializationVectorData == nil) {
		return nil;
	}

	/* mIRC fish 10 places the ininitialization vector directly on the data
	 stream rather than allowing the crypto library to handle that itself. 
	 If we do not append the IV here and instead feed it to Common Crypto,
	 mIRC will not handle the operation properly. */
	NSMutableData *objectToEncrypt = [NSMutableData data];

	[objectToEncrypt appendData:ininitializationVectorData];
	[objectToEncrypt appendData:rawInputData];

	NSData *encryptedData =
	_performCommonCryptoOperation(kCCEncrypt, kCCAlgorithmBlowfish, kCCModeCBC, NO, nil, secretKeyData, objectToEncrypt);

	return [XRBase64Encoding encodeData:encryptedData];
}

#pragma mark -
#pragma mark CBC Decryption

+ (NSString *)cbc_decrypt:(NSString *)rawInput key:(NSString *)secretKey encoding:(NSStringEncoding)dataEncoding
{
	NSData *secretKeyData = [secretKey dataUsingEncoding:dataEncoding];

	NSData *rawInputData = [XRBase64Encoding decodeData:rawInput];

	NSData *decryptedData =
	_performCommonCryptoOperation(kCCDecrypt, kCCAlgorithmBlowfish, kCCModeCBC, NO, nil, secretKeyData, rawInputData);

	/* If we contain at least two blocks, then remove the first block. 
	 mIRC fish 10 has the IV in the first block then we want at least
	 one block of user data. */
	if ([decryptedData length] >= (kCCBlockSizeBlowfish * 2)) {
		 decryptedData = [decryptedData subdataWithRange:NSMakeRange(kCCBlockSizeBlowfish,
										   ([decryptedData length] - kCCBlockSizeBlowfish))];
	} else {
		return nil;
	}

	NSMutableData *decryptedDataCleaned = [decryptedData mutableCopy];
	[decryptedDataCleaned removeBadCharacters];

	return [[NSString alloc] initWithData:decryptedDataCleaned encoding:dataEncoding];
}

#pragma mark -
#pragma mark ECB Mode Encryption

+ (NSString *)ecb_encrypt:(NSString *)rawInput key:(NSString *)secretKey encoding:(NSStringEncoding)dataEncoding
{
	NSData *secretKeyData = [secretKey dataUsingEncoding:dataEncoding];

	NSData *rawInputData = [rawInput dataUsingEncoding:dataEncoding paddedByBytes:kCCBlockSizeBlowfish];

	NSData *encryptedData =
	_performCommonCryptoOperation(kCCEncrypt, kCCAlgorithmBlowfish, kCCModeECB, NO, nil, secretKeyData, rawInputData);

	NSString *encryptedString = [EKBlowfishEncryptionBase ecb_encrypt_base64Encode:encryptedData];

	return encryptedString;
}

+ (NSString *)ecb_decrypt:(NSString *)rawInput key:(NSString *)secretKey encoding:(NSStringEncoding)dataEncoding lostBytes:(NSInteger *)lostBytes
{
	NSData *secretKeyData = [secretKey dataUsingEncoding:dataEncoding];

	NSData *encodedRawData = [rawInput dataUsingEncoding:dataEncoding fitToPadding:12 trimmedCharacters:lostBytes];

	NSData *rawInputData = [EKBlowfishEncryptionBase ecb_decrypt_base64Decode:encodedRawData];

	NSData *decryptedData =
	_performCommonCryptoOperation(kCCDecrypt, kCCAlgorithmBlowfish, kCCModeECB, NO, nil, secretKeyData, rawInputData);

	NSMutableData *decryptedDataCleaned = [decryptedData mutableCopy];
	[decryptedDataCleaned removeBadCharacters];

	return [[NSString alloc] initWithData:decryptedDataCleaned encoding:dataEncoding];
}

#pragma mark -
#pragma mark ECB Mode Encoding

+ (NSString *)ecb_encrypt_base64Encode:(NSData *)encryptedData
{
	if (encryptedData == nil) {
		return nil;
	}

	if (([encryptedData length] % kCCBlockSizeBlowfish) != 0) {
		return nil;
	}

	NSMutableData *outputBuffer = [NSMutableData data];

	unsigned char *s = (unsigned char *)[encryptedData bytes];

	for (NSInteger i = 0; i < [encryptedData length]; i += 8) {
		unsigned int left;
		unsigned int right;

		left  = (*s++ << 24);
		left += (*s++ << 16);
		left += (*s++ << 8);
		left +=  *s++;

		right  = (*s++ << 24);
		right += (*s++ << 16);
		right += (*s++ << 8);
		right +=  *s++;

		for (NSInteger k = 0; k < 6; k++) {
			unsigned char partChar = blowfish_ecb_base64_chars[(right & 0x3f)];

			[outputBuffer appendBytes:&partChar length:sizeof(partChar)];

			right = (right >> 6);
		}

		for (NSInteger k = 0; k < 6; k++) {
			unsigned char partChar = blowfish_ecb_base64_chars[(left & 0x3f)];

			[outputBuffer appendBytes:&partChar length:sizeof(partChar)];

			left = (left >> 6);
		}
	}

	return [[NSString alloc] initWithData:outputBuffer encoding:NSASCIIStringEncoding];
}

+ (int)ecb_decrypt_base64DecodeCharacterIndex:(char)c
{
	int i = (-1);

	for (i = 0; i < 64; i++) {
		if (blowfish_ecb_base64_chars[i] == c) {
			return i;
		}
	}

	return i;
}

+ (NSData *)ecb_decrypt_base64Decode:(NSData *)dataToDecrypt
{
	if (dataToDecrypt == nil) {
		return nil;
	}

	if (([dataToDecrypt length] % 12) != 0) {
		return nil;
	}

	NSMutableData *outputBuffer = [NSMutableData data];

	unsigned char *s = (unsigned char *)[dataToDecrypt bytes];

	for (NSInteger i = 0; i < [dataToDecrypt length]; i += 12) {
		unsigned int left = 0;
		unsigned int right = 0;

		for (NSInteger k = 0; k < 6; k++) {
			int partChar = [EKBlowfishEncryptionBase ecb_decrypt_base64DecodeCharacterIndex:(*s++)];

			if (partChar == (-1)) {
				return nil; // Bad character in block
			}

			right |= (partChar << k * 6);
		}

		for (NSInteger k = 0; k < 6; k++) {
			int partChar = [EKBlowfishEncryptionBase ecb_decrypt_base64DecodeCharacterIndex:(*s++)];

			if (partChar == (-1)) {
				return nil; // Bad character in block
			}

			left |= (partChar << k * 6);
		}

		uint8_t bufferByte[8];

		bufferByte[0] = ((left >> 24) & 0xFF);
		bufferByte[1] = ((left >> 16) & 0xFF);
		bufferByte[2] = ((left >> 8) & 0xFF);
		bufferByte[3] =  (left & 0xFF);

		bufferByte[4] = ((right >> 24) & 0xFF);
		bufferByte[5] = ((right >> 16) & 0xFF);
		bufferByte[6] = ((right >> 8) & 0xFF);
		bufferByte[7] =  (right & 0xFF);

		[outputBuffer appendBytes:&bufferByte length:sizeof(bufferByte)];
	}

	return [outputBuffer copy];
}

@end
