/* ********************************************************************* 
       _____        _               _    ___ ____   ____
      |_   _|___  _| |_ _   _  __ _| |  |_ _|  _ \ / ___|
       | |/ _ \ \/ / __| | | |/ _` | |   | || |_) | |
       | |  __/>  <| |_| |_| | (_| | |   | ||  _ <| |___
       |_|\___/_/\_\\__|\__,_|\__,_|_|  |___|_| \_\\____|

 Copyright (c) 2008 - 2010 Satoshi Nakagawa <psychs AT limechat DOT net>
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

#import "TextualApplication.h"

#define TXDefaultTextualLogStyle			@"resource:Simplified Light"
#define TXDefaultTextualLogFont				@"Lucida Grande"
#define TXDefaultTextualTimestampFormat		TLOFileLoggerTwentyFourHourClockFormat

#define TPCPreferencesThemeNameDefaultsKey						@"Theme -> Name"
#define TPCPreferencesThemeFontNameDefaultsKey					@"Theme -> Font Name"

#define TXDefaultFileTransferPortRangeStart				1096
#define TXDefaultFileTransferPortRangeEnd				1115

typedef enum TXNicknameHighlightMatchType : NSInteger {
	TXNicknameHighlightPartialMatchType = 0,
	TXNicknameHighlightExactMatchType,
    TXNicknameHighlightRegularExpressionMatchType,
} TXNicknameHighlightMatchType;

typedef enum TXTabKeyAction : NSInteger {
	TXTabKeyNickCompleteAction = 0,
	TXTabKeyUnreadChannelAction,
	TXTabKeyNoneTypeAction = 100,
} TXTabKeyAction;

typedef enum TXUserDoubleClickAction : NSInteger {
	TXUserDoubleClickWhoisAction = 100,
	TXUserDoubleClickPrivateMessageAction = 200,
	TXUserDoubleClickInsertTextFieldAction = 300,
} TXUserDoubleClickAction;

typedef enum TXNoticeSendLocationType : NSInteger {
	TXNoticeSendServerConsoleType = 0,
	TXNoticeSendCurrentChannelType = 1,
} TXNoticeSendLocationType;

typedef enum TXCommandWKeyAction : NSInteger {
	TXCommandWKeyCloseWindowAction = 0,
	TXCommandWKeyPartChannelAction = 1,
	TXCommandWKeyDisconnectAction = 2,
	TXCommandWKeyTerminateAction = 3,
} TXCommandWKeyAction;

typedef enum TXHostmaskBanFormat : NSInteger {
	TXHostmaskBanWHNINFormat  = 0, // With Hostmask, No Username/Nickname
	TXHostmaskBanWHAINNFormat = 1, // With Hostmask and Username, No Nickname
	TXHostmaskBanWHANNIFormat = 2, // With Hostmask and Nickname, No Username
	TXHostmaskBanExactFormat  = 3, // Exact Match
} TXHostmaskBanFormat;

typedef enum TXMainTextBoxFontSize : NSInteger {
	TXMainTextBoxFontNormalSize			= 1,
	TXMainTextBoxFontLargeSize			= 2,
	TXMainTextBoxFontExtraLargeSize		= 3,
} TXMainTextBoxFontSize;

typedef enum TXFileTransferRequestReplyAction : NSInteger {
	TXFileTransferRequestReplyIgnoreAction						= 1,
	TXFileTransferRequestReplyOpenDialogAction					= 2,
	TXFileTransferRequestReplyAutomaticallyDownloadAction		= 3,
} TXFileTransferRequestReplyAction;

typedef enum TXFileTransferIPAddressDetectionMethod : NSInteger {
	TXFileTransferIPAddressAutomaticDetectionMethod			= 1,
	TXFileTransferIPAddressManualDetectionMethod			= 2,
} TXFileTransferIPAddressDetectionMethod;

/* These actions are used for import purposes. */
typedef enum TPCPreferencesKeyReloadAction : NSInteger {
	TPCPreferencesKeyReloadDockIconBadgesAction,
	TPCPreferencesKeyReloadHighlightKeywordsAction,
	TPCPreferencesKeyReloadHighlightLoggingAction,
	TPCPreferencesKeyReloadInputHistoryScopeAction,
	TPCPreferencesKeyReloadMainWindowTransparencyLevelAction,
	TPCPreferencesKeyReloadMemberListAction,
	TPCPreferencesKeyReloadMemberListSortOrderAction,
	TPCPreferencesKeyReloadMemberListUserBadgesAction,
	TPCPreferencesKeyReloadPreferencesChangedAction,
	TPCPreferencesKeyReloadServerListAction,
	TPCPreferencesKeyReloadStyleAction,
	TPCPreferencesKeyReloadStyleWithTableViewsAction,
	TPCPreferencesKeyReloadTextDirectionAction,
	TPCPreferencesKeyReloadTextFieldFontSizeAction,
	TPCPreferencesKeyReloadTextFieldSegmentedControllerOriginAction
} TPCPreferencesKeyReloadAction;

