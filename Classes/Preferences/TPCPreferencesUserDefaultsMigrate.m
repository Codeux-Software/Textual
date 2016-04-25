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

#import "TextualApplication.h"

#import "TPCPreferencesUserDefaultsMigrate.h"
#import "TPCPreferencesUserDefaultsPrivate.h"

NS_ASSUME_NONNULL_BEGIN

#if TEXTUAL_BUILT_INSIDE_SANDBOX == 0
@implementation TPCPreferencesUserDefaults (TPCPreferencesUserDefaultsMigrate)

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
	 ~/Library/Preferences/com.codeux.apps.textual.plist

	 So whats the best way to handle the difference? NSUserDefaults does not allow an
	 application to specify the exact write path so that is out of the question and it
	 would be a burden to write our own complete implementation of NSUserDefaults
	 just to have custom paths.

	 To solve this problem, this method does the following:
		1) Read the contents of original preferences file and saves it within memory
		2) Erase the existing preferences file
	 1) If step #1 fails, then the method exits and does not attempt
	 migration to prevent certain edge cases.
		3) Create a symbolic link from the original file to new location.
	 1) Step #3 is allowed to fail. If it fails, we still have the original
	 values stored in memory and we can use those at the new location.
		4) Apply values in memory to new location
	 */

	/* Determine whether Textual has previously performed a group container migration. */
	id migratedOldKeys = [RZUserDefaults() objectForKey:@"TPCPreferencesUserDefaultsMigratedOldKeysToNewKeys_8380"];

	if (migratedOldKeys) {
		return; // Cancel operation...
	}

	/* The following paths are hardcoded because the bundle identifier for Textual
	 may change in the future, but these paths in the past will not be effected by
	 the bundle identifier change, which means they will always remain the same. */
	/* Each path is relative to the user's home directory. Not filesystem root. */
	/* Files are listed in priority from least important to most important. If a
	 file with higher priority has a key thats already defined, then that file
	 overrides the previously defined value. */
	NSDictionary *staticValues = [TPCResourceManager loadContentsOfPropertyListInResources:@"StaticStore"];

	NSArray<NSDictionary *> *pathsToMigrate = [staticValues arrayForKey:@"TPCPreferencesUserDefaults Paths to Migrate"];

	for (NSDictionary *pathToMigrateDict in pathsToMigrate) {
		@autoreleasepool {
			/* Define context variables for migration action. */
			NSString *pathToMigrateFromAbsolutePath = [pathToMigrateDict[@"sourcePath"] stringByExpandingTildeInPath];

			NSString *pathToMigrateToAbsolutePath = [pathToMigrateDict[@"destinationPath"] stringByExpandingTildeInPath];

			NSString *migrationPathType = pathToMigrateDict[@"pathType"];

			BOOL lockSource = [pathToMigrateDict boolForKey:@"lockSource"];

			BOOL hideOriginalOnMigration = [pathToMigrateDict boolForKey:@"hideOriginalOnMigration"];

			BOOL createSourceIfMissing = [pathToMigrateDict boolForKey:@"createSourceIfMissing"];

			/* Perform migration action. */
			if (NSObjectsAreEqual(migrationPathType, @"folder"))
			{
				[TPCPreferencesUserDefaults migrateFolderWithPath:pathToMigrateFromAbsolutePath
														   toPath:pathToMigrateToAbsolutePath
										  hideOriginalOnMigration:hideOriginalOnMigration
											createSourceIfMissing:createSourceIfMissing
													   lockSource:lockSource];
			}
			else if ([migrationPathType hasPrefix:@"file-"])
			{
				BOOL isPropertyList = NSObjectsAreEqual(migrationPathType, @"file-propertyList");

				[TPCPreferencesUserDefaults migrateFileWithPath:pathToMigrateFromAbsolutePath
														 toPath:pathToMigrateToAbsolutePath
										hideOriginalOnMigration:hideOriginalOnMigration
										  createSourceIfMissing:createSourceIfMissing
												 isPropertyList:isPropertyList
													 lockSource:lockSource];
			}
		}
	}

	/* Inform future calls to method not to perform migration again. */
	[RZUserDefaults() setObject:@(YES) forKey:@"TPCPreferencesUserDefaultsMigratedOldKeysToNewKeys_8380" postNotification:NO];
}

