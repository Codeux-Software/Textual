/* ********************************************************************* 
                  _____         _               _
                 |_   _|____  _| |_ _   _  __ _| |
                   | |/ _ \ \/ / __| | | |/ _` | |
                   | |  __/>  <| |_| |_| | (_| | |
                   |_|\___/_/\_\\__|\__,_|\__,_|_|

 Copyright (c) 2010 - 2017 Codeux Software, LLC & respective contributors.
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

#import "TPCPathInfo.h"
#import "TLOLanguagePreferences.h"
#import "TLOLicenseManagerDownloaderPrivate.h"
#import "TLOPopupPrompts.h"
#import "TDCProgressIndicatorSheetPrivate.h"
#import "TDCInAppPurchaseUpgradeEligibilitySheetPrivate.h"

NS_ASSUME_NONNULL_BEGIN

#if TEXTUAL_BUILT_FOR_APP_STORE_DISTRIBUTION == 1
@interface TDCInAppPurchaseUpgradeEligibilitySheet ()
@property (nonatomic, assign, readwrite) TLOInAppPurchaseUpgradeEligibility eligibility;
@property (nonatomic, strong) TLOLicenseManagerDownloader *licenseManagerDownloader;
@property (nonatomic, strong) TDCProgressIndicatorSheet *progressIndicator;
@property (nonatomic, strong) IBOutlet NSWindow *sheetNotEligible;
@property (nonatomic, strong) IBOutlet NSWindow *sheetEligibleDiscount;
@property (nonatomic, strong) IBOutlet NSWindow *sheetEligibleFree;
@property (nonatomic, assign) BOOL checkingEligibility;

- (IBAction)actionClose:(id)sender;
@end

@implementation TDCInAppPurchaseUpgradeEligibilitySheet

#pragma mark -
#pragma mark Dialog Foundation

- (instancetype)initWithWindow:(NSWindow *)window
{
	if ((self = [super initWithWindow:window])) {
		[self prepareInitialState];

		return self;
	}

	return self;
}

- (void)prepareInitialState
{
	(void)[RZMainBundle() loadNibNamed:@"TDCInAppPurchaseUpgradeEligibilitySheet" owner:self topLevelObjects:nil];

	self.eligibility = TLOInAppPurchaseUpgradeEligibilityUnknown;
}

- (void)startSheet
{
	LogToConsoleError("This method does nothing. Use -checkEligibility instead.");
	LogToConsoleCurrentStackTrace
}

- (void)endSheet
{
	[self _cancelEligibilityCheck];

	[super endSheet];
}

- (void)endSheetEarly
{
	/* If we end sheet early, before self.sheet is ever defined,
	 then trying to close it wont fire this delegate call.
	 We fake the call to the delegate so that the sheet can be released. */
	[self windowWillClose:nil];
}

- (void)checkEligibility
{
	[self _checkEligibility];
}

#pragma mark -
#pragma mark Utilities

- (void)_beginProgressIndicator
{
	[self _beginProgressIndicatorInWindow:self.window];
}

- (void)_beginProgressIndicatorInWindow:(NSWindow *)window
{
	self.progressIndicator = [[TDCProgressIndicatorSheet alloc] initWithWindow:window];

	[self.progressIndicator start];
}

- (void)_endProgressIndicator
{
	if (self.progressIndicator == nil) {
		return;
	}

	[self.progressIndicator stop];

	self.progressIndicator = nil;
}

/* The next two methods were copy and pasted from TDCLicenseManagerMigrateAppStoreSheet */
/* Should probably merge these files one day. */
- (nullable NSString *)receiptDataForApplicationAtURL:(NSURL *)applicationURL
{
	NSParameterAssert(applicationURL != nil);

	/* Locate application bundle and determine whether the receipt
	 file is even contained within it. */
	NSBundle *applicationBundle = [NSBundle bundleWithURL:applicationURL];

	if (applicationBundle == nil) {
		return nil;
	}

	NSURL *receiptFileURL = applicationBundle.appStoreReceiptURL;

	if (receiptFileURL == nil) {
		return nil;
	}

	if ([RZFileManager() fileExistsAtURL:receiptFileURL] == NO) {
		return nil;
	}

	/* If the receipt file exists, request the data and cache the base64
	 value of the receipt data. */
	NSError *receiptDataReadError = nil;

	NSData *receiptData = [NSData dataWithContentsOfURL:receiptFileURL options:0 error:&receiptDataReadError];

	if (receiptData == nil) {
		LogToConsoleError("Failed to read the contents of the receipt file: %{public}@",
		  receiptDataReadError.localizedDescription);

		return nil;
	}

	return [XRBase64Encoding encodeData:receiptData];
}

