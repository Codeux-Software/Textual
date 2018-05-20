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

#if TEXTUAL_BUILT_FOR_APP_STORE_DISTRIBUTION == 1
#import "BuildConfig.h"

#import "ARLReceiptLoader.h"
#import "TLOAppStoreManagerPrivate.h"

NS_ASSUME_NONNULL_BEGIN

#pragma mark -
#pragma mark Private Implementation

NSString * const TLOAppStoreIAPFreeTrialProductIdentifier			= @"com.codeux.iap.textual_free_trial";
NSString * const TLOAppStoreIAPStandardEditionProductIdentifier		= @"com.codeux.iap.textual_standard_edition";
NSString * const TLOAppStoreIAPUpgradeFromV6ProductIdentifier		= @"com.codeux.iap.textual_upgrade_v6";
NSString * const TLOAppStoreIAPUpgradeFromV6FreeProductIdentifier	= @"com.codeux.iap.textual_upgrade_v6_free";

NSInteger const TLOAppStoreTrialModeMaximumLifespan = (-2592000); // 30 days in seconds

static ARLReceiptContents *TLOAppStoreReceiptContents = nil;

BOOL TLOAppStoreIsOneProductPurchased(NSArray<NSString *> *productIdentifiers);
BOOL TLOAppStoreIsProductPurchased(NSString *productIdentifier);
ARLInAppPurchaseContents * _Nullable TLOAppStorePurchasedProductDetails(NSString *productIdentifier);

#pragma mark -
#pragma mark Implementation

BOOL TLOAppStoreLoadReceipt(void)
{
	ARLReceiptContents *receiptContents = nil;

	BOOL loadSuccessful = ARLReadReceiptFromBundle(RZMainBundle(), &receiptContents);

	if (loadSuccessful == NO) {
		LogToConsoleError("Failed to laod receipt contents: %@", ARLLastErrorMessage());

		TLOAppStoreReceiptContents = nil;

		return NO;
	}

	if ([TXBundleBuildProductIdentifier isEqualToString:receiptContents.bundleIdentifier] == NO) {
		LogToConsoleError("Mismatched bundle identifier");

		TLOAppStoreReceiptContents = nil;

		return NO;
	}

	TLOAppStoreReceiptContents = receiptContents;

	return YES;
}

BOOL TLOAppStoreReceiptLoaded(void)
{
	return (TLOAppStoreReceiptContents != nil);
}

ARLReceiptContents * _Nullable TLOAppStoreReceipt(void)
{
	return TLOAppStoreReceiptContents;
}

#pragma mark -
#pragma mark Products

NSArray<NSString *> *TLOAppStorePurchasedProducts(void)
{
	ARLReceiptContents *receipt = TLOAppStoreReceipt();
	
	if (receipt == nil) {
		return @[];
	}
	
	return receipt.inAppPurchases.allKeys;
}

NSUInteger TLOAppStoreNumberOfPurchasedProducts(void)
{
	return TLOAppStorePurchasedProducts().count;
}

BOOL TLOAppStoreIsOneProductPurchased(NSArray<NSString *> *productIdentifiers)
{
	NSCParameterAssert(productIdentifiers != nil);

	ARLReceiptContents *receipt = TLOAppStoreReceipt();

	if (receipt == nil) {
		return NO;
	}

	NSArray *purchasedProducts = receipt.inAppPurchases.allKeys;

	for (NSString *productIdentifier in productIdentifiers) {
		if ([purchasedProducts containsObject:productIdentifier]) {
			return YES;
		}
	}

	return NO;
}

BOOL TLOAppStoreIsProductPurchased(NSString *productIdentifier)
{
	NSCParameterAssert(productIdentifier != nil);

	return (TLOAppStorePurchasedProductDetails(productIdentifier) != nil);
}

ARLInAppPurchaseContents * _Nullable TLOAppStorePurchasedProductDetails(NSString *productIdentifier)
{
	NSCParameterAssert(productIdentifier != nil);

	ARLReceiptContents *receipt = TLOAppStoreReceipt();

	if (receipt == nil) {
		return nil;
	}

	return receipt.inAppPurchases[productIdentifier];
}

TLOAppStoreIAPProduct TLOAppStoreProductFromProductIdentifier(NSString *productIdentifier)
{
	NSCParameterAssert(productIdentifier != nil);

	if ([productIdentifier isEqualToString:TLOAppStoreIAPFreeTrialProductIdentifier]) {
		return TLOAppStoreIAPFreeTrialProduct;
	} else if ([productIdentifier isEqualToString:TLOAppStoreIAPStandardEditionProductIdentifier]) {
		return TLOAppStoreIAPStandardEditionProduct;
	} else if ([productIdentifier isEqualToString:TLOAppStoreIAPUpgradeFromV6ProductIdentifier]) {
		return TLOAppStoreIAPUpgradeFromV6Product;
	} else if ([productIdentifier isEqualToString:TLOAppStoreIAPUpgradeFromV6FreeProductIdentifier]) {
		return TLOAppStoreIAPUpgradeFromV6FreeProduct;
	}

	return TLOAppStoreIAPUnknownProduct;
}

#pragma mark -
#pragma mark Trial Mode

BOOL TLOAppStoreTextualIsRegistered(void)
{
	BOOL purchased =
	TLOAppStoreIsOneProductPurchased(
		 @[
			   TLOAppStoreIAPStandardEditionProductIdentifier,
			   TLOAppStoreIAPUpgradeFromV6ProductIdentifier,
			   TLOAppStoreIAPUpgradeFromV6FreeProductIdentifier
		   ]
	);

	return purchased;
}

BOOL TLOAppStoreIsTrialPurchased(void)
{
	BOOL purchased =
	TLOAppStoreIsProductPurchased(TLOAppStoreIAPFreeTrialProductIdentifier);

	return purchased;
}

BOOL TLOAppStoreIsTrialExpired(void)
{
	if (TLOAppStoreIsTrialPurchased() == NO) {
		return NO;
	}

	NSTimeInterval timeLeft = TLOAppStoreTimeReaminingInTrial();

	return (timeLeft >= 0);
}

NSTimeInterval TLOAppStoreTimeReaminingInTrial(void)
{
	ARLInAppPurchaseContents *purchaseDetails = TLOAppStorePurchasedProductDetails(TLOAppStoreIAPFreeTrialProductIdentifier);

	if (purchaseDetails == nil) {
		return 0;
	}

	NSDate *trialPeriodPurchaseDate = purchaseDetails.originalPurchaseDate;

	if (trialPeriodPurchaseDate == nil) {
		LogToConsoleError("Trial period purchase date should never be nil");

		return 0;
	}

	NSTimeInterval trialPeriodStartInterval = trialPeriodPurchaseDate.timeIntervalSinceNow;

	if (trialPeriodStartInterval < TLOAppStoreTrialModeMaximumLifespan) {
		return 0;
	} else {
		return (TLOAppStoreTrialModeMaximumLifespan - trialPeriodStartInterval);
	}
}

NS_ASSUME_NONNULL_END

#endif
