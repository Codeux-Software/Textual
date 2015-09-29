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

#define _useStrictHostmaskUsernameTypeChecking		0

NSStringEncoding const TXDefaultPrimaryStringEncoding		= NSUTF8StringEncoding;
NSStringEncoding const TXDefaultFallbackStringEncoding		= NSISOLatin1StringEncoding;

@implementation NSString (TXStringHelper)

- (BOOL)isValidInternetAddress
{
	if (NSObjectIsEmpty(self)) {
		return NO;
	}

	if (NSObjectsAreEqual(self, @"localhost")) {
		return YES;
	}

	if ([self isIPAddress]) {
		return YES;
	}

	BOOL performExtendedValidation = [RZUserDefaults() boolForKey:@"-[NSString isValidInternetAddress] Performs Extended Validation"];

	if (performExtendedValidation) {
		static NSCharacterSet *_validationCharacterSet = nil;

		if (_validationCharacterSet == nil) {
			NSMutableCharacterSet *alphaNumericCharacterSet = [[NSCharacterSet alphanumericCharacterSet] mutableCopy];

			[alphaNumericCharacterSet addCharactersInString:@".-"];

			[alphaNumericCharacterSet invert];

			_validationCharacterSet = [alphaNumericCharacterSet copy];
		}

		if ([self onlyContainsCharactersFromCharacterSet:_validationCharacterSet] == NO) {
			return NO;
		}
	}

	return YES;
}

- (NSString *)stringByAppendingIRCFormattingStop
{
	return [self stringByAppendingFormat:@"%C", IRCTextFormatterTerminatingCharacter];
}

- (BOOL)hostmaskComponents:(NSString *__autoreleasing *)nickname username:(NSString *__autoreleasing *)username address:(NSString *__autoreleasing *)address
{
	/* Gather basic information. */

	/* Find first ! starting from left side of string. */
	NSRange bang1pos = [self rangeOfString:@"!" options:0];

	/* Find first @ starting from the right side of string. */
	NSRange bang2pos = [self rangeOfString:@"@" options:NSBackwardsSearch];

	NSAssertReturnR((bang1pos.location != NSNotFound), NO);
	NSAssertReturnR((bang2pos.location != NSNotFound), NO);
	NSAssertReturnR((bang2pos.location > bang1pos.location), NO);

	/* Bind sections of the host. */
	NSString *nicknameInt = [self substringToIndex:bang1pos.location];

	NSString *usernameInt = [self substringWithRange:NSMakeRange((bang1pos.location + 1),
																 (bang2pos.location - (bang1pos.location + 1)))];

	NSString *addressInt = [self substringAfterIndex:bang2pos.location];
	
	/* Perform basic validation. */
	NSAssertReturnR([nicknameInt isHostmaskNickname], NO);
	NSAssertReturnR([usernameInt isHostmaskUsername], NO);
	NSAssertReturnR([nicknameInt isHostmaskAddress], NO);

	/* The host checks out so far, so define the output. */
	if (NSDissimilarObjects(nickname, NULL)) {
		*nickname = nicknameInt;
	}

	if (NSDissimilarObjects(username, NULL)) {
		*username = usernameInt;
	}

	if (NSDissimilarObjects(address, NULL)) {
		*address = addressInt;
	}

	return YES;
}

- (BOOL)isHostmask
{
	return [self hostmaskComponents:nil username:nil address:nil];
}

- (BOOL)isHostmaskAddress
{
	return ([self length] > 0 && [self containsCharacters:@"\x021\x040\x000\x020\x00d\x00a"] == NO);
}

- (BOOL)isHostmaskUsername
{
#if _useStrictHostmaskUsernameTypeChecking == 1
	NSString *bob = self;

	if ([bob hasPrefix:@"~"]) {
		bob = [bob substringFromIndex:1];
	}

	static NSCharacterSet *_badChars = nil;

	if (_badChars == nil) {
		NSMutableCharacterSet *characters = [NSMutableCharacterSet characterSetWithRange:NSMakeRange(1, 127)];

		[characters removeCharactersInRange:NSMakeRange(32, 1)]; // Remove SPACE
		[characters removeCharactersInRange:NSMakeRange(13, 1)]; // Remove CR
		[characters removeCharactersInRange:NSMakeRange(10, 1)]; // Remove LF
		
		[characters invert];

		_badChars = [characters copy];
	}

	NSRange rr = [bob rangeOfCharacterFromSet:_badChars];

	if (NSDissimilarObjects(rr.location, NSNotFound)) {
		return NO;
	}
#else
	return ([self length] > 0 &&
			[self length] <= TXMaximumIRCUsernameLength &&
			[self containsCharacters:@"\x000\x020\x00d\x00a"] == NO);
#endif
}

