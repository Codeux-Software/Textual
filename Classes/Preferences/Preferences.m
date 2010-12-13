// Created by Satoshi Nakagawa <psychs AT limechat DOT net> <http://github.com/psychs/limechat>
// Modifications by Codeux Software <support AT codeux DOT com> <https://github.com/codeux/Textual>
// You can redistribute it and/or modify it under the new BSD license.

#import "Preferences.h"

@implementation Preferences

static NSInteger startUpTime;

+ (NSInteger)startTime
{
	return startUpTime;
}

#pragma mark -
#pragma mark Version Dictonaries

static NSDictionary *textualPlist;
static NSDictionary *systemVersionPlist;

#if defined(__ppc__)
static NSString *processor = @"PowerPC 32-bit";
#elif defined(__ppc64__)
static NSString *processor = @"PowerPC 64-bit";
#elif defined(__i386__) 
static NSString *processor = @"Intel 32-bit";
#elif defined(__x86_64__)
static NSString *processor = @"Intel 64-bit";
#else
static NSString *processor = @"Unknown Architecture";
#endif

+ (NSDictionary*)textualInfoPlist
{
	return textualPlist;
}

+ (NSDictionary*)systemInfoPlist 
{
	return systemVersionPlist;
}

+ (NSString*)systemProcessor
{
	return processor;
}

#pragma mark -
#pragma mark Command Index

static NSMutableDictionary *commandIndex;

+ (NSDictionary*)commandIndexList
{
	return commandIndex;
}

+ (void)populateCommandIndex
{
	commandIndex = [[NSMutableDictionary alloc] init];
	
	[commandIndex setObject:@"3" forKey:IRCCI_AWAY];
	[commandIndex setObject:@"4" forKey:IRCCI_ERROR];
	[commandIndex setObject:@"5" forKey:IRCCI_INVITE];
	[commandIndex setObject:@"6" forKey:IRCCI_ISON];
	[commandIndex setObject:@"7" forKey:IRCCI_JOIN];
	[commandIndex setObject:@"8" forKey:IRCCI_KICK];
	[commandIndex setObject:@"9" forKey:IRCCI_KILL];
	[commandIndex setObject:@"10" forKey:IRCCI_LIST];
	[commandIndex setObject:@"11" forKey:IRCCI_MODE];
	[commandIndex setObject:@"12" forKey:IRCCI_NAMES];
	[commandIndex setObject:@"13" forKey:IRCCI_NICK];
	[commandIndex setObject:@"14" forKey:IRCCI_NOTICE];
	[commandIndex setObject:@"15" forKey:IRCCI_PART];
	[commandIndex setObject:@"16" forKey:IRCCI_PASS];
	[commandIndex setObject:@"17" forKey:IRCCI_PING];
	[commandIndex setObject:@"18" forKey:IRCCI_PONG];
	[commandIndex setObject:@"19" forKey:IRCCI_PRIVMSG];
	[commandIndex setObject:@"20" forKey:IRCCI_QUIT];
	[commandIndex setObject:@"21" forKey:IRCCI_TOPIC];
	[commandIndex setObject:@"22" forKey:IRCCI_USER];
	[commandIndex setObject:@"23" forKey:IRCCI_WHO];
	[commandIndex setObject:@"24" forKey:IRCCI_WHOIS];
	[commandIndex setObject:@"25" forKey:IRCCI_WHOWAS];
	[commandIndex setObject:@"27" forKey:IRCCI_ACTION];
	[commandIndex setObject:@"28" forKey:IRCCI_DCC];
	[commandIndex setObject:@"29" forKey:IRCCI_SEND];
	[commandIndex setObject:@"31" forKey:IRCCI_CLIENTINFO];
	[commandIndex setObject:@"32" forKey:IRCCI_CTCP];
	[commandIndex setObject:@"33" forKey:IRCCI_CTCPREPLY];
	[commandIndex setObject:@"34" forKey:IRCCI_TIME];
	[commandIndex setObject:@"35" forKey:IRCCI_USERINFO];
	[commandIndex setObject:@"36" forKey:IRCCI_VERSION];
	[commandIndex setObject:@"38" forKey:IRCCI_OMSG];
	[commandIndex setObject:@"39" forKey:IRCCI_ONOTICE];
	[commandIndex setObject:@"41" forKey:IRCCI_BAN];
	[commandIndex setObject:@"42" forKey:IRCCI_CLEAR];
	[commandIndex setObject:@"43" forKey:IRCCI_CLOSE];
	[commandIndex setObject:@"44" forKey:IRCCI_CYCLE];
	[commandIndex setObject:@"45" forKey:IRCCI_DEHALFOP];
	[commandIndex setObject:@"46" forKey:IRCCI_DEOP];
	[commandIndex setObject:@"47" forKey:IRCCI_DEVOICE];
	[commandIndex setObject:@"48" forKey:IRCCI_HALFOP];
	[commandIndex setObject:@"49" forKey:IRCCI_HOP];
	[commandIndex setObject:@"50" forKey:IRCCI_IGNORE];
	[commandIndex setObject:@"51" forKey:IRCCI_J];
	[commandIndex setObject:@"52" forKey:IRCCI_LEAVE];
	[commandIndex setObject:@"53" forKey:IRCCI_M];
	[commandIndex setObject:@"54" forKey:IRCCI_ME];
	[commandIndex setObject:@"55" forKey:IRCCI_MSG];
	[commandIndex setObject:@"56" forKey:IRCCI_OP];
	[commandIndex setObject:@"57" forKey:IRCCI_RAW];
	[commandIndex setObject:@"58" forKey:IRCCI_REJOIN];
	[commandIndex setObject:@"59" forKey:IRCCI_QUERY];
	[commandIndex setObject:@"60" forKey:IRCCI_QUOTE];
	[commandIndex setObject:@"61" forKey:IRCCI_T];
	[commandIndex setObject:@"62" forKey:IRCCI_TIMER];
	[commandIndex setObject:@"63" forKey:IRCCI_VOICE];
	[commandIndex setObject:@"64" forKey:IRCCI_UNBAN];
	[commandIndex setObject:@"65" forKey:IRCCI_UNIGNORE];
	[commandIndex setObject:@"66" forKey:IRCCI_UMODE];
	[commandIndex setObject:@"67" forKey:IRCCI_VERSION];
	[commandIndex setObject:@"68" forKey:IRCCI_WEIGHTS];
	[commandIndex setObject:@"69" forKey:IRCCI_ECHO];
	[commandIndex setObject:@"70" forKey:IRCCI_DEBUG];
	[commandIndex setObject:@"71" forKey:IRCCI_CLEARALL];
	[commandIndex setObject:@"72" forKey:IRCCI_AMSG];
	[commandIndex setObject:@"73" forKey:IRCCI_AME];
	[commandIndex setObject:@"74" forKey:IRCCI_MUTE]; 
	[commandIndex setObject:@"75" forKey:IRCCI_UNMUTE]; 
	[commandIndex setObject:@"76" forKey:IRCCI_UNLOAD_PLUGINS]; 
	[commandIndex setObject:@"77" forKey:IRCCI_REMOVE];  
	[commandIndex setObject:@"79" forKey:IRCCI_KICKBAN]; 
	[commandIndex setObject:@"80" forKey:IRCCI_WALLOPS]; 
	[commandIndex setObject:@"81" forKey:IRCCI_ICBADGE];
	[commandIndex setObject:@"82" forKey:IRCCI_SERVER];
	[commandIndex setObject:@"83" forKey:IRCCI_CONN]; 
	[commandIndex setObject:@"84" forKey:IRCCI_MYVERSION]; 
	[commandIndex setObject:@"85" forKey:IRCCI_CHATOPS]; 
	[commandIndex setObject:@"86" forKey:IRCCI_GLOBOPS]; 
	[commandIndex setObject:@"87" forKey:IRCCI_LOCOPS]; 
	[commandIndex setObject:@"88" forKey:IRCCI_NACHAT]; 
	[commandIndex setObject:@"89" forKey:IRCCI_ADCHAT]; 
	[commandIndex setObject:@"90" forKey:IRCCI_RESETFILES];
	[commandIndex setObject:@"91" forKey:IRCCI_LOAD_PLUGINS];
}

