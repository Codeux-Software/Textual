// Created by Satoshi Nakagawa <psychs AT limechat DOT net> <http://github.com/psychs/limechat>
// Modifications by Codeux Software <support AT codeux DOT com> <https://github.com/codeux/Textual>
// You can redistribute it and/or modify it under the new BSD license.

#define DEFAULT_TEXUAL_STYLE @"resource:Simplified Dark"

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
	HMBAN_FORMAT_WHNIN = 0, // With Hostmask, No Username/Nickname
	HMBAN_FORMAT_WHAINN = 1, // With Hostmask and Username, No Nickname
	HMBAN_FORMAT_WHANNI = 2, // With Hostmask and Nickname, No Username
	HMBAN_FORMAT_EXACT = 4, // Exact Match
} HostmaskBanFormat;

@interface Preferences : NSObject

+ (void)validateStoreReceipt;

+ (NSInteger)startTime;
+ (NSInteger)totalRunTime;
+ (void)updateTotalRunTime;

+ (BOOL)applicationRanOnLion;
+ (NSData *)applicationIcon;
+ (NSString *)applicationName;
+ (NSInteger)applicationProcessID;

+ (NSDictionary *)textualInfoPlist;
+ (NSDictionary *)systemInfoPlist;

+ (NSString *)whereScriptsPath;
+ (NSString *)whereApplicationSupportPath;
+ (NSString *)whereThemesPath;
+ (NSString *)whereScriptsLocalPath;
+ (NSString *)whereThemesLocalPath;
+ (NSString *)whereResourcePath;
+ (NSString *)wherePluginsPath;
+ (NSString *)wherePluginsLocalPath;
+ (NSString *)whereAppStoreReceipt;
+ (NSString *)whereMainApplicationBundle;

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
+ (BOOL)indentOnHang;
+ (BOOL)displayServerMOTD;
+ (BOOL)rightToLeftFormatting;
+ (BOOL)removeAllFormatting;

+ (BOOL)autoJoinOnInvite;
+ (BOOL)processChannelModes;

+ (BOOL)confirmQuit;
+ (BOOL)rejoinOnKick;
+ (BOOL)copyOnSelect;
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

+ (BOOL)floodControlIsEnabled;
+ (NSInteger)floodControlDelayTimer;
+ (NSInteger)floodControlMaxMessages;
+ (NSInteger)autojoinMaxChannelJoins;

+ (HostmaskBanFormat)banFormat;

+ (NSInteger)inlineImagesMaxWidth;
+ (void)setInlineImagesMaxWidth:(NSInteger)value;

+ (NSString *)themeName;
+ (NSString *)themeLogFontName;
+ (NSString *)themeNickFormat;
+ (NSString *)themeTimestampFormat;
+ (double)themeTransparency;
+ (double)themeLogFontSize;

+ (void)setThemeName:(NSString *)value;
+ (void)setThemeLogFontName:(NSString *)value;
+ (void)setThemeLogFontSize:(double)value;

+ (NSInteger)maxLogLines;
+ (void)setMaxLogLines:(NSInteger)value;

+ (NSString *)transcriptFolder;
+ (void)setTranscriptFolder:(NSString *)value;

+ (BOOL)stopGrowlOnActive;

+ (NSString *)titleForEvent:(GrowlNotificationType)event;
+ (NSString *)soundForEvent:(GrowlNotificationType)event;

+ (BOOL)growlEnabledForEvent:(GrowlNotificationType)event;
+ (BOOL)growlStickyForEvent:(GrowlNotificationType)event;
+ (BOOL)disableWhileAwayForEvent:(GrowlNotificationType)event;

+ (void)setSound:(NSString *)value forEvent:(GrowlNotificationType)event;
+ (void)setGrowlEnabled:(BOOL)value forEvent:(GrowlNotificationType)event;
+ (void)setGrowlSticky:(BOOL)value forEvent:(GrowlNotificationType)event;
+ (void)setDisableWhileAway:(BOOL)value forEvent:(GrowlNotificationType)event;

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