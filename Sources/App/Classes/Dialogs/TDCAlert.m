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

#import "TLOLocalization.h"
#import "TPCPreferencesUserDefaults.h"
#import "TDCAlert.h"

NS_ASSUME_NONNULL_BEGIN

NSString * const TDCAlertSuppressionPrefix = @"Text Input Prompt Suppression -> ";

@interface TDCAlertContext : NSObject
@property (nonatomic, copy, nullable) NSString *suppressionKey;
@property (nonatomic, copy, nullable) TDCAlertCompletionBlock completionBlock;
@end

@implementation TDCAlert

#pragma mark -
#pragma mark Modal Alerts (Panel)

+ (BOOL)modalAlertWithMessage:(NSString *)bodyText
						title:(NSString *)titleText
				defaultButton:(NSString *)buttonDefault
			  alternateButton:(nullable NSString *)buttonAlternate
{
	return
	[self modalAlertWithMessage:bodyText
						  title:titleText
				  defaultButton:buttonDefault
				alternateButton:buttonAlternate
				 suppressionKey:nil
				suppressionText:nil
				  accessoryView:nil
			suppressionResponse:NULL];
}

+ (BOOL)modalAlertWithMessage:(NSString *)bodyText
						title:(NSString *)titleText
				defaultButton:(NSString *)buttonDefault
			  alternateButton:(nullable NSString *)buttonAlternate
			   suppressionKey:(nullable NSString *)suppressKey
			  suppressionText:(nullable NSString *)suppressText
{
	return
	[self modalAlertWithMessage:bodyText
						  title:titleText
				  defaultButton:buttonDefault
				alternateButton:buttonAlternate
				 suppressionKey:suppressKey
				suppressionText:suppressText
				  accessoryView:nil
			suppressionResponse:NULL];
}

+ (BOOL)modalAlertWithMessage:(NSString *)bodyText
						 title:(NSString *)titleText
				 defaultButton:(NSString *)buttonDefault
			   alternateButton:(nullable NSString *)buttonAlternate
				suppressionKey:(nullable NSString *)suppressKey
			   suppressionText:(nullable NSString *)suppressText
				 accessoryView:(nullable NSView *)accessoryView
{
	return
	[self modalAlertWithMessage:bodyText
						  title:titleText
				  defaultButton:buttonDefault
				alternateButton:buttonAlternate
				 suppressionKey:suppressKey
				suppressionText:suppressText
				  accessoryView:accessoryView
			suppressionResponse:NULL];
}

+ (BOOL)modalAlertWithMessage:(NSString *)bodyText
						title:(NSString *)titleText
				defaultButton:(NSString *)buttonDefault
			  alternateButton:(nullable NSString *)buttonAlternate
			   suppressionKey:(nullable NSString *)suppressKey
			  suppressionText:(nullable NSString *)suppressText
		  suppressionResponse:(nullable BOOL *)suppressionResponse
{
	return
	[self modalAlertWithMessage:bodyText
						  title:titleText
				  defaultButton:buttonDefault
				alternateButton:buttonAlternate
				 suppressionKey:suppressKey
				suppressionText:suppressText
				  accessoryView:nil
			suppressionResponse:suppressionResponse];
}

