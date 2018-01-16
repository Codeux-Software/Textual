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

#import "NSObjectHelperPrivate.h"
#import "NSStringHelper.h"
#import "TXGlobalModels.h"
#import "TLOLanguagePreferences.h"
#import "TLOLicenseManagerPrivate.h"
#import "TLOLicenseManagerDownloaderPrivate.h"
#import "TLOPopupPrompts.h"
#import "TDCProgressIndicatorSheetPrivate.h"
#import "TDCLicenseUpgradeEligibilitySheetPrivate.h"

NS_ASSUME_NONNULL_BEGIN

#if TEXTUAL_BUILT_WITH_LICENSE_MANAGER == 1
@interface TDCLicenseUpgradeEligibilitySheet ()
@property (nonatomic, copy, readwrite) NSString *licenseKey;
@property (nonatomic, assign, readwrite) TLOLicenseUpgradeEligibility eligibility;
@property (nonatomic, strong) TLOLicenseManagerDownloader *licenseManagerDownloader;
@property (nonatomic, strong) TDCProgressIndicatorSheet *progressIndicator;
@property (nonatomic, strong) IBOutlet NSWindow *sheetNotEligible;
@property (nonatomic, strong) IBOutlet NSWindow *sheetEligibleDiscount;
@property (nonatomic, strong) IBOutlet NSWindow *sheetEligibleFree;
@property (nonatomic, assign) BOOL checkingEligibility;

- (IBAction)actionContactSupport:(id)sender;
- (IBAction)actionActivateLicense:(id)sender;
- (IBAction)actionPurchaseUpgrade:(id)sender;
- (IBAction)actionPurchaseStandalone:(id)sender;
- (IBAction)actionPurchaseMacAppStore:(id)sender;
- (IBAction)actionClose:(id)sender;
@end

@implementation TDCLicenseUpgradeEligibilitySheet

#pragma mark -
#pragma mark Dialog Foundation

ClassWithDesignatedInitializerInitMethod

- (instancetype)initWithLicenseKey:(NSString *)licenseKey
{
	NSParameterAssert(licenseKey != nil);

	if ((self = [super init])) {
		self.licenseKey = licenseKey;

		[self prepareInitialState];

		return self;
	}

	return self;
}

