// Modifications by Codeux Software <support AT codeux DOT com> <https://github.com/codeux/Textual>
// You can redistribute it and/or modify it under the new BSD license.

@implementation NSAttributedString (IRCTextFormatter)

#pragma mark -
#pragma mark General Calls

- (NSString *)attributedStringToASCIIFormatting
{
	NSString *realBody = [self string];
	
	NSMutableString *result = [NSMutableString string];
	
	NSRange effectiveRange;
	NSRange limitRange = NSMakeRange(0, [self length]);
	
	while (limitRange.length > 0) {
		NSDictionary *dict = [self safeAttributesAtIndex:limitRange.location longestEffectiveRange:&effectiveRange inRange:limitRange];
		
		NSInteger foregroundColor = mapColorValue([dict objectForKey:NSForegroundColorAttributeName]);
		NSInteger backgroundColor = mapColorValue([dict objectForKey:NSBackgroundColorAttributeName]);
        
        NSNumber *foregroundNumber = NSNumberWithInteger(foregroundColor);
        NSNumber *backgroundNumber = NSNumberWithInteger(backgroundColor);
		
		BOOL color = (foregroundColor >= 0 && foregroundColor <= 15);
        
        NSFont *baseFont = [dict objectForKey:NSFontAttributeName];
		
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

- (BOOL)IRCFormatterAttributeSetInRange:(IRCTextFormatterEffectType)effect range:(NSRange)limitRange
{
	NSRange effectiveRange;
	
	while (limitRange.length >= 1) {
		NSDictionary *dict = [self safeAttributesAtIndex:limitRange.location longestEffectiveRange:&effectiveRange inRange:limitRange];
		
		switch (effect) {
			case IRCTextFormatterBoldEffect: 
			{
                NSFont *baseFont = [dict objectForKey:NSFontAttributeName];
				
                return [baseFont fontTraitSet:NSBoldFontMask];
				
				break;
			}
			case IRCTextFormatterItalicEffect: 
			{
                NSFont *baseFont = [dict objectForKey:NSFontAttributeName];
				
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
				NSInteger foregroundColor = mapColorValue([dict objectForKey:NSForegroundColorAttributeName]);
				
                if (foregroundColor >= 0 && foregroundColor <= 15) {
                    return YES;
                }
				
				break;
			}
			case IRCTextFormatterBackgroundColorEffect:
			{
				BOOL result = BOOLValueFromObject([dict objectForKey:NSBackgroundColorAttributeName]);
				
				if (result) {
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

- (void)sanitizeIRCCompatibleAttributedString:(NSFont *)defaultFont 
                                        color:(NSColor *)defaultColor
                                       source:(TextField **)sourceField
                                        range:(NSRange)limitRange    
{
	NSRange effectiveRange;
    
    NSMutableDictionary *attrs = [NSMutableDictionary dictionary];
	
	limitRange = NSMakeRange(0, [self length]);
	
	while (limitRange.length >= 1) {
		NSDictionary *dict = [self safeAttributesAtIndex:limitRange.location longestEffectiveRange:&effectiveRange inRange:limitRange];
        
		/* Manage font settings */
		NSFont *baseFont = [dict objectForKey:NSFontAttributeName];
		
		BOOL boldText   = [baseFont fontTraitSet:NSBoldFontMask];
		BOOL italicText = [baseFont fontTraitSet:NSItalicFontMask];
		
		baseFont = defaultFont;
		
		if (baseFont) {
			if (boldText) {
				baseFont = [_NSFontManager() convertFont:baseFont toHaveTrait:NSBoldFontMask];
			}
			
			if (italicText) {
				baseFont = [_NSFontManager() convertFont:baseFont toHaveTrait:NSItalicFontMask];
			}
			
            [attrs setObject:baseFont forKey:NSFontAttributeName];
		}
        
		/* Process other attributes */
		NSColor *foregroundColorD = [dict objectForKey:NSForegroundColorAttributeName];
		NSColor *backgroundColorD = [dict objectForKey:NSBackgroundColorAttributeName];
		
		BOOL underlineText		  = ([dict integerForKey:NSUnderlineStyleAttributeName] == 1);
		BOOL hasForegroundColor   = NO;
		
		if (underlineText) {
            [attrs setObject:[NSNumber numberWithInt:NSSingleUnderlineStyle] forKey:NSUnderlineStyleAttributeName];
		}
		
		if (foregroundColorD) {
            NSInteger mappedColor = mapColorValue(foregroundColorD);
            
            if (mappedColor >= 0 && mappedColor <= 15) {
                hasForegroundColor = YES;
                
                [attrs setObject:foregroundColorD forKey:NSForegroundColorAttributeName];
            } else {
                [attrs setObject:defaultColor forKey:NSForegroundColorAttributeName];
            }
		} else {
            [attrs setObject:defaultColor forKey:NSForegroundColorAttributeName];
        }
		
		if (backgroundColorD) {
            if (hasForegroundColor) {
                NSInteger mappedColor = mapColorValue(backgroundColorD);
                
                if (mappedColor >= 0 && mappedColor <= 15) {
                    [attrs setObject:backgroundColorD forKey:NSBackgroundColorAttributeName];
                } else {
                    [attrs removeObjectForKey:NSBackgroundColorAttributeName];
                }
            } else {
                [attrs removeObjectForKey:NSBackgroundColorAttributeName];
            }
		} else {
            [attrs removeObjectForKey:NSBackgroundColorAttributeName];
        }
        
        if (NSObjectIsNotEmpty(attrs)) {
            [*sourceField setAttributes:attrs inRange:effectiveRange];
        }
		
		limitRange = NSMakeRange(NSMaxRange(effectiveRange), 
                                 (NSMaxRange(limitRange) - NSMaxRange(effectiveRange)));
	}
}

#pragma mark -
#pragma mark Adding/Removing Formatting

- (void)setIRCFormatterAttribute:(IRCTextFormatterEffectType)effect 
                           value:(id)value 
                           range:(NSRange)limitRange 
                          source:(TextField **)sourceField
{	
	NSRange effectiveRange;
	
	while (limitRange.length >= 1) {
		NSDictionary *dict = [self safeAttributesAtIndex:limitRange.location longestEffectiveRange:&effectiveRange inRange:limitRange];
		
		NSFont *baseFont = [dict objectForKey:NSFontAttributeName];
        
        NSMutableDictionary *newDict = [NSMutableDictionary dictionaryWithDictionary:dict];
        
        switch (effect) {
            case IRCTextFormatterBoldEffect:
            {
                if ([baseFont fontTraitSet:NSBoldFontMask] == NO) {
                    baseFont = [_NSFontManager() convertFont:baseFont toHaveTrait:NSBoldFontMask];
                }
                
                if (baseFont) {
                    [newDict setObject:baseFont forKey:NSFontAttributeName];
                }
                
                break;
            }
            case IRCTextFormatterItalicEffect:
            {
                if ([baseFont fontTraitSet:NSItalicFontMask] == NO) {
                    baseFont = [_NSFontManager() convertFont:baseFont toHaveTrait:NSItalicFontMask];
                }
                
                if (baseFont) {
                    [newDict setObject:baseFont forKey:NSFontAttributeName];
                }
                
                break;
            }
            case IRCTextFormatterUnderlineEffect:
            {
                [newDict setObject:[NSNumber numberWithInt:NSSingleUnderlineStyle] forKey:NSUnderlineStyleAttributeName];
                
                break;
            }
            case IRCTextFormatterForegroundColorEffect:
            {
                NSInteger colorCode = [value integerValue];
                
                if (colorCode >= 0 && colorCode <= 15) {
                    [newDict setObject:mapColorCode(colorCode) forKey:NSForegroundColorAttributeName];
                }
                
                break;
            }
            case IRCTextFormatterBackgroundColorEffect:
            {
                NSInteger colorCode = [value integerValue];
                
                if (colorCode >= 0 && colorCode <= 15) {
                    [newDict setObject:mapColorCode(colorCode) forKey:NSBackgroundColorAttributeName];
                }
                
                break;
            }
            default: break;
        }
        
        [*sourceField setAttributes:newDict inRange:effectiveRange];
		
		limitRange = NSMakeRange(NSMaxRange(effectiveRange), 
                                 (NSMaxRange(limitRange) - NSMaxRange(effectiveRange)));
    }
}

- (void)removeIRCFormatterAttribute:(IRCTextFormatterEffectType)effect 
                              range:(NSRange)limitRange 
                              color:(NSColor *)defaultColor
                             source:(TextField **)sourceField
{	
	NSRange effectiveRange;
	
	while (limitRange.length >= 1) {
		NSDictionary *dict = [self safeAttributesAtIndex:limitRange.location longestEffectiveRange:&effectiveRange inRange:limitRange];
		
		NSFont *baseFont = [dict objectForKey:NSFontAttributeName];
        
        NSMutableDictionary *newDict = [NSMutableDictionary dictionaryWithDictionary:dict];
		
		if (baseFont) {
			switch (effect) {
				case IRCTextFormatterBoldEffect:
				{
					if ([baseFont fontTraitSet:NSBoldFontMask]) {
						baseFont = [_NSFontManager() convertFont:baseFont toNotHaveTrait:NSBoldFontMask];
						
						if (baseFont) {
							[newDict setObject:baseFont forKey:NSFontAttributeName];
                            
                            [*sourceField setAttributes:newDict inRange:effectiveRange];
						}
					}
					
					break;
				}
				case IRCTextFormatterItalicEffect:
				{
					if ([baseFont fontTraitSet:NSItalicFontMask]) {
						baseFont = [_NSFontManager() convertFont:baseFont toNotHaveTrait:NSItalicFontMask];
						
						if (baseFont) {
							[newDict setObject:baseFont forKey:NSFontAttributeName];
                            
                            [*sourceField setAttributes:newDict inRange:effectiveRange];
						}
					}
					
					break;
				}
				case IRCTextFormatterUnderlineEffect:
				{
                    [*sourceField removeAttribute:NSUnderlineStyleAttributeName inRange:effectiveRange];
					
					break;
				}
				case IRCTextFormatterForegroundColorEffect:
				{
                    [newDict setObject:defaultColor forKey:NSForegroundColorAttributeName];
                    
                    [*sourceField setAttributes:newDict inRange:effectiveRange];
                    [*sourceField removeAttribute:NSBackgroundColorAttributeName inRange:effectiveRange];
					
					break;
				}
				case IRCTextFormatterBackgroundColorEffect:
				{
                    [*sourceField removeAttribute:NSBackgroundColorAttributeName inRange:effectiveRange];
					
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