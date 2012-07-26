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

#define _badgeSeperationSpace		1

#define _badgeTextFont				[NSFont fontWithName:@"Helvetica" size:22.0]

@implementation TVCDockIcon

+ (void)drawWithoutCount
{
	[NSApp setApplicationIconImage:[NSImage imageNamed:@"NSApplicationIcon"]];
}

+ (void)drawWithHilightCount:(NSInteger)highlightCount messageCount:(NSInteger)messageCount 
{
	messageCount   = ((messageCount   > 9999) ? 9999 : messageCount);
	highlightCount = ((highlightCount > 9999) ? 9999 : highlightCount);
	
	BOOL showRedBadge = (messageCount >= 1);
	BOOL showGreenBadge = (highlightCount >= 1);
	
	/* ////////////////////////////////////////////////////////// */
	/* Define Text Drawing Globals. */
	/* ////////////////////////////////////////////////////////// */
	
	NSSize badgeTextSize;
	
	NSMutableAttributedString *badgeText = [NSMutableAttributedString alloc];
	
	NSMutableDictionary *badgeTextAttrs = [NSMutableDictionary dictionary];
	
	badgeTextAttrs[NSForegroundColorAttributeName] = [NSColor whiteColor];
	badgeTextAttrs[NSFontAttributeName] = _badgeTextFont;
	
	/* ////////////////////////////////////////////////////////// */
	/* Load Drawing Images. */
	/* ////////////////////////////////////////////////////////// */
	
	NSImage *appIcon;
	
	appIcon = [NSImage imageNamed:@"NSApplicationIcon"];
	appIcon = [appIcon copy];
	
	NSImage *redBadgeLeft   = [NSImage imageNamed:@"DIRedBadgeLeft.png"];
	NSImage *redBadgeCenter = [NSImage imageNamed:@"DIRedBadgeCenter.png"];
	NSImage *redBadgeRight  = [NSImage imageNamed:@"DIRedBadgeRight.png"];
	
	NSImage *greenBadgeLeft		= [NSImage imageNamed:@"DIGreenBadgeLeft.png"];
	NSImage *greenBadgeCenter	= [NSImage imageNamed:@"DIGreenBadgeCenter.png"];
	NSImage *greenBadgeRight	= [NSImage imageNamed:@"DIGreenBadgeRight.png"];
	
	/* ////////////////////////////////////////////////////////// */
	/* Build Scaling Frames. */
	/* ////////////////////////////////////////////////////////// */
	
	NSRect redBadgeLeftFrame, greenBadgeLeftFrame;
	NSRect redBadgeRightFrame, greenBadgeRightFrame;
	NSRect redBadgeCenterFrame, greenBadgeCenterFrame;
	
	[appIcon lockFocus];
	
	/* Red Badge Size. */
	redBadgeRightFrame.size.height	= 44;
	redBadgeCenterFrame.size.height = 44;
	redBadgeLeftFrame.size.height	= 44;
	
	redBadgeLeftFrame.size.width    = 21;
	redBadgeCenterFrame.size.width	= [self badgeCenterTileWidth:messageCount];
	redBadgeRightFrame.size.width	= 20;
	
	/* Green Badge Size. */
	greenBadgeRightFrame.size.height	= 44;
	greenBadgeCenterFrame.size.height	= 44;
	greenBadgeLeftFrame.size.height		= 44;
	
	greenBadgeLeftFrame.size.width		= 21;
	greenBadgeCenterFrame.size.width	= [self badgeCenterTileWidth:highlightCount];
	greenBadgeRightFrame.size.width		= 20;
	
	/* ////////////////////////////////////////////////////////// */
	
	/* If there is no red badge, then the green one is drawn in the same
	 position of the red at the top right of the icon. The following is the
	 math required to psotiion it correctly relative to the icon. If the
	 red icon does exist in this drawing, then we will update these points 
	 of origin later on in the drawing. For now, assume it is at the top. */
	
	/* Green Badge Drawing Position. */
	greenBadgeLeftFrame.origin = NSMakePoint((appIcon.size.width - (greenBadgeRightFrame.size.width +
																	greenBadgeCenterFrame.size.width +
																	greenBadgeLeftFrame.size.width)), // End X Axis
											 (appIcon.size.height - greenBadgeRightFrame.size.height));
	
	greenBadgeCenterFrame.origin = NSMakePoint((appIcon.size.width - (greenBadgeRightFrame.size.width +
																	  greenBadgeCenterFrame.size.width)), // End X Axis
											   (appIcon.size.height - greenBadgeRightFrame.size.height));
	
	greenBadgeRightFrame.origin = NSMakePoint((appIcon.size.width - greenBadgeRightFrame.size.width), // End X Axis
											  (appIcon.size.height - greenBadgeRightFrame.size.height));
	
	/* Update origin if red badge will be drawn. */
	if (showRedBadge) {
		greenBadgeLeftFrame.origin.y = (appIcon.size.height - (greenBadgeLeftFrame.size.height +
															   redBadgeLeftFrame.size.height +
															   _badgeSeperationSpace));
		
		greenBadgeCenterFrame.origin.y = (appIcon.size.height - (greenBadgeCenterFrame.size.height +
																 redBadgeCenterFrame.size.height +
																 _badgeSeperationSpace));
		
		greenBadgeRightFrame.origin.y = (appIcon.size.height - (greenBadgeRightFrame.size.height +
																redBadgeRightFrame.size.height +
																_badgeSeperationSpace));
	}
	
	/* Red Badge Drawing Position. */
	redBadgeLeftFrame.origin = NSMakePoint((appIcon.size.width - (redBadgeRightFrame.size.width +
																  redBadgeCenterFrame.size.width +
																  redBadgeLeftFrame.size.width)), // End X Axis
										   (appIcon.size.height - redBadgeRightFrame.size.height));
	
	redBadgeCenterFrame.origin = NSMakePoint((appIcon.size.width - (redBadgeRightFrame.size.width +
																	redBadgeCenterFrame.size.width)), // End X Axis
											 (appIcon.size.height - redBadgeRightFrame.size.height));
	
	redBadgeRightFrame.origin = NSMakePoint((appIcon.size.width - redBadgeRightFrame.size.width), // End X Axis
											(appIcon.size.height - redBadgeRightFrame.size.height));
	
	/* ////////////////////////////////////////////////////////// */
	/* Draw Badges. */
	/* ////////////////////////////////////////////////////////// */
	
	/* Red Badge. */
	if (showRedBadge) {
		[redBadgeLeft	drawInRect:redBadgeLeftFrame	fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1];
		[redBadgeCenter drawInRect:redBadgeCenterFrame	fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1];
		[redBadgeRight	drawInRect:redBadgeRightFrame	fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1];
		
		/* Red Badge Text. */
		badgeText		= [badgeText initWithString:[NSString stringWithInteger:messageCount] attributes:badgeTextAttrs];
		badgeTextSize   = [badgeText size];
		
		NSInteger redBadgeTotalWidth = (redBadgeLeftFrame.size.width +
										redBadgeCenterFrame.size.width +
										redBadgeRightFrame.size.width);
		
		NSInteger redBadgeTotalHeight = redBadgeCenterFrame.size.height;
		
		NSInteger redBadgeWidthCenter  = ((redBadgeTotalWidth - badgeTextSize.width) / 2);
		NSInteger redBadgeHeightCenter = ((redBadgeTotalHeight - badgeTextSize.height) / 2);
		
		[badgeText drawAtPoint:NSMakePoint((appIcon.size.width - redBadgeTotalWidth + redBadgeWidthCenter),
										   (appIcon.size.height - redBadgeTotalHeight + redBadgeHeightCenter + 1))];
	}
	
	if (showGreenBadge) {
		/* Green Badge. */
		[greenBadgeLeft		drawInRect:greenBadgeLeftFrame		fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1];
		[greenBadgeCenter	drawInRect:greenBadgeCenterFrame	fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1];
		[greenBadgeRight	drawInRect:greenBadgeRightFrame		fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1];
		
		/* Green Badge Text. */
		if (showRedBadge) {
			[badgeText replaceCharactersInRange:NSMakeRange(0, badgeText.length) withString:[NSString stringWithInteger:highlightCount]];
		} else {
			badgeText = [badgeText initWithString:[NSString stringWithInteger:highlightCount] attributes:badgeTextAttrs];
		}
		
		badgeTextSize = [badgeText size];
		
		NSInteger greenBadgeTotalWidth = (greenBadgeLeftFrame.size.width +
										  greenBadgeCenterFrame.size.width +
										  greenBadgeRightFrame.size.width);
		
		NSInteger greenBadgeTotalHeight = greenBadgeCenterFrame.size.height;
		
		NSInteger greenBadgeWidthCenter  = ((greenBadgeTotalWidth - badgeTextSize.width) / 2);
		NSInteger greenBadgeHeightCenter = ((greenBadgeTotalHeight - badgeTextSize.height) / 2);
		
		NSPoint badgeTextDrawPath = NSMakePoint((appIcon.size.width - greenBadgeTotalWidth + greenBadgeWidthCenter),
												(appIcon.size.height - greenBadgeTotalHeight + greenBadgeHeightCenter + 1));
		
		if (showRedBadge) {
			badgeTextDrawPath.y -= (redBadgeCenterFrame.size.height + _badgeSeperationSpace);
		}
		
		[badgeText drawAtPoint:badgeTextDrawPath];
	}
	
	/* ////////////////////////////////////////////////////////// */
	/* Finish Icon. */
	/* ////////////////////////////////////////////////////////// */
	
	[appIcon unlockFocus];
	
	[NSApp setApplicationIconImage:appIcon];
}

+ (NSInteger)badgeCenterTileWidth:(NSInteger)count
{
	switch (count) {
		case 1 ... 9: return 5; break;
		case 10 ... 99: return 16; break;
		case 100 ... 999: return 28; break;
		case 1000 ... 9999: return 38; break;
		default: break;
	}
	
	return 1;
}

@end