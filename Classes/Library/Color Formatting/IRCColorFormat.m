/* ********************************************************************* 
                  _____         _               _
                 |_   _|____  _| |_ _   _  __ _| |
                   | |/ _ \ \/ / __| | | |/ _` | |
                   | |  __/>  <| |_| |_| | (_| | |
                   |_|\___/_/\_\\__|\__,_|\__,_|_|

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

#import "TVCLogRenderer.h"
#import "IRC.h"
#import "IRCClientConfig.h"
#import "IRCClient.h"
#import "IRCChannel.h"
#import "IRCColorFormatPrivate.h"

NS_ASSUME_NONNULL_BEGIN

NSString * const IRCTextFormatterBoldAttributeName = @"IRCTextFormatterBoldAttributeName";
NSString * const IRCTextFormatterItalicAttributeName = @"IRCTextFormatterItalicAttributeName";
NSString * const IRCTextFormatterMonospaceAttributeName = @"IRCTextFormatterMonospaceAttributeName";
NSString * const IRCTextFormatterStrikethroughAttributeName = @"IRCTextFormatterStrikethroughAttributeName";
NSString * const IRCTextFormatterUnderlineAttributeName = @"IRCTextFormatterUnderlineAttributeName";
NSString * const IRCTextFormatterForegroundColorAttributeName = @"IRCTextFormatterForegroundColorAttributeName";
NSString * const IRCTextFormatterBackgroundColorAttributeName = @"IRCTextFormatterBackgroundColorAttributeName";

@implementation NSAttributedString (IRCTextFormatterPrivate)

#pragma mark -
#pragma mark Text Truncation

+ (void)IRCColorComponentsInAttributes:(NSDictionary<NSString *, id> *)attributes
					  controlCharacter:(UniChar *)controlCharacter
					   foregroundColor:(NSString **)foregroundColor
					   backgroundColor:(NSString **)backgroundColor
{
	NSParameterAssert(attributes != nil);

	/* Color hex */
	id foregroundColorValue = attributes[IRCTextFormatterForegroundColorAttributeName];
	id backgroundColorValue = attributes[IRCTextFormatterBackgroundColorAttributeName];

	if ([foregroundColorValue isKindOfClass:[NSColor class]]) {
		*controlCharacter = IRCTextFormatterColorAsHexEffectCharacter;

		*foregroundColor = [[foregroundColorValue hexadecimalValue] substringFromIndex:1]; // Remove leading #

		if ([backgroundColorValue isKindOfClass:[NSColor class]]) {
			*backgroundColor = [[backgroundColorValue hexadecimalValue] substringFromIndex:1]; // Remove leading #
		}

		return;
	}

	/* Color digits */
	if ([foregroundColorValue isKindOfClass:[NSNumber class]]) {
		*controlCharacter = IRCTextFormatterColorAsDigitEffectCharacter;

		*foregroundColor = [foregroundColorValue integerStringValueWithLeadingZero];

		if ([backgroundColorValue isKindOfClass:[NSNumber class]]) {
			*backgroundColor = [backgroundColorValue integerStringValueWithLeadingZero];
		}
	}
}

