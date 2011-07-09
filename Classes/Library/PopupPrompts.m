// Created by Codeux Software <support AT codeux DOT com> <https://github.com/codeux/Textual>
// You can redistribute it and/or modify it under the new BSD license.

@implementation PopupPrompts

#pragma mark -
#pragma mark Alert Sheets

@synthesize _targetClass;
@synthesize _actionSelector;
@synthesize _suppressionKey;

- (void)dealloc
{
    [_suppressionKey drain];
    
    [super dealloc];
}

- (void)sheetWindowWithQuestion:(NSWindow *)window
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
	[alert setShowsSuppressionButton:useSupression];
	
	[[alert suppressionButton] setTitle:suppressText];
	
	_targetClass	= targetClass;
	_actionSelector = actionSelector;
	_suppressionKey = [__suppressionKey retain];
	
	[alert beginSheetModalForWindow:window modalDelegate:self
					 didEndSelector:@selector(_sheetWindowWithQuestionCallback:returnCode:contextInfo:) contextInfo:nil];
	
	[alert drain];
}

- (void)_sheetWindowWithQuestionCallback:(NSAlert *)alert returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo
{	
	if (NSObjectIsNotEmpty(_suppressionKey)) {
		NSButton *button = [alert suppressionButton];
		
		[_NSUserDefaults() setBool:[button state] forKey:_suppressionKey];
	}
	
	if ([_targetClass isKindOfClass:[self class]]) {
		return;
	}
	
	[_targetClass performSelector:_actionSelector withObject:[NSNumber numberWithInteger:returnCode]];
    
    [self drain];
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
	PopupPrompts *prompt = [PopupPrompts new];
	
	[prompt sheetWindowWithQuestion:window 
							 target:targetClass 
							 action:actionSelector 
							   body:bodyText 
							  title:titleText 
					  defaultButton:buttonDefault 
					alternateButton:buttonAlternate 
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
									   otherButton:nil
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
	
	[dialog drain];
	
	if (NSObjectIsNotEmpty(result) && button == NSAlertDefaultReturn) {
		return result;
	}
	
	return nil;
}

@end