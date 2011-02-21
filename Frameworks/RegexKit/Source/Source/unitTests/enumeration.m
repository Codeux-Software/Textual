//
//  enumeration.m
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

#import "enumeration.h"


@implementation enumeration

+ (void)tearDown
{
  NSLog(@"%@", RKPrettyObjectMethodString(@"Cache status:\n%@", [RKRegex regexCache]));
  NSLog(@"%@", RKPrettyObjectMethodString(@"Teardown complete\n\n"));
  fprintf(stderr, "-----------------------------------------\n\n");
}

- (void)testCreationAndInit
{
  NSAutoreleasePool *tempPool = NULL;
  RKEnumerator *enumerator = NULL;
  NSString *subjectString = @"  blarg   You think?  Nope.. ";
  
  STAssertTrueNoThrow((enumerator = [[[RKEnumerator alloc] initWithRegex:@"\\s*\\S+\\s+" string:subjectString inRange:NSMakeRange(0, [subjectString length])] autorelease]) != NULL, nil);
  STAssertTrue([subjectString isEqualToString:[enumerator string]], nil);
  STAssertTrue([[RKRegex regexWithRegexString:@"\\s*\\S+\\s+" options:(RKCompileUTF8 | RKCompileNoUTF8Check)] isEqual:[enumerator regex]], nil);

#ifdef REGEXKIT_DEBUGGING
  RKRegex *debugRegex = NSAllocateObject([RKRegex class], 0, NULL);
  [debugRegex setDebugRetainCount:YES];
  [debugRegex initWithRegexString:@"\\s*\\S+\\s+" options:(RKCompileUTF8 | RKCompileNoUTF8Check | RKCompileDupNames)];
  [debugRegex autorelease];
#endif
  
  tempPool = [[NSAutoreleasePool alloc] init];
  enumerator = NULL;
  STAssertTrueNoThrow((enumerator = [[RKEnumerator alloc] initWithRegex:[RKRegex regexWithRegexString:@"\\s*\\S+\\s+" options:(RKCompileUTF8 | RKCompileNoUTF8Check | RKCompileDupNames)] string:subjectString]) != NULL, nil);
  STAssertTrue([subjectString isEqualToString:[enumerator string]], nil);
  [tempPool release]; tempPool = NULL;
  [enumerator autorelease];
  STAssertFalse([[RKRegex regexWithRegexString:@"\\s*\\S+\\s+" options:RKCompileDupNames] isEqual:[enumerator regex]], nil);
  STAssertTrue([[RKRegex regexWithRegexString:@"\\s*\\S+\\s+" options:(RKCompileDupNames | RKCompileUTF8 | RKCompileNoUTF8Check)] isEqual:[enumerator regex]], nil);

  
  enumerator = NULL;
  STAssertTrueNoThrow((enumerator = [[[RKEnumerator alloc] initWithRegex:@"\\s*\\S+\\s+" string:subjectString] autorelease]) != NULL, nil);
  STAssertTrue([subjectString isEqualToString:[enumerator string]], nil);
  STAssertTrue([[RKRegex regexWithRegexString:@"\\s*\\S+\\s+" options:(RKCompileUTF8 | RKCompileNoUTF8Check)] isEqual:[enumerator regex]], nil);


  enumerator = NULL;
  STAssertTrueNoThrow((enumerator = [RKEnumerator enumeratorWithRegex:@"\\s*\\S+\\s+" string:subjectString inRange:NSMakeRange(0, [subjectString length])]) != NULL, nil);
  STAssertTrue([subjectString isEqualToString:[enumerator string]], nil);
  STAssertTrue([[RKRegex regexWithRegexString:@"\\s*\\S+\\s+" options:(RKCompileUTF8 | RKCompileNoUTF8Check)] isEqual:[enumerator regex]], nil);

  enumerator = NULL;
  STAssertTrueNoThrow((enumerator = [RKEnumerator enumeratorWithRegex:@"\\s*\\S+\\s+" string:subjectString]) != NULL, nil);
  STAssertTrue([subjectString isEqualToString:[enumerator string]], nil);
  STAssertTrue([[RKRegex regexWithRegexString:@"\\s*\\S+\\s+" options:(RKCompileUTF8 | RKCompileNoUTF8Check)] isEqual:[enumerator regex]], nil);

  STAssertThrowsSpecificNamed([[[RKEnumerator alloc] initWithRegex:@"\\s{1,6}\\S+\\s+" string:subjectString inRange:NSMakeRange(0, [subjectString length] + 1)] autorelease], NSException, NSRangeException, nil);
  STAssertThrowsSpecificNamed([[[RKEnumerator alloc] initWithRegex:@"\\s*\\S{3}\\s+" string:subjectString inRange:NSMakeRange([subjectString length] + 1, 100)] autorelease], NSException, NSRangeException, nil);

  STAssertThrowsSpecificNamed([RKEnumerator enumeratorWithRegex:@"\\s*\\S+\\s{9,}" string:subjectString inRange:NSMakeRange(2, [subjectString length] + 3)], NSException, NSRangeException, nil);
  STAssertThrowsSpecificNamed([RKEnumerator enumeratorWithRegex:@"\\s{3,}\\S+\\s+" string:subjectString inRange:NSMakeRange([subjectString length] - 2, 61)], NSException, NSRangeException, nil);

  STAssertThrowsSpecificNamed([[[RKEnumerator alloc] initWithRegex:@"\\s{1,6}\\S+\\s+" string:NULL inRange:NSMakeRange(0, [subjectString length])] autorelease], NSException, NSInvalidArgumentException, nil);
  STAssertThrowsSpecificNamed([[[RKEnumerator alloc] initWithRegex:@"\\s{6,12}\\S+\\s+" string:NULL] autorelease], NSException, NSInvalidArgumentException, nil);


  STAssertThrowsSpecificNamed([RKEnumerator enumeratorWithRegex:@"\\s*\\S+\\s{9,}" string:NULL inRange:NSMakeRange(0, [subjectString length])], NSException, NSInvalidArgumentException, nil);
  STAssertThrowsSpecificNamed([RKEnumerator enumeratorWithRegex:@"\\s*\\S{4,5}\\s{9,}" string:NULL], NSException, NSInvalidArgumentException, nil);


  STAssertThrowsSpecificNamed([[[RKEnumerator alloc] initWithRegex:NULL string:subjectString inRange:NSMakeRange(0, [subjectString length])] autorelease], NSException, NSInvalidArgumentException, nil);
  STAssertThrowsSpecificNamed([[[RKEnumerator alloc] initWithRegex:NULL string:subjectString] autorelease], NSException, NSInvalidArgumentException, nil);
  
  
  STAssertThrowsSpecificNamed([RKEnumerator enumeratorWithRegex:NULL string:subjectString inRange:NSMakeRange(0, [subjectString length])], NSException, NSInvalidArgumentException, nil);
  STAssertThrowsSpecificNamed([RKEnumerator enumeratorWithRegex:NULL string:subjectString], NSException, NSInvalidArgumentException, nil);
  
  enumerator = NULL;
  STAssertTrueNoThrow((enumerator = [subjectString matchEnumeratorWithRegex:@"\\s{5}\\S+?\\s?" inRange:NSMakeRange(0, [subjectString length])]) != NULL, nil);
  STAssertTrue([subjectString isEqualToString:[enumerator string]], nil);
  STAssertTrue([[RKRegex regexWithRegexString:@"\\s{5}\\S+?\\s?" options:(RKCompileUTF8 | RKCompileNoUTF8Check)] isEqual:[enumerator regex]], nil);

  enumerator = NULL;
  STAssertTrueNoThrow((enumerator = [subjectString matchEnumeratorWithRegex:@"\\s{6}\\S+?\\s?"]) != NULL, nil);
  STAssertTrue([subjectString isEqualToString:[enumerator string]], nil);
  STAssertTrue([[RKRegex regexWithRegexString:@"\\s{6}\\S+?\\s?" options:(RKCompileUTF8 | RKCompileNoUTF8Check)] isEqual:[enumerator regex]], nil);


  STAssertThrowsSpecificNamed([subjectString matchEnumeratorWithRegex:@"\\s{7}\\S+?\\s?" inRange:NSMakeRange(0, [subjectString length] + 1)], NSException, NSRangeException, nil);
  STAssertThrowsSpecificNamed([subjectString matchEnumeratorWithRegex:@"\\s{8}\\S+?\\s?" inRange:NSMakeRange([subjectString length], 1)], NSException, NSRangeException, nil);

  STAssertThrowsSpecificNamed([subjectString matchEnumeratorWithRegex:NULL inRange:NSMakeRange(2, [subjectString length] + 1)], NSException, NSInvalidArgumentException, nil);
  STAssertThrowsSpecificNamed([subjectString matchEnumeratorWithRegex:NULL], NSException, NSInvalidArgumentException, nil);

  // This test will (likely) cause a fault if RKRegex, RKCache, and RKEnumerator don't balance their retain/releases.
  // This creates an enumerator with a regex, then the cache is flushed, and an enumerator with the same regex specs is created.
  // The second one should be logically the same, but a different instantiation.
  
  tempPool = [[NSAutoreleasePool alloc] init];
  enumerator = NULL;
  STAssertTrueNoThrow((enumerator = [[RKEnumerator alloc] initWithRegex:[RKRegex regexWithRegexString:@"\\s*\\S+\\s+" options:(RKCompileUTF8 | RKCompileNoUTF8Check | RKCompileDupNames)] string:subjectString]) != NULL, nil);
  STAssertTrue([subjectString isEqualToString:[enumerator string]], nil);
  
  [tempPool release]; tempPool = NULL;
  [enumerator autorelease];
  [[RKRegex regexCache] clearCache];

  RKEnumerator *secondEnumerator = [RKEnumerator enumeratorWithRegex:[RKRegex regexWithRegexString:@"\\s*\\S+\\s+" options:(RKCompileUTF8 | RKCompileNoUTF8Check | RKCompileDupNames)] string:subjectString];
#ifdef REGEXKIT_DEBUGGING
  [[secondEnumerator regex] setDebugRetainCount:YES];
#endif

  STAssertFalse([[RKRegex regexWithRegexString:@"\\s*\\S+\\s+" options:RKCompileDupNames] isEqual:[enumerator regex]], nil);
  STAssertTrue([[RKRegex regexWithRegexString:@"\\s*\\S+\\s+" options:(RKCompileDupNames | RKCompileUTF8 | RKCompileNoUTF8Check)] isEqual:[enumerator regex]], nil);

  STAssertFalse([[RKRegex regexWithRegexString:@"\\s*\\S+\\s+" options:RKCompileDupNames] isEqual:[secondEnumerator regex]], nil);
  STAssertTrue([[RKRegex regexWithRegexString:@"\\s*\\S+\\s+" options:(RKCompileDupNames | RKCompileUTF8 | RKCompileNoUTF8Check)] isEqual:[secondEnumerator regex]], nil);

  STAssertFalse([RKRegex regexWithRegexString:@"\\s*\\S+\\s+" options:RKCompileDupNames] == [secondEnumerator regex], nil);
  STAssertTrue([RKRegex regexWithRegexString:@"\\s*\\S+\\s+" options:(RKCompileDupNames | RKCompileUTF8 | RKCompileNoUTF8Check)] == [secondEnumerator regex], nil);

  STAssertTrue([RKRegex regexWithRegexString:@"\\s*\\S+\\s+" options:RKCompileDupNames] != [enumerator regex], nil);
}


