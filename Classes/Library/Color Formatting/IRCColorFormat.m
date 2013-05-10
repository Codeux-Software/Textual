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

#define	_textTruncationPRIVMSGCommandConstant				14
#define	_textTruncationACTIONCommandConstant				8
#define	_textTruncationSpacePositionMaxDifferential			10

@implementation NSAttributedString (IRCTextFormatter)

#pragma mark -
#pragma mark Text Truncation

- (NSString *)attributedStringToASCIIFormatting
{
	NSString *realBody = self.string;
	
	NSMutableString *result = [NSMutableString string];
	
	NSRange effectiveRange;
	NSRange limitRange = NSMakeRange(0, [self length]);
	
	while (limitRange.length > 0) {
		NSDictionary *dict = [self safeAttributesAtIndex:limitRange.location longestEffectiveRange:&effectiveRange inRange:limitRange];

		NSInteger foregroundColor = [TVCLogRenderer mapColorValue:dict[NSForegroundColorAttributeName]];
		NSInteger backgroundColor = [TVCLogRenderer mapColorValue:dict[NSBackgroundColorAttributeName]];
        
        NSNumber *foregroundNumber = @(foregroundColor);
        NSNumber *backgroundNumber = @(backgroundColor);
		
		BOOL color = (foregroundColor >= 0 && foregroundColor <= 15);
        
        NSFont *baseFont = dict[NSFontAttributeName];
		
		BOOL boldText       = [baseFont fontTraitSet:NSBoldFontMask];
		BOOL italicText     = [baseFont fontTraitSet:NSItalicFontMask];
		BOOL underlineText  = ([dict integerForKey:NSUnderlineStyleAttributeName] == 1);
		
		if (underlineText)  { [result appendFormat:@"%c", 0x1F]; }
		if (italicText)     { [result appendFormat:@"%c", 0x16]; }
		if (boldText)       { [result appendFormat:@"%c", 0x02]; }
		
		if (color) {
			[result appendFormat:@"%c%@", 0x03, [foregroundNumber integerWithLeadingZero]];
			
			if (backgroundColor >= 0 && backgroundColor <= 15) {
				[result appendFormat:@",%@", [backgroundNumber integerWithLeadingZero]];
			}
		}
		
		[result appendString:[realBody safeSubstringWithRange:effectiveRange]];
		
		if (color)          { [result appendFormat:@"%c", 0x03]; }
		if (boldText)       { [result appendFormat:@"%c", 0x02]; }
		if (italicText)     { [result appendFormat:@"%c", 0x16]; }
		if (underlineText)  { [result appendFormat:@"%c", 0x1F]; }
		
		limitRange = NSMakeRange(NSMaxRange(effectiveRange), (NSMaxRange(limitRange) - NSMaxRange(effectiveRange)));
	}		
	
	return result;
}

