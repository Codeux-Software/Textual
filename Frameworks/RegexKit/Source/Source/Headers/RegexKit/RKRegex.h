//
//  RKRegex.h
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
  
#ifndef _REGEXKIT_RKREGEX_H_
#define _REGEXKIT_RKREGEX_H_ 1

/*!
 @header   RKRegex
 @abstract An Objective-C Framework for Regular Expressions using the PCRE Library
*/

#import <RegexKit/RegexKitDefines.h>
#import <RegexKit/RegexKitTypes.h>
#import <RegexKit/RegexKit.h>
#import <RegexKit/pcre.h>


/*!
 @class      RKRegex
 @toc        RKRegex
 @abstract   Regular Expression Pattern Matching Class
*/

@interface RKRegex : NSObject <NSCoding, NSCopying> {
  RK_STRONG_REF pcre            *_compiledPCRE;          // Pointer to pcre library type pcre.
  RK_STRONG_REF pcre_extra      *_extraPCRE;             // Pointer to pcre library type pcre_extra.

                NSString        *compiledRegexString;    // A copy of the regex string that was compiled.
                RKCompileOption  compileOption;          // The options used to compile this regex.
                RKUInteger       captureCount;           // The number of captures in the compiled regex string.
  RK_STRONG_REF char            *captureNameTable;       // Pointer to capture names structure.
                RKUInteger       captureNameTableLength; // Number of entries in the capture name structure
                RKUInteger       captureNameLength;      // The length of a capture name entry.
                NSArray         *captureNameArray;       // An array that maps capture index values to capture names.  nil if no named captures.
   
                RKInteger        referenceCountMinusOne; // Keep track of the reference count ourselves.
                RKUInteger       hash;                   // Hash value for this object.

  RK_STRONG_REF char            *compiledRegexUTF8String;
  RK_STRONG_REF char            *compiledOptionUTF8String;
}


/*!
 @toc   RKRegex
 @group PCRE Library Information
 @group Regular Expression Cache
 @group Creating Regular Expressions
 @group Instantiated Regular Expression Information
 @group Named Capture Information
 @group Matching Regular Expressions
*/


/*!
 @method     regexCache
 @tocgroup   RKRegex Regular Expression Cache
 @abstract   Returns the current regular expression cache.
 @seealso    @link RKCache RKCache @/link
*/

+ (RKCache *)regexCache;

/*!
 @method     PCREVersionString
 @tocgroup   RKRegex PCRE Library Information
 @discussion The underlying <a href="pcre/index.html"><i>PCRE</i></a> library will typically return a version string similar to <span class="code">"7.0 18-Dec-2006"</span>.
 @abstract   Returns a @link NSString NSString @/link of the <a href="pcre/index.html"><i>PCRE</i></a> library version.
 @result     Returns a @link NSString NSString @/link encapsulated copy of the characters returned by @link pcre_version pcre_version() @/link library function.
*/

+ (NSString *)PCREVersionString;
/*!
 @method     PCREMajorVersion
 @tocgroup   RKRegex PCRE Library Information
 @abstract   Returns the <a href="pcre/index.html"><i>PCRE</i></a> library major version.
 @result     Returns an @link RKUInteger RKUInteger @/link of the major version in @link PCREVersionString PCREVersionString @/link.
*/
+ (int32_t)PCREMajorVersion;
/*!
 @method     PCREMinorVersion
 @tocgroup   RKRegex PCRE Library Information
 @abstract   Returns the <a href="pcre/index.html"><i>PCRE</i></a> library minor version.
 @result     Returns an @link RKUInteger RKUInteger @/link of the minor version in @link PCREVersionString PCREVersionString @/link.
*/
+ (int32_t)PCREMinorVersion;
/*!
 @method     PCREBuildConfig
 @tocgroup   RKRegex PCRE Library Information
 @abstract   Returns a @link RKBuildConfig RKBuildConfig @/link mask representing features and configuration settings of the <a href="pcre/index.html"><i>PCRE</i></a> library when it was initially built.
 @result     A mask of @link RKBuildConfig RKBuildConfig @/link flags combined with the C bitwise OR operator representing features or defaults of the <a href="pcre/index.html"><i>PCRE</i></a> library that were set when the library was built.
*/
+ (RKBuildConfig)PCREBuildConfig;

