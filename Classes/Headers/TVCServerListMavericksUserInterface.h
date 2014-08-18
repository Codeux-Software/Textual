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

@property (readonly) NSInteger serverCellRowHeight;
@property (readonly) NSInteger channelCellRowHeight;

@property (readonly, copy) NSColor *serverListBackgroundColorForActiveWindow;
@property (readonly, copy) NSColor *serverListBackgroundColorForInactiveWindow;

@property (readonly, copy) NSImage *channelRowSelectionImageForActiveWindow;
@property (readonly, copy) NSImage *channelRowSelectionImageForInactiveWindow;

@property (readonly, copy) NSImage *serverRowSelectionImageForActiveWindow;
@property (readonly, copy) NSImage *serverRowSelectionImageForInactiveWindow;

@property (readonly, copy) NSFont *messageCountBadgeFont;

@property (readonly, copy) NSFont *normalChannelCellFont;
@property (readonly, copy) NSFont *selectedChannelCellFont;

@property (readonly, copy) NSFont *serverCellFont;

@property (readonly, copy) NSColor *messageCountBadgeAquaBackgroundColor;
@property (readonly, copy) NSColor *messageCountBadgeGraphtieBackgroundColor;

@property (readonly, copy) NSColor *messageCountHighlightedBadgeBackgroundColorForActiveWindow;
@property (readonly, copy) NSColor *messageCountHighlightedBadgeBackgroundColorForInactiveWindow;

@property (readonly, copy) NSColor *messageCountNormalBadgeTextColorForActiveWindow;
@property (readonly, copy) NSColor *messageCountNormalBadgeTextColorForInactiveWindow;

@property (readonly, copy) NSColor *messageCountHighlightedBadgeTextColor;

@property (readonly, copy) NSColor *messageCountSelectedBadgeTextColorForActiveWindow;
@property (readonly, copy) NSColor *messageCountSelectedBadgeTextColorForInactiveWindow;

@property (readonly, copy) NSColor *messageCountSelectedBadgeBackgroundColorForActiveWindow;
@property (readonly, copy) NSColor *messageCountSelectedBadgeBackgroundColorForInactiveWindow;

@property (readonly, copy) NSColor *messageCountBadgeShadowColor;

@property (readonly, copy) NSColor *serverCellNormalTextColor;
@property (readonly, copy) NSColor *serverCellDisabledTextColor;

@property (readonly, copy) NSColor *serverCellNormalTextShadowColorForActiveWindow;
@property (readonly, copy) NSColor *serverCellNormalTextShadowColorForInactiveWindow;

@property (readonly, copy) NSColor *serverCellSelectedTextColorForActiveWindow;
@property (readonly, copy) NSColor *serverCellSelectedTextColorForInactiveWindow;

@property (readonly, copy) NSColor *serverCellSelectedTextShadowColorForActiveWindow;
@property (readonly, copy) NSColor *serverCellSelectedTextShadowColorForInactiveWindow;

@property (readonly, copy) NSColor *channelCellNormalTextColor;
@property (readonly, copy) NSColor *channelCellDisabledTextColor;

@property (readonly, copy) NSColor *channelCellNormalTextShadowColor;

@property (readonly, copy) NSColor *channelCellSelectedTextColorForActiveWindow;
@property (readonly, copy) NSColor *channelCellSelectedTextColorForInactiveWindow;

@property (readonly, copy) NSColor *channelCellSelectedTextShadowColorForActiveWindow;
@property (readonly, copy) NSColor *channelCellSelectedTextShadowColorForInactiveWindow;

@property (readonly, copy) NSColor *graphiteTextSelectionShadowColor;

@property (readonly) NSInteger messageCountBadgeHeight;
@property (readonly) NSInteger messageCountBadgeMinimumWidth;
@property (readonly) NSInteger messageCountBadgePadding;
@property (readonly) NSInteger messageCountBadgeRightMargin;
@end

@interface TVCServerListMavericksLightUserInterface : TVCServerListMavericksUserInterface
@end

@interface TVCServerListMavericksDarkUserInterface : TVCServerListMavericksUserInterface
@end
