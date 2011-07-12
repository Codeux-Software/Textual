// Created by Satoshi Nakagawa <psychs AT limechat DOT net> <http://github.com/psychs/limechat>
// Modifications by Codeux Software <support AT codeux DOT com> <https://github.com/codeux/Textual>
// You can redistribute it and/or modify it under the new BSD license.

#import "ValidateReceipt.h"

@implementation Preferences

#pragma mark -
#pragma mark Version Dictonaries

static NSDictionary *textualPlist		= nil;
static NSDictionary *systemVersionPlist = nil;

+ (NSDictionary *)textualInfoPlist
{
	return textualPlist;
}

+ (NSDictionary *)systemInfoPlist 
{
	return systemVersionPlist;
}

#pragma mark -
#pragma mark App Store Receipt Validation

+ (void)validateStoreReceipt
{
	NSString *receipt = [self whereAppStoreReceipt];
	
	if (validateReceiptAtPath(receipt) == NO) {
		exit(173);
	} else {
		NSLog(@"Valid app store receipt located. Launching.");
	}
}

#pragma mark -
#pragma mark Command Index

static NSMutableDictionary *commandIndex = nil;

+ (NSDictionary *)commandIndexList
{
	return commandIndex;
}

+ (void)populateCommandIndex
{
	commandIndex = [NSMutableDictionary new];
	
	[commandIndex setObject:@"3"   forKey:IRCCI_AWAY];
	[commandIndex setObject:@"4"   forKey:IRCCI_ERROR];
	[commandIndex setObject:@"5"   forKey:IRCCI_INVITE];
	[commandIndex setObject:@"6"   forKey:IRCCI_ISON];
	[commandIndex setObject:@"7"   forKey:IRCCI_JOIN];
	[commandIndex setObject:@"8"   forKey:IRCCI_KICK];
	[commandIndex setObject:@"9"   forKey:IRCCI_KILL];
	[commandIndex setObject:@"10"  forKey:IRCCI_LIST];
	[commandIndex setObject:@"11"  forKey:IRCCI_MODE];
	[commandIndex setObject:@"12"  forKey:IRCCI_NAMES];
	[commandIndex setObject:@"13"  forKey:IRCCI_NICK];
	[commandIndex setObject:@"14"  forKey:IRCCI_NOTICE];
	[commandIndex setObject:@"15"  forKey:IRCCI_PART];
	[commandIndex setObject:@"16"  forKey:IRCCI_PASS];
	[commandIndex setObject:@"17"  forKey:IRCCI_PING];
	[commandIndex setObject:@"18"  forKey:IRCCI_PONG];
	[commandIndex setObject:@"19"  forKey:IRCCI_PRIVMSG];
	[commandIndex setObject:@"20"  forKey:IRCCI_QUIT];
	[commandIndex setObject:@"21"  forKey:IRCCI_TOPIC];
	[commandIndex setObject:@"22"  forKey:IRCCI_USER];
	[commandIndex setObject:@"23"  forKey:IRCCI_WHO];
	[commandIndex setObject:@"24"  forKey:IRCCI_WHOIS];
	[commandIndex setObject:@"25"  forKey:IRCCI_WHOWAS];
	[commandIndex setObject:@"27"  forKey:IRCCI_ACTION];
	[commandIndex setObject:@"28"  forKey:IRCCI_DCC];
	[commandIndex setObject:@"29"  forKey:IRCCI_SEND];
	[commandIndex setObject:@"31"  forKey:IRCCI_CLIENTINFO];
	[commandIndex setObject:@"32"  forKey:IRCCI_CTCP];
	[commandIndex setObject:@"33"  forKey:IRCCI_CTCPREPLY];
	[commandIndex setObject:@"34"  forKey:IRCCI_TIME];
	[commandIndex setObject:@"35"  forKey:IRCCI_USERINFO];
	[commandIndex setObject:@"36"  forKey:IRCCI_VERSION];
	[commandIndex setObject:@"38"  forKey:IRCCI_OMSG];
	[commandIndex setObject:@"39"  forKey:IRCCI_ONOTICE];
	[commandIndex setObject:@"41"  forKey:IRCCI_BAN];
	[commandIndex setObject:@"42"  forKey:IRCCI_CLEAR];
	[commandIndex setObject:@"43"  forKey:IRCCI_CLOSE];
	[commandIndex setObject:@"44"  forKey:IRCCI_CYCLE];
	[commandIndex setObject:@"45"  forKey:IRCCI_DEHALFOP];
	[commandIndex setObject:@"46"  forKey:IRCCI_DEOP];
	[commandIndex setObject:@"47"  forKey:IRCCI_DEVOICE];
	[commandIndex setObject:@"48"  forKey:IRCCI_HALFOP];
	[commandIndex setObject:@"49"  forKey:IRCCI_HOP];
	[commandIndex setObject:@"50"  forKey:IRCCI_IGNORE];
	[commandIndex setObject:@"51"  forKey:IRCCI_J];
	[commandIndex setObject:@"52"  forKey:IRCCI_LEAVE];
	[commandIndex setObject:@"53"  forKey:IRCCI_M];
	[commandIndex setObject:@"54"  forKey:IRCCI_ME];
	[commandIndex setObject:@"55"  forKey:IRCCI_MSG];
	[commandIndex setObject:@"56"  forKey:IRCCI_OP];
	[commandIndex setObject:@"57"  forKey:IRCCI_RAW];
	[commandIndex setObject:@"58"  forKey:IRCCI_REJOIN];
	[commandIndex setObject:@"59"  forKey:IRCCI_QUERY];
	[commandIndex setObject:@"60"  forKey:IRCCI_QUOTE];
	[commandIndex setObject:@"61"  forKey:IRCCI_T];
	[commandIndex setObject:@"62"  forKey:IRCCI_TIMER];
	[commandIndex setObject:@"63"  forKey:IRCCI_VOICE];
	[commandIndex setObject:@"64"  forKey:IRCCI_UNBAN];
	[commandIndex setObject:@"65"  forKey:IRCCI_UNIGNORE];
	[commandIndex setObject:@"66"  forKey:IRCCI_UMODE];
	[commandIndex setObject:@"67"  forKey:IRCCI_VERSION];
	[commandIndex setObject:@"68"  forKey:IRCCI_WEIGHTS];
	[commandIndex setObject:@"69"  forKey:IRCCI_ECHO];
	[commandIndex setObject:@"70"  forKey:IRCCI_DEBUG];
	[commandIndex setObject:@"71"  forKey:IRCCI_CLEARALL];
	[commandIndex setObject:@"72"  forKey:IRCCI_AMSG];
	[commandIndex setObject:@"73"  forKey:IRCCI_AME];
	[commandIndex setObject:@"74"  forKey:IRCCI_MUTE]; 
	[commandIndex setObject:@"75"  forKey:IRCCI_UNMUTE]; 
	[commandIndex setObject:@"76"  forKey:IRCCI_UNLOAD_PLUGINS]; 
	[commandIndex setObject:@"77"  forKey:IRCCI_REMOVE];  
	[commandIndex setObject:@"79"  forKey:IRCCI_KICKBAN]; 
	[commandIndex setObject:@"80"  forKey:IRCCI_WALLOPS]; 
	[commandIndex setObject:@"81"  forKey:IRCCI_ICBADGE];
	[commandIndex setObject:@"82"  forKey:IRCCI_SERVER];
	[commandIndex setObject:@"83"  forKey:IRCCI_CONN]; 
	[commandIndex setObject:@"84"  forKey:IRCCI_MYVERSION]; 
	[commandIndex setObject:@"85"  forKey:IRCCI_CHATOPS]; 
	[commandIndex setObject:@"86"  forKey:IRCCI_GLOBOPS]; 
	[commandIndex setObject:@"87"  forKey:IRCCI_LOCOPS]; 
	[commandIndex setObject:@"88"  forKey:IRCCI_NACHAT]; 
	[commandIndex setObject:@"89"  forKey:IRCCI_ADCHAT]; 
	[commandIndex setObject:@"90"  forKey:IRCCI_RESETFILES];
	[commandIndex setObject:@"91"  forKey:IRCCI_LOAD_PLUGINS];
	[commandIndex setObject:@"92"  forKey:IRCCI_SME];
	[commandIndex setObject:@"93"  forKey:IRCCI_SMSG];
	[commandIndex setObject:@"94"  forKey:IRCCI_LAGCHECK];
	[commandIndex setObject:@"95"  forKey:IRCCI_MYLAG];
	[commandIndex setObject:@"96"  forKey:IRCCI_ZLINE];
	[commandIndex setObject:@"97"  forKey:IRCCI_GLINE];
	[commandIndex setObject:@"98"  forKey:IRCCI_GZLINE];
	[commandIndex setObject:@"99"  forKey:IRCCI_SHUN];
	[commandIndex setObject:@"100" forKey:IRCCI_TEMPSHUN];
}