/*!
 @method     isValidRegexString:options:
 @tocgroup   RKRegex Creating Regular Expressions
 @abstract   Returns a Boolean value that indicates whether <span class="argument">regexString</span> and <span class="argument">options</span> are valid.
 @discussion Invokes @link regexWithRegexString:options: regexWithRegexString:options: @/link with <span class="argument">regexString</span> and <span class="argument">options</span> within a @link @try @try @/link / @link @catch @catch @/link block.  If the result is non-<span class="code">nil</span>, then the <span class="argument">regexString</span> is considered valid and <span class="code">YES</span> is returned, otherwise <span class="code">NO</span> is returned.  Any exceptions thrown during validation will be caught by @link isValidRegexString:options: isValidRegexString:options: @/link and <span class="code">NO</span> will be returned.
 @param regexString The regular expression to check.
 @param options A mask of options specified by combining @link RKCompileOption RKCompileOption @/link flags with the C bitwise OR operator.
 @result Returns <span class="code">YES</span> if valid, <span class="code">NO</span> otherwise.
*/

+ (BOOL)isValidRegexString:(NSString * const)regexString options:(const RKCompileOption)options;

/*!
 @method    regexWithRegexString:options:
 @tocgroup   RKRegex Creating Regular Expressions
 @abstract   Convenience method for an autoreleased @link RKRegex RKRegex @/link object.
 @discussion Currently creates a regular expression using the @link RKRegexPCRELibrary RKRegexPCRELibrary @/link PCRE library.
 @result Returns an autoreleased @link RKRegex RKRegex @/link object if successful, <span class="code">nil</span> otherwise.
 @seealso @link initWithRegexString:options: - initWithRegexString:options: @/link
*/
+ (id)regexWithRegexString:(NSString * const)regexString options:(const RKCompileOption)options;

/*!
 @method    regexWithRegexString:library:options:error:
 @tocgroup   RKRegex Creating Regular Expressions
 @abstract   Convenience method for an autoreleased @link RKRegex RKRegex @/link object.
 @discussion Currently the only supported regular expression matching library is @link RKRegexPCRELibrary RKRegexPCRELibrary@/link.
 @result Returns an autoreleased @link RKRegex RKRegex @/link object if successful, <span class="code">nil</span> otherwise.
 @seealso @link initWithRegexString:library:options:error: - initWithRegexString:library:options:error: @/link
*/
+ (id)regexWithRegexString:(NSString *)regexString library:(NSString *)libraryString options:(const RKCompileOption)libraryOptions error:(NSError **)error;