+ (NSString *)attributedStringToASCIIFormatting:(NSMutableAttributedString **)textToFormat inChannel:(IRCChannel *)channel onClient:(IRCClient *)client withLineType:(TVCLogLineType)lineType
{
	NSParameterAssert(textToFormat != nil);

	/* ///////////////////////////////////////////////////// */
	/*
	 Server level truncation does not count the total number of
	 characters in the received message alone. It also accounts for
	 everything that precedes it including the hostmask, channel name,
	 and any other commands.

	 Example: :<nickname>!<username>@<address> PRIVMSG #<channel> :<message>

	 The following math takes into account this information. The static
	 number of fourteen that we add to the math also accounts for the
	 PRIVMSG command, :, and additional spaces as part of the data we
	 are sending. We add an extra two as a buffer just to be safe.

	 This truncation engine also supports NOTICE and ACTION lines, but
	 that is it. Textual should only care about regular text.
	 */
	/* ///////////////////////////////////////////////////// */

#define	_textTruncationPRIVMSGCommandConstant				14
#define	_textTruncationACTIONCommandConstant				30
#define _textTruncationNOTICECommandConstant				14

#define _textTruncationHostmaskConstant						15 // Used if local user host is unknown

#define	_textTruncationSpacePositionMaxDifferential			10

	if (client == nil || channel == nil) {
		NSString *resultString = (*textToFormat).attributedStringToASCIIFormatting;

		[*textToFormat deleteCharactersInRange:(*textToFormat).range];

		return resultString;
	}

	/* Calculate the length of the channel name, the user's hostmask, 
	 and the command being sent part of this message. */
	NSString *channelName = channel.name;

	NSString *userHostmask = client.userHostmask;

	NSUInteger baseMath = channelName.length; // Start with the channel name's length

	if (userHostmask == nil) {
		baseMath += _textTruncationHostmaskConstant; // It's better to have something rather than nothing
	} else {
		baseMath += userHostmask.length;
	}

	if (lineType == TVCLogLinePrivateMessageType || lineType == TVCLogLinePrivateMessageNoHighlightType) {
		baseMath += _textTruncationPRIVMSGCommandConstant;
	} else if (lineType == TVCLogLineActionType || lineType == TVCLogLineActionNoHighlightType) {
		baseMath += _textTruncationACTIONCommandConstant;
	} else if (lineType == TVCLogLineNoticeType) {
		baseMath += _textTruncationNOTICECommandConstant;
	} else {
		return (*textToFormat).attributedStringToASCIIFormatting;
	}

	/* Begin computing the truncated string. */
	NSMutableAttributedString *base = [*textToFormat copy];

	NSMutableString *result = [NSMutableString string];

	/* Write out status. */
	NSUInteger totalCalculatedLength = baseMath;

	NSUInteger stringDeletionLength  = 0;

	NSUInteger maximumLength = TXMaximumIRCBodyLength;

#if TEXTUAL_BUILT_WITH_ADVANCED_ENCRYPTION == 1
	NSUInteger encryptionEstimate = [client lengthOfEncryptedMessageDirectedAt:channel.name thatFitsWithinBounds:(maximumLength - baseMath)];

	if (encryptionEstimate > 0) {
		maximumLength = encryptionEstimate;
	}
#endif

	/* Begin actual work. */
	NSUInteger startCharacterCount = 0;
	NSUInteger stopCharacterCount = 0;

	NSRange effectiveRange;

	NSRange limitRange = NSMakeRange(0, base.length);

	while (limitRange.length > 0) {
		BOOL breakLoopAfterAppend = NO;

		startCharacterCount = 0;
		stopCharacterCount = 0;

		/* ///////////////////////////////////////////////////// */
		/* Gather information about the attributes present and calculate the total
		 number of invisible characters necessary to support them. This count will
		 then be added into our math to determine the length of our string without
		 any formatting attached. */
		/* ///////////////////////////////////////////////////// */

		NSDictionary *attributes = [base attributesAtIndex:limitRange.location
									 longestEffectiveRange:&effectiveRange
												   inRange:limitRange];

		UniChar colorControlCharacter = 0;

		NSString *foregroundColor = nil;
		NSString *backgroundColor = nil;

		[NSAttributedString IRCColorComponentsInAttributes:attributes
										  controlCharacter:&colorControlCharacter
										   foregroundColor:&foregroundColor
										   backgroundColor:&backgroundColor];

		BOOL textIsBold = [attributes boolForKey:IRCTextFormatterBoldAttributeName];
		BOOL textIsItalicized = [attributes boolForKey:IRCTextFormatterItalicAttributeName];
		BOOL textIsMonospace = [attributes boolForKey:IRCTextFormatterMonospaceAttributeName];
		BOOL textIsStruckthrough = [attributes boolForKey:IRCTextFormatterStrikethroughAttributeName];
		BOOL textIsUnderlined = [attributes boolForKey:IRCTextFormatterUnderlineAttributeName];

		if (textIsBold) {
			startCharacterCount += 1; // control character
			stopCharacterCount += 1; // control character
		}

		if (textIsItalicized) {
			startCharacterCount += 1; // control character
			stopCharacterCount += 1; // control character
		}

		if (textIsMonospace) {
			startCharacterCount += 1; // control character
			stopCharacterCount += 1; // control character
		}

		if (textIsStruckthrough) {
			startCharacterCount += 1; // control character
			stopCharacterCount += 1; // control character
		}

		if (textIsUnderlined) {
			startCharacterCount += 1; // control character
			stopCharacterCount += 1; // control character
		}

		if (foregroundColor != nil) {
			startCharacterCount += (1 + foregroundColor.length); // control character plus value
			stopCharacterCount += 1; // control character
		}

		if (backgroundColor != nil) {
			startCharacterCount += (1 + backgroundColor.length); // comma character plus value
		}

		NSUInteger formattingCharacterCount = (startCharacterCount + stopCharacterCount);

		/* ///////////////////////////////////////////////////// */
		/* Now that we know the length of our message prefix and the total number
		 of characters required to support formatting we can start building up our
		 formatted string value containing our ASCII characters. */
		/* ///////////////////////////////////////////////////// */

		NSUInteger newLength = 0;

		/* At this point we do not care what the actaul length of this segment is.
		 The math below only checks two things. Whether the formatting characters
		 found above will fit into this segment as well as at least one unicode
		 character with a length of two. If neither of those can fit, then this
		 piece of formatted segment is junk and we can break from it. */

		/* If the starting location of our location is at 0, then we should not
		 have to worry about checking the length yet. Since the formatting
		 characters will occupy at maximum 13 entries at location 0, we can
		 do our append until the next, middle or end segment. */

		if (effectiveRange.location > 0) { // Length calculations for the middle of our string.
										   // Sally sold seashells down by the seashore.
										   //        |----------------------| <--- section we have to find

			newLength = (baseMath					+ // The base length. Beginning of string.
						 totalCalculatedLength		+ // Length of what we have already formatted.
						 formattingCharacterCount	+ // The formatting characters for this segment.
						 2);						  // The sad little two. A single unicode character.

			/* Will this new segment exceed the maximum size? */
			if (newLength > maximumLength) {
				break;
			}
		}

		/* Add the formatting characters to the final math before append. */
		totalCalculatedLength += formattingCharacterCount;

		/* Now is the point at which we begin to append. */
		/* Append the actual formatting. This uses the same technology used
		 in the above defined -attributedStringToASCIIFormatting method. */
		if (textIsUnderlined) {
			[result appendFormat:@"%c", IRCTextFormatterUnderlineEffectCharacter];
		}

		if (textIsStruckthrough) {
			[result appendFormat:@"%c", IRCTextFormatterStrikethroughEffectCharacter];
		}

		if (textIsMonospace) {
			[result appendFormat:@"%c", IRCTextFormatterMonospaceEffectCharacter];
		}

		if (textIsItalicized) {
			[result appendFormat:@"%c", IRCTextFormatterItalicEffectCharacter];
		}

		if (textIsBold) {
			[result appendFormat:@"%c", IRCTextFormatterBoldEffectCharacter];
		}

		if (foregroundColor != nil) {
			[result appendFormat:@"%c%@", colorControlCharacter, foregroundColor];

			if (backgroundColor != nil) {
				[result appendFormat:@",%@", backgroundColor];
			}
		}

		/* Okay, at this point we know two things. The the formatting characters above and below
		 the following append will fit within this segment plus at least one unicode character with
		 a length of two. Now here is where it gets tricky... we will go character by character in
		 our segment and append that. Any character below 0x7f will count against only one towards
		 the final result. Anything above it, is equal to two. We keep adding until the segment
		 is completed or we run out of space. At that point, we break. We have already added
		 the formatting characters into the math so any math checked against in the loop will
		 only be counted towards the actual characters. */

		for (NSUInteger i = 0; i < effectiveRange.length;) {
			NSUInteger characterIndex = (effectiveRange.location + i);

			NSRange characterRange = [base.string rangeOfComposedCharacterSequenceAtIndex:characterIndex];

			NSString *character = [base.string substringWithRange:characterRange];

			/* Update math */
			NSInteger characterSize = [character lengthOfBytesUsingEncoding:client.config.primaryEncoding];

			if (characterSize == 0) {
				characterSize = characterRange.length; // Just incase...
			}

			totalCalculatedLength += characterSize;

			/* Would this character go over the max body length? */
			if (totalCalculatedLength > maximumLength) {
				breakLoopAfterAppend = YES;

				/* Looking for spaces. */
				/* Now this is where the append gets a little technical. We want clean
				 truncation. Not half-assed ones. Therefore, if we have a space character
				 and it is within a certain range of the end of the line, then we will stop
				 append at that instead of breaking inside of a word. */
				NSUInteger minimumIndex = ((result.length - 1) - _textTruncationSpacePositionMaxDifferential);

				NSRange searchRange = NSMakeRange(minimumIndex, _textTruncationSpacePositionMaxDifferential);

				NSRange spaceRange = [result rangeOfCharacterFromSet:[NSCharacterSet whitespaceCharacterSet]
															 options:NSBackwardsSearch
															   range:searchRange];

				if (spaceRange.location != NSNotFound) {
					if (spaceRange.location < effectiveRange.location) {
						/* If the space is out of our segment, we don't want to use it. */
					} else {
						NSInteger indexDifference = (result.length - spaceRange.location);

						[result deleteCharactersInRange:NSMakeRange(spaceRange.location, indexDifference)];

						stringDeletionLength -= indexDifference;
					}
				}

				break; // Stop here if it goes out of bounds
			}

			/* Only update if we aren't at max */
			stringDeletionLength += characterRange.length;

			i += characterRange.length;

			/* Perform append */
			[result appendString:character];
		}

		if (foregroundColor != nil) {
			[result appendFormat:@"%c", colorControlCharacter];
		}

		if (textIsBold) {
			[result appendFormat:@"%c", IRCTextFormatterBoldEffectCharacter];
		}

		if (textIsItalicized) {
			[result appendFormat:@"%c", IRCTextFormatterItalicEffectCharacter];
		}

		if (textIsMonospace) {
			[result appendFormat:@"%c", IRCTextFormatterMonospaceEffectCharacter];
		}

		if (textIsStruckthrough) {
			[result appendFormat:@"%c", IRCTextFormatterStrikethroughEffectCharacter];
		}

		if (textIsUnderlined) {
			[result appendFormat:@"%c", IRCTextFormatterUnderlineEffectCharacter];
		}

		if (breakLoopAfterAppend) {
			break;
		}

		NSUInteger effectiveRangeNewLength = (base.length - stringDeletionLength);

		if (effectiveRangeNewLength <= 0) {
			break;
		}

		effectiveRange.location = stringDeletionLength;

		effectiveRange.length = effectiveRangeNewLength;

		limitRange = effectiveRange;
	}

	/* Return our attributed string to caller with our formatted line
	 so that the next one can be served up. */
	[*textToFormat deleteCharactersInRange:NSMakeRange(0, stringDeletionLength)];

#undef _textTruncationPRIVMSGCommandConstant
#undef _textTruncationACTIONCommandConstant
#undef _textTruncationNOTICECommandConstant

#undef _textTruncationHostmaskConstant

#undef _textTruncationSpacePositionMaxDifferential

	return result;
}

