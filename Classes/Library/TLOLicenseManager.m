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

#import "TLOLicenseManager.h"

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

/* 
 *	This source file does not contain source code from, but is designed
 *	around concepts of, the open source project known as "AquaticPrime"
 *
 *	<https://github.com/bdrister/AquaticPrime>
*/

#pragma mark -
#pragma mark Private Implementation

#if TEXTUAL_BUILT_WITH_LICENSE_MANAGER == 1
static SecKeyRef TLOLicenseManagerPublicKey = NULL;
static BOOL TLOLicenseManagerPublicKeyIsGenuineResult = YES;

static NSDictionary *TLOLicenseManagerCachedLicenseDictionary;

NSString * const TLOLicenseManagerHashOfGenuinePublicKey = @"a6970e52865bc004e6732fb37029406a57024517b10ec794aaa88dac82087624";

NSString * const TLOLicenseManagerLicenseKeyRegularExpression = @"^([a-z]{1,12})\\-([a-z]{1,12})\\-([a-z]{1,12})\\-([0-9]{1,35})$";

NSURL *TLOLicenseManagerUserLicenseFilePath(void);
NSData *TLOLicenseManagerUserLicenseFileContents(void);
NSData *TLOLicenseManagerPublicKeyContents(void);
BOOL TLOLicenseManagerPublicKeyIsGenuine(void);
BOOL TLOLicenseManagerPopulatePublicKeyRef(void);
NSDictionary *TLOLicenseManagerLicenseDictionaryWithData(NSData *licenseContents);
BOOL TLOLicenseManagerVerifyLicenseSignatureWithDictionary(NSDictionary *licenseDictionary);
BOOL TLOLicenseManagerLicenseDictionaryIsValid(NSDictionary *licenseDictionary);
void TLOLicenseManagerMaybeDisplayPublicKeyIsGenuineDialog(void);

NSString * const TLOLicenseManagerLicenseDictionaryLicenseActivationTokenKey		= @"licenseActivationToken";
NSString * const TLOLicenseManagerLicenseDictionaryLicenseCreationDateKey			= @"licenseCreationDate";
NSString * const TLOLicenseManagerLicenseDictionaryLicenseKeyKey					= @"licenseKey";
NSString * const TLOLicenseManagerLicenseDictionaryLicenseOwnerContactAddressKey	= @"licenseOwnerContactAddress";
NSString * const TLOLicenseManagerLicenseDictionaryLicenseOwnerNameKey				= @"licenseOwnerName";
NSString * const TLOLicenseManagerLicenseDictionaryLicenseSignatureKey				= @"licenseSignature";
#endif

#pragma mark -
#pragma mark Implementation

#if TEXTUAL_BUILT_WITH_LICENSE_MANAGER == 1
void TLOLicenseManagerSetup(void)
{
	static BOOL _setupComplete = NO;

	if (_setupComplete == NO) {
		_setupComplete = YES;

		(void)TLOLicenseManagerPopulatePublicKeyRef();

		XRPerformBlockAsynchronouslyOnGlobalQueue(^{
			TLOLicenseManagerMaybeDisplayPublicKeyIsGenuineDialog();
		});
	}
}

BOOL TLOLicenseManagerIsTrialMode(void)
{
	/* "trial" mode is designed to last forever. Instead of locking the user out after X days,
	 we instead just limit access to certain features. */

	if (TLOLicenseManagerPublicKeyIsGenuineResult == NO) {
		return YES;
	} else if (TLOLicenseManagerUserLicenseFileExists() == NO) {
		return YES;
	} else {
		return (TLOLicenseManagerVerifyLicenseSignature() == NO);
	}
}

BOOL TLOLicenseManagerLicenseDictionaryIsValid(NSDictionary *licenseDictionary)
{
	if (licenseDictionary == nil) {
		return NO;
	}

	if ([licenseDictionary objectForKey:TLOLicenseManagerLicenseDictionaryLicenseActivationTokenKey] == nil ||
		[licenseDictionary objectForKey:TLOLicenseManagerLicenseDictionaryLicenseCreationDateKey] == nil ||
		[licenseDictionary objectForKey:TLOLicenseManagerLicenseDictionaryLicenseSignatureKey] == nil)
	{
		return NO;
	}

	NSString *licenseKey = [licenseDictionary objectForKey:TLOLicenseManagerLicenseDictionaryLicenseKeyKey];

	if (licenseKey == nil) {
		return NO;
	}

	if ([XRRegularExpression string:licenseKey isMatchedByRegex:TLOLicenseManagerLicenseKeyRegularExpression withoutCase:YES] == NO) {
		return NO;
	}

	return YES;
}

BOOL TLOLicenseManagerVerifyLicenseSignature(void)
{
	return TLOLicenseManagerVerifyLicenseSignatureFromFile();
}

BOOL TLOLicenseManagerVerifyLicenseSignatureFromFile(void)
{
	NSDictionary *licenseDictionary = TLOLicenseManagerLicenseDictionary();

	return TLOLicenseManagerVerifyLicenseSignatureWithDictionary(licenseDictionary);
}

