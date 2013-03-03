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

@implementation TPCPreferencesMigrationAssistant

#pragma mark -
#pragma mark IRC Client & Channel Configuration

+ (NSDictionary *)convertIRCClientConfiguration:(NSDictionary *)config
{
	/* Has this configuration file already been migrated? */
	NSString *lastUpgrade = config[TPCPreferencesMigrationAssistantVersionKey];
	
	if (NSObjectIsNotEmpty(lastUpgrade)) {
		if ([lastUpgrade isEqualToString:TPCPreferencesMigrationAssistantUpgradePath]) {
			return config;
		}
	}
	
	NSMutableDictionary *nconfig = config.mutableCopy;
	
	/* If not, then migrate. */
	[nconfig removeAllObjects];
	
	[nconfig setInteger:[config integerForKey:@"encoding"]				forKey:@"characterEncodingDefault"];
	[nconfig setInteger:[config integerForKey:@"fallback_encoding"]		forKey:@"characterEncodingFallback"];
	[nconfig setInteger:[config integerForKey:@"port"]					forKey:@"serverPort"];
	[nconfig setInteger:[config integerForKey:@"proxy"]					forKey:@"proxyServerType"];
	[nconfig setInteger:[config integerForKey:@"proxy_port"]			forKey:@"proxyServerPort"];
	
	[nconfig setBool:[config boolForKey:@"auto_connect"]		forKey:@"connectOnLaunch"];
	[nconfig setBool:[config boolForKey:@"auto_reconnect"]		forKey:@"connectOnDisconnect"];
	[nconfig setBool:[config boolForKey:@"bouncer_mode"]		forKey:@"serverIsIRCBouncer"];
	[nconfig setBool:[config boolForKey:@"invisible"]			forKey:@"setInvisibleOnConnect"];
	[nconfig setBool:[config boolForKey:@"ssl"]					forKey:@"connectUsingSSL"];
	[nconfig setBool:[config boolForKey:@"trustedConnection"]	forKey:@"trustedSSLConnection"];
    [nconfig setBool:[config boolForKey:@"prefersIPv6"]			forKey:@"DNSResolverPrefersIPv6"];

	[nconfig safeSetObject:config[@"alt_nicks"]				forKey:@"identityAlternateNicknames"];
	[nconfig safeSetObject:config[@"guid"]					forKey:@"uniqueIdentifier"];
	[nconfig safeSetObject:config[@"host"]					forKey:@"serverAddress"];
	[nconfig safeSetObject:config[@"leaving_comment"]		forKey:@"connectionDisconnectDefaultMessage"];
	[nconfig safeSetObject:config[@"login_commands"]		forKey:@"onConnectCommands"];
	[nconfig safeSetObject:config[@"name"]					forKey:@"connectionName"];
	[nconfig safeSetObject:config[@"nick"]					forKey:@"identityNickname"];
	[nconfig safeSetObject:config[@"proxy_host"]			forKey:@"proxyServerAddress"];
	[nconfig safeSetObject:config[@"proxy_password"]		forKey:@"proxyServerPassword"];
	[nconfig safeSetObject:config[@"proxy_user"]			forKey:@"proxyServerUsername"];
	[nconfig safeSetObject:config[@"realname"]				forKey:@"identityRealname"];
	[nconfig safeSetObject:config[@"sleep_quit_message"]	forKey:@"connectionDisconnectSleepModeMessage"];
	[nconfig safeSetObject:config[@"username"]				forKey:@"identityUsername"];
	
	NSMutableDictionary *floodControl = [config dictionaryForKey:@"flood_control"].mutableCopy;
	
    [floodControl setInteger:[floodControl integerForKey:@"delay_timer"]		forKey:@"delayTimerInterval"];
    [floodControl setInteger:[floodControl integerForKey:@"message_count"]		forKey:@"maximumMessageCount"];
	
    [floodControl setBool:[floodControl boolForKey:@"outgoing"] forKey:@"serviceEnabled"];
    
	[nconfig safeSetObject:floodControl forKey:@"floodControl"];
	
	[nconfig safeSetObject:config[@"channels"] forKey:@"channelList"];
	[nconfig safeSetObject:config[@"ignores"] forKey:@"ignoreList"];
	
	[nconfig safeSetObject:TPCPreferencesMigrationAssistantUpgradePath
					forKey:TPCPreferencesMigrationAssistantVersionKey];
	
	return nconfig;
}

