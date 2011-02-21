//
//  unicode.m
//  RegexKit
//  http://regexkit.sourceforge.net/
//

/*
 Copyright © 2007-2008, John Engelhart
 
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions are met:
 
 * Redistributions of source code must retain the above copyright
 notice, this list of conditions and the following disclaimer.
 
 * Redistributions in binary form must reproduce the above copyright
 notice, this list of conditions and the following disclaimer in the
 documentation and/or other materials provided with the distribution.
 
 * Neither the name of the Zang Industries nor the names of its
 contributors may be used to endorse or promote products derived from
 this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED
 TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
 LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
 NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

#import "unicode.h"

/*
 VERY IMPORTANT!!
 
 PCRE and Foundation have two different definitions of what a character is.
 This is important when we are discussing things like ranges, as it can lead to very different .location and .lengths.
 
 PCRE works in UTF8 mode only, which for pragmatic purposes can be considered a eight bit byte stream.
 Assuming that the offset is a valid start of a UTF8 character, 'character 200' is one to one mapped to 'byte 200' (ie, char c = string[200]).
 If the character at index 200 is the start of a multibyte unicode character, let's say the copyright symbol '0xc2 0xa9' for example, this
 is really only a single character as displayed and what people would consider a character.  This is important because the next 'logical'
 character begins at byte index 202.  So 'logical character 201' is really string[202].  But in utf8 mode, there is no distinction between
 logical character and byte offset.

 Foundation strings, on the other hand, work in a 'UTF16 mode', where each character is treated as if it was converted to UTF16 representation.
 This means for the vast majority of cases, a single logical character is one UTF16 character (the exceptions start when you exceed the 65536
 possibilities of a 16 bit value, then just like utf8, the characters are 'escaped' and one logical character is represented by multiple utf16
 characters).
 
 This is important because locations and length in NSRanges can be very different between UTF8 and UTF16 representation.  In the copyright symbol
 example, the UTF8 range would be {200, 2}, but the UTF16/Foundation range would be {200, 1}.
 
 Therefore, we have two functions:

 RKConvertUTF16ToUTF8RangeForString(string, range)
 RKConvertUTF8ToUTF16RangeForString(string, range)

 that transform ranges back and forth between these two mapping spaces.  They do so by painfully starting at offset 0 and then move forward, keeping
 track of the offsets under both coordinate spaces.
 
 For Mac Roman and ASCII encodings, there can be no multibyte characters, so the UTF8 and UTF16/Foundation ranges are always exactly the same.  This
 means Mac Roman and ASCII encodings can be processed much faster as no conversion between spaces is required.
*/


static NSMutableArray *unicodeStringsArray = NULL;

@implementation unicode

+ (void)setUp
{

/*
0: pi ≅ 3 (apx eq)
1: ¥55 (yen)
2: Æ (ae)
3: Copyright © 2007
4: Ring of integers ℤ (dbl stk Z)
5: At the ∩ of two sets.
6: A wōŕđ 𝌴􏏼 wĩțȟ extra ȿţṻḟf
7: Frank Tang’s Iñtërnâtiônàlizætiøn Secrets 
*/

  const char *unicodeCStrings[] = {
/* 0 */ "pi \xE2\x89\x85 3 (apx eq)",
/* 1 */ "\xC2\xA5""55 (yen)",
/* 2 */ "\xC3\x86 (ae)",
/* 3 */ "Copyright \xC2\xA9 2007",
/* 4 */ "Ring of integers \xE2\x84\xA4 (dbl stk Z)",
/* 5 */ "At the \xE2\x88\xA9 of two sets.",
/* 6 */ "A w\xC5\x8D\xC5\x95\xC4\x91 \xF0\x9D\x8C\xB4\xF4\x8F\x8F\xBC w\xC4\xA9\xC8\x9B\xC8\x9F extra \xC8\xBF\xC5\xA3\xE1\xB9\xBB\xE1\xB8\x9F" "f",
/* 7 */ "Frank Tang\xE2\x80\x99s I\xC3\xB1t\xC3\xABrn\xC3\xA2ti\xC3\xB4n\xC3\xA0liz\xC3\xA6ti\xC3\xB8n Secrets",
        NULL
  };
  
  const char **cString = unicodeCStrings;
  
  unicodeStringsArray = [[NSMutableArray alloc] init];

  while(*cString != NULL) {
    [unicodeStringsArray addObject:[NSString stringWithUTF8String:*cString]];
    cString++;
  }
}

