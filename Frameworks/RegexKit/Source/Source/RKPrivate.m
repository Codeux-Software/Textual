//
//  RKPrivate.m
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

#import <RegexKit/RegexKitPrivate.h>

void nsprintf(NSString * const formatString, ...) {
  va_list ap;
  
  va_start(ap, formatString);
  vnsprintf(formatString, ap);
  va_end(ap);
  
  return;
}

void vnsprintf(NSString * const formatString, va_list ap) {
  NSString *logString = RKAutorelease([[NSString alloc] initWithFormat:formatString arguments:ap]);
  
  printf("%s", [logString UTF8String]);
}

#pragma mark -

NSString *RKPrettyObjectMethodStringFunction(id self, SEL _cmd, NSString * const formatString, ...) {
  va_list ap;
  
  va_start(ap, formatString);
  NSString *returnString = RKVPrettyObjectMethodStringFunction(self, _cmd, formatString, ap);
  va_end(ap);
  
  return(returnString);
}

NSString *RKVPrettyObjectMethodStringFunction(id self, SEL _cmd, NSString * const formatString, va_list argList) {
  return([[[NSString alloc] initWithFormat:[NSString stringWithFormat:@"%p [%@ %@]: %@", self, self == NULL ? @"NULL" : NSStringFromClass([(id)self class]), _cmd == NULL ? @"" : NSStringFromSelector(_cmd), formatString == NULL ? @"(formatString is NULL)" : formatString] arguments:argList] autorelease]);
}

#pragma mark -
#pragma mark NSError Additions

@implementation NSError (RegexKitPrivate)

+ (NSError *)rkErrorWithCode:(RKInteger)errorCode localizeDescription:(NSString *)errorStringToLocalize, ...
{
  va_list varArgsList; va_start(varArgsList, errorStringToLocalize);
  return([NSError errorWithDomain:RKRegexErrorDomain code:errorCode userInfo:[NSDictionary dictionaryWithObject:RKLocalizedFormatWithArgs(errorStringToLocalize, varArgsList) forKey:NSLocalizedDescriptionKey]]);
}

+ (NSError *)rkErrorWithDomain:(NSString *)errorDomain code:(RKInteger)errorCode localizeDescription:(NSString *)errorStringToLocalize, ...
{
  va_list varArgsList; va_start(varArgsList, errorStringToLocalize);
  return([NSError errorWithDomain:errorDomain code:errorCode userInfo:[NSDictionary dictionaryWithObject:RKLocalizedFormatWithArgs(errorStringToLocalize, varArgsList) forKey:NSLocalizedDescriptionKey]]);
}

+ (NSError *)rkErrorWithDomain:(NSString *)errorDomain code:(RKInteger)errorCode userInfo:(NSDictionary *)dict localizeDescription:(NSString *)errorStringToLocalize, ...
{
  va_list varArgsList; va_start(varArgsList, errorStringToLocalize);
  NSMutableDictionary *userInfoMutableDictionary = [NSMutableDictionary dictionaryWithDictionary:dict];
  [userInfoMutableDictionary setObject:NSLocalizedDescriptionKey forKey:RKLocalizedFormatWithArgs(errorStringToLocalize, varArgsList)];
  return([NSError errorWithDomain:errorDomain code:errorCode userInfo:[NSDictionary dictionaryWithDictionary:userInfoMutableDictionary]]);
}

@end

#pragma mark -
#pragma mark NSException Additions

@implementation NSException (RegexKitPrivate)

+ (NSException *)rkException:(NSString *)exceptionString localizeReason:(NSString *)reasonStringToLocalize, ...;
{
  va_list varArgsList; va_start(varArgsList, reasonStringToLocalize);
  return([NSException exceptionWithName:exceptionString reason:RKLocalizedFormatWithArgs(reasonStringToLocalize, varArgsList) userInfo:NULL]);
}

+ (NSException *)rkException:(NSString *)exceptionString userInfo:(NSDictionary *)infoDictionary localizeReason:(NSString *)reasonStringToLocalize, ...;
{
  va_list varArgsList; va_start(varArgsList, reasonStringToLocalize);
  return([NSException exceptionWithName:exceptionString reason:RKLocalizedFormatWithArgs(reasonStringToLocalize, varArgsList) userInfo:infoDictionary]);
}

+ (NSException *)rkException:(NSString *)exceptionString for:(id)object selector:(SEL)sel localizeReason:(NSString *)reasonStringToLocalize, ...;
{
  va_list varArgsList; va_start(varArgsList, reasonStringToLocalize);
  return([NSException exceptionWithName:exceptionString reason:RKVPrettyObjectMethodStringFunction(object, sel, RKLocalizedString(reasonStringToLocalize), varArgsList) userInfo:NULL]);
}

+ (NSException *)rkException:(NSString *)exceptionString for:(id)object selector:(SEL)sel userInfo:(NSDictionary *)infoDictionary localizeReason:(NSString *)reasonStringToLocalize, ...;
{
  va_list varArgsList; va_start(varArgsList, reasonStringToLocalize);
  return([NSException exceptionWithName:exceptionString reason:RKVPrettyObjectMethodStringFunction(object, sel, RKLocalizedString(reasonStringToLocalize), varArgsList) userInfo:infoDictionary]);
}