- (BOOL)canUseApplicationAtURL:(NSURL *)applicationURL applicationName:(NSString * _Nullable * _Nullable)applicationName
{
	/* The license API performs validation of the uploaded receipt which
	 means that the the only thing we need to know at this point is that
	 the bundlen identifier of the application is a known value and that
	 the receipt file actually does exist in the application. */
	NSBundle *applicationBundle = [NSBundle bundleWithURL:applicationURL];

	if (applicationBundle == nil) {
		return NO;
	}

	/* Pass to caller the application name of the bundle. */
	if ( applicationName) {
		*applicationName = applicationBundle.displayName;
	}

	/* Compare bundle identifier. */
	/* The bundle identifier used for comparison is hard coded is because
	 the bundle identifier for the running copy can be different than the
	 value that we are expecting from an older copy which we cannot change. */
	NSString *applicationBundleID = [applicationBundle objectForInfoDictionaryKey:@"CFBundleIdentifier"];

	if (NSObjectsAreEqual(applicationBundleID, @"com.codeux.irc.textual5") == NO) {
		return NO;
	}

	/* Determine whether a receipt file exists. */
	NSURL *receiptFileURL = applicationBundle.appStoreReceiptURL;

	if (receiptFileURL == nil) {
		return NO;
	}

	if ([RZFileManager() fileExistsAtURL:receiptFileURL] == NO) {
		return NO;
	}

	/* Return successful result */
	return YES;
}

#pragma mark -
#pragma mark Open Dialog

- (BOOL)panel:(id)sender validateURL:(NSURL *)url error:(NSError **)outError
{
	NSString *applicationName = nil;

	if ([self canUseApplicationAtURL:url applicationName:&applicationName] == NO) {
		if (outError) {
			NSMutableDictionary *userInfo = [NSMutableDictionary dictionary];

			userInfo[NSURLErrorKey] = url;

			userInfo[NSLocalizedDescriptionKey] = TXTLS(@"TDCInAppPurchaseUpgradeEligibilitySheet[1002][1]", applicationName);

			userInfo[NSLocalizedRecoverySuggestionErrorKey] = TXTLS(@"TDCInAppPurchaseUpgradeEligibilitySheet[1002][2]");

			*outError = [NSError errorWithDomain:TXErrorDomain code:29852 userInfo:userInfo];
		}

		return NO;
	}

	return YES;
}

- (void)_presentOpenDialog
{
	NSOpenPanel *d = [NSOpenPanel openPanel];

	NSURL *applicationsPath = [TPCPathInfo systemApplicationsURL];

	if (applicationsPath) {
		d.directoryURL = applicationsPath;
	}

	d.allowedFileTypes = @[@"app"];

	d.delegate = (id)self;

	d.allowsMultipleSelection = NO;
	d.canChooseDirectories = NO;
	d.canChooseFiles = YES;
	d.canCreateDirectories = NO;
	d.resolvesAliases = YES;

	d.message = TXTLS(@"TDCInAppPurchaseUpgradeEligibilitySheet[1001]");

	d.prompt = TXTLS(@"Prompts[0006]");

	[d beginSheetModalForWindow:self.window completionHandler:^(NSInteger result) {
		if (result == NSModalResponseOK) {
			[self _checkEligibilityOfApplicationAtURL:d.URL];
		} else {
			[self endSheetEarly];
		}
	}];
}

#pragma mark -
#pragma mark Eligibility Sheet Actions

