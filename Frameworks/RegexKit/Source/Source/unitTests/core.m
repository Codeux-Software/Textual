//
//  core.m
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

#import "core.h"


@implementation core

+ (void)tearDown
{
  NSLog(@"%@", RKPrettyObjectMethodString(@"Cache status:\n%@", [RKRegex regexCache]));
  NSLog(@"%@", RKPrettyObjectMethodString(@"Teardown complete\n\n"));
  fprintf(stderr, "-----------------------------------------\n\n");
}
  
- (void)testSimpleInit
{
  NSAutoreleasePool *initPool = [[NSAutoreleasePool alloc] init];
  
  RKRegex *regex = nil;
  NSMutableSet *regexSet = [NSMutableSet set];
  
  STAssertTrueNoThrow((regex = [[[RKRegex alloc] initWithRegexString:@".* (\\w+) .*" options:0] autorelease]) != NULL, nil);
  [regexSet addObject:regex];
  STAssertThrowsSpecificNamed([[[RKRegex alloc] initWithRegexString:nil options:0] autorelease], NSException, NSInvalidArgumentException, nil);
  STAssertThrowsSpecificNamed([[[RKRegex alloc] initWithRegexString:@".* (\\w+) .*" options:0xffffffff] autorelease], NSException, RKRegexSyntaxErrorException, nil);
  
  STAssertTrueNoThrow((regex = [RKRegex regexWithRegexString:@".* (\\w+) .*" options:0]) != NULL, nil);
  [regexSet addObject:regex];
  STAssertThrowsSpecificNamed([RKRegex regexWithRegexString:nil options:0], NSException, NSInvalidArgumentException, nil);
  STAssertThrowsSpecificNamed([RKRegex regexWithRegexString:@".* (\\w+) .*" options:0xffffffff], NSException, RKRegexSyntaxErrorException, nil);
  
  regex = [RKRegex regexWithRegexString:@".* (\\w+) .*" options:0];
  [regexSet addObject:regex];
  
  regex = [RKRegex regexWithRegexString:@".* (\\w+) .*" options:RKCompileDupNames];
  [regexSet addObject:regex];
  
  regex = [RKRegex regexWithRegexString:@".* (\\w+) .*" options:RKCompileDupNames];
  [regexSet addObject:regex];
  
  if([RKRegex PCREBuildConfig] & RKBuildConfigUTF8) {
    regex = [RKRegex regexWithRegexString:@".* (\\w+) .*" options:RKCompileDupNames | RKCompileUTF8];
    [regexSet addObject:regex];
    
    regex = [RKRegex regexWithRegexString:@".* (\\w+) .*" options:RKCompileDupNames | RKCompileUTF8];
    [regexSet addObject:regex];
    
    regex = [RKRegex regexWithRegexString:@".* (\\W+) .*" options:RKCompileDupNames | RKCompileUTF8];
    [regexSet addObject:regex];
    
    regex = [RKRegex regexWithRegexString:@".* (\\W+) .*" options:RKCompileDupNames | RKCompileUTF8];
    [regexSet addObject:regex];
  }
  
  [initPool release];
}

- (void)testTrivialInitStringEncoding
{
  // Copied from somewhere, converted to UTF8, french
  char utf8Ptr[] = {0x4c, 0x65, 0x20, 0x6d, 0xe2, 0x94, 0x9c, 0xc2, 0xac, 0x6d, 0x65, 0x20, 0x74, 0x65, 0x78, 0x74, 0x65, 0x20, 0x65, 0x6e, 0x20, 0x66, 0x72, 0x61, 0x6e, 0xe2, 0x94, 0x9c, 0xc2, 0xaf, 0x61, 0x69, 0x73, 0x00};
  NSString *initString = [NSString stringWithUTF8String:utf8Ptr];
  STAssertNotNil((id)initString, nil);
  
  RKRegex *regex = nil;
  STAssertNoThrow(regex = [RKRegex regexWithRegexString:(id)initString options:0], nil);
  STAssertNotNil(regex, nil);
}

- (void)testBuildConfig
{
  RKRegex *regex = NULL;
  STAssertTrueNoThrow((regex = [RKRegex regexWithRegexString:@".* (\\w+) .*" options:0]) != NULL, nil); if(regex == nil) { return; }
  
  RKBuildConfig regexBuildConfig = [RKRegex PCREBuildConfig];
  
  RKBuildConfig pcreBuildConfig = 0;
  RKCompileErrorCode initErrorCode = RKCompileErrorNoError;
  int tempConfigInt = 0;
  STAssertTrue((initErrorCode = pcre_config(PCRE_CONFIG_UTF8, &tempConfigInt)) == RKCompileErrorNoError, @"initErrorCode = %d", initErrorCode);
  if(tempConfigInt == 1) { pcreBuildConfig |= RKBuildConfigUTF8; }
  STAssertTrue((initErrorCode = pcre_config(PCRE_CONFIG_UNICODE_PROPERTIES, &tempConfigInt)) == RKCompileErrorNoError, @"initErrorCode = %d", initErrorCode);
  if(tempConfigInt == 1) { pcreBuildConfig |= RKBuildConfigUnicodeProperties; }
  
  STAssertTrue((initErrorCode = pcre_config(PCRE_CONFIG_NEWLINE, &tempConfigInt)) == RKCompileErrorNoError, @"initErrorCode = %d", initErrorCode);
  switch(tempConfigInt) {
    case -1: pcreBuildConfig |= RKBuildConfigNewlineAny; break;
#if PCRE_MAJOR >= 7 && PCRE_MINOR >= 1
    case -2: pcreBuildConfig |= RKBuildConfigNewlineAnyCRLF; break;
#endif // >= 7.1
    case 10: pcreBuildConfig |= RKBuildConfigNewlineLF; break;
    case 13: pcreBuildConfig |= RKBuildConfigNewlineCR; break;
    case 3338: pcreBuildConfig |= RKBuildConfigNewlineCRLF; break;
    default: STAssertTrue(tempConfigInt == tempConfigInt, @"Unknown new line configuration encountered. %u 0x%8.8x", tempConfigInt, tempConfigInt); break;
  }

#if PCRE_MAJOR >= 7 && PCRE_MINOR >= 4
  STAssertTrue(((initErrorCode = pcre_config(PCRE_CONFIG_BSR, &tempConfigInt)) == RKMatchErrorNoError), @"initErrorCode = %d", initErrorCode);
  switch(tempConfigInt) {
    case 0:   pcreBuildConfig |= RKBuildConfigBackslashRUnicode; break;
    case 1:   pcreBuildConfig |= RKBuildConfigBackslashRAnyCRLR; break;
    default: STAssertTrue(1==0, @"Unknown PCRE_CONFIG_BSR encountered.  %u 0x%8.8x", tempConfigInt, tempConfigInt); break;
  }
#endif // >= 7.4
  
  STAssertTrue(pcreBuildConfig == regexBuildConfig, @"regex config: %u pcre config: %u", regexBuildConfig, pcreBuildConfig);
}

- (void)testVersion
{
  NSString *versionString = @"0xdeadbeef";
  unsigned int majorVersion = 65536, minorVersion = 4095;
  
  STAssertNotNil((versionString = [RKRegex PCREVersionString]), @"Got %@", versionString);
  STAssertTrue(((majorVersion = [RKRegex PCREMajorVersion]) != 0), nil);
  STAssertTrue(((minorVersion = [RKRegex PCREMinorVersion]) != 4095), nil);
  NSLog(@"PCRE version string: '%s', majorVersion %u minorVersion %u", [versionString UTF8String], majorVersion, minorVersion);
}

- (void)testTrivialException
{
  NSDictionary *userInfo = nil;
  
  STAssertThrowsSpecificNamed([RKRegex regexWithRegexString:@"^(.*)\\" options:RKCompileNoOptions], NSException, RKRegexSyntaxErrorException, nil);
  
#ifdef __MACOSX_RUNTIME__
  
  @try { [RKRegex regexWithRegexString:@"^(.*)\\" options:RKCompileNoOptions]; } @catch (NSException *exception) { userInfo = [exception userInfo]; }
  
#else // ! __MACOSX_RUNTIME__
  
  NS_DURING
    [RKRegex regexWithRegexString:@"^(.*)\\" options:RKCompileNoOptions];
  NS_HANDLER
    userInfo = [localException userInfo];
  NS_ENDHANDLER
  
#endif //__MACOSX_RUNTIME__
  
  STAssertNotNil(userInfo, nil);
  STAssertNotNil([userInfo objectForKey:@"regexString"], nil);
  STAssertNotNil([userInfo objectForKey:@"regexAttributedString"], nil);
  STAssertNotNil([userInfo objectForKey:@"RKCompileOption"], nil);
  STAssertNotNil([userInfo objectForKey:@"RKCompileOptionString"], nil);
  STAssertNotNil([userInfo objectForKey:@"RKCompileOptionArray"], nil);
  STAssertNotNil([userInfo objectForKey:@"RKCompileErrorCode"], nil);
  STAssertNotNil([userInfo objectForKey:@"RKCompileErrorCodeString"], nil);
  STAssertNotNil([userInfo objectForKey:@"regexStringErrorLocation"], nil);
  STAssertNotNil([userInfo objectForKey:@"errorString"], nil);
}