+ (BOOL)modalAlertWithMessage:(NSString *)bodyText
						title:(NSString *)titleText
				defaultButton:(NSString *)buttonDefault
			  alternateButton:(nullable NSString *)buttonAlternate
			   suppressionKey:(nullable NSString *)suppressKey
			  suppressionText:(nullable NSString *)suppressText
				accessoryView:(nullable NSView *)accessoryView
		  suppressionResponse:(nullable BOOL *)suppressionResponse
{
	NSParameterAssert(bodyText != nil);
	NSParameterAssert(titleText != nil);
	NSParameterAssert(buttonDefault != nil);

	/* Require main thread */
	if ([NSThread isMainThread] == NO) {
		__block BOOL result = NO;

		[self performBlockOnMainThread:^{
			result =
			[self modalAlertWithMessage:bodyText
								  title:titleText
						  defaultButton:buttonDefault
						alternateButton:buttonAlternate
						 suppressionKey:suppressKey
						suppressionText:suppressText
						  accessoryView:accessoryView
					suppressionResponse:suppressionResponse];
		}];

		return result;
	}

	/* Prepare suppression */
	if (suppressKey) {
		suppressKey = [self suppressionKeyWithBase:suppressKey];

		/* Exit if suppressed */
		if ([RZUserDefaults() boolForKey:suppressKey]) {
			return YES;
		}
	}

	if (suppressKey && (suppressText == nil || suppressText.length == 0)) {
		suppressText = TXTLS(@"Prompts[68u-z9]");
	}

	/* Construct alert */
	NSAlert *alert = [NSAlert new];

	alert.messageText = titleText;
	alert.informativeText = bodyText;

	[alert addButtonWithTitle:buttonDefault];

	if (buttonAlternate) {
		[alert addButtonWithTitle:buttonAlternate];
	}

	if (suppressKey || suppressText) {
		alert.showsSuppressionButton = YES;

		alert.suppressionButton.title = suppressText;
	}

	if (accessoryView) {
		alert.accessoryView = accessoryView;
	}

	/* Pop alert */
	NSModalResponse returnCode = [alert runModal];

	TDCAlertResponse response = [self _convertResponseFromNSAlert:returnCode];

	[self _finalizeAlert:alert
			withResponse:response
		 completionBlock:nil
		  suppressionKey:suppressKey
	 suppressionResponse:suppressionResponse];

	return (response == TDCAlertResponseDefault);
}

#pragma mark -
#pragma mark Non-blocking Alerts (Panel)

+ (void)alertWithMessage:(NSString *)bodyText
				   title:(NSString *)titleText
		   defaultButton:(NSString *)buttonDefault
		 alternateButton:(nullable NSString *)buttonAlternate
{
	[self alertWithMessage:bodyText
					 title:titleText
			 defaultButton:buttonDefault
		   alternateButton:buttonAlternate
			suppressionKey:nil
		   suppressionText:nil
			 accessoryView:nil
		   completionBlock:nil];
}

+ (void)alertWithMessage:(NSString *)bodyText
				   title:(NSString *)titleText
		   defaultButton:(NSString *)buttonDefault
		 alternateButton:(nullable NSString *)buttonAlternate
		  suppressionKey:(nullable NSString *)suppressKey
		 suppressionText:(nullable NSString *)suppressText
{
	[self alertWithMessage:bodyText
					 title:titleText
			 defaultButton:buttonDefault
		   alternateButton:buttonAlternate
			suppressionKey:suppressKey
		   suppressionText:suppressText
			 accessoryView:nil
		   completionBlock:nil];
}

+ (void)alertWithMessage:(NSString *)bodyText
				   title:(NSString *)titleText
		   defaultButton:(NSString *)buttonDefault
		 alternateButton:(nullable NSString *)buttonAlternate
		 completionBlock:(nullable TDCAlertCompletionBlock)completionBlock
{
	[self alertWithMessage:bodyText
					 title:titleText
			 defaultButton:buttonDefault
		   alternateButton:buttonAlternate
			suppressionKey:nil
		   suppressionText:nil
			 accessoryView:nil
		   completionBlock:completionBlock];
}

+ (void)alertWithMessage:(NSString *)bodyText
				   title:(NSString *)titleText
		   defaultButton:(NSString *)buttonDefault
		 alternateButton:(nullable NSString *)buttonAlternate
		  suppressionKey:(nullable NSString *)suppressKey
		 suppressionText:(nullable NSString *)suppressText
		 completionBlock:(nullable TDCAlertCompletionBlock)completionBlock
{
	[self alertWithMessage:bodyText
					 title:titleText
			 defaultButton:buttonDefault
		   alternateButton:buttonAlternate
			suppressionKey:suppressKey
		   suppressionText:suppressText
			 accessoryView:nil
		   completionBlock:completionBlock];
}

