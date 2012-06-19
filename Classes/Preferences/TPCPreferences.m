// Created by Satoshi Nakagawa <psychs AT limechat DOT net> <http://github.com/psychs/limechat>
// Modifications by Codeux Software <support AT codeux DOT com> <https://github.com/codeux/Textual>
// You can redistribute it and/or modify it under the new BSD license.
// Converted to ARC Support on June 08, 2012

@implementation TPCPreferences

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
#pragma mark Command Index

static NSMutableDictionary *commandIndex = nil;

+ (NSDictionary *)commandIndexList
{
	return commandIndex;
}

+ (void)populateCommandIndex
{
	/* This needs to be redesigned… */
	commandIndex = [NSMutableDictionary new];
	
	[commandIndex setObject:@"3"   forKey:IRCCommandIndexAway];
	[commandIndex setObject:@"4"   forKey:IRCCommandIndexError];
	[commandIndex setObject:@"5"   forKey:IRCCommandIndexInvite];
	[commandIndex setObject:@"6"   forKey:IRCCommandIndexIson];
	[commandIndex setObject:@"7"   forKey:IRCCommandIndexJoin];
	[commandIndex setObject:@"8"   forKey:IRCCommandIndexKick];
	[commandIndex setObject:@"9"   forKey:IRCCommandIndexKill];
	[commandIndex setObject:@"10"  forKey:IRCCommandIndexList];
	[commandIndex setObject:@"11"  forKey:IRCCommandIndexMode];
	[commandIndex setObject:@"12"  forKey:IRCCommandIndexNames];
	[commandIndex setObject:@"13"  forKey:IRCCommandIndexNick];
	[commandIndex setObject:@"14"  forKey:IRCCommandIndexNotice];
	[commandIndex setObject:@"15"  forKey:IRCCommandIndexPart];
	[commandIndex setObject:@"16"  forKey:IRCCommandIndexPass];
	[commandIndex setObject:@"17"  forKey:IRCCommandIndexPing];
	[commandIndex setObject:@"18"  forKey:IRCCommandIndexPong];
	[commandIndex setObject:@"19"  forKey:IRCCommandIndexPrivmsg];
	[commandIndex setObject:@"20"  forKey:IRCCommandIndexQuit];
	[commandIndex setObject:@"21"  forKey:IRCCommandIndexTopic];
	[commandIndex setObject:@"22"  forKey:IRCCommandIndexUser];
	[commandIndex setObject:@"23"  forKey:IRCCommandIndexWho];
	[commandIndex setObject:@"24"  forKey:IRCCommandIndexWhois];
	[commandIndex setObject:@"25"  forKey:IRCCommandIndexWhowas];
	[commandIndex setObject:@"27"  forKey:IRCCommandIndexAction];
	[commandIndex setObject:@"28"  forKey:IRCCommandIndexDcc];
	[commandIndex setObject:@"29"  forKey:IRCCommandIndexSend];
	[commandIndex setObject:@"31"  forKey:IRCCommandIndexClientinfo];
	[commandIndex setObject:@"32"  forKey:IRCCommandIndexCtcp];
	[commandIndex setObject:@"33"  forKey:IRCCommandIndexCtcpreply];
	[commandIndex setObject:@"34"  forKey:IRCCommandIndexTime];
	[commandIndex setObject:@"35"  forKey:IRCCommandIndexUserinfo];
	[commandIndex setObject:@"36"  forKey:IRCCommandIndexVersion];
	[commandIndex setObject:@"38"  forKey:IRCCommandIndexOmsg];
	[commandIndex setObject:@"39"  forKey:IRCCommandIndexOnotice];
	[commandIndex setObject:@"41"  forKey:IRCCommandIndexBan];
	[commandIndex setObject:@"42"  forKey:IRCCommandIndexClear];
	[commandIndex setObject:@"43"  forKey:IRCCommandIndexClose];
	[commandIndex setObject:@"44"  forKey:IRCCommandIndexCycle];
	[commandIndex setObject:@"45"  forKey:IRCCommandIndexDehalfop];
	[commandIndex setObject:@"46"  forKey:IRCCommandIndexDeop];
	[commandIndex setObject:@"47"  forKey:IRCCommandIndexDevoice];
	[commandIndex setObject:@"48"  forKey:IRCCommandIndexHalfop];
	[commandIndex setObject:@"49"  forKey:IRCCommandIndexHop];
	[commandIndex setObject:@"50"  forKey:IRCCommandIndexIgnore];
	[commandIndex setObject:@"51"  forKey:IRCCommandIndexJ];
	[commandIndex setObject:@"52"  forKey:IRCCommandIndexLeave];
	[commandIndex setObject:@"53"  forKey:IRCCommandIndexM];
	[commandIndex setObject:@"54"  forKey:IRCCommandIndexMe];
	[commandIndex setObject:@"55"  forKey:IRCCommandIndexMsg];
	[commandIndex setObject:@"56"  forKey:IRCCommandIndexOp];
	[commandIndex setObject:@"57"  forKey:IRCCommandIndexRaw];
	[commandIndex setObject:@"58"  forKey:IRCCommandIndexRejoin];
	[commandIndex setObject:@"59"  forKey:IRCCommandIndexQuery];
	[commandIndex setObject:@"60"  forKey:IRCCommandIndexQuote];
	[commandIndex setObject:@"61"  forKey:IRCCommandIndexT];
	[commandIndex setObject:@"62"  forKey:IRCCommandIndexTimer];
	[commandIndex setObject:@"63"  forKey:IRCCommandIndexVoice];
	[commandIndex setObject:@"64"  forKey:IRCCommandIndexUnban];
	[commandIndex setObject:@"65"  forKey:IRCCommandIndexUnignore];
	[commandIndex setObject:@"66"  forKey:IRCCommandIndexUmode];
	//[commandIndex setObject:@"67"  forKey:IRCCommandIndexVersion]; — Deprecated index. Duplicate.
	[commandIndex setObject:@"68"  forKey:IRCCommandIndexWeights];
	[commandIndex setObject:@"69"  forKey:IRCCommandIndexEcho];
	[commandIndex setObject:@"70"  forKey:IRCCommandIndexDebug];
	[commandIndex setObject:@"71"  forKey:IRCCommandIndexClearall];
	[commandIndex setObject:@"72"  forKey:IRCCommandIndexAmsg];
	[commandIndex setObject:@"73"  forKey:IRCCommandIndexAme];
	[commandIndex setObject:@"74"  forKey:IRCCommandIndexMute]; 
	[commandIndex setObject:@"75"  forKey:IRCCommandIndexUnmute]; 
	[commandIndex setObject:@"76"  forKey:IRCCommandIndexUnloadPlugins]; 
	[commandIndex setObject:@"77"  forKey:IRCCommandIndexRemove];  
	[commandIndex setObject:@"79"  forKey:IRCCommandIndexKickban]; 
	[commandIndex setObject:@"80"  forKey:IRCCommandIndexWallops]; 
	[commandIndex setObject:@"81"  forKey:IRCCommandIndexIcbadge];
	[commandIndex setObject:@"82"  forKey:IRCCommandIndexServer];
	[commandIndex setObject:@"83"  forKey:IRCCommandIndexConn]; 
	[commandIndex setObject:@"84"  forKey:IRCCommandIndexMyversion]; 
	[commandIndex setObject:@"85"  forKey:IRCCommandIndexChatops]; 
	[commandIndex setObject:@"86"  forKey:IRCCommandIndexGlobops]; 
	[commandIndex setObject:@"87"  forKey:IRCCommandIndexLocops]; 
	[commandIndex setObject:@"88"  forKey:IRCCommandIndexNachat]; 
	[commandIndex setObject:@"89"  forKey:IRCCommandIndexAdchat]; 
	[commandIndex setObject:@"91"  forKey:IRCCommandIndexLoadPlugins];
	[commandIndex setObject:@"92"  forKey:IRCCommandIndexSme];
	[commandIndex setObject:@"93"  forKey:IRCCommandIndexSmsg];
	[commandIndex setObject:@"94"  forKey:IRCCommandIndexLagcheck];
	[commandIndex setObject:@"95"  forKey:IRCCommandIndexMylag];
	[commandIndex setObject:@"96"  forKey:IRCCommandIndexZline];
	[commandIndex setObject:@"97"  forKey:IRCCommandIndexGline];
	[commandIndex setObject:@"98"  forKey:IRCCommandIndexGzline];
	[commandIndex setObject:@"99"  forKey:IRCCommandIndexShun];
	[commandIndex setObject:@"100" forKey:IRCCommandIndexTempshun];
	[commandIndex setObject:@"101" forKey:IRCCommandIndexAuthenticate];
	[commandIndex setObject:@"102" forKey:IRCCommandIndexCap];
	[commandIndex setObject:@"103" forKey:IRCCommandIndexCaps];
	[commandIndex setObject:@"104" forKey:IRCCommandIndexCcbadge];
}

