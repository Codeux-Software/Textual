/* ********************************************************************* 
       _____        _               _    ___ ____   ____
      |_   _|___  _| |_ _   _  __ _| |  |_ _|  _ \ / ___|
       | |/ _ \ \/ / __| | | |/ _` | |   | || |_) | |
       | |  __/>  <| |_| |_| | (_| | |   | ||  _ <| |___
       |_|\___/_/\_\\__|\__,_|\__,_|_|  |___|_| \_\\____|

 Copyright (c) 2010 — 2013 Codeux Software & respective contributors.
        Please see Contributors.pdf and Acknowledgements.pdf

 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions
 are met:

    * Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the
      documentation and/or other materials provided with the distribution.
    * Neither the name of the Textual IRC Client & Codeux Software nor the
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

@implementation TVCTextFormatterMenu

#define _formattingMenuForegroundColorEnabledTag		95005
#define _formattingMenuBackgroundColorEnabledTag		95007
#define _formattingMenuForegroundColorDisabledTag		95004
#define _formattingMenuBackgroundColorDisabledTag		95006
#define _formattingMenuRainbowColorMenuItemTag			99

#pragma mark -
#pragma mark Menu Management

- (void)enableSheetField:(TVCTextField *)field
{
	self.sheetOverrideEnabled = YES;

	self.textField = field;
}

- (void)enableWindowField:(TVCTextField *)field
{
	self.sheetOverrideEnabled = NO;

	self.textField = field;
}

- (BOOL)validateMenuItem:(NSMenuItem *)item
{
	if ([self.textField.window attachedSheet] && self.sheetOverrideEnabled == NO) {
		return NO;
	}

	switch ([item tag]) {
		case 95001:
		{
			NSMenu *rootMenu = [item menu];

			BOOL boldText		 = [self boldSet];
			BOOL foregroundColor = [self foregroundColorSet];
			BOOL backgroundColor = [self backgroundColorSet];

			[[rootMenu itemWithTag:_formattingMenuForegroundColorEnabledTag]  setHidden:foregroundColor];
			[[rootMenu itemWithTag:_formattingMenuForegroundColorDisabledTag] setHidden:BOOLReverseValue(foregroundColor)];

			[[rootMenu itemWithTag:_formattingMenuBackgroundColorEnabledTag]  setHidden:backgroundColor];
			[[rootMenu itemWithTag:_formattingMenuBackgroundColorEnabledTag]  setEnabled:foregroundColor];
			[[rootMenu itemWithTag:_formattingMenuBackgroundColorDisabledTag] setHidden:BOOLReverseValue(backgroundColor)];

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
		default: break;
	}

	return YES;
}

#pragma mark -
#pragma mark Formatting Properties

- (BOOL)propertyIsSet:(IRCTextFormatterEffectType)effect
{
    return [self.textField IRCFormatterAttributeSetInRange:effect range:self.textField.selectedRange];
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
    dispatch_sync([self.textField formattingQueue], ^{
        NSRange selectedTextRange = [self.textField selectedRange];
        if (selectedTextRange.location == NSNotFound || selectedTextRange.length == 0) return;

        [self.textField setIRCFormatterAttribute:IRCTextFormatterBoldEffect
										   value:NSNumberWithBOOL(YES)
										   range:selectedTextRange];

        if ([self.textField respondsToSelector:@selector(focus)]) {
            [self.textField performSelector:@selector(focus)];
        }
    });
}

- (void)insertItalicCharIntoTextBox:(id)sender
{
    dispatch_sync([self.textField formattingQueue], ^{
        NSRange selectedTextRange = [self.textField selectedRange];
        if (selectedTextRange.location == NSNotFound || selectedTextRange.length == 0) return;

        [self.textField setIRCFormatterAttribute:IRCTextFormatterItalicEffect
										   value:NSNumberWithBOOL(YES)
										   range:selectedTextRange];

        if ([self.textField respondsToSelector:@selector(focus)]) {
            [self.textField performSelector:@selector(focus)];
        }
    });
}

- (void)insertUnderlineCharIntoTextBox:(id)sender
{
    dispatch_sync([self.textField formattingQueue], ^{
        NSRange selectedTextRange = [self.textField selectedRange];
        if (selectedTextRange.location == NSNotFound || selectedTextRange.length == 0) return;

        [self.textField setIRCFormatterAttribute:IRCTextFormatterUnderlineEffect
										   value:NSNumberWithBOOL(YES)
										   range:selectedTextRange];

        if ([self.textField respondsToSelector:@selector(focus)]) {
            [self.textField performSelector:@selector(focus)];
        }
    });
}

- (void)insertForegroundColorCharIntoTextBox:(id)sender
{
    dispatch_sync([self.textField formattingQueue], ^{
        NSRange selectedTextRange = [self.textField selectedRange];
        if (selectedTextRange.location == NSNotFound || selectedTextRange.length == 0) return;

        if ([sender tag] == 100) {
            if (selectedTextRange.length > TXMaximumRainbowTextFormattingLength) {
                selectedTextRange.length = TXMaximumRainbowTextFormattingLength;
            }

            NSString *charValue = nil;

            NSRange charRange;

            NSInteger colorChar         = 0;
            NSInteger charCountIndex    = 0;
            NSInteger rainbowArrayIndex = 0;

            NSMutableArray *colorCodes = [NSMutableArray arrayWithObjects:@"4", @"7", @"8", @"3", @"12", @"2", @"6", nil];

            while (1 == 1) {
                if (charCountIndex >= selectedTextRange.length) {
                    break;
                }

                charRange = NSMakeRange((selectedTextRange.location + charCountIndex), 1);
                charValue = [self.textField.stringValue safeSubstringWithRange:NSMakeRange(charCountIndex, 1)];

                if (rainbowArrayIndex > 6) {
                    rainbowArrayIndex = 0;
                }

                if ([charValue isEqualToString:NSStringWhitespacePlaceholder]) {
                    [self.textField setIRCFormatterAttribute:IRCTextFormatterForegroundColorEffect
													   value:@0
													   range:charRange];
                } else {
                    colorChar = [colorCodes integerAtIndex:rainbowArrayIndex];

                    [self.textField setIRCFormatterAttribute:IRCTextFormatterForegroundColorEffect
													   value:@(colorChar)
													   range:charRange];
                }

                charCountIndex++;
                rainbowArrayIndex++;
            }
        } else {
            [self.textField setIRCFormatterAttribute:IRCTextFormatterForegroundColorEffect
											   value:@([sender tag])
											   range:selectedTextRange];
        }

        if ([self.textField respondsToSelector:@selector(focus)]) {
            [self.textField performSelector:@selector(focus)];
        }
    });
}

- (void)insertBackgroundColorCharIntoTextBox:(id)sender
{
    dispatch_sync([self.textField formattingQueue], ^{
        NSRange selectedTextRange = [self.textField selectedRange];
        if (selectedTextRange.location == NSNotFound || selectedTextRange.length == 0) return;

        if ([sender tag] == 100) {
            if (selectedTextRange.length > TXMaximumRainbowTextFormattingLength) {
                selectedTextRange.length = TXMaximumRainbowTextFormattingLength;
            }

            NSRange charRange;

            NSInteger colorChar         = 0;
            NSInteger charCountIndex    = 0;
            NSInteger rainbowArrayIndex = 0;

            NSMutableArray *colorCodes = [NSMutableArray arrayWithObjects:@"6", @"2", @"12", @"9", @"8", @"7", @"4", nil];

            while (1 == 1) {
                if (charCountIndex >= selectedTextRange.length) {
                    break;
                }

                charRange = NSMakeRange((selectedTextRange.location + charCountIndex), 1);

                if (rainbowArrayIndex > 6) {
                    rainbowArrayIndex = 0;
                }

                colorChar = [colorCodes integerAtIndex:rainbowArrayIndex];

                [self.textField setIRCFormatterAttribute:IRCTextFormatterBackgroundColorEffect
												   value:@(colorChar)
												   range:charRange];

                charCountIndex++;
                rainbowArrayIndex++;
            }
        } else {
            [self.textField setIRCFormatterAttribute:IRCTextFormatterBackgroundColorEffect
											   value:@([sender tag])
											   range:selectedTextRange];
        }

        if ([self.textField respondsToSelector:@selector(focus)]) {
            [self.textField performSelector:@selector(focus)];
        }
    });
}

#pragma mark -
#pragma mark Remove Formatting

- (void)removeBoldCharFromTextBox:(id)sender
{
    dispatch_sync([self.textField formattingQueue], ^{
        NSRange selectedTextRange = [self.textField selectedRange];
        if (selectedTextRange.location == NSNotFound || selectedTextRange.length == 0) return;

        [self.textField removeIRCFormatterAttribute:IRCTextFormatterBoldEffect
											  range:selectedTextRange
											  color:TXDefaultTextFieldFontColor];

        if ([self.textField respondsToSelector:@selector(focus)]) {
            [self.textField performSelector:@selector(focus)];
        }
    });
}

- (void)removeItalicCharFromTextBox:(id)sender
{
    dispatch_sync([self.textField formattingQueue], ^{
        NSRange selectedTextRange = [self.textField selectedRange];
        if (selectedTextRange.location == NSNotFound || selectedTextRange.length == 0) return;

        [self.textField removeIRCFormatterAttribute:IRCTextFormatterItalicEffect
											  range:selectedTextRange
											  color:TXDefaultTextFieldFontColor];

        if ([self.textField respondsToSelector:@selector(focus)]) {
            [self.textField performSelector:@selector(focus)];
        }
    });
}

- (void)removeUnderlineCharFromTextBox:(id)sender
{
    dispatch_sync([self.textField formattingQueue], ^{
        NSRange selectedTextRange = [self.textField selectedRange];
        if (selectedTextRange.location == NSNotFound || selectedTextRange.length == 0) return;

        [self.textField removeIRCFormatterAttribute:IRCTextFormatterUnderlineEffect
											  range:selectedTextRange
											  color:TXDefaultTextFieldFontColor];

        if ([self.textField respondsToSelector:@selector(focus)]) {
            [self.textField performSelector:@selector(focus)];
        }
    });
}

- (void)removeForegroundColorCharFromTextBox:(id)sender
{
    dispatch_sync([self.textField formattingQueue], ^{
        NSRange selectedTextRange = [self.textField selectedRange];
        if (selectedTextRange.location == NSNotFound || selectedTextRange.length == 0) return;

        [self.textField removeIRCFormatterAttribute:IRCTextFormatterForegroundColorEffect
											  range:selectedTextRange
											  color:TXDefaultTextFieldFontColor];

        if ([self.textField respondsToSelector:@selector(focus)]) {
            [self.textField performSelector:@selector(focus)];
        }
    });
}

- (void)removeBackgroundColorCharFromTextBox:(id)sender
{
    dispatch_sync([self.textField formattingQueue], ^{
        NSRange selectedTextRange = [self.textField selectedRange];
        if (selectedTextRange.location == NSNotFound || selectedTextRange.length == 0) return;

        [self.textField removeIRCFormatterAttribute:IRCTextFormatterBackgroundColorEffect
											  range:selectedTextRange
											  color:TXDefaultTextFieldFontColor];

        if ([self.textField respondsToSelector:@selector(focus)]) {
            [self.textField performSelector:@selector(focus)];
        }
    });
}

@end