+ (void)alertWithMessage:(NSString *)bodyText
				   title:(NSString *)titleText
		   defaultButton:(NSString *)buttonDefault
		 alternateButton:(nullable NSString *)buttonAlternate
		  suppressionKey:(nullable NSString *)suppressKey
		 suppressionText:(nullable NSString *)suppressText
		   accessoryView:(nullable NSView *)accessoryView
		 completionBlock:(nullable TDCAlertCompletionBlock)completionBlock
{
	NSParameterAssert(bodyText != nil);
	NSParameterAssert(titleText != nil);
	NSParameterAssert(buttonDefault != nil);

	/* Require main thread */
	if ([NSThread isMainThread] == NO) {
		[self performBlockOnMainThread:^{
			[self alertWithMessage:bodyText
							 title:titleText
					 defaultButton:buttonDefault
				   alternateButton:buttonAlternate
					suppressionKey:suppressKey
				   suppressionText:suppressText
					 accessoryView:accessoryView
				   completionBlock:completionBlock];
		}];
	}

	/* Prepare suppression */
	if (suppressKey) {
		suppressKey = [self suppressionKeyWithBase:suppressKey];

		/* Exit if suppressed */
		if ([RZUserDefaults() boolForKey:suppressKey]) {
			if (completionBlock) {
				completionBlock(TDCAlertResponseDefault, YES, nil);
			}

			return;
		}
	}

	if (suppressKey && (suppressText == nil || suppressText.length == 0)) {
		suppressText = TXTLS(@"Prompts[68u-z9]");
	}

	/* Construct alert */
	TVCAlert *alert = [TVCAlert new];

	alert.messageText = titleText;
	alert.informativeText = bodyText;

	[alert addButtonWithTitle:buttonDefault];

	if (buttonAlternate) {
		[alert addButtonWithTitle:buttonAlternate];
	}

	if (suppressKey || suppressText) {
		alert.showsSuppressionButton = YES;

		alert.suppressionButton.title = suppressText;
	}

	if (accessoryView) {
		alert.accessoryView = accessoryView;
	}

	/* Pop alert */
	[alert showAlertWithCompletionBlock:^(TVCAlert *sender, TVCAlertResponseButton buttonClicked)
	{
		[self _finalizeAlert:alert
				withResponse:[self _convertResponseFromTVCAlert:buttonClicked]
			 completionBlock:completionBlock
			  suppressionKey:suppressKey
		 suppressionResponse:NULL];
	}];
}

#pragma mark -
#pragma mark Non-blocking Alerts (Sheet)

+ (void)alertSheetWithWindow:(NSWindow *)window
						body:(NSString *)bodyText
					   title:(NSString *)titleText
			   defaultButton:(NSString *)buttonDefault
			 alternateButton:(nullable NSString *)buttonAlternate
				 otherButton:(nullable NSString *)otherButton
{
	[self alertSheetWithWindow:window
						  body:bodyText
						 title:titleText
				 defaultButton:buttonDefault
			   alternateButton:buttonAlternate
				   otherButton:otherButton
				suppressionKey:nil
			   suppressionText:nil
				 accessoryView:nil
			   completionBlock:nil];
}

+ (void)alertSheetWithWindow:(NSWindow *)window
						body:(NSString *)bodyText
					   title:(NSString *)titleText
			   defaultButton:(NSString *)buttonDefault
			 alternateButton:(nullable NSString *)buttonAlternate
				 otherButton:(nullable NSString *)otherButton
			 completionBlock:(nullable TDCAlertCompletionBlock)completionBlock
{
	[self alertSheetWithWindow:window
						  body:bodyText
						 title:titleText
				 defaultButton:buttonDefault
			   alternateButton:buttonAlternate
				   otherButton:otherButton
				suppressionKey:nil
			   suppressionText:nil
				 accessoryView:nil
			   completionBlock:completionBlock];
}

