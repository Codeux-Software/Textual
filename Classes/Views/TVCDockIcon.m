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

#define _badgeSeperationSpace		1

@implementation TVCDockIcon

static NSInteger _cachedMessageCount = -1;
static NSInteger _cachedHighlightCount = -1;

+ (void)updateDockIcon
{
	NSAssertReturn([TPCPreferences displayDockBadge]);
	
	NSInteger messageCount = 0;
	NSInteger highlightCount = 0;
	
	for (IRCClient *u in [worldController() clientList]) {
		for (IRCChannel *c in [u channelList]) {
			if (c.config.pushNotifications && c.config.showTreeBadgeCount) {
				messageCount += c.dockUnreadCount;
			}
			
			highlightCount += c.nicknameHighlightCount;
		}
	}
	
	if (messageCount == 0 && highlightCount == 0) {
		[TVCDockIcon drawWithoutCount];
	} else {
		[TVCDockIcon drawWithHilightCount:highlightCount messageCount:messageCount];
	}
}

+ (NSImage *)applicationIcon
{
    /* THIS IS A SECRET!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
     
     Birthday icon designed by Alex Sørlie Glomsaas. */

	NSCalendar *sysCalendar = [NSCalendar currentCalendar];

    NSDateComponents *breakdownInfo = [sysCalendar components:(NSCalendarUnitMonth | NSCalendarUnitDay) fromDate:[NSDate date]];

    /* The first public commit of Textual occured on July, 23, 2010. This is the day
     that we consider the birthday of the application. */
    if ([breakdownInfo month] == 7 && [breakdownInfo day] == 23) {
        return [NSImage imageNamed:@"birthdayIcon"];
    } else {
        return [NSImage imageNamed:@"NSApplicationIcon"];
    }
}

+ (void)resetCachedCount
{
	_cachedHighlightCount = -1;
	_cachedMessageCount = -1;
}

+ (void)drawWithoutCount
{
    if (_cachedHighlightCount == 0 && _cachedMessageCount == 0) {
        return;
    }

    _cachedMessageCount = 0;
    _cachedHighlightCount = 0;
    
	[NSApp setApplicationIconImage:[self applicationIcon]];
}

