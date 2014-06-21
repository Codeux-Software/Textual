/* ********************************************************************* 
       _____        _               _    ___ ____   ____
      |_   _|___  _| |_ _   _  __ _| |  |_ _|  _ \ / ___|
       | |/ _ \ \/ / __| | | |/ _` | |   | || |_) | |
       | |  __/>  <| |_| |_| | (_| | |   | ||  _ <| |___
       |_|\___/_/\_\\__|\__,_|\__,_|_|  |___|_| \_\\____|

 Copyright (c) 2008 - 2010 Satoshi Nakagawa <psychs AT limechat DOT net>
 Copyright (c) 2010 — 2014 Codeux Software & respective contributors.
     Please see Acknowledgements.pdf for additional information.

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

@implementation TPCPreferences

#pragma mark -
#pragma mark Default Identity

+ (NSString *)defaultNickname
{
	return [RZUserDefaults() objectForKey:@"DefaultIdentity -> Nickname"];
}

+ (NSString *)defaultAwayNickname
{
	return [RZUserDefaults() objectForKey:@"DefaultIdentity -> AwayNickname"];
}

+ (NSString *)defaultUsername
{
	return [RZUserDefaults() objectForKey:@"DefaultIdentity -> Username"];
}

+ (NSString *)defaultRealname
{
	return [RZUserDefaults() objectForKey:@"DefaultIdentity -> Realname"];
}

#pragma mark -
#pragma mark General Preferences

/* There is no specific order to these. */
+ (NSInteger)autojoinMaxChannelJoins
{
	return [RZUserDefaults() integerForKey:@"AutojoinMaximumChannelJoinCount"];
}

+ (NSString *)defaultKickMessage
{
	return [RZUserDefaults() objectForKey:@"ChannelOperatorDefaultLocalization -> Kick Reason"];
}

+ (NSString *)IRCopDefaultKillMessage
{
	return [RZUserDefaults() objectForKey:@"IRCopDefaultLocalizaiton -> Kill Reason"];
}

+ (NSString *)IRCopDefaultGlineMessage
{
	return [RZUserDefaults() objectForKey:@"IRCopDefaultLocalizaiton -> G:Line Reason"];
}

+ (NSString *)IRCopDefaultShunMessage
{
	return [RZUserDefaults() objectForKey:@"IRCopDefaultLocalizaiton -> Shun Reason"];
}

+ (NSString *)masqueradeCTCPVersion
{
	return [RZUserDefaults() objectForKey:@"ApplicationCTCPVersionMasquerade"];
}

+ (BOOL)channelNavigationIsServerSpecific
{
	return [RZUserDefaults() boolForKey:@"ChannelNavigationIsServerSpecific"];
}

+ (BOOL)setAwayOnScreenSleep
{
	return [RZUserDefaults() boolForKey:@"SetAwayOnScreenSleep"];
}

+ (BOOL)invertSidebarColors
{
	if ([themeSettings() forceInvertSidebarColors]) {
		return YES;
	}

	return [RZUserDefaults() boolForKey:@"InvertSidebarColors"];
}

+ (BOOL)hideMainWindowSegmentedController
{
	return [RZUserDefaults() boolForKey:@"DisableMainWindowSegmentedController"];
}

+ (BOOL)autojoinWaitsForNickServ
{
	return [RZUserDefaults() boolForKey:@"AutojoinWaitsForNickservIdentification"];
}

+ (BOOL)logHighlights
{
	return [RZUserDefaults() boolForKey:@"LogHighlights"];
}

+ (BOOL)clearAllOnlyOnActiveServer
{
	return [RZUserDefaults() boolForKey:@"ApplyCommandToAllConnections -> clearall"];
}

+ (BOOL)displayServerMOTD
{
	return [RZUserDefaults() boolForKey:@"DisplayServerMessageOfTheDayOnConnect"];
}

+ (BOOL)copyOnSelect
{
	return [RZUserDefaults() boolForKey:@"CopyTextSelectionOnMouseUp"];
}

+ (BOOL)replyToCTCPRequests
{
	return [RZUserDefaults() boolForKey:@"ReplyUnignoredExternalCTCPRequests"];
}

+ (BOOL)autoAddScrollbackMark
{
	return [RZUserDefaults() boolForKey:@"AutomaticallyAddScrollbackMarker"];
}

+ (BOOL)removeAllFormatting
{
	return [RZUserDefaults() boolForKey:@"RemoveIRCTextFormatting"];
}

+ (BOOL)automaticallyDetectHighlightSpam
{
	return [RZUserDefaults() boolForKey:@"AutomaticallyDetectHighlightSpam"];
}

+ (BOOL)disableNicknameColorHashing
{
	return [RZUserDefaults() boolForKey:@"DisableRemoteNicknameColorHashing"];
}

+ (BOOL)useLargeFontForSidebars
{
	return [RZUserDefaults() boolForKey:@"UseLargeFontForSidebars"];
}

+ (BOOL)conversationTrackingIncludesUserModeSymbol
{
	return [RZUserDefaults() boolForKey:@"ConversationTrackingIncludesUserModeSymbol"];
}

+ (BOOL)rightToLeftFormatting
{
	return [RZUserDefaults() boolForKey:@"RightToLeftTextFormatting"];
}