+ (NSInteger)commandUIndex:(NSString *)command 
{
	return [commandIndex integerForKey:[command uppercaseString]];
}

#pragma mark -
#pragma mark Application Information

+ (BOOL)featureAvailableToOSXLion
{
	return (floor(NSAppKitVersionNumber) > NSAppKitVersionNumber10_6);
}

+ (BOOL)featureAvailableToOSXMountainLion
{
	return (floor(NSAppKitVersionNumber) > NSAppKitVersionNumber10_7);
}

+ (NSData *)applicationIcon
{
	return [[NSApp applicationIconImage] TIFFRepresentation];
}

+ (NSString *)applicationName
{
	return [textualPlist objectForKey:@"CFBundleName"];
}

+ (NSInteger)applicationProcessID
{
	return [[NSProcessInfo processInfo] processIdentifier];
}

+ (NSString *)gitBuildReference
{
	return [textualPlist objectForKey:@"TXBundleBuildReference"];
}

+ (NSString *)applicationBundleIdentifier
{
	return [[NSBundle mainBundle] bundleIdentifier];
}

#pragma mark -
#pragma mark Path Index

+ (NSString *)_whereApplicationSupportPath
{
	return [_NSFileManager() URLForDirectory:NSApplicationSupportDirectory
									inDomain:NSUserDomainMask
						   appropriateForURL:nil
									  create:YES
									   error:NULL].relativePath;
}

