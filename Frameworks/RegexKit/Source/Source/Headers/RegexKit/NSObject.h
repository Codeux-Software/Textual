//
//  NSObject.h
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
  
#ifndef _REGEXKIT_NSOBJECT_H_
#define _REGEXKIT_NSOBJECT_H_ 1

/*!
 @header NSObject
*/

#import <Foundation/Foundation.h>
#import <RegexKit/RegexKit.h>

/*!
 @category    NSObject (RegexKitAdditions)
 @abstract    Convenient @link NSObject NSObject @/link additions to make regular expression pattern matching and extraction easier.
*/
  
/*!
 @toc        NSObject
 @group      Identifying and Comparing Objects
 @group      Identifying Matches in an Array
 @group      Identifying Matches in a Set
*/
  
@interface NSObject (RegexKitAdditions)

/*!
 @method     isMatchedByRegex:
 @tocgroup   NSObject Identifying and Comparing Objects
 @abstract   Returns a Boolean value that indicates whether the receiver is matched by <span class="argument">aRegex</span>.
 @discussion Invokes @link isMatchedByRegex: isMatchedByRegex: @/link on the @link NSString NSString @/link returned by the receivers @link description description@/link.
 @param      aRegex A regular expression string or @link RKRegex RKRegex @/link object.
 @result     Returns <span class="code">YES</span> if the receiver is matched by <span class="argument">aRegex</span>, <span class="code">NO</span> otherwise.
*/
- (BOOL)isMatchedByRegex:(id)aRegex;


/*!
 @method     isMatchedByAnyRegexInArray:
 @tocgroup   NSObject Identifying Matches in an Array
 @abstract   Returns a Boolean value that indicates whether the receiver is matched by any regular expression in <span class="argument">regexArray</span>.
 @param      regexArray A @link NSArray NSArray @/link containing either regular expression strings or @link RKRegex RKRegex @/link objects.
 @discussion Equivalent to @link isMatchedByAnyRegexInArray:library:options:error: isMatchedByAnyRegexInArray:library:options:error: @/link using <span class="argument">regexArray</span> with @link RKRegexPCRELibrary RKRegexPCRELibrary @/link for <span class="argument">library</span> and <span class="code">(</span>@link RKCompileUTF8 RKCompileUTF8 @/link <span class="code">|</span> @link RKCompileNoUTF8Check RKCompileNoUTF8Check@/link<span class="code">)</span> for <span class="argument">libraryOptions</span>.
 @result     Returns <span class="code">YES</span> if the receiver is matched by any regular expression in <span class="argument">regexArray</span>, <span class="code">NO</span> otherwise.
 @seealso    @link anyMatchingRegexInArray: - anyMatchingRegexInArray: @/link
 @seealso    @link firstMatchingRegexInArray: - firstMatchingRegexInArray: @/link
 @seealso    @link isMatchedByAnyRegexInArray:library:options:error: - isMatchedByAnyRegexInArray:library:options:error: @/link
 */
- (BOOL)isMatchedByAnyRegexInArray:(NSArray *)regexArray;
/*!
 @method     anyMatchingRegexInArray:
 @tocgroup   NSObject Identifying Matches in an Array
 @abstract   Returns any regular expression from <span class="argument">regexArray</span> that matches the receiver.
 @param      regexArray A @link NSArray NSArray @/link containing either regular expression strings or @link RKRegex RKRegex @/link objects.
 @discussion Equivalent to @link anyMatchingRegexInArray:library:options:error: anyMatchingRegexInArray:library:options:error: @/link using <span class="argument">regexArray</span> with @link RKRegexPCRELibrary RKRegexPCRELibrary @/link for <span class="argument">library</span> and <span class="code">(</span>@link RKCompileUTF8 RKCompileUTF8 @/link <span class="code">|</span> @link RKCompileNoUTF8Check RKCompileNoUTF8Check@/link<span class="code">)</span> for <span class="argument">libraryOptions</span>.
 @result     Returns one of the regular expressions from <span class="argument">regexArray</span> that matches the receiver, or <span class="code">NULL</span> if the receiver is not matched by any of the regular expressions or an error occurs. The object returned is chosen at the receiver's convenience- the selection is not guaranteed to be random.
 @seealso    @link anyMatchingRegexInArray:library:options:error: - anyMatchingRegexInArray:library:options:error: @/link
 @seealso    @link firstMatchingRegexInArray: - firstMatchingRegexInArray: @/link
 @seealso    @link isMatchedByAnyRegexInArray: - isMatchedByAnyRegexInArray: @/link
 */
