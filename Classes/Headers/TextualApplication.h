/* ********************************************************************* 
       _____        _               _    ___ ____   ____
      |_   _|___  _| |_ _   _  __ _| |  |_ _|  _ \ / ___|
       | |/ _ \ \/ / __| | | |/ _` | |   | || |_) | |
       | |  __/>  <| |_| |_| | (_| | |   | ||  _ <| |___
       |_|\___/_/\_\\__|\__,_|\__,_|_|  |___|_| \_\\____|

 Copyright (c) 2010 — 2014 Codeux Software & respective contributors.
     Please see Acknowledgements.pdf for additional information.

 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions
 are met:

    * Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the
      documentation and/or other materials provided with the distribution.
    * Neither the name of the Textual IRC Client & Codeux Software nor the
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
	#import <WebKit/WebKit.h>
	#import <Security/Security.h>
	#import <QuartzCore/QuartzCore.h>
	#import <SystemConfiguration/SystemConfiguration.h>

	#import <SecurityInterface/SFCertificatePanel.h>
	#import <SecurityInterface/SFCertificateTrustPanel.h>
	#import <SecurityInterface/SFChooseIdentityPanel.h>

	#import <BlowfishEncryption/BlowfishEncryption.h>
	#import <SystemInformation/SystemInformation.h>
	#import <AutoHyperlinks/AutoHyperlinks.h>

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
	@class TDCFileTransferDialogRemoteAddress;
	@class TDCFileTransferDialogTableCell;
	@class TDCFileTransferDialogTransferController;
	@class TDChanBanExceptionSheet;
	@class TDChanBanSheet;
	@class TDChanInviteExceptionSheet;
	@class TDChannelSheet;
	@class TDCHighlightEntrySheet;
	@class TDCHighlightEntryMatchCondition;
	@class TDCHighlightListSheet;
	@class TDCInviteSheet;
	@class TDCListDialog;
	@class TDCModeSheet;
	@class TDCNickSheet;
	@class TDCPreferencesController;
	@class TDCPreferencesScriptWrapper;
	@class TDCPreferencesSoundWrapper;
	@class TDCProgressInformationSheet;
	@class TDCServerSheet;
	@class TDCSheetBase;
	@class TDCTopicSheet;
	@class TDCWelcomeSheet;
	@class THOPluginItem;
	@class THOPluginManager;
	@class THOUnicodeHelper;
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
	@class TLORegularExpression;
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
	@class TVCBasicTableViewSeparatorCell;
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
	@class TVCMainWindowChannelViewBox;
	@class TVCMainWindowLoadingScreenView;
	@class TVCMainWindowSegmentedController;
	@class TVCMainWindowSegmentedControllerCell;
	@class TVCMainWindowSplitView;
	@class TVCMainWindowTextView;
	@class TVCMainWindowTextViewBackground;
	@class TVCMainWindowTextViewContentView;
	@class TVCMainWindowTextViewMavericksUserInterace;
	@class TVCMainWindowTextViewYosemiteUserInterace;
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


	/* Protocol forwarders. */
	@protocol IRCConnectionDelegate;
	@protocol TDCAboutPanelDelegate;
	@protocol TDCAddressBookSheetDelegate;
	@protocol TDCFileTransferDialogRemoteAddressDelegate;
	@protocol TDChanBanExceptionSheetDelegate;
	@protocol TDChanBanSheetDelegate;
	@protocol TDChanInviteExceptionSheetDelegate;
	@protocol TDChannelSheetDelegate;
	@protocol TDCHighlightEntrySheetDelegate;
	@protocol TDCHighlightListSheetDelegate;
	@protocol TDCInviteSheetDelegate;
	@protocol TDCListDialogDelegate;
	@protocol TDCModeSheetDelegate;
	@protocol TDCNickSheetDelegate;
	@protocol TDCPreferencesControllerDelegate;
	@protocol TDCServerSheetDelegate;
	@protocol TDCTopicSheetDelegate;
	@protocol TDCWelcomeSheetDelegate;
	@protocol THOPluginProtocol;
	@protocol TVCLogViewDelegate;
	@protocol TVCMemberListDelegate;
	@protocol TVCServerListDelegate;

	/* Static Defeinitions. */

	#import "StaticDefinitions.h"

	/* Import frameworks based on defines. */
	#ifdef TEXTUAL_BUILT_WITH_HOCKEYAPP_SDK_ENABLED
		#import <HockeySDK/HockeySDK.h>
	#endif

	/* Protocol defenitions. (see file) */
	#import "TDCSharedProtocolDefinitions.h"

	/* 3rd Party Extensions. */

	#import "AGKeychain.h"
	#import "DDExtensions.h"
	#import "DDInvocation.h"
	#import "GCDAsyncSocket.h"
	#import "GCDAsyncSocketExtensions.h"
	#import "GRMustache.h"
	#import "GRMustacheAvailabilityMacros.h"
	#import "GRMustacheConfiguration.h"
	#import "GRMustacheContext.h"
	#import "GRMustacheError.h"
	#import "GRMustacheFilter.h"
	#import "GRMustacheLocalizer.h"
	#import "GRMustacheRendering.h"
	#import "GRMustacheTag.h"
	#import "GRMustacheTagDelegate.h"
	#import "GRMustacheTemplate.h"
	#import "GRMustacheTemplateRepository.h"
	#import "GRMustacheVersion.h"
	#import "GTMDefines.h"
	#import "GTMEncodeHTML.h"
	#import "GTMEncodeURL.h"
	#import "GTMGarbageCollection.h"
	#import "OELReachability.h"
	#import "RLMAsyncSocket.h"

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

	#import "NSArrayHelper.h"
	#import "NSBundleHelper.h"
	#import "NSByteCountFormatterHelper.h"
	#import "NSColorHelper.h"
	#import "NSDataHelper.h"
	#import "NSDateHelper.h"
	#import "NSDictionaryHelper.h"
	#import "NSFileManagerHelper.h"
	#import "NSFontHelper.h"
	#import "NSImageHelper.h"
	#import "NSMenuHelper.h"
	#import "NSNumberHelper.h"
	#import "NSValueHelper.h"
	#import "NSObjectHelper.h"
	#import "NSOutlineViewHelper.h"
	#import "NSPasteboardHelper.h"
	#import "NSRangeHelper.h"
	#import "NSRectHelper.h"
	#import "NSScreenHelper.h"
	#import "NSSplitViewHelper.h"
	#import "NSStringHelper.h"
	#import "NSTextFieldHelper.h"
	#import "NSWindowHelper.h"

	/* Dialogs. */

	#import "TDCSheetBase.h"
	#import "TDCAboutPanel.h"
	#import "TDCAddressBookSheet.h"
	#import "TDCFileTransferDialog.h"
	#import "TDCFileTransferDialogTableCell.h"
	#import "TDCFileTransferDialogTransferController.h"
	#import "TDCFileTransferDialogRemoteAddress.h"
	#import "TDCHighlightEntrySheet.h"
	#import "TDCHighlightListSheet.h"
	#import "TDCInviteSheet.h"
	#import "TDCListDialog.h"
	#import "TDCModeSheet.h"
	#import "TDCNickSheet.h"
	#import "TDCPreferencesController.h"
	#import "TDCPreferencesScriptWrapper.h"
	#import "TDCPreferencesSoundWrapper.h"
	#import "TDCServerSheet.h"
	#import "TDCTopicSheet.h"
	#import "TDCWelcomeSheet.h"
	#import "TDChanBanExceptionSheet.h"
	#import "TDChanBanSheet.h"
	#import "TDChanInviteExceptionSheet.h"
	#import "TDChannelSheet.h"

	/* Helpers. */

	#import "THOPluginItem.h"
	#import "THOPluginManager.h"
	#import "THOPluginProtocol.h"
	#import "THOUnicodeHelper.h"

	/* Library. */

	#import "TLOFileLogger.h"
	#import "TLOGrowlController.h"
	#import "TLOInputHistory.h"
	#import "TLOKeyEventHandler.h"
	#import "TLOLanguagePreferences.h"
	#import "TLOLinkParser.h"
	#import "TLONicknameCompletionStatus.h"
	#import "TLOPopupPrompts.h"
	#import "TLORegularExpression.h"
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
	#import "TVCBasicTableViewSeparatorCell.h"
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
