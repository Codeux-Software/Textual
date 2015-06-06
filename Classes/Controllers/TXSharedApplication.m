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

#define _defineSharedInstance(si_name, si_class)	+ (si_class *)si_name						\
													{											\
														static id sharedSelf = nil;				\
																								\
														static dispatch_once_t onceToken;		\
																								\
														dispatch_once(&onceToken, ^{			\
															sharedSelf = [si_class new];		\
														});										\
																								\
														return sharedSelf;						\
													}

@implementation TXSharedApplication

_defineSharedInstance(applicationPluginManager, THOPluginManager)
_defineSharedInstance(sharedGrowlController, TLOGrowlController)
_defineSharedInstance(sharedInputHistoryManager, TLOInputHistory)
_defineSharedInstance(sharedNicknameCompletionStatus, TLONicknameCompletionStatus)
_defineSharedInstance(sharedQueuedCertificateTrustPanel, TVCQueuedCertificateTrustPanel)
_defineSharedInstance(sharedSpeechSynthesizer, TLOSpeechSynthesizer)
_defineSharedInstance(sharedThemeController, TPCThemeController)

#if TEXTUAL_BUILT_WITH_ADVANCED_ENCRYPTION == 1
_defineSharedInstance(sharedEncryptionManager, TLOEncryptionManager)
#endif

+ (OELReachability *)sharedNetworkReachabilityObject
{
	static id sharedSelf = nil;
	
	static dispatch_once_t onceToken;
	
	dispatch_once(&onceToken, ^{
		sharedSelf = [OELReachability reachabilityForInternetConnection];
		
		[sharedSelf setReachableBlock:^(OELReachability *reachability) {
			[[NSObject worldController] reachabilityChanged:YES];
		}];
		
		[sharedSelf setUnreachableBlock:^(OELReachability *reachability) {
			[[NSObject worldController] reachabilityChanged:NO];
		}];
	});
	
	return sharedSelf;
}

+ (void)releaseSharedMutableSynchronizationSerialQueue
{
	(void)[TXSharedApplication sharedMutableSynchronizationSerialQueue:YES];
}

+ (dispatch_queue_t)sharedMutableSynchronizationSerialQueue:(BOOL)performRelease
{
	static dispatch_queue_t workQueue = NULL;
	
	if (performRelease) {
		if (workQueue) {
			workQueue = NULL;
		}
	} else {
		static dispatch_once_t onceToken;
		
		dispatch_once(&onceToken, ^{
			workQueue = dispatch_queue_create("sharedMutableSynchronizationSerialQueue", DISPATCH_QUEUE_SERIAL);
		});
	}
	
	return workQueue;
}

+ (dispatch_queue_t)sharedMutableSynchronizationSerialQueue
{
	return [TXSharedApplication sharedMutableSynchronizationSerialQueue:NO];
}

#if TEXTUAL_BUILT_WITH_ICLOUD_SUPPORT == 1
+ (TPCPreferencesCloudSync *)sharedCloudSyncManager
{
	static id sharedSelf = nil;
	
	static dispatch_once_t onceToken;
	
	dispatch_once(&onceToken, ^{
		sharedSelf = [TPCPreferencesCloudSync new];
	});
	
	return sharedSelf;
}
#endif

@end

@implementation NSObject (TXSharedApplicationObjectExtension)

__weak static TXMasterController *TXGlobalMasterControllerClassReference;

+ (void)setGlobalMasterControllerClassReference:(id)masterController
{
	TXGlobalMasterControllerClassReference = masterController;
}

- (TXMasterController *)masterController
{
	return TXGlobalMasterControllerClassReference;
}

+ (TXMasterController *)masterController
{
	return TXGlobalMasterControllerClassReference;
}

- (IRCWorld *)worldController
{
	return [TXGlobalMasterControllerClassReference world];
}

+ (IRCWorld *)worldController
{
	return [TXGlobalMasterControllerClassReference world];
}

- (TXMenuController *)menuController
{
	return [TXGlobalMasterControllerClassReference menuController];
}

+ (TXMenuController *)menuController
{
	return [TXGlobalMasterControllerClassReference menuController];
}

@end