- (NSString *)attributedStringToASCIIFormatting:(NSMutableAttributedString **)string 
                                       lineType:(TVCLogLineType)type 
                                        channel:(NSString *)chan 
                                       hostmask:(NSString *)host
{
    NSMutableAttributedString *base = [*string copy];
	
	NSMutableString *result = [NSMutableString string];
    
    NSInteger startCharCount = 0;
	NSInteger stopCharCount  = 0;
	
	/* ///////////////////////////////////////////////////// */
	/* 
	 Server level truncation does not count the total number of
	 characters in the received message alone. It also accounts for
	 everything that precedes it including the hostmask, channel name,
	 and any other commands.
	 
	 Example: :<nickname>!<username>@<host> PRIVMSG #<channel> :<message>
	 
	 The following math takes into account this information. The static
	 number of fourteen that we add to the math also accounts for the 
	 PRIVMSG command, :, and additional spaces as part of the data we 
	 are sending. We add an extra two as a buffer just to be safe.
	 
	 This method being called only is used for PRIVMSG so we do not have
	 to worry about anything else. That is, unless it is an action. In that
	 case, we simply add in a little more math. An ACTION accounts for eight 
	 additional characters occupied. This math also adds an additional one
	 character buffer same as the above mentioned math. 
	 */
	/* ///////////////////////////////////////////////////// */
	
    NSInteger baseMath = 0;
	
	baseMath += (chan.length + host.length);
	baseMath += _textTruncationPRIVMSGCommandConstant; 
	
	if (type == TVCLogLineActionType) {
		baseMath += _textTruncationACTIONCommandConstant;
	}
	
	NSInteger totalCalculatedLength = 0;
	NSInteger stringDeletionLength  = 0;
	
	NSRange effectiveRange;
	NSRange limitRange = NSMakeRange(0, base.string.length);
	
	while (limitRange.length > 0) {
		BOOL breakLoopAfterAppend = NO;
		
		totalCalculatedLength = 0;
		
		/* ///////////////////////////////////////////////////// */
		/* Gather information about the attributes present and calculate the total
		 number of invisible characters necessary to support them. This count will 
		 then be added into our math to determine the length of our string without
		 any formatting attached. */
		/* ///////////////////////////////////////////////////// */
		
		NSDictionary *dict = [base safeAttributesAtIndex:limitRange.location longestEffectiveRange:&effectiveRange inRange:limitRange];

		NSInteger foregroundColor = [TVCLogRenderer mapColorValue:dict[NSForegroundColorAttributeName]];
		NSInteger backgroundColor = [TVCLogRenderer mapColorValue:dict[NSBackgroundColorAttributeName]];

        NSNumber *foregroundNumber = @(foregroundColor);
        NSNumber *backgroundNumber = @(backgroundColor);
        
        NSFont *baseFont = dict[NSFontAttributeName];
		
		BOOL foregroundColorD = (foregroundColor >= 0 && foregroundColor <= 15);
        BOOL backgroundColorD = (backgroundColor >= 0 && backgroundColor <= 15);
		
		BOOL boldText       = [baseFont fontTraitSet:NSBoldFontMask];
		BOOL italicText     = [baseFont fontTraitSet:NSItalicFontMask];
		BOOL underlineText  = ([dict integerForKey:NSUnderlineStyleAttributeName] == 1);
		
        if (italicText)         { startCharCount += 1; stopCharCount += 1; }
        if (underlineText)      { startCharCount += 1; stopCharCount += 1; }
        if (underlineText)      { startCharCount += 1; stopCharCount += 1; }
        if (foregroundColorD)   { startCharCount += 3; stopCharCount += 1; }
        if (backgroundColorD)   { startCharCount += 3; }
		
		NSInteger formattingCharacterCount = (startCharCount + stopCharCount);
		
		/* ///////////////////////////////////////////////////// */
		/* Now that we know the length of our message prefix and the total number
		 of characters required to support formatting we can start building up our
		 formatted string value containing our ASCII characters. */
		/* ///////////////////////////////////////////////////// */
		
		NSString *cake = NSStringEmptyPlaceholder; // this variable name tells you a lot…
		
		NSInteger newLength = 0;
		
		/* Calculate our total length of our string minus any formatting. */
		if (effectiveRange.location == 0) { // Handle the legnth for the beginning of our string.
			newLength = (baseMath + effectiveRange.length + formattingCharacterCount);
			
			if (newLength >= TXMaximumIRCBodyLength) { 
				breakLoopAfterAppend = YES;
				
				newLength = (TXMaximumIRCBodyLength - (baseMath + formattingCharacterCount));
				
				totalCalculatedLength = newLength;
			} 
		} else { // Length calculations for the middle of our string.
			// Sally sold seashells down by the seashore.
			//        |----------------------| <--- section we have to find
			
			newLength = (stringDeletionLength		+		// Length of already parsed segments.
						 effectiveRange.length		+		// Our own length.
						 formattingCharacterCount	+		// Our formatting characters.
						 baseMath);							// Lastly, our base length.
			
			if (newLength >= TXMaximumIRCBodyLength) {
				newLength = (TXMaximumIRCBodyLength - (baseMath + formattingCharacterCount + stringDeletionLength));
				
				if (newLength <= 0) {
					/* If our new length would reduce our substringed cake to nothing,
					 then we simply break the loop because there is nothing more we 
					 can do at this point. */
					
					break;
				}
				
				totalCalculatedLength = newLength;
				
				breakLoopAfterAppend = YES;
			} 
		}
		
		/* If our calculated string length is still nil, then just
		 assume we did not have to make any calculations to fix it
		 within the context of our maximum message length limit. 
		 There is no other way it would be nil as we would have 
		 broken the loop for any errors that might have happened
		 prior to reaching this point. */
		
		if (totalCalculatedLength == 0) { 
			totalCalculatedLength = effectiveRange.length;
		}
		
		/* See? "cake" was a poor variable name for us. You would have never
		 guessed it was going to be assigned to the substringed value. */
		cake = [base.string safeSubstringWithRange:NSMakeRange(effectiveRange.location, totalCalculatedLength)];
		
		//DebugLogToConsole(@"cake: %@\nLength: %i", cake, totalCalculatedLength);
		
		/* Truncate at first available space as long as it is within range. */
		if (breakLoopAfterAppend && cake.length >= _textTruncationSpacePositionMaxDifferential) {
			NSRange spaceCharSearchBase = NSMakeRange((cake.length - _textTruncationSpacePositionMaxDifferential),
																	 _textTruncationSpacePositionMaxDifferential);
			
			NSRange spaceChar = [cake rangeOfCharacterFromSet:[NSCharacterSet whitespaceCharacterSet]
													  options:NSBackwardsSearch
														range:spaceCharSearchBase];
			
			//DebugLogToConsole(@"spaceCharacter: %@", NSStringFromRange(spaceChar));
			
			if (NSDissimilarObjects(spaceChar.location, NSNotFound)) {
				totalCalculatedLength = spaceChar.location;
				
				cake = [base.string safeSubstringWithRange:NSMakeRange(effectiveRange.location, totalCalculatedLength)];

				//DebugLogToConsole(@"newCake: %@\nLength: %i", cake, totalCalculatedLength);
			}
		}
		
		/* Append the actual formatting. This uses the same technology used
		 in the above defined -attributedStringToASCIIFormatting method. */
		if (underlineText)  { [result appendFormat:@"%c", 0x1F]; }
		if (italicText)     { [result appendFormat:@"%c", 0x16]; }
		if (boldText)       { [result appendFormat:@"%c", 0x02]; }
		
		if (foregroundColorD) {
			[result appendFormat:@"%c%@", 0x03, [foregroundNumber integerWithLeadingZero]];
			
			if (backgroundColorD) {
				[result appendFormat:@",%@", [backgroundNumber integerWithLeadingZero]];
			}
		}
		
		[result appendString:cake];
		
		if (foregroundColorD)   { [result appendFormat:@"%c", 0x03]; }
		if (boldText)           { [result appendFormat:@"%c", 0x02]; }
		if (italicText)         { [result appendFormat:@"%c", 0x16]; }
		if (underlineText)      { [result appendFormat:@"%c", 0x1F]; }
		
		/* Skip to next attributed section if we have not broken out of the loop by now. */
		stringDeletionLength += totalCalculatedLength;
		
		if (breakLoopAfterAppend) {
			break;
		}
		
		effectiveRange.location += totalCalculatedLength;
		effectiveRange.length    = (base.string.length - stringDeletionLength);
		
		//DebugLogToConsole(@"effectiveRange: %@", NSStringFromRange(effectiveRange));
		
		limitRange = effectiveRange;
	}
	
	/* Return our attributed string to caller with our formatted line
	 so that the next one can be served up. */
	
    [*string deleteCharactersInRange:NSMakeRange(0, stringDeletionLength)];
	
	//DebugLogToConsole(@"string: %@\nresult: %@\nrange: 0, %i", [*string string], result, stringDeletionLength);
	
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
				
				return result;
				
				break;
			}
			case IRCTextFormatterForegroundColorEffect:
			{
				NSColor *foregroundColor = dict[NSForegroundColorAttributeName];

				/* We compare the white value of our foreground color to that of
				 our text field so that we do not say we have a color when it is
				 only the color of the text field itself. */
				
                if (PointerIsNotEmpty(foregroundColor)) {
					NSColor *defaultColor = TXDefaultTextFieldFontColor;
					NSColor *compareColor = [foregroundColor colorUsingColorSpace:[NSColorSpace genericGrayColorSpace]];
					
					CGFloat defaultWhite = [defaultColor whiteComponent];
					CGFloat compareWhite = [compareColor whiteComponent];
					
					if (TXDirtyCGFloatMatch(defaultWhite, compareWhite)) {
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
            default: { return NO; break; }
		}
		
		limitRange = NSMakeRange(NSMaxRange(effectiveRange), (NSMaxRange(limitRange) - NSMaxRange(effectiveRange)));
	}
	
	return NO;
}

