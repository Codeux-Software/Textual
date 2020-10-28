/* *********************************************************************
 *                  _____         _               _
 *                 |_   _|____  _| |_ _   _  __ _| |
 *                   | |/ _ \ \/ / __| | | |/ _` | |
 *                   | |  __/>  <| |_| |_| | (_| | |
 *                   |_|\___/_/\_\\__|\__,_|\__,_|_|
 *
 * Copyright (c) 2010 - 2018 Codeux Software, LLC & respective contributors.
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

#import "TDCAlert.h"
#import "TLOPopupPrompts.h"

NS_ASSUME_NONNULL_BEGIN

NSString * const TLOPopupPromptSuppressionPrefix = @"Text Input Prompt Suppression -> ";

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-implementations"
@implementation TLOPopupPrompts

#pragma mark -
#pragma mark Alert Sheets

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
	TDCAlertCompletionBlock completionBlockNew = nil;

	if (completionBlock) {
		completionBlockNew = ^(TDCAlertResponse buttonClicked, BOOL suppressed, id _Nullable underlyingAlert) {
			TLOPopupPromptReturnType returnType = [self _convertResponseFromTDCAlert:buttonClicked];

			completionBlock(returnType, underlyingAlert, suppressed);
		};
	}

	[TDCAlert alertSheetWithWindow:window
							  body:bodyText
							 title:titleText
					 defaultButton:buttonDefault
				   alternateButton:buttonAlternate
					   otherButton:otherButton
					suppressionKey:suppressKey
				   suppressionText:suppressText
					 accessoryView:accessoryView
				   completionBlock:completionBlockNew];
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
	return
	[TDCAlert modalAlertWithMessage:bodyText
							  title:titleText
					  defaultButton:buttonDefault
					alternateButton:buttonAlternate
					 suppressionKey:suppressKey
					suppressionText:suppressText
				suppressionResponse:suppressionResponse];
}

#pragma mark -
#pragma mark Utilities

+ (NSString *)suppressionKeyWithBase:(NSString *)base
{
	NSParameterAssert(base != nil);

	if ([base hasPrefix:TLOPopupPromptSuppressionPrefix]) {
		return base;
	}

	return [TLOPopupPromptSuppressionPrefix stringByAppendingString:base];
}

+ (TLOPopupPromptReturnType)_convertResponseFromTDCAlert:(TDCAlertResponse)response
{
	switch (response) {
		case TDCAlertResponseAlternate:
		{
			return TLOPopupPromptReturnSecondaryType;
		}
		case TDCAlertResponseOther:
		{
			return TLOPopupPromptReturnOtherType;
		}
		default:
		{
			return TLOPopupPromptReturnPrimaryType;
		}
	}
}

@end
#pragma clang diagnostic pop

NS_ASSUME_NONNULL_END
