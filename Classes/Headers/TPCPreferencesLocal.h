/* ********************************************************************* 
                  _____         _               _
                 |_   _|____  _| |_ _   _  __ _| |
                   | |/ _ \ \/ / __| | | |/ _` | |
                   | |  __/>  <| |_| |_| | (_| | |
                   |_|\___/_/\_\\__|\__,_|\__,_|_|

 Copyright (c) 2008 - 2010 Satoshi Nakagawa <psychs AT limechat DOT net>
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

#import "TLOGrowlController.h"
#import "TPCPreferences.h"

NS_ASSUME_NONNULL_BEGIN

TEXTUAL_EXTERN NSString * const TPCPreferencesThemeNameDefaultsKey;
TEXTUAL_EXTERN NSString * const TPCPreferencesThemeFontNameDefaultsKey;
TEXTUAL_EXTERN NSString * const TPCPreferencesThemeFontSizeDefaultsKey;

TEXTUAL_EXTERN NSString * const TPCPreferencesThemeNameMissingLocallyDefaultsKey;
TEXTUAL_EXTERN NSString * const TPCPreferencesThemeFontNameMissingLocallyDefaultsKey;

TEXTUAL_EXTERN NSUInteger const TPCPreferencesDictionaryVersion;

typedef NS_ENUM(NSUInteger, TXNicknameHighlightMatchType) {
	TXNicknameHighlightPartialMatchType = 0,
	TXNicknameHighlightExactMatchType,
    TXNicknameHighlightRegularExpressionMatchType,
};

typedef NS_ENUM(NSUInteger, TXTabKeyAction) {
	TXTabKeyNicknameCompleteAction = 0,
	TXTabKeyUnreadChannelAction,
	TXTabKeyNoneTypeAction = 100,
};

typedef NS_ENUM(NSUInteger, TXUserDoubleClickAction) {
	TXUserDoubleClickWhoisAction = 100,
	TXUserDoubleClickPrivateMessageAction = 200,
	TXUserDoubleClickInsertTextFieldAction = 300,
};

typedef NS_ENUM(NSUInteger, TXNoticeSendLocationType) {
	TXNoticeSendServerConsoleType = 0,
	TXNoticeSendSelectedChannelType = 1,
	TXNoticeSendToQueryDestinationType = 2,
};

typedef NS_ENUM(NSUInteger, TXCommandWKeyAction) {
	TXCommandWKeyCloseWindowAction = 0,
	TXCommandWKeyPartChannelAction = 1,
	TXCommandWKeyDisconnectAction = 2,
	TXCommandWKeyTerminateAction = 3,
};

typedef NS_ENUM(NSUInteger, TXHostmaskBanFormat) {
	TXHostmaskBanWHNINFormat  = 0, // With Hostmask, No Username/Nickname
	TXHostmaskBanWHAINNFormat = 1, // With Hostmask and Username, No Nickname
	TXHostmaskBanWHANNIFormat = 2, // With Hostmask and Nickname, No Username
	TXHostmaskBanExactFormat  = 3, // Exact Match
};

typedef NS_ENUM(NSUInteger, TVCMainWindowTextViewFontSize) {
	TVCMainWindowTextViewFontNormalSize			= 1,
	TVCMainWindowTextViewFontLargeSize			= 2,
	TVCMainWindowTextViewFontExtraLargeSize		= 3,
	TVCMainWindowTextViewFontHumongousSize		= 4,
};

typedef NS_ENUM(NSUInteger, TXFileTransferRequestReplyAction) {
	TXFileTransferRequestReplyIgnoreAction						= 1,
	TXFileTransferRequestReplyOpenDialogAction					= 2,
	TXFileTransferRequestReplyAutomaticallyDownloadAction		= 3,
};

typedef NS_ENUM(NSUInteger, TXFileTransferIPAddressDetectionMethod) {
	/* integers are out of order to preserve existing preferences */
	TXFileTransferIPAddressRouterOnlyMethod				= 3,
	TXFileTransferIPAddressRouterAndFirstPartyMethod	= 1,
	TXFileTransferIPAddressRouterAndThirdPartyMethod	= 4,
	TXFileTransferIPAddressManualDetectionMethod		= 2,
};

