// Created by Satoshi Nakagawa <psychs AT limechat DOT net> <http://github.com/psychs/limechat>
// Modifications by Codeux Software <support AT codeux DOT com> <https://github.com/codeux/Textual>
// You can redistribute it and/or modify it under the new BSD license.
// Converted to ARC Support on June 08, 2012

/* TPCPreferences is one of our highest level objects. It is a wrapper for a lot
 of the data handed down to the application beyond simple preference values. It also
 provides information such as the IRC command index, version information, local
 directory paths, etc. */

#import "TextualApplication.h"

@implementation TPCPreferences

#pragma mark -
#pragma mark Version Dictonaries

static NSDictionary *textualInfoPlist	= nil;
static NSDictionary *systemVersionPlist = nil;

+ (NSDictionary *)textualInfoPlist
{
	return textualInfoPlist;
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

+ (NSInteger)indexOfIRCommand:(NSString *)command 
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
	return [textualInfoPlist objectForKey:@"CFBundleName"];
}

+ (NSInteger)applicationProcessID
{
	return [[NSProcessInfo processInfo] processIdentifier];
}

+ (NSString *)gitBuildReference
{
	return [textualInfoPlist objectForKey:@"TXBundleBuildReference"];
}

+ (NSString *)applicationBundleIdentifier
{
	return [[NSBundle mainBundle] bundleIdentifier];
}

+ (BOOL)runningInHighResolutionMode
{
	return ([_NSMainScreen() backingScaleFactor] == 2.0f);
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
		
		base = [_NSUserDefaults() objectForKey:@"LogTranscriptDestination"];
		base = [base stringByExpandingTildeInPath];
		
		return base;
	}
}

+ (void)setTranscriptFolder:(NSString *)value
{
	[_NSUserDefaults() setObject:value forKey:@"LogTranscriptDestination"];
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
	return [_NSUserDefaults() objectForKey:@"DefaultIdentity -> Nickname"];
}

+ (NSString *)defaultUsername
{
	return [_NSUserDefaults() objectForKey:@"DefaultIdentity -> Username"];
}

+ (NSString *)defaultRealname
{
	return [_NSUserDefaults() objectForKey:@"DefaultIdentity -> Realname"];
}

#pragma mark - 
#pragma mark General Preferences

+ (NSInteger)autojoinMaxChannelJoins
{
	return [_NSUserDefaults() integerForKey:@"AutojoinMaximumChannelJoinCount"];
}

+ (NSString *)defaultKickMessage
{
	return [_NSUserDefaults() objectForKey:@"ChannelOperatorDefaultLocalization -> Kick Reason"];
}

+ (NSString *)IRCopDefaultKillMessage
{
	return [_NSUserDefaults() objectForKey:@"IRCopDefaultLocalizaiton -> Kill Reason"];
}

+ (NSString *)IRCopDefaultGlineMessage
{
	return [_NSUserDefaults() objectForKey:@"IRCopDefaultLocalizaiton -> G:Line Reason"];
}

+ (NSString *)IRCopDefaultShunMessage
{
	return [_NSUserDefaults() objectForKey:@"IRCopDefaultLocalizaiton -> Shun Reason"];
}

+ (NSString *)IRCopAlertMatch
{
	return [_NSUserDefaults() objectForKey:@"ScanForIRCopAlertInServerNoticesMatch"];
}

+ (NSString *)masqueradeCTCPVersion
{
	return [_NSUserDefaults() objectForKey:@"ApplicationCTCPVersionMasquerade"];
}

+ (BOOL)invertSidebarColors
{
	return NO;
}

+ (BOOL)trackConversations
{
	return [_NSUserDefaults() boolForKey:@"TrackConversationsWithColorHashing"];
}

+ (BOOL)autojoinWaitForNickServ
{
	return [_NSUserDefaults() boolForKey:@"AutojoinWaitsForNickservIdentification"];
}

