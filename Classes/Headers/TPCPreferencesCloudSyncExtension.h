/* ********************************************************************* 
                  _____         _               _
                 |_   _|____  _| |_ _   _  __ _| |
                   | |/ _ \ \/ / __| | | |/ _` | |
                   | |  __/>  <| |_| |_| | (_| | |
                   |_|\___/_/\_\\__|\__,_|\__,_|_|

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

typedef enum TPCPreferencesKeyReloadActionMask : NSInteger {
	TPCPreferencesKeyReloadDockIconBadgesAction							= 1 << 0,
	TPCPreferencesKeyReloadHighlightKeywordsAction						= 1 << 1,
	TPCPreferencesKeyReloadHighlightLoggingAction						= 1 << 2,
	TPCPreferencesKeyReloadInputHistoryScopeAction						= 1 << 3,
    TPCPreferencesKeyReloadMainWindowAppearanceAction					= 1 << 4,  // Redraws all window elements including text field, lists, and center view to match appearance.
	TPCPreferencesKeyReloadMainWindowTransparencyLevelAction			= 1 << 5,
	TPCPreferencesKeyReloadMemberListAction								= 1 << 6, // Redraws apperance of member list and associated views. Usually unnecessary to call directly. Use window appearance instead.
	TPCPreferencesKeyReloadMemberListSortOrderAction					= 1 << 7,
	TPCPreferencesKeyReloadMemberListUserBadgesAction					= 1 << 8, // Redraws all items in member list and does not update the actual appearance of the member list.
	TPCPreferencesKeyReloadPreferencesChangedAction						= 1 << 9, // Invokes -preferencesChanged on all views from top, down.
	TPCPreferencesKeyReloadServerListAction								= 1 << 10, // Redraws appearance of server list and associated views. Usually unncessary to call directly. Use window appearance instead.
	TPCPreferencesKeyReloadServerListUnreadBadgesAction					= 1 << 11, // Redraw the individual unread badges in the server list
	TPCPreferencesKeyReloadStyleAction									= 1 << 12, // Reloads the style without reloading window appearance.
	TPCPreferencesKeyReloadStyleWithTableViewsAction					= 1 << 13, // Reloads the style as well as the window appearance.
	TPCPreferencesKeyReloadTextDirectionAction							= 1 << 14,
	TPCPreferencesKeyReloadTextFieldFontSizeAction						= 1 << 15,
	TPCPreferencesKeyReloadTextFieldSegmentedControllerOriginAction		= 1 << 16
} TPCPreferencesKeyReloadActionMask;

#if TEXTUAL_BUILT_WITH_ICLOUD_SUPPORT == 1
TEXTUAL_EXTERN NSString * const TPCPreferencesCloudSyncKeyValueStoreServicesDefaultsKey;
TEXTUAL_EXTERN NSString * const TPCPreferencesCloudSyncKeyValueStoreServicesLimitedToServersDefaultsKey;
#endif

@interface TPCPreferences (TPCPreferencesCloudSyncExtension)
#if TEXTUAL_BUILT_WITH_ICLOUD_SUPPORT == 1
+ (BOOL)syncPreferencesToTheCloud;
+ (BOOL)syncPreferencesToTheCloudLimitedToServers;
#endif

+ (void)performReloadActionForKeyValues:(NSArray *)prefKeys;
+ (void)performReloadActionForActionType:(TPCPreferencesKeyReloadActionMask)reloadAction;
@end