+ (BOOL)displayDockBadge
{
	return [RZUserDefaults() boolForKey:@"DisplayDockBadges"];
}

+ (BOOL)amsgAllConnections
{
	return [RZUserDefaults() boolForKey:@"ApplyCommandToAllConnections -> amsg"];
}

+ (BOOL)awayAllConnections
{
	return [RZUserDefaults() boolForKey:@"ApplyCommandToAllConnections -> away"];
}

+ (BOOL)giveFocusOnMessageCommand
{
	return [RZUserDefaults() boolForKey:@"FocusSelectionOnMessageCommandExecution"];
}

+ (BOOL)memberListSortFavorsServerStaff
{
	return [RZUserDefaults() boolForKey:@"MemberListSortFavorsServerStaff"];
}

+ (BOOL)postNotificationsWhileInFocus
{
	return [RZUserDefaults() boolForKey:@"PostNotificationsWhileInFocus"];
}

+ (BOOL)automaticallyFilterUnicodeTextSpam
{
	return [RZUserDefaults() boolForKey:@"AutomaticallyFilterUnicodeTextSpam"];
}

+ (BOOL)nickAllConnections
{
	return [RZUserDefaults() boolForKey:@"ApplyCommandToAllConnections -> nick"];
}

+ (BOOL)confirmQuit
{
	return [RZUserDefaults() boolForKey:@"ConfirmApplicationQuit"];
}

+ (BOOL)rememberServerListQueryStates
{
	return [RZUserDefaults() boolForKey:@"ServerListRetainsQueriesBetweenRestarts"];
}

+ (BOOL)rejoinOnKick
{
	return [RZUserDefaults() boolForKey:@"RejoinChannelOnLocalKick"];
}

+ (BOOL)reloadScrollbackOnLaunch
{
	return [RZUserDefaults() boolForKey:@"ReloadScrollbackOnLaunch"];
}

+ (BOOL)autoJoinOnInvite
{
	return [RZUserDefaults() boolForKey:@"AutojoinChannelOnInvite"];
}

+ (BOOL)connectOnDoubleclick
{
	return [RZUserDefaults() boolForKey:@"ServerListDoubleClickConnectServer"];
}

+ (BOOL)disconnectOnDoubleclick
{
	return [RZUserDefaults() boolForKey:@"ServerListDoubleClickDisconnectServer"];
}

+ (BOOL)joinOnDoubleclick
{
	return [RZUserDefaults() boolForKey:@"ServerListDoubleClickJoinChannel"];
}

+ (BOOL)leaveOnDoubleclick
{
	return [RZUserDefaults() boolForKey:@"ServerListDoubleClickLeaveChannel"];
}

+ (BOOL)logToDisk
{
	return [RZUserDefaults() boolForKey:@"LogTranscript"];
}

+ (BOOL)openBrowserInBackground
{
	return [RZUserDefaults() boolForKey:@"OpenClickedLinksInBackgroundBrowser"];
}

+ (BOOL)showInlineImages
{
	return [RZUserDefaults() boolForKey:@"DisplayEventInLogView -> Inline Media"];
}

+ (BOOL)inlineImagesDownloadsAllIgnoringCommonPatterns
{
	return [RZUserDefaults() boolForKey:@"InlineMediaDownloadsAllIgnoringCommonPatterns"];
}

+ (BOOL)showJoinLeave
{
	return [RZUserDefaults() boolForKey:@"DisplayEventInLogView -> Join, Part, Quit"];
}

+ (BOOL)commandReturnSendsMessageAsAction
{
	return [RZUserDefaults() boolForKey:@"CommandReturnSendsMessageAsAction"];
}

+ (BOOL)controlEnterSnedsMessage;
{
	return [RZUserDefaults() boolForKey:@"ControlEnterSendsMessage"];
}

+ (BOOL)displayPublicMessageCountOnDockBadge
{
	return [RZUserDefaults() boolForKey:@"DisplayPublicMessageCountInDockBadge"];
}

+ (BOOL)highlightCurrentNickname
{
	return [RZUserDefaults() boolForKey:@"TrackNicknameHighlightsOfLocalUser"];
}

+ (BOOL)inputHistoryIsChannelSpecific
{
	return [RZUserDefaults() boolForKey:@"SaveInputHistoryPerSelection"];
}

+ (CGFloat)swipeMinimumLength
{
	return [RZUserDefaults() doubleForKey:@"SwipeMinimumLength"];
}

+ (NSInteger)trackUserAwayStatusMaximumChannelSize
{
    return [RZUserDefaults() integerForKey:@"TrackUserAwayStatusMaximumChannelSize"];
}

+ (TXTabKeyAction)tabKeyAction
{
	return (TXTabKeyAction)[RZUserDefaults() integerForKey:@"Keyboard -> Tab Key Action"];
}

+ (TXNicknameHighlightMatchType)highlightMatchingMethod
{
	return (TXNicknameHighlightMatchType)[RZUserDefaults() integerForKey:@"NicknameHighlightMatchingType"];
}

+ (TXUserDoubleClickAction)userDoubleClickOption
{
	return (TXUserDoubleClickAction)[RZUserDefaults() integerForKey:@"UserListDoubleClickAction"];
}