- (void)testGetRanges
{
  NSString *regexString = @"^(Match)\\s+the\\s+(MAGIC)";
  NSString *subjectString = @"Match the MAGIC in this string";
  RKUInteger subjectLength = [subjectString length], captureCount = 0, x = 0;
  NSRange *matchRanges = NULL;
  
  RKRegex *regex = NULL;
  STAssertTrueNoThrow((regex = [RKRegex regexWithRegexString:regexString options:0]) != NULL, nil); if(regex == nil) { return; }
  
  captureCount = [regex captureCount];
  STAssertTrue(captureCount == 3, @"captureCount is %u", captureCount); if(captureCount != 3) { return; }
  
  matchRanges = alloca(captureCount * sizeof(NSRange));
  STAssertTrue(matchRanges != NULL, nil); if(matchRanges == NULL) { return; }
  
  RKMatchErrorCode errorCode = RKMatchErrorNoError;
  
  // First check if it works.
  for(x = 0; x < captureCount; x++) { matchRanges[x] = NSMakeRange(0xdeadbeef, 0x0badc0de); } errorCode = RKMatchErrorNoError;
  errorCode = [regex getRanges:matchRanges withCharacters:[subjectString UTF8String] length:subjectLength inRange:NSMakeRange(0, subjectLength) options:0];
  STAssertTrue(errorCode == 3, @"errorCode = %d", errorCode);
  STAssertTrue(NSEqualRanges(NSMakeRange(0, 15), matchRanges[0]), @"matchRange[0] = %@", NSStringFromRange(matchRanges[0]));
  STAssertTrue(NSEqualRanges(NSMakeRange(0, 5), matchRanges[1]), @"matchRange[1] = %@", NSStringFromRange(matchRanges[1]));
  STAssertTrue(NSEqualRanges(NSMakeRange(10, 5), matchRanges[2]), @"matchRange[2] = %@", NSStringFromRange(matchRanges[2]));
  
  /// getRanges NULL
  for(x = 0; x < captureCount; x++) { matchRanges[x] = NSMakeRange(0xdeadbeef, 0x0badc0de); } errorCode = RKMatchErrorNoError;
  STAssertThrowsSpecificNamed(errorCode = [regex getRanges:NULL withCharacters:[subjectString UTF8String] length:subjectLength inRange:NSMakeRange(0, subjectLength) options:0], NSException, NSInvalidArgumentException, nil);
  STAssertTrue(errorCode == RKMatchErrorNoError, @"errorCode = %d", errorCode);
  for(x = 0; x < captureCount; x++) { STAssertTrue(NSEqualRanges(matchRanges[x], NSMakeRange(0xdeadbeef, 0x0badc0de)), @"matchRange[%d] = %@", x, NSStringFromRange(matchRanges[x])); }
  
  /// withCharacters NULL
  for(x = 0; x < captureCount; x++) { matchRanges[x] = NSMakeRange(0xdeadbeef, 0x0badc0de); } errorCode = RKMatchErrorNoError;
  STAssertThrowsSpecificNamed(errorCode = [regex getRanges:matchRanges withCharacters:NULL length:subjectLength inRange:NSMakeRange(0, subjectLength) options:0], NSException, NSInvalidArgumentException, nil);
  STAssertTrue(errorCode == RKMatchErrorNoError, @"errorCode = %d", errorCode);
  for(x = 0; x < captureCount; x++) { STAssertTrue(NSEqualRanges(matchRanges[x], NSMakeRange(0xdeadbeef, 0x0badc0de)), @"matchRange[%d] = %@", x, NSStringFromRange(matchRanges[x])); }
  
  /// Bad options
  for(x = 0; x < captureCount; x++) { matchRanges[x] = NSMakeRange(0xdeadbeef, 0x0badc0de); } errorCode = RKMatchErrorNoError;
  STAssertNoThrow(errorCode = [regex getRanges:matchRanges withCharacters:[subjectString UTF8String] length:subjectLength inRange:NSMakeRange(0, subjectLength) options:0xffffffff], nil);
  STAssertTrue(errorCode == RKMatchErrorBadOption, @"errorCode = %d", errorCode);
  for(x = 0; x < captureCount; x++) { STAssertTrue(NSEqualRanges(matchRanges[x], NSMakeRange(0xdeadbeef, 0x0badc0de)), @"matchRange[%d] = %@", x, NSStringFromRange(matchRanges[x])); }
  
  /// inRange start location exactly at the end of buffer, with a length of 0
  for(x = 0; x < captureCount; x++) { matchRanges[x] = NSMakeRange(0xdeadbeef, 0x0badc0de); } errorCode = RKMatchErrorNoError;
  STAssertNoThrow(errorCode = [regex getRanges:matchRanges withCharacters:[subjectString UTF8String] length:subjectLength inRange:NSMakeRange(subjectLength, 0) options:0], nil);
  STAssertTrue(errorCode == RKMatchErrorNoMatch, @"errorCode = %d", errorCode);
  for(x = 0; x < captureCount; x++) { STAssertTrue(NSEqualRanges(matchRanges[x], NSMakeRange(0xdeadbeef, 0x0badc0de)), @"matchRange[%d] = %@", x, NSStringFromRange(matchRanges[x])); }
  
  /// inRange start location exactly at the end of buffer, with a length of 1
  for(x = 0; x < captureCount; x++) { matchRanges[x] = NSMakeRange(0xdeadbeef, 0x0badc0de); } errorCode = RKMatchErrorNoError;
  STAssertThrowsSpecificNamed(errorCode = [regex getRanges:matchRanges withCharacters:[subjectString UTF8String] length:subjectLength inRange:NSMakeRange(subjectLength, 1) options:0], NSException, NSRangeException, nil);
  STAssertTrue(errorCode == RKMatchErrorNoError, @"errorCode = %d", errorCode);
  for(x = 0; x < captureCount; x++) { STAssertTrue(NSEqualRanges(matchRanges[x], NSMakeRange(0xdeadbeef, 0x0badc0de)), @"matchRange[%d] = %@", x, NSStringFromRange(matchRanges[x])); }
  
  /// inRange start location > buffer length
  for(x = 0; x < captureCount; x++) { matchRanges[x] = NSMakeRange(0xdeadbeef, 0x0badc0de); } errorCode = RKMatchErrorNoError;
  STAssertThrowsSpecificNamed(errorCode = [regex getRanges:matchRanges withCharacters:[subjectString UTF8String] length:subjectLength inRange:NSMakeRange(subjectLength + 1, 1) options:0], NSException, NSRangeException, nil);
  STAssertTrue(errorCode == RKMatchErrorNoError, @"errorCode = %d", errorCode);
  for(x = 0; x < captureCount; x++) { STAssertTrue(NSEqualRanges(matchRanges[x], NSMakeRange(0xdeadbeef, 0x0badc0de)), @"matchRange[%d] = %@", x, NSStringFromRange(matchRanges[x])); }
  
  /// inRange start location at one character before end of buffer, with a length of 2 exceeding buffer length
  for(x = 0; x < captureCount; x++) { matchRanges[x] = NSMakeRange(0xdeadbeef, 0x0badc0de); } errorCode = RKMatchErrorNoError;
  STAssertThrowsSpecificNamed(errorCode = [regex getRanges:matchRanges withCharacters:[subjectString UTF8String] length:subjectLength inRange:NSMakeRange(subjectLength - 1, 2) options:0], NSException, NSRangeException, nil);
  STAssertTrue(errorCode == RKMatchErrorNoError, @"errorCode = %d", errorCode);
  for(x = 0; x < captureCount; x++) { STAssertTrue(NSEqualRanges(matchRanges[x], NSMakeRange(0xdeadbeef, 0x0badc0de)), @"matchRange[%d] = %@", x, NSStringFromRange(matchRanges[x])); }
  
  /// inRange start location at one character before end of buffer, with a length of 1 within buffer
  for(x = 0; x < captureCount; x++) { matchRanges[x] = NSMakeRange(0xdeadbeef, 0x0badc0de); } errorCode = RKMatchErrorNoError;
  STAssertNoThrow(errorCode = [regex getRanges:matchRanges withCharacters:[subjectString UTF8String] length:subjectLength inRange:NSMakeRange(subjectLength - 1, 1) options:0], nil);
  STAssertTrue(errorCode == RKMatchErrorNoMatch, @"errorCode = %d", errorCode);
  for(x = 0; x < captureCount; x++) { STAssertTrue(NSEqualRanges(matchRanges[x], NSMakeRange(0xdeadbeef, 0x0badc0de)), @"matchRange[%d] = %@", x, NSStringFromRange(matchRanges[x])); }
}

- (void)testSimpleGetRangesNoMatch
{
  NSString *regexString = @"^(Match)\\s+the\\s+(MAGIC)$";
  NSString *subjectString = @"Match the MAGIC in this string";
  RKUInteger subjectLength = [subjectString length], captureCount = 0, x = 0;
  NSRange *matchRanges = NULL;
  
  RKRegex *regex = [RKRegex regexWithRegexString:regexString options:0];
  STAssertNotNil(regex, nil); if(regex == nil) { return; }
  
  captureCount = [regex captureCount];
  STAssertTrue(captureCount == 3, @"captureCount is %u", captureCount); if(captureCount != 3) { return; }
  
  matchRanges = alloca(captureCount * sizeof(NSRange));
  STAssertTrue(matchRanges != NULL, nil); if(matchRanges == NULL) { return; }
  
  RKMatchErrorCode errorCode = RKMatchErrorNoError;
  
  for(x = 0; x < captureCount; x++) { matchRanges[x] = NSMakeRange(0xdeadbeef, 0x0badc0de); }
  errorCode = [regex getRanges:matchRanges withCharacters:[subjectString UTF8String] length:subjectLength inRange:NSMakeRange(0, subjectLength) options:0];
  STAssertTrue(errorCode == RKMatchErrorNoMatch, @"errorCode = %d", errorCode);
  for(x = 0; x < captureCount; x++) { STAssertTrue(NSEqualRanges(matchRanges[x], NSMakeRange(0xdeadbeef, 0x0badc0de)), @"matchRange[%d] = %@", x, NSStringFromRange(matchRanges[x])); }
}

