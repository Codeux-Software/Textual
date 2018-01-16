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

#import "IRCColorFormat.h"
#import "TVCTextViewWithIRCFormatterPrivate.h"
#import "TVCTextFormatterMenuPrivate.h"

NS_ASSUME_NONNULL_BEGIN

#define _formattingMenuForegroundColorEnabledTag		95005
#define _formattingMenuBackgroundColorEnabledTag		95007
#define _formattingMenuForegroundColorDisabledTag		95004
#define _formattingMenuBackgroundColorDisabledTag		95006
#define _formattingMenuRainbowColorMenuItemTag			299
#define _formattingMenuHexColorMenuItemTag				300

@interface TVCTextViewIRCFormattingMenu ()
@property (readonly, nullable) TVCTextViewWithIRCFormatter *textField;
@property (nonatomic, weak, readwrite) IBOutlet NSMenuItem *formatterMenu;
@property (nonatomic, weak, readwrite) IBOutlet NSMenu *foregroundColorMenu;
@property (nonatomic, weak, readwrite) IBOutlet NSMenu *backgroundColorMenu;
@end

@implementation TVCTextViewIRCFormattingMenu

#pragma mark -
#pragma mark Menu Management

- (nullable TVCTextViewWithIRCFormatter *)textField
{
	id firstResponder = [[NSApp keyWindow] firstResponder];

	if ([firstResponder isKindOfClass:[TVCTextViewWithIRCFormatter class]]) {
		return firstResponder;
	}

	return nil;
}