+ (NSInteger)commandUIndex:(NSString *)command 
{
	return [[commandIndex objectForKey:[command uppercaseString]] integerValue];
}

#pragma mark -
#pragma mark Path Index

+ (NSString*)whereApplicationSupportPath
{
	return [@"~/Library/Application Support/Textual/" stringByExpandingTildeInPath];
}

+ (NSString*)whereScriptsPath
{
	return [@"~/Library/Application Support/Textual/Scripts" stringByExpandingTildeInPath];
}

+ (NSString*)whereThemesPath
{
	return [@"~/Library/Application Support/Textual/Styles" stringByExpandingTildeInPath];
}

+ (NSString*)wherePluginsPath
{
	return [@"~/Library/Application Support/Textual/Extensions" stringByExpandingTildeInPath];
}

+ (NSString*)whereScriptsLocalPath
{
	return [[self whereResourcePath] stringByAppendingPathComponent:@"Scripts"];
}

+ (NSString*)whereThemesLocalPath
{
	return [[self whereResourcePath] stringByAppendingPathComponent:@"Styles"];	
}

+ (NSString*)wherePluginsLocalPath
{
	return [[self whereResourcePath] stringByAppendingPathComponent:@"Extensions"];	
}

+ (NSString*)whereResourcePath 
{
	return [[NSBundle mainBundle] resourcePath];
}

#pragma mark -
#pragma mark Flood Control

+ (BOOL)floodControlIsEnabled
{
	return [TXNSUserDefaultsPointer() boolForKey:@"Preferences.FloodControl.enabled"];
}

+ (NSInteger)floodControlMaxMessages
{
	return [TXNSUserDefaultsPointer() integerForKey:@"Preferences.FloodControl.maxmsg"];
}

+ (NSInteger)floodControlDelayTimer
{
	return [TXNSUserDefaultsPointer() integerForKey:@"Preferences.FloodControl.timer"];
}

#pragma mark -
#pragma mark Default Identity

+ (NSString*)defaultNickname
{
	return [TXNSUserDefaultsPointer() objectForKey:@"Preferences.Identity.nickname"];
}

+ (NSString*)defaultUsername
{
	return [TXNSUserDefaultsPointer() objectForKey:@"Preferences.Identity.username"];
}

+ (NSString*)defaultRealname
{
	return [TXNSUserDefaultsPointer() objectForKey:@"Preferences.Identity.realname"];
}

#pragma mark - 
#pragma mark General Preferences

+ (DCCActionType)dccAction
{
	return [TXNSUserDefaultsPointer() integerForKey:@"Preferences.DCC.action"];
}

+ (AddressDetectionType)dccAddressDetectionMethod
{
	return [TXNSUserDefaultsPointer() integerForKey:@"Preferences.DCC.address_detection_method"];
}

+ (NSInteger)autojoinMaxChannelJoins
{
	return [TXNSUserDefaultsPointer() integerForKey:@"Preferences.General.autojoin_maxchans"];
}

