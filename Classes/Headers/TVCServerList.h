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

@interface TVCServerList : NSOutlineView
@property (nonatomic, uweak) id keyDelegate;
@property (nonatomic, nweak) IBOutlet NSVisualEffectView *visualEffectView;

/* addItemToList and removeItemFromList work two completely different ways. 
 addItemToList expects that you have already added the item to the data source
 and that you are giving the list the index of the newly inserted item relative
 to the parent group. The list then manages that object. */
- (void)addItemToList:(NSInteger)index inParent:(id)parent;

/* removeItemFromList does not care about the index of an object as long as the
 object exists in the list. It will look for it anywhere. It checks if the item
 is a parent group or just a child and removes it based on that context. */
- (void)removeItemFromList:(id)oldObject;

/* Drawing. */
- (void)reloadAllDrawings;

- (void)updateDrawingForItem:(IRCTreeItem *)cellItem;
- (void)updateDrawingForRow:(NSInteger)rowIndex;

- (void)updateBackgroundColor;

@property (NS_NONATOMIC_IOSONLY, readonly, strong) id userInterfaceObjects;
@end

@interface TVCServerListSharedUserInterface : NSObject
+ (void)setOutlineViewDefaultDisclosureTriangle:(NSImage *)image;
+ (void)setOutlineViewAlternateDisclosureTriangle:(NSImage *)image;

+ (NSImage *)disclosureTriangleInContext:(BOOL)up selected:(BOOL)selected;

+ (BOOL)yosemiteIsUsingVibrantDarkMode;

+ (NSColor *)serverListBackgroundColor;
@end

@interface TVCServerListMavericksUserInterface : TVCServerListSharedUserInterface
@end

@interface TVCServerListLightYosemiteUserInterface : TVCServerListSharedUserInterface
+ (NSColor *)rowSelectionColorForActiveWindow;
+ (NSColor *)rowSelectionColorForInactiveWindow;

+ (NSColor *)serverListBackgroundColorForActiveWindow;
+ (NSColor *)serverListBackgroundColorForInactiveWindow;

+ (NSString *)privateMessageStatusIconFilename:(BOOL)isActive;

+ (NSColor *)channelCellNormalItemTextColorForActiveWindow;
+ (NSColor *)channelCellNormalItemTextColorForInactiveWindow;

+ (NSColor *)channelCellDisabledItemTextColorForActiveWindow;
+ (NSColor *)channelCellDisabledItemTextColorForInactiveWindow;

+ (NSColor *)channelCellErroneousItemTextColorForActiveWindow;
+ (NSColor *)channelCellErroneousItemTextColorForInactiveWindow;

+ (NSColor *)channelCellHighlightedItemTextColorForActiveWindow;
+ (NSColor *)channelCellHighlightedItemTextColorForInactiveWindow;

+ (NSColor *)channelCellSelectedTextColorForActiveWindow;
+ (NSColor *)channelCellSelectedTextColorForInactiveWindow;

+ (NSColor *)serverCellDisabledItemTextColorForActiveWindow;
+ (NSColor *)serverCellDisabledItemTextColorForInactiveWindow;

+ (NSColor *)serverCellNormalItemTextColorForActiveWindow;
+ (NSColor *)serverCellNormalItemTextColorForInactiveWindow;

+ (NSColor *)serverCellSelectedTextColorForActiveWindow;
+ (NSColor *)serverCellSelectedTextColorForInactiveWindow;

+ (NSColor *)messageCountNormalBadgeTextColorForActiveWindow;
+ (NSColor *)messageCountNormalBadgeTextColorForInactiveWindow;

+ (NSColor *)messageCountSelectedBadgeTextColorForActiveWindow;;
+ (NSColor *)messageCountSelectedBadgeTextColorForInactiveWindow;

+ (NSColor *)messageCountNormalBadgeBackgroundColorForActiveWindow;
+ (NSColor *)messageCountNormalBadgeBackgroundColorForInactiveWindow;

