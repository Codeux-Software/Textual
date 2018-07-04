/* *********************************************************************
 *                  _____         _               _
 *                 |_   _|____  _| |_ _   _  __ _| |
 *                   | |/ _ \ \/ / __| | | |/ _` | |
 *                   | |  __/>  <| |_| |_| | (_| | |
 *                   |_|\___/_/\_\\__|\__,_|\__,_|_|
 *
 * Copyright (c) 2010 - 2016 Codeux Software, LLC & respective contributors.
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

#import "TXSharedApplication.h"

NS_ASSUME_NONNULL_BEGIN

#define windowController()				[TXSharedApplication sharedWindowController]

#define sharedGrowlController()			[TXSharedApplication sharedGrowlController]

#define sharedPluginManager()			[TXSharedApplication sharedPluginManager]
#define sharedCloudManager()			[TXSharedApplication sharedCloudSyncManager]

@class OELReachability;
@class THOPluginManager;
@class TDCFileTransferDialog;
@class TLOGrowlController, TLOSpeechSynthesizer;
@class TVCLogControllerPrintingOperationQueue;
@class TXWindowController;

#if TEXTUAL_BUILT_WITH_ICLOUD_SUPPORT == 1
@class TPCPreferencesCloudSync;
#endif

#if TEXTUAL_BUILT_WITH_ADVANCED_ENCRYPTION == 1
@class TLOEncryptionManager;
#endif

#if TEXTUAL_BUILT_WITH_LICENSE_MANAGER == 1
@class TDCLicenseManagerDialog;
#endif

#if TEXTUAL_BUILT_FOR_APP_STORE_DISTRIBUTION == 1
@class TDCInAppPurchaseDialog;
#endif

@interface TXSharedApplication ()
#if TEXTUAL_BUILT_WITH_ICLOUD_SUPPORT == 1
+ (TPCPreferencesCloudSync *)sharedCloudSyncManager;
#endif

#if TEXTUAL_BUILT_WITH_ADVANCED_ENCRYPTION == 1
+ (TLOEncryptionManager *)sharedEncryptionManager;
#endif

+ (TLOGrowlController *)sharedGrowlController;
+ (OELReachability *)sharedNetworkReachabilityNotifier;
+ (THOPluginManager *)sharedPluginManager;
+ (TVCLogControllerPrintingOperationQueue *)sharedPrintingQueue;
+ (TLOSpeechSynthesizer *)sharedSpeechSynthesizer;
+ (TXWindowController *)sharedWindowController;

#if TEXTUAL_BUILT_WITH_LICENSE_MANAGER == 1
+ (TDCLicenseManagerDialog *)sharedLicenseManagerDialog;
#endif

#if TEXTUAL_BUILT_FOR_APP_STORE_DISTRIBUTION == 1
+ (TDCInAppPurchaseDialog *)sharedInAppPurchaseDialog;
#endif

+ (TDCFileTransferDialog *)sharedFileTransferDialog;
@end

@interface NSObject (TXSharedApplicationObjectExtensionPrivate)
+ (void)setGlobalMasterControllerClassReference:(TXMasterController *)masterController;
@end

NS_ASSUME_NONNULL_END
