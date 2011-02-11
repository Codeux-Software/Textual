// Modifications by Codeux Software <support AT codeux DOT com> <https://github.com/codeux/Textual>
// You can redistribute it and/or modify it under the new BSD license.

@implementation IRCTextFormatterMenu

@synthesize textField;
@synthesize formatterMenu;
@synthesize sheetOverrideEnabled;

#pragma mark -
#pragma mark Menu Management

- (void)enableSheetField:(NSTextField *)field
{
	textField = field;
    
	sheetOverrideEnabled = YES;
}

- (void)enableWindowField:(NSTextField *)field
{
	textField = field;
    
	sheetOverrideEnabled = NO;
}

- (NSRange)selectionRange:(NSAttributedString *)stringValue
{
	if (NSObjectIsNotEmpty(stringValue)) {
		NSRange selectedTextRange = [[textField currentEditor] selectedRange];
		
		if (selectedTextRange.location == NSNotFound) {
			selectedTextRange = NSMakeRange(0, [stringValue length]);
		}
		
		return selectedTextRange;
	} 
	
	return NSMakeRange(NSNotFound, 0);
}

- (BOOL)validateMenuItem:(NSMenuItem *)item
{
	if ([[textField window] attachedSheet] && sheetOverrideEnabled == NO) {
		return NO;
	}
	
	NSAttributedString *stringValue = [textField attributedStringValue];
	
	NSRange selectedTextRange = [self selectionRange:stringValue];
	
	switch ([item tag]) {
		case 95001: 
		{
			NSMenu *rootMenu = [item menu];
			
			BOOL boldText		 = [stringValue IRCFormatterAttributeSetInRange:IRCTextFormatterBoldEffect			  range:selectedTextRange];
			BOOL foregroundColor = [stringValue IRCFormatterAttributeSetInRange:IRCTextFormatterForegroundColorEffect range:selectedTextRange];
			BOOL backgroundColor = [stringValue IRCFormatterAttributeSetInRange:IRCTextFormatterBackgroundColorEffect range:selectedTextRange];
			
			[[rootMenu itemWithTag:95005] setHidden:foregroundColor];
			[[rootMenu itemWithTag:95004] setHidden:BOOLReverseValue(foregroundColor)];
			
			[[rootMenu itemWithTag:95007] setHidden:backgroundColor];
			[[rootMenu itemWithTag:95007] setEnabled:foregroundColor];
			[[rootMenu itemWithTag:95006] setHidden:BOOLReverseValue(backgroundColor)];
			
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
			BOOL italicText = [stringValue IRCFormatterAttributeSetInRange:IRCTextFormatterItalicEffect range:selectedTextRange];
			
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
			BOOL underlineText = [stringValue IRCFormatterAttributeSetInRange:IRCTextFormatterUnderlineEffect range:selectedTextRange];
			
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
			
			NSMenuItem *divider = [[item menu] itemWithTag:99];
			
			[item	 setHidden:BOOLReverseValue(condition)];
			[divider setHidden:BOOLReverseValue(condition)];
			
			return condition;
		}
		default: break;
	}
	
	return YES;
}

#pragma mark -
#pragma mark Add Formatting

- (void)insertBoldCharIntoTextBox:(id)sender
{
	NSRange selectedTextRange = [[textField currentEditor] selectedRange];
	if (selectedTextRange.location == NSNotFound) return;
	
	NSAttributedString *oldString = [textField attributedStringValue];
	NSAttributedString *newString = [oldString setIRCFormatterAttribute:IRCTextFormatterBoldEffect
																  value:[NSNumber numberWithBool:YES]
																  range:selectedTextRange];
	
	[textField setAttributedStringValue:newString];
	
	if ([textField respondsToSelector:@selector(focus)]) {
		[textField performSelector:@selector(focus)];
	}
}

- (void)insertItalicCharIntoTextBox:(id)sender
{
	NSRange selectedTextRange = [[textField currentEditor] selectedRange];
	if (selectedTextRange.location == NSNotFound) return;
	
	NSAttributedString *oldString = [textField attributedStringValue];
	NSAttributedString *newString = [oldString setIRCFormatterAttribute:IRCTextFormatterItalicEffect
																  value:[NSNumber numberWithBool:YES]
																  range:selectedTextRange];
	
	[textField setAttributedStringValue:newString];
	
	if ([textField respondsToSelector:@selector(focus)]) {
		[textField performSelector:@selector(focus)];
	}
}

- (void)insertUnderlineCharIntoTextBox:(id)sender
{
	NSRange selectedTextRange = [[textField currentEditor] selectedRange];
	if (selectedTextRange.location == NSNotFound) return;
	
	NSAttributedString *oldString = [textField attributedStringValue];
	NSAttributedString *newString = [oldString setIRCFormatterAttribute:IRCTextFormatterUnderlineEffect
																  value:[NSNumber numberWithBool:YES]
																  range:selectedTextRange];
	
	[textField setAttributedStringValue:newString];
	
	if ([textField respondsToSelector:@selector(focus)]) {
		[textField performSelector:@selector(focus)];
	}
}

