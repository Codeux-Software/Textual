/* *********************************************************************
 *                  _____         _               _
 *                 |_   _|____  _| |_ _   _  __ _| |
 *                   | |/ _ \ \/ / __| | | |/ _` | |
 *                   | |  __/>  <| |_| |_| | (_| | |
 *                   |_|\___/_/\_\\__|\__,_|\__,_|_|
 *
 * Copyright (c) 2010 - 2015 Codeux Software, LLC & respective contributors.
 *       Please see Acknowledgements.pdf for additional information.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *
 *  * Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 *  * Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 *  * Neither the name of Textual, "Codeux Software, LLC", nor the
 *    names of its contributors may be used to endorse or promote products
 *    derived from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE AUTHOR AND CONTRIBUTORS ``AS IS'' AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED. IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE LIABLE
 * FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
 * OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
 * LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
 * OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
 * SUCH DAMAGE.
 *
 *********************************************************************** */

#import "NSColorHelper.h"
#import "TVCServerListMavericksUserInterfacePrivate.h"

NS_ASSUME_NONNULL_BEGIN

@implementation TVCServerListMavericksLightUserInterface

- (NSImage *)disclosureTriangleInContext:(BOOL)up selected:(BOOL)selected
{
	return [super disclosureTriangleInContext:up selected:selected];
}

- (NSString *)privateMessageStatusIconFilename:(BOOL)isActive selected:(BOOL)selected
{
	return @"NSUser";
}

- (CGFloat)serverCellRowHeight
{
	return 21.0;
}

- (CGFloat)channelCellRowHeight
{
	return 20.0;
}

- (NSFont *)messageCountBadgeFont
{
	return [RZFontManager() fontWithFamily:@"Helvetica" traits:0 weight:9 size:10.5];
}

- (NSFont *)serverCellFont
{
	return [RZFontManager() fontWithFamily:@"Lucida Grande" traits:0 weight:15 size:12.0];
}

- (NSFont *)normalChannelCellFont
{
	return [RZFontManager() fontWithFamily:@"Lucida Grande" traits:0 weight:0 size:12.0];
}

- (NSFont *)selectedChannelCellFont
{
	return [RZFontManager() fontWithFamily:@"Lucida Grande" traits:0 weight:15 size:12.0];
}

- (CGFloat)messageCountBadgeHeight
{
	return 14.0;
}

- (CGFloat)messageCountBadgeMinimumWidth
{
	return 22.0;
}

- (CGFloat)messageCountBadgePadding
{
	return 6.0;
}

- (CGFloat)messageCountBadgeRightMargin
{
	return 3.0;
}

- (CGFloat)messageCountBadgeTextCenterYOffset
{
	return 0.0;
}

- (NSColor *)messageCountHighlightedBadgeBackgroundColorForActiveWindow
{
	return [NSColor colorWithCalibratedRed:0.0 green:0.414 blue:0.117 alpha:1.0];
}

- (NSColor *)messageCountHighlightedBadgeBackgroundColorForInactiveWindow
{
	return [NSColor colorWithCalibratedRed:0.0 green:0.414 blue:0.117 alpha:1.0];
}

- (NSColor *)messageCountBadgeAquaBackgroundColor
{
	return [NSColor colorWithCalibratedRed:0.593 green:0.656 blue:0.789 alpha:1.0];
}

- (NSColor *)messageCountBadgeGraphiteBackgroundColor
{
	return [NSColor colorWithCalibratedRed:0.512 green:0.574 blue:0.636 alpha:1.0];
}

- (NSColor *)messageCountSelectedBadgeBackgroundColorForActiveWindow
{
	return [NSColor whiteColor];
}

- (NSColor *)messageCountSelectedBadgeBackgroundColorForInactiveWindow
{
	return [NSColor whiteColor];
}

- (NSColor *)messageCountBadgeShadowColor
{
	return [NSColor colorWithCalibratedWhite:1.00 alpha:0.60];
}

