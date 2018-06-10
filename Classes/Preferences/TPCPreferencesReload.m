/* *********************************************************************
 *                  _____         _               _
 *                 |_   _|____  _| |_ _   _  __ _| |
 *                   | |/ _ \ \/ / __| | | |/ _` | |
 *                   | |  __/>  <| |_| |_| | (_| | |
 *                   |_|\___/_/\_\\__|\__,_|\__,_|_|
 *
 * Copyright (c) 2010 - 2016 Codeux Software, LLC & respective contributors.
 *       Please see Acknowledgements.pdf for additional information.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *
 *  * Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 *  * Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 *  * Neither the name of Textual, "Codeux Software, LLC", nor the
 *    names of its contributors may be used to endorse or promote products
 *    derived from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE AUTHOR AND CONTRIBUTORS ``AS IS'' AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED. IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE LIABLE
 * FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
 * OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
 * LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
 * OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
 * SUCH DAMAGE.
 *
 *********************************************************************** */

#import "NSObjectHelperPrivate.h"
#import "TXMasterControllerPrivate.h"
#import "TPCPreferencesLocalPrivate.h"
#import "IRCClientPrivate.h"
#import "IRCChannelPrivate.h"
#import "IRCCommandIndexPrivate.h"
#import "IRCWorld.h"
#import "TLOEncryptionManagerPrivate.h"
#import "TLOInputHistoryPrivate.h"
#import "TVCDockIconPrivate.h"
#import "TVCLogControllerPrivate.h"
#import "TVCLogControllerHistoricLogFilePrivate.h"
#import "TVCMainWindowPrivate.h"
#import "TVCMainWindowTextViewPrivate.h"
#import "TVCServerListPrivate.h"
#import "TVCMemberListPrivate.h"
#import "TVCMemberListAppearance.h"
#import "TDCInAppPurchaseDialogPrivate.h"
#import "TPCPreferencesReload.h"

NS_ASSUME_NONNULL_BEGIN

#pragma mark -
#pragma mark Private

@implementation TPCPreferences (TPCPreferencesReloadPrivate)

+ (void)observeReloadableNotifications
{
#if TEXTUAL_BUILT_FOR_APP_STORE_DISTRIBUTION == 1
	[RZNotificationCenter() addObserver:self.class
							   selector:@selector(onInAppPurchaseTrialExpired:)
								   name:TDCInAppPurchaseDialogTrialExpiredNotification
								 object:nil];

	[RZNotificationCenter() addObserver:self.class
							   selector:@selector(onInAppPurchaseTransactionFinished:)
								   name:TDCInAppPurchaseDialogTransactionFinishedNotification
								 object:nil];
#endif
}

#if TEXTUAL_BUILT_FOR_APP_STORE_DISTRIBUTION == 1
+ (void)onInAppPurchaseTrialExpired:(NSNotification *)notification
{
	[self performReloadAction:TPCPreferencesReloadLogTranscriptsAction];
}

+ (void)onInAppPurchaseTransactionFinished:(NSNotification *)notification
{
	[self performReloadAction:TPCPreferencesReloadLogTranscriptsAction];
}
#endif

@end

#pragma mark -
#pragma mark Public

@implementation TPCPreferences (TPCPreferencesReload)