+ (TXNoticeSendLocationType)locationToSendNotices
{
	return (TXNoticeSendLocationType)[RZUserDefaults() integerForKey:@"DestinationOfNonserverNotices"];
}

+ (TXCommandWKeyAction)commandWKeyAction
{
	return (TXCommandWKeyAction)[RZUserDefaults() integerForKey:@"Keyboard -> Command+W Action"];
}

+ (TXHostmaskBanFormat)banFormat
{
	return (TXHostmaskBanFormat)[RZUserDefaults() integerForKey:@"DefaultBanCommandHostmaskFormat"];
}

+ (TVCMainWindowTextViewFontSize)mainTextViewFontSize
{
	return (TVCMainWindowTextViewFontSize)[RZUserDefaults() integerForKey:@"Main Input Text Field -> Font Size"];
}

#pragma mark -
#pragma mark Theme

+ (NSString *)themeName
{
	return [RZUserDefaults() objectForKey:TPCPreferencesThemeNameDefaultsKey];
}

+ (void)setThemeName:(NSString *)value
{
	[RZUserDefaults() setObject:value forKey:TPCPreferencesThemeNameDefaultsKey];
	
	[RZUserDefaults() removeObjectForKey:TPCPreferencesThemeNameMissingLocallyDefaultsKey];
}

+ (void)setThemeNameWithExistenceCheck:(NSString *)value
{
	/* Did it exist anywhere at all? */
	if ([TPCThemeController themeExists:value] == NO) {
		[RZUserDefaults() setBool:YES forKey:TPCPreferencesThemeNameMissingLocallyDefaultsKey];
	} else {
		[TPCPreferences setThemeName:value];
	}
}

+ (NSString *)themeChannelViewFontName
{
	return [RZUserDefaults() objectForKey:TPCPreferencesThemeFontNameDefaultsKey];
}

+ (void)setThemeChannelViewFontName:(NSString *)value
{
	[RZUserDefaults() setObject:value forKey:TPCPreferencesThemeFontNameDefaultsKey];
	
	[RZUserDefaults() removeObjectForKey:TPCPreferencesThemeFontNameMissingLocallyDefaultsKey];
}

+ (void)setThemeChannelViewFontNameWithExistenceCheck:(NSString *)value
{
	if ([NSFont fontIsAvailable:value] == NO) {
		[RZUserDefaults() setBool:YES forKey:TPCPreferencesThemeFontNameMissingLocallyDefaultsKey];
	} else {
		[TPCPreferences setThemeChannelViewFontName:value];
	}
}

+ (double)themeChannelViewFontSize
{
	return [RZUserDefaults() doubleForKey:@"Theme -> Font Size"];
}

+ (void)setThemeChannelViewFontSize:(double)value
{
	[RZUserDefaults() setDouble:value forKey:@"Theme -> Font Size"];
}

+ (NSFont *)themeChannelViewFont
{
	return [NSFont fontWithName:[TPCPreferences themeChannelViewFontName]
						   size:[TPCPreferences themeChannelViewFontSize]];
}

+ (NSString *)themeNicknameFormat
{
	return [RZUserDefaults() objectForKey:@"Theme -> Nickname Format"];
}

+ (NSString *)themeTimestampFormat
{
	return [RZUserDefaults() objectForKey:@"Theme -> Timestamp Format"];
}

+ (double)themeTransparency
{
	return [RZUserDefaults() doubleForKey:@"MainWindowTransparencyLevel"];
}

#pragma mark -
#pragma mark Completion Suffix

+ (NSString *)tabCompletionSuffix
{
	return [RZUserDefaults() objectForKey:@"Keyboard -> Tab Key Completion Suffix"];
}

+ (void)setTabCompletionSuffix:(NSString *)value
{
	[RZUserDefaults() setObject:value forKey:@"Keyboard -> Tab Key Completion Suffix"];
}

#pragma mark -
#pragma mark Inline Image Size

+ (TXUnsignedLongLong)inlineImagesMaxFilesize
{
	NSInteger filesizeTag = [RZUserDefaults() integerForKey:@"inlineImageMaxFilesize"];

	switch (filesizeTag) {
		case 1: { return			(TXUnsignedLongLong)1048576;			} // 1 MB
		case 2: { return			(TXUnsignedLongLong)2097152;			} // 2 MB
		case 3: { return			(TXUnsignedLongLong)3145728;			} // 3 MB
		case 4: { return			(TXUnsignedLongLong)4194304;			} // 4 MB
		case 5: { return			(TXUnsignedLongLong)5242880;			} // 5 MB
		case 6: { return			(TXUnsignedLongLong)10485760;			} // 10 MB
		case 7: { return			(TXUnsignedLongLong)15728640;			} // 15 MB
		case 8: { return			(TXUnsignedLongLong)20971520;			} // 20 MB
		case 9: { return			(TXUnsignedLongLong)52428800;			} // 50 MB
		case 10: { return			(TXUnsignedLongLong)104857600;			} // 100 MB
		default: { return			(TXUnsignedLongLong)104857600;			} // 10 MB
	}
}

+ (NSInteger)inlineImagesMaxWidth
{
	return [RZUserDefaults() integerForKey:@"InlineMediaScalingWidth"];
}