- (void)_presentEligibilityCheckFailedSheetWithError:(NSString *)errorMessage
{
	NSParameterAssert(errorMessage != nil);

	[TLOPopupPrompts sheetWindowWithWindow:self.window
									  body:TXTLS(@"TDCInAppPurchaseUpgradeEligibilitySheet[1003][2]", errorMessage)
									 title:TXTLS(@"TDCInAppPurchaseUpgradeEligibilitySheet[1003][1]")
							 defaultButton:TXTLS(@"Prompts[0005]")
						   alternateButton:TXTLS(@"TDCInAppPurchaseUpgradeEligibilitySheet[1003][3]")
							   otherButton:nil
						   completionBlock:^(TLOPopupPromptReturnType buttonClicked, NSAlert *originalAlert, BOOL suppressionResponse) {
							   if (buttonClicked == TLOPopupPromptReturnSecondaryType) {
								   [self actionContactSupport:nil];
							   }

							   [self windowWillClose:nil];
						   }];
}

- (void)_presentReceiptFailedValidationSheet
{
	[TLOPopupPrompts sheetWindowWithWindow:self.window
									  body:TXTLS(@"TDCInAppPurchaseUpgradeEligibilitySheet[1004][2]")
									 title:TXTLS(@"TDCInAppPurchaseUpgradeEligibilitySheet[1004][1]")
							 defaultButton:TXTLS(@"Prompts[0005]")
						   alternateButton:TXTLS(@"TDCInAppPurchaseUpgradeEligibilitySheet[1004][3]")
							   otherButton:nil
						   completionBlock:^(TLOPopupPromptReturnType buttonClicked, NSAlert *originalAlert, BOOL suppressionResponse) {
							   if (buttonClicked == TLOPopupPromptReturnSecondaryType) {
								   [self actionContactSupport:nil];
							   }

							   [self windowWillClose:nil];
						   }];
}

- (void)_cancelEligibilityCheck
{
	if (self.checkingEligibility == NO) {
		return;
	}

	[self.licenseManagerDownloader cancelRequest];

	[self _checkEligibilityCompletionBlock];
}

- (void)_checkEligibility
{
	if (self.eligibility != TLOInAppPurchaseUpgradeEligibilityUnknown) {
		[self _eligibilityDetermined];

		return;
	}

	[self _presentOpenDialog];
}

- (void)_checkEligibilityOfApplicationAtURL:(NSURL *)applicationURL
{
	NSParameterAssert(applicationURL != nil);

	if (self.checkingEligibility == NO) {
		self.checkingEligibility = YES;
	} else {
		return;
	}

	/* Get receipt contents */
	NSString *receiptData = [self receiptDataForApplicationAtURL:applicationURL];

	if (receiptData == nil) {
		NSString *errorMessage = TXTLS(@"TDCInAppPurchaseUpgradeEligibilitySheet[1004][5]");

		[self _presentEligibilityCheckFailedSheetWithError:errorMessage];

		return;
	}

	/* Indicate progress to end user */
	[self _beginProgressIndicator];

	/* Check eligibility */
	__weak TDCInAppPurchaseUpgradeEligibilitySheet *weakSelf = self;

	TLOLicenseManagerDownloader *licenseManagerDownloader = [TLOLicenseManagerDownloader new];

	licenseManagerDownloader.completionBlock = ^(BOOL operationSuccessful, NSUInteger statusCode, id _Nullable statusContext) {
		[weakSelf _checkEligibilityCompletionBlock];

		[weakSelf _extractEligibilityFromResponseWithStatusCode:statusCode statusContext:statusContext];
	};

	licenseManagerDownloader.isSilentOnFailure = YES;
	licenseManagerDownloader.isSilentOnSuccess = YES;

	[licenseManagerDownloader checkUpgradeEligibilityOfReceipt:receiptData];

	self.licenseManagerDownloader = licenseManagerDownloader;
}

- (void)_checkEligibilityCompletionBlock
{
	self.licenseManagerDownloader = nil;

	[self _endProgressIndicator];

	self.checkingEligibility = NO;
}

