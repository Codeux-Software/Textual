/* ********************************************************************* 
                  _____         _               _
                 |_   _|____  _| |_ _   _  __ _| |
                   | |/ _ \ \/ / __| | | |/ _` | |
                   | |  __/>  <| |_| |_| | (_| | |
                   |_|\___/_/\_\\__|\__,_|\__,_|_|

 Copyright (c) 2008 - 2010 Satoshi Nakagawa <psychs AT limechat DOT net>
 Copyright (c) 2010 - 2015 Codeux Software, LLC & respective contributors.
        Please see Acknowledgements.pdf for additional information.

 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions
 are met:

    * Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the
      documentation and/or other materials provided with the distribution.
    * Neither the name of Textual and/or "Codeux Software, LLC", nor the 
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

#import "TPCPreferencesUserDefaultsMigrate.h"

NS_ASSUME_NONNULL_BEGIN

NSString * const TPCPreferencesThemeNameDefaultsKey				= @"Theme -> Name";
NSString * const TPCPreferencesThemeFontNameDefaultsKey			= @"Theme -> Font Name";

NSInteger const TPCPreferencesDictionaryVersion		= 100;

@implementation TPCPreferences

#pragma mark -
#pragma mark Default Identity

+ (NSString *)defaultNicknamePrefix
{
	return [[TPCPreferences defaultPreferences] objectForKey:@"DefaultIdentity -> Nickname"];
}

+ (void)populateDefaultNickname
{
	/* On large IRC networks using "Guest" as the default nickname may create 
	 conflicts as nickname guesses are exhausted while pending underscores to
	 the value looking for the next available match. To help with this, a 
	 random number is appended to the end of the default nickname. */

	NSString *defaultNickname = [[TPCPreferences defaultPreferences] stringForKey:@"DefaultIdentity -> Nickname"];

	NSString *nickname = [NSString stringWithFormat:@"%@%lu", defaultNickname, TXRandomNumber(100)];

	[RZUserDefaults() registerDefaults:@{@"DefaultIdentity -> Nickname" : nickname}];
}

+ (NSString *)defaultNickname
{
	return [RZUserDefaults() objectForKey:@"DefaultIdentity -> Nickname"];
}

+ (nullable NSString *)defaultAwayNickname
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

