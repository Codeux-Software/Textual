/* ********************************************************************* 
                  _____         _               _
                 |_   _|____  _| |_ _   _  __ _| |
                   | |/ _ \ \/ / __| | | |/ _` | |
                   | |  __/>  <| |_| |_| | (_| | |
                   |_|\___/_/\_\\__|\__,_|\__,_|_|

 Copyright (c) 2010 - 2015 Codeux Software, LLC & respective contributors.
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

NS_ASSUME_NONNULL_BEGIN

#define _reservedSlotDictionaryKey			@"Reserved Information"

@implementation IRCCommandIndex

static NSArray *_cachedPublicCommandList = nil;

static NSCache *_publicIndexLookupCache = nil;
static NSCache *_privateIndexLookupCache = nil;

static NSDictionary *IRCCommandIndexPublicValues = nil;
static NSDictionary *IRCCommandIndexPrivateValues = nil;

+ (void)populateCommandIndex
{
	static dispatch_once_t onceToken;

	dispatch_once(&onceToken, ^{
		[self _populateCommandIndex];
	});
}

+ (void)_populateCommandIndex
{
	/* Populate public data */
	NSDictionary *publicValues = [TPCResourceManager loadContentsOfPropertyListInResources:@"IRCCommandIndexPublicValues"];

	if (publicValues) {
		NSMutableDictionary *publicValuesMutable = [publicValues mutableCopy];

		[publicValuesMutable removeObjectForKey:_reservedSlotDictionaryKey];

		IRCCommandIndexPublicValues = [publicValuesMutable copy];
	}

	/* Populate private data */
	NSDictionary *privateValues = [TPCResourceManager loadContentsOfPropertyListInResources:@"IRCCommandIndexPrivateValues"];

	if (privateValues) {
		NSMutableDictionary *privateValuesMutable = [privateValues mutableCopy];

		[privateValuesMutable removeObjectForKey:_reservedSlotDictionaryKey];

		IRCCommandIndexPrivateValues = [privateValuesMutable copy];
	}
	
	/* Only error checking we need. It either fails or succeeds. */
	NSParameterAssert(IRCCommandIndexPrivateValues != nil);
	NSParameterAssert(IRCCommandIndexPublicValues != nil);

	/* Prepare caches */
	_publicIndexLookupCache = [NSCache new];
	_publicIndexLookupCache.countLimit = 35;

	_privateIndexLookupCache = [NSCache new];
	_privateIndexLookupCache.countLimit = 35;
}

+ (void)_invalidateCaches
{
	_cachedPublicCommandList = nil;

	[_publicIndexLookupCache removeAllObjects];
	[_privateIndexLookupCache removeAllObjects];
}

+ (void)cacheValue:(id)cachedValue withKey:(NSString *)cachedKey publicCache:(BOOL)publicCache
{
	NSParameterAssert(cachedValue != nil);
	NSParameterAssert(cachedKey != nil);

	if (publicCache) {
		[_publicIndexLookupCache setObject:cachedValue forKey:cachedKey];
	} else {
		[_privateIndexLookupCache setObject:cachedValue forKey:cachedKey];
	}
}

+ (nullable id)cachedValueForKey:(NSString *)cachedKey publicCache:(BOOL)publicCache
{
	NSParameterAssert(cachedKey != nil);

	NSDictionary *cachedValue = nil;

	if (publicCache) {
		cachedValue = [_publicIndexLookupCache objectForKey:cachedKey];
	} else {
		cachedValue = [_privateIndexLookupCache objectForKey:cachedKey];
	}

	return cachedValue;
}

+ (NSDictionary<NSString *, NSDictionary *> *)IRCCommandIndex:(BOOL)publicIndex
{
	if (publicIndex) {
		return IRCCommandIndexPublicValues;
	} else {
		return IRCCommandIndexPrivateValues;
	}
}

+ (NSArray<NSString *> *)publicIRCCommandList
{
	if (_cachedPublicCommandList == nil) {
		NSMutableArray<NSString *> *commandList = [NSMutableArray array];
		
		BOOL developerModeEnabled = [TPCPreferences developerModeEnabled];

		[IRCCommandIndexPublicValues enumerateKeysAndObjectsUsingBlock:^(NSString *indexKey, NSDictionary *indexValue, BOOL *stop) {
			BOOL developerOnly = [indexValue boolForKey:@"developerModeOnly"];

			if (developerModeEnabled == NO && developerOnly) {
				return;
			}

			[commandList addObject:indexValue[@"command"]];
		}];

		_cachedPublicCommandList = [commandList copy];
	}

	return _cachedPublicCommandList;
}

+ (nullable NSDictionary *)indexFromIndexKey:(NSString *)indexKey publicSearch:(BOOL)publicSearch
{
	NSDictionary *indexSet = [IRCCommandIndex IRCCommandIndex:publicSearch];

	NSDictionary *index = indexSet[indexKey];

	if (index == nil) {
		NSString *indexKeyCaseless = [indexSet keyIgnoringCase:indexSet];

		if (indexKeyCaseless) {
			index = indexSet[indexKeyCaseless];
		}
	}

	return index;
}

