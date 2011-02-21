//
//  RKUtility.m
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

#import <RegexKit/RKUtility.h>
#import <RegexKit/RegexKitPrivate.h>

NSString *RKStringFromNewlineOption(const int decodeNewlineOption, NSString *prefixString) {
  RKInteger newlineOption = decodeNewlineOption & RKMatchNewlineMask;
  NSString *newlineOptionString = NULL;
  BOOL unknownNewline = NO;
  
  if(prefixString == NULL) { prefixString = @""; }
  
  switch(newlineOption) {
    case 0:                     newlineOptionString = @"Default";                 break; // No newline option is set, use build time default
    case PCRE_NEWLINE_CR:       newlineOptionString = @"NewlineCR";               break;
    case PCRE_NEWLINE_LF:       newlineOptionString = @"NewlineLF";               break;
    case PCRE_NEWLINE_CRLF:     newlineOptionString = @"NewlineCRLF";             break;
#if PCRE_MAJOR >= 7 && PCRE_MINOR >= 1
    case PCRE_NEWLINE_ANYCRLF:  newlineOptionString = @"NewlineAnyCRLF";          break;
#endif // >= 7.1
    case PCRE_NEWLINE_ANY:      newlineOptionString = @"NewlineAny";              break;
    default:                    newlineOptionString = NULL; unknownNewline = YES; break;
  }
  
  if(newlineOptionString != NULL) { newlineOptionString = [NSString stringWithFormat:@"%@%@", prefixString, newlineOptionString]; }
  
  if((newlineOptionString == NULL) && (unknownNewline == YES)) { newlineOptionString = RKLocalizedFormat(@"/* Unknown Newline Option: 0x%8.8x */", (unsigned int)newlineOption); }
  
  return(newlineOptionString);
}

NSArray *RKArrayFromMatchOption(const RKMatchOption decodeMatchOption) {
  RKUInteger atString = 0;
  NSString *strings[256];
  memset(strings, 0, sizeof(NSString *) * 256);
  RKMatchOption decodedOptions = RKMatchNewlineMask;
  
  if(decodeMatchOption & RKMatchAnchored)           { strings[atString] = @"RKMatchAnchored";           atString++; decodedOptions |= RKMatchAnchored;           }
  if(decodeMatchOption & RKMatchNotBeginningOfLine) { strings[atString] = @"RKMatchNotBeginningOfLine"; atString++; decodedOptions |= RKMatchNotBeginningOfLine; }
  if(decodeMatchOption & RKMatchNotEndOfLine)       { strings[atString] = @"RKMatchNotEndOfLine";       atString++; decodedOptions |= RKMatchNotEndOfLine;       }
  if(decodeMatchOption & RKMatchNotEmpty)           { strings[atString] = @"RKMatchNotEmpty";           atString++; decodedOptions |= RKMatchNotEmpty;           }
  if(decodeMatchOption & RKMatchNoUTF8Check)        { strings[atString] = @"RKMatchNoUTF8Check";        atString++; decodedOptions |= RKMatchNoUTF8Check;        }
  if(decodeMatchOption & RKMatchPartial)            { strings[atString] = @"RKMatchPartial";            atString++; decodedOptions |= RKMatchPartial;            }
#if PCRE_MAJOR >= 7 && PCRE_MINOR >= 4
  if(decodeMatchOption & RKMatchBackslashRAnyCRLR)  { strings[atString] = @"RKMatchBackslashRAnyCRLR";  atString++; decodedOptions |= RKMatchBackslashRAnyCRLR;  }
  if(decodeMatchOption & RKMatchBackslashRUnicode)  { strings[atString] = @"RKMatchBackslashRUnicode";  atString++; decodedOptions |= RKMatchBackslashRUnicode;  }
#endif // >= 7.4
  
  if((decodeMatchOption & RKMatchNewlineMask) != RKMatchNewlineDefault) {
    strings[atString] = RKStringFromNewlineOption(decodeMatchOption, @"RKMatch"); if(strings[atString] != NULL) { atString++; }
  }
  decodedOptions |= (decodeMatchOption & RKMatchNewlineMask);

  decodedOptions ^= UINT_MAX;
  if((decodedOptions & decodeMatchOption) != 0) {
    strings[atString] = RKLocalizedFormat(@"/* Unknown match options remain: 0x%8.8x */", (unsigned int)(decodedOptions & decodeMatchOption));
    atString++;
  }
  
  if(atString == 0) { strings[atString] = @"RKMatchNoOptions"; atString++; }
  
  NSArray *stringArray = [NSArray arrayWithObjects:&strings[0] count:atString];
  
  return(stringArray);
}

