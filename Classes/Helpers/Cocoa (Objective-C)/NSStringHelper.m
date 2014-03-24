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

//
// This source file contains work that originated
// from the following authors:
//
//  Modified by Michael Bianco on 12/2/11.
//	<http://mabblog.com>
//
//  Created by Rick Bourner on Sat Aug 09 2003.
//  rick@bourner.com
//
// In reference to the source code for the call -compareWithWord:matchGain:missingCost:
// Originating URL: <https://gist.github.com/iloveitaly/1515464>
//
// =======================================================
//
// Created by Saurabh Sharma on May 3, 2011
//
// In reference to the source code for the call -sha1
// Originating URL: <http://www.makebetterthings.com/iphone/how-to-get-md5-and-sha1-in-objective-c-ios-sdk/>
//

#import "TextualApplication.h"

#import <CommonCrypto/CommonDigest.h>

#include <arpa/inet.h>

@implementation NSString (TXStringHelper)

/* Helper Methods */
+ (id)stringWithBytes:(const void *)bytes length:(NSUInteger)length encoding:(NSStringEncoding)encoding
{
	return [[NSString alloc] initWithBytes:bytes length:length encoding:encoding];
}

+ (id)stringWithData:(NSData *)data encoding:(NSStringEncoding)encoding
{
	return [[NSString alloc] initWithData:data encoding:encoding];
}

+ (NSString *)stringWithUUID
{
	CFUUIDRef uuidObj = CFUUIDCreate(nil);
	
	NSString *uuidString = (__bridge_transfer NSString *)CFUUIDCreateString(nil, uuidObj);
	
	CFRelease(uuidObj);

	return uuidString;
}

+ (NSString *)charsetRepFromStringEncoding:(NSStringEncoding)encoding
{
	CFStringEncoding cfencoding = CFStringConvertNSStringEncodingToEncoding(encoding);

	CFStringRef charsetStr = CFStringConvertEncodingToIANACharSetName(cfencoding);

	return (__bridge NSString *)(charsetStr);
}

+ (NSDictionary *)supportedStringEncodingsWithTitle:(BOOL)favorUTF8
{
    NSMutableDictionary *encodingList = [NSMutableDictionary dictionary];

    NSArray *supportedEncodings = [NSString supportedStringEncodings:favorUTF8];

    for (id encoding in supportedEncodings) {
        NSString *encodingTitle = [NSString localizedNameOfStringEncoding:[encoding integerValue]];

		if (encodingTitle) {
			encodingList[encodingTitle] = encoding;
		}
    }

    return encodingList;
}

+ (NSArray *)supportedStringEncodings:(BOOL)favorUTF8
{
    NSMutableArray *encodingList = [NSMutableArray array];

    const NSStringEncoding *encodings = [NSString availableStringEncodings];

    if (favorUTF8) {
        [encodingList safeAddObject:@(NSUTF8StringEncoding)];
    }

    while (1 == 1) {
        NSStringEncoding encoding = (*encodings++);

        if (encoding == 0) {
            break;
        }

        if (favorUTF8 && encoding == NSUTF8StringEncoding) {
            continue;
        }
		
		[encodingList addObject:@(encoding)];
    }

    return encodingList;
}

- (NSString *)safeSubstringWithRange:(NSRange)range
{
	if (NSRangeIsValidInBounds(range, [self length]) == NO) {
		return nil;
	}

	NSRange safeRange = [self rangeOfComposedCharacterSequencesForRange:range];
	
	return [self substringWithRange:safeRange];
}

- (NSString *)safeSubstringFromIndex:(NSInteger)anIndex
{
	if (anIndex > [self length] || anIndex < 0) {
		return nil;
	}

	NSRange cutRange = NSMakeRange(anIndex, ([self length] - anIndex));

	return [self safeSubstringWithRange:cutRange];
}

- (NSString *)safeSubstringToIndex:(NSInteger)anIndex
{
	if (anIndex > [self length] || anIndex < 0) {
		return nil;
	}

	NSRange cutRange = NSMakeRange(0, anIndex);

	return [self safeSubstringWithRange:cutRange];
}

- (UniChar)safeCharacterAtIndex:(NSInteger)anIndex
{
	if (anIndex > [self length] || anIndex < 0) {
		return 0;
	}

	return [self characterAtIndex:anIndex];
}

- (NSString *)stringCharacterAtIndex:(NSInteger)anIndex
{
	if (anIndex > [self length] || anIndex < 0) {
		return nil;
	}
	
	UniChar strChar = [self characterAtIndex:anIndex];

	return [NSString stringWithUniChar:strChar];
}

- (NSString *)substringAfterIndex:(NSInteger)anIndex
{
	return [self safeSubstringFromIndex:(anIndex + 1)];
}

- (NSString *)substringBeforeIndex:(NSInteger)anIndex
{
	return [self safeSubstringFromIndex:(anIndex - 1)];
}

- (BOOL)isEqualIgnoringCase:(NSString *)other
{
	return ([self caseInsensitiveCompare:other] == NSOrderedSame);
}

- (BOOL)contains:(NSString *)str
{
	return ([self stringPosition:str] >= 0);
}

- (BOOL)containsIgnoringCase:(NSString *)str
{
	return ([self stringPositionIgnoringCase:str] >= 0);
}

- (NSString *)sha1
{
    NSData *data = [self dataUsingEncoding:NSUTF8StringEncoding];
	
    uint8_t digest[CC_SHA1_DIGEST_LENGTH];
	
    CC_SHA1([data bytes], (CC_LONG)[data length], digest);
	
    NSMutableString *output = [NSMutableString stringWithCapacity:(CC_SHA1_DIGEST_LENGTH * 2)];
	
    for (int i = 0; i < CC_SHA1_DIGEST_LENGTH; i++) {
        [output appendFormat:@"%02x", digest[i]];
    }
	
    return output;
}

