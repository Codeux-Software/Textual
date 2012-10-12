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

@implementation TVCMemberList

- (void)updateBackgroundColor
{
	BOOL invertedColors = [TPCPreferences invertSidebarColors];
	
	if (invertedColors) {
		[self setBackgroundColor:[NSColor internalCalibratedRed:38.0 green:38.0 blue:38.0 alpha:1]];
	} else {
		[self setBackgroundColor:[NSColor sourceListBackgroundColor]];
	}

	[self updateOutlineViewColorScheme];
}

- (void)updateOutlineViewColorScheme
{
	BOOL invertedColors = [TPCPreferences invertSidebarColors];

	// ---- //

	self.layoutBadgeFont				= [_NSFontManager() fontWithFamily:@"Helvetica" traits:NSBoldFontMask weight:15 size:10.5];

	self.layoutUserCellFont				= [NSFont fontWithName:@"LucidaGrande"		size:11.0];
	self.layoutUserCellSelectionFont	= [NSFont fontWithName:@"LucidaGrande-Bold" size:11.0];

	self.layoutBadgeMargin				= 5.0;
	self.layoutBadgeHeight				= 14.0;
	self.layoutBadgeWidth				= 18.0;

	// ---- //

	if (invertedColors == NO) {
		/* //////////////////////////////////////////////////// */
		/* Standard Aqua Colors. */
		/* //////////////////////////////////////////////////// */

		self.layoutBadgeTextColorTS				= [NSColor internalCalibratedRed:158 green:169 blue:197 alpha:1];
		self.layoutBadgeTextColorNS				= [NSColor whiteColor];
		self.layoutBadgeShadowColor				= [NSColor colorWithCalibratedWhite:1.00 alpha:0.60];

		self.layoutBadgeMessageBackgroundColorTS	= [NSColor whiteColor];
		self.layoutBadgeMessageBackgroundColorQ		= [NSColor internalCalibratedRed:186 green:0   blue:0   alpha:1];
		self.layoutBadgeMessageBackgroundColorA		= [NSColor internalCalibratedRed:157 green:0   blue:89  alpha:1];
		self.layoutBadgeMessageBackgroundColorO		= [NSColor internalCalibratedRed:210 green:105 blue:30  alpha:1];
		self.layoutBadgeMessageBackgroundColorH		= [NSColor internalCalibratedRed:48  green:128 blue:17  alpha:1];
		self.layoutBadgeMessageBackgroundColorV		= [NSColor internalCalibratedRed:57  green:154 blue:199 alpha:1];
		self.layoutBadgeMessageBackgroundColorX		= [NSColor internalCalibratedRed:152 green:168 blue:202 alpha:1];

		self.layoutUserCellFontColor				= [NSColor blackColor];
		self.layoutUserCellSelectionFontColor		= [NSColor whiteColor];
		self.layoutUserCellShadowColor				= [NSColor internalColorWithSRGBRed:1.0 green:1.0 blue:1.0 alpha:0.6];
		self.layoutUserCellSelectionShadowColorAW	= [NSColor colorWithCalibratedWhite:0.00 alpha:0.48];
		self.layoutUserCellSelectionShadowColorIA	= [NSColor colorWithCalibratedWhite:0.00 alpha:0.30];

		self.layoutGraphiteSelectionColorAW		= [NSColor internalCalibratedRed:17 green:73 blue:126 alpha:1.00];

		/* //////////////////////////////////////////////////// */
		/* Standard Aqua Colors. — @end */
		/* //////////////////////////////////////////////////// */
	} else {
		/* //////////////////////////////////////////////////// */
		/* Black Aqua Colors. */
		/* //////////////////////////////////////////////////// */

		self.layoutBadgeTextColorTS				= [NSColor internalCalibratedRed:36.0 green:36.0 blue:36.0 alpha:1];
		self.layoutBadgeTextColorNS				= [NSColor whiteColor];
		self.layoutBadgeShadowColor				= [NSColor internalCalibratedRed:60.0 green:60.0 blue:60.0 alpha:1];

		self.layoutBadgeMessageBackgroundColorTS	= [NSColor whiteColor];
		self.layoutBadgeMessageBackgroundColorQ		= [NSColor internalCalibratedRed:186 green:0   blue:0   alpha:1];
		self.layoutBadgeMessageBackgroundColorA		= [NSColor internalCalibratedRed:157 green:0   blue:89  alpha:1];
		self.layoutBadgeMessageBackgroundColorO		= [NSColor internalCalibratedRed:210 green:105 blue:30  alpha:1];
		self.layoutBadgeMessageBackgroundColorH		= [NSColor internalCalibratedRed:48  green:128 blue:17  alpha:1];
		self.layoutBadgeMessageBackgroundColorV		= [NSColor internalCalibratedRed:57  green:154 blue:199 alpha:1];
		self.layoutBadgeMessageBackgroundColorX		= [NSColor internalCalibratedRed:48  green:48  blue:48 alpha:1];;

		self.layoutUserCellFontColor				= [NSColor internalCalibratedRed:225.0 green:224.0 blue:224.0 alpha:1];
		self.layoutUserCellSelectionFontColor		= [NSColor internalCalibratedRed:36.0 green:36.0 blue:36.0 alpha:1];
		self.layoutUserCellShadowColor				= [NSColor colorWithCalibratedWhite:0.00 alpha:0.90];
		self.layoutUserCellSelectionShadowColorAW	= [NSColor colorWithCalibratedWhite:1.00 alpha:0.30];
		self.layoutUserCellSelectionShadowColorIA	= [NSColor colorWithCalibratedWhite:1.00 alpha:0.30];

		/* //////////////////////////////////////////////////// */
		/* Black Aqua Colors. — @end */
		/* //////////////////////////////////////////////////// */
	}
}

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

@end