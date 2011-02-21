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

/*!
 @header   RegexKitTypes
 @abstract Defines constants and types used by the RegexKit.framework
*/

@class NSString;

/*!
 @toc   Constants
 @group Constants
 @group Error Domains
 @group Error Keys in User Info Dictionaries
 @group Exceptions
 @group Preprocessor Macros
 @group Regular Expression Libraries
*/

// Defined in RKRegex.m  Constants added here MUST be included in 'exports_list' to be visible!
/*!
 @const RKRegexSyntaxErrorException
 @tocgroup   Constants Exceptions
 @abstract   Name of the exception that occurs when the regular expression to be compiled with the given options has an error.
 @discussion See @link initWithRegexString:options: initWithRegexString:options: @/link for information regarding the information returned in the <span class="argument">userInfo</span> dictionary.
*/
extern NSString * const RKRegexSyntaxErrorException;

/*!
 @const RKRegexUnsupportedException
 @tocgroup   Constants Exceptions
 @abstract   Name of the exception that occurs when an unsupported feature or option is used.
*/
extern NSString * const RKRegexUnsupportedException;

/*!
@const RKRegexCaptureReferenceException
 @tocgroup   Constants Exceptions
 @abstract   Name of the exception that occurs when a capture reference (ie, <span class="regex">$1</span>) has an error.
*/
extern NSString * const RKRegexCaptureReferenceException;

/*!
@const RKRegexPCRELibrary
 @tocgroup   Constants Regular Expression Libraries
 @abstract   The PCRE regular expression pattern matching library.
*/
extern NSString * const RKRegexPCRELibrary;

/*!
@const RKRegexPCRELibraryErrorDomain
 @tocgroup   Constants Error Domains
 @abstract   PCRE Library errors.
*/
extern NSString * const RKRegexPCRELibraryErrorDomain;
/*!
@const RKRegexErrorDomain
 @tocgroup   Constants Error Domains
 @abstract   RegexKit Framework errors.
*/
extern NSString * const RKRegexErrorDomain;

/*!
@const RKRegexLibraryErrorKey
 @tocgroup   Constants Error Keys in User Info Dictionaries
 @abstract   The corresponding value is the regular expression library that caused the error.
*/
extern NSString * const RKRegexLibraryErrorKey;
/*!
@const RKRegexLibraryErrorStringErrorKey
 @tocgroup   Constants Error Keys in User Info Dictionaries
 @abstract   The corresponding value is the error string provided by the regular expression library that caused the error.
*/
extern NSString * const RKRegexLibraryErrorStringErrorKey;

/*!
@const RKRegexStringErrorKey
 @tocgroup   Constants Error Keys in User Info Dictionaries
 @abstract   The corresponding value is the regular expression that caused the error.
*/
extern NSString * const RKRegexStringErrorKey;
/*!
@const RKRegexStringErrorRangeErrorKey
 @tocgroup   Constants Error Keys in User Info Dictionaries
 @abstract   The corresponding value is a @link NSValue NSValue @/link with the @link NSRange NSRange @/link of @link RKRegexStringErrorKey RKRegexStringErrorKey @/link where the error occurred.
*/
extern NSString * const RKRegexStringErrorRangeErrorKey;
/*!
@const RKAttributedRegexStringErrorKey
 @tocgroup   Constants Error Keys in User Info Dictionaries
 @abstract   The corresponding value is a @link NSAttributedString NSAttributedString @/link that contains the regular expression that caused the error with attributes highlightling the location of the error.
*/
extern NSString * const RKAttributedRegexStringErrorKey;

/*!
@const RKAbreviatedRegexStringErrorKey
 @tocgroup   Constants Error Keys in User Info Dictionaries
 @abstract   The corresponding value is a truncated version of the regular expression that caused the error which is composed of a small number of characters to the left and to the right of the position that caused the error.  Intended for errors displayed to the user in which there is only a limited amount of space available or the display of a lengthy regular expression may be inappropriate.
*/
extern NSString * const RKAbreviatedRegexStringErrorKey;
/*!
@const RKAbreviatedRegexStringErrorRangeErrorKey
 @tocgroup   Constants Error Keys in User Info Dictionaries
 @abstract   The corresponding value is a @link NSValue NSValue @/link of the @link NSRange NSRange @/link of the character in @link RKAbreviatedRegexStringErrorKey RKAbreviatedRegexStringErrorKey @/link that caused the error.
*/
extern NSString * const RKAbreviatedRegexStringErrorRangeErrorKey;
/*!
@const RKAbreviatedAttributedRegexStringErrorKey
 @tocgroup   Constants Error Keys in User Info Dictionaries
 @abstract   The corresponding value is a @link NSAttributedString NSAttributedString @/link that contains the string from @link RKAbreviatedRegexStringErrorKey RKAbreviatedRegexStringErrorKey @/link with attributes highlightling the location of the error.  Intended for errors displayed to the user in which there is only a limited amount of space available or the display of a lengthy regular expression may be inappropriate.
*/
extern NSString * const RKAbreviatedAttributedRegexStringErrorKey;

