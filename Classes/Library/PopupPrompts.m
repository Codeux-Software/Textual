// Created by Codeux Software <support AT codeux DOT com> <https://github.com/codeux/Textual>
// You can redistribute it and/or modify it under the new BSD license.
// Converted to ARC Support on Thursday, June 08, 2012

@implementation PopupPrompts

#pragma mark -
#pragma mark Alert Sheets

@synthesize _targetClass;
@synthesize _actionSelector;
@synthesize _suppressionKey;

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
	
	NSString *__suppressionKey = @"";
	
	if (NSObjectIsNotEmpty(suppressKey)) {
        __suppressionKey = [PopupPromptSuppressionPrefix stringByAppendingString:suppressKey];
        
		useSupression = YES;
		
		if ([_NSUserDefaults() boolForKey:__suppressionKey] == YES && [suppressText isEqualToString:@"-"] == NO) {
			return;
		}
	}
	
	if (useSupression) {
		if (NSObjectIsEmpty(suppressText)) {
			suppressText = TXTLS(@"SUPPRESSION_BUTTON_DEFAULT_TITLE");
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
	
	self._targetClass	= targetClass;
	self._actionSelector = actionSelector;
	self._suppressionKey = __suppressionKey;
	
	[alert beginSheetModalForWindow:window modalDelegate:self
					 didEndSelector:@selector(_sheetWindowWithQuestionCallback:returnCode:contextInfo:)
						contextInfo:nil];
	
}

- (void)_sheetWindowWithQuestionCallback:(NSAlert *)alert returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo
{	
	if (NSObjectIsNotEmpty(self._suppressionKey)) {
		NSButton *button = [alert suppressionButton];
		
		[_NSUserDefaults() setBool:[button state] forKey:self._suppressionKey];
	}
	
	if ([self._targetClass isKindOfClass:[self class]]) {
		return;
	}
	
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
	[self._targetClass performSelector:self._actionSelector
							withObject:[NSNumber numberWithInteger:returnCode]];
#pragma clang diagnostic pop
    
}

+ (void)sheetWindowWithQuestion:(NSWindow *)window
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
	PopupPrompts *prompt = [PopupPrompts new];
	
	[prompt sheetWindowWithQuestion:window 
							 target:targetClass 
							 action:actionSelector 
							   body:bodyText 
							  title:titleText 
					  defaultButton:buttonDefault 
					alternateButton:buttonAlternate
						otherButton:otherButton
					 suppressionKey:suppressKey 
					suppressionText:suppressText];
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
	
	NSString *_suppressKey = @"";
	
	if (NSObjectIsNotEmpty(suppressKey) && [suppressText isEqualToString:@"-"] == NO) {
        _suppressKey = [PopupPromptSuppressionPrefix stringByAppendingString:suppressKey];
        
		useSupression = YES;
		
		if ([_NSUserDefaults() boolForKey:_suppressKey] == YES) {
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
			suppressText = TXTLS(@"SUPPRESSION_BUTTON_DEFAULT_TITLE");
		}
		
		[button setTitle:suppressText];
	}
	
	if ([alert runModal] == NSAlertDefaultReturn) {
		if (useSupression) {
			[_NSUserDefaults() setBool:[button state] forKey:_suppressKey];
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
	
	if (NSObjectIsNotEmpty(result) && button == NSAlertDefaultReturn) {
		return result;
	}
	
	return nil;
}

@end