/*!
 @method    initWithRegexString:options:
 @tocgroup   RKRegex Creating Regular Expressions
 @abstract   Returns a @link RKRegex RKRegex @/link object initialized with the regular expression <span class="argument">regexString</span> with @link RKCompileOption RKCompileOption @/link <span class="argument">options</span>.
 @discussion <p>Raises @link RKRegexSyntaxErrorException RKRegexSyntaxErrorException @/link if <span class="argument">regexString</span> in combination with <span class="argument">options</span> is not a valid regular expression.  The exception provides a <span class="argument">userInfo</span> dictionary containing the following keys and information:</p>
   <table class="standard" summary="RKRegexSyntaxErrorException userInfo dictionary information.">
   <caption><span class="identifier">Table 1</span> @link RKRegexSyntaxErrorException RKRegexSyntaxErrorException @/link <span class="argument">userInfo</span> dictionary information.</caption>
   <tr>
   <th>Key</th>
   <th>Object Type</th>
   <th>Description</th>
   </tr>
   <tr><td><b>regexString</b></td><td>@link NSString NSString @/link</td>
   <td>The <span class="argument">regexString</span> regular expression that caused the exception.</td></tr>
   <tr><td><b>regexStringErrorLocation</b></td><td>@link NSNumber NSNumber @/link</td>
   <td>The location of the character that caused the syntax error.</td></tr>
   <tr><td><b>regexAttributedString</b></td><td>@link NSAttributedString NSAttributedString @/link</td>
   <td>The <span class="argument">regexString</span> regular expression with a @link NSBackgroundColorAttributeName NSBackgroundColorAttributeName @/link set to [@link NSColor NSColor @/link @link NSColor/redColor redColor@/link] for the character that caused the error along with the @link NSToolTipAttributeName NSToolTipAttributeName @/link attribute (if supported) set to <b>errorString</b>.</td></tr>
   <tr><td><b>errorString</b></td><td>@link NSString NSString @/link</td>
   <td>The error string that the <a href="pcre/index.html"><i>PCRE</i></a> library returned.</td></tr>
   <tr><td><b>RKCompileOption</b></td><td>@link NSNumber NSNumber @/link</td>
   <td>The @link RKCompileOption RKCompileOption @/link that was passed with <span class="argument">regexString</span>.</td></tr>
   <tr><td><b>RKCompileOptionString</b></td><td>@link NSString NSString @/link</td>
   <td>A human readable C bitwise OR equivalent string of @link RKCompileOption RKCompileOption @/link <span class="argument">options</span>.</td></tr>
   <tr><td><b>RKCompileOptionArray</b></td><td>@link NSArray NSArray @/link</td>
   <td>The human readable equivalent of the individual C bitwise @link RKCompileOption RKCompileOption @/link <span class="argument">options</span> flags in a @link NSArray NSArray@/link.</td></tr>
   <tr><td><b>RKCompileErrorCode</b></td><td>@link NSNumber NSNumber @/link</td>
   <td>The @link RKCompileErrorCode RKCompileErrorCode @/link that the <a href="pcre/index.html"><i>PCRE</i></a> library returned.</td></tr>
   <tr><td><b>RKCompileErrorCodeString</b></td><td>@link NSString NSString @/link</td>
   <td>A human readable equivalent of the @link RKCompileErrorCode RKCompileErrorCode @/link name that the <a href="pcre/index.html"><i>PCRE</i></a> library returned.</td></tr>
   </table>
   <p>Currently creates a regular expression using the @link RKRegexPCRELibrary RKRegexPCRELibrary @/link PCRE library.</p>
 @param regexString The regular expression to compile.
   <div class="box important"><div class="table"><div class="row"><div class="label cell">Important:</div><div class="message cell">Raises a @link NSInvalidArgumentException NSInvalidArgumentException @/link if <span class="argument">regexString</span> is <span class="code">nil</span>.</div></div></div></div>
 @param options A mask of options specified by combining @link RKCompileOption RKCompileOption @/link flags with the C bitwise OR operator.
   <div class="box important"><div class="table"><div class="row"><div class="label cell">Important:</div><div class="message cell">Raises a @link RKRegexSyntaxErrorException RKRegexSyntaxErrorException @/link if <span class="argument">regexString</span> in combination with <span class="argument">options</span> is not a valid regular expression.</div></div></div></div>
 @result Returns a @link RKRegex RKRegex @/link object if successful, <span class="code">nil</span> otherwise.
*/
- (id)initWithRegexString:(NSString *)regexString options:(const RKCompileOption)options;
/*!
 @method    initWithRegexString:library:options:error:
 @tocgroup   RKRegex Creating Regular Expressions
 @abstract   Returns a @link RKRegex RKRegex @/link object initialized with the regular expression <span class="argument">regexString</span> using the regular expression pattern matching <span class="argument">library</span> with @link RKCompileOption RKCompileOption @/link <span class="argument">options</span>.
 @param regexString The regular expression to compile.
 @param library The regular expression pattern matching library to use. See <a href="Constants.html#Regular_Expression_Libraries" class="section-link">Regular Expression Libraries</a> for a list of valid constants.
 <div class="box note"><div class="table"><div class="row"><div class="label cell">Note:</div><div class="message cell">Currently the only supported regular expression matching library is the @link RKRegexPCRELibrary RKRegexPCRELibrary @/link PCRE library.</div></div></div></div>
 @param libraryOptions A mask of options specified by combining @link RKCompileOption RKCompileOption @/link flags with the C bitwise OR operator.
 @param error An <i>optional</i> parameter that if set and an error occurs, will contain a @link NSError NSError @/link object that describes the problem.  This may be set to <span class="code">NULL</span> if information about any errors is not required.
 @discussion <p>Unlike @link initWithRegexString:options: initWithRegexString:options:@/link, this method does not throw an exception on errors.  Instead, a @link NSError NSError @/link object is created and returned via the optional <span class="argument">error</span> parameter.</p>
 <div class="box important"><div class="table"><div class="row"><div class="label cell">Important:</div><div class="message cell">Exceptions are still thrown for invalid argument conditions, such as passing <span class="code">nil</span> for <span class="argument">regexString</span> or <span class="argument">library</span>.</div></div></div></div>
 @result Returns a @link RKRegex RKRegex @/link object if successful, <span class="code">nil</span> otherwise.
 @seealso @link initWithRegexString:options: - initWithRegexString:options: @/link
 @seealso @link regexWithRegexString:library:options:error: + regexWithRegexString:library:options:error: @/link
*/
- (id)initWithRegexString:(NSString *)regexString library:(NSString *)library options:(const RKCompileOption)libraryOptions error:(NSError **)error;

