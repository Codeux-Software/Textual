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

@implementation TVCTextViewIRCFormattingMenu

#define _formattingMenuForegroundColorEnabledTag		95005
#define _formattingMenuBackgroundColorEnabledTag		95007
#define _formattingMenuForegroundColorDisabledTag		95004
#define _formattingMenuBackgroundColorDisabledTag		95006
#define _formattingMenuRainbowColorMenuItemTag			299

#define _returnMethodOnBadRange			if (selectedTextRange.location == NSNotFound || selectedTextRange.length == 0) {		\
											return;																				\
										}


#pragma mark -
#pragma mark Menu Management

- (instancetype)init
{
	if ((self = [super init])) {
		self.formattingQueue = dispatch_queue_create("formattingQueue", DISPATCH_QUEUE_SERIAL);
		
		return self;
	}
	
	return nil;
}

- (void)dealloc
{
	self.formattingQueue = NULL;
}

- (void)enableSheetField:(TVCTextViewWithIRCFormatter *)field
{
	self.sheetOverrideEnabled = YES;

	self.textField = field;
}

- (void)enableWindowField:(TVCTextViewWithIRCFormatter *)field
{
	self.sheetOverrideEnabled = NO;

	self.textField = field;
}

- (BOOL)validateMenuItem:(NSMenuItem *)item
{
	if ([[NSApp keyWindow] firstResponder] == self.textField) {
		;
	} else {
		return NO;
	}

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
	return [self.textField IRCFormatterAttributeSetInRange:effect range:[self.textField selectedRange]];
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
	XRPerformBlockSynchronouslyOnQueue(self.formattingQueue, ^{
		NSRange selectedTextRange = [self.textField selectedRange];
		
		_returnMethodOnBadRange
		
		[self.textField setIRCFormatterAttribute:IRCTextFormatterBoldEffect
									   value:@YES
									   range:selectedTextRange];
		
		[self.textField focus];
	});
}

- (void)insertItalicCharIntoTextBox:(id)sender
{
	XRPerformBlockSynchronouslyOnQueue(self.formattingQueue, ^{
		NSRange selectedTextRange = [self.textField selectedRange];
		
		_returnMethodOnBadRange
		
		[self.textField setIRCFormatterAttribute:IRCTextFormatterItalicEffect
									   value:@YES
									   range:selectedTextRange];
		
		[self.textField focus];
	});
}

- (void)insertUnderlineCharIntoTextBox:(id)sender
{
	XRPerformBlockSynchronouslyOnQueue(self.formattingQueue, ^{
		NSRange selectedTextRange = [self.textField selectedRange];
		
		_returnMethodOnBadRange
		
		[self.textField setIRCFormatterAttribute:IRCTextFormatterUnderlineEffect
									   value:@YES
									   range:selectedTextRange];
		
		[self.textField focus];
	});
}

- (void)insertForegroundColorCharIntoTextBox:(id)sender
{
	XRPerformBlockSynchronouslyOnQueue(self.formattingQueue, ^{
		NSRange selectedTextRange = [self.textField selectedRange];
		
		_returnMethodOnBadRange
		
		if ([sender tag] == _formattingMenuRainbowColorMenuItemTag)
		{
			if (selectedTextRange.length > IRCTextFormatterMaximumRainbowTextFormattingLength) {
				selectedTextRange.length = IRCTextFormatterMaximumRainbowTextFormattingLength;
			}
			
			UniChar charValue;
			
			NSRange charRange;
			
			NSUInteger colorChar         = 0;
			NSUInteger charCountIndex    = 0;
			NSUInteger rainbowArrayIndex = 0;
			
			NSArray *colorCodes = @[@"4", @"7", @"8", @"3", @"12", @"2", @"6"];
			
			while (1 == 1) {
				/* Break once we reach the selected range length. */
				if (charCountIndex >= selectedTextRange.length) {
					break;
				}
				
				/* Range to apply to. */
				charRange = NSMakeRange((selectedTextRange.location + charCountIndex), 1);
				
				/* Character at that range. */
				charValue = [[self.textField stringValue] characterAtIndex:charCountIndex];
				
				/* Reset rainbow index. */
				if (rainbowArrayIndex > 6) {
					rainbowArrayIndex = 0;
				}
				
				/* Apply based on character. */
				if (charValue == ' ') {
					[self.textField setIRCFormatterAttribute:IRCTextFormatterForegroundColorEffect
												   value:@(0)
												   range:charRange];
				} else {
					colorChar = [colorCodes integerAtIndex:rainbowArrayIndex];
					
					[self.textField setIRCFormatterAttribute:IRCTextFormatterForegroundColorEffect
												   value:@(colorChar)
												   range:charRange];
				}
				
				/* Bump count. */
				charCountIndex += 1;
				
				rainbowArrayIndex += 1;
			}
		}
		else
		{
			[self.textField setIRCFormatterAttribute:IRCTextFormatterForegroundColorEffect
										   value:@([sender tag])
										   range:selectedTextRange];
		}
		
		[self.textField focus];
	});
}

