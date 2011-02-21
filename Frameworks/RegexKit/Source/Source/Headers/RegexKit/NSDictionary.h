//
//  NSDictionary.h
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
  
#ifndef _REGEXKIT_NSDICTIONARY_H_
#define _REGEXKIT_NSDICTIONARY_H_ 1

/*!
 @header NSDictionary
*/

#import <Foundation/Foundation.h>
#import <RegexKit/RegexKit.h>

/*!
 @category    NSDictionary (RegexKitAdditions)
 @abstract    Convenient @link NSDictionary NSDictionary @/link additions to make regular expression pattern matching and extraction easier.
*/
  
/*!
 @toc   NSDictionary
 @group Deriving New Dictionaries
 @group Accessing Keys and Values
 @group Querying a Dictionary
*/
  
 @interface NSDictionary (RegexKitAdditions)

/*!
 @method     dictionaryByMatchingKeysWithRegex:
 @tocgroup   NSDictionary Deriving New Dictionaries
 @abstract   Returns a new dictionary that contains the entries in the receiver whose keys are matched by <span class="argument">aRegex</span>.
 @seealso    @link dictionaryByMatchingObjectsWithRegex: - dictionaryByMatchingObjectsWithRegex: @/link
 @seealso    @link NSMutableDictionary/addEntriesFromDictionary:withKeysMatchingRegex: - addEntriesFromDictionary:withKeysMatchingRegex: @/link
*/
- (NSDictionary *)dictionaryByMatchingKeysWithRegex:(id)aRegex;
/*!
 @method     dictionaryByMatchingObjectsWithRegex:
 @tocgroup   NSDictionary Deriving New Dictionaries
 @abstract   Returns a new dictionary that contains the entries in the receiver whose objects are matched by <span class="argument">aRegex</span>.
 @result     Returns a @link NSDictionary NSDictionary @/link with a count of <span class="code">0</span> if there are no matches.
 @seealso    @link dictionaryByMatchingKeysWithRegex: - dictionaryByMatchingKeysWithRegex: @/link
 @seealso    @link NSMutableDictionary/addEntriesFromDictionary:withKeysMatchingRegex: - addEntriesFromDictionary:withKeysMatchingRegex: @/link
*/
- (NSDictionary *)dictionaryByMatchingObjectsWithRegex:(id)aRegex;
/*!
 @method     containsKeyMatchingRegex:
 @tocgroup   NSDictionary Querying a Dictionary
 @abstract   Returns a Boolean value that indicates whether any of the receivers keys are matched by <span class="argument">aRegex</span>.
 @result     Returns a @link NSDictionary NSDictionary @/link with a count of <span class="code">0</span> if there are no matches.
 @seealso    @link containsObjectMatchingRegex: - containsObjectMatchingRegex: @/link
*/
- (BOOL)containsKeyMatchingRegex:(id)aRegex;
/*!
 @method     containsObjectMatchingRegex:
 @tocgroup   NSDictionary Querying a Dictionary
 @abstract   Returns a Boolean value that indicates whether any of the receivers objects are matched by <span class="argument">aRegex</span>.
 @seealso    @link containsKeyMatchingRegex: - containsKeyMatchingRegex: @/link
*/
- (BOOL)containsObjectMatchingRegex:(id)aRegex;
/*!
 @method     keysMatchingRegex:
 @tocgroup   NSDictionary Accessing Keys and Values
 @abstract   Returns an array of the receiver's keys that are matched by <span class="argument">aRegex</span>.
 @result     Returns a @link NSArray NSArray @/link with a count of <span class="code">0</span> if there are no matches.
 @seealso    @link keysForObjectsMatchingRegex: - keysForObjectsMatchingRegex: @/link
 @seealso    @link objectsForKeysMatchingRegex: - objectsForKeysMatchingRegex: @/link
 @seealso    @link objectsMatchingRegex: - objectsMatchingRegex: @/link
*/
- (NSArray *)keysMatchingRegex:(id)aRegex;
/*!
 @method     keysForObjectsMatchingRegex:
 @tocgroup   NSDictionary Accessing Keys and Values
 @abstract   Returns an array containing the keys in the receiver whose object is matched by <span class="argument">aRegex</span>.
 @result     Returns a @link NSArray NSArray @/link with a count of <span class="code">0</span> if there are no matches.
 @seealso    @link keysMatchingRegex: - keysMatchingRegex: @/link
 @seealso    @link objectsForKeysMatchingRegex: - objectsForKeysMatchingRegex: @/link
 @seealso    @link objectsMatchingRegex: - objectsMatchingRegex: @/link
*/
- (NSArray *)keysForObjectsMatchingRegex:(id)aRegex;

