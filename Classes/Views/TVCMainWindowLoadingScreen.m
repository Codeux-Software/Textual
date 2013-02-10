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

@interface TVCMainWindowLoadingScreenView ()
@property (nonatomic, assign) BOOL stackLocked; // YES when animation is in progress.
@end

@implementation TVCMainWindowLoadingScreenView

#pragma mark -
#pragma mark Display View (Public)

- (void)popWelcomeAddServerView
{
	if (self.stackLocked == NO) {
		[self displayView:self.welcomeAddServerView];

		[self.welcomeAddServerViewButton setTarget:self.master.menu];
		[self.welcomeAddServerViewButton setAction:@selector(addServer:)];
	}
}

- (void)popLoadingConfigurationView
{
	if (self.stackLocked == NO) {
		[self displayView:self.loadingConfigurationView];

		[self.loadingConfigurationViewPI startAnimation:nil];
		[self.loadingConfigurationViewPI setDisplayedWhenStopped:NO];
	}	
}

#pragma mark -
#pragma mark Hide View (Public)

- (void)hideLoadingConfigurationView
{
	if (self.stackLocked == NO) {
		[self.loadingConfigurationViewPI stopAnimation:nil];
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

- (void)hideAll
{
	[self hideAll:YES];
}

- (void)hideAll:(BOOL)animate
{
	if (self.stackLocked == NO) {
		for (NSView *alv in [self allViews]) {
			if (alv.isHidden == NO && animate) {
				[self hideView:alv animate:animate];
			}
		}
	}
}

#pragma mark -
#pragma mark Display View (Private).

- (void)displayView:(NSView *)view
{
	[self disableBackgroundControls];

	[view setHidden:NO];
	[view setAlphaValue:1.0];
	
	[self setAlphaValue:1.0];
	[self displayIfNeeded];
}

#pragma mark -
#pragma mark Hide View (Private).

- (void)hideView:(NSView *)view animate:(BOOL)animate
{
	CGFloat _animationDelay = 0.7;

	if (animate == NO) {
		_animationDelay = 0.0;
	}

	[self enableBackgroundControls];
		
	[_NSAnimationCurrentContext() setDuration:_animationDelay];

	[NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
		self.stackLocked = YES;

		[self.animator setAlphaValue:0.0];
	} completionHandler:^{
		[view setHidden:YES];

		self.stackLocked = NO;
	}];
}

#pragma mark -
#pragma mark Private Utilities.

- (NSArray *)allViews
{
	/* For future expansion. */

	return @[self.loadingConfigurationView, self.welcomeAddServerView];
}

- (void)disableBackgroundControls
{
	[self.master.text setEditable:NO];
	[self.master.text setSelectable:NO];

	[self.backgroundContentView setHidden:YES];
}

- (void)enableBackgroundControls
{
	[self.master.text setEditable:YES];
	[self.master.text setSelectable:YES];

	[self.backgroundContentView setHidden:NO];
}

#pragma mark -
#pragma mark Private Utilities.

- (void)drawRect:(NSRect)dirtyRect
{
	NSView *activeView;

	for (NSView *alv in [self allViews]) {
		if (alv.isHidden == NO) {
			activeView = alv;
		} 
	}
	
	NSRect newtRect = activeView.frame;

	newtRect.origin.x  = ((self.window.frame.size.width  / 2) - (newtRect.size.width / 2));
	newtRect.origin.y  = ((self.window.frame.size.height / 2) - (newtRect.size.height / 2));
	newtRect.origin.y -= 24;

	[activeView setFrame:newtRect];

	[super drawRect:dirtyRect];
}

@end