@end

#pragma mark -

@implementation NSAttributedString (IRCTextFormatter)

#pragma mark -
#pragma mark Text Truncation

- (NSString *)attributedStringToASCIIFormatting
{
	NSString *realBody = self.string;

	NSMutableString *result = [NSMutableString string];

	[self enumerateAttributesInRange:self.range
							 options:0
						  usingBlock:^(NSDictionary *attributes, NSRange effectiveRange, BOOL *stop)
	 {
		 UniChar colorControlCharacter = 0;

		 NSString *foregroundColor = nil;
		 NSString *backgroundColor = nil;

		 [NSAttributedString IRCColorComponentsInAttributes:attributes
										   controlCharacter:&colorControlCharacter
											foregroundColor:&foregroundColor
											backgroundColor:&backgroundColor];

		 BOOL textIsBold = [attributes boolForKey:IRCTextFormatterBoldAttributeName];
		 BOOL textIsItalicized = [attributes boolForKey:IRCTextFormatterItalicAttributeName];
		 BOOL textIsMonospace = [attributes boolForKey:IRCTextFormatterMonospaceAttributeName];
		 BOOL textIsStruckthrough = [attributes boolForKey:IRCTextFormatterStrikethroughAttributeName];
		 BOOL textIsUnderlined = [attributes boolForKey:IRCTextFormatterUnderlineAttributeName];

		 if (textIsUnderlined) {
			 [result appendFormat:@"%c", IRCTextFormatterUnderlineEffectCharacter];
		 }

		 if (textIsStruckthrough) {
			 [result appendFormat:@"%c", IRCTextFormatterStrikethroughEffectCharacter];
		 }

		 if (textIsMonospace) {
			 [result appendFormat:@"%c", IRCTextFormatterMonospaceEffectCharacter];
		 }

		 if (textIsItalicized) {
			 [result appendFormat:@"%c", IRCTextFormatterItalicEffectCharacter];
		 }

		 if (textIsBold) {
			 [result appendFormat:@"%c", IRCTextFormatterBoldEffectCharacter];
		 }

		 if (foregroundColor != nil) {
			 [result appendFormat:@"%c%@", colorControlCharacter, foregroundColor];

			 if (backgroundColor != nil) {
				 [result appendFormat:@",%@", backgroundColor];
			 }
		 }

		 [result appendString:[realBody substringWithRange:effectiveRange]];

		 if (foregroundColor != nil) {
			 [result appendFormat:@"%c", colorControlCharacter];
		 }

		 if (textIsBold) {
			 [result appendFormat:@"%c", IRCTextFormatterBoldEffectCharacter];
		 }

		 if (textIsItalicized) {
			 [result appendFormat:@"%c", IRCTextFormatterItalicEffectCharacter];
		 }

		 if (textIsMonospace) {
			 [result appendFormat:@"%c", IRCTextFormatterMonospaceEffectCharacter];
		 }

		 if (textIsStruckthrough) {
			 [result appendFormat:@"%c", IRCTextFormatterStrikethroughEffectCharacter];
		 }

		 if (textIsUnderlined) {
			 [result appendFormat:@"%c", IRCTextFormatterUnderlineEffectCharacter];
		 }
	 }];

	return result;
}

