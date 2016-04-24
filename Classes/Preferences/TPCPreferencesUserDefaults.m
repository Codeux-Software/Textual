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

#import "TextualApplication.h"

#import "TPCPreferencesUserDefaultsPrivate.h"

#import "BuildConfig.h"

NSString * const TPCPreferencesUserDefaultsDidChangeNotification = @"TPCPreferencesUserDefaultsDidChangeNotification";

#pragma mark -
#pragma mark Reading & Writing

@implementation TPCPreferencesUserDefaults

+ (TPCPreferencesUserDefaults *)sharedUserDefaults
{
	static id sharedSelf = nil;

	static dispatch_once_t onceToken;

	dispatch_once(&onceToken, ^{
		sharedSelf = [[super allocWithZone:NULL] protectedInit];
	});

	return sharedSelf;
}

+ (id)alloc
{
	return [TPCPreferencesUserDefaults sharedUserDefaults];
}

+ (id)allocWithZone:(struct _NSZone *)zone
{
	return [TPCPreferencesUserDefaults sharedUserDefaults];
}

- (id)protectedInit
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

- (instancetype)initWithSuiteName:(NSString *)suitename
{
	return [TPCPreferencesUserDefaults sharedUserDefaults];
}

- (instancetype)initWithUser:(NSString *)username
{
	return [TPCPreferencesUserDefaults sharedUserDefaults];
}
#pragma clang diagnostic pop

- (void)setObject:(id)value forKey:(NSString *)defaultName
{
	[self setObject:value forKey:defaultName postNotification:YES];
}

- (void)setObject:(id)value forKey:(NSString *)defaultName postNotification:(BOOL)postNotification
{
	[self willChangeValueForKey:defaultName];

	if (value == nil) {
		if ([self objectForKey:defaultName] == nil) {
			;
		} else {
			[super setObject:nil forKey:defaultName];
		}
	} else {
		[super setObject:value forKey:defaultName];
	}

	[self didChangeValueForKey:defaultName];

	if (postNotification) {
		[RZNotificationCenter() postNotificationName:TPCPreferencesUserDefaultsDidChangeNotification object:self userInfo:@{@"changedKey" : defaultName}];
	}
}

- (void)setInteger:(NSInteger)value forKey:(NSString *)defaultName
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

- (void)setURL:(NSURL *)url forKey:(NSString *)defaultName
{
	[self setObject:url forKey:defaultName];
}

- (void)setColor:(NSColor *)color forKey:(NSString *)defaultName
{
	[self setObject:[NSArchiver archivedDataWithRootObject:color] forKey:defaultName];
}

- (NSColor *)colorForKey:(NSString *)defaultName
{
	id objectValue = [self objectForKey:defaultName];

	if (objectValue == nil) {
		return nil;
	}

	return [NSUnarchiver unarchiveObjectWithData:objectValue];
}

- (void)removeObjectForKey:(NSString *)defaultName
{
	[self setObject:nil forKey:defaultName];
}

+ (BOOL)keyIsExcludedFromBeingExported:(NSString *)key
{
	/* Find cached list of excluded keys or build from disk. */
	NSDictionary *cachedValues = [[masterController() sharedApplicationCacheObject] objectForKey:
			@"TPCPreferencesUserDefaults -> TPCPreferencesUserDefaults Keys Excluded from Export"];

	if (cachedValues == nil) {
		NSDictionary *staticValues = [TPCResourceManager loadContentsOfPropertyListInResources:@"StaticStore"];

		NSDictionary *_blockedNames = [staticValues dictionaryForKey:@"TPCPreferencesUserDefaults Keys Excluded from Export"];

		[[masterController() sharedApplicationCacheObject] setObject:_blockedNames forKey:
		 @"TPCPreferencesUserDefaults -> TPCPreferencesUserDefaults Keys Excluded from Export"];

		cachedValues = _blockedNames;
	}

	/* Using cached list of excluded keys, perform comparison on each. */
	for (NSString *blockedName in cachedValues) {
		NSString *comparisonOperator = cachedValues[blockedName];

		if ([comparisonOperator isEqualToString:@"="]) {
			if ([key isEqualToString:blockedName]) {
				return YES;
			}
		} else if ([comparisonOperator isEqualToString:@"PREFIX"]) {
			if ([key hasPrefix:blockedName]) {
				return YES;
			}
		} else if ([comparisonOperator isEqualToString:@"SUFFIX"]) {
			if ([key hasSuffix:blockedName]) {
				return YES;
			}
		}
	}

	/* Default to the key not being excluded. */
	return NO;
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
		 sharedSelf = [[super allocWithZone:NULL] protectedInitWithDefaults:[TPCPreferencesUserDefaults sharedUserDefaults] initialValues:nil];

		[sharedSelf setAppliesImmediately:YES];
	});

	return sharedSelf;
}

- (id)protectedInitWithDefaults:(NSUserDefaults *)defaults initialValues:(NSDictionary *)initialValues
{
	return [super initWithDefaults:defaults initialValues:initialValues];
}

+ (id)alloc
{
	return [TPCPreferencesUserDefaultsController sharedUserDefaultsController];
}

+ (id)allocWithZone:(struct _NSZone *)zone
{
	return [TPCPreferencesUserDefaultsController sharedUserDefaultsController];
}

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wobjc-designated-initializers"
- (instancetype)init
{
	return [TPCPreferencesUserDefaultsController sharedUserDefaultsController];
}

- (instancetype)initWithCoder:(NSCoder *)coder
{
	return [TPCPreferencesUserDefaultsController sharedUserDefaultsController];
}

- (instancetype)initWithDefaults:(NSUserDefaults *)defaults initialValues:(NSDictionary *)initialValues
{
	return [TPCPreferencesUserDefaultsController sharedUserDefaultsController];
}
#pragma clang diagnostic pop

- (id)defaults
{
	return [TPCPreferencesUserDefaults sharedUserDefaults];
}

@end
