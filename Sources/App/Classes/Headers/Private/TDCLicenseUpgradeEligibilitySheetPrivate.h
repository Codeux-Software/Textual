/* *********************************************************************
 *                  _____         _               _
 *                 |_   _|____  _| |_ _   _  __ _| |
 *                   | |/ _ \ \/ / __| | | |/ _` | |
 *                   | |  __/>  <| |_| |_| | (_| | |
 *                   |_|\___/_/\_\\__|\__,_|\__,_|_|
 *
 * Copyright (c) 2010 - 2017 Codeux Software, LLC & respective contributors.
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

#import "TDCSheetBase.h"

NS_ASSUME_NONNULL_BEGIN

#if TEXTUAL_BUILT_WITH_LICENSE_MANAGER == 1
typedef NS_ENUM(NSUInteger, TLOLicenseUpgradeEligibility) {
	TLOLicenseUpgradeEligibilityUnknown = LONG_MAX,
	TLOLicenseUpgradeEligibilityNot = 0,
	TLOLicenseUpgradeEligibilityDiscount = 1,
	TLOLicenseUpgradeEligibilityFree = 3,
	TLOLicenseUpgradeEligibilityAlreadyUpgraded = 2,
};

@protocol TDCLicenseUpgradeEligibilitySheetDelegate;

@interface TDCLicenseUpgradeEligibilitySheet : TDCSheetBase
@property (readonly, copy) NSString *licenseKey;
@property (readonly) TLOLicenseUpgradeEligibility eligibility;

- (instancetype)initWithLicenseKey:(NSString *)licenseKey NS_DESIGNATED_INITIALIZER;

- (void)checkEligibility;
@end

@protocol TDCLicenseUpgradeEligibilitySheetDelegate <NSObject>
@required

- (void)upgradeEligibilitySheetContactSupport:(TDCLicenseUpgradeEligibilitySheet *)sender;
- (void)upgradeEligibilitySheetActivateLicense:(TDCLicenseUpgradeEligibilitySheet *)sender;
- (void)upgradeEligibilitySheetPurchaseUpgrade:(TDCLicenseUpgradeEligibilitySheet *)sender;
- (void)upgradeEligibilitySheetPurchaseMacAppStore:(TDCLicenseUpgradeEligibilitySheet *)sender;
- (void)upgradeEligibilitySheetPurchaseStandalone:(TDCLicenseUpgradeEligibilitySheet *)sender;
- (void)upgradeEligibilitySheetChanged:(TDCLicenseUpgradeEligibilitySheet *)sender;
- (void)upgradeEligibilitySheetWillClose:(TDCLicenseUpgradeEligibilitySheet *)sender;
@end
#endif

NS_ASSUME_NONNULL_END