- (BOOL)IRCFormatterAttributeSetInRange:(IRCTextFormatterEffectType)effect
								  range:(NSRange)limitRange
{
	__block BOOL returnValue = NO;

	[self enumerateAttributesInRange:limitRange
							 options:0
						  usingBlock:^(NSDictionary *attributes, NSRange effectiveRange, BOOL *stop)
	 {
		 switch (effect) {
			 case IRCTextFormatterNoEffect:
			 {
					break;
			 }
			 case IRCTextFormatterBoldEffect:
			 {
				 if ([attributes boolForKey:IRCTextFormatterBoldAttributeName] == NO) {
					 return;
				 }

				 returnValue = YES;

				 *stop = YES;

				 break;
			 }
			 case IRCTextFormatterItalicEffect:
			 {
				 if ([attributes boolForKey:IRCTextFormatterItalicAttributeName] == NO) {
					 return;
				 }

				 returnValue = YES;

				 *stop = YES;

				 break;
			 }
			 case IRCTextFormatterMonospaceEffect:
			 {
				 if ([attributes boolForKey:IRCTextFormatterMonospaceAttributeName] == NO) {
					 return;
				 }

				 returnValue = YES;

				 *stop = YES;

				 break;
			 }
			 case IRCTextFormatterUnderlineEffect:
			 {
				 if ([attributes boolForKey:IRCTextFormatterUnderlineAttributeName] == NO) {
					 return;
				 }

				 returnValue = YES;

				 *stop = YES;

				 break;
			 }
			 case IRCTextFormatterStrikethroughEffect:
			 {
				 if ([attributes boolForKey:IRCTextFormatterStrikethroughAttributeName] == NO) {
					 return;
				 }

				 returnValue = YES;

				 *stop = YES;

				 break;
			 }
			 case IRCTextFormatterForegroundColorEffect:
			 {
				 id foregroundColor = attributes[IRCTextFormatterForegroundColorAttributeName];

				 if (foregroundColor == nil) {
					 return;
				 }

				 if ([foregroundColor isKindOfClass:[NSNumber class]])
				 {
					 NSInteger colorCode = [foregroundColor integerValue];

					 if (colorCode < 0 && colorCode > 15) {
						 return;
					 }
				 }
				 else if ([foregroundColor isKindOfClass:[NSColor class]] == NO)
				 {
					 return;
				 }

				 returnValue = YES;

				 *stop = YES;

				 break;
			 }
			 case IRCTextFormatterBackgroundColorEffect:
			 {
				 id backgroundColor = attributes[IRCTextFormatterBackgroundColorAttributeName];

				 if (backgroundColor == nil) {
					 return;
				 }

				 if ([backgroundColor isKindOfClass:[NSNumber class]])
				 {
					 NSInteger colorCode = [backgroundColor integerValue];

					 if (colorCode < 0 && colorCode > 15) {
						 return;
					 }
				 }
				 else if ([backgroundColor isKindOfClass:[NSColor class]] == NO)
				 {
					 return;
				 }

				 returnValue = YES;

				 *stop = YES;

				 break;
			 }
		 }
	 }];

	return returnValue;
}

