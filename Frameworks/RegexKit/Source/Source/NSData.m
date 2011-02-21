//
//  NSData.m
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

#import <RegexKit/NSData.h>
#import <RegexKit/RegexKitPrivate.h>

@implementation NSData (RegexKitAdditions)

//
// isMatchedByRegex: methods
//

- (BOOL)isMatchedByRegex:(id)aRegex
{
  RKUInteger dataLength = [self length];
  return([RKRegexFromStringOrRegex(self, _cmd, aRegex, RKCompileNoOptions, YES) matchesCharacters:[self bytes] length:dataLength inRange:NSMakeRange(0, dataLength) options:RKMatchNoOptions]);
}

- (BOOL)isMatchedByRegex:(id)aRegex inRange:(const NSRange)range
{
  return([RKRegexFromStringOrRegex(self, _cmd, aRegex, RKCompileNoOptions, YES) matchesCharacters:[self bytes] length:[self length] inRange:range options:RKMatchNoOptions]);
}

//
// rangeOfRegex: methods
//

- (NSRange)rangeOfRegex:(id)aRegex
{
  RKUInteger dataLength = [self length];
  return([RKRegexFromStringOrRegex(self, _cmd, aRegex, RKCompileNoOptions, YES) rangeForCharacters:[self bytes] length:dataLength inRange:NSMakeRange(0, dataLength) captureIndex:0 options:RKMatchNoOptions]);
}

- (NSRange)rangeOfRegex:(id)aRegex inRange:(const NSRange)range capture:(const RKUInteger)capture
{
  return([RKRegexFromStringOrRegex(self, _cmd, aRegex, RKCompileNoOptions, YES) rangeForCharacters:[self bytes] length:[self length] inRange:range captureIndex:capture options:RKMatchNoOptions]);
}

//
// rangesOfRegex: methods
//

- (NSRange *)rangesOfRegex:(id)aRegex
{
  RKUInteger dataLength = [self length];
  return([RKRegexFromStringOrRegex(self, _cmd, aRegex, RKCompileNoOptions, YES) rangesForCharacters:[self bytes] length:dataLength inRange:NSMakeRange(0, dataLength) options:RKMatchNoOptions]);
}

- (NSRange *)rangesOfRegex:(id)aRegex inRange:(const NSRange)range
{
  return([RKRegexFromStringOrRegex(self, _cmd, aRegex, RKCompileNoOptions, YES) rangesForCharacters:[self bytes] length:[self length] inRange:range options:RKMatchNoOptions]);
}

//
// subdataByMatching: methods
//

- (NSData *)subdataByMatching:(id)aRegex
{
  RKUInteger dataLength = [self length];
  NSRange subdataRange = [RKRegexFromStringOrRegex(self, _cmd, aRegex, RKCompileNoOptions, YES) rangeForCharacters:[self bytes] length:dataLength inRange:NSMakeRange(0, dataLength) captureIndex:0 options:RKMatchNoOptions];
  return(NSEqualRanges(NSMakeRange(NSNotFound, 0), subdataRange) ? (NSData *)[NSData data] : [self subdataWithRange:subdataRange]);
}

- (NSData *)subdataByMatching:(id)aRegex inRange:(const NSRange)range
{
  NSRange subdataRange = [RKRegexFromStringOrRegex(self, _cmd, aRegex, RKCompileNoOptions, YES) rangeForCharacters:[self bytes] length:[self length] inRange:range captureIndex:0 options:RKMatchNoOptions];
  return(NSEqualRanges(NSMakeRange(NSNotFound, 0), subdataRange) ? (NSData *)[NSData data] : [self subdataWithRange:subdataRange]);
}

@end