+ (NSDictionary *)convertIRCChannelConfiguration:(NSDictionary *)config
{
	/* Has this configuration file already been migrated? */
	NSString *lastUpgrade = config[TPCPreferencesMigrationAssistantVersionKey];
	
	if (NSObjectIsNotEmpty(lastUpgrade)) {
		if ([lastUpgrade isEqualToString:TPCPreferencesMigrationAssistantUpgradePath]) {
			return config;
		}
	}

	NSMutableDictionary *nconfig = config.mutableCopy;
	
	/* If not, then migrate. */
	[nconfig removeAllObjects];
	
	[nconfig setInteger:[config integerForKey:@"type"]		forKey:@"channelType"];
	
	[nconfig setBool:[config boolForKey:@"auto_join"]			forKey:@"joinOnConnect"];
	[nconfig setBool:[config boolForKey:@"growl"]				forKey:@"enableNotifications"];
    [nconfig setBool:[config boolForKey:@"disable_images"]		forKey:@"disableInlineMedia"];
    [nconfig setBool:[config boolForKey:@"ignore_highlights"]	forKey:@"ignoreHighlights"];
    [nconfig setBool:[config boolForKey:@"ignore_join,leave"]	forKey:@"ignoreJPQActivity"];
	
	[nconfig safeSetObject:config[@"encryptionKey"]	forKey:@"encryptionKey"];
	[nconfig safeSetObject:config[@"mode"]			forKey:@"defaultMode"];
	[nconfig safeSetObject:config[@"name"]			forKey:@"channelName"];
	[nconfig safeSetObject:config[@"password"]		forKey:@"secretJoinKey"];
	[nconfig safeSetObject:config[@"password"]		forKey:@"secretKey"];
	[nconfig safeSetObject:config[@"topic"]			forKey:@"defaultTopic"];
	
	[nconfig safeSetObject:TPCPreferencesMigrationAssistantUpgradePath
					forKey:TPCPreferencesMigrationAssistantVersionKey];
	
	return nconfig;
}

#pragma mark -
#pragma mark Global Preferences 

+ (void)migrateGlobalPreference:(NSString *)newKey from:(NSString *)oldKey
{
	[RZUserDefaults() setObject:[RZUserDefaults() objectForKey:oldKey] forKey:newKey];
	
	[RZUserDefaults() removeObjectForKey:oldKey];
}

