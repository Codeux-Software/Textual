// Modifications by Codeux Software <support AT codeux DOT com> <https://github.com/codeux/Textual>
// You can redistribute it and/or modify it under the new BSD license.
// Converted to ARC Support on June 08, 2012

#import "TextualApplication.h"

@implementation NSAttributedString (IRCTextFormatter)

#pragma mark -
#pragma mark Text Truncation

- (NSString *)attributedStringToASCIIFormatting
{
	NSString *realBody = [self string];
	
	NSMutableString *result = [NSMutableString string];
	
	NSRange effectiveRange;
	NSRange limitRange = NSMakeRange(0, [self length]);
	
	while (limitRange.length > 0) {
		NSDictionary *dict = [self safeAttributesAtIndex:limitRange.location longestEffectiveRange:&effectiveRange inRange:limitRange];
		
		NSInteger foregroundColor = mapColorValue(dict[NSForegroundColorAttributeName]);
		NSInteger backgroundColor = mapColorValue(dict[NSBackgroundColorAttributeName]);
        
        NSNumber *foregroundNumber = @(foregroundColor);
        NSNumber *backgroundNumber = @(backgroundColor);
		
		BOOL color = (foregroundColor >= 0 && foregroundColor <= 15);
        
        NSFont *baseFont = dict[NSFontAttributeName];
		
		BOOL boldText       = [baseFont fontTraitSet:NSBoldFontMask];
		BOOL italicText     = [baseFont fontTraitSet:NSItalicFontMask];
		BOOL underlineText  = ([dict integerForKey:NSUnderlineStyleAttributeName] == 1);
		
		if (underlineText)  [result appendFormat:@"%c", 0x1F];
		if (italicText)     [result appendFormat:@"%c", 0x16];
		if (boldText)       [result appendFormat:@"%c", 0x02];
		
		if (color) {
			[result appendFormat:@"%c%@", 0x03, [foregroundNumber integerWithLeadingZero]];
			
			if (backgroundColor >= 0 && backgroundColor <= 15) {
				[result appendFormat:@",%@", [backgroundNumber integerWithLeadingZero]];
			}
		}
		
		[result appendString:[realBody safeSubstringWithRange:effectiveRange]];
		
		if (color)          [result appendFormat:@"%c", 0x03];
		if (boldText)       [result appendFormat:@"%c", 0x02];
		if (italicText)     [result appendFormat:@"%c", 0x16];
		if (underlineText)  [result appendFormat:@"%c", 0x1F];
		
		limitRange = NSMakeRange(NSMaxRange(effectiveRange), 
								 (NSMaxRange(limitRange) - NSMaxRange(effectiveRange)));
	}		
	
	return result;
}

#warning FIX: "-attributedStringToASCIIFormatting:lineType:channel:hostmask:" is dangerous \
			to call. Its results cannot be guaranteed and are generally inaccurate.

/* TODO: Fix text truncation while also supporting formatting. */