+ (void)migrateFolderWithPath:(NSString *)sourceMigrationPath
					   toPath:(NSString *)destinationMigrationPath
	  hideOriginalOnMigration:(BOOL)hideOriginalOnMigration
		createSourceIfMissing:(BOOL)createSourceIfMissing
				   lockSource:(BOOL)lockSource
{
	/* If the destination folder already exists, cancel operation. */
	if ([RZFileManager() directoryExistsAtPath:destinationMigrationPath]) {
		return; // Cancel operation...
	}

	/* Perform migration action for path. */
	BOOL sourceMigrationPathExists = [RZFileManager() fileExistsAtPath:sourceMigrationPath];

	if (sourceMigrationPathExists == NO && createSourceIfMissing == NO) {
		return; // Cancel operation...
	}

	/* Move source path to new path. */
	if (sourceMigrationPathExists) {
		NSError *moveSourcePathError = nil;

		if ([RZFileManager() moveItemAtPath:sourceMigrationPath toPath:destinationMigrationPath error:&moveSourcePathError] == NO) {
			LogToConsole(@"Failed to move migration source path during migration: %@", [moveSourcePathError localizedDescription]);

			return; // Cancel operation...
		}
	} else {
		NSError *createSourcePathError = nil;

		if ([RZFileManager() createDirectoryAtPath:sourceMigrationPath withIntermediateDirectories:YES attributes:nil error:&createSourcePathError] == NO) {
			LogToConsole(@"Failed to create source migration path when missing: %@", [createSourcePathError localizedDescription]);

			return; // Cancel operation...
		}
	}

	/* Create symbolic link from source path to new path. */
	NSError *createSymbolicLinkError = nil;

	if ([RZFileManager() createSymbolicLinkAtPath:sourceMigrationPath withDestinationPath:destinationMigrationPath error:NULL] == NO) {
		LogToConsole(@"Failed to create symbolic link to destination path: %@", [createSymbolicLinkError localizedDescription]);
	}

	/* Modify source attributes */
	NSURL *sourceMigrationPathURL = [NSURL fileURLWithPath:sourceMigrationPath isDirectory:YES];

	if (hideOriginalOnMigration) {
		NSError *modifySourcePathAttributesError = nil;

		if ([sourceMigrationPathURL setResourceValue:@(YES) forKey:NSURLIsHiddenKey error:&modifySourcePathAttributesError] == NO) {
			LogToConsole(@"Failed to modify attributes of source migration path: %@", [modifySourcePathAttributesError localizedDescription]);
		}
	}

	if (lockSource) {
		NSError *modifySourcePathAttributesError = nil;

		if ([sourceMigrationPathURL setResourceValue:@(YES) forKey:NSURLIsUserImmutableKey error:&modifySourcePathAttributesError] == NO) {
			LogToConsole(@"Failed to modify attributes of source migration path: %@", [modifySourcePathAttributesError localizedDescription]);
		}
	}
}