@end

#pragma mark -

int RKRegexPCRECallout(pcre_callout_block * const callout_block RK_ATTRIBUTES(unused)) {
  [[NSException exceptionWithName:RKRegexUnsupportedException reason:RKLocalizedString(@"Callouts are not supported.") userInfo:NULL] raise];
  return(RKMatchErrorBadOption);
}



NSArray *RKArrayOfPrettyNewlineTypes(NSString * const prefixString) {
  return([NSArray arrayWithObjects:
    [NSString stringWithFormat:@"%@ 0x%8.8x", RKStringFromNewlineOption(RKCompileNewlineDefault, prefixString), (unsigned int)RKCompileNewlineDefault],
    [NSString stringWithFormat:@"%@ 0x%8.8x", RKStringFromNewlineOption(RKCompileNewlineCR,      prefixString), (unsigned int)RKCompileNewlineCR],
    [NSString stringWithFormat:@"%@ 0x%8.8x", RKStringFromNewlineOption(RKCompileNewlineLF,      prefixString), (unsigned int)RKCompileNewlineLF],
    [NSString stringWithFormat:@"%@ 0x%8.8x", RKStringFromNewlineOption(RKCompileNewlineCRLF,    prefixString), (unsigned int)RKCompileNewlineCRLF],
    [NSString stringWithFormat:@"%@ 0x%8.8x", RKStringFromNewlineOption(RKCompileNewlineAnyCRLF, prefixString), (unsigned int)RKCompileNewlineAnyCRLF],
    [NSString stringWithFormat:@"%@ 0x%8.8x", RKStringFromNewlineOption(RKCompileNewlineAny,     prefixString), (unsigned int)RKCompileNewlineAny],
    
    NULL]);
}