- (BOOL)isHostmaskNickname
{
	return ([self isNotEqualTo:@"*"] &&
			[self length] > 0 &&
			[self length] <= TXMaximumIRCNicknameLength &&
			[self containsCharacters:@"\x021\x040\x000\x020\x00d\x00a"] == NO);
}

- (BOOL)isNickname
{
	return [self isHostmaskNickname];
}

- (BOOL)isChannelName:(IRCClient *)client
{
	NSObjectIsEmptyAssertReturn(self, NO);
	
	if (client == nil) {
		return [self isChannelName];
	}

	NSString *validChars = [[client supportInfo] channelNamePrefixes];

	if ([self length] == 1) {
		NSString *c = [self stringCharacterAtIndex:0];

		return [c onlyContainsCharacters:validChars];
	} else {
		NSString *c1 = [self stringCharacterAtIndex:0];
		NSString *c2 = [self stringCharacterAtIndex:1];
		
		/* The ~ prefix is considered special. It is used by the ZNC partyline plugin. */
		BOOL isPartyline = ([c1 isEqualToString:@"~"] && [c2 isEqualToString:@"#"]);

		return ([c1 onlyContainsCharacters:validChars] || isPartyline);
	}
}

- (BOOL)isChannelName
{
	NSObjectIsEmptyAssertReturn(self, NO);

	UniChar c = [self characterAtIndex:0];

	return (c == '#' ||
		    c == '&' ||
		    c == '+' ||
		    c == '!' ||
		    c == '~' ||
			c == '?');
}

- (BOOL)isModeChannelName
{
	NSObjectIsEmptyAssertReturn(self, NO);

	UniChar c = [self characterAtIndex:0];

	return (c == '#' ||
		    c == '&' ||
		    c == '!' ||
		    c == '~' ||
		    c == '?');
}

- (NSString *)channelNameToken
{
	/* Remove any prefix from in front of channel (e.g. #) or return
	 an untouched copy of the string if there is none. */

	if ([self isChannelName] && [self length] > 1) {
		return [self substringFromIndex:1];
	}

	return self;
}

- (NSString *)channelNameTokenByTrimmingAllPrefixes:(IRCClient *)client
{
	NSObjectIsEmptyAssertReturn(self, nil);
	
	if (client == nil) {
		return [self channelNameToken];
	}
	
	NSString *prefixes = [[client supportInfo] channelNamePrefixes];
	
	NSCharacterSet *validChars = [NSCharacterSet characterSetWithCharactersInString:prefixes];
	
	return [self stringByTrimmingCharactersInSet:validChars];
}

- (NSString *)nicknameFromHostmask
{
	NSString *nickname = nil;

	if ([self hostmaskComponents:&nickname username:nil address:nil]) {
		return nickname;
	} else {
		return self;
	}

	return nil;
}

- (NSString *)usernameFromHostmask
{
	NSString *username = nil;

	if ([self hostmaskComponents:nil username:&username address:nil]) {
		return username;
	}

	return nil;
}

- (NSString *)addressFromHostmask
{
	NSString *address = nil;

	if ([self hostmaskComponents:nil username:nil address:&address]) {
		return address;
	}

	return nil;
}

- (NSString *)stringWithValidURIScheme
{
	return [AHHyperlinkScanner URLWithProperScheme:self];
}