/*!
@const RKCompileOptionErrorKey
 @tocgroup   Constants Error Keys in User Info Dictionaries
 @abstract   The corresponding value is a @link NSNumber NSNumber @/link containing the @link RKCompileOption RKCompileOption @/link for the regular expression that cause the error.
*/
extern NSString * const RKCompileOptionErrorKey;
/*!
@const RKCompileOptionArrayErrorKey
 @tocgroup   Constants Error Keys in User Info Dictionaries
 @abstract   The corresponding value is a @link NSArray NSArray @/link of @link NSString NSString @/link objects representing the @link RKCompileOption RKCompileOption @/link bits for the regular expression that cause the error.
*/
extern NSString * const RKCompileOptionArrayErrorKey;
/*!
@const RKCompileOptionArrayStringErrorKey
 @tocgroup   Constants Error Keys in User Info Dictionaries
 @abstract   The corresponding value is a @link NSString NSString @/link representation of the @link RKCompileOption RKCompileOption @/link bits joined together with the C bitwise OR operator for the regular expression that cause the error.
*/
extern NSString * const RKCompileOptionArrayStringErrorKey;

/*!
@const RKCompileErrorCodeErrorKey
 @tocgroup   Constants Error Keys in User Info Dictionaries
 @abstract   The corresponding value is a @link NSNumber NSNumber @/link of the @link RKCompileErrorCode RKCompileErrorCode @/link for the regular expression that caused the error.
*/
extern NSString * const RKCompileErrorCodeErrorKey;
/*!
@const RKCompileErrorCodeStringErrorKey
 @tocgroup   Constants Error Keys in User Info Dictionaries
 @abstract   The corresponding value is a @link NSString NSString @/link representation of the @link RKCompileErrorCode RKCompileErrorCode @/link for the regular expression that caused the error.
*/
extern NSString * const RKCompileErrorCodeStringErrorKey;

/*!
@const RKArrayIndexErrorKey
 @tocgroup   Constants Error Keys in User Info Dictionaries
 @abstract   The corresponding value is a @link NSNumber NSNumber @/link containing the array index for the regular expression that caused the error.  This error key is only set by the sorted regex collection methods.
*/
extern NSString * const RKArrayIndexErrorKey;
/*!
@const RKObjectErrorKey
 @tocgroup   Constants Error Keys in User Info Dictionaries
 @abstract   The corresponding value is the regular expression object from the collection that caused the error.  This error key is only set by the sorted regex collection methods.
*/
extern NSString * const RKObjectErrorKey;
/*!
@const RKCollectionErrorKey
 @tocgroup   Constants Error Keys in User Info Dictionaries
 @abstract   The corresponding value is the collection that contains the regular expression that caused the error.  This error key is only set by the sorted regex collection methods.
*/
extern NSString * const RKCollectionErrorKey;

/*!
 @toc DataTypes
*/

/*!
@typedef RKMatchErrorCode
 @abstract <p>Error codes that are returned by @link getRanges:withCharacters:length:inRange:options: getRanges:withCharacters:length:inRange:options:@/link.</p>
 <div class="box note marginTopSpacer marginBottomSpacer"><div class="table"><div class="row"><div class="label cell">Note:</div><div class="message cell">All <span class="code">RKMatchErrorCode</span> error codes are &lt; 0.</div></div></div></div>
 @constant RKMatchErrorNoError No error.
 @constant RKMatchErrorNoMatch The subject string did not match the regular expression.
 @constant RKMatchErrorNull This error is never returned by @link getRanges:withCharacters:length:inRange:options: getRanges:withCharacters:length:inRange:options:@/link.
 @constant RKMatchErrorBadOption An unrecognized bit was set in the @link RKMatchOption RKMatchOption @/link <span class="argument">options</span> argument.
 @constant RKMatchErrorBadMagic <a href="pcre/index.html" class="section-link">PCRE</a> stores a 4-byte "magic number" at the start of the compiled code, to catch the case when it is passed an invalid pointer and to detect when a pattern that was compiled in an environment of one endianness is run in an environment with the other endianness. This is the error that <a href="pcre/index.html" class="section-link">PCRE</a> gives when the magic number is not present.
 @constant RKMatchErrorUnknownOpcode While running the pattern match, an unknown item was encountered in the compiled pattern. This error could be caused by a bug in <a href="pcre/index.html" class="section-link">PCRE</a> or by overwriting of the compiled pattern.
 @constant RKMatchErrorNoMemory If a pattern contains back references and the internal matching buffers used by @link getRanges:withCharacters:length:inRange:options: getRanges:withCharacters:length:inRange:options: @/link are not big enough to hold the referenced substrings, then the <a href="pcre/index.html" class="section-link">PCRE</a> library will allocate a block of memory at the start of matching to use for this purpose.  If the <a href="pcre/index.html" class="section-link">PCRE</a> library is unable to allocate the additional memory, this error is returned.
 @constant RKMatchErrorNoSubstring This error is never returned by @link getRanges:withCharacters:length:inRange:options: getRanges:withCharacters:length:inRange:options:@/link.
 @constant RKMatchErrorMatchLimit The internal backtracking limit was reached.
 @constant RKMatchErrorCallout <p>This error is never generated by @link getRanges:withCharacters:length:inRange:options: getRanges:withCharacters:length:inRange:options: @/link itself. It is provided for use by callout functions that want to yield a distinctive error code. See the <a href="pcre/pcrecallout.html" class="section-link">PCRE Callouts</a> documentation for details.</p>
 <div class="box important marginTopSpacer marginBottomSpacer"><div class="table"><div class="row"><div class="label cell">Important:</div><div class="message cell">Use of callouts are unsupported and will raise a @link RKRegexUnsupportedException RKRegexUnsupportedException @/link if used.</div></div></div></div>
 @constant RKMatchErrorBadUTF8 A string that contains an invalid UTF-8 byte sequence was passed as a subject.
 @constant RKMatchErrorBadUTF8Offset The UTF-8 byte sequence that was passed as a subject was valid, but the value of <span class="argument">searchRange.location</span> did not point to the beginning of a UTF-8 character.
 @constant RKMatchErrorPartial The subject string did not match, but it did match partially. See the <a href="pcre/pcrepartial.html" class="section-link">Partial Matching in PCRE</a> documentation for details.
 @constant RKMatchErrorBadPartial The @link RKMatchPartial RKMatchPartial @/link option was used with a compiled pattern containing items that are not supported for partial matching. See the <a href="pcre/pcrepartial.html" class="section-link">Partial Matching in PCRE</a> documentation for details.
 @constant RKMatchErrorInternal An unexpected internal error has occurred. This error could be caused by a bug in <a href="pcre/index.html" class="section-link">PCRE</a> or by overwriting of the compiled pattern.
 @constant RKMatchErrorBadCount This error is never returned by @link getRanges:withCharacters:length:inRange:options: getRanges:withCharacters:length:inRange:options:@/link.
 @constant RKMatchErrorRecursionLimit The internal recursion limit was reached.
 @constant RKMatchErrorNullWorkSpaceLimit When a group that can match an empty substring is repeated with an unbounded upper limit, the subject position at the start of the group must be remembered, so that a test for an empty string can be made when the end of the group is reached. Some workspace is required for this; if it runs out, this error is given.
 @constant RKMatchErrorBadNewline An invalid combination of @link RKMatchNewlineMask RKMatchNewlineMask @/link options was given.
*/

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