NSArray *RKArrayFromCompileOption(const RKCompileOption decodeCompileOption) {
  RKUInteger atString = 0;
  NSString *strings[256];
  memset(strings, 0, sizeof(NSString *) * 256);
  RKCompileOption decodedOptions = RKCompileNewlineMask;
  
  if(decodeCompileOption & RKCompileNoOptions)         { strings[atString] = @"RKCompileNoOptions";         atString++; decodedOptions |= RKCompileNoOptions;         }
  if(decodeCompileOption & RKCompileCaseless)          { strings[atString] = @"RKCompileCaseless";          atString++; decodedOptions |= RKCompileCaseless;          }
  if(decodeCompileOption & RKCompileMultiline)         { strings[atString] = @"RKCompileMultiline";         atString++; decodedOptions |= RKCompileMultiline;         }
  if(decodeCompileOption & RKCompileDotAll)            { strings[atString] = @"RKCompileDotAll";            atString++; decodedOptions |= RKCompileDotAll;            }
  if(decodeCompileOption & RKCompileExtended)          { strings[atString] = @"RKCompileExtended";          atString++; decodedOptions |= RKCompileExtended;          }
  if(decodeCompileOption & RKCompileAnchored)          { strings[atString] = @"RKCompileAnchored";          atString++; decodedOptions |= RKCompileAnchored;          }
  if(decodeCompileOption & RKCompileDollarEndOnly)     { strings[atString] = @"RKCompileDollarEndOnly";     atString++; decodedOptions |= RKCompileDollarEndOnly;     }
  if(decodeCompileOption & RKCompileExtra)             { strings[atString] = @"RKCompileExtra";             atString++; decodedOptions |= RKCompileExtra;             }
  if(decodeCompileOption & RKCompileUngreedy)          { strings[atString] = @"RKCompileUngreedy";          atString++; decodedOptions |= RKCompileUngreedy;          }
  if(decodeCompileOption & RKCompileUTF8)              { strings[atString] = @"RKCompileUTF8";              atString++; decodedOptions |= RKCompileUTF8;              }
  if(decodeCompileOption & RKCompileNoAutoCapture)     { strings[atString] = @"RKCompileNoAutoCapture";     atString++; decodedOptions |= RKCompileNoAutoCapture;     }
  if(decodeCompileOption & RKCompileNoUTF8Check)       { strings[atString] = @"RKCompileNoUTF8Check";       atString++; decodedOptions |= RKCompileNoUTF8Check;       }
  if(decodeCompileOption & RKCompileAutoCallout)       { strings[atString] = @"RKCompileAutoCallout";       atString++; decodedOptions |= RKCompileAutoCallout;       }
  if(decodeCompileOption & RKCompileFirstLine)         { strings[atString] = @"RKCompileFirstLine";         atString++; decodedOptions |= RKCompileFirstLine;         }
  if(decodeCompileOption & RKCompileDupNames)          { strings[atString] = @"RKCompileDupNames";          atString++; decodedOptions |= RKCompileDupNames;          }
#if PCRE_MAJOR >= 7 && PCRE_MINOR >= 4
  if(decodeCompileOption & RKCompileBackslashRAnyCRLR) { strings[atString] = @"RKCompileBackslashRAnyCRLR"; atString++; decodedOptions |= RKCompileBackslashRAnyCRLR; }
  if(decodeCompileOption & RKCompileBackslashRUnicode) { strings[atString] = @"RKCompileBackslashRUnicode"; atString++; decodedOptions |= RKCompileBackslashRUnicode; }
#endif // >= 7.4
  
  if((decodeCompileOption & RKCompileNewlineMask) != RKCompileNewlineDefault) {
    strings[atString] = RKStringFromNewlineOption(decodeCompileOption, @"RKCompile"); if(strings[atString] != NULL) { atString++; }
  }
  decodedOptions |= (decodeCompileOption & RKCompileNewlineMask);
  
  decodedOptions ^= UINT_MAX;
  if((decodedOptions & decodeCompileOption) != 0) {
    strings[atString] = RKLocalizedFormat(@"/* Unknown compile options remain: 0x%8.8x */", (unsigned int)(decodedOptions & decodeCompileOption));
    atString++;
  }
  
  if(atString == 0) { strings[atString] = @"RKCompileNoOptions"; atString++; }
  
  NSArray *stringArray = [NSArray arrayWithObjects:&strings[0] count:atString];
  
  return(stringArray);
}

