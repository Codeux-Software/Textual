// Created by Satoshi Nakagawa <psychs AT limechat DOT net> <http://github.com/psychs/limechat>
// Modifications by Codeux Software <support AT codeux DOT com> <https://github.com/codeux/Textual>
// You can redistribute it and/or modify it under the new BSD license.

#import "ValidateReceipt.h"

@implementation Preferences

#pragma mark -
#pragma mark Version Dictonaries

static NSDictionary *textualPlist;
static NSDictionary *systemVersionPlist;
static NSMutableDictionary *commandIndex;

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

static BOOL receiptValidated = NO;

+ (void)validateStoreReceipt
{
	NSString *receipt = [[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:@"/Contents/_MASReceipt/receipt"];
	
	if (validateReceiptAtPath(receipt) == NO) {
		exit(173);
	} else {
		NSLog(@"Valid app store receipt located. Launching.");
		
		receiptValidated = YES;
	}
}

+ (BOOL)validStoreReceiptFound
{
	return receiptValidated;
}

#pragma mark -
#pragma mark Command Index

+ (NSDictionary *)commandIndexList
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

+ (NSString *)whereResourcePath 
{
	return [[NSBundle mainBundle] resourcePath];
}

#pragma mark -
#pragma mark Flood Control

+ (BOOL)floodControlIsEnabled
{
	return [TXNSUserDefaults() boolForKey:@"Preferences.FloodControl.enabled"];
}

+ (NSInteger)floodControlMaxMessages
{
	return [TXNSUserDefaults() integerForKey:@"Preferences.FloodControl.maxmsg"];
}

+ (NSInteger)floodControlDelayTimer
{
	return [TXNSUserDefaults() integerForKey:@"Preferences.FloodControl.timer"];
}

#pragma mark -
#pragma mark Default Identity

+ (NSString *)defaultNickname
{
	return [TXNSUserDefaults() objectForKey:@"Preferences.Identity.nickname"];
}

+ (NSString *)defaultUsername
{
	return [TXNSUserDefaults() objectForKey:@"Preferences.Identity.username"];
}

+ (NSString *)defaultRealname
{
	return [TXNSUserDefaults() objectForKey:@"Preferences.Identity.realname"];
}

#pragma mark - 
#pragma mark General Preferences

+ (NSInteger)autojoinMaxChannelJoins
{
	return [TXNSUserDefaults() integerForKey:@"Preferences.General.autojoin_maxchans"];
}

+ (NSInteger)connectAutoJoinDelay
{
	return [TXNSUserDefaults() integerForKey:@"Preferences.General.autojoin_delay"];
}

+ (NSString *)defaultKickMessage
{
	return [TXNSUserDefaults() objectForKey:@"Preferences.General.kick_message"];
}

+ (NSString *)IRCopDefaultKillMessage
{
	return [TXNSUserDefaults() objectForKey:@"Preferences.General.ircop_kill_message"];
}

+ (NSString *)IRCopDefaultGlineMessage
{
	return [TXNSUserDefaults() objectForKey:@"Preferences.General.ircop_gline_message"];
}

+ (NSString *)IRCopDefaultShunMessage
{
	return [TXNSUserDefaults() objectForKey:@"Preferences.General.ircop_shun_message"];
}

+ (NSString *)IRCopAlertMatch
{
	return [TXNSUserDefaults() objectForKey:@"Preferences.General.ircop_alert_match"];
}

+ (BOOL)logAllHighlightsToQuery
{
	return [TXNSUserDefaults() boolForKey:@"Preferences.General.log_highlights"];
}

+ (BOOL)clearAllOnlyOnActiveServer
{
	return [TXNSUserDefaults() boolForKey:@"Preferences.General.clear_only_active"];
}

+ (BOOL)displayServerMOTD
{
	return [TXNSUserDefaults() boolForKey:@"Preferences.General.display_servmotd"];
}

+ (BOOL)copyOnSelect
{
	return [TXNSUserDefaults() boolForKey:@"Preferences.General.copyonselect"];
}

+ (BOOL)autoAddScrollbackMark
{
	return [TXNSUserDefaults() boolForKey:@"Preferences.General.autoadd_scrollbackmark"];
}

+ (BOOL)removeAllFormatting
{
	return [TXNSUserDefaults() boolForKey:@"Preferences.General.strip_formatting"];
}

+ (BOOL)disableNicknameColors
{
	return [TXNSUserDefaults() boolForKey:@"Preferences.General.disable_nickname_colors"];
}

+ (BOOL)isUpgradedFromVersion100
{
	return [TXNSUserDefaults() boolForKey:@"SUHasLaunchedBefore"];
}

+ (BOOL)rightToLeftFormatting
{
	return [TXNSUserDefaults() boolForKey:@"Preferences.General.rtl_formatting"];
}

+ (NSString *)completionSuffix
{
	return [TXNSUserDefaults() objectForKey:@"Preferences.General.completion_suffix"];
}

+ (HostmaskBanFormat)banFormat
{
	return [TXNSUserDefaults() boolForKey:@"Preferences.General.banformat"];
}

+ (BOOL)displayDockBadge
{
	return [TXNSUserDefaults() boolForKey:@"Preferences.General.dockbadges"];
}

+ (BOOL)handleIRCopAlerts
{
	return [TXNSUserDefaults() boolForKey:@"Preferences.General.handle_operalerts"];
}

+ (BOOL)handleServerNotices
{
	return [TXNSUserDefaults() boolForKey:@"Preferences.General.handle_server_notices"];
}

+ (BOOL)amsgAllConnections
{
	return [TXNSUserDefaults() boolForKey:@"Preferences.General.amsg_allconnections"];
}

+ (BOOL)awayAllConnections
{
	return [TXNSUserDefaults() boolForKey:@"Preferences.General.away_allconnections"];
}

+ (BOOL)nickAllConnections
{
	return [TXNSUserDefaults() boolForKey:@"Preferences.General.nick_allconnections"];
}

+ (BOOL)indentOnHang
{
	return [TXNSUserDefaults() boolForKey:@"Preferences.Theme.indent_onwordwrap"];
}

+ (BOOL)confirmQuit
{
	return [TXNSUserDefaults() boolForKey:@"Preferences.General.confirm_quit"];
}

+ (BOOL)processChannelModes
{
	return [TXNSUserDefaults() boolForKey:@"Preferences.General.process_channel_modes"];
}

+ (BOOL)rejoinOnKick
{
	return [TXNSUserDefaults() boolForKey:@"Preferences.General.rejoin_onkick"];
}

+ (BOOL)autoJoinOnInvite
{
	return [TXNSUserDefaults() boolForKey:@"Preferences.General.autojoin_oninvite"];
}

+ (BOOL)connectOnDoubleclick
{
	return [TXNSUserDefaults() boolForKey:@"Preferences.General.connect_on_doubleclick"];
}

+ (BOOL)disconnectOnDoubleclick
{
	return [TXNSUserDefaults() boolForKey:@"Preferences.General.disconnect_on_doubleclick"];
}

+ (BOOL)joinOnDoubleclick
{
	return [TXNSUserDefaults() boolForKey:@"Preferences.General.join_on_doubleclick"];
}

+ (BOOL)leaveOnDoubleclick
{
	return [TXNSUserDefaults() boolForKey:@"Preferences.General.leave_on_doubleclick"];
}

+ (BOOL)logTranscript
{
	return [TXNSUserDefaults() boolForKey:@"Preferences.General.log_transcript"];
}

+ (BOOL)openBrowserInBackground
{
	return [TXNSUserDefaults() boolForKey:@"Preferences.General.open_browser_in_background"];
}

+ (BOOL)showInlineImages
{
	return [TXNSUserDefaults() boolForKey:@"Preferences.General.show_inline_images"];
}

+ (BOOL)showJoinLeave
{
	return [TXNSUserDefaults() boolForKey:@"Preferences.General.show_join_leave"];
}

+ (BOOL)stopGrowlOnActive
{
	return [TXNSUserDefaults() boolForKey:@"Preferences.General.stop_growl_on_active"];
}

+ (BOOL)countPublicMessagesInIconBadge
{
	return [TXNSUserDefaults() boolForKey:@"Preferences.General.dockbadge_countpub"];
}

+ (TabActionType)tabAction
{
	return [TXNSUserDefaults() integerForKey:@"Preferences.General.tab_action"];
}

+ (BOOL)keywordCurrentNick
{
	return [TXNSUserDefaults() boolForKey:@"Preferences.Keyword.current_nick"];
}

+ (NSArray *)keywordDislikeWords
{
	return [TXNSUserDefaults() objectForKey:@"Preferences.Keyword.dislike_words"];
}

+ (KeywordMatchType)keywordMatchingMethod
{
	return [TXNSUserDefaults() integerForKey:@"Preferences.Keyword.matching_method"];
}

+ (NSArray *)keywordWords
{
	return [TXNSUserDefaults() objectForKey:@"Preferences.Keyword.words"];
}

+ (UserDoubleClickAction)userDoubleClickOption
{
	return [TXNSUserDefaults() integerForKey:@"Preferences.General.user_doubleclick_action"];
}

+ (NoticesSendToLocation)locationToSendNotices
{
	return [TXNSUserDefaults() integerForKey:@"Preferences.General.notices_sendto_location"];
}

+ (CmdW_Shortcut_ResponseType)cmdWResponseType
{
	return [TXNSUserDefaults() integerForKey:@"Preferences.General.keyboard_cmdw_response"];
}

#pragma mark -
#pragma mark Theme

+ (NSString *)themeName
{
	return [TXNSUserDefaults() objectForKey:@"Preferences.Theme.name"];
}

+ (void)setThemeName:(NSString *)value
{
	[TXNSUserDefaults() setObject:value forKey:@"Preferences.Theme.name"];
}

+ (NSString *)themeLogFontName
{
	return [TXNSUserDefaults() objectForKey:@"Preferences.Theme.log_font_name"];
}

+ (void)setThemeLogFontName:(NSString *)value
{
	[TXNSUserDefaults() setObject:value forKey:@"Preferences.Theme.log_font_name"];
}

+ (double)themeLogFontSize
{
	return [TXNSUserDefaults() doubleForKey:@"Preferences.Theme.log_font_size"];
}

+ (void)setThemeLogFontSize:(double)value
{
	[TXNSUserDefaults() setDouble:value forKey:@"Preferences.Theme.log_font_size"];
}

+ (NSString *)themeNickFormat
{
	return [TXNSUserDefaults() objectForKey:@"Preferences.Theme.nick_format"];
}

+ (BOOL)inputHistoryIsChannelSpecific
{
	return [TXNSUserDefaults() boolForKey:@"Preferences.Theme.inputhistory_per_channel"];
}

+ (NSString *)themeTimestampFormat
{
	return [TXNSUserDefaults() objectForKey:@"Preferences.Theme.timestamp_format"];
}

+ (double)themeTransparency
{
	return [TXNSUserDefaults() doubleForKey:@"Preferences.Theme.transparency"];
}

#pragma mark -
#pragma mark Completion Suffix

+ (void)setCompletionSuffix:(NSString *)value
{
	[TXNSUserDefaults() setObject:value forKey:@"Preferences.General.completion_suffix"];
}

#pragma mark -
#pragma mark Inline Image Size

+ (NSInteger)inlineImagesMaxWidth
{
	return [TXNSUserDefaults() integerForKey:@"Preferences.General.inline_image_width"];
}

+ (void)setInlineImagesMaxWidth:(NSInteger)value
{
	[TXNSUserDefaults() setInteger:value forKey:@"Preferences.General.inline_image_width"];
}

#pragma mark -
#pragma mark Max Log Lines

+ (NSInteger)maxLogLines
{
	return [TXNSUserDefaults() integerForKey:@"Preferences.General.max_log_lines"];
}

+ (void)setMaxLogLines:(NSInteger)value
{
	[TXNSUserDefaults() setInteger:value forKey:@"Preferences.General.max_log_lines"];
}

#pragma mark -
#pragma mark Transcript Folder

+ (NSString *)transcriptFolder
{
	return [TXNSUserDefaults() objectForKey:@"Preferences.General.transcript_folder"];
}

+ (void)setTranscriptFolder:(NSString *)value
{
	[TXNSUserDefaults() setObject:value forKey:@"Preferences.General.transcript_folder"];
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
	return [TXNSUserDefaults() objectForKey:key];
}

+ (void)setSound:(NSString *)value forEvent:(GrowlNotificationType)event
{
	NSString *key = [[self keyForEvent:event] stringByAppendingString:@"Sound"];
	[TXNSUserDefaults() setObject:value forKey:key];
}

+ (BOOL)growlEnabledForEvent:(GrowlNotificationType)event
{
	NSString *key = [[self keyForEvent:event] stringByAppendingString:@"Growl"];
	return [TXNSUserDefaults() boolForKey:key];
}

+ (void)setGrowlEnabled:(BOOL)value forEvent:(GrowlNotificationType)event
{
	NSString *key = [[self keyForEvent:event] stringByAppendingString:@"Growl"];
	[TXNSUserDefaults() setBool:value forKey:key];
}

+ (BOOL)growlStickyForEvent:(GrowlNotificationType)event
{
	NSString *key = [[self keyForEvent:event] stringByAppendingString:@"GrowlSticky"];
	return [TXNSUserDefaults() boolForKey:key];
}

+ (void)setGrowlSticky:(BOOL)value forEvent:(GrowlNotificationType)event
{
	NSString *key = [[self keyForEvent:event] stringByAppendingString:@"GrowlSticky"];
	[TXNSUserDefaults() setBool:value forKey:key];
}

+ (BOOL)disableWhileAwayForEvent:(GrowlNotificationType)event
{
	NSString *key = [[self keyForEvent:event] stringByAppendingString:@"DisableWhileAway"];
	return [TXNSUserDefaults() boolForKey:key];
}

+ (void)setDisableWhileAway:(BOOL)value forEvent:(GrowlNotificationType)event
{
	NSString *key = [[self keyForEvent:event] stringByAppendingString:@"DisableWhileAway"];
	[TXNSUserDefaults() setBool:value forKey:key];
}

#pragma mark -
#pragma mark World

+ (BOOL)spellCheckEnabled
{
	if (![TXNSUserDefaults() objectForKey:@"spellCheck2"]) return YES;
	return [TXNSUserDefaults() boolForKey:@"spellCheck2"];
}

+ (void)setSpellCheckEnabled:(BOOL)value
{
	[TXNSUserDefaults() setBool:value forKey:@"spellCheck2"];
}

+ (BOOL)grammarCheckEnabled
{
	return [TXNSUserDefaults() boolForKey:@"grammarCheck"];
}

+ (void)setGrammarCheckEnabled:(BOOL)value
{
	[TXNSUserDefaults() setBool:value forKey:@"grammarCheck"];
}

+ (BOOL)spellingCorrectionEnabled
{
	return [TXNSUserDefaults() boolForKey:@"spellingCorrection"];
}

+ (void)setSpellingCorrectionEnabled:(BOOL)value
{
	[TXNSUserDefaults() setBool:value forKey:@"spellingCorrection"];
}

+ (BOOL)smartInsertDeleteEnabled
{
	if (![TXNSUserDefaults() objectForKey:@"smartInsertDelete"]) return YES;
	return [TXNSUserDefaults() boolForKey:@"smartInsertDelete"];
}

+ (void)setSmartInsertDeleteEnabled:(BOOL)value
{
	[TXNSUserDefaults() setBool:value forKey:@"smartInsertDelete"];
}

+ (BOOL)quoteSubstitutionEnabled
{
	return [TXNSUserDefaults() boolForKey:@"quoteSubstitution"];
}

+ (void)setQuoteSubstitutionEnabled:(BOOL)value
{
	[TXNSUserDefaults() setBool:value forKey:@"quoteSubstitution"];
}

+ (BOOL)dashSubstitutionEnabled
{
	return [TXNSUserDefaults() boolForKey:@"dashSubstitution"];
}

+ (void)setDashSubstitutionEnabled:(BOOL)value
{
	[TXNSUserDefaults() setBool:value forKey:@"dashSubstitution"];
}

+ (BOOL)linkDetectionEnabled
{
	return [TXNSUserDefaults() boolForKey:@"linkDetection"];
}

+ (void)setLinkDetectionEnabled:(BOOL)value
{
	[TXNSUserDefaults() setBool:value forKey:@"linkDetection"];
}

+ (BOOL)dataDetectionEnabled
{
	return [TXNSUserDefaults() boolForKey:@"dataDetection"];
}

+ (void)setDataDetectionEnabled:(BOOL)value
{
	[TXNSUserDefaults() setBool:value forKey:@"dataDetection"];
}

+ (BOOL)textReplacementEnabled
{
	return [TXNSUserDefaults() boolForKey:@"textReplacement"];
}

+ (void)setTextReplacementEnabled:(BOOL)value
{
	[TXNSUserDefaults() setBool:value forKey:@"textReplacement"];
}

#pragma mark -
#pragma mark Growl

+ (BOOL)registeredToGrowl
{
	return [TXNSUserDefaults() boolForKey:@"registeredToGrowl"];
}

+ (void)setRegisteredToGrowl:(BOOL)value
{
	[TXNSUserDefaults() setBool:value forKey:@"registeredToGrowl"];
}

#pragma mark -
#pragma mark World

+ (NSDictionary *)loadWorld
{
	return [TXNSUserDefaults() objectForKey:@"world"];
}

+ (void)saveWorld:(NSDictionary *)value
{
	[TXNSUserDefaults() setObject:value forKey:@"world"];
}

#pragma mark -
#pragma mark Window

+ (NSDictionary *)loadWindowStateWithName:(NSString *)name
{
	return [TXNSUserDefaults() objectForKey:name];
}

+ (void)saveWindowState:(NSDictionary *)value name:(NSString *)name
{
	[TXNSUserDefaults() setObject:value forKey:name];
}

#pragma mark -
#pragma mark Keywords

static NSMutableArray *keywords;
static NSMutableArray *excludeWords;

+ (void)loadKeywords
{
	if (keywords) {
		[keywords removeAllObjects];
	} else {
		keywords = [NSMutableArray new];
	}
	
	NSArray *ary = [TXNSUserDefaults() objectForKey:@"keywords"];
	
	for (NSDictionary *e in ary) {
		NSString *s = [e objectForKey:@"string"];
		
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
	
	NSArray *ary = [TXNSUserDefaults() objectForKey:@"excludeWords"];
	
	for (NSDictionary *e in ary) {
		NSString *s = [e objectForKey:@"string"];
		
		if (s) [excludeWords addObject:s];
	}
}

+ (void)cleanUpWords:(NSString *)key
{
	NSArray *src = [TXNSUserDefaults() objectForKey:key];
	
	NSMutableArray *ary = [NSMutableArray array];
	
	for (NSDictionary *e in src) {
		NSString *s = [e objectForKey:@"string"];
		
		if (s.length) {
			[ary addObject:s];
		}
	}
	
	[ary sortUsingSelector:@selector(caseInsensitiveCompare:)];
	
	NSMutableArray *saveAry = [NSMutableArray array];
	
	for (NSString *s in ary) {
		NSMutableDictionary *dic = [NSMutableDictionary dictionary];
		
		[dic setObject:s forKey:@"string"];
		[saveAry addObject:dic];
	}
	
	[TXNSUserDefaults() setObject:saveAry forKey:key];
	[TXNSUserDefaults() synchronize];
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
#pragma mark KVO

static NSInteger startUpTime;

+ (NSInteger)startTime
{
	return startUpTime;
}

+ (void)observeValueForKeyPath:(NSString *)key
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
	[TXNSUserDefaults() setBool:[[alert suppressionButton] state] forKey:@"Preferences.prompts.default_irc_client"];
	
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
				
		if ([[defaultClientBundle bundleIdentifier] isNotEqualTo:[mainBundle bundleIdentifier]]) {	
			BOOL suppCheck = [TXNSUserDefaults() boolForKey:@"Preferences.prompts.default_irc_client"];
			
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
	
	if (ircAppURL) CFRelease(ircAppURL);
	
	[pool release];
}

+ (void)initPreferences
{
	NSInteger numberOfRuns = [TXNSUserDefaults() integerForKey:@"TXRunCount"];
	[TXNSUserDefaults() setInteger:(numberOfRuns + 1) forKey:@"TXRunCount"];
	
	if (numberOfRuns > 0) {
		[[self invokeInBackgroundThread] defaultIRCClientPrompt];
	} 
	
	// ====================================================== //
	
	startUpTime = (long)[[NSDate date] timeIntervalSince1970];
	
	NSString *nick = NSUserName();
	
	nick = [nick stringByReplacingOccurrencesOfString:@" " withString:@"_"];
	nick = [nick stringByReplacingOccurrencesOfRegex:@"[^a-zA-Z0-9-_]" withString:@""];

	if (nick == nil) {
		nick = @"User";
	}
	
	// ====================================================== //
	
	NSMutableDictionary *d = [NSMutableDictionary dictionary];
	
	[d setBool:YES forKey:@"WebKitDeveloperExtras"];
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
	[d setBool:YES forKey:@"Preferences.Theme.indent_onwordwrap"];
	[d setObject:@"[%m/%d/%Y -:- %I:%M:%S %p]" forKey:@"Preferences.Theme.timestamp_format"];
	[d setDouble:1 forKey:@"Preferences.Theme.transparency"];
	[d setBool:NO forKey:@"Preferences.General.log_highlights"];
	[d setInt:1 forKey:@"Preferences.General.autojoin_delay"];
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
	
	[TXNSUserDefaults() registerDefaults:d];
	
	[TXNSUserDefaults() addObserver:(NSObject *)self forKeyPath:@"keywords" options:NSKeyValueObservingOptionNew context:NULL];
	[TXNSUserDefaults() addObserver:(NSObject *)self forKeyPath:@"excludeWords" options:NSKeyValueObservingOptionNew context:NULL];
	
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
	[TXNSUserDefaults() synchronize];
}

@end