// Created by Codeux Software <support AT codeux DOT com> <https://github.com/codeux/Textual>
// You can redistribute it and/or modify it under the new BSD license.

@interface PopupPrompts : NSObject 

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
						 target:(Class)targetClass
						 action:(SEL)actionSelector
						   body:(NSString *)bodyText 
						  title:(NSString *)titleText
				  defaultButton:(NSString *)buttonDefault
				alternateButton:(NSString *)buttonAlternate
				 suppressionKey:(NSString *)suppressKey
				suppressionText:(NSString *)suppressText;

@end