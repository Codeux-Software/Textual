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

#import "TPCPreferences.h"

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, TPCPreferencesReloadActionMask) {
	TPCPreferencesReloadAppearanceAction							= 1 << 0,
	TPCPreferencesReloadChannelViewArrangementAction				= 1 << 1,
	TPCPreferencesReloadDockIconBadgesAction						= 1 << 2,
	TPCPreferencesReloadHighlightKeywordsAction						= 1 << 3,
	TPCPreferencesReloadHighlightLoggingAction						= 1 << 4,
	TPCPreferencesReloadIRCCommandCacheAction						= 1 << 5,
	TPCPreferencesReloadInputHistoryScopeAction						= 1 << 6,
	TPCPreferencesReloadLogTranscriptsAction						= 1 << 7,
	TPCPreferencesReloadMainWindowTransparencyLevelAction			= 1 << 8,
	TPCPreferencesReloadMemberListAction							= 1 << 9,
	TPCPreferencesReloadMemberListSortOrderAction					= 1 << 10,
	TPCPreferencesReloadMemberListUserBadgesAction					= 1 << 11,
	TPCPreferencesReloadPreferencesChangedAction					= 1 << 12,
	TPCPreferencesReloadScrollbackSaveLimitAction					= 1 << 13,
	TPCPreferencesReloadScrollbackVisibleLimitAction				= 1 << 14,
	TPCPreferencesReloadServerListAction							= 1 << 15,
	TPCPreferencesReloadServerListUnreadBadgesAction				= 1 << 16,
	TPCPreferencesReloadStyleAction									= 1 << 17,
	TPCPreferencesReloadStyleWithTableViewsAction					= 1 << 18,
	TPCPreferencesReloadTextDirectionAction							= 1 << 19,
	TPCPreferencesReloadTextFieldFontSizeAction						= 1 << 20,
	TPCPreferencesReloadTextFieldSegmentedControllerOriginAction	= 1 << 21,

#if TEXTUAL_BUILT_WITH_ADVANCED_ENCRYPTION == 1
	TPCPreferencesReloadEncryptionPolicyAction						= 1 << 22,
#endif

#if TEXTUAL_BUILT_WITH_SPARKLE_ENABLED == 1
	TPCPreferencesReloadSparkleFrameworkFeedURLAction				= 1 << 23,
#endif
};

@interface TPCPreferences (TPCPreferencesReload)
+ (void)performReloadActionForKeys:(NSArray<NSString *> *)keys;
+ (void)performReloadAction:(TPCPreferencesReloadActionMask)reloadAction;
+ (void)performReloadAction:(TPCPreferencesReloadActionMask)reloadAction forKey:(nullable NSString *)key; // key is only used for context
@end

NS_ASSUME_NONNULL_END