- (RKRegex *)anyMatchingRegexInArray:(NSArray *)regexArray;
/*!
 @method     firstMatchingRegexInArray:
 @tocgroup   NSObject Identifying Matches in an Array
 @abstract   Returns the first regular expression from <span class="argument">regexArray</span> that matches the receiver.
 @param      regexArray A @link NSArray NSArray @/link containing either regular expression strings or @link RKRegex RKRegex @/link objects.
 @discussion Equivalent to @link firstMatchingRegexInArray:library:options:error: firstMatchingRegexInArray:library:options:error: @/link using <span class="argument">regexArray</span> with @link RKRegexPCRELibrary RKRegexPCRELibrary @/link for <span class="argument">library</span> and <span class="code">(</span>@link RKCompileUTF8 RKCompileUTF8 @/link <span class="code">|</span> @link RKCompileNoUTF8Check RKCompileNoUTF8Check@/link<span class="code">)</span> for <span class="argument">libraryOptions</span>.
 @result     Returns the first regular expression from <span class="argument">regexArray</span> that matches the receiver, or <span class="code">NULL</span> if the receiver is not matched by any of the regular expressions or an error occurs.
 @seealso    @link anyMatchingRegexInArray: - anyMatchingRegexInArray: @/link
 @seealso    @link firstMatchingRegexInArray:library:options:error: - firstMatchingRegexInArray:library:options:error: @/link
 @seealso    @link isMatchedByAnyRegexInArray: - isMatchedByAnyRegexInArray: @/link
 */
- (RKRegex *)firstMatchingRegexInArray:(NSArray *)regexArray;
/*!
 @method     isMatchedByAnyRegexInArray:library:options:error:
 @tocgroup   NSObject Identifying Matches in an Array
 @abstract   Returns a Boolean value that indicates whether the receiver is matched by any regular expression in <span class="argument">regexArray</span> using the regular expression <span class="argument">library</span> and <span class="argument">libraryOptions</span>, setting the optional <span class="argument">error</span> parameter if an error occurs.
 @discussion <span class="argument">regexArray</span> may contain either regular expression strings or @link RKRegex RKRegex @/link objects.  See <a href="Constants.html#Regular_Expression_Libraries" class="section-link">Regular Expression Libraries</a> for a list of valid <span class="argument">library</span> constants.  If information about any errors is not required, <span class="argument">error</span> may be set to <span class="code">NULL</span>.
 @result     Returns <span class="code">YES</span> if the receiver is matched by any regular expression in <span class="argument">regexArray</span>, <span class="code">NO</span> otherwise.
 @seealso    @link anyMatchingRegexInArray:library:options:error: - anyMatchingRegexInArray:library:options:error: @/link
 @seealso    @link firstMatchingRegexInArray:library:options:error: - firstMatchingRegexInArray:library:options:error: @/link
 @seealso    @link isMatchedByAnyRegexInArray: - isMatchedByAnyRegexInArray: @/link
 */
- (BOOL)isMatchedByAnyRegexInArray:(NSArray *)regexArray library:(NSString *)library options:(RKCompileOption)libraryOptions error:(NSError **)error;
/*!
 @method     anyMatchingRegexInArray:library:options:error:
 @tocgroup   NSObject Identifying Matches in an Array
 @abstract   Returns any regular expression from <span class="argument">regexArray</span> that matches the receiver using the regular expression <span class="argument">library</span> and <span class="argument">libraryOptions</span>, setting the optional <span class="argument">error</span> parameter if an error occurs.
 @discussion <span class="argument">regexArray</span> may contain either regular expression strings or @link RKRegex RKRegex @/link objects.  See <a href="Constants.html#Regular_Expression_Libraries" class="section-link">Regular Expression Libraries</a> for a list of valid <span class="argument">library</span> constants.  If information about any errors is not required, <span class="argument">error</span> may be set to <span class="code">NULL</span>.
 @result     Returns one of the regular expressions from <span class="argument">regexArray</span> that matches the receiver, or <span class="code">NULL</span> if the receiver is not matched by any of the regular expressions or an error occurs. The object returned is chosen at the receiver's convenience- the selection is not guaranteed to be random.
 @seealso    @link anyMatchingRegexInArray: - anyMatchingRegexInArray: @/link
 @seealso    @link firstMatchingRegexInArray:library:options:error: - firstMatchingRegexInArray:library:options:error: @/link
 @seealso    @link isMatchedByAnyRegexInArray:library:options:error: - isMatchedByAnyRegexInArray:library:options:error: @/link
 */