#pragma mark -
#pragma mark Pasted String Sanitization

- (void)sanitizeIRCCompatibleAttributedString:(BOOL)clearAttributes
{
	if (clearAttributes) {
		NSDictionary *attributes = @{
			NSFontAttributeName				: TXDefaultTextFieldFont,
			NSForegroundColorAttributeName	: TXDefaultTextFieldFontColor,
		};

		[self setTypingAttributes:attributes];
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
                    baseFont = [RZFontManager() convertFont:baseFont toHaveTrait:NSBoldFontMask];
                }
                
                if (baseFont) {
                    newDict[NSFontAttributeName] = baseFont;
                }
                
                break;
            }
            case IRCTextFormatterItalicEffect:
            {
                if ([baseFont fontTraitSet:NSItalicFontMask] == NO) {
                    baseFont = [RZFontManager() convertFont:baseFont toHaveTrait:NSItalicFontMask];
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
                    newDict[NSForegroundColorAttributeName] = [TVCLogRenderer mapColorCode:colorCode];
                }
                
                break;
            }
            case IRCTextFormatterBackgroundColorEffect:
            {
                NSInteger colorCode = [value integerValue];
                
                if (colorCode >= 0 && colorCode <= 15) {
                    newDict[NSBackgroundColorAttributeName] = [TVCLogRenderer mapColorCode:colorCode];
                }
                
                break;
            }
            default: { break; }
        }

		[self addUndoActionForAttributes:dict inRange:effectiveRange];
		
        [self setAttributes:newDict inRange:effectiveRange];
		
		limitRange = NSMakeRange(NSMaxRange(effectiveRange), (NSMaxRange(limitRange) - NSMaxRange(effectiveRange)));
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
						baseFont = [RZFontManager() convertFont:baseFont toNotHaveTrait:NSBoldFontMask];
					
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
						baseFont = [RZFontManager() convertFont:baseFont toNotHaveTrait:NSItalicFontMask];
						
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

		[self addUndoActionForAttributes:dict inRange:effectiveRange];
		
		limitRange = NSMakeRange(NSMaxRange(effectiveRange), (NSMaxRange(limitRange) - NSMaxRange(effectiveRange)));
	}
}

@end
