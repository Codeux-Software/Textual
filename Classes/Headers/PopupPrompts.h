// Created by Codeux Software <support AT codeux DOT com> <https://github.com/codeux/Textual>
// You can redistribute it and/or modify it under the new BSD license.
// Converted to ARC Support on Thursday, June 08, 2012

#define PopupPromptSuppressionPrefix	@"Preferences.prompts."

@interface PopupPrompts : NSObject 
@property (nonatomic, unsafe_unretained) id _targetClass;
@property (nonatomic, assign) id _suppressionKey;
@property (nonatomic, assign) SEL _actionSelector;

+ (void)popupPromptNULLSelector:(NSInteger)returnCode;

+ (BOOL)dialogWindowWithQuestion:(NSString *)bodyText 
						   title:(NSString *)titleText
				   defaultButton:(NSString *)buttonDefault
				 alternateButton:(NSString *)buttonAlternate
					 otherButton:(NSString *)otherButton
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
					otherButton:(NSString *)otherButton
				 suppressionKey:(NSString *)suppressKey
				suppressionText:(NSString *)suppressText;
@end