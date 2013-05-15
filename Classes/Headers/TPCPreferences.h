/* ********************************************************************* 
       _____        _               _    ___ ____   ____
      |_   _|___  _| |_ _   _  __ _| |  |_ _|  _ \ / ___|
       | |/ _ \ \/ / __| | | |/ _` | |   | || |_) | |
       | |  __/>  <| |_| |_| | (_| | |   | ||  _ <| |___
       |_|\___/_/\_\\__|\__,_|\__,_|_|  |___|_| \_\\____|

 Copyright (c) 2010 — 2013 Codeux Software & respective contributors.
        Please see Contributors.pdf and Acknowledgements.pdf

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
#define TXDefaultTextualTimestampFormat		@"[%H:%M:%S]"

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

@interface TPCPreferences : NSObject
+ (BOOL)isDefaultIRCClient;

+ (BOOL)sandboxEnabled;

+ (NSTimeInterval)timeIntervalSinceApplicationLaunch;
+ (NSTimeInterval)timeIntervalSinceApplicationInstall;
+ (void)saveTimeIntervalSinceApplicationInstall;

+ (NSInteger)applicationRunCount;
+ (void)updateApplicationRunCount;

+ (NSSize)minimumWindowSize;
+ (NSRect)defaultWindowFrame;

+ (BOOL)featureAvailableToOSXLion;
+ (BOOL)featureAvailableToOSXMountainLion;

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
+ (NSString *)customScriptFolderPath;
+ (NSString *)customThemeFolderPath;
+ (NSString *)bundledThemeFolderPath;
+ (NSString *)bundledExtensionFolderPath;
+ (NSString *)bundledScriptFolderPath;
+ (NSString *)systemUnsupervisedScriptFolderPath;

+ (BOOL)channelNavigationIsServerSpecific;

+ (BOOL)logTranscript;

+ (NSString *)transcriptFolder;
+ (void)setTranscriptFolder:(id)value;

+ (void)startUsingTranscriptFolderSecurityScopedBookmark;
+ (void)stopUsingTranscriptFolderSecurityScopedBookmark;

+ (NSArray *)publicIRCCommandList;
+ (NSInteger)indexOfIRCommand:(NSString *)command;
+ (NSInteger)indexOfIRCommand:(NSString *)command publicSearch:(BOOL)isPublic;

+ (NSArray *)IRCCommandIndex:(BOOL)isPublic;

+ (NSString *)defaultRealname;
+ (NSString *)defaultUsername;
+ (NSString *)defaultNickname;
+ (NSString *)defaultAwayNickname;
+ (NSString *)defaultKickMessage;

+ (BOOL)handleIRCopAlerts;
+ (BOOL)handleServerNotices;

+ (NSString *)IRCopDefaultKillMessage;
+ (NSString *)IRCopDefaultGlineMessage;
+ (NSString *)IRCopDefaultShunMessage;
+ (NSString *)IRCopAlertMatch;

+ (BOOL)giveFocusOnMessageCommand;

+ (BOOL)amsgAllConnections;
+ (BOOL)awayAllConnections;
+ (BOOL)nickAllConnections;
+ (BOOL)clearAllOnlyOnActiveServer;

+ (BOOL)memberListSortFavorsServerStaff;

+ (TXNoticeSendLocationType)locationToSendNotices;

+ (BOOL)trackConversations;
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
+ (BOOL)processChannelModes;

+ (BOOL)confirmQuit;
+ (BOOL)rejoinOnKick;
+ (BOOL)copyOnSelect;
+ (BOOL)replyToCTCPRequests;
+ (BOOL)autojoinWaitsForNickServ;

+ (BOOL)inputHistoryIsChannelSpecific;

+ (TXCommandWKeyAction)commandWKeyAction;

+ (BOOL)openBrowserInBackground;

+ (BOOL)connectOnDoubleclick;
+ (BOOL)disconnectOnDoubleclick;
+ (BOOL)joinOnDoubleclick;
+ (BOOL)leaveOnDoubleclick;

+ (NSInteger)autojoinMaxChannelJoins;

+ (TXUserDoubleClickAction)userDoubleClickOption;

+ (TXHostmaskBanFormat)banFormat;

+ (NSInteger)inlineImagesMaxWidth;
+ (void)setInlineImagesMaxWidth:(NSInteger)value;

+ (NSString *)themeName;
+ (NSString *)themeNicknameFormat;
+ (NSString *)themeTimestampFormat;

+ (double)themeTransparency;

+ (NSFont *)themeChannelViewFont;
+ (NSString *)themeChannelViewFontName;
+ (double)themeChannelViewFontSize;

+ (void)setThemeName:(NSString *)value;
+ (void)setThemeChannelViewFontName:(NSString *)value;
+ (void)setThemeChannelViewFontSize:(double)value;

+ (NSInteger)maxLogLines;
+ (void)setMaxLogLines:(NSInteger)value;

+ (BOOL)stopGrowlOnActive;

+ (NSString *)titleForEvent:(TXNotificationType)event;
+ (NSString *)soundForEvent:(TXNotificationType)event;

+ (BOOL)speakEvent:(TXNotificationType)event;
+ (BOOL)growlEnabledForEvent:(TXNotificationType)event;
+ (BOOL)disabledWhileAwayForEvent:(TXNotificationType)event;

+ (void)setSound:(NSString *)value forEvent:(TXNotificationType)event;
+ (void)setGrowlEnabled:(BOOL)value forEvent:(TXNotificationType)event;
+ (void)setDisabledWhileAway:(BOOL)value forEvent:(TXNotificationType)event;
+ (void)setEventIsSpoken:(BOOL)value forEvent:(TXNotificationType)event;

+ (TXTabKeyAction)tabKeyAction;

+ (NSString *)tabCompletionSuffix;
+ (void)setTabCompletionSuffix:(NSString *)value;

+ (NSDictionary *)loadWorld;
+ (void)saveWorld:(NSDictionary *)value;

+ (NSDictionary *)loadWindowStateWithName:(NSString *)name;
+ (void)saveWindowState:(NSDictionary *)value name:(NSString *)name;

+ (TXNicknameHighlightMatchType)highlightMatchingMethod;

+ (BOOL)logHighlights;
+ (BOOL)highlightCurrentNickname;

+ (CGFloat)swipeMinimumLength;

+ (NSArray *)highlightMatchKeywords;
+ (NSArray *)highlightExcludeKeywords;

+ (void)cleanUpHighlightKeywords;

+ (void)defaultIRCClientPrompt:(BOOL)forced;

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

@end
