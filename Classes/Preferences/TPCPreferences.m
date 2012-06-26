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
	
	commandIndex[IRCCommandIndexAction] = @"27";
	commandIndex[IRCCommandIndexAdchat] = @"89"; 
	commandIndex[IRCCommandIndexAme] = @"73";
	commandIndex[IRCCommandIndexAmsg] = @"72";
	commandIndex[IRCCommandIndexAuthenticate] = @"101";
	commandIndex[IRCCommandIndexAway] = @"3";
	commandIndex[IRCCommandIndexBan] = @"41";
	commandIndex[IRCCommandIndexCap] = @"102";
	commandIndex[IRCCommandIndexCaps] = @"103";
	commandIndex[IRCCommandIndexCcbadge] = @"104";
	commandIndex[IRCCommandIndexChatops] = @"85"; 
	commandIndex[IRCCommandIndexClear] = @"42";
	commandIndex[IRCCommandIndexClearall] = @"71";
	commandIndex[IRCCommandIndexClientinfo] = @"31";
	commandIndex[IRCCommandIndexClose] = @"43";
	commandIndex[IRCCommandIndexConn] = @"83"; 
	commandIndex[IRCCommandIndexCtcp] = @"32";
	commandIndex[IRCCommandIndexCtcpreply] = @"33";
	commandIndex[IRCCommandIndexCycle] = @"44";
	commandIndex[IRCCommandIndexDcc] = @"28";
	commandIndex[IRCCommandIndexDebug] = @"70";
	commandIndex[IRCCommandIndexDehalfop] = @"45";
	commandIndex[IRCCommandIndexDeop] = @"46";
	commandIndex[IRCCommandIndexDevoice] = @"47";
	commandIndex[IRCCommandIndexEcho] = @"69";
	commandIndex[IRCCommandIndexError] = @"4";
	commandIndex[IRCCommandIndexGline] = @"97";
	commandIndex[IRCCommandIndexGlobops] = @"86"; 
	commandIndex[IRCCommandIndexGzline] = @"98";
	commandIndex[IRCCommandIndexHalfop] = @"48";
	commandIndex[IRCCommandIndexHop] = @"49";
	commandIndex[IRCCommandIndexIcbadge] = @"81";
	commandIndex[IRCCommandIndexIgnore] = @"50";
	commandIndex[IRCCommandIndexInvite] = @"5";
	commandIndex[IRCCommandIndexIson] = @"6";
	commandIndex[IRCCommandIndexJ] = @"51";
	commandIndex[IRCCommandIndexJoin] = @"7";
	commandIndex[IRCCommandIndexKick] = @"8";
	commandIndex[IRCCommandIndexKickban] = @"79"; 
	commandIndex[IRCCommandIndexKill] = @"9";
	commandIndex[IRCCommandIndexLagcheck] = @"94";
	commandIndex[IRCCommandIndexLeave] = @"52";
	commandIndex[IRCCommandIndexList] = @"10";
	commandIndex[IRCCommandIndexLoadPlugins] = @"91";
	commandIndex[IRCCommandIndexLocops] = @"87"; 
	commandIndex[IRCCommandIndexM] = @"53";
	commandIndex[IRCCommandIndexMe] = @"54";
	commandIndex[IRCCommandIndexMode] = @"11";
	commandIndex[IRCCommandIndexMsg] = @"55";
	commandIndex[IRCCommandIndexMute] = @"74"; 
	commandIndex[IRCCommandIndexMylag] = @"95";
	commandIndex[IRCCommandIndexMyversion] = @"84"; 
	commandIndex[IRCCommandIndexNachat] = @"88"; 
	commandIndex[IRCCommandIndexNames] = @"12";
	commandIndex[IRCCommandIndexNick] = @"13";
	commandIndex[IRCCommandIndexNotice] = @"14";
	commandIndex[IRCCommandIndexOmsg] = @"38";
	commandIndex[IRCCommandIndexOnotice] = @"39";
	commandIndex[IRCCommandIndexOp] = @"56";
	commandIndex[IRCCommandIndexPart] = @"15";
	commandIndex[IRCCommandIndexPass] = @"16";
	commandIndex[IRCCommandIndexPing] = @"17";
	commandIndex[IRCCommandIndexPong] = @"18";
	commandIndex[IRCCommandIndexPrivmsg] = @"19";
	commandIndex[IRCCommandIndexQuery] = @"59";
	commandIndex[IRCCommandIndexQuit] = @"20";
	commandIndex[IRCCommandIndexQuote] = @"60";
	commandIndex[IRCCommandIndexRaw] = @"57";
	commandIndex[IRCCommandIndexRejoin] = @"58";
	commandIndex[IRCCommandIndexRemove] = @"77";  
	commandIndex[IRCCommandIndexSend] = @"29";
	commandIndex[IRCCommandIndexServer] = @"82";
	commandIndex[IRCCommandIndexShun] = @"99";
	commandIndex[IRCCommandIndexSme] = @"92";
	commandIndex[IRCCommandIndexSmsg] = @"93";
	commandIndex[IRCCommandIndexT] = @"61";
	commandIndex[IRCCommandIndexTempshun] = @"100";
	commandIndex[IRCCommandIndexTime] = @"34";
	commandIndex[IRCCommandIndexTimer] = @"62";
	commandIndex[IRCCommandIndexTopic] = @"21";
	commandIndex[IRCCommandIndexUmode] = @"66";
	commandIndex[IRCCommandIndexUnban] = @"64";
	commandIndex[IRCCommandIndexUnignore] = @"65";
	commandIndex[IRCCommandIndexUnloadPlugins] = @"76"; 
	commandIndex[IRCCommandIndexUnmute] = @"75"; 
	commandIndex[IRCCommandIndexUser] = @"22";
	commandIndex[IRCCommandIndexUserinfo] = @"35";
	commandIndex[IRCCommandIndexVersion] = @"36";
	commandIndex[IRCCommandIndexVoice] = @"63";
	commandIndex[IRCCommandIndexWallops] = @"80"; 
	commandIndex[IRCCommandIndexWeights] = @"68";
	commandIndex[IRCCommandIndexWho] = @"23";
	commandIndex[IRCCommandIndexWhois] = @"24";
	commandIndex[IRCCommandIndexWhowas] = @"25";
	commandIndex[IRCCommandIndexZline] = @"96";
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
	return textualInfoPlist[@"CFBundleName"];
}