NSArray *RKArrayFromBuildConfig(const RKBuildConfig decodeBuildConfig) {
  RKUInteger atString = 0;
  NSString *strings[256];
  memset(strings, 0, sizeof(NSString *) * 256);
  RKBuildConfig decodedBuildConfig = RKBuildConfigNoOptions;
  
  if(decodeBuildConfig & RKBuildConfigUTF8)              { strings[atString] = @"RKBuildConfigUTF8";              atString++; decodedBuildConfig |= RKBuildConfigUTF8;              }
  if(decodeBuildConfig & RKBuildConfigUnicodeProperties) { strings[atString] = @"RKBuildConfigUnicodeProperties"; atString++; decodedBuildConfig |= RKBuildConfigUnicodeProperties; }
#if PCRE_MAJOR >= 7 && PCRE_MINOR >= 4
  if(decodeBuildConfig & RKBuildConfigBackslashRAnyCRLR) { strings[atString] = @"RKBuildConfigBackslashRAnyCRLR"; atString++; decodedBuildConfig |= RKBuildConfigBackslashRAnyCRLR; }
  if(decodeBuildConfig & RKBuildConfigBackslashRUnicode) { strings[atString] = @"RKBuildConfigBackslashRUnicode"; atString++; decodedBuildConfig |= RKBuildConfigBackslashRUnicode; }
#endif // >= 7.4
  
  if((decodeBuildConfig & RKBuildConfigNewlineMask) != RKBuildConfigNewlineDefault) {
    strings[atString] = RKStringFromNewlineOption(decodeBuildConfig, @"RKBuildConfig"); if(strings[atString] != NULL) { atString++; }
  }
  decodedBuildConfig |= (decodeBuildConfig & RKBuildConfigNewlineMask);

  decodedBuildConfig ^= UINT_MAX;
  if((decodedBuildConfig & decodeBuildConfig) != 0) {
    strings[atString] = RKLocalizedFormat(@"/* Unknown build config options remain: 0x%8.8x */", (unsigned int)(decodedBuildConfig & decodeBuildConfig));
    atString++;
  }
  
  if(atString == 0) { strings[atString] = @"RKBuildConfigNoOptions"; atString++; }
  
  NSArray *stringArray = [NSArray arrayWithObjects:&strings[0] count:atString];
  
  return(stringArray);
}