+ (NSInteger)inlineImagesMaxHeight
{
	return [RZUserDefaults() integerForKey:@"InlineMediaMaximumHeight"];
}

+ (void)setInlineImagesMaxWidth:(NSInteger)value
{
	[RZUserDefaults() setInteger:value forKey:@"InlineMediaScalingWidth"];
}

+ (void)setInlineImagesMaxHeight:(NSInteger)value
{
	[RZUserDefaults() setInteger:value forKey:@"InlineMediaMaximumHeight"];
}

#pragma mark -
#pragma mark File Transfers

+ (TXFileTransferRequestReplyAction)fileTransferRequestReplyAction
{
	return [RZUserDefaults() integerForKey:@"File Transfers -> File Transfer Request Reply Action"];
}

+ (TXFileTransferIPAddressDetectionMethod)fileTransferIPAddressDetectionMethod
{
	return [RZUserDefaults() integerForKey:@"File Transfers -> File Transfer IP Address Detection Method"];
}

+ (BOOL)fileTransferRequestsAreReversed
{
	return [RZUserDefaults() boolForKey:@"File Transfers -> File Transfer Requests Use Reverse DCC"];
}

+ (NSInteger)fileTransferPortRangeStart
{
	return [RZUserDefaults() integerForKey:@"File Transfers -> File Transfer Port Range Start"];
}

+ (void)setFileTransferPortRangeStart:(NSInteger)value
{
	[RZUserDefaults() setInteger:value forKey:@"File Transfers -> File Transfer Port Range Start"];
}

+ (NSInteger)fileTransferPortRangeEnd
{
	return [RZUserDefaults() integerForKey:@"File Transfers -> File Transfer Port Range End"];
}

+ (void)setFileTransferPortRangeEnd:(NSInteger)value
{
	[RZUserDefaults() setInteger:value forKey:@"File Transfers -> File Transfer Port Range End"];
}

+ (NSString *)fileTransferManuallyEnteredIPAddress
{
	return [RZUserDefaults() objectForKey:@"File Transfers -> File Transfer Manually Entered IP Address"];
}

#pragma mark -
#pragma mark Max Log Lines

+ (NSInteger)scrollbackLimit
{
	return [RZUserDefaults() integerForKey:@"ScrollbackMaximumLineCount"];
}

+ (void)setScrollbackLimit:(NSInteger)value
{
	[RZUserDefaults() setInteger:value forKey:@"ScrollbackMaximumLineCount"];
}

#pragma mark -
#pragma mark Growl

+ (NSString *)keyForEvent:(TXNotificationType)event
{
	switch (event) {
		case TXNotificationAddressBookMatchType:	{ return @"NotificationType -> Address Book Match";				}
		case TXNotificationChannelMessageType:		{ return @"NotificationType -> Public Message";					}
		case TXNotificationChannelNoticeType:		{ return @"NotificationType -> Public Notice";					}
		case TXNotificationConnectType:				{ return @"NotificationType -> Connected";						}
		case TXNotificationDisconnectType:			{ return @"NotificationType -> Disconnected";					}
		case TXNotificationHighlightType:			{ return @"NotificationType -> Highlight";						}
		case TXNotificationInviteType:				{ return @"NotificationType -> Channel Invitation";				}
		case TXNotificationKickType:				{ return @"NotificationType -> Kicked from Channel";			}
		case TXNotificationNewPrivateMessageType:	{ return @"NotificationType -> Private Message (New)";			}
		case TXNotificationPrivateMessageType:		{ return @"NotificationType -> Private Message";				}
		case TXNotificationPrivateNoticeType:		{ return @"NotificationType -> Private Notice";					}
			
		case TXNotificationFileTransferSendSuccessfulType:		{ return @"NotificationType -> Successful File Transfer (Sending)";			}
		case TXNotificationFileTransferReceiveSuccessfulType:	{ return @"NotificationType -> Successful File Transfer (Receiving)";		}
		case TXNotificationFileTransferSendFailedType:			{ return @"NotificationType -> Failed File Transfer (Sending)";				}
		case TXNotificationFileTransferReceiveFailedType:		{ return @"NotificationType -> Failed File Transfer (Receiving)";			}
		case TXNotificationFileTransferReceiveRequestedType:	{ return @"NotificationType -> File Transfer Request";						}
			
		default: { return nil; }
	}

	return nil;
}

+ (NSString *)soundForEvent:(TXNotificationType)event
{
	NSString *okey = [TPCPreferences keyForEvent:event];

	NSObjectIsEmptyAssertReturn(okey, nil);

	NSString *key = [okey stringByAppendingString:@" -> Sound"];

	return [RZUserDefaults() objectForKey:key];
}

+ (void)setSound:(NSString *)value forEvent:(TXNotificationType)event
{
	NSString *okey = [TPCPreferences keyForEvent:event];

	NSObjectIsEmptyAssert(okey);

	NSString *key = [okey stringByAppendingString:@" -> Sound"];

	[RZUserDefaults() setObject:value forKey:key];
}

+ (BOOL)growlEnabledForEvent:(TXNotificationType)event
{
	NSString *okey = [TPCPreferences keyForEvent:event];

	NSObjectIsEmptyAssertReturn(okey, NO);

	NSString *key = [okey stringByAppendingString:@" -> Enabled"];

	return [RZUserDefaults() boolForKey:key];
}