+ (NSInteger)applicationProcessID
{
	return [[NSProcessInfo processInfo] processIdentifier];
}

+ (NSString *)gitBuildReference
{
	return textualInfoPlist[@"TXBundleBuildReference"];
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
	
	return NSStringEmptyPlaceholder;
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

static NSURL *transcriptFolderResolvedBookmark;

+ (void)stopUsingTranscriptFolderBookmarkResources
{
	if (NSObjectIsNotEmpty(transcriptFolderResolvedBookmark)) {
		[transcriptFolderResolvedBookmark stopAccessingSecurityScopedResource];
		
		transcriptFolderResolvedBookmark = nil;
	}
}

+ (NSString *)transcriptFolder
{
	if ([self sandboxEnabled] && [TPCPreferences securityScopedBookmarksAvailable]) {
		if (NSObjectIsNotEmpty(transcriptFolderResolvedBookmark)) {
			return [transcriptFolderResolvedBookmark path];
		} else {
			NSData *bookmark = [_NSUserDefaults() dataForKey:@"LogTranscriptDestinationSecurityBookmark"];
			
			if (NSObjectIsNotEmpty(bookmark)) {
				NSError *error;
				
				NSURL *resolvedBookmark = [NSURL URLByResolvingBookmarkData:bookmark
																	options:NSURLBookmarkResolutionWithSecurityScope
															  relativeToURL:nil
														bookmarkDataIsStale:NO
																	  error:&error];
				
				if (error) {
					NSLog(@"Error creating bookmark for URL: %@", error);
				} else {
					[resolvedBookmark startAccessingSecurityScopedResource];
					
					transcriptFolderResolvedBookmark = resolvedBookmark;
					
					return [transcriptFolderResolvedBookmark path];
				}
			}
		}

		return nil;
	} else {
		NSString *base = [_NSUserDefaults() objectForKey:@"LogTranscriptDestination"];
	
		return [base stringByExpandingTildeInPath];
	}
}

+ (void)setTranscriptFolder:(id)value
{
	// "value" can either be returned as an absolute path on non-sandboxed
	// versions of Textual or as an NSData object on sandboxed versions.
	
	if ([self sandboxEnabled]) {
		if ([TPCPreferences securityScopedBookmarksAvailable] == NO) {
			return;
		}
		
		[self stopUsingTranscriptFolderBookmarkResources];
		
		[_NSUserDefaults() setObject:value forKey:@"LogTranscriptDestinationSecurityBookmark"];
	} else {
		[_NSUserDefaults() setObject:value forKey:@"LogTranscriptDestination"];
	}
}

#pragma mark -
#pragma mark Sandbox Check

+ (BOOL)sandboxEnabled
{
	NSString *suffix = [NSString stringWithFormat:@"Containers/%@/Data", [TPCPreferences applicationBundleIdentifier]];
	
	return [NSHomeDirectory() hasSuffix:suffix];
}

+ (BOOL)securityScopedBookmarksAvailable
{
	if ([TPCPreferences featureAvailableToOSXLion] == NO) {
		return NO;
	}

	if ([TPCPreferences featureAvailableToOSXMountainLion]) {
		return YES;
	}

	NSString *osxversion = systemVersionPlist[@"ProductVersion"];

	NSArray *matches = @[@"10.7", @"10.7.0", @"10.7.1", @"10.7.2"];

	return ([matches containsObject:osxversion] == NO);
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
		NSString *s = e[@"string"];
		
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
		NSString *s = e[@"string"];
		
		if (s) [excludeWords safeAddObject:s];
	}
}