- (BOOL)validateMenuItem:(NSMenuItem *)item
{
	if (self.textField == nil) {
		return NO;
	}

	switch (item.tag) {
		case 95001:
		{
			NSMenu *rootMenu = item.menu;

			BOOL boldText = self.textIsBold;

			BOOL foregroundColor = self.textHasForegroundColor;
			BOOL backgroundColor = self.textHasBackgroundColor;

			[rootMenu itemWithTag:_formattingMenuForegroundColorEnabledTag].hidden = foregroundColor;
			[rootMenu itemWithTag:_formattingMenuForegroundColorDisabledTag].hidden = (foregroundColor == NO);

			[rootMenu itemWithTag:_formattingMenuBackgroundColorEnabledTag].hidden = backgroundColor;
			[rootMenu itemWithTag:_formattingMenuBackgroundColorDisabledTag].hidden = (backgroundColor == NO);

			[rootMenu itemWithTag:_formattingMenuBackgroundColorEnabledTag].enabled = foregroundColor;

			item.state = boldText;

			if (boldText) {
				item.action = @selector(removeBoldCharFromTextBox:);
			} else {
				item.action = @selector(insertBoldCharIntoTextBox:);
			}

			return YES;
		}
		case 95002:
		{
			BOOL italicText = self.textIsItalicized;

			item.state = italicText;

			if (italicText) {
				item.action = @selector(removeItalicCharFromTextBox:);
			} else {
				item.action = @selector(insertItalicCharIntoTextBox:);
			}

			return YES;
		}
		case 95009:
		{
			BOOL monospaceText = self.textIsMonospace;

			item.state = monospaceText;

			if (monospaceText) {
				item.action = @selector(removeMonospaceCharFromTextBox:);
			} else {
				item.action = @selector(insertMonospaceCharIntoTextBox:);
			}

			return YES;
		}
		case 95008:
		{
			BOOL struckthroughText = self.textIsStruckthrough;

			item.state = struckthroughText;

			if (struckthroughText) {
				item.action = @selector(removeStrikethroughCharFromTextBox:);
			} else {
				item.action = @selector(insertStrikethroughCharIntoTextBox:);
			}

			return YES;
		}
		case 95003:
		{
			BOOL underlineText = self.textIsUnderlined;

			item.state = underlineText;

			if (underlineText) {
				item.action = @selector(removeUnderlineCharFromTextBox:);
			} else {
				item.action = @selector(insertUnderlineCharIntoTextBox:);
			}

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
	NSRange selectedTextRange = self.textField.selectedRange;

	return [self.textField.attributedString IRCFormatterAttributeSetInRange:formatterEffect range:selectedTextRange];
}

- (BOOL)textIsBold
{
	return [self propertyIsSet:IRCTextFormatterBoldEffect];
}

- (BOOL)textIsItalicized
{
	return [self propertyIsSet:IRCTextFormatterItalicEffect];
}

- (BOOL)textIsMonospace
{
	return [self propertyIsSet:IRCTextFormatterMonospaceEffect];
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

- (void)applyEffectToTextBox:(IRCTextFormatterEffectType)formatterEffect withValue:(id)value inRange:(NSRange)limitRange
{
	NSMutableAttributedString *stringMutableCopy = [self mutableStringAtRange:limitRange];

	if (stringMutableCopy == nil) {
		return;
	}

	[self applyEffect:formatterEffect withValue:value toMutableString:stringMutableCopy];

	[self applyAttributedStringToTextBox:stringMutableCopy inRange:limitRange];

	if (formatterEffect == IRCTextFormatterForegroundColorEffect && value == nil) {
		[self.textField resetFontColorInRange:limitRange];
	}

	if (formatterEffect == IRCTextFormatterMonospaceEffect && value == nil) {
		[self.textField resetFontInRange:limitRange];
	}
}

- (nullable NSMutableAttributedString *)mutableStringAtRange:(NSRange)limitRange
{
	if (limitRange.location == NSNotFound || limitRange.length == 0) {
		return nil;
	}

	NSAttributedString *stringSubstring = [self.textField.attributedString attributedSubstringFromRange:limitRange];

	return [stringSubstring mutableCopy];
}

- (void)applyEffect:(IRCTextFormatterEffectType)formatterEffect withValue:(id)value toMutableString:(NSMutableAttributedString *)mutableString
{
	[self applyEffect:formatterEffect withValue:value inRange:mutableString.range toMutableString:mutableString];
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
	if ([self.textField shouldChangeTextInRange:limitRange replacementString:mutableString.string] == NO) {
		return;
	}

	[self.textField.textStorage replaceCharactersInRange:limitRange withAttributedString:mutableString];

	[self.textField didChangeText];

	[self.textField setSelectedRange:limitRange];
}

#pragma mark -
#pragma mark Add Formatting

- (void)insertBoldCharIntoTextBox:(id)sender
{
	NSRange selectedTextRange = self.textField.selectedRange;

	[self applyEffectToTextBox:IRCTextFormatterBoldEffect withValue:@(YES) inRange:selectedTextRange];
}

- (void)insertItalicCharIntoTextBox:(id)sender
{
	NSRange selectedTextRange = self.textField.selectedRange;

	[self applyEffectToTextBox:IRCTextFormatterItalicEffect withValue:@(YES) inRange:selectedTextRange];
}

- (void)insertMonospaceCharIntoTextBox:(id)sender
{
	NSRange selectedTextRange = self.textField.selectedRange;

	[self applyEffectToTextBox:IRCTextFormatterMonospaceEffect withValue:@(YES) inRange:selectedTextRange];
}

- (void)insertStrikethroughCharIntoTextBox:(id)sender
{
	NSRange selectedTextRange = self.textField.selectedRange;

	[self applyEffectToTextBox:IRCTextFormatterStrikethroughEffect withValue:@(YES) inRange:selectedTextRange];
}

- (void)insertUnderlineCharIntoTextBox:(id)sender
{
	NSRange selectedTextRange = self.textField.selectedRange;

	[self applyEffectToTextBox:IRCTextFormatterUnderlineEffect withValue:@(YES) inRange:selectedTextRange];
}

- (void)insertForegroundColorCharIntoTextBox:(id)sender
{
	if ([sender tag] == _formattingMenuRainbowColorMenuItemTag) {
		[self insertRainbowColorCharInfoTextBox:sender asForegroundColor:YES];

		return;
	}
	else if ([sender tag] == _formattingMenuHexColorMenuItemTag)
	{
		NSColorPanel *colorPanel = [NSColorPanel sharedColorPanel];

		[colorPanel setTarget:self];
		[colorPanel setAction:@selector(foregroundColorPanelColorChanged:)];
		[colorPanel setAlphaValue:1.0];
		[colorPanel setColor:self.textField.preferredFontColor];

		[colorPanel orderFront:nil];
	}

	NSRange selectedTextRange = self.textField.selectedRange;

	[self applyEffectToTextBox:IRCTextFormatterForegroundColorEffect withValue:@([sender tag]) inRange:selectedTextRange];
}

- (void)insertBackgroundColorCharIntoTextBox:(id)sender
{
	if ([sender tag] == _formattingMenuRainbowColorMenuItemTag)
	{
		[self insertRainbowColorCharInfoTextBox:sender asForegroundColor:NO];

		return;
	}
	else if ([sender tag] == _formattingMenuHexColorMenuItemTag)
	{
		NSColorPanel *colorPanel = [NSColorPanel sharedColorPanel];

		[colorPanel setTarget:self];
		[colorPanel setAction:@selector(backgroundColorPanelColorChanged:)];
		[colorPanel setAlphaValue:1.0];
		[colorPanel setColor:[NSColor whiteColor]];

		[colorPanel orderFront:nil];
	}

	NSRange selectedTextRange = self.textField.selectedRange;

	[self applyEffectToTextBox:IRCTextFormatterBackgroundColorEffect withValue:@([sender tag]) inRange:selectedTextRange];
}

- (void)insertRainbowColorCharInfoTextBox:(id)sender asForegroundColor:(BOOL)asForegroundColor
{
	NSRange selectedTextRange = self.textField.selectedRange;

	NSMutableAttributedString *mutableStringCopy = [self mutableStringAtRange:selectedTextRange];

	if (mutableStringCopy == nil) {
		return;
	}

	[mutableStringCopy beginEditing];

	NSUInteger rainbowArrayIndex = 0;

	NSArray *colorCodes = @[@(4), @(7), @(8), @(3), @(12), @(2), @(6)];

	for (NSUInteger charCountIndex = 0; charCountIndex < mutableStringCopy.length; charCountIndex++) {
		if (rainbowArrayIndex > 6) {
			rainbowArrayIndex = 0;
		}

		NSUInteger currentColorCode = [colorCodes unsignedIntegerAtIndex:rainbowArrayIndex];

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

- (void)foregroundColorPanelColorChanged:(NSColorPanel *)sender
{
	NSRange selectedTextRange = self.textField.selectedRange;

	[self applyEffectToTextBox:IRCTextFormatterForegroundColorEffect withValue:sender.color inRange:selectedTextRange];
}

- (void)backgroundColorPanelColorChanged:(NSColorPanel *)sender
{
	NSRange selectedTextRange = self.textField.selectedRange;

	[self applyEffectToTextBox:IRCTextFormatterBackgroundColorEffect withValue:sender.color inRange:selectedTextRange];
}

#pragma mark -
#pragma mark Remove Formatting

- (void)removeBoldCharFromTextBox:(id)sender
{
	NSRange selectedTextRange = self.textField.selectedRange;

	[self applyEffectToTextBox:IRCTextFormatterBoldEffect withValue:nil inRange:selectedTextRange];
}

- (void)removeItalicCharFromTextBox:(id)sender
{
	NSRange selectedTextRange = self.textField.selectedRange;

	[self applyEffectToTextBox:IRCTextFormatterItalicEffect withValue:nil inRange:selectedTextRange];
}

- (void)removeMonospaceCharFromTextBox:(id)sender
{
	NSRange selectedTextRange = self.textField.selectedRange;

	[self applyEffectToTextBox:IRCTextFormatterMonospaceEffect withValue:nil inRange:selectedTextRange];
}

- (void)removeStrikethroughCharFromTextBox:(id)sender
{
	NSRange selectedTextRange = self.textField.selectedRange;

	[self applyEffectToTextBox:IRCTextFormatterStrikethroughEffect withValue:nil inRange:selectedTextRange];
}

- (void)removeUnderlineCharFromTextBox:(id)sender
{
	NSRange selectedTextRange = self.textField.selectedRange;

	[self applyEffectToTextBox:IRCTextFormatterUnderlineEffect withValue:nil inRange:selectedTextRange];
}

- (void)removeForegroundColorCharFromTextBox:(id)sender
{
	NSRange selectedTextRange = self.textField.selectedRange;

	[self applyEffectToTextBox:IRCTextFormatterForegroundColorEffect withValue:nil inRange:selectedTextRange];
}

- (void)removeBackgroundColorCharFromTextBox:(id)sender
{
	NSRange selectedTextRange = self.textField.selectedRange;

	[self applyEffectToTextBox:IRCTextFormatterBackgroundColorEffect withValue:nil inRange:selectedTextRange];
}

@end

NS_ASSUME_NONNULL_END
