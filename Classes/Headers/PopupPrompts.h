// Created by Codeux Software <support AT codeux DOT com> <https://github.com/codeux/Textual>
// You can redistribute it and/or modify it under the new BSD license.

#define PopupPromptSuppressionPrefix	@"Preferences.prompts."

@interface PopupPrompts : NSObject 
{
	id  _targetClass;
	id  _suppressionKey;
	SEL _actionSelector;
}

@property (nonatomic, readonly) id _targetClass;
@property (nonatomic, readonly) id _suppressionKey;
@property (nonatomic, readonly) SEL _actionSelector;

+ (void)popupPromptNULLSelector:(NSInteger)returnCode;

+ (BOOL)dialogWindowWithQuestion:(NSString *)bodyText 
						   title:(NSString *)titleText
				   defaultButton:(NSString *)buttonDefault
				 alternateButton:(NSString *)buttonAlternate
				  suppressionKey:(NSString *)suppressKey
				 suppressionText:(NSString *)suppressText;

+ (NSString *)dialogWindowWithInput:(NSString *)bodyText 
							  title:(NSString *)titleText
					  defaultButton:(NSString *)buttonDefault
					alternateButton:(NSString *)buttonAlternate
					   defaultInput:(NSString *)defaultValue;

+ (void)sheetWindowWithQuestion:(NSWindow *)window
						 target:(id)targetClass
						 action:(SEL)actionSelector
						   body:(NSString *)bodyText 
						  title:(NSString *)titleText
				  defaultButton:(NSString *)buttonDefault
				alternateButton:(NSString *)buttonAlternate
				 suppressionKey:(NSString *)suppressKey
				suppressionText:(NSString *)suppressText;

@end