+ (NSString *)whereApplicationSupportPath
{
	NSString *dest = [[self _whereApplicationSupportPath] stringByAppendingPathComponent:@"/Textual IRC/"];
	
	if ([_NSFileManager() fileExistsAtPath:dest] == NO) {
		[_NSFileManager() createDirectoryAtPath:dest withIntermediateDirectories:YES attributes:nil error:NULL];
	}
	
	return dest;
}

+ (NSString *)whereScriptsPath
{
	NSString *dest = [[self _whereApplicationSupportPath] stringByAppendingPathComponent:@"/Textual IRC/Scripts/"];
	
	if ([_NSFileManager() fileExistsAtPath:dest] == NO) {
		[_NSFileManager() createDirectoryAtPath:dest withIntermediateDirectories:YES attributes:nil error:NULL];
	}
	
	return dest;
}

+ (NSString *)whereThemesPath
{
	NSString *dest = [[self _whereApplicationSupportPath] stringByAppendingPathComponent:@"/Textual IRC/Styles/"];
	
	if ([_NSFileManager() fileExistsAtPath:dest] == NO) {
		[_NSFileManager() createDirectoryAtPath:dest withIntermediateDirectories:YES attributes:nil error:NULL];
	}
	
	return dest;
}

+ (NSString *)wherePluginsPath
{
	NSString *dest = [[self _whereApplicationSupportPath] stringByAppendingPathComponent:@"/Textual IRC/Extensions/"];
	
	if ([_NSFileManager() fileExistsAtPath:dest] == NO) {
		[_NSFileManager() createDirectoryAtPath:dest withIntermediateDirectories:YES attributes:nil error:NULL];
	}
	
	return dest;
}

+ (NSString *)whereScriptsLocalPath
{
	return [[self whereResourcePath] stringByAppendingPathComponent:@"Scripts"];
}

#ifdef TXUserScriptsFolderAvailable
+ (NSString *)whereScriptsUnsupervisedPath
{
	if ([TPCPreferences featureAvailableToOSXMountainLion]) {
		return [_NSFileManager() URLForDirectory:NSApplicationScriptsDirectory
										inDomain:NSUserDomainMask
							   appropriateForURL:nil
										  create:YES
										   error:NULL].relativePath;
	}
	
	return nil;
}
#endif

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
#pragma mark Logging