@end

#pragma mark -
#pragma mark Adding/Removing Formatting

@implementation NSMutableAttributedString (IRCTextFormatter)

- (void)setIRCFormatterAttribute:(IRCTextFormatterEffectType)effect
						   value:(id)value
						   range:(NSRange)limitRange
{
	[self enumerateAttributesInRange:limitRange
							 options:NSAttributedStringEnumerationReverse
						  usingBlock:^(NSDictionary *attributes, NSRange effectiveRange, BOOL *stop)
	 {
		 NSFont *baseFont = attributes[NSFontAttributeName];

		 switch (effect) {
			 case IRCTextFormatterNoEffect:
			 {
					break;
			 }
			 case IRCTextFormatterBoldEffect:
			 {
				 if ([baseFont fontTraitSet:NSBoldFontMask] == NO) {
					 baseFont = [RZFontManager() convertFont:baseFont toHaveTrait:NSBoldFontMask];
				 }

				 if (baseFont) {
					 [self addAttribute:IRCTextFormatterBoldAttributeName value:@(YES) range:effectiveRange];

					 [self addAttribute:NSFontAttributeName value:baseFont range:effectiveRange];
				 }

				 break;
			 }
			 case IRCTextFormatterItalicEffect:
			 {
				 if ([baseFont fontTraitSet:NSItalicFontMask] == NO) {
					 baseFont = [RZFontManager() convertFont:baseFont toHaveTrait:NSItalicFontMask];
				 }

				 if (baseFont) {
					 [self addAttribute:IRCTextFormatterItalicAttributeName value:@(YES) range:effectiveRange];

					 [self addAttribute:NSFontAttributeName value:baseFont range:effectiveRange];
				 }

				 break;
			 }
			 case IRCTextFormatterMonospaceEffect:
			 {
				 baseFont = [RZFontManager() convertFont:baseFont toFamily:@"Menlo"];

				 [self addAttribute:IRCTextFormatterMonospaceAttributeName value:@(YES) range:effectiveRange];

				 [self addAttribute:NSFontAttributeName value:baseFont range:effectiveRange];

				 break;
			 }
			 case IRCTextFormatterUnderlineEffect:
			 {
				 [self addAttribute:IRCTextFormatterUnderlineAttributeName value:@(YES) range:effectiveRange];

				 [self addAttribute:NSUnderlineStyleAttributeName value:@(NSUnderlineStyleSingle) range:effectiveRange];

				 break;
			 }
			 case IRCTextFormatterStrikethroughEffect:
			 {
				 [self addAttribute:IRCTextFormatterStrikethroughAttributeName value:@(YES) range:effectiveRange];

				 [self addAttribute:NSStrikethroughStyleAttributeName value:@(NSUnderlineStyleSingle) range:effectiveRange];

				 break;
			 }
			 case IRCTextFormatterForegroundColorEffect:
			 {
				 if (value == nil) {
					 break;
				 }

				 if ([value isKindOfClass:[NSNumber class]])
				 {
					 NSInteger colorCode = [value integerValue];

					 if (colorCode >= 0 && colorCode <= 15) {
						 [self addAttribute:IRCTextFormatterForegroundColorAttributeName value:@(colorCode) range:effectiveRange];

						 [self addAttribute:NSForegroundColorAttributeName value:[TVCLogRenderer mapColorCode:colorCode] range:effectiveRange];
					 }
				 }
				 else if ([value isKindOfClass:[NSColor class]])
				 {
					 [self addAttribute:IRCTextFormatterForegroundColorAttributeName value:value range:effectiveRange];

					 [self addAttribute:NSForegroundColorAttributeName value:value range:effectiveRange];
				 }

				 break;
			 }
			 case IRCTextFormatterBackgroundColorEffect:
			 {
				 if (value == nil) {
					 break;
				 }

				 if ([value isKindOfClass:[NSNumber class]])
				 {
					 NSInteger colorCode = [value integerValue];

					 if (colorCode >= 0 && colorCode <= 15) {
						 [self addAttribute:IRCTextFormatterBackgroundColorAttributeName value:@(colorCode) range:effectiveRange];

						 [self addAttribute:NSBackgroundColorAttributeName value:[TVCLogRenderer mapColorCode:colorCode] range:effectiveRange];
					 }
				 }
				 else if ([value isKindOfClass:[NSColor class]])
				 {
					 [self addAttribute:IRCTextFormatterBackgroundColorAttributeName value:value range:effectiveRange];

					 [self addAttribute:NSBackgroundColorAttributeName value:value range:effectiveRange];
				 }

				 break;
			 }
		 }
	 }];
}