- (NSString *)attributedStringToASCIIFormatting:(NSMutableAttributedString **)string 
                                       lineType:(TVCLogLineType)type 
                                        channel:(NSString *)chan 
                                       hostmask:(NSString *)host
{
    /* Do not look for logic in the following code because you will hurt your brain.
     This method was thrown together in one night and is very hacked. Miracle it works. */
    
    NSMutableAttributedString *base = [*string copy];
	
	NSMutableString *result = [NSMutableString string];
    
    NSInteger newChars   = 0;
    NSInteger baseMath   = (chan.length + host.length + 14); 
	NSInteger baseLength = (base.length + baseMath);
    
    if (baseLength > TXMaximumIRCBodyLength) {
        baseLength -= (baseLength - TXMaximumIRCBodyLength);
    }
    
    NSRange deleteRange;
	NSRange effectiveRange;
	NSRange limitRange = NSMakeRange(0, (baseLength - baseMath));
    
    deleteRange.location = 0;
    deleteRange.length   = limitRange.length;
    
    BOOL needBreak = NO;
	
	while (limitRange.length > 0) {
		NSDictionary *dict = [base safeAttributesAtIndex:limitRange.location longestEffectiveRange:&effectiveRange inRange:limitRange];
        
		NSInteger foregroundColor = mapColorValue(dict[NSForegroundColorAttributeName]);
		NSInteger backgroundColor = mapColorValue(dict[NSBackgroundColorAttributeName]);
        
        NSNumber *foregroundNumber = @(foregroundColor);
        NSNumber *backgroundNumber = @(backgroundColor);
        
        NSFont *baseFont = dict[NSFontAttributeName];
		
		BOOL foregroundColorD = (foregroundColor >= 0 && foregroundColor <= 15);
        BOOL backgroundColorD = (backgroundColor >= 0 && backgroundColor <= 15);
		
		BOOL boldText       = [baseFont fontTraitSet:NSBoldFontMask];
		BOOL italicText     = [baseFont fontTraitSet:NSItalicFontMask];
		BOOL underlineText  = ([dict integerForKey:NSUnderlineStyleAttributeName] == 1);
		
        if (italicText)         newChars += 2;
        if (underlineText)      newChars += 2;
        if (underlineText)      newChars += 2;
        if (foregroundColorD)   newChars += 3;
        if (backgroundColorD)   newChars += 3;
        
        NSInteger newLength = (baseMath + result.length + newChars);
        
        NSString *cake = NSStringEmptyPlaceholder; // variable names make no sense
        
        if (newLength > TXMaximumIRCBodyLength) {
            if (effectiveRange.length < newChars) {
                deleteRange.length = effectiveRange.location;
                
                break;
            } else {
                effectiveRange.length  -= newChars;
                deleteRange.length      = (effectiveRange.location + effectiveRange.length);
            }
        }
        
        if (effectiveRange.length == (TXMaximumIRCBodyLength - baseMath)) { // max
            cake = [base.string safeSubstringWithRange:effectiveRange];
            
            if ([cake contains:NSStringWhitespacePlaceholder]) {
                NSInteger spaceIndex = [cake rangeOfString:NSStringWhitespacePlaceholder options:NSBackwardsSearch range:effectiveRange].location; 
                NSInteger charDiff   = (effectiveRange.length - spaceIndex);
                
                if (charDiff <= 100) {
                    effectiveRange.length -= charDiff;
                    deleteRange.length    -= charDiff;
                    
                    cake = [base.string safeSubstringWithRange:effectiveRange];
                    
                    needBreak = YES;
                }
            }
        } else {
            cake = [base.string safeSubstringWithRange:effectiveRange];
        }
        
		if (underlineText)  [result appendFormat:@"%c", 0x1F];
		if (italicText)     [result appendFormat:@"%c", 0x16];
		if (boldText)       [result appendFormat:@"%c", 0x02];
		
		if (foregroundColorD) {
			[result appendFormat:@"%c%@", 0x03, [foregroundNumber integerWithLeadingZero]];
			
			if (backgroundColorD) {
				[result appendFormat:@",%@", [backgroundNumber integerWithLeadingZero]];
			}
		}
		
		[result appendString:cake];
		
		if (foregroundColorD)       [result appendFormat:@"%c", 0x03];
		if (boldText)               [result appendFormat:@"%c", 0x02];
		if (italicText)             [result appendFormat:@"%c", 0x16];
		if (underlineText)          [result appendFormat:@"%c", 0x1F];
        if (needBreak)              break;
		
		limitRange = NSMakeRange(NSMaxRange(effectiveRange), 
                                 (NSMaxRange(limitRange) - NSMaxRange(effectiveRange)));
	}		
    
    [*string deleteCharactersInRange:deleteRange];
    
    return result;
}

@end

#pragma mark -
#pragma mark General Formatting Calls

@implementation TVCTextField (TextFieldFormattingHelper)

