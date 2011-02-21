//
//  NSSet.h
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
  
#ifndef _REGEXKIT_NSSET_H_
#define _REGEXKIT_NSSET_H_ 1

/*!
 @header NSSet
*/

#import <Foundation/Foundation.h>
#import <RegexKit/RegexKit.h>
#import <stdarg.h>
  
/*!
 @category    NSSet (RegexKitAdditions)
 @abstract    Convenient @link NSSet NSSet @/link additions to make regular expression pattern matching and extraction easier.
 @discussion  (comprehensive description)
*/
  
/*!
 @toc        NSSet
 @group      Deriving New Sets
 @group      Querying a Set
*/
  
 @interface NSSet (RegexKitAdditions)

/*!
 @method     anyObjectMatchingRegex:
 @tocgroup   NSSet Querying a Set
 @abstract   Returns one of the objects in the receiver, or <span class="code">nil</span> if the receiver contains no objects matching <span class="argument">aRegex</span>.
 @result     One of the objects in the receiver, or <span class="code">nil</span> if the receiver contains no objects matching <span class="argument">aRegex</span>. The object returned is chosen at the receiver's convenience- the selection is not guaranteed to be random.
 @seealso    @link NSSet/anyObject - anyObject @/link (NSSet)
 @seealso    @link setByMatchingObjectsWithRegex: - setByMatchingObjectsWithRegex: @/link
*/
-(id)anyObjectMatchingRegex:(id)aRegex;
/*!
 @method     containsObjectMatchingRegex:
 @tocgroup   NSSet Querying a Set
 @abstract   Returns a Boolean value that indicates whether an object matching <span class="argument">aRegex</span> is present in the receiver.
*/
-(BOOL)containsObjectMatchingRegex:(id)aRegex;
/*!
 @method     countOfObjectsMatchingRegex:
 @tocgroup   NSSet Querying a Set
 @abstract   Returns the number of objects matching <span class="argument">aRegex</span> in the receiver.
*/
-(RKUInteger)countOfObjectsMatchingRegex:(id)aRegex;
/*!
 @method     setByMatchingObjectsWithRegex:
 @tocgroup   NSSet Deriving New Sets
 @abstract   Returns a new set that contains all the objects in the receiver matching <span class="argument">aRegex</span>.
 @result     Returns a set with a count of <span class="code">0</span> if there are no matches.
 @seealso    @link NSMutableSet/addObjectsFromArray:matchingRegex: - addObjectsFromArray:matchingRegex: @/link (NSMutableSet)
 @seealso    @link NSMutableSet/addObjectsFromSet:matchingRegex: - addObjectsFromSet:matchingRegex: @/link (NSMutableSet)
*/
-(NSSet *)setByMatchingObjectsWithRegex:(id)aRegex;


@end

/*!
 @toc        NSMutableSet
 @group      Removing Objects
 @group      Adding Objects
*/

 @interface NSMutableSet (RegexKitAdditions)

/*!
 @method     removeObjectsMatchingRegex:
 @tocgroup   NSMutableSet Removing Objects
 @abstract   Removes all objects that match <span class="argument">aRegex</span> from the receiver.
*/
-(void)removeObjectsMatchingRegex:(id)aRegex;

/*!
 @method     addObjectsFromArray:matchingRegex:
 @tocgroup   NSMutableSet Adding Objects
 @abstract   Adds the objects matching <span class="argument">aRegex</span> contained in <span class="argument">otherArray</span> to the receiver's content.
 @param      otherArray An array to search for objects matching <span class="argument">aRegex</span> to add to the receiver's content.
 @param      aRegex A regular expression string or @link RKRegex RKRegex @/link object.
*/
- (void)addObjectsFromArray:(NSArray *)otherArray matchingRegex:(id)aRegex;
/*!
 @method     addObjectsFromSet:matchingRegex:
 @tocgroup   NSMutableSet Adding Objects
 @abstract   Adds the objects matching <span class="argument">aRegex</span> contained in <span class="argument">otherSet</span> to the receiver's content.
 @param      otherSet A set to search for objects matching <span class="argument">aRegex</span> to add to the receiver's content.
 @param      aRegex A regular expression string or @link RKRegex RKRegex @/link object.
*/
- (void)addObjectsFromSet:(NSSet *)otherSet matchingRegex:(id)aRegex;

@end

#endif // _REGEXKIT_NSSET_H_
    
#ifdef __cplusplus
  }  /* extern "C" */
#endif