- (void)testMatchesCharacters
{
  NSString *regexString = @"^(Match)\\s+(?<huh>the|or|is)\\s+(MAGIC)";
  NSString *subjectString = @"Match the MAGIC in this string";
  RKUInteger subjectLength = [subjectString length], captureCount = 0, x = 0;
  NSRange *matchRanges = NULL, resultRange;
  
  RKRegex *regex = [RKRegex regexWithRegexString:regexString options:0];
  STAssertNotNil(regex, nil); if(regex == nil) { return; }
  
  captureCount = [regex captureCount];
  STAssertTrue(captureCount == 4, @"captureCount is %u", captureCount); if(captureCount != 4) { return; }
    
  matchRanges = alloca(captureCount * sizeof(NSRange));
  STAssertTrue(matchRanges != NULL, nil); if(matchRanges == NULL) { return; }
  
  for(x = 0; x < captureCount; x++) { matchRanges[x] = NSMakeRange(0xdeadbeef, 0x0badc0de); }
  
  resultRange = NSMakeRange(0xdeadbeef, 0x0badc0de);
  STAssertTrueNoThrow((NSEqualRanges(NSMakeRange(0, 15), (resultRange = [regex rangeForCharacters:[subjectString UTF8String] length:subjectLength inRange:NSMakeRange(0, subjectLength) captureIndex:0 options:RKMatchNoOptions]))), nil);
  resultRange = NSMakeRange(0xdeadbeef, 0x0badc0de);
  STAssertTrueNoThrow((NSEqualRanges(NSMakeRange(0, 5), (resultRange = [regex rangeForCharacters:[subjectString UTF8String] length:subjectLength inRange:NSMakeRange(0, subjectLength) captureIndex:1 options:RKMatchNoOptions]))), nil);
  resultRange = NSMakeRange(0xdeadbeef, 0x0badc0de);
  STAssertTrueNoThrow((NSEqualRanges(NSMakeRange(6, 3), (resultRange = [regex rangeForCharacters:[subjectString UTF8String] length:subjectLength inRange:NSMakeRange(0, subjectLength) captureIndex:2 options:RKMatchNoOptions]))), nil);
  resultRange = NSMakeRange(0xdeadbeef, 0x0badc0de);
  STAssertTrueNoThrow((NSEqualRanges(NSMakeRange(10, 5), (resultRange = [regex rangeForCharacters:[subjectString UTF8String] length:subjectLength inRange:NSMakeRange(0, subjectLength) captureIndex:3 options:RKMatchNoOptions]))), nil);


  resultRange = NSMakeRange(0xdeadbeef, 0x0badc0de);
  STAssertTrueNoThrow((NSEqualRanges(NSMakeRange(0, 15), (resultRange = [regex rangeForCharacters:[subjectString UTF8String] length:subjectLength inRange:NSMakeRange(0, 15) captureIndex:0 options:RKMatchNoOptions]))), nil);
  resultRange = NSMakeRange(0xdeadbeef, 0x0badc0de);
  STAssertTrueNoThrow((NSEqualRanges(NSMakeRange(0, 5), (resultRange = [regex rangeForCharacters:[subjectString UTF8String] length:subjectLength inRange:NSMakeRange(0, 15) captureIndex:1 options:RKMatchNoOptions]))), nil);
  resultRange = NSMakeRange(0xdeadbeef, 0x0badc0de);
  STAssertTrueNoThrow((NSEqualRanges(NSMakeRange(6, 3), (resultRange = [regex rangeForCharacters:[subjectString UTF8String] length:subjectLength inRange:NSMakeRange(0, 15) captureIndex:2 options:RKMatchNoOptions]))), nil);
  resultRange = NSMakeRange(0xdeadbeef, 0x0badc0de);
  STAssertTrueNoThrow((NSEqualRanges(NSMakeRange(10, 5), (resultRange = [regex rangeForCharacters:[subjectString UTF8String] length:subjectLength inRange:NSMakeRange(0, 15) captureIndex:3 options:RKMatchNoOptions]))), nil);


  resultRange = NSMakeRange(0xdeadbeef, 0x0badc0de);
  STAssertTrueNoThrow((NSEqualRanges(NSMakeRange(NSNotFound, 0), (resultRange = [regex rangeForCharacters:[subjectString UTF8String] length:subjectLength inRange:NSMakeRange(0, 14) captureIndex:0 options:RKMatchNoOptions]))), nil);
  resultRange = NSMakeRange(0xdeadbeef, 0x0badc0de);
  STAssertTrueNoThrow((NSEqualRanges(NSMakeRange(NSNotFound, 0), (resultRange = [regex rangeForCharacters:[subjectString UTF8String] length:subjectLength inRange:NSMakeRange(0, 14) captureIndex:1 options:RKMatchNoOptions]))), nil);
  resultRange = NSMakeRange(0xdeadbeef, 0x0badc0de);
  STAssertTrueNoThrow((NSEqualRanges(NSMakeRange(NSNotFound, 0), (resultRange = [regex rangeForCharacters:[subjectString UTF8String] length:subjectLength inRange:NSMakeRange(0, 14) captureIndex:2 options:RKMatchNoOptions]))), nil);
  resultRange = NSMakeRange(0xdeadbeef, 0x0badc0de);
  STAssertTrueNoThrow((NSEqualRanges(NSMakeRange(NSNotFound, 0), (resultRange = [regex rangeForCharacters:[subjectString UTF8String] length:subjectLength inRange:NSMakeRange(0, 14) captureIndex:3 options:RKMatchNoOptions]))), nil);
  
  resultRange = NSMakeRange(0xdeadbeef, 0x0badc0de);
  STAssertTrueNoThrow((NSEqualRanges(NSMakeRange(NSNotFound, 0), (resultRange = [regex rangeForCharacters:[subjectString UTF8String] length:subjectLength inRange:NSMakeRange(1, 17) captureIndex:0 options:RKMatchNoOptions]))), nil);
  resultRange = NSMakeRange(0xdeadbeef, 0x0badc0de);
  STAssertTrueNoThrow((NSEqualRanges(NSMakeRange(NSNotFound, 0), (resultRange = [regex rangeForCharacters:[subjectString UTF8String] length:subjectLength inRange:NSMakeRange(1, 17) captureIndex:1 options:RKMatchNoOptions]))), nil);
  resultRange = NSMakeRange(0xdeadbeef, 0x0badc0de);
  STAssertTrueNoThrow((NSEqualRanges(NSMakeRange(NSNotFound, 0), (resultRange = [regex rangeForCharacters:[subjectString UTF8String] length:subjectLength inRange:NSMakeRange(1, 17) captureIndex:2 options:RKMatchNoOptions]))), nil);
  resultRange = NSMakeRange(0xdeadbeef, 0x0badc0de);
  STAssertTrueNoThrow((NSEqualRanges(NSMakeRange(NSNotFound, 0), (resultRange = [regex rangeForCharacters:[subjectString UTF8String] length:subjectLength inRange:NSMakeRange(1, 17) captureIndex:3 options:RKMatchNoOptions]))), nil);
  

  resultRange = NSMakeRange(0xdeadbeef, 0x0badc0de);
  STAssertThrowsSpecificNamed((NSEqualRanges(NSMakeRange(NSNotFound, 0), (resultRange = [regex rangeForCharacters:[subjectString UTF8String] length:subjectLength inRange:NSMakeRange(1, 99) captureIndex:3 options:RKMatchNoOptions]))), NSException, NSRangeException, nil);

  resultRange = NSMakeRange(0xdeadbeef, 0x0badc0de);
  STAssertThrowsSpecificNamed((NSEqualRanges(NSMakeRange(NSNotFound, 0), (resultRange = [regex rangeForCharacters:[subjectString UTF8String] length:subjectLength inRange:NSMakeRange(0, subjectLength) captureIndex:4 options:RKMatchNoOptions]))), NSException, NSInvalidArgumentException, nil);
}


- (void)testRangesForCharacters
{
  NSString *regexString = @"^(Match)\\s+(?<huh>the|or|is)\\s+(MAGIC)";
  NSString *subjectString = @"Match the MAGIC in this string";
  RKUInteger subjectLength = [subjectString length], captureCount = 0, x = 0;
  NSRange *matchRanges = NULL, *resultRanges = NULL;
  
  RKRegex *regex = [RKRegex regexWithRegexString:regexString options:0];
  STAssertNotNil(regex, nil); if(regex == nil) { return; }
  
  captureCount = [regex captureCount];
  STAssertTrue(captureCount == 4, @"captureCount is %u", captureCount); if(captureCount != 4) { return; }
    
  matchRanges = alloca(captureCount * sizeof(NSRange));
  STAssertTrue(matchRanges != NULL, nil); if(matchRanges == NULL) { return; }
  
  for(x = 0; x < captureCount; x++) { matchRanges[x] = NSMakeRange(0xdeadbeef, 0x0badc0de); }  


  STAssertTrueNoThrow(((resultRanges = [regex rangesForCharacters:[subjectString UTF8String] length:subjectLength inRange:NSMakeRange(0, subjectLength) options:RKMatchNoOptions]) != NULL), nil);
  // {0, 15}, {0, 5}, {6, 3}, {10, 5}
  STAssertTrue(NSEqualRanges(NSMakeRange(0, 15), resultRanges[0]), nil);
  STAssertTrue(NSEqualRanges(NSMakeRange(0, 5), resultRanges[1]), nil);
  STAssertTrue(NSEqualRanges(NSMakeRange(6, 3), resultRanges[2]), nil);
  STAssertTrue(NSEqualRanges(NSMakeRange(10, 5), resultRanges[3]), nil);

  STAssertTrueNoThrow(((resultRanges = [regex rangesForCharacters:[subjectString UTF8String] length:subjectLength inRange:NSMakeRange(0, 15) options:RKMatchNoOptions]) != NULL), nil);
  // {0, 15}, {0, 5}, {6, 3}, {10, 5}
  STAssertTrue(NSEqualRanges(NSMakeRange(0, 15), resultRanges[0]), nil);
  STAssertTrue(NSEqualRanges(NSMakeRange(0, 5), resultRanges[1]), nil);
  STAssertTrue(NSEqualRanges(NSMakeRange(6, 3), resultRanges[2]), nil);
  STAssertTrue(NSEqualRanges(NSMakeRange(10, 5), resultRanges[3]), nil);

  STAssertTrueNoThrow(((resultRanges = [regex rangesForCharacters:[subjectString UTF8String] length:subjectLength inRange:NSMakeRange(1, 15) options:RKMatchNoOptions]) == NULL), nil);

  STAssertTrueNoThrow(((resultRanges = [regex rangesForCharacters:[subjectString UTF8String] length:subjectLength inRange:NSMakeRange(subjectLength, 0) options:RKMatchNoOptions]) == NULL), nil);
  STAssertThrowsSpecificNamed((resultRanges = [regex rangesForCharacters:[subjectString UTF8String] length:subjectLength inRange:NSMakeRange(subjectLength + 1, 0) options:RKMatchNoOptions]), NSException, NSRangeException, nil);
  STAssertThrowsSpecificNamed((resultRanges = [regex rangesForCharacters:[subjectString UTF8String] length:subjectLength inRange:NSMakeRange(subjectLength, 1) options:RKMatchNoOptions]), NSException, NSRangeException, nil);

  STAssertThrowsSpecificNamed((resultRanges = [regex rangesForCharacters:NULL length:subjectLength inRange:NSMakeRange(0, 100) options:RKMatchNoOptions]), NSException, NSInvalidArgumentException, nil);
}



