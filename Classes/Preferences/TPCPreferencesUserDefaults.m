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

#import "BuildConfig.h"

#import <objc/message.h>

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
		return [super initWithUser:nil];
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

	[RZNotificationCenter() postNotificationName:TPCPreferencesUserDefaultsDidChangeNotification object:self userInfo:@{@"changedKey" : defaultName}];
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
		NSDictionary *staticValues = [TPCResourceManager loadContentsOfPropertyListInResourcesFolderNamed:@"StaticStore"];

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

+ (void)migrateKeyValuesAwayFromGroupContainer
{
	/* Discussion:

	 To make the non-Mac App Store and Mac App Store version the best possible 
	 experience, the user should have their preferences migrated the moment the 
	 application opens, before anything happens so they never suspect there is 
	 any difference. This is very difficult because one is sandboxed, another is 
	 not. Each writes to their own respective paths for preferences.

	 This method works to merge paths into one:
		The Mac App Store version of Textual writes to the following path:
			~/Library/Group Containers/8482Q6EPL6.com.codeux.irc.textual/Library/Preferences/8482Q6EPL6.com.codeux.irc.textual.plist

		The non-Mac App Store version of Textual writes to the following path:
			~/Library/Preferences/com.codeux.irc.textual5.plist

	 So whats the best way to handle the difference? NSUserDefaults does not allow an
	 application to specify the exact write path so that is out of the question and it
	 would be a burden to write our own complete implementation of NSUserDefaults
	 just to have custom paths.

	 To solve this problem, this method first reads all keys from the Mac App Store
	 path if it exists so we know the existing preferences. Once we have those values,
	 we delete the Mac App Store preferences file. Next, we create a symbolic link from
	 the Mac App Store version to the non-Mac App Store version.

	 Once all this is complete, we write the values in memory to the new location. The
	 symbolic link, though related to a sandboxed application, works as expected (at least
	 when tested against El Capitan when writing this comment). */

	/* Determine whether Textual has previously performed a group container migration. */
	id migratedOldKeys = [RZUserDefaults() objectForKey:@"TPCPreferencesUserDefaultsMigratedOldKeysToNewKeys_8288"];

	if (migratedOldKeys) {
		return; // Cancel operation...
	}

	/* Determine whether container preferences file exists. */
	NSString *containerPath = [TPCPathInfo applicationGroupContainerPath];

	if (containerPath == nil) {
		return; // Cancel operation...
	}

	NSString *groupContainerPreferencesFilename = [NSString stringWithFormat:@"/Library/Preferences/%@.plist", TXBundleBuildGroupContainerIdentifier];

	NSString *groupContainerPreferencesFilePath = [containerPath stringByAppendingPathComponent:groupContainerPreferencesFilename];

	if ([RZFileManager() fileExistsAtPath:groupContainerPreferencesFilePath] == NO) {
		return; // Cancel operation...
	}

	/* Load contents of relevant dictionaries. */
	NSDictionary *groupContainerPreferences = [NSDictionary dictionaryWithContentsOfFile:groupContainerPreferencesFilePath];

	NSDictionary *remappedPreferenceKeys = [TPCResourceManager loadContentsOfPropertyListInResourcesFolderNamed:@"RegisteredUserDefaultsRemappedKeys"];

	if (groupContainerPreferences == nil || remappedPreferenceKeys == nil) {
		LogToConsole(@"'groupContainerPreferences' or 'remappedPreferenceKeys' is nil");

		return; // Cancel operation...
	}

	/* We delete the existing group container preferences file and 
	 replace it with a symbolic link. Doing this way ensures that the 
	 new path (non-sandboxed path) can be accessed by the Mac App Store 
	 version so that they are wrote to at the same path. */
	NSString *userPreferencesPath = [TPCPathInfo userPreferencesFolderPath];

	NSString *localPreferencesFilename = [NSString stringWithFormat:@"%@.plist", [TPCApplicationInfo applicationBundleIdentifier]];

	NSString *localPreferencesFilePath = [userPreferencesPath stringByAppendingPathComponent:localPreferencesFilename];

	if ([RZFileManager() removeItemAtPath:groupContainerPreferencesFilePath error:NULL] == NO) {
		LogToConsole(@"Failed to remove group container preferences file.");

		return; // Cancel operation...
	}

	/* We do not return if the creation of the symbolic link fails. 
	 If it fails, we still write the keys in memory so that we can at 
	 least have the user preferences on disk somewhere, they just wont
	 be read by the Mac App Store without symbolic link. */
	(void)[RZFileManager() createSymbolicLinkAtPath:groupContainerPreferencesFilePath withDestinationPath:localPreferencesFilePath error:NULL];

	/* Begin migrating group container values. */
	[groupContainerPreferences enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
		/* Determine whether a key is remapped to new name. */
		NSString *mappedKey = key;

		NSString *remappedKey = remappedPreferenceKeys[key];

		if (remappedKey) {
			mappedKey = remappedKey;
		}

		/* Determine whether the key already exists. If so, override. */
		id existingValue = [RZUserDefaults() objectForKey:mappedKey];

		if (existingValue) {
			[RZUserDefaults() removeObjectForKey:mappedKey];
		}

		/* Set new value to non-group container. */
		[RZUserDefaults() setObject:obj forKey:mappedKey];
	}];

	/* Inform future calls to method not to perform migration again. */
	[RZUserDefaults() setBool:YES forKey:@"TPCPreferencesUserDefaultsMigratedOldKeysToNewKeys_8288"];
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

#pragma mark -

@implementation TPCPreferencesUserDefaultsObjectProxy

+ (id)userDefaultValues
{
	return [[TPCPreferencesUserDefaultsController sharedUserDefaultsController] values];
}

+ (id)localDefaultValues
{
	return [[TPCPreferencesUserDefaultsController sharedUserDefaultsController] values];
}

- (id)valueForKey:(NSString *)key
{
	return [[TPCPreferencesUserDefaultsController sharedUserDefaultsController] valueForKey:key];
}

- (void)setValue:(id)value forKey:(NSString *)key
{
	[[TPCPreferencesUserDefaultsController sharedUserDefaultsController] setValue:value forKey:key];
}

@end