+ (NSInteger)connectAutoJoinDelay
{
	return [TXNSUserDefaultsPointer() integerForKey:@"Preferences.General.autojoin_delay"];
}

+ (NSString*)defaultKickMessage
{
	return [TXNSUserDefaultsPointer() objectForKey:@"Preferences.General.kick_message"];
}

+ (NSString*)IRCopDefaultKillMessage
{
	return [TXNSUserDefaultsPointer() objectForKey:@"Preferences.General.ircop_kill_message"];
}

+ (NSString*)IRCopDefaultGlineMessage
{
	return [TXNSUserDefaultsPointer() objectForKey:@"Preferences.General.ircop_gline_message"];
}

+ (NSString*)IRCopDefaultShunMessage
{
	return [TXNSUserDefaultsPointer() objectForKey:@"Preferences.General.ircop_shun_message"];
}

+ (NSString*)IRCopAlertMatch
{
	return [TXNSUserDefaultsPointer() objectForKey:@"Preferences.General.ircop_alert_match"];
}

+ (BOOL)logAllHighlightsToQuery
{
	return [TXNSUserDefaultsPointer() boolForKey:@"Preferences.General.log_highlights"];
}

+ (BOOL)clearAllOnlyOnActiveServer
{
	return [TXNSUserDefaultsPointer() boolForKey:@"Preferences.General.clear_only_active"];
}

+ (BOOL)displayServerMOTD
{
	return [TXNSUserDefaultsPointer() boolForKey:@"Preferences.General.display_servmotd"];
}

+ (BOOL)copyOnSelect
{
	return [TXNSUserDefaultsPointer() boolForKey:@"Preferences.General.copyonselect"];
}

+ (BOOL)autoAddScrollbackMark
{
	return [TXNSUserDefaultsPointer() boolForKey:@"Preferences.General.autoadd_scrollbackmark"];
}

+ (BOOL)removeAllFormatting
{
	return [TXNSUserDefaultsPointer() boolForKey:@"Preferences.General.strip_formatting"];
}

+ (BOOL)disableNicknameColors
{
	return [TXNSUserDefaultsPointer() boolForKey:@"Preferences.General.disable_nickname_colors"];
}

+ (BOOL)isUpgradedFromVersion100
{
	return [TXNSUserDefaultsPointer() boolForKey:@"SUHasLaunchedBefore"];
}

+ (BOOL)rightToLeftFormatting
{
	return [TXNSUserDefaultsPointer() boolForKey:@"Preferences.General.rtl_formatting"];
}

+ (NSString*)dccMyaddress
{
	return [TXNSUserDefaultsPointer() objectForKey:@"Preferences.DCC.myaddress"];
}

+ (NSString*)completionSuffix
{
	return [TXNSUserDefaultsPointer() objectForKey:@"Preferences.General.completion_suffix"];
}

+ (HostmaskBanFormat)banFormat
{
	return [TXNSUserDefaultsPointer() boolForKey:@"Preferences.General.banformat"];
}

+ (BOOL)displayDockBadge
{
	return [TXNSUserDefaultsPointer() boolForKey:@"Preferences.General.dockbadges"];
}

+ (BOOL)handleIRCopAlerts
{
	return [TXNSUserDefaultsPointer() boolForKey:@"Preferences.General.handle_operalerts"];
}

+ (BOOL)handleServerNotices
{
	return [TXNSUserDefaultsPointer() boolForKey:@"Preferences.General.handle_server_notices"];
}

+ (BOOL)amsgAllConnections
{
	return [TXNSUserDefaultsPointer() boolForKey:@"Preferences.General.amsg_allconnections"];
}

+ (BOOL)awayAllConnections
{
	return [TXNSUserDefaultsPointer() boolForKey:@"Preferences.General.away_allconnections"];
}

+ (BOOL)nickAllConnections
{
	return [TXNSUserDefaultsPointer() boolForKey:@"Preferences.General.nick_allconnections"];
}

+ (BOOL)indentOnHang
{
	return [TXNSUserDefaultsPointer() boolForKey:@"Preferences.Theme.indent_onwordwrap"];
}

+ (BOOL)confirmQuit
{
	return [TXNSUserDefaultsPointer() boolForKey:@"Preferences.General.confirm_quit"];
}

+ (BOOL)processChannelModes
{
	return [TXNSUserDefaultsPointer() boolForKey:@"Preferences.General.process_channel_modes"];
}

+ (BOOL)rejoinOnKick
{
	return [TXNSUserDefaultsPointer() boolForKey:@"Preferences.General.rejoin_onkick"];
}

+ (BOOL)autoJoinOnInvite
{
	return [TXNSUserDefaultsPointer() boolForKey:@"Preferences.General.autojoin_oninvite"];
}

+ (BOOL)connectOnDoubleclick
{
	return [TXNSUserDefaultsPointer() boolForKey:@"Preferences.General.connect_on_doubleclick"];
}

+ (BOOL)disconnectOnDoubleclick
{
	return [TXNSUserDefaultsPointer() boolForKey:@"Preferences.General.disconnect_on_doubleclick"];
}

+ (BOOL)joinOnDoubleclick
{
	return [TXNSUserDefaultsPointer() boolForKey:@"Preferences.General.join_on_doubleclick"];
}

+ (BOOL)leaveOnDoubleclick
{
	return [TXNSUserDefaultsPointer() boolForKey:@"Preferences.General.leave_on_doubleclick"];
}

+ (BOOL)logTranscript
{
	return [TXNSUserDefaultsPointer() boolForKey:@"Preferences.General.log_transcript"];
}

+ (BOOL)openBrowserInBackground
{
	return [TXNSUserDefaultsPointer() boolForKey:@"Preferences.General.open_browser_in_background"];
}

