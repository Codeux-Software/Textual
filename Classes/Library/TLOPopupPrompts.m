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

#import <objc/objc-runtime.h>

#import "TLOLanguagePreferences.h"
#import "TPCPreferencesUserDefaults.h"
#import "TLOPopupPrompts.h"

NS_ASSUME_NONNULL_BEGIN

NSString * const TLOPopupPromptSuppressionPrefix = @"Text Input Prompt Suppression -> ";

@interface TLOPopupPromptsContext : NSObject
@property (nonatomic, assign) BOOL suppressionTextSet;
@property (nonatomic, assign) BOOL suppressionKeySet;
@property (nonatomic, copy, nullable) NSString *suppressionKey;
@property (nonatomic, copy, nullable) TLOPopupPromptsCompletionBlock completionBlock;
@end

@implementation TLOPopupPrompts

+ (NSString *)suppressionKeyWithBase:(NSString *)base
{
	NSParameterAssert(base != nil);

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

	[self _sheetWindowWithWindowCallback_stage2:alert returnCode:returnCode contextInfo:promptData];
}

+ (void)_sheetWindowWithWindowCallback_stage2:(NSAlert *)alert returnCode:(NSInteger)returnCode contextInfo:(TLOPopupPromptsContext *)contextInfo
{
	BOOL suppressionState = NO;

	if (alert.showsSuppressionButton) {
		suppressionState = (alert.suppressionButton.state == NSOnState);
	}

	if (suppressionState) {
		if (contextInfo.suppressionKeySet) {
			[RZUserDefaults() setBool:YES forKey:contextInfo.suppressionKey];
		}
	}

	if (contextInfo.completionBlock) {
		TLOPopupPromptReturnType returnValue = TLOPopupPromptReturnPrimaryType;

		if (returnCode == NSAlertSecondButtonReturn) {
			returnValue = TLOPopupPromptReturnSecondaryType;
		} else if (returnCode == NSAlertOtherReturn ||
				   returnCode == NSAlertThirdButtonReturn)
		{
			returnValue = TLOPopupPromptReturnOtherType;
		}

		contextInfo.completionBlock(returnValue, alert, suppressionState);
	}
}

+ (void)sheetWindowWithWindow:(NSWindow *)window
						 body:(NSString *)bodyText
						title:(NSString *)titleText
				defaultButton:(NSString *)buttonDefault
			  alternateButton:(nullable NSString *)buttonAlternate
				  otherButton:(nullable NSString *)otherButton
{
	[self sheetWindowWithWindow:window
						   body:bodyText
						  title:titleText
				  defaultButton:buttonDefault
				alternateButton:buttonAlternate
					otherButton:otherButton
				 suppressionKey:nil
				suppressionText:nil
				completionBlock:nil
				  accessoryView:nil];
}

+ (void)sheetWindowWithWindow:(NSWindow *)window
						 body:(NSString *)bodyText
						title:(NSString *)titleText
				defaultButton:(NSString *)buttonDefault
			  alternateButton:(nullable NSString *)buttonAlternate
				  otherButton:(nullable NSString *)otherButton
			  completionBlock:(nullable TLOPopupPromptsCompletionBlock)completionBlock
{
	[self sheetWindowWithWindow:window
						   body:bodyText
						  title:titleText
				  defaultButton:buttonDefault
				alternateButton:buttonAlternate
					otherButton:otherButton
				 suppressionKey:nil
				suppressionText:nil
				completionBlock:completionBlock
				  accessoryView:nil];
}

+ (void)sheetWindowWithWindow:(NSWindow *)window
						 body:(NSString *)bodyText
						title:(NSString *)titleText
				defaultButton:(NSString *)buttonDefault
			  alternateButton:(nullable NSString *)buttonAlternate
				  otherButton:(nullable NSString *)otherButton
			  completionBlock:(nullable TLOPopupPromptsCompletionBlock)completionBlock
				accessoryView:(nullable NSView *)accessoryView
{
	[self sheetWindowWithWindow:window
						   body:bodyText
						  title:titleText
				  defaultButton:buttonDefault
				alternateButton:buttonAlternate
					otherButton:otherButton
				 suppressionKey:nil
				suppressionText:nil
				completionBlock:completionBlock
				  accessoryView:accessoryView];
}

+ (void)sheetWindowWithWindow:(NSWindow *)window
						 body:(NSString *)bodyText
						title:(NSString *)titleText
				defaultButton:(NSString *)buttonDefault
			  alternateButton:(nullable NSString *)buttonAlternate
				  otherButton:(nullable NSString *)otherButton
			   suppressionKey:(nullable NSString *)suppressKey
			  suppressionText:(nullable NSString *)suppressText
			  completionBlock:(nullable TLOPopupPromptsCompletionBlock)completionBlock
{
	[self sheetWindowWithWindow:window
						   body:bodyText
						  title:titleText
				  defaultButton:buttonDefault
				alternateButton:buttonAlternate
					otherButton:otherButton
				 suppressionKey:suppressKey
				suppressionText:suppressText
				completionBlock:completionBlock
				  accessoryView:nil];
}