/*!
 @method     regexString
 @tocgroup   RKRegex Instantiated Regular Expression Information
 @abstract   Returns the regular expression used to create the receiver.
*/
- (NSString *)regexString;

/*!
 @method     compileOption
 @tocgroup   RKRegex Instantiated Regular Expression Information
 @abstract   Returns the @link RKCompileOption RKCompileOption @/link options used to create the receiver.
 @result     A mask of @link RKCompileOption RKCompileOption @/link flags combined with the C bitwise OR operator representing the options used in compiling the regular expression of the receiver.
*/
- (RKCompileOption)compileOption;

/*!
 @method     captureCount
 @tocgroup   RKRegex Instantiated Regular Expression Information
 @abstract   Returns the number of captures that the receivers regular expression contains.
 @discussion Every regular expression has at least one capture representing the entire range that the regular expression matched.  Additional subcaptures are created with <span class="regex">()</span> pairs.
 @seealso    <a href="pcre/pcrepattern.html#SEC11" class="section-link">Regular Expression Subpatterns</a>
*/

- (RKUInteger)captureCount;
/*!
 @method     captureNameArray
 @tocgroup   RKRegex Named Capture Information
 @abstract   Returns a @link NSArray NSArray @/link which maps the capture names in the receivers regular expression to their equivalent capture index values.
 @discussion <p>If the regular expression of the receiver uses named subcaptures (ie, <span class="regex">(?&lt;<b>year</b>&gt;(\d\d)?\d\d)</span> ), then for each capture name there exists a corresponding capture index.  A @link NSArray NSArray @/link is created with @link captureCount captureCount @/link elements and for every capture name the corresponding array index is set to a @link NSString NSString @/link of the capture name.  If there is no capture name for an index, a @link NSNull NSNull @/link is used instead.</p>
              <p>This method returns <span class="code">nil</span> if the receivers regular expression does not contain any named subcaptures.</p>
 @result     Returns a @link NSArray NSArray @/link which maps the capture names in the receivers regular expression to their equivalent capture index values, or <span class="code">nil</span> if the receivers regular expression does not contain any capture names.
*/
- (NSArray *)captureNameArray;
/*!
 @method     isValidCaptureName:
 @tocgroup   RKRegex Named Capture Information
 @abstract   Returns a Boolean value that indicates whether <span class="argument">captureNameString</span> is a valid capture name for the receiver.
 @param      captureNameString A @link NSString NSString @/link of the name of the desired capture index.
*/
- (BOOL)isValidCaptureName:(NSString * const)captureNameString;
/*!
 @method     captureIndexForCaptureName:
 @tocgroup   RKRegex Named Capture Information
 @abstract   Returns the capture index for <span class="argument">captureNameString</span>, or the first capture index of <span class="argument">captureNameString</span> if compiled with @link RKCompileDupNames RKCompileDupNames@/link.
 @param      captureNameString The name of the desired capture index.
 <div class="box important"><div class="table"><div class="row"><div class="label cell">Important:</div><div class="message cell">Raises a @link NSInvalidArgumentException NSInvalidArgumentException @/link if <span class="argument">captureNameString</span> is <span class="code">nil</span> or is not a valid capture name for the receivers regular expression.</div></div></div></div>
*/
- (RKUInteger)captureIndexForCaptureName:(NSString * const)captureNameString;
/*!
 @method     captureNameForCaptureIndex:
 @tocgroup   RKRegex Named Capture Information
 @abstract   Returns the capture name for the captured index.
 @param      captureIndex The capture index of the desired capture name.
 <div class="box important"><div class="table"><div class="row"><div class="label cell">Important:</div><div class="message cell">Raises a @link NSInvalidArgumentException NSInvalidArgumentException @/link if <span class="argument">captureIndex</span> is not valid for the receivers regular expression.</div></div></div></div>
 @result     Returns the capture name for <span class="argument">captureIndex</span>, otherwise <span class="code">nil</span> if <span class="argument">captureIndex</span> does not have a name associated with it.
*/
- (NSString *)captureNameForCaptureIndex:(const RKUInteger)captureIndex;
/*!
 @method     captureIndexForCaptureName:inMatchedRanges:
 @tocgroup   RKRegex Named Capture Information
 @abstract   Returns the capture index for <span class="argument">captureNameString</span> from a match operation, or the capture index of the first successful match for <span class="argument">captureNameString</span> if @link RKCompileDupNames RKCompileDupNames @/link is used and there are multiple instances of <span class="argument">captureNameString</span> in the receivers regular expression.
 @discussion <p>Used primarily when a regular expression is compiled with @link RKCompileDupNames RKCompileDupNames @/link or when the <span class="regex">(?J)</span> option has been set to determine the capture index for the first successful match in the <span class="argument">matchedRanges</span> result from @link getRanges:withCharacters:length:inRange:options: getRanges:withCharacters:length:inRange:options:@/link. If none of the multiple <span class="argument">captureNameString</span> successfully matched then @link NSNotFound NSNotFound @/link will be returned.</p>
    <p>May be used when a regular expression is not compiled with @link RKCompileDupNames RKCompileDupNames@/link or there is only a single instance of <span class="argument">captureNameString</span>, in which case the result will be the capture index of <span class="argument">captureNameString</span> only if <span class="argument">captureNameString</span> successfully matched, otherwise @link NSNotFound NSNotFound @/link is returned.</p>
 @seealso    @link getRanges:withCharacters:length:inRange:options: - getRanges:withCharacters:length:inRange:options: @/link
 @param      captureNameString The name of the desired capture index.
    <div class="box important"><div class="table"><div class="row"><div class="label cell">Important:</div><div class="message cell">Raises a @link NSInvalidArgumentException NSInvalidArgumentException @/link if <span class="argument">captureNameString</span> is <span class="code">nil</span> or is not a valid capture name for the receivers regular expression.</div></div></div></div>
 @param      matchedRanges The ranges result from a @link getRanges:withCharacters:length:inRange:options: getRanges:withCharacters:length:inRange:options: @/link match.
 <div class="box important"><div class="table"><div class="row"><div class="label cell">Important:</div><div class="message cell">Raises a @link NSInvalidArgumentException NSInvalidArgumentException @/link if <span class="argument">matchedRanges</span> is <span class="code">NULL</span>.</div></div></div></div>
 @result     The first capture index that matched in <span class="argument">matchedRanges</span> for <span class="argument">captureNameString</span>, otherwise @link NSNotFound NSNotFound @/link is returned if there were no successful matches for any of the captures indexes of <span class="argument">captureNameString</span>.
*/
- (RKUInteger)captureIndexForCaptureName:(NSString *)captureNameString inMatchedRanges:(const NSRange *)matchedRanges;

