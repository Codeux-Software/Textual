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

static NSDictionary *TLOLicenseManagerCachedLicenseDictionary = nil;

NSString * const TLOLicenseManagerHashOfGenuinePublicKey = @"9d9a02f1f861a203aa761230c1ee02040002314502d75826a97a948bcf4bb1d6";

NSString * const TLOLicenseManagerLicenseKeyRegularExpression = @"^([a-z]{1,12})\\-([a-z]{1,12})\\-([a-z]{1,12})\\-([0-9]{1,35})$";

NSInteger const TLOLicenseManagerLicenseKeyExpectedLength = 45;

NSInteger const TLOLicenseManagerTrialModeMaximumLifespan = (-2592000); // 30 days in seconds

BOOL TLOLicenseManagerGenerateNewKeyPair(void);
BOOL TLOLicenseManagerLicenseDictionaryIsValid(NSDictionary *licenseDictionary);
BOOL TLOLicenseManagerPopulatePublicKeyRef(void);
void TLOLicenseManagerSetPublicKeyIsGenuine(void);
BOOL TLOLicenseManagerUserLicenseFileExists(void);
CFDataRef TLOLicenseManagerExportContentsOfKeyRef(SecKeyRef theKeyRef, BOOL isPublicKey);
NSData *TLOLicenseManagerPublicKeyContents(void);
NSData *TLOLicenseManagerUserLicenseFileContents(void);
NSDictionary *TLOLicenseManagerLicenseDictionary(void);
NSDictionary *TLOLicenseManagerLicenseDictionaryWithData(NSData *licenseContents);
NSURL *TLOLicenseManagerTrialModeInformationFilePath(void);
NSURL *TLOLicenseManagerUserLicenseFilePath(void);

NSString * const TLOLicenseManagerLicenseDictionaryLicenseCreationDateKey			= @"licenseCreationDate";
NSString * const TLOLicenseManagerLicenseDictionaryLicenseKeyKey					= @"licenseKey";
NSString * const TLOLicenseManagerLicenseDictionaryLicenseProductNameKey			= @"licenseProductName";
NSString * const TLOLicenseManagerLicenseDictionaryLicenseOwnerContactAddressKey	= @"licenseOwnerContactAddress";
NSString * const TLOLicenseManagerLicenseDictionaryLicenseOwnerNameKey				= @"licenseOwnerName";
NSString * const TLOLicenseManagerLicenseDictionaryLicenseSignatureKey				= @"licenseSignature";

#define _includePublicKeyGenerator				0
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
			TLOLicenseManagerSetPublicKeyIsGenuine();
		});
	}
}

#pragma mark -
#pragma mark Trial Mode

BOOL TLOLicenseManagerTextualIsRegistered(void)
{
	if (TLOLicenseManagerPublicKeyIsGenuineResult == NO) {
		return NO;
	} else if (TLOLicenseManagerUserLicenseFileExists() == NO) {
		return NO;
	} else {
		NSDictionary *licenseDictionary = TLOLicenseManagerLicenseDictionary();

		return NSDissimilarObjects(licenseDictionary, nil);
	}
}

BOOL TLOLicenseManagerIsTrialExpired(void)
{
	NSTimeInterval timeLeft = TLOLicenseManagerTimeReaminingInTrial();

	return (timeLeft == 0);
}

