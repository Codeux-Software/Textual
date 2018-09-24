/* *********************************************************************
 *                  _____         _               _
 *                 |_   _|____  _| |_ _   _  __ _| |
 *                   | |/ _ \ \/ / __| | | |/ _` | |
 *                   | |  __/>  <| |_| |_| | (_| | |
 *                   |_|\___/_/\_\\__|\__,_|\__,_|_|
 *
 * Copyright (c) 2010 - 2016 Codeux Software, LLC & respective contributors.
 *       Please see Acknowledgements.pdf for additional information.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *
 *  * Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 *  * Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 *  * Neither the name of Textual, "Codeux Software, LLC", nor the
 *    names of its contributors may be used to endorse or promote products
 *    derived from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE AUTHOR AND CONTRIBUTORS ``AS IS'' AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED. IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE LIABLE
 * FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
 * OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
 * LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
 * OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
 * SUCH DAMAGE.
 *
 *********************************************************************** */

NS_ASSUME_NONNULL_BEGIN

#pragma mark -
#pragma mark Immutable Object

@interface IRCHighlightMatchCondition : NSObject <NSCopying, NSMutableCopying>
@property (readonly, copy) NSString *uniqueIdentifier;
@property (readonly, copy) NSString *matchKeyword;
@property (readonly, copy, nullable) NSString *matchChannelId;
@property (readonly) BOOL matchIsExcluded;

- (instancetype)initWithDictionary:(NSDictionary<NSString *, id> *)dic NS_DESIGNATED_INITIALIZER;
- (NSDictionary<NSString *, id> *)dictionaryValue;

- (id)uniqueCopy;
- (id)uniqueCopyMutable;
@end

#pragma mark -
#pragma mark Mutable Object

@interface IRCHighlightMatchConditionMutable : IRCHighlightMatchCondition
@property (nonatomic, copy, readwrite) NSString *matchKeyword;
@property (nonatomic, copy, readwrite, nullable) NSString *matchChannelId;
@property (nonatomic, assign, readwrite) BOOL matchIsExcluded;
@end

NS_ASSUME_NONNULL_END