+ (BOOL)logAllHighlightsToQuery
{
	return [_NSUserDefaults() boolForKey:@"LogHighlights"];
}

+ (BOOL)clearAllOnlyOnActiveServer
{
	return [_NSUserDefaults() boolForKey:@"ApplyCommandToAllConnections -> clearall"];
}

+ (BOOL)displayServerMOTD
{
	return [_NSUserDefaults() boolForKey:@"DisplayServerMessageOfTheDayOnConnect"];
}

+ (BOOL)copyOnSelect
{
	return [_NSUserDefaults() boolForKey:@"CopyTextSelectionOnMouseUp"];
}

+ (BOOL)replyToCTCPRequests
{
	return [_NSUserDefaults() boolForKey:@"ReplyUnignoredExternalCTCPRequests"];
}

+ (BOOL)autoAddScrollbackMark
{
	return [_NSUserDefaults() boolForKey:@"AutomaticallyAddScrollbackMarker"];
}

+ (BOOL)removeAllFormatting
{
	return [_NSUserDefaults() boolForKey:@"RemoveIRCTextFormatting"];
}

+ (BOOL)useLogAntialiasing
{
	return [_NSUserDefaults() boolForKey:@"DisplayMainWindowWithAntialiasing"];
}

+ (BOOL)disableNicknameColors
{
	return [_NSUserDefaults() boolForKey:@"DisableRemoteNicknameColorHashing"];
}

+ (BOOL)rightToLeftFormatting
{
	return [_NSUserDefaults() boolForKey:@"RightToLeftTextFormatting"];
}

+ (NSString *)completionSuffix
{
	return [_NSUserDefaults() objectForKey:@"Keyboard -> Tab Key Completion Suffix"];
}

+ (TXHostmaskBanFormat)banFormat
{
	return (TXHostmaskBanFormat)[_NSUserDefaults() integerForKey:@"DefaultBanCommandHostmaskFormat"];
}

+ (TXNSDouble)viewLoopConsoleDelay
{
	return [_NSUserDefaults() doubleForKey:@"LogViewMessageQueueLoopDelay -> Console"];
}

+ (TXNSDouble)viewLoopChannelDelay
{
	return [_NSUserDefaults() doubleForKey:@"LogViewMessageQueueLoopDelay -> Channel"];
}

+ (BOOL)displayDockBadge
{
	return [_NSUserDefaults() boolForKey:@"DisplayDockBadges"];
}

+ (BOOL)handleIRCopAlerts
{
	return [_NSUserDefaults() boolForKey:@"ScanForIRCopAlertInServerNotices"];
}

+ (BOOL)handleServerNotices
{
	return [_NSUserDefaults() boolForKey:@"ProcessServerNoticesForIRCop"];
}

+ (BOOL)amsgAllConnections
{
	return [_NSUserDefaults() boolForKey:@"ApplyCommandToAllConnections -> amsg"];
}

+ (BOOL)awayAllConnections
{
	return [_NSUserDefaults() boolForKey:@"ApplyCommandToAllConnections -> away"];
}

+ (BOOL)giveFocusOnMessage
{
	return [_NSUserDefaults() boolForKey:@"FocusSelectionOnMessageCommandExecution"];
}

+ (BOOL)nickAllConnections
{
	return [_NSUserDefaults() boolForKey:@"ApplyCommandToAllConnections -> nick"];
}

+ (BOOL)confirmQuit
{
	return [_NSUserDefaults() boolForKey:@"ConfirmApplicationQuit"];
}

+ (BOOL)processChannelModes
{
	return [_NSUserDefaults() boolForKey:@"ProcessChannelModesOnJoin"];
}

+ (BOOL)rejoinOnKick
{
	return [_NSUserDefaults() boolForKey:@"RejoinChannelOnLocalKick"];
}