- (void)testCaptureNameCornerCases
{
  RKUInteger captureCount = 0, x = 0;
  NSRange *matchRanges = NULL;
  NSString *regexString = NULL;
  RKRegex *regex = NULL;
  
  regexString = @"(?<date> (?<year>(\\d\\d)?\\d\\d) - (?<month>\\d\\d) - (?<day>\\d\\d) )";
  STAssertTrueNoThrow((regex = [RKRegex regexWithRegexString:regexString options:0]) != NULL, nil);

  captureCount = [regex captureCount];
  STAssertTrue(captureCount == 6, @"captureCount is %u", captureCount); if(captureCount != 6) { return; }
  
  NSArray *regexCaptureNameArray = [regex captureNameArray];
  STAssertNotNil(regexCaptureNameArray, nil);
  STAssertTrue([regexCaptureNameArray count] == 6, @"count: %u", [regexCaptureNameArray count]);
  
  STAssertTrue([[regexCaptureNameArray objectAtIndex:0] isEqual:[NSNull null]], @"== %@", [regexCaptureNameArray objectAtIndex:0]);
  STAssertTrue([[regexCaptureNameArray objectAtIndex:1] isEqualToString:@"date"], @"== %@", [regexCaptureNameArray objectAtIndex:1]);
  STAssertTrue([[regexCaptureNameArray objectAtIndex:2] isEqualToString:@"year"], @"== %@", [regexCaptureNameArray objectAtIndex:2]);
  STAssertTrue([[regexCaptureNameArray objectAtIndex:3] isEqual:[NSNull null]], @"== %@", [regexCaptureNameArray objectAtIndex:3]);
  STAssertTrue([[regexCaptureNameArray objectAtIndex:4] isEqualToString:@"month"], @"== %@", [regexCaptureNameArray objectAtIndex:4]);
  STAssertTrue([[regexCaptureNameArray objectAtIndex:5] isEqualToString:@"day"], @"== %@", [regexCaptureNameArray objectAtIndex:5]);
  
  matchRanges = alloca(captureCount * sizeof(NSRange));
  STAssertTrue(matchRanges != NULL, nil); if(matchRanges == NULL) { return; }
  
  STAssertThrowsSpecificNamed([regex captureIndexForCaptureName:nil], NSException, NSInvalidArgumentException, nil);
  STAssertThrowsSpecificNamed([regex captureIndexForCaptureName:@"Doesn't exist"], NSException, RKRegexCaptureReferenceException, nil);
  STAssertTrueNoThrow(([regex captureIndexForCaptureName:@"date"] == 1), nil);
  STAssertTrueNoThrow(([regex captureIndexForCaptureName:@"year"] == 2), nil);
  STAssertTrueNoThrow(([regex captureIndexForCaptureName:@"month"] == 4), nil);
  STAssertTrueNoThrow(([regex captureIndexForCaptureName:@"day"] == 5), nil);

  for(x = 0; x < captureCount; x++) { matchRanges[x] = NSMakeRange(NSNotFound, 0); }
  STAssertThrowsSpecificNamed([regex captureIndexForCaptureName:NULL inMatchedRanges:matchRanges], NSException, NSInvalidArgumentException, nil);
  STAssertThrowsSpecificNamed([regex captureIndexForCaptureName:@"Doesn't exist" inMatchedRanges:matchRanges], NSException, RKRegexCaptureReferenceException, nil);
  STAssertThrowsSpecificNamed([regex captureIndexForCaptureName:@"date" inMatchedRanges:NULL], NSException, NSInvalidArgumentException, nil);
  STAssertTrueNoThrow(([regex captureIndexForCaptureName:@"date" inMatchedRanges:matchRanges] == NSNotFound), nil);
  STAssertTrueNoThrow(([regex captureIndexForCaptureName:@"year" inMatchedRanges:matchRanges] == NSNotFound), nil);
  STAssertTrueNoThrow(([regex captureIndexForCaptureName:@"month" inMatchedRanges:matchRanges] == NSNotFound), nil);
  STAssertTrueNoThrow(([regex captureIndexForCaptureName:@"day" inMatchedRanges:matchRanges] == NSNotFound), nil);

  for(x = 0; x < captureCount; x++) { matchRanges[x] = NSMakeRange(0, 0); }
  STAssertTrueNoThrow(([regex captureIndexForCaptureName:@"date" inMatchedRanges:matchRanges] == 1), nil);
  STAssertTrueNoThrow(([regex captureIndexForCaptureName:@"year" inMatchedRanges:matchRanges] == 2), nil);
  STAssertTrueNoThrow(([regex captureIndexForCaptureName:@"month" inMatchedRanges:matchRanges] == 4), nil);
  STAssertTrueNoThrow(([regex captureIndexForCaptureName:@"day" inMatchedRanges:matchRanges] == 5), nil);
  
  STAssertTrueNoThrow(([regex captureNameForCaptureIndex:0] == NULL), nil);
  STAssertTrueNoThrow(([[regex captureNameForCaptureIndex:1] isEqualToString:@"date"] == YES), nil);
  STAssertTrueNoThrow(([[regex captureNameForCaptureIndex:2] isEqualToString:@"year"] == YES), nil);
  STAssertTrueNoThrow(([regex captureNameForCaptureIndex:3] == NULL), nil);
  STAssertTrueNoThrow(([[regex captureNameForCaptureIndex:4] isEqualToString:@"month"] == YES), nil);
  STAssertTrueNoThrow(([[regex captureNameForCaptureIndex:5] isEqualToString:@"day"] == YES), nil);
  STAssertThrowsSpecificNamed([regex captureNameForCaptureIndex:6], NSException, NSInvalidArgumentException, nil);
  STAssertThrowsSpecificNamed([regex captureNameForCaptureIndex:7], NSException, NSInvalidArgumentException, nil);

  STAssertThrowsSpecificNamed([regex isValidCaptureName:NULL], NSException, NSInvalidArgumentException, nil);
  STAssertTrueNoThrow(([regex isValidCaptureName:@""] == NO), nil);
  STAssertTrueNoThrow(([regex isValidCaptureName:@"date"] == YES), nil);
  STAssertTrueNoThrow(([regex isValidCaptureName:@"year"] == YES), nil);
  STAssertTrueNoThrow(([regex isValidCaptureName:@"month"] == YES), nil);
  STAssertTrueNoThrow(([regex isValidCaptureName:@"day"] == YES), nil);


  regexString = @"( ((\\d\\d)?\\d\\d) - (\\d\\d) - (\\d\\d) )";
  STAssertTrueNoThrow((regex = [RKRegex regexWithRegexString:regexString options:0]) != NULL, nil);
  captureCount = [regex captureCount];
  STAssertTrue(captureCount == 6, @"captureCount is %u", captureCount); if(captureCount != 6) { return; }

  STAssertTrueNoThrow((regexCaptureNameArray = [regex captureNameArray]) == NULL, nil);
  
  matchRanges = alloca(captureCount * sizeof(NSRange));
  STAssertTrue(matchRanges != NULL, nil); if(matchRanges == NULL) { return; }
  
  STAssertThrowsSpecificNamed([regex captureIndexForCaptureName:nil], NSException, NSInvalidArgumentException, nil);
  STAssertThrowsSpecificNamed([regex captureIndexForCaptureName:@"Doesn't exist"], NSException, RKRegexCaptureReferenceException, nil);
  STAssertThrowsSpecificNamed([regex captureIndexForCaptureName:@"date"], NSException, RKRegexCaptureReferenceException, nil);
  
  for(x = 0; x < captureCount; x++) { matchRanges[x] = NSMakeRange(NSNotFound, 0); }
  STAssertThrowsSpecificNamed([regex captureIndexForCaptureName:NULL inMatchedRanges:matchRanges], NSException, NSInvalidArgumentException, nil);
  STAssertThrowsSpecificNamed([regex captureIndexForCaptureName:@"Doesn't exist" inMatchedRanges:matchRanges], NSException, RKRegexCaptureReferenceException, nil);
  STAssertThrowsSpecificNamed([regex captureIndexForCaptureName:@"date" inMatchedRanges:NULL], NSException, NSInvalidArgumentException, nil);
  STAssertThrowsSpecificNamed([regex captureIndexForCaptureName:@"date" inMatchedRanges:matchRanges], NSException, RKRegexCaptureReferenceException, nil);
  STAssertThrowsSpecificNamed([regex captureIndexForCaptureName:@"year" inMatchedRanges:matchRanges], NSException, RKRegexCaptureReferenceException, nil);
  STAssertThrowsSpecificNamed([regex captureIndexForCaptureName:@"month" inMatchedRanges:matchRanges], NSException, RKRegexCaptureReferenceException, nil);
  STAssertThrowsSpecificNamed([regex captureIndexForCaptureName:@"day" inMatchedRanges:matchRanges], NSException, RKRegexCaptureReferenceException, nil);
  
  for(x = 0; x < captureCount; x++) { matchRanges[x] = NSMakeRange(0, 0); }
  STAssertThrowsSpecificNamed([regex captureIndexForCaptureName:@"date" inMatchedRanges:matchRanges], NSException, RKRegexCaptureReferenceException, nil);
  STAssertThrowsSpecificNamed([regex captureIndexForCaptureName:@"year" inMatchedRanges:matchRanges], NSException, RKRegexCaptureReferenceException, nil);
  STAssertThrowsSpecificNamed([regex captureIndexForCaptureName:@"month" inMatchedRanges:matchRanges], NSException, RKRegexCaptureReferenceException, nil);
  STAssertThrowsSpecificNamed([regex captureIndexForCaptureName:@"day" inMatchedRanges:matchRanges], NSException, RKRegexCaptureReferenceException, nil);
  
  STAssertTrueNoThrow(([regex captureNameForCaptureIndex:0] == NULL), nil);
  STAssertTrueNoThrow(([regex captureNameForCaptureIndex:1] == NULL), nil);
  STAssertTrueNoThrow(([regex captureNameForCaptureIndex:2] == NULL), nil);
  STAssertTrueNoThrow(([regex captureNameForCaptureIndex:3] == NULL), nil);
  STAssertTrueNoThrow(([regex captureNameForCaptureIndex:4] == NULL), nil);
  STAssertTrueNoThrow(([regex captureNameForCaptureIndex:5] == NULL), nil);
  STAssertThrowsSpecificNamed([regex captureNameForCaptureIndex:6], NSException, NSInvalidArgumentException, nil);
  STAssertThrowsSpecificNamed([regex captureNameForCaptureIndex:7], NSException, NSInvalidArgumentException, nil);
  
  STAssertThrowsSpecificNamed([regex isValidCaptureName:NULL], NSException, NSInvalidArgumentException, nil);
  STAssertTrueNoThrow(([regex isValidCaptureName:@""] == NO), nil);
  STAssertTrueNoThrow(([regex isValidCaptureName:@"date"] == NO), nil);
  STAssertTrueNoThrow(([regex isValidCaptureName:@"year"] == NO), nil);
  STAssertTrueNoThrow(([regex isValidCaptureName:@"month"] == NO), nil);
  STAssertTrueNoThrow(([regex isValidCaptureName:@"day"] == NO), nil);
  
}

