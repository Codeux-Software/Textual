//
//  NSArray.h
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
  
#ifndef _REGEXKIT_NSARRAY_H_
#define _REGEXKIT_NSARRAY_H_ 1

/*!
 @header NSArray
*/

#import <Foundation/Foundation.h>
#import <RegexKit/RegexKit.h>
  
/*!
 @category    NSArray (RegexKitAdditions)
 @abstract    Convenient @link NSArray NSArray @/link additions to make regular expression pattern matching and extraction easier.
*/
  
/*!
 @toc   NSArray
 @group Deriving New Arrays
 @group Querying an Array
*/

@interface NSArray (RegexKitAdditions)
/*!
 @method     arrayByMatchingObjectsWithRegex:
 @tocgroup   NSArray Deriving New Arrays
 @abstract   Returns a new array that contains all the objects in the receiver matching <span class="argument">aRegex</span>.
 @seealso    @link addObjectsFromArray:matchingRegex: - addObjectsFromArray:matchingRegex: @/link
 @seealso    @link arrayByMatchingObjectsWithRegex:inRange: - arrayByMatchingObjectsWithRegex:inRange: @/link
*/
-(NSArray *)arrayByMatchingObjectsWithRegex:(id)aRegex;
/*!
 @method     arrayByMatchingObjectsWithRegex:inRange:
 @tocgroup   NSArray Deriving New Arrays
 @abstract   Returns a new array that contains all the objects in the receiver matching <span class="argument">aRegex</span> within the specified <span class="argument">range</span>.
 @seealso    @link addObjectsFromArray:matchingRegex: - addObjectsFromArray:matchingRegex: @/link
*/
-(NSArray *)arrayByMatchingObjectsWithRegex:(id)aRegex inRange:(const NSRange)range;
/*!
 @method     containsObjectMatchingRegex:
 @tocgroup   NSArray Querying an Array
 @abstract   Returns a Boolean value that indicates whether an object matching <span class="argument">aRegex</span> is present in the receiver.
 @result     <span class="code">YES</span> if an object that is matched by <span class="argument">aRegex</span> is present in the receiver, otherwise <span class="code">NO</span>.
 @seealso    @link containsObjectMatchingRegex:inRange: - containsObjectMatchingRegex:inRange: @/link
 @seealso    @link indexOfObjectMatchingRegex: - indexOfObjectMatchingRegex: @/link
*/
-(BOOL)containsObjectMatchingRegex:(id)aRegex;
/*!
 @method     containsObjectMatchingRegex:inRange:
 @tocgroup   NSArray Querying an Array
 @abstract   Returns a Boolean value that indicates whether an object in the specified <span class="argument">range</span> matching <span class="argument">aRegex</span> is present in the receiver.
 @result     <span class="code">YES</span> if an object that is matched by <span class="argument">aRegex</span> is present in the receiver, otherwise <span class="code">NO</span>.
 @seealso    @link indexOfObjectMatchingRegex:inRange: - indexOfObjectMatchingRegex:inRange: @/link
*/
-(BOOL)containsObjectMatchingRegex:(id)aRegex inRange:(const NSRange)range;
/*!
 @method     countOfObjectsMatchingRegex:
 @tocgroup   NSArray Querying an Array
 @abstract   Returns the number of objects matching <span class="argument">aRegex</span> in the receiver.
 @seealso    @link countOfObjectsMatchingRegex:inRange: - countOfObjectsMatchingRegex:inRange: @/link
*/
-(RKUInteger)countOfObjectsMatchingRegex:(id)aRegex;
/*!
 @method     countOfObjectsMatchingRegex:inRange:
 @tocgroup   NSArray Querying an Array
 @abstract   Returns the number of objects matching <span class="argument">aRegex</span> in the receiver within the specified <span class="argument">range</span>.
*/
-(RKUInteger)countOfObjectsMatchingRegex:(id)aRegex inRange:(const NSRange)range;
/*!
 @method     indexOfObjectMatchingRegex:
 @tocgroup   NSArray Querying an Array
 @abstract   Searches the receiver for an object that matches <span class="argument">aRegex</span> and returns the lowest index whose corresponding array value is equal to the matched object.
 @discussion If none of the objects in the receiver are matched by <span class="argument">aRegex</span>, @link indexOfObjectMatchingRegex: indexOfObjectMatchingRegex: @/link returns @link NSNotFound NSNotFound @/link.
 @seealso    @link indexOfObjectMatchingRegex:inRange: - indexOfObjectMatchingRegex:inRange: @/link
*/
-(RKUInteger)indexOfObjectMatchingRegex:(id)aRegex;
/*!
 @method     indexOfObjectMatchingRegex:inRange:
 @tocgroup   NSArray Querying an Array
 @abstract   Searches the specified <span class="argument">range</span> within the receiver for an object that matches <span class="argument">aRegex</span> and returns the lowest index whose corresponding array value is equal to the matched object.
 @discussion If none of the objects in the specified <span class="argument">range</span> are matched by <span class="argument">aRegex</span>, @link indexOfObjectMatchingRegex:inRange: indexOfObjectMatchingRegex:inRange: @/link returns @link NSNotFound NSNotFound @/link.
 @seealso    @link indexOfObjectMatchingRegex: - indexOfObjectMatchingRegex: @/link
*/
-(RKUInteger)indexOfObjectMatchingRegex:(id)aRegex inRange:(const NSRange)range;
/*!
 @method     indexSetOfObjectsMatchingRegex:
 @tocgroup   NSArray Querying an Array
 @abstract   Searches the receiver for objects that are matched by <span class="argument">aRegex</span> and returns a @link NSIndexSet NSIndexSet @/link containing the matching indexes.
 @seealso    @link indexSetOfObjectsMatchingRegex:inRange: - indexSetOfObjectsMatchingRegex:inRange: @/link
*/
-(NSIndexSet *)indexSetOfObjectsMatchingRegex:(id)aRegex;
/*!
 @method     indexSetOfObjectsMatchingRegex:inRange:
 @tocgroup   NSArray Querying an Array
 @abstract   Searches the specified <span class="argument">range</span> within the receiver for objects that are matched by <span class="argument">aRegex</span> and returns a @link NSIndexSet NSIndexSet @/link containing the matching indexes.
 @seealso    @link indexSetOfObjectsMatchingRegex: - indexSetOfObjectsMatchingRegex: @/link
*/
-(NSIndexSet *)indexSetOfObjectsMatchingRegex:(id)aRegex inRange:(const NSRange)range;