+ (BOOL)showInlineImages
{
	return [TXNSUserDefaultsPointer() boolForKey:@"Preferences.General.show_inline_images"];
}

+ (BOOL)showJoinLeave
{
	return [TXNSUserDefaultsPointer() boolForKey:@"Preferences.General.show_join_leave"];
}

+ (BOOL)stopGrowlOnActive
{
	return [TXNSUserDefaultsPointer() boolForKey:@"Preferences.General.stop_growl_on_active"];
}

+ (BOOL)countPublicMessagesInIconBadge
{
	return [TXNSUserDefaultsPointer() boolForKey:@"Preferences.General.dockbadge_countpub"];
}

+ (TabActionType)tabAction
{
	return [TXNSUserDefaultsPointer() integerForKey:@"Preferences.General.tab_action"];
}

+ (BOOL)keywordCurrentNick
{
	return [TXNSUserDefaultsPointer() boolForKey:@"Preferences.Keyword.current_nick"];
}

+ (NSArray*)keywordDislikeWords
{
	return [TXNSUserDefaultsPointer() objectForKey:@"Preferences.Keyword.dislike_words"];
}

+ (KeywordMatchType)keywordMatchingMethod
{
	return [TXNSUserDefaultsPointer() integerForKey:@"Preferences.Keyword.matching_method"];
}

+ (NSArray*)keywordWords
{
	return [TXNSUserDefaultsPointer() objectForKey:@"Preferences.Keyword.words"];
}

+ (UserDoubleClickAction)userDoubleClickOption
{
	return [TXNSUserDefaultsPointer() integerForKey:@"Preferences.General.user_doubleclick_action"];
}

+ (NoticesSendToLocation)locationToSendNotices
{
	return [TXNSUserDefaultsPointer() integerForKey:@"Preferences.General.notices_sendto_location"];
}

+ (CmdW_Shortcut_ResponseType)cmdWResponseType
{
	return [TXNSUserDefaultsPointer() integerForKey:@"Preferences.General.keyboard_cmdw_response"];
}

#pragma mark -
#pragma mark Theme

+ (NSString*)themeName
{
	return [TXNSUserDefaultsPointer() objectForKey:@"Preferences.Theme.name"];
}

+ (void)setThemeName:(NSString*)value
{
	[TXNSUserDefaultsPointer() setObject:value forKey:@"Preferences.Theme.name"];
}

+ (NSString*)themeLogFontName
{
	return [TXNSUserDefaultsPointer() objectForKey:@"Preferences.Theme.log_font_name"];
}

+ (void)setThemeLogFontName:(NSString*)value
{
	[TXNSUserDefaultsPointer() setObject:value forKey:@"Preferences.Theme.log_font_name"];
}

+ (double)themeLogFontSize
{
	return [TXNSUserDefaultsPointer() doubleForKey:@"Preferences.Theme.log_font_size"];
}

+ (void)setThemeLogFontSize:(double)value
{
	[TXNSUserDefaultsPointer() setDouble:value forKey:@"Preferences.Theme.log_font_size"];
}

+ (NSString*)themeNickFormat
{
	return [TXNSUserDefaultsPointer() objectForKey:@"Preferences.Theme.nick_format"];
}

+ (BOOL)inputHistoryIsChannelSpecific
{
	return [TXNSUserDefaultsPointer() boolForKey:@"Preferences.Theme.inputhistory_per_channel"];
}

+ (BOOL)themeOverrideLogFont
{
	return [TXNSUserDefaultsPointer() boolForKey:@"Preferences.Theme.override_log_font"];
}

+ (BOOL)themeOverrideNickFormat
{
	return [TXNSUserDefaultsPointer() boolForKey:@"Preferences.Theme.override_nick_format"];
}

+ (BOOL)themeOverrideTimestampFormat
{
	return [TXNSUserDefaultsPointer() boolForKey:@"Preferences.Theme.override_timestamp_format"];
}

+ (NSString*)themeTimestampFormat
{
	return [TXNSUserDefaultsPointer() objectForKey:@"Preferences.Theme.timestamp_format"];
}

+ (double)themeTransparency
{
	return [TXNSUserDefaultsPointer() doubleForKey:@"Preferences.Theme.transparency"];
}

#pragma mark -
#pragma mark Completion Suffix

+ (void)setCompletionSuffix:(NSString*)value
{
	[TXNSUserDefaultsPointer() setObject:value forKey:@"Preferences.General.completion_suffix"];
}

#pragma mark -
#pragma mark DCC Ports

+ (NSInteger)dccFirstPort
{
	return [TXNSUserDefaultsPointer() integerForKey:@"Preferences.DCC.first_port"];
}

+ (void)setDccFirstPort:(NSInteger)value
{
	[TXNSUserDefaultsPointer() setInteger:value forKey:@"Preferences.DCC.first_port"];
}

+ (NSInteger)dccLastPort
{
	return [TXNSUserDefaultsPointer() integerForKey:@"Preferences.DCC.last_port"];
}

+ (void)setDccLastPort:(NSInteger)value
{
	[TXNSUserDefaultsPointer() setInteger:value forKey:@"Preferences.DCC.last_port"];
}

#pragma mark -
#pragma mark Inline Image Size

+ (NSInteger)inlineImagesMaxWidth
{
	return [TXNSUserDefaultsPointer() integerForKey:@"Preferences.General.inline_image_width"];
}

+ (void)setInlineImagesMaxWidth:(NSInteger)value
{
	[TXNSUserDefaultsPointer() setInteger:value forKey:@"Preferences.General.inline_image_width"];
}

#pragma mark -
#pragma mark Max Log Lines