+ (nullable NSString *)IRCCommandFromIndexKey:(NSString *)indexKey publicSearch:(BOOL)publicSearch
{
	NSParameterAssert(indexKey != nil);

	NSString *cachedKey = [NSString stringWithFormat:@"%s-%@", _cmd, indexKey];

	NSString *cachedValue = [IRCCommandIndex cachedValueForKey:cachedKey publicCache:publicSearch];

	if (cachedValue == nil) {
		LogToConsoleDebug("Cache miss for %{public}@", indexKey)

		NSDictionary *index = [IRCCommandIndex indexFromIndexKey:indexKey publicSearch:publicSearch];

		if (index) {
			cachedValue = index[@"command"];

			[IRCCommandIndex cacheValue:cachedValue withKey:cachedKey publicCache:publicSearch];
		}
	}

	return cachedValue;
}

NSString * _Nullable IRCPrivateCommandIndex(const char *indexKey)
{
	return [IRCCommandIndex IRCCommandFromIndexKey:@(indexKey) publicSearch:NO];
}

NSString * _Nullable IRCPublicCommandIndex(const char *indexKey)
{
	return [IRCCommandIndex IRCCommandFromIndexKey:@(indexKey) publicSearch:YES];
}

+ (NSUInteger)indexOfIRCommand:(NSString *)command
{
	return [IRCCommandIndex indexOfIRCommand:command publicSearch:YES];
}

+ (NSUInteger)_indexOfIRCommand:(NSString *)command publicSearch:(BOOL)publicSearch
{
	NSParameterAssert(command != nil);

	NSDictionary *searchPath = [IRCCommandIndex IRCCommandIndex:publicSearch];

	BOOL developerModeEnabled = [TPCPreferences developerModeEnabled];

	__block NSDictionary *index = nil;

	[searchPath enumerateKeysAndObjectsUsingBlock:^(NSString *indexKey, NSDictionary *indexValue, BOOL *stop) {
		NSString *indexCommand = indexValue[@"command"];

		if ([indexCommand isEqualIgnoringCase:command] == NO) {
			return;
		}

		if (publicSearch) {
			BOOL isDeveloperOnly = [indexValue boolForKey:@"developerModeOnly"];

			if (isDeveloperOnly && developerModeEnabled == NO) {
				return;
			}
		} else {
			BOOL isStandalone = [indexValue boolForKey:@"isStandalone"];

			if (isStandalone == NO) {
				return;
			}
		}

		index = indexValue;

		*stop = YES;
	}];

	if (index) {
		return [index unsignedIntegerForKey:@"indexValue"];
	}

	return NSNotFound;
}

+ (NSUInteger)indexOfIRCommand:(NSString *)command publicSearch:(BOOL)publicSearch
{
	NSParameterAssert(command != nil);

	NSString *cachedKey = [NSString stringWithFormat:@"%s-%@", _cmd, command];

	NSNumber *cachedValue = [IRCCommandIndex cachedValueForKey:cachedKey publicCache:publicSearch];

	if (cachedValue == nil) {
		LogToConsoleDebug("Cache miss for %{public}@", command)

		NSUInteger index = [IRCCommandIndex _indexOfIRCommand:command publicSearch:publicSearch];

		if (index != NSNotFound) {
			cachedValue = @(index);

			[IRCCommandIndex cacheValue:cachedValue withKey:cachedKey publicCache:publicSearch];
		}
	}

	if (cachedValue) {
		return cachedValue.unsignedIntegerValue;
	}

	return NSNotFound;
}

+ (NSUInteger)_colonIndexForCommand:(NSString *)command
{
	NSParameterAssert(command != nil);

	/* The command index that Textual uses is complex for anyone who
	 has never seen it before, but on the other hand, it is also very
	 convenient for storing static information about any IRC command
	 that Textual may handle. For example, the internal command list
	 keeps track of where the colon (:) should be placed for specific
	 outgoing commands. Better than guessing. */
	__block NSUInteger index = NSNotFound;

	[IRCCommandIndexPrivateValues enumerateKeysAndObjectsUsingBlock:^(NSString *indexKey, NSDictionary *indexValue, BOOL *stop) {
		if ([indexValue boolForKey:@"isStandalone"] == NO) {
			return;
		}

		NSString *indexCommand = indexValue[@"command"];

		if ([indexCommand isEqualIgnoringCase:command]) {
			NSInteger colonIndex = [indexValue integerForKey:@"outgoingColonIndex"];

			if (colonIndex >= 0) {
				index = colonIndex;
			}

			*stop = YES;
		}
	}];

	return index;
}

+ (NSUInteger)colonIndexForCommand:(NSString *)command
{
	NSParameterAssert(command != nil);

	NSString *cachedKey = [NSString stringWithFormat:@"%s-%@", _cmd, command];

	NSNumber *cachedValue = [IRCCommandIndex cachedValueForKey:cachedKey publicCache:NO];

	if (cachedValue == nil) {
		LogToConsoleDebug("Cache miss for %{public}@", command)

		NSUInteger index = [IRCCommandIndex _colonIndexForCommand:command];

		if (index != NSNotFound) {
			cachedValue = @(index);

			[IRCCommandIndex cacheValue:cachedValue withKey:cachedKey publicCache:NO];
		}
	}

	if (cachedValue) {
		return cachedValue.unsignedIntegerValue;
	}

	return NSNotFound;
}

@end

NS_ASSUME_NONNULL_END