typedef NS_ENUM(NSUInteger, TXChannelViewArrangement) {
	TXChannelViewArrangedHorizontally		= 0,
	TXChannelViewArrangedVertically 		= 1
};

@interface TPCPreferences (TPCPreferencesLocal)
+ (BOOL)appNapEnabled;

+ (BOOL)developerModeEnabled;

+ (nullable NSString *)masqueradeCTCPVersion;

#if TEXTUAL_BUILT_WITH_SPARKLE_ENABLED == 1
+ (BOOL)receiveBetaUpdates;
#endif

+ (BOOL)channelNavigationIsServerSpecific;

+ (BOOL)automaticallyDetectHighlightSpam;

+ (BOOL)rememberServerListQueryStates;

+ (TVCMainWindowTextViewFontSize)mainTextViewFontSize;
+ (BOOL)focusMainTextViewOnSelectionChange;

+ (BOOL)logToDisk; // Checks whether checkbox for logging is checked.
+ (BOOL)logToDiskIsEnabled; // Checks whether checkbox is checked and whether an actual path is configured.

+ (BOOL)postNotificationsWhileInFocus;

+ (BOOL)automaticallyFilterUnicodeTextSpam;

+ (BOOL)conversationTrackingIncludesUserModeSymbol;

+ (NSString *)defaultRealName;
+ (NSString *)defaultUsername;
+ (NSString *)defaultNickname;
+ (nullable NSString *)defaultAwayNickname;
+ (NSString *)defaultKickMessage;

+ (NSString *)IRCopDefaultKillMessage;
+ (NSString *)IRCopDefaultGlineMessage;
+ (NSString *)IRCopDefaultShunMessage;

#if TEXTUAL_BUILT_WITH_ADVANCED_ENCRYPTION == 1
+ (BOOL)textEncryptionIsOpportunistic;
+ (BOOL)textEncryptionIsRequired;
+ (BOOL)textEncryptionIsEnabled;
#endif

+ (BOOL)enableEchoMessageCapability;

+ (BOOL)giveFocusOnMessageCommand;

+ (BOOL)amsgAllConnections;
+ (BOOL)awayAllConnections;
+ (BOOL)nickAllConnections;
+ (BOOL)clearAllOnlyOnActiveServer;

+ (BOOL)memberListSortFavorsServerStaff;
+ (BOOL)memberListUpdatesUserInfoPopoverOnScroll;
+ (BOOL)memberListDisplayNoModeSymbol;

+ (TXNoticeSendLocationType)locationToSendNotices;

+ (BOOL)disableNicknameColorHashing;

+ (BOOL)displayDockBadge;
+ (BOOL)displayPublicMessageCountOnDockBadge;

+ (BOOL)setAwayOnScreenSleep;
+ (BOOL)disconnectOnSleep;

+ (BOOL)autoAddScrollbackMark;
+ (BOOL)showInlineImages TEXTUAL_DEPRECATED("Use -showInlineMedia instead");
+ (BOOL)showInlineMedia;
+ (BOOL)showJoinLeave;
+ (BOOL)displayServerMOTD;
+ (BOOL)rightToLeftFormatting;
+ (BOOL)removeAllFormatting;

+ (NSUInteger)trackUserAwayStatusMaximumChannelSize;

+ (BOOL)invertSidebarColors;

+ (BOOL)invertSidebarColorsPreferenceUserConfigurable;

+ (BOOL)disableSidebarTranslucency;
+ (BOOL)hideMainWindowSegmentedController;

+ (BOOL)reloadScrollbackOnLaunch;

+ (BOOL)automaticallyReloadCustomThemesWhenTheyChange;

+ (BOOL)autoJoinOnInvite;

+ (BOOL)confirmQuit;
+ (BOOL)rejoinOnKick;
+ (BOOL)copyOnSelect;
+ (BOOL)replyToCTCPRequests;
+ (BOOL)autojoinWaitsForNickServ TEXTUAL_DEPRECATED("This option is now server specific. It is maintained here to read any previous, user-configured value to use a default");

+ (BOOL)inputHistoryIsChannelSpecific;

+ (TXCommandWKeyAction)commandWKeyAction;

+ (BOOL)commandReturnSendsMessageAsAction;
+ (BOOL)controlEnterSnedsMessage;

+ (BOOL)openBrowserInBackground;