- (void)testNextEnumerations
{
  NSString *enumerateString = @"1, 2, 3";
  RKEnumerator *regexEnumerator = NULL;
  NSArray *matchArray = NULL;
  
  // nextObject
  STAssertTrueNoThrow((regexEnumerator = [enumerateString matchEnumeratorWithRegex:@"\\s*(\\d+),?"]) != NULL, nil);

  STAssertTrueNoThrow((matchArray = [regexEnumerator nextObject]) != NULL, nil);
  STAssertTrue([matchArray count] == 2, nil);
  STAssertTrue([[matchArray objectAtIndex:0] isEqualToValue:[NSValue valueWithRange:NSMakeRange(0, 2)]], nil);
  STAssertTrue([[matchArray objectAtIndex:1] isEqualToValue:[NSValue valueWithRange:NSMakeRange(0, 1)]], nil);

  STAssertTrueNoThrow((matchArray = [regexEnumerator nextObject]) != NULL, nil);
  STAssertTrue([matchArray count] == 2, nil);
  STAssertTrue([[matchArray objectAtIndex:0] isEqualToValue:[NSValue valueWithRange:NSMakeRange(2, 3)]], nil);
  STAssertTrue([[matchArray objectAtIndex:1] isEqualToValue:[NSValue valueWithRange:NSMakeRange(3, 1)]], nil);

  STAssertTrueNoThrow((matchArray = [regexEnumerator nextObject]) != NULL, nil);
  STAssertTrue([matchArray count] == 2, nil);
  STAssertTrue([[matchArray objectAtIndex:0] isEqualToValue:[NSValue valueWithRange:NSMakeRange(5, 2)]], nil);
  STAssertTrue([[matchArray objectAtIndex:1] isEqualToValue:[NSValue valueWithRange:NSMakeRange(6, 1)]], nil);

  STAssertTrueNoThrow((matchArray = [regexEnumerator nextObject]) == NULL, nil);
  STAssertTrueNoThrow((matchArray = [regexEnumerator nextObject]) == NULL, nil);


  //nextRange
  NSRange matchedRange;
  STAssertTrueNoThrow((regexEnumerator = [enumerateString matchEnumeratorWithRegex:@"\\s*(\\d+),?"]) != NULL, nil);
  
  matchedRange = NSMakeRange(15428599, 54151);
  STAssertTrueNoThrow(NSEqualRanges(matchedRange = [regexEnumerator nextRange], NSMakeRange(0, 2)), @"Range: %@", NSStringFromRange(matchedRange));

  matchedRange = NSMakeRange(15428599, 54151);
  STAssertTrueNoThrow(NSEqualRanges(matchedRange = [regexEnumerator nextRange], NSMakeRange(2, 3)), nil);

  matchedRange = NSMakeRange(15428599, 54151);
  STAssertTrueNoThrow(NSEqualRanges(matchedRange = [regexEnumerator nextRange], NSMakeRange(5, 2)), nil);
    
  matchedRange = NSMakeRange(15428599, 54151);
  STAssertTrueNoThrow(NSEqualRanges(matchedRange = [regexEnumerator nextRange], NSMakeRange(NSNotFound, 0)), nil);

  matchedRange = NSMakeRange(15428599, 54151);
  STAssertTrueNoThrow(NSEqualRanges(matchedRange = [regexEnumerator nextRange], NSMakeRange(NSNotFound, 0)), nil);

  
  //nextRangeForCapture
  STAssertTrueNoThrow((regexEnumerator = [enumerateString matchEnumeratorWithRegex:@"\\s*(\\d+),?"]) != NULL, nil);
  
  matchedRange = NSMakeRange(15428599, 54151);
  STAssertTrueNoThrow(NSEqualRanges(matchedRange = [regexEnumerator nextRangeForCapture:0], NSMakeRange(0, 2)), @"Range: %@", NSStringFromRange(matchedRange));
  
  matchedRange = NSMakeRange(15428599, 54151);
  STAssertTrueNoThrow(NSEqualRanges(matchedRange = [regexEnumerator nextRangeForCapture:0], NSMakeRange(2, 3)), @"Range: %@", NSStringFromRange(matchedRange));
  
  matchedRange = NSMakeRange(15428599, 54151);
  STAssertTrueNoThrow(NSEqualRanges(matchedRange = [regexEnumerator nextRangeForCapture:0], NSMakeRange(5, 2)), @"Range: %@", NSStringFromRange(matchedRange));
  
  matchedRange = NSMakeRange(15428599, 54151);
  STAssertTrueNoThrow(NSEqualRanges(matchedRange = [regexEnumerator nextRangeForCapture:0], NSMakeRange(NSNotFound, 0)), @"Range: %@", NSStringFromRange(matchedRange));
  
  matchedRange = NSMakeRange(15428599, 54151);
  STAssertTrueNoThrow(NSEqualRanges(matchedRange = [regexEnumerator nextRangeForCapture:0], NSMakeRange(NSNotFound, 0)), @"Range: %@", NSStringFromRange(matchedRange));

  // Different capture subpattern
  STAssertTrueNoThrow((regexEnumerator = [enumerateString matchEnumeratorWithRegex:@"\\s*(\\d+),?"]) != NULL, nil);
  
  matchedRange = NSMakeRange(15428599, 54151);
  STAssertTrueNoThrow(NSEqualRanges(matchedRange = [regexEnumerator nextRangeForCapture:1], NSMakeRange(0, 1)), @"Range: %@", NSStringFromRange(matchedRange));
  
  matchedRange = NSMakeRange(15428599, 54151);
  STAssertTrueNoThrow(NSEqualRanges(matchedRange = [regexEnumerator nextRangeForCapture:1], NSMakeRange(3, 1)), @"Range: %@", NSStringFromRange(matchedRange));
  
  matchedRange = NSMakeRange(15428599, 54151);
  STAssertTrueNoThrow(NSEqualRanges(matchedRange = [regexEnumerator nextRangeForCapture:1], NSMakeRange(6, 1)), @"Range: %@", NSStringFromRange(matchedRange));
  
  matchedRange = NSMakeRange(15428599, 54151);
  STAssertTrueNoThrow(NSEqualRanges(matchedRange = [regexEnumerator nextRangeForCapture:1], NSMakeRange(NSNotFound, 0)), @"Range: %@", NSStringFromRange(matchedRange));
  
  matchedRange = NSMakeRange(15428599, 54151);
  STAssertTrueNoThrow(NSEqualRanges(matchedRange = [regexEnumerator nextRangeForCapture:1], NSMakeRange(NSNotFound, 0)), @"Range: %@", NSStringFromRange(matchedRange));

  // Mixed capture subpattern
  STAssertTrueNoThrow((regexEnumerator = [enumerateString matchEnumeratorWithRegex:@"\\s*(\\d+),?"]) != NULL, nil);
  
  matchedRange = NSMakeRange(15428599, 54151);
  STAssertTrueNoThrow(NSEqualRanges(matchedRange = [regexEnumerator nextRangeForCapture:1], NSMakeRange(0, 1)), @"Range: %@", NSStringFromRange(matchedRange));
  
  matchedRange = NSMakeRange(15428599, 54151);
  STAssertTrueNoThrow(NSEqualRanges(matchedRange = [regexEnumerator nextRangeForCapture:0], NSMakeRange(2, 3)), @"Range: %@", NSStringFromRange(matchedRange));
  
  matchedRange = NSMakeRange(15428599, 54151);
  STAssertTrueNoThrow(NSEqualRanges(matchedRange = [regexEnumerator nextRangeForCapture:1], NSMakeRange(6, 1)), @"Range: %@", NSStringFromRange(matchedRange));
  
  matchedRange = NSMakeRange(15428599, 54151);
  STAssertTrueNoThrow(NSEqualRanges(matchedRange = [regexEnumerator nextRangeForCapture:0], NSMakeRange(NSNotFound, 0)), @"Range: %@", NSStringFromRange(matchedRange));
  
  matchedRange = NSMakeRange(15428599, 54151);
  STAssertTrueNoThrow(NSEqualRanges(matchedRange = [regexEnumerator nextRangeForCapture:1], NSMakeRange(NSNotFound, 0)), @"Range: %@", NSStringFromRange(matchedRange));
  
  // Invalid capture subpattern
  STAssertTrueNoThrow((regexEnumerator = [enumerateString matchEnumeratorWithRegex:@"\\s*(\\d+),?"]) != NULL, nil);
  
  matchedRange = NSMakeRange(15428599, 54151);
  STAssertThrowsSpecificNamed((matchedRange = [regexEnumerator nextRangeForCapture:2]), NSException, NSInvalidArgumentException, nil);
  STAssertTrue(NSEqualRanges(matchedRange, NSMakeRange(15428599, 54151)), nil);

  matchedRange = NSMakeRange(15428599, 54151);
  // The previous exception should not have advanced us to the next match.
  STAssertTrueNoThrow(NSEqualRanges(matchedRange = [regexEnumerator nextRangeForCapture:0], NSMakeRange(0, 2)), @"Range: %@", NSStringFromRange(matchedRange));

  matchedRange = NSMakeRange(15428599, 54151);
  STAssertThrowsSpecificNamed((matchedRange = [regexEnumerator nextRangeForCapture:3]), NSException, NSInvalidArgumentException, nil);
  STAssertTrue(NSEqualRanges(matchedRange, NSMakeRange(15428599, 54151)), nil);
  
  matchedRange = NSMakeRange(15428599, 54151);
  STAssertTrueNoThrow(NSEqualRanges(matchedRange = [regexEnumerator nextRangeForCapture:1], NSMakeRange(3, 1)), @"Range: %@", NSStringFromRange(matchedRange));
  
  matchedRange = NSMakeRange(15428599, 54151);
  STAssertThrowsSpecificNamed((matchedRange = [regexEnumerator nextRangeForCapture:4]), NSException, NSInvalidArgumentException, nil);
  STAssertTrue(NSEqualRanges(matchedRange, NSMakeRange(15428599, 54151)), nil);

  matchedRange = NSMakeRange(15428599, 54151);
  STAssertTrueNoThrow(NSEqualRanges(matchedRange = [regexEnumerator nextRangeForCapture:0], NSMakeRange(5, 2)), @"Range: %@", NSStringFromRange(matchedRange));
  
  matchedRange = NSMakeRange(15428599, 54151);
  STAssertThrowsSpecificNamed((matchedRange = [regexEnumerator nextRangeForCapture:5]), NSException, NSInvalidArgumentException, @"Range: %@", NSStringFromRange(matchedRange));
  STAssertTrue(NSEqualRanges(matchedRange, NSMakeRange(15428599, 54151)), nil);
  
  matchedRange = NSMakeRange(15428599, 54151);
  STAssertTrueNoThrow(NSEqualRanges(matchedRange = [regexEnumerator nextRangeForCapture:1], NSMakeRange(NSNotFound, 0)), @"Range: %@", NSStringFromRange(matchedRange));
  
  matchedRange = NSMakeRange(15428599, 54151);
  // Once exhausted, will always return NSNotFound, 0, even for invalid capture numbers
  STAssertTrueNoThrow(NSEqualRanges(matchedRange = [regexEnumerator nextRangeForCapture:6], NSMakeRange(NSNotFound, 0)), @"Range: %@", NSStringFromRange(matchedRange));
  
  matchedRange = NSMakeRange(15428599, 54151);
  STAssertTrueNoThrow(NSEqualRanges(matchedRange = [regexEnumerator nextRangeForCapture:0], NSMakeRange(NSNotFound, 0)), @"Range: %@", NSStringFromRange(matchedRange));
  

  // nextRangeForCaptureName
  STAssertTrueNoThrow((regexEnumerator = [enumerateString matchEnumeratorWithRegex:@"(?<everything>\\s*(?<theNumber>\\d+)(?<maybeComma>,?))"]) != NULL, nil);
  
  matchedRange = NSMakeRange(15428599, 54151);
  STAssertTrueNoThrow(NSEqualRanges(matchedRange = [regexEnumerator nextRangeForCaptureName:@"everything"], NSMakeRange(0, 2)), @"Range: %@", NSStringFromRange(matchedRange));
  
  matchedRange = NSMakeRange(15428599, 54151);
  STAssertTrueNoThrow(NSEqualRanges(matchedRange = [regexEnumerator nextRangeForCaptureName:@"everything"], NSMakeRange(2, 3)), @"Range: %@", NSStringFromRange(matchedRange));
  
  matchedRange = NSMakeRange(15428599, 54151);
  STAssertTrueNoThrow(NSEqualRanges(matchedRange = [regexEnumerator nextRangeForCaptureName:@"everything"], NSMakeRange(5, 2)), @"Range: %@", NSStringFromRange(matchedRange));
  
  matchedRange = NSMakeRange(15428599, 54151);
  STAssertTrueNoThrow(NSEqualRanges(matchedRange = [regexEnumerator nextRangeForCaptureName:@"everything"], NSMakeRange(NSNotFound, 0)), @"Range: %@", NSStringFromRange(matchedRange));
  
  matchedRange = NSMakeRange(15428599, 54151);
  STAssertTrueNoThrow(NSEqualRanges(matchedRange = [regexEnumerator nextRangeForCaptureName:@"everything"], NSMakeRange(NSNotFound, 0)), @"Range: %@", NSStringFromRange(matchedRange));

  // different capture name
  STAssertTrueNoThrow((regexEnumerator = [enumerateString matchEnumeratorWithRegex:@"(?<everything>\\s*(?<theNumber>\\d+)(?<maybeComma>,?))"]) != NULL, nil);
  
  matchedRange = NSMakeRange(15428599, 54151);
  STAssertTrueNoThrow(NSEqualRanges(matchedRange = [regexEnumerator nextRangeForCaptureName:@"theNumber"], NSMakeRange(0, 1)), @"Range: %@", NSStringFromRange(matchedRange));
  
  matchedRange = NSMakeRange(15428599, 54151);
  STAssertTrueNoThrow(NSEqualRanges(matchedRange = [regexEnumerator nextRangeForCaptureName:@"theNumber"], NSMakeRange(3, 1)), @"Range: %@", NSStringFromRange(matchedRange));
  
  matchedRange = NSMakeRange(15428599, 54151);
  STAssertTrueNoThrow(NSEqualRanges(matchedRange = [regexEnumerator nextRangeForCaptureName:@"theNumber"], NSMakeRange(6, 1)), @"Range: %@", NSStringFromRange(matchedRange));
  
  matchedRange = NSMakeRange(15428599, 54151);
  STAssertTrueNoThrow(NSEqualRanges(matchedRange = [regexEnumerator nextRangeForCaptureName:@"theNumber"], NSMakeRange(NSNotFound, 0)), @"Range: %@", NSStringFromRange(matchedRange));
  
  matchedRange = NSMakeRange(15428599, 54151);
  STAssertTrueNoThrow(NSEqualRanges(matchedRange = [regexEnumerator nextRangeForCaptureName:@"theNumber"], NSMakeRange(NSNotFound, 0)), @"Range: %@", NSStringFromRange(matchedRange));

  // Mixed capture name
  STAssertTrueNoThrow((regexEnumerator = [enumerateString matchEnumeratorWithRegex:@"(?<everything>\\s*(?<theNumber>\\d+)(?<maybeComma>,?))"]) != NULL, nil);
  
  matchedRange = NSMakeRange(15428599, 54151);
  STAssertTrueNoThrow(NSEqualRanges(matchedRange = [regexEnumerator nextRangeForCaptureName:@"theNumber"], NSMakeRange(0, 1)), @"Range: %@", NSStringFromRange(matchedRange));
  
  matchedRange = NSMakeRange(15428599, 54151);
  STAssertTrueNoThrow(NSEqualRanges(matchedRange = [regexEnumerator nextRangeForCaptureName:@"everything"], NSMakeRange(2, 3)), @"Range: %@", NSStringFromRange(matchedRange));
  
  matchedRange = NSMakeRange(15428599, 54151);
  STAssertTrueNoThrow(NSEqualRanges(matchedRange = [regexEnumerator nextRangeForCaptureName:@"theNumber"], NSMakeRange(6, 1)), @"Range: %@", NSStringFromRange(matchedRange));
  
  matchedRange = NSMakeRange(15428599, 54151);
  STAssertTrueNoThrow(NSEqualRanges(matchedRange = [regexEnumerator nextRangeForCaptureName:@"everything"], NSMakeRange(NSNotFound, 0)), @"Range: %@", NSStringFromRange(matchedRange));
  
  matchedRange = NSMakeRange(15428599, 54151);
  STAssertTrueNoThrow(NSEqualRanges(matchedRange = [regexEnumerator nextRangeForCaptureName:@"theNumber"], NSMakeRange(NSNotFound, 0)), @"Range: %@", NSStringFromRange(matchedRange));
  
  // Invalid capture name
  STAssertTrueNoThrow((regexEnumerator = [enumerateString matchEnumeratorWithRegex:@"(?<everything>\\s*(?<theNumber>\\d+)(?<maybeComma>,?))"]) != NULL, nil);
    
  matchedRange = NSMakeRange(39293, 45833);
  STAssertThrowsSpecificNamed((matchedRange = [regexEnumerator nextRangeForCaptureName:NULL]), NSException, NSInvalidArgumentException, nil);
  STAssertTrue(NSEqualRanges(matchedRange, NSMakeRange(39293, 45833)), nil);
  
  matchedRange = NSMakeRange(39293, 45833);
  // The previous exception should not have advanced us to the next match.
  STAssertTrueNoThrow(NSEqualRanges(matchedRange = [regexEnumerator nextRangeForCaptureName:@"everything"], NSMakeRange(0, 2)), @"Range: %@", NSStringFromRange(matchedRange));
  
  matchedRange = NSMakeRange(39293, 45833);
  STAssertThrowsSpecificNamed((matchedRange = [regexEnumerator nextRangeForCaptureName:@"doesNotExist"]), NSException, RKRegexCaptureReferenceException, nil);
  STAssertTrue(NSEqualRanges(matchedRange, NSMakeRange(39293, 45833)), nil);
  
  matchedRange = NSMakeRange(39293, 45833);
  STAssertTrueNoThrow(NSEqualRanges(matchedRange = [regexEnumerator nextRangeForCaptureName:@"theNumber"], NSMakeRange(3, 1)), @"Range: %@", NSStringFromRange(matchedRange));
  
  matchedRange = NSMakeRange(39293, 45833);
  STAssertThrowsSpecificNamed((matchedRange = [regexEnumerator nextRangeForCaptureName:@"theNumber_"]), NSException, RKRegexCaptureReferenceException, nil);
  STAssertTrue(NSEqualRanges(matchedRange, NSMakeRange(39293, 45833)), nil);
  
  matchedRange = NSMakeRange(39293, 45833);
  STAssertTrueNoThrow(NSEqualRanges(matchedRange = [regexEnumerator nextRangeForCaptureName:@"everything"], NSMakeRange(5, 2)), @"Range: %@", NSStringFromRange(matchedRange));
  
  matchedRange = NSMakeRange(39293, 45833);
  STAssertThrowsSpecificNamed((matchedRange = [regexEnumerator nextRangeForCaptureName:@"everything?"]), NSException, RKRegexCaptureReferenceException, @"Range: %@", NSStringFromRange(matchedRange));
  STAssertTrue(NSEqualRanges(matchedRange, NSMakeRange(39293, 45833)), nil);
  
  matchedRange = NSMakeRange(39293, 45833);
  STAssertTrueNoThrow(NSEqualRanges(matchedRange = [regexEnumerator nextRangeForCaptureName:@"theNumber"], NSMakeRange(NSNotFound, 0)), @"Range: %@", NSStringFromRange(matchedRange));
  
  matchedRange = NSMakeRange(39293, 45833);
  // Once exhausted, will always return NSNotFound, 0, even for invalid capture numbers
  STAssertTrueNoThrow(NSEqualRanges(matchedRange = [regexEnumerator nextRangeForCaptureName:@"whatNumber"], NSMakeRange(NSNotFound, 0)), @"Range: %@", NSStringFromRange(matchedRange));
  
  matchedRange = NSMakeRange(39293, 45833);
  // But NULL will still throw an exception.
  STAssertThrowsSpecificNamed((matchedRange = [regexEnumerator nextRangeForCaptureName:NULL]), NSException, NSInvalidArgumentException, nil);
  STAssertTrue(NSEqualRanges(matchedRange, NSMakeRange(39293, 45833)), nil);
  
  matchedRange = NSMakeRange(39293, 45833);
  STAssertTrueNoThrow(NSEqualRanges(matchedRange = [regexEnumerator nextRangeForCaptureName:@"everything"], NSMakeRange(NSNotFound, 0)), @"Range: %@", NSStringFromRange(matchedRange));

  


  //nextRanges
  NSRange *matchedRanges = NULL, *firstRanges = NULL;
  STAssertTrueNoThrow((regexEnumerator = [enumerateString matchEnumeratorWithRegex:@"\\s*(\\d+),?"]) != NULL, nil);
  
  matchedRanges = (NSRange *)0xdeadbeef;
  STAssertTrueNoThrow((firstRanges = matchedRanges = [regexEnumerator nextRanges]) != NULL, nil);
  STAssertTrue(firstRanges == matchedRanges, nil);
  STAssertTrue(NSEqualRanges(matchedRanges[0], NSMakeRange(0, 2)), @"Range: %@", NSStringFromRange(matchedRanges[0]));
  STAssertTrue(NSEqualRanges(matchedRanges[1], NSMakeRange(0, 1)), @"Range: %@", NSStringFromRange(matchedRanges[1]));
  
  matchedRanges = (NSRange *)0xdeadbeef;
  STAssertTrueNoThrow((matchedRanges = [regexEnumerator nextRanges]) != NULL, nil);
  STAssertTrue(firstRanges == matchedRanges, nil);
  STAssertTrue(NSEqualRanges(matchedRanges[0], NSMakeRange(2, 3)), @"Range: %@", NSStringFromRange(matchedRanges[0]));
  STAssertTrue(NSEqualRanges(matchedRanges[1], NSMakeRange(3, 1)), @"Range: %@", NSStringFromRange(matchedRanges[1]));
  
  matchedRanges = (NSRange *)0xdeadbeef;
  STAssertTrueNoThrow((matchedRanges = [regexEnumerator nextRanges]) != NULL, nil);
  STAssertTrue(firstRanges == matchedRanges, nil);
  STAssertTrue(NSEqualRanges(matchedRanges[0], NSMakeRange(5, 2)), @"Range: %@", NSStringFromRange(matchedRanges[0]));
  STAssertTrue(NSEqualRanges(matchedRanges[1], NSMakeRange(6, 1)), @"Range: %@", NSStringFromRange(matchedRanges[1]));
  
  matchedRanges = (NSRange *)0xdeadbeef;
  STAssertTrueNoThrow((matchedRanges = [regexEnumerator nextRanges]) == NULL, nil);
  
  matchedRanges = (NSRange *)0xdeadbeef;
  STAssertTrueNoThrow((matchedRanges = [regexEnumerator nextRanges]) == NULL, nil);
  

}

