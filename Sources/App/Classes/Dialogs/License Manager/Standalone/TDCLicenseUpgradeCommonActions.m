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

#import "TXMasterController.h"
#import "TXMenuControllerPrivate.h"
#import "TLOpenLink.h"
#import "TDCLicenseUpgradeCommonActionsPrivate.h"

NS_ASSUME_NONNULL_BEGIN

#if TEXTUAL_BUILT_WITH_LICENSE_MANAGER == 1
@implementation TDCLicenseUpgradeCommonActions

+ (void)contactSupport
{
	[menuController() contactSupport:nil];
}

+ (void)activateLicense:(NSString *)licenseKey
{
	NSParameterAssert(licenseKey != nil);

	[menuController() manageLicense:nil activateLicenseKey:licenseKey];
}

+ (void)purchaseUpgradeForLicense:(NSString *)licenseKey
{
	NSParameterAssert(licenseKey != nil);

	NSString *linkToOpen = [NSString stringWithFormat:@"https://www.codeux.com/textual/version-7-upgrade/upgradeLicense/%@", licenseKey];

	[TLOpenLink openWithString:linkToOpen inBackground:NO];
}

+ (void)learnMore
{
	NSURL *urlToOpen = [NSURL URLWithString:@"https://www.codeux.com/textual/version-7-upgrade/learnMore"];

	[TLOpenLink open:urlToOpen inBackground:NO];
}

+ (void)openStandaloneStore
{
	[menuController() openStandaloneStoreWebpage:nil];
}

+ (void)openMacAppStore
{
	[menuController() openMacAppStoreWebpage:nil];
}

@end
#endif

NS_ASSUME_NONNULL_END