+ (NSInteger)maxLogLines
{
	return [TXNSUserDefaultsPointer() integerForKey:@"Preferences.General.max_log_lines"];
}

+ (void)setMaxLogLines:(NSInteger)value
{
	[TXNSUserDefaultsPointer() setInteger:value forKey:@"Preferences.General.max_log_lines"];
}

#pragma mark -
#pragma mark Transcript Folder

+ (NSString*)transcriptFolder
{
	return [TXNSUserDefaultsPointer() objectForKey:@"Preferences.General.transcript_folder"];
}

+ (void)setTranscriptFolder:(NSString*)value
{
	[TXNSUserDefaultsPointer() setObject:value forKey:@"Preferences.General.transcript_folder"];
}

#pragma mark -
#pragma mark Events

+ (NSString*)titleForEvent:(GrowlNotificationType)event
{
	switch (event) {
		case GROWL_HIGHLIGHT:
			return TXTLS(@"GROWL_HIGHLIGHT");
		case GROWL_NEW_TALK:
			return TXTLS(@"GROWL_NEW_TALK");
		case GROWL_CHANNEL_MSG:
			return TXTLS(@"GROWL_CHANNEL_MSG");
		case GROWL_CHANNEL_NOTICE:
			return TXTLS(@"GROWL_CHANNEL_NOTICE");
		case GROWL_TALK_MSG:
			return TXTLS(@"GROWL_TALK_MSG");
		case GROWL_TALK_NOTICE:
			return TXTLS(@"GROWL_TALK_NOTICE");
		case GROWL_KICKED:
			return TXTLS(@"GROWL_KICKED");
		case GROWL_INVITED:
			return TXTLS(@"GROWL_INVITED");
		case GROWL_LOGIN:
			return TXTLS(@"GROWL_LOGIN");
		case GROWL_DISCONNECT:
			return TXTLS(@"GROWL_DISCONNECT");
		case GROWL_ADDRESS_BOOK_MATCH:
			return TXTLS(@"GROWL_ADDRESS_BOOK_MATCH");
	}
	
	return nil;
}

+ (NSString*)keyForEvent:(GrowlNotificationType)event
{
	switch (event) {
		case GROWL_HIGHLIGHT:
			return @"eventHighlight";
		case GROWL_NEW_TALK:
			return @"eventNewtalk";
		case GROWL_CHANNEL_MSG:
			return @"eventChannelText";
		case GROWL_CHANNEL_NOTICE:
			return @"eventChannelNotice";
		case GROWL_TALK_MSG:
			return @"eventTalkText";
		case GROWL_TALK_NOTICE:
			return @"eventTalkNotice";
		case GROWL_KICKED:
			return @"eventKicked";
		case GROWL_INVITED:
			return @"eventInvited";
		case GROWL_LOGIN:
			return @"eventLogin";
		case GROWL_DISCONNECT:
			return @"eventDisconnect";
		case GROWL_ADDRESS_BOOK_MATCH:
			return @"eventAddressBookMatch";
	}
	
	return nil;
}

+ (NSString*)soundForEvent:(GrowlNotificationType)event
{
	NSString* key = [[self keyForEvent:event] stringByAppendingString:@"Sound"];
	return [TXNSUserDefaultsPointer() objectForKey:key];
}

+ (void)setSound:(NSString*)value forEvent:(GrowlNotificationType)event
{
	NSString* key = [[self keyForEvent:event] stringByAppendingString:@"Sound"];
	[TXNSUserDefaultsPointer() setObject:value forKey:key];
}

+ (BOOL)growlEnabledForEvent:(GrowlNotificationType)event
{
	NSString* key = [[self keyForEvent:event] stringByAppendingString:@"Growl"];
	return [TXNSUserDefaultsPointer() boolForKey:key];
}

+ (void)setGrowlEnabled:(BOOL)value forEvent:(GrowlNotificationType)event
{
	NSString* key = [[self keyForEvent:event] stringByAppendingString:@"Growl"];
	[TXNSUserDefaultsPointer() setBool:value forKey:key];
}

+ (BOOL)growlStickyForEvent:(GrowlNotificationType)event
{
	NSString* key = [[self keyForEvent:event] stringByAppendingString:@"GrowlSticky"];
	return [TXNSUserDefaultsPointer() boolForKey:key];
}

+ (void)setGrowlSticky:(BOOL)value forEvent:(GrowlNotificationType)event
{
	NSString* key = [[self keyForEvent:event] stringByAppendingString:@"GrowlSticky"];
	[TXNSUserDefaultsPointer() setBool:value forKey:key];
}

+ (BOOL)disableWhileAwayForEvent:(GrowlNotificationType)event
{
	NSString* key = [[self keyForEvent:event] stringByAppendingString:@"DisableWhileAway"];
	return [TXNSUserDefaultsPointer() boolForKey:key];
}

+ (void)setDisableWhileAway:(BOOL)value forEvent:(GrowlNotificationType)event
{
	NSString* key = [[self keyForEvent:event] stringByAppendingString:@"DisableWhileAway"];
	[TXNSUserDefaultsPointer() setBool:value forKey:key];
}

#pragma mark -
#pragma mark World

+ (BOOL)spellCheckEnabled
{
	if (![TXNSUserDefaultsPointer() objectForKey:@"spellCheck2"]) return YES;
	return [TXNSUserDefaultsPointer() boolForKey:@"spellCheck2"];
}

+ (void)setSpellCheckEnabled:(BOOL)value
{
	[TXNSUserDefaultsPointer() setBool:value forKey:@"spellCheck2"];
}

+ (BOOL)grammarCheckEnabled
{
	return [TXNSUserDefaultsPointer() boolForKey:@"grammarCheck"];
}

