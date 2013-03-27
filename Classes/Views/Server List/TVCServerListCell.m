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

@interface TVCServerListCell ()
@property (nonatomic, assign) BOOL isAwaitingRedraw;
@property (nonatomic, assign) CFAbsoluteTime lastDrawTime;
@property (nonatomic, strong) NSString *cachedStatusBadgeFile;
@property (nonatomic, strong) TVCServerListCellBadge *badgeRenderer;
@end

#define _delayedDrawLimit		1.0

#pragma mark -
#pragma mark Private Headers

@implementation TVCServerListCell

#pragma mark -
#pragma mark Cell Information

- (NSInteger)rowIndex
{
	return [self.serverList rowForItem:self.cellItem];
}

- (TVCServerList *)serverList
{
	return self.masterController.serverList;
}

- (NSDictionary *)drawingContext
{
	/* This information is used by every drawing method defined below. */
	/* The information itself should be brief and not validated to allow
	 it to be passed as fast as possible. Allow the actual method doing
	 the drawing to validate the values passed to it. */

	/* These are not the only keys that may be seen in this dictionary.
	 Each drawing method will add custom ones to do their own actions. 
	 I don't know who I am even talking to writing this. Like, really,
	 who is going to read this besides myself? I guess I am doing this
	 as a note to future self to remember how this freaking thing works
	 in a year or so when it probably needs editing again. -.- */

	NSInteger rowIndex = [self rowIndex];

	return @{
		@"rowIndex"		: @(rowIndex),
		@"isInverted"	: @([TPCPreferences invertSidebarColors]),
		@"isRetina"		: @([TPCPreferences runningInHighResolutionMode]),
		@"isSelected"	: @([self.cellItem isEqual:self.worldController.selectedItem]),
		@"isKeyWindow"	: @(self.masterController.mainWindowIsActive),
		@"isGraphite"	: @([NSColor currentControlTint] == NSGraphiteControlTint)
	};
}

- (BOOL)isReadyForDraw
{
	/* We only allow draws to occur every 1.0 second at minimum so that our badge
	 does not have to be stressed during possible flood events. */

	if (self.lastDrawTime == 0) {
		return YES;
	}

	CFAbsoluteTime now = CFAbsoluteTimeGetCurrent();

	if ((now - self.lastDrawTime) >= _delayedDrawLimit) {
		return YES;
	}

	return NO;
}

#pragma mark -
#pragma mark Cell Drawing

- (NSRect)expansionFrameWithFrame:(NSRect)cellFrame inView:(NSView *)view
{
	return NSZeroRect;
}

- (NSColor *)highlightColorWithFrame:(NSRect)cellFrame inView:(NSView *)controlView
{
	return nil;
}

- (void)updateGroupDisclosureTriangle /* DO NOT CALL DIRECTLY FROM THIS CLASS. */
{
	NSButton *theButtonParent;

	for (id view in self.superview.subviews) {
		if ([view isKindOfClass:[NSButton class]]) {
			theButtonParent = view;
		}
	}

	PointerIsEmptyAssert(theButtonParent);

	[self updateGroupDisclosureTriangle:theButtonParent];
}

- (void)updateGroupDisclosureTriangle:(NSButton *)theButtonParent
{
	NSButtonCell *theButton = [theButtonParent cell];
	
	/* Button, yay! */
	NSInteger rowIndex = [self rowIndex];

	BOOL isSelected = (rowIndex == self.serverList.selectedRow);

	/* We keep a reference to the default button. */
	if (PointerIsEmpty(self.serverList.defaultDisclosureTriangle)) {
		self.serverList.defaultDisclosureTriangle = [theButton image];
	}

	if (PointerIsEmpty(self.serverList.alternateDisclosureTriangle)) {
		self.serverList.alternateDisclosureTriangle = [theButton alternateImage];
	}

	/* Now the fun can begin. */
	NSImage *primary = [self.serverList disclosureTriangleInContext:YES selected:isSelected];
	NSImage *alterna = [self.serverList disclosureTriangleInContext:NO selected:isSelected];

	[theButton setImage:primary];
	[theButton setAlternateImage:alterna];

	if (isSelected) {
		[theButton setBackgroundStyle:NSBackgroundStyleLowered];
	} else {
		[theButton setBackgroundStyle:NSBackgroundStyleRaised];
	}

	/* In our layered back scroll view this forces the disclosure triangle to be redrawn. */
	[theButtonParent setHidden:YES];
	[theButtonParent setHidden:NO];
}

