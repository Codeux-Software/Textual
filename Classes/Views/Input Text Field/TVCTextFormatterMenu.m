/* ********************************************************************* 
                  _____         _               _
                 |_   _|____  _| |_ _   _  __ _| |
                   | |/ _ \ \/ / __| | | |/ _` | |
                   | |  __/>  <| |_| |_| | (_| | |
                   |_|\___/_/\_\\__|\__,_|\__,_|_|

 Copyright (c) 2008 - 2010 Satoshi Nakagawa <psychs AT limechat DOT net>
 Copyright (c) 2010 - 2015 Codeux Software, LLC & respective contributors.
        Please see Acknowledgements.pdf for additional information.

 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions
 are met:

    * Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the
      documentation and/or other materials provided with the distribution.
    * Neither the name of Textual and/or "Codeux Software, LLC", nor the 
      names of its contributors may be used to endorse or promote products 
      derived from this software without specific prior written permission.

 THIS SOFTWARE IS PROVIDED BY THE AUTHOR AND CONTRIBUTORS ``AS IS'' AND
 ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 ARE DISCLAIMED. IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE LIABLE
 FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
 OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
 LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
 OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
 SUCH DAMAGE.

 *********************************************************************** */

#import "TextualApplication.h"

#define _formattingMenuForegroundColorEnabledTag		95005
#define _formattingMenuBackgroundColorEnabledTag		95007
#define _formattingMenuForegroundColorDisabledTag		95004
#define _formattingMenuBackgroundColorDisabledTag		95006
#define _formattingMenuRainbowColorMenuItemTag			299

@implementation TVCTextViewIRCFormattingMenu

#pragma mark -
#pragma mark Menu Management

- (id)textField
{
	return [[NSApp keyWindow] firstResponder];
}

- (BOOL)firstResponderSupportsFormatting
{
	if ([[self textField] isKindOfClass:[TVCTextViewWithIRCFormatter class]]) {
		return YES;
	} else {
		return NO;
	}
}

- (BOOL)validateMenuItem:(NSMenuItem *)item
{
	if ([self firstResponderSupportsFormatting] == NO) {
		return NO;
	}

	switch ([item tag]) {
		case 95001:
		{
			NSMenu *rootMenu = [item menu];
			
			BOOL boldText = [self textIsBold];
			
			BOOL foregroundColor = [self textHasForegroundColor];
			BOOL backgroundColor = [self textHasBackgroundColor];
			
			[[rootMenu itemWithTag:_formattingMenuForegroundColorEnabledTag]  setHidden: foregroundColor];
			[[rootMenu itemWithTag:_formattingMenuForegroundColorDisabledTag] setHidden:(foregroundColor == NO)];
			
			[[rootMenu itemWithTag:_formattingMenuBackgroundColorEnabledTag]  setHidden: backgroundColor];
			[[rootMenu itemWithTag:_formattingMenuBackgroundColorDisabledTag] setHidden:(backgroundColor == NO)];
			
			[[rootMenu itemWithTag:_formattingMenuBackgroundColorEnabledTag]  setEnabled:foregroundColor];
			
			[item setState:boldText];
			
			if (boldText) {
				[item setAction:@selector(removeBoldCharFromTextBox:)];
			} else {
				[item setAction:@selector(insertBoldCharIntoTextBox:)];
			}
			
			return YES;
		}
		case 95002:
		{
			BOOL italicText = [self textIsItalicized];
			
			if (italicText) {
				[item setAction:@selector(removeItalicCharFromTextBox:)];
			} else {
				[item setAction:@selector(insertItalicCharIntoTextBox:)];
			}
			
			[item setState:italicText];
			
			return YES;
		}
		case 95008:
		{
			BOOL struckthroughText = [self textIsStruckthrough];

			if (struckthroughText) {
				[item setAction:@selector(removeStrikethroughCharFromTextBox:)];
			} else {
				[item setAction:@selector(insertStrikethroughCharIntoTextBox:)];
			}

			[item setState:struckthroughText];

			return YES;
		}
		case 95003:
		{
			BOOL underlineText = [self textIsUnderlined];
			
			if (underlineText) {
				[item setAction:@selector(removeUnderlineCharFromTextBox:)];
			} else {
				[item setAction:@selector(insertUnderlineCharIntoTextBox:)];
			}
			
			[item setState:underlineText];
			
			return YES;
		}
		default:
		{
			break;
		}
	}
	
	return YES;
}

