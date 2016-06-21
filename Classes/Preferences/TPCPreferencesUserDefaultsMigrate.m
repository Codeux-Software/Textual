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

NS_ASSUME_NONNULL_BEGIN

#if TEXTUAL_BUILT_INSIDE_SANDBOX == 0
@implementation TPCPreferencesUserDefaults (TPCPreferencesUserDefaultsMigrate)

+ (void)migrateKeyValuesAwayFromGroupContainer
{
#define _defaultsKey	@"TPCPreferencesUserDefaultsMigratedOldKeysToNewKeys_8380"

	id migratedOldKeys = [RZUserDefaults() objectForKey:_defaultsKey];

	if (migratedOldKeys) {
		return;
	}

	NSDictionary *staticValues = [TPCResourceManager loadContentsOfPropertyListInResources:@"StaticStore"];

	NSArray<NSDictionary *> *pathsToMigrate = [staticValues arrayForKey:@"TPCPreferencesUserDefaults Paths to Migrate"];

	for (NSDictionary *pathToMigrate in pathsToMigrate) {
		@autoreleasepool {
			NSString *pathToMigrateFrom = [pathToMigrate[@"sourcePath"] stringByExpandingTildeInPath];

			NSString *pathToMigrateTo = [pathToMigrate[@"destinationPath"] stringByExpandingTildeInPath];

			BOOL lockSource = [pathToMigrate boolForKey:@"lockSource"];

			BOOL hideSource = [pathToMigrate boolForKey:@"hideSource"];

			BOOL createSourceIfMissing = [pathToMigrate boolForKey:@"createSourceIfMissing"];

			[TPCPreferencesUserDefaults migrateFileFromPath:pathToMigrateFrom
													 toPath:pathToMigrateTo
									  createSourceIfMissing:createSourceIfMissing
												 hideSource:hideSource
												 lockSource:lockSource];
		}
	}

	[RZUserDefaults() setObject:@(YES) forKey:_defaultsKey postNotification:NO];

#undef _defaultsKey
}

+ (BOOL)createBackupOfPath:(NSString *)sourcePath
{
	NSParameterAssert(sourcePath != nil);

	NSString *sourcePathWithoutExtension = sourcePath.stringByDeletingPathExtension;

	NSString *sourcePathExtension = sourcePath.pathExtension;

	NSString *sourcePathBackupPath =
	[NSString stringWithFormat:@"%@-backup.%@", sourcePathWithoutExtension, sourcePathExtension];

	return
	[RZFileManager() replaceItemAtPath:sourcePathBackupPath
						withItemAtPath:sourcePath
					 moveToDestination:NO
				moveDestinationToTrash:NO];
}

+ (void)migrateFileFromPath:(NSString *)sourcePath
					 toPath:(NSString *)destinationPath
	  createSourceIfMissing:(BOOL)createSourceIfMissing
				 hideSource:(BOOL)hideSource
				 lockSource:(BOOL)lockSource
{
	NSParameterAssert(sourcePath != nil);
	NSParameterAssert(destinationPath != nil);

	/* Exit if the source migration path does not exist */
	BOOL sourcePathExists = [RZFileManager() fileExistsAtPath:sourcePath];

	if (sourcePathExists == NO && createSourceIfMissing == NO) {
		return;
	}

	/* Retrieve values from property list */
	NSDictionary<NSString *, id> *preferencesToMigrate = nil;

	NSDictionary<NSString *, NSString *> *preferencesKeysRemapped = nil;

	if (sourcePathExists) {
		/* Create a backup of the source */
		if ([TPCPreferencesUserDefaults createBackupOfPath:sourcePath] == NO) {
			LogToConsole(@"Failed to create backup of source path: '%@'", sourcePath)

			return;
		}

		/* Retrieve values from property list. */
		preferencesToMigrate = [NSDictionary dictionaryWithContentsOfFile:sourcePath];

		preferencesKeysRemapped = [TPCResourceManager loadContentsOfPropertyListInResources:@"RegisteredUserDefaultsRemappedKeys"];

		if (preferencesToMigrate == nil || preferencesKeysRemapped == nil) {
			LogToConsole(@"'preferencesToMigrate' or 'preferencesKeysRemapped' is nil")

			return;
		}

		/* We delete the existing group container preferences file and
		 replace it with a symbolic link. Doing this way ensures that the
		 new path (non-sandboxed path) can be accessed by the Mac App Store
		 version so that they are wrote to at the same path. */
		NSError *removeSourcePathError = nil;

		if ([RZFileManager() removeItemAtPath:sourcePath error:&removeSourcePathError] == NO) {
			LogToConsole(@"Failed to erase source path: '%@' - '%@'",
				sourcePath, [removeSourcePathError localizedDescription])

			return;
		}
	}

	/* We do not return if the creation of the symbolic link fails.
	 If it fails, we still write the keys in memory so that we can at
	 least have the user preferences on disk somewhere, they just wont
	 be read by the Mac App Store without symbolic link. */
	if (sourcePathExists == NO && createSourceIfMissing) {
		NSString *sourcePathLeading = sourcePath.stringByDeletingLastPathComponent;

		NSError *createSourcePathLeadingError = nil;

		if ([RZFileManager() fileExistsAtPath:sourcePathLeading] == NO) {
			if ([RZFileManager() createDirectoryAtPath:sourcePathLeading withIntermediateDirectories:YES attributes:nil error:&createSourcePathLeadingError] == NO) {
				LogToConsole(@"Failed to create source path: '%@' - '%@'",
					sourcePathLeading, [createSourcePathLeadingError localizedDescription])

				return;
			}
		}
	}

	NSError *createSymbolicLinkError = nil;

	if ([RZFileManager() createSymbolicLinkAtPath:sourcePath withDestinationPath:destinationPath error:&createSymbolicLinkError] == NO) {
		LogToConsole(@"Failed to create symbolic link to destination path: '%@' -> '%@' - %@",
			sourcePath, destinationPath, [createSymbolicLinkError localizedDescription])
	}

	/* Modify source attributes */
	NSURL *sourcePathURL = [NSURL fileURLWithPath:sourcePath isDirectory:NO];

	if (hideSource) {
		NSError *modifySourcePathAttributesError = nil;

		if ([sourcePathURL setResourceValue:@(YES) forKey:NSURLIsHiddenKey error:&modifySourcePathAttributesError] == NO) {
			LogToConsole(@"Failed to modify attributes of source path: '%@' - '%@'",
				[sourcePathURL absoluteString], [modifySourcePathAttributesError localizedDescription])
		}
	}

	if (lockSource) {
		NSError *modifySourcePathAttributesError = nil;

		if ([sourcePathURL setResourceValue:@(YES) forKey:NSURLIsUserImmutableKey error:&modifySourcePathAttributesError] == NO) {
			LogToConsole(@"Failed to modify attributes of source path: '%@' - '%@'",
				[sourcePathURL absoluteString], [modifySourcePathAttributesError localizedDescription])
		}
	}

	/* Begin migrating group container values */
	if (preferencesToMigrate == nil) {
		return;
	}

	[preferencesToMigrate enumerateKeysAndObjectsUsingBlock:^(NSString *key, id object, BOOL *stop) {
		NSString *keyRemapped = preferencesKeysRemapped[key];

		if (keyRemapped) {
			key = keyRemapped;
		}

		[RZUserDefaults() setObject:object forKey:key postNotification:NO];
	}];
}

@end
#endif

NS_ASSUME_NONNULL_END