- (void)_extractEligibilityFromResponseWithStatusCode:(NSUInteger)statusCode statusContext:(nullable NSDictionary<NSString *, id> *)statusContext
{
	LogToConsoleDebug("Status code: %ld", statusCode);

#define _presentEligibilityCheckFailedSheet 	\
	[self _presentEligibilityCheckFailedSheetWithError:errorMessage]; 	\
	return;

	/* Check for common status codes. */
	if (statusCode != 0) {
		/* We want to give the user the best chance to upgrade, so if the
		 response fails because the receipt itself is invalid (maybe they
		 copied it), then we give them the option to get a new one. */
		if (statusCode == 6700002 || // Validation failure
			statusCode == 6700003)   // Bad bundle ID
		{
			[self _presentReceiptFailedValidationSheet];

			return;
		}

		NSString *errorMessage = nil;

		if (statusCode == TLOLicenseManagerDownloaderRequestStatusCodeTryAgainLater) {
			errorMessage = TXTLS(@"TDCInAppPurchaseUpgradeEligibilitySheet[1005][6]");
		} else {
			errorMessage = TXTLS(@"TDCInAppPurchaseUpgradeEligibilitySheet[1005][1]", statusCode);
		}

		_presentEligibilityCheckFailedSheet
	}

	/* There is never a time a status context should be nil for this check. */
	if (statusContext == nil) {
		NSString *errorMessage = TXTLS(@"TDCInAppPurchaseUpgradeEligibilitySheet[1005][2]");

		_presentEligibilityCheckFailedSheet
	}

	/* Ensure the response we received is a type we support. */
	id eligibilityObject = [statusContext objectForKey:@"receiptUpgradeEligibility"];

	if (eligibilityObject == nil || [eligibilityObject isKindOfClass:[NSNumber class]] == NO) {
		LogToConsoleError("'receiptUpgradeEligibility' is nil or not of kind 'NSNumber'");

		NSString *errorMessage = TXTLS(@"TDCInAppPurchaseUpgradeEligibilitySheet[1005][3]");

		_presentEligibilityCheckFailedSheet
	}

	/* Save eligibility */
	NSUInteger eligibility = [eligibilityObject unsignedIntegerValue];

	if (eligibility != TLOInAppPurchaseUpgradeEligibleDiscount &&
		eligibility != TLOInAppPurchaseUpgradeEligibleFree &&
		eligibility != TLOInAppPurchaseUpgradeNotEligible &&
		eligibility != TLOInAppPurchaseUpgradeAlreadyUpgraded)
	{
		NSString *errorMessage = TXTLS(@"TDCInAppPurchaseUpgradeEligibilitySheet[1005][4]", eligibility);

		_presentEligibilityCheckFailedSheet
	}

	self.eligibility = eligibility;

	/* Present sheet */
	[self _eligibilityDetermined];

	/* Inform delegate */
	[self.delegate upgradeEligibilitySheetChanged:self];

#undef _presentEligibilityCheckFailedSheet
}

- (void)_eligibilityDetermined
{
	if (self.eligibility == TLOInAppPurchaseUpgradeEligibleDiscount) {
		self.sheet = self.sheetEligibleDiscount;
	} else if (self.eligibility == TLOInAppPurchaseUpgradeNotEligible) {
		self.sheet = self.sheetNotEligible;
	} else if (self.eligibility == TLOInAppPurchaseUpgradeEligibleFree ||
			   self.eligibility == TLOInAppPurchaseUpgradeAlreadyUpgraded)
	{
		self.sheet = self.sheetEligibleFree;
	}

	[super startSheet];
}

- (void)actionContactSupport:(id)sender
{
	[self.delegate upgradeEligibilitySheetContactSupport:self];
}

- (void)actionClose:(id)sender
{
	[self endSheet];
}

#pragma mark -
#pragma mark NSWindow Delegate

- (void)windowWillClose:(NSNotification *)note
{
	[self.delegate upgradeEligibilitySheetWillClose:self];
}

@end
#endif

NS_ASSUME_NONNULL_END