BOOL TLOLicenseManagerVerifyLicenseSignatureWithData(NSData *licenseFileContents)
{
	NSDictionary *licenseDictionary = TLOLicenseManagerLicenseDictionaryWithData(licenseFileContents);

	return TLOLicenseManagerVerifyLicenseSignatureWithDictionary(licenseDictionary);
}

BOOL TLOLicenseManagerVerifyLicenseSignatureWithDictionary(NSDictionary *licenseDictionary)
{
	/* Attempt to populate public key information. */
	if (TLOLicenseManagerPublicKey == NULL) {
		return NO;
	}

	/* Perform basic validation */
	if (TLOLicenseManagerLicenseDictionaryIsValid(licenseDictionary) == NO) {
		LogToConsole(@"Reading license dictionary failed. Returned nil result.");

		return NO;
	}

	/* Retrieve license signature information */
	NSData *licenseSignature = [licenseDictionary objectForKey:TLOLicenseManagerLicenseDictionaryLicenseSignatureKey];

	if (licenseSignature == nil) {
		LogToConsole(@"Missing license signature in license dictionary");

		return NO;
	}

	CFDataRef cfLicenseSignature = (__bridge CFDataRef)(licenseSignature);

	/* Combine all contents of the dictionary, in sorted order, excluding
	 the license dictinoary signature because thats used for comparison. */
	NSMutableData *combinedLicenseData = [NSMutableData data];

	NSArray *sortedLicenseDictionaryKeys = [licenseDictionary sortedDictionaryKeys];

	for (NSString *key in sortedLicenseDictionaryKeys) {
		/* Do not add the signature to the combined data object */
		if (NSObjectsAreEqual(key, TLOLicenseManagerLicenseDictionaryLicenseSignatureKey)) {
			continue;
		}

		id obj = licenseDictionary[key];

		/* Do not factor in anything other that string-based values */
		if ([obj isKindOfClass:[NSString class]] == NO) {
			continue;
		}

		/* Convert the string value into a data object and append it */
		NSData *dataObject = [obj dataUsingEncoding:NSUTF8StringEncoding];

		if (dataObject) {
			[combinedLicenseData appendBytes:[dataObject bytes] length:[dataObject length]];
		}
	};

	if ([combinedLicenseData length] <= 0) {
		LogToConsole(@"Legnth of combinedLicenseData is below or equal to zero (0)");

		return NO;
	}

	CFDataRef cfCombinedLicenseData = (__bridge CFDataRef)(combinedLicenseData);

	/* Setup transform function for verifying signature */
	SecTransformRef verifyFunction = SecVerifyTransformCreate(TLOLicenseManagerPublicKey, cfLicenseSignature, NULL);

	if (verifyFunction == NULL) {
		LogToConsole(@"Failed to create transform using SecVerifyTransformCreate()");

		return NO;
	}

	/* Setup transform attributes */
	if (SecTransformSetAttribute(verifyFunction, kSecTransformInputAttributeName, cfCombinedLicenseData, NULL)		== false ||
		SecTransformSetAttribute(verifyFunction, kSecDigestTypeAttribute, kSecDigestSHA2, NULL)						== false ||
		SecTransformSetAttribute(verifyFunction, kSecDigestLengthAttribute, (__bridge CFNumberRef)@(256), NULL)		== false)
	{
		CFRelease(verifyFunction);

		LogToConsole(@"Failed to modify transform attributes using SecTransformSetAttribute()");

		return NO;
	}

	/* Perform signature verification */
	CFTypeRef cfVerifyResult = SecTransformExecute(verifyFunction, NULL);

	CFRelease(verifyFunction);

	if (CFGetTypeID(cfVerifyResult) == CFBooleanGetTypeID()) {
		if (cfVerifyResult == kCFBooleanTrue) {
			return YES;
		}
	} else {
		LogToConsole(@"SecTransformExecute() returned a result that is not of type: CFBooleanRef");
	}

	return NO;
}

NSURL *TLOLicenseManagerUserLicenseFilePath(void)
{
	NSString *cachesFolder = [TPCPathInfo applicationLocalContainerApplicationSupportPath];

	if (cachesFolder == nil) {
		return nil;
	}

	NSString *dest = [cachesFolder stringByAppendingPathComponent:@"/Textual5UserLicense.plist"];

	return [NSURL fileURLWithPath:dest isDirectory:NO];
}

BOOL TLOLicenseManagerUserLicenseFileExists(void)
{
	NSURL *licenseFilePath = TLOLicenseManagerUserLicenseFilePath();

	if (licenseFilePath == nil) {
		return NO;
	} else {
		BOOL isDirectory = NO;

		BOOL fileExists = [RZFileManager() fileExistsAtPath:[licenseFilePath path] isDirectory:&isDirectory];

		return (fileExists && isDirectory == NO);
	}
}