+ (NSInteger)commandUIndex:(NSString *)command 
{
	return [commandIndex integerForKey:[command uppercaseString]];
}

#pragma mark -
#pragma mark Application Information

+ (BOOL)applicationRanOnLion
{
	return (floor(NSAppKitVersionNumber) > NSAppKitVersionNumber10_6);
}

+ (NSData *)applicationIcon
{
	return [[NSApp applicationIconImage] TIFFRepresentation];
}

+ (NSString *)applicationName;
{
	return [textualPlist objectForKey:@"CFBundleName"];
}

+ (NSInteger)applicationProcessID
{
	return [[NSProcessInfo processInfo] processIdentifier];
}

#pragma mark -
#pragma mark Path Index

+ (NSString *)whereApplicationSupportPath
{
	return [@"~/Library/Application Support/Textual/" stringByExpandingTildeInPath];
}

+ (NSString *)whereScriptsPath
{
	return [@"~/Library/Application Support/Textual/Scripts" stringByExpandingTildeInPath];
}

+ (NSString *)whereThemesPath
{
	return [@"~/Library/Application Support/Textual/Styles" stringByExpandingTildeInPath];
}

+ (NSString *)wherePluginsPath
{
	return [@"~/Library/Application Support/Textual/Extensions" stringByExpandingTildeInPath];
}

