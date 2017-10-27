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

#import "TVCInputPromptDialog.h"

NS_ASSUME_NONNULL_BEGIN

@interface TVCInputPromptDialog ()
@property (nonatomic, weak) IBOutlet NSButton *defaultButton;
@property (nonatomic, weak) IBOutlet NSButton *alternateButton;
@property (nonatomic, weak) IBOutlet NSTextField *informationalText;
@property (nonatomic, weak) IBOutlet NSTextField *informationalTitle;
@property (nonatomic, weak) IBOutlet NSTextField *informationalInput;
@property (nonatomic, copy) TVCInputPromptDialogCompletionBlock completionBlock;
@property (nonatomic, assign) BOOL defaultButtonClicked;

- (IBAction)modalDidCloseWithDefaultButton:(id)sender;
- (IBAction)modalDidCloseWithAlternateButton:(id)sender;
@end

@implementation TVCInputPromptDialog

- (void)alertWithMessageTitle:(NSString *)messageTitle
			  informativeText:(NSString *)informativeText
				defaultButton:(NSString *)defaultButtonTitle
			  alternateButton:(nullable NSString *)alternateButtonTitle
			 defaultUserInput:(nullable NSString *)userInputText
			  completionBlock:(nullable TVCInputPromptDialogCompletionBlock)completionBlock
{
	NSParameterAssert(messageTitle != nil);
	NSParameterAssert(informativeText != nil);
	NSParameterAssert(defaultButtonTitle != nil);

	(void)[RZMainBundle() loadNibNamed:@"TVCInputPromptDialog" owner:self topLevelObjects:nil];

	if (userInputText) {
		self.informationalInput.stringValue = userInputText;
	}

	self.defaultButton.title = defaultButtonTitle;
	self.defaultButton.action = @selector(modalDidCloseWithDefaultButton:);
	self.defaultButton.target = self;

	self.alternateButton.title = alternateButtonTitle;
	self.alternateButton.action = @selector(modalDidCloseWithAlternateButton:);
	self.alternateButton.target = self;

	self.informationalTitle.stringValue = messageTitle;
	self.informationalText.stringValue = informativeText;

	self.completionBlock = completionBlock;

	[self.window makeKeyAndOrderFront:nil];
}

- (void)modalDidCloseWithDefaultButton:(id)sender
{
	self.defaultButtonClicked = YES;

	[self.window close];
}

- (void)modalDidCloseWithAlternateButton:(id)sender
{
	self.defaultButtonClicked = NO;

	[self.window close];
}

- (void)windowWillClose:(NSNotification *)note
{
	if (self.completionBlock) {
		self.completionBlock(self, self.defaultButtonClicked, self.informationalInput.stringValue);
	}
}

@end

NS_ASSUME_NONNULL_END
