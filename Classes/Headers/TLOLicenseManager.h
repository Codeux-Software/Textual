/* ********************************************************************* 
                  _____         _               _
                 |_   _|____  _| |_ _   _  __ _| |
                   | |/ _ \ \/ / __| | | |/ _` | |
                   | |  __/>  <| |_| |_| | (_| | |
                   |_|\___/_/\_\\__|\__,_|\__,_|_|

 Copyright (c) 2010 - 2015 Codeux Software, LLC & respective contributors.
        Please see Acknowledgements.pdf for additional information.

 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions
 are met:

    * Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the
      documentation and/or other materials provided with the distribution.
    * Neither the name of Textual and/or "Codeux Software, LLC", nor the 
      names of its contributors may be used to endorse or promote products 
      derived from this software without specific prior written permission.

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

#import "TextualApplication.h"

TEXTUAL_EXTERN NSString const * TLOLicenseManagerLicenseDictionaryLicenseActivationTokenKey;
TEXTUAL_EXTERN NSString const * TLOLicenseManagerLicenseDictionaryLicenseCreationDateKey;
TEXTUAL_EXTERN NSString const * TLOLicenseManagerLicenseDictionaryLicenseKeyKey;
TEXTUAL_EXTERN NSString const * TLOLicenseManagerLicenseDictionaryLicenseOwnerContactAddressKey;
TEXTUAL_EXTERN NSString const * TLOLicenseManagerLicenseDictionaryLicenseOwnerNameKey;
TEXTUAL_EXTERN NSString const * TLOLicenseManagerLicenseDictionaryLicenseSignatureKey;

TEXTUAL_EXTERN BOOL TLOLicenseManagerUserLicenseFileExists(void);

TEXTUAL_EXTERN BOOL TLOLicenseManagerPublicKeyIsGenuine(void);

TEXTUAL_EXTERN void TLOLicenseManagerMaybeDisplayPublicKeyIsGenuinDialog(void);

TEXTUAL_EXTERN BOOL TLOLicenseManagerVerifyLicenseSignature(void); // Alias for TLOLicenseManagerVerifyLicenseSignatureFromFile
TEXTUAL_EXTERN BOOL TLOLicenseManagerVerifyLicenseSignatureFromFile(void);

TEXTUAL_EXTERN BOOL TLOLicenseManagerVerifyLicenseSignatureWithData(NSData *licenseFileContents);

TEXTUAL_EXTERN NSDictionary *TLOLicenseManagerLicenseDictionary(void);

TEXTUAL_EXTERN NSData *TLOLicenseManagerUserLicenseFileContents(void);

TEXTUAL_EXTERN NSString *TLOLicenseManagerLicenseActivationToken(void);
TEXTUAL_EXTERN NSString *TLOLicenseManagerLicenseKey(void);
TEXTUAL_EXTERN NSString *TLOLicenseManagerLicenseOwnerContactAddress(void);
TEXTUAL_EXTERN NSString *TLOLicenseManagerLicenseOwnerName(void);

/* Operations related to the user license file cache the license file the first time 
 that it is accessed. The following method allows this cache to be reset to a blank 
 state to allow a new file to be loaded next time an operation is performed. */
TEXTUAL_EXTERN void TLOLicenseManagerResetLicenseDictionaryCache(void);