@interface TPCPreferences : NSObject
+ (BOOL)isDefaultIRCClient;

+ (BOOL)sandboxEnabled;

+ (NSDate *)applicationLaunchDate;
+ (NSTimeInterval)timeIntervalSinceApplicationLaunch;
+ (NSTimeInterval)timeIntervalSinceApplicationInstall;
+ (void)saveTimeIntervalSinceApplicationInstall;

+ (NSInteger)applicationRunCount;
+ (void)updateApplicationRunCount;

+ (NSSize)minimumWindowSize;
+ (NSRect)defaultWindowFrame;

+ (BOOL)featureAvailableToOSXLion;
+ (BOOL)featureAvailableToOSXMountainLion;
+ (BOOL)featureAvailableToOSXMavericks;

+ (BOOL)runningInHighResolutionMode;

+ (NSString *)masqueradeCTCPVersion;

+ (NSString *)applicationName;
+ (NSString *)applicationBundleIdentifier;

+ (NSInteger)applicationProcessID;

+ (NSString *)gitBuildReference;
+ (NSString *)gitCommitCount;

+ (NSDictionary *)textualInfoPlist;

+ (NSString *)applicationBundlePath;
+ (NSString *)applicationSupportFolderPath;
+ (NSString *)applicationTemporaryFolderPath;
+ (NSString *)applicationCachesFolderPath;
+ (NSString *)applicationResourcesFolderPath;
+ (NSString *)customExtensionFolderPath;
+ (NSString *)customThemeFolderPath;
+ (NSString *)bundledThemeFolderPath;
+ (NSString *)bundledExtensionFolderPath;
+ (NSString *)bundledScriptFolderPath;
+ (NSString *)systemUnsupervisedScriptFolderPath; // Textual's folder.
+ (NSString *)systemUnsupervisedScriptFolderRootPath; // Root path.
+ (NSString *)userHomeDirectoryPathOutsideSandbox;
+ (NSString *)userDownloadFolderPath;

#ifdef TEXTUAL_BUILT_WITH_ICLOUD_SUPPORT
+ (NSString *)applicationUbiquitousContainerPath;

+ (NSString *)cloudCustomThemeFolderPath; // Actual iCloud folder.
+ (NSString *)cloudCustomThemeCachedFolderPath; // Where iCloud folder is cached locally.
#endif

+ (BOOL)channelNavigationIsServerSpecific;

+ (BOOL)automaticallyDetectHighlightSpam;

+ (BOOL)rememberServerListQueryStates;

+ (TXMainTextBoxFontSize)mainTextBoxFontSize;

+ (BOOL)logTranscript;

+ (BOOL)postNotificationsWhileInFocus;

+ (BOOL)automaticallyFilterUnicodeTextSpam;

+ (BOOL)conversationTrackingIncludesUserModeSymbol;

+ (NSURL *)transcriptFolder;
+ (void)setTranscriptFolder:(id)value;