NSString *RKStringFromCompileErrorCode(const RKCompileErrorCode decodeErrorCode) {
  NSString *errorCodeString = NULL;
  
  switch(decodeErrorCode) {
    case RKCompileErrorNoError:                                     errorCodeString = @"RKCompileErrorNoError";                                     break;
    case RKCompileErrorEscapeAtEndOfPattern:                        errorCodeString = @"RKCompileErrorEscapeAtEndOfPattern";                        break;
    case RKCompileErrorByteEscapeAtEndOfPattern:                    errorCodeString = @"RKCompileErrorByteEscapeAtEndOfPattern";                    break;
    case RKCompileErrorUnrecognizedCharacterFollowingEscape:        errorCodeString = @"RKCompileErrorUnrecognizedCharacterFollowingEscape";        break;
    case RKCompileErrorNumbersOutOfOrder:                           errorCodeString = @"RKCompileErrorNumbersOutOfOrder";                           break;
    case RKCompileErrorNumbersToBig:                                errorCodeString = @"RKCompileErrorNumbersToBig";                                break;
    case RKCompileErrorMissingTerminatorForCharacterClass:          errorCodeString = @"RKCompileErrorMissingTerminatorForCharacterClass";          break;
    case RKCompileErrorInvalidEscapeInCharacterClass:               errorCodeString = @"RKCompileErrorInvalidEscapeInCharacterClass";               break;
    case RKCompileErrorRangeOutOfOrderInCharacterClass:             errorCodeString = @"RKCompileErrorRangeOutOfOrderInCharacterClass";             break;
    case RKCompileErrorNothingToRepeat:                             errorCodeString = @"RKCompileErrorNothingToRepeat";                             break;
    case RKCompileErrorInternalErrorUnexpectedRepeat:               errorCodeString = @"RKCompileErrorInternalErrorUnexpectedRepeat";               break;
    case RKCompileErrorUnrecognizedCharacterAfterOption:            errorCodeString = @"RKCompileErrorUnrecognizedCharacterAfterOption";            break;
    case RKCompileErrorPOSIXNamedClassOutsideOfClass:               errorCodeString = @"RKCompileErrorPOSIXNamedClassOutsideOfClass";               break;
    case RKCompileErrorMissingParentheses:                          errorCodeString = @"RKCompileErrorMissingParentheses";                          break;
    case RKCompileErrorReferenceToNonExistentSubpattern:            errorCodeString = @"RKCompileErrorReferenceToNonExistentSubpattern";            break;
    case RKCompileErrorErrorOffsetPassedAsNull:                     errorCodeString = @"RKCompileErrorErrorOffsetPassedAsNull";                     break;
    case RKCompileErrorUnknownOptionBits:                           errorCodeString = @"RKCompileErrorUnknownOptionBits";                           break;
    case RKCompileErrorMissingParenthesesAfterComment:              errorCodeString = @"RKCompileErrorMissingParenthesesAfterComment";              break;
    case RKCompileErrorRegexTooLarge:                               errorCodeString = @"RKCompileErrorRegexTooLarge";                               break;
    case RKCompileErrorNoMemory:                                    errorCodeString = @"RKCompileErrorNoMemory";                                    break;
    case RKCompileErrorUnmatchedParentheses:                        errorCodeString = @"RKCompileErrorUnmatchedParentheses";                        break;
    case RKCompileErrorInternalCodeOverflow:                        errorCodeString = @"RKCompileErrorInternalCodeOverflow";                        break;
    case RKCompileErrorUnrecognizedCharacterAfterNamedSubppatern:   errorCodeString = @"RKCompileErrorUnrecognizedCharacterAfterNamedSubppatern";   break;
    case RKCompileErrorLookbehindAssertionNotFixedLength:           errorCodeString = @"RKCompileErrorLookbehindAssertionNotFixedLength";           break;
    case RKCompileErrorMalformedNameOrNumberAfterSubpattern:        errorCodeString = @"RKCompileErrorMalformedNameOrNumberAfterSubpattern";        break;
    case RKCompileErrorConditionalGroupContainsMoreThanTwoBranches: errorCodeString = @"RKCompileErrorConditionalGroupContainsMoreThanTwoBranches"; break;
    case RKCompileErrorAssertionExpectedAfterCondition:             errorCodeString = @"RKCompileErrorAssertionExpectedAfterCondition";             break;
    case RKCompileErrorMissingEndParentheses:                       errorCodeString = @"RKCompileErrorMissingEndParentheses";                       break;
    case RKCompileErrorUnknownPOSIXClassName:                       errorCodeString = @"RKCompileErrorUnknownPOSIXClassName";                       break;
    case RKCompileErrorPOSIXCollatingNotSupported:                  errorCodeString = @"RKCompileErrorPOSIXCollatingNotSupported";                  break;
    case RKCompileErrorMissingUTF8Support:                          errorCodeString = @"RKCompileErrorMissingUTF8Support";                          break;
    case RKCompileErrorHexCharacterValueTooLarge:                   errorCodeString = @"RKCompileErrorHexCharacterValueTooLarge";                   break;
    case RKCompileErrorInvalidCondition:                            errorCodeString = @"RKCompileErrorInvalidCondition";                            break;
    case RKCompileErrorNotAllowedInLookbehindAssertion:             errorCodeString = @"RKCompileErrorNotAllowedInLookbehindAssertion";             break;
    case RKCompileErrorNotSupported:                                errorCodeString = @"RKCompileErrorNotSupported";                                break;
    case RKCompileErrorCalloutExceedsMaximumAllowed:                errorCodeString = @"RKCompileErrorCalloutExceedsMaximumAllowed";                break;
    case RKCompileErrorMissingParenthesesAfterCallout:              errorCodeString = @"RKCompileErrorMissingParenthesesAfterCallout";              break;
    case RKCompileErrorRecursiveInfinitLoop:                        errorCodeString = @"RKCompileErrorRecursiveInfinitLoop";                        break;
    case RKCompileErrorUnrecognizedCharacterAfterNamedPattern:      errorCodeString = @"RKCompileErrorUnrecognizedCharacterAfterNamedPattern";      break;
    case RKCompileErrorSubpatternNameMissingTerminator:             errorCodeString = @"RKCompileErrorSubpatternNameMissingTerminator";             break;
    case RKCompileErrorDuplicateSubpatternNames:                    errorCodeString = @"RKCompileErrorDuplicateSubpatternNames";                    break;
    case RKCompileErrorInvalidUTF8String:                           errorCodeString = @"RKCompileErrorInvalidUTF8String";                           break;
    case RKCompileErrorMissingUnicodeSupport:                       errorCodeString = @"RKCompileErrorMissingUnicodeSupport";                       break;
    case RKCompileErrorMalformedUnicodeProperty:                    errorCodeString = @"RKCompileErrorMalformedUnicodeProperty";                    break;
    case RKCompileErrorUnknownPropertyAfterUnicodeCharacter:        errorCodeString = @"RKCompileErrorUnknownPropertyAfterUnicodeCharacter";        break;
    case RKCompileErrorSubpatternNameTooLong:                       errorCodeString = @"RKCompileErrorSubpatternNameTooLong";                       break;
    case RKCompileErrorTooManySubpatterns:                          errorCodeString = @"RKCompileErrorTooManySubpatterns";                          break;
    case RKCompileErrorRepeatedSubpatternTooLong:                   errorCodeString = @"RKCompileErrorRepeatedSubpatternTooLong";                   break;
    case RKCompileErrorIllegalOctalValueOutsideUTF8:                errorCodeString = @"RKCompileErrorIllegalOctalValueOutsideUTF8";                break;
    case RKCompileErrorInternalOverranCompilingWorkspace:           errorCodeString = @"RKCompileErrorInternalOverranCompilingWorkspace";           break;
    case RKCompileErrorInternalReferencedSubpatternNotFound:        errorCodeString = @"RKCompileErrorInternalReferencedSubpatternNotFound";        break;
    case RKCompileErrorDEFINEGroupContainsMoreThanOneBranch:        errorCodeString = @"RKCompileErrorDEFINEGroupContainsMoreThanOneBranch";        break;
    case RKCompileErrorRepeatingDEFINEGroupNotAllowed:              errorCodeString = @"RKCompileErrorRepeatingDEFINEGroupNotAllowed";              break;
    case RKCompileErrorInconsistentNewlineOptions:                  errorCodeString = @"RKCompileErrorInconsistentNewlineOptions";                  break;
    case RKCompileErrorReferenceMustBeNonZeroNumberOrBraced:        errorCodeString = @"RKCompileErrorReferenceMustBeNonZeroNumberOrBraced";        break;
    case RKCompileErrorRelativeSubpatternNumberMustNotBeZero:       errorCodeString = @"RKCompileErrorRelativeSubpatternNumberMustNotBeZero";       break;
    default:                                                        errorCodeString = RKLocalizedFormat(@"Unknown error code (#%d)", (int)decodeErrorCode); break;
  }
  
  return(errorCodeString);
}

