// Created by Codeux Software <support AT codeux DOT com> <https://github.com/codeux/Textual>
// You can redistribute it and/or modify it under the new BSD license.

#ifdef __OBJC__
	#import <Cocoa/Cocoa.h>
	#import <WebKit/WebKit.h>
	#import <Security/Security.h>
	#import <SystemConfiguration/SystemConfiguration.h>

	#import "StaticDefinitions.h"

	/* Class Forwarders. */

	@class IRCAddressBook;
	@class IRCChannel;
	@class IRCChannelConfig;
	@class IRCChannelMode;
	@class IRCClient;
	@class IRCClientConfig;
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
	@class IRCWorldConfig;
	@class LVCLogRenderer;
	@class TDCAboutPanelSWindowController;
	@class TDCAddressBookSheet;
	@class TDCHighlightSheet;
	@class TDCInviteSheet;
	@class TDCListDialog;
	@class TDCModeSheet;
	@class TDCNickSheet;
	@class TDCPreferencesController;
	@class TDCPreferencesScriptWrapper;
	@class TDCPreferencesSoundWrapper;
	@class TDCServerSheet;
	@class TDCSheetBase;
	@class TDCTopicSheet;
	@class TDCWelcomeSheet;
	@class TDChanBanExceptionSheet;
	@class TDChanBanSheet;
	@class TDChanInviteExceptionSheet;
	@class TDChannelSheet;
	@class THOPluginProtocol;
	@class THOTextualPluginItem;
	@class THOUnicodeHelper;
	@class TLOFileLogger;
	@class TLOFileWithContent;
	@class TLOGrowlController;
	@class TLOInputHistory;
	@class TLOKeyEventHandler;
	@class TLOLanguagePreferences;
	@class TLOLinkParser;
	@class TLONickCompletionStatus;
	@class TLOPopupPrompts;
	@class TLORegularExpression;
	@class TLOSocketClient;
	@class TLOSoundPlayer;
	@class TLOTimer;
	@class TLOTimerCommand;
	@class TLOpenLink;
	@class TPCOtherTheme;
	@class TPCPreferences;
	@class TPCPreferencesMigrationAssistant;
	@class TPCViewTheme;
	@class TVCDockIcon;
	@class TVCImageURLParser;
	@class TVCInputPromptDialog;
	@class TVCInputTextField;
	@class TVCInputTextFieldBackground;
	@class TVCListSeparatorCell;
	@class TVCListView;
	@class TVCLogController;
	@class TVCLogLine;
	@class TVCLogPolicy;
	@class TVCLogScriptEventSink;
	@class TVCLogView;
	@class TVCMainWindow;
	@class TVCMainWindowSegmentedCell;
	@class TVCMainWindowSegmentedControl;
	@class TVCMemberList;
	@class TVCMemberListCell;
	@class TVCServerList;
	@class TVCServerListCell;
	@class TVCTextFieldSTextView;
	@class TVCTextFormatterMenu;
	@class TVCThinSplitView;
	@class TVCWebViewAutoScroll;
	@class TXMasterController;
	@class TXMenuController;

	/* 3rd Party Extensions. */

	#import "AGKeychain.h"
	#import "DDExtensions.h"
	#import "DDInvocation.h"
	#import "GCDAsyncSocket.h"
	#import "GCDAsyncSocketExtensions.h"
	#import "GTMBase64.h"
	#import "GTMDefines.h"
	#import "GTMGarbageCollection.h"
	#import "GTMEncodeHTML.h"
	#import "GTMEncodeURL.h"
	#import "RLMAsyncSocket.h"
	#import "RegexKitLite.h"

	/* IRC Controllers — Core. */

	#import "IRC.h"
	#import "IRCAddressBook.h"
	#import "IRCChannel.h"
	#import "IRCChannelConfig.h"
	#import "IRCChannelMode.h"
	#import "IRCClient.h"
	#import "IRCClientConfig.h"
	#import "IRCColorFormat.h"
	#import "IRCConnection.h"
	#import "IRCExtras.h"
	#import "IRCISupportInfo.h"
	#import "IRCMessage.h"
	#import "IRCModeInfo.h"
	#import "IRCPrefix.h"
	#import "IRCSendingMessage.h"
	#import "IRCTreeItem.h"
	#import "IRCUser.h"
	#import "IRCWorld.h"
	#import "IRCWorldConfig.h"

	/* Framework Extensions (Helpers). */

	#import "NSArrayHelper.h"
	#import "NSBundleHelper.h"
	#import "NSColorHelper.h"
	#import "NSDataHelper.h"
	#import "NSDateHelper.h"
	#import "NSDictionaryHelper.h"
	#import "NSFontHelper.h"
	#import "NSNumberHelper.h"
	#import "NSOutlineViewHelper.h"
	#import "NSPasteboardHelper.h"
	#import "NSRectHelper.h"
	#import "NSSplitViewHelper.h"
	#import "NSStringHelper.h"
	#import "NSTextFieldHelper.h"
	#import "NSWindowHelper.h"

	/* Dialogs. */

	#import "TDCSheetBase.h"
	#import "TDCAboutPanel.h"
	#import "TDCAddressBookSheet.h"
	#import "TDCHighlightSheet.h"
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
	#import "THOPluginProtocol.h"
	#import "THOUnicodeHelper.h"

	/* Library. */

	#import "TLOFileLogger.h"
	#import "TLOFileWithContent.h"
	#import "TLOGrowlController.h"
	#import "TLOInputHistory.h"
	#import "TLOKeyEventHandler.h"
	#import "TLOLanguagePreferences.h"
	#import "TLOLinkParser.h"
	#import "TLONickCompletionStatus.h"
	#import "TLOPopupPrompts.h"
	#import "TLORegularExpression.h"
	#import "TLOSocketClient.h"
	#import "TLOSoundPlayer.h"
	#import "TLOTimer.h"
	#import "TLOTimerCommand.h"
	#import "TLOpenLink.h"

	/* Preferences. */

	#import "TPCOtherTheme.h"
	#import "TPCPreferences.h"
	#import "TPCPreferencesMigrationAssistant.h"
	#import "TPCViewTheme.h"

	/* View Controllers. */

	#import "TVCDockIcon.h"
	#import "TVCImageURLParser.h"
	#import "TVCInputPromptDialog.h"
	#import "TVCInputTextField.h"
	#import "TVCListSeparatorCell.h"
	#import "TVCListView.h"
	#import "TVCLogController.h"
	#import "TVCLogLine.h"
	#import "TVCLogPolicy.h"
	#import "TVCLogRenderer.h"
	#import "TVCLogScriptEventSink.h"
	#import "TVCLogView.h"
	#import "TVCMainWindow.h"
	#import "TVCMainWindowSegmentedControl.h"
	#import "TVCMemberList.h"
	#import "TVCMemberListCell.h"
	#import "TVCServerList.h"
	#import "TVCServerListCell.h"
	#import "TVCTextField.h"
	#import "TVCTextFormatterMenu.h"
	#import "TVCThinSplitView.h"
	#import "TVCWebViewAutoScroll.h"

	/* Master Controllers — Root. */

	#import "TXGlobalModels.h"
	#import "TXMasterController.h"
	#import "TXMenuController.h"
#endif

/* @end */