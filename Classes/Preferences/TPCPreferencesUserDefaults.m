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

#import "TPCResourceManager.h"
#import "TPCPreferencesUserDefaultsLocal.h"

NS_ASSUME_NONNULL_BEGIN

#pragma mark -
#pragma mark Reading & Writing

@implementation TPCPreferencesUserDefaults (TPCPreferencesUserDefaultsLocal)

+ (BOOL)key:(NSString *)defaultName1 matchesKey:(NSString *)defaultName2 usingMatchingPattern:(NSString *)matchingPattern
{
	NSParameterAssert(defaultName1 != nil);
	NSParameterAssert(defaultName2 != nil);
	NSParameterAssert(matchingPattern != nil);

	if ([matchingPattern isEqualToString:@"="]) {
		if ([defaultName1 isEqualToString:defaultName2]) {
			return YES;
		}
	} else if ([matchingPattern isEqualToString:@"PREFIX"]) {
		if ([defaultName1 hasPrefix:defaultName2]) {
			return YES;
		}
	} else if ([matchingPattern isEqualToString:@"SUFFIX"]) {
		if ([defaultName1 hasSuffix:defaultName2]) {
			return YES;
		}
	}

	return NO;
}

+ (BOOL)keyIsExcludedFromBeingExported:(NSString *)defaultName
{
	NSParameterAssert(defaultName != nil);

	static NSDictionary<NSString *, NSString *> *cachedValues = nil;

	static dispatch_once_t onceToken;

	dispatch_once(&onceToken, ^{
		NSDictionary *staticValues =
		[TPCResourceManager loadContentsOfPropertyListInResources:@"StaticStore"];

		cachedValues =
		[staticValues dictionaryForKey:@"TPCPreferencesUserDefaults Keys Excluded from Export"];
	});

	__block BOOL returnValue = NO;

	[cachedValues enumerateKeysAndObjectsUsingBlock:^(NSString *cachedKey, NSString *cachedObject, BOOL *stop) {
		if ([self key:defaultName matchesKey:cachedKey usingMatchingPattern:cachedObject]) {
			*stop = YES;

			returnValue = YES;
		}
	}];

	return returnValue;
}

+ (BOOL)keyIsObsolete:(NSString *)defaultName
{
	NSParameterAssert(defaultName != nil);

	static NSDictionary<NSString *, NSString *> *cachedValues = nil;

	static dispatch_once_t onceToken;

	dispatch_once(&onceToken, ^{
		NSDictionary *staticValues =
		[TPCResourceManager loadContentsOfPropertyListInResources:@"StaticStore"];

		cachedValues =
		[staticValues dictionaryForKey:@"TPCPreferencesUserDefaults Obsolete Keys"];
	});

	__block BOOL returnValue = NO;

	[cachedValues enumerateKeysAndObjectsUsingBlock:^(NSString *cachedKey, NSString *cachedObject, BOOL *stop) {
		if ([self key:defaultName matchesKey:cachedKey usingMatchingPattern:cachedObject]) {
			*stop = YES;

			returnValue = YES;
		}
	}];

	return returnValue;
}

@end

#pragma mark -
#pragma mark Object KVO Proxying

@implementation TPCPreferencesUserDefaultsController

+ (TPCPreferencesUserDefaultsController *)sharedUserDefaultsController
{
	static id sharedSelf = nil;

	static dispatch_once_t onceToken;

	dispatch_once(&onceToken, ^{
		TPCPreferencesUserDefaults *defaults = [TPCPreferencesUserDefaults sharedUserDefaults];

		 sharedSelf = [[super allocWithZone:NULL] _initWithDefaults:defaults initialValues:nil];

		[sharedSelf setAppliesImmediately:YES];
	});

	return sharedSelf;
}

- (instancetype)_initWithDefaults:(nullable NSUserDefaults *)defaults initialValues:(nullable NSDictionary<NSString *, id> *)initialValues
{
	return [super initWithDefaults:defaults initialValues:initialValues];
}

+ (instancetype)alloc
{
	return [TPCPreferencesUserDefaultsController sharedUserDefaultsController];
}

+ (instancetype)allocWithZone:(struct _NSZone *)zone
{
	return [TPCPreferencesUserDefaultsController sharedUserDefaultsController];
}

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wobjc-designated-initializers"
- (instancetype)init
{
	return [TPCPreferencesUserDefaultsController sharedUserDefaultsController];
}

- (nullable instancetype)initWithCoder:(NSCoder *)coder
{
	return [TPCPreferencesUserDefaultsController sharedUserDefaultsController];
}

- (instancetype)initWithDefaults:(nullable NSUserDefaults *)defaults initialValues:(nullable NSDictionary<NSString *, id> *)initialValues
{
	return [TPCPreferencesUserDefaultsController sharedUserDefaultsController];
}
#pragma clang diagnostic pop

- (id)defaults
{
	return [TPCPreferencesUserDefaults sharedUserDefaults];
}

@end

NS_ASSUME_NONNULL_END
