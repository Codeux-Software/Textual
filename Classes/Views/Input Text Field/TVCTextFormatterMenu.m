/* ********************************************************************* 
       _____        _               _    ___ ____   ____
      |_   _|___  _| |_ _   _  __ _| |  |_ _|  _ \ / ___|
       | |/ _ \ \/ / __| | | |/ _` | |   | || |_) | |
       | |  __/>  <| |_| |_| | (_| | |   | ||  _ <| |___
       |_|\___/_/\_\\__|\__,_|\__,_|_|  |___|_| \_\\____|

 Copyright (c) 2008 - 2010 Satoshi Nakagawa <psychs AT limechat DOT net>
 Copyright (c) 2010 — 2014 Codeux Software & respective contributors.
     Please see Acknowledgements.pdf for additional information.

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

#define _returnMethodOnBadRange			if (selectedTextRange.location == NSNotFound || selectedTextRange.length == 0) {		\
												return;																				\
										}


#pragma mark -
#pragma mark Menu Management

- (id)init
{
	if ((self = [super init])) {
		_formattingQueue = dispatch_queue_create("formattingQueue", NULL);
		
		return self;
	}
	
	return nil;
}

- (void)dealloc
{
	dispatch_release(_formattingQueue);
	
	_formattingQueue = NULL;
}

- (void)enableSheetField:(TVCTextViewWithIRCFormatter *)field
{
	_sheetOverrideEnabled = YES;

	_textField = field;
}

- (void)enableWindowField:(TVCTextViewWithIRCFormatter *)field
{
	_sheetOverrideEnabled = NO;

	_textField = field;
}

- (BOOL)validateMenuItem:(NSMenuItem *)item
{
	switch ([item tag]) {
		case 95001:
		{
			NSMenu *rootMenu = [item menu];
			
			BOOL boldText		 = [self boldSet];
			
			BOOL foregroundColor = [self foregroundColorSet];
			BOOL backgroundColor = [self backgroundColorSet];
			
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
		default:
		{
			break;
		}
	}
	
	return YES;
}

#pragma mark -
#pragma mark Formatting Properties

- (BOOL)propertyIsSet:(IRCTextFormatterEffectType)effect
{
	return [_textField IRCFormatterAttributeSetInRange:effect range:[_textField selectedRange]];
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
	dispatch_sync(_formattingQueue, ^{
		NSRange selectedTextRange = [_textField selectedRange];
		
		_returnMethodOnBadRange;
		
		[_textField setIRCFormatterAttribute:IRCTextFormatterBoldEffect
									   value:NSNumberWithBOOL(YES)
									   range:selectedTextRange];
		
		[_textField focus];
	});
}

- (void)insertItalicCharIntoTextBox:(id)sender
{
	dispatch_sync(_formattingQueue, ^{
		NSRange selectedTextRange = [_textField selectedRange];
		
		_returnMethodOnBadRange;
		
		[_textField setIRCFormatterAttribute:IRCTextFormatterItalicEffect
									   value:NSNumberWithBOOL(YES)
									   range:selectedTextRange];
		
		[_textField focus];
	});
}

- (void)insertUnderlineCharIntoTextBox:(id)sender
{
	dispatch_sync(_formattingQueue, ^{
		NSRange selectedTextRange = [_textField selectedRange];
		
		_returnMethodOnBadRange;
		
		[_textField setIRCFormatterAttribute:IRCTextFormatterUnderlineEffect
									   value:NSNumberWithBOOL(YES)
									   range:selectedTextRange];
		
		[_textField focus];
	});
}

- (void)insertForegroundColorCharIntoTextBox:(id)sender
{
	dispatch_sync(_formattingQueue, ^{
		NSRange selectedTextRange = [_textField selectedRange];
		
		_returnMethodOnBadRange;
		
		if ([sender tag] == 100) {
			if (selectedTextRange.length > IRCTextFormatterMaximumRainbowTextFormattingLength) {
				selectedTextRange.length = IRCTextFormatterMaximumRainbowTextFormattingLength;
			}
			
			UniChar charValue;
			
			NSRange charRange;
			
			NSInteger colorChar         = 0;
			NSInteger charCountIndex    = 0;
			NSInteger rainbowArrayIndex = 0;
			
			NSArray *colorCodes = @[@"4", @"7", @"8", @"3", @"12", @"2", @"6"];
			
			while (1 == 1) {
				/* Break once we reach the selected range length. */
				if (charCountIndex >= selectedTextRange.length) {
					break;
				}
				
				/* Range to apply to. */
				charRange = NSMakeRange((selectedTextRange.location + charCountIndex), 1);
				
				/* Character at that range. */
				charValue = [[_textField stringValue] characterAtIndex:charCountIndex];
				
				/* Reset rainbow index. */
				if (rainbowArrayIndex > 6) {
					rainbowArrayIndex = 0;
				}
				
				/* Apply based on character. */
				if (charValue == ' ') {
					[_textField setIRCFormatterAttribute:IRCTextFormatterForegroundColorEffect
												   value:@(0)
												   range:charRange];
				} else {
					colorChar = [colorCodes integerAtIndex:rainbowArrayIndex];
					
					[_textField setIRCFormatterAttribute:IRCTextFormatterForegroundColorEffect
												   value:@(colorChar)
												   range:charRange];
				}
				
				/* Bump count. */
				charCountIndex += 1;
				
				rainbowArrayIndex += 1;
			}
		} else {
			[_textField setIRCFormatterAttribute:IRCTextFormatterForegroundColorEffect
										   value:@([sender tag])
										   range:selectedTextRange];
		}
		
		[_textField focus];
	});
}