#pragma mark -
#pragma mark Formatting Properties

- (BOOL)propertyIsSet:(IRCTextFormatterEffectType)formatterEffect
{
	NSRange selectedTextRange = [self.textField selectedRange];

	return [[self.textField attributedString] IRCFormatterAttributeSetInRange:formatterEffect range:selectedTextRange];
}

- (BOOL)textIsBold
{
	return [self propertyIsSet:IRCTextFormatterBoldEffect];
}

- (BOOL)textIsItalicized
{
	return [self propertyIsSet:IRCTextFormatterItalicEffect];
}

- (BOOL)textIsStruckthrough
{
	return [self propertyIsSet:IRCTextFormatterStrikethroughEffect];
}

- (BOOL)textIsUnderlined
{
	return [self propertyIsSet:IRCTextFormatterUnderlineEffect];
}

- (BOOL)textHasForegroundColor
{
	return [self propertyIsSet:IRCTextFormatterForegroundColorEffect];
}

- (BOOL)textHasBackgroundColor
{
	return [self propertyIsSet:IRCTextFormatterBackgroundColorEffect];
}

#pragma mark -
#pragma mark Formatting Storage Helpers

/* @public */
- (void)applyEffectToTextBox:(IRCTextFormatterEffectType)formatterEffect withValue:(id)value inRange:(NSRange)limitRange
{
	NSMutableAttributedString *stringMutableCopy = [self mutableStringAtRange:limitRange];

	if (stringMutableCopy) {
		[self applyEffect:formatterEffect withValue:value toMutableString:stringMutableCopy];

		[self applyAttributedStringToTextBox:stringMutableCopy inRange:limitRange];

		if (formatterEffect == IRCTextFormatterForegroundColorEffect && value == nil) {
			[self.textField resetTextColorInRange:limitRange];
		}
	}
}

/* @private */
- (NSMutableAttributedString *)mutableStringAtRange:(NSRange)limitRange
{
	if (limitRange.location == NSNotFound || limitRange.length == 0) {
		return nil;
	} else {
		NSAttributedString *stringSubstring = [[self.textField attributedString] attributedSubstringFromRange:limitRange];

		return [stringSubstring mutableCopy];
	}
}

- (void)applyEffect:(IRCTextFormatterEffectType)formatterEffect withValue:(id)value toMutableString:(NSMutableAttributedString *)mutableString
{
	[self applyEffect:formatterEffect withValue:value inRange:[mutableString range] toMutableString:mutableString];
}

- (void)applyEffect:(IRCTextFormatterEffectType)formatterEffect withValue:(id)value inRange:(NSRange)limitRange toMutableString:(NSMutableAttributedString *)mutableString
{
	if (value) {
		[mutableString setIRCFormatterAttribute:formatterEffect value:value range:limitRange];
	} else {
		[mutableString removeIRCFormatterAttribute:formatterEffect range:limitRange];
	}
}

- (void)applyAttributedStringToTextBox:(NSMutableAttributedString *)mutableString inRange:(NSRange)limitRange
{
	if ([self.textField shouldChangeTextInRange:limitRange replacementString:[mutableString string]]) {
		[[self.textField textStorage] replaceCharactersInRange:limitRange withAttributedString:mutableString];

		[self.textField didChangeText];

		[self.textField setSelectedRange:limitRange];
	}
}

#pragma mark -
#pragma mark Add Formatting

- (void)insertBoldCharIntoTextBox:(id)sender
{
	NSRange selectedTextRange = [self.textField selectedRange];

	[self applyEffectToTextBox:IRCTextFormatterBoldEffect withValue:@(YES) inRange:selectedTextRange];
}

- (void)insertItalicCharIntoTextBox:(id)sender
{
	NSRange selectedTextRange = [self.textField selectedRange];

	[self applyEffectToTextBox:IRCTextFormatterItalicEffect withValue:@(YES) inRange:selectedTextRange];
}

- (void)insertStrikethroughCharIntoTextBox:(id)sender
{
	NSRange selectedTextRange = [self.textField selectedRange];

	[self applyEffectToTextBox:IRCTextFormatterStrikethroughEffect withValue:@(YES) inRange:selectedTextRange];
}