- (void)updateSelectionBackgroundView
{
	/****************************************************************/
	/* Define context variables. */
	/****************************************************************/

	NSDictionary *drawContext = [self drawingContext];

	BOOL invertedColors = [drawContext boolForKey:@"isInverted"];
	BOOL isKeyWindow = [drawContext boolForKey:@"isKeyWindow"];
	BOOL isGraphite = [drawContext boolForKey:@"isGraphite"];
	BOOL isSelected = [drawContext boolForKey:@"isSelected"];

	if (isSelected == NO) {
		[self.backgroundImageCell setHidden:YES];

		return;
	}

	IRCChannel *channel = self.cellItem.viewController.channel;

	/****************************************************************/
	/* Find the name of the image to be drawn. */
	/****************************************************************/

	NSString *backgroundImage;

	if (channel.isChannel || channel.isPrivateMessage) {
		backgroundImage = @"ChannelCellSelection";
	} else {
		backgroundImage = @"ServerCellSelection";
	}

	if (invertedColors == NO) {
		if (isKeyWindow) {
			backgroundImage = [backgroundImage stringByAppendingString:@"_Focused"];
		} else {
			backgroundImage = [backgroundImage stringByAppendingString:@"_Unfocused"];
		}

		if (isGraphite) {
			backgroundImage = [backgroundImage stringByAppendingString:@"_Graphite"];
		} else {
			backgroundImage = [backgroundImage stringByAppendingString:@"_Aqua"];
		}
	}

	if (invertedColors) {
		backgroundImage = [backgroundImage stringByAppendingString:@"_Inverted"];
	}

	NSImage *origBackgroundImage = [NSImage imageNamed:backgroundImage];

	/****************************************************************/
	/* Put the background to screen. */
	/****************************************************************/

	/* When our image view is visible for the selected item, right clicking on
	 it will not do anything unless we define a menu to use with our view. Below,
	 we define the menu that matches the selection. */
	NSMenu *menu = self.masterController.serverMenuItem.submenu;

	if (channel) {
		menu = self.masterController.channelMenuItem.submenu;
	}

	/* Setting the menu on our imageView, not only backgroundImageCell, makes it
	 so right clicking on the channel status produces the same menu that is given
	 clicking anywhere else in the server list. */
	[self.imageView setMenu:menu];

	/* Populate the background image cell. */
	[self.backgroundImageCell setImage:origBackgroundImage];
	[self.backgroundImageCell setMenu:menu];
	[self.backgroundImageCell setHidden:NO];
}

- (void)performTimedDrawInFrame:(id)frameString
{
	[self updateDrawing:NSRectFromString(frameString) skipDrawingCheck:YES];

	self.isAwaitingRedraw = NO;
}

- (void)updateDrawing:(NSRect)cellFrame
{
	[self updateDrawing:cellFrame skipDrawingCheck:NO];
}

- (void)updateDrawing:(NSRect)cellFrame skipDrawingCheck:(BOOL)doNotLimit
{
	[self updateSelectionBackgroundView]; // Selection always takes precedence.
	
	if (doNotLimit == NO) {
		BOOL drawReady = [self isReadyForDraw];

		if (drawReady == NO) {
			if (self.isAwaitingRedraw == NO) {
				self.isAwaitingRedraw = YES;

				[self performSelector:@selector(performTimedDrawInFrame:)
						   withObject:NSStringFromRect(cellFrame)
						   afterDelay:_delayedDrawLimit];
			}

			return;
		}
	}

	PointerIsEmptyAssert(self.cellItem);

	BOOL isGroupItem = [self.serverList isGroupItem:self.cellItem];

	if (isGroupItem) {
		[self updateDrawingForGroupItem:cellFrame];
	} else {
		[self updateDrawingForChildItem:cellFrame];
	}

	self.lastDrawTime = CFAbsoluteTimeGetCurrent();
}

