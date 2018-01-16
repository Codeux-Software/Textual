/* ********************************************************************* 
                  _____         _               _
                 |_   _|____  _| |_ _   _  __ _| |
                   | |/ _ \ \/ / __| | | |/ _` | |
                   | |  __/>  <| |_| |_| | (_| | |
                   |_|\___/_/\_\\__|\__,_|\__,_|_|

 Copyright (c) 2010 - 2016 Codeux Software, LLC & respective contributors.
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

#import "TPCPreferences.h"

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, TPCPreferencesReloadActionMask) {
	TPCPreferencesReloadDockIconBadgesAction						= 1 << 0,
	TPCPreferencesReloadHighlightKeywordsAction						= 1 << 1,
	TPCPreferencesReloadHighlightLoggingAction						= 1 << 2,
	TPCPreferencesReloadInputHistoryScopeAction						= 1 << 3,
	TPCPreferencesReloadMainWindowAppearanceAction					= 1 << 4,
	TPCPreferencesReloadMainWindowTransparencyLevelAction			= 1 << 5,
	TPCPreferencesReloadMemberListAction							= 1 << 6,
	TPCPreferencesReloadMemberListSortOrderAction					= 1 << 7,
	TPCPreferencesReloadMemberListUserBadgesAction					= 1 << 8,
	TPCPreferencesReloadPreferencesChangedAction					= 1 << 9,
	TPCPreferencesReloadServerListAction							= 1 << 10,
	TPCPreferencesReloadServerListUnreadBadgesAction				= 1 << 11,
	TPCPreferencesReloadStyleAction									= 1 << 12,
	TPCPreferencesReloadStyleWithTableViewsAction					= 1 << 13,
	TPCPreferencesReloadTextDirectionAction							= 1 << 14,
	TPCPreferencesReloadTextFieldFontSizeAction						= 1 << 15,
	TPCPreferencesReloadTextFieldSegmentedControllerOriginAction	= 1 << 16,

#if TEXTUAL_BUILT_WITH_SPARKLE_ENABLED == 1
	TPCPreferencesReloadSparkleFrameworkFeedURLAction				= 1 << 17,
#endif

	TPCPreferencesReloadIRCCommandCacheAction						= 1 << 19,
	TPCPreferencesReloadLogTranscriptsAction						= 1 << 21,
	TPCPreferencesReloadScrollbackSaveLimitAction					= 1 << 22,
	TPCPreferencesReloadScrollbackVisibleLimitAction				= 1 << 22,
	TPCPreferencesReloadChannelViewArrangementAction				= 1 << 23
};

@interface TPCPreferences (TPCPreferencesReload)
+ (void)performReloadActionForKeys:(NSArray<NSString *> *)keys;
+ (void)performReloadAction:(TPCPreferencesReloadActionMask)reloadAction;
@end

NS_ASSUME_NONNULL_END
