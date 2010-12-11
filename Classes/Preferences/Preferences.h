// Created by Satoshi Nakagawa <psychs AT limechat DOT net> <http://github.com/psychs/limechat>
// Modifications by Codeux Software <support AT codeux DOT com> <https://github.com/codeux/Textual>
// You can redistribute it and/or modify it under the new BSD license.

#import <Cocoa/Cocoa.h>
#import "GrowlController.h"

typedef enum {
	ADDRESS_DETECT_SPECIFY = 0,
	ADDRESS_DETECT_JOIN = 2,
} AddressDetectionType;

typedef enum {
	DCC_AUTO_ACCEPT = 0,
	DCC_SHOW_DIALOG,
	DCC_IGNORE,
} DCCActionType;

typedef enum {
	KEYWORD_MATCH_PARTIAL = 0,
	KEYWORD_MATCH_EXACT,
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

+ (NSInteger)startTime;
+ (NSDictionary*)textualInfoPlist;
+ (NSDictionary*)systemInfoPlist;
+ (NSString*)systemProcessor;
+ (DCCActionType)dccAction;
+ (AddressDetectionType)dccAddressDetectionMethod;
+ (NSString*)whereScriptsPath;
+ (NSString*)whereApplicationSupportPath;
+ (NSInteger)commandUIndex:(NSString *)command;
+ (NSDictionary*)commandIndexList;
+ (NSString*)whereThemesPath;
+ (NSString*)whereScriptsLocalPath;
+ (NSString*)whereThemesLocalPath;
+ (NSString*)whereResourcePath;
+ (NSString*)wherePluginsPath;
+ (NSString*)wherePluginsLocalPath;
+ (NSString*)dccMyaddress;
+ (NSString*)completionSuffix;
+ (NSString*)defaultRealname;
+ (NSString*)defaultUsername;
+ (NSString*)defaultNickname;
+ (NSString*)IRCopDefaultKillMessage;
+ (NSString*)IRCopDefaultGlineMessage;
+ (NSString*)IRCopDefaultShunMessage;
+ (BOOL)floodControlIsEnabled;
+ (NSInteger)floodControlDelayTimer;
+ (NSInteger)floodControlMaxMessages;
+ (NSString*)IRCopAlertMatch;
+ (NSInteger)connectAutoJoinDelay;
+ (NSInteger)autojoinMaxChannelJoins;
+ (NSString*)defaultKickMessage;
+ (BOOL)inputHistoryIsChannelSpecific;
+ (BOOL)logAllHighlightsToQuery;
+ (BOOL)clearAllOnlyOnActiveServer;
+ (BOOL)displayServerMOTD;
+ (BOOL)copyOnSelect;
+ (BOOL)handleIRCopAlerts;
+ (BOOL)autoAddScrollbackMark;
+ (BOOL)rightToLeftFormatting;
+ (BOOL)removeAllFormatting;
+ (BOOL)displayDockBadge;
+ (BOOL)handleServerNotices;
+ (BOOL)amsgAllConnections;
+ (BOOL)awayAllConnections;
+ (BOOL)nickAllConnections;
+ (BOOL)confirmQuit;
+ (BOOL)indentOnHang;
+ (BOOL)processChannelModes;
+ (BOOL)rejoinOnKick;
+ (BOOL)autoJoinOnInvite;
+ (BOOL)connectOnDoubleclick;
+ (BOOL)disconnectOnDoubleclick;
+ (BOOL)joinOnDoubleclick;
+ (BOOL)leaveOnDoubleclick;
+ (BOOL)logTranscript;
+ (BOOL)openBrowserInBackground;
+ (BOOL)showInlineImages;
+ (BOOL)showJoinLeave;
+ (BOOL)stopGrowlOnActive;
+ (BOOL)disableNicknameColors;
+ (BOOL)isUpgradedFromVersion100;
+ (BOOL)countPublicMessagesInIconBadge;
+ (TabActionType)tabAction;
+ (BOOL)keywordCurrentNick;
+ (HostmaskBanFormat)banFormat;
+ (KeywordMatchType)keywordMatchingMethod;
+ (CmdW_Shortcut_ResponseType)cmdWResponseType;
+ (NoticesSendToLocation)locationToSendNotices;
+ (UserDoubleClickAction)userDoubleClickOption;

+ (NSInteger)inlineImagesMaxWidth;
+ (void)setInlineImagesMaxWidth:(NSInteger)value;

+ (NSString*)themeName;
+ (void)setThemeName:(NSString*)value;
+ (NSString*)themeLogFontName;
+ (void)setThemeLogFontName:(NSString*)value;
+ (double)themeLogFontSize;
+ (void)setThemeLogFontSize:(double)value;
+ (NSString*)themeNickFormat;
+ (BOOL)themeOverrideLogFont;
+ (BOOL)themeOverrideNickFormat;
+ (BOOL)themeOverrideTimestampFormat;
+ (NSString*)themeTimestampFormat;
+ (double)themeTransparency;

+ (NSInteger)dccFirstPort;
+ (void)setDccFirstPort:(NSInteger)value;
+ (NSInteger)dccLastPort;
+ (void)setDccLastPort:(NSInteger)value;

+ (NSInteger)maxLogLines;
+ (void)setMaxLogLines:(NSInteger)value;

+ (NSString*)transcriptFolder;
+ (void)setTranscriptFolder:(NSString*)value;

+ (NSString*)titleForEvent:(GrowlNotificationType)event;
+ (NSString*)soundForEvent:(GrowlNotificationType)event;
+ (void)setSound:(NSString*)value forEvent:(GrowlNotificationType)event;
+ (BOOL)growlEnabledForEvent:(GrowlNotificationType)event;
+ (void)setGrowlEnabled:(BOOL)value forEvent:(GrowlNotificationType)event;
+ (BOOL)growlStickyForEvent:(GrowlNotificationType)event;
+ (void)setGrowlSticky:(BOOL)value forEvent:(GrowlNotificationType)event;
+ (BOOL)disableWhileAwayForEvent:(GrowlNotificationType)event;
+ (void)setDisableWhileAway:(BOOL)value forEvent:(GrowlNotificationType)event;

+ (void)setCompletionSuffix:(NSString*)value;

+ (BOOL)spellCheckEnabled;
+ (void)setSpellCheckEnabled:(BOOL)value;
+ (BOOL)grammarCheckEnabled;
+ (void)setGrammarCheckEnabled:(BOOL)value;
+ (BOOL)spellingCorrectionEnabled;
+ (void)setSpellingCorrectionEnabled:(BOOL)value;
+ (BOOL)smartInsertDeleteEnabled;
+ (void)setSmartInsertDeleteEnabled:(BOOL)value;
+ (BOOL)quoteSubstitutionEnabled;
+ (void)setQuoteSubstitutionEnabled:(BOOL)value;
+ (BOOL)dashSubstitutionEnabled;
+ (void)setDashSubstitutionEnabled:(BOOL)value;
+ (BOOL)linkDetectionEnabled;
+ (void)setLinkDetectionEnabled:(BOOL)value;
+ (BOOL)dataDetectionEnabled;
+ (void)setDataDetectionEnabled:(BOOL)value;
+ (BOOL)textReplacementEnabled;
+ (void)setTextReplacementEnabled:(BOOL)value;

+ (BOOL)registeredToGrowl;
+ (void)setRegisteredToGrowl:(BOOL)value;

+ (NSDictionary*)loadWorld;
+ (void)saveWorld:(NSDictionary*)value;

+ (NSDictionary*)loadWindowStateWithName:(NSString*)name;
+ (void)saveWindowState:(NSDictionary*)value name:(NSString*)name;

+ (NSArray*)keywords;
+ (NSArray*)excludeWords;
+ (void)cleanUpWords;

+ (void)initPreferences;
+ (void)sync;

@end