+ (void)tearDown
{
  if(unicodeStringsArray != NULL) { [unicodeStringsArray autorelease]; unicodeStringsArray = NULL; }

  NSLog(@"%@", RKPrettyObjectMethodString(@"Cache status:\n%@", [RKRegex regexCache]));
  NSLog(@"%@", RKPrettyObjectMethodString(@"Teardown complete\n\n"));
  fprintf(stderr, "-----------------------------------------\n\n");

  if(garbageCollectorEnabled) {
    NSLog(@"Exhaustive collection.");
    objc_collect_function(3 << 0);
  }

  if([sleepWhenFinishedEnvString intValue]) {
    NSLog(@"Environment variable SLEEP_WHEN_FINISHED exists.  Will now enter a sleep loop forever.");
    NSLog(@"PID: %lu", (unsigned long)getpid());
    while(1) { sleep(1); }
  }
  sleep(1);
}

- (void)testSimple
{
  /*
   copyrightString = 'Copyright © 2007'
   The copyright symbol in the middle is two bytes in UTF8 form (0xc2 0xa9), but only a single UTF16 character (U+00A9, 0x00a9).
   If things are working correctly, the various category extensions should accept and return utf16 character ranges, not utf8 byte offset ranges.
  */
  RKRegex *regex = [RKRegex regexWithRegexString:@"2007" options:(RKCompileUTF8 | RKCompileNoUTF8Check)];

  NSString *copyrightString = [unicodeStringsArray objectAtIndex:3];
  const char *copyrightUTF8String = [copyrightString UTF8String];
  size_t copyrightUTF8ByteLength = strlen(copyrightUTF8String);
  RKUInteger foundationLength = [copyrightString length];  
  
  NSRange foundationRange = [copyrightString rangeOfString:@"2007"];
  NSRange byteRange = [regex rangeForCharacters:copyrightUTF8String length:copyrightUTF8ByteLength inRange:NSMakeRange(0, copyrightUTF8ByteLength) captureIndex:0 options:RKMatchNoUTF8Check];
  NSRange stringAdditionsRange = [copyrightString rangeOfRegex:regex];

  STAssertTrue(NSEqualRanges(foundationRange, stringAdditionsRange), @"foundationRange: %@ stringAdditionsRange: %@", NSStringFromRange(foundationRange), NSStringFromRange(stringAdditionsRange));
  STAssertTrue(NSEqualRanges(stringAdditionsRange, NSMakeRange(12, 4)), @"stringAdditionsRange: %@", NSStringFromRange(stringAdditionsRange));
  STAssertTrue(NSEqualRanges(byteRange, NSMakeRange(13, 4)), @"byteRange: %@", NSStringFromRange(byteRange));
  STAssertTrue((foundationLength == 16), @"Length: %lu", (unsigned long)foundationLength);
  STAssertTrue((copyrightUTF8ByteLength == 17), @"Length: %lu", (unsigned long)copyrightUTF8ByteLength);
  
  NSString *substringFromStringAdditionsRange = [copyrightString substringWithRange:stringAdditionsRange];
  STAssertTrue([substringFromStringAdditionsRange isEqualToString:@"2007"], @"string = %@", substringFromStringAdditionsRange);

  int convertedYear = 1234;
  STAssertTrue(([copyrightString getCapturesWithRegex:regex inRange:foundationRange references:@"${0:%d}", &convertedYear, NULL] == YES), NULL);
  STAssertTrue((convertedYear == 2007), @"Year = %d", convertedYear);
  
  NSRange regexRange = [copyrightString rangeOfRegex:regex inRange:foundationRange capture:0];
  STAssertTrue((NSEqualRanges(regexRange, NSMakeRange(12, 4))), @"range: %@", NSStringFromRange(regexRange));

  regexRange = [copyrightString rangeOfRegex:@"2007" inRange:foundationRange capture:0];
  STAssertTrue((NSEqualRanges(regexRange, NSMakeRange(12, 4))), @"range: %@", NSStringFromRange(regexRange));

  NSRange *regexRanges = [copyrightString rangesOfRegex:regex inRange:foundationRange];
  STAssertTrue((NSEqualRanges(regexRanges[0], NSMakeRange(12, 4))), @"range: %@", NSStringFromRange(regexRanges[0]));

  regexRanges = [copyrightString rangesOfRegex:@"2007" inRange:foundationRange];
  STAssertTrue((NSEqualRanges(regexRanges[0], NSMakeRange(12, 4))), @"range: %@", NSStringFromRange(regexRanges[0]));

  regexRanges = [copyrightString rangesOfRegex:@"^(\\w+)\\s+(\\p{Any}+)\\s+(2007)$" inRange:NSMakeRange(0, [copyrightString length])];
  STAssertTrue((NSEqualRanges(regexRanges[0], NSMakeRange(0, 16))), @"range: %@", NSStringFromRange(regexRanges[0]));
  STAssertTrue((NSEqualRanges(regexRanges[1], NSMakeRange(0, 9))), @"range: %@", NSStringFromRange(regexRanges[1]));
  STAssertTrue((NSEqualRanges(regexRanges[2], NSMakeRange(10, 1))), @"range: %@", NSStringFromRange(regexRanges[2]));
  STAssertTrue((NSEqualRanges(regexRanges[3], NSMakeRange(12, 4))), @"range: %@", NSStringFromRange(regexRanges[3]));

  NSString *replacedString = [copyrightString stringByMatching:@"^(\\w+)\\s+(\\p{Any}+)\\s+(2007)$" inRange:NSMakeRange(0, [copyrightString length]) replace:RKReplaceAll withReferenceString:@"$1 ($2) $3, $2 2008"];
  STAssertTrue((replacedString != NULL), NULL);
  STAssertTrue(([replacedString length] == 26), @"length: %lu", (unsigned long)[replacedString length]);
  STAssertTrue((strlen([replacedString UTF8String]) == 28), @"length: %lu", (unsigned long)strlen([replacedString UTF8String]));
  STAssertTrue((NSEqualRanges([replacedString rangeOfRegex:@"2008"], NSMakeRange(22, 4))), @"range: %@", NSStringFromRange([replacedString rangeOfRegex:@"2008"]));

  replacedString = [copyrightString stringByMatching:@"2007" inRange:NSMakeRange(12, 4) replace:RKReplaceAll withReferenceString:@"2008"];
  STAssertTrue((replacedString != NULL), NULL);
  STAssertTrue(([replacedString length] == 16), @"length: %lu", (unsigned long)[replacedString length]);
  STAssertTrue((strlen([replacedString UTF8String]) == 17), @"length: %lu", (unsigned long)strlen([replacedString UTF8String]));
  STAssertTrue((NSEqualRanges([replacedString rangeOfRegex:@"2008"], NSMakeRange(12, 4))), @"range: %@", NSStringFromRange([replacedString rangeOfRegex:@"2008"]));
}

