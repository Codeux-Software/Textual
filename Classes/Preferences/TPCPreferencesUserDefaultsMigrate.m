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

#import "BuildConfig.h"

#import "TLOLanguagePreferences.h"
#import "TLOPopupPrompts.h"
#import "TPCResourceManager.h"
#import "TPCPreferencesUserDefaultsPrivate.h"
#import "TPCPreferencesUserDefaultsMigratePrivate.h"

NS_ASSUME_NONNULL_BEGIN

@implementation TPCPreferencesUserDefaults (TPCPreferencesUserDefaultsMigrate)

#pragma mark -
#pragma mark Repair Preferences

+ (void)repairPreferences
{
	[self _repairOldStyleSymbolicLink];
}

/* Textual 5 would create a symoblic link from the App Store preferences file path
 to the standalone preferences file path. This was done so if you began using App Store
 verison, the symbolic link would allow the app to access preferences already set.
 This is no longer done but the symbolic link still exists for a lot of users.
 This logic replaces the symbolic link with a copy of the file its linked against. */
+ (void)_repairOldStyleSymbolicLink
{
	/* Locate preferences file */
	NSURL *preferencesFile = [self expandPath:@"group:8482Q6EPL6.com.codeux.irc.textual"];

	if (preferencesFile == nil) {
		LogToConsoleDebug("-expandPath returned nil value");

		return;
	}

	if ([RZFileManager() fileExistsAtURL:preferencesFile] == NO) {
		LogToConsoleDebug("Preferences file does not exist");

		return;
	}

	/* Lock getter */
	NSNumber *isLocked;

	{
		NSError *isLockedError;

		if ([preferencesFile getResourceValue:&isLocked forKey:NSURLIsUserImmutableKey error:&isLockedError] == NO) {
			LogToConsoleError("Failed to determine whether preferences file is locked: %@",
				 isLockedError.localizedDescription);

			return;
		}
	}

	/* Lock setter */
	if (isLocked.boolValue) {
		NSError *removeLockError;

		if ([preferencesFile setResourceValue:@(NO) forKey:NSURLIsUserImmutableKey error:&removeLockError] == NO) {
			LogToConsoleError("Failed to remove lock from preferences file: %@",
				  removeLockError.localizedDescription);

			return;
		}
	}

	/* Smbolic link getter */
	NSNumber *isSymbolicLink;

	{
		NSError *isSymbolicLinkError;

		if ([preferencesFile getResourceValue:&isSymbolicLink forKey:NSURLIsSymbolicLinkKey error:&isSymbolicLinkError] == NO) {
			LogToConsoleError("Failed to determine whether preferences file is symbolic link: %@",
				  isSymbolicLinkError.localizedDescription);

			return;
		}
	}

	/* Symbolic link check */
	if (isSymbolicLink.boolValue == NO) {
		LogToConsoleDebug("Preferences file does not require repair");

		return;
	}

	/* Copy linked file to temporary location */
	NSURL *preferencesFileTemp = [preferencesFile URLByAppendingPathExtension:@"backup"];

	NSURL *preferencesFileResolved = [preferencesFile URLByResolvingSymlinksInPath];

	{
		NSError *copyError;

		if ([RZFileManager() copyItemAtURL:preferencesFileResolved toURL:preferencesFileTemp error:&copyError] == NO) {
			LogToConsoleError("Failed to copy resolved preferences file to temporary location: %@",
				  copyError.localizedDescription);

			return;
		}

	}

	/* Delete symbolic link */
	{
		NSError *deleteError;

		if ([RZFileManager() removeItemAtURL:preferencesFile error:&deleteError] == NO) {
			LogToConsoleError("Failed to delete symbolic link: %@",
				  deleteError.localizedDescription);

			return;
		}
	}

	/* Copy temporary file to correct location */
	{
		NSError *moveError;

		if ([RZFileManager() copyItemAtURL:preferencesFileTemp toURL:preferencesFile error:&moveError] == NO) {
			LogToConsoleError("Failed to copy temporary preferences file to new location: %@",
				  moveError.localizedDescription);

			return;
		}
	}

	LogToConsoleDebug("Finished repairing preferences");
}