/*!
 @method     captureIndexForCaptureName:inMatchedRanges:error:
 @tocgroup   RKRegex Named Capture Information
 @abstract   Returns the capture index for <span class="argument">captureNameString</span> from a match operation, or the capture index of the first successful match for <span class="argument">captureNameString</span> if @link RKCompileDupNames RKCompileDupNames @/link is used and there are multiple instances of <span class="argument">captureNameString</span> in the receivers regular expression.
 @discussion <p>This method is similar to @link captureIndexForCaptureName:inMatchedRanges: captureIndexForCaptureName:inMatchedRanges: @/link except that it <i>optionally</i> returns a @link NSError NSError @/link object for error conditions instead of throwing an exception.  The <span class="argument">error</span> parameter may be set to <span class="code">nil</span> if information about the error is not required.</p>
 <div class="box important"><div class="table"><div class="row"><div class="label cell">Important:</div><div class="message cell">Exceptions are still thrown for invalid argument conditions, such as passing <span class="code">nil</span> for <span class="argument">captureNameString</span> or <span class="argument">matchedRanges</span>.</div></div></div></div>
 @seealso    @link captureIndexForCaptureName:inMatchedRanges: - captureIndexForCaptureName:inMatchedRanges: @/link
 @seealso    @link getRanges:withCharacters:length:inRange:options: - getRanges:withCharacters:length:inRange:options: @/link
*/
- (RKUInteger)captureIndexForCaptureName:(NSString *)captureNameString inMatchedRanges:(const NSRange *)matchedRanges error:(NSError **)error;

