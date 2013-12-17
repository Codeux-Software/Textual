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

@implementation TVCMemberListCellBadge

#pragma mark -
#pragma mark Public API

- (void)invalidateBadgeImageCacheAndRebuild
{
	_userModeBadgeImage_Y = [self generateModeSymbolForMode:1];
	_userModeBadgeImage_Q = [self generateModeSymbolForMode:2];
	_userModeBadgeImage_A = [self generateModeSymbolForMode:3];
	_userModeBadgeImage_O = [self generateModeSymbolForMode:4];
	_userModeBadgeImage_H = [self generateModeSymbolForMode:5];
	_userModeBadgeImage_V = [self generateModeSymbolForMode:6];
	_userModeBadgeImage_X = [self generateModeSymbolForMode:7];

	_userModeBadgeImage_Selected = [self generateModeSymbolForMode:100];
}

#pragma mark -
#pragma mark Private Implementation

- (NSImage *)generateModeSymbolForMode:(NSInteger)mode
{
	/* char mode mapping: 
		100 = selected badge.
		1 = y
		2 = q
		3 = a
		4 = o
		5 = h
		6 = v
		7 = x (default)
	*/
	
	/* Align the badge. */
    NSRect badgeFrame = NSMakeRect(0, 1, self.memberList.userMarkBadgeWidth, self.memberList.userMarkBadgeHeight);

	/* Create image and lock focus. */
	NSSize imageFrame = NSMakeSize(self.memberList.userMarkBadgeWidth, (self.memberList.userMarkBadgeHeight + 1)); // one is added for the shadow #YOLO

	NSImage *newImage = [NSImage newImageWithSize:imageFrame];

	[newImage lockFocus];

	/* Prepare the shadow. */
    NSBezierPath *badgePath = nil;

	if (mode == 100) {
		// …
	} else {
		NSRect shadowFrame = badgeFrame;

		/* The shadow frame is a round rectangle that matches the one
		 being drawn with a 1 point offset below the badge to give the
		 appearance of a drop shadow. */
		shadowFrame.origin.y -= 1;

        badgePath = [NSBezierPath bezierPathWithRoundedRect:shadowFrame xRadius:4.0 yRadius:4.0];

		[self.memberList.userMarkBadgeShadowColor set];

		[badgePath fill];
    }

	/* Determin the badge's background color. White is the default
	 because that is the color used when the badge is selected. */
    NSColor *backgroundColor = [NSColor whiteColor];

	if (mode == 1) {
		backgroundColor = [self.memberList userMarkBadgeBackgroundColor_Y];
	} else if (mode == 2) {
		backgroundColor = [self.memberList userMarkBadgeBackgroundColor_Q];
	} else if (mode == 3) {
		backgroundColor = [self.memberList userMarkBadgeBackgroundColor_A];
	} else if (mode == 4) {
		backgroundColor = [self.memberList userMarkBadgeBackgroundColor_O];
	} else if (mode == 5) {
		backgroundColor = [self.memberList userMarkBadgeBackgroundColor_H];
	} else if (mode == 6) {
		backgroundColor = [self.memberList userMarkBadgeBackgroundColor_V];
	} else if (mode == 7) {
		if ([NSColor currentControlTint] == NSGraphiteControlTint) {
			backgroundColor = [self.memberList userMarkBadgeBackgroundColor_XGraphite];
		} else {
			backgroundColor = [self.memberList userMarkBadgeBackgroundColor_XAqua];
		}
	}

	/* Fill in the background. */
	badgePath = [NSBezierPath bezierPathWithRoundedRect:badgeFrame xRadius:4.0 yRadius:4.0];

    [backgroundColor set];

	[badgePath fill];

	/* Complete the draw and return image. */
	[newImage unlockFocus];

	return newImage;
}

#pragma mark -
#pragma mark Common Pointers

- (TVCMemberList *)memberList
{
	return self.masterController.memberList;
}

@end