+ (NSString *)whereScriptsLocalPath
{
	return [[self whereResourcePath] stringByAppendingPathComponent:@"Scripts"];
}

+ (NSString *)whereThemesLocalPath
{
	return [[self whereResourcePath] stringByAppendingPathComponent:@"Styles"];	
}

+ (NSString *)wherePluginsLocalPath
{
	return [[self whereResourcePath] stringByAppendingPathComponent:@"Extensions"];	
}

+ (NSString *)whereAppStoreReceipt
{
	return [[self whereMainApplicationBundle] stringByAppendingPathComponent:@"/Contents/_MASReceipt/receipt"];
}

+ (NSString *)whereResourcePath 
{
	return [[NSBundle mainBundle] resourcePath];
}

+ (NSString *)whereMainApplicationBundle
{
	return [[NSBundle mainBundle] bundlePath];
}

#pragma mark -
#pragma mark Flood Control

+ (BOOL)floodControlIsEnabled
{
	return [_NSUserDefaults() boolForKey:@"Preferences.FloodControl.enabled"];
}

+ (NSInteger)floodControlMaxMessages
{
	return [_NSUserDefaults() integerForKey:@"Preferences.FloodControl.maxmsg"];
}

+ (NSInteger)floodControlDelayTimer
{
	return [_NSUserDefaults() integerForKey:@"Preferences.FloodControl.timer"];
}

#pragma mark -
#pragma mark Default Identity

+ (NSString *)defaultNickname
{
	return [_NSUserDefaults() objectForKey:@"Preferences.Identity.nickname"];
}

+ (NSString *)defaultUsername
{
	return [_NSUserDefaults() objectForKey:@"Preferences.Identity.username"];
}

+ (NSString *)defaultRealname
{
	return [_NSUserDefaults() objectForKey:@"Preferences.Identity.realname"];
}

#pragma mark - 
#pragma mark General Preferences

/* There is no real logic to how the following preferences are ordered. */

+ (NSInteger)autojoinMaxChannelJoins
{
	return [_NSUserDefaults() integerForKey:@"Preferences.General.autojoin_maxchans"];
}

+ (NSString *)defaultKickMessage
{
	return [_NSUserDefaults() objectForKey:@"Preferences.General.kick_message"];
}

+ (NSString *)IRCopDefaultKillMessage
{
	return [_NSUserDefaults() objectForKey:@"Preferences.General.ircop_kill_message"];
}

+ (NSString *)IRCopDefaultGlineMessage
{
	return [_NSUserDefaults() objectForKey:@"Preferences.General.ircop_gline_message"];
}

+ (NSString *)IRCopDefaultShunMessage
{
	return [_NSUserDefaults() objectForKey:@"Preferences.General.ircop_shun_message"];
}

+ (NSString *)IRCopAlertMatch
{
	return [_NSUserDefaults() objectForKey:@"Preferences.General.ircop_alert_match"];
}

+ (BOOL)trackConversations
{
	return [_NSUserDefaults() boolForKey:@"Preferences.General.track_conversations"];
}

+ (BOOL)autojoinWaitForNickServ
{
	return [_NSUserDefaults() boolForKey:@"Preferences.General.nickserv_delay_autojoin"];
}

+ (BOOL)logAllHighlightsToQuery
{
	return [_NSUserDefaults() boolForKey:@"Preferences.General.log_highlights"];
}

+ (BOOL)clearAllOnlyOnActiveServer
{
	return [_NSUserDefaults() boolForKey:@"Preferences.General.clear_only_active"];
}

+ (BOOL)displayServerMOTD
{
	return [_NSUserDefaults() boolForKey:@"Preferences.General.display_servmotd"];
}