+ (void)performReloadActionForKeys:(NSArray<NSString *> *)keys
{
	NSParameterAssert(keys != nil);

	TPCPreferencesReloadActionMask reloadAction = 0;

	/* Style specific reloads... */
	if ([keys containsObject:@"AutomaticallyFilterUnicodeTextSpam"] ||
		[keys containsObject:@"ConversationTrackingIncludesUserModeSymbol"] ||
		[keys containsObject:@"DisableRemoteNicknameColorHashing"] ||
		[keys containsObject:@"DisplayEventInLogView -> Inline Media"] ||
		[keys containsObject:@"DisplayEventInLogView -> Join, Part, Quit"] ||
		[keys containsObject:@"Theme -> Nickname Format"] ||
		[keys containsObject:@"Theme -> Timestamp Format"] ||
		[keys containsObject:@"Theme -> Channel Font Preference Enabled"] ||
		[keys containsObject:@"Theme -> Nickname Format Preference Enabled"] ||
		[keys containsObject:@"Theme -> Timestamp Format Preference Enabled"] ||
		[keys containsObject:TPCPreferencesThemeFontNameDefaultsKey] ||
		[keys containsObject:TPCPreferencesThemeFontSizeDefaultsKey] ||
		[keys containsObject:TPCPreferencesThemeNameDefaultsKey])
	{
		reloadAction |= TPCPreferencesReloadStyleAction;
	}

	/* Highlight lists */
	if ([keys containsObject:@"Highlight List -> Excluded Matches"] ||
		[keys containsObject:@"Highlight List -> Primary Matches"])
	{
		reloadAction |= TPCPreferencesReloadHighlightKeywordsAction;
	}

	/* Highlight logging */
	if ([keys containsObject:@"LogHighlights"]) {
		reloadAction |= TPCPreferencesReloadHighlightLoggingAction;
	}

	/* Text direction: right-to-left, left-to-right */
	if ([keys containsObject:@"RightToLeftTextFormatting"]) {
		reloadAction |= TPCPreferencesReloadTextDirectionAction;
	}

	/* Text field font size */
	if ([keys containsObject:@"Main Input Text Field -> Font Size"]) {
		reloadAction |= TPCPreferencesReloadTextFieldFontSizeAction;
	}

	/* Input history scope */
	if ([keys containsObject:@"SaveInputHistoryPerSelection"]) {
		reloadAction |= TPCPreferencesReloadInputHistoryScopeAction;
	}

	/* Main window segmented controller */
	if ([keys containsObject:@"DisableMainWindowSegmentedController"]) {
		reloadAction |= TPCPreferencesReloadTextFieldSegmentedControllerOriginAction;
	}

	/* Main window alpha level */
	if ([keys containsObject:@"MainWindowTransparencyLevel"]) {
		reloadAction |= TPCPreferencesReloadMainWindowTransparencyLevelAction;
	}

	/* Dock icon */
	if ([keys containsObject:@"DisplayDockBadges"] ||
		[keys containsObject:@"DisplayPublicMessageCountInDockBadge"])
	{
		reloadAction |= TPCPreferencesReloadDockIconBadgesAction;
	}

	/* Main window appearance */
	if ([keys containsObject:@"InvertSidebarColors"]) {
		reloadAction |= TPCPreferencesReloadMainWindowAppearanceAction;
	}

	/* Member list sort order */
	if ([keys containsObject:@"MemberListSortFavorsServerStaff"]) {
		reloadAction |= TPCPreferencesReloadMemberListSortOrderAction;
	}

	/* Member list user badge colors */
	if ([keys containsObject:@"DisplayUserListNoModeSymbol"] ||
		[keys containsObject:@"User List Mode Badge Colors -> +y"] ||
		[keys containsObject:@"User List Mode Badge Colors -> +q"] ||
		[keys containsObject:@"User List Mode Badge Colors -> +a"] ||
		[keys containsObject:@"User List Mode Badge Colors -> +o"] ||
		[keys containsObject:@"User List Mode Badge Colors -> +h"] ||
		[keys containsObject:@"User List Mode Badge Colors -> +v"] ||
		[keys containsObject:@"User List Mode Badge Colors -> no mode"])
	{
		reloadAction |= TPCPreferencesReloadMemberListAction;
		reloadAction |= TPCPreferencesReloadMemberListUserBadgesAction;
	}

	/* Server list unread count badge colors */
	if ([keys containsObject:@"Server List Unread Message Count Badge Colors -> Highlight"]) {
		reloadAction |= TPCPreferencesReloadServerListUnreadBadgesAction;
	}

	/* Sparkle framework update feed URL */
#if TEXTUAL_BUILT_WITH_SPARKLE_ENABLED == 1
	if ([keys containsObject:@"ReceiveBetaUpdates"]) {
		reloadAction |= TPCPreferencesReloadSparkleFrameworkFeedURLAction;
	}
#endif

	/* Developer mode */
	if ([keys containsObject:@"TextualDeveloperEnvironment"]) {
		reloadAction |= TPCPreferencesReloadIRCCommandCacheAction;
	}

	/* Scrollback limit */
	if ([keys containsObject:@"ScrollbackMaximumSavedLineCount"]) {
		reloadAction |= TPCPreferencesReloadScrollbackSaveLimitAction;
	}

	if ([keys containsObject:@"ScrollbackMaximumVisibleLineCount"]) {
		reloadAction |= TPCPreferencesReloadScrollbackVisibleLimitAction;
	}

	/* Channel view arrangement */
	if ([keys containsObject:@"ChannelViewArrangement"]) {
		reloadAction |= TPCPreferencesReloadChannelViewArrangementAction;
	}

	/* Encryption policy */
#if TEXTUAL_BUILT_WITH_ADVANCED_ENCRYPTION == 1
	if ([keys containsObject:@"Off-the-Record Messaging -> Enable Encryption"] ||
		[keys containsObject:@"Off-the-Record Messaging -> Automatically Enable Service"] ||
		[keys containsObject:@"Off-the-Record Messaging -> Require Encryption"])
	{
		reloadAction |= TPCPreferencesReloadEncryptionPolicyAction;
	}
#endif

	/* After this is all complete; we call -preferencesChanged just to take 
	 care of everything else that does not need specific reloads. */
	reloadAction |= TPCPreferencesReloadPreferencesChangedAction;

	[self performReloadAction:reloadAction];
}

