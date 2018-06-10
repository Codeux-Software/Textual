/* *********************************************************************
 *                  _____         _               _
 *                 |_   _|____  _| |_ _   _  __ _| |
 *                   | |/ _ \ \/ / __| | | |/ _` | |
 *                   | |  __/>  <| |_| |_| | (_| | |
 *                   |_|\___/_/\_\\__|\__,_|\__,_|_|
 *
 *    Copyright (c) 2018 Codeux Software, LLC & respective contributors.
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

#import "TVCAppearance.h"

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, TVCMainWindowAppearanceType)
{
	TVCMainWindowAppearanceMavericksAquaLightType,
	TVCMainWindowAppearanceMavericksAquaDarkType,
	TVCMainWindowAppearanceMavericksGraphiteLightType,
	TVCMainWindowAppearanceMavericksGraphiteDarkType,
	TVCMainWindowAppearanceYosemiteLightType,
	TVCMainWindowAppearanceYosemiteDarkType,
	TVCMainWindowAppearanceMojaveLightType,
	TVCMainWindowAppearanceMojaveDarkType,
};

@class TVCServerListAppearance, TVCMemberListAppearance, TVCMainWindowAppearance;

/* TVCMainWindowAppearanceProperties is offered as a protocl so that
 childen appearances can return the same proeprties without whoever
 is accessing the child having to call up the chain.
 The child will do that for it so the call is shorter. */
@protocol TVCMainWindowAppearanceProperties <NSObject>
@property (readonly, weak) TVCMainWindowAppearance *parentAppearance;

@property (readonly) TVCMainWindowAppearanceType appearanceType;

@property (readonly) BOOL isDarkAppearance;
@property (readonly) BOOL isHighResolutionAppearance;
@property (readonly) BOOL isModernAppearance; // Anything newer or equal to OS X Yosemite
@end

@interface TVCMainWindowAppearance : TVCAppearance <TVCMainWindowAppearanceProperties>
@property (readonly, copy) NSString *appearanceName;

@property (readonly) TVCServerListAppearance *serverList;
@property (readonly) TVCMemberListAppearance *memberList;

@property (readonly, copy, nullable) NSColor *channelViewOverlayDefaultBackgroundColorActiveWindow;
@property (readonly, copy, nullable) NSColor *channelViewOverlayDefaultBackgroundColorInactiveWindow;

@property (readonly, copy, nullable) NSColor *splitViewDividerColor;

@property (readonly, copy, nullable) NSColor *titlebarAccessoryViewBackgroundColorActiveWindow;
@property (readonly, copy, nullable) NSColor *titlebarAccessoryViewBackgroundColorInactiveWindow;
@end

typedef NS_ENUM(NSUInteger, TVCMainWindowAppearanceUpdateType)
{
	TVCMainWindowAppearanceEverythingUpdateType,
	TVCMainWindowAppearanceSelectionUpdateType
};

@protocol TVCMainWindowAppearanceUpdateTarget <NSObject>
- (void)updateAppearance;
- (void)updateAppearanceWithType:(TVCMainWindowAppearanceUpdateType)updateType;
@end

NS_ASSUME_NONNULL_END