NSString *RKStringFromMatchErrorCode(const RKMatchErrorCode decodeErrorCode) {
  NSString *errorCodeString = NULL;
  
  if(decodeErrorCode > 0) { return(@""); }
  
  switch(decodeErrorCode) {
    case RKMatchErrorNoError:            errorCodeString = @"RKMatchErrorNoError";            break;
    case RKMatchErrorNoMatch:            errorCodeString = @"RKMatchErrorNoMatch";            break;
    case RKMatchErrorNull:               errorCodeString = @"RKMatchErrorNull";               break;
    case RKMatchErrorBadOption:          errorCodeString = @"RKMatchErrorBadOption";          break;
    case RKMatchErrorBadMagic:           errorCodeString = @"RKMatchErrorBadMagic";           break;
    case RKMatchErrorUnknownOpcode:      errorCodeString = @"RKMatchErrorUnknownOpcode";      break;
    case RKMatchErrorNoMemory:           errorCodeString = @"RKMatchErrorNoMemory";           break;
    case RKMatchErrorNoSubstring:        errorCodeString = @"RKMatchErrorNoSubstring";        break;
    case RKMatchErrorMatchLimit:         errorCodeString = @"RKMatchErrorMatchLimit";         break;
    case RKMatchErrorCallout:            errorCodeString = @"RKMatchErrorCallout";            break;
    case RKMatchErrorBadUTF8:            errorCodeString = @"RKMatchErrorBadUTF8";            break;
    case RKMatchErrorBadUTF8Offset:      errorCodeString = @"RKMatchErrorBadUTF8Offset";      break;
    case RKMatchErrorPartial:            errorCodeString = @"RKMatchErrorPartial";            break;
    case RKMatchErrorBadPartial:         errorCodeString = @"RKMatchErrorBadPartial";         break;
    case RKMatchErrorInternal:           errorCodeString = @"RKMatchErrorInternal";           break;
    case RKMatchErrorBadCount:           errorCodeString = @"RKMatchErrorBadCount";           break;
    case RKMatchErrorRecursionLimit:     errorCodeString = @"RKMatchErrorRecursionLimit";     break;
    case RKMatchErrorNullWorkSpaceLimit: errorCodeString = @"RKMatchErrorNullWorkSpaceLimit"; break;
    case RKMatchErrorBadNewline:         errorCodeString = @"RKMatchErrorBadNewline";         break;
    default:                             errorCodeString = RKLocalizedFormat(@"Unknown error code (#%d)", (int)decodeErrorCode); break;
  }
  
  return(errorCodeString);
}


