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

NS_ASSUME_NONNULL_BEGIN

@interface TVCMainWindowLoadingScreenView ()
@property (nonatomic, weak) IBOutlet NSView *welcomeAddServerNormalView;
@property (nonatomic, weak) IBOutlet NSView *loadingConfigurationView;
@property (nonatomic, weak) IBOutlet NSView *trialExpiredView;
@property (nonatomic, weak) IBOutlet NSButton *welcomeAddServerViewButton;
@property (nonatomic, weak) IBOutlet NSProgressIndicator *loadingConfigurationViewPI;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *loadingScreenMinimumWidthConstraint;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *loadingScreenMinimumHeightConstraint;
@property (nonatomic, assign) BOOL isAnimating; // YES when animation is in progress
@end

@implementation TVCMainWindowLoadingScreenView

#pragma mark -
#pragma mark Display View (Public)

- (void)showWelcomeAddServerView
{
	if (self.isAnimating) {
		return;
	}

	[self displayView:self.welcomeAddServerNormalView];
}

- (void)showLoadingConfigurationView
{
	if (self.isAnimating) {
		return;
	}

	[self displayView:self.loadingConfigurationView];

	[self.loadingConfigurationViewPI startAnimation:nil];
}

- (void)showTrialExpiredView
{
	if (self.isAnimating) {
		return;
	}

	[self displayView:self.trialExpiredView];
}

#pragma mark -
#pragma mark Hide View (Public)

- (void)hideLoadingConfigurationView
{
	if (self.isAnimating == NO) {
		[self.loadingConfigurationViewPI stopAnimation:nil];
	}

	[self hideAllWithoutAnimation];
}

- (void)hideLoadingConfigurationViewAnimated
{
	if (self.isAnimating == NO) {
		[self.loadingConfigurationViewPI stopAnimation:nil];
	}

	[self hideAllWithAnimation];
}

#pragma mark -

- (void)hideWelcomeAddServerView
{
	[self hideAllWithoutAnimation];
}

- (void)hideWelcomeAddServerViewAnimated
{
	[self hideAllWithAnimation];
}

#pragma mark -

- (void)hideTrialExpiredView
{
	[self hideAllWithoutAnimation];
}

- (void)hideTrialExpiredViewAnimated
{
	[self hideAllWithAnimation];
}

#pragma mark -

- (void)hideAll
{
	[self hideAllAnimated:NO];
}

- (void)hideAllAnimated
{
	[self hideAllWithAnimation];
}

- (void)hideAllWithAnimation
{
	[self hideAllAnimated:YES];
}

- (void)hideAllWithoutAnimation
{
	[self hideAllAnimated:NO];
}

- (void)hideAllAnimated:(BOOL)animate
{
	if (self.isAnimating) {
		return;
	}

	for (NSView *subview in self.contentView.subviews) {
		if (subview.hidden) {
			continue;
		}

		[self hideView:subview animate:animate];
	}
}

#pragma mark -
#pragma mark Display View (Private)

- (void)displayView:(NSView *)view
{
	[self disableBackgroundControlsStepOne];

	NSRect viewFrame = view.frame;
	
	self.loadingScreenMinimumWidthConstraint.constant = viewFrame.size.width;
	self.loadingScreenMinimumHeightConstraint.constant = viewFrame.size.height;

	view.hidden = NO;

	self.alphaValue = 1.0;

	self.hidden = NO;
	
	[self displayIfNeeded];

	[self disableBackgroundControlsStepTwo];
}

#pragma mark -
#pragma mark Hide View (Private)

- (void)hideView:(NSView *)view animate:(BOOL)animate
{
	[self enableBackgroundControlsStepOne];
	
	self.loadingScreenMinimumWidthConstraint.constant = 0.0;
	self.loadingScreenMinimumHeightConstraint.constant = 0.0;

	/* ================================== */

	TXEmtpyBlockDataType phaseTwoBlock = ^{
		view.hidden = YES;

		self.hidden = YES;

		[self enableBackgroundControlsStepTwo];
	};

	/* ================================== */

	if (animate == NO) {
		self.alphaValue = 0.0;

		phaseTwoBlock();

		return;
	}

	/* ================================== */

	self.isAnimating = YES;

	[RZAnimationCurrentContext() setDuration:1.0];

	[NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
		[self animator].alphaValue = 0.0;
	} completionHandler:^{
		phaseTwoBlock();

		self.isAnimating = NO;
	}];
}

#pragma mark -
#pragma mark Private Utilities

- (BOOL)viewIsVisible
{
	return (self.isAnimating && self.isHidden == NO);
}

- (void)disableBackgroundControlsStepOne
{
	self.mainWindow.contentSplitView.hidden = YES;
}

- (void)disableBackgroundControlsStepTwo
{
	TVCMainWindowTextView *textField = self.mainWindow.inputTextField;

	textField.editable = NO;

	textField.selectable = NO;

	[textField updateSegmentedController];
}

- (void)enableBackgroundControlsStepOne
{
	self.mainWindow.contentSplitView.hidden = NO;
}

- (void)enableBackgroundControlsStepTwo
{
	TVCMainWindowTextView *textField = self.mainWindow.inputTextField;

	textField.editable = YES;

	textField.selectable = YES;
	
	[textField updateSegmentedController];
}

@end

NS_ASSUME_NONNULL_END
