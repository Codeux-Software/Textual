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

#import <objc/objc-runtime.h>

NSString * const TLOPopupPromptSuppressionPrefix				= @"Text Input Prompt Suppression -> ";

@interface TLOPopupPromptsContext : NSObject
@property (nonatomic, assign) BOOL suppressionTextSet;
@property (nonatomic, assign) BOOL suppressionKeySet;
@property (nonatomic, copy) NSString *suppressionKey;
@property (nonatomic, copy) TLOPopupPromptsCompletionBlock completionBlock;
@end

@implementation TLOPopupPrompts

+ (NSString *)suppressionKeyWithBase:(NSString *)base
{
	NSObjectIsEmptyAssertReturn(base, nil);

	if ([base hasPrefix:TLOPopupPromptSuppressionPrefix]) {
		return base;
	}

	return [TLOPopupPromptSuppressionPrefix stringByAppendingString:base];
}

#pragma mark -
#pragma mark Alert Sheets

+ (void)_sheetWindowWithWindowCallback_stage1:(NSAlert *)alert returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo
{
	TLOPopupPromptsContext *promptData = (TLOPopupPromptsContext *)CFBridgingRelease(contextInfo);

	[TLOPopupPrompts _sheetWindowWithWindowCallback_stage2:alert returnCode:returnCode contextInfo:promptData];
}

+ (void)_sheetWindowWithWindowCallback_stage2:(NSAlert *)alert returnCode:(NSInteger)returnCode contextInfo:(TLOPopupPromptsContext *)contextInfo
{
	BOOL suppressionState = NO;

	if ([alert showsSuppressionButton]) {
		suppressionState = ([[alert suppressionButton] state] == NSOnState);
	}

	if (suppressionState) {
		if ([contextInfo suppressionKeySet]) {
			[RZUserDefaults() setBool:YES forKey:[contextInfo suppressionKey]];
		}
	}

	if ([contextInfo completionBlock]) {
		TLOPopupPromptReturnType returnValue = TLOPopupPromptReturnPrimaryType;

		if (returnCode == NSAlertSecondButtonReturn) {
			returnValue = TLOPopupPromptReturnSecondaryType;
		} else if (returnCode == NSAlertOtherReturn ||
				   returnCode == NSAlertThirdButtonReturn)
		{
			returnValue = TLOPopupPromptReturnOtherType;
		}

		[contextInfo completionBlock](returnValue, alert, suppressionState);
	}
}

+ (void)sheetWindowWithWindow:(NSWindow *)window
						 body:(NSString *)bodyText
						title:(NSString *)titleText
				defaultButton:(NSString *)buttonDefault
			  alternateButton:(NSString *)buttonAlternate
				  otherButton:(NSString *)otherButton
{
	[TLOPopupPrompts sheetWindowWithWindow:window
									  body:bodyText
									 title:titleText
							 defaultButton:buttonDefault
						   alternateButton:buttonAlternate
							   otherButton:otherButton
							suppressionKey:nil
						   suppressionText:nil
						   completionBlock:nil];
}

+ (void)sheetWindowWithWindow:(NSWindow *)window
						 body:(NSString *)bodyText
						title:(NSString *)titleText
				defaultButton:(NSString *)buttonDefault
			  alternateButton:(NSString *)buttonAlternate
				  otherButton:(NSString *)otherButton
			  completionBlock:(TLOPopupPromptsCompletionBlock)completionBlock
{
	[TLOPopupPrompts sheetWindowWithWindow:window
									  body:bodyText
									 title:titleText
							 defaultButton:buttonDefault
						   alternateButton:buttonAlternate
							   otherButton:otherButton
							suppressionKey:nil
						   suppressionText:nil
						   completionBlock:completionBlock];
}

+ (void)sheetWindowWithWindow:(NSWindow *)window
						 body:(NSString *)bodyText
						title:(NSString *)titleText
				defaultButton:(NSString *)buttonDefault
			  alternateButton:(NSString *)buttonAlternate
				  otherButton:(NSString *)otherButton
			   suppressionKey:(NSString *)suppressKey
			  suppressionText:(NSString *)suppressText
			  completionBlock:(TLOPopupPromptsCompletionBlock)completionBlock
{

	/* Check which thread is accessed */
	if ([NSThread isMainThread] == NO) {
		[self performBlockOnMainThread:^{
			[TLOPopupPrompts sheetWindowWithWindow:window
											  body:bodyText
											 title:titleText
									 defaultButton:buttonDefault
								   alternateButton:buttonAlternate
									   otherButton:otherButton
									suppressionKey:suppressKey
								   suppressionText:suppressText
								   completionBlock:completionBlock];
		}];

		return;
	}

	/* Prepare suppression */
	BOOL suppressTextSet = NSObjectIsNotEmpty(suppressText);

	BOOL suppressKeySet = NSObjectIsNotEmpty(suppressKey);

	NSString *suppressKeyPrivate = suppressKey;

	if (suppressKeySet) {
		if ([suppressKeyPrivate hasPrefix:TLOPopupPromptSuppressionPrefix] == NO) {
			suppressKeyPrivate = [TLOPopupPromptSuppressionPrefix stringByAppendingString:suppressKeyPrivate];
		}

		if ([RZUserDefaults() boolForKey:suppressKeyPrivate]) {
			return;
		}
	}

	if (suppressTextSet == NO) {
		suppressText = BLS(1194);
	}

	/* Construct alert */
	NSAlert *alert = [NSAlert new];

	[alert setAlertStyle:NSInformationalAlertStyle];

	[alert setMessageText:titleText];
	[alert setInformativeText:bodyText];
	[alert addButtonWithTitle:buttonDefault];
	[alert addButtonWithTitle:buttonAlternate];
	[alert addButtonWithTitle:otherButton];

	if (suppressTextSet) {
		[alert setShowsSuppressionButton:YES];

		[[alert suppressionButton] setTitle:suppressText];
	}

	/* Construct alert context */
	TLOPopupPromptsContext *promptObject = [TLOPopupPromptsContext new];

	[promptObject setSuppressionTextSet:suppressTextSet];
	[promptObject setSuppressionKeySet:suppressKeySet];

	[promptObject setSuppressionKey:suppressKeyPrivate];

	[promptObject setCompletionBlock:completionBlock];

	/* Pop alert */
	if ([XRSystemInformation isUsingOSXYosemiteOrLater]) {
		[alert beginSheetModalForWindow:window completionHandler:^(NSModalResponse returnCode) {
			[TLOPopupPrompts _sheetWindowWithWindowCallback_stage2:alert returnCode:returnCode contextInfo:promptObject];
		}];
	} else {
		[alert beginSheetModalForWindow:window
						  modalDelegate:[TLOPopupPrompts class]
						 didEndSelector:@selector(_sheetWindowWithWindowCallback_stage1:returnCode:contextInfo:)
							contextInfo:(void *)CFBridgingRetain(promptObject)];
	}
}