+ (NSColor *)messageCountSelectedBadgeBackgroundColorForActiveWindow;
+ (NSColor *)messageCountSelectedBadgeBackgroundColorForInactiveWindow;

+ (NSColor *)messageCountHighlightedBadgeBackgroundColorForActiveWindow;
+ (NSColor *)messageCountHighlightedBadgeBackgroundColorForInactiveWindow;

+ (NSFont *)messageCountBadgeFont;

+ (NSInteger)messageCountBadgeHeight;
+ (NSInteger)messageCountBadgeMinimumWidth;
+ (NSInteger)messageCountBadgePadding;
+ (NSInteger)messageCountBadgeRightMargin;

+ (NSInteger)channelCellTextFieldWithBadgeRightMargin;
@end

@interface TVCServerListDarkYosemiteUserInterface : TVCServerListSharedUserInterface
+ (NSColor *)rowSelectionColorForActiveWindow;
+ (NSColor *)rowSelectionColorForInactiveWindow;

+ (NSColor *)serverListBackgroundColorForActiveWindow;
+ (NSColor *)serverListBackgroundColorForInactiveWindow;

+ (NSString *)privateMessageStatusIconFilename:(BOOL)isActive;

+ (NSColor *)channelCellNormalItemTextColorForActiveWindow;
+ (NSColor *)channelCellNormalItemTextColorForInactiveWindow;

+ (NSColor *)channelCellDisabledItemTextColorForActiveWindow;
+ (NSColor *)channelCellDisabledItemTextColorForInactiveWindow;

+ (NSColor *)channelCellErroneousItemTextColorForActiveWindow;
+ (NSColor *)channelCellErroneousItemTextColorForInactiveWindow;

+ (NSColor *)channelCellHighlightedItemTextColorForActiveWindow;
+ (NSColor *)channelCellHighlightedItemTextColorForInactiveWindow;

+ (NSColor *)channelCellSelectedTextColorForActiveWindow;
+ (NSColor *)channelCellSelectedTextColorForInactiveWindow;

+ (NSColor *)serverCellDisabledItemTextColorForActiveWindow;
+ (NSColor *)serverCellDisabledItemTextColorForInactiveWindow;

+ (NSColor *)serverCellNormalItemTextColorForActiveWindow;
+ (NSColor *)serverCellNormalItemTextColorForInactiveWindow;

+ (NSColor *)serverCellSelectedTextColorForActiveWindow;
+ (NSColor *)serverCellSelectedTextColorForInactiveWindow;

+ (NSColor *)messageCountNormalBadgeTextColorForActiveWindow;
+ (NSColor *)messageCountNormalBadgeTextColorForInactiveWindow;

+ (NSColor *)messageCountSelectedBadgeTextColorForActiveWindow;
+ (NSColor *)messageCountSelectedBadgeTextColorForInactiveWindow;

+ (NSColor *)messageCountNormalBadgeBackgroundColorForActiveWindow;
+ (NSColor *)messageCountNormalBadgeBackgroundColorForInactiveWindow;

+ (NSColor *)messageCountSelectedBadgeBackgroundColorForActiveWindow;
+ (NSColor *)messageCountSelectedBadgeBackgroundColorForInactiveWindow;

+ (NSColor *)messageCountHighlightedBadgeBackgroundColorForActiveWindow;
+ (NSColor *)messageCountHighlightedBadgeBackgroundColorForInactiveWindow;

+ (NSFont *)messageCountBadgeFont;

+ (NSInteger)messageCountBadgeHeight;
+ (NSInteger)messageCountBadgeMinimumWidth;
+ (NSInteger)messageCountBadgePadding;
+ (NSInteger)messageCountBadgeRightMargin;

+ (NSInteger)channelCellTextFieldWithBadgeRightMargin;
@end

@protocol TVCServerListDelegate <NSObject>
@required

- (void)serverListKeyDown:(NSEvent *)e;
@end
