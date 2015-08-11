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

#ifdef __OBJC__
	#import <Cocoa/Cocoa.h>

	#import <QuartzCore/QuartzCore.h>

	#import <Security/Security.h>
	#import <SecurityInterface/SFCertificatePanel.h>
	#import <SecurityInterface/SFCertificateTrustPanel.h>
	#import <SecurityInterface/SFChooseIdentityPanel.h>

	#import <SystemConfiguration/SystemConfiguration.h>

	#import <WebKit/WebKit.h>

	#import <AutoHyperlinks/AutoHyperlinks.h>
	#import <CocoaExtensions/CocoaExtensions.h>
	#import <EncryptionKit/EncryptionKit.h>

	/* Class Forwarders. */
	@class IRCAddressBookEntry;
	@class IRCChannel;
	@class IRCChannelConfig;
	@class IRCChannelMode;
	@class IRCClient;
	@class IRCClientConfig;
	@class IRCCommandIndex;
	@class IRCConnection;
	@class IRCExtras;
	@class IRCISupportInfo;
	@class IRCMessage;
	@class IRCModeInfo;
	@class IRCPrefix;
	@class IRCSendingMessage;
	@class IRCTreeItem;
	@class IRCUser;
	@class IRCWorld;
	@class TDCAboutPanel;
	@class TDCAddressBookSheet;
	@class TDCFileTransferDialog;
	@class TDCFileTransferDialogRemoteAddressLookup;
	@class TDCFileTransferDialogTableCell;
	@class TDCFileTransferDialogTransferController;
	@class TDCHighlightEntryMatchCondition;
	@class TDCHighlightEntrySheet;
	@class TDCHighlightListSheet;
	@class TDCHighlightListSheetEntry;
	@class TDCListDialog;
	@class TDCPreferencesController;
	@class TDCPreferencesScriptWrapper;
	@class TDCPreferencesSoundWrapper;
	@class TDCProgressInformationSheet;
	@class TDCServerChangeNicknameSheet;
	@class TDCServerSheet;
	@class TDCSheetBase;
	@class TDCWelcomeSheet;
	@class TDChannelBanListSheet;
	@class TDChannelInviteSheet;
	@class TDChannelModifyModesSheet;
	@class TDChannelModifyTopicSheet;
	@class TDChannelPropertiesSheet;
	@class THOPluginItem;
	@class THOPluginManager;
	@class THOUnicodeHelper;
	@class TLOEncryptionManager;
	@class TLOFileLogger;
	@class TLOGrowlController;
	@class TLOInputHistory;
	@class TLOInputHistoryObject;
	@class TLOKeyEventHandler;
	@class TLOLanguagePreferences;
	@class TLOLinkParser;
	@class TLONicknameCompletionStatus;
	@class TLOpenLink;
	@class TLOPopupPrompts;
	@class TLOSoundPlayer;
	@class TLOSpeechSynthesizer;
	@class TLOTimer;
	@class TLOTimerCommand;
	@class TPCApplicationInfo;
	@class TPCPathInfo;
	@class TPCPreferences;
	@class TPCPreferencesCloudSync;
	@class TPCPreferencesImportExport;
	@class TPCPreferencesUserDefaults;
	@class TPCPreferencesUserDefaultsObjectProxy;
	@class TPCResourceManager;
	@class TPCResourceManagerDocumentTypeImporter;
	@class TPCThemeController;
	@class TPCThemeSettings;
	@class TVCAnimatedContentNavigationOutlineView;
	@class TVCBasicTableView;
	@class TVCDockIcon;
	@class TVCImageURLoader;
	@class TVCImageURLParser;
	@class TVCInputPromptDialog;
	@class TVCLogController;
	@class TVCLogControllerHistoricLogFile;
	@class TVCLogControllerOperationQueue;
	@class TVCLogControllerOperationItem;
	@class TVCLogLine;
	@class TVCLogPolicy;
	@class TVCLogRenderer;
	@class TVCLogScriptEventSink;
	@class TVCLogView;
	@class TVCMainWindow;
	@class TVCMainWindowLoadingScreenView;
	@class TVCMainWindowSegmentedController;
	@class TVCMainWindowSegmentedControllerCell;
	@class TVCMainWindowSplitView;
	@class TVCMainWindowTextView;
	@class TVCMainWindowTextViewBackground;
	@class TVCMainWindowTextViewContentView;
	@class TVCMainWindowTextViewMavericksUserInterace;
	@class TVCMainWindowTextViewYosemiteUserInterace;
	@class TVCMainWindowTitlebarAccessoryView;
	@class TVCMainWindowTitlebarAccessoryViewController;
	@class TVCMainWindowTitlebarAccessoryViewLockButton;
	@class TVCMemberLisCellYosemiteTextFieldInterior;
	@class TVCMemberList;
	@class TVCMemberListCell;
	@class TVCMemberListCellMavericksTextField;
	@class TVCMemberListCellMavericksTextFieldBackingLayer;
	@class TVCMemberListDarkYosemiteUserInterface;
	@class TVCMemberListLightYosemiteUserInterface;
	@class TVCMemberListMavericksDarkUserInterface;
	@class TVCMemberListMavericksLightUserInterface;
	@class TVCMemberListMavericksUserInterface;
	@class TVCMemberListMavericksUserInterfaceBackground;
	@class TVCMemberListRowCell;
	@class TVCMemberListSharedUserInterface;
	@class TVCMemberListUserInfoPopover;
	@class TVCMemberListYosemiteUserInterface;
	@class TVCQueuedCertificateTrustPanel;
	@class TVCServerList;
	@class TVCServerListCell;
	@class TVCServerListCellChildItem;
	@class TVCServerListCellGroupItem;
	@class TVCServerListCellMavericksTextField;
	@class TVCServerListCellMavericksTextFieldBackingLayer;
	@class TVCServerListCellYosemiteTextFieldInterior;
	@class TVCServerListDarkYosemiteUserInterface;
	@class TVCServerListLightYosemiteUserInterface;
	@class TVCServerListMavericksDarkUserInterface;
	@class TVCServerListMavericksLightUserInterface;
	@class TVCServerListMavericksUserInterface;
	@class TVCServerListMavericksUserInterfaceBackground;
	@class TVCServerListRowCell;
	@class TVCServerListSharedUserInterface;
	@class TVCServerListYosemiteUserInterface;
	@class TVCTextFieldWithValueValidation;
	@class TVCTextFieldComboBoxWithValueValidation;
	@class TVCTextFieldComboBoxWithValueValidationCell;
	@class TVCTextFieldWithValueValidationCell;
	@class TVCTextViewIRCFormattingMenu;
	@class TVCTextViewWithIRCFormatter;
	@class TVCWebViewAutoScroll;
	@class TXMasterController;
	@class TXMasterController;
	@class TXMenuController;
	@class TXMenuControllerMainWindowProxy;
	@class TXSharedApplication;
	@class TXUserInterface;

	/* Static Defeinitions. */
	#import "StaticDefinitions.h"

	/* Import frameworks based on defines. */
	#ifndef TEXTUAL_BUILT_WITH_HOCKEYAPP_SDK_ENABLED
		#define	TEXTUAL_BUILT_WITH_HOCKEYAPP_SDK_ENABLED 0
	#endif

	#if TEXTUAL_BUILT_WITH_HOCKEYAPP_SDK_ENABLED == 1
		#import <HockeySDK/HockeySDK.h>
	#endif

	#ifndef TEXTUAL_BUILT_WITH_SPARKLE_ENABLED
		#define TEXTUAL_BUILT_WITH_SPARKLE_ENABLED 0
	#endif

	#if TEXTUAL_BUILT_WITH_SPARKLE_ENABLED == 1
		#import <Sparkle/Sparkle.h>
	#endif

	#ifndef TEXTUAL_BUILT_WITH_LICENSE_MANAGER
		#define TEXTUAL_BUILT_WITH_LICENSE_MANAGER 0
	#endif

	#ifndef TEXTUAL_BUILT_WITH_ICLOUD_SUPPORT
		#define TEXTUAL_BUILT_WITH_ICLOUD_SUPPORT 0
	#endif

	#ifndef TEXTUAL_BUILT_WITH_ADVANCED_ENCRYPTION
		#define TEXTUAL_BUILT_WITH_ADVANCED_ENCRYPTION 0
	#endif

	#ifndef TEXTUAL_BUILT_WITH_FORCED_BETA_LIFESPAN
		#define TEXTUAL_BUILT_WITH_FORCED_BETA_LIFESPAN 0
	#endif

	/* Protocol defenitions. (see file) */
	#import "TDCSharedProtocolDefinitions.h"

	/* 3rd-party Extensions. */
	#import "GCDAsyncSocket.h"
	#import "GCDAsyncSocketExtensions.h"
	#import "GCDAsyncSocketCipherNames.h"
	#import "GRMustacheAvailabilityMacros.h"
	#import "GRMustache.h"
	#import "GRMustacheConfiguration.h"
	#import "GRMustacheContentType.h"
	#import "GRMustacheContext.h"
	#import "GRMustacheError.h"
	#import "GRMustacheFilter.h"
	#import "GRMustacheLocalizer.h"
	#import "GRMustacheRendering.h"
	#import "GRMustacheSafeKeyAccess.h"
	#import "GRMustacheTag.h"
	#import "GRMustacheTagDelegate.h"
	#import "GRMustacheTemplate.h"
	#import "GRMustacheTemplateRepository.h"
	#import "GRMustacheVersion.h"
	#import "GTMEncodeHTML.h"
	#import "GTMEncodeURL.h"
	#import "OELReachability.h"

	/* IRC Controllers — Core. */
	#import "IRC.h"
	#import "IRCAddressBook.h"
	#import "IRCChannel.h"
	#import "IRCChannelConfig.h"
	#import "IRCChannelMode.h"
	#import "IRCClient.h"
	#import "IRCClientConfig.h"
	#import "IRCColorFormat.h"
	#import "IRCCommandIndex.h"
	#import "IRCConnection.h"
	#import "IRCConnectionSocket.h"
	#import "IRCExtras.h"
	#import "IRCISupportInfo.h"
	#import "IRCMessage.h"
	#import "IRCModeInfo.h"
	#import "IRCPrefix.h"
	#import "IRCSendingMessage.h"
	#import "IRCTreeItem.h"
	#import "IRCUser.h"
	#import "IRCWorld.h"
	#import "IRCWorldCloudExtension.h"

	/* Framework Extensions (Helpers). */
	#import "NSColorHelper.h"
	#import "NSObjectHelper.h"
	#import "NSStringHelper.h"
	#import "NSTableVIewHelper.h"
	#import "NSViewHelper.h"

	/* Dialogs. */
	#import "TDCSheetBase.h"
	#import "TDCAboutPanel.h"
	#import "TDCAddressBookSheet.h"
	#import "TDCFileTransferDialog.h"
	#import "TDCFileTransferDialogTableCell.h"
	#import "TDCFileTransferDialogTransferController.h"
	#import "TDCFileTransferDialogRemoteAddressLookup.h"
	#import "TDCHighlightEntrySheet.h"
	#import "TDCHighlightListSheet.h"
	#import "TDCListDialog.h"
	#import "TDCPreferencesController.h"
	#import "TDCPreferencesScriptWrapper.h"
	#import "TDCPreferencesSoundWrapper.h"
	#import "TDCServerChangeNicknameSheet.h"
	#import "TDCServerSheet.h"
	#import "TDCWelcomeSheet.h"
	#import "TDChannelBanListSheet.h"
	#import "TDChannelInviteSheet.h"
	#import "TDChannelModifyModesSheet.h"
	#import "TDChannelModifyTopicSheet.h"
	#import "TDChannelPropertiesSheet.h"

	/* Helpers. */
	#import "THOPluginItem.h"
	#import "THOPluginManager.h"
	#import "THOPluginProtocol.h"
	#import "THOUnicodeHelper.h"

	/* Library. */
	#import "TLOEncryptionManager.h"
	#import "TLOFileLogger.h"
	#import "TLOGrowlController.h"
	#import "TLOInputHistory.h"
	#import "TLOKeyEventHandler.h"
	#import "TLOLanguagePreferences.h"
	#import "TLOLinkParser.h"
	#import "TLONicknameCompletionStatus.h"
	#import "TLOPopupPrompts.h"
	#import "TLOSoundPlayer.h"
	#import "TLOSpeechSynthesizer.h"
	#import "TLOTimer.h"
	#import "TLOTimerCommand.h"
	#import "TLOpenLink.h"

	/* Preferences. */
	#import "TPCApplicationInfo.h"
	#import "TPCPathInfo.h"
	#import "TPCPreferences.h"
	#import "TPCPreferencesCloudSync.h"
	#import "TPCPreferencesCloudSyncExtension.h"
	#import "TPCPreferencesImportExport.h"
	#import "TPCPreferencesUserDefaults.h"
	#import "TPCResourceManager.h"
	#import "TPCThemeController.h"
	#import "TPCThemeSettings.h"

	/* View Controllers. */
	#import "TVCAnimatedContentNavigationOutlineView.h"
	#import "TVCDockIcon.h"
	#import "TVCImageURLParser.h"
	#import "TVCImageURLoader.h"
	#import "TVCInputPromptDialog.h"
	#import "TVCMainWindowTextView.h"
	#import "TVCBasicTableView.h"
	#import "TVCLogController.h"
	#import "TVCLogControllerHistoricLogFile.h"
	#import "TVCLogControllerOperationQueue.h"
	#import "TVCLogLine.h"
	#import "TVCLogPolicy.h"
	#import "TVCLogRenderer.h"
	#import "TVCLogScriptEventSink.h"
	#import "TVCLogView.h"
	#import "TVCMainWindow.h"
	#import "TVCMainWindowLoadingScreen.h"
	#import "TVCMainWindowSegmentedControl.h"
	#import "TVCMainWindowSplitView.h"
	#import "TVCMainWindowTextViewMavericksUserInterace.h"
	#import "TVCMainWindowTextViewYosemiteUserInterace.h"
	#import "TVCMainWindowTitlebarAccessoryView.h"
	#import "TDCProgressInformationSheet.h"
	#import "TVCMemberList.h"
	#import "TVCMemberListCell.h"
	#import "TVCMemberListUserInfoPopover.h"
	#import "TVCMemberListSharedUserInterface.h"
	#import "TVCMemberListMavericksUserInterface.h"
	#import "TVCMemberListYosemiteUserInterface.h"
	#import "TVCQueuedCertificateTrustPanel.h"
	#import "TVCServerList.h"
	#import "TVCServerListCell.h"
	#import "TVCServerListSharedUserInterface.h"
	#import "TVCServerListMavericksUserInterface.h"
	#import "TVCServerListYosemiteUserInterface.h"
	#import "TVCTextFieldWithValueValidation.h"
	#import "TVCTextFieldComboBoxWithValueValidation.h"
	#import "TVCTextViewWithIRCFormatter.h"
	#import "TVCTextFormatterMenu.h"
	#import "TVCWebViewAutoScroll.h"

	/* Master Controllers — Root. */
	#import "TXGlobalModels.h"
	#import "TXMasterController.h"
	#import "TXMenuController.h"
	#import "TXSharedApplication.h"
	#import "TXUserInterface.h"
#endif

/* @end */