+ (BOOL)autoJoinOnInvite
{
	return [_NSUserDefaults() boolForKey:@"AutojoinChannelOnInvite"];
}

+ (BOOL)connectOnDoubleclick
{
	return [_NSUserDefaults() boolForKey:@"ServerListDoubleClickConnectServer"];
}

+ (BOOL)disconnectOnDoubleclick
{
	return [_NSUserDefaults() boolForKey:@"ServerListDoubleClickDisconnectServer"];
}

+ (BOOL)joinOnDoubleclick
{
	return [_NSUserDefaults() boolForKey:@"ServerListDoubleClickJoinChannel"];
}

+ (BOOL)leaveOnDoubleclick
{
	return [_NSUserDefaults() boolForKey:@"ServerListDoubleClickLeaveChannel"];
}

+ (BOOL)logTranscript
{
	return [_NSUserDefaults() boolForKey:@"LogTranscript"];
}

+ (BOOL)openBrowserInBackground
{
	return [_NSUserDefaults() boolForKey:@"OpenClickedLinksInBackgroundBrowser"];
}

+ (BOOL)showInlineImages
{
	return [_NSUserDefaults() boolForKey:@"DisplayEventInLogView -> Inline Media"];
}

+ (BOOL)showJoinLeave
{
	return [_NSUserDefaults() boolForKey:@"DisplayEventInLogView -> Join, Part, Quit"];
}

+ (BOOL)stopGrowlOnActive
{
	return [_NSUserDefaults() boolForKey:@"DisableNotificationsForActiveWindow"];
}

+ (BOOL)countPublicMessagesInIconBadge
{
	return [_NSUserDefaults() boolForKey:@"DisplayPublicMessageCountInDockBadge"];
}

+ (TXTabKeyActionType)tabAction
{
	return (TXTabKeyActionType)[_NSUserDefaults() integerForKey:@"Keyboard -> Tab Key Action"];
}

+ (BOOL)keywordCurrentNick
{
	return [_NSUserDefaults() boolForKey:@"TrackNicknameHighlightsOfLocalUser"];
}

+ (TXNicknameHighlightMatchType)keywordMatchingMethod
{
	return (TXNicknameHighlightMatchType)[_NSUserDefaults() integerForKey:@"NicknameHighlightMatchingType"];
}

+ (TXUserDoubleClickAction)userDoubleClickOption
{
	return (TXUserDoubleClickAction)[_NSUserDefaults() integerForKey:@"UserListDoubleClickAction"];
}

+ (TXNoticeSendLocationType)locationToSendNotices
{
	return (TXNoticeSendLocationType)[_NSUserDefaults() integerForKey:@"DestinationOfNonserverNotices"];
}

+ (TXCmdWShortcutResponseType)cmdWResponseType
{
	return (TXCmdWShortcutResponseType)[_NSUserDefaults() integerForKey:@"Keyboard -> Command+W Action"];
}

#pragma mark -
#pragma mark Theme

+ (NSString *)themeName
{
	return [_NSUserDefaults() objectForKey:@"Theme -> Name"];
}

+ (void)setThemeName:(NSString *)value
{
	[_NSUserDefaults() setObject:value forKey:@"Theme -> Name"];
}

+ (NSString *)themeChannelViewFontName
{
	return [_NSUserDefaults() objectForKey:@"Theme -> Font Name"];
}

+ (void)setThemeChannelViewFontName:(NSString *)value
{
	[_NSUserDefaults() setObject:value forKey:@"Theme -> Font Name"];
}

+ (TXNSDouble)themeChannelViewFontSize
{
	return [_NSUserDefaults() doubleForKey:@"Theme -> Font Size"];
}

+ (void)setThemeChannelViewFontSize:(TXNSDouble)value
{
	[_NSUserDefaults() setDouble:value forKey:@"Theme -> Font Size"];
}

+ (NSString *)themeNickFormat
{
	return [_NSUserDefaults() objectForKey:@"Theme -> Nickname Format"];
}

