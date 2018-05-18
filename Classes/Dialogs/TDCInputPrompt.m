/* ********************************************************************* 
                  _____         _               _
                 |_   _|____  _| |_ _   _  __ _| |
                   | |/ _ \ \/ / __| | | |/ _` | |
                   | |  __/>  <| |_| |_| | (_| | |
                   |_|\___/_/\_\\__|\__,_|\__,_|_|

 Copyright (c) 2010 - 2018 Codeux Software, LLC & respective contributors.
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

#import "TDCInputPrompt.h"

NS_ASSUME_NONNULL_BEGIN

@implementation TDCInputPrompt

+ (void)promptWithMessage:(NSString *)bodyText
					title:(NSString *)titleText
			defaultButton:(NSString *)buttonDefault
		  alternateButton:(nullable NSString *)buttonAlternate
			prefillString:(nullable NSString *)prefillString
		  completionBlock:(TDCInputPromptCompletionBlock)completionBlock;
{
	NSParameterAssert(bodyText != nil);
	NSParameterAssert(titleText != nil);
	NSParameterAssert(buttonDefault != nil);
	NSParameterAssert(completionBlock != nil);

	/* Create text field */
	NSTextField *textField = [NSTextField new];

	textField.translatesAutoresizingMaskIntoConstraints = NO;

	[textField addConstraints:
	 @[
	   [NSLayoutConstraint constraintWithItem:textField
									attribute:NSLayoutAttributeWidth
									relatedBy:NSLayoutRelationEqual
									   toItem:nil
									attribute:NSLayoutAttributeNotAnAttribute
								   multiplier:1.0
									 constant:295.0],

	   [NSLayoutConstraint constraintWithItem:textField
									attribute:NSLayoutAttributeHeight
									relatedBy:NSLayoutRelationEqual
									   toItem:nil
									attribute:NSLayoutAttributeNotAnAttribute
								   multiplier:1.0
									 constant:22.0]
	   ]
	 ];

	textField.editable = YES;
	textField.selectable = YES;

	textField.drawsBackground = YES;
	textField.bordered = YES;
	textField.bezeled = YES;

	textField.cell.lineBreakMode = NSLineBreakByTruncatingTail;

	if (prefillString) {
		textField.stringValue = prefillString;
	}

	/* Present prompt */
	[self alertWithMessage:bodyText
					 title:titleText
			 defaultButton:buttonDefault
		   alternateButton:buttonAlternate
			suppressionKey:nil
		   suppressionText:nil
			 accessoryView:textField
		   completionBlock:^(TDCAlertResponse buttonClicked, BOOL suppressed, id underlyingAlert) {
			   [self _finalizePromptWithResponse:buttonClicked textField:textField completionBlock:completionBlock];
		   }];

	/* Make text field first responder */
	[textField.window makeFirstResponder:textField];
}

+ (void)_finalizePromptWithResponse:(TDCAlertResponse)response textField:(NSTextField *)textField completionBlock:(TDCInputPromptCompletionBlock)completionBlock
{
	completionBlock(response, textField.stringValue);
}

@end

NS_ASSUME_NONNULL_END