+ (void)setGrowlEnabled:(BOOL)value forEvent:(TXNotificationType)event
{
	NSString *okey = [TPCPreferences keyForEvent:event];

	NSObjectIsEmptyAssert(okey);

	NSString *key = [okey stringByAppendingString:@" -> Enabled"];

	[RZUserDefaults() setBool:value forKey:key];
}

+ (BOOL)disabledWhileAwayForEvent:(TXNotificationType)event
{
	NSString *okey = [TPCPreferences keyForEvent:event];

	NSObjectIsEmptyAssertReturn(okey, NO);

	NSString *key = [okey stringByAppendingString:@" -> Disable While Away"];

	return [RZUserDefaults() boolForKey:key];
}

+ (void)setDisabledWhileAway:(BOOL)value forEvent:(TXNotificationType)event
{
	NSString *okey = [TPCPreferences keyForEvent:event];

	NSObjectIsEmptyAssert(okey);

	NSString *key = [okey stringByAppendingString:@" -> Disable While Away"];

	[RZUserDefaults() setBool:value forKey:key];
}

+ (BOOL)bounceDockIconForEvent:(TXNotificationType)event
{
    NSString *okey = [TPCPreferences keyForEvent:event];
    
    NSObjectIsEmptyAssertReturn(okey, NO);
    
    NSString *key = [okey stringByAppendingString:@" -> Bounce Dock Icon"];
    
    return [RZUserDefaults() boolForKey:key];
}

+ (void)setBounceDockIcon:(BOOL)value forEvent:(TXNotificationType)event
{
    NSString *okey = [TPCPreferences keyForEvent:event];
    
	NSObjectIsEmptyAssert(okey);
    
	NSString *key = [okey stringByAppendingString:@" -> Bounce Dock Icon"];
    
	[RZUserDefaults() setBool:value forKey:key];
}

+ (BOOL)speakEvent:(TXNotificationType)event
{
	NSString *okey = [TPCPreferences keyForEvent:event];

	NSObjectIsEmptyAssertReturn(okey, NO);

	NSString *key = [okey stringByAppendingString:@" -> Speak"];

	return [RZUserDefaults() boolForKey:key];
}

+ (void)setEventIsSpoken:(BOOL)value forEvent:(TXNotificationType)event
{
	NSString *okey = [TPCPreferences keyForEvent:event];

	NSObjectIsEmptyAssert(okey);

	NSString *key = [okey stringByAppendingString:@" -> Speak"];

	[RZUserDefaults() setBool:value forKey:key];
}

#pragma mark -
#pragma mark World

+ (NSDictionary *)loadWorld
{
	return [RZUserDefaults() objectForKey:IRCWorldControllerDefaultsStorageKey];
}

+ (void)saveWorld:(NSDictionary *)value
{
	[RZUserDefaults() setObject:value forKey:IRCWorldControllerDefaultsStorageKey];
}

#pragma mark -
#pragma mark Keywords

static NSMutableArray *matchKeywords = nil;
static NSMutableArray *excludeKeywords = nil;

+ (void)loadMatchKeywords
{
	if (matchKeywords) {
		[matchKeywords removeAllObjects];
	} else {
		matchKeywords = [NSMutableArray new];
	}

	NSArray *ary = [RZUserDefaults() objectForKey:@"Highlight List -> Primary Matches"];

	for (NSDictionary *e in ary) {
		NSString *s = e[@"string"];

		NSObjectIsEmptyAssertLoopContinue(s);

		[matchKeywords addObject:s];
	}
}

+ (void)loadExcludeKeywords
{
	if (excludeKeywords) {
		[excludeKeywords removeAllObjects];
	} else {
		excludeKeywords = [NSMutableArray new];
	}

	NSArray *ary = [RZUserDefaults() objectForKey:@"Highlight List -> Excluded Matches"];

	for (NSDictionary *e in ary) {
		NSString *s = e[@"string"];

		NSObjectIsEmptyAssertLoopContinue(s);

		[excludeKeywords addObject:s];
	}
}

+ (void)cleanUpKeywords:(NSString *)key
{
	NSArray *src = [RZUserDefaults() objectForKey:key];

	NSMutableArray *ary = [NSMutableArray array];

	for (NSDictionary *e in src) {
		NSString *s = e[@"string"];

		NSObjectIsEmptyAssertLoopContinue(s);

		[ary addObject:s];
	}

	[ary sortUsingSelector:@selector(caseInsensitiveCompare:)];

	NSMutableArray *saveAry = [NSMutableArray array];

	for (NSString *s in ary) {
		[saveAry addObject:[@{@"string" : s} mutableCopy]];
	}

	[RZUserDefaults() setObject:saveAry forKey:key];
}

+ (void)cleanUpHighlightKeywords
{
	[TPCPreferences cleanUpKeywords:@"Highlight List -> Primary Matches"];
	[TPCPreferences cleanUpKeywords:@"Highlight List -> Excluded Matches"];
}

+ (NSArray *)highlightMatchKeywords
{
	return matchKeywords;
}

+ (NSArray *)highlightExcludeKeywords
{
	return excludeKeywords;
}

#pragma mark -
#pragma mark Key-Value Observing