+ (BOOL)appendReasonToCommonIRCopCommands
{
	return [RZUserDefaults() boolForKey:@"AutomaticallyAppendReasonToCommonIRCopCommands"];
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

+ (nullable NSString *)masqueradeCTCPVersion
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

+ (BOOL)disableSidebarTranslucency
{
	return [RZUserDefaults() boolForKey:@"DisableSidebarTranslucency"];
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

#if TEXTUAL_BUILT_WITH_ADVANCED_ENCRYPTION == 1
+ (BOOL)textEncryptionIsOpportunistic
{
	return [RZUserDefaults() boolForKey:@"Off-the-Record Messaging -> Automatically Enable Service"];
}

+ (BOOL)textEncryptionIsRequired
{
	return [RZUserDefaults() boolForKey:@"Off-the-Record Messaging -> Require Encryption"];
}

+ (BOOL)textEncryptionIsEnabled
{
	return [RZUserDefaults() boolForKey:@"Off-the-Record Messaging -> Enable Encryption"];
}
#endif

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

#if TEXTUAL_BUILT_WITH_SPARKLE_ENABLED == 1
+ (void)setReceiveBetaUpdates:(BOOL)receiveBetaUpdates
{
	[RZUserDefaults() setBool:receiveBetaUpdates forKey:@"ReceiveBetaUpdates"];
}

+ (BOOL)receiveBetaUpdates
{
	return [RZUserDefaults() boolForKey:@"ReceiveBetaUpdates"];
}
#endif

+ (BOOL)disableNicknameColorHashing
{
	return [RZUserDefaults() boolForKey:@"DisableRemoteNicknameColorHashing"];
}

+ (BOOL)nicknameColorHashingComputesRGBValue
{
	return [RZUserDefaults() boolForKey:@"NicknameColorHashingComputesRGBValue"];
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

+ (BOOL)memberListUpdatesUserInfoPopoverOnScroll
{
	return [RZUserDefaults() boolForKey:@"MemberListUpdatesUserInfoPopoverOnScroll"];
}

+ (BOOL)memberListDisplayNoModeSymbol
{
	return [RZUserDefaults() boolForKey:@"DisplayUserListNoModeSymbol"];
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

+ (BOOL)logToDiskIsEnabled
{
	return ([RZUserDefaults() boolForKey:@"LogTranscript"] && [TPCPathInfo logFileFolderLocation]);
}

+ (BOOL)openBrowserInBackground
{
	return [RZUserDefaults() boolForKey:@"OpenClickedLinksInBackgroundBrowser"];
}

+ (BOOL)showInlineImages
{
	return [RZUserDefaults() boolForKey:@"DisplayEventInLogView -> Inline Media"];
}

+ (BOOL)showJoinLeave
{
	return [RZUserDefaults() boolForKey:@"DisplayEventInLogView -> Join, Part, Quit"];
}

+ (BOOL)commandReturnSendsMessageAsAction
{
	return [RZUserDefaults() boolForKey:@"CommandReturnSendsMessageAsAction"];
}

+ (BOOL)controlEnterSnedsMessage
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
	return (TXCommandWKeyAction)[RZUserDefaults() integerForKey:@"Keyboard -> Command+W Key Action"];
}

+ (TXHostmaskBanFormat)banFormat
{
	return (TXHostmaskBanFormat)[RZUserDefaults() integerForKey:@"DefaultBanCommandHostmaskFormat"];
}

+ (TVCMainWindowTextViewFontSize)mainTextViewFontSize
{
	return (TVCMainWindowTextViewFontSize)[RZUserDefaults() integerForKey:@"Main Input Text Field -> Font Size"];
}

+ (BOOL)focusMainTextViewOnSelectionChange
{
	return [RZUserDefaults() boolForKey:@"Main Input Text Field -> Focus When Changing Views"];
}

#pragma mark -
#pragma mark Developer Mode

+ (void)setDeveloperModeEnabled:(BOOL)developerModeEnabled
{
	[RZUserDefaults() setBool:developerModeEnabled forKey:@"TextualDeveloperEnvironment"];
}

+ (BOOL)developerModeEnabled
{
	return [RZUserDefaults() boolForKey:@"TextualDeveloperEnvironment"];
}

#pragma mark -
#pragma mark Theme

+ (BOOL)invertSidebarColorsPreferenceUserConfigurable
{
	return [RZUserDefaults() boolForKey:@"Theme -> Invert Sidebar Colors Preference Enabled"];
}

+ (void)setInvertSidebarColorsPreferenceUserConfigurable:(BOOL)invertSidebarColorsPreferenceUserConfigurable
{
	[RZUserDefaults() setBool:invertSidebarColorsPreferenceUserConfigurable forKey:@"Theme -> Invert Sidebar Colors Preference Enabled"];
}

+ (void)setInvertSidebarColors:(BOOL)invertSidebarColors
{
	[RZUserDefaults() boolForKey:@"InvertSidebarColors"];
}

+ (BOOL)invertSidebarColors
{
	if ([themeSettings() invertSidebarColors]) {
		return YES;
	}

	return [RZUserDefaults() boolForKey:@"InvertSidebarColors"];
}

+ (NSString *)themeNameDefault
{
	return [[TPCPreferences defaultPreferences] objectForKey:TPCPreferencesThemeNameDefaultsKey];
}

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

+ (NSString *)themeChannelViewFontNameDefault
{
	return [[TPCPreferences defaultPreferences] objectForKey:TPCPreferencesThemeFontNameDefaultsKey];
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

+ (BOOL)themeChannelViewFontPreferenceUserConfigurable
{
	return [RZUserDefaults() boolForKey:@"Theme -> Channel Font Preference Enabled"];
}

+ (void)setThemeChannelViewFontPreferenceUserConfigurable:(BOOL)themeChannelViewFontPreferenceUserConfigurable
{
	[RZUserDefaults() setBool:themeChannelViewFontPreferenceUserConfigurable forKey:@"Theme -> Channel Font Preference Enabled"];
}

+ (NSString *)themeNicknameFormatDefault
{
	return [[TPCPreferences defaultPreferences] objectForKey:@"Theme -> Nickname Format"];
}

+ (NSString *)themeNicknameFormat
{
	return [RZUserDefaults() objectForKey:@"Theme -> Nickname Format"];
}

+ (BOOL)themeNicknameFormatPreferenceUserConfigurable
{
	return [RZUserDefaults() boolForKey:@"Timestamp Format Preference Enabled"];
}

+ (void)setThemeNicknameFormatPreferenceUserConfigurable:(BOOL)themeNicknameFormatPreferenceUserConfigurable
{
	[RZUserDefaults() setBool:themeNicknameFormatPreferenceUserConfigurable forKey:@"Theme -> Nickname Format Preference Enabled"];
}

+ (NSString *)themeTimestampFormatDefault
{
	return [[TPCPreferences defaultPreferences] objectForKey:@"Theme -> Timestamp Format"];
}

+ (NSString *)themeTimestampFormat
{
	return [RZUserDefaults() objectForKey:@"Theme -> Timestamp Format"];
}

+ (BOOL)themeTimestampFormatPreferenceUserConfigurable
{
	return [RZUserDefaults() boolForKey:@"Timestamp Format Preference Enabled"];
}

+ (void)setThemeTimestampFormatPreferenceUserConfigurable:(BOOL)themeTimestampFormatPreferenceUserConfigurable
{
	[RZUserDefaults() setBool:themeTimestampFormatPreferenceUserConfigurable forKey:@"Timestamp Format Preference Enabled"];
}

+ (double)mainWindowTransparency
{
	return [RZUserDefaults() doubleForKey:@"MainWindowTransparencyLevel"];
}

+ (BOOL)automaticallyReloadCustomThemesWhenTheyChange
{
	return [RZUserDefaults() boolForKey:@"AutomaticallyReloadCustomThemesWhenTheyChange"];
}

+ (BOOL)webKit2Enabled
{
	BOOL canUseWebKit2 = [RZUserDefaults() boolForKey:@"UsesWebKit2WhenAvailable"];

	if (canUseWebKit2 == NO) {
		return NO;
	}

	if ([XRSystemInformation isUsingOSXElCapitanOrLater]) {
		return YES;
	}

	return NO;
}

+ (BOOL)webKit2ProcessPoolSizeLimited
{
	return [RZUserDefaults() boolForKey:@"WKProcessPoolSizeIsLimited"];
}

+ (BOOL)themeChannelViewUsesCustomScrollers
{
	return ([RZUserDefaults() boolForKey:@"WebViewDoNotUsesCustomScrollers"] == NO);
}

#pragma mark -
#pragma mark Completion Suffix

+ (nullable NSString *)tabCompletionSuffix
{
	return [RZUserDefaults() objectForKey:@"Keyboard -> Tab Key Completion Suffix"];
}

+ (void)setTabCompletionSuffix:(NSString *)value
{
	[RZUserDefaults() setObject:value forKey:@"Keyboard -> Tab Key Completion Suffix"];
}

+ (BOOL)tabCompletionDoNotAppendWhitespace
{
	return [RZUserDefaults() boolForKey:@"Tab Completion -> Do Not Use Whitespace for Missing Completion Suffix"];
}

+ (BOOL)tabCompletionCutForwardToFirstWhitespace
{
	return [RZUserDefaults() boolForKey:@"Tab Completion -> Completion Suffix Cut Forward Until Space"];
}

#pragma mark -
#pragma mark Inline Image Size

+ (TXUnsignedLongLong)inlineImagesMaxFilesize
{
	NSInteger filesizeTag = [RZUserDefaults() integerForKey:@"InlineMediaMaximumFilesize"];

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
		default: { return			(TXUnsignedLongLong)2097152;			} // 2 MB
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

+ (BOOL)fileTransfersPreventIdleSystemSleep
{
	return [RZUserDefaults() boolForKey:@"File Transfers -> Idle System Sleep Prevented During File Transfer"];
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

+ (nullable NSString *)fileTransferManuallyEnteredIPAddress
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
	}

	return nil;
}

+ (nullable NSString *)soundForEvent:(TXNotificationType)event
{
	NSString *okey = [TPCPreferences keyForEvent:event];

	PointerIsEmptyAssertReturn(okey, nil);

	NSString *key = [okey stringByAppendingString:@" -> Sound"];

	return [RZUserDefaults() objectForKey:key];
}

+ (void)setSound:(NSString *)value forEvent:(TXNotificationType)event
{
	NSString *okey = [TPCPreferences keyForEvent:event];

	PointerIsEmptyAssert(okey);

	NSString *key = [okey stringByAppendingString:@" -> Sound"];

	[RZUserDefaults() setObject:value forKey:key];
}

+ (BOOL)growlEnabledForEvent:(TXNotificationType)event
{
	NSString *okey = [TPCPreferences keyForEvent:event];

	PointerIsEmptyAssertReturn(okey, NO);

	NSString *key = [okey stringByAppendingString:@" -> Enabled"];

	return [RZUserDefaults() boolForKey:key];
}

+ (void)setGrowlEnabled:(BOOL)value forEvent:(TXNotificationType)event
{
	NSString *okey = [TPCPreferences keyForEvent:event];

	PointerIsEmptyAssert(okey);

	NSString *key = [okey stringByAppendingString:@" -> Enabled"];

	[RZUserDefaults() setBool:value forKey:key];
}

+ (BOOL)disabledWhileAwayForEvent:(TXNotificationType)event
{
	NSString *okey = [TPCPreferences keyForEvent:event];

	PointerIsEmptyAssertReturn(okey, NO);

	NSString *key = [okey stringByAppendingString:@" -> Disable While Away"];

	return [RZUserDefaults() boolForKey:key];
}

+ (void)setDisabledWhileAway:(BOOL)value forEvent:(TXNotificationType)event
{
	NSString *okey = [TPCPreferences keyForEvent:event];

	PointerIsEmptyAssert(okey);

	NSString *key = [okey stringByAppendingString:@" -> Disable While Away"];

	[RZUserDefaults() setBool:value forKey:key];
}

+ (BOOL)bounceDockIconForEvent:(TXNotificationType)event
{
    NSString *okey = [TPCPreferences keyForEvent:event];
    
    PointerIsEmptyAssertReturn(okey, NO);
    
    NSString *key = [okey stringByAppendingString:@" -> Bounce Dock Icon"];
    
    return [RZUserDefaults() boolForKey:key];
}

+ (void)setBounceDockIcon:(BOOL)value forEvent:(TXNotificationType)event
{
    NSString *okey = [TPCPreferences keyForEvent:event];
    
	PointerIsEmptyAssert(okey);
    
	NSString *key = [okey stringByAppendingString:@" -> Bounce Dock Icon"];
    
	[RZUserDefaults() setBool:value forKey:key];
}

+ (BOOL)bounceDockIconRepeatedlyForEvent:(TXNotificationType)event
{
	NSString *okey = [TPCPreferences keyForEvent:event];

	PointerIsEmptyAssertReturn(okey, NO);

	NSString *key = [okey stringByAppendingString:@" -> Bounce Dock Icon Repeatedly"];

	return [RZUserDefaults() boolForKey:key];
}

+ (void)setBounceDockIconRepeatedly:(BOOL)value forEvent:(TXNotificationType)event
{
	NSString *okey = [TPCPreferences keyForEvent:event];

	PointerIsEmptyAssert(okey);

	NSString *key = [okey stringByAppendingString:@" -> Bounce Dock Icon Repeatedly"];

	[RZUserDefaults() setBool:value forKey:key];
}

+ (BOOL)speakEvent:(TXNotificationType)event
{
	NSString *okey = [TPCPreferences keyForEvent:event];

	PointerIsEmptyAssertReturn(okey, NO);

	NSString *key = [okey stringByAppendingString:@" -> Speak"];

	return [RZUserDefaults() boolForKey:key];
}

+ (void)setEventIsSpoken:(BOOL)value forEvent:(TXNotificationType)event
{
	NSString *okey = [TPCPreferences keyForEvent:event];

	PointerIsEmptyAssert(okey);

	NSString *key = [okey stringByAppendingString:@" -> Speak"];

	[RZUserDefaults() setBool:value forKey:key];
}

#pragma mark -
#pragma mark World

+ (nullable NSDictionary<NSString *, id> *)loadWorld
{
	return [RZUserDefaults() objectForKey:IRCWorldControllerDefaultsStorageKey];
}

+ (void)saveWorld:(nullable NSDictionary<NSString *, id> *)value
{
	[RZUserDefaults() setObject:value forKey:IRCWorldControllerDefaultsStorageKey];
}

#pragma mark -
#pragma mark Keywords

static NSMutableArray<NSString *> *matchKeywords = nil;
static NSMutableArray<NSString *> *excludeKeywords = nil;

+ (void)loadMatchKeywords
{
	if (matchKeywords) {
		[matchKeywords removeAllObjects];
	} else {
		matchKeywords = [NSMutableArray new];
	}

	NSArray<NSDictionary *> *ary = [RZUserDefaults() objectForKey:@"Highlight List -> Primary Matches"];

	for (NSDictionary<NSString *, NSString *> *e in ary) {
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

	NSArray<NSDictionary *> *ary = [RZUserDefaults() objectForKey:@"Highlight List -> Excluded Matches"];

	for (NSDictionary<NSString *, NSString *> *e in ary) {
		NSString *s = e[@"string"];

		NSObjectIsEmptyAssertLoopContinue(s);

		[excludeKeywords addObject:s];
	}
}

+ (void)cleanUpKeywords:(NSString *)key
{
	NSArray<NSDictionary *> *src = [RZUserDefaults() objectForKey:key];

	NSMutableArray<NSString *> *ary = [NSMutableArray array];

	for (NSDictionary<NSString *, NSString *> *e in src) {
		NSString *s = e[@"string"];

		NSObjectIsEmptyAssertLoopContinue(s);

		[ary addObject:s];
	}

	[ary sortUsingSelector:@selector(caseInsensitiveCompare:)];

	NSMutableArray<NSDictionary *> *saveAry = [NSMutableArray array];

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

+ (nullable NSArray<NSString *> *)highlightMatchKeywords
{
	return matchKeywords;
}

+ (nullable NSArray<NSString *> *)highlightExcludeKeywords
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

+ (NSDictionary<NSString *, id> *)defaultPreferences
{
	return [[NSUserDefaults standardUserDefaults] volatileDomainForName:NSRegistrationDomain];
}

+ (void)initPreferences
{
	[TPCApplicationInfo updateApplicationRunCount];

	// ====================================================== //

#if TEXTUAL_BUILT_INSIDE_SANDBOX == 0
	[TPCPreferencesUserDefaults migrateKeyValuesAwayFromGroupContainer];
#endif

	NSDictionary *defaults =
	[TPCResourceManager loadContentsOfPropertyListInResources:@"RegisteredUserDefaults"];

	[RZUserDefaults() registerDefaults:defaults];

	[TPCPreferences populateDefaultNickname];

	[RZUserDefaults() addObserver:(id)self forKeyPath:@"Highlight List -> Primary Matches"  options:NSKeyValueObservingOptionNew context:NULL];
	[RZUserDefaults() addObserver:(id)self forKeyPath:@"Highlight List -> Excluded Matches" options:NSKeyValueObservingOptionNew context:NULL];

	[TPCPreferences loadMatchKeywords];
	[TPCPreferences loadExcludeKeywords];
	
	[IRCCommandIndex populateCommandIndex];

	/* Sandbox Check */
	[RZUserDefaults() setBool:[TPCApplicationInfo sandboxEnabled]						forKey:@"Security -> Sandbox Enabled"];

	[RZUserDefaults() setBool:[XRSystemInformation isUsingOSXLionOrLater]				forKey:@"System -> Running Mac OS Lion Or Newer"];
	[RZUserDefaults() setBool:[XRSystemInformation isUsingOSXMountainLionOrLater]		forKey:@"System -> Running Mac OS Mountain Lion Or Newer"];
	[RZUserDefaults() setBool:[XRSystemInformation isUsingOSXMavericksOrLater]			forKey:@"System -> Running Mac OS Mavericks Or Newer"];
	[RZUserDefaults() setBool:[XRSystemInformation isUsingOSXYosemiteOrLater]			forKey:@"System -> Running Mac OS Yosemite Or Newer"];

#if TEXTUAL_BUILT_WITH_HOCKEYAPP_SDK_ENABLED == 1
	[RZUserDefaults() setBool:YES forKey:@"System -> 3rd-party Services -> Built with HockeyApp Framework"];
#else
	[RZUserDefaults() setBool:NO forKey:@"System -> 3rd-party Services -> Built with HockeyApp Framework"];
#endif

#if TEXTUAL_BUILT_WITH_SPARKLE_ENABLED == 1
	[RZUserDefaults() setBool:YES forKey:@"System -> 3rd-party Services -> Built with Sparkle Framework"];
#else 
	[RZUserDefaults() setBool:NO forKey:@"System -> 3rd-party Services -> Built with Sparkle Framework"];
#endif

#if TEXTUAL_BUILT_WITH_ICLOUD_SUPPORT == 0
	[RZUserDefaults() setBool:NO forKey:@"System -> Built with iCloud Support"];
#else
	if ([XRSystemInformation isUsingOSXMountainLionOrLater]) {
		[RZUserDefaults() setBool:YES forKey:@"System -> Built with iCloud Support"];
	} else {
		[RZUserDefaults() setBool:NO forKey:@"System -> Built with iCloud Support"];
	}
#endif

#if TEXTUAL_BUILT_WITH_LICENSE_MANAGER == 1
	[RZUserDefaults() setBool:YES forKey:@"System -> Built with License Manager Backend"];
#else
	[RZUserDefaults() setBool:NO forKey:@"System -> Built with License Manager Backend"];
#endif

#if TEXTUAL_BUILT_WITH_ADVANCED_ENCRYPTION == 1
	[RZUserDefaults() setBool:YES forKey:@"System -> Built with Off-the-Record Messaging Support"];
#else
	[RZUserDefaults() setBool:NO forKey:@"System -> Built with Off-the-Record Messaging Support"];
#endif

	[RZUserDefaults() setInteger:TPCPreferencesDictionaryVersion forKey:@"TPCPreferencesDictionaryVersion"];

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
	[RZUserDefaults() setBool:value forKey:@"TextFieldAutomaticSpellCheck"];
}

+ (BOOL)textFieldAutomaticGrammarCheck
{
	return [RZUserDefaults() boolForKey:@"TextFieldAutomaticGrammarCheck"];
}

+ (void)setTextFieldAutomaticGrammarCheck:(BOOL)value
{
	[RZUserDefaults() setBool:value forKey:@"TextFieldAutomaticGrammarCheck"];
}

+ (BOOL)textFieldAutomaticSpellCorrection
{
	return [RZUserDefaults() boolForKey:@"TextFieldAutomaticSpellCorrection"];
}

+ (void)setTextFieldAutomaticSpellCorrection:(BOOL)value
{
	[RZUserDefaults() setBool:value forKey:@"TextFieldAutomaticSpellCorrection"];
}

+ (BOOL)textFieldSmartCopyPaste
{
	return [RZUserDefaults() boolForKey:@"TextFieldSmartCopyPaste"];
}

+ (void)setTextFieldSmartCopyPaste:(BOOL)value
{
	[RZUserDefaults() setBool:value forKey:@"TextFieldSmartCopyPaste"];
}

+ (BOOL)textFieldSmartQuotes
{
	return [RZUserDefaults() boolForKey:@"TextFieldSmartQuotes"];
}

+ (void)setTextFieldSmartQuotes:(BOOL)value
{
	[RZUserDefaults() setBool:value forKey:@"TextFieldSmartQuotes"];
}

+ (BOOL)textFieldSmartDashes
{
	return [RZUserDefaults() boolForKey:@"TextFieldSmartDashes"];
}

+ (void)setTextFieldSmartDashes:(BOOL)value
{
	[RZUserDefaults() setBool:value forKey:@"TextFieldSmartDashes"];
}

+ (BOOL)textFieldSmartLinks
{
	return [RZUserDefaults() boolForKey:@"TextFieldSmartLinks"];
}

+ (void)setTextFieldSmartLinks:(BOOL)value
{
	[RZUserDefaults() setBool:value forKey:@"TextFieldSmartLinks"];
}

+ (BOOL)textFieldDataDetectors
{
	return [RZUserDefaults() boolForKey:@"TextFieldDataDetectors"];
}

+ (void)setTextFieldDataDetectors:(BOOL)value
{
	[RZUserDefaults() setBool:value forKey:@"TextFieldDataDetectors"];
}

+ (BOOL)textFieldTextReplacement
{
	return [RZUserDefaults() boolForKey:@"TextFieldTextReplacement"];
}

+ (void)setTextFieldTextReplacement:(BOOL)value
{
	[RZUserDefaults() setBool:value forKey:@"TextFieldTextReplacement"];
}

@end

NS_ASSUME_NONNULL_END
