/* ********************************************************************* 
                  _____         _               _
                 |_   _|____  _| |_ _   _  __ _| |
                   | |/ _ \ \/ / __| | | |/ _` | |
                   | |  __/>  <| |_| |_| | (_| | |
                   |_|\___/_/\_\\__|\__,_|\__,_|_|

 Copyright (c) 2010 — 2014 Codeux Software & respective contributors.
     Please see Acknowledgements.pdf for additional information.

 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions
 are met:

    * Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the
      documentation and/or other materials provided with the distribution.
    * Neither the name of Textual and/or Codeux Software, nor the names of 
      its contributors may be used to endorse or promote products derived 
      from this software without specific prior written permission.

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

#define _textContainerPadding		3

@interface TVCInputPromptDialog ()
@property (nonatomic, assign) BOOL defaultButtonClicked;
@end

@implementation TVCInputPromptDialog

- (void)alertWithMessageTitle:(NSString *)messageTitle
				defaultButton:(NSString *)defaultButtonTitle
			  alternateButton:(NSString *)alternateButtonTitle
			  informativeText:(NSString *)informativeText
			 defaultUserInput:(NSString *)userInputText
			  completionBlock:(void (^)(BOOL defaultButtonClicked, NSString *resultString))callbackBlock
{
	[RZMainBundle() loadCustomNibNamed:@"TVCInputPromptDialog" owner:self topLevelObjects:nil];

	if (NSObjectIsNotEmpty(userInputText)) {
		[self.informationalInput setStringValue:userInputText];
	}
	
	[self.defaultButton	setTitle:defaultButtonTitle];
	[self.defaultButton setAction:@selector(modalDidCloseWithDefaultButton:)];
	[self.defaultButton setTarget:self];

	[self.alternateButton setTitle:alternateButtonTitle];
	[self.alternateButton setAction:@selector(modalDidCloseWithAlternateButton:)];
	[self.alternateButton setTarget:self];
	
	[self.informationalText	setStringValue:informativeText];
	[self.informationalTitle setStringValue:messageTitle];

	self.completionBlock = callbackBlock;

	[self runModal];
}

- (NSFont *)informativeTextFont
{
	return [NSFont boldSystemFontOfSize:11.0];
}

- (void)runModal
{
	/* The following math dynamically resizes the dialog window and informational
	 text view based on any value provided to the modal. It is actually very complex,
	 but Textual has some strong APIs to assist. */
	
	/* Get base measurements. */
	NSString *informativeText = [self.informationalText stringValue];

	NSRect infoTextFrame = [self.informationalText frame];

	CGFloat newHeight = [informativeText pixelHeightInWidth:infoTextFrame.size.width forcedFont:[self informativeTextFont]];

	NSInteger heightDiff = (infoTextFrame.size.height - newHeight);

	/* Compare it to windows frame. */
	NSRect windowFrame = [[self window] frame];
	
	windowFrame.size.height = ((windowFrame.size.height - heightDiff) + _textContainerPadding);
	
	infoTextFrame.size.height = (newHeight + _textContainerPadding);
	
	/* Apply new frames. */
	[[self window] setFrame:windowFrame display:NO animate:NO];
	[[self window] makeKeyAndOrderFront:nil];
	
	[self.informationalText setFrame:infoTextFrame];
}

- (void)modalDidCloseWithDefaultButton:(id)sender
{
	self.defaultButtonClicked = YES;

	[[self window] close];
}

- (void)modalDidCloseWithAlternateButton:(id)sender
{
	self.defaultButtonClicked = NO;

	[[self window] close];
}

- (void)windowWillClose:(NSNotification *)note
{
	if (self.completionBlock) {
		self.completionBlock(self.defaultButtonClicked, [self.informationalInput stringValue]);
	}
}

@end
