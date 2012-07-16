// Created by Codeux Software <support AT codeux DOT com> <https://github.com/codeux/Textual>
// You can redistribute it and/or modify it under the new BSD license.

#import "TextualApplication.h"

#define TXPopupPromptSuppressionPrefix		@"Text Input Prompt Suppression -> "

typedef enum TLOPopupPromptReturnType : NSInteger {
	TLOPopupPromptReturnPrimaryType,
	TLOPopupPromptReturnSecondaryType,
	TLOPopupPromptReturnOtherType,
} TLOPopupPromptReturnType;

@interface TLOPopupPrompts : NSObject
+ (void)popupPromptNilSelector:(TLOPopupPromptReturnType)returnCode;

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

- (void)sheetWindowWithQuestion:(NSWindow *)window
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