+ (void)observeValueForKeyPath:(NSString *)key ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	if ([key isEqualToString:@"Highlight List -> Primary Matches"]) {
		[TPCPreferences loadMatchKeywords];
	} else if ([key isEqualToString:@"Highlight List -> Excluded Matches"]) {
		[TPCPreferences loadExcludeKeywords];
	}
}

#pragma mark -
#pragma mark Initialization

+ (NSDictionary *)defaultPreferences
{
	NSMutableDictionary *d = [NSMutableDictionary dictionary];
	
#ifdef TEXTUAL_BUILT_WITH_ICLOUD_SUPPORT
	d[TPCPreferencesCloudSyncKeyValueStoreServicesDefaultsKey]					= @(NO);
	d[TPCPreferencesCloudSyncKeyValueStoreServicesLimitedToServersDefaultsKey]	= @(NO);
#endif
	
	d[@"AutomaticallyAddScrollbackMarker"]				= @(YES);
	d[@"AutomaticallyDetectHighlightSpam"]				= @(YES);
	d[@"ChannelNavigationIsServerSpecific"]				= @(YES);
	d[@"CommandReturnSendsMessageAsAction"]				= @(YES);
	d[@"ConfirmApplicationQuit"]						= @(YES);
	d[@"DisplayDockBadges"]								= @(YES);
	d[@"DisplayEventInLogView -> Join, Part, Quit"]		= @(YES);
	d[@"DisplayServerMessageOfTheDayOnConnect"]			= @(YES);
	d[@"DisplayUserListNoModeSymbol"]					= @(YES);
	d[@"FocusSelectionOnMessageCommandExecution"]		= @(YES);
	d[@"LogHighlights"]									= @(YES);
	d[@"PostNotificationsWhileInFocus"]					= @(YES);
	d[@"ReloadScrollbackOnLaunch"]						= @(YES);
	d[@"ReplyUnignoredExternalCTCPRequests"]			= @(YES);
	d[@"TrackNicknameHighlightsOfLocalUser"]			= @(YES);
	d[@"WebKitDeveloperExtras"]							= @(YES);
	
	/* Settings for the NSTextView context menu. */
	d[@"TextFieldAutomaticSpellCheck"]					= @(YES);
	d[@"TextFieldAutomaticGrammarCheck"]				= @(YES);
	d[@"TextFieldAutomaticSpellCorrection"]				= @(NO);
	d[@"TextFieldSmartCopyPaste"]						= @(YES);
	d[@"TextFieldTextReplacement"]						= @(YES);
	
	/* This controls the two-finger swipe sensitivity. The lower it is, the more
	 sensitive the swipe left/right detection is. The higher it is, the less
	 sensitive the swipe detection is. <= 0 means off. */
	d[@"SwipeMinimumLength"]							= @(30);
	
	d[@"NotificationType -> Highlight -> Enabled"]				= @(YES);
	d[@"NotificationType -> Highlight -> Sound"]				= @"Glass";
	d[@"NotificationType -> Highlight -> Bounce Dock Icon"]		= @(YES);
	
	d[@"NotificationType -> Private Message (New) -> Enabled"]			= @(YES);
	d[@"NotificationType -> Private Message (New) -> Sound"]			= @"Submarine";
	d[@"NotificationType -> Private Message (New) -> Bounce Dock Icon"] = @(YES);
	
	d[@"NotificationType -> Private Message -> Enabled"]			= @(YES);
	d[@"NotificationType -> Private Message -> Sound"]				= @"Submarine";
	d[@"NotificationType -> Private Message -> Bounce Dock Icon"]	= @(YES);
	
	d[@"NotificationType -> Address Book Match -> Enabled"]		= @(YES);
	d[@"NotificationType -> Private Message (New) -> Enabled"]	= @(YES);
	
	d[@"NotificationType -> Successful File Transfer (Sending) -> Enabled"]		= @(YES);
	d[@"NotificationType -> Successful File Transfer (Receiving) -> Enabled"]	= @(YES);
	d[@"NotificationType -> Failed File Transfer (Sending) -> Enabled"]			= @(YES);
	d[@"NotificationType -> Failed File Transfer (Receiving) -> Enabled"]		= @(YES);
	d[@"NotificationType -> File Transfer Request -> Enabled"]					= @(YES);
	
	d[@"NotificationType -> Successful File Transfer (Sending) -> Bounce Dock Icon"]	= @(YES);
	d[@"NotificationType -> Successful File Transfer (Receiving) -> Bounce Dock Icon"]	= @(YES);
	d[@"NotificationType -> Failed File Transfer (Sending) -> Bounce Dock Icon"]		= @(YES);
	d[@"NotificationType -> Failed File Transfer (Receiving) -> Bounce Dock Icon"]		= @(YES);
	d[@"NotificationType -> File Transfer Request -> Bounce Dock Icon"]					= @(YES);
	
	d[@"NotificationType -> File Transfer Request -> Sound"] = @"Blow"; // u wut m8
	
	d[@"DefaultIdentity -> Nickname"] = @"Guest";
	d[@"DefaultIdentity -> AwayNickname"] = NSStringEmptyPlaceholder;
	d[@"DefaultIdentity -> Username"] = @"textual";
	d[@"DefaultIdentity -> Realname"] = @"Textual User";
	
	d[@"IRCopDefaultLocalizaiton -> Shun Reason"]	= BLS(1030);
	d[@"IRCopDefaultLocalizaiton -> Kill Reason"]	= BLS(1029);
	d[@"IRCopDefaultLocalizaiton -> G:Line Reason"] = BLS(1027);
	
	TVCMemberList *memberList = [mainWindow() memberList];
	
	d[@"User List Mode Badge Colors —> +y"] = [NSArchiver archivedDataWithRootObject:[memberList userMarkBadgeBackgroundColor_YDefault]];
	d[@"User List Mode Badge Colors —> +q"] = [NSArchiver archivedDataWithRootObject:[memberList userMarkBadgeBackgroundColor_QDefault]];
	d[@"User List Mode Badge Colors —> +a"] = [NSArchiver archivedDataWithRootObject:[memberList userMarkBadgeBackgroundColor_ADefault]];
	d[@"User List Mode Badge Colors —> +o"] = [NSArchiver archivedDataWithRootObject:[memberList userMarkBadgeBackgroundColor_ODefault]];
	d[@"User List Mode Badge Colors —> +h"] = [NSArchiver archivedDataWithRootObject:[memberList userMarkBadgeBackgroundColor_HDefault]];
	d[@"User List Mode Badge Colors —> +v"] = [NSArchiver archivedDataWithRootObject:[memberList userMarkBadgeBackgroundColor_VDefault]];
	
	d[@"ChannelOperatorDefaultLocalization -> Kick Reason"] = BLS(1028);
	
	d[TPCPreferencesThemeNameDefaultsKey]				= TXDefaultTextualChannelViewStyle;
	d[TPCPreferencesThemeFontNameDefaultsKey]			= TXDefaultTextualChannelViewFont;

	d[@"Theme -> Nickname Format"]						= TVCLogLineUndefinedNicknameFormat;
	d[@"Theme -> Timestamp Format"]						= TXDefaultTextualTimestampFormat;
	
	d[@"inlineImageMaxFilesize"]				= @(2);
    d[@"TrackUserAwayStatusMaximumChannelSize"] = @(0);
	d[@"AutojoinMaximumChannelJoinCount"]		= @(2);
	d[@"ScrollbackMaximumLineCount"]			= @(300);
	d[@"InlineMediaScalingWidth"]				= @(300);
	d[@"InlineMediaMaximumHeight"]				= @(0);
	
	d[@"Keyboard -> Tab Key Action"]			= @(TXTabKeyNickCompleteAction);
	d[@"Keyboard -> Command+W Action"]			= @(TXCommandWKeyCloseWindowAction);
	d[@"Main Input Text Field -> Font Size"]	= @(TVCMainWindowTextViewFontNormalSize);
	d[@"NicknameHighlightMatchingType"]			= @(TXNicknameHighlightExactMatchType);
	d[@"DefaultBanCommandHostmaskFormat"]		= @(TXHostmaskBanWHAINNFormat);
	d[@"DestinationOfNonserverNotices"]			= @(TXNoticeSendServerConsoleType);
	d[@"UserListDoubleClickAction"]				= @(TXUserDoubleClickPrivateMessageAction);
	
	d[@"File Transfers -> File Transfer Request Reply Action"] = @(TXFileTransferRequestReplyOpenDialogAction);
	d[@"File Transfers -> File Transfer IP Address Detection Method"] = @(TXFileTransferIPAddressAutomaticDetectionMethod);

	d[@"File Transfers -> File Transfer Port Range Start"] = @(TXDefaultFileTransferPortRangeStart);
	d[@"File Transfers -> File Transfer Port Range End"] = @(TXDefaultFileTransferPortRangeEnd);
	
	d[@"MainWindowTransparencyLevel"]		= @(1.0);
	d[@"Theme -> Font Size"]				= @(12.0);
	
	return d;
}