#pragma mark -
#pragma mark Group Item Drawing

- (void)updateDrawingForGroupItem:(NSRect)cellFrame
{
	/**************************************************************/
	/* Define our context variables. */
	/**************************************************************/

	NSDictionary *drawContext = [self drawingContext];

	BOOL invertedColors = [drawContext boolForKey:@"isInverted"];
	BOOL isKeyWindow = [drawContext boolForKey:@"isKeyWindow"];
	BOOL isSelected = [drawContext boolForKey:@"isSelected"];

	/* The viewController always has a reference to either a channel or client. It is also
	 defined for every item in our server list. It is the most reliable way to access the
	 outside information. */
	IRCClient *client = self.cellItem.viewController.client;

	/**************************************************************/
	/* Create our new string from scratch. */
	/**************************************************************/

	/* The new string inherits the attributes of the text field so that stuff that we do not
	 define like the paragraph style is passed along and not lost when we define a new value. */
	NSMutableAttributedString *newStrValue = [NSMutableAttributedString mutableStringWithBase:self.cellItem.label
																				   attributes:self.customTextField.attributedStringValue.attributes];
	
	/* Text font and color. */
	NSColor *controlColor = self.serverList.serverCellNormalTextColor;

	if (client.isConnected == NO) {
		controlColor = self.serverList.serverCellDisabledTextColor;
	}

	/* Prepare text shadow. */
	NSShadow *itemShadow = [NSShadow new];

	[itemShadow setShadowOffset:NSMakeSize(0, -1)];

	if (invertedColors) {
		[itemShadow setShadowBlurRadius:1.0];
	}

	if (isSelected) {
		if (isKeyWindow) {
			controlColor = self.serverList.serverCellSelectedTextColorForActiveWindow;
		} else {
			controlColor = self.serverList.serverCellSelectedTextColorForInactiveWindow;
		}

		if (isKeyWindow) {
			[itemShadow setShadowColor:self.serverList.serverCellSelectedTextShadowColorForActiveWindow];
		} else {
			[itemShadow setShadowColor:self.serverList.serverCellSelectedTextShadowColorForInactiveWindow];
		}
	} else {
		if (isKeyWindow) {
			[itemShadow setShadowColor:self.serverList.serverCellNormalTextShadowColorForActiveWindow];
		} else {
			[itemShadow setShadowColor:self.serverList.serverCellNormalTextShadowColorForInactiveWindow];
		}
	}

	/**************************************************************/
	/* Set attributes on the new string. */
	/**************************************************************/

	NSRange textRange = NSMakeRange(0, newStrValue.length);

	[newStrValue addAttribute:NSShadowAttributeName	value:itemShadow range:textRange];
	[newStrValue addAttribute:NSForegroundColorAttributeName value:controlColor	range:textRange];
	[newStrValue addAttribute:NSFontAttributeName value:self.serverList.serverCellFont range:textRange];

	/**************************************************************/
	/* Set the text field value to our new string. */
	/**************************************************************/

	if ([self.customTextField.attributedStringValue isEqual:newStrValue] == NO) {
		/* Only tell the text field of changes if there are actual ones. Why draw the same value again. */

		[self.customTextField setAttributedStringValue:newStrValue];
	}

	/* There is a freak bug when animations will result in our frame for our text
	 field being all funky wrong. This resets the frame to the correct origin. */

	NSRect textFieldFrame = self.customTextField.frame;
	NSRect serverListFrame = self.serverList.frame;

	textFieldFrame.origin.y = 2;
	textFieldFrame.origin.x = self.serverList.serverCellTextFieldLeftMargin;
	
	textFieldFrame.size.width  = serverListFrame.size.width;
	textFieldFrame.size.width -= self.serverList.serverCellTextFieldLeftMargin;
	textFieldFrame.size.width -= self.serverList.serverCellTextFieldRightMargin;

	[self.customTextField setFrame:textFieldFrame];
}


#pragma mark -
#pragma mark Child Item Drawing

