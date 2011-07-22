// Modifications by Codeux Software <support AT codeux DOT com> <https://github.com/codeux/Textual>
// You can redistribute it and/or modify it under the new BSD license.

@implementation IRCTextFormatterMenu

@synthesize textField;
@synthesize formatterMenu;
@synthesize foregroundColorMenu;
@synthesize backgroundColorMenu;
@synthesize sheetOverrideEnabled;

#define FormattingMenuForegroundColorEnabledTag		95005
#define FormattingMenuBackgroundColorEnabledTag		95007
#define FormattingMenuForegroundColorDisabledTag	95004
#define FormattingMenuBackgroundColorDisabledTag	95006
#define FormattingMenuRainbowColorMenuItemTag		99

#pragma mark -
#pragma mark Menu Management

- (void)enableSheetField:(TextField *)field
{
	sheetOverrideEnabled = YES;
	textField			 = field;
}

- (void)enableWindowField:(TextField *)field
{
	sheetOverrideEnabled = NO;
	textField			 = field;
}

- (BOOL)validateMenuItem:(NSMenuItem *)item
{
	if ([[textField window] hasAttachedSheet] && sheetOverrideEnabled == NO) {
		return NO;
	}
	
	switch ([item tag]) {
		case 95001: 
		{
			NSMenu *rootMenu = [item menu];
			
			BOOL boldText		 = [self boldSet];
			BOOL foregroundColor = [self foregroundColorSet];
			BOOL backgroundColor = [self backgroundColorSet];
			
			[[rootMenu itemWithTag:FormattingMenuForegroundColorEnabledTag]  setHidden:foregroundColor];
			[[rootMenu itemWithTag:FormattingMenuForegroundColorDisabledTag] setHidden:BOOLReverseValue(foregroundColor)];
			
			[[rootMenu itemWithTag:FormattingMenuBackgroundColorEnabledTag]  setHidden:backgroundColor];
			[[rootMenu itemWithTag:FormattingMenuBackgroundColorEnabledTag]  setEnabled:foregroundColor];
			[[rootMenu itemWithTag:FormattingMenuBackgroundColorDisabledTag] setHidden:BOOLReverseValue(backgroundColor)];
			
			[item setState:boldText];
			
			if (boldText) {
				[item setAction:@selector(removeBoldCharFromTextBox:)];
			} else {
				[item setAction:@selector(insertBoldCharIntoTextBox:)];
			}
			
			return YES;
			break;
		}
		case 95002:
		{
			BOOL italicText = [self italicSet];
			
			if (italicText) {
				[item setAction:@selector(removeItalicCharFromTextBox:)];
			} else {
				[item setAction:@selector(insertItalicCharIntoTextBox:)];
			}
			
			[item setState:italicText];
			
			return YES;
			break;
		}
		case 95003:
		{
			BOOL underlineText = [self underlineSet];
			
			if (underlineText) {
				[item setAction:@selector(removeUnderlineCharFromTextBox:)];
			} else {
				[item setAction:@selector(insertUnderlineCharIntoTextBox:)];
			}
			
			[item setState:underlineText];
			
			return YES;
			break;
		}
		case 100:
		{
			BOOL condition = [_NSUserDefaults() boolForKey:@"EnableRainbowFormattingMenuItem"];
			
			NSMenuItem *divider = [[item menu] itemWithTag:FormattingMenuRainbowColorMenuItemTag];
			
			[item	 setHidden:BOOLReverseValue(condition)];
			[divider setHidden:BOOLReverseValue(condition)];
			
			return condition;
		}
		default: break;
	}
	
	return YES;
}

#pragma mark -
#pragma mark Formatting Properties

- (BOOL)propertyIsSet:(IRCTextFormatterEffectType)effect
{
	return [[textField attributedStringValue] IRCFormatterAttributeSetInRange:effect range:[textField selectedRange]];
}

- (BOOL)boldSet
{
	return [self propertyIsSet:IRCTextFormatterBoldEffect];
}

- (BOOL)italicSet
{
	return [self propertyIsSet:IRCTextFormatterItalicEffect];
}

- (BOOL)underlineSet
{
	return [self propertyIsSet:IRCTextFormatterUnderlineEffect];
}

- (BOOL)foregroundColorSet
{
	return [self propertyIsSet:IRCTextFormatterForegroundColorEffect];
}

- (BOOL)backgroundColorSet
{
	return [self propertyIsSet:IRCTextFormatterBackgroundColorEffect];
}

#pragma mark -
#pragma mark Add Formatting