+ (BOOL)copyOnSelect
{
	return [_NSUserDefaults() boolForKey:@"Preferences.General.copyonselect"];
}

+ (BOOL)autoAddScrollbackMark
{
	return [_NSUserDefaults() boolForKey:@"Preferences.General.autoadd_scrollbackmark"];
}

+ (BOOL)removeAllFormatting
{
	return [_NSUserDefaults() boolForKey:@"Preferences.General.strip_formatting"];
}

+ (BOOL)disableNicknameColors
{
	return [_NSUserDefaults() boolForKey:@"Preferences.General.disable_nickname_colors"];
}

+ (BOOL)rightToLeftFormatting
{
	return [_NSUserDefaults() boolForKey:@"Preferences.General.rtl_formatting"];
}

+ (NSString *)completionSuffix
{
	return [_NSUserDefaults() objectForKey:@"Preferences.General.completion_suffix"];
}

+ (HostmaskBanFormat)banFormat
{
	return [_NSUserDefaults() boolForKey:@"Preferences.General.banformat"];
}

+ (BOOL)displayDockBadge
{
	return [_NSUserDefaults() boolForKey:@"Preferences.General.dockbadges"];
}

+ (BOOL)handleIRCopAlerts
{
	return [_NSUserDefaults() boolForKey:@"Preferences.General.handle_operalerts"];
}

+ (BOOL)handleServerNotices
{
	return [_NSUserDefaults() boolForKey:@"Preferences.General.handle_server_notices"];
}

+ (BOOL)amsgAllConnections
{
	return [_NSUserDefaults() boolForKey:@"Preferences.General.amsg_allconnections"];
}

+ (BOOL)awayAllConnections
{
	return [_NSUserDefaults() boolForKey:@"Preferences.General.away_allconnections"];
}

+ (BOOL)nickAllConnections
{
	return [_NSUserDefaults() boolForKey:@"Preferences.General.nick_allconnections"];
}

+ (BOOL)indentOnHang
{
	return [_NSUserDefaults() boolForKey:@"Preferences.Theme.indent_onwordwrap"];
}

+ (BOOL)confirmQuit
{
	return [_NSUserDefaults() boolForKey:@"Preferences.General.confirm_quit"];
}

+ (BOOL)processChannelModes
{
	return [_NSUserDefaults() boolForKey:@"Preferences.General.process_channel_modes"];
}

+ (BOOL)rejoinOnKick
{
	return [_NSUserDefaults() boolForKey:@"Preferences.General.rejoin_onkick"];
}

+ (BOOL)autoJoinOnInvite
{
	return [_NSUserDefaults() boolForKey:@"Preferences.General.autojoin_oninvite"];
}

+ (BOOL)connectOnDoubleclick
{
	return [_NSUserDefaults() boolForKey:@"Preferences.General.connect_on_doubleclick"];
}

+ (BOOL)disconnectOnDoubleclick
{
	return [_NSUserDefaults() boolForKey:@"Preferences.General.disconnect_on_doubleclick"];
}

+ (BOOL)joinOnDoubleclick
{
	return [_NSUserDefaults() boolForKey:@"Preferences.General.join_on_doubleclick"];
}

+ (BOOL)leaveOnDoubleclick
{
	return [_NSUserDefaults() boolForKey:@"Preferences.General.leave_on_doubleclick"];
}

+ (BOOL)logTranscript
{
	return [_NSUserDefaults() boolForKey:@"Preferences.General.log_transcript"];
}

+ (BOOL)openBrowserInBackground
{
	return [_NSUserDefaults() boolForKey:@"Preferences.General.open_browser_in_background"];
}

+ (BOOL)showInlineImages
{
	return [_NSUserDefaults() boolForKey:@"Preferences.General.show_inline_images"];
}

+ (BOOL)showJoinLeave
{
	return [_NSUserDefaults() boolForKey:@"Preferences.General.show_join_leave"];
}

+ (BOOL)stopGrowlOnActive
{
	return [_NSUserDefaults() boolForKey:@"Preferences.General.stop_growl_on_active"];
}

+ (BOOL)countPublicMessagesInIconBadge
{
	return [_NSUserDefaults() boolForKey:@"Preferences.General.dockbadge_countpub"];
}

+ (TabActionType)tabAction
{
	return [_NSUserDefaults() integerForKey:@"Preferences.General.tab_action"];
}

+ (BOOL)keywordCurrentNick
{
	return [_NSUserDefaults() boolForKey:@"Preferences.Keyword.current_nick"];
}

+ (NSArray *)keywordDislikeWords
{
	return [_NSUserDefaults() objectForKey:@"Preferences.Keyword.dislike_words"];
}

