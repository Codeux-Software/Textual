/* ********************************************************************* 
       _____        _               _    ___ ____   ____
      |_   _|___  _| |_ _   _  __ _| |  |_ _|  _ \ / ___|
       | |/ _ \ \/ / __| | | |/ _` | |   | || |_) | |
       | |  __/>  <| |_| |_| | (_| | |   | ||  _ <| |___
       |_|\___/_/\_\\__|\__,_|\__,_|_|  |___|_| \_\\____|

 Copyright (c) 2008 - 2010 Satoshi Nakagawa <psychs AT limechat DOT net>
 Copyright (c) 2010 — 2014 Codeux Software & respective contributors.
     Please see Acknowledgements.pdf for additional information.

 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions
 are met:

    * Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the
      documentation and/or other materials provided with the distribution.
    * Neither the name of the Textual IRC Client & Codeux Software nor the
      names of its contributors may be used to endorse or promote products
      derived from this software without specific prior written permission.

 THIS SOFTWARE IS PROVIDED BY THE AUTHOR AND CONTRIBUTORS ``AS IS'' AND
 ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 ARE DISCLAIMED. IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE LIABLE
 FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
 OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
 LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
 OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
 SUCH DAMAGE.

 *********************************************************************** */

#import "TextualApplication.h"

@interface NSArray (TXArrayHelper)
@property (nonatomic, readonly, assign) NSRange range;

- (id)safeObjectAtIndex:(NSInteger)n;

- (BOOL)boolAtIndex:(NSInteger)n;
- (NSArray *)arrayAtIndex:(NSInteger)n;
- (NSString *)stringAtIndex:(NSInteger)n;
- (NSDictionary *)dictionaryAtIndex:(NSInteger)n;
- (NSInteger)integerAtIndex:(NSInteger)n;
- (long long)longLongAtIndex:(NSInteger)n;
- (double)doubleAtIndex:(NSInteger)n;
- (void *)pointerAtIndex:(NSInteger)n;

- (BOOL)containsObjectIgnoringCase:(id)anObject;

- (NSArray *)arrayByInsertingSortedObject:(id)obj usingComparator:(NSComparator)comparator;

- (NSArray *)arrayByRemovingObjectAtIndex:(NSUInteger)idx;

- (NSUInteger)indexOfObjectMatchingValue:(id)value withKeyPath:(NSString *)keyPath;

- (NSUInteger)indexOfObjectMatchingValue:(id)value withKeyPath:(NSString *)keyPath usingSelector:(SEL)comparison;
@end

@interface NSMutableArray (TXMutableArrayHelper)
- (void)safeRemoveObjectAtIndex:(NSInteger)n;

- (void)safeAddObject:(id)anObject;
- (void)safeAddObjectWithoutDuplication:(id)anObject;

- (void)addBool:(BOOL)value;
- (void)addInteger:(NSInteger)value;
- (void)addLongLong:(long long)value;
- (void)addDouble:(double)value;
- (void)addPointer:(void *)value;

- (void)safeInsertObject:(id)anObject atIndex:(NSUInteger)index;

- (void)insertBool:(BOOL)value atIndex:(NSUInteger)index;
- (void)insertInteger:(NSInteger)value atIndex:(NSUInteger)index;
- (void)insertLongLong:(long long)value atIndex:(NSUInteger)index;
- (void)insertDouble:(double)value atIndex:(NSUInteger)index;
- (void)insertPointer:(void *)value atIndex:(NSUInteger)index;

- (void)performSelectorOnObjectValueAndReplace:(SEL)performSelector;

- (void)insertSortedObject:(id)obj usingComparator:(NSComparator)comparator;
@end

@interface NSIndexSet (TXIndexSetHelper)
- (NSArray *)arrayFromIndexSet;
@end