- (void)testBrownBear
{
  // Gerriet M. Denkmann gerriet (at) mdenkmann (dot) de
  // Reported the following returned the ranges {2, 1}, {5, 1}, {14, 1}, {21, 1}
  // Fixed in 0.4.0 with the UTF8 (pcre) <-> UTF16 (Foundation) character index conversions.
  //
  //       The brown bear is changing
  //       Der braune Bär ändert sich.
  // UTF8: Der braune B\xC3\xA4r \xC3\xA4ndert sich.

  NSString *brownBearString = [NSString stringWithUTF8String:"Der braune B\xC3\xA4r \xC3\xA4ndert sich."];
  RKEnumerator *brownBearStringEnumerator = [brownBearString matchEnumeratorWithRegex:@"r"];
  NSRange *matchRanges = NULL;
  int x = 0;
  NSRange brownBearRanges[4];
  for(int y = 0; y < 4; y++) { brownBearRanges[y] = NSMakeRange(NSNotFound, 65537); }
  
  while((matchRanges = [brownBearStringEnumerator nextRanges]) != NULL) { brownBearRanges[x] = matchRanges[0]; x++; }
  
  STAssertTrue((x == 4), @"X = %d", x);
  STAssertTrue(NSEqualRanges(brownBearRanges[0], NSMakeRange(2, 1)), @"range = %@", NSStringFromRange(brownBearRanges[0]));
  STAssertTrue(NSEqualRanges(brownBearRanges[1], NSMakeRange(5, 1)), @"range = %@", NSStringFromRange(brownBearRanges[1]));
  STAssertTrue(NSEqualRanges(brownBearRanges[2], NSMakeRange(13, 1)), @"range = %@", NSStringFromRange(brownBearRanges[2]));
  STAssertTrue(NSEqualRanges(brownBearRanges[3], NSMakeRange(19, 1)), @"range = %@", NSStringFromRange(brownBearRanges[3]));  


  // Now attempt to match the 'ä' with a regex.
  // A NSString is created with the UTF8 string "\xC3\xA4" == 'ä'
  // 
  // Der braune Bär ändert sich.
  // 012345678901234567890123456
  //            1111111112222222
  //  {12, 1} -> |  | <- {15, 1}
  
  NSString *utf8TestRegex = [NSString stringWithUTF8String:"\xC3\xA4"];
  brownBearStringEnumerator = [brownBearString matchEnumeratorWithRegex:utf8TestRegex];
  matchRanges = NULL;
  x = 0;
  for(int y = 0; y < 4; y++) { brownBearRanges[y] = NSMakeRange(NSNotFound, 65537); }
  
  while((matchRanges = [brownBearStringEnumerator nextRanges]) != NULL) { brownBearRanges[x] = matchRanges[0]; x++; }

  STAssertTrue((x == 2), @"X = %d", x);
  STAssertTrue(NSEqualRanges(brownBearRanges[0], NSMakeRange(12, 1)), @"range = %@", NSStringFromRange(brownBearRanges[0]));
  STAssertTrue(NSEqualRanges(brownBearRanges[1], NSMakeRange(15, 1)), @"range = %@", NSStringFromRange(brownBearRanges[1]));
}

@end
