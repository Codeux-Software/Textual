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

NSString * const TPCPreferencesUserDefaultsDidChangeNotification = @"TPCPreferencesUserDefaultsDidChangeNotification";

#pragma mark -
#pragma mark Reading & Writing

@implementation TPCPreferencesUserDefaults

+ (TPCPreferencesUserDefaults *)sharedUserDefaults
{
	static id sharedSelf = nil;

	static dispatch_once_t onceToken;

	dispatch_once(&onceToken, ^{
		sharedSelf = [[super allocWithZone:NULL] _t_init];
	});

	return sharedSelf;
}

+ (instancetype)alloc
{
	return [TPCPreferencesUserDefaults sharedUserDefaults];
}

+ (instancetype)allocWithZone:(struct _NSZone *)zone
{
	return [TPCPreferencesUserDefaults sharedUserDefaults];
}

- (instancetype)_t_init
{
	if ([XRSystemInformation isUsingOSXMavericksOrLater]) {
#if TEXTUAL_BUILT_INSIDE_SANDBOX == 1
		return [super initWithSuiteName:TXBundleBuildGroupContainerIdentifier];
#else
		return [super initWithSuiteName:nil];
#endif
	} else {
		return [super initWithUser:NSUserName()];
	}
}

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wobjc-designated-initializers"
- (instancetype)init
{
	return [TPCPreferencesUserDefaults sharedUserDefaults];
}

- (nullable instancetype)initWithSuiteName:(nullable NSString *)suitename
{
	return [TPCPreferencesUserDefaults sharedUserDefaults];
}

- (nullable instancetype)initWithUser:(NSString *)username
{
	return [TPCPreferencesUserDefaults sharedUserDefaults];
}
#pragma clang diagnostic pop

- (void)setObject:(nullable id)value forKey:(NSString *)defaultName
{
	[self setObject:value forKey:defaultName postNotification:YES];
}

- (void)setObject:(nullable id)value forKey:(NSString *)defaultName postNotification:(BOOL)postNotification
{
	NSParameterAssert(defaultName != nil);

	id oldValue = [self objectForKey:defaultName];

	if (oldValue && NSObjectsAreEqual(value, oldValue)) {
		return;
	}

	[self willChangeValueForKey:defaultName];

	if (value == nil) {
		if (oldValue) {
			[super setObject:nil forKey:defaultName];
		}
	} else {
		[super setObject:value forKey:defaultName];
	}

	[self didChangeValueForKey:defaultName];

	if (postNotification) {
		[RZNotificationCenter() postNotificationName:TPCPreferencesUserDefaultsDidChangeNotification
											  object:self
											userInfo:@{@"changedKey" : defaultName}];
	}
}

- (void)setInteger:(NSInteger)value forKey:(NSString *)defaultName
{
	[self setObject:@(value) forKey:defaultName];
}

- (void)setUnsignedInteger:(NSUInteger)value forKey:(NSString *)defaultName
{
	[self setObject:@(value) forKey:defaultName];
}

- (void)setShort:(short)value forKey:(NSString *)defaultName
{
	[self setObject:@(value) forKey:defaultName];
}

- (void)setUnsignedShort:(unsigned short)value forKey:(NSString *)defaultName
{
	[self setObject:@(value) forKey:defaultName];
}

- (void)setLong:(long)value forKey:(NSString *)defaultName
{
	[self setObject:@(value) forKey:defaultName];
}

- (void)setUnsignedLong:(unsigned long)value forKey:(NSString *)defaultName
{
	[self setObject:@(value) forKey:defaultName];
}

- (void)setLongLong:(long long)value forKey:(NSString *)defaultName
{
	[self setObject:@(value) forKey:defaultName];
}

- (void)setUnsignedLongLong:(unsigned long long)value forKey:(NSString *)defaultName
{
	[self setObject:@(value) forKey:defaultName];
}

- (void)setFloat:(float)value forKey:(NSString *)defaultName
{
	[self setObject:@(value) forKey:defaultName];
}

- (void)setDouble:(double)value forKey:(NSString *)defaultName
{
	[self setObject:@(value) forKey:defaultName];
}

- (void)setBool:(BOOL)value forKey:(NSString *)defaultName
{
	[self setObject:@(value) forKey:defaultName];
}

- (void)setURL:(nullable NSURL *)value forKey:(NSString *)defaultName
{
	[self setObject:value forKey:defaultName];
}

- (void)removeObjectForKey:(NSString *)defaultName
{
	[self setObject:nil forKey:defaultName];
}

+ (BOOL)keyIsExcludedFromBeingExported:(NSString *)key
{
	NSParameterAssert(key != nil);

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
		if ([cachedObject isEqualToString:@"="]) {
			if ([key isEqualToString:cachedKey] == NO) {
				return;
			}
		} else if ([cachedObject isEqualToString:@"PREFIX"]) {
			if ([key hasPrefix:cachedKey] == NO) {
				return;
			}
		} else if ([cachedObject isEqualToString:@"SUFFIX"]) {
			if ([key hasSuffix:cachedKey] == NO) {
				return;
			}
		}

		*stop = YES;
			
		returnValue = YES;
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

		 sharedSelf = [[super allocWithZone:NULL] _t_initWithDefaults:defaults initialValues:nil];

		[sharedSelf setAppliesImmediately:YES];
	});

	return sharedSelf;
}

- (instancetype)_t_initWithDefaults:(nullable NSUserDefaults *)defaults initialValues:(nullable NSDictionary<NSString *, id> *)initialValues
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