@end


/*!
 @category    NSMutableArray (RegexKitAdditions)
 @abstract    Convenient @link NSMutableArray NSMutableArray @/link additions to make regular expression pattern matching and extraction easier.
 @discussion  (comprehensive description)
*/

/*!
 @toc        NSMutableArray
 @group      Adding Objects
 @group      Removing Objects
*/

 @interface NSMutableArray (RegexKitAdditions)

/*!
 @method     addObjectsFromArray:matchingRegex:
 @tocgroup   NSMutableArray Adding Objects
 @abstract   Adds the objects matching <span class="argument">aRegex</span> contained in <span class="argument">otherArray</span> to the end of the receiver's content.
 @param      otherArray An array to search for objects matching <span class="argument">aRegex</span> to add to the end of the receiver's content.
 @param      aRegex A regular expression string or @link RKRegex RKRegex @/link object.
*/
- (void)addObjectsFromArray:(NSArray *)otherArray matchingRegex:(id)aRegex;

/*!
 @method     removeObjectsMatchingRegex:
 @tocgroup   NSMutableArray Removing Objects
 @abstract   Removes all objects that match <span class="argument">aRegex</span> from the receiver.
*/
-(void)removeObjectsMatchingRegex:(id)aRegex;
/*!
 @method     removeObjectsMatchingRegex:inRange:
 @tocgroup   NSMutableArray Removing Objects
 @abstract   Removes all objects matching <span class="argument">aRegex</span> within <span class="argument">range</span> from the receiver.
*/
-(void)removeObjectsMatchingRegex:(id)aRegex inRange:(const NSRange)range;

@end

#endif // _REGEXKIT_NSARRAY_H_
    
#ifdef __cplusplus
  }  /* extern "C" */
#endif
