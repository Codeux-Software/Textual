/* ********************************************************************* 
       _____        _               _    ___ ____   ____
      |_   _|___  _| |_ _   _  __ _| |  |_ _|  _ \ / ___|
       | |/ _ \ \/ / __| | | |/ _` | |   | || |_) | |
       | |  __/>  <| |_| |_| | (_| | |   | ||  _ <| |___
       |_|\___/_/\_\\__|\__,_|\__,_|_|  |___|_| \_\\____|

 Copyright (c) 2010 — 2013 Codeux Software & respective contributors.
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

@implementation TVCMemberList

- (void)keyDown:(NSEvent *)e
{
	if (self.keyDelegate) {
		switch ([e keyCode]) {
			case 123 ... 126:
			case 116:
			case 121:
				break;
			default:
				if ([self.keyDelegate respondsToSelector:@selector(memberListViewKeyDown:)]) {
					[self.keyDelegate memberListViewKeyDown:e];
				}
				
				break;
		}
	}
}

- (void)drawContextMenuHighlightForRow:(int)row
{
    // Do not draw focus ring …
}

- (void)updateBackgroundColor
{
	[self setBackgroundColor:[self listBackgroundColor]];
}

#pragma mark -
#pragma mark User Interface Design Elements

- (NSColor *)listBackgroundColor
{
	return [NSColor defineUserInterfaceItem:[NSColor sourceListBackgroundColor]
							   invertedItem:[NSColor internalCalibratedRed:38.0 green:38.0 blue:38.0 alpha:1]];
}

- (NSColor *)userMarkBadgeBackgroundColor_XGraphite
{
	return [NSColor defineUserInterfaceItem:[NSColor internalCalibratedRed:132 green:147 blue:163 alpha:1]
							   invertedItem:[NSColor internalCalibratedRed:48 green:48 blue:48 alpha:1]];
}

- (NSColor *)userMarkBadgeBackgroundColor_XAqua
{
	return [NSColor defineUserInterfaceItem:[NSColor internalCalibratedRed:152 green:168 blue:202 alpha:1]
							   invertedItem:[NSColor internalCalibratedRed:48 green:48 blue:48 alpha:1]];
}

- (NSColor *)userMarkBadgeBackgroundColor_Q
{
	return [NSColor internalCalibratedRed:186 green:0 blue:0 alpha:1];
}

- (NSColor *)userMarkBadgeBackgroundColor_A
{
	return [NSColor internalCalibratedRed:157 green:0 blue:89 alpha:1];
}

- (NSColor *)userMarkBadgeBackgroundColor_O
{
	return [NSColor internalCalibratedRed:90 green:51 blue:156 alpha:1];
}

- (NSColor *)userMarkBadgeBackgroundColor_H
{
	return [NSColor internalCalibratedRed:17 green:125 blue:19 alpha:1];
}

- (NSColor *)userMarkBadgeBackgroundColor_V
{
	return [NSColor internalCalibratedRed:51 green:123 blue:156 alpha:1];
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
	return [NSColor defineUserInterfaceItem:[NSColor internalCalibratedRed:158 green:169 blue:197 alpha:1]
							   invertedItem:[NSColor internalCalibratedRed:36.0 green:36.0 blue:36.0 alpha:1]];
}

- (NSColor *)userMarkBadgeShadowColor
{
	return [NSColor defineUserInterfaceItem:[NSColor colorWithCalibratedWhite:1.00 alpha:0.60]
							   invertedItem:[NSColor internalCalibratedRed:60.0 green:60.0 blue:60.0 alpha:1]];
}

- (NSFont *)userMarkBadgeFont
{
	return [RZFontManager() fontWithFamily:@"Helvetica" traits:NSBoldFontMask weight:15 size:10.5];
}

- (NSInteger)userMarkBadgeMargin
{
	return 5.0;
}

- (NSInteger)userMarkBadgeWidth
{
	return 18.0;
}

- (NSInteger)userMarkBadgeHeight
{
	return 14.0;
}

- (NSFont *)normalCellFont
{
	return [NSFont fontWithName:@"LucidaGrande" size:11.0];
}

- (NSFont *)selectedCellFont
{
	return [NSFont fontWithName:@"LucidaGrande-Bold" size:11.0];
}

- (NSColor *)normalCellTextColor
{
	return [NSColor defineUserInterfaceItem:[NSColor blackColor]
							   invertedItem:[NSColor internalCalibratedRed:225.0 green:224.0 blue:224.0 alpha:1]];
}

- (NSColor *)selectedCellTextColor
{
	return [NSColor defineUserInterfaceItem:[NSColor whiteColor]
							   invertedItem:[NSColor internalCalibratedRed:36.0 green:36.0 blue:36.0 alpha:1]];
}

- (NSColor *)normalCellTextShadowColor
{
	return [NSColor defineUserInterfaceItem:[NSColor colorWithSRGBRed:1.0 green:1.0 blue:1.0 alpha:0.6]
							   invertedItem:[NSColor colorWithCalibratedWhite:0.00 alpha:0.90]];
}

- (NSColor *)normalSelectedCellTextShadowColorForActiveWindow
{
	return [NSColor defineUserInterfaceItem:[NSColor colorWithCalibratedWhite:0.00 alpha:0.48]
							   invertedItem:[NSColor colorWithCalibratedWhite:1.00 alpha:0.30]];
}

- (NSColor *)normalSelectedCellTextShadowColorForInactiveWindow
{
	return [NSColor defineUserInterfaceItem:[NSColor colorWithCalibratedWhite:0.00 alpha:0.30]
							   invertedItem:[NSColor colorWithCalibratedWhite:1.00 alpha:0.30]];
}

- (NSColor *)graphiteSelectedCellTextShadowColorForActiveWindow
{
	return [NSColor internalCalibratedRed:17 green:73 blue:126 alpha:1.00];
}

@end