+ (NSArray *)publicIRCCommandList;
+ (NSInteger)indexOfIRCommand:(NSString *)command;
+ (NSInteger)indexOfIRCommand:(NSString *)command publicSearch:(BOOL)isPublic;

+ (NSArray *)IRCCommandIndex:(BOOL)isPublic;

+ (NSString *)defaultRealname;
+ (NSString *)defaultUsername;
+ (NSString *)defaultNickname;
+ (NSString *)defaultAwayNickname;
+ (NSString *)defaultKickMessage;

+ (NSString *)IRCopDefaultKillMessage;
+ (NSString *)IRCopDefaultGlineMessage;
+ (NSString *)IRCopDefaultShunMessage;

+ (BOOL)giveFocusOnMessageCommand;

#ifdef TEXTUAL_BUILT_WITH_ICLOUD_SUPPORT
+ (BOOL)syncPreferencesToTheCloud; /* ZE CLOUD! */
+ (BOOL)syncPreferencesToTheCloudLimitedToServers;
#endif

+ (BOOL)amsgAllConnections;
+ (BOOL)awayAllConnections;
+ (BOOL)nickAllConnections;
+ (BOOL)clearAllOnlyOnActiveServer;

+ (BOOL)memberListSortFavorsServerStaff;

+ (TXNoticeSendLocationType)locationToSendNotices;

+ (BOOL)disableNicknameColorHashing;

+ (BOOL)displayDockBadge;
+ (BOOL)displayPublicMessageCountOnDockBadge;

+ (BOOL)setAwayOnScreenSleep;

+ (BOOL)autoAddScrollbackMark;
+ (BOOL)showInlineImages;
+ (BOOL)showJoinLeave;
+ (BOOL)displayServerMOTD;
+ (BOOL)rightToLeftFormatting;
+ (BOOL)removeAllFormatting;

+ (NSInteger)trackUserAwayStatusMaximumChannelSize;

+ (BOOL)useLargeFontForSidebars;
+ (BOOL)invertSidebarColors;
+ (BOOL)hideMainWindowSegmentedController;

+ (BOOL)reloadScrollbackOnLaunch;

+ (BOOL)autoJoinOnInvite;

+ (BOOL)confirmQuit;
+ (BOOL)rejoinOnKick;
+ (BOOL)copyOnSelect;
+ (BOOL)replyToCTCPRequests;
+ (BOOL)autojoinWaitsForNickServ;

+ (BOOL)inputHistoryIsChannelSpecific;

+ (TXCommandWKeyAction)commandWKeyAction;

+ (BOOL)commandReturnSendsMessageAsAction;
+ (BOOL)controlEnterSnedsMessage;

+ (BOOL)openBrowserInBackground;

+ (BOOL)connectOnDoubleclick;
+ (BOOL)disconnectOnDoubleclick;
+ (BOOL)joinOnDoubleclick;
+ (BOOL)leaveOnDoubleclick;

+ (NSInteger)autojoinMaxChannelJoins;

+ (TXUserDoubleClickAction)userDoubleClickOption;

+ (TXHostmaskBanFormat)banFormat;

+ (TXFSLongInt)inlineImagesMaxFilesize;

+ (NSInteger)inlineImagesMaxWidth;
+ (void)setInlineImagesMaxWidth:(NSInteger)value;

+ (NSInteger)inlineImagesMaxHeight;
+ (void)setInlineImagesMaxHeight:(NSInteger)value;

+ (BOOL)inlineImagesDownloadsAllIgnoringCommonPatterns;

+ (NSString *)themeName;
+ (NSString *)themeNicknameFormat;
+ (NSString *)themeTimestampFormat;

+ (double)themeTransparency;

+ (NSFont *)themeChannelViewFont;
+ (NSString *)themeChannelViewFontName;
+ (double)themeChannelViewFontSize;

+ (void)setThemeName:(NSString *)value;
+ (void)setThemeNameWithExistenceCheck:(NSString *)value;

+ (void)setThemeChannelViewFontName:(NSString *)value;
+ (void)setThemeChannelViewFontNameWithExistenceCheck:(NSString *)value;

