// Modifications by Codeux Software <support AT codeux DOT com> <https://github.com/codeux/Textual>
// You can redistribute it and/or modify it under the new BSD license.

#import <Foundation/NSAttributedString.h>

TEXTUAL_EXTERN NSString *IRCTextFormatterBoldAttributeName;
TEXTUAL_EXTERN NSString *IRCTextFormatterItalicAttributeName;
TEXTUAL_EXTERN NSString *IRCTextFormatterUnderlineAttributeName;
TEXTUAL_EXTERN NSString *IRCTextFormatterForegroundColorAttributeName;
TEXTUAL_EXTERN NSString *IRCTextFormatterBackgroundColorAttributeName;

typedef enum {
	IRCTextFormatterBoldEffect,
	IRCTextFormatterItalicEffect,
	IRCTextFormatterUnderlineEffect,
	IRCTextFormatterForegroundColorEffect,
	IRCTextFormatterBackgroundColorEffect,
} IRCTextFormatterEffectType; 

@interface NSAttributedString (IRCTextFormatter)
- (NSString *)attributedStringToASCIIFormatting;

- (void)sanitizeIRCCompatibleAttributedString:(NSFont *)defaultFont 
                                        color:(NSColor *)defaultColor
                                       source:(TextField **)sourceField
                                        range:(NSRange)limitRange;    

- (BOOL)IRCFormatterAttributeSetInRange:(IRCTextFormatterEffectType)effect range:(NSRange)limitRange;

- (NSAttributedString *)setIRCFormatterAttribute:(IRCTextFormatterEffectType)effect value:(id)value range:(NSRange)limitRange;
- (NSAttributedString *)removeIRCFormatterAttribute:(IRCTextFormatterEffectType)effect range:(NSRange)limitRange color:(NSColor *)defaultColor;
@end