- (void)testDuplicateCaptureNameCornerCases
{
  NSString *regexString = @"(?<date> (?<year>(\\d\\d)?\\d\\d) - (?<month>\\d\\d) - (?<day>\\d\\d) / (?<month>\\d\\d))";
  RKUInteger captureCount = 0, x = 0;
  NSRange *matchRanges = NULL;
  
  STAssertThrowsSpecificNamed([RKRegex regexWithRegexString:regexString options:0], NSException, RKRegexSyntaxErrorException, nil); // needs to have dup names option
  
  RKRegex *regex = [RKRegex regexWithRegexString:regexString options:RKCompileDupNames];
  STAssertNotNil(regex, nil); if(regex == nil) { return; }
  STAssertTrue((captureCount = [regex captureCount]) == 7, @"count: %u", captureCount);
  
  matchRanges = alloca(captureCount * sizeof(NSRange));
  STAssertTrue(matchRanges != NULL, nil); if(matchRanges == NULL) { return; }
  
  NSArray *regexCaptureNameArray = [regex captureNameArray];
  STAssertNotNil(regexCaptureNameArray, nil);
  STAssertTrue([regexCaptureNameArray count] == 7, @"count: %u", [regexCaptureNameArray count]);
  
  STAssertTrue([[regexCaptureNameArray objectAtIndex:0] isEqual:[NSNull null]], @"== %@", [regexCaptureNameArray objectAtIndex:0]);
  STAssertTrue([[regexCaptureNameArray objectAtIndex:1] isEqualToString:@"date"], @"== %@", [regexCaptureNameArray objectAtIndex:1]);
  STAssertTrue([[regexCaptureNameArray objectAtIndex:2] isEqualToString:@"year"], @"== %@", [regexCaptureNameArray objectAtIndex:2]);
  STAssertTrue([[regexCaptureNameArray objectAtIndex:3] isEqual:[NSNull null]], @"== %@", [regexCaptureNameArray objectAtIndex:3]);
  STAssertTrue([[regexCaptureNameArray objectAtIndex:4] isEqualToString:@"month"], @"== %@", [regexCaptureNameArray objectAtIndex:4]);
  STAssertTrue([[regexCaptureNameArray objectAtIndex:5] isEqualToString:@"day"], @"== %@", [regexCaptureNameArray objectAtIndex:5]);
  STAssertTrue([[regexCaptureNameArray objectAtIndex:6] isEqualToString:@"month"], @"== %@", [regexCaptureNameArray objectAtIndex:6]);
  
  STAssertTrueNoThrow(([regex captureNameForCaptureIndex:0] == NULL), nil);
  STAssertTrueNoThrow(([[regex captureNameForCaptureIndex:1] isEqualToString:@"date"] == YES), nil);
  STAssertTrueNoThrow(([[regex captureNameForCaptureIndex:2] isEqualToString:@"year"] == YES), nil);
  STAssertTrueNoThrow(([regex captureNameForCaptureIndex:3] == NULL), nil);
  STAssertTrueNoThrow(([[regex captureNameForCaptureIndex:4] isEqualToString:@"month"] == YES), nil);
  STAssertTrueNoThrow(([[regex captureNameForCaptureIndex:5] isEqualToString:@"day"] == YES), nil);
  STAssertTrueNoThrow(([[regex captureNameForCaptureIndex:6] isEqualToString:@"month"] == YES), nil);
  STAssertThrowsSpecificNamed([regex captureNameForCaptureIndex:7], NSException, NSInvalidArgumentException, nil);
  STAssertThrowsSpecificNamed([regex captureNameForCaptureIndex:8], NSException, NSInvalidArgumentException, nil);
  

  STAssertTrue([regex captureIndexForCaptureName:@"date"] == 1, @"value: %u", [regex captureIndexForCaptureName:@"date"]);
  STAssertTrue([regex captureIndexForCaptureName:@"year"] == 2, @"value: %u", [regex captureIndexForCaptureName:@"year"]);
  STAssertTrue([regex captureIndexForCaptureName:@"month"] == 4, @"value: %u", [regex captureIndexForCaptureName:@"month"]); // Only the lowest index is returned
  STAssertTrue([regex captureIndexForCaptureName:@"day"] == 5, @"value: %u", [regex captureIndexForCaptureName:@"day"]);
  
  STAssertThrowsSpecificNamed([regex captureIndexForCaptureName:nil], NSException, NSInvalidArgumentException, nil);
  STAssertThrowsSpecificNamed([regex captureIndexForCaptureName:@"Doesn't exist"], NSException, RKRegexCaptureReferenceException, nil);
  STAssertTrueNoThrow(([regex captureIndexForCaptureName:@"date"] == 1), nil);
  STAssertTrueNoThrow(([regex captureIndexForCaptureName:@"year"] == 2), nil);
  STAssertTrueNoThrow(([regex captureIndexForCaptureName:@"month"] == 4), nil);
  STAssertTrueNoThrow(([regex captureIndexForCaptureName:@"day"] == 5), nil);
  
  for(x = 0; x < captureCount; x++) { matchRanges[x] = NSMakeRange(NSNotFound, 0); }

  STAssertThrowsSpecificNamed([regex captureIndexForCaptureName:NULL inMatchedRanges:matchRanges], NSException, NSInvalidArgumentException, nil);
  STAssertThrowsSpecificNamed([regex captureIndexForCaptureName:@"Doesn't exist" inMatchedRanges:matchRanges], NSException, RKRegexCaptureReferenceException, nil);
  STAssertThrowsSpecificNamed([regex captureIndexForCaptureName:@"date" inMatchedRanges:NULL], NSException, NSInvalidArgumentException, nil);
  STAssertTrueNoThrow(([regex captureIndexForCaptureName:@"date" inMatchedRanges:matchRanges] == NSNotFound), nil);
  STAssertTrueNoThrow(([regex captureIndexForCaptureName:@"year" inMatchedRanges:matchRanges] == NSNotFound), nil);
  STAssertTrueNoThrow(([regex captureIndexForCaptureName:@"month" inMatchedRanges:matchRanges] == NSNotFound), nil);
  STAssertTrueNoThrow(([regex captureIndexForCaptureName:@"day" inMatchedRanges:matchRanges] == NSNotFound), nil);
  
  for(x = 0; x < captureCount; x++) { matchRanges[x] = NSMakeRange(0, 0); }
  STAssertTrueNoThrow(([regex captureIndexForCaptureName:@"date" inMatchedRanges:matchRanges] == 1), nil);
  STAssertTrueNoThrow(([regex captureIndexForCaptureName:@"year" inMatchedRanges:matchRanges] == 2), nil);
  STAssertTrueNoThrow(([regex captureIndexForCaptureName:@"month" inMatchedRanges:matchRanges] == 4), nil);
  STAssertTrueNoThrow(([regex captureIndexForCaptureName:@"day" inMatchedRanges:matchRanges] == 5), nil);

  matchRanges[4] = NSMakeRange(NSNotFound, 0);
  STAssertTrueNoThrow(([regex captureIndexForCaptureName:@"month" inMatchedRanges:matchRanges] == 6), @"Got: %lu", (unsigned long)[regex captureIndexForCaptureName:@"month" inMatchedRanges:matchRanges]);
  matchRanges[6] = NSMakeRange(NSNotFound, 0);
  STAssertTrueNoThrow(([regex captureIndexForCaptureName:@"month" inMatchedRanges:matchRanges] == NSNotFound), nil);

  STAssertThrows([regex captureIndexForCaptureName:@"UNKNOWN"], nil);
  STAssertThrows([regex captureIndexForCaptureName:nil], nil);
}


