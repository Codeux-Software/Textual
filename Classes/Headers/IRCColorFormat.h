// Modifications by Codeux Software <support AT codeux DOT com> <https://github.com/codeux/Textual>
// You can redistribute it and/or modify it under the new BSD license.

typedef enum {
	IRCTextFormatterBoldEffect,
	IRCTextFormatterItalicEffect,
	IRCTextFormatterUnderlineEffect,
	IRCTextFormatterForegroundColorEffect,
	IRCTextFormatterBackgroundColorEffect,
} IRCTextFormatterEffectType; 

@interface NSAttributedString (IRCTextFormatter)
- (NSString *)attributedStringToASCIIFormatting;
- (NSString *)attributedStringToASCIIFormatting:(NSMutableAttributedString **)string 
                                       lineType:(LogLineType)type 
                                        channel:(NSString *)chan 
                                       hostmask:(NSString *)host;

- (void)sanitizeIRCCompatibleAttributedString:(NSFont *)defaultFont 
                                        color:(NSColor *)defaultColor
                                       source:(TextField **)sourceField
                                        range:(NSRange)limitRange;    

- (BOOL)IRCFormatterAttributeSetInRange:(IRCTextFormatterEffectType)effect range:(NSRange)limitRange;

- (void)setIRCFormatterAttribute:(IRCTextFormatterEffectType)effect 
                           value:(id)value 
                           range:(NSRange)limitRange 
                          source:(TextField **)sourceField;

- (void)removeIRCFormatterAttribute:(IRCTextFormatterEffectType)effect 
                              range:(NSRange)limitRange 
                              color:(NSColor *)defaultColor
                             source:(TextField **)sourceField;
@end