NSString *RKLocalizedStringForPCRECompileErrorCode(int errorCode) {
  NSString *localizeString = NULL, *returnString = NULL;
  
  switch(errorCode) {
    case RKCompileErrorNoError:                                     localizeString = @"No error."; break;
    case RKCompileErrorEscapeAtEndOfPattern:                        localizeString = @"The start of an escape sequence, '\\', was found at end of the regular expression."; break;
    case RKCompileErrorByteEscapeAtEndOfPattern:                    localizeString = @"'\\c' at end of pattern."; break;
    case RKCompileErrorUnrecognizedCharacterFollowingEscape:        localizeString = @"Unknown escape sequence specified by the character following '\\'."; break;
    case RKCompileErrorNumbersOutOfOrder:                           localizeString = @"The numbers are out of order in the '{x, y}' quantifier."; break;
    case RKCompileErrorNumbersToBig:                                localizeString = @"Number too big in {} quantifier."; break;
    case RKCompileErrorMissingTerminatorForCharacterClass:          localizeString = @"The terminating ']' for the '[...]' character class is missing."; break;
    case RKCompileErrorInvalidEscapeInCharacterClass:               localizeString = @"Invalid escape sequence inside the '[...]' character class."; break;
    case RKCompileErrorRangeOutOfOrderInCharacterClass:             localizeString = @"Invalid character range specified inside the '[a-z]' character class."; break;
    case RKCompileErrorNothingToRepeat:                             localizeString = @"Nothing to repeat."; break;
    case RKCompileErrorInternalErrorUnexpectedRepeat:               localizeString = @"Internal error, unexpected repeat."; break;
    case RKCompileErrorUnrecognizedCharacterAfterOption:            localizeString = @"Unrecognized character after '(?'."; break;
    case RKCompileErrorPOSIXNamedClassOutsideOfClass:               localizeString = @"POSIX named classes are supported only within a '[...]' character class."; break;
    case RKCompileErrorMissingParentheses:                          localizeString = @"The closing ')' for a '(...)' parenthesis pair is missing."; break;
    case RKCompileErrorReferenceToNonExistentSubpattern:            localizeString = @"Reference to non-existent subpattern."; break;
    case RKCompileErrorErrorOffsetPassedAsNull:                     localizeString = @"Internal error, the error offset argument to pcre_exec() may not be NULL."; break;
    case RKCompileErrorUnknownOptionBits:                           localizeString = @"Unrecognized compile option bit(s) set."; break;
    case RKCompileErrorMissingParenthesesAfterComment:              localizeString = @"Missing ')' after comment."; break;
    case RKCompileErrorRegexTooLarge:                               localizeString = @"The regular expression is too large."; break;
    case RKCompileErrorNoMemory:                                    localizeString = @"Memory allocation failure."; break;
    case RKCompileErrorUnmatchedParentheses:                        localizeString = @"Unmatched parentheses."; break;
    case RKCompileErrorInternalCodeOverflow:                        localizeString = @"Internal error, code overflow."; break;
    case RKCompileErrorUnrecognizedCharacterAfterNamedSubppatern:   localizeString = @"Unrecognized character after '(?<'."; break;
    case RKCompileErrorLookbehindAssertionNotFixedLength:           localizeString = @"Lookbehind assertion is not fixed length."; break;
    case RKCompileErrorMalformedNameOrNumberAfterSubpattern:        localizeString = @"Malformed number or name after '(?('."; break;
    case RKCompileErrorConditionalGroupContainsMoreThanTwoBranches: localizeString = @"The conditional group contains more than two branches."; break;
    case RKCompileErrorAssertionExpectedAfterCondition:             localizeString = @"Assertion expected after '(?('."; break;
    case RKCompileErrorMissingEndParentheses:                       localizeString = @"'(?R' or '(?DIGITS' must be followed by ')'."; break;
    case RKCompileErrorUnknownPOSIXClassName:                       localizeString = @"Unknown POSIX class name."; break;
    case RKCompileErrorPOSIXCollatingNotSupported:                  localizeString = @"POSIX collating elements are not supported."; break;
    case RKCompileErrorMissingUTF8Support:                          localizeString = @"The PCRE library was not built with UTF8 support."; break;
    case RKCompileErrorHexCharacterValueTooLarge:                   localizeString = @"The character value in '\\x{...}' sequence is too large."; break;
    case RKCompileErrorInvalidCondition:                            localizeString = @"Invalid condition '(?(0)'."; break;
    case RKCompileErrorNotAllowedInLookbehindAssertion:             localizeString = @"The escape sequence '\\C' is not permittedd in a look-behind assertion."; break;
    case RKCompileErrorNotSupported:                                localizeString = @"PCRE does not support '\\L', '\\l', '\\N', '\\U', or '\\u'."; break;
    case RKCompileErrorCalloutExceedsMaximumAllowed:                localizeString = @"The number after '(?C' is greater than 255."; break;
    case RKCompileErrorMissingParenthesesAfterCallout:              localizeString = @"The closing ')' for '(?C' is missing."; break;
    case RKCompileErrorRecursiveInfinitLoop:                        localizeString = @"The recursive call could loop indefinitely."; break;
    case RKCompileErrorUnrecognizedCharacterAfterNamedPattern:      localizeString = @"Unrecognized character after '(?P'."; break;
    case RKCompileErrorSubpatternNameMissingTerminator:             localizeString = @"Syntax error in subpattern name (missing terminator)."; break;
    case RKCompileErrorDuplicateSubpatternNames:                    localizeString = @"The name of a named subpattern must be unique when the duplicate names compile option is not set."; break;
    case RKCompileErrorInvalidUTF8String:                           localizeString = @"Invalid UTF8 string."; break;
    case RKCompileErrorMissingUnicodeSupport:                       localizeString = @"The escape sequences '\\P', '\\p', and '\\X' are not valid because the PCRE library was not built with Unicode support."; break;
    case RKCompileErrorMalformedUnicodeProperty:                    localizeString = @"Malformed '\\P' or '\\p' escape sequence."; break;
    case RKCompileErrorUnknownPropertyAfterUnicodeCharacter:        localizeString = @"Unknown property name after '\\P' or '\\p'."; break;
    case RKCompileErrorSubpatternNameTooLong:                       localizeString = @"The named subpattern exceeds the maximum length of 32 characters."; break;
    case RKCompileErrorTooManySubpatterns:                          localizeString = @"The number of named subpatterns exceeds the maximum of 10,000."; break;
    case RKCompileErrorRepeatedSubpatternTooLong:                   localizeString = @"The repeated subpattern is too long."; break;
    case RKCompileErrorIllegalOctalValueOutsideUTF8:                localizeString = @"Octal values greater than '\\377' are not permited when the UTF8 compile option is not set."; break;
    case RKCompileErrorInternalOverranCompilingWorkspace:           localizeString = @"Internal error, overran compiling workspace."; break;
    case RKCompileErrorInternalReferencedSubpatternNotFound:        localizeString = @"Internal error, previously-checked referenced subpattern was not found."; break;
    case RKCompileErrorDEFINEGroupContainsMoreThanOneBranch:        localizeString = @"The DEFINE group contains more than one branch."; break;
    case RKCompileErrorRepeatingDEFINEGroupNotAllowed:              localizeString = @"Repeating a DEFINE group is not allowed."; break;
    case RKCompileErrorInconsistentNewlineOptions:                  localizeString = @"Inconsistent newline compile option."; break;
    case RKCompileErrorReferenceMustBeNonZeroNumberOrBraced:        localizeString = @"The '\\g' escape sequence must be followed by a non-zero number, or a braced name or number, e.g. '{name}' or '{0123}'."; break;
    case RKCompileErrorRelativeSubpatternNumberMustNotBeZero:       localizeString = @"The relative subpattern reference parameter to '(?+' , '(?-' , '(?(+', or '(?(-' must be followed by a non-zero number."; break;
    default:                                                        returnString   = RKLocalizedFormatFromTable(@"Unknown error.  Code #%d.", @"pcre", errorCode); break;
  }

  if(localizeString != NULL) { returnString = RKLocalizedStringFromTable(localizeString, @"pcre"); }
  return(returnString);
}