const char *RKCharactersFromCompileErrorCode(const RKCompileErrorCode decodeErrorCode) {
  const char *errorCodeCharacters = NULL;
  
  switch(decodeErrorCode) {
    case RKCompileErrorNoError:                                     errorCodeCharacters = "RKCompileErrorNoError";                                     break;
    case RKCompileErrorEscapeAtEndOfPattern:                        errorCodeCharacters = "RKCompileErrorEscapeAtEndOfPattern";                        break;
    case RKCompileErrorByteEscapeAtEndOfPattern:                    errorCodeCharacters = "RKCompileErrorByteEscapeAtEndOfPattern";                    break;
    case RKCompileErrorUnrecognizedCharacterFollowingEscape:        errorCodeCharacters = "RKCompileErrorUnrecognizedCharacterFollowingEscape";        break;
    case RKCompileErrorNumbersOutOfOrder:                           errorCodeCharacters = "RKCompileErrorNumbersOutOfOrder";                           break;
    case RKCompileErrorNumbersToBig:                                errorCodeCharacters = "RKCompileErrorNumbersToBig";                                break;
    case RKCompileErrorMissingTerminatorForCharacterClass:          errorCodeCharacters = "RKCompileErrorMissingTerminatorForCharacterClass";          break;
    case RKCompileErrorInvalidEscapeInCharacterClass:               errorCodeCharacters = "RKCompileErrorInvalidEscapeInCharacterClass";               break;
    case RKCompileErrorRangeOutOfOrderInCharacterClass:             errorCodeCharacters = "RKCompileErrorRangeOutOfOrderInCharacterClass";             break;
    case RKCompileErrorNothingToRepeat:                             errorCodeCharacters = "RKCompileErrorNothingToRepeat";                             break;
    case RKCompileErrorInternalErrorUnexpectedRepeat:               errorCodeCharacters = "RKCompileErrorInternalErrorUnexpectedRepeat";               break;
    case RKCompileErrorUnrecognizedCharacterAfterOption:            errorCodeCharacters = "RKCompileErrorUnrecognizedCharacterAfterOption";            break;
    case RKCompileErrorPOSIXNamedClassOutsideOfClass:               errorCodeCharacters = "RKCompileErrorPOSIXNamedClassOutsideOfClass";               break;
    case RKCompileErrorMissingParentheses:                          errorCodeCharacters = "RKCompileErrorMissingParentheses";                          break;
    case RKCompileErrorReferenceToNonExistentSubpattern:            errorCodeCharacters = "RKCompileErrorReferenceToNonExistentSubpattern";            break;
    case RKCompileErrorErrorOffsetPassedAsNull:                     errorCodeCharacters = "RKCompileErrorErrorOffsetPassedAsNull";                     break;
    case RKCompileErrorUnknownOptionBits:                           errorCodeCharacters = "RKCompileErrorUnknownOptionBits";                           break;
    case RKCompileErrorMissingParenthesesAfterComment:              errorCodeCharacters = "RKCompileErrorMissingParenthesesAfterComment";              break;
    case RKCompileErrorRegexTooLarge:                               errorCodeCharacters = "RKCompileErrorRegexTooLarge";                               break;
    case RKCompileErrorNoMemory:                                    errorCodeCharacters = "RKCompileErrorNoMemory";                                    break;
    case RKCompileErrorUnmatchedParentheses:                        errorCodeCharacters = "RKCompileErrorUnmatchedParentheses";                        break;
    case RKCompileErrorInternalCodeOverflow:                        errorCodeCharacters = "RKCompileErrorInternalCodeOverflow";                        break;
    case RKCompileErrorUnrecognizedCharacterAfterNamedSubppatern:   errorCodeCharacters = "RKCompileErrorUnrecognizedCharacterAfterNamedSubppatern";   break;
    case RKCompileErrorLookbehindAssertionNotFixedLength:           errorCodeCharacters = "RKCompileErrorLookbehindAssertionNotFixedLength";           break;
    case RKCompileErrorMalformedNameOrNumberAfterSubpattern:        errorCodeCharacters = "RKCompileErrorMalformedNameOrNumberAfterSubpattern";        break;
    case RKCompileErrorConditionalGroupContainsMoreThanTwoBranches: errorCodeCharacters = "RKCompileErrorConditionalGroupContainsMoreThanTwoBranches"; break;
    case RKCompileErrorAssertionExpectedAfterCondition:             errorCodeCharacters = "RKCompileErrorAssertionExpectedAfterCondition";             break;
    case RKCompileErrorMissingEndParentheses:                       errorCodeCharacters = "RKCompileErrorMissingEndParentheses";                       break;
    case RKCompileErrorUnknownPOSIXClassName:                       errorCodeCharacters = "RKCompileErrorUnknownPOSIXClassName";                       break;
    case RKCompileErrorPOSIXCollatingNotSupported:                  errorCodeCharacters = "RKCompileErrorPOSIXCollatingNotSupported";                  break;
    case RKCompileErrorMissingUTF8Support:                          errorCodeCharacters = "RKCompileErrorMissingUTF8Support";                          break;
    case RKCompileErrorHexCharacterValueTooLarge:                   errorCodeCharacters = "RKCompileErrorHexCharacterValueTooLarge";                   break;
    case RKCompileErrorInvalidCondition:                            errorCodeCharacters = "RKCompileErrorInvalidCondition";                            break;
    case RKCompileErrorNotAllowedInLookbehindAssertion:             errorCodeCharacters = "RKCompileErrorNotAllowedInLookbehindAssertion";             break;
    case RKCompileErrorNotSupported:                                errorCodeCharacters = "RKCompileErrorNotSupported";                                break;
    case RKCompileErrorCalloutExceedsMaximumAllowed:                errorCodeCharacters = "RKCompileErrorCalloutExceedsMaximumAllowed";                break;
    case RKCompileErrorMissingParenthesesAfterCallout:              errorCodeCharacters = "RKCompileErrorMissingParenthesesAfterCallout";              break;
    case RKCompileErrorRecursiveInfinitLoop:                        errorCodeCharacters = "RKCompileErrorRecursiveInfinitLoop";                        break;
    case RKCompileErrorUnrecognizedCharacterAfterNamedPattern:      errorCodeCharacters = "RKCompileErrorUnrecognizedCharacterAfterNamedPattern";      break;
    case RKCompileErrorSubpatternNameMissingTerminator:             errorCodeCharacters = "RKCompileErrorSubpatternNameMissingTerminator";             break;
    case RKCompileErrorDuplicateSubpatternNames:                    errorCodeCharacters = "RKCompileErrorDuplicateSubpatternNames";                    break;
    case RKCompileErrorInvalidUTF8String:                           errorCodeCharacters = "RKCompileErrorInvalidUTF8String";                           break;
    case RKCompileErrorMissingUnicodeSupport:                       errorCodeCharacters = "RKCompileErrorMissingUnicodeSupport";                       break;
    case RKCompileErrorMalformedUnicodeProperty:                    errorCodeCharacters = "RKCompileErrorMalformedUnicodeProperty";                    break;
    case RKCompileErrorUnknownPropertyAfterUnicodeCharacter:        errorCodeCharacters = "RKCompileErrorUnknownPropertyAfterUnicodeCharacter";        break;
    case RKCompileErrorSubpatternNameTooLong:                       errorCodeCharacters = "RKCompileErrorSubpatternNameTooLong";                       break;
    case RKCompileErrorTooManySubpatterns:                          errorCodeCharacters = "RKCompileErrorTooManySubpatterns";                          break;
    case RKCompileErrorRepeatedSubpatternTooLong:                   errorCodeCharacters = "RKCompileErrorRepeatedSubpatternTooLong";                   break;
    case RKCompileErrorIllegalOctalValueOutsideUTF8:                errorCodeCharacters = "RKCompileErrorIllegalOctalValueOutsideUTF8";                break;
    case RKCompileErrorInternalOverranCompilingWorkspace:           errorCodeCharacters = "RKCompileErrorInternalOverranCompilingWorkspace";           break;
    case RKCompileErrorInternalReferencedSubpatternNotFound:        errorCodeCharacters = "RKCompileErrorInternalReferencedSubpatternNotFound";        break;
    case RKCompileErrorDEFINEGroupContainsMoreThanOneBranch:        errorCodeCharacters = "RKCompileErrorDEFINEGroupContainsMoreThanOneBranch";        break;
    case RKCompileErrorRepeatingDEFINEGroupNotAllowed:              errorCodeCharacters = "RKCompileErrorRepeatingDEFINEGroupNotAllowed";              break;
    case RKCompileErrorInconsistentNewlineOptions:                  errorCodeCharacters = "RKCompileErrorInconsistentNewlineOptions";                  break;
    case RKCompileErrorReferenceMustBeNonZeroNumberOrBraced:        errorCodeCharacters = "RKCompileErrorReferenceMustBeNonZeroNumberOrBraced";        break;
    case RKCompileErrorRelativeSubpatternNumberMustNotBeZero:       errorCodeCharacters = "RKCompileErrorRelativeSubpatternNumberMustNotBeZero";       break;
    default:                                                        errorCodeCharacters = "Unknown error code";                                        break;
  }
  
  return(errorCodeCharacters);
}