+ (void)sheetWindowWithWindow:(NSWindow *)window
						 body:(NSString *)bodyText
						title:(NSString *)titleText
				defaultButton:(NSString *)buttonDefault
			  alternateButton:(nullable NSString *)buttonAlternate
				  otherButton:(nullable NSString *)otherButton
			   suppressionKey:(nullable NSString *)suppressKey
			  suppressionText:(nullable NSString *)suppressText
			  completionBlock:(nullable TLOPopupPromptsCompletionBlock)completionBlock
				accessoryView:(nullable NSView *)accessoryView
{
	NSParameterAssert(window != nil);
	NSParameterAssert(bodyText != nil);
	NSParameterAssert(titleText != nil);
	NSParameterAssert(buttonDefault != nil);

	/* Check which thread is accessed */
	if ([NSThread isMainThread] == NO) {
		[self performBlockOnMainThread:^{
			[self sheetWindowWithWindow:window
								   body:bodyText
								  title:titleText
						  defaultButton:buttonDefault
						alternateButton:buttonAlternate
							otherButton:otherButton
						 suppressionKey:suppressKey
						suppressionText:suppressText
						completionBlock:completionBlock
						  accessoryView:accessoryView];
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
		suppressText = TXTLS(@"Prompts[1040]");
	}

	/* Construct alert */
	NSAlert *alert = [NSAlert new];

	alert.alertStyle = NSInformationalAlertStyle;

	alert.messageText = titleText;
	alert.informativeText = bodyText;
	[alert addButtonWithTitle:buttonDefault];
	[alert addButtonWithTitle:buttonAlternate];
	[alert addButtonWithTitle:otherButton];

	if (suppressKeySet || suppressTextSet) {
		alert.showsSuppressionButton = YES;

		alert.suppressionButton.title = suppressText;
	}

	if (accessoryView != nil) {
		alert.accessoryView = accessoryView;
	}

	/* Construct alert context */
	TLOPopupPromptsContext *promptObject = [TLOPopupPromptsContext new];

	promptObject.suppressionTextSet = suppressTextSet;
	promptObject.suppressionKeySet = suppressKeySet;

	promptObject.suppressionKey = suppressKeyPrivate;

	promptObject.completionBlock = completionBlock;

	/* Pop alert */
	if (TEXTUAL_RUNNING_ON(10.10, Yosemite)) {
		[alert beginSheetModalForWindow:window completionHandler:^(NSModalResponse returnCode) {
			[self _sheetWindowWithWindowCallback_stage2:alert returnCode:returnCode contextInfo:promptObject];
		}];
	} else {
		[alert beginSheetModalForWindow:window
						  modalDelegate:[self class]
						 didEndSelector:@selector(_sheetWindowWithWindowCallback_stage1:returnCode:contextInfo:)
							contextInfo:(void *)CFBridgingRetain(promptObject)];
	}
}

#pragma mark -
#pragma mark Alert Dialogs

+ (BOOL)dialogWindowWithMessage:(NSString *)bodyText
						  title:(NSString *)titleText
				  defaultButton:(NSString *)buttonDefault
				alternateButton:(nullable NSString *)buttonAlternate
{
	return [self dialogWindowWithMessage:bodyText
								   title:titleText
						   defaultButton:buttonDefault
						 alternateButton:buttonAlternate
						  suppressionKey:nil
						 suppressionText:nil];
}

+ (BOOL)dialogWindowWithMessage:(NSString *)bodyText
						  title:(NSString *)titleText
				  defaultButton:(NSString *)buttonDefault
				alternateButton:(nullable NSString *)buttonAlternate
				 suppressionKey:(nullable NSString *)suppressKey
				suppressionText:(nullable NSString *)suppressText
{
	return [self dialogWindowWithMessage:bodyText
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
				alternateButton:(nullable NSString *)buttonAlternate
				 suppressionKey:(nullable NSString *)suppressKey
				suppressionText:(nullable NSString *)suppressText
			suppressionResponse:(nullable BOOL *)suppressionResponse
{
	NSParameterAssert(bodyText != nil);
	NSParameterAssert(titleText != nil);
	NSParameterAssert(buttonDefault != nil);

	/* Check which thread is accessed */
	if ([NSThread isMainThread] == NO) {
		__block BOOL result = NO;

		[self performBlockOnMainThread:^{
			result =
			[self dialogWindowWithMessage:bodyText
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
		suppressText = TXTLS(@"Prompts[1040]");
	}

	/* Construct alert */
	NSAlert *alert = [NSAlert new];

	alert.messageText = titleText;
	alert.informativeText = bodyText;

	[alert addButtonWithTitle:buttonDefault];
	[alert addButtonWithTitle:buttonAlternate];

	if (suppressKeySet || suppressTextSet) {
		alert.showsSuppressionButton = YES;

		alert.suppressionButton.title = suppressText;
	}

	/* Pop alert */
	NSModalResponse response = [alert runModal];

	/* Record whether the user pressed the suppression button */
	BOOL suppressionState = NO;

	if (alert.showsSuppressionButton) {
		suppressionState = (alert.suppressionButton.state == NSOnState);
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

NS_ASSUME_NONNULL_END