- (void)insertBoldCharIntoTextBox:(id)sender
{
	NSRange selectedTextRange = [textField selectedRange];
	if (selectedTextRange.location == NSNotFound || selectedTextRange.length == 0) return;
	
	NSAttributedString *oldString = [textField attributedStringValue];
	NSAttributedString *newString = [oldString setIRCFormatterAttribute:IRCTextFormatterBoldEffect
																  value:NSNumberWithBOOL(YES)
																  range:selectedTextRange];
	
	[textField setAttributedStringValue:newString];
	
	if ([textField respondsToSelector:@selector(focus)]) {
		[textField performSelector:@selector(focus)];
	}
}

- (void)insertItalicCharIntoTextBox:(id)sender
{
	NSRange selectedTextRange = [textField selectedRange];
	if (selectedTextRange.location == NSNotFound || selectedTextRange.length == 0) return;
	
	NSAttributedString *oldString = [textField attributedStringValue];
	NSAttributedString *newString = [oldString setIRCFormatterAttribute:IRCTextFormatterItalicEffect
																  value:NSNumberWithBOOL(YES)
																  range:selectedTextRange];
	
	[textField setAttributedStringValue:newString];
	
	if ([textField respondsToSelector:@selector(focus)]) {
		[textField performSelector:@selector(focus)];
	}
}

- (void)insertUnderlineCharIntoTextBox:(id)sender
{
	NSRange selectedTextRange = [textField selectedRange];
	if (selectedTextRange.location == NSNotFound || selectedTextRange.length == 0) return;
	
	NSAttributedString *oldString = [textField attributedStringValue];
	NSAttributedString *newString = [oldString setIRCFormatterAttribute:IRCTextFormatterUnderlineEffect
																  value:NSNumberWithBOOL(YES)
																  range:selectedTextRange];
	
	[textField setAttributedStringValue:newString];
	
	if ([textField respondsToSelector:@selector(focus)]) {
		[textField performSelector:@selector(focus)];
	}
}

- (void)insertForegroundColorCharIntoTextBox:(id)sender
{
	NSRange selectedTextRange = [textField selectedRange];
	if (selectedTextRange.location == NSNotFound || selectedTextRange.length == 0) return;
	
	NSAttributedString *oldString = [textField attributedStringValue];
	NSAttributedString *newString = oldString;
	
	if ([sender tag] == 100) { 
		NSString *charValue = nil;
		
		NSRange charRange;
		
		NSInteger colorChar = 0;
		NSInteger charCountIndex = 0;
		NSInteger rainbowArrayIndex = 0;
		
		NSMutableArray *colorCodes = [NSMutableArray arrayWithObjects:@"4", @"7", @"8", @"3", @"12", @"2", @"6", nil];
		
		while (1 == 1) {
			if (charCountIndex >= selectedTextRange.length) break;
			
			charRange = NSMakeRange((selectedTextRange.location + charCountIndex), 1);
			charValue = [[textField stringValue] safeSubstringWithRange:NSMakeRange(charCountIndex, 1)];
			
			if (rainbowArrayIndex > 6) rainbowArrayIndex = 0;
			
			if ([charValue isEqualToString:NSWhitespaceCharacter]) {
				newString = [newString setIRCFormatterAttribute:IRCTextFormatterForegroundColorEffect
														  value:NSNumberWithInteger(0)
														  range:charRange];
			} else {
				colorChar = [[colorCodes safeObjectAtIndex:rainbowArrayIndex] integerValue];
				newString = [newString setIRCFormatterAttribute:IRCTextFormatterForegroundColorEffect
														  value:NSNumberWithInteger(colorChar)
														  range:charRange];
			}
			
			charCountIndex++;
			rainbowArrayIndex++;
		}
	} else {
		newString = [oldString setIRCFormatterAttribute:IRCTextFormatterForegroundColorEffect
												  value:NSNumberWithInteger([sender tag])
                                                  range:selectedTextRange];
    }
    
    [textField setAttributedStringValue:newString];
    
    if ([textField respondsToSelector:@selector(focus)]) {
        [textField performSelector:@selector(focus)];
    }
}