/*!
@typedef RKCompileErrorCode
 @abstract The error reported by the <a href="pcre/index.html" class="section-link">PCRE</a> library when attempting to compile a regular expression.
 @constant RKCompileErrorNoError No error.
 @constant RKCompileErrorEscapeAtEndOfPattern <span class="regex">&#92;</span> at end of pattern.
 @constant RKCompileErrorByteEscapeAtEndOfPattern <span class="regex">&#92;c</span> at end of pattern.
 @constant RKCompileErrorUnrecognizedCharacterFollowingEscape Unrecognized character follows <span class="regex">&#92;</span>.
 @constant RKCompileErrorNumbersOutOfOrder Numbers out of order in <span class="regex">&#123;&#125;</span> quantifier.
 @constant RKCompileErrorNumbersToBig Number too big in <span class="regex">&#123;&#125;</span> quantifier.
 @constant RKCompileErrorMissingTerminatorForCharacterClass Missing terminating <span class="regex">&#93;</span> for character class.
 @constant RKCompileErrorInvalidEscapeInCharacterClass Invalid escape sequence in character class.
 @constant RKCompileErrorRangeOutOfOrderInCharacterClass Range out of order in character class.
 @constant RKCompileErrorNothingToRepeat Nothing to repeat.
 @constant RKCompileErrorInternalErrorUnexpectedRepeat Internal error, unexpected repeat.
 @constant RKCompileErrorUnrecognizedCharacterAfterOption Unrecognized character after <span class="regex">&#40;&#63;</span>.
 @constant RKCompileErrorPOSIXNamedClassOutsideOfClass POSIX named classes are supported only within a class.
 @constant RKCompileErrorMissingParentheses Missing <span class="regex">&#41;</span>.
 @constant RKCompileErrorReferenceToNonExistentSubpattern Reference to non-existent subpattern.
 @constant RKCompileErrorErrorOffsetPassedAsNull Internal error, <span class="code">erroffset</span> passed as <span class="code">NULL</span>.
 @constant RKCompileErrorUnknownOptionBits Unknown @link RKCompileOption RKCompileOption @/link option bit&#40;s&#41; set.
 @constant RKCompileErrorMissingParenthesesAfterComment Missing <span class="regex">&#41;</span> after comment.
 @constant RKCompileErrorRegexTooLarge Regular expression too large.
 @constant RKCompileErrorNoMemory Memory allocation failure.
 @constant RKCompileErrorUnmatchedParentheses Unmatched parentheses.
 @constant RKCompileErrorInternalCodeOverflow Internal error, code overflow.
 @constant RKCompileErrorUnrecognizedCharacterAfterNamedSubppatern Unrecognized character after <span class="regex">&#40;&#63;&lt;</span>.
 @constant RKCompileErrorLookbehindAssertionNotFixedLength Lookbehind assertion is not fixed length.
 @constant RKCompileErrorMalformedNameOrNumberAfterSubpattern Malformed number or name after <span class="regex">&#40;&#63;&#40;</span>.
 @constant RKCompileErrorConditionalGroupContainsMoreThanTwoBranches Conditional group contains more than two branches.
 @constant RKCompileErrorAssertionExpectedAfterCondition Assertion expected after <span class="regex">&#40;&#63;&#40;</span>.
 @constant RKCompileErrorMissingEndParentheses <span class="regex">&#40;&#63;R</span> or <span class="regex">&#40;&#63;digits</span> must be followed by <span class="regex">&#41;</span>.
 @constant RKCompileErrorUnknownPOSIXClassName Unknown POSIX class name.
 @constant RKCompileErrorPOSIXCollatingNotSupported POSIX collating elements are not supported.
 @constant RKCompileErrorMissingUTF8Support The <a href="pcre/index.html" class="section-link">PCRE</a> library was not built with UTF-8 support. See @link RKBuildConfigUTF8 RKBuildConfigUTF8@/link.
 @constant RKCompileErrorHexCharacterValueTooLarge Character value in <span class="regex">&#92;x&#123;...&#125;</span> sequence is too large.
 @constant RKCompileErrorInvalidCondition Invalid condition <span class="regex">&#40;&#63;&#40;0&#41;</span>.
 @constant RKCompileErrorNotAllowedInLookbehindAssertion <span class="regex">&#92;C</span> not allowed in lookbehind assertion.
 @constant RKCompileErrorNotSupported <a href="pcre/index.html" class="section-link">PCRE</a> does not support <span class="regex">&#92;L</span>, <span class="regex">&#92;l</span>, <span class="regex">&#92;N</span>, <span class="regex">&#92;U</span>, or <span class="regex">&#92;u</span>.
 @constant RKCompileErrorCalloutExceedsMaximumAllowed Number after <span class="regex">&#40;&#63;C</span> is &gt; 255.
 @constant RKCompileErrorMissingParenthesesAfterCallout closing <span class="regex">&#41;</span> for <span class="regex">&#40;&#63;C</span> expected.
 @constant RKCompileErrorRecursiveInfinitLoop Recursive call could loop indefinitely.
 @constant RKCompileErrorUnrecognizedCharacterAfterNamedPattern Unrecognized character after <span class="regex">&#40;&#63;P</span>.
 @constant RKCompileErrorSubpatternNameMissingTerminator Syntax error in subpattern name &#40;missing terminator&#41;.
 @constant RKCompileErrorDuplicateSubpatternNames Two named subpatterns have the same name. See @link RKCompileDupNames RKCompileDupNames@/link.
 @constant RKCompileErrorInvalidUTF8String Invalid UTF-8 string.
 @constant RKCompileErrorMissingUnicodeSupport The <a href="pcre/index.html" class="section-link">PCRE</a> library was not built with Unicode support. <span class="regex">&#92;P</span>, <span class="regex">&#92;p</span>, and <span class="regex">&#92;X</span> are invalid. See @link RKBuildConfigUnicodeProperties RKBuildConfigUnicodeProperties@/link.
 @constant RKCompileErrorMalformedUnicodeProperty Malformed <span class="regex">&#92;P</span> or <span class="regex">&#92;p</span> sequence.
 @constant RKCompileErrorUnknownPropertyAfterUnicodeCharacter Unknown property name after <span class="regex">&#92;P</span> or <span class="regex">&#92;p</span>.
 @constant RKCompileErrorSubpatternNameTooLong Subpattern name is too long &#40;maximum 32 characters&#41;.
 @constant RKCompileErrorTooManySubpatterns Too many named subpatterns &#40;maximum 10,000&#41;.
 @constant RKCompileErrorRepeatedSubpatternTooLong Repeated subpattern is too long.
 @constant RKCompileErrorIllegalOctalValueOutsideUTF8 Octal value is greater than <span class="regex">&#92;377</span> &#40;not in UTF-8 mode&#41;.
 @constant RKCompileErrorInternalOverranCompilingWorkspace Internal error, overran compiling workspace.
 @constant RKCompileErrorInternalReferencedSubpatternNotFound Internal error, previously-checked referenced subpattern not found.
 @constant RKCompileErrorDEFINEGroupContainsMoreThanOneBranch <span class="regex">DEFINE</span> group contains more than one branch.
 @constant RKCompileErrorRepeatingDEFINEGroupNotAllowed Repeating a <span class="regex">DEFINE</span> group is not allowed.
 @constant RKCompileErrorInconsistentNewlineOptions Inconsistent @link RKCompileNewlineMask RKCompileNewlineMask @/link options.
 @constant RKCompileErrorReferenceMustBeNonZeroNumberOrBraced <span class="regex">\g</span> must be followed by a non-zero number or a braced name or number (ie, <span class="regex">{name}</span> or <span class="regex">{0123}</span>).
 @constant RKCompileErrorRelativeSubpatternNumberMustNotBeZero The relative subpattern reference parameter to <span class="regex">(?+</span> , <span class="regex">(?-</span> , <span class="regex">(?(+</span> , or <span class="regex">(?(-</span> must be followed by a non-zero number.
*/

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


