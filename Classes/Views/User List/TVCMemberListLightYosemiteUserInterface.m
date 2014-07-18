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

@implementation TVCMemberListDarkYosemiteUserInterface

+ (NSInteger)cellRowHeight
{
	return 20.0;
}

+ (NSColor *)userMarkBadgeBackgroundColorForActiveWindow
{
	return [NSColor colorWithCalibratedWhite:0.15 alpha:1.0];
}

+ (NSColor *)userMarkBadgeBackgroundColorForInactiveWindow
{
	return [NSColor colorWithCalibratedWhite:0.15 alpha:1.0];
}

+ (NSColor *)normalCellTextColorForActiveWindow
{
	return [NSColor colorWithCalibratedWhite:0.8 alpha:1.0];
}

+ (NSColor *)awayUserCellTextColorForActiveWindow
{
	return [NSColor colorWithCalibratedWhite:0.8 alpha:1.0];
}

+ (NSColor *)normalCellTextColorForInactiveWindow
{
	return [NSColor colorWithCalibratedWhite:0.9 alpha:1.0];
}

+ (NSColor *)awayUserCellTextColorForInactiveWindow
{
	return [NSColor colorWithCalibratedWhite:0.9 alpha:1.0];
}

+ (NSColor *)selectedCellTextColorForActiveWindow
{
	return [NSColor colorWithCalibratedWhite:0.7 alpha:1.0];
}

+ (NSColor *)selectedCellTextColorForInactiveWindow
{
	return [NSColor colorWithCalibratedWhite:0.7 alpha:1.0];
}

+ (NSColor *)userMarkBadgeNormalTextColor
{
	return [NSColor whiteColor];
}

+ (NSColor *)userMarkBadgeSelectedBackgroundColor
{
	return [NSColor whiteColor];
}

+ (NSColor *)userMarkBadgeSelectedTextColor
{
	return [NSColor colorWithCalibratedRed:0.232 green:0.232 blue:0.232 alpha:1.0];
}

+ (NSColor *)rowSelectionColorForActiveWindow
{
	return [NSColor colorWithCalibratedWhite:0.2 alpha:1.0];
}

+ (NSColor *)rowSelectionColorForInactiveWindow
{
	return [NSColor colorWithCalibratedWhite:0.2 alpha:1.0];
}

+ (NSColor *)memberListBackgroundColorForActiveWindow
{
	return nil; // Use system default.
}

+ (NSColor *)memberListBackgroundColorForInactiveWindow
{
	return nil; // Use system default.
}

@end