- (void)testCurrentRanges
{
  NSString *enumerateString = @"1, 2, 3";
  RKEnumerator *regexEnumerator = NULL;
  NSRange matchedRange, *matchedRanges = NULL, *firstRanges = NULL;
  
  STAssertTrueNoThrow((regexEnumerator = [enumerateString matchEnumeratorWithRegex:@"\\s*(\\d+),?"]) != NULL, nil);

  matchedRanges = (NSRange *)0xdeadbeef;
  STAssertThrowsSpecificNamed((matchedRanges = [regexEnumerator currentRanges]), NSException, NSInvalidArgumentException, nil);
  STAssertTrue(matchedRanges == (NSRange *)0xdeadbeef, @"Ranges: %p", matchedRanges);

  // Advance to the first match
  STAssertTrueNoThrow((firstRanges = [regexEnumerator nextRanges]) != NULL, nil);

  matchedRanges = (NSRange *)0xdeadbeef;
  STAssertTrueNoThrow((matchedRanges = [regexEnumerator currentRanges]) != NULL, nil);
  STAssertTrue(firstRanges == matchedRanges, nil);
  STAssertTrue(NSEqualRanges(matchedRanges[0], NSMakeRange(0, 2)), @"Range: %@", NSStringFromRange(matchedRanges[0]));
  STAssertTrue(NSEqualRanges(matchedRanges[1], NSMakeRange(0, 1)), @"Range: %@", NSStringFromRange(matchedRanges[1]));


  STAssertTrueNoThrow([regexEnumerator nextRanges] == firstRanges, nil);
  matchedRanges = (NSRange *)0xdeadbeef;
  STAssertTrueNoThrow((matchedRanges = [regexEnumerator currentRanges]) != NULL, nil);
  STAssertTrue(firstRanges == matchedRanges, nil);
  STAssertTrue(NSEqualRanges(matchedRanges[0], NSMakeRange(2, 3)), @"Range: %@", NSStringFromRange(matchedRanges[0]));
  STAssertTrue(NSEqualRanges(matchedRanges[1], NSMakeRange(3, 1)), @"Range: %@", NSStringFromRange(matchedRanges[1]));

  STAssertTrueNoThrow([regexEnumerator nextRanges] == firstRanges, nil);
  matchedRanges = (NSRange *)0xdeadbeef;
  STAssertTrueNoThrow((matchedRanges = [regexEnumerator currentRanges]) != NULL, nil);
  STAssertTrue(firstRanges == matchedRanges, nil);
  STAssertTrue(NSEqualRanges(matchedRanges[0], NSMakeRange(5, 2)), @"Range: %@", NSStringFromRange(matchedRanges[0]));
  STAssertTrue(NSEqualRanges(matchedRanges[1], NSMakeRange(6, 1)), @"Range: %@", NSStringFromRange(matchedRanges[1]));

  STAssertTrueNoThrow([regexEnumerator nextRanges] == NULL, nil);
  matchedRanges = (NSRange *)0xdeadbeef;
  STAssertTrueNoThrow((matchedRanges = [regexEnumerator currentRanges]) == NULL, nil);

  STAssertTrueNoThrow([regexEnumerator nextRanges] == NULL, nil);
  matchedRanges = (NSRange *)0xdeadbeef;
  STAssertTrueNoThrow((matchedRanges = [regexEnumerator currentRanges]) == NULL, nil);




  STAssertTrueNoThrow((regexEnumerator = [enumerateString matchEnumeratorWithRegex:@"\\s*(\\d+),?"]) != NULL, nil);
  
  matchedRange = NSMakeRange(1214281727, 37607);
  STAssertThrowsSpecificNamed((matchedRange = [regexEnumerator currentRange]), NSException, NSInvalidArgumentException, nil);
  STAssertTrue(NSEqualRanges(matchedRange, NSMakeRange(1214281727, 37607)) , @"Range: %p", NSStringFromRange(matchedRange));
  
  // Advance to the first match
  STAssertTrueNoThrow((firstRanges = [regexEnumerator nextRanges]) != NULL, nil);
  matchedRange = NSMakeRange(1214281727, 37607);
  STAssertTrueNoThrow(NSEqualRanges(matchedRange = [regexEnumerator currentRange], NSMakeRange(0, 2)), @"Range: %@", NSStringFromRange(matchedRange));
  
  STAssertTrueNoThrow((firstRanges = [regexEnumerator nextRanges]) != NULL, nil);
  matchedRange = NSMakeRange(1214281727, 37607);
  STAssertTrueNoThrow(NSEqualRanges(matchedRange = [regexEnumerator currentRange], NSMakeRange(2, 3)), @"Range: %@", NSStringFromRange(matchedRange));

  STAssertTrueNoThrow((firstRanges = [regexEnumerator nextRanges]) != NULL, nil);
  matchedRange = NSMakeRange(1214281727, 37607);
  STAssertTrueNoThrow(NSEqualRanges(matchedRange = [regexEnumerator currentRange], NSMakeRange(5, 2)), @"Range: %@", NSStringFromRange(matchedRange));

  STAssertTrueNoThrow((firstRanges = [regexEnumerator nextRanges]) == NULL, nil);
  matchedRange = NSMakeRange(1214281727, 37607);
  STAssertTrueNoThrow(NSEqualRanges(matchedRange = [regexEnumerator currentRange], NSMakeRange(NSNotFound, 0)), @"Range: %@", NSStringFromRange(matchedRange));

  STAssertTrueNoThrow((firstRanges = [regexEnumerator nextRanges]) == NULL, nil);
  matchedRange = NSMakeRange(1214281727, 37607);
  STAssertTrueNoThrow(NSEqualRanges(matchedRange = [regexEnumerator currentRange], NSMakeRange(NSNotFound, 0)), @"Range: %@", NSStringFromRange(matchedRange));
  


  // currentRangeForCapture:
  STAssertTrueNoThrow((regexEnumerator = [enumerateString matchEnumeratorWithRegex:@"\\s*(\\d+),?"]) != NULL, nil);
  
  matchedRange = NSMakeRange(1214281727, 37607);
  STAssertThrowsSpecificNamed((matchedRange = [regexEnumerator currentRangeForCapture:0]), NSException, NSInvalidArgumentException, nil);
  STAssertTrue(NSEqualRanges(matchedRange, NSMakeRange(1214281727, 37607)) , @"Range: %p", NSStringFromRange(matchedRange));
  
  // Advance to the first match
  STAssertTrueNoThrow((firstRanges = [regexEnumerator nextRanges]) != NULL, nil);
  matchedRange = NSMakeRange(1214281727, 37607);
  STAssertTrueNoThrow(NSEqualRanges(matchedRange = [regexEnumerator currentRangeForCapture:0], NSMakeRange(0, 2)), @"Range: %@", NSStringFromRange(matchedRange));
  
  STAssertTrueNoThrow((firstRanges = [regexEnumerator nextRanges]) != NULL, nil);
  matchedRange = NSMakeRange(1214281727, 37607);
  STAssertTrueNoThrow(NSEqualRanges(matchedRange = [regexEnumerator currentRangeForCapture:0], NSMakeRange(2, 3)), @"Range: %@", NSStringFromRange(matchedRange));
  
  STAssertTrueNoThrow((firstRanges = [regexEnumerator nextRanges]) != NULL, nil);
  matchedRange = NSMakeRange(1214281727, 37607);
  STAssertTrueNoThrow(NSEqualRanges(matchedRange = [regexEnumerator currentRangeForCapture:0], NSMakeRange(5, 2)), @"Range: %@", NSStringFromRange(matchedRange));
  
  STAssertTrueNoThrow((firstRanges = [regexEnumerator nextRanges]) == NULL, nil);
  matchedRange = NSMakeRange(1214281727, 37607);
  STAssertTrueNoThrow(NSEqualRanges(matchedRange = [regexEnumerator currentRangeForCapture:0], NSMakeRange(NSNotFound, 0)), @"Range: %@", NSStringFromRange(matchedRange));
  
  STAssertTrueNoThrow((firstRanges = [regexEnumerator nextRanges]) == NULL, nil);
  matchedRange = NSMakeRange(1214281727, 37607);
  STAssertTrueNoThrow(NSEqualRanges(matchedRange = [regexEnumerator currentRangeForCapture:0], NSMakeRange(NSNotFound, 0)), @"Range: %@", NSStringFromRange(matchedRange));


  // different capture subpattern
  STAssertTrueNoThrow((regexEnumerator = [enumerateString matchEnumeratorWithRegex:@"\\s*(\\d+),?"]) != NULL, nil);
  
  matchedRange = NSMakeRange(1214281727, 37607);
  STAssertThrowsSpecificNamed((matchedRange = [regexEnumerator currentRangeForCapture:1]), NSException, NSInvalidArgumentException, nil);
  STAssertTrue(NSEqualRanges(matchedRange, NSMakeRange(1214281727, 37607)) , @"Range: %p", NSStringFromRange(matchedRange));

  // Advance to the first match
  STAssertTrueNoThrow((firstRanges = [regexEnumerator nextRanges]) != NULL, nil);
  matchedRange = NSMakeRange(1214281727, 37607);
  STAssertTrueNoThrow(NSEqualRanges(matchedRange = [regexEnumerator currentRangeForCapture:1], NSMakeRange(0, 1)), @"Range: %@", NSStringFromRange(matchedRange));
  
  STAssertTrueNoThrow((firstRanges = [regexEnumerator nextRanges]) != NULL, nil);
  matchedRange = NSMakeRange(1214281727, 37607);
  STAssertTrueNoThrow(NSEqualRanges(matchedRange = [regexEnumerator currentRangeForCapture:1], NSMakeRange(3, 1)), @"Range: %@", NSStringFromRange(matchedRange));
  
  STAssertTrueNoThrow((firstRanges = [regexEnumerator nextRanges]) != NULL, nil);
  matchedRange = NSMakeRange(1214281727, 37607);
  STAssertTrueNoThrow(NSEqualRanges(matchedRange = [regexEnumerator currentRangeForCapture:1], NSMakeRange(6, 1)), @"Range: %@", NSStringFromRange(matchedRange));
  
  STAssertTrueNoThrow((firstRanges = [regexEnumerator nextRanges]) == NULL, nil);
  matchedRange = NSMakeRange(1214281727, 37607);
  STAssertTrueNoThrow(NSEqualRanges(matchedRange = [regexEnumerator currentRangeForCapture:1], NSMakeRange(NSNotFound, 0)), @"Range: %@", NSStringFromRange(matchedRange));
  
  STAssertTrueNoThrow((firstRanges = [regexEnumerator nextRanges]) == NULL, nil);
  matchedRange = NSMakeRange(1214281727, 37607);
  STAssertTrueNoThrow(NSEqualRanges(matchedRange = [regexEnumerator currentRangeForCapture:1], NSMakeRange(NSNotFound, 0)), @"Range: %@", NSStringFromRange(matchedRange));
  

  // mixed capture subpattern
  STAssertTrueNoThrow((regexEnumerator = [enumerateString matchEnumeratorWithRegex:@"\\s*(\\d+),?"]) != NULL, nil);
  
  matchedRange = NSMakeRange(1214281727, 37607);
  STAssertThrowsSpecificNamed((matchedRange = [regexEnumerator currentRangeForCapture:0]), NSException, NSInvalidArgumentException, nil);
  STAssertTrue(NSEqualRanges(matchedRange, NSMakeRange(1214281727, 37607)) , @"Range: %p", NSStringFromRange(matchedRange));

  // Advance to the first match
  STAssertTrueNoThrow((firstRanges = [regexEnumerator nextRanges]) != NULL, nil);
  matchedRange = NSMakeRange(1214281727, 37607);
  STAssertTrueNoThrow(NSEqualRanges(matchedRange = [regexEnumerator currentRangeForCapture:1], NSMakeRange(0, 1)), @"Range: %@", NSStringFromRange(matchedRange));
  
  STAssertTrueNoThrow((firstRanges = [regexEnumerator nextRanges]) != NULL, nil);
  matchedRange = NSMakeRange(1214281727, 37607);
  STAssertTrueNoThrow(NSEqualRanges(matchedRange = [regexEnumerator currentRangeForCapture:0], NSMakeRange(2, 3)), @"Range: %@", NSStringFromRange(matchedRange));
  
  STAssertTrueNoThrow((firstRanges = [regexEnumerator nextRanges]) != NULL, nil);
  matchedRange = NSMakeRange(1214281727, 37607);
  STAssertTrueNoThrow(NSEqualRanges(matchedRange = [regexEnumerator currentRangeForCapture:1], NSMakeRange(6, 1)), @"Range: %@", NSStringFromRange(matchedRange));
  
  STAssertTrueNoThrow((firstRanges = [regexEnumerator nextRanges]) == NULL, nil);
  matchedRange = NSMakeRange(1214281727, 37607);
  STAssertTrueNoThrow(NSEqualRanges(matchedRange = [regexEnumerator currentRangeForCapture:0], NSMakeRange(NSNotFound, 0)), @"Range: %@", NSStringFromRange(matchedRange));
  
  STAssertTrueNoThrow((firstRanges = [regexEnumerator nextRanges]) == NULL, nil);
  matchedRange = NSMakeRange(1214281727, 37607);
  STAssertTrueNoThrow(NSEqualRanges(matchedRange = [regexEnumerator currentRangeForCapture:1], NSMakeRange(NSNotFound, 0)), @"Range: %@", NSStringFromRange(matchedRange));


  // invalid capture subpattern
  STAssertTrueNoThrow((regexEnumerator = [enumerateString matchEnumeratorWithRegex:@"\\s*(\\d+),?"]) != NULL, nil);
    
  matchedRange = NSMakeRange(1214281727, 37607);
  STAssertThrowsSpecificNamed((matchedRange = [regexEnumerator currentRangeForCapture:1]), NSException, NSInvalidArgumentException, nil);
  STAssertTrue(NSEqualRanges(matchedRange, NSMakeRange(1214281727, 37607)) , @"Range: %p", NSStringFromRange(matchedRange));
  
  // Advance to the first match
  STAssertTrueNoThrow((firstRanges = [regexEnumerator nextRanges]) != NULL, nil);
  matchedRange = NSMakeRange(1214281727, 37607);
  STAssertThrowsSpecificNamed((matchedRange = [regexEnumerator currentRangeForCapture:2]), NSException, NSInvalidArgumentException, nil);
  STAssertTrue(NSEqualRanges(matchedRange, NSMakeRange(1214281727, 37607)), nil);
  
  matchedRange = NSMakeRange(1214281727, 37607);
  STAssertTrueNoThrow(NSEqualRanges(matchedRange = [regexEnumerator currentRangeForCapture:0], NSMakeRange(0, 2)), @"Range: %@", NSStringFromRange(matchedRange));
  
  matchedRange = NSMakeRange(1214281727, 37607);
  STAssertThrowsSpecificNamed((matchedRange = [regexEnumerator currentRangeForCapture:3]), NSException, NSInvalidArgumentException, nil);
  STAssertTrue(NSEqualRanges(matchedRange, NSMakeRange(1214281727, 37607)), nil);

  matchedRange = NSMakeRange(1214281727, 37607);
  STAssertTrueNoThrow(NSEqualRanges(matchedRange = [regexEnumerator currentRangeForCapture:1], NSMakeRange(0, 1)), @"Range: %@", NSStringFromRange(matchedRange));


  // Advance
  STAssertTrueNoThrow((firstRanges = [regexEnumerator nextRanges]) != NULL, nil);

  matchedRange = NSMakeRange(1214281727, 37607);
  STAssertThrowsSpecificNamed((matchedRange = [regexEnumerator currentRangeForCapture:4]), NSException, NSInvalidArgumentException, nil);
  STAssertTrue(NSEqualRanges(matchedRange, NSMakeRange(1214281727, 37607)), nil);
  
  matchedRange = NSMakeRange(1214281727, 37607);
  STAssertTrueNoThrow(NSEqualRanges(matchedRange = [regexEnumerator currentRangeForCapture:1], NSMakeRange(3, 1)), @"Range: %@", NSStringFromRange(matchedRange));
  
  matchedRange = NSMakeRange(1214281727, 37607);
  STAssertThrowsSpecificNamed((matchedRange = [regexEnumerator currentRangeForCapture:5]), NSException, NSInvalidArgumentException, nil);
  STAssertTrue(NSEqualRanges(matchedRange, NSMakeRange(1214281727, 37607)), nil);


  matchedRange = NSMakeRange(1214281727, 37607);
  STAssertTrueNoThrow(NSEqualRanges(matchedRange = [regexEnumerator currentRangeForCapture:0], NSMakeRange(2, 3)), @"Range: %@", NSStringFromRange(matchedRange));


  // Advance
  STAssertTrueNoThrow((firstRanges = [regexEnumerator nextRanges]) != NULL, nil);
  
  matchedRange = NSMakeRange(1214281727, 37607);
  STAssertThrowsSpecificNamed((matchedRange = [regexEnumerator currentRangeForCapture:6]), NSException, NSInvalidArgumentException, @"Range: %@", NSStringFromRange(matchedRange));
  STAssertTrue(NSEqualRanges(matchedRange, NSMakeRange(1214281727, 37607)), nil);
  
  matchedRange = NSMakeRange(1214281727, 37607);
  STAssertTrueNoThrow(NSEqualRanges(matchedRange = [regexEnumerator currentRangeForCapture:0], NSMakeRange(5, 2)), @"Range: %@", NSStringFromRange(matchedRange));
  
  matchedRange = NSMakeRange(1214281727, 37607);
  STAssertThrowsSpecificNamed((matchedRange = [regexEnumerator currentRangeForCapture:7]), NSException, NSInvalidArgumentException, @"Range: %@", NSStringFromRange(matchedRange));
  STAssertTrue(NSEqualRanges(matchedRange, NSMakeRange(1214281727, 37607)), nil);

  matchedRange = NSMakeRange(1214281727, 37607);
  STAssertTrueNoThrow(NSEqualRanges(matchedRange = [regexEnumerator currentRangeForCapture:1], NSMakeRange(6, 1)), @"Range: %@", NSStringFromRange(matchedRange));
  

  // Advance
  STAssertTrueNoThrow((firstRanges = [regexEnumerator nextRanges]) == NULL, nil);

  matchedRange = NSMakeRange(1214281727, 37607);
  STAssertTrueNoThrow(NSEqualRanges(matchedRange = [regexEnumerator currentRangeForCapture:0], NSMakeRange(NSNotFound, 0)), @"Range: %@", NSStringFromRange(matchedRange));
  matchedRange = NSMakeRange(1214281727, 37607);
  STAssertTrueNoThrow(NSEqualRanges(matchedRange = [regexEnumerator currentRangeForCapture:1], NSMakeRange(NSNotFound, 0)), @"Range: %@", NSStringFromRange(matchedRange));
  matchedRange = NSMakeRange(1214281727, 37607);
  STAssertTrueNoThrow(NSEqualRanges(matchedRange = [regexEnumerator currentRangeForCapture:2], NSMakeRange(NSNotFound, 0)), @"Range: %@", NSStringFromRange(matchedRange));
  matchedRange = NSMakeRange(1214281727, 37607);
  STAssertTrueNoThrow(NSEqualRanges(matchedRange = [regexEnumerator currentRangeForCapture:3], NSMakeRange(NSNotFound, 0)), @"Range: %@", NSStringFromRange(matchedRange));
  
  // Advance
  STAssertTrueNoThrow((firstRanges = [regexEnumerator nextRanges]) == NULL, nil);
  
  matchedRange = NSMakeRange(1214281727, 37607);
  // Once exhausted, will always return NSNotFound, 0, even for invalid capture numbers
  STAssertTrueNoThrow(NSEqualRanges(matchedRange = [regexEnumerator currentRangeForCapture:0], NSMakeRange(NSNotFound, 0)), @"Range: %@", NSStringFromRange(matchedRange));
  matchedRange = NSMakeRange(1214281727, 37607);
  STAssertTrueNoThrow(NSEqualRanges(matchedRange = [regexEnumerator currentRangeForCapture:1], NSMakeRange(NSNotFound, 0)), @"Range: %@", NSStringFromRange(matchedRange));
  matchedRange = NSMakeRange(1214281727, 37607);
  STAssertTrueNoThrow(NSEqualRanges(matchedRange = [regexEnumerator currentRangeForCapture:2], NSMakeRange(NSNotFound, 0)), @"Range: %@", NSStringFromRange(matchedRange));
  matchedRange = NSMakeRange(1214281727, 37607);
  STAssertTrueNoThrow(NSEqualRanges(matchedRange = [regexEnumerator currentRangeForCapture:3], NSMakeRange(NSNotFound, 0)), @"Range: %@", NSStringFromRange(matchedRange));





  // currentRangeForCaptureName:
  STAssertTrueNoThrow((regexEnumerator = [enumerateString matchEnumeratorWithRegex:@"(?<everything>\\s*(?<theNumber>\\d+)(?<maybeComma>,?))"]) != NULL, nil);
  
  matchedRange = NSMakeRange(1214281727, 37607);
  STAssertThrowsSpecificNamed((matchedRange = [regexEnumerator currentRangeForCaptureName:@"everything"]), NSException, NSInvalidArgumentException, nil);
  STAssertTrue(NSEqualRanges(matchedRange, NSMakeRange(1214281727, 37607)) , @"Range: %p", NSStringFromRange(matchedRange));
  
  // Advance to the first match
  STAssertTrueNoThrow((firstRanges = [regexEnumerator nextRanges]) != NULL, nil);
  matchedRange = NSMakeRange(1214281727, 37607);
  STAssertTrueNoThrow(NSEqualRanges(matchedRange = [regexEnumerator currentRangeForCaptureName:@"everything"], NSMakeRange(0, 2)), @"Range: %@", NSStringFromRange(matchedRange));
  
  STAssertTrueNoThrow((firstRanges = [regexEnumerator nextRanges]) != NULL, nil);
  matchedRange = NSMakeRange(1214281727, 37607);
  STAssertTrueNoThrow(NSEqualRanges(matchedRange = [regexEnumerator currentRangeForCaptureName:@"everything"], NSMakeRange(2, 3)), @"Range: %@", NSStringFromRange(matchedRange));
  
  STAssertTrueNoThrow((firstRanges = [regexEnumerator nextRanges]) != NULL, nil);
  matchedRange = NSMakeRange(1214281727, 37607);
  STAssertTrueNoThrow(NSEqualRanges(matchedRange = [regexEnumerator currentRangeForCaptureName:@"everything"], NSMakeRange(5, 2)), @"Range: %@", NSStringFromRange(matchedRange));
  
  STAssertTrueNoThrow((firstRanges = [regexEnumerator nextRanges]) == NULL, nil);
  matchedRange = NSMakeRange(1214281727, 37607);
  STAssertTrueNoThrow(NSEqualRanges(matchedRange = [regexEnumerator currentRangeForCaptureName:@"everything"], NSMakeRange(NSNotFound, 0)), @"Range: %@", NSStringFromRange(matchedRange));
  
  STAssertTrueNoThrow((firstRanges = [regexEnumerator nextRanges]) == NULL, nil);
  matchedRange = NSMakeRange(1214281727, 37607);
  STAssertTrueNoThrow(NSEqualRanges(matchedRange = [regexEnumerator currentRangeForCaptureName:@"everything"], NSMakeRange(NSNotFound, 0)), @"Range: %@", NSStringFromRange(matchedRange));


  // different capture subpattern
  STAssertTrueNoThrow((regexEnumerator = [enumerateString matchEnumeratorWithRegex:@"(?<everything>\\s*(?<theNumber>\\d+)(?<maybeComma>,?))"]) != NULL, nil);
  
  matchedRange = NSMakeRange(1214281727, 37607);
  STAssertThrowsSpecificNamed((matchedRange = [regexEnumerator currentRangeForCaptureName:@"theNumber"]), NSException, NSInvalidArgumentException, nil);
  STAssertTrue(NSEqualRanges(matchedRange, NSMakeRange(1214281727, 37607)) , @"Range: %p", NSStringFromRange(matchedRange));

  // Advance to the first match
  STAssertTrueNoThrow((firstRanges = [regexEnumerator nextRanges]) != NULL, nil);
  matchedRange = NSMakeRange(1214281727, 37607);
  STAssertTrueNoThrow(NSEqualRanges(matchedRange = [regexEnumerator currentRangeForCaptureName:@"theNumber"], NSMakeRange(0, 1)), @"Range: %@", NSStringFromRange(matchedRange));
  
  STAssertTrueNoThrow((firstRanges = [regexEnumerator nextRanges]) != NULL, nil);
  matchedRange = NSMakeRange(1214281727, 37607);
  STAssertTrueNoThrow(NSEqualRanges(matchedRange = [regexEnumerator currentRangeForCaptureName:@"theNumber"], NSMakeRange(3, 1)), @"Range: %@", NSStringFromRange(matchedRange));
  
  STAssertTrueNoThrow((firstRanges = [regexEnumerator nextRanges]) != NULL, nil);
  matchedRange = NSMakeRange(1214281727, 37607);
  STAssertTrueNoThrow(NSEqualRanges(matchedRange = [regexEnumerator currentRangeForCaptureName:@"theNumber"], NSMakeRange(6, 1)), @"Range: %@", NSStringFromRange(matchedRange));
  
  STAssertTrueNoThrow((firstRanges = [regexEnumerator nextRanges]) == NULL, nil);
  matchedRange = NSMakeRange(1214281727, 37607);
  STAssertTrueNoThrow(NSEqualRanges(matchedRange = [regexEnumerator currentRangeForCaptureName:@"theNumber"], NSMakeRange(NSNotFound, 0)), @"Range: %@", NSStringFromRange(matchedRange));
  
  STAssertTrueNoThrow((firstRanges = [regexEnumerator nextRanges]) == NULL, nil);
  matchedRange = NSMakeRange(1214281727, 37607);
  STAssertTrueNoThrow(NSEqualRanges(matchedRange = [regexEnumerator currentRangeForCaptureName:@"theNumber"], NSMakeRange(NSNotFound, 0)), @"Range: %@", NSStringFromRange(matchedRange));
  

  // mixed capture subpattern
  STAssertTrueNoThrow((regexEnumerator = [enumerateString matchEnumeratorWithRegex:@"(?<everything>\\s*(?<theNumber>\\d+)(?<maybeComma>,?))"]) != NULL, nil);
  
  matchedRange = NSMakeRange(1214281727, 37607);
  STAssertThrowsSpecificNamed((matchedRange = [regexEnumerator currentRangeForCaptureName:@"everything"]), NSException, NSInvalidArgumentException, nil);
  STAssertTrue(NSEqualRanges(matchedRange, NSMakeRange(1214281727, 37607)) , @"Range: %p", NSStringFromRange(matchedRange));

  // Advance to the first match
  STAssertTrueNoThrow((firstRanges = [regexEnumerator nextRanges]) != NULL, nil);
  matchedRange = NSMakeRange(1214281727, 37607);
  STAssertTrueNoThrow(NSEqualRanges(matchedRange = [regexEnumerator currentRangeForCaptureName:@"theNumber"], NSMakeRange(0, 1)), @"Range: %@", NSStringFromRange(matchedRange));
  
  STAssertTrueNoThrow((firstRanges = [regexEnumerator nextRanges]) != NULL, nil);
  matchedRange = NSMakeRange(1214281727, 37607);
  STAssertTrueNoThrow(NSEqualRanges(matchedRange = [regexEnumerator currentRangeForCaptureName:@"everything"], NSMakeRange(2, 3)), @"Range: %@", NSStringFromRange(matchedRange));
  
  STAssertTrueNoThrow((firstRanges = [regexEnumerator nextRanges]) != NULL, nil);
  matchedRange = NSMakeRange(1214281727, 37607);
  STAssertTrueNoThrow(NSEqualRanges(matchedRange = [regexEnumerator currentRangeForCaptureName:@"theNumber"], NSMakeRange(6, 1)), @"Range: %@", NSStringFromRange(matchedRange));
  
  STAssertTrueNoThrow((firstRanges = [regexEnumerator nextRanges]) == NULL, nil);
  matchedRange = NSMakeRange(1214281727, 37607);
  STAssertTrueNoThrow(NSEqualRanges(matchedRange = [regexEnumerator currentRangeForCaptureName:@"everything"], NSMakeRange(NSNotFound, 0)), @"Range: %@", NSStringFromRange(matchedRange));
  
  STAssertTrueNoThrow((firstRanges = [regexEnumerator nextRanges]) == NULL, nil);
  matchedRange = NSMakeRange(1214281727, 37607);
  STAssertTrueNoThrow(NSEqualRanges(matchedRange = [regexEnumerator currentRangeForCaptureName:@"theNumber"], NSMakeRange(NSNotFound, 0)), @"Range: %@", NSStringFromRange(matchedRange));


  // invalid capture subpattern
  STAssertTrueNoThrow((regexEnumerator = [enumerateString matchEnumeratorWithRegex:@"(?<everything>\\s*(?<theNumber>\\d+)(?<maybeComma>,?))"]) != NULL, nil);
    
  matchedRange = NSMakeRange(1214281727, 37607);
  STAssertThrowsSpecificNamed((matchedRange = [regexEnumerator currentRangeForCaptureName:@"theNumber"]), NSException, NSInvalidArgumentException, nil);
  STAssertTrue(NSEqualRanges(matchedRange, NSMakeRange(1214281727, 37607)) , @"Range: %p", NSStringFromRange(matchedRange));
  
  // Advance to the first match
  STAssertTrueNoThrow((firstRanges = [regexEnumerator nextRanges]) != NULL, nil);
  matchedRange = NSMakeRange(1214281727, 37607);
  STAssertThrowsSpecificNamed((matchedRange = [regexEnumerator currentRangeForCaptureName:NULL]), NSException, NSInvalidArgumentException, nil);
  STAssertTrue(NSEqualRanges(matchedRange, NSMakeRange(1214281727, 37607)), nil);
  
  matchedRange = NSMakeRange(1214281727, 37607);
  STAssertTrueNoThrow(NSEqualRanges(matchedRange = [regexEnumerator currentRangeForCaptureName:@"everything"], NSMakeRange(0, 2)), @"Range: %@", NSStringFromRange(matchedRange));
  
  matchedRange = NSMakeRange(1214281727, 37607);
  STAssertThrowsSpecificNamed((matchedRange = [regexEnumerator currentRangeForCaptureName:@"whichOne?"]), NSException, RKRegexCaptureReferenceException, nil);
  STAssertTrue(NSEqualRanges(matchedRange, NSMakeRange(1214281727, 37607)), nil);

  matchedRange = NSMakeRange(1214281727, 37607);
  STAssertTrueNoThrow(NSEqualRanges(matchedRange = [regexEnumerator currentRangeForCaptureName:@"theNumber"], NSMakeRange(0, 1)), @"Range: %@", NSStringFromRange(matchedRange));


  // Advance
  STAssertTrueNoThrow((firstRanges = [regexEnumerator nextRanges]) != NULL, nil);

  matchedRange = NSMakeRange(1214281727, 37607);
  STAssertThrowsSpecificNamed((matchedRange = [regexEnumerator currentRangeForCaptureName:@"noWay"]), NSException, RKRegexCaptureReferenceException, nil);
  STAssertTrue(NSEqualRanges(matchedRange, NSMakeRange(1214281727, 37607)), nil);
  
  matchedRange = NSMakeRange(1214281727, 37607);
  STAssertTrueNoThrow(NSEqualRanges(matchedRange = [regexEnumerator currentRangeForCaptureName:@"theNumber"], NSMakeRange(3, 1)), @"Range: %@", NSStringFromRange(matchedRange));
  
  matchedRange = NSMakeRange(1214281727, 37607);
  STAssertThrowsSpecificNamed((matchedRange = [regexEnumerator currentRangeForCaptureName:@"cantBe"]), NSException, RKRegexCaptureReferenceException, nil);
  STAssertTrue(NSEqualRanges(matchedRange, NSMakeRange(1214281727, 37607)), nil);


  matchedRange = NSMakeRange(1214281727, 37607);
  STAssertTrueNoThrow(NSEqualRanges(matchedRange = [regexEnumerator currentRangeForCaptureName:@"everything"], NSMakeRange(2, 3)), @"Range: %@", NSStringFromRange(matchedRange));


  // Advance
  STAssertTrueNoThrow((firstRanges = [regexEnumerator nextRanges]) != NULL, nil);
  
  matchedRange = NSMakeRange(1214281727, 37607);
  STAssertThrowsSpecificNamed((matchedRange = [regexEnumerator currentRangeForCaptureName:@"ohNo"]), NSException, RKRegexCaptureReferenceException, @"Range: %@", NSStringFromRange(matchedRange));
  STAssertTrue(NSEqualRanges(matchedRange, NSMakeRange(1214281727, 37607)), nil);
  
  matchedRange = NSMakeRange(1214281727, 37607);
  STAssertTrueNoThrow(NSEqualRanges(matchedRange = [regexEnumerator currentRangeForCaptureName:@"everything"], NSMakeRange(5, 2)), @"Range: %@", NSStringFromRange(matchedRange));
  
  matchedRange = NSMakeRange(1214281727, 37607);
  STAssertThrowsSpecificNamed((matchedRange = [regexEnumerator currentRangeForCaptureName:@"spoon!"]), NSException, RKRegexCaptureReferenceException, @"Range: %@", NSStringFromRange(matchedRange));
  STAssertTrue(NSEqualRanges(matchedRange, NSMakeRange(1214281727, 37607)), nil);

  matchedRange = NSMakeRange(1214281727, 37607);
  STAssertTrueNoThrow(NSEqualRanges(matchedRange = [regexEnumerator currentRangeForCaptureName:@"theNumber"], NSMakeRange(6, 1)), @"Range: %@", NSStringFromRange(matchedRange));
  

  // Advance
  STAssertTrueNoThrow((firstRanges = [regexEnumerator nextRanges]) == NULL, nil);

  matchedRange = NSMakeRange(1214281727, 37607);
  STAssertTrueNoThrow(NSEqualRanges(matchedRange = [regexEnumerator currentRangeForCaptureName:@"everything"], NSMakeRange(NSNotFound, 0)), @"Range: %@", NSStringFromRange(matchedRange));
  matchedRange = NSMakeRange(1214281727, 37607);
  STAssertTrueNoThrow(NSEqualRanges(matchedRange = [regexEnumerator currentRangeForCaptureName:@"theNumber"], NSMakeRange(NSNotFound, 0)), @"Range: %@", NSStringFromRange(matchedRange));
  matchedRange = NSMakeRange(1214281727, 37607);
  STAssertThrowsSpecificNamed((matchedRange = [regexEnumerator currentRangeForCaptureName:NULL]), NSException, NSInvalidArgumentException, @"Range: %@", NSStringFromRange(matchedRange));
  STAssertTrue(NSEqualRanges(matchedRange, NSMakeRange(1214281727, 37607)), nil);
  matchedRange = NSMakeRange(1214281727, 37607);
  STAssertTrueNoThrow(NSEqualRanges(matchedRange = [regexEnumerator currentRangeForCaptureName:@"lostMe"], NSMakeRange(NSNotFound, 0)), @"Range: %@", NSStringFromRange(matchedRange));
  
  // Advance
  STAssertTrueNoThrow((firstRanges = [regexEnumerator nextRanges]) == NULL, nil);
  
  matchedRange = NSMakeRange(1214281727, 37607);
  // Once exhausted, will always return NSNotFound, 0, even for invalid capture numbers
  STAssertTrueNoThrow(NSEqualRanges(matchedRange = [regexEnumerator currentRangeForCaptureName:@"everything"], NSMakeRange(NSNotFound, 0)), @"Range: %@", NSStringFromRange(matchedRange));
  matchedRange = NSMakeRange(1214281727, 37607);
  STAssertTrueNoThrow(NSEqualRanges(matchedRange = [regexEnumerator currentRangeForCaptureName:@"theNumber"], NSMakeRange(NSNotFound, 0)), @"Range: %@", NSStringFromRange(matchedRange));
  matchedRange = NSMakeRange(1214281727, 37607);
  STAssertTrueNoThrow(NSEqualRanges(matchedRange = [regexEnumerator currentRangeForCaptureName:@"weirdSounds"], NSMakeRange(NSNotFound, 0)), @"Range: %@", NSStringFromRange(matchedRange));
  matchedRange = NSMakeRange(1214281727, 37607);
  STAssertTrueNoThrow(NSEqualRanges(matchedRange = [regexEnumerator currentRangeForCaptureName:@"boringText"], NSMakeRange(NSNotFound, 0)), @"Range: %@", NSStringFromRange(matchedRange));
}