/*!
@typedef RKMatchOption
 @abstract A collection of bitmask options that can be combined together and passed via the <span class="argument">options</span> argument of @link getRanges:withCharacters:length:inRange:options: getRanges:withCharacters:length:inRange:options: @/link or one of the other @link RKRegex RKRegex @/link matching methods.
 @constant RKMatchNoOptions No specific options
 @constant RKMatchAnchored The @link RKMatchAnchored RKMatchAnchored @/link option limits @link getRanges:withCharacters:length:inRange:options: getRanges:withCharacters:length:inRange:options: @/link to matching at the first matching position. If the regular expression was compiled with @link RKCompileAnchored RKCompileAnchored @/link, or turned out to be anchored by virtue of its contents, it cannot be made unanchored at matching time.
 @constant RKMatchNotBeginningOfLine This option specifies that first character of the subject string is not the beginning of a line, so the <span class="regex-textual">circumflex</span> metacharacter should not match before it. Setting this without @link RKCompileMultiline RKCompileMultiline @/link (at compile time) causes <span class="regex-textual">circumflex</span> never to match. This option affects only the behavior of the <span class="regex-textual">circumflex</span> metacharacter. It does not affect <span class="regex">&#92;A</span>.
 @constant RKMatchNotEndOfLine This option specifies that the end of the subject string is not the end of a line, so the <span class="regex-textual">dollar</span> metacharacter should not match it nor (except in @link RKCompileMultiline RKCompileMultiline @/link mode) a <span class="regex-textual">newline</span> immediately before it. Setting this without @link RKCompileMultiline RKCompileMultiline @/link (at compile time) causes <span class="regex-textual">dollar</span> never to match. This option affects only the behavior of the <span class="regex-textual">dollar</span> metacharacter. It does not affect <span class="regex">&#92;Z</span> or <span class="regex">&#92;z</span>.
 @constant RKMatchNotEmpty <p>An empty string is not considered to be a valid match if this option is set. If there are alternatives in the regular expression, they are tried. If all the alternatives match the empty string, the entire match fails. For example, if the regular expression</p>
 
 <p><span class="regex">a&#63;b&#63;</span></p>
 
 <p>is applied to a string not beginning with "a" or "b", it matches the empty string at the start of the subject. With @link RKMatchNotEmpty RKMatchNotEmpty @/link set, this match is not valid, so <a href="pcre/index.html" class="section-link">PCRE</a> searches further into the string for occurrences of "a" or "b".</p>
 
 <p>Perl has no direct equivalent of @link RKMatchNotEmpty RKMatchNotEmpty @/link, but it does make a special case of a pattern match of the empty string within its <span class="code">split()</span> function, and when using the <span class="regex">/g</span> modifier. It is possible to emulate Perl's behavior after matching a null string by first trying the match again at the same offset with @link RKMatchNotEmpty RKMatchNotEmpty @/link and @link RKMatchAnchored RKMatchAnchored @/link, and then if that fails by advancing the starting offset (see below) and trying an ordinary match again. There is some code that demonstrates how to do this in the pcredemo.c sample program.</p>
 @constant RKMatchNoUTF8Check <p>When @link RKCompileUTF8 RKCompileUTF8 @/link is set at compile time, the validity of the subject as a UTF-8 string is automatically checked when @link getRanges:withCharacters:length:inRange:options: getRanges:withCharacters:length:inRange:options: @/link is subsequently called. The value of <i>searchRange</i> location is also checked to ensure that it points to the start of a UTF-8 character. If an invalid UTF-8 sequence of bytes is found, @link getRanges:withCharacters:length:inRange:options: getRanges:withCharacters:length:inRange:options: @/link returns the error @link RKMatchErrorBadUTF8Offset RKMatchErrorBadUTF8Offset @/link. If <i>searchRange</i> location contains an invalid value, @link RKMatchErrorBadUTF8Offset RKMatchErrorBadUTF8Offset @/link is returned.</p>
 
 <p>If you already know that your subject is valid, and you want to skip these checks for performance reasons, you can set the @link RKMatchNoUTF8Check RKMatchNoUTF8Check @/link option when calling @link getRanges:withCharacters:length:inRange:options: getRanges:withCharacters:length:inRange:options: @/link. You might want to do this for the second and subsequent calls to @link getRanges:withCharacters:length:inRange:options: getRanges:withCharacters:length:inRange:options: @/link if you are making repeated calls to find all the matches in a single subject string. However, you should be sure that the value of <span class="argument">searchRange</span> location points to the start of a UTF-8 character. When @link RKMatchNoUTF8Check RKMatchNoUTF8Check @/link is set, the effect of passing an invalid UTF-8 string as a <span class="argument">charactersBuffer</span>, or a value of <span class="argument">searchRange</span> location that does not point to the start of a UTF-8 character, is undefined. Your program may crash.</p>
 @constant RKMatchPartial This option turns on the partial matching feature. If the subject string fails to match the regular expression, but at some point during the matching process the end of the subject was reached (that is, the subject partially matches the pattern and the failure to match occurred only because there were not enough subject characters), @link getRanges:withCharacters:length:inRange:options: getRanges:withCharacters:length:inRange:options: @/link returns @link RKMatchErrorPartial RKMatchErrorPartial @/link instead of @link RKMatchErrorNoMatch RKMatchErrorNoMatch @/link. When @link RKMatchPartial RKMatchPartial @/link is used, there are RK_C99(restrict)ions on what may appear in the pattern. These are discussed in <a href="pcre/pcrepartial.html" class="section-link">Partial Matching in PCRE</a>.
 @constant RKMatchNewlineDefault The default newline sequence defined when the <a href="pcre/index.html" class="section-link">PCRE</a> library was built.
 @constant RKMatchNewlineCR The character 13 (<i>carriage return</i>, <b>CR</b>) is used as the end of line character during the match.
 @constant RKMatchNewlineLF The character 10 (<i>linefeed</i>, <b>LF</b>) is used as the end of line character during the match.
 @constant RKMatchNewlineCRLF The character sequence 13 (<i>carriage return</i>, <b>CR</b>), 10 (<i>linefeed</i>, <b>LF</b>) is used as the end of line character sequence during the match.
 @constant RKMatchNewlineAnyCRLF @link RKMatchNewlineCR RKMatchNewlineCR@/link, @link RKMatchNewlineLF RKMatchNewlineLF@/link, and @link RKMatchNewlineCRLF RKMatchNewlineCRLF@/link will be used as the end of line character sequence during the match.
 @constant RKMatchNewlineAny Any valid Unicode newline sequence is used as the end of line during the match.
 @constant RKMatchNewlineMask A bitmask to extract only the newline setting.
 @constant RKMatchBackslashRAnyCRLR The escape sequence <span class="regex">\R</span> in the compiled regular expression will match only <b>CR</b>, <b>LF</b>, or <b>CRLF</b>, temporarily over-riding the setting used when the regular expression was compiled.  This option is mutually exclusive of @link RKMatchBackslashRUnicode RKMatchBackslashRUnicode@/link.
 @constant RKMatchBackslashRUnicode The escape sequence <span class="regex">\R</span> in the compiled regular expression will match any Unicode line ending sequence, temporarily over-riding the setting used when the regular expression was compiled.  This option is mutually exclusive of @link RKMatchBackslashRAnyCRLR RKMatchBackslashRAnyCRLR@/link.
*/


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


