/* *********************************************************************
 *                  _____         _               _
 *                 |_   _|____  _| |_ _   _  __ _| |
 *                   | |/ _ \ \/ / __| | | |/ _` | |
 *                   | |  __/>  <| |_| |_| | (_| | |
 *                   |_|\___/_/\_\\__|\__,_|\__,_|_|
 *
 * Copyright (c) 2010 - 2015 Codeux Software, LLC & respective contributors.
 *       Please see Acknowledgements.pdf for additional information.
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
 *  * Neither the name of Textual, "Codeux Software, LLC", nor the
 *    names of its contributors may be used to endorse or promote products
 *    derived from this software without specific prior written permission.
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

NS_ASSUME_NONNULL_BEGIN

#if TEXTUAL_BUILT_WITH_LICENSE_MANAGER == 1
TEXTUAL_EXTERN NSString * const TLOLicenseManagerLicenseDictionaryLicenseCreationDateKey;
TEXTUAL_EXTERN NSString * const TLOLicenseManagerLicenseDictionaryLicenseGenerationKey;
TEXTUAL_EXTERN NSString * const TLOLicenseManagerLicenseDictionaryLicenseKeyKey;
TEXTUAL_EXTERN NSString * const TLOLicenseManagerLicenseDictionaryLicenseProductNameKey;
TEXTUAL_EXTERN NSString * const TLOLicenseManagerLicenseDictionaryLicenseOwnerContactAddressKey;
TEXTUAL_EXTERN NSString * const TLOLicenseManagerLicenseDictionaryLicenseOwnerNameKey;
TEXTUAL_EXTERN NSString * const TLOLicenseManagerLicenseDictionaryLicenseSignatureKey;

TEXTUAL_EXTERN NSUInteger const TLOLicenseManagerCurrentLicenseGeneration;

TEXTUAL_EXTERN void TLOLicenseManagerSetup(void);

TEXTUAL_EXTERN BOOL TLOLicenseManagerTextualIsRegistered(void);

TEXTUAL_EXTERN BOOL TLOLicenseManagerIsTrialExpired(void);
TEXTUAL_EXTERN NSTimeInterval TLOLicenseManagerTimeReaminingInTrial(void);

TEXTUAL_EXTERN BOOL TLOLicenseManagerDeleteLicenseFile(void);
TEXTUAL_EXTERN BOOL TLOLicenseManagerWriteLicenseFileContents(NSData * _Nullable newContents);

TEXTUAL_EXTERN BOOL TLOLicenseManagerLicenseKeyIsValid(NSString *licenseKey);

TEXTUAL_EXTERN NSString * _Nullable TLOLicenseManagerLicenseCreationDate(void);
TEXTUAL_EXTERN NSString * _Nullable TLOLicenseManagerLicenseCreationDateFormatted(void);
TEXTUAL_EXTERN NSUInteger TLOLicenseManagerLicenseGeneration(void);
TEXTUAL_EXTERN NSString * _Nullable TLOLicenseManagerLicenseKey(void);
TEXTUAL_EXTERN NSString * _Nullable TLOLicenseManagerLicenseOwnerContactAddress(void);
TEXTUAL_EXTERN NSString * _Nullable TLOLicenseManagerLicenseOwnerName(void);
#endif

NS_ASSUME_NONNULL_END
