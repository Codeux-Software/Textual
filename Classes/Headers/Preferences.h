// Created by Satoshi Nakagawa <psychs AT limechat DOT net> <http://github.com/psychs/limechat>
// Modifications by Codeux Software <support AT codeux DOT com> <https://github.com/codeux/Textual>
// You can redistribute it and/or modify it under the new BSD license.

#define DEFAULT_TEXTUAL_STYLE @"resource:Simplified Light"
#define DEFAULT_TEXTUAL_FONT  @"Lucida Grande"

typedef enum {
	KEYWORD_MATCH_PARTIAL = 0,
	KEYWORD_MATCH_EXACT,
    KEYWORD_MATCH_REGEX,
} KeywordMatchType;

typedef enum {
	TAB_COMPLETE_NICK = 0,
	TAB_UNREAD,
	TAB_NONE = 100,
} TabActionType;

typedef enum {
	USERDC_ACTION_WHOIS = 100,
	USERDC_ACTION_QUERY = 200,
} UserDoubleClickAction;

typedef enum {
	NOTICES_SENDTO_CONSOLE = 0,
	NOTICES_SENDTO_CURCHAN = 1,
} NoticesSendToLocation;

typedef enum {
	CMDWKEY_SHORTCUT_CLOSE = 0,
	CMDWKEY_SHORTCUT_PARTC = 1,
	CMDWKEY_SHORTCUT_DISCT = 2,
	CMDWKEY_SHORTCUT_QUITA = 3,
} CmdW_Shortcut_ResponseType;

typedef enum {
	HMBAN_FORMAT_WHNIN  = 0, // With Hostmask, No Username/Nickname
	HMBAN_FORMAT_WHAINN = 1, // With Hostmask and Username, No Nickname
	HMBAN_FORMAT_WHANNI = 2, // With Hostmask and Nickname, No Username
	HMBAN_FORMAT_EXACT  = 3, // Exact Match
} HostmaskBanFormat;

@interface Preferences : NSObject

+ (BOOL)sandboxEnabled;

+ (void)validateStoreReceipt;

+ (NSInteger)startTime;
+ (NSInteger)totalRunTime;
+ (void)updateTotalRunTime;

+ (BOOL)featureAvailableToOSXLion;
+ (BOOL)featureAvailableToOSXMountainLion;

+ (NSData *)applicationIcon;
+ (NSString *)applicationName;
+ (NSInteger)applicationProcessID;
+ (NSString *)applicationBundleIdentifier;

+ (NSString *)gitBuildReference;

+ (NSDoubleN)viewLoopConsoleDelay;
+ (NSDoubleN)viewLoopChannelDelay;

+ (NSDictionary *)textualInfoPlist;
+ (NSDictionary *)systemInfoPlist;

+ (NSString *)whereScriptsPath;
+ (NSString *)whereApplicationSupportPath;
+ (NSString *)whereThemesPath;
+ (NSString *)whereScriptsLocalPath;

#ifdef _USES_APPLICATION_SCRIPTS_FOLDER
+ (NSString *)whereScriptsUnsupervisedPath;
#endif

+ (NSString *)whereThemesLocalPath;
+ (NSString *)whereResourcePath;
+ (NSString *)wherePluginsPath;
+ (NSString *)wherePluginsLocalPath;
+ (NSString *)whereAppStoreReceipt;
+ (NSString *)whereMainApplicationBundle;

+ (NSString *)transcriptFolder;
+ (void)setTranscriptFolder:(NSString *)value;

+ (NSDictionary *)commandIndexList;
+ (NSInteger)commandUIndex:(NSString *)command;

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

+ (NoticesSendToLocation)locationToSendNotices;

+ (BOOL)trackConversations;
+ (BOOL)disableNicknameColors;

+ (BOOL)logAllHighlightsToQuery;
+ (BOOL)keywordCurrentNick;

+ (KeywordMatchType)keywordMatchingMethod;

+ (BOOL)displayDockBadge;
+ (BOOL)countPublicMessagesInIconBadge;

+ (BOOL)autoAddScrollbackMark;
+ (BOOL)showInlineImages;
+ (BOOL)showJoinLeave;
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

+ (CmdW_Shortcut_ResponseType)cmdWResponseType;

+ (BOOL)logTranscript;

+ (BOOL)openBrowserInBackground;

+ (BOOL)connectOnDoubleclick;
+ (BOOL)disconnectOnDoubleclick;
+ (BOOL)joinOnDoubleclick;
+ (BOOL)leaveOnDoubleclick;

+ (UserDoubleClickAction)userDoubleClickOption;

+ (NSInteger)autojoinMaxChannelJoins;
+ (HostmaskBanFormat)banFormat;

+ (NSInteger)inlineImagesMaxWidth;
+ (void)setInlineImagesMaxWidth:(NSInteger)value;

+ (NSString *)themeName;
+ (NSString *)themeChannelViewFontName;
+ (NSString *)themeNickFormat;
+ (NSString *)themeTimestampFormat;
+ (NSDoubleN)themeTransparency;
+ (NSDoubleN)themeChannelViewFontSize;

+ (void)setThemeName:(NSString *)value;
+ (void)setThemeChannelViewFontName:(NSString *)value;
+ (void)setThemeChannelViewFontSize:(NSDoubleN)value;

+ (NSInteger)maxLogLines;
+ (void)setMaxLogLines:(NSInteger)value;

+ (BOOL)stopGrowlOnActive;

+ (NSString *)titleForEvent:(NotificationType)event;
+ (NSString *)soundForEvent:(NotificationType)event;

+ (BOOL)growlEnabledForEvent:(NotificationType)event;
+ (BOOL)growlStickyForEvent:(NotificationType)event;
+ (BOOL)disableWhileAwayForEvent:(NotificationType)event;

+ (void)setSound:(NSString *)value forEvent:(NotificationType)event;
+ (void)setGrowlEnabled:(BOOL)value forEvent:(NotificationType)event;
+ (void)setGrowlSticky:(BOOL)value forEvent:(NotificationType)event;
+ (void)setDisableWhileAway:(BOOL)value forEvent:(NotificationType)event;

+ (TabActionType)tabAction;

+ (NSString *)completionSuffix;
+ (void)setCompletionSuffix:(NSString *)value;

+ (BOOL)registeredToGrowl;
+ (void)setRegisteredToGrowl:(BOOL)value;

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
