/* ********************************************************************* 
       _____        _               _    ___ ____   ____
      |_   _|___  _| |_ _   _  __ _| |  |_ _|  _ \ / ___|
       | |/ _ \ \/ / __| | | |/ _` | |   | || |_) | |
       | |  __/>  <| |_| |_| | (_| | |   | ||  _ <| |___
       |_|\___/_/\_\\__|\__,_|\__,_|_|  |___|_| \_\\____|

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

#import "BuildConfig.h"

#define _userDefaults			[TPCPreferencesUserDefaults sharedLocalContainerUserDefaults]

#define _groupDefaults			[TPCPreferencesUserDefaults sharedGroupContainerUserDefaults]

#pragma mark -
#pragma mark Reading & Writing

@implementation TPCPreferencesUserDefaults

+ (TPCPreferencesUserDefaults *)sharedUserDefaults
{
	static id sharedSelf = nil;
	
	static dispatch_once_t onceToken;
	
	dispatch_once(&onceToken, ^{
		sharedSelf = [TPCPreferencesUserDefaults new];
	});
	
	return sharedSelf;
}

+ (NSUserDefaults *)sharedGroupContainerUserDefaults
{
	static id sharedSelf = nil;
	
	static dispatch_once_t onceToken;
	
	dispatch_once(&onceToken, ^{
		sharedSelf = [[NSUserDefaults alloc] initWithSuiteName:TXBundleBuildGroupIdentifier];
	});
	
	return sharedSelf;
}

+ (NSUserDefaults *)sharedLocalContainerUserDefaults
{
	static id sharedSelf = nil;

	static dispatch_once_t onceToken;

	dispatch_once(&onceToken, ^{
		sharedSelf = [NSUserDefaults new];
	});

	return sharedSelf;
}

- (NSDictionary *)dictionaryRepresentation
{
	/* Group container will take priority. */
	NSMutableDictionary *settings = [NSMutableDictionary dictionary];
	
	if ([CSFWSystemInformation featureAvailableToOSXMavericks]) {
		NSDictionary *groupDict = [_groupDefaults dictionaryRepresentation];
		
		for (NSString *key in groupDict) {
			settings[key] = groupDict[key];
		}
	}
	
	/* Default back to self. */
	NSDictionary *localGroup = [_userDefaults dictionaryRepresentation];
	
	for (NSString *key in localGroup) {
		if (settings[key] == nil) {
			settings[key] = localGroup[key];
		}
	}
	
	/* Return value. */
	return settings;
}

- (void)registerDefaultsForApplicationContainer:(NSDictionary *)registrationDictionary
{
	[_userDefaults registerDefaults:registrationDictionary];
}

- (void)registerDefaultsForGroupContainer:(NSDictionary *)registrationDictionary
{
	if ([CSFWSystemInformation featureAvailableToOSXMavericks]) {
		[_groupDefaults registerDefaults:registrationDictionary];
	} else {
		[_userDefaults registerDefaults:registrationDictionary];
	}
}