+ (KeywordMatchType)keywordMatchingMethod
{
	return [_NSUserDefaults() integerForKey:@"Preferences.Keyword.matching_method"];
}

+ (NSArray *)keywordWords
{
	return [_NSUserDefaults() objectForKey:@"Preferences.Keyword.words"];
}

+ (UserDoubleClickAction)userDoubleClickOption
{
	return [_NSUserDefaults() integerForKey:@"Preferences.General.user_doubleclick_action"];
}

+ (NoticesSendToLocation)locationToSendNotices
{
	return [_NSUserDefaults() integerForKey:@"Preferences.General.notices_sendto_location"];
}

+ (CmdW_Shortcut_ResponseType)cmdWResponseType
{
	return [_NSUserDefaults() integerForKey:@"Preferences.General.keyboard_cmdw_response"];
}

#pragma mark -
#pragma mark Theme

+ (NSString *)themeName
{
	return [_NSUserDefaults() objectForKey:@"Preferences.Theme.name"];
}

+ (void)setThemeName:(NSString *)value
{
	[_NSUserDefaults() setObject:value forKey:@"Preferences.Theme.name"];
}

+ (NSString *)themeLogFontName
{
	return [_NSUserDefaults() objectForKey:@"Preferences.Theme.log_font_name"];
}

+ (void)setThemeLogFontName:(NSString *)value
{
	[_NSUserDefaults() setObject:value forKey:@"Preferences.Theme.log_font_name"];
}

+ (double)themeLogFontSize
{
	return [_NSUserDefaults() doubleForKey:@"Preferences.Theme.log_font_size"];
}

+ (void)setThemeLogFontSize:(double)value
{
	[_NSUserDefaults() setDouble:value forKey:@"Preferences.Theme.log_font_size"];
}

+ (NSString *)themeNickFormat
{
	return [_NSUserDefaults() objectForKey:@"Preferences.Theme.nick_format"];
}

+ (BOOL)inputHistoryIsChannelSpecific
{
	return [_NSUserDefaults() boolForKey:@"Preferences.Theme.inputhistory_per_channel"];
}

+ (NSString *)themeTimestampFormat
{
	return [_NSUserDefaults() objectForKey:@"Preferences.Theme.timestamp_format"];
}

+ (double)themeTransparency
{
	return [_NSUserDefaults() doubleForKey:@"Preferences.Theme.transparency"];
}

#pragma mark -
#pragma mark Completion Suffix

+ (void)setCompletionSuffix:(NSString *)value
{
	[_NSUserDefaults() setObject:value forKey:@"Preferences.General.completion_suffix"];
}

#pragma mark -
#pragma mark Inline Image Size

+ (NSInteger)inlineImagesMaxWidth
{
	return [_NSUserDefaults() integerForKey:@"Preferences.General.inline_image_width"];
}

+ (void)setInlineImagesMaxWidth:(NSInteger)value
{
	[_NSUserDefaults() setInteger:value forKey:@"Preferences.General.inline_image_width"];
}

#pragma mark -
#pragma mark Max Log Lines

+ (NSInteger)maxLogLines
{
	return [_NSUserDefaults() integerForKey:@"Preferences.General.max_log_lines"];
}

+ (void)setMaxLogLines:(NSInteger)value
{
	[_NSUserDefaults() setInteger:value forKey:@"Preferences.General.max_log_lines"];
}

#pragma mark -
#pragma mark Transcript Folder

+ (NSString *)transcriptFolder
{
	return [_NSUserDefaults() objectForKey:@"Preferences.General.transcript_folder"];
}

+ (void)setTranscriptFolder:(NSString *)value
{
	[_NSUserDefaults() setObject:value forKey:@"Preferences.General.transcript_folder"];
}

#pragma mark -
#pragma mark Events

+ (NSString *)titleForEvent:(GrowlNotificationType)event
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

+ (NSString *)keyForEvent:(GrowlNotificationType)event
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

+ (NSString *)soundForEvent:(GrowlNotificationType)event
{
	NSString *key = [[self keyForEvent:event] stringByAppendingString:@"Sound"];
	
	return [_NSUserDefaults() objectForKey:key];
}

+ (void)setSound:(NSString *)value forEvent:(GrowlNotificationType)event
{
	NSString *key = [[self keyForEvent:event] stringByAppendingString:@"Sound"];
	
	[_NSUserDefaults() setObject:value forKey:key];
}

+ (BOOL)growlEnabledForEvent:(GrowlNotificationType)event
{
	NSString *key = [[self keyForEvent:event] stringByAppendingString:@"Growl"];
	
	return [_NSUserDefaults() boolForKey:key];
}

