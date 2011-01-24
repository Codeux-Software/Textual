// Created by Codeux Software <support AT codeux DOT com> <https://github.com/codeux/Textual>
// You can redistribute it and/or modify it under the new BSD license.

#ifdef __OBJC__
	#include <Cocoa/Cocoa.h>
	#include <Carbon/Carbon.h>
	#include <WebKit/WebKit.h>
	#include <Security/Security.h>
	#include <SystemConfiguration/SystemConfiguration.h>
	
	#define BOOLReverseValue(b)		((b == YES) ? NO : YES)

	#ifdef DEBUG
		#define LOG(...) NSLog(__VA_ARGS__);
		#define LOG_METHOD NSLog(@"%s", __func__);
		#define APPLOG(...) NSLog(__VA_ARGS__);
		#define START_WATCH			CFAbsoluteTime start_time__ = CFAbsoluteTimeGetCurrent();
		#define END_WATCH			LOG(@"### time elapsed: %f", CFAbsoluteTimeGetCurrent() - start_time__);
	#else
		#define LOG(...) ;
		#define LOG_METHOD ;
		#define APPLOG(...) { if (NSAppEnableApplicationLog) NSLog(__VA_ARGS__); }
		#define START_WATCH	;
		#define END_WATCH ;
	#endif

	#define CFItemRefToID(s)			(id)s

	typedef unsigned long long TXFSLongInt; // filesizes

	#import "GlobalModels.h"
	#import "RegexKitLite.h"
	#import "AsyncSocket.h"
	#import "AsyncSocketExtensions.h"
	#import "TinyGrowlClient.h"
	#import "GrowlController.h"
	#import "Preferences.h"
	#import "OtherTheme.h"
	#import "FileWithContent.h"
	#import "ViewTheme.h"
	#import "LogView.h"
	#import "ChatBox.h"
	#import "LogLine.h"
	#import "DockIcon.h"
	#import "TreeView.h"
	#import "ListView.h"
	#import "LogPolicy.h"
	#import "TextField.h"
	#import "KeyEventHandler.h"
	#import "MainWindow.h"
	#import "LogRenderer.h"
	#import "DialogWindow.h"
	#import "ThinSplitView.h"
	#import "InputTextField.h"
	#import "ImageURLParser.h"
	#import "ServerTreeView.h"
	#import "MarkedScroller.h"
	#import "WebViewAutoScroll.h"
	#import "LogScriptEventSink.h"
	#import "LogController.h"
	#import "MemberListViewCell.h"
	#import "FieldEditorTextView.h"
	#import "TableProgressIndicator.h"
	#import "TextFieldWithDisabledState.h"
	#import "Timer.h"
	#import "TCPClient.h"
	#import "TCPServer.h"
	#import "URLParser.h"
	#import "AGKeychain.h"
	#import "FileLogger.h"
	#import "InputHistory.h"
	#import "LanguagePreferences.h"
	#import "GTMBase64.h"
	#import "URLOpener.h"
	#import "GTMDefines.h"
	#import "NSData+Kana.h"
	#import "SoundPlayer.h"
	#import "NSFontHelper.h"
	#import "NSDataHelper.h"
	#import "NSRectHelper.h"
	#import "UnicodeHelper.h"
	#import "NSColorHelper.h"
	#import "NSArrayHelper.h"
	#import "NSWindowHelper.h"
	#import "NSStringHelper.h"
	#import "NSNumberHelper.h"
	#import "GTMNSString+HTML.h"
	#import "NSPasteboardHelper.h"
	#import "NSDictionaryHelper.h"
	#import "DDInvocationGrabber.h"
	#import "GTMGarbageCollection.h"
	#import "NSObject+DDExtensions.h"
	#import "GTMNSString+URLArguments.h"
	#import "IRC.h"
	#import "IRCUser.h"
	#import "MemberListViewCell.h"
	#import "MemberListView.h"
	#import "IRCExtras.h"
	#import "IRCTreeItem.h"
	#import "IRCWorldConfig.h"
	#import "IRCWorld.h"
	#import "IRCClientConfig.h"
	#import "IRCISupportInfo.h"
	#import "IRCChannelMode.h"
	#import "IRCConnection.h"
	#import "IRCChannelConfig.h"
	#import "SheetBase.h"
	#import "ModeSheet.h"
	#import "NickSheet.h"
	#import "AboutPanel.h"
	#import "TopicSheet.h"
	#import "ListDialog.h"
	#import "InviteSheet.h"
	#import "SoundWrapper.h"
	#import "ChannelSheet.h"
	#import "WelcomeSheet.h"
	#import "ChanBanSheet.h"
	#import "ScriptsWrapper.h"
	#import "AddressBook.h"
	#import "AddressBookSheet.h"
	#import "ServerSheet.h"
	#import "InputPromptDialog.h"
	#import "ChanBanExceptionSheet.h"
	#import "IRCPrefix.h"
	#import "IRCChannel.h"
	#import "IRCMessage.h"
	#import "IRCClient.h"
	#import "TimerCommand.h"
	#import "IRCSendingMessage.h"
	#import "PreferencesController.h"
	#import "PluginProtocol.h"
	#import "NSBundleHelper.h"
	#import "TextualPluginItem.h"
	#import "MenuController.h"
	#import "NickCompletionStatus.h"
	#import "MasterController.h"
#endif

/* @end */