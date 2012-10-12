/* ********************************************************************* 
       _____        _               _    ___ ____   ____
      |_   _|___  _| |_ _   _  __ _| |  |_ _|  _ \ / ___|
       | |/ _ \ \/ / __| | | |/ _` | |   | || |_) | |
       | |  __/>  <| |_| |_| | (_| | |   | ||  _ <| |___
       |_|\___/_/\_\\__|\__,_|\__,_|_|  |___|_| \_\\____|

 Copyright (c) 2010 — 2012 Codeux Software & respective contributors.
        Please see Contributors.pdf and Acknowledgements.pdf

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

@interface TVCMemberList : TVCListView
@property (nonatomic, strong) NSFont *layoutBadgeFont;
@property (nonatomic, strong) NSFont *layoutUserCellFont;
@property (nonatomic, strong) NSFont *layoutUserCellSelectionFont;
@property (nonatomic, assign) NSInteger layoutBadgeMargin;
@property (nonatomic, assign) NSInteger layoutBadgeHeight;
@property (nonatomic, assign) NSInteger layoutBadgeWidth;
@property (nonatomic, strong) NSColor *layoutBadgeTextColorTS;
@property (nonatomic, strong) NSColor *layoutBadgeTextColorNS;
@property (nonatomic, strong) NSColor *layoutBadgeShadowColor;
@property (nonatomic, strong) NSColor *layoutBadgeMessageBackgroundColorTS;
@property (nonatomic, strong) NSColor *layoutBadgeMessageBackgroundColorQ;
@property (nonatomic, strong) NSColor *layoutBadgeMessageBackgroundColorA;
@property (nonatomic, strong) NSColor *layoutBadgeMessageBackgroundColorO;
@property (nonatomic, strong) NSColor *layoutBadgeMessageBackgroundColorH;
@property (nonatomic, strong) NSColor *layoutBadgeMessageBackgroundColorV;
@property (nonatomic, strong) NSColor *layoutBadgeMessageBackgroundColorX;
@property (nonatomic, strong) NSColor *layoutUserCellFontColor;
@property (nonatomic, strong) NSColor *layoutUserCellSelectionFontColor;
@property (nonatomic, strong) NSColor *layoutUserCellShadowColor;
@property (nonatomic, strong) NSColor *layoutUserCellSelectionShadowColorAW;
@property (nonatomic, strong) NSColor *layoutUserCellSelectionShadowColorIA;
@property (nonatomic, strong) NSColor *layoutGraphiteSelectionColorAW;

- (void)updateBackgroundColor;
@end

@interface NSObject (MemberListViewDelegate)
- (void)memberListViewKeyDown:(NSEvent *)e;
@end