NSData *TLOLicenseManagerUserLicenseFileContents(void)
{
	NSURL *licenseFilePath = TLOLicenseManagerUserLicenseFilePath();

	if (licenseFilePath == nil) {
		LogToConsole(@"Unable to determine the path to retrieve license information from.");

		return nil;
	}

	if (TLOLicenseManagerUserLicenseFileExists() == NO) {
		return nil;
	} else {
		NSError *readError = nil;

		NSData *licenseContents = [NSData dataWithContentsOfURL:licenseFilePath options:0 error:&readError];

		if (licenseContents == nil) {
			LogToConsole(@"Unable to read user license file. Error: %@", [readError localizedDescription]);

			return nil;
		} else {
			return licenseContents;
		}
	}
}

NSDictionary *TLOLicenseManagerLicenseDictionary(void)
{
	if (TLOLicenseManagerCachedLicenseDictionary == nil) {
		NSData *licenseContents = TLOLicenseManagerUserLicenseFileContents();

		NSDictionary *licenseDictionary = TLOLicenseManagerLicenseDictionaryWithData(licenseContents);

		TLOLicenseManagerCachedLicenseDictionary = [licenseDictionary copy];
	}

	return TLOLicenseManagerCachedLicenseDictionary;
}

NSDictionary *TLOLicenseManagerLicenseDictionaryWithData(NSData *licenseContents)
{
	/* The contents of the user license is /supposed/ to be a properly formatted
	 property list as sent from the license system hosted on www.codeux.com */
	
	if (licenseContents == nil) {
		return nil;
	} else {
		NSError *readError = nil;

		id licenseDictionary = [NSPropertyListSerialization propertyListWithData:licenseContents
																		 options:NSPropertyListImmutable
																		  format:NULL
																		   error:&readError];

		if (licenseDictionary == nil || [licenseDictionary isKindOfClass:[NSDictionary class]] == NO) {
			if (readError) {
				LogToConsole(@"Failed to convert contents of user license into dictionary. Error: %@", [readError localizedDescription]);
			}

			return nil;
		} else {
			return licenseDictionary;
		}
	}
}

void TLOLicenseManagerResetLicenseDictionaryCache(void)
{
	TLOLicenseManagerCachedLicenseDictionary = nil;
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
		TLOLicenseManagerPublicKeyIsGenuineResult = YES;
	} else {
		TLOLicenseManagerPublicKeyIsGenuineResult = NO;
	}

	return TLOLicenseManagerPublicKeyIsGenuineResult;
}

void TLOLicenseManagerMaybeDisplayPublicKeyIsGenuineDialog(void)
{
	/* TLOLicenseManagerMaybeDisplayPublicKeyIsGenuineDialog() is expected
	 to be called from the global queue to avoid overhead of hashing the
	 public key file, which means we have to present dialog on main thread. */
	BOOL publicKeyIsGenuine = TLOLicenseManagerPublicKeyIsGenuine();

	XRPerformBlockAsynchronouslyOnMainQueue(^{
		if (publicKeyIsGenuine) {
			BOOL userAction = [TLOPopupPrompts dialogWindowWithMessage:TXTLS(@"BasicLanguage[1274][2]")
																 title:TXTLS(@"BasicLanguage[1274][1]")
														 defaultButton:TXTLS(@"BasicLanguage[1186]")
													   alternateButton:TXTLS(@"BasicLanguage[1274][3]")
														suppressionKey:@"license_manager_public_key_is_not_genuine"
													   suppressionText:nil];

			if (userAction == NO) { // NO = secondary button ("View Source Code")
				[TLOpenLink openWithString:@"https://github.com/Codeux-Software/Textual"];
			}
		}
	});
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

NSString *TLOLicenseManagerLicenseOwnerName(void)
{
	NSDictionary *licenseDictionary = TLOLicenseManagerLicenseDictionary();

	if (licenseDictionary == nil) {
		return nil;
	} else {
		return licenseDictionary[TLOLicenseManagerLicenseDictionaryLicenseOwnerNameKey];
	}
}

NSString *TLOLicenseManagerLicenseOwnerContactAddress(void)
{
	NSDictionary *licenseDictionary = TLOLicenseManagerLicenseDictionary();

	if (licenseDictionary == nil) {
		return nil;
	} else {
		return licenseDictionary[TLOLicenseManagerLicenseDictionaryLicenseOwnerContactAddressKey];
	}
}

NSString *TLOLicenseManagerLicenseKey(void)
{
	NSDictionary *licenseDictionary = TLOLicenseManagerLicenseDictionary();

	if (licenseDictionary == nil) {
		return nil;
	} else {
		return licenseDictionary[TLOLicenseManagerLicenseDictionaryLicenseKeyKey];
	}}

NSString *TLOLicenseManagerLicenseActivationToken(void)
{
	NSDictionary *licenseDictionary = TLOLicenseManagerLicenseDictionary();

	if (licenseDictionary == nil) {
		return nil;
	} else {
		return licenseDictionary[TLOLicenseManagerLicenseDictionaryLicenseActivationTokenKey];
	}
}
#endif