- (NSColor *)messageCountNormalBadgeTextColorForActiveWindow
{
	return [NSColor whiteColor];
}

- (NSColor *)messageCountNormalBadgeTextColorForInactiveWindow
{
	return [NSColor whiteColor];
}

- (NSColor *)messageCountHighlightedBadgeTextColor
{
	return [NSColor whiteColor];
}

- (NSColor *)messageCountSelectedBadgeTextColorForActiveWindow
{
	return [NSColor colorWithCalibratedRed:0.617 green:0.660 blue:0.769 alpha:1.0];
}

- (NSColor *)messageCountSelectedBadgeTextColorForInactiveWindow
{
	return [NSColor colorWithCalibratedRed:0.617 green:0.660 blue:0.769 alpha:1.0];
}

- (NSColor *)serverCellNormalTextColor
{
	return [NSColor outlineViewHeaderTextColor];
}

- (NSColor *)serverCellDisabledTextColor
{
	return [NSColor outlineViewHeaderDisabledTextColor];
}

- (NSColor *)serverCellSelectedTextColorForActiveWindow
{
	return [NSColor whiteColor];
}

- (NSColor *)serverCellSelectedTextColorForInactiveWindow
{
	return [NSColor whiteColor];
}

- (NSColor *)serverCellNormalTextShadowColorForActiveWindow
{
	return [NSColor colorWithCalibratedWhite:1.00 alpha:1.00];
}

- (NSColor *)serverCellNormalTextShadowColorForInactiveWindow
{
	return [NSColor colorWithCalibratedWhite:1.00 alpha:1.00];
}

- (NSColor *)serverCellSelectedTextShadowColorForActiveWindow
{
	return [NSColor colorWithCalibratedWhite:0.00 alpha:0.30];
}

- (NSColor *)serverCellSelectedTextShadowColorForInactiveWindow
{
	return [NSColor colorWithCalibratedWhite:0.00 alpha:0.20];
}

- (NSColor *)channelCellNormalTextColor
{
	return [NSColor colorWithCalibratedWhite:0.0 alpha:0.8];
}

- (NSColor *)channelCellDisabledTextColor
{
	return [NSColor colorWithCalibratedWhite:0.0 alpha:0.35];
}

- (NSColor *)channelCellSelectedTextColorForActiveWindow
{
	return [NSColor whiteColor];
}

- (NSColor *)channelCellSelectedTextColorForInactiveWindow
{
	return [NSColor whiteColor];
}

- (NSColor *)channelCellNormalTextShadowColor
{
	return [NSColor colorWithSRGBRed:1.0 green:1.0 blue:1.0 alpha:0.6];
}

- (NSColor *)channelCellSelectedTextShadowColorForActiveWindow
{
	return [NSColor colorWithCalibratedWhite:0.00 alpha:0.48];
}

- (NSColor *)channelCellSelectedTextShadowColorForInactiveWindow
{
	return [NSColor colorWithCalibratedWhite:0.00 alpha:0.30];
}

- (NSColor *)graphiteTextSelectionShadowColor
{
	return [NSColor colorWithCalibratedRed:0.066 green:0.285 blue:0.249 alpha:1.0];
}

- (nullable NSImage *)channelRowSelectionImageForActiveWindow
{
	return nil; // Use system default
}

- (nullable NSImage *)channelRowSelectionImageForInactiveWindow
{
	return nil; // Use system default
}

- (nullable NSImage *)serverRowSelectionImageForActiveWindow
{
	return nil; // Use system default
}

- (nullable NSImage *)serverRowSelectionImageForInactiveWindow
{
	return nil; // Use system default
}

- (nullable NSColor *)serverListBackgroundColorForActiveWindow
{
	return nil; // Use system default
}

- (nullable NSColor *)serverListBackgroundColorForInactiveWindow
{
	return [NSColor colorWithCalibratedRed:0.901 green:0.901 blue:0.901 alpha:1.0];
}

@end

NS_ASSUME_NONNULL_END