- (BOOL)IRCFormatterAttributeSetInRange:(IRCTextFormatterEffectType)effect 
                                  range:(NSRange)limitRange 
{
    NSAttributedString *valued = self.attributedString;
    
	NSRange effectiveRange;
	
	while (limitRange.length >= 1) {
		NSDictionary *dict = [valued safeAttributesAtIndex:limitRange.location longestEffectiveRange:&effectiveRange inRange:limitRange];
		
		switch (effect) {
			case IRCTextFormatterBoldEffect: 
			{
                NSFont *baseFont = dict[NSFontAttributeName];
				
                return [baseFont fontTraitSet:NSBoldFontMask];
				
				break;
			}
			case IRCTextFormatterItalicEffect: 
			{
                NSFont *baseFont = dict[NSFontAttributeName];
				
                return [baseFont fontTraitSet:NSItalicFontMask];
				
				break;
			}
			case IRCTextFormatterUnderlineEffect:
			{
				BOOL result = ([dict integerForKey:NSUnderlineStyleAttributeName] == 1);
				
				if (result) {
					return YES;
				}
				
				break;
			}
			case IRCTextFormatterForegroundColorEffect:
			{
				NSColor *foregroundColor = dict[NSForegroundColorAttributeName];
				
                if (PointerIsNotEmpty(foregroundColor)) {
					NSColor *defaultColor = TXDefaultTextFieldFontColor;
					NSColor *compareColor = [foregroundColor colorUsingColorSpace:[NSColorSpace genericGrayColorSpace]];

					CGFloat defaultWhite = [defaultColor whiteComponent];
					CGFloat compareWhite = [compareColor whiteComponent];
					
					if (TXDirtyCGFloatsMatch(defaultWhite, compareWhite)) {
						return NO;
					}

                    return YES;
                }
				
				break;
			}
			case IRCTextFormatterBackgroundColorEffect:
			{
				NSColor *backgroundColor = dict[NSBackgroundColorAttributeName];
				
				if (PointerIsNotEmpty(backgroundColor)) {
					return YES;
				}
				
				break;
			} 
            default: return NO; break;
		}
		
		limitRange = NSMakeRange(NSMaxRange(effectiveRange), 
								 (NSMaxRange(limitRange) - NSMaxRange(effectiveRange)));
	}
	
	return NO;
}

#pragma mark -
#pragma mark Pasted String Sanitization

- (void)sanitizeIRCCompatibleAttributedString:(BOOL)clearAttributes
{
	if (clearAttributes) {
		NSAttributedString *stringv = [NSAttributedString alloc];
		NSAttributedString *stringn = [NSAttributedString emptyString];
		
		NSMutableDictionary *attrs = [NSMutableDictionary dictionary];
		
		attrs[NSFontAttributeName] = TXDefaultTextFieldFont;
		attrs[NSForegroundColorAttributeName] = TXDefaultTextFieldFontColor;

		(void)[stringv initWithString:TXTLS(@"InputTextFieldPlaceholderValue") attributes:attrs];

		[self setAttributedStringValue:stringv];
		[self setAttributedStringValue:stringn];
	} else {
		[self setFont:TXDefaultTextFieldFont];
	}
}

#pragma mark -
#pragma mark Adding/Removing Formatting