+ (void)alertSheetWithWindow:(NSWindow *)window
						body:(NSString *)bodyText
					   title:(NSString *)titleText
			   defaultButton:(NSString *)buttonDefault
			 alternateButton:(nullable NSString *)buttonAlternate
				 otherButton:(nullable NSString *)otherButton
			   accessoryView:(nullable NSView *)accessoryView
			 completionBlock:(nullable TDCAlertCompletionBlock)completionBlock
{
	[self alertSheetWithWindow:window
						  body:bodyText
						 title:titleText
				 defaultButton:buttonDefault
			   alternateButton:buttonAlternate
				   otherButton:otherButton
				suppressionKey:nil
			   suppressionText:nil
				 accessoryView:accessoryView
			   completionBlock:completionBlock];
}

+ (void)alertSheetWithWindow:(NSWindow *)window
						body:(NSString *)bodyText
					   title:(NSString *)titleText
			   defaultButton:(NSString *)buttonDefault
			 alternateButton:(nullable NSString *)buttonAlternate
				 otherButton:(nullable NSString *)otherButton
			  suppressionKey:(nullable NSString *)suppressKey
			 suppressionText:(nullable NSString *)suppressText
			 completionBlock:(nullable TDCAlertCompletionBlock)completionBlock
{
	[self alertSheetWithWindow:window
						  body:bodyText
						 title:titleText
				 defaultButton:buttonDefault
			   alternateButton:buttonAlternate
				   otherButton:otherButton
				suppressionKey:suppressKey
			   suppressionText:suppressText
				 accessoryView:nil
			   completionBlock:completionBlock];
}

+ (void)alertSheetWithWindow:(NSWindow *)window
						body:(NSString *)bodyText
					   title:(NSString *)titleText
			   defaultButton:(NSString *)buttonDefault
			 alternateButton:(nullable NSString *)buttonAlternate
				 otherButton:(nullable NSString *)otherButton
			  suppressionKey:(nullable NSString *)suppressKey
			 suppressionText:(nullable NSString *)suppressText
			   accessoryView:(nullable NSView *)accessoryView
			 completionBlock:(nullable TDCAlertCompletionBlock)completionBlock
{
	NSParameterAssert(window != nil);
	NSParameterAssert(bodyText != nil);
	NSParameterAssert(titleText != nil);
	NSParameterAssert(buttonDefault != nil);

	/* Require main thread */
	if ([NSThread isMainThread] == NO) {
		[self performBlockOnMainThread:^{
			[self alertSheetWithWindow:window
								  body:bodyText
								 title:titleText
						 defaultButton:buttonDefault
					   alternateButton:buttonAlternate
						   otherButton:otherButton
						suppressionKey:suppressKey
					   suppressionText:suppressText
						 accessoryView:accessoryView
					   completionBlock:completionBlock];
		}];
	}

	/* Prepare suppression */
	if (suppressKey) {
		suppressKey = [self suppressionKeyWithBase:suppressKey];

		/* Exit if suppressed */
		if ([RZUserDefaults() boolForKey:suppressKey]) {
			if (completionBlock) {
				completionBlock(TDCAlertResponseDefault, YES, nil);
			}

			return;
		}
	}

	if (suppressKey && (suppressText == nil || suppressText.length == 0)) {
		suppressText = TXTLS(@"Prompts[68u-z9]");
	}

	/* Construct alert */
	NSAlert *alert = [NSAlert new];

	alert.alertStyle = NSInformationalAlertStyle;

	alert.messageText = titleText;
	alert.informativeText = bodyText;

	[alert addButtonWithTitle:buttonDefault];

	if (buttonAlternate) {
		[alert addButtonWithTitle:buttonAlternate];
	}

	if (otherButton) {
		[alert addButtonWithTitle:otherButton];
	}

	if (suppressKey || suppressText) {
		alert.showsSuppressionButton = YES;

		alert.suppressionButton.title = suppressText;
	}

	if (accessoryView) {
		alert.accessoryView = accessoryView;
	}

	/* Construct alert context */
	TDCAlertContext *context = [TDCAlertContext new];

	context.suppressionKey = suppressKey;

	context.completionBlock = completionBlock;

	/* Pop alert */
	if (TEXTUAL_RUNNING_ON_YOSEMITE) {
		[alert beginSheetModalForWindow:window completionHandler:^(NSModalResponse returnCode) {
			[self _alertSheetResponseCallback_stage2:alert returnCode:returnCode contextInfo:context];
		}];
	} else {
		[alert beginSheetModalForWindow:window
						  modalDelegate:[self class]
						 didEndSelector:@selector(_alertSheetResponseCallback_stage1:returnCode:contextInfo:)
							contextInfo:(void *)CFBridgingRetain(context)];
	}
}