+ (NSString *)transcriptFolder
{
	if ([self sandboxEnabled]) {
		NSString *dest = [NSHomeDirectory() stringByAppendingPathComponent:@"Logs"];
		
		if ([_NSFileManager() fileExistsAtPath:dest] == NO) {
			[_NSFileManager() createDirectoryAtPath:dest withIntermediateDirectories:YES attributes:nil error:NULL];
		}
		
		return dest;
	} else {
		NSString *base;
		
		base = [_NSUserDefaults() objectForKey:@"Preferences.General.transcript_folder"];
		base = [base stringByExpandingTildeInPath];
		
		return base;
	}
}

+ (void)setTranscriptFolder:(NSString *)value
{
	[_NSUserDefaults() setObject:value forKey:@"Preferences.General.transcript_folder"];
}

#pragma mark -
#pragma mark Sandbox Check

+ (BOOL)sandboxEnabled
{
	NSString *suffix = [NSString stringWithFormat:@"Containers/%@/Data", [TPCPreferences applicationBundleIdentifier]];
	
	return [NSHomeDirectory() hasSuffix:suffix];
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

+ (NSString *)masqueradeCTCPVersion
{
	return [_NSUserDefaults() objectForKey:@"Preferences.General.masquerade_ctcp_version"];
}

+ (BOOL)invertSidebarColors
{
	return NO;
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

+ (BOOL)replyToCTCPRequests
{
	return [_NSUserDefaults() boolForKey:@"Preferences.General.reply_ctcp_requests"];
}

+ (BOOL)autoAddScrollbackMark
{
	return [_NSUserDefaults() boolForKey:@"Preferences.General.autoadd_scrollbackmark"];
}

+ (BOOL)removeAllFormatting
{
	return [_NSUserDefaults() boolForKey:@"Preferences.General.strip_formatting"];
}

+ (BOOL)useLogAntialiasing
{
	return [_NSUserDefaults() boolForKey:@"Preferences.General.log_antialiasing"];
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

+ (TXHostmaskBanFormat)banFormat
{
	return (TXHostmaskBanFormat)[_NSUserDefaults() integerForKey:@"Preferences.General.banformat"];
}

+ (TXNSDouble)viewLoopConsoleDelay
{
	return [_NSUserDefaults() doubleForKey:@"Preferences.Experimental.view_loop_console_delay"];
}

+ (TXNSDouble)viewLoopChannelDelay
{
	return [_NSUserDefaults() doubleForKey:@"Preferences.Experimental.view_loop_channel_delay"];
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

+ (BOOL)giveFocusOnMessage
{
	return [_NSUserDefaults() boolForKey:@"Preferences.General.focus_on_message"];
}

+ (BOOL)nickAllConnections
{
	return [_NSUserDefaults() boolForKey:@"Preferences.General.nick_allconnections"];
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

+ (TXTabKeyActionType)tabAction
{
	return (TXTabKeyActionType)[_NSUserDefaults() integerForKey:@"Preferences.General.tab_action"];
}

+ (BOOL)keywordCurrentNick
{
	return [_NSUserDefaults() boolForKey:@"Preferences.Keyword.current_nick"];
}

+ (NSArray *)keywordDislikeWords
{
	return [_NSUserDefaults() objectForKey:@"Preferences.Keyword.dislike_words"];
}

+ (TXNicknameHighlightMatchType)keywordMatchingMethod
{
	return (TXNicknameHighlightMatchType)[_NSUserDefaults() integerForKey:@"Preferences.Keyword.matching_method"];
}

+ (NSArray *)keywordWords
{
	return [_NSUserDefaults() objectForKey:@"Preferences.Keyword.words"];
}

+ (TXUserDoubleClickAction)userDoubleClickOption
{
	return (TXUserDoubleClickAction)[_NSUserDefaults() integerForKey:@"Preferences.General.user_doubleclick_action"];
}

+ (TXNoticeSendLocationType)locationToSendNotices
{
	return (TXNoticeSendLocationType)[_NSUserDefaults() integerForKey:@"Preferences.General.notices_sendto_location"];
}

+ (TXCmdWShortcutResponseType)cmdWResponseType
{
	return (TXCmdWShortcutResponseType)[_NSUserDefaults() integerForKey:@"Preferences.General.keyboard_cmdw_response"];
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

+ (NSString *)themeChannelViewFontName
{
	return [_NSUserDefaults() objectForKey:@"Preferences.Theme.log_font_name"];
}

+ (void)setThemeChannelViewFontName:(NSString *)value
{
	[_NSUserDefaults() setObject:value forKey:@"Preferences.Theme.log_font_name"];
}

+ (TXNSDouble)themeChannelViewFontSize
{
	return [_NSUserDefaults() doubleForKey:@"Preferences.Theme.log_font_size"];
}

+ (void)setThemeChannelViewFontSize:(TXNSDouble)value
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

+ (TXNSDouble)themeTransparency
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
#pragma mark Events

+ (NSString *)titleForEvent:(TXNotificationType)event
{
	switch (event) {
		case TXNotificationHighlightType:			return TXTLS(@"TXNotificationHighlightType");
		case TXNotificationNewQueryType:		    return TXTLS(@"TXNotificationNewQueryType");
		case TXNotificationChannelMessageType:		return TXTLS(@"TXNotificationChannelMessageType");
		case TXNotificationChannelNoticeType:		return TXTLS(@"TXNotificationChannelNoticeType");
		case TXNotificationQueryMessageType:		return TXTLS(@"TXNotificationQueryMessageType");
		case TXNotificationQueryNoticeType:			return TXTLS(@"TXNotificationQueryNoticeType");
		case TXNotificationKickType:				return TXTLS(@"TXNotificationKickType");
		case TXNotificationInviteType:				return TXTLS(@"TXNotificationInviteType");
		case TXNotificationConnectType:				return TXTLS(@"TXNotificationConnectType");
		case TXNotificationDisconnectType:			return TXTLS(@"TXNotificationDisconnectType");
		case TXNotificationAddressBookMatchType:	return TXTLS(@"TXNotificationAddressBookMatchType");
		default: return nil;
	}
	
	return nil;
}

+ (NSString *)keyForEvent:(TXNotificationType)event
{
	switch (event) {
		case TXNotificationHighlightType:			return @"eventHighlight";
		case TXNotificationNewQueryType:			return @"eventNewtalk";
		case TXNotificationChannelMessageType:		return @"eventChannelText";
		case TXNotificationChannelNoticeType:		return @"eventChannelNotice";
		case TXNotificationQueryMessageType:		return @"eventTalkText";
		case TXNotificationQueryNoticeType:			return @"eventTalkNotice";
		case TXNotificationKickType:				return @"eventKicked";
		case TXNotificationInviteType:				return @"eventInvited";
		case TXNotificationConnectType:				return @"eventLogin";
		case TXNotificationDisconnectType:			return @"eventDisconnect";
		case TXNotificationAddressBookMatchType:	return @"eventAddressBookMatch";
		default: return nil;
	}
	
	return nil;
}

+ (NSString *)soundForEvent:(TXNotificationType)event
{
	NSString *okey = [self keyForEvent:event];
	
	if (NSObjectIsEmpty(okey)) {
		return nil;
	}
	
	NSString *key = [okey stringByAppendingString:@"Sound"];
	
	return [_NSUserDefaults() objectForKey:key];
}

+ (void)setSound:(NSString *)value forEvent:(TXNotificationType)event
{
	NSString *okey = [self keyForEvent:event];
	
	if (NSObjectIsEmpty(okey)) {
		return;
	}
	
	NSString *key = [okey stringByAppendingString:@"Sound"];
	
	[_NSUserDefaults() setObject:value forKey:key];
}

+ (BOOL)growlEnabledForEvent:(TXNotificationType)event
{
	NSString *okey = [self keyForEvent:event];
	
	if (NSObjectIsEmpty(okey)) {
		return NO;
	}
	
	NSString *key = [okey stringByAppendingString:@"Growl"];
	
	return [_NSUserDefaults() boolForKey:key];
}

+ (void)setGrowlEnabled:(BOOL)value forEvent:(TXNotificationType)event
{
	NSString *okey = [self keyForEvent:event];
	
	if (NSObjectIsEmpty(okey)) {
		return;
	}
	
	NSString *key = [okey stringByAppendingString:@"Growl"];
	
	[_NSUserDefaults() setBool:value forKey:key];
}

+ (BOOL)growlStickyForEvent:(TXNotificationType)event
{
	NSString *okey = [self keyForEvent:event];
	
	if (NSObjectIsEmpty(okey)) {
		return NO;
	}
	
	NSString *key = [okey stringByAppendingString:@"GrowlSticky"];
	
	return [_NSUserDefaults() boolForKey:key];
}

+ (void)setGrowlSticky:(BOOL)value forEvent:(TXNotificationType)event
{
	NSString *okey = [self keyForEvent:event];
	
	if (NSObjectIsEmpty(okey)) {
		return;
	}
	
	NSString *key = [okey stringByAppendingString:@"GrowlSticky"];
	
	[_NSUserDefaults() setBool:value forKey:key];
}

+ (BOOL)disableWhileAwayForEvent:(TXNotificationType)event
{
	NSString *okey = [self keyForEvent:event];
	
	if (NSObjectIsEmpty(okey)) {
		return NO;
	}
	
	NSString *key = [okey stringByAppendingString:@"DisableWhileAway"];
	
	return [_NSUserDefaults() boolForKey:key];
}

+ (void)setDisableWhileAway:(BOOL)value forEvent:(TXNotificationType)event
{
	NSString *okey = [self keyForEvent:event];
	
	if (NSObjectIsEmpty(okey)) {
		return;
	}
	
	NSString *key = [okey stringByAppendingString:@"DisableWhileAway"];
	
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

+ (void)defaultIRCClientSheetCallback:(NSNumber *)returnCode 
{	
    NSInteger _returnCode = [returnCode integerValue];
    
	if (_returnCode == NSAlertFirstButtonReturn) {
		NSString *bundleID    = [[NSBundle mainBundle] bundleIdentifier];
		OSStatus changeResult = LSSetDefaultHandlerForURLScheme((__bridge CFStringRef)@"irc", (__bridge CFStringRef)(bundleID));
		
		if (changeResult == noErr) return;
	}
}

+ (void)defaultIRCClientPrompt
{
	[NSThread sleepForTimeInterval:1.5];
	
	NSURL *baseURL = [[NSURL alloc] initWithString:@"irc:"];
	
    CFURLRef ircAppURL = NULL;
    OSStatus status    = LSGetApplicationForURL((__bridge CFURLRef)baseURL, kLSRolesAll, NULL, &ircAppURL);
	
	if (status == noErr) {
		NSBundle *mainBundle		  = [NSBundle mainBundle];
		NSBundle *defaultClientBundle = [NSBundle bundleWithURL:CFBridgingRelease(ircAppURL)];
		
		if ([[defaultClientBundle bundleIdentifier] isNotEqualTo:[mainBundle bundleIdentifier]]) {
			TLOPopupPrompts *prompt = [TLOPopupPrompts new];
			
			[prompt sheetWindowWithQuestion:[NSApp keyWindow]
									 target:self
									 action:@selector(defaultIRCClientSheetCallback:)
									   body:TXTLS(@"SetAsDefaultIRCClientPromptMessage")
									  title:TXTLS(@"SetAsDefaultIRCClientPromptTitle")
							  defaultButton:TXTLS(@"YesButton") 
							alternateButton:TXTLS(@"NoButton") 
								otherButton:nil
							 suppressionKey:@"default_irc_client" 
							suppressionText:nil];
		}
	}
}

+ (void)initPreferences
{
	NSInteger numberOfRuns = ([_NSUserDefaults() integerForKey:@"TXRunCount"] + 1);
	
	[_NSUserDefaults() setInteger:numberOfRuns forKey:@"TXRunCount"];
	
#ifndef IS_TRIAL_BINARY
	if (numberOfRuns >= 2) {
		[self.invokeInBackgroundThread defaultIRCClientPrompt];
	} 
#endif
	
	startUpTime = [NSDate epochTime];
	
	// ====================================================== //
	
	NSMutableDictionary *d = [NSMutableDictionary dictionary];
	
	[d setBool:YES forKey:@"SpellChecking"];
	[d setBool:YES forKey:@"GrammarChecking"];
	[d setBool:YES forKey:@"eventHighlightGrowl"];
	[d setBool:YES forKey:@"eventNewtalkGrowl"];
	[d setBool:YES forKey:@"eventAddressBookMatch"];
	[d setBool:YES forKey:@"WebKitDeveloperExtras"];
	[d setBool:YES forKey:@"Preferences.General.confirm_quit"];
	[d setBool:YES forKey:@"Preferences.General.use_growl"];
	[d setBool:YES forKey:@"Preferences.General.stop_growl_on_active"];
	[d setBool:YES forKey:@"Preferences.General.display_servmotd"];
	[d setBool:YES forKey:@"Preferences.General.dockbadges"];
	[d setBool:YES forKey:@"Preferences.General.autoadd_scrollbackmark"];
	[d setBool:YES forKey:@"Preferences.General.show_join_leave"];
	[d setBool:YES forKey:@"Preferences.General.track_conversations"];
	[d setBool:YES forKey:@"Preferences.Keyword.current_nick"];
	[d setBool:YES forKey:@"Preferences.Theme.predetermine_fonts"];
    [d setBool:YES forKey:@"Preferences.General.use_nomode_symbol"];
    [d setBool:YES forKey:@"Preferences.General.focus_on_message"];
	[d setBool:YES forKey:@"Preferences.General.reply_ctcp_requests"];
	[d setBool:YES forKey:@"Preferences.General.log_antialiasing"];
	[d setBool:YES forKey:@"Preferences.General.process_channel_modes"];
	[d setBool:NO  forKey:@"AutoSpellCorrection"];
    [d setBool:NO  forKey:TXDeveloperEnvironmentToken];
	[d setBool:NO  forKey:@"Preferences.General.log_transcript"];
	[d setBool:NO  forKey:@"ForceServerListBadgeLocalization"];
	[d setBool:NO  forKey:@"Preferences.General.copyonselect"];
	[d setBool:NO  forKey:@"Preferences.General.strip_formatting"];
	[d setBool:NO  forKey:@"Preferences.General.rtl_formatting"];
	[d setBool:NO  forKey:@"Preferences.General.handle_server_notices"];
	[d setBool:NO  forKey:@"Preferences.General.handle_operalerts"];
	[d setBool:NO  forKey:@"Preferences.General.clear_only_active"];
	[d setBool:NO  forKey:@"Preferences.General.rejoin_onkick"];
	[d setBool:NO  forKey:@"Preferences.General.autojoin_oninvite"];
	[d setBool:NO  forKey:@"Preferences.General.amsg_allconnections"];
	[d setBool:NO  forKey:@"Preferences.General.away_allconnections"];
	[d setBool:NO  forKey:@"Preferences.General.nick_allconnections"];
	[d setBool:NO  forKey:@"Preferences.General.connect_on_doubleclick"];
	[d setBool:NO  forKey:@"Preferences.General.disconnect_on_doubleclick"];
	[d setBool:NO  forKey:@"Preferences.General.join_on_doubleclick"];
	[d setBool:NO  forKey:@"Preferences.General.leave_on_doubleclick"];
	[d setBool:NO  forKey:@"Preferences.General.open_browser_in_background"];
	[d setBool:NO  forKey:@"Preferences.General.show_inline_images"];
	[d setBool:NO  forKey:@"Preferences.General.log_highlights"];
	[d setBool:NO  forKey:@"Preferences.General.nickserv_delay_autojoin"];
	[d setBool:NO  forKey:@"Preferences.Theme.inputhistory_per_channel"];
	[d setBool:NO  forKey:@"Preferences.General.dockbadge_countpub"];
	[d setBool:NO  forKey:@"Preferences.General.disable_nickname_colors"];
	
	[d setObject:@"Glass"							forKey:@"eventHighlightSound"];
	[d setObject:@"ircop alert"						forKey:@"Preferences.General.ircop_alert_match"];
	[d setObject:@"Guest"							forKey:@"Preferences.Identity.nickname"];
	[d setObject:@"textual"							forKey:@"Preferences.Identity.username"];
	[d setObject:@"Textual User"					forKey:@"Preferences.Identity.realname"];
	[d setObject:TXTLS(@"ShunReason")				forKey:@"Preferences.General.ircop_shun_message"];
	[d setObject:TXTLS(@"KillReason")				forKey:@"Preferences.General.ircop_kill_message"];
	[d setObject:TXTLS(@"GlineReason")				forKey:@"Preferences.General.ircop_gline_message"];
	[d setObject:TXTLS(@"KickReason")				forKey:@"Preferences.General.kick_message"];
	[d setObject:TXDefaultTextualLogStyle			forKey:@"Preferences.Theme.name"];
	[d setObject:TXDefaultTextualLogFont			forKey:@"Preferences.Theme.log_font_name"];
	[d setObject:TXDefaultTextualNicknameFormat		forKey:@"Preferences.Theme.nick_format"];
	[d setObject:TXDefaultTextualTimestampFormat	forKey:@"Preferences.Theme.timestamp_format"];
	[d setObject:@"~/Documents/Textual Logs"		forKey:@"Preferences.General.transcript_folder"];
	
	[d setInteger:2										forKey:@"Preferences.General.autojoin_maxchans"];
	[d setInteger:300									forKey:@"Preferences.General.max_log_lines"];
	[d setInteger:300									forKey:@"Preferences.General.inline_image_width"];
	[d setInteger:TXTabKeyActionNickCompleteType		forKey:@"Preferences.General.tab_action"];
	[d setInteger:TXNicknameHighlightExactMatchType		forKey:@"Preferences.Keyword.matching_method"];
	[d setInteger:TXHostmaskBanWHAINNFormat				forKey:@"Preferences.General.banformat"];
	[d setInteger:TXNoticeSendServerConsoleType			forKey:@"Preferences.General.notices_sendto_location"];
	[d setInteger:TXUserDoubleClickQueryAction			forKey:@"Preferences.General.user_doubleclick_action"];
	[d setInteger:TXCmdWShortcutCloseWindowType			forKey:@"Preferences.General.keyboard_cmdw_response"];
	
	[d setDouble:0.05 forKey:@"Preferences.Experimental.view_loop_console_delay"];
	[d setDouble:0.07 forKey:@"Preferences.Experimental.view_loop_channel_delay"];
	[d setDouble:12.0 forKey:@"Preferences.Theme.log_font_size"];
	[d setDouble:1.0  forKey:@"Preferences.Theme.transparency"];
	
	// ====================================================== //
    
	[_NSUserDefaults() registerDefaults:d];
	
	[_NSUserDefaults() addObserver:(id)self forKeyPath:@"keywords"     options:NSKeyValueObservingOptionNew context:NULL];
	[_NSUserDefaults() addObserver:(id)self forKeyPath:@"excludeWords" options:NSKeyValueObservingOptionNew context:NULL];
	
	systemVersionPlist = [NSDictionary dictionaryWithContentsOfFile:@"/System/Library/CoreServices/ServerVersion.plist"];
	if (NSObjectIsEmpty(systemVersionPlist)) systemVersionPlist = [NSDictionary dictionaryWithContentsOfFile:@"/System/Library/CoreServices/SystemVersion.plist"];
	if (NSObjectIsEmpty(systemVersionPlist)) exit(10);
	
	
	textualPlist = [[NSBundle mainBundle] infoDictionary];
	
	[self loadKeywords];
	[self loadExcludeWords];
	[self populateCommandIndex];
	
	/* Sandbox Check */
	
	[_NSUserDefaults() setBool:[TPCPreferences sandboxEnabled] forKey:@"Preferences.security.sandbox_enabled"];
	
	/* Font Check */
	
	if ([NSFont fontIsAvailable:[TPCPreferences themeChannelViewFontName]] == NO) {
		[_NSUserDefaults() setObject:TXDefaultTextualLogFont forKey:@"Preferences.Theme.log_font_name"];
	}
	
	/* Theme Check */
	
	NSString *themeName = [TPCViewTheme extractThemeName:[TPCPreferences themeName]];
	NSString *themePath = [[TPCPreferences whereThemesPath] stringByAppendingPathComponent:themeName];
	
	if ([_NSFileManager() fileExistsAtPath:themePath] == NO) {
        themePath = [[TPCPreferences whereThemesLocalPath] stringByAppendingPathComponent:themeName];
        
        if ([_NSFileManager() fileExistsAtPath:themePath] == NO) {
            [_NSUserDefaults() setObject:TXDefaultTextualLogStyle forKey:@"Preferences.Theme.name"];
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
