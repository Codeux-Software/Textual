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

NSString * const TLOPopupPromptSpecialSuppressionTextValue		= @"<TLOPopupPromptSpecialSuppressionTextValue>";

@interface TLOPopupPromptsContext : NSObject
@property (nonatomic, copy) NSString *suppressionKey;
@property (nonatomic, assign) BOOL isForcedSuppression;
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
	if ([contextInfo suppressionKey]) {
		if ([contextInfo isForcedSuppression]) {
			[RZUserDefaults() setBool:YES forKey:[contextInfo suppressionKey]];
		} else {
			NSButton *button = [alert suppressionButton];

			[RZUserDefaults() setBool:[button state] forKey:[contextInfo suppressionKey]];
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

		[contextInfo completionBlock](returnValue, alert);
	}
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
	/* Check suppression. */
	NSString *suppressionText = [suppressText copy];

	BOOL useSupression = NSObjectIsNotEmpty(suppressKey);

	NSString *privateSuppressionKey = nil;

	if (suppressKey) {
		if ([suppressKey hasPrefix:TLOPopupPromptSuppressionPrefix] == NO) {
			privateSuppressionKey = [TLOPopupPromptSuppressionPrefix stringByAppendingString:suppressKey];
		}

		if (useSupression) {
			if ([RZUserDefaults() boolForKey:privateSuppressionKey]) {
				return;
			}
		}
	}

	if (NSObjectIsEmpty(suppressionText)) {
		suppressionText = BLS(1194);
	}

	BOOL isForcedSuppression = [suppressionText isEqualToString:TLOPopupPromptSpecialSuppressionTextValue];

	/* Pop sheet. */
	NSAlert *alert = [NSAlert new];

	[alert setAlertStyle:NSInformationalAlertStyle];

	[alert setMessageText:titleText];
	[alert setInformativeText:bodyText];
	[alert addButtonWithTitle:buttonDefault];
	[alert addButtonWithTitle:buttonAlternate];
	[alert addButtonWithTitle:otherButton];

	if (isForcedSuppression == NO) {
		if (useSupression) {
			[alert setShowsSuppressionButton:useSupression];

			[[alert suppressionButton] setTitle:suppressionText];
		}
	}

	[self performBlockOnMainThread:^{
		TLOPopupPromptsContext *promptObject = [TLOPopupPromptsContext new];

		[promptObject setSuppressionKey:privateSuppressionKey];
		[promptObject setIsForcedSuppression:isForcedSuppression];
		[promptObject setCompletionBlock:completionBlock];

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
	}];
}

#pragma mark -
#pragma mark Alert Dialogs

+ (BOOL)dialogWindowWithMessage:(NSString *)bodyText
						  title:(NSString *)titleText
				  defaultButton:(NSString *)buttonDefault
				alternateButton:(NSString *)buttonAlternate
				 suppressionKey:(NSString *)suppressKey
				suppressionText:(NSString *)suppressText
{
	/* Prepare suppression. */
	BOOL useSupression = NSObjectIsNotEmpty(suppressKey);

	NSString *privateSuppressionKey = nil;

	if (suppressKey) {
		if ([suppressKey hasPrefix:TLOPopupPromptSuppressionPrefix] == NO) {
			privateSuppressionKey = [TLOPopupPromptSuppressionPrefix stringByAppendingString:suppressKey];
		}

		if (useSupression) {
			if ([RZUserDefaults() boolForKey:privateSuppressionKey]) {
				return YES;
			}
		}
	}

	if (NSObjectIsEmpty(suppressText)) {
		suppressText = BLS(1194);
	}

	BOOL isForcedSuppression = [suppressText isEqualToString:TLOPopupPromptSpecialSuppressionTextValue];

	/* Pop dialog. */
	NSAlert *alert = [NSAlert new];

	[alert setMessageText:titleText];
	[alert setInformativeText:bodyText];

	[alert addButtonWithTitle:buttonDefault];
	[alert addButtonWithTitle:buttonAlternate];

	if (isForcedSuppression == NO) {
		if (useSupression) {
			[alert setShowsSuppressionButton:useSupression];

			[[alert suppressionButton] setTitle:suppressText];
		}
	}

	__block BOOL result = NO;

	void(^runblock)(void) = ^{
		/* Return result. */
		NSModalResponse response = [alert runModal];

		if (response == NSAlertFirstButtonReturn) {
			if (useSupression) {
				if (isForcedSuppression) {
					[RZUserDefaults() setBool:YES forKey:privateSuppressionKey];
				} else {
					[RZUserDefaults() setBool:[[alert suppressionButton] state] forKey:privateSuppressionKey];
				}
			}

			result = YES;
		} else {
			if (useSupression) {
				if (isForcedSuppression) {
					[RZUserDefaults() setBool:YES forKey:privateSuppressionKey];
				}
			}

			result = NO;
		}
	};

	[self performBlockOnMainThread:runblock];

	return result;
}

@end

@implementation TLOPopupPromptsContext
@end