+ (void)setGrowlEnabled:(BOOL)value forEvent:(GrowlNotificationType)event
{
	NSString *key = [[self keyForEvent:event] stringByAppendingString:@"Growl"];
	
	[_NSUserDefaults() setBool:value forKey:key];
}

+ (BOOL)growlStickyForEvent:(GrowlNotificationType)event
{
	NSString *key = [[self keyForEvent:event] stringByAppendingString:@"GrowlSticky"];
	
	return [_NSUserDefaults() boolForKey:key];
}

+ (void)setGrowlSticky:(BOOL)value forEvent:(GrowlNotificationType)event
{
	NSString *key = [[self keyForEvent:event] stringByAppendingString:@"GrowlSticky"];
	
	[_NSUserDefaults() setBool:value forKey:key];
}

+ (BOOL)disableWhileAwayForEvent:(GrowlNotificationType)event
{
	NSString *key = [[self keyForEvent:event] stringByAppendingString:@"DisableWhileAway"];
	
	return [_NSUserDefaults() boolForKey:key];
}

+ (void)setDisableWhileAway:(BOOL)value forEvent:(GrowlNotificationType)event
{
	NSString *key = [[self keyForEvent:event] stringByAppendingString:@"DisableWhileAway"];
	
	[_NSUserDefaults() setBool:value forKey:key];
}

#pragma mark -
#pragma mark Growl

+ (BOOL)registeredToGrowl
{
	return [_NSUserDefaults() boolForKey:@"registeredToGrowl"];
}

+ (void)setRegisteredToGrowl:(BOOL)value
{
	[_NSUserDefaults() setBool:value forKey:@"registeredToGrowl"];
}

#pragma mark -
#pragma mark World

+ (NSDictionary *)loadWorld
{
	return [_NSUserDefaults() objectForKey:@"world"];
}

+ (void)saveWorld:(NSDictionary *)value
{
	[_NSUserDefaults() setObject:value forKey:@"world"];
}

#pragma mark -
#pragma mark Window

+ (NSDictionary *)loadWindowStateWithName:(NSString *)name
{
	return [_NSUserDefaults() objectForKey:name];
}

+ (void)saveWindowState:(NSDictionary *)value name:(NSString *)name
{
	[_NSUserDefaults() setObject:value forKey:name];
}

#pragma mark -
#pragma mark Keywords

static NSMutableArray *keywords     = nil;
static NSMutableArray *excludeWords = nil;

+ (void)loadKeywords
{
	if (keywords) {
		[keywords removeAllObjects];
	} else {
		keywords = [NSMutableArray new];
	}
	
	NSArray *ary = [_NSUserDefaults() objectForKey:@"keywords"];
	
	for (NSDictionary *e in ary) {
		NSString *s = [e objectForKey:@"string"];
		
		if (NSObjectIsNotEmpty(s)) {
			[keywords safeAddObject:s];
		}
	}
}

+ (void)loadExcludeWords
{
	if (excludeWords) {
		[excludeWords removeAllObjects];
	} else {
		excludeWords = [NSMutableArray new];
	}
	
	NSArray *ary = [_NSUserDefaults() objectForKey:@"excludeWords"];
	
	for (NSDictionary *e in ary) {
		NSString *s = [e objectForKey:@"string"];
		
		if (s) [excludeWords safeAddObject:s];
	}
}

+ (void)cleanUpWords:(NSString *)key
{
	NSArray *src = [_NSUserDefaults() objectForKey:key];
	
	NSMutableArray *ary = [NSMutableArray array];
	
	for (NSDictionary *e in src) {
		NSString *s = [e objectForKey:@"string"];
		
		if (NSObjectIsNotEmpty(s)) {
			[ary safeAddObject:s];
		}
	}
	
	[ary sortUsingSelector:@selector(caseInsensitiveCompare:)];
	
	NSMutableArray *saveAry = [NSMutableArray array];
	
	for (NSString *s in ary) {
		NSMutableDictionary *dic = [NSMutableDictionary dictionary];
		
		[dic setObject:s forKey:@"string"];
		
		[saveAry safeAddObject:dic];
	}
	
	[_NSUserDefaults() setObject:saveAry forKey:key];
	[_NSUserDefaults() synchronize];
}

+ (void)cleanUpWords
{
	[self cleanUpWords:@"keywords"];
	[self cleanUpWords:@"excludeWords"];
}

+ (NSArray *)keywords
{
	return keywords;
}

+ (NSArray *)excludeWords
{
	return excludeWords;
}

#pragma mark -
#pragma mark Start/Run Time Monitoring

static NSInteger startUpTime = 0;
static NSInteger totalRunTime = 0;

+ (NSInteger)startTime
{
	return startUpTime;
}

