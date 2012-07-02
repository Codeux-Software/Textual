// Created by Satoshi Nakagawa <psychs AT limechat DOT net> <http://github.com/psychs/limechat>
// Modifications by Codeux Software <support AT codeux DOT com> <https://github.com/codeux/Textual>
// You can redistribute it and/or modify it under the new BSD license.

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

+ (TXNSDouble)viewLoopConsoleDelay;
+ (TXNSDouble)viewLoopChannelDelay;

+ (NSDictionary *)textualInfoPlist;
+ (NSDictionary *)systemInfoPlist;

+ (NSString *)whereScriptsPath;
+ (NSString *)whereApplicationSupportPath;
+ (NSString *)whereThemesPath;
+ (NSString *)whereScriptsLocalPath;

#ifdef TXUserScriptsFolderAvailable
+ (NSString *)whereScriptsUnsupervisedPath;
#endif

+ (NSString *)whereThemesLocalPath;
+ (NSString *)whereResourcePath;
+ (NSString *)wherePluginsPath;
+ (NSString *)wherePluginsLocalPath;
+ (NSString *)whereAppStoreReceipt;
+ (NSString *)whereMainApplicationBundle;

+ (NSString *)transcriptFolder;
+ (void)setTranscriptFolder:(id)value;
+ (void)stopUsingTranscriptFolderBookmarkResources;

+ (NSDictionary *)commandIndexList;
+ (NSInteger)indexOfIRCommand:(NSString *)command;

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
+ (BOOL)displayServerMOTD;
+ (BOOL)rightToLeftFormatting;
+ (BOOL)removeAllFormatting;
+ (BOOL)useLogAntialiasing;

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
+ (NSString *)themeNickFormat;
+ (NSString *)themeTimestampFormat;
+ (TXNSDouble)themeTransparency;
+ (TXNSDouble)themeChannelViewFontSize;

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

+ (void)initPreferences;
+ (void)sync;
@end