- (void) testEnumeratorCaptureExtractionAndConversion
{
  NSString *enumerateString = @"1, 2, 3", *captured0String = nil, *captured1String = nil, *captured2String = nil;
  NSRange *matchedRanges = NULL, *firstRanges = NULL;
  int int0Type = 59, int1Type = 61, int2Type = 67;
  RKEnumerator *regexEnumerator = NULL;

  STAssertTrueNoThrow((regexEnumerator = [enumerateString matchEnumeratorWithRegex:@"\\s*(\\d+),?"]) != NULL, nil);
  
  matchedRanges = (NSRange *)0xdeadbeef;
  STAssertTrueNoThrow((firstRanges = matchedRanges = [regexEnumerator nextRanges]) != NULL, nil);
  STAssertTrue(firstRanges == matchedRanges, nil);
  STAssertTrue(NSEqualRanges(matchedRanges[0], NSMakeRange(0, 2)), @"Range: %@", NSStringFromRange(matchedRanges[0]));
  STAssertTrue(NSEqualRanges(matchedRanges[1], NSMakeRange(0, 1)), @"Range: %@", NSStringFromRange(matchedRanges[1]));

  int0Type = 59; int1Type = 61; int2Type = 67;
  STAssertTrueNoThrow(([regexEnumerator getCapturesWithReferences:@"${1:%d}", &int1Type, nil] == YES), nil);
  STAssertTrue(int0Type == 59, @"int0Type = %d", int0Type);
  STAssertTrue(int1Type == 1, @"int1Type = %d", int1Type);
  STAssertTrue(int2Type == 67, @"int2Type = %d", int2Type);
  captured0String = captured1String = captured2String = nil;
  STAssertTrueNoThrow(([regexEnumerator getCapturesWithReferences:@"${1}", &captured1String, nil] == YES), nil);
  STAssertTrue([captured1String isEqualToString:@"1"] == YES, @"captured1String = %@", captured1String);
  STAssertTrue(captured0String == nil, @"captured0String = %@", captured0String); 
  STAssertTrue(captured2String == nil, @"captured2String = %@", captured2String); 


  STAssertTrueNoThrow((matchedRanges = [regexEnumerator nextRanges]) != NULL, nil);
  STAssertTrue(firstRanges == matchedRanges, nil);
  STAssertTrue(NSEqualRanges(matchedRanges[0], NSMakeRange(2, 3)), @"Range: %@", NSStringFromRange(matchedRanges[0]));
  STAssertTrue(NSEqualRanges(matchedRanges[1], NSMakeRange(3, 1)), @"Range: %@", NSStringFromRange(matchedRanges[1]));
  
  int0Type = 59; int1Type = 61; int2Type = 67;
  STAssertTrueNoThrow(([regexEnumerator getCapturesWithReferences:@"${1:%d}", &int1Type, nil] == YES), nil);
  STAssertTrue(int0Type == 59, @"int0Type = %d", int0Type);
  STAssertTrue(int1Type == 2, @"int1Type = %d", int1Type);
  STAssertTrue(int2Type == 67, @"int2Type = %d", int2Type);
  captured0String = captured1String = captured2String = nil;
  STAssertTrueNoThrow(([regexEnumerator getCapturesWithReferences:@"${1}", &captured1String, nil] == YES), nil);
  STAssertTrue([captured1String isEqualToString:@"2"] == YES, @"captured1String = %@", captured1String);
  STAssertTrue(captured0String == nil, @"captured0String = %@", captured0String); 
  STAssertTrue(captured2String == nil, @"captured2String = %@", captured2String); 

  STAssertTrueNoThrow((matchedRanges = [regexEnumerator nextRanges]) != NULL, nil);
  STAssertTrue(firstRanges == matchedRanges, nil);
  STAssertTrue(NSEqualRanges(matchedRanges[0], NSMakeRange(5, 2)), @"Range: %@", NSStringFromRange(matchedRanges[0]));
  STAssertTrue(NSEqualRanges(matchedRanges[1], NSMakeRange(6, 1)), @"Range: %@", NSStringFromRange(matchedRanges[1]));
  
  int0Type = 59; int1Type = 61; int2Type = 67;
  STAssertTrueNoThrow(([regexEnumerator getCapturesWithReferences:@"${1:%d}", &int1Type, nil] == YES), nil);
  STAssertTrue(int0Type == 59, @"int0Type = %d", int0Type);
  STAssertTrue(int1Type == 3, @"int1Type = %d", int1Type);
  STAssertTrue(int2Type == 67, @"int2Type = %d", int2Type);
  captured0String = captured1String = captured2String = nil;
  STAssertTrueNoThrow(([regexEnumerator getCapturesWithReferences:@"${1}", &captured1String, nil] == YES), nil);
  STAssertTrue([captured1String isEqualToString:@"3"] == YES, @"captured1String = %@", captured1String);
  STAssertTrue(captured0String == nil, @"captured0String = %@", captured0String); 
  STAssertTrue(captured2String == nil, @"captured2String = %@", captured2String); 


  STAssertTrueNoThrow((matchedRanges = [regexEnumerator nextRanges]) == NULL, nil);
  
  int0Type = 59; int1Type = 61; int2Type = 67;
  STAssertTrueNoThrow(([regexEnumerator getCapturesWithReferences:@"${1:%d}", &int1Type, nil] == NO), nil);
  STAssertTrue(int0Type == 59, @"int0Type = %d", int0Type);
  STAssertTrue(int1Type == 61, @"int1Type = %d", int1Type);
  STAssertTrue(int2Type == 67, @"int2Type = %d", int2Type);
  captured0String = captured1String = captured2String = nil;
  STAssertTrueNoThrow(([regexEnumerator getCapturesWithReferences:@"${1}", &captured1String, nil] == NO), nil);
  STAssertTrue(captured0String == nil, @"captured0String = %@", captured0String); 
  STAssertTrue(captured0String == nil, @"captured0String = %@", captured1String); 
  STAssertTrue(captured2String == nil, @"captured2String = %@", captured2String); 



  STAssertTrueNoThrow((regexEnumerator = [enumerateString matchEnumeratorWithRegex:@"\\s*(?<theNumber>\\d+),?"]) != NULL, nil);
  
  matchedRanges = (NSRange *)0xdeadbeef;
  STAssertTrueNoThrow((firstRanges = matchedRanges = [regexEnumerator nextRanges]) != NULL, nil);
  STAssertTrue(firstRanges == matchedRanges, nil);
  STAssertTrue(NSEqualRanges(matchedRanges[0], NSMakeRange(0, 2)), @"Range: %@", NSStringFromRange(matchedRanges[0]));
  STAssertTrue(NSEqualRanges(matchedRanges[1], NSMakeRange(0, 1)), @"Range: %@", NSStringFromRange(matchedRanges[1]));
  
  int0Type = 59; int1Type = 61; int2Type = 67;
  STAssertTrueNoThrow(([regexEnumerator getCapturesWithReferences:@"${1:%d}", &int1Type, nil] == YES), nil);
  STAssertTrue(int0Type == 59, @"int0Type = %d", int0Type);
  STAssertTrue(int1Type == 1, @"int1Type = %d", int1Type);
  STAssertTrue(int2Type == 67, @"int2Type = %d", int2Type);
  captured0String = captured1String = captured2String = nil;
  STAssertTrueNoThrow(([regexEnumerator getCapturesWithReferences:@"${1}", &captured1String, nil] == YES), nil);
  STAssertTrue([captured1String isEqualToString:@"1"] == YES, @"captured1String = %@", captured1String);
  STAssertTrue(captured0String == nil, @"captured0String = %@", captured0String); 
  STAssertTrue(captured2String == nil, @"captured2String = %@", captured2String); 
  int0Type = 59; int1Type = 61; int2Type = 67;
  STAssertTrueNoThrow(([regexEnumerator getCapturesWithReferences:@"${theNumber:%d}", &int1Type, nil] == YES), nil);
  STAssertTrue(int0Type == 59, @"int0Type = %d", int0Type);
  STAssertTrue(int1Type == 1, @"int1Type = %d", int1Type);
  STAssertTrue(int2Type == 67, @"int2Type = %d", int2Type);
  captured0String = captured1String = captured2String = nil;
  STAssertTrueNoThrow(([regexEnumerator getCapturesWithReferences:@"${theNumber}", &captured1String, nil] == YES), nil);
  STAssertTrue([captured1String isEqualToString:@"1"] == YES, @"captured1String = %@", captured1String);
  STAssertTrue(captured0String == nil, @"captured0String = %@", captured0String); 
  STAssertTrue(captured2String == nil, @"captured2String = %@", captured2String); 
  
  
  STAssertTrueNoThrow((matchedRanges = [regexEnumerator nextRanges]) != NULL, nil);
  STAssertTrue(firstRanges == matchedRanges, nil);
  STAssertTrue(NSEqualRanges(matchedRanges[0], NSMakeRange(2, 3)), @"Range: %@", NSStringFromRange(matchedRanges[0]));
  STAssertTrue(NSEqualRanges(matchedRanges[1], NSMakeRange(3, 1)), @"Range: %@", NSStringFromRange(matchedRanges[1]));
  
  int0Type = 59; int1Type = 61; int2Type = 67;
  STAssertTrueNoThrow(([regexEnumerator getCapturesWithReferences:@"${1:%d}", &int1Type, nil] == YES), nil);
  STAssertTrue(int0Type == 59, @"int0Type = %d", int0Type);
  STAssertTrue(int1Type == 2, @"int1Type = %d", int1Type);
  STAssertTrue(int2Type == 67, @"int2Type = %d", int2Type);
  captured0String = captured1String = captured2String = nil;
  STAssertTrueNoThrow(([regexEnumerator getCapturesWithReferences:@"${1}", &captured1String, nil] == YES), nil);
  STAssertTrue([captured1String isEqualToString:@"2"] == YES, @"captured1String = %@", captured1String);
  STAssertTrue(captured0String == nil, @"captured0String = %@", captured0String); 
  STAssertTrue(captured2String == nil, @"captured2String = %@", captured2String); 
  int0Type = 59; int1Type = 61; int2Type = 67;
  STAssertTrueNoThrow(([regexEnumerator getCapturesWithReferences:@"${theNumber:%d}", &int1Type, nil] == YES), nil);
  STAssertTrue(int0Type == 59, @"int0Type = %d", int0Type);
  STAssertTrue(int1Type == 2, @"int1Type = %d", int1Type);
  STAssertTrue(int2Type == 67, @"int2Type = %d", int2Type);
  captured0String = captured1String = captured2String = nil;
  STAssertTrueNoThrow(([regexEnumerator getCapturesWithReferences:@"${theNumber}", &captured1String, nil] == YES), nil);
  STAssertTrue([captured1String isEqualToString:@"2"] == YES, @"captured1String = %@", captured1String);
  STAssertTrue(captured0String == nil, @"captured0String = %@", captured0String); 
  STAssertTrue(captured2String == nil, @"captured2String = %@", captured2String); 
  
  STAssertTrueNoThrow((matchedRanges = [regexEnumerator nextRanges]) != NULL, nil);
  STAssertTrue(firstRanges == matchedRanges, nil);
  STAssertTrue(NSEqualRanges(matchedRanges[0], NSMakeRange(5, 2)), @"Range: %@", NSStringFromRange(matchedRanges[0]));
  STAssertTrue(NSEqualRanges(matchedRanges[1], NSMakeRange(6, 1)), @"Range: %@", NSStringFromRange(matchedRanges[1]));
  
  int0Type = 59; int1Type = 61; int2Type = 67;
  STAssertTrueNoThrow(([regexEnumerator getCapturesWithReferences:@"${1:%d}", &int1Type, nil] == YES), nil);
  STAssertTrue(int0Type == 59, @"int0Type = %d", int0Type);
  STAssertTrue(int1Type == 3, @"int1Type = %d", int1Type);
  STAssertTrue(int2Type == 67, @"int2Type = %d", int2Type);
  captured0String = captured1String = captured2String = nil;
  STAssertTrueNoThrow(([regexEnumerator getCapturesWithReferences:@"${1}", &captured1String, nil] == YES), nil);
  STAssertTrue([captured1String isEqualToString:@"3"] == YES, @"captured1String = %@", captured1String);
  STAssertTrue(captured0String == nil, @"captured0String = %@", captured0String); 
  STAssertTrue(captured2String == nil, @"captured2String = %@", captured2String); 
  int0Type = 59; int1Type = 61; int2Type = 67;
  STAssertTrueNoThrow(([regexEnumerator getCapturesWithReferences:@"${theNumber:%d}", &int1Type, nil] == YES), nil);
  STAssertTrue(int0Type == 59, @"int0Type = %d", int0Type);
  STAssertTrue(int1Type == 3, @"int1Type = %d", int1Type);
  STAssertTrue(int2Type == 67, @"int2Type = %d", int2Type);
  captured0String = captured1String = captured2String = nil;
  STAssertTrueNoThrow(([regexEnumerator getCapturesWithReferences:@"${theNumber}", &captured1String, nil] == YES), nil);
  STAssertTrue([captured1String isEqualToString:@"3"] == YES, @"captured1String = %@", captured1String);
  STAssertTrue(captured0String == nil, @"captured0String = %@", captured0String); 
  STAssertTrue(captured2String == nil, @"captured2String = %@", captured2String); 
  
  
  STAssertTrueNoThrow((matchedRanges = [regexEnumerator nextRanges]) == NULL, nil);
  
  int0Type = 59; int1Type = 61; int2Type = 67;
  STAssertTrueNoThrow(([regexEnumerator getCapturesWithReferences:@"${1:%d}", &int1Type, nil] == NO), nil);
  STAssertTrue(int0Type == 59, @"int0Type = %d", int0Type);
  STAssertTrue(int1Type == 61, @"int1Type = %d", int1Type);
  STAssertTrue(int2Type == 67, @"int2Type = %d", int2Type);
  captured0String = captured1String = captured2String = nil;
  STAssertTrueNoThrow(([regexEnumerator getCapturesWithReferences:@"${1}", &captured1String, nil] == NO), nil);
  STAssertTrue(captured0String == nil, @"captured0String = %@", captured0String); 
  STAssertTrue(captured0String == nil, @"captured0String = %@", captured1String); 
  STAssertTrue(captured2String == nil, @"captured2String = %@", captured2String); 
  int0Type = 59; int1Type = 61; int2Type = 67;
  STAssertTrueNoThrow(([regexEnumerator getCapturesWithReferences:@"${theNumber:%d}", &int1Type, nil] == NO), nil);
  STAssertTrue(int0Type == 59, @"int0Type = %d", int0Type);
  STAssertTrue(int1Type == 61, @"int1Type = %d", int1Type);
  STAssertTrue(int2Type == 67, @"int2Type = %d", int2Type);
  captured0String = captured1String = captured2String = nil;
  STAssertTrueNoThrow(([regexEnumerator getCapturesWithReferences:@"${theNumber}", &captured1String, nil] == NO), nil);
  STAssertTrue(captured0String == nil, @"captured0String = %@", captured0String); 
  STAssertTrue(captured0String == nil, @"captured0String = %@", captured1String); 
  STAssertTrue(captured2String == nil, @"captured2String = %@", captured2String); 
  
  
 
  // Check for some exception cases.
  STAssertTrueNoThrow((regexEnumerator = [enumerateString matchEnumeratorWithRegex:@"\\s*(\\d+),?"]) != NULL, nil);
  
  matchedRanges = (NSRange *)0xdeadbeef;
  STAssertTrueNoThrow((firstRanges = matchedRanges = [regexEnumerator nextRanges]) != NULL, nil);
  STAssertTrue(firstRanges == matchedRanges, nil);
  STAssertTrue(NSEqualRanges(matchedRanges[0], NSMakeRange(0, 2)), @"Range: %@", NSStringFromRange(matchedRanges[0]));
  STAssertTrue(NSEqualRanges(matchedRanges[1], NSMakeRange(0, 1)), @"Range: %@", NSStringFromRange(matchedRanges[1]));
  
  int0Type = 59; int1Type = 61; int2Type = 67;
  STAssertTrueNoThrow(([regexEnumerator getCapturesWithReferences:@"${1:%d}", &int1Type, nil] == YES), nil);
  STAssertTrue(int0Type == 59, @"int0Type = %d", int0Type);
  STAssertTrue(int1Type == 1, @"int1Type = %d", int1Type);
  STAssertTrue(int2Type == 67, @"int2Type = %d", int2Type);
  captured0String = captured1String = captured2String = nil;
  STAssertTrueNoThrow(([regexEnumerator getCapturesWithReferences:@"${1}", &captured1String, nil] == YES), nil);
  STAssertTrue([captured1String isEqualToString:@"1"] == YES, @"captured1String = %@", captured1String);
  STAssertTrue(captured0String == nil, @"captured0String = %@", captured0String); 
  STAssertTrue(captured2String == nil, @"captured2String = %@", captured2String); 
  int0Type = 59; int1Type = 61; int2Type = 67;
  STAssertThrowsSpecificNamed([regexEnumerator getCapturesWithReferences:NULL], NSException, NSInvalidArgumentException, nil);
  STAssertTrue(int0Type == 59, @"int0Type = %d", int0Type);
  STAssertTrue(int1Type == 61, @"int1Type = %d", int1Type);
  STAssertTrue(int2Type == 67, @"int2Type = %d", int2Type);
  captured0String = captured1String = captured2String = nil;
  STAssertThrowsSpecificNamed([regexEnumerator getCapturesWithReferences:NULL], NSException, NSInvalidArgumentException, nil);
  STAssertTrue(captured0String == nil, @"captured0String = %@", captured0String); 
  STAssertTrue(captured0String == nil, @"captured0String = %@", captured1String); 
  STAssertTrue(captured2String == nil, @"captured2String = %@", captured2String); 
  // Exception shouldn't affect our results.
  int0Type = 59; int1Type = 61; int2Type = 67;
  STAssertTrueNoThrow(([regexEnumerator getCapturesWithReferences:@"${1:%d}", &int1Type, nil] == YES), nil);
  STAssertTrue(int0Type == 59, @"int0Type = %d", int0Type);
  STAssertTrue(int1Type == 1, @"int1Type = %d", int1Type);
  STAssertTrue(int2Type == 67, @"int2Type = %d", int2Type);
  captured0String = captured1String = captured2String = nil;
  STAssertTrueNoThrow(([regexEnumerator getCapturesWithReferences:@"${1}", &captured1String, nil] == YES), nil);
  STAssertTrue([captured1String isEqualToString:@"1"] == YES, @"captured1String = %@", captured1String);
  STAssertTrue(captured0String == nil, @"captured0String = %@", captured0String); 
  STAssertTrue(captured2String == nil, @"captured2String = %@", captured2String); 
  
  
  STAssertTrueNoThrow((matchedRanges = [regexEnumerator nextRanges]) != NULL, nil);
  STAssertTrue(firstRanges == matchedRanges, nil);
  STAssertTrue(NSEqualRanges(matchedRanges[0], NSMakeRange(2, 3)), @"Range: %@", NSStringFromRange(matchedRanges[0]));
  STAssertTrue(NSEqualRanges(matchedRanges[1], NSMakeRange(3, 1)), @"Range: %@", NSStringFromRange(matchedRanges[1]));
  
  int0Type = 59; int1Type = 61; int2Type = 67;
  STAssertThrowsSpecificNamed([regexEnumerator getCapturesWithReferences:NULL], NSException, NSInvalidArgumentException, nil);
  STAssertTrue(int0Type == 59, @"int0Type = %d", int0Type);
  STAssertTrue(int1Type == 61, @"int1Type = %d", int1Type);
  STAssertTrue(int2Type == 67, @"int2Type = %d", int2Type);
  captured0String = captured1String = captured2String = nil;
  STAssertThrowsSpecificNamed([regexEnumerator getCapturesWithReferences:NULL], NSException, NSInvalidArgumentException, nil);
  STAssertTrue(captured0String == nil, @"captured0String = %@", captured0String); 
  STAssertTrue(captured0String == nil, @"captured0String = %@", captured1String); 
  STAssertTrue(captured2String == nil, @"captured2String = %@", captured2String); 
  // Exception shouldn't affect our results.
  int0Type = 59; int1Type = 61; int2Type = 67;
  STAssertTrueNoThrow(([regexEnumerator getCapturesWithReferences:@"${1:%d}", &int1Type, nil] == YES), nil);
  STAssertTrue(int0Type == 59, @"int0Type = %d", int0Type);
  STAssertTrue(int1Type == 2, @"int1Type = %d", int1Type);
  STAssertTrue(int2Type == 67, @"int2Type = %d", int2Type);
  captured0String = captured1String = captured2String = nil;
  STAssertTrueNoThrow(([regexEnumerator getCapturesWithReferences:@"${1}", &captured1String, nil] == YES), nil);
  STAssertTrue([captured1String isEqualToString:@"2"] == YES, @"captured1String = %@", captured1String);
  STAssertTrue(captured0String == nil, @"captured0String = %@", captured0String); 
  STAssertTrue(captured2String == nil, @"captured2String = %@", captured2String); 
  
  STAssertTrueNoThrow((matchedRanges = [regexEnumerator nextRanges]) != NULL, nil);
  STAssertTrue(firstRanges == matchedRanges, nil);
  STAssertTrue(NSEqualRanges(matchedRanges[0], NSMakeRange(5, 2)), @"Range: %@", NSStringFromRange(matchedRanges[0]));
  STAssertTrue(NSEqualRanges(matchedRanges[1], NSMakeRange(6, 1)), @"Range: %@", NSStringFromRange(matchedRanges[1]));
  
  int0Type = 59; int1Type = 61; int2Type = 67;
  STAssertTrueNoThrow(([regexEnumerator getCapturesWithReferences:@"${1:%d}", &int1Type, nil] == YES), nil);
  STAssertTrue(int0Type == 59, @"int0Type = %d", int0Type);
  STAssertTrue(int1Type == 3, @"int1Type = %d", int1Type);
  STAssertTrue(int2Type == 67, @"int2Type = %d", int2Type);
  captured0String = captured1String = captured2String = nil;
  STAssertTrueNoThrow(([regexEnumerator getCapturesWithReferences:@"${1}", &captured1String, nil] == YES), nil);
  STAssertTrue([captured1String isEqualToString:@"3"] == YES, @"captured1String = %@", captured1String);
  STAssertTrue(captured0String == nil, @"captured0String = %@", captured0String); 
  STAssertTrue(captured2String == nil, @"captured2String = %@", captured2String); 
  
  int0Type = 59; int1Type = 61; int2Type = 67;
  STAssertThrowsSpecificNamed([regexEnumerator getCapturesWithReferences:NULL], NSException, NSInvalidArgumentException, nil);
  STAssertTrue(int0Type == 59, @"int0Type = %d", int0Type);
  STAssertTrue(int1Type == 61, @"int1Type = %d", int1Type);
  STAssertTrue(int2Type == 67, @"int2Type = %d", int2Type);
  captured0String = captured1String = captured2String = nil;
  STAssertThrowsSpecificNamed([regexEnumerator getCapturesWithReferences:NULL], NSException, NSInvalidArgumentException, nil);
  STAssertTrue(captured0String == nil, @"captured0String = %@", captured0String); 
  STAssertTrue(captured0String == nil, @"captured0String = %@", captured1String); 
  STAssertTrue(captured2String == nil, @"captured2String = %@", captured2String); 
  // Exception shouldn't affect our results.
  
  STAssertTrueNoThrow((matchedRanges = [regexEnumerator nextRanges]) == NULL, nil);
  
  int0Type = 59; int1Type = 61; int2Type = 67;
  STAssertTrueNoThrow(([regexEnumerator getCapturesWithReferences:@"${1:%d}", &int1Type, nil] == NO), nil);
  STAssertTrue(int0Type == 59, @"int0Type = %d", int0Type);
  STAssertTrue(int1Type == 61, @"int1Type = %d", int1Type);
  STAssertTrue(int2Type == 67, @"int2Type = %d", int2Type);
  captured0String = captured1String = captured2String = nil;
  STAssertTrueNoThrow(([regexEnumerator getCapturesWithReferences:@"${1}", &captured1String, nil] == NO), nil);
  STAssertTrue(captured0String == nil, @"captured0String = %@", captured0String); 
  STAssertTrue(captured0String == nil, @"captured0String = %@", captured1String); 
  STAssertTrue(captured2String == nil, @"captured2String = %@", captured2String); 
  int0Type = 59; int1Type = 61; int2Type = 67;
  STAssertThrowsSpecificNamed([regexEnumerator getCapturesWithReferences:NULL], NSException, NSInvalidArgumentException, nil);
  STAssertTrue(int0Type == 59, @"int0Type = %d", int0Type);
  STAssertTrue(int1Type == 61, @"int1Type = %d", int1Type);
  STAssertTrue(int2Type == 67, @"int2Type = %d", int2Type);
  captured0String = captured1String = captured2String = nil;
  STAssertThrowsSpecificNamed([regexEnumerator getCapturesWithReferences:NULL], NSException, NSInvalidArgumentException, nil);
  STAssertTrue(captured0String == nil, @"captured0String = %@", captured0String); 
  STAssertTrue(captured0String == nil, @"captured0String = %@", captured1String); 
  STAssertTrue(captured2String == nil, @"captured2String = %@", captured2String); 

  
}

