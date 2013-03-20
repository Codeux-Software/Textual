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

@interface TVCServerListCellBadge ()
@property (nonatomic, strong) NSImage *cachedBadgeImage;
@property (nonatomic, strong) NSDictionary *cachedDrawContext;
@end

@implementation TVCServerListCellBadge

/* TVCServerListCellBadge is designed to be called and return a pre-built image of a badge to
 draw to the screen. It maintains a cached copy of the last image returned as well as the 
 draw context used for that image. When the class is asked for an image, it first compares
 the draw context against what it already has. If it is the same, then it returns the image
 right away instead of drawing it again. 
 
 The class is designed primarly for drawing heavy events such as scrolling where a lot of 
 redraws occur during a small period of time. The user is not interacting with these badges
 at these times so the cached image will usually be returned instead of the old way in which
 we drew the badges directly to screen instead of storing them as images. */

- (NSSize)scaledSize
{
	PointerIsEmptyAssertReturn(self.cachedBadgeImage, NSZeroSize);

	NSSize imageSize = self.cachedBadgeImage.size;

	return imageSize;
}

- (NSImage *)drawBadgeForCellItem:(id)cellItem withDrawingContext:(NSDictionary *)drawContext
{
	/* Do input validation. */
	PointerIsEmptyAssertReturn(cellItem, nil);

	NSObjectIsEmptyAssertReturn(drawContext, nil);

	/* Define local context information. */
	IRCChannel *channel = cellItem;

	BOOL isSelected = [drawContext boolForKey:@"isSelected"];
	BOOL isKeyWindow = [drawContext boolForKey:@"isKeyWindow"];

	/* Gather information about the badge to draw. */
	BOOL drawMessageBadge = (isSelected == NO || (isKeyWindow == NO && isSelected));

	NSInteger channelTreeUnreadCount = channel.treeUnreadCount;
	NSInteger nicknameHighlightCount = channel.nicknameHighlightCount;

	BOOL isHighlight = (nicknameHighlightCount >= 1);

	/* Begin draw if we want to. */
	if (channelTreeUnreadCount >= 1 && drawMessageBadge) {
		/* Build our local context. */
		NSMutableDictionary *newContext = [drawContext mutableCopy];

		/* Remove information that is constantly changing so we do not
		 keep redrawing when we do not have to. To see the information
		 passed to drawContext see TVCServerListCell.m. */
		[newContext removeObjectForKey:@"rowIndex"];
		[newContext removeObjectForKey:@"isKeyWindow"];

		/* Add new items. */
		[newContext setBool:isHighlight forKey:@"isHighlight"];
		
		[newContext setInteger:channelTreeUnreadCount forKey:@"unreadCount"];

		/* Compare context to cache. */
		if (self.cachedDrawContext && [newContext isEqualToDictionary:self.cachedDrawContext]) {
			/* We have a cache and the context has not changed. Return image if it exists. */

			if (self.cachedBadgeImage) {
				return self.cachedBadgeImage;
			}
		}

		/* The draw engine reads this. */
		self.cachedDrawContext = newContext;

		/* If we got to this point, then that means we have to draw a new image. */

		/* { */
			/* Get the string being draw. */
			NSAttributedString *mcstring = [self messageCountBadgeText:channelTreeUnreadCount selected:(isSelected && isHighlight == NO)];

			/* Get the rect being drawn. */
			NSRect badgeRect = [self messageCountBadgeRectWithText:mcstring];

			/* Draw the badge. */
			NSImage *finalBadge = [self completeDrawFor:mcstring inFrame:badgeRect];

			PointerIsEmptyAssertReturn(finalBadge, nil);

			/* Update cache. */
			self.cachedBadgeImage = finalBadge;

			return finalBadge;
		/* } @end */
	} else {
		/* We do not need to draw anything for the context so destroy the cache. */

		self.cachedDrawContext = nil;
		self.cachedBadgeImage = nil;
	}

	/* Return nil if we do not have anything. */
	return nil;
}

#pragma mark -
#pragma mark Internal Drawing

- (NSAttributedString *)messageCountBadgeText:(NSInteger)messageCount selected:(BOOL)isSelected
{
	NSString *messageCountString = TXFormattedNumber(messageCount);

    /* Pick which font size best aligns with the badge. */
	NSColor *textColor = self.serverList.messageCountBadgeNormalTextColor;

	if (isSelected) {
		textColor = self.serverList.messageCountBadgeSelectedTextColor;
	}

	NSFont *textFont = self.serverList.messageCountBadgeFont;

	NSMutableDictionary *attributes = [NSMutableDictionary dictionary];

	[attributes setObject:textFont forKey:NSFontAttributeName];
	[attributes setObject:textColor forKey:NSForegroundColorAttributeName];

	NSAttributedString *mcstring = [NSAttributedString stringWithBase:messageCountString attributes:attributes];

	return mcstring;
}

