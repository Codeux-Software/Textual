/* *********************************************************************
 *                  _____         _               _
 *                 |_   _|____  _| |_ _   _  __ _| |
 *                   | |/ _ \ \/ / __| | | |/ _` | |
 *                   | |  __/>  <| |_| |_| | (_| | |
 *                   |_|\___/_/\_\\__|\__,_|\__,_|_|
 *
 * Copyright (c) 2010 - 2015 Codeux Software, LLC & respective contributors.
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

#ifdef __OBJC__
	/* System frameworks */
	#import <Cocoa/Cocoa.h>

	#import <Security/Security.h>

	#import <WebKit/WebKit.h>

	/* Custom frameworks */
	#import <AutoHyperlinks/AutoHyperlinks.h>
	#import <CocoaExtensions/CocoaExtensions.h>

	/* Static Defeinitions */
	#import "StaticDefinitions.h"

	/* IRC Controllers — Core */
	#import "IRC.h"
	#import "IRCAddressBook.h"
	#import "IRCAddressBookUserTracking.h"
	#import "IRCChannel.h"
	#import "IRCChannelConfig.h"
	#import "IRCChannelMode.h"
	#import "IRCChannelUser.h"
	#import "IRCClient.h"
	#import "IRCClientConfig.h"
	#import "IRCColorFormat.h"
	#import "IRCCommandIndex.h"
	#import "IRCConnection.h"
	#import "IRCConnectionConfig.h"
	#import "IRCHighlightLogEntry.h"
	#import "IRCHighlightMatchCondition.h"
	#import "IRCISupportInfo.h"
	#import "IRCMessage.h"
	#import "IRCModeInfo.h"
	#import "IRCNetworkList.h"
	#import "IRCPrefix.h"
	#import "IRCSendingMessage.h"
	#import "IRCServer.h"
	#import "IRCTreeItem.h"
	#import "IRCUser.h"
	#import "IRCUserRelations.h"
	#import "IRCWorld.h"

	/* Framework Extensions (Helpers) */
	#import "NSColorHelper.h"
	#import "NSStringHelper.h"
	#import "NSViewHelper.h"

	/* Dialogs */
	#import "TDCAlert.h"
	#import "TDCInputPrompt.h"
	#import "TDCSheetBase.h"
	#import "TDCWindowBase.h"

	/* Helpers */
	#import "THOPluginProtocol.h"
	#import "THOUnicodeHelper.h"

	/* Library */
	#import "TLOEncryptionManager.h"
	#import "TLOGrowlController.h"
	#import "TLOInternetAddressLookup.h"
	#import "TLOKeyEventHandler.h"
	#import "TLOLanguagePreferences.h"
	#import "TLOLinkParser.h"
	#import "TLOPopupPrompts.h"
	#import "TLOSoundPlayer.h"
	#import "TLOTimer.h"
	#import "TLOpenLink.h"

	/* Preferences */
	#import "TPCApplicationInfo.h"
	#import "TPCPathInfo.h"
	#import "TPCPreferencesCloudSync.h"
	#import "TPCPreferencesCloudSyncExtension.h"
	#import "TPCPreferencesImportExport.h"
	#import "TPCPreferencesLocal.h"
	#import "TPCPreferencesReload.h"
	#import "TPCPreferencesUserDefaultsLocal.h"
	#import "TPCResourceManager.h"
	#import "TPCThemeController.h"
	#import "TPCThemeSettings.h"

	/* View Controllers */
	#import "TVCAlert.h"
	#import "TVCAutoExpandingTextField.h"
	#import "TVCAutoExpandingTokenField.h"
	#import "TVCBasicTableView.h"
	#import "TVCChannelSelectionViewController.h"
	#import "TVCComboBoxWithValueValidation.h"
	#import "TVCLogController.h"
	#import "TVCLogLine.h"
	#import "TVCLogRenderer.h"
	#import "TVCLogView.h"
	#import "TVCMainWindow.h"
	#import "TVCMainWindowLoadingScreen.h"
	#import "TVCMainWindowSplitView.h"
	#import "TVCMainWindowTextView.h"
	#import "TVCMemberList.h"
	#import "TVCServerList.h"
	#import "TVCTextFieldWithValueValidation.h"
	#import "TVCTextViewWithIRCFormatter.h"

	/* Master Controllers — Root */
	#import "TXGlobalModels.h"
	#import "TXMasterController.h"
	#import "TXMenuController.h"
	#import "TXSharedApplication.h"
	#import "TXUserInterface.h"
#endif

/* @end */