- (void)prepareInitialState
{
	(void)[RZMainBundle() loadNibNamed:@"TDCLicenseUpgradeEligibilitySheet" owner:self topLevelObjects:nil];

	self.eligibility = TLOLicenseUpgradeEligibilityUnknown;
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

#pragma mark -
#pragma mark Eligibility Sheet Actions

- (void)_presentEligibilityCheckFailedSheetWithError:(NSString *)errorMessage
{
	NSParameterAssert(errorMessage != nil);

	[TLOPopupPrompts sheetWindowWithWindow:self.window
									  body:TXTLS(@"TDCLicenseUpgradeEligibilitySheet[1001][2]", errorMessage)
									 title:TXTLS(@"TDCLicenseUpgradeEligibilitySheet[1001][1]", self.licenseKey.prettyLicenseKey)
							 defaultButton:TXTLS(@"Prompts[0005]")
						   alternateButton:TXTLS(@"TDCLicenseUpgradeEligibilitySheet[1001][3]")
							   otherButton:nil
						   completionBlock:^(TLOPopupPromptReturnType buttonClicked, NSAlert *originalAlert, BOOL suppressionResponse) {
							   if (buttonClicked == TLOPopupPromptReturnSecondaryType) {
								   [self actionContactSupport:nil];
							   }

							   [self endSheetEarly];
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
	if (self.eligibility != TLOLicenseUpgradeEligibilityUnknown) {
		[self _eligibilityDetermined];

		return;
	}

	[self _checkEligibilityOfLicense:self.licenseKey];
}

- (void)_checkEligibilityOfLicense:(NSString *)licenseKey
{
	NSParameterAssert(licenseKey != nil);

	if (self.checkingEligibility == NO) {
		self.checkingEligibility = YES;
	} else {
		return;
	}

	[self _beginProgressIndicator];

	__weak TDCLicenseUpgradeEligibilitySheet *weakSelf = self;

	TLOLicenseManagerDownloader *licenseManagerDownloader = [TLOLicenseManagerDownloader new];

	licenseManagerDownloader.completionBlock = ^(BOOL operationSuccessful, NSUInteger statusCode, id _Nullable statusContext) {
		[weakSelf _checkEligibilityCompletionBlock];

		[weakSelf _extractEligibilityFromResponseWithStatusCode:statusCode statusContext:statusContext];
	};

	licenseManagerDownloader.isSilentOnFailure = YES;
	licenseManagerDownloader.isSilentOnSuccess = YES;

	[licenseManagerDownloader checkUpgradeEligibilityOfLicense:licenseKey];

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
		NSString *errorMessage = nil;

		if (statusCode == TLOLicenseManagerDownloaderRequestStatusCodeTryAgainLater) {
			errorMessage = TXTLS(@"TDCLicenseUpgradeEligibilitySheet[1002][5]");
		} else {
			errorMessage = TXTLS(@"TDCLicenseUpgradeEligibilitySheet[1002][1]", statusCode);
		}

		_presentEligibilityCheckFailedSheet
	}

	/* There is never a time a status context should be nil for this check. */
	if (statusContext == nil) {
		NSString *errorMessage = TXTLS(@"TDCLicenseUpgradeEligibilitySheet[1002][2]");

		_presentEligibilityCheckFailedSheet
	}

	/* Ensure the response we received is a type we support. */
	id eligibilityObject = [statusContext objectForKey:@"licenseUpgradeEligibility"];

	if (eligibilityObject == nil || [eligibilityObject isKindOfClass:[NSNumber class]] == NO) {
		LogToConsoleError("'licenseUpgradeEligibility' is nil or not of kind 'NSNumber'");

		NSString *errorMessage = TXTLS(@"TDCLicenseUpgradeEligibilitySheet[1002][3]");

		_presentEligibilityCheckFailedSheet
	}

	/* Save eligibility */
	NSUInteger eligibility = [eligibilityObject unsignedIntegerValue];

	if (eligibility != TLOLicenseUpgradeEligibleDiscount &&
		eligibility != TLOLicenseUpgradeEligibleFree &&
		eligibility != TLOLicenseUpgradeNotEligible &&
		eligibility != TLOLicenseUpgradeAlreadyUpgraded)
	{
		NSString *errorMessage = TXTLS(@"TDCLicenseUpgradeEligibilitySheet[1002][4]", eligibility);

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
	if (self.eligibility == TLOLicenseUpgradeEligibleDiscount) {
		self.sheet = self.sheetEligibleDiscount;
	} else if (self.eligibility == TLOLicenseUpgradeNotEligible) {
		self.sheet = self.sheetNotEligible;
	} else if (self.eligibility == TLOLicenseUpgradeEligibleFree ||
			   self.eligibility == TLOLicenseUpgradeAlreadyUpgraded)
	{
		self.sheet = self.sheetEligibleFree;
	}

	[super startSheet];
}

- (void)actionContactSupport:(id)sender
{
	[self.delegate upgradeEligibilitySheetContactSupport:self];
}

- (void)actionActivateLicense:(id)sender
{
	[self.delegate upgradeEligibilitySheetActivateLicense:self];
}

- (void)actionPurchaseUpgrade:(id)sender
{
	[self.delegate upgradeEligibilitySheetPurchaseUpgrade:self];
}

- (void)actionPurchaseMacAppStore:(id)sender
{
	[self.delegate upgradeEligibilitySheetPurchaseMacAppStore:self];
}

- (void)actionPurchaseStandalone:(id)sender
{
	[self.delegate upgradeEligibilitySheetPurchaseStandalone:self];
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