- (NSRect)messageCountBadgeRectWithText:(NSAttributedString *)mcstring
{
	NSInteger messageCountWidth = (mcstring.size.width + (self.serverList.messageCountBadgePadding * 2));

	NSRect badgeFrame = NSMakeRect(0, 1, messageCountWidth, self.serverList.messageCountBadgeHeight);

	if (badgeFrame.size.width < self.serverList.messageCountBadgeMinimumWidth) {
		badgeFrame.size.width = self.serverList.messageCountBadgeMinimumWidth;
	 }
	 
	 return badgeFrame;
}

- (NSImage *)completeDrawFor:(NSAttributedString *)mcstring inFrame:(NSRect)badgeFrame
{
	/*************************************************************/
	/* Prepare drawing. */
	/*************************************************************/

	BOOL isGraphite = [self.cachedDrawContext boolForKey:@"isGraphite"];
	BOOL isSelected = [self.cachedDrawContext boolForKey:@"isSelected"];
	BOOL isHighlight = [self.cachedDrawContext boolForKey:@"isHighlight"];
	
	/* Create blank badge image. */
	/* 1 point is added to size to allow room for a shadow. */
	NSSize imageSize = NSMakeSize(badgeFrame.size.width, (badgeFrame.size.height + 1));
	
	NSImage *newDrawImage = [NSImage newImageWithSize:imageSize];

	/* Lock focus for drawing. */
	[newDrawImage lockFocus];
	
	/*************************************************************/
	/* Begin drawing. */
	/*************************************************************/

	NSBezierPath *badgePath;

	/* Draw the badge's drop shadow. */
	if (isSelected == NO) {
		NSRect shadowFrame = badgeFrame;

		/* The shadow frame is a round rectangle that matches the one
		 being drawn with a 1 point offset below the badge to give the 
		 appearance of a drop shadow. */
		shadowFrame.origin.y -= 1;

		badgePath = [NSBezierPath bezierPathWithRoundedRect:shadowFrame
													xRadius:(self.serverList.messageCountBadgeHeight / 2.0)
													yRadius:(self.serverList.messageCountBadgeHeight / 2.0)];

		[self.serverList.messageCountBadgeShadowColor set];

		[badgePath fill];
	}

	/*************************************************************/
	/* Background color drawing. */
	/*************************************************************/

	/* Draw the background color. */
	NSColor *backgroundColor;

	if (isHighlight) {
		backgroundColor = self.serverList.messageCountBadgeHighlightBackgroundColor;
	} else {
		if (isSelected) {
			backgroundColor = self.serverList.messageCountBadgeSelectedBackgroundColor;
		} else {
			if (isGraphite) {
				backgroundColor = self.serverList.messageCountBadgeGraphtieBackgroundColor;
			} else {
				backgroundColor = self.serverList.messageCountBadgeAquaBackgroundColor;
			}
		}
	}

	badgePath = [NSBezierPath bezierPathWithRoundedRect:badgeFrame
												xRadius:(self.serverList.messageCountBadgeHeight / 2.0)
												yRadius:(self.serverList.messageCountBadgeHeight / 2.0)];

	[backgroundColor set];

	[badgePath fill];

	/*************************************************************/
	/* Badge text drawing. */
	/*************************************************************/

	/* Center the text relative to the badge itself. */
	NSPoint badgeTextPoint;

	badgeTextPoint = NSMakePoint((NSMidX(badgeFrame) - (mcstring.size.width / 2.0)),
								(NSMidY(badgeFrame) - (mcstring.size.height / 2.0)));

	
	if ([TPCPreferences runningInHighResolutionMode]) {
		badgeTextPoint.y -= 0.5;
	}
	
	/* The actual draw. */
	[mcstring drawAtPoint:badgeTextPoint];

	/*************************************************************/
	/* Finish drawing. */
	/*************************************************************/

	/* Remove focus from the draw image. */
	[newDrawImage unlockFocus];

	/* Return the result. */
	return newDrawImage;
}

#pragma mark -
#pragma mark Drawing Pointers

- (TVCServerList *)serverList
{
	return self.masterController.serverList;
}

@end