NSTimeInterval TLOLicenseManagerTimeReaminingInTrial(void)
{
	/* Determine where trial information will be stored on disk. */
	NSURL *trialInformationFilePath = TLOLicenseManagerTrialModeInformationFilePath();

	if (trialInformationFilePath == nil) {
		return 0;
	}

	/* If the trial information file does not exist yet, then create a new
	 one which will define when the trial period began. */
	/* NSPropertyListSerialization is used by this function, in place of the built
	 in NSData read & write methods, for better error reporting. */
	if ([RZFileManager() fileExistsAtPath:[trialInformationFilePath path]] == NO)
	{
		NSDictionary *trialInformation = @{
			@"trialPeriodStartDate" : [NSDate date]
		};

		NSError *trialInformationPropertyListError = nil;

		NSData *trialInformationPropertyList =
		[NSPropertyListSerialization dataWithPropertyList:trialInformation
												   format:NSPropertyListBinaryFormat_v1_0
												  options:0
													error:&trialInformationPropertyListError];

		if (trialInformationPropertyList == nil) {
			LogToConsole(@"Failed to create trial information property list: %@", [trialInformationPropertyListError localizedDescription]);

			return 0; // Cannot continue function...
		}

		NSError *trialInformationWriteError = nil;

		if ([trialInformationPropertyList writeToURL:trialInformationFilePath options:NSDataWritingAtomic error:&trialInformationWriteError] == NO) {
			LogToConsole(@"Failed to write trial information to disk: %@", trialInformationWriteError);

			return 0; // Cannot continue function...
		}

		NSError *modifyTrialInformationAttributesError = nil;

		if ([trialInformationFilePath setResourceValue:@(YES) forKey:NSURLIsHiddenKey error:&modifyTrialInformationAttributesError] == NO) {
			LogToConsole(@"Failed to modify attributes of trial information file: %@", [modifyTrialInformationAttributesError localizedDescription]);
			
			return 0; // Cannot continue function...
		}

		NSError *lockTrialInformationFileError = nil;

		if ([RZFileManager() lockItemAtPath:[trialInformationFilePath path] error:&lockTrialInformationFileError] == NO) {
			LogToConsole(@"Failed to lock the trial information file: %@", lockTrialInformationFileError);

			return 0; // Cannot continue function...
		}
	}

	/* Read trial information from disk. */
	NSError *trialInformationDataReadError = nil;

	NSData *trialInformationData = [NSData dataWithContentsOfURL:trialInformationFilePath options:0 error:&trialInformationDataReadError];

	if (trialInformationData == nil) {
		LogToConsole(@"Failed to read contents of trial information file: %@", [trialInformationDataReadError localizedDescription]);

		return 0; // Cannot continue function...
	}

	NSError *trialInformationPropertyListError = nil;

	NSDictionary *trialInformation =
	[NSPropertyListSerialization propertyListWithData:trialInformationData
											  options:NSPropertyListImmutable
											   format:NULL
												error:&trialInformationPropertyListError];

	if (trialInformation == nil) {
		LogToConsole(@"Failed to convert property list to NSDictionary: %@", [trialInformationPropertyListError localizedDescription]);

		return 0; // Cannot continue function...
	}

	/* Given dictionary, get start date of trial and return time left. */
	NSDate *trialPeriodStartDate = trialInformation[@"trialPeriodStartDate"];

	if (trialPeriodStartDate == nil || [trialPeriodStartDate isKindOfClass:[NSDate class]] == NO) {
		LogToConsole(@"The value of 'trialPeriodStartDate' is nil or not of kind 'NSDate'");

		return 0; // Cannot continue function...
	}

	/* trialPeriodStartInterval will be negative because it is in the past. */
	NSTimeInterval trialPeriodStartInterval = [trialPeriodStartDate timeIntervalSinceNow];

	if (trialPeriodStartInterval > 0) {
		/* Return expired date for those who try to be clever by setting future time. */

		return 0;
	} else if (trialPeriodStartInterval < TLOLicenseManagerTrialModeMaximumLifespan) {
		return 0;
	} else {
		return (TLOLicenseManagerTrialModeMaximumLifespan - trialPeriodStartInterval);
	}
}

NSURL *TLOLicenseManagerTrialModeInformationFilePath(void)
{
	NSString *cachesFolder = [TPCPathInfo applicationLocalContainerApplicationSupportPath];

	if (cachesFolder == nil) {
		return nil;
	}

	NSString *dest = [cachesFolder stringByAppendingPathComponent:@"/Textual_Trial_Information.plist"];

	return [NSURL fileURLWithPath:dest isDirectory:NO];
}

#pragma mark -
#pragma mark User License File Validation

BOOL TLOLicenseManagerLicenseKeyIsValid(NSString *licenseKey)
{
	if (NSObjectIsEmpty(licenseKey)) {
		return NO;
	}

	if ([licenseKey length] != TLOLicenseManagerLicenseKeyExpectedLength) {
		return NO;
	}

	if ([XRRegularExpression string:licenseKey isMatchedByRegex:TLOLicenseManagerLicenseKeyRegularExpression withoutCase:YES] == NO) {
		return NO;
	} else {
		return YES;
	}
}