/*!
@typedef RKCompileOption
 @abstract A collection of bitmask options that can be combined together and passed via the <span class="argument">options</span> argument of @link regexWithRegexString:options: regexWithRegexString:options: @/link or @link initWithRegexString:options: initWithRegexString:options:@/link.
 @constant RKCompileNoOptions No specific options.
 @constant RKCompileCaseless If this bit is set, letters in the pattern match both upper and lower case letters. It is equivalent to Perl's <span class="regex">/i</span> option, and it can be changed within a pattern by a <span class="regex">&#63;i</span> option setting. In UTF-8 mode, <a href="pcre/index.html" class="section-link">PCRE</a> always understands the concept of case for characters whose values are less than 128, so caseless matching is always possible. For characters with higher values, the concept of case is supported if the <a href="pcre/index.html" class="section-link">PCRE</a> library is built with Unicode property support, but not otherwise. If you want to use caseless matching for characters 128 and above, you must ensure that the <a href="pcre/index.html" class="section-link">PCRE</a> library is built with Unicode property support as well as with UTF-8 support. See @link RKBuildConfig RKBuildConfig@/link.
 @constant RKCompileMultiline <p>By default, <a href="pcre/index.html" class="section-link">PCRE</a> treats the subject string as consisting of a single line of characters (even if it actually contains <span class="regex-textual">newlines</span>). The <span class="regex-textual">start of line</span> metacharacter <span class="regex">&#94;</span> matches only at the start of the string, while the <span class="regex-textual">end of line</span> metacharacter <span class="regex">&#36;</span> matches only at the end of the string, or before a terminating <span class="regex-textual">newline</span> (unless @link RKCompileDollarEndOnly RKCompileDollarEndOnly @/link is set). This is the same as Perl.</p>
 
 <p>When @link RKCompileMultiline RKCompileMultiline @/link is set, the <span class="regex-textual">start of line</span> and <span class="regex-textual">end of line</span> constructs match immediately following or immediately before internal <span class="regex-textual">newlines</span> in the subject string, respectively, as well as at the very start and end. This is equivalent to Perl's <span class="regex">/m</span> option, and it can be changed within a pattern by a <span class="regex">&#63;m</span> option setting. If there are no <span class="regex-textual">newlines</span> in a subject string, or no occurrences of <span class="regex">&#94;</span> or <span class="regex">&#36;</span> in a pattern, setting @link RKCompileMultiline RKCompileMultiline @/link has no effect.</p>
 @constant RKCompileDotAll If this bit is set, a <span class="regex-textual">dot</span> metacharacter in the pattern matches all characters, including those that indicate <span class="regex-textual">newline</span>. Without it, a <span class="regex-textual">dot</span> does not match when the current position is at a <span class="regex-textual">newline</span>. This option is equivalent to Perl's <span class="regex">/s</span> option, and it can be changed within a pattern by a <span class="regex">&#63;s</span> option setting. A negative class such as <span class="regex">&#91;&#94;a&#93;</span> always matches <span class="regex-textual">newline</span> characters, independent of the setting of this option.
 @constant RKCompileExtended <p>If this bit is set, <span class="regex-textual">whitespace</span> data characters in the pattern are totally ignored except when escaped or inside a character class. <span class="regex-textual">Whitespace</span> does not include the <b>VT</b> character (code 11). In addition, characters between an unescaped <span class="regex">&#35;</span> outside a character class and the next <span class="regex-textual">newline</span>, inclusive, are also ignored. This is equivalent to Perl's <span class="regex">/x</span> option, and it can be changed within a pattern by a <span class="regex">&#63;x</span> option setting.</p>
 
 <p>This option makes it possible to include comments inside complicated patterns. Note, however, that this applies only to data characters. <span class="regex-textual">Whitespace</span> characters may never appear within special character sequences in a pattern, for example within the sequence <span class="regex">&#40;&#63;&#40;</span> which introduces a conditional subpattern.</p>
 @constant RKCompileAnchored If this bit is set, the pattern is forced to be "anchored", that is, it is constrained to match only at the first matching point in the string that is being searched (the "subject string"). This effect can also be achieved by appropriate constructs in the pattern itself, which is the only way to do it in Perl.
 @constant RKCompileDollarEndOnly If this bit is set, a <span class="regex-textual">dollar</span> metacharacter in the pattern matches only at the end of the subject string. Without this option, a <span class="regex-textual">dollar</span> also matches immediately before a <span class="regex-textual">newline</span> at the end of the string (but not before any other <span class="regex-textual">newlines</span>). The @link RKCompileDollarEndOnly RKCompileDollarEndOnly @/link option is ignored if @link RKCompileMultiline RKCompileMultiline @/link is set. There is no equivalent to this option in Perl, and no way to set it within a pattern.
 @constant RKCompileExtra This option was invented in order to turn on additional functionality of <a href="pcre/index.html" class="section-link">PCRE</a> that is incompatible with Perl, but it is currently of very little use. When set, any backslash in a pattern that is followed by a letter that has no special meaning causes an error, thus reserving these combinations for future expansion. By default, as in Perl, a backslash followed by a letter with no special meaning is treated as a literal. (Perl can, however, be persuaded to give a warning for this.) There are at present no other features controlled by this option. It can also be set by a <span class="regex">&#63;X</span> option setting within a pattern.
 @constant RKCompileUngreedy This option inverts the "greediness" of the quantifiers so that they are not greedy by default, but become greedy if followed by <span class="regex">&#63;</span>. It is not compatible with Perl. It can also be set by a <span class="regex">&#63;U</span> option setting within the pattern.
 @constant RKCompileUTF8 This option causes <a href="pcre/index.html" class="section-link">PCRE</a> to regard both the pattern and the subject as strings of UTF-8 characters instead of single-byte character strings. However, it is available only when the <a href="pcre/index.html" class="section-link">PCRE</a> library is built to include UTF-8 support. If not, the use of this option returns an error. See <a href="pcre/pcre.html#utf8support" class="section-link">UTF-8 and Unicode Property Support</a> for more information.
 @constant RKCompileNoAutoCapture If this option is set, it disables the use of numbered capturing parentheses in the pattern. Any opening parenthesis that is not followed by <span class="regex">&#63;</span> behaves as if it were followed by <span class="regex">&#63;&#58;</span> but named parentheses can still be used for capturing (and they acquire numbers in the usual way). There is no equivalent of this option in Perl.
 @constant RKCompileNoUTF8Check When @link RKCompileUTF8 RKCompileUTF8 @/link is set, the validity of the pattern as a UTF-8 string is automatically checked. If an invalid UTF-8 sequence of bytes is found, @link initWithRegexString:options: initWithRegexString:options: @/link returns an error. If you already know that your pattern is valid, and you want to skip this check for performance reasons, you can set the @link RKCompileNoUTF8Check RKCompileNoUTF8Check @/link option. When it is set, the effect of passing an invalid UTF-8 string as a pattern is undefined. It may cause your program to crash. Note that @link RKMatchNoUTF8Check RKMatchNoUTF8Check @/link can also be passed to @link getRanges:withCharacters:length:inRange:options: getRanges:withCharacters:length:inRange:options:@/link to suppress the UTF-8 validity checking of subject strings.
 @constant RKCompileAutoCallout <p>If this bit is set, @link initWithRegexString:options: initWithRegexString:options: @/link automatically inserts callout items, all with number 255, before each pattern item. For discussion of the callout facility, see the <a href="pcre/pcrecallout.html" class="section-link">PCRE Callouts</a> documentation.</p>
 <div class="box important marginTopSpacer marginBottomSpacer"><div class="table"><div class="row"><div class="label cell">Important:</div><div class="message cell">Use of callouts are unsupported and will raise a @link RKRegexUnsupportedException RKRegexUnsupportedException @/link if used.</div></div></div></div>
 @constant RKCompileFirstLine If this option is set, an unanchored pattern is required to match before or at the first <span class="regex-textual">newline</span> in the subject string, though the matched text may continue over the <span class="regex-textual">newline</span>.
 @constant RKCompileDupNames If this bit is set, names used to identify capturing subpatterns need not be unique. This can be helpful for certain types of regular expressions when it is known that only one instance of the named subpattern can ever be matched. See <a href="pcre/pcrepattern.html#SEC12" class="section-link">Named Subpatterns</a> for more information. The option may also be set be specifying the <span class="regex">(?J)</span> option in the regular expression.
 @constant RKCompileAllOptions Contains a bitmask of all the defined options.
 @constant RKCompileUnsupported Contains a bitmask of invalid options.
 @constant RKCompileNewlineDefault The default newline sequence defined when the <a href="pcre/index.html" class="section-link">PCRE</a> library was built.
 @constant RKCompileNewlineCR The character 13 (<i>carriage return</i>, <b>CR</b>) is the default end of line character.
 @constant RKCompileNewlineLF The character 10 (<i>linefeed</i>, <b>LF</b>) is the default end of line character.
 @constant RKCompileNewlineCRLF The character sequence 13 (<i>carriage return</i>, <b>CR</b>), 10 (<i>linefeed</i>, <b>LF</b>) is the default end of line character sequence.
 @constant RKCompileNewlineAny Any valid Unicode newline sequence is the default end of line.
 @constant RKCompileNewlineAnyCRLF Any of the newline character sequences from @link RKCompileNewlineCR RKCompileNewlineCR@/link, @link RKCompileNewlineLF RKCompileNewlineLF@/link, or @link RKCompileNewlineCRLF RKCompileNewlineCRLF @/link will be used as a match for the end of line character sequence.
 @constant RKCompileNewlineMask A bitmask to extract only the newline setting.
 @constant RKCompileNewlineShift The number of bits that the newline type is shifted to the left.
 @constant RKCompileBackslashRAnyCRLR The escape sequence <span class="regex">\R</span> for the compiled regular expression will match only <b>CR</b>, <b>LF</b>, or <b>CRLF</b>.  This option is mutually exclusive of @link RKCompileBackslashRUnicode RKCompileBackslashRUnicode@/link.
 @constant RKCompileBackslashRUnicode The escape sequence <span class="regex">\R</span> for the compiled regular expression will match any Unicode line ending sequence.  This option is mutually exclusive of @link RKCompileBackslashRAnyCRLR RKCompileBackslashRAnyCRLR@/link.
*/

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