+ (void)cleanUpWords:(NSString *)key
{
	NSArray *src = [_NSUserDefaults() objectForKey:key];
	
	NSMutableArray *ary = [NSMutableArray array];
	
	for (NSDictionary *e in src) {
		NSString *s = e[@"string"];
		
		if (NSObjectIsNotEmpty(s)) {
			[ary safeAddObject:s];
		}
	}
	
	[ary sortUsingSelector:@selector(caseInsensitiveCompare:)];
	
	NSMutableArray *saveAry = [NSMutableArray array];
	
	for (NSString *s in ary) {
		NSMutableDictionary *dic = [NSMutableDictionary dictionary];
		
		dic[@"string"] = s;
		
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
	
	d[@"NotificationType -> Highlight -> Sound"] = @"Glass";
	d[@"ScanForIRCopAlertInServerNoticesMatch"] = @"ircop alert";
	d[@"DefaultIdentity -> Nickname"] = @"Guest";
	d[@"DefaultIdentity -> Username"] = @"textual";
	d[@"DefaultIdentity -> Realname"] = @"Textual User";
	d[@"IRCopDefaultLocalizaiton -> Shun Reason"] = TXTLS(@"ShunReason");
	d[@"IRCopDefaultLocalizaiton -> Kill Reason"] = TXTLS(@"KillReason");
	d[@"IRCopDefaultLocalizaiton -> G:Line Reason"] = TXTLS(@"GlineReason");
	d[@"ChannelOperatorDefaultLocalization -> Kick Reasone"] = TXTLS(@"KickReason");
	d[@"Theme -> Name"] = TXDefaultTextualLogStyle;
	d[@"Theme -> Font Name"] = TXDefaultTextualLogFont;
	d[@"Theme -> Nickname Format"] = TXLogLineUndefinedNicknameFormat;
	d[@"Theme -> Timestamp Format"] = TXDefaultTextualTimestampFormat;
	d[@"LogTranscriptDestination"] = @"~/Documents/Textual Logs";
	
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
	
	[_NSUserDefaults() setBool:[TPCPreferences sandboxEnabled]						forKey:@"Security -> Sandbox Enabled"];
	[_NSUserDefaults() setBool:[TPCPreferences securityScopedBookmarksAvailable]	forKey:@"Security -> Scoped Bookmarks Available"];
	
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
