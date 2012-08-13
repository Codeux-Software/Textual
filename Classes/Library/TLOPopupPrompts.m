/* ********************************************************************* 
       _____        _               _    ___ ____   ____
      |_   _|___  _| |_ _   _  __ _| |  |_ _|  _ \ / ___|
       | |/ _ \ \/ / __| | | |/ _` | |   | || |_) | |
       | |  __/>  <| |_| |_| | (_| | |   | ||  _ <| |___
       |_|\___/_/\_\\__|\__,_|\__,_|_|  |___|_| \_\\____|

 Copyright (c) 2010 — 2012 Codeux Software & respective contributors.
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

#import <objc/objc-runtime.h>

@implementation TLOPopupPrompts

#pragma mark -
#pragma mark Alert Sheets

+ (void)sheetWindowWithQuestionCallback:(NSAlert *)alert returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo
{
	NSArray *sheetInfo = (NSArray *)CFBridgingRelease(contextInfo);

	NSString *suppressionKey = sheetInfo[0];
	NSString *selectorName   = sheetInfo[2];

	id  targetClass  = sheetInfo[1];
	SEL targetAction = NSSelectorFromString(selectorName);

	if (NSObjectIsNotEmpty(suppressionKey)) {
		NSButton *button = [alert suppressionButton];

		[_NSUserDefaults() setBool:[button state] forKey:suppressionKey];
	}

	if ([targetClass isKindOfClass:[self class]]) {
		return;
	}

	TLOPopupPromptReturnType returnValue = TLOPopupPromptReturnPrimaryType;

	if (returnCode == NSAlertSecondButtonReturn) {
		returnValue = TLOPopupPromptReturnSecondaryType;
	} else if (returnCode == NSAlertOtherReturn || returnCode == NSAlertThirdButtonReturn) {
		returnValue = TLOPopupPromptReturnOtherType;
	}

	objc_msgSend(targetClass, targetAction, returnValue);
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
	BOOL useSupression = NO;

	NSString *__suppressionKey = NSStringEmptyPlaceholder;

	if (NSObjectIsNotEmpty(suppressKey)) {
        __suppressionKey = [TXPopupPromptSuppressionPrefix stringByAppendingString:suppressKey];

		if ([suppressText isEqualToString:@"-"] == NO) {
			useSupression = YES;

			if ([_NSUserDefaults() boolForKey:__suppressionKey] == YES) {
				return;
			}
		}
	}

	if (useSupression) {
		if (NSObjectIsEmpty(suppressText)) {
			suppressText = TXTLS(@"PromptSuppressionButtonDefaultTitle");
		}
	} else {
		suppressText = nil;
	}

	NSAlert *alert = [NSAlert new];

	[alert setAlertStyle:NSInformationalAlertStyle];

	[alert setMessageText:titleText];
	[alert setInformativeText:bodyText];
	[alert addButtonWithTitle:buttonDefault];
	[alert addButtonWithTitle:buttonAlternate];
	[alert addButtonWithTitle:otherButton];
	[alert setShowsSuppressionButton:useSupression];

	[[alert suppressionButton] setTitle:suppressText];

	NSArray *context = @[__suppressionKey, targetClass,
	NSStringFromSelector(actionSelector)];

	[alert beginSheetModalForWindow:window modalDelegate:[self class]
					 didEndSelector:@selector(sheetWindowWithQuestionCallback:returnCode:contextInfo:)
						contextInfo:(void *)CFBridgingRetain(context)];
}

+ (void)popupPromptNilSelector:(TLOPopupPromptReturnType)returnCode
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
	BOOL useSupression = NO;

	NSString *__suppressKey = NSStringEmptyPlaceholder;

	if (NSObjectIsNotEmpty(suppressKey) && [suppressText isEqualToString:@"-"] == NO) {
        __suppressKey = [TXPopupPromptSuppressionPrefix stringByAppendingString:suppressKey];

		useSupression = YES;

		if ([_NSUserDefaults() boolForKey:__suppressKey] == YES) {
			return YES;
		}
	}

	NSAlert *alert = [NSAlert alertWithMessageText:titleText
									 defaultButton:buttonDefault
								   alternateButton:buttonAlternate
									   otherButton:nil
						 informativeTextWithFormat:bodyText];

	NSButton *button = [alert suppressionButton];

	[alert setShowsSuppressionButton:useSupression];

	if (useSupression) {
		if (NSObjectIsEmpty(suppressText)) {
			suppressText = TXTLS(@"PromptSuppressionButtonDefaultTitle");
		}

		[button setTitle:suppressText];
	}

	if ([alert runModal] == NSAlertDefaultReturn) {
		if (useSupression) {
			[_NSUserDefaults() setBool:[button state] forKey:__suppressKey];
		}

		return YES;
	} else {
		return NO;
	}
}

+ (NSString *)dialogWindowWithInput:(NSString *)bodyText
							  title:(NSString *)titleText
					  defaultButton:(NSString *)buttonDefault
					alternateButton:(NSString *)buttonAlternate
					   defaultInput:(NSString *)defaultValue
{
	TVCInputPromptDialog *dialog = [TVCInputPromptDialog new];

	[dialog alertWithMessageText:titleText
				   defaultButton:buttonDefault
				 alternateButton:buttonAlternate
				 informativeText:bodyText
				defaultUserInput:defaultValue];

	[dialog runModal];

	NSInteger button = [dialog buttonClicked];

	NSString *result = [dialog promptValue];

	if (NSObjectIsNotEmpty(result) && button == NSAlertDefaultReturn) {
		return result;
	}

	return nil;
}

@end