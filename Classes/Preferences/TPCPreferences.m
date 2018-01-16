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

#import "TXGlobalModels.h"
#import "IRCWorld.h"
#import "TPCApplicationInfoPrivate.h"
#import "TPCPathInfoPrivate.h"
#import "TPCPreferencesUserDefaultsLocal.h"
#import "TPCPreferencesUserDefaultsMigratePrivate.h"
#import "TPCPreferencesReloadPrivate.h"
#import "TPCResourceManager.h"
#import "TPCThemeController.h"
#import "TPCThemeSettings.h"
#import "TPCPreferencesLocalPrivate.h"

NS_ASSUME_NONNULL_BEGIN

NSString * const TPCPreferencesThemeNameDefaultsKey	= @"Theme -> Name";

NSString * const TPCPreferencesThemeFontNameDefaultsKey	= @"Theme -> Font Name";
NSString * const TPCPreferencesThemeFontSizeDefaultsKey	= @"Theme -> Font Size";

NSString * const TPCPreferencesThemeNameMissingLocallyDefaultsKey = @"Theme -> Name -> Did Not Exist During Last Sync";

NSString * const TPCPreferencesThemeFontNameMissingLocallyDefaultsKey = @"Theme -> Font Name -> Did Not Exist During Last Sync";

NSUInteger const TPCPreferencesDictionaryVersion = 602;

@implementation TPCPreferences (TPCPreferencesLocal)

#pragma mark -
#pragma mark Default Identity

+ (NSString *)_defaultNicknamePrefix
{
	return [TPCPreferences defaultPreferences][@"DefaultIdentity -> Nickname"];
}