+ (BOOL)connectOnDoubleclick;
+ (BOOL)disconnectOnDoubleclick;
+ (BOOL)joinOnDoubleclick;
+ (BOOL)leaveOnDoubleclick;

+ (NSUInteger)autojoinMaximumChannelJoins;
+ (NSTimeInterval)autojoinDelayBetweenChannelJoins;

+ (TXUserDoubleClickAction)userDoubleClickOption;

+ (TXHostmaskBanFormat)banFormat;

+ (BOOL)webKit2Enabled;
+ (BOOL)webKit2ProcessPoolSizeLimited;
+ (BOOL)webKit2PreviewLinks;

+ (NSString *)themeName;
+ (NSString *)themeNameDefault;

+ (NSString *)themeNicknameFormat;
+ (NSString *)themeNicknameFormatDefault;

+ (NSString *)themeTimestampFormat;
+ (NSString *)themeTimestampFormatDefault;

+ (CGFloat)mainWindowTransparency;

+ (nullable NSFont *)themeChannelViewFont;
+ (NSString *)themeChannelViewFontName;
+ (NSString *)themeChannelViewFontNameDefault;
+ (CGFloat)themeChannelViewFontSize;

+ (BOOL)themeNicknameFormatPreferenceUserConfigurable;
+ (BOOL)themeTimestampFormatPreferenceUserConfigurable;
+ (BOOL)themeChannelViewFontPreferenceUserConfigurable;

+ (BOOL)themeChannelViewUsesCustomScrollers;

+ (NSUInteger)scrollbackSaveLimit;
+ (NSUInteger)scrollbackVisibleLimit;

+ (TXChannelViewArrangement)channelViewArrangement;

+ (BOOL)soundIsMuted;

+ (BOOL)onlySpeakEventsForSelection;

+ (BOOL)channelMessageSpeakChannelName;
+ (BOOL)channelMessageSpeakNickname;

+ (nullable NSString *)soundForEvent:(TXNotificationType)event;

+ (BOOL)speakEvent:(TXNotificationType)event;
+ (BOOL)growlEnabledForEvent:(TXNotificationType)event;
+ (BOOL)disabledWhileAwayForEvent:(TXNotificationType)event;
+ (BOOL)bounceDockIconForEvent:(TXNotificationType)event;
+ (BOOL)bounceDockIconRepeatedlyForEvent:(TXNotificationType)event;

+ (TXTabKeyAction)tabKeyAction;

+ (BOOL)fileTransferRequestsAreReversed;
+ (BOOL)fileTransfersPreventIdleSystemSleep;

+ (TXFileTransferRequestReplyAction)fileTransferRequestReplyAction;
+ (TXFileTransferIPAddressDetectionMethod)fileTransferIPAddressDetectionMethod;

+ (uint16_t)fileTransferPortRangeStart;
+ (uint16_t)fileTransferPortRangeEnd;

+ (nullable NSString *)fileTransferManuallyEnteredIPAddress;
+ (nullable NSString *)fileTransferIPAddressInterfaceName;

+ (nullable NSString *)tabCompletionSuffix;

+ (BOOL)tabCompletionDoNotAppendWhitespace;
+ (BOOL)tabCompletionCutForwardToFirstWhitespace;

+ (nullable NSArray<NSDictionary *> *)clientList;

+ (TXNicknameHighlightMatchType)highlightMatchingMethod;

+ (BOOL)logHighlights;
+ (BOOL)highlightCurrentNickname;

+ (CGFloat)swipeMinimumLength;

+ (nullable NSArray<NSString *> *)highlightMatchKeywords;
+ (nullable NSArray<NSString *> *)highlightExcludeKeywords;

+ (NSDictionary<NSString *, id> *)defaultPreferences;

+ (BOOL)textFieldAutomaticSpellCheck;
+ (BOOL)textFieldAutomaticGrammarCheck;
+ (BOOL)textFieldAutomaticSpellCorrection;
+ (BOOL)textFieldSmartCopyPaste;
+ (BOOL)textFieldSmartQuotes;
+ (BOOL)textFieldSmartDashes;
+ (BOOL)textFieldSmartLinks;
+ (BOOL)textFieldDataDetectors;
+ (BOOL)textFieldTextReplacement;
@end

NS_ASSUME_NONNULL_END