+ (void)setGrammarCheckEnabled:(BOOL)value
{
	[TXNSUserDefaultsPointer() setBool:value forKey:@"grammarCheck"];
}

+ (BOOL)spellingCorrectionEnabled
{
	return [TXNSUserDefaultsPointer() boolForKey:@"spellingCorrection"];
}

+ (void)setSpellingCorrectionEnabled:(BOOL)value
{
	[TXNSUserDefaultsPointer() setBool:value forKey:@"spellingCorrection"];
}

+ (BOOL)smartInsertDeleteEnabled
{
	if (![TXNSUserDefaultsPointer() objectForKey:@"smartInsertDelete"]) return YES;
	return [TXNSUserDefaultsPointer() boolForKey:@"smartInsertDelete"];
}

+ (void)setSmartInsertDeleteEnabled:(BOOL)value
{
	[TXNSUserDefaultsPointer() setBool:value forKey:@"smartInsertDelete"];
}

+ (BOOL)quoteSubstitutionEnabled
{
	return [TXNSUserDefaultsPointer() boolForKey:@"quoteSubstitution"];
}

+ (void)setQuoteSubstitutionEnabled:(BOOL)value
{
	[TXNSUserDefaultsPointer() setBool:value forKey:@"quoteSubstitution"];
}

+ (BOOL)dashSubstitutionEnabled
{
	return [TXNSUserDefaultsPointer() boolForKey:@"dashSubstitution"];
}

+ (void)setDashSubstitutionEnabled:(BOOL)value
{
	[TXNSUserDefaultsPointer() setBool:value forKey:@"dashSubstitution"];
}

+ (BOOL)linkDetectionEnabled
{
	return [TXNSUserDefaultsPointer() boolForKey:@"linkDetection"];
}

+ (void)setLinkDetectionEnabled:(BOOL)value
{
	[TXNSUserDefaultsPointer() setBool:value forKey:@"linkDetection"];
}

+ (BOOL)dataDetectionEnabled
{
	return [TXNSUserDefaultsPointer() boolForKey:@"dataDetection"];
}

+ (void)setDataDetectionEnabled:(BOOL)value
{
	[TXNSUserDefaultsPointer() setBool:value forKey:@"dataDetection"];
}

+ (BOOL)textReplacementEnabled
{
	return [TXNSUserDefaultsPointer() boolForKey:@"textReplacement"];
}

+ (void)setTextReplacementEnabled:(BOOL)value
{
	[TXNSUserDefaultsPointer() setBool:value forKey:@"textReplacement"];
}

#pragma mark -
#pragma mark Growl

+ (BOOL)registeredToGrowl
{
	return [TXNSUserDefaultsPointer() boolForKey:@"registeredToGrowl"];
}

+ (void)setRegisteredToGrowl:(BOOL)value
{
	[TXNSUserDefaultsPointer() setBool:value forKey:@"registeredToGrowl"];
}

#pragma mark -
#pragma mark World

+ (NSDictionary*)loadWorld
{
	return [TXNSUserDefaultsPointer() objectForKey:@"world"];
}

+ (void)saveWorld:(NSDictionary*)value
{
	[TXNSUserDefaultsPointer() setObject:value forKey:@"world"];
}

#pragma mark -
#pragma mark Window

+ (NSDictionary*)loadWindowStateWithName:(NSString*)name
{
	return [TXNSUserDefaultsPointer() objectForKey:name];
}

+ (void)saveWindowState:(NSDictionary*)value name:(NSString*)name
{
	[TXNSUserDefaultsPointer() setObject:value forKey:name];
}

#pragma mark -
#pragma mark Keywords

static NSMutableArray* keywords;
static NSMutableArray* excludeWords;

+ (void)loadKeywords
{
	if (keywords) {
		[keywords removeAllObjects];
	} else {
		keywords = [NSMutableArray new];
	}
	
	NSArray* ary = [TXNSUserDefaultsPointer() objectForKey:@"keywords"];
	
	for (NSDictionary* e in ary) {
		NSString* s = [e objectForKey:@"string"];
		
		if (s) [keywords addObject:s];
	}
}

+ (void)loadExcludeWords
{
	if (excludeWords) {
		[excludeWords removeAllObjects];
	} else {
		excludeWords = [NSMutableArray new];
	}
	
	NSArray* ary = [TXNSUserDefaultsPointer() objectForKey:@"excludeWords"];
	
	for (NSDictionary* e in ary) {
		NSString* s = [e objectForKey:@"string"];
		
		if (s) [excludeWords addObject:s];
	}
}

+ (void)cleanUpWords:(NSString*)key
{
	NSArray* src = [TXNSUserDefaultsPointer() objectForKey:key];
	
	NSMutableArray* ary = [NSMutableArray array];
	
	for (NSDictionary* e in src) {
		NSString* s = [e objectForKey:@"string"];
		
		if (s.length) {
			[ary addObject:s];
		}
	}
	
	[ary sortUsingSelector:@selector(caseInsensitiveCompare:)];
	
	NSMutableArray* saveAry = [NSMutableArray array];
	
	for (NSString* s in ary) {
		NSMutableDictionary* dic = [NSMutableDictionary dictionary];
		
		[dic setObject:s forKey:@"string"];
		[saveAry addObject:dic];
	}
	
	[TXNSUserDefaultsPointer() setObject:saveAry forKey:key];
	[TXNSUserDefaultsPointer() synchronize];
}

+ (void)cleanUpWords
{
	[self cleanUpWords:@"keywords"];
	[self cleanUpWords:@"excludeWords"];
}

+ (NSArray*)keywords
{
	return keywords;
}