const char *RKCharactersFromMatchErrorCode(const RKMatchErrorCode decodeErrorCode) {
  const char *errorCodeCharacters = NULL;
  
  if(decodeErrorCode > 0) { return(""); }
  
  switch(decodeErrorCode) {
    case RKMatchErrorNoError:            errorCodeCharacters = "RKMatchErrorNoError";            break;
    case RKMatchErrorNoMatch:            errorCodeCharacters = "RKMatchErrorNoMatch";            break;
    case RKMatchErrorNull:               errorCodeCharacters = "RKMatchErrorNull";               break;
    case RKMatchErrorBadOption:          errorCodeCharacters = "RKMatchErrorBadOption";          break;
    case RKMatchErrorBadMagic:           errorCodeCharacters = "RKMatchErrorBadMagic";           break;
    case RKMatchErrorUnknownOpcode:      errorCodeCharacters = "RKMatchErrorUnknownOpcode";      break;
    case RKMatchErrorNoMemory:           errorCodeCharacters = "RKMatchErrorNoMemory";           break;
    case RKMatchErrorNoSubstring:        errorCodeCharacters = "RKMatchErrorNoSubstring";        break;
    case RKMatchErrorMatchLimit:         errorCodeCharacters = "RKMatchErrorMatchLimit";         break;
    case RKMatchErrorCallout:            errorCodeCharacters = "RKMatchErrorCallout";            break;
    case RKMatchErrorBadUTF8:            errorCodeCharacters = "RKMatchErrorBadUTF8";            break;
    case RKMatchErrorBadUTF8Offset:      errorCodeCharacters = "RKMatchErrorBadUTF8Offset";      break;
    case RKMatchErrorPartial:            errorCodeCharacters = "RKMatchErrorPartial";            break;
    case RKMatchErrorBadPartial:         errorCodeCharacters = "RKMatchErrorBadPartial";         break;
    case RKMatchErrorInternal:           errorCodeCharacters = "RKMatchErrorInternal";           break;
    case RKMatchErrorBadCount:           errorCodeCharacters = "RKMatchErrorBadCount";           break;
    case RKMatchErrorRecursionLimit:     errorCodeCharacters = "RKMatchErrorRecursionLimit";     break;
    case RKMatchErrorNullWorkSpaceLimit: errorCodeCharacters = "RKMatchErrorNullWorkSpaceLimit"; break;
    case RKMatchErrorBadNewline:         errorCodeCharacters = "RKMatchErrorBadNewline";         break;
    default:                             errorCodeCharacters = "Unknown error code";             break;
  }
  
  return(errorCodeCharacters);
}