+ (NSInteger)totalRunTime
{
	totalRunTime  = [_NSUserDefaults() integerForKey:@"TXRunTime"];
	totalRunTime += [NSDate secondsSinceUnixTimestamp:startUpTime];
	
	return totalRunTime;
}

+ (void)updateTotalRunTime
{
	[_NSUserDefaults() setInteger:[self totalRunTime] forKey:@"TXRunTime"];
}

#pragma mark -
#pragma mark Key-Value Observing

+ (void)observeValueForKeyPath:(NSString *)key ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	if ([key isEqualToString:@"keywords"]) {
		[self loadKeywords];
	} else if ([key isEqualToString:@"excludeWords"]) {
		[self loadExcludeWords];
	}
}

#pragma mark -
#pragma mark Initialization

+ (void)defaultIRCClientSheetCallback:(NSAlert *)alert returnCode:(int)returnCode contextInfo:(void *)contextInfo
{	
	[_NSUserDefaults() setBool:[[alert suppressionButton] state] forKey:@"Preferences.prompts.default_irc_client"];
	
	if (returnCode == NSAlertFirstButtonReturn) {
		NSString *bundleID = [[NSBundle mainBundle] bundleIdentifier];
		OSStatus changeResult = LSSetDefaultHandlerForURLScheme((CFStringRef)@"irc", (CFStringRef)bundleID);
		
		if (changeResult == noErr) return;
	}
}

+ (void)defaultIRCClientPrompt
{
	[NSThread sleepForTimeInterval:1.5];
	
    CFURLRef ircAppURL = NULL;
    OSStatus status = LSGetApplicationForURL((CFURLRef)[NSURL URLWithString:@"irc:"], kLSRolesAll, NULL, &ircAppURL);
	
	if (status == noErr) {
		NSBundle *mainBundle = [NSBundle mainBundle];
		NSBundle *defaultClientBundle = [NSBundle bundleWithURL:(NSURL *)ircAppURL];
		
		if ([[defaultClientBundle bundleIdentifier] isNotEqualTo:[mainBundle bundleIdentifier]]) {
			[PopupPrompts sheetWindowWithQuestion:[NSApp keyWindow]
										   target:self
										   action:@selector(defaultIRCClientSheetCallback:returnCode:contextInfo:)
											 body:TXTLS(@"DEFAULT_IRC_CLIENT_PROMPT_MESSAGE")
											title:TXTLS(@"DEFAULT_IRC_CLIENT_PROMPT_TITLE")
									defaultButton:TXTLS(@"YES_BUTTON") 
								  alternateButton:TXTLS(@"NO_BUTTON") 
								   suppressionKey:@"Preferences.prompts.default_irc_client" 
								  suppressionText:nil];
		}
	}
	
	if (ircAppURL) CFRelease(ircAppURL);
}