+ (NSArray*)excludeWords
{
	return excludeWords;
}

#pragma mark -
#pragma mark KVO

+ (void)observeValueForKeyPath:(NSString*)key
					  ofObject:(id)object
						change:(NSDictionary *)change
					   context:(void *)context
{
	if ([key isEqualToString:@"keywords"]) {
		[self loadKeywords];
	} else if ([key isEqualToString:@"excludeWords"]) {
		[self loadExcludeWords];
	}
}

+ (void)defaultIRCClientSheetCallback:(NSAlert *)alert returnCode:(int)returnCode contextInfo:(void *)contextInfo
{	
	[TXNSUserDefaultsPointer() setBool:[[alert suppressionButton] state] forKey:@"Preferences.prompts.default_irc_client"];
	
	if (returnCode == NSAlertFirstButtonReturn) {
		NSString *bundleID = [[NSBundle mainBundle] bundleIdentifier];
		OSStatus changeResult = LSSetDefaultHandlerForURLScheme((CFStringRef)@"irc", (CFStringRef)bundleID);
		
		if (changeResult == noErr) return;
	}
}

+ (void)defaultIRCClientPrompt
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	[NSThread sleepForTimeInterval:1.5];
	
    CFURLRef ircAppURL = NULL;
    OSStatus status = LSGetApplicationForURL((CFURLRef)[NSURL URLWithString:@"irc:"], kLSRolesAll, NULL, &ircAppURL);
	
	if (status == noErr) {
		NSBundle *mainBundle = [NSBundle mainBundle];
		NSBundle *defaultClientBundle = [NSBundle bundleWithURL:(NSURL *)ircAppURL];
		
		if ([defaultClientBundle isEqual:mainBundle] == NO) {	
			BOOL suppCheck = [TXNSUserDefaultsPointer() boolForKey:@"Preferences.prompts.default_irc_client"];
			
			if (suppCheck == NO) {
				NSAlert *alert = [[NSAlert alloc] init];
				
				[alert autorelease];
				
				[alert addButtonWithTitle:TXTLS(@"YES_BUTTON")];
				[alert addButtonWithTitle:TXTLS(@"NO_BUTTON")];
				[alert setMessageText:TXTLS(@"DEFAULT_IRC_CLIENT_PROMPT_TITLE")];
				[alert setInformativeText:TXTLS(@"DEFAULT_IRC_CLIENT_PROMPT_MESSAGE")];
				[alert setShowsSuppressionButton:YES];
				[[alert suppressionButton] setTitle:TXTLS(@"SUPPRESSION_BUTTON_DEFAULT_TITLE")];
				[alert setAlertStyle:NSInformationalAlertStyle];
				[alert beginSheetModalForWindow:[NSApp mainWindow] modalDelegate:self didEndSelector:@selector(defaultIRCClientSheetCallback:returnCode:contextInfo:) contextInfo:nil];
			}
		}
	}
	
	if (ircAppURL) TXCFSpecialRelease(ircAppURL);
	
	[pool release];
}