- (RKRegex *)anyMatchingRegexInArray:(NSArray *)regexArray library:(NSString *)library options:(RKCompileOption)libraryOptions error:(NSError **)error;
/*!
 @method     firstMatchingRegexInArray:library:options:error:
 @tocgroup   NSObject Identifying Matches in an Array
 @abstract   Returns the first regular expression from <span class="argument">regexArray</span> that matches the receiver using the regular expression <span class="argument">library</span> and <span class="argument">libraryOptions</span>, setting the optional <span class="argument">error</span> parameter if an error occurs.
 @discussion <span class="argument">regexArray</span> may contain either regular expression strings or @link RKRegex RKRegex @/link objects.  See <a href="Constants.html#Regular_Expression_Libraries" class="section-link">Regular Expression Libraries</a> for a list of valid <span class="argument">library</span> constants.  If information about any errors is not required, <span class="argument">error</span> may be set to <span class="code">NULL</span>.
 @result     Returns the first regular expression from <span class="argument">regexArray</span> that matches the receiver, or <span class="code">NULL</span> if the receiver is not matched by any of the regular expressions or an error occurs.
 @seealso    @link anyMatchingRegexInArray:library:options:error: - anyMatchingRegexInArray:library:options:error: @/link
 @seealso    @link firstMatchingRegexInArray: - firstMatchingRegexInArray: @/link
 @seealso    @link isMatchedByAnyRegexInArray:library:options:error: - isMatchedByAnyRegexInArray:library:options:error: @/link
 */
- (RKRegex *)firstMatchingRegexInArray:(NSArray *)regexArray library:(NSString *)library options:(RKCompileOption)libraryOptions error:(NSError **)error;