#pragma mark -
#pragma mark Migrate Preferences

+ (void)migratePreferences
{
#define _defaultsKeyPrefix	@"TPCPreferences -> Migration -> "

	/* Do not perform migration for specific identifiers when we
	 had done so in the past using the old style defaults key. */
	if ([[self sharedUserDefaults] boolForKey:@"TPCPreferences -> Migration -> Preference Files"]) {
		[[self sharedUserDefaults] setBool:YES forKey:(_defaultsKeyPrefix "8f014f5a-b079-4574-b856-c4f893c99145")];
	}

	/* Perform migration */
	NSDictionary *staticValues = [TPCResourceManager loadContentsOfPropertyListInResources:@"StaticStore"];

	NSArray<NSDictionary *> *pathsToMigrate = [staticValues arrayForKey:@"TPCPreferencesUserDefaults Paths to Migrate"];

	if (pathsToMigrate == nil) {
		[self presentMigrationFailedErrorMessage];

		return;
	}

	for (NSDictionary *pathToMigrate in pathsToMigrate) {
		@autoreleasepool {
			/* Do not continue if we are on the wrong build scheme. */
			NSString *buildScheme = pathToMigrate[@"buildScheme"];

			if ([buildScheme isEqualToString:TXBundleBuildScheme] == NO) {
				continue;
			}

			/* Do not continue if this path has already been migrated. */
			NSString *identifier = pathToMigrate[@"identifier"];

			NSString *defaultsKey = [_defaultsKeyPrefix stringByAppendingString:identifier];

			if ([[self sharedUserDefaults] boolForKey:defaultsKey]) {
				continue;
			}

			/* Perform migration */
			NSURL *pathToMigrateFrom = [self expandPath:pathToMigrate[@"sourcePath"]];

			if (pathToMigrateFrom == nil) {
				[self presentMigrationFailedErrorMessage];

				continue;
			}

			BOOL success =
			[self migrateFileFromPath:pathToMigrateFrom];

			if (success == NO) {
				[self presentMigrationFailedErrorMessage];

				continue;
			}

			[[self sharedUserDefaults] setBool:YES forKey:defaultsKey];
		}
	}

#undef _defaultsKeyPrefix
}

+ (nullable NSURL *)expandPath:(NSString *)path
{
	if ([path hasPrefix:@"~"])
	{
		path = [path stringByExpandingTildeInPath];
	}
	else if ([path hasPrefix:@"group:"])
	{
		NSString *identifier = [path substringFromIndex:6];

		NSURL *pathURL = [RZFileManager() containerURLForSecurityApplicationGroupIdentifier:identifier];

		if (pathURL == nil) {
			return nil;
		}

		NSString *pathSuffix = [NSString stringWithFormat:@"Library/Preferences/%@.plist", identifier];

		return [pathURL URLByAppendingPathComponent:pathSuffix];
	}

	return [NSURL URLWithString:path];
}

+ (BOOL)migrateFileFromPath:(NSURL *)sourceURL
{
	NSParameterAssert(sourceURL != nil);

	/* Exit if the source migration path does not exist */
	if ([RZFileManager() fileExistsAtPath:sourceURL.path] == NO) {
		return YES; // return success
	}

	/* Retrieve values from property list */
	NSDictionary<NSString *, id> *preferencesToMigrate = [NSDictionary dictionaryWithContentsOfURL:sourceURL];

	if (preferencesToMigrate == nil) {
		return NO;
	}

	/* Perform migration */
	[preferencesToMigrate enumerateKeysAndObjectsUsingBlock:^(NSString *key, id object, BOOL *stop) {
		[[self sharedUserDefaults] setObject:object forKey:key postNotification:NO];
	}];

	return YES;
}

#pragma mark -
#pragma mark Messages

+ (void)presentMigrationFailedErrorMessage
{
	[TLOPopupPrompts dialogWindowWithMessage:TXTLS(@"Prompts[1138][1]")
									   title:TXTLS(@"Prompts[1138][2]")
							   defaultButton:TXTLS(@"Prompts[0005]")
							 alternateButton:nil];
}

@end

NS_ASSUME_NONNULL_END