- (void)insertBackgroundColorCharIntoTextBox:(id)sender
{
	dispatch_sync(_formattingQueue, ^{
		NSRange selectedTextRange = [_textField selectedRange];
		
		_returnMethodOnBadRange;
		
		if ([sender tag] == 100) {
			if (selectedTextRange.length > IRCTextFormatterMaximumRainbowTextFormattingLength) {
				selectedTextRange.length = IRCTextFormatterMaximumRainbowTextFormattingLength;
			}
			
			NSRange charRange;
			
			NSInteger colorChar         = 0;
			NSInteger charCountIndex    = 0;
			NSInteger rainbowArrayIndex = 0;
			
			NSArray *colorCodes = @[@"6", @"2", @"12", @"9", @"8", @"7", @"4"];
			
			while (1 == 1) {
				/* Break when we reach the length of the selected range. */
				if (charCountIndex >= selectedTextRange.length) {
					break;
				}
				
				/* Range of replacement. */
				charRange = NSMakeRange((selectedTextRange.location + charCountIndex), 1);
				
				/* Update rainbow index. */
				if (rainbowArrayIndex > 6) {
					rainbowArrayIndex = 0;
				}
				
				/* Apply color. */
				colorChar = [colorCodes integerAtIndex:rainbowArrayIndex];
				
				[_textField setIRCFormatterAttribute:IRCTextFormatterBackgroundColorEffect
											   value:@(colorChar)
											   range:charRange];
				
				/* Bump numbers. */
				charCountIndex += 1;
				
				rainbowArrayIndex += 1;
			}
		} else {
			[_textField setIRCFormatterAttribute:IRCTextFormatterBackgroundColorEffect
										   value:@([sender tag])
										   range:selectedTextRange];
		}
		
		[_textField focus];
	});
}

#pragma mark -
#pragma mark Remove Formatting

- (void)removeBoldCharFromTextBox:(id)sender
{
	dispatch_sync(_formattingQueue, ^{
		NSRange selectedTextRange = [_textField selectedRange];
		
		_returnMethodOnBadRange;
		
		[_textField removeIRCFormatterAttribute:IRCTextFormatterBoldEffect
										  range:selectedTextRange
										  color:[_textField preferredFontColor]];
		
		[_textField focus];
	});
}

- (void)removeItalicCharFromTextBox:(id)sender
{
	dispatch_sync(_formattingQueue, ^{
		NSRange selectedTextRange = [_textField selectedRange];
		
		_returnMethodOnBadRange;
		
		[_textField removeIRCFormatterAttribute:IRCTextFormatterItalicEffect
										  range:selectedTextRange
										  color:[_textField preferredFontColor]];
		
		[_textField focus];
	});
}

- (void)removeUnderlineCharFromTextBox:(id)sender
{
	dispatch_sync(_formattingQueue, ^{
		NSRange selectedTextRange = [_textField selectedRange];
		
		_returnMethodOnBadRange;
		
		[_textField removeIRCFormatterAttribute:IRCTextFormatterUnderlineEffect
										  range:selectedTextRange
										  color:[_textField preferredFontColor]];
		
		[_textField focus];
	});
}

- (void)removeForegroundColorCharFromTextBox:(id)sender
{
	dispatch_sync(_formattingQueue, ^{
		NSRange selectedTextRange = [_textField selectedRange];
		
		_returnMethodOnBadRange;
		
		[_textField removeIRCFormatterAttribute:IRCTextFormatterForegroundColorEffect
										  range:selectedTextRange
										  color:[_textField preferredFontColor]];
		
		[_textField focus];
	});
}

- (void)removeBackgroundColorCharFromTextBox:(id)sender
{
	dispatch_sync(_formattingQueue, ^{
		NSRange selectedTextRange = [_textField selectedRange];
		
		_returnMethodOnBadRange;
		
		[_textField removeIRCFormatterAttribute:IRCTextFormatterBackgroundColorEffect
										  range:selectedTextRange
										  color:[_textField preferredFontColor]];
		
		[_textField focus];
	});
}

@end
