// Modifications by Codeux Software <support AT codeux DOT com> <https://github.com/codeux/Textual>
// You can redistribute it and/or modify it under the new BSD license.
// Converted to ARC Support on June 08, 2012

#import "TVCTextField.h" // superclass

typedef enum IRCTextFormatterEffectType : NSInteger {
	IRCTextFormatterBoldEffect,
	IRCTextFormatterItalicEffect,
	IRCTextFormatterUnderlineEffect,
	IRCTextFormatterForegroundColorEffect,
	IRCTextFormatterBackgroundColorEffect,
} IRCTextFormatterEffectType; 

#define TXMaximumRainbowTextFormattingLength   300

@interface NSAttributedString (IRCTextFormatter)
- (NSString *)attributedStringToASCIIFormatting;
- (NSString *)attributedStringToASCIIFormatting:(NSMutableAttributedString **)string 
                                       lineType:(TVCLogLineType)type 
                                        channel:(NSString *)chan 
                                       hostmask:(NSString *)host;
@end

@interface TVCTextField (TextFieldFormattingHelper) 
- (void)sanitizeIRCCompatibleAttributedString:(BOOL)clearAttributes;

- (BOOL)IRCFormatterAttributeSetInRange:(IRCTextFormatterEffectType)effect 
                                  range:(NSRange)limitRange;

- (void)setIRCFormatterAttribute:(IRCTextFormatterEffectType)effect 
                           value:(id)value 
                           range:(NSRange)limitRange;

- (void)removeIRCFormatterAttribute:(IRCTextFormatterEffectType)effect 
                              range:(NSRange)limitRange 
                              color:(NSColor *)defaultColor;
@end