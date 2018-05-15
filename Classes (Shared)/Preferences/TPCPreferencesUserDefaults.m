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

#include "BuildConfig.h"

#import "TPCPreferencesUserDefaults.h"

/* TPCPreferencesUserDefaults is specifically designed for reading and writing
 from the main app's preferences file, even within an XPC service. */
/* NSUserDefaults can be used in an XPC service if service speific preferences
 need to be retained somehow. */

NS_ASSUME_NONNULL_BEGIN

NSString * const TPCPreferencesUserDefaultsDidChangeNotification = @"TPCPreferencesUserDefaultsDidChangeNotification";

#pragma mark -
#pragma mark Reading & Writing

#if TEXTUAL_BUILDING_XPC_SERVICE == 1
@interface NSUserDefaults ()
- (void)setObject:(nullable id)value forKey:(NSString *)defaultName inDomain:(NSString *)domainName;
@end
#endif

@implementation TPCPreferencesUserDefaults

+ (TPCPreferencesUserDefaults *)sharedUserDefaults
{
	static id sharedSelf = nil;

	static dispatch_once_t onceToken;

	dispatch_once(&onceToken, ^{
		sharedSelf = [[super allocWithZone:NULL] _init];
	});

	return sharedSelf;
}

+ (instancetype)alloc
{
	return [self sharedUserDefaults];
}

+ (instancetype)allocWithZone:(struct _NSZone *)zone
{
	return [self sharedUserDefaults];
}

- (instancetype)_init
{
#if TEXTUAL_BUILT_INSIDE_SANDBOX == 0 || TEXTUAL_BUILDING_XPC_SERVICE == 1
	TPCPreferencesUserDefaults *defaults = [super initWithSuiteName:nil];

#if TEXTUAL_BUILDING_XPC_SERVICE == 1
	[defaults addSuiteNamed:TXBundleBuildGroupContainerIdentifier];
#endif

	return defaults;
#else
	return [super initWithSuiteName:TXBundleBuildGroupContainerIdentifier];
#endif
}

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wobjc-designated-initializers"
- (instancetype)init
{
	return [self.class sharedUserDefaults];
}

- (nullable instancetype)initWithSuiteName:(nullable NSString *)suitename
{
	return [self.class sharedUserDefaults];
}

- (nullable instancetype)initWithUser:(NSString *)username
{
	return [self.class sharedUserDefaults];
}
#pragma clang diagnostic pop

- (void)_setObject:(nullable id)value forKey:(NSString *)defaultName
{
#if TEXTUAL_BUILDING_XPC_SERVICE == 1
	[super setObject:value forKey:defaultName inDomain:TXBundleBuildGroupContainerIdentifier];
#else
	[super setObject:value forKey:defaultName];
#endif
}

- (void)setObject:(nullable id)value forKey:(NSString *)defaultName
{
	[self setObject:value forKey:defaultName postNotification:YES];
}

- (void)setObject:(nullable id)value forKey:(NSString *)defaultName postNotification:(BOOL)postNotification
{
	NSParameterAssert(defaultName != nil);

	id oldValue = [self objectForKey:defaultName];

	if (oldValue && oldValue == value) {
		return;
	}

	[self willChangeValueForKey:defaultName];

	if (value == nil) {
		if (oldValue) {
			[self _setObject:nil forKey:defaultName];
		}
	} else {
		[self _setObject:value forKey:defaultName];
	}

	[self didChangeValueForKey:defaultName];

	if (postNotification) {
		[RZNotificationCenter() postNotificationName:TPCPreferencesUserDefaultsDidChangeNotification
											  object:self
											userInfo:@{@"changedKey" : defaultName}];

		/* We currently don't need to communicate preferences changes between the
		 main app and XPC services, but if we do, then we should enable this code. */
#if 0
		[RZDistributedNotificationCenter() postNotificationName:TPCPreferencesUserDefaultsDidChangeNotification
														 object:@"TPCPreferencesUserDefaults"
													   userInfo:@{@"changedKey" : defaultName}];
#endif
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

- (void)registerDefault:(id <NSCopying>)value forKey:(NSString *)defaultName
{
	NSParameterAssert(value != nil);
	NSParameterAssert(defaultName != nil);

	[self registerDefaults:@{defaultName : value}];
}

- (NSDictionary<NSString *, id> *)registeredDefaults
{
	return [self volatileDomainForName:NSRegistrationDomain];
}

@end

NS_ASSUME_NONNULL_END