- (void)removeIRCFormatterAttribute:(IRCTextFormatterEffectType)effect
							  range:(NSRange)limitRange
{
	[self enumerateAttributesInRange:limitRange
							 options:NSAttributedStringEnumerationReverse
						  usingBlock:^(NSDictionary *attributes, NSRange effectiveRange, BOOL *stop)
	 {
		 NSFont *baseFont = attributes[NSFontAttributeName];

		 if (baseFont == nil) {
			 return;
		 }

		 switch (effect) {
			 case IRCTextFormatterNoEffect:
			 {
				 break;
			 }
			 case IRCTextFormatterBoldEffect:
			 {
				 if ([baseFont fontTraitSet:NSBoldFontMask]) {
					 baseFont = [RZFontManager() convertFont:baseFont toNotHaveTrait:NSBoldFontMask];

					 if (baseFont) {
						 [self addAttribute:NSFontAttributeName value:baseFont range:effectiveRange];
					 }

					 [self removeAttribute:IRCTextFormatterBoldAttributeName range:effectiveRange];
				 }

				 break;
			 }
			 case IRCTextFormatterItalicEffect:
			 {
				 if ([baseFont fontTraitSet:NSItalicFontMask]) {
					 baseFont = [RZFontManager() convertFont:baseFont toNotHaveTrait:NSItalicFontMask];

					 if (baseFont) {
						 [self addAttribute:NSFontAttributeName value:baseFont range:effectiveRange];
					 }

					 [self removeAttribute:IRCTextFormatterItalicAttributeName range:effectiveRange];
				 }

				 break;
			 }
			 case IRCTextFormatterMonospaceEffect:
			 {
				 [self removeAttribute:NSFontAttributeName range:effectiveRange];

				 [self removeAttribute:IRCTextFormatterMonospaceAttributeName range:effectiveRange];

				 break;
			 }
			 case IRCTextFormatterUnderlineEffect:
			 {
				 [self removeAttribute:NSUnderlineStyleAttributeName range:effectiveRange];

				 [self removeAttribute:IRCTextFormatterUnderlineAttributeName range:effectiveRange];

				 break;
			 }
			 case IRCTextFormatterStrikethroughEffect:
			 {
				 [self removeAttribute:NSStrikethroughStyleAttributeName range:effectiveRange];

				 [self removeAttribute:IRCTextFormatterStrikethroughAttributeName range:effectiveRange];

				 break;
			 }
			 case IRCTextFormatterForegroundColorEffect:
			 {
				 [self removeAttribute:NSBackgroundColorAttributeName range:effectiveRange];

				 [self removeAttribute:IRCTextFormatterForegroundColorAttributeName range:effectiveRange];

				 break;
			 }
			 case IRCTextFormatterBackgroundColorEffect:
			 {
				 [self removeAttribute:NSBackgroundColorAttributeName range:effectiveRange];

				 [self removeAttribute:IRCTextFormatterBackgroundColorAttributeName range:effectiveRange];

				 break;
			 }
		 }
	 }];
}

@end

NS_ASSUME_NONNULL_END