- (void)testDuplicateCaptureNameJOptionCornerCases
{
  NSString *regexString = @"(?J)(?<date> (?<year>(\\d\\d)?\\d\\d) - (?<month>\\d\\d) - (?<day>\\d\\d) / (?<month>\\d\\d))";
  RKUInteger captureCount = 0, x = 0;
  NSRange *matchRanges = NULL;
  
  RKRegex *regex = [RKRegex regexWithRegexString:regexString options:RKCompileNoOptions];
  STAssertNotNil(regex, nil); if(regex == nil) { return; }
  STAssertTrue((captureCount = [regex captureCount]) == 7, @"count: %u", captureCount);
  
  matchRanges = alloca(captureCount * sizeof(NSRange));
  STAssertTrue(matchRanges != NULL, nil); if(matchRanges == NULL) { return; }
  
  NSArray *regexCaptureNameArray = [regex captureNameArray];
  STAssertNotNil(regexCaptureNameArray, nil);
  STAssertTrue([regexCaptureNameArray count] == 7, @"count: %u", [regexCaptureNameArray count]);
  
  STAssertTrue([[regexCaptureNameArray objectAtIndex:0] isEqual:[NSNull null]], @"== %@", [regexCaptureNameArray objectAtIndex:0]);
  STAssertTrue([[regexCaptureNameArray objectAtIndex:1] isEqualToString:@"date"], @"== %@", [regexCaptureNameArray objectAtIndex:1]);
  STAssertTrue([[regexCaptureNameArray objectAtIndex:2] isEqualToString:@"year"], @"== %@", [regexCaptureNameArray objectAtIndex:2]);
  STAssertTrue([[regexCaptureNameArray objectAtIndex:3] isEqual:[NSNull null]], @"== %@", [regexCaptureNameArray objectAtIndex:3]);
  STAssertTrue([[regexCaptureNameArray objectAtIndex:4] isEqualToString:@"month"], @"== %@", [regexCaptureNameArray objectAtIndex:4]);
  STAssertTrue([[regexCaptureNameArray objectAtIndex:5] isEqualToString:@"day"], @"== %@", [regexCaptureNameArray objectAtIndex:5]);
  STAssertTrue([[regexCaptureNameArray objectAtIndex:6] isEqualToString:@"month"], @"== %@", [regexCaptureNameArray objectAtIndex:6]);
  
  STAssertTrueNoThrow(([regex captureNameForCaptureIndex:0] == NULL), nil);
  STAssertTrueNoThrow(([[regex captureNameForCaptureIndex:1] isEqualToString:@"date"] == YES), nil);
  STAssertTrueNoThrow(([[regex captureNameForCaptureIndex:2] isEqualToString:@"year"] == YES), nil);
  STAssertTrueNoThrow(([regex captureNameForCaptureIndex:3] == NULL), nil);
  STAssertTrueNoThrow(([[regex captureNameForCaptureIndex:4] isEqualToString:@"month"] == YES), nil);
  STAssertTrueNoThrow(([[regex captureNameForCaptureIndex:5] isEqualToString:@"day"] == YES), nil);
  STAssertTrueNoThrow(([[regex captureNameForCaptureIndex:6] isEqualToString:@"month"] == YES), nil);
  STAssertThrowsSpecificNamed([regex captureNameForCaptureIndex:7], NSException, NSInvalidArgumentException, nil);
  STAssertThrowsSpecificNamed([regex captureNameForCaptureIndex:8], NSException, NSInvalidArgumentException, nil);
  
  
  STAssertTrue([regex captureIndexForCaptureName:@"date"] == 1, @"value: %u", [regex captureIndexForCaptureName:@"date"]);
  STAssertTrue([regex captureIndexForCaptureName:@"year"] == 2, @"value: %u", [regex captureIndexForCaptureName:@"year"]);
  STAssertTrue([regex captureIndexForCaptureName:@"month"] == 4, @"value: %u", [regex captureIndexForCaptureName:@"month"]); // Only the lowest index is returned
  STAssertTrue([regex captureIndexForCaptureName:@"day"] == 5, @"value: %u", [regex captureIndexForCaptureName:@"day"]);
  
  STAssertThrowsSpecificNamed([regex captureIndexForCaptureName:nil], NSException, NSInvalidArgumentException, nil);
  STAssertThrowsSpecificNamed([regex captureIndexForCaptureName:@"Doesn't exist"], NSException, RKRegexCaptureReferenceException, nil);
  STAssertTrueNoThrow(([regex captureIndexForCaptureName:@"date"] == 1), nil);
  STAssertTrueNoThrow(([regex captureIndexForCaptureName:@"year"] == 2), nil);
  STAssertTrueNoThrow(([regex captureIndexForCaptureName:@"month"] == 4), nil);
  STAssertTrueNoThrow(([regex captureIndexForCaptureName:@"day"] == 5), nil);
  
  for(x = 0; x < captureCount; x++) { matchRanges[x] = NSMakeRange(NSNotFound, 0); }
  
  STAssertThrowsSpecificNamed([regex captureIndexForCaptureName:NULL inMatchedRanges:matchRanges], NSException, NSInvalidArgumentException, nil);
  STAssertThrowsSpecificNamed([regex captureIndexForCaptureName:@"Doesn't exist" inMatchedRanges:matchRanges], NSException, RKRegexCaptureReferenceException, nil);
  STAssertThrowsSpecificNamed([regex captureIndexForCaptureName:@"date" inMatchedRanges:NULL], NSException, NSInvalidArgumentException, nil);
  STAssertTrueNoThrow(([regex captureIndexForCaptureName:@"date" inMatchedRanges:matchRanges] == NSNotFound), nil);
  STAssertTrueNoThrow(([regex captureIndexForCaptureName:@"year" inMatchedRanges:matchRanges] == NSNotFound), nil);
  STAssertTrueNoThrow(([regex captureIndexForCaptureName:@"month" inMatchedRanges:matchRanges] == NSNotFound), nil);
  STAssertTrueNoThrow(([regex captureIndexForCaptureName:@"day" inMatchedRanges:matchRanges] == NSNotFound), nil);
  
  for(x = 0; x < captureCount; x++) { matchRanges[x] = NSMakeRange(0, 0); }
  STAssertTrueNoThrow(([regex captureIndexForCaptureName:@"date" inMatchedRanges:matchRanges] == 1), nil);
  STAssertTrueNoThrow(([regex captureIndexForCaptureName:@"year" inMatchedRanges:matchRanges] == 2), nil);
  STAssertTrueNoThrow(([regex captureIndexForCaptureName:@"month" inMatchedRanges:matchRanges] == 4), nil);
  STAssertTrueNoThrow(([regex captureIndexForCaptureName:@"day" inMatchedRanges:matchRanges] == 5), nil);
  
  matchRanges[4] = NSMakeRange(NSNotFound, 0);
  STAssertTrueNoThrow(([regex captureIndexForCaptureName:@"month" inMatchedRanges:matchRanges] == 6), @"Got: %lu", (unsigned long)[regex captureIndexForCaptureName:@"month" inMatchedRanges:matchRanges]);
  matchRanges[6] = NSMakeRange(NSNotFound, 0);
  STAssertTrueNoThrow(([regex captureIndexForCaptureName:@"month" inMatchedRanges:matchRanges] == NSNotFound), nil);
  
  STAssertThrows([regex captureIndexForCaptureName:@"UNKNOWN"], nil);
  STAssertThrows([regex captureIndexForCaptureName:nil], nil);
}


- (void)testRegexString
{
  RKRegex *regex = [RKRegex regexWithRegexString:[NSString stringWithFormat:@"123"] options:0];
  STAssertTrue([[regex regexString] isEqualToString:[NSString stringWithFormat:@"123"]], nil);
  regex = [RKRegex regexWithRegexString:[NSString stringWithFormat:@"^(Match)\\s+the\\s+(MAGIC)$"] options:0];
  STAssertTrue([[regex regexString] isEqualToString:[NSString stringWithFormat:@"^(Match)\\s+the\\s+(MAGIC)$"]], nil);
}

- (void)testValidRegexString
{
  STAssertTrueNoThrow([RKRegex isValidRegexString:@"123" options:0], nil);
  STAssertTrueNoThrow([RKRegex isValidRegexString:@"^(Match)\\s+the\\s+(MAGIC)$" options:0], nil);
  
  STAssertTrueNoThrow([RKRegex isValidRegexString:@"(?<pn> \\( ( (?>[^()]+) | (?&pn) )* \\) )" options:0], nil);
  STAssertTrueNoThrow([RKRegex isValidRegexString:@"\\( ( ( (?>[^()]+) | (?R) )* ) \\)" options:0], nil);
  STAssertTrueNoThrow([RKRegex isValidRegexString:@"\\( ( ( (?>[^()]+) | (?R) )* ) \\)" options:0], nil);
  STAssertTrueNoThrow([RKRegex isValidRegexString:@"\\( ( ( ([^()]+) | (?R) )* ) \\)" options:0], nil);
  
  STAssertFalseNoThrow([RKRegex isValidRegexString:@"^(Match)\\s+the\\s+((MAGIC)$" options:0], nil);
  STAssertFalseNoThrow([RKRegex isValidRegexString:@"(?<pn> \\( ( (?>[^()]+) | (?&xq) )* \\) )" options:0], nil);
  
  STAssertFalseNoThrow([RKRegex isValidRegexString:nil options:0], nil);
  STAssertFalseNoThrow([RKRegex isValidRegexString:@"\\( ( ( ([^()]+) | (?R) )* ) \\)" options:0xffffffff], nil);
}

- (void)testCacheExists
{
  STAssertTrueNoThrow(([RKRegex regexCache] != NULL), nil);
  STAssertTrueNoThrow(([[RKRegex regexCache] status] != NULL), nil); 
}

- (void)testNSCopying
{
  id copiedRegex = nil;
  RKRegex *regex = [RKRegex regexWithRegexString:@"\\s*(.*\\S+)\\s*" options:RKCompileNoOptions];
  BOOL conforms = [regex conformsToProtocol:@protocol(NSCopying)];
  STAssertNotNil(regex, nil);
  STAssertTrue((conforms == YES), nil);
  if((conforms == NO) || (regex == nil)) { return; }
  
  [[RKRegex regexCache] clearCache];
  STAssertTrue(([[RKRegex regexCache] cacheCount] == 0), @"Count = %d", [[RKRegex regexCache] cacheCount]);
  [[RKRegex regexCache] setCacheAddingEnabled:YES];
  [[RKRegex regexCache] setCacheLookupEnabled:YES]; // Known state
  
  regex = [RKRegex regexWithRegexString:@"\\s*(.*\\S+)\\s*" options:RKCompileNoOptions];
  STAssertNotNil((copiedRegex = [[regex copy] autorelease]), nil);
  STAssertTrue((copiedRegex != regex), nil);
  STAssertTrue(([copiedRegex hash] == [regex hash]), nil);

  STAssertTrue(([[RKRegex regexCache] cacheCount] == 1), @"Count = %d", [[RKRegex regexCache] cacheCount]);

  regex = [RKRegex regexWithRegexString:@"\\s*(.*\\S+)\\s*" options:RKCompileNoOptions]; // In cache check
  STAssertNotNil((copiedRegex = [[regex copy] autorelease]), nil);
  STAssertTrue((copiedRegex != regex), nil);
  STAssertTrue(([copiedRegex hash] == [regex hash]), nil);
  
  regex = [RKRegex regexWithRegexString:@"\\s*(.*\\S+)\\s*" options:RKCompileUngreedy];
  STAssertNotNil((copiedRegex = [[regex copy] autorelease]), nil);
  STAssertTrue((copiedRegex != regex), nil);
  STAssertTrue(([copiedRegex hash] == [regex hash]), nil);

  //
  
  regex = [RKRegex regexWithRegexString:@"(?<pn> \\( ( (?>[^()]+) | (?&pn) )* \\) )" options:RKCompileNoOptions];
  STAssertNotNil((copiedRegex = [[regex copy] autorelease]), nil);
  STAssertTrue((copiedRegex != regex), nil);
  STAssertTrue(([copiedRegex hash] == [regex hash]), nil);

  regex = [RKRegex regexWithRegexString:@"(?<pn> \\( ( (?>[^()]+) | (?&pn) )* \\) )" options:(RKCompileMultiline | RKCompileCaseless | RKCompileNewlineCR)];
  STAssertNotNil((copiedRegex = [[regex copy] autorelease]), nil);
  STAssertTrue((copiedRegex != regex), nil);
  STAssertTrue(([copiedRegex hash] == [regex hash]), nil);

  STAssertTrue(([[RKRegex regexCache] cacheCount] == 4), @"Count = %d", [[RKRegex regexCache] cacheCount]);

  regex = [RKRegex regexWithRegexString:@"(?<pn> \\( ( (?>[^()]+) | (?&pn) )* \\) )" options:(RKCompileMultiline | RKCompileCaseless | RKCompileNewlineCR)]; // In cache check
  STAssertNotNil((copiedRegex = [[regex copy] autorelease]), nil);
  STAssertTrue((copiedRegex != regex), nil);
  STAssertTrue(([copiedRegex hash] == [regex hash]), nil);
  
  //
  
  regex = [RKRegex regexWithRegexString:@"^(Match)\\s+the\\s+(MAGIC)$" options:RKCompileNoOptions];
  STAssertNotNil((copiedRegex = [[regex copy] autorelease]), nil);
  STAssertTrue((copiedRegex != regex), nil);
  STAssertTrue(([copiedRegex hash] == [regex hash]), nil);
  
  regex = [RKRegex regexWithRegexString:@"^(Match)\\s+the\\s+(MAGIC)$" options:(RKCompileMultiline | RKCompileCaseless | RKCompileNewlineCR)];
  STAssertNotNil((copiedRegex = [[regex copy] autorelease]), nil);
  STAssertTrue((copiedRegex != regex), nil);
  STAssertTrue(([copiedRegex hash] == [regex hash]), nil);

  //
  
  regex = [RKRegex regexWithRegexString:@"\\( ( ( (?>[^()]+) | (?R) )* ) \\)" options:RKCompileNoOptions];
  STAssertNotNil((copiedRegex = [[regex copy] autorelease]), nil);
  STAssertTrue((copiedRegex != regex), nil);
  STAssertTrue(([copiedRegex hash] == [regex hash]), nil);
  
  regex = [RKRegex regexWithRegexString:@"\\( ( ( (?>[^()]+) | (?R) )* ) \\)" options:(RKCompileMultiline | RKCompileCaseless | RKCompileNewlineCR)];
  STAssertNotNil((copiedRegex = [[regex copy] autorelease]), nil);
  STAssertTrue((copiedRegex != regex), nil);
  STAssertTrue(([copiedRegex hash] == [regex hash]), nil);

  [[RKRegex regexCache] clearCache];
  [[RKRegex regexCache] setCacheAddingEnabled:NO];
  [[RKRegex regexCache] setCacheLookupEnabled:NO]; // Known state
  

  regex = [RKRegex regexWithRegexString:@"\\s*(.*\\S+)\\s*" options:RKCompileNoOptions];
  STAssertNotNil((copiedRegex = [[regex copy] autorelease]), nil);
  STAssertTrue((copiedRegex != regex), nil);
  STAssertTrue(([copiedRegex hash] == [regex hash]), nil);
  
  regex = [RKRegex regexWithRegexString:@"\\s*(.*\\S+)\\s*" options:RKCompileNoOptions]; // (not) In cache check
  STAssertNotNil((copiedRegex = [[regex copy] autorelease]), nil);
  STAssertTrue((copiedRegex != regex), nil);
  STAssertTrue(([copiedRegex hash] == [regex hash]), nil);
  
  regex = [RKRegex regexWithRegexString:@"\\s*(.*\\S+)\\s*" options:RKCompileUngreedy];
  STAssertNotNil((copiedRegex = [[regex copy] autorelease]), nil);
  STAssertTrue((copiedRegex != regex), nil);
  STAssertTrue(([copiedRegex hash] == [regex hash]), nil);
  
  //
  
  regex = [RKRegex regexWithRegexString:@"(?<pn> \\( ( (?>[^()]+) | (?&pn) )* \\) )" options:RKCompileNoOptions];
  STAssertNotNil((copiedRegex = [[regex copy] autorelease]), nil);
  STAssertTrue((copiedRegex != regex), nil);
  STAssertTrue(([copiedRegex hash] == [regex hash]), nil);
  
  regex = [RKRegex regexWithRegexString:@"(?<pn> \\( ( (?>[^()]+) | (?&pn) )* \\) )" options:(RKCompileMultiline | RKCompileCaseless | RKCompileNewlineCR)];
  STAssertNotNil((copiedRegex = [[regex copy] autorelease]), nil);
  STAssertTrue((copiedRegex != regex), nil);
  STAssertTrue(([copiedRegex hash] == [regex hash]), nil);
  
  regex = [RKRegex regexWithRegexString:@"(?<pn> \\( ( (?>[^()]+) | (?&pn) )* \\) )" options:(RKCompileMultiline | RKCompileCaseless | RKCompileNewlineCR)]; // (not) In cache check
  STAssertNotNil((copiedRegex = [[regex copy] autorelease]), nil);
  STAssertTrue((copiedRegex != regex), nil);
  STAssertTrue(([copiedRegex hash] == [regex hash]), nil);

  STAssertTrue(([[RKRegex regexCache] cacheCount] == 0), @"Count = %d", [[RKRegex regexCache] cacheCount]);

  [[RKRegex regexCache] setCacheAddingEnabled:YES];
  [[RKRegex regexCache] setCacheLookupEnabled:YES]; // Known state

}