- (NSArray *)split:(NSString *)delimiter
{
	return [self componentsSeparatedByString:delimiter];
}

- (NSString *)trim
{
	return [self stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
}

- (NSString *)trimNewlines
{
	return [self stringByTrimmingCharactersInSet:[NSCharacterSet newlineCharacterSet]];
}

- (NSString *)trimCharacters:(NSString *)charset
{
	return [self stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:charset]];
}

- (NSString *)removeAllNewlines
{
	return [self stringByReplacingOccurrencesOfString:NSStringNewlinePlaceholder withString:NSStringEmptyPlaceholder];
}

- (NSInteger)compareWithWord:(NSString *)stringB matchGain:(NSInteger)gain missingCost:(NSInteger)cost
{
	// normalize strings
	NSString *stringA = [NSString stringWithString:self];
	
	stringA = [stringA.trim lowercaseString];
	stringB = [stringB.trim lowercaseString];
	
	// Step 1
	NSInteger k, i, j, change, *d, distance;
	
	NSUInteger n = [stringA length];
	NSUInteger m = [stringB length];
	
	if (NSDissimilarObjects(n++, 0) && NSDissimilarObjects(m++, 0))
	{
		d = malloc(sizeof(NSInteger) * m * n );
		
		for (k = 0; k < n; k++) {
			d[k] = k;
		}
		
		for (k = 0; k < m; k++) {
			d[ k * n ] = k;
		}
		
		for (i = 1; i < n; i++) {
			for (j = 1; j < m; j++) {
				if ([stringA characterAtIndex:(i - 1)] == [stringB characterAtIndex:(j - 1)]) {
					change = -(gain);
				} else {
					change = cost;
				}
				
				// Step 6
				d[ (j * n + i) ] = MIN( (d[ ((j - 1) * n + i) ] + 1),
								   MIN( (d[  (j * n + i - 1) ] +  1),
									    (d[ ((j - 1) * n + i -1) ] + change)));
			}
		}
		
		distance = d[ (n * m - 1) ];
		
		free(d);
		
		return distance;
	}
	
	return 0;
}

- (NSInteger)stringPosition:(NSString *)needle
{
	NSRange searchResult = [self rangeOfString:needle];
	
	if (searchResult.location == NSNotFound) {
		return -1;
	}
	
	return searchResult.location;
}

- (NSInteger)stringPositionIgnoringCase:(NSString *)needle
{
	NSRange searchResult = [self rangeOfString:needle options:NSCaseInsensitiveSearch];

	if (searchResult.location == NSNotFound) {
		return -1;
	}

	return searchResult.location;
}

- (NSString *)stringByDeletingPreifx:(NSString *)prefix
{
	if ([prefix length] > 0 && [self length] > [prefix length]) {
		if ([self hasPrefix:prefix]) {
			return [self substringFromIndex:[prefix length]];
		}
	}
	
	return self;
}

- (BOOL)hostmaskComponents:(NSString **)nickname username:(NSString **)username address:(NSString **)address client:(IRCClient *)client
{
	/* Gather basic information. */
	NSInteger bang1pos = [self stringPosition:@"!"];
	NSInteger bang2pos = [self stringPosition:@"@"];

	NSAssertReturnR((bang1pos >= 0), NO);
	NSAssertReturnR((bang2pos >= 0), NO);
	NSAssertReturnR((bang2pos > bang1pos), NO);

	/* Bind sections of the host. */
	NSString *nicknameInt = [self substringToIndex:bang1pos];

	NSString *usernameInt = [self substringWithRange:NSMakeRange((bang1pos + 1),
																 (bang2pos - (bang1pos + 1)))];

	NSString *addressInt = [self substringAfterIndex:bang2pos];

	/* Perform basic validation. */
	NSAssertReturnR(([nicknameInt length] > 0), NO);
	NSAssertReturnR(([usernameInt length] > 0), NO);
	NSAssertReturnR(([addressInt length] > 0), NO);

	NSAssertReturnR([usernameInt isUsername], NO);

	/* Further compare values. */
	/* Rizon and QuakeNet allow formatting characters in the address part. … WHAT THE FUCK? */
	NSString *formattingCharsSet = [NSString stringWithFormat:@"%@%C%C%C%C%C%C", IRCUserAddressValidCharacters, 0x02, 0x03, 0x0F, 0x1d, 0x16, 0x1F];

	if ([addressInt onlyContainsCharacters:formattingCharsSet] == NO) {
		/* Host sections contain redundant characters. */
		/* The host is not valid. */

		return NO;
	}

	/* Perform client specific validation. */
	if (client) {
		/* Check whether the nickname is a valid nickname. */
		NSAssertReturnR([nicknameInt isNickname:client], NO);
	}

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
	return [self isHostmask:nil];
}

- (BOOL)isHostmask:(IRCClient *)client
{
	return [self hostmaskComponents:nil username:nil address:nil client:client];
}

- (BOOL)isUsername /* Ident — @private */
{
	NSString *bob = self;

	if ([bob hasPrefix:@"~"]) {
		bob = [bob substringFromIndex:1];
	}

	if ([bob onlyContainsCharacters:IRCUsernameValidCharacters] == NO) {
		return NO;
	}

	return (bob.length <= TXMaximumIRCUsernameLength);
}

- (BOOL)isNickname
{
	return ([self isNotEqualTo:@"*"] && [self contains:@"."] == NO);
}

- (BOOL)isNickname:(IRCClient *)client
{
	NSObjectIsEmptyAssertReturn(self, NO);

	if (client) {
		NSInteger maxNickLength = [[client isupport] nicknameLength];

		return ([self isNickname] && [self length] <= maxNickLength);
	} else {
		return [self isNickname];
	}
}

