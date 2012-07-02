// Created by Codeux Software <support AT codeux DOT com> <https://github.com/codeux/Textual>
// You can redistribute it and/or modify it under the new BSD license.

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
	
	objc_msgSend(targetClass, targetAction, @(returnCode));
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
        
		useSupression = YES;
		
		if ([_NSUserDefaults() boolForKey:__suppressionKey] == YES && [suppressText isEqualToString:@"-"] == NO) {
			return;
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

+ (void)popupPromptNULLSelector:(NSInteger)returnCode
{
	return;
}

#pragma mark -
#pragma mark Alert Dialogs

+ (BOOL)dialogWindowWithQuestion:(NSString *)bodyText 
						   title:(NSString *)titleText
				   defaultButton:(NSString *)buttonDefault
				 alternateButton:(NSString *)buttonAlternate
					 otherButton:(NSString *)otherButton
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
									   otherButton:otherButton
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