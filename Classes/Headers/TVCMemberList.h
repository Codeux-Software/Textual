/* ********************************************************************* 
       _____        _               _    ___ ____   ____
      |_   _|___  _| |_ _   _  __ _| |  |_ _|  _ \ / ___|
       | |/ _ \ \/ / __| | | |/ _` | |   | || |_) | |
       | |  __/>  <| |_| |_| | (_| | |   | ||  _ <| |___
       |_|\___/_/\_\\__|\__,_|\__,_|_|  |___|_| \_\\____|

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

@interface TVCMemberList : NSOutlineView
@property (nonatomic, uweak) id keyDelegate;
@property (nonatomic, strong) id badgeRenderer;
@property (nonatomic, assign) BOOL setHiddenByUser;

/* Additions & Removals. */
- (void)addItemToList:(NSInteger)index;

- (void)removeItemFromList:(id)oldObject;

/* Drawing. */
- (void)beginGroupedUpdates;
- (void)endGroupedUpdates;

- (BOOL)updatesArePaging;

- (void)reloadAllDrawings;
- (void)reloadAllUserInterfaceElements;

- (void)reloadSelectionDrawingForRow:(NSInteger)row;
- (void)reloadSelectionDrawingBySelectingItemsInIndexSet:(NSIndexSet *)rows;

- (void)updateDrawingForMember:(IRCUser *)cellItem;
- (void)updateDrawingForRow:(NSInteger)rowIndex;

- (void)updateBackgroundColor;

/* Badge renderer. */
- (void)createBadgeRenderer;

/* Event monitor. */
- (void)destroyUserInfoPopoverOnWindowKeyChange;

/* User interface elements. */
- (NSColor *)normalCellTextColor;
- (NSColor *)awayUserCellTextColor;

- (NSColor *)normalCellTextShadowColor;
- (NSColor *)normalSelectedCellTextShadowColorForActiveWindow;
- (NSColor *)normalSelectedCellTextShadowColorForInactiveWindow;
- (NSColor *)graphiteSelectedCellTextShadowColorForActiveWindow;

- (NSColor *)selectedCellTextColor;

- (NSPoint)userMarkBadgeTextOrigin_Normal;
- (NSPoint)userMarkBadgeTextOrigin_AtSign; /* @ */
- (NSPoint)userMarkBadgeTextOrigin_AndSign; /* & */
- (NSPoint)userMarkBadgeTextOrigin_PercentSign; /* % */
- (NSPoint)userMarkBadgeTextOrigin_ExclamationMark; /* ! */

- (NSColor *)userMarkBadgeBackgroundColor_YDefault;
- (NSColor *)userMarkBadgeBackgroundColor_ADefault;
- (NSColor *)userMarkBadgeBackgroundColor_HDefault;
- (NSColor *)userMarkBadgeBackgroundColor_ODefault;
- (NSColor *)userMarkBadgeBackgroundColor_QDefault;
- (NSColor *)userMarkBadgeBackgroundColor_VDefault;

- (NSColor *)userMarkBadgeBackgroundColor_Y;
- (NSColor *)userMarkBadgeBackgroundColor_A;
- (NSColor *)userMarkBadgeBackgroundColor_H;
- (NSColor *)userMarkBadgeBackgroundColor_O;
- (NSColor *)userMarkBadgeBackgroundColor_Q;
- (NSColor *)userMarkBadgeBackgroundColor_V;
- (NSColor *)userMarkBadgeBackgroundColor_XAqua;
- (NSColor *)userMarkBadgeBackgroundColor_XGraphite;
- (NSColor *)userMarkBadgeNormalTextColor;
- (NSColor *)userMarkBadgeSelectedBackgroundColor;
- (NSColor *)userMarkBadgeSelectedTextColor;
- (NSColor *)userMarkBadgeShadowColor;

- (NSFont *)normalCellFont;
- (NSFont *)selectedCellFont;
- (NSFont *)userMarkBadgeFont;

- (NSInteger)userMarkBadgeHeight;
- (NSInteger)userMarkBadgeMargin;
- (NSInteger)userMarkBadgeWidth;
@end

@interface TVCMemberListScrollClipView : NSClipView
@end

@interface TVCMemberListScrollView : NSScrollView
@end

@interface NSObject (TVCMemberListDelegate)
- (void)memberListViewKeyDown:(NSEvent *)e;
@end