+ (void)initPreferences
{
	[TPCApplicationInfo updateApplicationRunCount];

#ifndef TEXTUAL_TRIAL_BINARY
	NSInteger numberOfRuns = [TPCApplicationInfo applicationRunCount];

	if (numberOfRuns >= 2) {
		[TPCApplicationInfo defaultIRCClientPrompt:NO];
	}
#endif

	// ====================================================== //

	NSDictionary *d = [TPCPreferences defaultPreferences];

	// ====================================================== //

	[RZUserDefaults() registerDefaults:d];

	[RZUserDefaults() addObserver:(id)self forKeyPath:@"Highlight List -> Primary Matches"  options:NSKeyValueObservingOptionNew context:NULL];
	[RZUserDefaults() addObserver:(id)self forKeyPath:@"Highlight List -> Excluded Matches" options:NSKeyValueObservingOptionNew context:NULL];

	[TPCPreferences loadMatchKeywords];
	[TPCPreferences loadExcludeKeywords];
	
	[IRCCommandIndex populateCommandIndex];

	/* Sandbox Check */

	[RZUserDefaults() setBool:[TPCApplicationInfo sandboxEnabled]							forKey:@"Security -> Sandbox Enabled"];

	[RZUserDefaults() setBool:[CSFWSystemInformation featureAvailableToOSXLion]				forKey:@"System —> Running Mac OS Lion Or Newer"];
	[RZUserDefaults() setBool:[CSFWSystemInformation featureAvailableToOSXMountainLion]		forKey:@"System —> Running Mac OS Mountain Lion Or Newer"];
	[RZUserDefaults() setBool:[CSFWSystemInformation featureAvailableToOSXMavericks]		forKey:@"System —> Running Mac OS Mavericks Or Newer"];
	[RZUserDefaults() setBool:[CSFWSystemInformation featureAvailableToOSXYosemite]			forKey:@"System —> Running Mac OS Yosemite Or Newer"];
	
#ifndef TEXTUAL_BUILT_WITH_ICLOUD_SUPPORT
	[RZUserDefaults() setBool:NO forKey:@"System —> Built with iCloud Support"];
#else
	if ([CSFWSystemInformation featureAvailableToOSXMountainLion]) {
		[RZUserDefaults() setBool:YES forKey:@"System —> Built with iCloud Support"];
	} else {
		[RZUserDefaults() setBool:NO forKey:@"System —> Built with iCloud Support"];
	}
#endif
	
	/* Validate some stuff. */
	(void)[TPCPreferences performValidationForKeyValues:YES];

	/* Setup loggin. */
	[TPCPathInfo startUsingLogLocationSecurityScopedBookmark];
}