- (void)insertUnderlineCharIntoTextBox:(id)sender
{
	NSRange selectedTextRange = [self.textField selectedRange];

	[self applyEffectToTextBox:IRCTextFormatterUnderlineEffect withValue:@(YES) inRange:selectedTextRange];
}

- (void)insertForegroundColorCharIntoTextBox:(id)sender
{
	if ([sender tag] == _formattingMenuRainbowColorMenuItemTag) {
		[self insertRainbowColorCharInfoTextBox:sender foregroundColor:YES];
	} else {
		NSRange selectedTextRange = [self.textField selectedRange];

		[self applyEffectToTextBox:IRCTextFormatterForegroundColorEffect withValue:@([sender tag]) inRange:selectedTextRange];
	}
}

- (void)insertBackgroundColorCharIntoTextBox:(id)sender
{
	if ([sender tag] == _formattingMenuRainbowColorMenuItemTag) {
		[self insertRainbowColorCharInfoTextBox:sender foregroundColor:NO];
	} else {
		NSRange selectedTextRange = [self.textField selectedRange];

		[self applyEffectToTextBox:IRCTextFormatterBackgroundColorEffect withValue:@([sender tag]) inRange:selectedTextRange];
	}
}

- (void)insertRainbowColorCharInfoTextBox:(id)sender foregroundColor:(BOOL)asForegroundColor
{
	NSRange selectedTextRange = [self.textField selectedRange];

	NSMutableAttributedString *mutableStringCopy = [self mutableStringAtRange:selectedTextRange];

	if (mutableStringCopy == nil) {
		return;
	}

	[mutableStringCopy beginEditing];

	NSUInteger rainbowArrayIndex = 0;

	NSArray *colorCodes = @[@"4", @"7", @"8", @"3", @"12", @"2", @"6"];

	for (NSInteger charCountIndex = 0; charCountIndex < [mutableStringCopy length]; charCountIndex++) {
		if (rainbowArrayIndex > 6) {
			rainbowArrayIndex = 0;
		}

		NSInteger currentColorCode = [colorCodes integerAtIndex:rainbowArrayIndex];

		NSRange currentCharacterRange = NSMakeRange(charCountIndex, 1);

		if (asForegroundColor) {
			[self applyEffect:IRCTextFormatterForegroundColorEffect withValue:@(currentColorCode) inRange:currentCharacterRange toMutableString:mutableStringCopy];
		} else {
			[self applyEffect:IRCTextFormatterBackgroundColorEffect withValue:@(currentColorCode) inRange:currentCharacterRange toMutableString:mutableStringCopy];
		}

		rainbowArrayIndex += 1;
	}

	[mutableStringCopy endEditing];

	[self applyAttributedStringToTextBox:mutableStringCopy inRange:selectedTextRange];
}

#pragma mark -
#pragma mark Remove Formatting

- (void)removeBoldCharFromTextBox:(id)sender
{
	NSRange selectedTextRange = [self.textField selectedRange];

	[self applyEffectToTextBox:IRCTextFormatterBoldEffect withValue:nil inRange:selectedTextRange];
}

- (void)removeItalicCharFromTextBox:(id)sender
{
	NSRange selectedTextRange = [self.textField selectedRange];

	[self applyEffectToTextBox:IRCTextFormatterItalicEffect withValue:nil inRange:selectedTextRange];
}

- (void)removeStrikethroughCharFromTextBox:(id)sender
{
	NSRange selectedTextRange = [self.textField selectedRange];

	[self applyEffectToTextBox:IRCTextFormatterStrikethroughEffect withValue:nil inRange:selectedTextRange];
}

- (void)removeUnderlineCharFromTextBox:(id)sender
{
	NSRange selectedTextRange = [self.textField selectedRange];

	[self applyEffectToTextBox:IRCTextFormatterUnderlineEffect withValue:nil inRange:selectedTextRange];
}

- (void)removeForegroundColorCharFromTextBox:(id)sender
{
	NSRange selectedTextRange = [self.textField selectedRange];

	[self applyEffectToTextBox:IRCTextFormatterForegroundColorEffect withValue:nil inRange:selectedTextRange];
}

- (void)removeBackgroundColorCharFromTextBox:(id)sender
{
	NSRange selectedTextRange = [self.textField selectedRange];

	[self applyEffectToTextBox:IRCTextFormatterBackgroundColorEffect withValue:nil inRange:selectedTextRange];
}

@end
