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

#import "TLOLicenseManagerDownloader.h"

#if TEXTUAL_BUILT_WITH_LICENSE_MANAGER == 1

typedef enum TLOLicenseManagerDownloaderRequestType : NSInteger {
	TLOLicenseManagerDownloaderRequestActivationType,
	TLOLicenseManagerDownloaderRequestDeactivationWithType,
	TLOLicenseManagerDownloaderRequestDeactivationWithoutType,
	TLOLicenseManagerDownloaderRequestSendLostLicenseType,
	TLOLicenseManagerDownloaderRequestConvertMASReceiptType
} TLOLicenseManagerDownloaderRequestType;

/* URLs for performing certain actions with license keys. */
NSString * const TLOLicenseManagerDownloaderLicenseAPIActivationURL						= @"http://www.codeux.com/textual/private/fastspring/license-api/activateLicense.cs";
NSString * const TLOLicenseManagerDownloaderLicenseAPIDeactivationWithTokenURL			= @"http://www.codeux.com/textual/private/fastspring/license-api/deactivateLicense.cs";
NSString * const TLOLicenseManagerDownloaderLicenseAPIDeactivationWithoutTokenURL		= @"http://www.codeux.com/textual/private/fastspring/license-api/deactivateLicenseRequest.cs";
NSString * const TLOLicenseManagerDownloaderLicenseAPISendLostLicenseURL				= @"http://www.codeux.com/textual/private/fastspring/license-api/sendLostLicense.cs";
NSString * const TLOLicenseManagerDownloaderLicenseAPIConvertMASReceiptURL				= @"http://www.codeux.com/textual/private/fastspring/license-api/convertReceiptToLicense.cs";

/* The license API sets HTTP header status codes on failure, but it also populates the contents of the
 response body with plain text for specific error conditions. The following constants defines the exact
 plain text response for known API replies. These response bodies are only checked for if the API server
 returns a non-200 OK status code. */
NSString * const TLOLicenseManagerDownloaderRequestResponseBodyGenericError					= @"-500-";
NSString * const TLOLicenseManagerDownloaderRequestResponseBodyTryAgainLater				= @"-501-";
NSString * const TLOLicenseManagerDownloaderRequestResponseBodyTooManyActivations			= @"-502-";

/* The license API throttles requests to prevent abuse. The following HTTP status code will inform
 Textual if it the license API has been overwhelmed. */
NSInteger const TLOLicenseManagerDownloaderRequestResponseStatusSuccess = 200; // OK
NSInteger const TLOLicenseManagerDownloaderRequestResponseStatusTryAgainLater = 503; // Service Unavailable

/* Private header */
@interface TLOLicenseManagerDownloader ()
@property (nonatomic, assign) TLOLicenseManagerDownloaderRequestType requestType;
@property (nonatomic, copy) TLOLicenseManagerDownloaderCompletionBlock completionBlock;
@property (nonatomic, copy) NSString *requestLicenseKey;
@property (nonatomic, copy) NSString *requestContextInfo; // Additional, optional info such as activation token
@end

@implementation TLOLicenseManagerDownloader

#pragma mark -
#pragma mark Public Interface

- (void)activateLicense:(NSString *)licenseKey completionBlock:(TLOLicenseManagerDownloaderCompletionBlock)completionBlock
{

}

- (void)deactivateLicense:(NSString *)licenseKey withActivationToken:(NSString *)activationToken completionBlock:(TLOLicenseManagerDownloaderCompletionBlock)completionBlock
{

}

- (void)deactivateLicenseWithoutActivationToken:(NSString *)licenseKey completionBlock:(TLOLicenseManagerDownloaderCompletionBlock)completionBlock
{

}

- (void)requestLostLicenseKeyForContactAddress:(NSString *)contactAddress completionBlock:(TLOLicenseManagerDownloaderCompletionBlock)completionBlock
{

}

- (void)convertMacAppStorePurcahse:(TLOLicenseManagerDownloaderCompletionBlock)completionBlock
{

}

@end

#endif
