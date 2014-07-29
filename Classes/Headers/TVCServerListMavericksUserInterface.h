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

@interface TVCServerListMavericksUserInterface : TVCServerListSharedUserInterface
- (NSImage *)disclosureTriangleInContext:(BOOL)up selected:(BOOL)selected;

- (NSString *)privateMessageStatusIconFilename:(BOOL)isActive selected:(BOOL)selected;

- (NSInteger)serverCellRowHeight;
- (NSInteger)channelCellRowHeight;

- (NSColor *)serverListBackgroundColor;

- (NSImage *)channelRowSelectionImageForActiveWindow;
- (NSImage *)channelRowSelectionImageForInactiveWindow;

- (NSImage *)serverRowSelectionImageForActiveWindow;
- (NSImage *)serverRowSelectionImageForInactiveWindow;

- (NSFont *)messageCountBadgeFont;

- (NSFont *)normalChannelCellFont;
- (NSFont *)selectedChannelCellFont;

- (NSFont *)serverCellFont;

- (NSColor *)messageCountBadgeAquaBackgroundColor;
- (NSColor *)messageCountBadgeGraphtieBackgroundColor;

- (NSColor *)messageCountHighlightedBadgeBackgroundColorForActiveWindow;
- (NSColor *)messageCountHighlightedBadgeBackgroundColorForInactiveWindow;

- (NSColor *)messageCountNormalBadgeTextColorForActiveWindow;
- (NSColor *)messageCountNormalBadgeTextColorForInactiveWindow;

- (NSColor *)messageCountHighlightedBadgeTextColor;

- (NSColor *)messageCountSelectedBadgeTextColorForActiveWindow;
- (NSColor *)messageCountSelectedBadgeTextColorForInactiveWindow;

- (NSColor *)messageCountSelectedBadgeBackgroundColorForActiveWindow;
- (NSColor *)messageCountSelectedBadgeBackgroundColorForInactiveWindow;

- (NSColor *)messageCountBadgeShadowColor;

- (NSColor *)serverCellNormalTextColor;
- (NSColor *)serverCellDisabledTextColor;

- (NSColor *)serverCellNormalTextShadowColorForActiveWindow;
- (NSColor *)serverCellNormalTextShadowColorForInactiveWindow;

- (NSColor *)serverCellSelectedTextColorForActiveWindow;
- (NSColor *)serverCellSelectedTextColorForInactiveWindow;

- (NSColor *)serverCellSelectedTextShadowColorForActiveWindow;
- (NSColor *)serverCellSelectedTextShadowColorForInactiveWindow;

- (NSColor *)channelCellNormalTextColor;
- (NSColor *)channelCellDisabledTextColor;

- (NSColor *)channelCellNormalTextShadowColor;

- (NSColor *)channelCellSelectedTextColorForActiveWindow;
- (NSColor *)channelCellSelectedTextColorForInactiveWindow;

- (NSColor *)channelCellSelectedTextShadowColorForActiveWindow;
- (NSColor *)channelCellSelectedTextShadowColorForInactiveWindow;

- (NSColor *)graphiteTextSelectionShadowColor;

- (NSInteger)messageCountBadgeHeight;
- (NSInteger)messageCountBadgeMinimumWidth;
- (NSInteger)messageCountBadgePadding;
- (NSInteger)messageCountBadgeRightMargin;
@end

@interface TVCServerListMavericksLightUserInterface : TVCServerListMavericksUserInterface
@end

@interface TVCServerListMavericksDarkUserInterface : TVCServerListMavericksUserInterface
@end
