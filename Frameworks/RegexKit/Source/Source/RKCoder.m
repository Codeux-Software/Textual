//
//  RKCoder.m
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

#import <RegexKit/RKCoder.h>

NSDictionary *RKRegexCoderDifferencesDictionary(id self RK_ATTRIBUTES(unused), const SEL _cmd RK_ATTRIBUTES(unused), NSCoder * const coder, id codedRegexString RK_ATTRIBUTES(unused), const RKCompileOption codedCompileOption) {
  // This may seem like an overkill, but I figure that encoded objects have a long shelf life.  A lot of time can pass between creation and reconstitution.
  // Therefore, this has the distinct possibility that "it used to work, 6 months ago" is going to happen because something changed.
  // If we do fail, this notes any differences that might have contributed to the failure, such as a new PCRE version or using a new option in a future PCRE build.
  // I've personally been caught by UTF8 build differences, which isn't terribly obvious what the cause of the problem is.  This would highlight it instantly.
  
  NSMutableArray  *extraInfoArray = [NSMutableArray array];  // addObject: strings of extra info
  NSString *codedVersionString = [coder decodeObjectForKey:@"PCREVersionString"];
  RKBuildConfig codedBuildConfig = [coder decodeInt32ForKey:@"PCREBuildConfig"];
  
  if([[RKRegex PCREVersionString] isEqualToString:codedVersionString] == NO) { [extraInfoArray addObject:RKLocalizedFormat(@"Encoded PCRE version   : %@, current version %@", codedVersionString, [RKRegex PCREVersionString])]; }
  
  // Mask off known valid bits and check if any remain
  RKCompileOption unknownCompileOption = (codedCompileOption & (~(RKCompileAllOptions | RKCompileNewlineMask)));
  if(unknownCompileOption != 0) {
    [extraInfoArray addObject:RKLocalizedFormat(@"Decoded compile options: 0x%8.8x (%@)", (unsigned int)codedCompileOption, [RKArrayFromCompileOption(codedCompileOption) componentsJoinedByString:@" | "])];
    [extraInfoArray addObject:RKLocalizedFormat(@"Unknown option bits    : 0x%8.8x", (unsigned int)unknownCompileOption)];
  }
  
  // Check for valid newline type
  RKCompileOption codedCompileNewlineOption = (codedCompileOption & RKCompileNewlineMask);
  if((codedCompileNewlineOption != RKCompileNewlineCR)   && (codedCompileNewlineOption != RKCompileNewlineLF)  &&
     (codedCompileNewlineOption != RKCompileNewlineCRLF) && 
#if PCRE_MAJOR >= 7 && PCRE_MINOR >= 1
     (codedCompileNewlineOption != RKCompileNewlineAnyCRLF) &&
#endif
     (codedCompileNewlineOption != RKCompileNewlineAny)  && (codedCompileNewlineOption != RKCompileNewlineDefault)) {
    [extraInfoArray addObject:RKLocalizedFormat(@"Unknown Newline type   : 0x%8.8x. Valid types: %@", (unsigned int)codedCompileNewlineOption, [RKArrayOfPrettyNewlineTypes(@"RKCompile") componentsJoinedByString:@", "])];
  }
  
  // Calculate a bit difference of RKBuildConfig options
  RKBuildConfig differenceBuildConfig = ((codedBuildConfig & ~RKBuildConfigNewlineMask) ^ ([RKRegex PCREBuildConfig] & ~RKBuildConfigNewlineMask));
  differenceBuildConfig |= ((codedBuildConfig & RKBuildConfigNewlineMask) != ([RKRegex PCREBuildConfig] & RKBuildConfigNewlineMask)) ? (codedBuildConfig & RKBuildConfigNewlineMask) : 0;
  
  if(differenceBuildConfig != 0) {
    [extraInfoArray addObject:RKLocalizedFormat(@"Encoded build config   : 0x%8.8x (%@)", (unsigned int)codedBuildConfig, [RKArrayFromBuildConfig(codedBuildConfig) componentsJoinedByString:@" | "])];
    [extraInfoArray addObject:RKLocalizedFormat(@"Current build config   : 0x%8.8x (%@)", (unsigned int)[RKRegex PCREBuildConfig], [RKArrayFromBuildConfig([RKRegex PCREBuildConfig]) componentsJoinedByString:@" | "])];
    [extraInfoArray addObject:RKLocalizedFormat(@"Difference in builds   : 0x%8.8x (%@)", (unsigned int)differenceBuildConfig, [RKArrayFromBuildConfig(differenceBuildConfig) componentsJoinedByString:@" | "])];
  }
  
  NSMutableString *extraInfoString = [NSMutableString string]; // In case there is no extra info created, this can be safely printed with no visible effect
  if([extraInfoArray count] != 0) { extraInfoString = RKLocalizedFormat(@"\nAdditional information: %@\n", [extraInfoArray componentsJoinedByString:RKLocalizedString(@"\n                        ")]); }
  
  return([NSDictionary dictionaryWithObjectsAndKeys:extraInfoArray, @"extraInfoArray", extraInfoString, @"extraInfoString", NULL]);
}