- (void)testNSCodingEncodeDecode
{
  RKRegex *regex = [RKRegex regexWithRegexString:@"\\s*(.*\\S+)\\s*" options:RKCompileNoOptions];
  BOOL conforms = [regex conformsToProtocol:@protocol(NSCoding)];
  STAssertNotNil(regex, nil);
  STAssertTrue((conforms == YES), nil);
  if((conforms == NO) || (regex == nil)) { return; }

  NSMutableData *data = [NSMutableData data];
  STAssertNotNil(data, nil);
  NSKeyedArchiver *archiver = nil;
  NSKeyedUnarchiver *unarchiver = nil;
  id decodedRegex = nil;

  [[RKRegex regexCache] clearCache];
  STAssertTrue(([[RKRegex regexCache] cacheCount] == 0), @"Count = %d", [[RKRegex regexCache] cacheCount]);
  [[RKRegex regexCache] setCacheAddingEnabled:YES];
  [[RKRegex regexCache] setCacheLookupEnabled:YES]; // Known state
  
  [data setLength:0];
  regex = [RKRegex regexWithRegexString:@"\\s*(.*\\S+)\\s*" options:RKCompileNoOptions];
  STAssertNotNil((archiver = [[[NSKeyedArchiver alloc] initForWritingWithMutableData:data] autorelease]), nil);
  STAssertNoThrow([archiver encodeObject:regex forKey:@"regex"], nil);
  STAssertNoThrow([archiver finishEncoding], nil);

  STAssertTrue([data length] > 0, nil);

  STAssertNotNil((unarchiver = [[[NSKeyedUnarchiver alloc] initForReadingWithData:data] autorelease]), nil);
  STAssertNoThrow((decodedRegex = [unarchiver decodeObjectForKey:@"regex"]), nil);
  STAssertNotNil(decodedRegex, nil);
  STAssertTrue(([regex hash] == [decodedRegex hash]), nil);
  STAssertNoThrow([unarchiver finishDecoding], nil);

  ////
  STAssertTrue(([[RKRegex regexCache] cacheCount] == 1), @"Count = %d", [[RKRegex regexCache] cacheCount]);
  // Exactly the same, but this time we are in the cache, so check that case.
  
  [data setLength:0];
  regex = [RKRegex regexWithRegexString:@"\\s*(.*\\S+)\\s*" options:RKCompileNoOptions];
  STAssertTrue(([[RKRegex regexCache] cacheCount] == 1), @"Count = %d", [[RKRegex regexCache] cacheCount]); // Should be the same
  STAssertNotNil((archiver = [[[NSKeyedArchiver alloc] initForWritingWithMutableData:data] autorelease]), nil);
  STAssertNoThrow([archiver encodeObject:regex forKey:@"regex"], nil);
  STAssertNoThrow([archiver finishEncoding], nil);
  
  STAssertTrue([data length] > 0, nil);
  
  STAssertNotNil((unarchiver = [[[NSKeyedUnarchiver alloc] initForReadingWithData:data] autorelease]), nil);
  STAssertNoThrow((decodedRegex = [unarchiver decodeObjectForKey:@"regex"]), nil);
  STAssertNotNil(decodedRegex, nil);
  STAssertTrue(([regex hash] == [decodedRegex hash]), nil);
  STAssertNoThrow([unarchiver finishDecoding], nil);

  ////
  STAssertTrue(([[RKRegex regexCache] cacheCount] == 1), @"Count = %d", [[RKRegex regexCache] cacheCount]);
  // Exactly the same, in cache, added multiple times
  
  [data setLength:0];
  regex = [RKRegex regexWithRegexString:@"\\s*(.*\\S+)\\s*" options:RKCompileNoOptions];
  STAssertTrue(([[RKRegex regexCache] cacheCount] == 1), @"Count = %d", [[RKRegex regexCache] cacheCount]); // Should be the same
  STAssertNotNil((archiver = [[[NSKeyedArchiver alloc] initForWritingWithMutableData:data] autorelease]), nil);
  STAssertNoThrow([archiver encodeObject:regex forKey:@"regex1"], nil);
  STAssertNoThrow([archiver encodeObject:regex forKey:@"regex2"], nil);
  STAssertNoThrow([archiver finishEncoding], nil);
  
  STAssertTrue([data length] > 0, nil);
  
  STAssertNotNil((unarchiver = [[[NSKeyedUnarchiver alloc] initForReadingWithData:data] autorelease]), nil);
  STAssertNoThrow((decodedRegex = [unarchiver decodeObjectForKey:@"regex1"]), nil);
  STAssertNotNil(decodedRegex, nil);
  STAssertTrue(([regex hash] == [decodedRegex hash]), nil);
  STAssertNoThrow((decodedRegex = [unarchiver decodeObjectForKey:@"regex2"]), nil);
  STAssertNotNil(decodedRegex, nil);
  STAssertTrue(([regex hash] == [decodedRegex hash]), nil);
  STAssertNoThrow([unarchiver finishDecoding], nil);
  

  // w/ option

  [data setLength:0];
  regex = [RKRegex regexWithRegexString:@"\\s*(.*\\S+)\\s*" options:(RKCompileNewlineCRLF)];
  STAssertNotNil((archiver = [[[NSKeyedArchiver alloc] initForWritingWithMutableData:data] autorelease]), nil);
  STAssertNoThrow([archiver encodeObject:regex forKey:@"regex"], nil);
  STAssertNoThrow([archiver finishEncoding], nil);
  
  STAssertTrue([data length] > 0, nil);
  
  STAssertNotNil((unarchiver = [[[NSKeyedUnarchiver alloc] initForReadingWithData:data] autorelease]), nil);
  STAssertNoThrow((decodedRegex = [unarchiver decodeObjectForKey:@"regex"]), nil);
  STAssertNotNil(decodedRegex, nil);
  STAssertTrue(([regex hash] == [decodedRegex hash]), nil);
  STAssertNoThrow([unarchiver finishDecoding], nil);

  // w/ many options
  
  [data setLength:0];
  regex = [RKRegex regexWithRegexString:@"\\s*(.*\\S+)\\s*" options:(RKCompileNewlineCRLF | RKCompileFirstLine | RKCompileDupNames)];
  STAssertNotNil((archiver = [[[NSKeyedArchiver alloc] initForWritingWithMutableData:data] autorelease]), nil);
  STAssertNoThrow([archiver encodeObject:regex forKey:@"regex"], nil);
  STAssertNoThrow([archiver finishEncoding], nil);
  
  STAssertTrue([data length] > 0, nil);
  
  STAssertNotNil((unarchiver = [[[NSKeyedUnarchiver alloc] initForReadingWithData:data] autorelease]), nil);
  STAssertNoThrow((decodedRegex = [unarchiver decodeObjectForKey:@"regex"]), nil);
  STAssertNotNil(decodedRegex, nil);
  STAssertTrue(([regex hash] == [decodedRegex hash]), nil);
  STAssertNoThrow([unarchiver finishDecoding], nil);
  
  STAssertTrue(([[RKRegex regexCache] cacheCount] == 3), @"Count = %d", [[RKRegex regexCache] cacheCount]);  

  // Disable cache and repeat
  [[RKRegex regexCache] clearCache];
  STAssertTrue(([[RKRegex regexCache] cacheCount] == 0), @"Count = %d", [[RKRegex regexCache] cacheCount]);
  [[RKRegex regexCache] setCacheAddingEnabled:NO];
  [[RKRegex regexCache] setCacheLookupEnabled:NO];
  
  [data setLength:0];
  regex = [RKRegex regexWithRegexString:@"\\s*(.*\\S+)\\s*" options:RKCompileNoOptions];
  STAssertNotNil((archiver = [[[NSKeyedArchiver alloc] initForWritingWithMutableData:data] autorelease]), nil);
  STAssertNoThrow([archiver encodeObject:regex forKey:@"regex"], nil);
  STAssertNoThrow([archiver finishEncoding], nil);
  
  STAssertTrue([data length] > 0, nil);
  
  STAssertNotNil((unarchiver = [[[NSKeyedUnarchiver alloc] initForReadingWithData:data] autorelease]), nil);
  STAssertNoThrow((decodedRegex = [unarchiver decodeObjectForKey:@"regex"]), nil);
  STAssertNotNil(decodedRegex, nil);
  STAssertTrue(([regex hash] == [decodedRegex hash]), nil);
  STAssertNoThrow([unarchiver finishDecoding], nil);

  
  ////
  STAssertTrue(([[RKRegex regexCache] cacheCount] == 0), @"Count = %d", [[RKRegex regexCache] cacheCount]);
  // Exactly the same, but non-caching check
  
  [data setLength:0];
  regex = [RKRegex regexWithRegexString:@"\\s*(.*\\S+)\\s*" options:RKCompileNoOptions];
  STAssertTrue(([[RKRegex regexCache] cacheCount] == 0), @"Count = %d", [[RKRegex regexCache] cacheCount]); // Should not be in cache
  STAssertNotNil((archiver = [[[NSKeyedArchiver alloc] initForWritingWithMutableData:data] autorelease]), nil);
  STAssertNoThrow([archiver encodeObject:regex forKey:@"regex"], nil);
  STAssertNoThrow([archiver finishEncoding], nil);
  
  STAssertTrue([data length] > 0, nil);
  
  STAssertNotNil((unarchiver = [[[NSKeyedUnarchiver alloc] initForReadingWithData:data] autorelease]), nil);
  STAssertNoThrow((decodedRegex = [unarchiver decodeObjectForKey:@"regex"]), nil);
  STAssertNotNil(decodedRegex, nil);
  STAssertTrue(([regex hash] == [decodedRegex hash]), nil);
  STAssertNoThrow([unarchiver finishDecoding], nil);

  // Exactly the same, not in cache, added multiple times
  
  [data setLength:0];
  regex = [RKRegex regexWithRegexString:@"\\s*(.*\\S+)\\s*" options:RKCompileNoOptions];
  STAssertTrue(([[RKRegex regexCache] cacheCount] == 0), @"Count = %d", [[RKRegex regexCache] cacheCount]); // Should not be in cache
  STAssertNotNil((archiver = [[[NSKeyedArchiver alloc] initForWritingWithMutableData:data] autorelease]), nil);
  STAssertNoThrow([archiver encodeObject:regex forKey:@"regex1"], nil);
  STAssertNoThrow([archiver encodeObject:regex forKey:@"regex2"], nil);
  STAssertNoThrow([archiver finishEncoding], nil);
  
  STAssertTrue([data length] > 0, nil);
  
  STAssertNotNil((unarchiver = [[[NSKeyedUnarchiver alloc] initForReadingWithData:data] autorelease]), nil);
  STAssertNoThrow((decodedRegex = [unarchiver decodeObjectForKey:@"regex1"]), nil);
  STAssertNotNil(decodedRegex, nil);
  STAssertTrue(([regex hash] == [decodedRegex hash]), nil);
  STAssertNoThrow((decodedRegex = [unarchiver decodeObjectForKey:@"regex2"]), nil);
  STAssertNotNil(decodedRegex, nil);
  STAssertTrue(([regex hash] == [decodedRegex hash]), nil);
  STAssertNoThrow([unarchiver finishDecoding], nil);
  
  
  // w/ option
  
  [data setLength:0];
  regex = [RKRegex regexWithRegexString:@"\\s*(.*\\S+)\\s*" options:(RKCompileNewlineCRLF)];
  STAssertNotNil((archiver = [[[NSKeyedArchiver alloc] initForWritingWithMutableData:data] autorelease]), nil);
  STAssertNoThrow([archiver encodeObject:regex forKey:@"regex"], nil);
  STAssertNoThrow([archiver finishEncoding], nil);
  
  STAssertTrue([data length] > 0, nil);
  
  STAssertNotNil((unarchiver = [[[NSKeyedUnarchiver alloc] initForReadingWithData:data] autorelease]), nil);
  STAssertNoThrow((decodedRegex = [unarchiver decodeObjectForKey:@"regex"]), nil);
  STAssertNotNil(decodedRegex, nil);
  STAssertNoThrow([unarchiver finishDecoding], nil);
  STAssertTrue(([regex hash] == [decodedRegex hash]), nil);
  
  // w/ many options
  
  [data setLength:0];
  regex = [RKRegex regexWithRegexString:@"\\s*(.*\\S+)\\s*" options:(RKCompileNewlineCRLF | RKCompileFirstLine | RKCompileDupNames)];
  STAssertNotNil((archiver = [[[NSKeyedArchiver alloc] initForWritingWithMutableData:data] autorelease]), nil);
  STAssertNoThrow([archiver encodeObject:regex forKey:@"regex"], nil);
  STAssertNoThrow([archiver finishEncoding], nil);
  
  STAssertTrue([data length] > 0, nil);
  
  STAssertNotNil((unarchiver = [[[NSKeyedUnarchiver alloc] initForReadingWithData:data] autorelease]), nil);
  STAssertNoThrow((decodedRegex = [unarchiver decodeObjectForKey:@"regex"]), nil);
  STAssertNotNil(decodedRegex, nil);
  STAssertNoThrow([unarchiver finishDecoding], nil);
  STAssertTrue(([regex hash] == [decodedRegex hash]), nil);
  
  STAssertTrue(([[RKRegex regexCache] cacheCount] == 0), @"Count = %d", [[RKRegex regexCache] cacheCount]);
  
  // Re-enable the cache
  [[RKRegex regexCache] clearCache];
  STAssertTrue(([[RKRegex regexCache] cacheCount] == 0), @"Count = %d", [[RKRegex regexCache] cacheCount]);
  [[RKRegex regexCache] setCacheAddingEnabled:YES];
  [[RKRegex regexCache] setCacheLookupEnabled:YES];

  // And now we encode a regex in XML format, replace the regex string with a regex known to be syntactically incorrect, and feed it back in.

  NSMutableString *encodedString = nil;
  
  [data setLength:0];
  regex = [RKRegex regexWithRegexString:@"\\s*(.*\\S+)\\s*" options:RKCompileNoOptions];
  STAssertNotNil((archiver = [[[NSKeyedArchiver alloc] initForWritingWithMutableData:data] autorelease]), nil);
  [archiver setOutputFormat:NSPropertyListXMLFormat_v1_0];
  STAssertNoThrow([archiver encodeObject:regex forKey:@"regex"], nil);
  STAssertNoThrow([archiver finishEncoding], nil);
  
  STAssertTrue([data length] > 0, nil);
  encodedString = [[[NSMutableString alloc] initWithBytes:[data bytes] length:[data length] encoding:NSUTF8StringEncoding] autorelease];
  [encodedString replaceOccurrencesOfString:@"\\s*(.*\\S+)\\s*" withString:@"\\s*(.*\\S+).s\\" options:NSLiteralSearch range:NSMakeRange(0, [encodedString length])];
  [data setData:[encodedString dataUsingEncoding:NSUTF8StringEncoding]];
  
  STAssertNotNil((unarchiver = [[[NSKeyedUnarchiver alloc] initForReadingWithData:data] autorelease]), nil);
  STAssertThrowsSpecificNamed((decodedRegex = [unarchiver decodeObjectForKey:@"regex"]), NSException, NSInvalidUnarchiveOperationException, nil);
  STAssertNoThrow([unarchiver finishDecoding], nil);

  // Excercise the "Additional info" code path
  
  [data setLength:0];
  regex = [RKRegex regexWithRegexString:@"\\s*(.*\\S+)\\s*" options:RKCompileNoOptions];
  STAssertNotNil((archiver = [[[NSKeyedArchiver alloc] initForWritingWithMutableData:data] autorelease]), nil);
  [archiver setOutputFormat:NSPropertyListXMLFormat_v1_0];
  STAssertNoThrow([archiver encodeObject:regex forKey:@"regex"], nil);
  STAssertNoThrow([archiver finishEncoding], nil);
  
  STAssertTrue([data length] > 0, nil);
  encodedString = [[[NSMutableString alloc] initWithBytes:[data bytes] length:[data length] encoding:NSUTF8StringEncoding] autorelease];
  [encodedString replaceOccurrencesOfString:@"\\s*(.*\\S+)\\s*" withString:@"\\s*(.*\\S+).s\\" options:NSLiteralSearch range:NSMakeRange(0, [encodedString length])];
  [encodedString replaceOccurrencesOfString:[NSString stringWithFormat:@"%d", [RKRegex PCREBuildConfig]] withString:[NSString stringWithFormat:@"%d", [RKRegex PCREBuildConfig] ^ RKBuildConfigUnicodeProperties] options:NSLiteralSearch range:NSMakeRange(0, [encodedString length])];
  [encodedString replaceOccurrencesOfString:[RKRegex PCREVersionString] withString:@"23.42 05-23-2002" options:NSLiteralSearch range:NSMakeRange(0, [encodedString length])];
  [data setData:[encodedString dataUsingEncoding:NSUTF8StringEncoding]];
  
  STAssertNotNil((unarchiver = [[[NSKeyedUnarchiver alloc] initForReadingWithData:data] autorelease]), nil);
  STAssertThrowsSpecificNamed((decodedRegex = [unarchiver decodeObjectForKey:@"regex"]), NSException, NSInvalidUnarchiveOperationException, nil);
  STAssertNoThrow([unarchiver finishDecoding], nil);
}

@end