BOOL TLOLicenseManagerLicenseDictionaryIsValid(NSDictionary *licenseDictionary)
{
	if (licenseDictionary == nil) {
		return NO;
	}

	if (licenseDictionary[TLOLicenseManagerLicenseDictionaryLicenseProductNameKey] == nil ||
		licenseDictionary[TLOLicenseManagerLicenseDictionaryLicenseCreationDateKey] == nil ||
		licenseDictionary[TLOLicenseManagerLicenseDictionaryLicenseSignatureKey] == nil)
	{
		return NO;
	}

	NSString *licenseKey = licenseDictionary[TLOLicenseManagerLicenseDictionaryLicenseKeyKey];

	if (TLOLicenseManagerLicenseKeyIsValid(licenseKey) == NO) {
		return NO;
	}

	return YES;
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
	NSData *licenseSignature = licenseDictionary[TLOLicenseManagerLicenseDictionaryLicenseSignatureKey];

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

#pragma mark -
#pragma mark Reading & Writing User License File

NSURL *TLOLicenseManagerUserLicenseFilePath(void)
{
	NSString *cachesFolder = [TPCPathInfo applicationLocalContainerApplicationSupportPath];

	if (cachesFolder == nil) {
		return nil;
	}

	NSString *dest = [cachesFolder stringByAppendingPathComponent:@"/Textual_User_License.plist"];

	return [NSURL fileURLWithPath:dest isDirectory:NO];
}

BOOL TLOLicenseManagerDeleteUserLicenseFile(void)
{
	return TLOLicenseManagerUserLicenseWriteFileContents(nil);
}

BOOL TLOLicenseManagerUserLicenseWriteFileContents(NSData *newContents)
{
	NSURL *licenseFilePath = TLOLicenseManagerUserLicenseFilePath();

	NSDictionary *licenseDictionary = nil;

	if (newContents) {
		NSDictionary *ls_licenseDictionary = TLOLicenseManagerLicenseDictionaryWithData(newContents);

		if (TLOLicenseManagerVerifyLicenseSignatureWithDictionary(ls_licenseDictionary) == NO) {
			LogToConsole(@"Verify for new license file contents failed");

			return NO;
		} else {
			licenseDictionary = ls_licenseDictionary;
		}
	}

	if (TLOLicenseManagerUserLicenseFileExists()) {
		NSError *deleteError = nil;

		if ([RZFileManager() removeItemAtURL:licenseFilePath error:&deleteError] == NO) {
			LogToConsole(@"Failed to delete user license file with error: %@", [deleteError localizedDescription]);

			return NO;
		}
	}

	if (newContents == nil) {
		TLOLicenseManagerCachedLicenseDictionary = nil;

		return YES;
	}

	NSError *writeFileError = nil;

	if ([newContents writeToURL:licenseFilePath options:NSDataWritingAtomic error:&writeFileError] == NO) {
		LogToConsole(@"Failed to write user license file with error: %@", [writeFileError localizedDescription]);

		return NO;
	} else {
		TLOLicenseManagerCachedLicenseDictionary = [licenseDictionary copy];

		return YES;
	}
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

		if (TLOLicenseManagerVerifyLicenseSignatureWithDictionary(licenseDictionary) == NO) {
			/* TLOLicenseManagerLicenseDictionary() is called during menu validation the exact moment
			 Textual is launched. This occurs before the license manager has been setup which means
			 this console message is spammed a few dozen times because its called for each menu item. 
			 This is an easy fix that only displays this warning after Textual has been open for at 
			 least a period of 5 seconds. 
			 
			 This console message can be potentially helpful in diagnosing problems for the end user
			 which means this is the solution instead of removing it. */
			if ([TPCApplicationInfo timeIntervalSinceApplicationLaunch] > 5) {
				LogToConsole(@"Cannot load license dictionary because it did not pass validation");
			}

			return nil;
		}

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

#pragma mark -
#pragma mark Public Key Access

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

void TLOLicenseManagerSetPublicKeyIsGenuine(void)
{
	NSData *publicKeyContents = TLOLicenseManagerPublicKeyContents();

	if (publicKeyContents == nil) {
		return;
	}

	NSString *actualPublicKeyHash = [publicKeyContents sha256];

	if (NSObjectsAreEqual(TLOLicenseManagerHashOfGenuinePublicKey, actualPublicKeyHash)) {
		TLOLicenseManagerPublicKeyIsGenuineResult = YES;
	} else {
		TLOLicenseManagerPublicKeyIsGenuineResult = NO;
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
		LogToConsole(@"SecItemImport() failed to import public key with status code: %i", operationStatus);

		return NO;
	}
}

#pragma mark -
#pragma mark License File Signature Key Generator

#if _includePublicKeyGenerator == 1
BOOL TLOLicenseManagerGenerateNewKeyPair(void)
{
	const int _generatedKeyPairKeySize =		4096;

	CFNumberRef keyBitSizeNum = CFNumberCreate(kCFAllocatorDefault, kCFNumberIntType, &_generatedKeyPairKeySize);

	CFMutableDictionaryRef parameters = CFDictionaryCreateMutable(kCFAllocatorDefault,
																  0,
																  &kCFTypeDictionaryKeyCallBacks,
																  &kCFTypeDictionaryValueCallBacks);

	CFDictionarySetValue(parameters, kSecAttrKeyType, kSecAttrKeyTypeRSA);

	CFDictionarySetValue(parameters, kSecAttrKeySizeInBits, keyBitSizeNum);

	SecKeyRef publicKeyRef = NULL;
	SecKeyRef privateKeyRef = NULL;

	OSStatus operationStatus = SecKeyGeneratePair(parameters, &publicKeyRef, &privateKeyRef);

	if (operationStatus == noErr) {
		CFDataRef publicKeyData = TLOLicenseManagerExportContentsOfKeyRef(publicKeyRef, YES);
		CFDataRef privateKeyData = TLOLicenseManagerExportContentsOfKeyRef(privateKeyRef, NO);

		NSString *publicKeyString = [NSString stringWithData:(__bridge NSData *)(publicKeyData) encoding:NSASCIIStringEncoding];
		NSString *privateKeyString = [NSString stringWithData:(__bridge NSData *)(privateKeyData) encoding:NSASCIIStringEncoding];

		// Insert breakpoint here...

#pragma unused(publicKeyString)
#pragma unused(privateKeyString)

		return YES;
	} else {
		LogToConsole(@"SecKeyGeneratePair() failed to generate key pair with status code: %i", operationStatus);

		return NO;
	}
}

CFDataRef TLOLicenseManagerExportContentsOfKeyRef(SecKeyRef theKeyRef, BOOL isPublicKey)
{
	if (theKeyRef == NULL) {
		return NULL;
	}

	SecItemImportExportKeyParameters exportParameters;

	exportParameters.version = SEC_KEY_IMPORT_EXPORT_PARAMS_VERSION;
	exportParameters.flags = 0;

	exportParameters.passphrase = NULL;
	exportParameters.alertTitle = NULL;
	exportParameters.alertPrompt = NULL;
	exportParameters.accessRef = NULL;

	CFMutableArrayRef keyUsage = CFArrayCreateMutable(kCFAllocatorDefault, 0, &kCFTypeArrayCallBacks);

	if (isPublicKey) {
		CFArrayAppendValue(keyUsage, kSecAttrCanDecrypt);
		CFArrayAppendValue(keyUsage, kSecAttrCanVerify);
	} else {
		CFArrayAppendValue(keyUsage, kSecAttrCanSign);
	}

	CFMutableArrayRef keyAttributes = CFArrayCreateMutable(kCFAllocatorDefault, 0, &kCFTypeArrayCallBacks);

	exportParameters.keyUsage = keyUsage;
	exportParameters.keyAttributes = keyAttributes;

	SecExternalFormat externalFormat = kSecFormatPEMSequence;

	int flags = 0;

	CFDataRef pkdata = NULL;

	OSStatus operationStatus = SecItemExport(theKeyRef, externalFormat,flags, &exportParameters, &pkdata);

	if (operationStatus == noErr) {
		return pkdata;
	} else {
		LogToConsole(@"SecItemExport() failed to export key contents with status code: %i", operationStatus);

		return NULL;
	}
}
#endif

#pragma mark -
#pragma mark User License File Information

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
	}
}

NSString *TLOLicenseManagerLicenseCreationDate(void)
{
	NSDictionary *licenseDictionary = TLOLicenseManagerLicenseDictionary();

	if (licenseDictionary == nil) {
		return nil;
	} else {
		return licenseDictionary[TLOLicenseManagerLicenseDictionaryLicenseCreationDateKey];
	}
}

NSString *TLOLicenseManagerLicenseCreationDateFormatted(void)
{
	NSString *creationDateString = TLOLicenseManagerLicenseCreationDate();

	if (creationDateString == nil) {
		return nil;
	}

	NSDateFormatter *dateFormatter = [NSDateFormatter new];

	[dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];

	NSDate *creationDate = [dateFormatter dateFromString:creationDateString];

	NSString *formattedCreationDate = nil;

	if (creationDate == nil) {
		formattedCreationDate = creationDateString;
	} else {
		[dateFormatter setDateFormat:nil];

		[dateFormatter setDoesRelativeDateFormatting:YES];

		[dateFormatter setDateStyle:NSDateFormatterLongStyle];
		[dateFormatter setTimeStyle:NSDateFormatterNoStyle];

		formattedCreationDate = [dateFormatter stringFromDate:creationDate];
	}

	return formattedCreationDate;
}

#endif