+ (void)_alertSheetResponseCallback_stage1:(NSAlert *)alert returnCode:(NSInteger)returnCode contextInfo:(void *)context
{
	TDCAlertContext *contextObject = ((TDCAlertContext *)CFBridgingRelease(context));

	[self _alertSheetResponseCallback_stage2:alert returnCode:returnCode contextInfo:contextObject];
}

+ (void)_alertSheetResponseCallback_stage2:(NSAlert *)alert returnCode:(NSInteger)returnCode contextInfo:(TDCAlertContext *)context
{
	NSString *suppressionKey = context.suppressionKey;

	TDCAlertCompletionBlock completionBlock = context.completionBlock;

	[self _finalizeAlert:alert
			withResponse:[self _convertResponseFromNSAlert:returnCode]
		 completionBlock:completionBlock
		  suppressionKey:suppressionKey
	 suppressionResponse:NULL];
}

#pragma mark -
#pragma mark Utilities

+ (NSString *)suppressionKeyWithBase:(NSString *)base
{
	NSParameterAssert(base != nil);

	if ([base hasPrefix:TDCAlertSuppressionPrefix]) {
		return base;
	}

	return [TDCAlertSuppressionPrefix stringByAppendingString:base];
}

+ (void)_finalizeAlert:(nullable id)underlyingAlert
		  withResponse:(TDCAlertResponse)response
	   completionBlock:(nullable TDCAlertCompletionBlock)completionBlock
		suppressionKey:(nullable NSString *)suppressionKey
   suppressionResponse:(nullable BOOL *)suppressionResponse
{
	BOOL suppressed = [self _recordSuppressionForButton:[underlyingAlert suppressionButton] withKey:suppressionKey];

	if ( suppressionResponse) {
		*suppressionResponse = suppressed;
	}

	if (completionBlock) {
		completionBlock(response, suppressed, underlyingAlert);
	}
}

+ (BOOL)_recordSuppressionForButton:(nullable NSButton *)suppressionButton withKey:(nullable NSString *)suppressionKey
{
	/* There are some times when we use suppression text field
	 to give user option that doesn't mean to suppress the
	 prompt next time. We therefore only return NO for both
	 arguments missing and not just one. */
	if (suppressionButton == nil && suppressionKey == nil) {
		return NO;
	}

	BOOL suppressed = (suppressionButton.state == NSOnState);

	if (suppressed) {
		[RZUserDefaults() setBool:YES forKey:suppressionKey];
	}

	return suppressed;
}

+ (TDCAlertResponse)_convertResponseFromNSAlert:(NSUInteger)response
{
	switch (response) {
		case NSAlertSecondButtonReturn:
		{
			return TDCAlertResponseAlternate;
		}
		case NSAlertThirdButtonReturn:
		{
			return TDCAlertResponseOther;
		}
		default:
		{
			return TDCAlertResponseDefault;
		}
	}
}

+ (TDCAlertResponse)_convertResponseFromTVCAlert:(TVCAlertResponseButton)response
{
	switch (response) {
		case TVCAlertResponseButtonSecond:
		{
			return TDCAlertResponseAlternate;
		}
		case TVCAlertResponseButtonThird:
		{
			return TDCAlertResponseOther;
		}
		default:
		{
			return TDCAlertResponseDefault;
		}
	}
}

@end

#pragma mark -

@implementation TDCAlertContext
@end

NS_ASSUME_NONNULL_END