- (void)drawStatusBadge:(NSString *)iconName withAlpha:(CGFloat)alpha
{
	/* Stop constantly redrawing. */
	NSString *cacheToken = [NSString stringWithFormat:@"%@—%f", iconName, alpha];

	if (self.cachedStatusBadgeFile) {
		if (cacheToken.hash == self.cachedStatusBadgeFile.hash) {
			return;
		}
	}

	self.cachedStatusBadgeFile = cacheToken;

	/* Begin draw. */
	NSImage *oldImage = [NSImage imageNamed:iconName];
	NSImage *newImage = oldImage;

	/* Draw an image with alpha. */
	/* We already know all these images will be 16x16. */
	if (alpha < 1.0) {
		newImage = [NSImage newImageWithSize:NSMakeSize(16, 16)];

		[newImage lockFocus];

		[oldImage drawInRect:NSMakeRect(0, 0, 16, 16)
					fromRect:NSZeroRect
				   operation:NSCompositeSourceOver
					fraction:alpha
			  respectFlipped:YES
					   hints:nil];

		[newImage unlockFocus];
	}

	/* Set the new image. */
	[self.imageView setImage:newImage];

	/* The private message icon is designed a little different than the
	 channel status icon. Therefore, we have to change its origin to make
	 up for the difference in design. */
	NSRect oldRect = [self.imageView frame];

	if ([iconName hasPrefix:@"colloquy"]) {
		oldRect.origin.y = 0;
	} else {
		oldRect.origin.y = 1;
	}
	
	[self.imageView setFrame:oldRect];
}

- (void)updateDrawingForChildItem:(NSRect)cellFrame
{
	/**************************************************************/
	/* Define our context variables. */
	/**************************************************************/

	NSDictionary *drawContext = [self drawingContext];

	BOOL invertedColors = [drawContext boolForKey:@"isInverted"];
	BOOL isKeyWindow = [drawContext boolForKey:@"isKeyWindow"];
	BOOL isGraphite = [drawContext boolForKey:@"isGraphite"];
	BOOL isSelected = [drawContext boolForKey:@"isSelected"];

	IRCChannel *channel = self.cellItem.viewController.channel;
	
	/**************************************************************/
	/* Draw status icon for channel. */
	/**************************************************************/

	/* Status icon. */
	if (channel.isChannel) {
		if (channel.isActive) {
			[self drawStatusBadge:@"colloquyRoomTabRegular" withAlpha:1.0];
		} else {
			[self drawStatusBadge:@"colloquyRoomTabRegular" withAlpha:0.5];
		}
	} else {
		[self drawStatusBadge:[self.serverList privateMessageStatusIconFilename:isSelected] withAlpha:0.8];
	}

	/**************************************************************/
	/* Create our new string from scratch. */
	/**************************************************************/

	NSMutableAttributedString *newStrValue = [NSMutableAttributedString mutableStringWithBase:self.cellItem.label
																				   attributes:self.customTextField.attributedStringValue.attributes];

	/* Build badge context. */
	[self updateMessageCountBadge:drawContext];
	
	/* Define the text shadow information. */
	NSShadow *itemShadow = [NSShadow new];

	[itemShadow setShadowBlurRadius:1.0];
	[itemShadow setShadowOffset:NSMakeSize(0, -1)];

	if (isSelected == NO) {
		[itemShadow setShadowColor:self.serverList.channelCellNormalTextShadowColor];
	} else {
		if (invertedColors == NO) {
			[itemShadow setShadowBlurRadius:2.0];
		}

		if (isKeyWindow) {
			if (isGraphite && invertedColors == NO) {
				[itemShadow setShadowColor:self.serverList.graphiteTextSelectionShadowColor];
			} else {
				[itemShadow setShadowColor:self.serverList.channelCellSelectedTextShadowColorForActiveWindow];
			}
		} else {
			[itemShadow setShadowColor:self.serverList.channelCellSelectedTextShadowColorForInactiveWindow];
		}
	}

	/**************************************************************/
	/* Set attributes on the new string. */
	/**************************************************************/

	NSRange textRange = NSMakeRange(0, newStrValue.length);

	if (isSelected) {
		[newStrValue addAttribute:NSFontAttributeName value:self.serverList.selectedChannelCellFont range:textRange];

		if (isKeyWindow) {
			[newStrValue addAttribute:NSForegroundColorAttributeName value:self.serverList.channelCellSelectedTextColorForActiveWindow range:textRange];
		} else {
			[newStrValue addAttribute:NSForegroundColorAttributeName value:self.serverList.channelCellSelectedTextColorForInactiveWindow range:textRange];
		}
	} else {
		[newStrValue addAttribute:NSForegroundColorAttributeName value:self.serverList.channelCellNormalTextColor range:textRange];

		[newStrValue addAttribute:NSFontAttributeName value:self.serverList.normalChannelCellFont range:textRange];
	}

	[newStrValue addAttribute:NSShadowAttributeName value:itemShadow range:textRange];

	/**************************************************************/
	/* Set the text field value to our new string. */
	/**************************************************************/
	
	if ([self.customTextField.attributedStringValue isEqual:newStrValue] == NO) {
		/* Only tell the text field of changes if there are actual ones. Why draw the same value again. */

		[self.customTextField setAttributedStringValue:newStrValue];
	}
}