- (void)insertBackgroundColorCharIntoTextBox:(id)sender
{
    NSRange selectedTextRange = [textField selectedRange];
    if (selectedTextRange.location == NSNotFound || selectedTextRange.length == 0) return;
    
    NSAttributedString *oldString = [textField attributedStringValue];
    NSAttributedString *newString = oldString;
    
    if ([sender tag] == 100) { 
        NSRange charRange;
        
        NSInteger colorChar = 0;
        NSInteger charCountIndex = 0;
        NSInteger rainbowArrayIndex = 0;
        
        NSMutableArray *colorCodes = [NSMutableArray arrayWithObjects:@"6", @"2", @"12", @"9", @"8", @"7", @"4", nil];
        
        while (1 == 1) {
            if (charCountIndex >= selectedTextRange.length) break;
            
            charRange = NSMakeRange((selectedTextRange.location + charCountIndex), 1);
            
            if (rainbowArrayIndex > 6) rainbowArrayIndex = 0;
            
            colorChar = [[colorCodes safeObjectAtIndex:rainbowArrayIndex] integerValue];
            newString = [newString setIRCFormatterAttribute:IRCTextFormatterBackgroundColorEffect
                                                      value:NSNumberWithInteger(colorChar)
                                                      range:charRange];
            
            charCountIndex++;
            rainbowArrayIndex++;
        }
    } else {
        newString = [oldString setIRCFormatterAttribute:IRCTextFormatterBackgroundColorEffect
                                                  value:NSNumberWithInteger([sender tag])
                                                  range:selectedTextRange];
    }
    
    [textField setAttributedStringValue:newString];
    
    if ([textField respondsToSelector:@selector(focus)]) {
        [textField performSelector:@selector(focus)];
    }
}

#pragma mark -
#pragma mark Remove Formatting

- (void)removeBoldCharFromTextBox:(id)sender
{
    NSRange selectedTextRange = [textField selectedRange];
    if (selectedTextRange.location == NSNotFound || selectedTextRange.length == 0) return;
    
    NSAttributedString *oldString = [textField attributedStringValue];
    NSAttributedString *newString = [oldString removeIRCFormatterAttribute:IRCTextFormatterBoldEffect
                                                                     range:selectedTextRange
                                                                     color:[textField textColor]];
    
    [textField setAttributedStringValue:newString];
    
    if ([textField respondsToSelector:@selector(focus)]) {
        [textField performSelector:@selector(focus)];
    }
}

- (void)removeItalicCharFromTextBox:(id)sender
{
    NSRange selectedTextRange = [textField selectedRange];
    if (selectedTextRange.location == NSNotFound || selectedTextRange.length == 0) return;
    
    NSAttributedString *oldString = [textField attributedStringValue];
    NSAttributedString *newString = [oldString removeIRCFormatterAttribute:IRCTextFormatterItalicEffect
                                                                     range:selectedTextRange
                                                                     color:[textField textColor]];
    
    [textField setAttributedStringValue:newString];
    
    if ([textField respondsToSelector:@selector(focus)]) {
        [textField performSelector:@selector(focus)];
    }
}

- (void)removeUnderlineCharFromTextBox:(id)sender
{
    NSRange selectedTextRange = [textField selectedRange];
    if (selectedTextRange.location == NSNotFound || selectedTextRange.length == 0) return;
    
    NSAttributedString *oldString = [textField attributedStringValue];
    NSAttributedString *newString = [oldString removeIRCFormatterAttribute:IRCTextFormatterUnderlineEffect
                                                                     range:selectedTextRange
                                                                     color:[textField textColor]];
    
    [textField setAttributedStringValue:newString];
    
    if ([textField respondsToSelector:@selector(focus)]) {
        [textField performSelector:@selector(focus)];
    }
}

- (void)removeForegroundColorCharFromTextBox:(id)sender
{
    NSRange selectedTextRange = [textField selectedRange];
    if (selectedTextRange.location == NSNotFound || selectedTextRange.length == 0) return;
    
    NSAttributedString *oldString = [textField attributedStringValue];
    NSAttributedString *newString = nil;
    
    newString = [oldString removeIRCFormatterAttribute:IRCTextFormatterForegroundColorEffect
                                                 range:selectedTextRange
                                                 color:[textField textColor]];
    
    newString = [newString removeIRCFormatterAttribute:IRCTextFormatterBackgroundColorEffect 
                                                 range:selectedTextRange
                                                 color:[textField textColor]];
    
    [textField setAttributedStringValue:newString];
    
    if ([textField respondsToSelector:@selector(focus)]) {
        [textField performSelector:@selector(focus)];
    }
}

- (void)removeBackgroundColorCharFromTextBox:(id)sender
{
    NSRange selectedTextRange = [textField selectedRange];
    if (selectedTextRange.location == NSNotFound || selectedTextRange.length == 0) return;
    
    NSAttributedString *oldString = [textField attributedStringValue];
    NSAttributedString *newString = [oldString removeIRCFormatterAttribute:IRCTextFormatterBackgroundColorEffect
                                                                     range:selectedTextRange
                                                                     color:[textField textColor]];
    
    [textField setAttributedStringValue:newString];
    
    if ([textField respondsToSelector:@selector(focus)]) {
        [textField performSelector:@selector(focus)];
    }
}

@end