- (void)testEnumeratorStringCreation
{
  NSString *enumerateString = @"1, 2, 3", *createdString = nil;
  NSRange *matchedRanges = NULL, *firstRanges = NULL;
  RKEnumerator *regexEnumerator = NULL;
  
  STAssertTrueNoThrow((regexEnumerator = [enumerateString matchEnumeratorWithRegex:@"\\s*(\\d+),?"]) != NULL, nil);
  
  matchedRanges = (NSRange *)0xdeadbeef;
  STAssertTrueNoThrow((firstRanges = matchedRanges = [regexEnumerator nextRanges]) != NULL, nil);
  STAssertTrue(firstRanges == matchedRanges, nil);
  STAssertTrue(NSEqualRanges(matchedRanges[0], NSMakeRange(0, 2)), @"Range: %@", NSStringFromRange(matchedRanges[0]));
  STAssertTrue(NSEqualRanges(matchedRanges[1], NSMakeRange(0, 1)), @"Range: %@", NSStringFromRange(matchedRanges[1]));
  createdString = NULL;
  STAssertTrueNoThrow((createdString = [regexEnumerator stringWithReferenceString:@"Parsed $0"]) != NULL, nil);
  STAssertTrue([createdString isEqualToString:@"Parsed 1,"], @"createdString: %@", createdString);
  createdString = NULL;
  STAssertTrueNoThrow((createdString = [regexEnumerator stringWithReferenceString:@"Parsed $1"]) != NULL, nil);
  STAssertTrue([createdString isEqualToString:@"Parsed 1"], @"createdString: %@", createdString);
  createdString = NULL;
  STAssertTrueNoThrow((createdString = [regexEnumerator stringWithReferenceString:@"Parsed ${1}"]) != NULL, nil);
  STAssertTrue([createdString isEqualToString:@"Parsed 1"], @"createdString: %@", createdString);


  STAssertTrueNoThrow((matchedRanges = [regexEnumerator nextRanges]) != NULL, nil);
  STAssertTrue(firstRanges == matchedRanges, nil);
  STAssertTrue(NSEqualRanges(matchedRanges[0], NSMakeRange(2, 3)), @"Range: %@", NSStringFromRange(matchedRanges[0]));
  STAssertTrue(NSEqualRanges(matchedRanges[1], NSMakeRange(3, 1)), @"Range: %@", NSStringFromRange(matchedRanges[1]));
  createdString = NULL;
  STAssertTrueNoThrow((createdString = [regexEnumerator stringWithReferenceString:@"Parsed $0"]) != NULL, nil);
  STAssertTrue([createdString isEqualToString:@"Parsed  2,"], @"createdString: %@", createdString);
  createdString = NULL;
  STAssertTrueNoThrow((createdString = [regexEnumerator stringWithReferenceString:@"Parsed $1"]) != NULL, nil);
  STAssertTrue([createdString isEqualToString:@"Parsed 2"], @"createdString: %@", createdString);
  createdString = NULL;
  STAssertTrueNoThrow((createdString = [regexEnumerator stringWithReferenceString:@"Parsed ${1}"]) != NULL, nil);
  STAssertTrue([createdString isEqualToString:@"Parsed 2"], @"createdString: %@", createdString);
  

  STAssertTrueNoThrow((matchedRanges = [regexEnumerator nextRanges]) != NULL, nil);
  STAssertTrue(firstRanges == matchedRanges, nil);
  STAssertTrue(NSEqualRanges(matchedRanges[0], NSMakeRange(5, 2)), @"Range: %@", NSStringFromRange(matchedRanges[0]));
  STAssertTrue(NSEqualRanges(matchedRanges[1], NSMakeRange(6, 1)), @"Range: %@", NSStringFromRange(matchedRanges[1]));
  createdString = NULL;
  STAssertTrueNoThrow((createdString = [regexEnumerator stringWithReferenceString:@"Parsed $0"]) != NULL, nil);
  STAssertTrue([createdString isEqualToString:@"Parsed  3"], @"createdString: %@", createdString);
  createdString = NULL;
  STAssertTrueNoThrow((createdString = [regexEnumerator stringWithReferenceString:@"Parsed $1"]) != NULL, nil);
  STAssertTrue([createdString isEqualToString:@"Parsed 3"], @"createdString: %@", createdString);
  createdString = NULL;
  STAssertTrueNoThrow((createdString = [regexEnumerator stringWithReferenceString:@"Parsed ${1}"]) != NULL, nil);
  STAssertTrue([createdString isEqualToString:@"Parsed 3"], @"createdString: %@", createdString);
  
  STAssertTrueNoThrow((matchedRanges = [regexEnumerator nextRanges]) == NULL, nil);
  createdString = (NSString *)0xdeadbeef;
  STAssertTrueNoThrow((createdString = [regexEnumerator stringWithReferenceString:@"Parsed $0"]) == NULL, nil);
  createdString = (NSString *)0xdeadbeef;
  STAssertTrueNoThrow((createdString = [regexEnumerator stringWithReferenceString:@"Parsed $1"]) == NULL, nil);
  createdString = (NSString *)0xdeadbeef;
  STAssertTrueNoThrow((createdString = [regexEnumerator stringWithReferenceString:@"Parsed ${1}"]) == NULL, nil);
  




  STAssertTrueNoThrow((regexEnumerator = [enumerateString matchEnumeratorWithRegex:@"\\s*(?<theNumber>\\d+),?"]) != NULL, nil);
  
  matchedRanges = (NSRange *)0xdeadbeef;
  STAssertTrueNoThrow((firstRanges = matchedRanges = [regexEnumerator nextRanges]) != NULL, nil);
  STAssertTrue(firstRanges == matchedRanges, nil);
  STAssertTrue(NSEqualRanges(matchedRanges[0], NSMakeRange(0, 2)), @"Range: %@", NSStringFromRange(matchedRanges[0]));
  STAssertTrue(NSEqualRanges(matchedRanges[1], NSMakeRange(0, 1)), @"Range: %@", NSStringFromRange(matchedRanges[1]));
  createdString = NULL;
  STAssertTrueNoThrow((createdString = [regexEnumerator stringWithReferenceString:@"Parsed $0"]) != NULL, nil);
  STAssertTrue([createdString isEqualToString:@"Parsed 1,"], @"createdString: %@", createdString);
  createdString = NULL;
  STAssertTrueNoThrow((createdString = [regexEnumerator stringWithReferenceString:@"Parsed $1"]) != NULL, nil);
  STAssertTrue([createdString isEqualToString:@"Parsed 1"], @"createdString: %@", createdString);
  createdString = NULL;
  STAssertTrueNoThrow((createdString = [regexEnumerator stringWithReferenceString:@"Parsed ${1}"]) != NULL, nil);
  STAssertTrue([createdString isEqualToString:@"Parsed 1"], @"createdString: %@", createdString);
  createdString = NULL;
  STAssertTrueNoThrow((createdString = [regexEnumerator stringWithReferenceString:@"Parsed ${theNumber}"]) != NULL, nil);
  STAssertTrue([createdString isEqualToString:@"Parsed 1"], @"createdString: %@", createdString);
  
  
  STAssertTrueNoThrow((matchedRanges = [regexEnumerator nextRanges]) != NULL, nil);
  STAssertTrue(firstRanges == matchedRanges, nil);
  STAssertTrue(NSEqualRanges(matchedRanges[0], NSMakeRange(2, 3)), @"Range: %@", NSStringFromRange(matchedRanges[0]));
  STAssertTrue(NSEqualRanges(matchedRanges[1], NSMakeRange(3, 1)), @"Range: %@", NSStringFromRange(matchedRanges[1]));
  createdString = NULL;
  STAssertTrueNoThrow((createdString = [regexEnumerator stringWithReferenceString:@"Parsed $0"]) != NULL, nil);
  STAssertTrue([createdString isEqualToString:@"Parsed  2,"], @"createdString: %@", createdString);
  createdString = NULL;
  STAssertTrueNoThrow((createdString = [regexEnumerator stringWithReferenceString:@"Parsed $1"]) != NULL, nil);
  STAssertTrue([createdString isEqualToString:@"Parsed 2"], @"createdString: %@", createdString);
  createdString = NULL;
  STAssertTrueNoThrow((createdString = [regexEnumerator stringWithReferenceString:@"Parsed ${1}"]) != NULL, nil);
  STAssertTrue([createdString isEqualToString:@"Parsed 2"], @"createdString: %@", createdString);
  createdString = NULL;
  STAssertTrueNoThrow((createdString = [regexEnumerator stringWithReferenceString:@"Parsed ${theNumber}"]) != NULL, nil);
  STAssertTrue([createdString isEqualToString:@"Parsed 2"], @"createdString: %@", createdString);
  
  
  STAssertTrueNoThrow((matchedRanges = [regexEnumerator nextRanges]) != NULL, nil);
  STAssertTrue(firstRanges == matchedRanges, nil);
  STAssertTrue(NSEqualRanges(matchedRanges[0], NSMakeRange(5, 2)), @"Range: %@", NSStringFromRange(matchedRanges[0]));
  STAssertTrue(NSEqualRanges(matchedRanges[1], NSMakeRange(6, 1)), @"Range: %@", NSStringFromRange(matchedRanges[1]));
  createdString = NULL;
  STAssertTrueNoThrow((createdString = [regexEnumerator stringWithReferenceString:@"Parsed $0"]) != NULL, nil);
  STAssertTrue([createdString isEqualToString:@"Parsed  3"], @"createdString: %@", createdString);
  createdString = NULL;
  STAssertTrueNoThrow((createdString = [regexEnumerator stringWithReferenceString:@"Parsed $1"]) != NULL, nil);
  STAssertTrue([createdString isEqualToString:@"Parsed 3"], @"createdString: %@", createdString);
  createdString = NULL;
  STAssertTrueNoThrow((createdString = [regexEnumerator stringWithReferenceString:@"Parsed ${1}"]) != NULL, nil);
  STAssertTrue([createdString isEqualToString:@"Parsed 3"], @"createdString: %@", createdString);
  createdString = NULL;
  STAssertTrueNoThrow((createdString = [regexEnumerator stringWithReferenceString:@"Parsed ${theNumber}"]) != NULL, nil);
  STAssertTrue([createdString isEqualToString:@"Parsed 3"], @"createdString: %@", createdString);
  
  STAssertTrueNoThrow((matchedRanges = [regexEnumerator nextRanges]) == NULL, nil);
  createdString = (NSString *)0xdeadbeef;
  STAssertTrueNoThrow((createdString = [regexEnumerator stringWithReferenceString:@"Parsed $0"]) == NULL, nil);
  createdString = (NSString *)0xdeadbeef;
  STAssertTrueNoThrow((createdString = [regexEnumerator stringWithReferenceString:@"Parsed $1"]) == NULL, nil);
  createdString = (NSString *)0xdeadbeef;
  STAssertTrueNoThrow((createdString = [regexEnumerator stringWithReferenceString:@"Parsed ${1}"]) == NULL, nil);
  createdString = (NSString *)0xdeadbeef;
  STAssertTrueNoThrow((createdString = [regexEnumerator stringWithReferenceString:@"Parsed ${theNumber}"]) == NULL, nil);




  STAssertTrueNoThrow((regexEnumerator = [enumerateString matchEnumeratorWithRegex:@"\\s*(?<theNumber>\\d+),?"]) != NULL, nil);
  
  matchedRanges = (NSRange *)0xdeadbeef;
  STAssertTrueNoThrow((firstRanges = matchedRanges = [regexEnumerator nextRanges]) != NULL, nil);
  STAssertTrue(firstRanges == matchedRanges, nil);
  STAssertTrue(NSEqualRanges(matchedRanges[0], NSMakeRange(0, 2)), @"Range: %@", NSStringFromRange(matchedRanges[0]));
  STAssertTrue(NSEqualRanges(matchedRanges[1], NSMakeRange(0, 1)), @"Range: %@", NSStringFromRange(matchedRanges[1]));
  createdString = NULL;
  STAssertTrueNoThrow((createdString = [regexEnumerator stringWithReferenceString:@"Parsed $0"]) != NULL, nil);
  STAssertTrue([createdString isEqualToString:@"Parsed 1,"], @"createdString: %@", createdString);
  createdString = (NSString *)0xdeadbeef;
  STAssertThrowsSpecificNamed(createdString = [regexEnumerator stringWithReferenceString:NULL], NSException, NSInvalidArgumentException, nil);
  STAssertTrue(createdString == (NSString *)0xdeadbeef, nil);
  createdString = NULL;
  STAssertTrueNoThrow((createdString = [regexEnumerator stringWithReferenceString:@"Parsed $1"]) != NULL, nil);
  STAssertTrue([createdString isEqualToString:@"Parsed 1"], @"createdString: %@", createdString);
  createdString = NULL;
  STAssertTrueNoThrow((createdString = [regexEnumerator stringWithReferenceString:@"Parsed ${1}"]) != NULL, nil);
  STAssertTrue([createdString isEqualToString:@"Parsed 1"], @"createdString: %@", createdString);
  createdString = NULL;
  STAssertTrueNoThrow((createdString = [regexEnumerator stringWithReferenceString:@"Parsed ${theNumber}"]) != NULL, nil);
  STAssertTrue([createdString isEqualToString:@"Parsed 1"], @"createdString: %@", createdString);
  
  
  STAssertTrueNoThrow((matchedRanges = [regexEnumerator nextRanges]) != NULL, nil);
  STAssertTrue(firstRanges == matchedRanges, nil);
  STAssertTrue(NSEqualRanges(matchedRanges[0], NSMakeRange(2, 3)), @"Range: %@", NSStringFromRange(matchedRanges[0]));
  STAssertTrue(NSEqualRanges(matchedRanges[1], NSMakeRange(3, 1)), @"Range: %@", NSStringFromRange(matchedRanges[1]));
  createdString = NULL;
  STAssertTrueNoThrow((createdString = [regexEnumerator stringWithReferenceString:@"Parsed $0"]) != NULL, nil);
  STAssertTrue([createdString isEqualToString:@"Parsed  2,"], @"createdString: %@", createdString);
  createdString = (NSString *)0xdeadbeef;
  STAssertThrowsSpecificNamed(createdString = [regexEnumerator stringWithReferenceString:NULL], NSException, NSInvalidArgumentException, nil);
  STAssertTrue(createdString == (NSString *)0xdeadbeef, nil);
  createdString = NULL;
  STAssertTrueNoThrow((createdString = [regexEnumerator stringWithReferenceString:@"Parsed $1"]) != NULL, nil);
  STAssertTrue([createdString isEqualToString:@"Parsed 2"], @"createdString: %@", createdString);
  createdString = NULL;
  STAssertTrueNoThrow((createdString = [regexEnumerator stringWithReferenceString:@"Parsed ${1}"]) != NULL, nil);
  STAssertTrue([createdString isEqualToString:@"Parsed 2"], @"createdString: %@", createdString);
  createdString = NULL;
  STAssertTrueNoThrow((createdString = [regexEnumerator stringWithReferenceString:@"Parsed ${theNumber}"]) != NULL, nil);
  STAssertTrue([createdString isEqualToString:@"Parsed 2"], @"createdString: %@", createdString);
  
  
  STAssertTrueNoThrow((matchedRanges = [regexEnumerator nextRanges]) != NULL, nil);
  STAssertTrue(firstRanges == matchedRanges, nil);
  STAssertTrue(NSEqualRanges(matchedRanges[0], NSMakeRange(5, 2)), @"Range: %@", NSStringFromRange(matchedRanges[0]));
  STAssertTrue(NSEqualRanges(matchedRanges[1], NSMakeRange(6, 1)), @"Range: %@", NSStringFromRange(matchedRanges[1]));
  createdString = NULL;
  STAssertTrueNoThrow((createdString = [regexEnumerator stringWithReferenceString:@"Parsed $0"]) != NULL, nil);
  STAssertTrue([createdString isEqualToString:@"Parsed  3"], @"createdString: %@", createdString);
  createdString = NULL;
  STAssertTrueNoThrow((createdString = [regexEnumerator stringWithReferenceString:@"Parsed $1"]) != NULL, nil);
  STAssertTrue([createdString isEqualToString:@"Parsed 3"], @"createdString: %@", createdString);
  createdString = NULL;
  STAssertTrueNoThrow((createdString = [regexEnumerator stringWithReferenceString:@"Parsed ${1}"]) != NULL, nil);
  STAssertTrue([createdString isEqualToString:@"Parsed 3"], @"createdString: %@", createdString);
  createdString = (NSString *)0xdeadbeef;
  STAssertThrowsSpecificNamed(createdString = [regexEnumerator stringWithReferenceString:NULL], NSException, NSInvalidArgumentException, nil);
  STAssertTrue(createdString == (NSString *)0xdeadbeef, nil);
  createdString = NULL;
  STAssertTrueNoThrow((createdString = [regexEnumerator stringWithReferenceString:@"Parsed ${theNumber}"]) != NULL, nil);
  STAssertTrue([createdString isEqualToString:@"Parsed 3"], @"createdString: %@", createdString);
  
  STAssertTrueNoThrow((matchedRanges = [regexEnumerator nextRanges]) == NULL, nil);
  createdString = (NSString *)0xdeadbeef;
  STAssertTrueNoThrow((createdString = [regexEnumerator stringWithReferenceString:@"Parsed $0"]) == NULL, nil);
  createdString = (NSString *)0xdeadbeef;
  STAssertThrowsSpecificNamed(createdString = [regexEnumerator stringWithReferenceString:NULL], NSException, NSInvalidArgumentException, nil);
  STAssertTrue(createdString == (NSString *)0xdeadbeef, nil);
  createdString = (NSString *)0xdeadbeef;
  STAssertTrueNoThrow((createdString = [regexEnumerator stringWithReferenceString:@"Parsed $1"]) == NULL, nil);
  createdString = (NSString *)0xdeadbeef;
  STAssertTrueNoThrow((createdString = [regexEnumerator stringWithReferenceString:@"Parsed ${1}"]) == NULL, nil);
  createdString = (NSString *)0xdeadbeef;
  STAssertTrueNoThrow((createdString = [regexEnumerator stringWithReferenceString:@"Parsed ${theNumber}"]) == NULL, nil);




  va_list argList;

  STAssertTrueNoThrow((regexEnumerator = [enumerateString matchEnumeratorWithRegex:@"\\s*(?<theNumber>\\d+),?"]) != NULL, nil);
  
  matchedRanges = (NSRange *)0xdeadbeef;
  STAssertTrueNoThrow((firstRanges = matchedRanges = [regexEnumerator nextRanges]) != NULL, nil);
  STAssertTrue(firstRanges == matchedRanges, nil);
  STAssertTrue(NSEqualRanges(matchedRanges[0], NSMakeRange(0, 2)), @"Range: %@", NSStringFromRange(matchedRanges[0]));
  STAssertTrue(NSEqualRanges(matchedRanges[1], NSMakeRange(0, 1)), @"Range: %@", NSStringFromRange(matchedRanges[1]));
  createdString = NULL;
  STAssertTrueNoThrow((createdString = [regexEnumerator stringWithReferenceFormat:@"Parsed $0"]) != NULL, nil);
  STAssertTrue([createdString isEqualToString:@"Parsed 1,"], @"createdString: %@", createdString);
  createdString = (NSString *)0xdeadbeef;
  STAssertThrowsSpecificNamed(createdString = [regexEnumerator stringWithReferenceString:NULL], NSException, NSInvalidArgumentException, nil);
  STAssertTrue(createdString == (NSString *)0xdeadbeef, nil);
  createdString = NULL;
  STAssertTrueNoThrow((createdString = [regexEnumerator stringWithReferenceFormat:@"Parsed $1 %d", 5]) != NULL, nil);
  STAssertTrue([createdString isEqualToString:@"Parsed 1 5"], @"createdString: %@", createdString);
  createdString = NULL;
  STAssertTrueNoThrow((createdString = [regexEnumerator stringWithReferenceFormat:@"Parsed %s${1}", "??"]) != NULL, nil);
  STAssertTrue([createdString isEqualToString:@"Parsed ??1"], @"createdString: %@", createdString);
  createdString = NULL;
  STAssertTrueNoThrow((createdString = [regexEnumerator stringWithReferenceFormat:@"Parsed ${theNumber}"]) != NULL, nil);
  STAssertTrue([createdString isEqualToString:@"Parsed 1"], @"createdString: %@", createdString);
  
  
  STAssertTrueNoThrow((matchedRanges = [regexEnumerator nextRanges]) != NULL, nil);
  STAssertTrue(firstRanges == matchedRanges, nil);
  STAssertTrue(NSEqualRanges(matchedRanges[0], NSMakeRange(2, 3)), @"Range: %@", NSStringFromRange(matchedRanges[0]));
  STAssertTrue(NSEqualRanges(matchedRanges[1], NSMakeRange(3, 1)), @"Range: %@", NSStringFromRange(matchedRanges[1]));
  createdString = NULL;
  STAssertTrueNoThrow((createdString = [regexEnumerator stringWithReferenceFormat:@"Parsed $0"]) != NULL, nil);
  STAssertTrue([createdString isEqualToString:@"Parsed  2,"], @"createdString: %@", createdString);
  createdString = (NSString *)0xdeadbeef;
  STAssertThrowsSpecificNamed(createdString = [regexEnumerator stringWithReferenceFormat:NULL arguments:argList], NSException, NSInvalidArgumentException, nil);
  STAssertTrue(createdString == (NSString *)0xdeadbeef, nil);
  createdString = NULL;
  STAssertTrueNoThrow((createdString = [regexEnumerator stringWithReferenceFormat:@"Parsed $1" arguments:argList]) != NULL, nil);
  STAssertTrue([createdString isEqualToString:@"Parsed 2"], @"createdString: %@", createdString);
  createdString = NULL;
  STAssertTrueNoThrow((createdString = [regexEnumerator stringWithReferenceFormat:@"Parsed ${1}"]) != NULL, nil);
  STAssertTrue([createdString isEqualToString:@"Parsed 2"], @"createdString: %@", createdString);
  createdString = NULL;
  STAssertTrueNoThrow((createdString = [regexEnumerator stringWithReferenceFormat:@"Parsed ${theNumber}"]) != NULL, nil);
  STAssertTrue([createdString isEqualToString:@"Parsed 2"], @"createdString: %@", createdString);
  
  
  STAssertTrueNoThrow((matchedRanges = [regexEnumerator nextRanges]) != NULL, nil);
  STAssertTrue(firstRanges == matchedRanges, nil);
  STAssertTrue(NSEqualRanges(matchedRanges[0], NSMakeRange(5, 2)), @"Range: %@", NSStringFromRange(matchedRanges[0]));
  STAssertTrue(NSEqualRanges(matchedRanges[1], NSMakeRange(6, 1)), @"Range: %@", NSStringFromRange(matchedRanges[1]));
  createdString = NULL;
  STAssertTrueNoThrow((createdString = [regexEnumerator stringWithReferenceFormat:@"Parsed $0"]) != NULL, nil);
  STAssertTrue([createdString isEqualToString:@"Parsed  3"], @"createdString: %@", createdString);
  createdString = NULL;
  STAssertTrueNoThrow((createdString = [regexEnumerator stringWithReferenceFormat:@"Parsed $1"]) != NULL, nil);
  STAssertTrue([createdString isEqualToString:@"Parsed 3"], @"createdString: %@", createdString);
  createdString = NULL;
  STAssertTrueNoThrow((createdString = [regexEnumerator stringWithReferenceFormat:@"Parsed ${1}"]) != NULL, nil);
  STAssertTrue([createdString isEqualToString:@"Parsed 3"], @"createdString: %@", createdString);
  createdString = (NSString *)0xdeadbeef;
  STAssertThrowsSpecificNamed(createdString = [regexEnumerator stringWithReferenceFormat:NULL], NSException, NSInvalidArgumentException, nil);
  STAssertTrue(createdString == (NSString *)0xdeadbeef, nil);
  createdString = NULL;
  STAssertTrueNoThrow((createdString = [regexEnumerator stringWithReferenceFormat:@"Parsed ${theNumber}"]) != NULL, nil);
  STAssertTrue([createdString isEqualToString:@"Parsed 3"], @"createdString: %@", createdString);
  
  STAssertTrueNoThrow((matchedRanges = [regexEnumerator nextRanges]) == NULL, nil);
  createdString = (NSString *)0xdeadbeef;
  STAssertTrueNoThrow((createdString = [regexEnumerator stringWithReferenceFormat:@"Parsed $0"]) == NULL, nil);
  createdString = (NSString *)0xdeadbeef;
  STAssertThrowsSpecificNamed(createdString = [regexEnumerator stringWithReferenceFormat:NULL], NSException, NSInvalidArgumentException, nil);
  STAssertTrue(createdString == (NSString *)0xdeadbeef, nil);
  createdString = (NSString *)0xdeadbeef;
  STAssertThrowsSpecificNamed(createdString = [regexEnumerator stringWithReferenceFormat:NULL arguments:argList], NSException, NSInvalidArgumentException, nil);
  STAssertTrue(createdString == (NSString *)0xdeadbeef, nil);
  createdString = (NSString *)0xdeadbeef;
  STAssertTrueNoThrow((createdString = [regexEnumerator stringWithReferenceFormat:@"Parsed $1"]) == NULL, nil);
  createdString = (NSString *)0xdeadbeef;
  STAssertTrueNoThrow((createdString = [regexEnumerator stringWithReferenceFormat:@"Parsed ${1}"]) == NULL, nil);
  createdString = (NSString *)0xdeadbeef;
  STAssertTrueNoThrow((createdString = [regexEnumerator stringWithReferenceFormat:@"Parsed ${theNumber}"]) == NULL, nil);
  
}
  
@end
