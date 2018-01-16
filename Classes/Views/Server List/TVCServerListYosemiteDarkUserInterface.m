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

#import "TVCServerListYosemiteUserInterfacePrivate.h"

NS_ASSUME_NONNULL_BEGIN

@implementation TVCServerListDarkYosemiteUserInterface

- (NSImage *)disclosureTriangleInContext:(BOOL)up selected:(BOOL)selected
{
	if (up) {
		return [NSImage imageNamed:@"YosemiteDarkServerListViewDisclosureUp"];
	} else {
		return [NSImage imageNamed:@"YosemiteDarkServerListViewDisclosureDown"];
	}
}

- (NSString *)privateMessageStatusIconFilename:(BOOL)isActive
{
	if (isActive) {
		return @"VibrantDarkServerListViewPrivateMessageUserIconActive";
	} else {
		return @"VibrantDarkServerListViewPrivateMessageUserIconInactive";
	}
}

- (NSColor *)channelCellNormalItemTextColorForActiveWindow
{
	return [NSColor colorWithCalibratedWhite:0.8 alpha:1.0];
}

- (NSColor *)channelCellNormalItemTextColorForInactiveWindow
{
	return [NSColor colorWithCalibratedWhite:0.8 alpha:1.0];
}

- (NSColor *)channelCellDisabledItemTextColorForActiveWindow
{
	return [NSColor colorWithCalibratedWhite:0.4 alpha:1.0];
}

- (NSColor *)channelCellDisabledItemTextColorForInactiveWindow
{
	return [NSColor colorWithCalibratedWhite:0.4 alpha:1.0];
}

- (NSColor *)channelCellHighlightedItemTextColorForActiveWindow
{
	return [NSColor colorWithCalibratedRed:0.0 green:0.414 blue:0.117 alpha:1.0];
}

- (NSColor *)channelCellHighlightedItemTextColorForInactiveWindow
{
	return [NSColor colorWithCalibratedRed:0.0 green:0.414 blue:0.117 alpha:1.0];
}

- (NSColor *)channelCellErroneousItemTextColorForActiveWindow
{
	return [NSColor colorWithCalibratedRed:0.850 green:0.0 blue:0.0 alpha:1.0];
}

- (NSColor *)channelCellErroneousItemTextColorForInactiveWindow
{
	return [NSColor colorWithCalibratedRed:0.850 green:0.0 blue:0.0 alpha:1.0];
}

- (NSColor *)channelCellSelectedTextColorForActiveWindow
{
	return [NSColor colorWithCalibratedWhite:0.8 alpha:1.0];
}

- (NSColor *)channelCellSelectedTextColorForInactiveWindow
{
	return [NSColor colorWithCalibratedWhite:0.7 alpha:1.0];
}

- (NSColor *)serverCellDisabledItemTextColorForActiveWindow
{
	return [NSColor colorWithCalibratedWhite:0.4 alpha:1.0];
}

- (NSColor *)serverCellDisabledItemTextColorForInactiveWindow
{
	return [NSColor colorWithCalibratedWhite:0.4 alpha:1.0];
}

- (NSColor *)serverCellNormalItemTextColorForActiveWindow
{
	return [NSColor colorWithCalibratedWhite:0.8 alpha:1.0];
}

- (NSColor *)serverCellNormalItemTextColorForInactiveWindow
{
	return [NSColor colorWithCalibratedWhite:0.8 alpha:1.0];
}

- (NSColor *)serverCellSelectedTextColorForActiveWindow
{
	return [NSColor colorWithCalibratedWhite:0.8 alpha:1.0];
}

- (NSColor *)serverCellSelectedTextColorForInactiveWindow
{
	return [NSColor colorWithCalibratedWhite:0.7 alpha:1.0];
}

- (NSColor *)messageCountNormalBadgeTextColorForActiveWindow
{
	return [NSColor whiteColor];
}

- (NSColor *)messageCountNormalBadgeTextColorForInactiveWindow
{
	return [NSColor whiteColor];
}

- (NSColor *)messageCountSelectedBadgeTextColorForActiveWindow
{
	return [NSColor colorWithCalibratedRed:0.1 green:0.1 blue:0.1 alpha:1.0];
}

- (NSColor *)messageCountSelectedBadgeTextColorForInactiveWindow
{
	return [NSColor colorWithCalibratedRed:0.1 green:0.1 blue:0.1 alpha:1.0];
}

- (NSColor *)messageCountHighlightedBadgeTextColor
{
	return [NSColor whiteColor];
}

- (NSColor *)messageCountNormalBadgeBackgroundColorForActiveWindow
{
	return [NSColor colorWithCalibratedWhite:0.15 alpha:1.0];
}

- (NSColor *)messageCountNormalBadgeBackgroundColorForInactiveWindow
{
	return [NSColor colorWithCalibratedWhite:0.15 alpha:1.0];
}

- (NSColor *)messageCountSelectedBadgeBackgroundColorForActiveWindow
{
	return [NSColor whiteColor];
}

- (NSColor *)messageCountSelectedBadgeBackgroundColorForInactiveWindow
{
	return [NSColor whiteColor];
}

- (NSColor *)messageCountHighlightedBadgeBackgroundColorForActiveWindow
{
	return [NSColor colorWithCalibratedRed:0.0117 green:0.1562 blue:0.0 alpha:1.0];
}

- (NSColor *)messageCountHighlightedBadgeBackgroundColorForInactiveWindow
{
	return [NSColor colorWithCalibratedRed:0.0117 green:0.1562 blue:0.0 alpha:1.0];
}

- (nullable NSColor *)rowSelectionColorForActiveWindow
{
	return [NSColor colorWithCalibratedWhite:0.2 alpha:1.0];
}

- (nullable NSColor *)rowSelectionColorForInactiveWindow
{
	return [NSColor colorWithCalibratedWhite:0.2 alpha:1.0];
}

@end

NS_ASSUME_NONNULL_END