- (id)attributedStringWithIRCFormatting:(NSFont *)preferredFont preferredFontColor:(NSColor *)preferredFontColor honorFormattingPreference:(BOOL)formattingPreference
{
	if (formattingPreference) {
		if ([TPCPreferences removeAllFormatting]) {
			return [self stripIRCEffects];
		}
	}

	NSMutableDictionary *attributes = [NSMutableDictionary dictionary];

	if (preferredFont) {
		attributes[TVCLogRendererConfigurationAttributedStringPreferredFontAttribute] = preferredFont;
	}

	if (preferredFontColor) {
		attributes[TVCLogRendererConfigurationAttributedStringPreferredFontColorAttribute] = preferredFontColor;
	}

	return [TVCLogRenderer renderBodyIntoAttributedString:self withAttributes:attributes];
}

- (id)attributedStringWithIRCFormatting:(NSFont *)preferredFont preferredFontColor:(NSColor *)preferredFontColor
{
	return [self attributedStringWithIRCFormatting:preferredFont preferredFontColor:preferredFontColor honorFormattingPreference:NO];
}

- (NSString *)stripIRCEffects
{
	NSObjectIsEmptyAssertReturn(self, nil);

	NSInteger pos = 0;
	NSInteger len = [self length];
	
	NSInteger buflen = (len * sizeof(UniChar));
	
	UniChar *src = alloca(buflen);
	UniChar *buf = alloca(buflen);
	
	[self getCharacters:src range:NSMakeRange(0, len)];
	
	for (NSInteger i = 0; i < len; ++i) {
		unichar c = src[i];
		
		if (c < 0x20) {
			switch (c) {
				case IRCTextFormatterBoldEffectCharacter:
				case 0x16: // Old character used for italic text
				case IRCTextFormatterItalicEffectCharacter:
				case IRCTextFormatterStrikethroughEffectCharacter:
				case IRCTextFormatterUnderlineEffectCharacter:
				case IRCTextFormatterTerminatingCharacter:
				{
					break;
				}
				case IRCTextFormatterColorEffectCharacter:
				{
					if ((i + 1) >= len) {
						continue;
					}

					UniChar d = src[(i + 1)];
					
					if (CSCEF_StringIsBase10Numeric(d) == NO) {
						continue;
					}
					
					i++;

					// ---- //
					
					if ((i + 1) >= len) {
						continue;
					}

					UniChar e = src[(i + 1)];
					
					if (CSCEF_StringIsBase10Numeric(e) == NO && NSDissimilarObjects(e, ',')) {
						continue;
					}
					
					i++;

					// ---- //
					
					if ((e == ',') == NO) {
						if ((i + 1) >= len) {
							continue;
						}
						
						UniChar f = src[(i + 1)];
						
						if (NSDissimilarObjects(f, ',')) {
							continue;
						}
						
						i++;
					}

					// ---- //

					if ((i + 1) >= len) {
						continue;
					}

					UniChar g = src[(i + 1)];

					if (CSCEF_StringIsBase10Numeric(g) == NO) {
						i--;
						
						continue;
					}
					
					i++;

					// ---- //

					if ((i + 1) >= len) {
						continue;
					}

					UniChar h = src[(i + 1)];

					if (CSCEF_StringIsBase10Numeric(h) == NO) {
						continue;
					}
					
					i++;

					// ---- //
					
					break;
				}
				default:
				{
					buf[pos++] = c;
					
					break;
				}
			}
		} else {
			buf[pos++] = c;
		}
	}
	
	return [NSString stringWithCharacters:buf length:pos];
}

- (NSString *)base64EncodingWithLineLength:(NSUInteger)lineLength
{
	NSData *baseData = [self dataUsingEncoding:NSUTF8StringEncoding];
	
	NSString *encodedResult = [XRBase64Encoding encodeData:baseData];
	
	NSObjectIsEmptyAssertReturn(encodedResult, nil);
	
	NSMutableString *resultString = [NSMutableString string];
	
	if ([encodedResult length] > lineLength) {
		NSInteger rlc = ceil([encodedResult length] / lineLength);

		for (NSInteger i = 1; i <= rlc; i++) {
			NSString *append = [encodedResult substringToIndex:lineLength];

			[resultString appendString:append];
			[resultString appendString:NSStringNewlinePlaceholder];

			encodedResult = [encodedResult substringFromIndex:lineLength];
		}
	}
	
	[resultString appendString:encodedResult];

	return resultString;
}

@end
