//
//  RKUtility.h
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
  
#ifndef _REGEXKIT_RKUTILITY_H_
#define _REGEXKIT_RKUTILITY_H_ 1

/*!
 @header RKUtility
*/

#import <Foundation/Foundation.h>
#import <RegexKit/RegexKitDefines.h>
#import <RegexKit/RegexKitTypes.h>

/*!
 @toc Functions
 @group Utility Functions
 @group Unicode Character Index Conversions
*/  

/*!
 @function  RKStringFromNewlineOption
 @tocgroup   Functions Utility Functions
 @abstract   Returns a string representation of the RKBuildConfig, RKCompileOption, or RKMatchOption Newline sequence prepended with <span class="argument">prefixString</span>.
 @discussion <p>Since multiple option types are decoded, the caller is required to supply the corresponding prefix via <span class="argument">prefixString</span>.</p>
 <p>Returns <span class="code">&#47;&#42;Unknown Newline Option: 0x</span><span class="argument">decodeNewlineOption</span><span class="code">&#42;&#47;</span> if the <span class="argument">decodeNewlineOption</span> is not recognized.</p> 
 @param      decodeNewlineOption The @link RKBuildConfig RKBuildConfig@/link, @link RKCompileOption RKCompileOption@/link, or @link RKMatchOption RKMatchOption @/link to decode.
 @param      prefixString  The prefix to prepend to the decoded Newline sequence
 @result     Returns a string in the form "<i>RKCompileNewlineAny</i>" when <span class="argument">prefixString</span> is <span class="code">@"RKCompile"</span>.
*/
REGEXKIT_EXTERN NSString *RKStringFromNewlineOption(const int decodeNewlineOption, NSString *prefixString) RK_ATTRIBUTES(nonnull (2), used);  

/*!
 @function RKArrayFromMatchOption
 @tocgroup   Functions Utility Functions
 @abstract   Returns an array representation of @link RKMatchOption RKMatchOption @/link bits in string form.
 @discussion  <p>Returns @link RKMatchNoOptions RKMatchNoOptions @/link if no options are set.</p>
    <p>Returns <span class="code">&#47;&#42;Unknown match options remain: 0x</span><span class="argument">decodeMatchOption</span><span class="code">&#42;&#47;</span> if there are undecoded bits remaining.</p> 
  <p>The following example forms a C bitwise OR string representation of the @link RKMatchOption RKMatchOption @/link bits:</p>
 <div class="box sourcecode">RKMatchOption matchOptions = (RKMatchAnchored | RKMatchNoUTF8Check);
NSArray *matchOptionsArray = RKArrayFromMatchOptions(matchOptions);
NSString *matchOptionsString = [NSString stringWithFormat:&#64;"(&#37;&#64;)", [matchOptions componentsJoinedByString:&#64;" | "]];

&#47;&#42; matchOptionsString == &#64;"(RKMatchAnchored | RKMatchNoUTF8Check)" &#42;&#47;</div> 
 @param      decodeMatchOption A mask of options specified by combining @link RKMatchOption RKMatchOption @/link flags with the C bitwise OR operator.
 @result     Returns an array of the individual @link RKMatchOption RKMatchOption @/link bits in string form.
*/
REGEXKIT_EXTERN NSArray *RKArrayFromMatchOption(const RKMatchOption decodeMatchOption) RK_ATTRIBUTES(used);

/*!
 @function RKArrayFromCompileOption
 @tocgroup   Functions Utility Functions
 @abstract   Returns an array representation of @link RKCompileOption RKCompileOption @/link bits in string form.
 @discussion <p>Returns @link RKCompileNoOptions RKCompileNoOptions @/link if no options are set.</p>
 <p>Returns <span class="code">&#47;&#42;Unknown compile options remain: 0x</span><span class="argument">decodeCompileOption</span><span class="code">&#42;&#47;</span> if there are undecoded bits remaining.</p> 
 <p>See the example from @link RKArrayFromMatchOption RKArrayFromMatchOption @/link to form a C bitwise OR string representation.</p>
 @param      decodeCompileOption A mask of options specified by combining @link RKCompileOption RKCompileOption @/link flags with the C bitwise OR operator.
 @result     Returns an array of the individual @link RKCompileOption RKCompileOption @/link bits in string form.
*/
REGEXKIT_EXTERN NSArray  *RKArrayFromCompileOption(const RKCompileOption decodeCompileOption) RK_ATTRIBUTES(used);

/*!
 @function RKArrayFromBuildConfig
 @tocgroup   Functions Utility Functions
 @abstract   Returns an array representation of @link RKBuildConfig RKBuildConfig @/link bits in string form.
 @discussion See the example from @link RKArrayFromMatchOption RKArrayFromMatchOption @/link to form a C bitwise OR string representation.
 @param      decodeBuildConfig  A mask of options specified by combining @link RKBuildConfig RKBuildConfig @/link flags with the C bitwise OR operator.
 @result     Returns an array of the individual @link RKBuildConfig RKBuildConfig @/link bits in string form.
*/
REGEXKIT_EXTERN NSArray  *RKArrayFromBuildConfig(const RKBuildConfig decodeBuildConfig) RK_ATTRIBUTES(used);

/*!
 @function RKStringFromCompileErrorCode
 @tocgroup   Functions Utility Functions
 @abstract   Returns a string representation of a @link RKCompileErrorCode RKCompileErrorCode@/link.
 @discussion Returns <span class="code">Unknown error code (#</span><span class="argument">decodeErrorCode</span><span class="code">)</span> on unknown error values.
 @param      decodeErrorCode A @link RKCompileErrorCode RKCompileErrorCode @/link value.
 @result     Returns a string representation of a @link RKCompileErrorCode RKCompileErrorCode@/link.
*/
REGEXKIT_EXTERN NSString *RKStringFromCompileErrorCode(const RKCompileErrorCode decodeErrorCode) RK_ATTRIBUTES(used);

/*!
 @function RKStringFromMatchErrorCode
 @tocgroup   Functions Utility Functions
 @abstract   Returns a string representation of a @link RKMatchErrorCode RKMatchErrorCode@/link.
 @discussion Returns <span class="code">Unknown error code (#</span><span class="argument">decodeErrorCode</span><span class="code">)</span> on unknown error values.
 @param      decodeErrorCode A @link RKMatchErrorCode RKMatchErrorCode @/link value.
 @result     Returns a string representation of a @link RKMatchErrorCode RKMatchErrorCode@/link.
*/
REGEXKIT_EXTERN NSString *RKStringFromMatchErrorCode(const RKMatchErrorCode decodeErrorCode) RK_ATTRIBUTES(used);
  
#endif // _REGEXKIT_RKUTILITY_H_
    
#ifdef __cplusplus
  }  /* extern "C" */
#endif