/*!
 @method     matchesCharacters:length:inRange:options:
 @tocgroup   RKRegex Matching Regular Expressions
 @abstract   Returns a Boolean value that indicates whether <span class="argument">matchCharacters</span> of <span class="argument">length</span> in <span class="argument">searchRange</span> with <span class="argument">options</span> is matched by the receiver.
 @discussion Invokes @link rangeForCharacters:length:inRange:captureIndex:options: rangeForCharacters:length:inRange:captureIndex:options: @/link for <span class="argument">captureIndex</span> of <span class="code">0</span> with the specified parameters and returns <span class="code">NO</span> if the result is @link NSNotFound NSNotFound@/link, <span class="code">YES</span> otherwise. 
 @param      matchCharacters The characters to match against.  This value must not be <span class="code">NULL</span>.
    <div class="box important"><div class="table"><div class="row"><div class="label cell">Important:</div><div class="message cell">Raises a @link NSInvalidArgumentException NSInvalidArgumentException @/link if <span class="argument">matchCharacters</span> is <span class="code">NULL</span>.</div></div></div></div>
 @param      length The number of characters in <span class="argument">matchCharacters</span>.
 @param      searchRange The range within <span class="argument">matchCharacters</span> to match against.
    <div class="box important"><div class="table"><div class="row"><div class="label cell">Important:</div><div class="message cell">Raises a @link NSRangeException NSRangeException @/link if any part of <span class="argument">searchRange</span> lies beyond the end of <span class="argument">matchCharacters</span>.</div></div></div></div>
 @param      options A mask of options specified by combining @link RKMatchOption RKMatchOption @/link flags with the C bitwise OR operator.
 @result     <span class="code">YES</span> if the receiver matches <span class="argument">matchCharacters</span> of length <span class="argument">length</span> within <span class="argument">searchRange</span> with <span class="argument">options</span>, otherwise <span class="code">NO</span>.
*/