+ (void)convertExistingGlobalPreferences
{
	/* Has this configuration file already been migrated? */
	NSString *lastUpgrade = [RZUserDefaults() objectForKey:TPCPreferencesMigrationAssistantVersionKey];
	
	if (NSObjectIsNotEmpty(lastUpgrade)) {
		if ([lastUpgrade isEqualToString:TPCPreferencesMigrationAssistantUpgradePath]) {
			return;
		}
	}
	
	/* If not, then migrate. */
	[self.class migrateGlobalPreference:@"World Controller"								from:@"world"];
	[self.class migrateGlobalPreference:@"Window -> Main Window"						from:@"MainWindow"];
	[self.class migrateGlobalPreference:@"Highlight List -> Primary Matches"			from:@"keywords"];
	[self.class migrateGlobalPreference:@"Highlight List -> Excluded Matches"			from:@"excludeWords"];

	[self.class migrateGlobalPreference:@"ApplicationCTCPVersionMasquerade"				from:@"Preferences.General.masquerade_ctcp_version"];
	[self.class migrateGlobalPreference:@"ApplyCommandToAllConnections -> amsg"			from:@"Preferences.General.amsg_allconnections"];
	[self.class migrateGlobalPreference:@"ApplyCommandToAllConnections -> away"			from:@"Preferences.General.away_allconnections"];
	[self.class migrateGlobalPreference:@"ApplyCommandToAllConnections -> clearall"		from:@"Preferences.General.clear_only_active"];
	[self.class migrateGlobalPreference:@"ApplyCommandToAllConnections -> nick"			from:@"Preferences.General.nick_allconnections"];
	[self.class migrateGlobalPreference:@"AutojoinChannelOnInvite"						from:@"Preferences.General.autojoin_oninvite"];
	[self.class migrateGlobalPreference:@"AutojoinMaximumChannelJoinCount"				from:@"Preferences.General.autojoin_maxchans"];
	[self.class migrateGlobalPreference:@"AutojoinWaitsForNickservIdentification"		from:@"Preferences.General.nickserv_delay_autojoin"];
	[self.class migrateGlobalPreference:@"AutomaticallyAddScrollbackMarker"				from:@"Preferences.General.autoadd_scrollbackmark"];
	
	[self.class migrateGlobalPreference:@"ChannelOperatorDefaultLocalization -> Kick Reason"	from:@"Preferences.General.kick_message"];
	
	[self.class migrateGlobalPreference:@"ConfirmApplicationQuit"						from:@"Preferences.General.confirm_quit"];
	[self.class migrateGlobalPreference:@"CopyTextSelectionOnMouseUp"					from:@"Preferences.General.copyonselect"];
	[self.class migrateGlobalPreference:@"DefaultBanCommandHostmaskFormat"				from:@"Preferences.General.banformat"];
	[self.class migrateGlobalPreference:@"DefaultIdentity -> Nickname"					from:@"Preferences.Identity.nickname"];
	[self.class migrateGlobalPreference:@"DefaultIdentity -> Realname"					from:@"Preferences.Identity.realname"];
	[self.class migrateGlobalPreference:@"DefaultIdentity -> Username"					from:@"Preferences.Identity.username"];
	[self.class migrateGlobalPreference:@"DestinationOfNonserverNotices"				from:@"Preferences.General.notices_sendto_location"];
	[self.class migrateGlobalPreference:@"DisableNotificationsForActiveWindow"			from:@"Preferences.General.stop_growl_on_active"];
	[self.class migrateGlobalPreference:@"DisableRemoteNicknameColorHashing"			from:@"Preferences.General.disable_nickname_colors"];
	[self.class migrateGlobalPreference:@"DisplayDockBadges"							from:@"Preferences.General.dockbadges"];
	[self.class migrateGlobalPreference:@"DisplayEventInLogView -> Inline Media"		from:@"Preferences.General.show_inline_images"];
	[self.class migrateGlobalPreference:@"DisplayEventInLogView -> Join, Part, Quit"	from:@"Preferences.General.show_join_leave"];
	[self.class migrateGlobalPreference:@"DisplayMainWindowWithAntialiasing"			from:@"Preferences.General.log_antialiasing"];
	[self.class migrateGlobalPreference:@"DisplayPublicMessageCountInDockBadge"			from:@"Preferences.General.dockbadge_countpub"];
	[self.class migrateGlobalPreference:@"DisplayServerMessageOfTheDayOnConnect"		from:@"Preferences.General.display_servmotd"];
	[self.class migrateGlobalPreference:@"DisplayUserListNoModeSymbol"					from:@"Preferences.General.use_nomode_symbol"];
	[self.class migrateGlobalPreference:@"FocusSelectionOnMessageCommandExecution"		from:@"Preferences.General.focus_on_message"];
	[self.class migrateGlobalPreference:@"IRCopDefaultLocalizaiton -> G:Line Reason"	from:@"Preferences.General.ircop_gline_message"];
	[self.class migrateGlobalPreference:@"IRCopDefaultLocalizaiton -> Kill Reason"		from:@"Preferences.General.ircop_kill_message"];
	[self.class migrateGlobalPreference:@"IRCopDefaultLocalizaiton -> Shun Reason"		from:@"Preferences.General.ircop_shun_message"];
	[self.class migrateGlobalPreference:@"InlineMediaScalingWidth"						from:@"Preferences.General.inline_image_width"];
	[self.class migrateGlobalPreference:@"Keyboard -> Command+W Action"					from:@"Preferences.General.keyboard_cmdw_response"];
	[self.class migrateGlobalPreference:@"Keyboard -> Tab Key Action"					from:@"Preferences.General.tab_action"];
	[self.class migrateGlobalPreference:@"Keyboard -> Tab Key Completion Suffix"		from:@"Preferences.General.completion_suffix"];
	[self.class migrateGlobalPreference:@"LogHighlights"								from:@"Preferences.General.log_highlights"];
	[self.class migrateGlobalPreference:@"LogTranscript"								from:@"Preferences.General.log_transcript"];
	[self.class migrateGlobalPreference:@"LogTranscriptDestination"						from:@"Preferences.General.transcript_folder"];
	[self.class migrateGlobalPreference:@"MainWindowTransparencyLevel"					from:@"Preferences.Theme.transparency"];
	[self.class migrateGlobalPreference:@"NicknameHighlightMatchingType"				from:@"Preferences.Keyword.matching_method"];
	[self.class migrateGlobalPreference:@"OpenClickedLinksInBackgroundBrowser"			from:@"Preferences.General.open_browser_in_background"];
	[self.class migrateGlobalPreference:@"ProcessChannelModesOnJoin"					from:@"Preferences.General.process_channel_modes"];
	[self.class migrateGlobalPreference:@"ProcessServerNoticesForIRCop"					from:@"Preferences.General.handle_server_notices"];
	[self.class migrateGlobalPreference:@"RejoinChannelOnLocalKick"						from:@"Preferences.General.rejoin_onkick"];
	[self.class migrateGlobalPreference:@"RemoveIRCTextFormatting"						from:@"Preferences.General.strip_formatting"];
	[self.class migrateGlobalPreference:@"ReplyUnignoredExternalCTCPRequests"			from:@"Preferences.General.reply_ctcp_requests"];
	[self.class migrateGlobalPreference:@"RightToLeftTextFormatting"					from:@"Preferences.General.rtl_formatting"];
	[self.class migrateGlobalPreference:@"SaveInputHistoryPerSelection"					from:@"Preferences.Theme.inputhistory_per_channel"];
	[self.class migrateGlobalPreference:@"ScanForIRCopAlertInServerNotices"				from:@"Preferences.General.handle_operalerts"];
	[self.class migrateGlobalPreference:@"ScanForIRCopAlertInServerNoticesMatch"		from:@"Preferences.General.ircop_alert_match"];
	[self.class migrateGlobalPreference:@"ScrollbackMaximumLineCount"					from:@"Preferences.General.max_log_lines"];
	[self.class migrateGlobalPreference:@"ServerListDoubleClickConnectServer"			from:@"Preferences.General.connect_on_doubleclick"];
	[self.class migrateGlobalPreference:@"ServerListDoubleClickDisconnectServer"		from:@"Preferences.General.disconnect_on_doubleclick"];
	[self.class migrateGlobalPreference:@"ServerListDoubleClickJoinChannel"				from:@"Preferences.General.join_on_doubleclick"];
	[self.class migrateGlobalPreference:@"ServerListDoubleClickLeaveChannel"			from:@"Preferences.General.leave_on_doubleclick"];
	[self.class migrateGlobalPreference:@"TextFieldAutomaticGrammarCheck"				from:@"GrammarChecking"];
	[self.class migrateGlobalPreference:@"TextFieldAutomaticSpellCheck"					from:@"SpellChecking"];
	[self.class migrateGlobalPreference:@"TextFieldAutomaticSpellCorrection"			from:@"AutoSpellCorrection"];
	[self.class migrateGlobalPreference:@"Theme -> Font Name"							from:@"Preferences.Theme.log_font_name"];
	[self.class migrateGlobalPreference:@"Theme -> Font Size"							from:@"Preferences.Theme.log_font_size"];
	[self.class migrateGlobalPreference:@"Theme -> Name"								from:@"Preferences.Theme.name"];
	[self.class migrateGlobalPreference:@"Theme -> Nickname Format"						from:@"Preferences.Theme.nick_format"];
	[self.class migrateGlobalPreference:@"Theme -> Timestamp Format"					from:@"Preferences.Theme.timestamp_format"];
	[self.class migrateGlobalPreference:@"TrackConversationsWithColorHashing"			from:@"Preferences.General.track_conversations"];
	[self.class migrateGlobalPreference:@"TrackNicknameHighlightsOfLocalUser"			from:@"Preferences.Keyword.current_nick"];
	[self.class migrateGlobalPreference:@"UserListDoubleClickAction"					from:@"Preferences.General.user_doubleclick_action"];

	[self.class migrateGlobalPreference:@"NotificationType -> Highlight -> Enabled"						from:@"eventHighlightGrowl"];
	[self.class migrateGlobalPreference:@"NotificationType -> Private Message (New) -> Enabled"			from:@"eventNewtalkGrowl"];
	[self.class migrateGlobalPreference:@"NotificationType -> Public Message -> Enabled"				from:@"eventChannelTextGrowl"];
	[self.class migrateGlobalPreference:@"NotificationType -> Public Notice -> Enabled"					from:@"eventChannelNoticeGrowl"];
	[self.class migrateGlobalPreference:@"NotificationType -> Private Message -> Enabled"				from:@"eventTalkTextGrowl"];
	[self.class migrateGlobalPreference:@"NotificationType -> Private Notice -> Enabled"				from:@"eventTalkNoticeGrowl"];
	[self.class migrateGlobalPreference:@"NotificationType -> Kicked from Channel -> Enabled"			from:@"eventKickedGrowl"];
	[self.class migrateGlobalPreference:@"NotificationType -> Channel Invitation -> Enabled"			from:@"eventInvitedGrowl"];
	[self.class migrateGlobalPreference:@"NotificationType -> Connected -> Enabled"						from:@"eventLoginGrowl"];
	[self.class migrateGlobalPreference:@"NotificationType -> Disconnected -> Enabled"					from:@"eventDisconnectGrowl"];
	[self.class migrateGlobalPreference:@"NotificationType -> Address Bok Match -> Enabled"				from:@"eventAddressBookMatchGrowl"];
	
	[self.class migrateGlobalPreference:@"NotificationType -> Highlight -> Sound"						from:@"eventHighlightSound"];
	[self.class migrateGlobalPreference:@"NotificationType -> Private Message (New) -> Sound"			from:@"eventNewtalkSound"];
	[self.class migrateGlobalPreference:@"NotificationType -> Public Message -> Sound"					from:@"eventChannelTextSound"];
	[self.class migrateGlobalPreference:@"NotificationType -> Public Notice -> Sound"					from:@"eventChannelNoticeSound"];
	[self.class migrateGlobalPreference:@"NotificationType -> Private Message -> Sound"					from:@"eventTalkTextSound"];
	[self.class migrateGlobalPreference:@"NotificationType -> Private Notice -> Sound"					from:@"eventTalkNoticeSound"];
	[self.class migrateGlobalPreference:@"NotificationType -> Kicked from Channel -> Sound"				from:@"eventKickedSound"];
	[self.class migrateGlobalPreference:@"NotificationType -> Channel Invitation -> Sound"				from:@"eventInvitedSound"];
	[self.class migrateGlobalPreference:@"NotificationType -> Connected -> Sound"						from:@"eventLoginSound"];
	[self.class migrateGlobalPreference:@"NotificationType -> Disconnected -> Sound"					from:@"eventDisconnectSound"];
	[self.class migrateGlobalPreference:@"NotificationType -> Address Bok Match -> Enabled"				from:@"eventAddressBookMatchSound"];

	[self.class migrateGlobalPreference:@"NotificationType -> Highlight -> Disable While Away"					from:@"eventHighlightDisableWhileAway"];
	[self.class migrateGlobalPreference:@"NotificationType -> Private Message (New) -> Disable While Away"		from:@"eventNewtalkDisableWhileAway"];
	[self.class migrateGlobalPreference:@"NotificationType -> Public Message -> Disable While Away"				from:@"eventChannelTextDisableWhileAway"];
	[self.class migrateGlobalPreference:@"NotificationType -> Public Notice -> Disable While Away"				from:@"eventChannelNoticeDisableWhileAway"];
	[self.class migrateGlobalPreference:@"NotificationType -> Private Message -> Disable While Away"			from:@"eventTalkTextDisableWhileAway"];
	[self.class migrateGlobalPreference:@"NotificationType -> Private Notice -> Disable While Away"				from:@"eventTalkNoticeDisableWhileAway"];
	[self.class migrateGlobalPreference:@"NotificationType -> Kicked from Channel -> Disable While Away"		from:@"eventKickedDisableWhileAway"];
	[self.class migrateGlobalPreference:@"NotificationType -> Channel Invitation -> Disable While Away"			from:@"eventInvitedDisableWhileAway"];
	[self.class migrateGlobalPreference:@"NotificationType -> Connected -> Disable While Away"					from:@"eventLoginDisableWhileAway"];
	[self.class migrateGlobalPreference:@"NotificationType -> Disconnected -> Disable While Away"				from:@"eventDisconnectDisableWhileAway"];
	[self.class migrateGlobalPreference:@"NotificationType -> Address Bok Match -> Enabled"						from:@"eventAddressBookMatchDisableWhileAway"];
	
	[RZUserDefaults() setObject:TPCPreferencesMigrationAssistantUpgradePath
						  forKey:TPCPreferencesMigrationAssistantVersionKey];
}

@end
