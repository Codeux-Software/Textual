// Created by Codeux Software <support AT codeux DOT com> <https://github.com/codeux/Textual>
// You can redistribute it and/or modify it under the new BSD license.

@implementation PopupPrompts

+ (BOOL)dialogWindowWithQuestion:(NSString *)bodyText 
						   title:(NSString *)titleText
				   defaultButton:(NSString *)buttonDefault
				 alternateButton:(NSString *)buttonAlternate
				  suppressionKey:(NSString *)suppressKey
				 suppressionText:(NSString *)suppressText
{
	BOOL useSupression = NO;
	
	if (NSObjectIsNotEmpty(suppressKey) && [suppressText isEqualToString:@"-"] == NO) {
		useSupression = YES;
		
		if ([_NSUserDefaults() boolForKey:suppressKey] == YES) {
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
		[button setTitle:((suppressText) ?: TXTLS(@"SUPPRESSION_BUTTON_DEFAULT_TITLE"))];
	}
	
	if ([alert runModal] == NSAlertDefaultReturn) {
		if (useSupression) {
			[_NSUserDefaults() setBool:[button state] forKey:suppressKey];
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
	InputPromptDialog *dialog = [InputPromptDialog new];
	
	[dialog alertWithMessageText:titleText
				   defaultButton:buttonDefault 
				 alternateButton:buttonAlternate
				 informativeText:bodyText
				defaultUserInput:defaultValue];
	
	[dialog runModal];
	
	NSInteger button = [dialog buttonClicked];
	NSString *result = [dialog promptValue];
	
	[dialog drain];
	
	if (NSObjectIsNotEmpty(result) && button == NSAlertDefaultReturn) {
		return result;
	}
	
	return nil;
}

+ (void)sheetWindowWithQuestion:(NSWindow *)window
						 target:(id)targetClass
						 action:(SEL)actionSelector
						   body:(NSString *)bodyText 
						  title:(NSString *)titleText
				  defaultButton:(NSString *)buttonDefault
				alternateButton:(NSString *)buttonAlternate
				 suppressionKey:(NSString *)suppressKey
				suppressionText:(NSString *)suppressText
{
	BOOL useSupression = NO;
	
	if (NSObjectIsNotEmpty(suppressKey)) {
		useSupression = YES;
		
		if ([_NSUserDefaults() boolForKey:suppressKey] == YES && [suppressText isEqualToString:@"-"] == NO) {
			return;
		}
	}
	
	NSAlert *alert = [NSAlert new];
	
	[alert setAlertStyle:NSInformationalAlertStyle];
	
	[alert setMessageText:titleText];
	[alert setInformativeText:bodyText];
	[alert addButtonWithTitle:buttonDefault];
	[alert addButtonWithTitle:buttonAlternate];
	[alert setShowsSuppressionButton:useSupression];
	
	[[alert suppressionButton] setTitle:((suppressText) ?: TXTLS(@"SUPPRESSION_BUTTON_DEFAULT_TITLE"))];
	
	[alert beginSheetModalForWindow:window modalDelegate:targetClass 
					 didEndSelector:actionSelector contextInfo:nil];
	
	[alert drain];
}

@end