#pragma mark -
#pragma mark Alert Dialogs

+ (BOOL)dialogWindowWithMessage:(NSString *)bodyText
						  title:(NSString *)titleText
				  defaultButton:(NSString *)buttonDefault
				alternateButton:(NSString *)buttonAlternate
{
	return [TLOPopupPrompts dialogWindowWithMessage:bodyText
											  title:titleText
									  defaultButton:buttonDefault
									alternateButton:buttonAlternate
									 suppressionKey:nil
									suppressionText:nil];
}

+ (BOOL)dialogWindowWithMessage:(NSString *)bodyText
						  title:(NSString *)titleText
				  defaultButton:(NSString *)buttonDefault
				alternateButton:(NSString *)buttonAlternate
				 suppressionKey:(NSString *)suppressKey
				suppressionText:(NSString *)suppressText
{
	return [TLOPopupPrompts dialogWindowWithMessage:bodyText
											  title:titleText
									  defaultButton:buttonDefault
									alternateButton:buttonAlternate
									 suppressionKey:suppressKey
									suppressionText:suppressText
								suppressionResponse:NULL];
}

+ (BOOL)dialogWindowWithMessage:(NSString *)bodyText
						  title:(NSString *)titleText
				  defaultButton:(NSString *)buttonDefault
				alternateButton:(NSString *)buttonAlternate
				 suppressionKey:(NSString *)suppressKey
				suppressionText:(NSString *)suppressText
			suppressionResponse:(BOOL *)suppressionResponse
{
	/* Check which thread is accessed */
	if ([NSThread isMainThread] == NO) {
		__block BOOL result = NO;

		[self performBlockOnMainThread:^{
			result =
			[TLOPopupPrompts dialogWindowWithMessage:bodyText
											   title:titleText
									   defaultButton:buttonDefault
									 alternateButton:buttonAlternate
									  suppressionKey:suppressKey
									 suppressionText:suppressText
								 suppressionResponse:suppressionResponse];
		}];

		return result;
	}

	/* Prepare suppression */
	BOOL suppressTextSet = NSObjectIsNotEmpty(suppressText);

	BOOL suppressKeySet = NSObjectIsNotEmpty(suppressKey);

	NSString *suppressKeyPrivate = suppressKey;

	if (suppressKeySet) {
		if ([suppressKeyPrivate hasPrefix:TLOPopupPromptSuppressionPrefix] == NO) {
			suppressKeyPrivate = [TLOPopupPromptSuppressionPrefix stringByAppendingString:suppressKeyPrivate];
		}

		if ([RZUserDefaults() boolForKey:suppressKeyPrivate]) {
			return YES;
		}
	}

	if (suppressTextSet == NO) {
		suppressText = BLS(1194);
	}

	/* Construct alert */
	NSAlert *alert = [NSAlert new];

	[alert setMessageText:titleText];
	[alert setInformativeText:bodyText];

	[alert addButtonWithTitle:buttonDefault];
	[alert addButtonWithTitle:buttonAlternate];

	if (suppressTextSet) {
		[alert setShowsSuppressionButton:YES];

		[[alert suppressionButton] setTitle:suppressText];
	}

	/* Pop alert */
	NSModalResponse response = [alert runModal];

	/* Record whether the user pressed the suppression button */
	BOOL suppressionState = NO;

	if ([alert showsSuppressionButton]) {
		suppressionState = ([[alert suppressionButton] state] == NSOnState);
	}

	if ( suppressionResponse) {
		*suppressionResponse = suppressionState;
	}

	/* Return final result */
	if (response == NSAlertFirstButtonReturn) {
		if (suppressionState && suppressKeySet) {
			[RZUserDefaults() setBool:YES forKey:suppressKeyPrivate];
		}

		return YES;
	} else {
		return NO;
	}
}

@end

@implementation TLOPopupPromptsContext
@end
