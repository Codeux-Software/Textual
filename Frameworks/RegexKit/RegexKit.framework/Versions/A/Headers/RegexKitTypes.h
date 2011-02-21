//
//  RegexKitTypes.h
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

#ifdef __cplusplus
extern "C" {
#endif
  
#ifndef _REGEXKIT_REGEXKITTYPES_H_
#define _REGEXKIT_REGEXKITTYPES_H_ 1

@class NSString;

// Defined in RKRegex.m  Constants added here MUST be included in 'exports_list' to be visible!
extern NSString * const RKRegexSyntaxErrorException;
extern NSString * const RKRegexUnsupportedException;
extern NSString * const RKRegexCaptureReferenceException;
extern NSString * const RKRegexPCRELibrary;
extern NSString * const RKRegexPCRELibraryErrorDomain;
extern NSString * const RKRegexErrorDomain;
extern NSString * const RKRegexLibraryErrorKey;
extern NSString * const RKRegexLibraryErrorStringErrorKey;
extern NSString * const RKRegexStringErrorKey;
extern NSString * const RKRegexStringErrorRangeErrorKey;
extern NSString * const RKAttributedRegexStringErrorKey;
extern NSString * const RKAbreviatedRegexStringErrorKey;
extern NSString * const RKAbreviatedRegexStringErrorRangeErrorKey;
extern NSString * const RKAbreviatedAttributedRegexStringErrorKey;
extern NSString * const RKCompileOptionErrorKey;
extern NSString * const RKCompileOptionArrayErrorKey;
extern NSString * const RKCompileOptionArrayStringErrorKey;
extern NSString * const RKCompileErrorCodeErrorKey;
extern NSString * const RKCompileErrorCodeStringErrorKey;
extern NSString * const RKArrayIndexErrorKey;
extern NSString * const RKObjectErrorKey;
extern NSString * const RKCollectionErrorKey;

typedef enum {
  RKMatchErrorNoError                   = 0,
  RKMatchErrorNoMatch                   = -1,
  RKMatchErrorNull                      = -2,
  RKMatchErrorBadOption                 = -3,
  RKMatchErrorBadMagic                  = -4,
  RKMatchErrorUnknownOpcode             = -5,
  RKMatchErrorNoMemory                  = -6,
  RKMatchErrorNoSubstring               = -7,
  RKMatchErrorMatchLimit                = -8,
  RKMatchErrorCallout                   = -9, 
  RKMatchErrorBadUTF8                   = -10,
  RKMatchErrorBadUTF8Offset             = -11,
  RKMatchErrorPartial                   = -12,
  RKMatchErrorBadPartial                = -13,
  RKMatchErrorInternal                  = -14,
  RKMatchErrorBadCount                  = -15,
  RKMatchErrorRecursionLimit            = -21,
  RKMatchErrorNullWorkSpaceLimit        = -22,
  RKMatchErrorBadNewline                = -23
} RKMatchErrorCode;

typedef enum {
  RKCompileErrorNoError = 0,
  RKCompileErrorEscapeAtEndOfPattern = 1,
  RKCompileErrorByteEscapeAtEndOfPattern = 2,
  RKCompileErrorUnrecognizedCharacterFollowingEscape = 3,
  RKCompileErrorNumbersOutOfOrder = 4,
  RKCompileErrorNumbersToBig = 5,
  RKCompileErrorMissingTerminatorForCharacterClass = 6,
  RKCompileErrorInvalidEscapeInCharacterClass = 7,
  RKCompileErrorRangeOutOfOrderInCharacterClass = 8,
  RKCompileErrorNothingToRepeat = 9,
  RKCompileErrorInternalErrorUnexpectedRepeat = 11,
  RKCompileErrorUnrecognizedCharacterAfterOption = 12,
  RKCompileErrorPOSIXNamedClassOutsideOfClass = 13,
  RKCompileErrorMissingParentheses = 14,
  RKCompileErrorReferenceToNonExistentSubpattern = 15,
  RKCompileErrorErrorOffsetPassedAsNull = 16,
  RKCompileErrorUnknownOptionBits = 17,
  RKCompileErrorMissingParenthesesAfterComment = 18,
  RKCompileErrorRegexTooLarge = 20,
  RKCompileErrorNoMemory = 21,
  RKCompileErrorUnmatchedParentheses = 22,
  RKCompileErrorInternalCodeOverflow = 23,
  RKCompileErrorUnrecognizedCharacterAfterNamedSubppatern = 24,
  RKCompileErrorLookbehindAssertionNotFixedLength = 25,
  RKCompileErrorMalformedNameOrNumberAfterSubpattern = 26,
  RKCompileErrorConditionalGroupContainsMoreThanTwoBranches = 27,
  RKCompileErrorAssertionExpectedAfterCondition = 28,
  RKCompileErrorMissingEndParentheses = 29,
  RKCompileErrorUnknownPOSIXClassName = 30,
  RKCompileErrorPOSIXCollatingNotSupported = 31,
  RKCompileErrorMissingUTF8Support = 32,
  RKCompileErrorHexCharacterValueTooLarge = 34,
  RKCompileErrorInvalidCondition = 35,
  RKCompileErrorNotAllowedInLookbehindAssertion = 36,
  RKCompileErrorNotSupported = 37,
  RKCompileErrorCalloutExceedsMaximumAllowed = 38,
  RKCompileErrorMissingParenthesesAfterCallout = 39,
  RKCompileErrorRecursiveInfinitLoop = 40,
  RKCompileErrorUnrecognizedCharacterAfterNamedPattern = 41,
  RKCompileErrorSubpatternNameMissingTerminator = 42,
  RKCompileErrorDuplicateSubpatternNames = 43,
  RKCompileErrorInvalidUTF8String = 44,
  RKCompileErrorMissingUnicodeSupport = 45,
  RKCompileErrorMalformedUnicodeProperty = 46,
  RKCompileErrorUnknownPropertyAfterUnicodeCharacter = 47,
  RKCompileErrorSubpatternNameTooLong = 48,
  RKCompileErrorTooManySubpatterns = 49,
  RKCompileErrorRepeatedSubpatternTooLong = 50,
  RKCompileErrorIllegalOctalValueOutsideUTF8 = 51,
  RKCompileErrorInternalOverranCompilingWorkspace = 52,
  RKCompileErrorInternalReferencedSubpatternNotFound = 53,
  RKCompileErrorDEFINEGroupContainsMoreThanOneBranch = 54,
  RKCompileErrorRepeatingDEFINEGroupNotAllowed = 55,
  RKCompileErrorInconsistentNewlineOptions = 56,
  RKCompileErrorReferenceMustBeNonZeroNumberOrBraced = 57,
  RKCompileErrorRelativeSubpatternNumberMustNotBeZero = 58
} RKCompileErrorCode;


typedef enum {
  RKMatchNoOptions           = 0,
  RKMatchAnchored            = 1 << 4,
  RKMatchNotBeginningOfLine  = 1 << 7,
  RKMatchNotEndOfLine        = 1 << 8,
  RKMatchNotEmpty            = 1 << 10,
  RKMatchNoUTF8Check         = 1 << 13,
  RKMatchPartial             = 1 << 15,
  RKMatchNewlineDefault      = 0x00000000,
  RKMatchNewlineCR           = 0x00100000,
  RKMatchNewlineLF           = 0x00200000,
  RKMatchNewlineCRLF         = 0x00300000,
  RKMatchNewlineAny          = 0x00400000,
  RKMatchNewlineAnyCRLF      = 0x00500000,
  RKMatchNewlineMask         = 0x00700000,
  RKMatchBackslashRAnyCRLR   = 1 << 23,
  RKMatchBackslashRUnicode   = 1 << 24
} RKMatchOption;

typedef enum {
  RKCompileNoOptions           = 0,
  RKCompileCaseless            = 1 << 0,
  RKCompileMultiline           = 1 << 1,
  RKCompileDotAll              = 1 << 2,
  RKCompileExtended            = 1 << 3,
  RKCompileAnchored            = 1 << 4,
  RKCompileDollarEndOnly       = 1 << 5,
  RKCompileExtra               = 1 << 6,
  RKCompileUngreedy            = 1 << 9,
  RKCompileUTF8                = 1 << 11,
  RKCompileNoAutoCapture       = 1 << 12,
  RKCompileNoUTF8Check         = 1 << 13,
  RKCompileAutoCallout         = 1 << 14,
  RKCompileFirstLine           = 1 << 18,
  RKCompileDupNames            = 1 << 19,
  RKCompileBackslashRAnyCRLR   = 1 << 23,
  RKCompileBackslashRUnicode   = 1 << 24,
  RKCompileAllOptions          = (RKCompileCaseless          | RKCompileMultiline   | RKCompileDotAll    | RKCompileExtended | RKCompileAnchored          | 
                                  RKCompileDollarEndOnly     | RKCompileExtra       | RKCompileUngreedy  | RKCompileUTF8     | RKCompileNoAutoCapture     | 
                                  RKCompileNoUTF8Check       | RKCompileAutoCallout | RKCompileFirstLine | RKCompileDupNames | RKCompileBackslashRAnyCRLR |
                                  RKCompileBackslashRUnicode
                                  ),
  RKCompileUnsupported         = (RKCompileAutoCallout),
  RKCompileNewlineDefault      = 0x00000000,
  RKCompileNewlineCR           = 0x00100000,
  RKCompileNewlineLF           = 0x00200000,
  RKCompileNewlineCRLF         = 0x00300000,
  RKCompileNewlineAny          = 0x00400000,
  RKCompileNewlineAnyCRLF      = 0x00500000,
  RKCompileNewlineMask         = 0x00700000,
  RKCompileNewlineShift        = 20
} RKCompileOption;

typedef enum {
  RKBuildConfigNoOptions         = 0,
  RKBuildConfigUTF8              = 1 << 0,
  RKBuildConfigUnicodeProperties = 1 << 1,
  RKBuildConfigNewlineDefault    = 0x00000000,
  RKBuildConfigNewlineCR         = 0x00100000,
  RKBuildConfigNewlineLF         = 0x00200000,
  RKBuildConfigNewlineCRLF       = 0x00300000,
  RKBuildConfigNewlineAny        = 0x00400000,
  RKBuildConfigNewlineAnyCRLF    = 0x00500000, 
  RKBuildConfigNewlineMask       = 0x00700000,
  RKBuildConfigBackslashRAnyCRLR = 1 << 23,
  RKBuildConfigBackslashRUnicode = 1 << 24
} RKBuildConfig;

#endif // _REGEXKIT_REGEXKITTYPES_H_

#ifdef __cplusplus
  }  /* extern "C" */
#endif