- (void)insertForegroundColorCharIntoTextBox:(id)sender
{
	NSRange selectedTextRange = [[textField currentEditor] selectedRange];
	if (selectedTextRange.location == NSNotFound) return;
	
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
			
			if ([charValue isEqualToString:@" "]) {
				newString = [newString setIRCFormatterAttribute:IRCTextFormatterForegroundColorEffect
														  value:[NSNumber numberWithInteger:0]
														  range:charRange];
			} else {
				colorChar = [[colorCodes safeObjectAtIndex:rainbowArrayIndex] integerValue];
				newString = [newString setIRCFormatterAttribute:IRCTextFormatterForegroundColorEffect
														  value:[NSNumber numberWithInteger:colorChar]
														  range:charRange];
			}
			
			charCountIndex++;
			rainbowArrayIndex++;
		}
	} else {
		newString = [oldString setIRCFormatterAttribute:IRCTextFormatterForegroundColorEffect
												  value:[NSNumber numberWithInteger:[sender tag]]
												  range:selectedTextRange];
	}
	
	[textField setAttributedStringValue:newString];
	
	if ([textField respondsToSelector:@selector(focus)]) {
		[textField performSelector:@selector(focus)];
	}
}

- (void)insertBackgroundColorCharIntoTextBox:(id)sender
{
	NSRange selectedTextRange = [[textField currentEditor] selectedRange];
	if (selectedTextRange.location == NSNotFound) return;
	
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
													  value:[NSNumber numberWithInteger:colorChar]
													  range:charRange];
			
			charCountIndex++;
			rainbowArrayIndex++;
		}
	} else {
		newString = [oldString setIRCFormatterAttribute:IRCTextFormatterBackgroundColorEffect
												  value:[NSNumber numberWithInteger:[sender tag]]
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
	NSRange selectedTextRange = [[textField currentEditor] selectedRange];
	if (selectedTextRange.location == NSNotFound) return;
	
	NSAttributedString *oldString = [textField attributedStringValue];
	NSAttributedString *newString = [oldString removeIRCFormatterAttribute:IRCTextFormatterBoldEffect
																	 range:selectedTextRange];
	
	[textField setAttributedStringValue:newString];
	
	if ([textField respondsToSelector:@selector(focus)]) {
		[textField performSelector:@selector(focus)];
	}
}

- (void)removeItalicCharFromTextBox:(id)sender
{
	NSRange selectedTextRange = [[textField currentEditor] selectedRange];
	if (selectedTextRange.location == NSNotFound) return;
	
	NSAttributedString *oldString = [textField attributedStringValue];
	NSAttributedString *newString = [oldString removeIRCFormatterAttribute:IRCTextFormatterItalicEffect
																	 range:selectedTextRange];
	
	[textField setAttributedStringValue:newString];
	
	if ([textField respondsToSelector:@selector(focus)]) {
		[textField performSelector:@selector(focus)];
	}
}

- (void)removeUnderlineCharFromTextBox:(id)sender
{
	NSRange selectedTextRange = [[textField currentEditor] selectedRange];
	if (selectedTextRange.location == NSNotFound) return;
	
	NSAttributedString *oldString = [textField attributedStringValue];
	NSAttributedString *newString = [oldString removeIRCFormatterAttribute:IRCTextFormatterUnderlineEffect
																	 range:selectedTextRange];
	
	[textField setAttributedStringValue:newString];
	
	if ([textField respondsToSelector:@selector(focus)]) {
		[textField performSelector:@selector(focus)];
	}
}

- (void)removeForegroundColorCharFromTextBox:(id)sender
{
	NSRange selectedTextRange = [[textField currentEditor] selectedRange];
	if (selectedTextRange.location == NSNotFound) return;
	
	NSAttributedString *oldString = [textField attributedStringValue];
	NSAttributedString *newString = nil;
	
	newString = [oldString removeIRCFormatterAttribute:IRCTextFormatterForegroundColorEffect
												 range:selectedTextRange];
	
	newString = [newString removeIRCFormatterAttribute:IRCTextFormatterBackgroundColorEffect 
												 range:selectedTextRange];
	
	[textField setAttributedStringValue:newString];
	
	if ([textField respondsToSelector:@selector(focus)]) {
		[textField performSelector:@selector(focus)];
	}
}

- (void)removeBackgroundColorCharFromTextBox:(id)sender
{
	NSRange selectedTextRange = [[textField currentEditor] selectedRange];
	if (selectedTextRange.location == NSNotFound) return;
	
	NSAttributedString *oldString = [textField attributedStringValue];
	NSAttributedString *newString = [oldString removeIRCFormatterAttribute:IRCTextFormatterBackgroundColorEffect
																	 range:selectedTextRange];
	
	[textField setAttributedStringValue:newString];
	
	if ([textField respondsToSelector:@selector(focus)]) {
		[textField performSelector:@selector(focus)];
	}
}

@end