/*!
@typedef RKBuildConfig
 @abstract A bitmap of flags representing the configuration options of the <a href="pcre/index.html" class="section-link">PCRE</a> library when it was initially built.  Some options may represent default values, others may represent features that can not be altered or added at run time. If a required feature is missing then the underlying <a href="pcre/index.html" class="section-link">PCRE</a> library that @link RKRegex RKRegex @/link is linked against will have to be changed.  This will most likely require rebuilding the <a href="pcre/index.html" class="section-link">PCRE</a> library and RegexKit framework from the source with the desired configuration options.
 @constant RKBuildConfigNoOptions No build config options specified.
 @constant RKBuildConfigUTF8 Set if the <a href="pcre/index.html" class="section-link">PCRE</a> library was compiled with UTF-8 support. This feature is normally enabled for the RegexKit framework by default.  See <a href="pcre/pcrebuild.html#SEC3" class="section-link">UTF-8 Support</a> and <a href="pcre/pcre.html#SEC4" class="section-link">UTF-8 and Unicode Property Support</a> for more information.
 @constant RKBuildConfigUnicodeProperties Set if the <a href="pcre/index.html" class="section-link">PCRE</a> library was compiled with Unicode Properties support, enabling the regular expression pattern escapes <span class="regex">&#92;P</span>, <span class="regex">&#92;p</span>, and <span class="regex">&#92;X</span>. This feature is normally enabled for the RegexKit framework by default.  See <a href="pcre/pcrebuild.html#SEC4" class="section-link">Unicode Character Property Support</a> and <a href="pcre/pcre.html#SEC4" class="section-link">UTF-8 and Unicode Property Support</a> for more information.
 @constant RKBuildConfigNewlineDefault The default character sequence. See <a href="pcre/pcrebuild.html#SEC5" class="section-link">Code Value of Newline</a> for more information.
 @constant RKBuildConfigNewlineCR The character 13 (<i>carriage return</i>, <b>CR</b>) is the default end of line character. See <a href="pcre/pcrebuild.html#SEC5" class="section-link">Code Value of Newline</a> for more information.
 @constant RKBuildConfigNewlineLF The character 10 (<i>linefeed</i>, <b>LF</b>) is the default end of line character. See <a href="pcre/pcrebuild.html#SEC5" class="section-link">Code Value of Newline</a> for more information.
 @constant RKBuildConfigNewlineCRLF The character sequence 13 (<i>carriage return</i>, <b>CR</b>), 10 (<i>linefeed</i>, <b>LF</b>) is the default end of line character sequence. See <a href="pcre/pcrebuild.html#SEC5" class="section-link">Code Value of Newline</a> for more information.
 @constant RKBuildConfigNewlineAnyCRLF The default end of line character sequence is a combination of @link RKBuildConfigNewlineCR RKBuildConfigNewlineCR@/link, @link RKBuildConfigNewlineLF RKBuildConfigNewlineLF@/link, and @link RKBuildConfigNewlineCRLF RKBuildConfigNewlineCRLF@/link. See <a href="pcre/pcrebuild.html#SEC5" class="section-link">Code Value of Newline</a> for more information.
 @constant RKBuildConfigNewlineAny Any valid Unicode newline sequence is the default end of line. See <a href="pcre/pcrebuild.html#SEC5" class="section-link">Code Value of Newline</a> for more information.
 @constant RKBuildConfigNewlineMask A bitmask to extract only the newline setting. See <a href="pcre/pcrebuild.html#SEC5" class="section-link">Code Value of Newline</a> and <a href="pcre/pcreapi.html#SEC3" class="section-link">Newlines</a> for more information.
 @constant RKBuildConfigBackslashRAnyCRLR The regular expression escape sequence <span class="regex">\R</span> matches only <b>CR</b>, <b>LF</b>, or <b>CRLF</b>.
 @constant RKBuildConfigBackslashRUnicode The regular expression escape sequence <span class="regex">\R</span> matches any Unicode line ending sequence.
*/

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
