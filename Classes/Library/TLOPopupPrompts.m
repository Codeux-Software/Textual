/* ********************************************************************* 
       _____        _               _    ___ ____   ____
      |_   _|___  _| |_ _   _  __ _| |  |_ _|  _ \ / ___|
       | |/ _ \ \/ / __| | | |/ _` | |   | || |_) | |
       | |  __/>  <| |_| |_| | (_| | |   | ||  _ <| |___
       |_|\___/_/\_\\__|\__,_|\__,_|_|  |___|_| \_\\____|

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

#import <objc/objc-runtime.h>

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

+ (void)sheetWindowWithQuestionCallback:(NSAlert *)alert returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo
{
	/* This callback is internal so we will not verify the context. */
	NSArray *sheetInfo = (NSArray *)CFBridgingRelease(contextInfo);

	NSString *suppressionKey = sheetInfo[0];
	NSString *selectorName   = sheetInfo[2];

	BOOL isForcedSuppression = [sheetInfo boolAtIndex:3];

	id  targetClass  = sheetInfo[1];
	SEL targetAction = NSSelectorFromString(selectorName);

	if (NSObjectIsNotEmpty(suppressionKey)) {
		if (isForcedSuppression) {
			[RZStandardUserDefualts() setBool:YES forKey:suppressionKey];
		} else {
			NSButton *button = [alert suppressionButton];

			[RZStandardUserDefualts() setBool:[button state] forKey:suppressionKey];
		}
	}

	if ([targetClass isKindOfClass:[self class]]) {
		return;
	}

	TLOPopupPromptReturnType returnValue = TLOPopupPromptReturnPrimaryType;

	if (returnCode == NSAlertSecondButtonReturn) {
		returnValue = TLOPopupPromptReturnSecondaryType;
	} else if (returnCode == NSAlertOtherReturn ||
			   returnCode == NSAlertThirdButtonReturn)
	{
		returnValue = TLOPopupPromptReturnOtherType;
	}

	objc_msgSend(targetClass, targetAction, returnValue, alert);
}

- (void)sheetWindowWithQuestion:(NSWindow *)window
						 target:(id)targetClass
						 action:(SEL)actionSelector
						   body:(NSString *)bodyText
						  title:(NSString *)titleText
				  defaultButton:(NSString *)buttonDefault
				alternateButton:(NSString *)buttonAlternate
					otherButton:(NSString *)otherButton
				 suppressionKey:(NSString *)suppressKey
				suppressionText:(NSString *)suppressText
{
	/* Check suppression. */
	BOOL useSupression = NSObjectIsNotEmpty(suppressKey);

	NSString *privateSuppressionKey = NSStringEmptyPlaceholder;

	if (suppressKey) {
		privateSuppressionKey = [TLOPopupPromptSuppressionPrefix stringByAppendingString:suppressKey];

		if (useSupression && [RZStandardUserDefualts() boolForKey:privateSuppressionKey]) {
			return;
		}
	}

	if (NSObjectIsEmpty(suppressText)) {
		suppressText = BLS(1194);
	}

	BOOL isForcedSuppression = [suppressText isEqualToString:TLOPopupPromptSpecialSuppressionTextValue];

	/* Pop sheet. */
	NSAlert *alert = [NSAlert new];

	[alert setAlertStyle:NSInformationalAlertStyle];

	[alert setMessageText:titleText];
	[alert setInformativeText:bodyText];
	[alert addButtonWithTitle:buttonDefault];
	[alert addButtonWithTitle:buttonAlternate];
	[alert addButtonWithTitle:otherButton];

	if (useSupression && isForcedSuppression == NO) {
		[alert setShowsSuppressionButton:useSupression];

		[[alert suppressionButton] setTitle:suppressText];
	}
	
	NSArray *context = @[privateSuppressionKey, targetClass, NSStringFromSelector(actionSelector), @(isForcedSuppression)];
	
	[self performBlockOnMainThread:^{
		[alert beginSheetModalForWindow:window
						  modalDelegate:[self class]
						 didEndSelector:@selector(sheetWindowWithQuestionCallback:returnCode:contextInfo:)
							contextInfo:(void *)CFBridgingRetain(context)];
	}];
}

+ (void)popupPromptNilSelector:(TLOPopupPromptReturnType)returnCode withOriginalAlert:(NSAlert *)originalAlert
{
	return;
}

#pragma mark -
#pragma mark Alert Dialogs

+ (BOOL)dialogWindowWithQuestion:(NSString *)bodyText
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
		privateSuppressionKey = [TLOPopupPromptSuppressionPrefix stringByAppendingString:suppressKey];

		if (useSupression && [RZStandardUserDefualts() boolForKey:privateSuppressionKey]) {
			return YES;
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

	NSButton *suppressionButton = [alert suppressionButton];
	
	if (useSupression && isForcedSuppression == NO) {
		[alert setShowsSuppressionButton:useSupression];

		[suppressionButton setTitle:suppressText];
	}

	__block BOOL result = NO;

	void(^runblock)(void) = ^{
		/* Return result. */
		NSModalResponse response = [alert runModal];

		if (response == NSAlertFirstButtonReturn) {
			if (useSupression) {
				if (isForcedSuppression) {
					[RZStandardUserDefualts() setBool:YES forKey:privateSuppressionKey];
				} else {
					[RZStandardUserDefualts() setBool:[suppressionButton state] forKey:privateSuppressionKey];
				}
			}

			result = YES;
		} else {
			if (useSupression) {
				if (isForcedSuppression) {
					[RZStandardUserDefualts() setBool:YES forKey:privateSuppressionKey];
				}
			}

			result = NO;
		}
	};

	[self performBlockOnMainThread:runblock];

	return result;
}

@end
