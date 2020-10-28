/* *********************************************************************
 *                  _____         _               _
 *                 |_   _|____  _| |_ _   _  __ _| |
 *                   | |/ _ \ \/ / __| | | |/ _` | |
 *                   | |  __/>  <| |_| |_| | (_| | |
 *                   |_|\___/_/\_\\__|\__,_|\__,_|_|
 *
 * Copyright (c) 2010 - 2020 Codeux Software, LLC & respective contributors.
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
#import "TVCMainWindowSidebarSmoothTextFieldPrivate.h"

NS_ASSUME_NONNULL_BEGIN

@implementation TVCMainWindowSidebarSmoothTextField
@end

@implementation TVCMainWindowSidebarSmoothTextFieldCell

- (CGFloat)contentsScale
{
	return self.mainWindow.backingScaleFactor;
}

- (nullable NSColor *)fontSmoothingBackgroundColorForParentTableRow
{
	NSTableRowView *tableRow = [self recursivelyFindTableRowViewRelativeTo:self.controlView];

	if (tableRow == nil) {
		return nil;
	}

	if ([tableRow respondsToSelector:@selector(fontSmoothingBackgroundColor)]) {
		return [tableRow performSelector:@selector(fontSmoothingBackgroundColor)];
	}

	return nil;
}

- (nullable NSTableRowView *)recursivelyFindTableRowViewRelativeTo:(NSView *)controlView
{
	if ([controlView isKindOfClass:[NSTableRowView class]]) {
		return (id)controlView;
	}

	NSView *controlViewSuperview = controlView.superview;

	if (controlViewSuperview == nil) {
		return nil;
	}

	return [self recursivelyFindTableRowViewRelativeTo:controlViewSuperview];
}

- (NSColor *)backgroundColorForFakingSubpixelAntialiasing
{
	NSAttributedString *stringValue = self.attributedStringValue;

	NSColor *textColor = [stringValue attribute:NSForegroundColorAttributeName atIndex:0 effectiveRange:NULL];

	if (textColor.isShadeOfGray == NO) {
		return textColor;
	}

	NSColor *superviewSmoothingColor = self.fontSmoothingBackgroundColorForParentTableRow;

	if (superviewSmoothingColor) {
		return superviewSmoothingColor;
	}

	LogToConsoleError("*** WARNING: -fontSmoothingBackgroundColorForParentTableRow returned nil value");

	return [NSColor clearColor];
}

- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView
{
	/* Mojave no longer performs subpixel antialiasing */
	if (TEXTUAL_RUNNING_ON_MOJAVE) {
		[super drawWithFrame:cellFrame inView:controlView];

		return;
	}

	NSAttributedString *stringValue = self.attributedStringValue;

	if (stringValue.length == 0) {
		return;
	}

	NSColor *backgroundColor = self.backgroundColorForFakingSubpixelAntialiasing;

	NSRect cellFrameCopy = cellFrame;

	CGFloat coreTextFrameOffset = 0;

	NSImage *stringValueImage = [stringValue imageRepWithSize:cellFrameCopy.size
												  scaleFactor:self.contentsScale
											  backgroundColor:backgroundColor
										  coreTextFrameOffset:&coreTextFrameOffset];

	/* This is an incredibly lazy fix. Emoji characters add an extra 4 pixels
	 to the height when drawing with a height of 16 which is the height we are
	 drawing into right now. I will eventually fix this to scale to any size, 
	 but as long as this works for now... */
	if (fabs(coreTextFrameOffset) == 4.0) {
		cellFrameCopy.origin.y += 1;
	}

	[stringValueImage drawInRect:cellFrameCopy
						fromRect:NSZeroRect
					   operation:NSCompositingOperationSourceOver
						fraction:1.0
				  respectFlipped:YES
						   hints:nil];
}

@end

NS_ASSUME_NONNULL_END