- (void)setObject:(id)value forKey:(NSString *)defaultName
{
	[RZUserDefaultsValueProxy() setValue:value forKey:defaultName];
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

- (id)objectForKey:(NSString *)defaultName
{
	/* Group container will take priority. */
	if ([CSFWSystemInformation featureAvailableToOSXMavericks]) {
		if ([TPCPreferencesUserDefaults keyIsExcludedFromGroupContainer:defaultName] == NO) {
			 id objectValue = [_groupDefaults objectForKey:defaultName];

			if (objectValue) {
				return objectValue;
			}
		}
	}
	
	/* Default back to self. */
	return [_userDefaults objectForKey:defaultName];
}

- (NSString *)stringForKey:(NSString *)defaultName
{
	id objectValue = [self objectForKey:defaultName];
	
	if (objectValue == nil) {
		return nil;
	}
	
	return objectValue;
}

- (NSArray *)arrayForKey:(NSString *)defaultName
{
	id objectValue = [self objectForKey:defaultName];
	
	if (objectValue == nil) {
		return nil;
	}
	
	return objectValue;
}

- (NSDictionary *)dictionaryForKey:(NSString *)defaultName
{
	id objectValue = [self objectForKey:defaultName];
	
	if (objectValue == nil) {
		return nil;
	}
	
	return objectValue;
}

- (NSData *)dataForKey:(NSString *)defaultName
{
	id objectValue = [self objectForKey:defaultName];
	
	if (objectValue == nil) {
		return nil;
	}
	
	return objectValue;
}

- (NSArray *)stringArrayForKey:(NSString *)defaultName
{
	id objectValue = [self objectForKey:defaultName];
	
	if (objectValue == nil) {
		return nil;
	}
	
	return objectValue;
}

- (NSColor *)colorForKey:(NSString *)defaultName
{
	id objectValue = [self objectForKey:defaultName];
	
	if (objectValue == nil) {
		return nil;
	}
	
	return [NSUnarchiver unarchiveObjectWithData:objectValue];
}

- (NSInteger)integerForKey:(NSString *)defaultName
{
	id objectValue = [self objectForKey:defaultName];
	
	if (objectValue == nil) {
		return 0;
	}
	
	return [objectValue integerValue];
}

- (float)floatForKey:(NSString *)defaultName
{
	id objectValue = [self objectForKey:defaultName];
	
	if (objectValue == nil) {
		return 0.0f;
	}
	
	return [objectValue floatValue];
}

- (double)doubleForKey:(NSString *)defaultName
{
	id objectValue = [self objectForKey:defaultName];
	
	if (objectValue == nil) {
		return 0.0;
	}
	
	return [objectValue doubleValue];
}

- (BOOL)boolForKey:(NSString *)defaultName
{
	id objectValue = [self objectForKey:defaultName];
	
	if (objectValue == nil) {
		return NO;
	}
	
	return [objectValue boolValue];
}

- (NSURL *)URLForKey:(NSString *)defaultName
{
	id objectValue = [self objectForKey:defaultName];
	
	if (objectValue == nil) {
		return nil;
	}
	
	return objectValue;
}

- (void)removeObjectForKey:(NSString *)defaultName
{
	[RZUserDefaultsValueProxy() willChangeValueForKey:defaultName];
	
	[super removeObjectForKey:defaultName];
	
	[RZUserDefaultsValueProxy() didChangeValueForKey:defaultName];
}

/* Keys that shall never be included in the group container. */
+ (BOOL)keyIsExcludedFromGroupContainer:(NSString *)key
{
	if ([key hasPrefix:@"NS"] ||											/* Apple owned prefix. */
		[key hasPrefix:@"SGT"] ||											/* Apple owned prefix. */
		[key hasPrefix:@"Apple"] ||											/* Apple owned prefix. */
		[key hasPrefix:@"WebKit"] ||										/* Apple owned prefix. */
		[key hasPrefix:@"com.apple."] ||									/* Apple owned prefix. */
		[key hasPrefix:@"DataDetectorsSettings"] ||							/* Apple owned prefix. */
		
		[key hasPrefix:@"HockeySDK"] ||										/* HockeyApp owned prefix. */
		
		[key hasPrefix:@"TXRunCount"] ||									/* Textual owned prefix. */
		[key hasPrefix:@"TXRunTime"] ||										/* Textual owned prefix. */
		
		[key hasPrefix:@"TextField"] ||										/* Textual owned prefix. */
		[key hasPrefix:@"System —>"] ||										/* Textual owned prefix. */
		[key hasPrefix:@"Security ->"] ||									/* Textual owned prefix. */
		[key hasPrefix:@"Window -> Main Window"] ||							/* Textual owned prefix. */
		[key hasPrefix:@"Private Extension Store -> "] ||					/* Textual owned prefix. */
		[key hasPrefix:@"Saved Window State —> Internal —> "] ||			/* Textual owned prefix. */
		[key hasPrefix:@"Saved Window State —> Internal (v2) —> "] ||		/* Textual owned prefix. */
		[key hasPrefix:@"Text Input Prompt Suppression -> "] ||				/* Textual owned prefix. */
		[key hasPrefix:@"Textual Five Migration Tool ->"] ||				/* Textual owned prefix. */
		[key hasPrefix:@"Internal Theme Settings Key-value Store -> "] ||	/* Textual owned prefix. */

		[key hasPrefix:@"TDCPreferencesControllerDidShowMountainLionDeprecationWarning"] ||					/* Textual owned prefix. */
		[key hasPrefix:@"TPCPreferencesUserDefaultsPerformedGroupContaineCleanup"] ||						/* Textual owned prefix. */
		[key hasPrefix:@"TPCPreferencesUserDefaultsLastUsedOperatingSystemSupportedGroupContainers"])		/* Textual owned prefix. */
	{
		return YES;
	}
	else
	{
		return NO;
	}
}

/* Returns YES if a key should not be migrated to the group container by -migrateValuesToGroupContainer */
+ (BOOL)keyIsSpecial:(NSString *)key
{
	if ([key hasPrefix:@"TPCPreferencesUserDefaultsLastUsedOperatingSystemSupportedGroupContainers"] ||
		[key hasPrefix:@"TPCPreferencesUserDefaultsPerformedGroupContaineCleanup"])
	{
		return YES;
	}
	else
	{
		return NO;
	}
}

/* Performs a one time migration of sandbox level keys to the group container. */
- (void)migrateValuesToGroupContainer
{
	if ([CSFWSystemInformation featureAvailableToOSXMavericks]) {
		id usesGroupContainer = [_userDefaults objectForKey:@"TPCPreferencesUserDefaultsLastUsedOperatingSystemSupportedGroupContainers"];
		
		if (usesGroupContainer) { // make sure the key even exists (non-nil)
			if ([usesGroupContainer boolValue] == NO) {
				NSDictionary *localDictionary = [_userDefaults dictionaryRepresentation];
				
				for (NSString *dictKey in localDictionary) {
					if ([TPCPreferencesUserDefaults keyIsExcludedFromGroupContainer:dictKey] == NO &&
						[TPCPreferencesUserDefaults keyIsSpecial:dictKey] == NO)
					{
						if ([_groupDefaults objectForKey:dictKey] == nil) {
							[_groupDefaults setObject:localDictionary[dictKey] forKey:dictKey];
						}
					}
				}
			}
		}
		
		[_userDefaults setBool:YES forKey:@"TPCPreferencesUserDefaultsLastUsedOperatingSystemSupportedGroupContainers"];
	} else {
		[_userDefaults setBool:NO forKey:@"TPCPreferencesUserDefaultsLastUsedOperatingSystemSupportedGroupContainers"];
	}
}

/* Does a traversal of the group container looking for keys that do not belong there
 and remove those so that the incorrect value is not maintained. */
- (void)purgeKeysThatDontBelongInGroupContainer
{
	if ([CSFWSystemInformation featureAvailableToOSXMavericks]) {
		NSDictionary *groupDictionary = [_groupDefaults dictionaryRepresentation];

		for (NSString *dictKey in groupDictionary) {
			if ([TPCPreferencesUserDefaults keyIsExcludedFromGroupContainer:dictKey]) {
				[_groupDefaults removeObjectForKey:dictKey];
			}
		}
	}
}

@end

#pragma mark -
#pragma mark Object KVO Proxying

@implementation TPCPreferencesUserDefaultsObjectProxy

+ (id)userDefaultValues
{
	static id sharedSelf = nil;
	
	static dispatch_once_t onceToken;
	
	dispatch_once(&onceToken, ^{
		sharedSelf = [TPCPreferencesUserDefaultsObjectProxy new];
	});
	
	return sharedSelf;
}

+ (id)localDefaultValues
{
	return [TPCPreferencesUserDefaultsObjectProxy userDefaultValues];
}

- (id)valueForKey:(NSString *)key
{
	if ([CSFWSystemInformation featureAvailableToOSXMavericks]) {
		if ([TPCPreferencesUserDefaults keyIsExcludedFromGroupContainer:key] == NO) {
			return [_groupDefaults objectForKey:key];
		} else {
			return [_userDefaults objectForKey:key];
		}
	} else {
		return [_userDefaults objectForKey:key];
	}
}

- (void)setValue:(id)value forKey:(NSString *)key
{
	[self willChangeValueForKey:key];
	
	if ([TPCPreferencesUserDefaults keyIsExcludedFromGroupContainer:key] == NO) {
		if ([CSFWSystemInformation featureAvailableToOSXMavericks]) {
			[_groupDefaults setObject:value forKey:key];
		} else {
			[_userDefaults setObject:value forKey:key];
		}
	} else {
		[_userDefaults setObject:value forKey:key];
	}
	
	[self didChangeValueForKey:key];
	
	[RZNotificationCenter() postNotificationName:TPCPreferencesUserDefaultsDidChangeNotification object:self userInfo:@{@"changedKey" : key}];
}

@end