+ (void)drawWithHilightCount:(NSInteger)highlightCount messageCount:(NSInteger)messageCount 
{
    if (_cachedHighlightCount == highlightCount && _cachedMessageCount == messageCount) {
        return;
    }

    _cachedMessageCount = messageCount;
    _cachedHighlightCount = highlightCount;
    
	if (messageCount > 9999) {
		messageCount = 9999;
	}

	if (highlightCount > 9999) {
		highlightCount = 9999;
	}
	
	BOOL showRedBadge = (messageCount >= 1);
	BOOL showGreenBadge = (highlightCount >= 1);
	
	/* ////////////////////////////////////////////////////////// */
	/* Define Text Drawing Globals. */
	/* ////////////////////////////////////////////////////////// */
	
	NSSize badgeTextSize;
	
	NSMutableAttributedString *badgeText = [NSMutableAttributedString alloc];
	
	NSDictionary *badgeTextAttrs = nil;
	
	NSInteger badgeTextFrameCorrection = 0;
	
	if ([XRSystemInformation isUsingOSXYosemiteOrLater]) {
		badgeTextFrameCorrection = 2;
		
		badgeTextAttrs = @{
			NSFontAttributeName				: [NSFont fontWithName:@"Helvetica" size:24.0],
			NSForegroundColorAttributeName	: [NSColor whiteColor]
		};
	}else {
		badgeTextFrameCorrection = 1;
		
		badgeTextAttrs = @{
			NSFontAttributeName				: [NSFont fontWithName:@"Helvetica" size:22.0],
			NSForegroundColorAttributeName	: [NSColor whiteColor]
		};
	}
	
	/* ////////////////////////////////////////////////////////// */
	/* Load Drawing Images. */
	/* ////////////////////////////////////////////////////////// */
	
	NSImage *appIcon = [[self applicationIcon] copy];
	
	NSImage *redBadgeLeft = nil;
	NSImage *redBadgeCenter = nil;
	NSImage *redBadgeRight = nil;

	NSImage *greenBadgeLeft = nil;
	NSImage *greenBadgeCenter = nil;
	NSImage *greenBadgeRight = nil;

	if ([XRSystemInformation isUsingOSXYosemiteOrLater]) {
		redBadgeLeft   = [NSImage imageNamed:@"DIRedBadgeLeftYosemite.png"];
		redBadgeCenter = [NSImage imageNamed:@"DIRedBadgeCenterYosemite.png"];
		redBadgeRight  = [NSImage imageNamed:@"DIRedBadgeRightYosemite.png"];

		greenBadgeLeft		= [NSImage imageNamed:@"DIGreenBadgeLeftYosemite.png"];
		greenBadgeCenter	= [NSImage imageNamed:@"DIGreenBadgeCenterYosemite.png"];
		greenBadgeRight		= [NSImage imageNamed:@"DIGreenBadgeRightYosemite.png"];
	} else {
		redBadgeLeft   = [NSImage imageNamed:@"DIRedBadgeLeftMavericks.png"];
		redBadgeCenter = [NSImage imageNamed:@"DIRedBadgeCenterMavericks.png"];
		redBadgeRight  = [NSImage imageNamed:@"DIRedBadgeRightMavericks.png"];

		greenBadgeLeft		= [NSImage imageNamed:@"DIGreenBadgeLeftMavericks.png"];
		greenBadgeCenter	= [NSImage imageNamed:@"DIGreenBadgeCenterMavericks.png"];
		greenBadgeRight		= [NSImage imageNamed:@"DIGreenBadgeRightMavericks.png"];
	}
	
	/* ////////////////////////////////////////////////////////// */
	/* Build Scaling Frames. */
	/* ////////////////////////////////////////////////////////// */
	
	NSRect redBadgeLeftFrame, greenBadgeLeftFrame;
	NSRect redBadgeRightFrame, greenBadgeRightFrame;
	NSRect redBadgeCenterFrame, greenBadgeCenterFrame;
	
	[appIcon lockFocus];
	
	if ([XRSystemInformation isUsingOSXYosemiteOrLater]) {
		/* Red Badge Size. */
		redBadgeRightFrame.size.height	= 53;
		redBadgeCenterFrame.size.height = 53;
		redBadgeLeftFrame.size.height	= 53;
		
		redBadgeLeftFrame.size.width    = 27;
		redBadgeCenterFrame.size.width	= [self badgeCenterTileWidthForYosemite:messageCount];
		redBadgeRightFrame.size.width	= 26;
		
		/* Green Badge Size. */
		greenBadgeRightFrame.size.height	= 53;
		greenBadgeCenterFrame.size.height	= 53;
		greenBadgeLeftFrame.size.height		= 53;
		
		greenBadgeLeftFrame.size.width		= 27;
		greenBadgeCenterFrame.size.width	= [self badgeCenterTileWidthForYosemite:highlightCount];
		greenBadgeRightFrame.size.width		= 26;
	} else {
		/* Red Badge Size. */
		redBadgeRightFrame.size.height	= 44;
		redBadgeCenterFrame.size.height = 44;
		redBadgeLeftFrame.size.height	= 44;
		
		redBadgeLeftFrame.size.width    = 21;
		redBadgeCenterFrame.size.width	= [self badgeCenterTileWidthForMavericks:messageCount];
		redBadgeRightFrame.size.width	= 20;
		
		/* Green Badge Size. */
		greenBadgeRightFrame.size.height	= 44;
		greenBadgeCenterFrame.size.height	= 44;
		greenBadgeLeftFrame.size.height		= 44;
		
		greenBadgeLeftFrame.size.width		= 21;
		greenBadgeCenterFrame.size.width	= [self badgeCenterTileWidthForMavericks:highlightCount];
		greenBadgeRightFrame.size.width		= 20;
	}
	
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
		[redBadgeLeft	drawInRect:redBadgeLeftFrame	fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0];
		[redBadgeCenter drawInRect:redBadgeCenterFrame	fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0];
		[redBadgeRight	drawInRect:redBadgeRightFrame	fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0];
		
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
										   (appIcon.size.height - redBadgeTotalHeight + redBadgeHeightCenter + badgeTextFrameCorrection))];
	}
	
	if (showGreenBadge) {
		/* Green Badge. */
		[greenBadgeLeft		drawInRect:greenBadgeLeftFrame		fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0];
		[greenBadgeCenter	drawInRect:greenBadgeCenterFrame	fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0];
		[greenBadgeRight	drawInRect:greenBadgeRightFrame		fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0];
		
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
												(appIcon.size.height - greenBadgeTotalHeight + greenBadgeHeightCenter + badgeTextFrameCorrection));
		
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

+ (NSInteger)badgeCenterTileWidthForMavericks:(NSInteger)count
{
	switch (count) {
		case 1 ... 9:
		{
			return 5;
		}
		case 10 ... 99:
		{
			return 16;
		}
		case 100 ... 999:
		{
			return 28;
		}
		case 1000 ... 9999:
		{
			return 38;
		}
	}
	
	return 1;
}

+ (NSInteger)badgeCenterTileWidthForYosemite:(NSInteger)count
{
	switch (count) {
		case 1 ... 9:
		{
			return 1;
		}
		case 10 ... 99:
		{
			return 1;
		}
		case 100 ... 999:
		{
			return 18;
		}
		case 1000 ... 9999:
		{
			return 28;
		}
	}
	
	return 1;
}

@end