+ (void)_populateDefaultNickname
{
	/* Using "Guest" as the default nickname may create conflicts as nickname guesses are 
	 exhausted while appending underscores. To fix this, a random number is appended to 
	 the end of the default nickname. */
	NSString *nicknamePrefix = [TPCPreferences _defaultNicknamePrefix];

	NSString *nickname = [nicknamePrefix stringByAppendingFormat:@"%lu", TXRandomNumber(100)];

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

+ (NSString *)defaultRealName
{
	return [RZUserDefaults() objectForKey:@"DefaultIdentity -> Realname"];
}

#pragma mark -
#pragma mark General Preferences

+ (NSUInteger)autojoinMaximumChannelJoins
{
	return [RZUserDefaults() unsignedIntegerForKey:@"AutojoinMaximumChannelJoinCount"];
}

+ (NSTimeInterval)autojoinDelayBetweenChannelJoins
{
	return [RZUserDefaults() doubleForKey:@"AutojoinDelayBetweenChannelJoins"];
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

+ (BOOL)disconnectOnSleep
{
	return [RZUserDefaults() boolForKey:@"AutomaticallyDisconnectForSleepMode"];
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
+ (void)setTextEncryptionIsOpportunistic:(BOOL)textEncryptionIsOpportunistic
{
	[RZUserDefaults() setBool:textEncryptionIsOpportunistic forKey:@"Off-the-Record Messaging -> Automatically Enable Service"];
}

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

+ (BOOL)enableEchoMessageCapability
{
	return [RZUserDefaults() boolForKey:@"IRC -> Enable echo-message Capability"];
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

+ (void)setLogToDisk:(BOOL)logToDisk
{
	[RZUserDefaults() setBool:logToDisk forKey:@"LogTranscript"];
}

+ (BOOL)logToDiskIsEnabled
{
	return ([RZUserDefaults() boolForKey:@"LogTranscript"] &&
			[TPCPathInfo transcriptFolderURL] != nil);
}

+ (BOOL)openBrowserInBackground
{
	return [RZUserDefaults() boolForKey:@"OpenClickedLinksInBackgroundBrowser"];
}

+ (BOOL)showInlineImages
{
	return [TPCPreferences showInlineMedia];
}

+ (BOOL)showInlineMedia
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

+ (BOOL)generateLocalizedTimestampTemplateToken
{
	return [RZUserDefaults() boolForKey:@"GenerateLocalizedTimestampTemplateToken"];
}

+ (void)setHighlightCurrentNickname:(BOOL)highlightCurrentNickname
{
	[RZUserDefaults() setBool:highlightCurrentNickname forKey:@"TrackNicknameHighlightsOfLocalUser"];
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

+ (NSUInteger)trackUserAwayStatusMaximumChannelSize
{
	return [RZUserDefaults() unsignedIntegerForKey:@"TrackUserAwayStatusMaximumChannelSize"];
}

+ (TXTabKeyAction)tabKeyAction
{
	return (TXTabKeyAction)[RZUserDefaults() unsignedIntegerForKey:@"Keyboard -> Tab Key Action"];
}

+ (TXNicknameHighlightMatchType)highlightMatchingMethod
{
	return (TXNicknameHighlightMatchType)[RZUserDefaults() unsignedIntegerForKey:@"NicknameHighlightMatchingType"];
}

+ (TXUserDoubleClickAction)userDoubleClickOption
{
	return (TXUserDoubleClickAction)[RZUserDefaults() unsignedIntegerForKey:@"UserListDoubleClickAction"];
}

+ (TXNoticeSendLocationType)locationToSendNotices
{
	return (TXNoticeSendLocationType)[RZUserDefaults() unsignedIntegerForKey:@"DestinationOfNonserverNotices"];
}

+ (TXCommandWKeyAction)commandWKeyAction
{
	return (TXCommandWKeyAction)[RZUserDefaults() unsignedIntegerForKey:@"Keyboard -> Command+W Key Action"];
}

+ (TXHostmaskBanFormat)banFormat
{
	return (TXHostmaskBanFormat)[RZUserDefaults() unsignedIntegerForKey:@"DefaultBanCommandHostmaskFormat"];
}

+ (TVCMainWindowTextViewFontSize)mainTextViewFontSize
{
	return (TVCMainWindowTextViewFontSize)[RZUserDefaults() unsignedIntegerForKey:@"Main Input Text Field -> Font Size"];
}

+ (BOOL)focusMainTextViewOnSelectionChange
{
	return [RZUserDefaults() boolForKey:@"Main Input Text Field -> Focus When Changing Views"];
}

#pragma mark -
#pragma mark App Nap 

+ (BOOL)appNapEnabled
{
	return ([[NSUserDefaults standardUserDefaults] boolForKey:@"NSAppSleepDisabled"] == NO);
}

+ (void)setAppNapEnabled:(BOOL)appNapEnabled
{
	[[NSUserDefaults standardUserDefaults] setBool:(appNapEnabled == NO) forKey:@"NSAppSleepDisabled"];
}

#pragma mark -
#pragma mark Updates

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
	[RZUserDefaults() registerDefault:@(invertSidebarColorsPreferenceUserConfigurable) forKey:@"Theme -> Invert Sidebar Colors Preference Enabled"];
}

+ (void)setInvertSidebarColors:(BOOL)invertSidebarColors
{
	[RZUserDefaults() setBool:invertSidebarColors forKey:@"InvertSidebarColors"];
}

+ (BOOL)invertSidebarColors
{
	if (themeSettings().invertSidebarColors) {
		return YES;
	}

	return [RZUserDefaults() boolForKey:@"InvertSidebarColors"];
}

+ (NSString *)themeNameDefault
{
	return [TPCPreferences defaultPreferences][TPCPreferencesThemeNameDefaultsKey];
}

+ (NSString *)themeName
{
	return [RZUserDefaults() objectForKey:TPCPreferencesThemeNameDefaultsKey];
}

+ (void)setThemeName:(NSString *)value
{
	NSParameterAssert(value != nil);

	[RZUserDefaults() setObject:value forKey:TPCPreferencesThemeNameDefaultsKey];

	[RZUserDefaults() removeObjectForKey:TPCPreferencesThemeNameMissingLocallyDefaultsKey];
}

+ (void)setThemeNameWithExistenceCheck:(NSString *)value
{
	NSParameterAssert(value != nil);

	if ([TPCThemeController themeExists:value]) {
		[TPCPreferences setThemeName:value];
	} else {
		[RZUserDefaults() setBool:YES forKey:TPCPreferencesThemeNameMissingLocallyDefaultsKey];
	}
}

+ (NSString *)themeChannelViewFontNameDefault
{
	return [TPCPreferences defaultPreferences][TPCPreferencesThemeFontNameDefaultsKey];
}

+ (NSString *)themeChannelViewFontName
{
	return [RZUserDefaults() objectForKey:TPCPreferencesThemeFontNameDefaultsKey];
}

+ (void)setThemeChannelViewFontName:(NSString *)value
{
	NSParameterAssert(value != nil);

	[RZUserDefaults() setObject:value forKey:TPCPreferencesThemeFontNameDefaultsKey];

	[RZUserDefaults() removeObjectForKey:TPCPreferencesThemeFontNameMissingLocallyDefaultsKey];
}

+ (void)setThemeChannelViewFontNameWithExistenceCheck:(NSString *)value
{
	NSParameterAssert(value != nil);

	if ([NSFont fontIsAvailable:value]) {
		[TPCPreferences setThemeChannelViewFontName:value];
	} else {
		[RZUserDefaults() setBool:YES forKey:TPCPreferencesThemeFontNameMissingLocallyDefaultsKey];
	}
}

+ (CGFloat)themeChannelViewFontSize
{
	return [RZUserDefaults() doubleForKey:@"Theme -> Font Size"];
}

+ (void)setThemeChannelViewFontSize:(CGFloat)value
{
	[RZUserDefaults() setDouble:value forKey:@"Theme -> Font Size"];
}

+ (nullable NSFont *)themeChannelViewFont
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
	[RZUserDefaults() registerDefault:@(themeChannelViewFontPreferenceUserConfigurable) forKey:@"Theme -> Channel Font Preference Enabled"];
}

+ (NSString *)themeNicknameFormatDefault
{
	return [TPCPreferences defaultPreferences][@"Theme -> Nickname Format"];
}

+ (NSString *)themeNicknameFormat
{
	return [RZUserDefaults() objectForKey:@"Theme -> Nickname Format"];
}

+ (BOOL)themeNicknameFormatPreferenceUserConfigurable
{
	return [RZUserDefaults() boolForKey:@"Theme -> Nickname Format Preference Enabled"];
}

+ (void)setThemeNicknameFormatPreferenceUserConfigurable:(BOOL)themeNicknameFormatPreferenceUserConfigurable
{
	[RZUserDefaults() registerDefault:@(themeNicknameFormatPreferenceUserConfigurable) forKey:@"Theme -> Nickname Format Preference Enabled"];
}

+ (NSString *)themeTimestampFormatDefault
{
	return [TPCPreferences defaultPreferences][@"Theme -> Timestamp Format"];
}

+ (NSString *)themeTimestampFormat
{
	return [RZUserDefaults() objectForKey:@"Theme -> Timestamp Format"];
}

+ (BOOL)themeTimestampFormatPreferenceUserConfigurable
{
	return [RZUserDefaults() boolForKey:@"Theme -> Timestamp Format Preference Enabled"];
}

+ (void)setThemeTimestampFormatPreferenceUserConfigurable:(BOOL)themeTimestampFormatPreferenceUserConfigurable
{
	[RZUserDefaults() registerDefault:@(themeTimestampFormatPreferenceUserConfigurable) forKey:@"Theme -> Timestamp Format Preference Enabled"];
}

+ (CGFloat)mainWindowTransparency
{
	return [RZUserDefaults() doubleForKey:@"MainWindowTransparencyLevel"];
}

+ (BOOL)automaticallyReloadCustomThemesWhenTheyChange
{
	return [RZUserDefaults() boolForKey:@"AutomaticallyReloadCustomThemesWhenTheyChange"];
}

+ (void)setWebKit2Enabled:(BOOL)webKit2Enabled
{
	[RZUserDefaults() setBool:webKit2Enabled forKey:@"UsesWebKit2WhenAvailable"];
}

+ (BOOL)webKit2Enabled
{
	BOOL canUseWebKit2 = [RZUserDefaults() boolForKey:@"UsesWebKit2WhenAvailable"];

	if (canUseWebKit2 == NO) {
		return NO;
	}

	if (TEXTUAL_RUNNING_ON(10.11, ElCapitan)) {
		return YES;
	}

	return NO;
}

+ (BOOL)webKit2ProcessPoolSizeLimited
{
	return [RZUserDefaults() boolForKey:@"WebViewProcessPoolSizeIsLimited"];
}

+ (BOOL)webKit2PreviewLinks
{
	return [RZUserDefaults() boolForKey:@"WebViewPreviewLinks"];
}

+ (BOOL)themeChannelViewUsesCustomScrollers
{
	return ([RZUserDefaults() boolForKey:@"WebViewDoNotUsesCustomScrollers"] == NO);
}

+ (TXChannelViewArrangement)channelViewArrangement
{
	return [RZUserDefaults() unsignedIntegerForKey:@"ChannelViewArrangement"];
}

#pragma mark -
#pragma mark Completion Suffix

+ (nullable NSString *)tabCompletionSuffix
{
	return [RZUserDefaults() objectForKey:@"Keyboard -> Tab Key Completion Suffix"];
}

+ (void)setTabCompletionSuffix:(NSString *)value
{
	NSParameterAssert(value != nil);

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
#pragma mark File Transfers

+ (TXFileTransferRequestReplyAction)fileTransferRequestReplyAction
{
	return [RZUserDefaults() unsignedIntegerForKey:@"File Transfers -> File Transfer Request Reply Action"];
}

+ (TXFileTransferIPAddressDetectionMethod)fileTransferIPAddressDetectionMethod
{
	return [RZUserDefaults() unsignedIntegerForKey:@"File Transfers -> File Transfer IP Address Detection Method"];
}

+ (BOOL)fileTransferRequestsAreReversed
{
	return [RZUserDefaults() boolForKey:@"File Transfers -> File Transfer Requests Use Reverse DCC"];
}

+ (BOOL)fileTransfersPreventIdleSystemSleep
{
	return [RZUserDefaults() boolForKey:@"File Transfers -> Idle System Sleep Prevented During File Transfer"];
}

+ (uint16_t)fileTransferPortRangeStart
{
	return [RZUserDefaults() unsignedShortForKey:@"File Transfers -> File Transfer Port Range Start"];
}

+ (void)setFileTransferPortRangeStart:(uint16_t)value
{
	[RZUserDefaults() setUnsignedShort:value forKey:@"File Transfers -> File Transfer Port Range Start"];
}

+ (uint16_t)fileTransferPortRangeEnd
{
	return [RZUserDefaults() unsignedShortForKey:@"File Transfers -> File Transfer Port Range End"];
}

+ (void)setFileTransferPortRangeEnd:(uint16_t)value
{
	[RZUserDefaults() setUnsignedShort:value forKey:@"File Transfers -> File Transfer Port Range End"];
}

+ (nullable NSString *)fileTransferManuallyEnteredIPAddress
{
	return [RZUserDefaults() objectForKey:@"File Transfers -> File Transfer Manually Entered IP Address"];
}

+ (nullable NSString *)fileTransferIPAddressInterfaceName
{
	return [RZUserDefaults() objectForKey:@"File Transfers -> File Transfer IP Address Interface Name"];
}

#pragma mark -
#pragma mark Max Log Lines

+ (NSUInteger)scrollbackSaveLimit
{
	return [RZUserDefaults() unsignedIntegerForKey:@"ScrollbackMaximumSavedLineCount"];
}

+ (void)setScrollbackSaveLimit:(NSUInteger)scrollbackSaveLimit
{
	[RZUserDefaults() setUnsignedInteger:scrollbackSaveLimit forKey:@"ScrollbackMaximumSavedLineCount"];
}

+ (NSUInteger)scrollbackVisibleLimit
{
	return [RZUserDefaults() unsignedIntegerForKey:@"ScrollbackMaximumVisibleLineCount"];
}

+ (void)setScrollbackVisibleLimit:(NSUInteger)scrollbackVisibleLimit
{
	[RZUserDefaults() setUnsignedInteger:scrollbackVisibleLimit forKey:@"ScrollbackMaximumVisibleLineCount"];
}

#pragma mark -
#pragma mark Growl

+ (BOOL)soundIsMuted
{
	return [RZUserDefaults() boolForKey:@"Notification Sound Is Muted"];
}

+ (void)setSoundIsMuted:(BOOL)soundIsMuted
{
	[RZUserDefaults() setBool:soundIsMuted forKey:@"Notification Sound Is Muted"];
}

+ (nullable NSString *)keyForEvent:(TXNotificationType)event category:(NSString *)category
{
	NSParameterAssert(category != nil);

	NSString *returnValue = nil;

	switch (event) {
#define _dv(key, value)		case (key): { returnValue = (value); break; }

		_dv(TXNotificationAddressBookMatchType, @"NotificationType -> Address Book Match -> ")
		_dv(TXNotificationChannelMessageType, @"NotificationType -> Public Message -> ")
		_dv(TXNotificationChannelNoticeType, @"NotificationType -> Public Notice -> ")
		_dv(TXNotificationConnectType, @"NotificationType -> Connected -> ")
		_dv(TXNotificationDisconnectType, @"NotificationType -> Disconnected -> ")
		_dv(TXNotificationHighlightType, @"NotificationType -> Highlight -> ")
		_dv(TXNotificationInviteType, @"NotificationType -> Channel Invitation -> ")
		_dv(TXNotificationKickType, @"NotificationType -> Kicked from Channel -> ")
		_dv(TXNotificationNewPrivateMessageType, @"NotificationType -> Private Message (New) -> ")
		_dv(TXNotificationPrivateMessageType, @"NotificationType -> Private Message -> ")
		_dv(TXNotificationPrivateNoticeType, @"NotificationType -> Private Notice -> ")
		_dv(TXNotificationFileTransferSendSuccessfulType, @"NotificationType -> Successful File Transfer (Sending) -> ")
		_dv(TXNotificationFileTransferReceiveSuccessfulType, @"NotificationType -> Successful File Transfer (Receiving) -> ")
		_dv(TXNotificationFileTransferSendFailedType, @"NotificationType -> Failed File Transfer (Sending) -> ")
		_dv(TXNotificationFileTransferReceiveFailedType, @"NotificationType -> Failed File Transfer (Receiving) -> ")
		_dv(TXNotificationFileTransferReceiveRequestedType, @"NotificationType -> File Transfer Request -> ")
		_dv(TXNotificationUserJoinedType, @"NotificationType -> User Joined -> ")
		_dv(TXNotificationUserPartedType, @"NotificationType -> User Parted -> ")
		_dv(TXNotificationUserDisconnectedType, @"NotificationType -> User Disconnected -> ")

#undef _dv
	}

	if (returnValue == nil) {
		return nil;
	}

	return [returnValue stringByAppendingString:category];
}

+ (nullable NSString *)soundForEvent:(TXNotificationType)event
{
	NSString *eventKey = [TPCPreferences keyForEvent:event category:@"Sound"];

	if (eventKey == nil) {
		return nil;
	}

	return [RZUserDefaults() objectForKey:eventKey];
}

+ (void)setSound:(nullable NSString *)value forEvent:(TXNotificationType)event
{
	NSString *eventKey = [TPCPreferences keyForEvent:event category:@"Sound"];

	if (eventKey == nil) {
		return;
	}

	[RZUserDefaults() setObject:value forKey:eventKey];
}

+ (BOOL)growlEnabledForEvent:(TXNotificationType)event
{
	NSString *eventKey = [TPCPreferences keyForEvent:event category:@"Enabled"];

	if (eventKey == nil) {
		return NO;
	}

	return [RZUserDefaults() boolForKey:eventKey];
}

+ (void)setGrowlEnabled:(BOOL)value forEvent:(TXNotificationType)event
{
	NSString *eventKey = [TPCPreferences keyForEvent:event category:@"Enabled"];

	if (eventKey == nil) {
		return;
	}

	[RZUserDefaults() setBool:value forKey:eventKey];
}

+ (BOOL)disabledWhileAwayForEvent:(TXNotificationType)event
{
	NSString *eventKey = [TPCPreferences keyForEvent:event category:@"Disable While Away"];

	if (eventKey == nil) {
		return NO;
	}

	return [RZUserDefaults() boolForKey:eventKey];
}

+ (void)setDisabledWhileAway:(BOOL)value forEvent:(TXNotificationType)event
{
	NSString *eventKey = [TPCPreferences keyForEvent:event category:@"Disable While Away"];

	if (eventKey == nil) {
		return;
	}

	[RZUserDefaults() setBool:value forKey:eventKey];
}

+ (BOOL)bounceDockIconForEvent:(TXNotificationType)event
{
	NSString *eventKey = [TPCPreferences keyForEvent:event category:@"Bounce Dock Icon"];

	if (eventKey == nil) {
		return NO;
	}

	return [RZUserDefaults() boolForKey:eventKey];
}

+ (void)setBounceDockIcon:(BOOL)value forEvent:(TXNotificationType)event
{
	NSString *eventKey = [TPCPreferences keyForEvent:event category:@"Bounce Dock Icon"];

	if (eventKey == nil) {
		return;
	}

	[RZUserDefaults() setBool:value forKey:eventKey];
}

+ (BOOL)bounceDockIconRepeatedlyForEvent:(TXNotificationType)event
{
	NSString *eventKey = [TPCPreferences keyForEvent:event category:@"Bounce Dock Icon Repeatedly"];

	if (eventKey == nil) {
		return NO;
	}

	return [RZUserDefaults() boolForKey:eventKey];
}

+ (void)setBounceDockIconRepeatedly:(BOOL)value forEvent:(TXNotificationType)event
{
	NSString *eventKey = [TPCPreferences keyForEvent:event category:@"Bounce Dock Icon Repeatedly"];

	if (eventKey == nil) {
		return;
	}

	[RZUserDefaults() setBool:value forKey:eventKey];
}

+ (BOOL)speakEvent:(TXNotificationType)event
{
	NSString *eventKey = [TPCPreferences keyForEvent:event category:@"Speak"];

	if (eventKey == nil) {
		return NO;
	}

	return [RZUserDefaults() boolForKey:eventKey];
}

+ (void)setEventIsSpoken:(BOOL)value forEvent:(TXNotificationType)event
{
	NSString *eventKey = [TPCPreferences keyForEvent:event category:@"Speak"];

	if (eventKey == nil) {
		return;
	}

	[RZUserDefaults() setBool:value forKey:eventKey];
}

+ (BOOL)onlySpeakEventsForSelection
{
	return [RZUserDefaults() boolForKey:@"OnlySpeakNotificationsForSelection"];
}

+ (void)setOnlySpeakEventsForSelection:(BOOL)onlySpeakEventsForSelection
{
	[RZUserDefaults() setBool:onlySpeakEventsForSelection forKey:@"OnlySpeakNotificationsForSelection"];
}

+ (BOOL)channelMessageSpeakChannelName
{
	NSString *eventKey = [TPCPreferences keyForEvent:TXNotificationChannelMessageType category:@"Speak Channel Name"];

	return [RZUserDefaults() boolForKey:eventKey];
}

+ (void)setChannelMessageSpeakChannelName:(BOOL)channelMessageSpeakChannelName
{
	NSString *eventKey = [TPCPreferences keyForEvent:TXNotificationChannelMessageType category:@"Speak Channel Name"];

	[RZUserDefaults() setBool:channelMessageSpeakChannelName forKey:eventKey];
}

+ (BOOL)channelMessageSpeakNickname
{
	NSString *eventKey = [TPCPreferences keyForEvent:TXNotificationChannelMessageType category:@"Speak Nickname"];

	return [RZUserDefaults() boolForKey:eventKey];
}

+ (void)setChannelMessageSpeakNickname:(BOOL)channelMessageSpeakNickname
{
	NSString *eventKey = [TPCPreferences keyForEvent:TXNotificationChannelMessageType category:@"Speak Nickname"];

	[RZUserDefaults() setBool:channelMessageSpeakNickname forKey:eventKey];
}

#pragma mark -
#pragma mark World

+ (nullable NSArray<NSDictionary *> *)clientList
{
	return [RZUserDefaults() objectForKey:IRCWorldClientListDefaultsKey];
}

+ (void)setClientList:(nullable NSArray<NSDictionary *> *)clientList
{
	[RZUserDefaults() setObject:clientList forKey:IRCWorldClientListDefaultsKey];
}

#pragma mark -
#pragma mark Keywords

static NSArray<NSString *> *_excludeKeywords = nil;
static NSArray<NSString *> *_matchKeywords = nil;

+ (void)_loadExcludeKeywords
{
	NSArray<NSDictionary *> *keywordArrayIn = [RZUserDefaults() arrayForKey:@"Highlight List -> Excluded Matches"];

	NSMutableArray<NSString *> *keywordArrayOut = [NSMutableArray array];

	for (NSDictionary<NSString *, NSString *> *keyword in keywordArrayIn) {
		NSString *s = keyword[@"string"];

		if (s && s.length > 0) {
			[keywordArrayOut addObject:s];
		}
	}

	_excludeKeywords = [keywordArrayOut copy];
}

+ (void)_loadMatchKeywords
{
	NSArray<NSDictionary *> *keywordArrayIn = [RZUserDefaults() arrayForKey:@"Highlight List -> Primary Matches"];

	NSMutableArray<NSString *> *keywordArrayOut = [NSMutableArray array];

	for (NSDictionary<NSString *, NSString *> *keyword in keywordArrayIn) {
		NSString *s = keyword[@"string"];

		if (s && s.length > 0) {
			[keywordArrayOut addObject:s];
		}
	}

	_matchKeywords = [keywordArrayOut copy];
}

+ (void)_cleanUpKeywords:(NSString *)key
{
	NSArray<NSDictionary *> *keywordArrayIn = [RZUserDefaults() arrayForKey:key];

	NSMutableArray<NSString *> *keywordArrayOut = [NSMutableArray array];

	for (NSDictionary<NSString *, NSString *> *keyword in keywordArrayIn) {
		NSString *s = keyword[@"string"];

		if (s && s.length > 0) {
			[keywordArrayOut addObject:s];
		}
	}

	[keywordArrayOut sortUsingSelector:@selector(caseInsensitiveCompare:)];

	NSArray *arrayToSave = keywordArrayOut.stringArrayControllerObjects;

	[RZUserDefaults() setObject:arrayToSave forKey:key];
}

+ (void)cleanUpHighlightKeywords
{
	[TPCPreferences _cleanUpKeywords:@"Highlight List -> Primary Matches"];

	[TPCPreferences _cleanUpKeywords:@"Highlight List -> Excluded Matches"];
}

+ (nullable NSArray<NSString *> *)highlightMatchKeywords
{
	return _matchKeywords;
}

+ (nullable NSArray<NSString *> *)highlightExcludeKeywords
{
	return _excludeKeywords;
}

#pragma mark -
#pragma mark Key-Value Observing

+ (void)observeValueForKeyPath:(NSString *)key ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	if ([key isEqualToString:@"Highlight List -> Primary Matches"]) {
		[TPCPreferences _loadMatchKeywords];
	} else if ([key isEqualToString:@"Highlight List -> Excluded Matches"]) {
		[TPCPreferences _loadExcludeKeywords];
	}
}

#pragma mark -
#pragma mark Migration

+ (void)_migrateWorldControllerToVersion600
{
#define _defaultsKey @"TPCPreferences -> Migration -> World Controller Migrated (600)"

	if ([RZUserDefaults() boolForKey:@"World Controller Migrated (600)"]) {
		[RZUserDefaults() removeObjectForKey:@"World Controller Migrated (600)"];

		[RZUserDefaults() setBool:YES forKey:_defaultsKey];
	}

	if ([RZUserDefaults() boolForKey:_defaultsKey]) {
		return;
	}

	BOOL clientListMigrated = [RZUserDefaults() boolForKey:_defaultsKey];

	if (clientListMigrated) {
		return;
	}

	NSDictionary *worldController = [RZUserDefaults() dictionaryForKey:@"World Controller"];

	NSArray<NSDictionary *> *clientList = [worldController arrayForKey:@"clients"];

	if (clientList.count > 0) {
		[TPCPreferences setClientList:clientList];
	}

	BOOL soundIsMuted = [worldController boolForKey:@"soundIsMuted"];

	if (soundIsMuted) {
		[TPCPreferences setSoundIsMuted:soundIsMuted];
	}

	[RZUserDefaults() setBool:YES forKey:_defaultsKey];

#undef _defaultsKey
}

#if TEXTUAL_BUILT_WITH_SPARKLE_ENABLED == 1
+ (void)_migrateSparkleConfigurationToVersion601
{

#define _defaultsKey @"TPCPreferences -> Migration -> Sparkle (601)"

	BOOL sparkleMigrated = [RZUserDefaults() boolForKey:_defaultsKey];

	if (sparkleMigrated) {
		return;
	}

	[[NSUserDefaults standardUserDefaults] removeObjectForKey:@"SUEnableAutomaticChecks"];

	[RZUserDefaults() setBool:YES forKey:_defaultsKey];

#undef _defaultsKey

}
#endif

+ (void)_migratePreferencesToVersion602
{
	/* This method removes keys that are obsolete. Obsolete keys include those
	 that are no longer used by any feature, or keys that should only be stored
	 temporarily. This method must be called before -registeredDefaults are 
	 invoked, or we would could potentially fuck shit up really bad. */
	NSNumber *dictionaryVersion = [RZUserDefaults() objectForKey:@"TPCPreferencesDictionaryVersion"];

	if (dictionaryVersion.integerValue != 600) {
		return;
	}

	NSDictionary *dictionaryContents = RZUserDefaults().dictionaryRepresentation;

	[dictionaryContents enumerateKeysAndObjectsUsingBlock:^(NSString *key, id object, BOOL *stop) {
		if ([TPCPreferencesUserDefaults keyIsObsolete:key]) {
			[RZUserDefaults() removeObjectForKey:key];
		}
	}];
}

#pragma mark -
#pragma mark Dynamic Defaults 

+ (void)registerWebKit2DynamicDefaults
{
	/* The WebKit2 Web Inspector cannot work attached to Textual's main window.
	 Whoes fault this is isn't clear, but I do not have time to take a deep 
	 look at it at this time. To fix it temporarily, we always force it as 
	 window. To prevent the user breaking Textual by attaching it, we force
	 reset the default here, every run. */

	[[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"__WebInspectorPageGroupLevel1__.WebKit2InspectorStartsAttached"];
}

+ (void)registerPreferencesDictionaryVersion
{
	/* We do not allow Textual to register a version lower than what is 
	 already set so that if the user opens an older version, we do not
	 perform migrations more than once. Probably would have been smart
	 to do this from the beginning. */
	NSNumber *dictionaryVersion = [RZUserDefaults() objectForKey:@"TPCPreferencesDictionaryVersion"];

	if (dictionaryVersion.integerValue >= TPCPreferencesDictionaryVersion) {
		return;
	}

	[RZUserDefaults() setUnsignedInteger:TPCPreferencesDictionaryVersion forKey:@"TPCPreferencesDictionaryVersion"];
}

#pragma mark -
#pragma mark Initialization

+ (NSDictionary<NSString *, id> *)defaultPreferences
{
	/* Note added October 2017:

	 I wrote this code a year ago and today (when the note was written),
	 I took another look at it. 95% of defaults are registered with
	 RZUserDefaults, not NSUserDefaults. So why has this code never
	 created a problem?

	 After performing more research, it turns out the registration domain
	 is app wide. It doesn't care which instance of NSUserDefaults you
	 set it on or read it from. It will be consistent app wide.

	 This is nothing exciting. I documenting this more for my own sanity. */

	return [RZUserDefaults() volatileDomainForName:NSRegistrationDomain];
}

+ (void)registerDynamicDefaults
{
	[self _populateDefaultNickname];

	[self registerWebKit2DynamicDefaults];

	NSMutableDictionary *dynamicDefaults = [NSMutableDictionary dictionary];

	[dynamicDefaults setBool:[TPCApplicationInfo sandboxEnabled]						forKey:@"Security -> Sandbox Enabled"];

	[dynamicDefaults setBool:TEXTUAL_RUNNING_ON(10.8, MountainLion)		forKey:@"System -> Running Mac OS Mountain Lion Or Newer"];
	[dynamicDefaults setBool:TEXTUAL_RUNNING_ON(10.9, Mavericks)		forKey:@"System -> Running Mac OS Mavericks Or Newer"];
	[dynamicDefaults setBool:TEXTUAL_RUNNING_ON(10.10, Yosemite)		forKey:@"System -> Running Mac OS Yosemite Or Newer"];
	[dynamicDefaults setBool:TEXTUAL_RUNNING_ON(10.11, ElCapitan)		forKey:@"System -> Running Mac OS El Capitan Or Newer"];
	[dynamicDefaults setBool:TEXTUAL_RUNNING_ON(10.12, Sierra)			forKey:@"System -> Running Mac OS Sierra Or Newer"];
	[dynamicDefaults setBool:TEXTUAL_RUNNING_ON(10.13, HighSierra)		forKey:@"System -> Running Mac OS High Sierra Or Newer"];

#if TEXTUAL_BUILT_WITH_HOCKEYAPP_SDK_ENABLED == 1
	[dynamicDefaults setBool:YES forKey:@"System -> 3rd-party Services -> Built with HockeyApp Framework"];
#else
	[dynamicDefaults setBool:NO forKey:@"System -> 3rd-party Services -> Built with HockeyApp Framework"];
#endif

#if TEXTUAL_BUILT_WITH_SPARKLE_ENABLED == 1
	[dynamicDefaults setBool:YES forKey:@"System -> 3rd-party Services -> Built with Sparkle Framework"];
#else
	[dynamicDefaults setBool:NO forKey:@"System -> 3rd-party Services -> Built with Sparkle Framework"];
#endif

#if TEXTUAL_BUILT_WITH_ICLOUD_SUPPORT == 1
	[dynamicDefaults setBool:YES forKey:@"System -> Built with iCloud Support"];
#else
	[dynamicDefaults setBool:NO forKey:@"System -> Built with iCloud Support"];
#endif

#if TEXTUAL_BUILT_WITH_LICENSE_MANAGER == 1
	[dynamicDefaults setBool:YES forKey:@"System -> Built with License Manager Backend"];
#else
	[dynamicDefaults setBool:NO forKey:@"System -> Built with License Manager Backend"];
#endif

#if TEXTUAL_BUILT_WITH_ADVANCED_ENCRYPTION == 1
	[dynamicDefaults setBool:YES forKey:@"System -> Built with Off-the-Record Messaging Support"];
#else
	[dynamicDefaults setBool:NO forKey:@"System -> Built with Off-the-Record Messaging Support"];
#endif

	[RZUserDefaults() registerDefaults:dynamicDefaults];

	[TPCPreferences registerPreferencesDictionaryVersion];
}

+ (void)registerDefaults
{
	NSDictionary *localDefaults =
	[TPCResourceManager loadContentsOfPropertyListInResources:@"RegisteredUserDefaults"];

	[[NSUserDefaults standardUserDefaults] registerDefaults:localDefaults];

	NSDictionary *containerDefaults =
	[TPCResourceManager loadContentsOfPropertyListInResources:@"RegisteredUserDefaultsInContainer"];

	[RZUserDefaults() registerDefaults:containerDefaults];

	[TPCPreferences registerDynamicDefaults];
}

+ (void)initPreferences
{
	[TPCApplicationInfo incrementApplicationRunCount];

	// ====================================================== //

	[TPCPreferencesUserDefaults repairPreferences];

#if TEXTUAL_BUILT_INSIDE_SANDBOX == 0
	[TPCPreferencesUserDefaults migratePreferences];
#endif

	[TPCPreferences _migratePreferencesToVersion602];

	[TPCPreferences registerDefaults];

	[TPCPreferences _migrateWorldControllerToVersion600];

#if TEXTUAL_BUILT_WITH_SPARKLE_ENABLED == 1
	[TPCPreferences _migrateSparkleConfigurationToVersion601];
#endif

	[TPCPathInfo startUsingTranscriptFolderURL];

	[RZUserDefaults() addObserver:(id)self forKeyPath:@"Highlight List -> Excluded Matches" options:NSKeyValueObservingOptionNew context:NULL];
	[RZUserDefaults() addObserver:(id)self forKeyPath:@"Highlight List -> Primary Matches" options:NSKeyValueObservingOptionNew context:NULL];

	[TPCPreferences _loadExcludeKeywords];
	[TPCPreferences _loadMatchKeywords];

	[TPCPreferences observeReloadableNotifications];
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