+ (void)migrateFileWithPath:(NSString *)sourceMigrationPath
					 toPath:(NSString *)destinationMigrationPath
	hideOriginalOnMigration:(BOOL)hideOriginalOnMigration
	  createSourceIfMissing:(BOOL)createSourceIfMissing
			 isPropertyList:(BOOL)isPropertyList
				 lockSource:(BOOL)lockSource
{
	/* Exit if the source migration path does not exist. */
	BOOL sourceMigrationPathExists = [RZFileManager() fileExistsAtPath:sourceMigrationPath];

	if (sourceMigrationPathExists == NO && createSourceIfMissing == NO) {
		return; // Cancel operation...
	}

	/* Retrieve values from property list. */
	NSDictionary<NSString *, id> *preferencesToMigrate = nil;

	NSDictionary<NSString *, NSString *> *remappedPreferenceKeys = nil;

	if (sourceMigrationPathExists) {
		if (isPropertyList) {
			/* Retrieve values from property list. */
			preferencesToMigrate = [NSDictionary dictionaryWithContentsOfFile:sourceMigrationPath];

			remappedPreferenceKeys = [TPCResourceManager loadContentsOfPropertyListInResources:@"RegisteredUserDefaultsRemappedKeys"];

			if (preferencesToMigrate == nil || remappedPreferenceKeys == nil) {
				LogToConsole(@"'preferencesToMigrate' or 'remappedPreferenceKeys' is nil");

				return; // Cancel operation...
			}
		}

		/* We delete the existing group container preferences file and
		 replace it with a symbolic link. Doing this way ensures that the
		 new path (non-sandboxed path) can be accessed by the Mac App Store
		 version so that they are wrote to at the same path. */
		NSError *removeSourcePathError = nil;

		if ([RZFileManager() removeItemAtPath:sourceMigrationPath error:&removeSourcePathError] == NO) {
			LogToConsole(@"Failed to erase the migration source file: %@", [removeSourcePathError localizedDescription]);

			return; // Cancel operation...
		}
	}

	/* We do not return if the creation of the symbolic link fails.
	 If it fails, we still write the keys in memory so that we can at
	 least have the user preferences on disk somewhere, they just wont
	 be read by the Mac App Store without symbolic link. */
	if (sourceMigrationPathExists == NO && createSourceIfMissing) {
		NSString *sourceMigrationPathOwner = [sourceMigrationPath stringByDeletingLastPathComponent];

		NSError *createSourcePathError = nil;

		if ([RZFileManager() fileExistsAtPath:sourceMigrationPathOwner] == NO) {
			if ([RZFileManager() createDirectoryAtPath:sourceMigrationPathOwner withIntermediateDirectories:YES attributes:nil error:&createSourcePathError] == NO) {
				LogToConsole(@"Failed to create source migration path when missing: %@", [createSourcePathError localizedDescription]);

				return; // Cancel operation...
			}
		}
	}

	NSError *createSymbolicLinkError = nil;

	if ([RZFileManager() createSymbolicLinkAtPath:sourceMigrationPath withDestinationPath:destinationMigrationPath error:NULL] == NO) {
		LogToConsole(@"Failed to create symbolic link to destination path: %@", [createSymbolicLinkError localizedDescription]);
	}

	/* Modify source attributes */
	NSURL *sourceMigrationPathURL = [NSURL fileURLWithPath:sourceMigrationPath isDirectory:NO];

	if (hideOriginalOnMigration) {
		NSError *modifySourcePathAttributesError = nil;

		if ([sourceMigrationPathURL setResourceValue:@(YES) forKey:NSURLIsHiddenKey error:&modifySourcePathAttributesError] == NO) {
			LogToConsole(@"Failed to modify attributes of source migration path: %@", [modifySourcePathAttributesError localizedDescription]);
		}
	}

	if (lockSource) {
		NSError *modifySourcePathAttributesError = nil;

		if ([sourceMigrationPathURL setResourceValue:@(YES) forKey:NSURLIsUserImmutableKey error:&modifySourcePathAttributesError] == NO) {
			LogToConsole(@"Failed to modify attributes of source migration path: %@", [modifySourcePathAttributesError localizedDescription]);
		}
	}

	/* Begin migrating group container values. */
	if (isPropertyList && sourceMigrationPathExists) {
		[preferencesToMigrate enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
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
			[RZUserDefaults() setObject:obj forKey:mappedKey postNotification:NO];
		}];
	}
}

@end
#endif

NS_ASSUME_NONNULL_END