+ (BOOL)inputHistoryIsChannelSpecific
{
	return [_NSUserDefaults() boolForKey:@"SaveInputHistoryPerSelection"];
}

+ (NSString *)themeTimestampFormat
{
	return [_NSUserDefaults() objectForKey:@"Theme -> Timestamp Format"];
}

+ (TXNSDouble)themeTransparency
{
	return [_NSUserDefaults() doubleForKey:@"MainWindowTransparencyLevel"];
}

#pragma mark -
#pragma mark Completion Suffix

+ (void)setCompletionSuffix:(NSString *)value
{
	[_NSUserDefaults() setObject:value forKey:@"Keyboard -> Tab Key Completion Suffix"];
}

#pragma mark -
#pragma mark Inline Image Size

+ (NSInteger)inlineImagesMaxWidth
{
	return [_NSUserDefaults() integerForKey:@"InlineMediaScalingWidt"];
}

+ (void)setInlineImagesMaxWidth:(NSInteger)value
{
	[_NSUserDefaults() setInteger:value forKey:@"InlineMediaScalingWidt"];
}

#pragma mark -
#pragma mark Max Log Lines

+ (NSInteger)maxLogLines
{
	return [_NSUserDefaults() integerForKey:@"ScrollbackMaximumLineCount"];
}

+ (void)setMaxLogLines:(NSInteger)value
{
	[_NSUserDefaults() setInteger:value forKey:@"ScrollbackMaximumLineCount"];
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
		case TXNotificationHighlightType:			return @"NotificationType -> Highlight";
		case TXNotificationNewQueryType:			return @"NotificationType -> Private Message (New)";
		case TXNotificationChannelMessageType:		return @"NotificationType -> Public Message";
		case TXNotificationChannelNoticeType:		return @"NotificationType -> Public Notice";
		case TXNotificationQueryMessageType:		return @"NotificationType -> Private Message";
		case TXNotificationQueryNoticeType:			return @"NotificationType -> Private Notice";
		case TXNotificationKickType:				return @"NotificationType -> Kicked from Channel";
		case TXNotificationInviteType:				return @"NotificationType -> Channel Invitation";
		case TXNotificationConnectType:				return @"NotificationType -> Connected";
		case TXNotificationDisconnectType:			return @"NotificationType -> Disconnected";
		case TXNotificationAddressBookMatchType:	return @"NotificationType -> Address Bok Match";
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
	
	NSString *key = [okey stringByAppendingString:@" -> Sound"];
	
	return [_NSUserDefaults() objectForKey:key];
}

+ (void)setSound:(NSString *)value forEvent:(TXNotificationType)event
{
	NSString *okey = [self keyForEvent:event];
	
	if (NSObjectIsEmpty(okey)) {
		return;
	}
	
	NSString *key = [okey stringByAppendingString:@" -> Sound"];
	
	[_NSUserDefaults() setObject:value forKey:key];
}

+ (BOOL)growlEnabledForEvent:(TXNotificationType)event
{
	NSString *okey = [self keyForEvent:event];
	
	if (NSObjectIsEmpty(okey)) {
		return NO;
	}
	
	NSString *key = [okey stringByAppendingString:@" -> Enabled"];
	
	return [_NSUserDefaults() boolForKey:key];
}

+ (void)setGrowlEnabled:(BOOL)value forEvent:(TXNotificationType)event
{
	NSString *okey = [self keyForEvent:event];
	
	if (NSObjectIsEmpty(okey)) {
		return;
	}
	
	NSString *key = [okey stringByAppendingString:@" -> Enabled"];
	
	[_NSUserDefaults() setBool:value forKey:key];
}

+ (BOOL)growlStickyForEvent:(TXNotificationType)event
{
	NSString *okey = [self keyForEvent:event];
	
	if (NSObjectIsEmpty(okey)) {
		return NO;
	}
	
	NSString *key = [okey stringByAppendingString:@" -> Sticky"];
	
	return [_NSUserDefaults() boolForKey:key];
}

