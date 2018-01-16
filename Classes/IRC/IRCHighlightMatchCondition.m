/* ********************************************************************* 
                  _____         _               _
                 |_   _|____  _| |_ _   _  __ _| |
                   | |/ _ \ \/ / __| | | |/ _` | |
                   | |  __/>  <| |_| |_| | (_| | |
                   |_|\___/_/\_\\__|\__,_|\__,_|_|

 Copyright (c) 2010 - 2016 Codeux Software, LLC & respective contributors.
        Please see Acknowledgements.pdf for additional information.

 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions
 are met:

    * Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the
      documentation and/or other materials provided with the distribution.
    * Neither the name of Textual and/or "Codeux Software, LLC", nor the 
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

#import "NSObjectHelperPrivate.h"
#import "IRCHighlightMatchConditionInternal.h"

NS_ASSUME_NONNULL_BEGIN

@implementation IRCHighlightMatchCondition

DESIGNATED_INITIALIZER_EXCEPTION_BODY_BEGIN
- (instancetype)init
{
	return [self initWithDictionary:@{}];
}
DESIGNATED_INITIALIZER_EXCEPTION_BODY_END

- (instancetype)initWithDictionary:(NSDictionary<NSString *, id> *)dic
{
	ObjectIsAlreadyInitializedAssert

	if ((self = [super init])) {
		[self populateDictionaryValues:dic];

		[self populateDefaultsPostflight];

		[self initializedClassHealthCheck];

		self->_objectInitialized = YES;

		return self;
	}

	return nil;
}

- (void)initializedClassHealthCheck
{
	ObjectIsAlreadyInitializedAssert

	if ([self isMutable]) {
		return;
	}

	NSParameterAssert(self->_matchKeyword.length > 0);
}

- (void)populateDictionaryValues:(NSDictionary<NSString *, id> *)dic
{
	NSParameterAssert(dic != nil);

	if ([self isMutable] == NO) {
		ObjectIsAlreadyInitializedAssert
	}

	[dic assignBoolTo:&self->_matchIsExcluded forKey:@"matchIsExcluded"];

	[dic assignStringTo:&self->_matchChannelId forKey:@"matchChannelID"];
	[dic assignStringTo:&self->_matchKeyword forKey:@"matchKeyword"];
	[dic assignStringTo:&self->_uniqueIdentifier forKey:@"uniqueIdentifier"];
}

- (void)populateDefaultsPostflight
{
	ObjectIsAlreadyInitializedAssert

	SetVariableIfNil(self->_matchKeyword, @"")

	SetVariableIfNil(self->_uniqueIdentifier, [NSString stringWithUUID])
}

- (NSDictionary<NSString *, id> *)dictionaryValue
{
	NSMutableDictionary<NSString *, id> *dic = [NSMutableDictionary dictionary];

	[dic maybeSetObject:self.matchChannelId forKey:@"matchChannelID"];
	[dic maybeSetObject:self.matchKeyword forKey:@"matchKeyword"];
	[dic maybeSetObject:self.uniqueIdentifier forKey:@"uniqueIdentifier"];

	[dic setBool:self.matchIsExcluded forKey:@"matchIsExcluded"];

	return [dic copy];
}

- (id)copyWithZone:(nullable NSZone *)zone
{
	  IRCHighlightMatchCondition *object =
	[[IRCHighlightMatchCondition allocWithZone:zone] initWithDictionary:self.dictionaryValue];

	return object;
}

- (id)mutableCopyWithZone:(nullable NSZone *)zone
{
	  IRCHighlightMatchConditionMutable *object =
	[[IRCHighlightMatchConditionMutable allocWithZone:zone] initWithDictionary:self.dictionaryValue];

	return object;
}

- (id)uniqueCopy
{
	return [self uniqueCopyAsMutable:NO];
}

- (id)uniqueCopyMutable
{
	return [self uniqueCopyAsMutable:YES];
}

- (id)uniqueCopyAsMutable:(BOOL)asMutable
{
	IRCHighlightMatchCondition *object = nil;

	if (asMutable == NO) {
		object = [self copy];
	} else {
		object = [self mutableCopy];
	}

	object->_uniqueIdentifier = [NSString stringWithUUID];

	return object;
}

- (BOOL)isMutable
{
	return NO;
}

@end

#pragma mark -

@implementation IRCHighlightMatchConditionMutable

@dynamic matchChannelId;
@dynamic matchIsExcluded;
@dynamic matchKeyword;

- (BOOL)isMutable
{
	return YES;
}

- (void)setMatchIsExcluded:(BOOL)matchIsExcluded
{
	if (self->_matchIsExcluded != matchIsExcluded) {
		self->_matchIsExcluded = matchIsExcluded;
	}
}

- (void)setMatchChannelId:(nullable NSString *)matchChannelId
{
	if (self->_matchChannelId != matchChannelId) {
		self->_matchChannelId = [matchChannelId copy];
	}
}

- (void)setMatchKeyword:(NSString *)matchKeyword
{
	NSParameterAssert(matchKeyword != nil);

	if (self->_matchKeyword != matchKeyword) {
		self->_matchKeyword = [matchKeyword copy];
	}
}

@end

NS_ASSUME_NONNULL_END