- (void)setIRCFormatterAttribute:(IRCTextFormatterEffectType)effect 
                           value:(id)value 
                           range:(NSRange)limitRange
{	
    NSAttributedString *valued = self.attributedString;
    
	NSRange effectiveRange;
	
	while (limitRange.length >= 1) {
		NSDictionary *dict = [valued safeAttributesAtIndex:limitRange.location longestEffectiveRange:&effectiveRange inRange:limitRange];
		
		NSFont *baseFont = dict[NSFontAttributeName];
        
        NSMutableDictionary *newDict = [NSMutableDictionary dictionaryWithDictionary:dict];
        
        switch (effect) {
            case IRCTextFormatterBoldEffect:
            {
                if ([baseFont fontTraitSet:NSBoldFontMask] == NO) {
                    baseFont = [_NSFontManager() convertFont:baseFont toHaveTrait:NSBoldFontMask];
                }
                
                if (baseFont) {
                    newDict[NSFontAttributeName] = baseFont;
                }
                
                break;
            }
            case IRCTextFormatterItalicEffect:
            {
                if ([baseFont fontTraitSet:NSItalicFontMask] == NO) {
                    baseFont = [_NSFontManager() convertFont:baseFont toHaveTrait:NSItalicFontMask];
                }
                
                if (baseFont) {
                    newDict[NSFontAttributeName] = baseFont;
                }
                
                break;
            }
            case IRCTextFormatterUnderlineEffect:
            {
                newDict[NSUnderlineStyleAttributeName] = @(NSSingleUnderlineStyle);
                
                break;
            }
            case IRCTextFormatterForegroundColorEffect:
            {
                NSInteger colorCode = [value integerValue];
                
                if (colorCode >= 0 && colorCode <= 15) {
                    newDict[NSForegroundColorAttributeName] = mapColorCode(colorCode);
                }
                
                break;
            }
            case IRCTextFormatterBackgroundColorEffect:
            {
                NSInteger colorCode = [value integerValue];
                
                if (colorCode >= 0 && colorCode <= 15) {
                    newDict[NSBackgroundColorAttributeName] = mapColorCode(colorCode);
                }
                
                break;
            }
            default: break;
        }
        
        [self setAttributes:newDict inRange:effectiveRange];
		
		limitRange = NSMakeRange(NSMaxRange(effectiveRange), 
                                 (NSMaxRange(limitRange) - NSMaxRange(effectiveRange)));
    }
}

- (void)removeIRCFormatterAttribute:(IRCTextFormatterEffectType)effect 
                              range:(NSRange)limitRange 
                              color:(NSColor *)defaultColor
{	
    NSAttributedString *valued = self.attributedString;
    
	NSRange effectiveRange;
	
	while (limitRange.length >= 1) {
		NSDictionary *dict = [valued safeAttributesAtIndex:limitRange.location longestEffectiveRange:&effectiveRange inRange:limitRange];
		
		NSFont *baseFont = dict[NSFontAttributeName];
        
        NSMutableDictionary *newDict = [NSMutableDictionary dictionaryWithDictionary:dict];
		
		if (baseFont) {
			switch (effect) {
				case IRCTextFormatterBoldEffect:
				{
					if ([baseFont fontTraitSet:NSBoldFontMask]) {
						baseFont = [_NSFontManager() convertFont:baseFont toNotHaveTrait:NSBoldFontMask];
						
						if (baseFont) {
							newDict[NSFontAttributeName] = baseFont;
                            
                            [self setAttributes:newDict inRange:effectiveRange];
						}
					}
					
					break;
				}
				case IRCTextFormatterItalicEffect:
				{
					if ([baseFont fontTraitSet:NSItalicFontMask]) {
						baseFont = [_NSFontManager() convertFont:baseFont toNotHaveTrait:NSItalicFontMask];
						
						if (baseFont) {
							newDict[NSFontAttributeName] = baseFont;
                            
                            [self setAttributes:newDict inRange:effectiveRange];
						}
					}
					
					break;
				}
				case IRCTextFormatterUnderlineEffect:
				{
                    [self removeAttribute:NSUnderlineStyleAttributeName inRange:effectiveRange];
					
					break;
				}
				case IRCTextFormatterForegroundColorEffect:
				{
                    newDict[NSForegroundColorAttributeName] = defaultColor;
                    
                    [self setAttributes:newDict inRange:effectiveRange];
                    [self removeAttribute:NSBackgroundColorAttributeName inRange:effectiveRange];
					
					break;
				}
				case IRCTextFormatterBackgroundColorEffect:
				{
                    [self removeAttribute:NSBackgroundColorAttributeName inRange:effectiveRange];
					
					break;
				}
				default: break;
			}
		}
		
		limitRange = NSMakeRange(NSMaxRange(effectiveRange), 
                                 (NSMaxRange(limitRange) - NSMaxRange(effectiveRange)));
	}
}

@end