+ (void)setThemeChannelViewFontSize:(double)value;

+ (NSInteger)maxLogLines;
+ (void)setMaxLogLines:(NSInteger)value;

+ (NSString *)titleForEvent:(TXNotificationType)event;
+ (NSString *)soundForEvent:(TXNotificationType)event;

+ (BOOL)speakEvent:(TXNotificationType)event;
+ (BOOL)growlEnabledForEvent:(TXNotificationType)event;
+ (BOOL)disabledWhileAwayForEvent:(TXNotificationType)event;
+ (BOOL)bounceDockIconForEvent:(TXNotificationType)event;

+ (void)setSound:(NSString *)value forEvent:(TXNotificationType)event;
+ (void)setGrowlEnabled:(BOOL)value forEvent:(TXNotificationType)event;
+ (void)setDisabledWhileAway:(BOOL)value forEvent:(TXNotificationType)event;
+ (void)setBounceDockIcon:(BOOL)value forEvent:(TXNotificationType)event;
+ (void)setEventIsSpoken:(BOOL)value forEvent:(TXNotificationType)event;

+ (TXTabKeyAction)tabKeyAction;

+ (BOOL)fileTransferRequestsAreReversed;

+ (TXFileTransferRequestReplyAction)fileTransferRequestReplyAction;
+ (TXFileTransferIPAddressDetectionMethod)fileTransferIPAddressDetectionMethod;

+ (NSInteger)fileTransferPortRangeStart;
+ (NSInteger)fileTransferPortRangeEnd;

+ (void)setFileTransferPortRangeStart:(NSInteger)value;
+ (void)setFileTransferPortRangeEnd:(NSInteger)value;

+ (NSString *)fileTransferManuallyEnteredIPAddress;

+ (NSString *)tabCompletionSuffix;
+ (void)setTabCompletionSuffix:(NSString *)value;

+ (NSDictionary *)loadWorld;
+ (void)saveWorld:(NSDictionary *)value;

+ (TXNicknameHighlightMatchType)highlightMatchingMethod;

+ (BOOL)logHighlights;
+ (BOOL)highlightCurrentNickname;

+ (CGFloat)swipeMinimumLength;

+ (NSArray *)highlightMatchKeywords;
+ (NSArray *)highlightExcludeKeywords;

+ (void)cleanUpHighlightKeywords;

+ (void)defaultIRCClientPrompt:(BOOL)forced;

+ (NSDictionary *)defaultPreferences;

+ (void)initPreferences;

#pragma mark -
#pragma mark NSTextView Preferences

+ (BOOL)textFieldAutomaticSpellCheck;
+ (void)setTextFieldAutomaticSpellCheck:(BOOL)value;

+ (BOOL)textFieldAutomaticGrammarCheck;
+ (void)setTextFieldAutomaticGrammarCheck:(BOOL)value;

+ (BOOL)textFieldAutomaticSpellCorrection;
+ (void)setTextFieldAutomaticSpellCorrection:(BOOL)value;

+ (BOOL)textFieldSmartCopyPaste;
+ (void)setTextFieldSmartCopyPaste:(BOOL)value;

+ (BOOL)textFieldSmartQuotes;
+ (void)setTextFieldSmartQuotes:(BOOL)value;

+ (BOOL)textFieldSmartDashes;
+ (void)setTextFieldSmartDashes:(BOOL)value;

+ (BOOL)textFieldSmartLinks;
+ (void)setTextFieldSmartLinks:(BOOL)value;

+ (BOOL)textFieldDataDetectors;
+ (void)setTextFieldDataDetectors:(BOOL)value;

+ (BOOL)textFieldTextReplacement;
+ (void)setTextFieldTextReplacement:(BOOL)value;

+ (BOOL)performValidationForKeyValues:(BOOL)duringInitialization;

/* The following should only be called by TPCPreferencesImportExport */
+ (void)performReloadActionForKeyValues:(NSArray *)prefKeys;
+ (void)performReloadActionForActionType:(TPCPreferencesKeyReloadAction)reloadAction;
@end
