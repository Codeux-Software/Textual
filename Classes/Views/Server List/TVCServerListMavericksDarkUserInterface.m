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

#import "TVCServerListMavericksUserInterfacePrivate.h"

NS_ASSUME_NONNULL_BEGIN

@implementation TVCServerListMavericksDarkUserInterface

- (NSImage *)disclosureTriangleInContext:(BOOL)up selected:(BOOL)selected
{
	if (up) {
		if (selected) {
			return [NSImage imageNamed:@"MavericksDarkServerListViewDisclosureUpSelected"];
		} else {
			return [NSImage imageNamed:@"MavericksDarkServerListViewDisclosureUp"];
		}
	} else {
		if (selected) {
			return [NSImage imageNamed:@"MavericksDarkServerListViewDisclosureDownSelected"];
		} else {
			return [NSImage imageNamed:@"MavericksDarkServerListViewDisclosureDown"];
		}
	}
}

- (NSString *)privateMessageStatusIconFilename:(BOOL)isActive selected:(BOOL)selected
{
	if (selected) {
		return @"NSUser";
	} else {
		if (isActive) {
			return @"MavericksDarkServerListViewSelectedPrivateMessageUserActive";
		} else {
			return @"MavericksDarkServerListViewSelectedPrivateMessageUserInactive";
		}
	}
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
	return [NSColor colorWithCalibratedRed:0.187 green:0.187 blue:0.187 alpha:1.0];
}

- (NSColor *)messageCountBadgeGraphiteBackgroundColor
{
	return [NSColor colorWithCalibratedRed:0.187 green:0.187 blue:0.187 alpha:1.0];
}

- (NSColor *)messageCountSelectedBadgeBackgroundColorForActiveWindow
{
	return [NSColor darkGrayColor];
}

- (NSColor *)messageCountSelectedBadgeBackgroundColorForInactiveWindow
{
	return [NSColor darkGrayColor];
}

- (NSColor *)messageCountBadgeShadowColor
{
	return [NSColor colorWithCalibratedRed:0.234 green:0.234 blue:0.234 alpha:1.0];
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
	return [NSColor whiteColor];
}

- (NSColor *)messageCountSelectedBadgeTextColorForInactiveWindow
{
	return [NSColor whiteColor];
}

- (NSColor *)serverCellNormalTextColor
{
	return [NSColor whiteColor];
}

- (NSColor *)serverCellDisabledTextColor
{
	return [NSColor colorWithCalibratedRed:0.660 green:0.660 blue:0.660 alpha:1.0];
}

- (NSColor *)serverCellSelectedTextColorForActiveWindow
{
	return [NSColor colorWithCalibratedRed:0.140 green:0.140 blue:0.140 alpha:1.0];
}

- (NSColor *)serverCellSelectedTextColorForInactiveWindow
{
	return [NSColor colorWithCalibratedRed:0.140 green:0.140 blue:0.140 alpha:1.0];
}

- (NSColor *)serverCellNormalTextShadowColorForActiveWindow
{
	return [NSColor colorWithCalibratedWhite:0.00 alpha:0.90];
}

- (NSColor *)serverCellNormalTextShadowColorForInactiveWindow
{
	return [NSColor colorWithCalibratedWhite:0.00 alpha:0.90];
}

- (NSColor *)serverCellSelectedTextShadowColorForActiveWindow
{
	return [NSColor colorWithCalibratedWhite:1.00 alpha:0.30];
}

- (NSColor *)serverCellSelectedTextShadowColorForInactiveWindow
{
	return [NSColor colorWithCalibratedWhite:1.00 alpha:0.30];
}

- (NSColor *)channelCellNormalTextColor
{
	return [NSColor whiteColor];
}

- (NSColor *)channelCellDisabledTextColor
{
	return [NSColor colorWithCalibratedWhite:1.0 alpha:0.6];
}

- (NSColor *)channelCellSelectedTextColorForActiveWindow
{
	return [NSColor colorWithCalibratedRed:0.140 green:0.140 blue:0.140 alpha:1.0];
}

- (NSColor *)channelCellSelectedTextColorForInactiveWindow
{
	return [NSColor colorWithCalibratedRed:0.140 green:0.140 blue:0.140 alpha:1.0];
}

- (NSColor *)channelCellNormalTextShadowColor
{
	return [NSColor colorWithCalibratedWhite:0.00 alpha:0.90];
}

- (NSColor *)channelCellSelectedTextShadowColorForActiveWindow
{
	return [NSColor colorWithCalibratedWhite:1.00 alpha:0.30];
}

- (NSColor *)channelCellSelectedTextShadowColorForInactiveWindow
{
	return [NSColor colorWithCalibratedWhite:1.00 alpha:0.30];
}

- (NSColor *)graphiteTextSelectionShadowColor
{
	return [NSColor colorWithCalibratedRed:0.066 green:0.285 blue:0.249 alpha:1.0];
}

- (nullable NSImage *)channelRowSelectionImageForActiveWindow
{
	return [NSImage imageNamed:@"MavericksDarkChannelCellSelection"];
}

- (nullable NSImage *)channelRowSelectionImageForInactiveWindow
{
	return [NSImage imageNamed:@"MavericksDarkChannelCellSelection"];
}

- (nullable NSImage *)serverRowSelectionImageForActiveWindow
{
	return [NSImage imageNamed:@"MavericksDarkServerCellSelection"];
}

- (nullable NSImage *)serverRowSelectionImageForInactiveWindow
{
	return [NSImage imageNamed:@"MavericksDarkServerCellSelection"];
}

- (nullable NSColor *)serverListBackgroundColorForActiveWindow
{
	return [NSColor colorWithCalibratedRed:0.148 green:0.148 blue:0.148 alpha:1.0];
}

- (nullable NSColor *)serverListBackgroundColorForInactiveWindow
{
	return [NSColor colorWithCalibratedRed:0.148 green:0.148 blue:0.148 alpha:1.0];
}

@end

NS_ASSUME_NONNULL_END