- (BOOL)isChannelName:(IRCClient *)client
{
	NSObjectIsEmptyAssertReturn(self, NO);
	
	if (client == nil) {
		return [self isChannelName];
	}

	NSString *validChars = [[client isupport] channelNamePrefixes];

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

	return (self.length >= 1 && (c == '#' || c == '&' || c == '+' || c == '!' || c == '~' || c == '?'));
}

- (BOOL)isModeChannelName
{
	NSObjectIsEmptyAssertReturn(self, NO);

	UniChar c = [self characterAtIndex:0];

	return (self.length >= 1 && (c == '#' || c == '&' || c == '!' || c == '~' || c == '?'));
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
	NSObjectIsEmptyAssertReturn(self, NO);
	
	if (PointerIsEmpty(client)) {
		return [self channelNameToken];
	}
	
	NSCharacterSet *validChars = [NSCharacterSet characterSetWithCharactersInString:[client.isupport channelNamePrefixes]];
	
	return [self stringByTrimmingCharactersInSet:validChars];
}

- (NSString *)nicknameFromHostmask
{
	return [self nicknameFromHostmask:nil];
}

- (NSString *)usernameFromHostmask
{
	return [self usernameFromHostmask:nil];
}

- (NSString *)addressFromHostmask
{
	return [self addressFromHostmask:nil];
}

- (NSString *)nicknameFromHostmask:(IRCClient *)client
{
	NSString *nickname = nil;

	if ([self hostmaskComponents:&nickname username:nil address:nil client:client]) {
		return nickname;
	} else {
		return self;
	}

	return nil;
}

- (NSString *)usernameFromHostmask:(IRCClient *)client
{
	NSString *username = nil;

	if ([self hostmaskComponents:nil username:&username address:nil client:client]) {
		return username;
	}

	return nil;
}

- (NSString *)addressFromHostmask:(IRCClient *)client
{
	NSString *address = nil;

	if ([self hostmaskComponents:nil username:nil address:&address client:client]) {
		return address;
	}

	return nil;
	
}

- (NSString *)reservedCharactersToIRCFormatting
{
	/* 
	 
	 This is an interesting method. Long, long ago when Textual was still a young
	 fork of Limechat we were working on formatting support for the input text field.
	 The feature was sorta, kinda rushed so "reserved characters" were settled on.
	 It was just a rip off of mIRC boxy things they use for formatting.

	 User would select a portion of text they wanted formatted, right click, select
	 the formatting, then Textual would insert the boxes around the text. Of couse
	 Textual now has a more modern system for formatting. This method still exists
	 though so a theme can customize localizations with IRC formatting since the
	 localizations do not support HTML.

	 Maybe a new system is needed? Nah, no rush. No themes even change localizations.

	 Format:
		 ▤<foreground 1-15>,[background 1-15]<text>▤ — color
		 ▥<text>▥ — bold
		 ▧<text>▧ — italics
		 ▨<text>▨ — underline
	 
	 */

	NSString *s = self;

	s = [s stringByReplacingOccurrencesOfString:[NSString stringWithUniChar:0x03] withString:@"▤"]; // color
	s = [s stringByReplacingOccurrencesOfString:[NSString stringWithUniChar:0x02] withString:@"▥"]; // bold
	s = [s stringByReplacingOccurrencesOfString:[NSString stringWithUniChar:0x1d] withString:@"▧"]; // italics
	s = [s stringByReplacingOccurrencesOfString:[NSString stringWithUniChar:0x1F] withString:@"▨"]; // underline

	return s;
}

- (NSString *)cleanedServerHostmask
{
    NSString *bob = [self trim];

    if ([TLORegularExpression string:bob isMatchedByRegex:@"^([^:]+):([0-9]{2,7})$"] ||
        [TLORegularExpression string:bob isMatchedByRegex:@"^\\[([0-9a-f:]+)\\]:([0-9]{2,7})$"])
	{
		NSRange searchRange = [bob rangeOfString:@":" options:NSBackwardsSearch range:NSMakeRange(0, [self length])];

		if (searchRange.location == NSNotFound) {
			return bob;
		}

		return [bob substringToIndex:searchRange.location];
    }

	return bob;
}

- (BOOL)isIPAddress
{
	return ([self isIPv4Address] || [self isIPv6Address]);
}

- (BOOL)isIPv4Address
{
	struct sockaddr_in sa;
	
    int result = inet_pton(AF_INET, [self UTF8String], &(sa.sin_addr));
    
	return (result == 1);
}

- (BOOL)isIPv6Address
{
	struct in6_addr sa;
	
    int result = inet_pton(AF_INET6, [self UTF8String], &sa);
    
	return (result == 1);
}

- (NSString *)stringWithValidURIScheme
{
	return [AHHyperlinkScanner URLWithProperScheme:self];
}

- (id)attributedStringWithIRCFormatting:(NSFont *)defaultFont honorFormattingPreference:(BOOL)formattingPreference
{
	if (formattingPreference && [TPCPreferences removeAllFormatting]) {
		return [self stripIRCEffects];
	}

    NSDictionary *input = @{@"attributedStringFont" : defaultFont};

	return [TVCLogRenderer renderBody:self
						   controller:[self.worldController selectedViewController]
						   renderType:TVCLogRendererAttributedStringType
						   properties:input
						   resultInfo:NULL];
}

- (id)attributedStringWithIRCFormatting:(NSFont *)defaultFont
{
	return [self attributedStringWithIRCFormatting:defaultFont honorFormattingPreference:NO];
}