/*!
 @method     isMatchedByAnyRegexInSet:
 @tocgroup   NSObject Identifying Matches in a Set
 @abstract   Returns a Boolean value that indicates whether the receiver is matched by any regular expression in <span class="argument">regexSet</span>.
 @param      regexSet A @link NSSet NSSet @/link containing either regular expression strings or @link RKRegex RKRegex @/link objects.
 @discussion Equivalent to @link isMatchedByAnyRegexInSet:library:options:error: isMatchedByAnyRegexInSet:library:options:error: @/link using <span class="argument">regexArray</span> with @link RKRegexPCRELibrary RKRegexPCRELibrary @/link for <span class="argument">library</span> and <span class="code">(</span>@link RKCompileUTF8 RKCompileUTF8 @/link <span class="code">|</span> @link RKCompileNoUTF8Check RKCompileNoUTF8Check@/link<span class="code">)</span> for <span class="argument">libraryOptions</span>.
 @result     Returns <span class="code">YES</span> if the receiver is matched by any regular expression in <span class="argument">regexSet</span>, <span class="code">NO</span> otherwise.
 @seealso    @link anyMatchingRegexInSet: - anyMatchingRegexInSet: @/link
 @seealso    @link isMatchedByAnyRegexInSet:library:options:error: - isMatchedByAnyRegexInSet:library:options:error: @/link
*/
- (BOOL)isMatchedByAnyRegexInSet:(NSSet *)regexSet;
/*!
 @method     anyMatchingRegexInSet:
 @tocgroup   NSObject Identifying Matches in a Set
 @abstract   Returns any regular expression from <span class="argument">regexSet</span> that matches the receiver.
 @param      regexSet A @link NSSet NSSet @/link containing either regular expression strings or @link RKRegex RKRegex @/link objects.
 @discussion Equivalent to @link anyMatchingRegexInSet:library:options:error: anyMatchingRegexInSet:library:options:error: @/link using <span class="argument">regexArray</span> with @link RKRegexPCRELibrary RKRegexPCRELibrary @/link for <span class="argument">library</span> and <span class="code">(</span>@link RKCompileUTF8 RKCompileUTF8 @/link <span class="code">|</span> @link RKCompileNoUTF8Check RKCompileNoUTF8Check@/link<span class="code">)</span> for <span class="argument">libraryOptions</span>.
 @result     Returns one of the regular expressions from <span class="argument">regexSet</span> that matches the receiver, or <span class="code">NULL</span> if the receiver is not matched by any of the regular expressions or an error occurs. The object returned is chosen at the receiver's convenience- the selection is not guaranteed to be random.
 @seealso    @link anyMatchingRegexInSet:library:options:error: - anyMatchingRegexInSet:library:options:error: @/link
 @seealso    @link isMatchedByAnyRegexInSet: - isMatchedByAnyRegexInSet: @/link
*/
- (RKRegex *)anyMatchingRegexInSet:(NSSet *)regexSet;
/*!
 @method     isMatchedByAnyRegexInSet:library:options:error:
 @tocgroup   NSObject Identifying Matches in a Set
 @abstract   Returns a Boolean value that indicates whether the receiver is matched by any regular expression in <span class="argument">regexSet</span> using the regular expression <span class="argument">library</span> and <span class="argument">libraryOptions</span>, setting the optional <span class="argument">error</span> parameter if an error occurs.
 @discussion <span class="argument">regexSet</span> may contain either regular expression strings or @link RKRegex RKRegex @/link objects.  See <a href="Constants.html#Regular_Expression_Libraries" class="section-link">Regular Expression Libraries</a> for a list of valid <span class="argument">library</span> constants.  If information about any errors is not required, <span class="argument">error</span> may be set to <span class="code">NULL</span>.
 @result     Returns <span class="code">YES</span> if the receiver is matched by any regular expression in <span class="argument">regexSet</span>, <span class="code">NO</span> otherwise.
 @seealso    @link anyMatchingRegexInSet:library:options:error: - anyMatchingRegexInSet:library:options:error: @/link
 @seealso    @link isMatchedByAnyRegexInSet: - isMatchedByAnyRegexInSet: @/link
*/
- (BOOL)isMatchedByAnyRegexInSet:(NSSet *)regexSet library:(NSString *)library options:(RKCompileOption)libraryOptions error:(NSError **)error;
/*!
 @method     anyMatchingRegexInSet:library:options:error:
 @tocgroup   NSObject Identifying Matches in a Set
 @abstract   Returns any regular expression from <span class="argument">regexSet</span> that matches the receiver using the regular expression <span class="argument">library</span> and <span class="argument">libraryOptions</span>, setting the optional <span class="argument">error</span> parameter if an error occurs.
 @discussion See <a href="Constants.html#Regular_Expression_Libraries" class="section-link">Regular Expression Libraries</a> for a list of valid <span class="argument">library</span> constants.  If information about any errors is not required, <span class="argument">error</span> may be set to <span class="code">NULL</span>.
 @result     <span class="argument">regexSet</span> may contain either regular expression strings or @link RKRegex RKRegex @/link objects.  Returns one of the regular expressions from <span class="argument">regexSet</span> that matches the receiver, or <span class="code">NULL</span> if the receiver is not matched by any of the regular expressions or an error occurs. The object returned is chosen at the receiver's convenience- the selection is not guaranteed to be random.
 @seealso    @link anyMatchingRegexInSet: - anyMatchingRegexInSet: @/link
 @seealso    @link isMatchedByAnyRegexInSet:library:options:error: - isMatchedByAnyRegexInSet:library:options:error: @/link
*/
- (RKRegex *)anyMatchingRegexInSet:(NSSet *)regexSet library:(NSString *)library options:(RKCompileOption)libraryOptions error:(NSError **)error;

@end

#endif // _REGEXKIT_NSOBJECT_H_

#ifdef __cplusplus
  }  /* extern "C" */
#endif