+ (void)initPreferences
{
	NSInteger numberOfRuns = ([_NSUserDefaults() integerForKey:@"TXRunCount"] + 1);

	[_NSUserDefaults() setInteger:numberOfRuns forKey:@"TXRunCount"];
	
	if (numberOfRuns >= 2) {
		[[self invokeInBackgroundThread] defaultIRCClientPrompt];
	} 
	
	startUpTime = [[NSDate date] timeIntervalSince1970];
	
	// ====================================================== //
	
	NSMutableDictionary *d = [NSMutableDictionary dictionary];
	
	[d setBool:YES forKey:@"SpellChecking"];
	[d setBool:YES forKey:@"WebKitDeveloperExtras"];
	[d setBool:NO forKey:@"Preferences.General.copyonselect"];
	[d setBool:NO forKey:@"Preferences.General.strip_formatting"];
	[d setBool:NO forKey:@"Preferences.General.rtl_formatting"];
	[d setBool:YES forKey:@"Preferences.General.display_servmotd"];
	[d setObject:@"Guest" forKey:@"Preferences.Identity.nickname"];
	[d setObject:@"textual" forKey:@"Preferences.Identity.username"];
	[d setObject:@"Textual User" forKey:@"Preferences.Identity.realname"];
	[d setBool:YES forKey:@"Preferences.General.dockbadges"];
	[d setBool:YES forKey:@"Preferences.General.autoadd_scrollbackmark"];
	[d setBool:NO forKey:@"Preferences.General.handle_server_notices"];
	[d setObject:@"ircop alert" forKey:@"Preferences.General.ircop_alert_match"];
	[d setBool:NO forKey:@"Preferences.FloodControl.enabled"];
	[d setInteger:2 forKey:@"Preferences.FloodControl.timer"];
	[d setInteger:2 forKey:@"Preferences.FloodControl.maxmsg"];
	[d setInteger:5 forKey:@"Preferences.General.autojoin_maxchans"];
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
	[d setObject:@"Glass" forKey:@"eventHighlightSound"];
	[d setInteger:TAB_COMPLETE_NICK forKey:@"Preferences.General.tab_action"];
	[d setBool:YES forKey:@"Preferences.Keyword.current_nick"];
	[d setInteger:KEYWORD_MATCH_EXACT forKey:@"Preferences.Keyword.matching_method"];
	[d setObject:DEFAULT_TEXUAL_STYLE forKey:@"Preferences.Theme.name"];
	[d setObject:DEFAULT_TEXUAL_STYLE forKey:@"Preferences.Theme.log_font_name"];
	[d setDouble:12 forKey:@"Preferences.Theme.log_font_size"];
	[d setObject:@"<%@%n>" forKey:@"Preferences.Theme.nick_format"];
	[d setBool:YES forKey:@"Preferences.Theme.indent_onwordwrap"];
	[d setObject:@"[%H:%M:%S]" forKey:@"Preferences.Theme.timestamp_format"];
	[d setDouble:1 forKey:@"Preferences.Theme.transparency"];
	[d setBool:NO forKey:@"Preferences.General.log_highlights"];
	[d setBool:NO forKey:@"Preferences.General.nickserv_delay_autojoin"];
	[d setBool:YES forKey:@"Preferences.General.show_join_leave"];
	[d setBool:NO forKey:@"Preferences.Theme.inputhistory_per_channel"];
	[d setInteger:300 forKey:@"Preferences.General.max_log_lines"];
	[d setInteger:300 forKey:@"Preferences.General.inline_image_width"];
	[d setBool:NO forKey:@"Preferences.General.dockbadge_countpub"];
	[d setBool:NO forKey:@"Preferences.General.disable_nickname_colors"];
	[d setBool:YES forKey:@"Preferences.General.track_conversations"];
	[d setObject:@"~/Documents/Textual Logs" forKey:@"Preferences.General.transcript_folder"];
	[d setInteger:HMBAN_FORMAT_WHAINN forKey:@"Preferences.General.banformat"];
	[d setInteger:NOTICES_SENDTO_CONSOLE forKey:@"Preferences.General.notices_sendto_location"];
	[d setInteger:USERDC_ACTION_QUERY forKey:@"Preferences.General.user_doubleclick_action"];
	[d setInteger:CMDWKEY_SHORTCUT_CLOSE forKey:@"Preferences.General.keyboard_cmdw_response"];
    
	[_NSUserDefaults() registerDefaults:d];
	
	[_NSUserDefaults() addObserver:(NSObject *)self forKeyPath:@"keywords"     options:NSKeyValueObservingOptionNew context:NULL];
	[_NSUserDefaults() addObserver:(NSObject *)self forKeyPath:@"excludeWords" options:NSKeyValueObservingOptionNew context:NULL];
	
	systemVersionPlist = [NSDictionary dictionaryWithContentsOfFile:@"/System/Library/CoreServices/ServerVersion.plist"];
	if (NSObjectIsEmpty(systemVersionPlist)) systemVersionPlist = [NSDictionary dictionaryWithContentsOfFile:@"/System/Library/CoreServices/SystemVersion.plist"];
	if (NSObjectIsEmpty(systemVersionPlist)) exit(10);
	
	[systemVersionPlist retain];
	
	textualPlist = [[NSBundle mainBundle] infoDictionary];
	
	[self loadKeywords];
	[self loadExcludeWords];
	[self populateCommandIndex];
	
	if ([NSFont fontIsAvailable:[Preferences themeLogFontName]] == NO) {
		[_NSUserDefaults() setObject:@"Lucida Grande" forKey:@"Preferences.Theme.log_font_name"];
	}

	NSString *themeName = [ViewTheme extractThemeName:[Preferences themeName]];
	NSString *themePath = [[Preferences whereThemesPath] stringByAppendingPathComponent:themeName];
	
	if ([_NSFileManager() fileExistsAtPath:themePath] == NO) {
        themePath = [[Preferences whereThemesLocalPath] stringByAppendingPathComponent:themeName];
      
        if ([_NSFileManager() fileExistsAtPath:themePath] == NO) {
            [_NSUserDefaults() setObject:DEFAULT_TEXUAL_STYLE forKey:@"Preferences.Theme.name"];
        } else {
            NSString *newName = [NSString stringWithFormat:@"resource:%@", themeName];
            
            [_NSUserDefaults() setObject:newName forKey:@"Preferences.Theme.name"];
        }
	}
}

+ (void)sync
{
	[_NSUserDefaults() synchronize];
}

@end