- (NSString *)trimAndGetFirstToken
{
	NSObjectIsEmptyAssertReturn(self, self);

	NSString *firstToken = [NSString getTokenFromFirstWhitespaceGroup:[self trim] returnedDeletionRange:NULL];

	return firstToken;
}

- (NSString *)safeFilename
{
	NSString *bob = self.trim;

	bob = [bob stringByReplacingOccurrencesOfString:@"/" withString:@"_"];
	bob = [bob stringByReplacingOccurrencesOfString:@":" withString:@"_"];

	return bob;
}

- (BOOL)isNumericOnly
{
	NSObjectIsEmptyAssertReturn(self, NO);
	
	for (NSInteger i = 0; i < [self length]; ++i) {
		UniChar c = [self characterAtIndex:i];
		
		if (TXStringIsBase10Numeric(c) == NO) {
			return NO;
		}
	}
	
	return YES;
}

- (BOOL)isAlphabeticNumericOnly
{
	NSObjectIsEmptyAssertReturn(self, NO);

	for (NSInteger i = 0; i < [self length]; ++i) {
		UniChar c = [self characterAtIndex:i];
		
		if (TXStringIsAlphabeticNumeric(c) == NO) {
			return NO;
		}
	}
	
	return YES;
}

- (BOOL)containsCharacters:(NSString *)validChars
{
	NSObjectIsEmptyAssertReturn(self, NO);
	NSObjectIsEmptyAssertReturn(validChars, NO);

	NSCharacterSet *chars = [NSCharacterSet characterSetWithCharactersInString:validChars];

	NSRange searchRange = [self rangeOfCharacterFromSet:chars];

	return NSDissimilarObjects(searchRange.location, NSNotFound);
}

- (BOOL)onlyContainsCharacters:(NSString *)validChars
{
	NSObjectIsEmptyAssertReturn(self, NO);
	NSObjectIsEmptyAssertReturn(validChars, NO);

	NSCharacterSet *chars = [[NSCharacterSet characterSetWithCharactersInString:validChars] invertedSet];

	NSRange searchRange = [self rangeOfCharacterFromSet:chars];

	return (searchRange.location == NSNotFound);
}

- (NSString *)stringByDeletingAllCharactersInSet:(NSString *)validChars deleteThoseNotInSet:(BOOL)onlyDeleteThoseNotInSet
{
	NSObjectIsEmptyAssertReturn(self, nil);
	NSObjectIsEmptyAssertReturn(validChars, nil);
	
	NSMutableString *result = [NSMutableString string];

	NSCharacterSet *chars = [NSCharacterSet characterSetWithCharactersInString:validChars];
	
	NSScanner *scanner = [NSScanner scannerWithString:self];
	
	while ([scanner isAtEnd] == NO) {
		NSString *buffer;
		
		if (onlyDeleteThoseNotInSet) {
			if ([scanner scanCharactersFromSet:chars intoString:&buffer]) {
				[result appendString:buffer];
			} else {
				[scanner setScanLocation:([scanner scanLocation] + 1)];
			}
		} else {
			if ([scanner scanCharactersFromSet:chars intoString:&buffer]) {
				[scanner setScanLocation:([scanner scanLocation] + 1)];
			} else {
				[result appendString:buffer];
			}
		}
	}
	
	return result;
}

- (NSString *)stringByDeletingAllCharactersInSet:(NSString *)validChars
{
	return [self stringByDeletingAllCharactersInSet:validChars deleteThoseNotInSet:NO];
}