- (BOOL)matchesCharacters:(const void *)matchCharacters length:(const RKUInteger)length inRange:(const NSRange)searchRange options:(const RKMatchOption)options;
/*!
 @method     rangeForCharacters:length:inRange:captureIndex:options:
 @tocgroup   RKRegex Matching Regular Expressions
 @abstract   Returns the range of <span class="argument">captureIndex</span> for the first match in <span class="argument">matchCharacters</span> of length <span class="argument">length</span> inside <span class="argument">searchRange</span> with <span class="argument">options</span> matched by the receiver.
 @discussion (comprehensive description)
 <div class="box important"><div class="table"><div class="row"><div class="label cell">Important:</div><div class="message cell">Raises a @link NSInvalidArgumentException NSInvalidArgumentException @/link if <span class="argument">captureIndex</span> is not valid for the receivers regular expression.</div></div></div></div>
 @param      matchCharacters The characters to match against.  This value must not be <span class="code">NULL</span>.
 <div class="box important"><div class="table"><div class="row"><div class="label cell">Important:</div><div class="message cell">Raises a @link NSInvalidArgumentException NSInvalidArgumentException @/link if <span class="argument">matchCharacters</span> is <span class="code">NULL</span>.</div></div></div></div>
 @param      length The number of characters in <span class="argument">matchCharacters</span>.
 @param      searchRange The range within <span class="argument">matchString</span> to match against.
    <div class="box important"><div class="table"><div class="row"><div class="label cell">Important:</div><div class="message cell">Raises a @link NSRangeException NSRangeException @/link if any part of <span class="argument">searchRange</span> lies beyond the end of <span class="argument">matchString</span>.</div></div></div></div>
 @param      captureIndex The range of the match for the capture subpattern <span class="argument">captureIndex</span> of the receivers regular expression to return.
 @param      options A mask of options specified by combining @link RKMatchOption RKMatchOption @/link flags with the C bitwise OR operator.
 @result     A @link NSRange NSRange @/link structure giving the location and length of <span class="argument">captureIndex</span> for the first match in <span class="argument">matchCharacters</span> of length <span class="argument">length</span> inside <span class="argument">searchRange</span>  with <span class="argument">options</span> that is matched by the receiver. Returns <span class="code">{</span>@link NSNotFound NSNotFound@/link<span class="code">, 0}</span> if the receiver does not match <span class="argument">matchCharacters</span>.
*/
- (NSRange)rangeForCharacters:(const void *)matchCharacters length:(const RKUInteger)length inRange:(const NSRange)searchRange captureIndex:(const RKUInteger)captureIndex options:(const RKMatchOption)options;
/*!
 @method     rangesForCharacters:length:inRange:options:
 @tocgroup   RKRegex Matching Regular Expressions
 @abstract   Returns a pointer to an array of @link NSRange NSRange @/link structures that correspond to the capture indexes of the receiver for the first match in <span class="argument">matchCharacters</span> of length <span class="argument">length</span> in <span class="argument">searchRange</span> with <span class="argument">options</span>.
 @discussion <p>The returned pointer of an array of @link captureCount captureCount @/link @link NSRange NSRange @/link structures is automatically freed just as a autoreleased object would be released; you should copy any values that are required past the autorelease context in which they were created.</p>
    <p>There is no need to @link free free() @/link the returned result as it will automatically be deallocated at the end of the current @link NSAutoreleasePool NSAutoreleasePool @/link context.</p>
 <p>Example code</p>
 <div class="box sourcecode">&#47;&#47; Assumes that regexObject and characters exists
NSRange *captureRanges = NULL;

captureRanges = [regexObject rangesForCharacters:characters length:strlen(characters) inRange:NSMakeRange(0, strlen(characters)) options:RKMatchNoOptions];

if(captureRanges != NULL) {
  int x;
  for(x = 0; x &lt; [regexObject captureCount]; x++) {
    NSLog(&#64;"Capture index &#37;d location &#37;u, length &#37;u", x, captureRanges[x].location, captureRanges[x].length);
    NSLog(&#64;"NSRange string &#37;&#64;", NSStringFromRange(captureRanges[x]));
  }
}</div>
 @param      matchCharacters The characters to match against.  This value must not be <span class="code">NULL</span>.
    <div class="box important"><div class="table"><div class="row"><div class="label cell">Important:</div><div class="message cell">Raises a @link NSInvalidArgumentException NSInvalidArgumentException @/link if <span class="argument">matchCharacters</span> is <span class="code">NULL</span>.</div></div></div></div>
 @param      length The number of characters in <span class="argument">matchCharacters</span>.
 @param      searchRange The range within <span class="argument">matchString</span> to match against.
    <div class="box important"><div class="table"><div class="row"><div class="label cell">Important:</div><div class="message cell">Raises a @link NSRangeException NSRangeException @/link if any part of <span class="argument">searchRange</span> lies beyond the end of <span class="argument">matchString</span>.</div></div></div></div>
 @param      options A mask of options specified by combining @link RKMatchOption RKMatchOption @/link flags with the C bitwise OR operator.
 @result     <p>A pointer to an autoreleased allocation of memory that is <span class="nobr"><span class="code">sizeof(</span>@link NSRange NSRange@/link<span class="code">) * [self</span> @link captureCount captureCount@/link<span class="code">]</span></span> bytes long and contains @link captureCount captureCount @/link @link NSRange NSRange @/link structures with the location and length for the capture indexes of the first match in <span class="argument">matchCharacters</span> of length <span class="argument">length</span> within the range <span class="argument">searchRange</span> using <span class="argument">options</span>.</p>
    <p>Returns <span class="code">NULL</span> if the receiver does not match <span class="argument">matchCharacters</span> using the supplied arguments.</p>
*/
- (NSRange *)rangesForCharacters:(const void *)matchCharacters length:(const RKUInteger)length inRange:(const NSRange)searchRange options:(const RKMatchOption)options;
/*!
 @method    getRanges:withCharacters:length:inRange:options:
 @tocgroup   RKRegex Matching Regular Expressions
 @abstract   Low level regular expression matching method.
 @discussion <p>This method is the low level matching primitive to the <a href="pcre/index.html"><i>PCRE</i></a> library.</p>
   <p>@link getRanges:withCharacters:length:inRange:options: getRanges:withCharacters:length:inRange:options: @/link allocates all of the memory needed to perform the regular expression  matching and store any temporary results on the stack.  The match results, if any, are translated from the <a href="pcre/index.html"><i>PCRE</i></a> library format to the equivalent @link NSRange NSRange @/link format and stored in the caller supplied <span class="argument">ranges</span> @link NSRange NSRange @/link array.  For nearly all cases this means that there is no associated @link malloc malloc() @/link overhead involved.  See @link rangesForCharacters:length:inRange:options: rangesForCharacters:length:inRange:options:@/link, which creates an @link autorelease autorelease @/link buffer to store the results, if the caller is unable to provide a suitable buffer.</p>
   <p>It is important to note that setting the <span class="argument nobr">searchRange.location</span> and adding the equivalent offset to <span class="argument">charactersBuffer</span> are not the same thing.  The value of <span class="argument">charactersBuffer</span> marks the hard start of the buffer, whereas a positive <span class="argument nobr">searchRange.location</span> makes the characters from <span class="argument">charactersBuffer</span> up to <span class="argument nobr">searchRange.location</span> available to the matching engine.  This is an important distinction for some types of regular expressions, such as those that use lookbehind (ie, <span class="regex">(?<=)</span>), which may require examining characters that are strictly not within <span class="argument">searchRange</span>.</p>
 @param ranges Caller supplied pointer to an array of @link NSRange NSRange@/links at least @link captureCount captureCount @/link big.
   <div class="box warning"><div class="table"><div class="row"><div class="label cell">Warning:</div><div class="message cell">Failure to provide a correctly sized <span class="argument">ranges</span> array will result in memory corruption.</div></div></div></div>
 @param charactersBuffer Pointer to the start of characters to search.
   <div class="box important"><div class="table"><div class="row"><div class="label cell">Important:</div><div class="message cell">Raises a @link NSInvalidArgumentException NSInvalidArgumentException @/link if <span class="argument">ranges</span> or <span class="argument">charactersBuffer</span> is <span class="code">NULL</span>.</div></div></div></div>
 @param length Length of <span class="argument">charactersBuffer</span>.
 @param searchRange The range within <span class="argument">charactersBuffer</span> to match.
   <div class="box important"><div class="table"><div class="row"><div class="label cell">Important:</div><div class="message cell">Raises a @link NSRangeException NSRangeException @/link if <span class="argument">length</span> or <span class="argument">searchRange</span> is invalid or represents an invalid combination.</div></div></div></div>
 @param options A mask of options specified by combining @link RKMatchOption RKMatchOption @/link flags with the C bitwise OR operator.
 @result Returns the number of captures matched (&gt;0) on success, otherwise a @link RKMatchErrorCode RKMatchErrorCode @/link (&lt;0) on failure.  The values in <span class="argument">ranges</span> are only modified on a successful match.
*/
- (RKMatchErrorCode)getRanges:(NSRange *)ranges withCharacters:(const void *)charactersBuffer length:(const RKUInteger)length inRange:(const NSRange)searchRange options:(const RKMatchOption)options;

@end

#endif // _REGEXKIT_RKREGEX_H_
    
#ifdef __cplusplus
  }  /* extern "C" */
#endif