id RKRegexInitWithCoder(id self, const SEL _cmd RK_ATTRIBUTES(unused), NSCoder * const coder) {
  id codedRegexString = [coder decodeObjectForKey:@"RKRegexString"];
  RKCompileOption codedCompileOption = [coder decodeInt32ForKey:@"RKCompileOption"];
  id decodedRegex = NULL;
  
  // Here we catch any regex instantiation exceptions and add extra info from RKRegexCoderDifferencesDictionary(), if any.
  
#ifdef USE_MACRO_EXCEPTIONS
  
  NS_DURING
    decodedRegex = [self initWithRegexString:codedRegexString options:codedCompileOption];
  NS_HANDLER
    NSDictionary *extraInfoDictionary = RKRegexCoderDifferencesDictionary(self, _cmd, coder, codedRegexString, codedCompileOption);
    [[NSException rkException:NSInvalidUnarchiveOperationException userInfo:[NSDictionary dictionaryWithObject:localException forKey:@"exception"] localizeReason:@"Exception during initialization:\n%@%@", [localException reason], [extraInfoDictionary objectForKey:@"extraInfoString"]] raise];
  NS_ENDHANDLER
  
#else // not macro exceptions, compiler -fobjc-exceptions
  
 @try { decodedRegex = [self initWithRegexString:codedRegexString options:codedCompileOption]; }
 @catch (NSException *localException) {
    NSDictionary *extraInfoDictionary = RKRegexCoderDifferencesDictionary(self, _cmd, coder, codedRegexString, codedCompileOption);
    [[NSException rkException:NSInvalidUnarchiveOperationException userInfo:[NSDictionary dictionaryWithObject:localException forKey:@"exception"] localizeReason:@"Exception during initialization:\n%@%@", [localException reason], [extraInfoDictionary objectForKey:@"extraInfoString"]] raise];
  }
  
#endif //USE_MACRO_EXCEPTIONS
  
  if(decodedRegex == NULL) { [[NSException rkException:NSInvalidUnarchiveOperationException userInfo:[NSDictionary dictionaryWithObjectsAndKeys:(codedRegexString == NULL) ? (id)[NSNull null]:codedRegexString, @"regexString", [NSNumber numberWithInt:codedCompileOption], @"compileOption", NULL] localizeReason:@"Failed to recreate regular expression."] raise]; }
  
  return(decodedRegex);
}

void RKRegexEncodeWithCoder(id self, const SEL _cmd RK_ATTRIBUTES(unused), NSCoder * const coder) {
  [coder encodeObject:[self regexString] forKey:@"RKRegexString"];
  [coder encodeInt32:[self compileOption] forKey:@"RKCompileOption"];
  [coder encodeObject:[[self class] PCREVersionString] forKey:@"PCREVersionString"];
  [coder encodeInt32:[[self class] PCREMajorVersion] forKey:@"PCREMajorVersion"];
  [coder encodeInt32:[[self class] PCREMinorVersion] forKey:@"PCREMinorVersion"];
  [coder encodeInt32:[[self class] PCREBuildConfig] forKey:@"PCREBuildConfig"];
}