+ (void)setGrowlSticky:(BOOL)value forEvent:(TXNotificationType)event
{
	NSString *okey = [self keyForEvent:event];
	
	if (NSObjectIsEmpty(okey)) {
		return;
	}
	
	NSString *key = [okey stringByAppendingString:@" -> Sticky"];
	
	[_NSUserDefaults() setBool:value forKey:key];
}

+ (BOOL)disableWhileAwayForEvent:(TXNotificationType)event
{
	NSString *okey = [self keyForEvent:event];
	
	if (NSObjectIsEmpty(okey)) {
		return NO;
	}
	
	NSString *key = [okey stringByAppendingString:@" -> Disable While Away"];
	
	return [_NSUserDefaults() boolForKey:key];
}

+ (void)setDisableWhileAway:(BOOL)value forEvent:(TXNotificationType)event
{
	NSString *okey = [self keyForEvent:event];
	
	if (NSObjectIsEmpty(okey)) {
		return;
	}
	
	NSString *key = [okey stringByAppendingString:@" -> Disable While Away"];
	
	[_NSUserDefaults() setBool:value forKey:key];
}

#pragma mark -
#pragma mark World

+ (NSDictionary *)loadWorld
{
	return [_NSUserDefaults() objectForKey:@"World Controller"];
}

+ (void)saveWorld:(NSDictionary *)value
{
	[_NSUserDefaults() setObject:value forKey:@"World Controller"];
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
	
	NSArray *ary = [_NSUserDefaults() objectForKey:@"Highlight List -> Primary Matches"];
	
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
	
	NSArray *ary = [_NSUserDefaults() objectForKey:@"Highlight List -> Excluded Matches"];
	
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
	[self cleanUpWords:@"Highlight List -> Primary Matches"];
	[self cleanUpWords:@"Highlight List -> Excluded Matches"];
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
	if ([key isEqualToString:@"Highlight List -> Primary Matches"]) {
		[self loadKeywords];
	} else if ([key isEqualToString:@"Highlight List -> Excluded Matches"]) {
		[self loadExcludeWords];
	}
}

#pragma mark -
#pragma mark Initialization

+ (void)defaultIRCClientSheetCallback:(NSNumber *)returnCode 
{	
    NSInteger _returnCode = [returnCode integerValue];
    
	if (_returnCode == NSAlertFirstButtonReturn) {
		NSString *bundleID = [TPCPreferences applicationBundleIdentifier];
		
		OSStatus changeResult;

		changeResult = LSSetDefaultHandlerForURLScheme((__bridge CFStringRef)@"irc",
													   (__bridge CFStringRef)(bundleID));
		
		changeResult = LSSetDefaultHandlerForURLScheme((__bridge CFStringRef)@"ircs",
													   (__bridge CFStringRef)(bundleID));

#pragma unused(changeResult)
	}
}