- (NSString *)stringByDeletingAllCharactersNotInSet:(NSString *)validChars
{
	return [self stringByDeletingAllCharactersInSet:validChars deleteThoseNotInSet:YES];
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
				case 0x2:
				case 0xf:
				case 0x16:
				case 0x1d:
				case 0x1f:
				{
					break;
				}
				case 0x3:
				{
					/* ============================================= */
					/* Begin color stripping.						 */
					/* ============================================= */
					
					if ((i + 1) >= len) {
						continue;
					}

					UniChar d = src[(i + 1)];
					
					if (TXStringIsBase10Numeric(d) == NO) {
						continue;
					}
					
					i++;

					// ---- //
					
					if ((i + 1) >= len) {
						continue;
					}

					UniChar e = src[(i + 1)];
					
					if (TXStringIsBase10Numeric(e) == NO && NSDissimilarObjects(e, ',')) {
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

					if (TXStringIsBase10Numeric(g) == NO) {
						i--;
						
						continue;
					}
					
					i++;

					// ---- //

					if ((i + 1) >= len) {
						continue;
					}

					UniChar h = src[(i + 1)];

					if (TXStringIsBase10Numeric(h) == NO) {
						continue;
					}
					
					i++;

					// ---- //
					
					break;
					
					/* ============================================= */
					/* End color stripping.							 */
					/* ============================================= */
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

- (NSRange)rangeOfNextSegmentMatchingRegularExpression:(NSString *)regex startingAt:(NSInteger)start
{
	NSInteger stringLength = [self length];
	
	NSAssertReturnR((stringLength > start), NSEmptyRange());
	
	NSString *searchString = [self substringFromIndex:start];
	
	NSRange searchRange = [TLORegularExpression string:searchString rangeOfRegex:regex];

	if (searchRange.location == NSNotFound) {
		return NSEmptyRange();
	}

	NSRange r = NSMakeRange((start + searchRange.location),
									 searchRange.length);
	
	return r;
}

- (NSString *)encodeURIComponent
{
	NSObjectIsEmptyAssertReturn(self, NSStringEmptyPlaceholder);
	
	const char *sourcedata = [self UTF8String];
	const char *characters = "0123456789ABCDEF";

	PointerIsEmptyAssertReturn(sourcedata, NSStringEmptyPlaceholder);
	
	NSUInteger datalength = [self lengthOfBytesUsingEncoding:NSUTF8StringEncoding];
	
	char  buf[(datalength * 4)];
	char *dest = buf;
	
	for (NSInteger i = (datalength - 1); i >= 0; --i) {
		unsigned char c = *sourcedata++;
		
		if (TXStringIsWordLetter(c) || c == '-' || c == '.' || c == '~') {
			*dest++ = c;
		} else {
			*dest++ = '%';
			*dest++ = characters[(c / 16)];
			*dest++ = characters[(c % 16)];
		}
	}
	
	return [NSString stringWithBytes:buf length:(dest - buf) encoding:NSASCIIStringEncoding];
}

- (NSString *)encodeURIFragment
{
	NSObjectIsEmptyAssertReturn(self, NSStringEmptyPlaceholder);

	const char *sourcedata = [self UTF8String];
	const char *characters = "0123456789ABCDEF";

	PointerIsEmptyAssertReturn(sourcedata, NSStringEmptyPlaceholder);

	NSUInteger datalength = [self lengthOfBytesUsingEncoding:NSUTF8StringEncoding];

	char  buf[(datalength * 4)];
	char *dest = buf;

	for (NSInteger i = (datalength - 1); i >= 0; --i) {
		unsigned char c = *sourcedata++;
		
		if (TXStringIsWordLetter(c)
			|| c == '#' || c == '%'
			|| c == '&' || c == '+'
			|| c == ',' || c == '-'
			|| c == '.' || c == '/'
			|| c == ':' || c == ';'
			|| c == '=' || c == '?'
			|| c == '@' || c == '~')
		{
			*dest++ = c;
		} else {
			*dest++ = '%';
			*dest++ = characters[(c / 16)];
			*dest++ = characters[(c % 16)];
		}
	}
	
	return [NSString stringWithBytes:buf length:(dest - buf) encoding:NSASCIIStringEncoding];
}

- (NSString *)decodeURIFragement
{
	return [self stringByReplacingPercentEscapesUsingEncoding:NSASCIIStringEncoding];
}

- (NSInteger)wrappedLineCount:(NSInteger)boundWidth lineMultiplier:(NSInteger)lineHeight forcedFont:(NSFont *)textFont
{
	CGFloat boundHeight = [self pixelHeightInWidth:boundWidth forcedFont:textFont];
	
	return (boundHeight / lineHeight);
}

- (CGFloat)pixelHeightInWidth:(NSInteger)width forcedFont:(NSFont *)font
{
	NSAttributedString *base = [NSAttributedString emptyStringWithBase:self];

	return [base pixelHeightInWidth:width forcedFont:font];
}

- (NSString *)base64EncodingWithLineLength:(NSInteger)lineLength
{
	NSData *baseData = [self dataUsingEncoding:NSUTF8StringEncoding];
	
	NSString *encodedResult = [CSFWBase64Encoding encodeData:baseData];
	
	NSObjectIsEmptyAssertReturn(encodedResult, nil);
	
	NSMutableString *resultString = [NSMutableString string];
	
	if ([encodedResult length] > lineLength) {
		NSInteger rlc = ceil([encodedResult length] / lineLength);

		for (NSInteger i = 1; i <= rlc; i++) {
			NSString *append = [encodedResult safeSubstringToIndex:lineLength];

			[resultString appendString:append];
			[resultString appendString:NSStringNewlinePlaceholder];

			encodedResult = [encodedResult safeSubstringFromIndex:lineLength];
		}
	}
	
	[resultString appendString:encodedResult];

	return resultString;
}

- (NSString *)string
{
	return self;
}

+ (id)getTokenFromFirstWhitespaceGroup:(id)stringValue returnedDeletionRange:(NSRange *)whitespaceRange
{
	/* What type of string are we processing? */
	BOOL isAttributedString = ([stringValue isKindOfClass:[NSAttributedString class]]);

	/* Check the input. */
	if (stringValue == nil || [stringValue length] < 1) {
		if (isAttributedString) {
			return [NSAttributedString emptyString];
		} else {
			return NSStringEmptyPlaceholder;
		}
	}

	/* Define base variables. */
	NSScanner *scanner = [NSScanner scannerWithString:[stringValue string]];

	[scanner setCharactersToBeSkipped:nil]; // Do not skip anything.

	/* Scan up to first space. */
	[scanner scanUpToString:@" " intoString:NULL];

	NSInteger scanLocation = [scanner scanLocation];

	/* We now scan from the scan location to the end of whitespaces. */
	if (whitespaceRange) {
		NSInteger stringLength = [stringValue length];
		NSInteger stringForward = scanLocation;

		while (1 == 1) { // Infinite loops are safe! :-)
			NSAssertReturnLoopBreak(stringForward < stringLength);

			UniChar c = [[stringValue string] characterAtIndex:stringForward];

			if (c == ' ') {
				stringForward += 1;
			} else {
				break;
			}
		}

		*whitespaceRange = NSMakeRange(0, stringForward);
	}

	/* Build and return final tokenized string from range. */
	id resultString;

	if (isAttributedString) {
		resultString = [stringValue attributedSubstringFromRange:NSMakeRange(0, scanLocation)];
	} else {
		resultString = [stringValue substringToIndex:scanLocation];
	}

	return resultString;
}

+ (id)getTokenFromFirstQuoteGroup:(id)stringValue returnedDeletionRange:(NSRange *)quoteRange
{
	/* What type of string are we processing? */
	BOOL isAttributedString = ([stringValue isKindOfClass:[NSAttributedString class]]);

	/* Check the input. */
	if (stringValue == nil || [stringValue length] < 1) {
		if (isAttributedString) {
			return [NSAttributedString emptyString];
		} else {
			return NSStringEmptyPlaceholder;
		}
	}

	/* String must have an opening quote before we even use it. */
	id originalString = [stringValue mutableCopy];

	if ([[originalString string] hasPrefix:@"\""] == NO) {
		return nil;
	}

	/* Define base variables. */
	NSScanner *scanner = [NSScanner scannerWithString:[originalString string]];

	[scanner setCharactersToBeSkipped:nil]; // Do not skip anything.

	/* We do have a starting quote so we will now set the scanner
	 to that then have it set it it to destroy it from scanner. */
	[scanner scanUpToString:@"\"" intoString:NULL];
	[scanner scanString:@"\"" intoString:NULL];

	/* Now we will scan the rest of the string to the end. */
	while ([scanner isAtEnd] == NO) {
		[scanner scanUpToString:@"\"" intoString:NULL];

		/* End here. */
		if ([scanner scanLocation] == [stringValue length]) {
			return nil;
		}

		/* Scan location is now set at this quote. */
		NSUInteger scanLocation = [scanner scanLocation];

		/* Check the left side of the quote. */
		NSInteger slashCount = 0;

		/* Find all slashes left of this quote. */
		for (NSInteger i = (scanLocation - 1); i > 0; i--) {
			UniChar c = [[originalString string] characterAtIndex:i];

			if (c == '\\') {
				slashCount += 1;
			} else {
				break;
			}
		}

		BOOL slashesAreEven = (slashCount > 0 && ((slashCount % 2) == 0));

		/* If the quote is not escaped, then we either want
		 to be at the end of the string or only have a space
		 to our right side. Anything else invalidates group. */
		if (slashesAreEven || slashCount == 0) {
			NSInteger charIndex = (scanLocation + 1);

			if ([originalString length] > charIndex) {
				UniChar rightChar = [[originalString string] characterAtIndex:charIndex];

				if (NSDissimilarObjects(rightChar, ' ')) {
					return nil;
				}
			}
		}

		/* Start calculations on escapes. */
		if (slashCount > 0) {
			if (slashesAreEven) {
				/* The slashes escape themselves left of this quote
				 so we do not have to do anything except continue on. */
			} else {
				/* Scan current quote and move forward. */
				if ([scanner isAtEnd]) {
					return nil;
				} else {
					[scanner setScanLocation:([scanner scanLocation] + 1)];
				}

				continue;
			}
		} /* End escape calculations. */

		/* Delete outside quotes. */
		[originalString deleteCharactersInRange:NSMakeRange(scanLocation, ([originalString length] - scanLocation))];
		[originalString deleteCharactersInRange:NSMakeRange(0, 1)];

		/* Now that we calculated escapes, we will now replace slash 
		 groups so that two slashes equal to one anywhere in the string. */
		NSInteger loopPosition = ([originalString length] - 1);

		BOOL isInSlashGroup = NO;
		BOOL lastCharWasQuote = NO;

		NSInteger slashGroupStart = -1;
		NSInteger slashGroupCount = -1;

		while (loopPosition > -1) {
			UniChar c = [[originalString string] characterAtIndex:loopPosition];

			if (c == '\\' && loopPosition > 0) {
				if (isInSlashGroup == NO) {
					isInSlashGroup = YES;

					slashGroupStart = loopPosition;
					slashGroupCount = 1;
				} else {
					slashGroupCount += 1;
				}
			}
			else if (NSDissimilarObjects(c, '\\') || (c == '\\' && loopPosition == 0))
			{
				/* Increase by one if we end at a \ */
				if (loopPosition == 0 && c == '\\') {
					if (isInSlashGroup == NO) {
						isInSlashGroup = YES;

						slashGroupStart = 0;
						slashGroupCount = 1;
					} else {
						slashGroupCount += 1;
					}
				}

				if (isInSlashGroup) {
					if (lastCharWasQuote && slashGroupCount == 1) {
						/* When a single slash escapes a quote, then we just delete that single
						 slash entirely. Any other character with a single slash, does not have
						 that slash erased as that character does not need escaping. */

						[originalString deleteCharactersInRange:NSMakeRange(slashGroupStart, 1)];
					} else {
						/* We are scanning backwards so the start is position minus length. */
						NSInteger actualStart = ((slashGroupStart - slashGroupCount) + 1);

						NSRange deleteRange = NSMakeRange(actualStart, slashGroupCount);

						/* Delete the existing slash group. */
						[originalString deleteCharactersInRange:deleteRange];

						/* Now, we build the replacement slashes. */
						NSMutableString *newSlashGroup = [NSMutableString string];

						/* How many slashes is the loop going to create? */
						NSInteger newCount = slashGroupCount;

						/* If previous char was a quote, then we have to minus one. */
						if (lastCharWasQuote) {
							newCount -= 1;
						}

						/* If the number of slashes is divisible by two, then it is a
						 matter of dividing them and replacing them with the divided value. */
						BOOL divisibleByTwo = ((slashGroupCount % 2) == 0);

						if (divisibleByTwo == NO) {
							/* We manually insert the extra when we can't divide. */
							newCount -= 1;

							[newSlashGroup appendString:@"\\"];
						}

						/* Updated math. */
						newCount = (newCount / 2);

						/* Create slash group. */
						for (NSInteger i = 0; i < newCount; i++) {
							[newSlashGroup appendString:@"\\"];
						}

						/* Insert the new group. */
						if (isAttributedString) {
							NSAttributedString *newGroup = [NSAttributedString emptyStringWithBase:newSlashGroup];

							[originalString insertAttributedString:newGroup atIndex:actualStart];
						} else {
							[originalString insertString:newSlashGroup atIndex:actualStart];
						}
					}

					isInSlashGroup = NO;

					slashGroupCount = -1;
					slashGroupStart = -1;
				}

				lastCharWasQuote = (c == '"');
			}

			/* Go down by one. */
			loopPosition -= 1;
		}

		/* We are done here. First we have to calculate the deletion range.
		 As the deletion range takes into account all whitespaces following
		 it so the next token starts at an actual character, we still have 
		 to scan forward from the starting location. For that, we will use
		 a simple for loop and compare characters. */
		if (quoteRange) {
			NSInteger stringLength = [stringValue length];
			NSInteger stringForward = ([scanner scanLocation] + 1);

			while (1 == 1) { // Infinite loops are safe! :-)
				NSAssertReturnLoopBreak(stringForward < stringLength);

				UniChar c = [[stringValue string] characterAtIndex:stringForward];

				if (c == ' ') {
					stringForward += 1;
				} else {
					break;
				}
			}

			*quoteRange = NSMakeRange(0, stringForward);
		}

		/* Build and return final tokenized string from range. */
		return originalString;
	} /* while loop. */
	
	return nil;
}

@end

@implementation NSString (NSStringNumberHelper)

+ (NSString *)stringWithChar:(char)value								{ return [NSString stringWithFormat:@"%c", value]; }
+ (NSString *)stringWithUniChar:(UniChar)value							{ return [NSString stringWithFormat:@"%C", value]; }
+ (NSString *)stringWithUnsignedChar:(unsigned char)value				{ return [NSString stringWithFormat:@"%c", value]; }

+ (NSString *)stringWithShort:(short)value								{ return [NSString stringWithFormat:@"%hi", value]; }
+ (NSString *)stringWithUnsignedShort:(unsigned short)value				{ return [NSString stringWithFormat:@"%hu", value]; }

+ (NSString *)stringWithInt:(int)value									{ return [NSString stringWithFormat:@"%i", value]; }
+ (NSString *)stringWithInteger:(NSInteger)value						{ return [NSString stringWithFormat:@"%ld", value]; }

+ (NSString *)stringWithUnsignedInt:(unsigned int)value					{ return [NSString stringWithFormat:@"%u", value]; }
+ (NSString *)stringWithUnsignedInteger:(NSUInteger)value				{ return [NSString stringWithFormat:@"%lu", value]; }

+ (NSString *)stringWithLong:(long)value								{ return [NSString stringWithFormat:@"%ld", value]; }
+ (NSString *)stringWithUnsignedLong:(unsigned long)value				{ return [NSString stringWithFormat:@"%lu", value]; }

+ (NSString *)stringWithLongLong:(long long)value						{ return [NSString stringWithFormat:@"%qi", value]; }
+ (NSString *)stringWithUnsignedLongLong:(unsigned long long)value		{ return [NSString stringWithFormat:@"%qu", value]; }

+ (NSString *)stringWithFloat:(float)value								{ return [NSString stringWithFormat:@"%f", value]; }
+ (NSString *)stringWithDouble:(double)value							{ return [NSString stringWithFormat:@"%f", value]; }

@end

@implementation NSMutableString (NSMutableStringHelper)

- (void)safeDeleteCharactersInRange:(NSRange)range
{
	if (NSRangeIsValidInBounds(range, [self length])) {
		[self deleteCharactersInRange:range];
	}
}

- (NSString *)getTokenIncludingQuotes
{
	NSRange deletionRange = NSEmptyRange();

	NSString *quotedGroup = [NSString getTokenFromFirstQuoteGroup:self returnedDeletionRange:&deletionRange];

	if (quotedGroup == nil) {
		return [self getToken];
	} else {
		if (NSDissimilarObjects(deletionRange.location, NSNotFound)) {
			[self deleteCharactersInRange:deletionRange];
		}

		return quotedGroup;
	}
}

- (NSString *)getToken
{
	NSRange deletionRange = NSEmptyRange();

	NSString *token = [NSString getTokenFromFirstWhitespaceGroup:self returnedDeletionRange:&deletionRange];

	if (token == nil) {
		return NSStringEmptyPlaceholder;
	} else {
		if (NSDissimilarObjects(deletionRange.location, NSNotFound)) {
			[self deleteCharactersInRange:deletionRange];
		}

		return token;
	}
}

@end

@implementation NSAttributedString (NSAttributedStringHelper)

+ (NSAttributedString *)emptyString
{
    return [NSAttributedString emptyStringWithBase:NSStringEmptyPlaceholder];
}

+ (NSAttributedString *)emptyStringWithBase:(NSString *)base
{
	return [[NSAttributedString alloc] initWithString:base];
}

+ (NSAttributedString *)stringWithBase:(NSString *)base attributes:(NSDictionary *)baseAttributes
{
	return [[NSAttributedString alloc] initWithString:base attributes:baseAttributes];
}

- (NSDictionary *)attributes
{
    return [self safeAttributesAtIndex:0 longestEffectiveRange:NULL inRange:NSMakeRange(0, [self length])];
}

- (id)safeAttribute:(NSString *)attrName atIndex:(NSUInteger)location effectiveRange:(NSRangePointer)range
{
	NSAssertReturnR((location < [self length]), nil);
	
	return [self attribute:attrName atIndex:location effectiveRange:range];
}

- (NSDictionary *)safeAttributesAtIndex:(NSUInteger)location longestEffectiveRange:(NSRangePointer)range inRange:(NSRange)rangeLimit
{
	NSAssertReturnR((location < [self length]), nil);

	if (NSRangeIsValidInBounds(rangeLimit, [self length])) {
		return [self attributesAtIndex:location longestEffectiveRange:range inRange:rangeLimit];
	}

	return nil;
}

- (id)safeAttribute:(NSString *)attrName atIndex:(NSUInteger)location longestEffectiveRange:(NSRangePointer)range inRange:(NSRange)rangeLimit
{
	NSAssertReturnR((location < [self length]), nil);

	if (NSRangeIsValidInBounds(rangeLimit, [self length])) {
		return [self attribute:attrName atIndex:location longestEffectiveRange:range inRange:rangeLimit];
	}

	return nil;
}

- (NSAttributedString *)attributedStringByTrimmingCharactersInSet:(NSCharacterSet *)set
{
	return [self attributedStringByTrimmingCharactersInSet:set frontChop:NULL];
}

- (NSAttributedString *)attributedStringByTrimmingCharactersInSet:(NSCharacterSet *)set frontChop:(NSRangePointer)front
{
	NSString *baseString = [self string];
	
	NSRange range;
	
	NSUInteger locati = 0;
	NSUInteger length = 0;
	
	NSCharacterSet *invertedSet = [set invertedSet];
	
	range = [baseString rangeOfCharacterFromSet:invertedSet];

	if (range.length >= 1) {
		locati = range.location;
	} else {
		locati = 0;
	}
	
	if (PointerIsEmpty(front) == NO) {
		*front = range;
	}
	
	range = [baseString rangeOfCharacterFromSet:invertedSet options:NSBackwardsSearch];

	if (range.length >= 1) {
		length = (NSMaxRange(range) - locati);
	} else {
		length = ([baseString length] - locati);
	}
	
	return [self attributedSubstringFromRange:NSMakeRange(locati, length)];
}

- (NSArray *)splitIntoLines
{
    NSMutableArray *lines = [NSMutableArray array];
    
    NSInteger stringLength = [[self string] length];
    NSInteger rangeStartIn = 0;
    
    NSMutableAttributedString *copyd = [self mutableCopy];
    
    while (rangeStartIn < stringLength) {
		NSRange srb = NSMakeRange(rangeStartIn, (stringLength - rangeStartIn));
     
		NSRange srr = [self.string rangeOfCharacterFromSet:[NSCharacterSet newlineCharacterSet] options:0 range:srb];
        
        if (srr.location == NSNotFound) {
            break;
        }
        
        NSRange delRange = NSMakeRange(0, ((srr.location - rangeStartIn) + 1));
        NSRange cutRange = NSMakeRange(rangeStartIn, (srr.location - rangeStartIn));
        
        NSAttributedString *line = [self attributedSubstringFromRange:cutRange];
        
		if (line) {
			[lines addObject:line];
		}
		
        [copyd deleteCharactersInRange:delRange];
        
        rangeStartIn = NSMaxRange(srr);
    }
    
    if (NSObjectIsEmpty(lines)) {
        [lines addObject:self];
    } else {
        if (NSObjectIsNotEmpty(copyd)) {
			[lines addObject:copyd];
        }
    }
    
    return lines;
}

- (NSInteger)wrappedLineCount:(NSInteger)boundWidth lineMultiplier:(NSInteger)lineHeight
{
	return [self wrappedLineCount:boundWidth lineMultiplier:lineHeight forcedFont:nil];
}

- (NSInteger)wrappedLineCount:(NSInteger)boundWidth lineMultiplier:(NSInteger)lineHeight forcedFont:(NSFont *)textFont
{	
	CGFloat boundHeight = [self pixelHeightInWidth:boundWidth forcedFont:textFont];

	return (boundHeight / lineHeight);
}

- (CGFloat)pixelHeightInWidth:(NSInteger)width
{
	return [self pixelHeightInWidth:width forcedFont:nil];
}

- (CGFloat)pixelHeightInWidth:(NSInteger)width forcedFont:(NSFont *)font
{
	NSMutableAttributedString *baseMutable = self.mutableCopy;
	
	NSMutableParagraphStyle *paragraphStyle = [NSMutableParagraphStyle new];
	
	[paragraphStyle setLineBreakMode:NSLineBreakByCharWrapping];
	
	NSMutableDictionary *attributes = [NSMutableDictionary dictionaryWithObjectsAndKeys:paragraphStyle, NSParagraphStyleAttributeName, nil];

	if (PointerIsNotEmpty(font)) {
		attributes[NSFontAttributeName] = font;
	}

	[baseMutable setAttributes:attributes range:NSMakeRange(0, [baseMutable length])];

	NSRect bounds = [baseMutable boundingRectWithSize:NSMakeSize(width, 0.0)
											  options:NSStringDrawingUsesLineFragmentOrigin];
	
	return NSHeight(bounds);
}

@end

@implementation NSMutableAttributedString (NSMutableAttributedStringHelper)

+ (NSMutableAttributedString *)mutableStringWithBase:(NSString *)base attributes:(NSDictionary *)baseAttributes
{
	return [[NSMutableAttributedString alloc] initWithString:base attributes:baseAttributes];
}

- (NSAttributedString *)getToken
{
	NSRange deletionRange = NSEmptyRange();

	NSAttributedString *token = [NSString getTokenFromFirstWhitespaceGroup:self returnedDeletionRange:&deletionRange];

	if (token == nil) {
		return [NSAttributedString emptyString];
	} else {
		if (NSDissimilarObjects(deletionRange.location, NSNotFound)) {
			[self deleteCharactersInRange:deletionRange];
		}

		return token;
	}
}

- (NSAttributedString *)getTokenIncludingQuotes
{
	NSRange deletionRange = NSEmptyRange();

	NSAttributedString *quotedGroup = [NSString getTokenFromFirstQuoteGroup:self returnedDeletionRange:&deletionRange];

	if (quotedGroup == nil) {
		return [self getToken];
	} else {
		if (NSDissimilarObjects(deletionRange.location, NSNotFound)) {
			[self deleteCharactersInRange:deletionRange];
		}

		return quotedGroup;
	}
}

@end
