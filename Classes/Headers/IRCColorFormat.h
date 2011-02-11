// Modifications by Codeux Software <support AT codeux DOT com> <https://github.com/codeux/Textual>
// You can redistribute it and/or modify it under the new BSD license.

#import <Foundation/NSAttributedString.h>

extern NSString *IRCTextFormatterBoldAttributeName;
extern NSString *IRCTextFormatterItalicAttributeName;
extern NSString *IRCTextFormatterUnderlineAttributeName;
extern NSString *IRCTextFormatterForegroundColorAttributeName;
extern NSString *IRCTextFormatterBackgroundColorAttributeName;
extern NSString *IRCTextFormatterDefaultFontColorAttributeName;

typedef enum {
	IRCTextFormatterBoldEffect,
	IRCTextFormatterItalicEffect,
	IRCTextFormatterUnderlineEffect,
	IRCTextFormatterForegroundColorEffect,
	IRCTextFormatterBackgroundColorEffect,
	IRCTextFormatterDefaultFontColorEffect,
} IRCTextFormatterEffectType; 

@interface NSAttributedString (IRCTextFormatter)
- (NSString *)attributedStringToASCIIFormatting;

- (NSArray *)stringSanitizationValidAttributesMatrix;

- (NSAttributedString *)sanitizeNSLinkedAttributedString:(NSColor *)defaultColor;
- (NSAttributedString *)sanitizeIRCCompatibleAttributedString:(NSColor *)defaultColor 
													 oldColor:(NSColor *)auxiliaryColor 
											  backgroundColor:(NSColor *)backgroundColor
												  defaultFont:(NSFont *)defaultFont;

- (BOOL)IRCFormatterAttributeSetInRange:(IRCTextFormatterEffectType)effect range:(NSRange)limitRange;

- (NSAttributedString *)removeIRCFormatterAttribute:(IRCTextFormatterEffectType)effect range:(NSRange)limitRange;
- (NSAttributedString *)setIRCFormatterAttribute:(IRCTextFormatterEffectType)effect value:(id)value range:(NSRange)limitRange;
@end