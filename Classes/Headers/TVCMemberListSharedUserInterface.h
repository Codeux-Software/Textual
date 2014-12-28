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

@interface TVCMemberListSharedUserInterface : NSObject
+ (BOOL)yosemiteIsUsingVibrantDarkMode;

- (NSImage *)cachedUserMarkBadgeForSymbol:(NSString *)mark rank:(IRCUserRank)rank;
- (void)cacheUserMarkBadge:(NSImage *)badgeImage forSymbol:(NSString *)mark rank:(IRCUserRank)rank;

- (void)invalidateAllUserMarkBadgeCaches;

@property (readonly, copy) NSColor *memberListBackgroundColorForActiveWindow;
@property (readonly, copy) NSColor *memberListBackgroundColorForInactiveWindow;

@property (readonly, copy) NSColor *userMarkBadgeBackgroundColor_Y;
@property (readonly, copy) NSColor *userMarkBadgeBackgroundColor_A;
@property (readonly, copy) NSColor *userMarkBadgeBackgroundColor_H;
@property (readonly, copy) NSColor *userMarkBadgeBackgroundColor_O;
@property (readonly, copy) NSColor *userMarkBadgeBackgroundColor_Q;
@property (readonly, copy) NSColor *userMarkBadgeBackgroundColor_V;

@property (readonly, copy) NSColor *userMarkBadgeBackgroundColor_YDefault;
@property (readonly, copy) NSColor *userMarkBadgeBackgroundColor_ADefault;
@property (readonly, copy) NSColor *userMarkBadgeBackgroundColor_HDefault;
@property (readonly, copy) NSColor *userMarkBadgeBackgroundColor_ODefault;
@property (readonly, copy) NSColor *userMarkBadgeBackgroundColor_QDefault;
@property (readonly, copy) NSColor *userMarkBadgeBackgroundColor_VDefault;

@property (readonly, copy) NSFont *userMarkBadgeFont;
@property (readonly, copy) NSFont *userMarkBadgeFontSelected;

@property (readonly, copy) NSFont *userMarkBadgeFontForRetina;
@property (readonly, copy) NSFont *userMarkBadgeFontSelectedForRetina;

@property (readonly) NSInteger userMarkBadgeHeight;
@property (readonly) NSInteger userMarkBadgeWidth;
@end

@interface TVCMemberListMavericksUserInterfaceBackground : NSBox
@end