+ (void)initPreferences
{
	if ([TXNSUserDefaultsPointer() boolForKey:@"TXTNotFirstRun"] == YES) {
		[[self invokeInBackgroundThread] defaultIRCClientPrompt];
	} else {
		[TXNSUserDefaultsPointer() setBool:YES forKey:@"TXTNotFirstRun"];
	}
	
	// ====================================================== //
	
	startUpTime = (long)[[NSDate date] timeIntervalSince1970];
	
	NSString* nick = NSUserName();
	
	nick = [nick stringByReplacingOccurrencesOfString:@" " withString:@"_"];
	nick = [nick stringByMatching:@"[^a-zA-Z0-9-_]" replace:RKReplaceAll withReferenceString:@""];

	if (nick == nil) {
		nick = @"User";
	}
	
	// ====================================================== //
	
	NSMutableDictionary* d = [NSMutableDictionary dictionary];
	
	[d setBool:YES forKey:@"WebKitDeveloperExtras"];
	[d setInt:DCC_SHOW_DIALOG forKey:@"Preferences.DCC.action"];
	[d setInt:ADDRESS_DETECT_JOIN forKey:@"Preferences.DCC.address_detection_method"];
	[d setObject:@"" forKey:@"Preferences.DCC.myaddress"];
	[d setObject:nick forKey:@"Preferences.Identity.nickname"];
	[d setBool:NO forKey:@"Preferences.General.copyonselect"];
	[d setBool:NO forKey:@"Preferences.General.strip_formatting"];
	[d setBool:NO forKey:@"Preferences.General.rtl_formatting"];
	[d setBool:YES forKey:@"Preferences.General.display_servmotd"];
	[d setObject:@"textual" forKey:@"Preferences.Identity.username"];
	[d setObject:@"Textual User" forKey:@"Preferences.Identity.realname"];
	[d setBool:YES forKey:@"Preferences.General.dockbadges"];
	[d setBool:YES forKey:@"Preferences.General.autoadd_scrollbackmark"];
	[d setBool:NO forKey:@"Preferences.General.handle_server_notices"];
	[d setObject:@"ircop alert" forKey:@"Preferences.General.ircop_alert_match"];
	[d setBool:NO forKey:@"Preferences.FloodControl.enabled"];
	[d setInt:2 forKey:@"Preferences.FloodControl.timer"];
	[d setInt:2 forKey:@"Preferences.FloodControl.maxmsg"];
	[d setInt:5 forKey:@"Preferences.General.autojoin_maxchans"];
	[d setBool:NO forKey:@"Preferences.General.handle_operalerts"];
	[d setBool:NO forKey:@"Preferences.General.process_channel_modes"];
	[d setBool:NO forKey:@"Preferences.General.clear_only_active"];
	[d setBool:NO forKey:@"Preferences.General.rejoin_onkick"];
	[d setBool:NO forKey:@"Preferences.General.autojoin_oninvite"];
	[d setBool:NO forKey:@"Preferences.General.amsg_allconnections"];
	[d setBool:NO forKey:@"Preferences.General.away_allconnections"];
	[d setBool:NO forKey:@"Preferences.General.nick_allconnections"];
	[d setObject:TXTLS(@"SHUN_REASON") forKey:@"Preferences.General.ircop_shun_message"];
	[d setObject:TXTLS(@"KILL_REASON") forKey:@"Preferences.General.ircop_kill_message"];
	[d setObject:TXTLS(@"GLINE_REASON") forKey:@"Preferences.General.ircop_gline_message"];
	[d setObject:TXTLS(@"KICK_REASON") forKey:@"Preferences.General.kick_message"];
	[d setBool:YES forKey:@"Preferences.General.confirm_quit"];
	[d setBool:NO forKey:@"Preferences.General.connect_on_doubleclick"];
	[d setBool:NO forKey:@"Preferences.General.disconnect_on_doubleclick"];
	[d setBool:NO forKey:@"Preferences.General.join_on_doubleclick"];
	[d setBool:NO forKey:@"Preferences.General.leave_on_doubleclick"];
	[d setBool:YES forKey:@"Preferences.General.log_transcript"];
	[d setBool:NO forKey:@"Preferences.General.open_browser_in_background"];
	[d setBool:NO forKey:@"Preferences.General.show_inline_images"];
	[d setBool:YES forKey:@"Preferences.General.use_growl"];
	[d setBool:YES forKey:@"Preferences.General.stop_growl_on_active"];
	[d setBool:YES forKey:@"eventHighlightGrowl"];
	[d setBool:YES forKey:@"eventNewtalkGrowl"];
	[d setInt:TAB_COMPLETE_NICK forKey:@"Preferences.General.tab_action"];
	[d setBool:YES forKey:@"Preferences.Keyword.current_nick"];
	[d setInt:KEYWORD_MATCH_PARTIAL forKey:@"Preferences.Keyword.matching_method"];
	[d setObject:@"user:Simplified Dark" forKey:@"Preferences.Theme.name"];
	[d setObject:@"Lucida Grande" forKey:@"Preferences.Theme.log_font_name"];
	[d setDouble:12 forKey:@"Preferences.Theme.log_font_size"];
	[d setObject:@"<%@%n>" forKey:@"Preferences.Theme.nick_format"];
	[d setBool:NO forKey:@"Preferences.Theme.override_log_font"];
	[d setBool:NO forKey:@"Preferences.Theme.override_nick_format"];
	[d setBool:YES forKey:@"Preferences.Theme.indent_onwordwrap"];
	[d setBool:NO forKey:@"Preferences.Theme.override_timestamp_format"];
	[d setObject:@"[%m/%d/%Y -:- %I:%M:%S %p]" forKey:@"Preferences.Theme.timestamp_format"];
	[d setDouble:1 forKey:@"Preferences.Theme.transparency"];
	[d setBool:NO forKey:@"Preferences.General.log_highlights"];
	[d setInt:1 forKey:@"Preferences.General.autojoin_delay"];
	[d setInt:1096 forKey:@"Preferences.DCC.first_port"];
	[d setInt:1115 forKey:@"Preferences.DCC.last_port"];
	[d setBool:YES forKey:@"Preferences.General.show_join_leave"];
	[d setBool:NO forKey:@"Preferences.Theme.inputhistory_per_channel"];
	[d setInt:300 forKey:@"Preferences.General.max_log_lines"];
	[d setInt:300 forKey:@"Preferences.General.inline_image_width"];
	[d setBool:NO forKey:@"Preferences.General.dockbadge_countpub"];
	[d setBool:NO forKey:@"Preferences.General.disable_nickname_colors"];
	[d setObject:@"~/Documents/Textual Logs" forKey:@"Preferences.General.transcript_folder"];
	[d setInt:HMBAN_FORMAT_WHAINN forKey:@"Preferences.General.banformat"];
	[d setInt:NOTICES_SENDTO_CONSOLE forKey:@"Preferences.General.notices_sendto_location"];
	[d setInt:USERDC_ACTION_QUERY forKey:@"Preferences.General.user_doubleclick_action"];
	[d setInt:CMDWKEY_SHORTCUT_CLOSE forKey:@"Preferences.General.keyboard_cmdw_response"];
	
	[TXNSUserDefaultsPointer() registerDefaults:d];
	
	[TXNSUserDefaultsPointer() addObserver:(NSObject*)self forKeyPath:@"keywords" options:NSKeyValueObservingOptionNew context:NULL];
	[TXNSUserDefaultsPointer() addObserver:(NSObject*)self forKeyPath:@"excludeWords" options:NSKeyValueObservingOptionNew context:NULL];
	
	systemVersionPlist = [[NSDictionary allocWithZone:nil] initWithContentsOfFile:@"/System/Library/CoreServices/ServerVersion.plist"];
	if (!systemVersionPlist) systemVersionPlist = [[NSDictionary allocWithZone:nil] initWithContentsOfFile:@"/System/Library/CoreServices/SystemVersion.plist"];
	if (!systemVersionPlist) exit(10);
	
	textualPlist = [[NSBundle mainBundle] infoDictionary];
	
	[self loadKeywords];
	[self loadExcludeWords];
	[self populateCommandIndex];
}

+ (void)sync
{
	[TXNSUserDefaultsPointer() synchronize];
}

@end