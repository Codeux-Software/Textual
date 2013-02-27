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

#define _textContainerPadding		3

#define _informativeTextFont		[NSFont fontWithName:@"Lucida Grande" size:11.0] 

@implementation TVCInputPromptDialog

- (void)alertWithMessageTitle:(NSString *)messageTitle
				defaultButton:(NSString *)defaultButtonTitle
			  alternateButton:(NSString *)alternateButtonTitle
			  informativeText:(NSString *)informativeText
			 defaultUserInput:(NSString *)userInputText
{
	[NSBundle loadNibNamed:@"TVCInputPromptDialog" owner:self];
	
	if (NSObjectIsNotEmpty(userInputText)) {
		[self.informationalInput setStringValue:userInputText];
	}
	
	[self.defaultButton	setTitle:defaultButtonTitle];
	[self.alternateButton setTitle:alternateButtonTitle];
	
	[self.informationalText	setStringValue:informativeText];
	[self.informationalTitle setStringValue:messageTitle];
}

- (void)runModal
{
	/* The following math dynamically resizes the dialog window and informational
	 text view based on any value provided to the modal. It is actually very complex,
	 but Textual has some strong APIs to assist. */
	
	NSString *informativeText = [self.informationalText stringValue];

	NSRect windowFrame = self.dialogWindow.frame;
	NSRect infoTextFrame = self.informationalText.frame;

	CGFloat newHeight = [informativeText pixelHeightInWidth:infoTextFrame.size.width forcedFont:_informativeTextFont];

	NSInteger heightDiff = (infoTextFrame.size.height - newHeight);

	windowFrame.size.height = ((windowFrame.size.height - heightDiff) + _textContainerPadding);
	infoTextFrame.size.height = (newHeight + _textContainerPadding);
	
	[self.dialogWindow setFrame:windowFrame display:NO animate:NO];
	[self.dialogWindow makeKeyAndOrderFront:nil];
	
	[self.informationalText setFrame:infoTextFrame];
	
	while (self.dialogWindow.isVisible) {
		continue; // Loop until we have a value.
	}
}

- (NSString *)promptValue
{
	return self.finalModalValue;
}

- (void)modalDidCloseWithDefaultButton:(id)sender
{
	self.buttonClicked = NSAlertDefaultReturn;
	
	self.finalModalValue = self.informationalInput.stringValue;
	
	[self.dialogWindow close];
}

- (void)modalDidCloseWithAlternateButton:(id)sender
{
	self.buttonClicked = NSAlertAlternateReturn;

	self.finalModalValue = self.informationalInput.stringValue;
	
	[self.dialogWindow close];
}

@end