#pragma mark -
#pragma mark NSTextView Preferences

+ (BOOL)textFieldAutomaticSpellCheck
{
	return [RZUserDefaults() boolForKey:@"TextFieldAutomaticSpellCheck"];
}

+ (void)setTextFieldAutomaticSpellCheck:(BOOL)value
{
	if (NSDissimilarObjects(value, [TPCPreferences textFieldAutomaticSpellCheck])) {
		[RZUserDefaults() setBool:value forKey:@"TextFieldAutomaticSpellCheck"];
	}
}

+ (BOOL)textFieldAutomaticGrammarCheck
{
	return [RZUserDefaults() boolForKey:@"TextFieldAutomaticGrammarCheck"];
}

+ (void)setTextFieldAutomaticGrammarCheck:(BOOL)value
{
	if (NSDissimilarObjects(value, [TPCPreferences textFieldAutomaticGrammarCheck])) {
		[RZUserDefaults() setBool:value forKey:@"TextFieldAutomaticGrammarCheck"];
	}
}

+ (BOOL)textFieldAutomaticSpellCorrection
{
	return [RZUserDefaults() boolForKey:@"TextFieldAutomaticSpellCorrection"];
}

+ (void)setTextFieldAutomaticSpellCorrection:(BOOL)value
{
	if (NSDissimilarObjects(value, [TPCPreferences textFieldAutomaticSpellCorrection])) {
		[RZUserDefaults() setBool:value forKey:@"TextFieldAutomaticSpellCorrection"];
	}
}

+ (BOOL)textFieldSmartCopyPaste
{
	return [RZUserDefaults() boolForKey:@"TextFieldSmartCopyPaste"];
}

+ (void)setTextFieldSmartCopyPaste:(BOOL)value
{
	if (NSDissimilarObjects(value, [TPCPreferences textFieldSmartCopyPaste])) {
		[RZUserDefaults() setBool:value forKey:@"TextFieldSmartCopyPaste"];
	}
}

+ (BOOL)textFieldSmartQuotes
{
	return [RZUserDefaults() boolForKey:@"TextFieldSmartQuotes"];
}

+ (void)setTextFieldSmartQuotes:(BOOL)value
{
	if (NSDissimilarObjects(value, [TPCPreferences textFieldSmartQuotes])) {
		[RZUserDefaults() setBool:value forKey:@"TextFieldSmartQuotes"];
	}
}

+ (BOOL)textFieldSmartDashes
{
	return [RZUserDefaults() boolForKey:@"TextFieldSmartDashes"];
}

+ (void)setTextFieldSmartDashes:(BOOL)value
{
	if (NSDissimilarObjects(value, [TPCPreferences textFieldSmartDashes])) {
		[RZUserDefaults() setBool:value forKey:@"TextFieldSmartDashes"];
	}
}

+ (BOOL)textFieldSmartLinks
{
	return [RZUserDefaults() boolForKey:@"TextFieldSmartLinks"];
}

+ (void)setTextFieldSmartLinks:(BOOL)value
{
	if (NSDissimilarObjects(value, [TPCPreferences textFieldSmartLinks])) {
		[RZUserDefaults() setBool:value forKey:@"TextFieldSmartLinks"];
	}
}

+ (BOOL)textFieldDataDetectors
{
	return [RZUserDefaults() boolForKey:@"TextFieldDataDetectors"];
}

+ (void)setTextFieldDataDetectors:(BOOL)value
{
	if (NSDissimilarObjects(value, [TPCPreferences textFieldDataDetectors])) {
		[RZUserDefaults() setBool:value forKey:@"TextFieldDataDetectors"];
	}
}

+ (BOOL)textFieldTextReplacement
{
	return [RZUserDefaults() boolForKey:@"TextFieldTextReplacement"];
}

+ (void)setTextFieldTextReplacement:(BOOL)value
{
	if (NSDissimilarObjects(value, [TPCPreferences textFieldTextReplacement])) {
		[RZUserDefaults() setBool:value forKey:@"TextFieldTextReplacement"];
	}
}

@end