+ (void)performReloadAction:(TPCPreferencesReloadActionMask)reloadAction
{
	[self performReloadAction:reloadAction forKey:nil];
}

+ (void)performReloadAction:(TPCPreferencesReloadActionMask)reloadAction forKey:(nullable NSString *)key
{
	/* Update dock icon */
	if ((reloadAction & TPCPreferencesReloadDockIconBadgesAction) == TPCPreferencesReloadDockIconBadgesAction) {
		[TVCDockIcon updateDockIcon];
	}

	/* As reloading the theme will also reload the server and member list, we keep
	 track of whether that happened so it is not performed more than one time. */
	BOOL didReloadActiveStyle = NO;

	BOOL didReloadUserInterface = NO;

	/* Member list appearance */
	if ((reloadAction & TPCPreferencesReloadMemberListUserBadgesAction) == TPCPreferencesReloadMemberListUserBadgesAction) {
		/* We invalidate this early because a separate action may
		 which is attached to our mask may reload the drawings for
		 us so until we know if that happened, we wait. */

		/* If we know FOR CERTAIN we only are ONLY reloading the user badges
		 and we have a key for context, then be more efficient by only updating
		 drawings related to this preference. The member list automatically
		 invalidates its caches when passing a recognized key. */ 
		if (reloadAction == TPCPreferencesReloadMemberListUserBadgesAction && key != nil) {
			[mainWindowMemberList() refreshDrawingForChangesToPreference:key];
		} else {
			[mainWindowMemberList().userInterfaceObjects invalidateUserMarkBadgeCaches];
		}
	}

	/* Window appearance */
	if ((reloadAction & TPCPreferencesReloadMainWindowAppearanceAction) == TPCPreferencesReloadMainWindowAppearanceAction) {
		[mainWindow() updateBackgroundColor];

		didReloadUserInterface = YES;
	}

	/* Active style */
	if ((reloadAction & TPCPreferencesReloadStyleAction) == TPCPreferencesReloadStyleAction) {
		[mainWindow() reloadTheme];

		didReloadActiveStyle = YES;
	} else if ((reloadAction & TPCPreferencesReloadStyleWithTableViewsAction) == TPCPreferencesReloadStyleWithTableViewsAction) {
		if (didReloadUserInterface == NO) {
			didReloadUserInterface = YES;

			[mainWindow() reloadThemeAndUserInterface];
		} else {
			[mainWindow() reloadTheme];
		}

		didReloadActiveStyle = YES;
	}

	/* Server list */
	if ((reloadAction & TPCPreferencesReloadServerListAction) == TPCPreferencesReloadServerListAction) {
		if (didReloadUserInterface == NO) {
			[mainWindowServerList() updateBackgroundColor];

			[mainWindowServerList() reloadAllDrawings];
		}
	} else if ((reloadAction & TPCPreferencesReloadServerListUnreadBadgesAction) == TPCPreferencesReloadServerListUnreadBadgesAction) {
		if (didReloadUserInterface == NO) {
			/* The color used for unread badges on Yosemite also apply to the text color
			 so we must reload all drawings instead of only the badges themselves. */
			if (TEXTUAL_RUNNING_ON_YOSEMITE) {
				[mainWindowServerList() refreshAllDrawings];
			} else {
				[mainWindowServerList() refreshAllUnreadMessageCountBadges];
			}
		}
	}

	/* Member list appearance */
	if ((reloadAction & TPCPreferencesReloadMemberListAction) == TPCPreferencesReloadMemberListAction) {
		if (didReloadUserInterface == NO) {
			[mainWindowMemberList() updateBackgroundColor];
		}
	}

	/* Member list sort order */
	BOOL didReloadMemberListSortOrder = NO;

	if ((reloadAction & TPCPreferencesReloadMemberListSortOrderAction) == TPCPreferencesReloadMemberListSortOrderAction) {
		for (IRCClient *u in worldController().clientList) {
			for (IRCChannel *c in u.channelList) {
				[c reloadDataForTableViewBySortingMembers];
			}
		}

		didReloadMemberListSortOrder = YES;
	}

	/* Member list appearance */
	if ((reloadAction & TPCPreferencesReloadMemberListAction) == TPCPreferencesReloadMemberListAction) {
		/* Sort order will redraw these for us */
		if (didReloadMemberListSortOrder == NO) {
			[mainWindowMemberList() refreshAllDrawings];
		}
	}

	/* Main window segmented controller */
	if ((reloadAction & TPCPreferencesReloadTextFieldSegmentedControllerOriginAction) == TPCPreferencesReloadTextFieldSegmentedControllerOriginAction) {
		[mainWindowTextField() reloadOriginPointsAndRecalculateSize];
	}

	/* Main window alpha level */
	if ((reloadAction & TPCPreferencesReloadMainWindowTransparencyLevelAction) == TPCPreferencesReloadMainWindowTransparencyLevelAction) {
		[mainWindow() updateAlphaValueToReflectPreferences];
	}

	/* Highlight keywords */
	if ((reloadAction & TPCPreferencesReloadHighlightKeywordsAction) == TPCPreferencesReloadHighlightKeywordsAction) {
		[self cleanUpHighlightKeywords];
	}

	/* Highlight logging */
	if ((reloadAction & TPCPreferencesReloadHighlightLoggingAction) == TPCPreferencesReloadHighlightLoggingAction) {
		if ([self logHighlights] == NO) {
			for (IRCClient *u in worldController().clientList) {
				[u clearCachedHighlights];
			}
		}
	}

	/* Text direction: right-to-left, left-to-right */
	if ((reloadAction & TPCPreferencesReloadTextDirectionAction) == TPCPreferencesReloadTextDirectionAction) {
		[mainWindowTextField() updateTextDirection];

		if (didReloadActiveStyle == NO) {
			[mainWindow() reloadTheme];
		}
	}

	/* Text field font size */
	if ((reloadAction & TPCPreferencesReloadTextFieldFontSizeAction) == TPCPreferencesReloadTextFieldFontSizeAction) {
		[mainWindowTextField() updateTextBasedOnPreferredFontSize];
	}

	/* Input history scope */
	if ((reloadAction & TPCPreferencesReloadInputHistoryScopeAction) == TPCPreferencesReloadInputHistoryScopeAction) {
		[mainWindow().inputHistoryManager noteInputHistoryObjectScopeDidChange];
	}

	/* Sparkle framework update feed URL */
#if TEXTUAL_BUILT_WITH_SPARKLE_ENABLED == 1
	if ((reloadAction & TPCPreferencesReloadSparkleFrameworkFeedURLAction) == TPCPreferencesReloadSparkleFrameworkFeedURLAction) {
		[masterController() prepareThirdPartyServiceSparkleFramework];
	}
#endif

	/* Command index cache */
	if ((reloadAction & TPCPreferencesReloadIRCCommandCacheAction) == TPCPreferencesReloadIRCCommandCacheAction) {
		[IRCCommandIndex invalidateCaches];
	}

	/* Transcript folder URL */
	if ((reloadAction & TPCPreferencesReloadLogTranscriptsAction) == TPCPreferencesReloadLogTranscriptsAction) {
		for (IRCClient *u in worldController().clientList) {
			[u reopenLogFileIfNeeded];

			for (IRCChannel *c in u.channelList) {
				[c reopenLogFileIfNeeded];
			}
		}
	}

	/* Scrollback limit */
	if ((reloadAction & TPCPreferencesReloadScrollbackSaveLimitAction) == TPCPreferencesReloadScrollbackSaveLimitAction) {
		[TVCLogControllerHistoricLogSharedInstance() resetMaximumLineCount];
	}

	if ((reloadAction & TPCPreferencesReloadScrollbackVisibleLimitAction) == TPCPreferencesReloadScrollbackSaveLimitAction) {
		for (IRCClient *u in worldController().clientList) {
			[u.viewController changeScrollbackLimit];

			for (IRCChannel *c in u.channelList) {
				[c.viewController changeScrollbackLimit];
			}
		}
	}

	/* Channel view arrangement */
	if ((reloadAction & TPCPreferencesReloadChannelViewArrangementAction) == TPCPreferencesReloadChannelViewArrangementAction) {
		[mainWindow() updateChannelViewArrangement];
	}

	/* Encryption policy */
#if TEXTUAL_BUILT_WITH_ADVANCED_ENCRYPTION == 1
	if ((reloadAction & TPCPreferencesReloadEncryptionPolicyAction) == TPCPreferencesReloadEncryptionPolicyAction) {
		[sharedEncryptionManager() updatePolicy];

		/* Maybe remove title bar accessory view if encryption is disabled. */
		[mainWindow() updateTitle];
	}
#endif

	/* World controller preferences changed call */
	if ((reloadAction & TPCPreferencesReloadPreferencesChangedAction) == TPCPreferencesReloadPreferencesChangedAction) {
		[worldController() preferencesChanged];

		[mainWindow() preferencesChanged];
	}
}

@end

NS_ASSUME_NONNULL_END