- (void)updateMessageCountBadge:(NSDictionary *)drawContext
{
	NSObjectIsEmptyAssert(drawContext);

	if (PointerIsEmpty(self.badgeRenderer)) {
		self.badgeRenderer = [TVCServerListCellBadge new];
	}

	NSImage *badgeImage = [self.badgeRenderer drawBadgeForCellItem:self.cellItem
												withDrawingContext:drawContext];

	/* Had someone tell me how much they hate math. Bitch, please… you cannot call
	 yourself a programmer and not know math. Math is used everywhere in code. Take
	 these frame calculations for an example. Go team! */

	NSRect badgeViewFrame = self.badgeCountImageCell.frame;
	NSRect textFieldFrame = self.customTextField.frame;
	NSRect serverListFrame = self.serverList.frame;

	textFieldFrame.origin.y = 0;

	if (badgeImage) {
		NSSize scaledSize = [self.badgeRenderer scaledSize];

		badgeViewFrame.size = scaledSize;

		badgeViewFrame.origin.y  = 1;
		badgeViewFrame.origin.x  = serverListFrame.size.width;
		badgeViewFrame.origin.x -= scaledSize.width;
		badgeViewFrame.origin.x -= self.serverList.messageCountBadgeRightMargin;

		[self.badgeCountImageCell setImage:badgeImage];
		[self.badgeCountImageCell setHidden:NO];
	} else {
		badgeViewFrame.size = NSZeroSize;

		[self.badgeCountImageCell setImage:nil];
		[self.badgeCountImageCell setHidden:YES];
	}

	textFieldFrame.origin.x = self.serverList.channelCellTextFieldLeftMargin;

	textFieldFrame.size.width  = (serverListFrame.size.width - self.serverList.channelCellTextFieldLeftMargin);
	textFieldFrame.size.width -= badgeViewFrame.size.width;
	textFieldFrame.size.width -= self.serverList.messageCountBadgeRightMargin;

	if ([TPCPreferences useLargeFontForSidebars] && [TPCPreferences runningInHighResolutionMode]) {
		textFieldFrame.origin.y = -0.5;
	}

	[self.customTextField setFrame:textFieldFrame];
	[self.badgeCountImageCell setFrame:badgeViewFrame];
}

@end

@implementation TVCServerListCellGroupItem
/* For future use. */
@end

@implementation TVCServerListCellChildItem
/* For future use. */
@end

@implementation TVCserverlistRowCell

- (void)drawDraggingDestinationFeedbackInRect:(NSRect)dirtyRect
{
	/* Ignore this. */
}

- (void)drawSelectionInRect:(NSRect)dirtyRect
{
	/* Ignore this. */
}

- (void)drawRect:(NSRect)dirtyRect
{
	/* Ignore this. */
}

- (void)didAddSubview:(NSView *)subview
{
	id firstObject = [self.subviews objectAtIndex:0];

	if ([firstObject isKindOfClass:[TVCServerListCellGroupItem class]]) {
		if ([subview isKindOfClass:[NSButton class]]) {
			TVCServerListCellGroupItem *groupItem = firstObject;

			[groupItem updateGroupDisclosureTriangle:(id)subview];
		}
	}

	[super didAddSubview:subview];
}

@end