/*!
 @method     objectsForKeysMatchingRegex:
 @tocgroup   NSDictionary Accessing Keys and Values
 @abstract   Returns an array containing the objects in the receiver whose key is matched by <span class="argument">aRegex</span>.
 @result     Returns a @link NSArray NSArray @/link with a count of <span class="code">0</span> if there are no matches.
 @seealso    @link keysForObjectsMatchingRegex: - keysForObjectsMatchingRegex: @/link
 @seealso    @link keysMatchingRegex: - keysMatchingRegex: @/link
 @seealso    @link objectsMatchingRegex: - objectsMatchingRegex: @/link
*/
- (NSArray *)objectsForKeysMatchingRegex:(id)aRegex;
/*!
 @method     objectsMatchingRegex:
 @tocgroup   NSDictionary Accessing Keys and Values
 @abstract   Returns an array containing the objects in the receiver that are matched by <span class="argument">aRegex</span>.
 @result     Returns a @link NSArray NSArray @/link with a count of <span class="code">0</span> if there are no matches.
 @seealso    @link keysForObjectsMatchingRegex: - keysForObjectsMatchingRegex: @/link
 @seealso    @link keysMatchingRegex: - keysMatchingRegex: @/link
 @seealso    @link objectsForKeysMatchingRegex: - objectsForKeysMatchingRegex: @/link
*/
- (NSArray *)objectsMatchingRegex:(id)regexObject;

 @end

/*!
 @toc        NSMutableDictionary
 @group      Adding Entries
 @group      Removing Entries
*/

 @interface NSMutableDictionary (RegexKitAdditions)

/*!
 @method     addEntriesFromDictionary:withKeysMatchingRegex:
 @tocgroup   NSMutableDictionary Adding Entries
 @abstract   Adds to the receiver the entries from <span class="argument">otherDictionary</span> whose keys are matched by <span class="argument">aRegex</span>.
 @discussion Does nothing if none of the <span class="argument">otherDictionary</span> keys are matched by <span class="argument">aRegex</span>.
 @param      otherDictionary The dictionary from which to add entries.
 @param      aRegex A regular expression string or @link RKRegex RKRegex @/link object.
*/
- (void)addEntriesFromDictionary:(id)otherDictionary withKeysMatchingRegex:(id)aRegex;
/*!
 @method     addEntriesFromDictionary:withObjectsMatchingRegex:
 @tocgroup   NSMutableDictionary Adding Entries
 @abstract   Adds to the receiver the entries from <span class="argument">otherDictionary</span> whose objects are matched by <span class="argument">aRegex</span>.
 @discussion Does nothing if none of the <span class="argument">otherDictionary</span> objects are matched by <span class="argument">aRegex</span>.
 @param      otherDictionary The dictionary from which to add entries.
 @param      aRegex A regular expression string or @link RKRegex RKRegex @/link object.
*/
- (void)addEntriesFromDictionary:(id)otherDictionary withObjectsMatchingRegex:(id)aRegex;

/*!
 @method     removeObjectsMatchingRegex:
 @tocgroup   NSMutableDictionary Removing Entries
 @abstract   Removes from the receiver the entries whose objects are matched by <span class="argument">aRegex</span>.
 @discussion Does nothing if none of the receivers objects are matched by <span class="argument">aRegex</span>.
*/
- (void)removeObjectsMatchingRegex:(id)aRegex;
/*!
 @method     removeObjectsForKeysMatchingRegex:
 @tocgroup   NSMutableDictionary Removing Entries
 @abstract   Removes from the receiver the entries whose keys are matched by <span class="argument">aRegex</span>.
 @discussion Does nothing if none of the receivers keys are matched by <span class="argument">aRegex</span>.
*/
- (void)removeObjectsForKeysMatchingRegex:(id)aRegex;


@end

#endif // _REGEXKIT_NSDICTIONARY_H_
    
#ifdef __cplusplus
  }  /* extern "C" */
#endif
