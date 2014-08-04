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

@implementation TVCMemberListMavericksDarkUserInterface

- (NSInteger)cellRowHeight
{
	return 20.0;
}

- (NSImage *)rowSelectionImageForActiveWindow
{
	return [NSImage imageNamed:@"MavericksDarkChannelCellSelection"];
}

- (NSImage *)rowSelectionImageForInactiveWindow
{
	return [NSImage imageNamed:@"MavericksDarkChannelCellSelection"];
}

- (NSColor *)userMarkBadgeBackgroundColorForGraphite
{
	return [NSColor colorWithCalibratedRed:0.187 green:0.187 blue:0.187 alpha:1.0];
}

- (NSColor *)userMarkBadgeBackgroundColorForAqua
{
	return [NSColor colorWithCalibratedRed:0.187 green:0.187 blue:0.187 alpha:1.0];
}

- (NSColor *)userMarkBadgeSelectedBackgroundColor
{
	return [NSColor whiteColor];
}

- (NSColor *)userMarkBadgeNormalTextColor
{
	return [NSColor whiteColor];
}

- (NSColor *)userMarkBadgeSelectedTextColor
{
	return [NSColor colorWithCalibratedRed:0.140 green:0.140 blue:0.140 alpha:1.0];
}

- (NSColor *)userMarkBadgeShadowColor
{
	return [NSColor colorWithCalibratedRed:0.234 green:0.234 blue:0.234 alpha:1.0];
}

- (NSFont *)normalCellFont
{
	return [NSFont fontWithName:@"LucidaGrande" size:12.0];
}

- (NSFont *)selectedCellFont
{
	return [RZFontManager() fontWithFamily:@"Lucida Grande" traits:0 weight:9 size:12.0];
}

- (NSColor *)normalCellTextColor
{
	return [NSColor whiteColor];
}

- (NSColor *)awayUserCellTextColor
{
	return [NSColor colorWithCalibratedWhite:1.0 alpha:0.6];
}

- (NSColor *)selectedCellTextColor
{
	return [NSColor colorWithCalibratedRed:0.140 green:0.140 blue:0.140 alpha:1.0];
}

- (NSColor *)normalCellTextShadowColor
{
	return [NSColor colorWithCalibratedWhite:0.00 alpha:0.90];
}

- (NSColor *)normalSelectedCellTextShadowColorForActiveWindow
{
	return [NSColor colorWithCalibratedWhite:1.00 alpha:0.30];
}

- (NSColor *)normalSelectedCellTextShadowColorForInactiveWindow
{
	return [NSColor colorWithCalibratedWhite:1.00 alpha:0.30];
}

- (NSColor *)graphiteSelectedCellTextShadowColorForActiveWindow
{
	return [NSColor colorWithCalibratedRed:0.066 green:0.285 blue:0.492 alpha:1.0];
}

- (NSColor *)memberListBackgroundColorForActiveWindow
{
	return [NSColor colorWithCalibratedRed:0.148 green:0.148 blue:0.148 alpha:1.0];
}

- (NSColor *)memberListBackgroundColorForInactiveWindow
{
	return [NSColor colorWithCalibratedRed:0.148 green:0.148 blue:0.148 alpha:1.0];
}

@end
