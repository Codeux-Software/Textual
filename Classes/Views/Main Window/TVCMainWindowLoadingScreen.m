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

@interface TVCMainWindowLoadingScreenView ()
@property (nonatomic, weak) IBOutlet NSView *welcomeAddServerNormalView;
@property (nonatomic, weak) IBOutlet NSView *loadingConfigurationView;
@property (nonatomic, weak) IBOutlet NSView *trialExpiredView;
@property (nonatomic, weak) IBOutlet NSButton *welcomeAddServerViewButton;
@property (nonatomic, weak) IBOutlet NSProgressIndicator *loadingConfigurationViewPI;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *loadingScreenMinimumWidthConstraint;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *loadingScreenMinimumHeightConstraint;
@property (nonatomic, assign) BOOL stackLocked; // YES when animation is in progress.
@end

@implementation TVCMainWindowLoadingScreenView

#pragma mark -
#pragma mark Display View (Public)

- (void)popWelcomeAddServerView
{
	if (self.stackLocked == NO) {
		[self displayView:self.welcomeAddServerNormalView];
	}
}

- (void)popLoadingConfigurationView
{
	if (self.stackLocked == NO) {
		[self displayView:self.loadingConfigurationView];

		[self.loadingConfigurationViewPI startAnimation:nil];
		[self.loadingConfigurationViewPI setDisplayedWhenStopped:YES];
	}	
}

- (void)popTrialExpiredView
{
	if (self.stackLocked == NO) {
		[self displayView:self.trialExpiredView];
	}
}

#pragma mark -
#pragma mark Hide View (Public)

- (void)hideLoadingConfigurationView
{
	if (self.stackLocked == NO) {
		[self.loadingConfigurationViewPI stopAnimation:nil];
		[self.loadingConfigurationViewPI setDisplayedWhenStopped:NO];
	}
	
	[self hideAll:YES];
}

- (void)hideLoadingConfigurationView:(BOOL)animate
{
	if (self.stackLocked == NO) {
		[self.loadingConfigurationViewPI stopAnimation:nil];
	}

	[self hideAll:animate];
}

#pragma mark -

- (void)hideWelcomeAddServerView
{
	[self hideAll:YES];
}

- (void)hideWelcomeAddServerView:(BOOL)animate
{
	[self hideAll:animate];
}

#pragma mark -

- (void)hideTrialExpiredView
{
	[self hideAll:YES];
}

- (void)hideTrialExpiredView:(BOOL)animate
{
	[self hideAll:animate];
}

#pragma mark -

- (void)hideAll
{
	[self hideAll:YES];
}

- (void)hideAll:(BOOL)animate
{
	if (self.stackLocked == NO) {
		for (NSView *alv in [[self contentView] subviews]) {
			if ([alv isHidden] == NO) {
				[self hideView:alv animate:animate];
			}
		}
	}
}

#pragma mark -
#pragma mark Display View (Private).

- (void)displayView:(NSView *)view
{
	[self disableBackgroundControlsStepOne];

	NSRect viewFrame = [view frame];
	
	[self.loadingScreenMinimumWidthConstraint setConstant:viewFrame.size.width];
	[self.loadingScreenMinimumHeightConstraint setConstant:viewFrame.size.height];

	[view setHidden:NO];

	[view setAlphaValue:1.0];
	
	[self setHidden:NO];

	[self setAlphaValue:1.0];
	
	[self displayIfNeeded];

	[self disableBackgroundControlsStepTwo];
}

#pragma mark -
#pragma mark Hide View (Private).

- (void)hideView:(NSView *)view animate:(BOOL)animate
{
	/* The primary view and background view must be set to hidden instead of simply setting
	 it to 0.0 alpha. If only the alpha is changed, then the underlying WebView will not be
	 able to register mouse movements over elements because the views are invisible and on
	 top of the WebView it_ */

	[self enableBackgroundControlsStepOne];
	
	[self.loadingScreenMinimumWidthConstraint setConstant:0];
	[self.loadingScreenMinimumHeightConstraint setConstant:0];
	
	if (animate == NO) {
		[view setHidden:YES];
	
		[self setHidden:YES];

		[self setAlphaValue:0.0];

		[self enableBackgroundControlsStepTwo];
	} else {
		[RZAnimationCurrentContext() setDuration:0.8];

		[NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
			self.stackLocked = animate;

			[[self animator] setAlphaValue:0.0];
		} completionHandler:^{
			[view setHidden:YES];

			[self setHidden:YES];

			self.stackLocked = NO;

			[self enableBackgroundControlsStepTwo];
		}];
	}
}

#pragma mark -
#pragma mark Private Utilities.

- (BOOL)viewIsVisible
{
	return ([self isHidden] == NO || self.stackLocked);
}

- (void)disableBackgroundControlsStepOne
{
	[[mainWindow() contentSplitView] setHidden:YES];
}

- (void)disableBackgroundControlsStepTwo
{
	[mainWindowTextField() setEditable:NO];
	[mainWindowTextField() setSelectable:NO];
	
	[mainWindowTextField() updateSegmentedController];
}

- (void)enableBackgroundControlsStepOne
{
	[[mainWindow() contentSplitView] setHidden:NO];
}

- (void)enableBackgroundControlsStepTwo
{
	[mainWindowTextField() setEditable:YES];
	[mainWindowTextField() setSelectable:YES];
	
	[mainWindowTextField() updateSegmentedController];
}

@end
