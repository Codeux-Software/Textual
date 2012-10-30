/* ********************************************************************* 
       _____        _               _    ___ ____   ____
      |_   _|___  _| |_ _   _  __ _| |  |_ _|  _ \ / ___|
       | |/ _ \ \/ / __| | | |/ _` | |   | || |_) | |
       | |  __/>  <| |_| |_| | (_| | |   | ||  _ <| |___
       |_|\___/_/\_\\__|\__,_|\__,_|_|  |___|_| \_\\____|

 Copyright (c) 2010 — 2012 Codeux Software & respective contributors.
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

typedef enum TXTabKeyActionType : NSInteger {
	TXTabKeyActionNickCompleteType = 0,
	TXTabKeyActionUnreadChannelType,
	TXTabKeyActionNoneType = 100,
} TXTabKeyActionType;

typedef enum TXUserDoubleClickAction : NSInteger {
	TXUserDoubleClickWhoisAction = 100,
	TXUserDoubleClickQueryAction = 200,
} TXUserDoubleClickAction;

typedef enum TXNoticeSendLocationType : NSInteger {
	TXNoticeSendServerConsoleType = 0,
	TXNoticeSendCurrentChannelType = 1,
} TXNoticeSendLocationType;

typedef enum TXCmdWShortcutResponseType : NSInteger {
	TXCmdWShortcutCloseWindowType = 0,
	TXCmdWShortcutPartChannelType = 1,
	TXCmdWShortcutDisconnectType = 2,
	TXCmdWShortcutTerminateType = 3,
} TXCmdWShortcutResponseType;

typedef enum TXHostmaskBanFormat : NSInteger {
	TXHostmaskBanWHNINFormat  = 0, // With Hostmask, No Username/Nickname
	TXHostmaskBanWHAINNFormat = 1, // With Hostmask and Username, No Nickname
	TXHostmaskBanWHANNIFormat = 2, // With Hostmask and Nickname, No Username
	TXHostmaskBanExactFormat  = 3, // Exact Match
} TXHostmaskBanFormat;

@interface TPCPreferences : NSObject
+ (BOOL)sandboxEnabled;
+ (BOOL)securityScopedBookmarksAvailable;

+ (TXMasterController *)masterController;
+ (void)setMasterController:(TXMasterController *)master;

+ (NSInteger)startTime;
+ (NSInteger)totalRunTime;
+ (void)updateTotalRunTime;

+ (BOOL)featureAvailableToOSXLion;
+ (BOOL)featureAvailableToOSXMountainLion;

+ (BOOL)runningInHighResolutionMode;

+ (NSString *)masqueradeCTCPVersion;

+ (NSData *)applicationIcon;
+ (NSString *)applicationName;
+ (NSInteger)applicationProcessID;
+ (NSString *)applicationBundleIdentifier;

+ (NSString *)gitBuildReference;

+ (NSDictionary *)textualInfoPlist;
+ (NSDictionary *)systemInfoPlist;

+ (NSString *)applicationBundlePath;
+ (NSString *)applicationSupportFolderPath;
+ (NSString *)applicationTemporaryFolderPath;
+ (NSString *)applicationResourcesFolderPath;
+ (NSString *)customExtensionFolderPath;
+ (NSString *)customScriptFolderPath;
+ (NSString *)customThemeFolderPath;
+ (NSString *)bundledThemeFolderPath;
+ (NSString *)bundledExtensionFolderPath;
+ (NSString *)bundledScriptFolderPath;
+ (NSString *)appleStoreReceiptFilePath;
+ (NSString *)userHomeDirectoryPathOutsideSandbox;

#ifdef TXUserScriptsFolderAvailable
+ (NSString *)systemUnsupervisedScriptFolderPath;
#endif

+ (NSString *)transcriptFolder;
+ (void)setTranscriptFolder:(id)value;
+ (void)stopUsingTranscriptFolderBookmarkResources;

+ (NSArray *)publicIRCCommandList;
+ (NSInteger)indexOfIRCommand:(NSString *)command;
+ (NSInteger)indexOfIRCommand:(NSString *)command publicSearch:(BOOL)isPublic;

+ (NSString *)defaultRealname;
+ (NSString *)defaultUsername;
+ (NSString *)defaultNickname;
+ (NSString *)defaultKickMessage;

+ (BOOL)handleIRCopAlerts;
+ (BOOL)handleServerNotices;

+ (NSString *)IRCopDefaultKillMessage;
+ (NSString *)IRCopDefaultGlineMessage;
+ (NSString *)IRCopDefaultShunMessage;
+ (NSString *)IRCopAlertMatch;

+ (BOOL)amsgAllConnections;
+ (BOOL)awayAllConnections;
+ (BOOL)giveFocusOnMessage;
+ (BOOL)nickAllConnections;
+ (BOOL)clearAllOnlyOnActiveServer;

+ (TXNoticeSendLocationType)locationToSendNotices;

+ (BOOL)trackConversations;
+ (BOOL)disableNicknameColors;

+ (BOOL)logAllHighlightsToQuery;
+ (BOOL)keywordCurrentNick;

+ (TXNicknameHighlightMatchType)keywordMatchingMethod;

+ (BOOL)displayDockBadge;
+ (BOOL)countPublicMessagesInIconBadge;

+ (BOOL)autoAddScrollbackMark;
+ (BOOL)showInlineImages;
+ (BOOL)showJoinLeave;
+ (BOOL)invertSidebarColors;
+ (BOOL)hideMainWindowSegmentedController;
+ (BOOL)displayServerMOTD;
+ (BOOL)rightToLeftFormatting;
+ (BOOL)removeAllFormatting;
+ (BOOL)useLogAntialiasing;

+ (BOOL)reloadScrollbackOnLaunch;

+ (BOOL)autoJoinOnInvite;
+ (BOOL)processChannelModes;

+ (BOOL)confirmQuit;
+ (BOOL)rejoinOnKick;
+ (BOOL)copyOnSelect;
+ (BOOL)replyToCTCPRequests;
+ (BOOL)autojoinWaitForNickServ;
+ (BOOL)inputHistoryIsChannelSpecific;

+ (TXCmdWShortcutResponseType)cmdWResponseType;

+ (BOOL)logTranscript;

+ (BOOL)openBrowserInBackground;

+ (BOOL)connectOnDoubleclick;
+ (BOOL)disconnectOnDoubleclick;
+ (BOOL)joinOnDoubleclick;
+ (BOOL)leaveOnDoubleclick;

+ (TXUserDoubleClickAction)userDoubleClickOption;

+ (NSInteger)autojoinMaxChannelJoins;
+ (TXHostmaskBanFormat)banFormat;

+ (NSInteger)inlineImagesMaxWidth;
+ (void)setInlineImagesMaxWidth:(NSInteger)value;

+ (NSString *)themeName;
+ (NSString *)themeChannelViewFontName;
+ (NSString *)themeNicknameFormat;
+ (NSString *)themeTimestampFormat;
+ (TXNSDouble)themeTransparency;
+ (TXNSDouble)themeChannelViewFontSize;
+ (NSFont *)themeChannelViewFont;

+ (void)setThemeName:(NSString *)value;
+ (void)setThemeChannelViewFontName:(NSString *)value;
+ (void)setThemeChannelViewFontSize:(TXNSDouble)value;

+ (NSInteger)maxLogLines;
+ (void)setMaxLogLines:(NSInteger)value;

+ (BOOL)stopGrowlOnActive;

+ (NSString *)titleForEvent:(TXNotificationType)event;
+ (NSString *)soundForEvent:(TXNotificationType)event;

+ (BOOL)growlEnabledForEvent:(TXNotificationType)event;
+ (BOOL)growlStickyForEvent:(TXNotificationType)event;
+ (BOOL)disableWhileAwayForEvent:(TXNotificationType)event;

+ (void)setSound:(NSString *)value forEvent:(TXNotificationType)event;
+ (void)setGrowlEnabled:(BOOL)value forEvent:(TXNotificationType)event;
+ (void)setGrowlSticky:(BOOL)value forEvent:(TXNotificationType)event;
+ (void)setDisableWhileAway:(BOOL)value forEvent:(TXNotificationType)event;

+ (TXTabKeyActionType)tabAction;

+ (NSString *)completionSuffix;
+ (void)setCompletionSuffix:(NSString *)value;

+ (NSDictionary *)loadWorld;
+ (void)saveWorld:(NSDictionary *)value;

+ (NSDictionary *)loadWindowStateWithName:(NSString *)name;
+ (void)saveWindowState:(NSDictionary *)value name:(NSString *)name;

+ (NSArray *)keywords;
+ (NSArray *)excludeWords;
+ (void)cleanUpWords;

+ (void)defaultIRCClientPrompt:(BOOL)forced;

+ (void)initPreferences;
+ (void)sync;
@end