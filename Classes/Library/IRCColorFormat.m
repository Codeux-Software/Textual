// Modifications by Codeux Software <support AT codeux DOT com> <https://github.com/codeux/Textual>
// You can redistribute it and/or modify it under the new BSD license.

NSString *IRCTextFormatterBoldAttributeName             = @"IRCTextFormatterBold";
NSString *IRCTextFormatterItalicAttributeName           = @"IRCTextFormatterItalic";
NSString *IRCTextFormatterUnderlineAttributeName        = @"IRCTextFormatterUnderline";
NSString *IRCTextFormatterForegroundColorAttributeName  = @"IRCTextFormatterForegroundColor";
NSString *IRCTextFormatterBackgroundColorAttributeName  = @"IRCTextFormatterBackgroundColor";

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
		
		NSNumber *foregroundNumber = [dict objectForKey:IRCTextFormatterForegroundColorAttributeName];
		NSNumber *backgroundNumber = [dict objectForKey:IRCTextFormatterBackgroundColorAttributeName];
		
		NSInteger foregroundColor = ((foregroundNumber) ? [foregroundNumber integerValue] : -1);
		NSInteger backgroundColor = ((backgroundNumber) ? [backgroundNumber integerValue] : -1);
		
		BOOL color = (foregroundColor >= 0 && foregroundColor <= 15);
		
		BOOL boldText       = [dict boolForKey:IRCTextFormatterBoldAttributeName];
		BOOL italicText     = [dict boolForKey:IRCTextFormatterItalicAttributeName];
		BOOL underlineText  = [dict boolForKey:IRCTextFormatterUnderlineAttributeName];
		
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
				BOOL result = [dict boolForKey:IRCTextFormatterBoldAttributeName];
				
				if (result) {
					return YES;
				}
				
				break;
			}
			case IRCTextFormatterItalicEffect: 
			{
				BOOL result = [dict boolForKey:IRCTextFormatterItalicAttributeName];
				
				if (result) {
					return YES;
				}
				
				break;
			}
			case IRCTextFormatterUnderlineEffect:
			{
				BOOL result = [dict boolForKey:IRCTextFormatterUnderlineAttributeName];
				
				if (result) {
					return YES;
				}
				
				break;
			}
			case IRCTextFormatterForegroundColorEffect:
			{
				BOOL result = BOOLValueFromObject([dict objectForKey:NSForegroundColorAttributeName]);
				
				NSNumber *foregroundNumber = [dict objectForKey:IRCTextFormatterForegroundColorAttributeName];
				
				if (foregroundNumber && result) {
					NSInteger foregroundColor = [foregroundNumber integerValue];
					
					if (foregroundColor >= 0 && foregroundColor <= 15) {
						return YES;
					}
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
		
		if (backgroundColorD && hasForegroundColor) {
			NSInteger mappedColor = mapColorValue(backgroundColorD);
            
            if (mappedColor >= 0 && mappedColor <= 15) {
                [attrs setObject:backgroundColorD forKey:NSBackgroundColorAttributeName];
            }
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

- (NSAttributedString *)setIRCFormatterAttribute:(IRCTextFormatterEffectType)effect value:(id)value range:(NSRange)limitRange
{
	NSMutableAttributedString *result = [self mutableCopy];
	
	NSFont *baseFont = [self safeAttribute:NSFontAttributeName atIndex:limitRange.location effectiveRange:NULL];
	
	if (baseFont) {
		switch (effect) {
			case IRCTextFormatterBoldEffect:
			{
				if ([baseFont fontTraitSet:NSBoldFontMask] == NO) {
					baseFont = [_NSFontManager() convertFont:baseFont toHaveTrait:NSBoldFontMask];
				}
				
				if (baseFont) {
					[result addAttribute:NSFontAttributeName			   value:baseFont range:limitRange];
					[result addAttribute:IRCTextFormatterBoldAttributeName value:value	  range:limitRange];
				}
				
				break;
			}
			case IRCTextFormatterItalicEffect:
			{
				if ([baseFont fontTraitSet:NSItalicFontMask] == NO) {
					baseFont = [_NSFontManager() convertFont:baseFont toHaveTrait:NSItalicFontMask];
				}
				
				if (baseFont) {
					[result addAttribute:NSFontAttributeName				 value:baseFont range:limitRange];
					[result addAttribute:IRCTextFormatterItalicAttributeName value:value	range:limitRange];
				}
				
				break;
			}
			case IRCTextFormatterUnderlineEffect:
			{
				[result addAttribute:IRCTextFormatterUnderlineAttributeName value:value											  range:limitRange];
				[result addAttribute:NSUnderlineStyleAttributeName			value:[NSNumber numberWithInt:NSSingleUnderlineStyle] range:limitRange];
				
				break;
			}
			case IRCTextFormatterForegroundColorEffect:
			{
				NSInteger colorCode = [value integerValue];
				
				if (colorCode >= 0 && colorCode <= 15) {
					[result addAttribute:IRCTextFormatterForegroundColorAttributeName value:value					range:limitRange];
					[result addAttribute:NSForegroundColorAttributeName				  value:mapColorCode(colorCode) range:limitRange];
				}
				
				break;
			}
			case IRCTextFormatterBackgroundColorEffect:
			{
				NSNumber *foregroundColor = [self safeAttribute:IRCTextFormatterForegroundColorAttributeName atIndex:limitRange.location effectiveRange:NULL];
				
				if (foregroundColor) {
					NSInteger backColor  = [value           integerValue];
					NSInteger frontColor = [foregroundColor integerValue];
					
					if (backColor >= 0 && backColor <= 15 && frontColor >= 0 && frontColor <= 15) {
						[result addAttribute:IRCTextFormatterBackgroundColorAttributeName value:value					range:limitRange];
						[result addAttribute:NSBackgroundColorAttributeName				  value:mapColorCode(backColor) range:limitRange];
					}
				}
				
				break;
			}
		}
	}
	
	return [result autodrain];
}

- (NSAttributedString *)removeIRCFormatterAttribute:(IRCTextFormatterEffectType)effect range:(NSRange)limitRange color:(NSColor *)defaultColor
{
	NSMutableAttributedString *result = [self mutableCopy];
	
	NSRange effectiveRange;
	
	while (limitRange.length >= 1) {
		NSDictionary *dict = [self safeAttributesAtIndex:limitRange.location longestEffectiveRange:&effectiveRange inRange:limitRange];
		
		NSFont *baseFont = [dict objectForKey:NSFontAttributeName];
		
		if (baseFont) {
			switch (effect) {
				case IRCTextFormatterBoldEffect:
				{
					BOOL boldText = [dict boolForKey:IRCTextFormatterBoldAttributeName];
					
					if ([baseFont fontTraitSet:NSBoldFontMask]) {
						baseFont = [_NSFontManager() convertFont:baseFont toNotHaveTrait:NSBoldFontMask];
						
						if (baseFont) {
							[result addAttribute:NSFontAttributeName value:baseFont range:effectiveRange];
						}
					}
					
					if (boldText) {
						[result removeAttribute:IRCTextFormatterBoldAttributeName range:effectiveRange];
					}
					
					break;
				}
				case IRCTextFormatterItalicEffect:
				{
					BOOL italicText = [dict boolForKey:IRCTextFormatterItalicAttributeName];
					
					if ([baseFont fontTraitSet:NSItalicFontMask]) {
						baseFont = [_NSFontManager() convertFont:baseFont toNotHaveTrait:NSItalicFontMask];
						
						if (baseFont) {
							[result addAttribute:NSFontAttributeName value:baseFont range:effectiveRange];
						}
					}
					
					if (italicText) {
						[result removeAttribute:IRCTextFormatterItalicAttributeName range:effectiveRange];
					}
					
					break;
				}
				case IRCTextFormatterUnderlineEffect:
				{
					[result removeAttribute:NSUnderlineStyleAttributeName		   range:effectiveRange];
					[result removeAttribute:IRCTextFormatterUnderlineAttributeName range:effectiveRange];
					
					break;
				}
				case IRCTextFormatterForegroundColorEffect:
				{
					[result removeAttribute:NSForegroundColorAttributeName				 range:effectiveRange];
					[result removeAttribute:IRCTextFormatterForegroundColorAttributeName range:effectiveRange];
                    
                    [result addAttribute:NSForegroundColorAttributeName value:defaultColor range:effectiveRange];
					
					break;
				}
				case IRCTextFormatterBackgroundColorEffect:
				{
					[result removeAttribute:NSBackgroundColorAttributeName				 range:effectiveRange];
					[result removeAttribute:IRCTextFormatterBackgroundColorAttributeName range:effectiveRange];
					
					break;
				}
				default: break;
			}
		}
		
		limitRange = NSMakeRange(NSMaxRange(effectiveRange), 
                                 (NSMaxRange(limitRange) - NSMaxRange(effectiveRange)));
	}
	
	return [result autodrain];
}

@end