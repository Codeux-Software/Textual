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

#import "TVCMainWindow.h"

NS_ASSUME_NONNULL_BEGIN

@implementation NSView (TXViewHelperPrivate)

- (nullable TVCMainWindow *)mainWindow
{
	NSWindow *window = self.window;

	if ([window isMemberOfClass:[TVCMainWindow class]] == NO) {
		return nil;
	}

	return (TVCMainWindow *)window;
}

@end

#pragma mark -

@implementation NSView (TXViewHelper)

- (void)attachSubviewToHugEdges:(NSView *)subview
{
	NSParameterAssert(subview != nil);

	/* Remove any views that may already be in place. */
	NSArray *contentSubviews = self.subviews;

	if (contentSubviews.count > 0) {
		[contentSubviews[0] removeFromSuperview];
	}

	[self addSubview:subview];

	/* Add new constraints. */
	[self addConstraints:
	 [NSLayoutConstraint constraintsWithVisualFormat:@"H:|-0-[subview]-0-|"
											 options:NSLayoutFormatDirectionLeadingToTrailing
											 metrics:nil
											   views:NSDictionaryOfVariableBindings(subview)]];

	[self addConstraints:
	 [NSLayoutConstraint constraintsWithVisualFormat:@"V:|-0-[subview]-0-|"
											 options:NSLayoutFormatDirectionLeadingToTrailing
											 metrics:nil
											   views:NSDictionaryOfVariableBindings(subview)]];
}

- (void)attachSubview:(NSView *)subview adjustedWidthConstraint:(nullable NSLayoutConstraint *)parentViewWidthConstraint adjustedHeightConstraint:(nullable NSLayoutConstraint *)parentViewHeightConstraint
{
	NSParameterAssert(subview != nil);

	/* Remove any views that may already be in place. */
	NSArray *contentSubviews = self.subviews;

	if (contentSubviews.count > 0) {
		[contentSubviews[0] removeFromSuperview];
	}

	[self addSubview:subview];

	/* Adjust constraints of parent view to maintain the same size
	 of the subview that is being added. */
	NSRect subviewFrame = subview.frame;

	CGFloat subviewFrameWidth = NSWidth(subviewFrame);
	CGFloat subviewFrameHeight = NSHeight(subviewFrame);

	if ( parentViewWidthConstraint) {
		parentViewWidthConstraint.constant = subviewFrameWidth;
	}

	if ( parentViewHeightConstraint) {
		parentViewHeightConstraint.constant = subviewFrameHeight;
	}

	/* Add new constraints. */
	NSMutableArray *constraints = [NSMutableArray array];

	[constraints addObject:
	 [NSLayoutConstraint constraintWithItem:subview
								  attribute:NSLayoutAttributeWidth
								  relatedBy:NSLayoutRelationEqual
									 toItem:nil
								  attribute:NSLayoutAttributeNotAnAttribute
								 multiplier:1.0
								   constant:subviewFrameWidth]
	 ];

	[constraints addObject:
	 [NSLayoutConstraint constraintWithItem:subview
								  attribute:NSLayoutAttributeHeight
								  relatedBy:NSLayoutRelationEqual
									 toItem:nil
								  attribute:NSLayoutAttributeNotAnAttribute
								 multiplier:1.0
								   constant:subviewFrameHeight]
	 ];

	[subview addConstraints:constraints];
}

@end

#pragma mark -

@implementation NSCell (TXCellHelperPrivate)

- (nullable NSWindow *)window
{
	return self.controlView.window;
}

- (nullable TVCMainWindow *)mainWindow
{
	return self.controlView.mainWindow;
}

@end

NS_ASSUME_NONNULL_END
