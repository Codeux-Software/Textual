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

/* 
*
*  TLOLicenseManager is designed to enforce remote license signatures, but
*  Textual is open source so it does not make much sense to design it in such
*  a way that tries to prevent copying.
*
*  The license manager is designed to work in very specific ways:
*
*  1. Given a documented public key, then the public key is used to verify the
*     signature that is present in license files.
*
*  2. A hash of the public key is hardcoded into a function. On launch, the hash
*     of the expected public key and the activate public key are compared. If they
*     are not equal, then this copy of Textual is not "Genuine" — in this case, the
*     user is presented a small prompt informing that Textual is open source and they
*     should prefer the open source version over a possibly pirated version.
*
*  3. At no time shall the license manager make an attempt to lock a user out of
*     application. At most, limit functionality to trial-mode level.
*
 */

static SecKeyRef TLOLicenseManagerPublicKey;

const NSString * TLOLicenseManagerHashOfGenuinePublicKey = @"b2f40b8fe032156ac8f56c68877f9359620d5f3fccffda741494e7fc72375ab0";

NSURL *TLOLicenseManagerUserLicenseFilePath(void)
{
	NSString *cachesFolder = [TPCPathInfo applicationLocalContainerApplicationSupportPath];

	if (cachesFolder == nil) {
		return nil;
	}

	NSString *dest = [cachesFolder stringByAppendingPathComponent:@"/Textual5UserLicense.plist"];

	return [NSURL fileURLWithPath:dest isDirectory:NO];
}

NSData *TLOLicenseManagerUserLicenseFileContents(void)
{
	NSURL *licenseFilePath = TLOLicenseManagerUserLicenseFilePath();

	if (licenseFilePath == nil) {
		LogToConsole(@"Unable to determine the path to retrieve license information from.");

		return nil;
	}

	if ([RZFileManager() fileExistsAtPath:[licenseFilePath path]]) {
		NSError *readError = nil;

		NSData *licenseContents = [NSData dataWithContentsOfURL:licenseFilePath options:0 error:&readError];

		if (licenseContents == nil) {
			LogToConsole(@"Unable to read user license file. Error: %@", [readError localizedDescription]);

			return nil;
		} else {
			return licenseContents;
		}
	} else {
		return nil;
	}
}

NSData *TLOLicenseManagerPublicKeyContents(void)
{
	/* Find where public key is */
	NSURL *publicKeyPath = [RZMainBundle() URLForResource:@"RemoteLicenseSystemPublicKey" withExtension:@"pub"];

	if (publicKeyPath == nil) {
		LogToConsole(@"Unable to find the public key used for verifying signatures.");

		return nil;
	}

	/* Load contents of the public key */
	NSError *readError = nil;

	NSData *publicKeyContents = [NSData dataWithContentsOfURL:publicKeyPath options:0 error:&readError];

	if (publicKeyContents == nil) {
		LogToConsole(@"Unable to read contents of the public key used for verifying signatures. Error: %@", [readError localizedDescription]);

		return nil;
	}

	return publicKeyContents;
}

BOOL TLOLicenseManagerPublicKeyIsGenuine(void)
{
	NSData *publicKeyContents = TLOLicenseManagerPublicKeyContents();

	if (publicKeyContents == nil) {
		return NO;
	}

	NSString *actualPublicKeyHash = [publicKeyContents sha256];

	if (NSObjectsAreEqual(TLOLicenseManagerHashOfGenuinePublicKey, actualPublicKeyHash)) {
		return YES;
	} else {
		return NO;
	}
}

BOOL TLOLicenseManagerPopulatePublicKeyRef(void)
{
	if (PointerIsEmpty(TLOLicenseManagerPublicKey) == NO) {
		return YES; // Do not import public key once we already imported it...
	}

	NSData *publicKeyContents = TLOLicenseManagerPublicKeyContents();

	if (publicKeyContents == nil) {
		return NO;
	}

	SecItemImportExportKeyParameters importParameters;

	importParameters.version = SEC_KEY_IMPORT_EXPORT_PARAMS_VERSION;
	importParameters.flags = kSecKeyNoAccessControl;

	importParameters.passphrase = NULL;
	importParameters.alertTitle = NULL;
	importParameters.alertPrompt = NULL;
	importParameters.accessRef = NULL;

	importParameters.keyUsage = NULL;
	importParameters.keyAttributes = NULL;

	SecExternalItemType itemType = kSecItemTypePublicKey;

	SecExternalFormat externalFormat = kSecFormatPEMSequence;

	int flags = 0;

	CFArrayRef tempArray = NULL;

	OSStatus operationStatus =
		SecItemImport((__bridge CFDataRef)(publicKeyContents), NULL, &externalFormat, &itemType, flags, &importParameters, NULL, &tempArray);

	if (operationStatus == noErr) {
		TLOLicenseManagerPublicKey = (SecKeyRef)CFArrayGetValueAtIndex(tempArray, 0);

		CFRetain(TLOLicenseManagerPublicKey);

		CFRelease(tempArray);

		return YES;
	} else {
		LogToConsole(@"SecItemImport() failed to import public key with status codeL %i", operationStatus);

		return NO;
	}
}
