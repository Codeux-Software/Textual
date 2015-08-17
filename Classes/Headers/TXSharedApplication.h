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

#define masterController()			[self masterController]
#define menuController()			[masterController() menuController]
#define worldController()			[masterController() world]
#define windowController()			[TXSharedApplication sharedWindowController]

#define mainWindow()				[masterController() mainWindow]

#define mainWindowLoadingScreen()	[mainWindow() loadingScreen]
#define mainWindowServerList()		[mainWindow() serverList]
#define mainWindowMemberList()		[mainWindow() memberList]
#define mainWindowTextField()		[mainWindow() inputTextField]

#define themeController()			[TXSharedApplication sharedThemeController]

#define themeSettings()				[themeController() customSettings]

#define sharedGrowlController()			[TXSharedApplication sharedGrowlController]

#define sharedPluginManager()			[TXSharedApplication applicationPluginManager]
#define sharedCloudManager()			[TXSharedApplication sharedCloudSyncManager]

@interface TXSharedApplication : NSObject
+ (TXWindowController *)sharedWindowController;
+ (OELReachability *)sharedNetworkReachabilityObject;
+ (THOPluginManager *)applicationPluginManager;
+ (TLOGrowlController *)sharedGrowlController;
+ (TLOInputHistory *)sharedInputHistoryManager;
+ (TLONicknameCompletionStatus *)sharedNicknameCompletionStatus;
+ (TLOSpeechSynthesizer *)sharedSpeechSynthesizer;
+ (TPCThemeController *)sharedThemeController;
+ (TVCQueuedCertificateTrustPanel *)sharedQueuedCertificateTrustPanel;

#if TEXTUAL_BUILT_WITH_ADVANCED_ENCRYPTION == 1
+ (TLOEncryptionManager *)sharedEncryptionManager;
#endif

/* Mutable sets in Textual (e.g. channel user lists) are accessed on this queue
 and this queue alone to prevent accessing on different threads at same time 
 which could result in corrupted data access. It is not recommended to call 
 this serial queue for any reason from a plugin. It is a work horse for Textual
 and should be respected as such. */
+ (dispatch_queue_t)sharedMutableSynchronizationSerialQueue;
+ (void)releaseSharedMutableSynchronizationSerialQueue;

#if TEXTUAL_BUILT_WITH_ICLOUD_SUPPORT == 1
+ (TPCPreferencesCloudSync *)sharedCloudSyncManager;
#endif
@end

@interface NSObject (TXSharedApplicationObjectExtension)
- (TXMasterController *)masterController;
+ (TXMasterController *)masterController;

+ (void)setGlobalMasterControllerClassReference:(id)masterController;
@end
