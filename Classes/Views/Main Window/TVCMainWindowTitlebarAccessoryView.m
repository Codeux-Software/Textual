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

#import "NSViewHelperPrivate.h"
#import "TVCMainWindow.h"
#import "TVCMainWindowAppearance.h"
#import "TVCMainWindowTitlebarAccessoryViewPrivate.h"

NS_ASSUME_NONNULL_BEGIN

/* This class is used by both Mavericks and Yosemite, but only the Yosemite
 version does any drawing. */
@implementation TVCMainWindowTitlebarAccessoryView
@end

@implementation TVCMainWindowTitlebarAccessoryViewController
@end

@interface TVCMainWindowTitlebarAccessoryViewLockButton ()
@property (nonatomic, assign) BOOL drawsCustomBackgroundColor;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *lockButtonLeftMarginConstraint;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *lockButtonRightMarginConstraint;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *lockButtonSuperviewWidthConstraint;
@end

@implementation TVCMainWindowTitlebarAccessoryViewLockButton

- (void)sizeToFit
{
	[super sizeToFit];

	/* NSTitlebarAccessoryViewController is not very friendly when it comes
	 to allowing us to specify an NSLayoutConstraint based width for our view
	 and updating the width of its clip view based on changes to that. Lucky
	 for us NSTitlebarAccessoryViewController at least monitors the frame
	 value for its associated view which means if we manually specify the 
	 width in its frame, then we can at least force a resize then. */
	CGFloat buttonWidth = NSWidth(self.frame);

	CGFloat buttonLeftMargin = self.lockButtonLeftMarginConstraint.constant;
	CGFloat buttonRightMargin = self.lockButtonRightMarginConstraint.constant;

	CGFloat totalViewWidth = (buttonLeftMargin + buttonWidth + buttonRightMargin);

	if (TEXTUAL_RUNNING_ON_YOSEMITE) {
		NSRect superviewFrame = self.superview.frame;

		superviewFrame.size.width = totalViewWidth;

		self.superview.frame = superviewFrame;

		return;
	}

	if (self.lockButtonSuperviewWidthConstraint) {
		self.lockButtonSuperviewWidthConstraint.constant = totalViewWidth;
	}
}

- (void)awakeFromNib
{
	[super awakeFromNib];

	[self disableDrawingCustomBackgroundColor];
}

- (void)positionImageOverContent
{
	[self.cell setImagePosition:NSImageOverlaps];
}

- (void)positionImageOnLeftSide
{
	[self.cell setImagePosition:NSImageLeft];
}

- (void)setIconAsLocked
{
	NSImage *iconImage = [NSImage imageNamed:@"NSLockLockedTemplate"];

	self.image = iconImage;
}

- (void)setIconAsUnlocked
{
	NSImage *iconImage = [NSImage imageNamed:@"NSLockUnlockedTemplate"];

	self.image = iconImage;
}

- (void)disableDrawingCustomBackgroundColor
{
	if (TEXTUAL_RUNNING_ON_YOSEMITE == NO) {
		return;
	}

	self.cell.backgroundStyle = NSBackgroundStyleRaised;

	self.drawsCustomBackgroundColor = NO;
}

- (void)enableDrawingCustomBackgroundColor
{
	if (TEXTUAL_RUNNING_ON_YOSEMITE == NO) {
		return;
	}

	self.cell.backgroundStyle = NSBackgroundStyleLowered;

	self.drawsCustomBackgroundColor = YES;
}

- (void)drawRect:(NSRect)dirtyRect
{
	if ([self needsToDrawRect:dirtyRect] == NO) {
		return;
	}

	if (self.drawsCustomBackgroundColor) {
		[self drawInteriorOnYosemite];
	}

	[super drawRect:dirtyRect];
}

- (void)drawInteriorOnYosemite
{
	if (self.mainWindow.isActiveForDrawing == NO) {
		return;
	}

	TVCMainWindowAppearance *appearance = self.mainWindow.userInterfaceObjects;

	if (appearance == nil) {
		return;
	}

	[self drawInteriorForActiveWindowOnYosemiteWithAppearance:appearance];
}

- (void)drawInteriorForActiveWindowOnYosemiteWithAppearance:(TVCMainWindowAppearance *)appearance
{
	NSParameterAssert(appearance != nil);

	/* On Yosemite, we get the bounds of the object and tweak it just slighly to match what
	 it actually is. After that, we draw our color in behind it to fake the background. */
	NSRect controllerFrame = self.bounds;

	controllerFrame.size.height -= 1.0;

	NSColor *controllerBackgroundColor = appearance.titlebarAccessoryViewBackgroundColorActiveWindow;

	NSBezierPath *drawingPath = [NSBezierPath bezierPathWithRoundedRect:controllerFrame xRadius:4.0 yRadius:4.0];

	[controllerBackgroundColor set];

	[drawingPath fill];
}

- (BOOL)needsDisplayWhenMainWindowAppearanceChanges
{
	return YES;
}

@end

NS_ASSUME_NONNULL_END