- (void)insertBackgroundColorCharIntoTextBox:(id)sender
{
	XRPerformBlockSynchronouslyOnQueue(self.formattingQueue, ^{
		NSRange selectedTextRange = [self.textField selectedRange];
		
		_returnMethodOnBadRange
		
		if ([sender tag] == _formattingMenuRainbowColorMenuItemTag)
		{
			if (selectedTextRange.length > IRCTextFormatterMaximumRainbowTextFormattingLength) {
				selectedTextRange.length = IRCTextFormatterMaximumRainbowTextFormattingLength;
			}
			
			NSRange charRange;
			
			NSUInteger colorChar         = 0;
			NSUInteger charCountIndex    = 0;
			NSUInteger rainbowArrayIndex = 0;
			
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
				
				[self.textField setIRCFormatterAttribute:IRCTextFormatterBackgroundColorEffect
											   value:@(colorChar)
											   range:charRange];
				
				/* Bump numbers. */
				charCountIndex += 1;
				
				rainbowArrayIndex += 1;
			}
		}
		else
		{
			[self.textField setIRCFormatterAttribute:IRCTextFormatterBackgroundColorEffect
										   value:@([sender tag])
										   range:selectedTextRange];
		}
		
		[self.textField focus];
	});
}

#pragma mark -
#pragma mark Remove Formatting

- (void)removeBoldCharFromTextBox:(id)sender
{
	XRPerformBlockSynchronouslyOnQueue(self.formattingQueue, ^{
		NSRange selectedTextRange = [self.textField selectedRange];
		
		_returnMethodOnBadRange
		
		[self.textField removeIRCFormatterAttribute:IRCTextFormatterBoldEffect
										  range:selectedTextRange
										  color:[self.textField preferredFontColor]];
		
		[self.textField focus];
	});
}

- (void)removeItalicCharFromTextBox:(id)sender
{
	XRPerformBlockSynchronouslyOnQueue(self.formattingQueue, ^{
		NSRange selectedTextRange = [self.textField selectedRange];
		
		_returnMethodOnBadRange
		
		[self.textField removeIRCFormatterAttribute:IRCTextFormatterItalicEffect
										  range:selectedTextRange
										  color:[self.textField preferredFontColor]];
		
		[self.textField focus];
	});
}

- (void)removeUnderlineCharFromTextBox:(id)sender
{
	XRPerformBlockSynchronouslyOnQueue(self.formattingQueue, ^{
		NSRange selectedTextRange = [self.textField selectedRange];
		
		_returnMethodOnBadRange
		
		[self.textField removeIRCFormatterAttribute:IRCTextFormatterUnderlineEffect
										  range:selectedTextRange
										  color:[self.textField preferredFontColor]];
		
		[self.textField focus];
	});
}

- (void)removeForegroundColorCharFromTextBox:(id)sender
{
	XRPerformBlockSynchronouslyOnQueue(self.formattingQueue, ^{
		NSRange selectedTextRange = [self.textField selectedRange];
		
		_returnMethodOnBadRange
		
		[self.textField removeIRCFormatterAttribute:IRCTextFormatterForegroundColorEffect
										  range:selectedTextRange
										  color:[self.textField preferredFontColor]];
		
		[self.textField focus];
	});
}

- (void)removeBackgroundColorCharFromTextBox:(id)sender
{
	XRPerformBlockSynchronouslyOnQueue(self.formattingQueue, ^{
		NSRange selectedTextRange = [self.textField selectedRange];
		
		_returnMethodOnBadRange	
		
		[self.textField removeIRCFormatterAttribute:IRCTextFormatterBackgroundColorEffect
										  range:selectedTextRange
										  color:[self.textField preferredFontColor]];
		
		[self.textField focus];
	});
}

@end