+ (void)defaultIRCClientPrompt
{
	[NSThread sleepForTimeInterval:1.5];
	
	NSURL *baseURL = [NSURL URLWithString:@"irc:"];
	
    CFURLRef appURL = NULL;
    OSStatus status = LSGetApplicationForURL((__bridge CFURLRef)baseURL, kLSRolesAll, NULL, &appURL);

	if (status == noErr) {
		NSBundle *mainBundle = [NSBundle mainBundle];
		NSBundle *baseBundle = [NSBundle bundleWithURL:CFBridgingRelease(appURL)];
		
		if ([[baseBundle bundleIdentifier] isNotEqualTo:[mainBundle bundleIdentifier]]) {
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
	NSInteger numberOfRuns = 0;

	numberOfRuns  = [_NSUserDefaults() integerForKey:@"TXRunCount"];
	numberOfRuns += 1;
	
	[_NSUserDefaults() setInteger:numberOfRuns forKey:@"TXRunCount"];
	
#ifndef IS_TRIAL_BINARY
	if (numberOfRuns >= 2) {
		[self.invokeInBackgroundThread defaultIRCClientPrompt];
	} 
#endif
	
	startUpTime = [NSDate epochTime];
	
	// ====================================================== //
	
	NSMutableDictionary *d = [NSMutableDictionary dictionary];
	
	[d setBool:YES forKey:@"AutomaticallyAddScrollbackMarker"];
	[d setBool:YES forKey:@"ConfirmApplicationQuit"];
	[d setBool:YES forKey:@"DisableNotificationsForActiveWindow"];
	[d setBool:YES forKey:@"DisplayDockBadges"];
	[d setBool:YES forKey:@"DisplayEventInLogView -> Join, Part, Quit"];
	[d setBool:YES forKey:@"DisplayMainWindowWithAntialiasing"];
	[d setBool:YES forKey:@"DisplayServerMessageOfTheDayOnConnect"];
	[d setBool:YES forKey:@"DisplayUserListNoModeSymbol"];
	[d setBool:YES forKey:@"FocusSelectionOnMessageCommandExecution"];
	[d setBool:YES forKey:@"LogHighlights"];
	[d setBool:YES forKey:@"LogTranscript"];
	[d setBool:YES forKey:@"ProcessChannelModesOnJoin"];
	[d setBool:YES forKey:@"ReplyUnignoredExternalCTCPRequests"];
	[d setBool:YES forKey:@"TextFieldAutomaticGrammarCheck"];
	[d setBool:YES forKey:@"TextFieldAutomaticSpellCheck"];
	[d setBool:YES forKey:@"TrackConversationsWithColorHashing"];
	[d setBool:YES forKey:@"TrackNicknameHighlightsOfLocalUser"];
	[d setBool:YES forKey:@"WebKitDeveloperExtras"];
	[d setBool:YES forKey:@"NotificationType -> Highlight -> Enabled"];
	[d setBool:YES forKey:@"NotificationType -> Address Bok Match -> Enabled"];
	[d setBool:YES forKey:@"NotificationType -> Private Message (New) -> Enabled"];
	
	[d setObject:@"Glass"							forKey:@"NotificationType -> Highlight -> Sound"];
	[d setObject:@"ircop alert"						forKey:@"ScanForIRCopAlertInServerNoticesMatch"];
	[d setObject:@"Guest"							forKey:@"DefaultIdentity -> Nickname"];
	[d setObject:@"textual"							forKey:@"DefaultIdentity -> Username"];
	[d setObject:@"Textual User"					forKey:@"DefaultIdentity -> Realname"];
	[d setObject:TXTLS(@"ShunReason")				forKey:@"IRCopDefaultLocalizaiton -> Shun Reason"];
	[d setObject:TXTLS(@"KillReason")				forKey:@"IRCopDefaultLocalizaiton -> Kill Reason"];
	[d setObject:TXTLS(@"GlineReason")				forKey:@"IRCopDefaultLocalizaiton -> G:Line Reason"];
	[d setObject:TXTLS(@"KickReason")				forKey:@"ChannelOperatorDefaultLocalization -> Kick Reasone"];
	[d setObject:TXDefaultTextualLogStyle			forKey:@"Theme -> Name"];
	[d setObject:TXDefaultTextualLogFont			forKey:@"Theme -> Font Name"];
	[d setObject:TXLogLineUndefinedNicknameFormat	forKey:@"Theme -> Nickname Format"];
	[d setObject:TXDefaultTextualTimestampFormat	forKey:@"Theme -> Timestamp Format"];
	[d setObject:@"~/Documents/Textual Logs"		forKey:@"LogTranscriptDestination"];
	
	[d setInteger:2										forKey:@"AutojoinMaximumChannelJoinCount"];
	[d setInteger:300									forKey:@"ScrollbackMaximumLineCount"];
	[d setInteger:300									forKey:@"InlineMediaScalingWidth"];
	[d setInteger:TXTabKeyActionNickCompleteType		forKey:@"Keyboard -> Tab Key Action"];
	[d setInteger:TXCmdWShortcutCloseWindowType			forKey:@"Keyboard -> Command+W Action"];
	[d setInteger:TXNicknameHighlightExactMatchType		forKey:@"NicknameHighlightMatchingType"];
	[d setInteger:TXHostmaskBanWHAINNFormat				forKey:@"DefaultBanCommandHostmaskFormat"];
	[d setInteger:TXNoticeSendServerConsoleType			forKey:@"DestinationOfNonserverNotices"];
	[d setInteger:TXUserDoubleClickQueryAction			forKey:@"UserListDoubleClickAction"];
	
	[d setDouble:0.05 forKey:@"LogViewMessageQueueLoopDelay -> Console"];
	[d setDouble:0.07 forKey:@"LogViewMessageQueueLoopDelay -> Channel"];
	[d setDouble:12.0 forKey:@"Theme -> Font Size"];
	[d setDouble:1.0  forKey:@"MainWindowTransparencyLevel"];
	
	// ====================================================== //

	[TPCPreferencesMigrationAssistant convertExistingGlobalPreferences];

	[_NSUserDefaults() registerDefaults:d];
	
	[_NSUserDefaults() addObserver:(id)self forKeyPath:@"Highlight List -> Primary Matches"  options:NSKeyValueObservingOptionNew context:NULL];
	[_NSUserDefaults() addObserver:(id)self forKeyPath:@"Highlight List -> Excluded Matches" options:NSKeyValueObservingOptionNew context:NULL];
	
	systemVersionPlist = [NSDictionary dictionaryWithContentsOfFile:@"/System/Library/CoreServices/ServerVersion.plist"];

	if (NSObjectIsEmpty(systemVersionPlist)) {
		systemVersionPlist = [NSDictionary dictionaryWithContentsOfFile:@"/System/Library/CoreServices/SystemVersion.plist"];
	}

	if (NSObjectIsEmpty(systemVersionPlist)) {
		exit(10);
	}
	
	textualInfoPlist = [[NSBundle mainBundle] infoDictionary];
	
	[self loadKeywords];
	[self loadExcludeWords];
	[self populateCommandIndex];
	
	/* Sandbox Check */
	
	[_NSUserDefaults() setBool:[TPCPreferences sandboxEnabled] forKey:@"Security -> Sandbox Enabled"];
	
	/* Font Check */
	
	if ([NSFont fontIsAvailable:[TPCPreferences themeChannelViewFontName]] == NO) {
		[_NSUserDefaults() setObject:TXDefaultTextualLogFont forKey:@"Theme -> Font Name"];
	}
	
	/* Theme Check */
	
	NSString *themeName = [TPCViewTheme extractThemeName:[TPCPreferences themeName]];
	NSString *themePath;

	themePath = [TPCPreferences whereThemesPath];
	themePath = [themePath stringByAppendingPathComponent:themeName];
	
	if ([_NSFileManager() fileExistsAtPath:themePath] == NO) {
		themePath = [TPCPreferences whereThemesLocalPath];
        themePath = [themePath stringByAppendingPathComponent:themeName];
        
        if ([_NSFileManager() fileExistsAtPath:themePath] == NO) {
            [_NSUserDefaults() setObject:TXDefaultTextualLogStyle forKey:@"Theme -> Name"];
        } else {
            NSString *newName = [NSString stringWithFormat:@"resource:%@", themeName];
            
            [_NSUserDefaults() setObject:newName forKey:@"Theme -> Name"];
        }
	}
}

+ (void)sync
{
	[_NSUserDefaults() synchronize];
}

@end
