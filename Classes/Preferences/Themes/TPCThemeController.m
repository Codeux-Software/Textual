/* *********************************************************************
 *                  _____         _               _
 *                 |_   _|____  _| |_ _   _  __ _| |
 *                   | |/ _ \ \/ / __| | | |/ _` | |
 *                   | |  __/>  <| |_| |_| | (_| | |
 *                   |_|\___/_/\_\\__|\__,_|\__,_|_|
 *
 * Copyright (c) 2008 - 2010 Satoshi Nakagawa <psychs AT limechat DOT net>
 * Copyright (c) 2010 - 2015 Codeux Software, LLC & respective contributors.
 *       Please see Acknowledgements.pdf for additional information.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *
 *  * Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 *  * Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 *  * Neither the name of Textual, "Codeux Software, LLC", nor the
 *    names of its contributors may be used to endorse or promote products
 *    derived from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE AUTHOR AND CONTRIBUTORS ``AS IS'' AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED. IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE LIABLE
 * FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
 * OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
 * LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
 * OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
 * SUCH DAMAGE.
 *
 *********************************************************************** */

#import "TXGlobalModels.h"
#import "TXMasterController.h"
#import "TXMenuController.h"
#import "TDCAlert.h"
#import "TDCProgressIndicatorSheetPrivate.h"
#import "TLOLanguagePreferences.h"
#import "TPCPathInfo.h"
#import "TPCPreferencesCloudSync.h"
#import "TPCPreferencesLocalPrivate.h"
#import "TPCPreferencesReload.h"
#import "TPCThemeSettingsPrivate.h"
#import "TPCThemeControllerPrivate.h"

NS_ASSUME_NONNULL_BEGIN

NSString * const TPCThemeControllerCloudThemeNameBasicPrefix			= @"cloud";
NSString * const TPCThemeControllerCloudThemeNameCompletePrefix			= @"cloud:";

NSString * const TPCThemeControllerCustomThemeNameBasicPrefix			= @"user";
NSString * const TPCThemeControllerCustomThemeNameCompletePrefix		= @"user:";

NSString * const TPCThemeControllerBundledThemeNameBasicPrefix			= @"resource";
NSString * const TPCThemeControllerBundledThemeNameCompletePrefix		= @"resource:";

NSString * const TPCThemeControllerThemeListDidChangeNotification		= @"TPCThemeControllerThemeListDidChangeNotification";

/* Copy operation class is responsible for copying the active theme to a 
 different location when a user requests a local copy of the theme. */
@interface TPCThemeControllerCopyOperation : NSObject
@property (nonatomic, weak) TPCThemeController *themeController;
@property (nonatomic, copy) NSString *themeName; // Name without source prefix
@property (nonatomic, copy) NSString *pathBeingCopiedTo;
@property (nonatomic, copy) NSString *pathBeingCopiedFrom;
@property (nonatomic, assign) TPCThemeControllerStorageLocation destinationLocation;
@property (nonatomic, assign) BOOL reloadThemeWhenCopied; // If YES, setThemeName: is called when copy completes. Otherwise, files are copied and nothing happens.
@property (nonatomic, assign) BOOL openThemeWhenCopied;
@property (nonatomic, strong) TDCProgressIndicatorSheet *progressIndicator;

- (void)beginOperation;
@end

@interface TPCThemeController ()
@property (nonatomic, copy) NSString *cachedThemeName;
@property (nonatomic, copy, readwrite) NSString *cacheToken;
@property (nonatomic, copy, readwrite) NSURL *baseURL;
@property (nonatomic, strong, readwrite) TPCThemeSettings *customSettings;
@property (nonatomic, assign, readwrite) TPCThemeControllerStorageLocation storageLocation;
@property (nonatomic, assign, nullable) FSEventStreamRef eventStreamRef;
@property (nonatomic, strong, nullable) TPCThemeControllerCopyOperation *currentCopyOperation;
@end

#pragma mark -
#pragma mark Theme Controller

@implementation TPCThemeController

- (instancetype)init
{
	if ((self = [super init])) {
		[self prepareInitialState];

		return self;
	}

	return nil;
}

- (void)prepareInitialState
{
	self.customSettings = [TPCThemeSettings new];
}

- (void)prepareForApplicationTermination
{
	[self stopMonitoringActiveThemePath];

	[self removeTemporaryCopyOfTheme];
}

- (NSString *)path
{
	return self.baseURL.path;
}

- (NSString *)temporaryPath
{
	NSString *sourcePath = [TPCPathInfo applicationTemporaryProcessSpecific];

	NSString *basePath = [sourcePath stringByAppendingPathComponent:@"/Cached-Style-Resources/"];

	return basePath;
}

- (BOOL)usesTemporaryPath
{
	return [TPCPreferences webKit2Enabled];
}

- (NSString *)name
{
	NSString *themeName = self.cachedThemeName;

	return [self.class extractThemeName:themeName];
}

+ (BOOL)themeExists:(NSString *)themeName
{
	NSString *themePath = [self pathOfThemeWithName:themeName];

	return (themePath != nil);
}

+ (BOOL)themeAtPathIsValid:(NSString *)path
{
	NSParameterAssert(path != nil);

	BOOL pathIsDirectory = NO;

	if ([RZFileManager() fileExistsAtPath:path isDirectory:&pathIsDirectory] == NO) {
		return NO;
	}

	if (pathIsDirectory == NO) {
		return NO;
	}

#if TEXTUAL_BUILT_WITH_ICLOUD_SUPPORT == 1
	if ([RZFileManager() isUbiquitousItemAtPathDownloaded:path] == NO) {
		return NO;
	}
#endif

	NSString *cssFile = [path stringByAppendingPathComponent:@"design.css"];

	if ([RZFileManager() fileExistsAtPath:cssFile] == NO) {
		return NO;
	}

	NSString *jsFile = [path stringByAppendingPathComponent:@"scripts.js"];

	if ([RZFileManager() fileExistsAtPath:jsFile] == NO) {
		return NO;
	}

	return YES;
}

+ (nullable NSString *)pathOfThemeWithName:(NSString *)themeName
{
	return [self pathOfThemeWithName:themeName storageLocation:NULL];
}

+ (nullable NSString *)pathOfThemeWithName:(NSString *)themeName storageLocation:(nullable TPCThemeControllerStorageLocation *)storageLocation
{
	NSParameterAssert(themeName != nil);

	NSString *fileName = [self extractThemeName:themeName];

	if (fileName.length == 0) {
		return nil;
	}

	NSString *fileSource = [self extractThemeSource:themeName];

	if (fileSource.length == 0) {
		return nil;
	}

	TPCThemeControllerStorageLocation fileLocation;

	NSString *filePath = nil;

	if ([fileSource isEqualToString:TPCThemeControllerCloudThemeNameBasicPrefix])
	{

#if TEXTUAL_BUILT_WITH_ICLOUD_SUPPORT == 1
		fileLocation = TPCThemeControllerStorageCloudLocation;

		filePath = [[TPCPathInfo cloudCustomThemes] stringByAppendingPathComponent:fileName];
#endif

	}
	else if ([fileSource isEqualToString:TPCThemeControllerCustomThemeNameBasicPrefix])
	{
		fileLocation = TPCThemeControllerStorageCustomLocation;

		filePath = [[TPCPathInfo customThemes] stringByAppendingPathComponent:fileName];
	}
	else
	{
		fileLocation = TPCThemeControllerStorageBundleLocation;

		filePath = [[TPCPathInfo bundledThemes] stringByAppendingPathComponent:fileName];
	}

	if (filePath == nil) {
		return nil;
	}

	if ([self themeAtPathIsValid:filePath]) {
		if ( storageLocation) {
			*storageLocation = fileLocation;
		}

		return filePath;
	}

	return nil;
}

- (void)load
{
	[self startMonitoringActiveThemePath];

	/* resetPreferencesForPreferredTheme is called for the configured
	 theme before the first ever -reload is called to recover from a
	 style being deleted while the app was closed. */
	[self resetPreferencesForPreferredTheme];

	[self reload];
}

- (void)reload
{
	/* Try to find a theme by the stored name */
	NSString *themeName = [TPCPreferences themeName];

	TPCThemeControllerStorageLocation storageLocation = TPCThemeControllerStorageUnknownLocation;

	NSString *themePath = [self.class pathOfThemeWithName:themeName storageLocation:&storageLocation];

	NSAssert1((storageLocation != TPCThemeControllerStorageUnknownLocation),
		@"Missing style resource files: %@", themeName);

	self.baseURL = [NSURL fileURLWithPath:themePath isDirectory:YES];

	self.cachedThemeName = themeName;

	self.cacheToken = [NSString stringWithUnsignedInteger:TXRandomNumber(1000000)];

	self.storageLocation = storageLocation;

	[self.customSettings reloadWithPath:themePath];

	[self createTemporaryCopyOfTheme];

	[self maybePresentCompatibilityWarningDialog];
}

- (void)recreateTemporaryCopyOfThemeIfNecessary
{
	if (self.usesTemporaryPath == NO) {
		return;
	}

	NSString *temporaryPath = self.temporaryPath;

	if ([RZFileManager() fileExistsAtPath:temporaryPath]) {
		return;
	}

	[self createTemporaryCopyOfTheme];
}

- (void)removeTemporaryCopyOfTheme
{
	if (self.usesTemporaryPath == NO) {
		return;
	}

	NSString *temporaryPath = self.temporaryPath;

	if ([RZFileManager() fileExistsAtPath:temporaryPath] == NO) {
		return;
	}

	NSError *removeItemError = nil;

	if ([RZFileManager() removeItemAtPath:temporaryPath error:&removeItemError] == NO) {
		LogToConsoleError("Failed to remove temporary directory: %{public}@", removeItemError.localizedDescription);
	}
}

- (void)createTemporaryCopyOfTheme
{
	if (self.usesTemporaryPath == NO) {
		return;
	}

	NSString *temporaryPath = self.temporaryPath;

	[RZFileManager() replaceItemAtPath:temporaryPath
						withItemAtPath:self.path
					 moveToDestination:NO
				moveDestinationToTrash:NO];
}

- (void)maybePresentCompatibilityWarningDialog
{
	if (self.customSettings.usesIncompatibleTemplateEngineVersion == NO) {
		return;
	}

	NSUInteger themeNameHash = self.cachedThemeName.hash;

	NSString *suppressionKey = [NSString stringWithFormat:
					@"incompatible_theme_dialog_%lu", themeNameHash];

	[TDCAlert alertWithMessage:TXTLS(@"Prompts[1118][2]")
						 title:TXTLS(@"Prompts[1118][1]", self.name)
				 defaultButton:TXTLS(@"Prompts[1118][3]")
			   alternateButton:TXTLS(@"Prompts[0005]")
				suppressionKey:suppressionKey
			   suppressionText:nil
			   completionBlock:^(TDCAlertResponse buttonClicked, BOOL suppressed, id underlyingAlert) {
				   if (buttonClicked != TDCAlertResponseDefaultButton) {
					   return;
				   }

				   [menuController() showStylePreferences:nil];
			   }];
}

- (BOOL)validateThemeAndReloadIfNecessary
{
	if ([self resetPreferencesForActiveTheme]) {
		LogToConsoleInfo("Reloading theme because it failed validation");

		[TPCPreferences performReloadAction:TPCPreferencesReloadStyleWithTableViewsAction];

		return YES;
	} else {
		return NO;
	}
}

- (void)resetPreferencesForPreferredTheme
{
	NSString *themeName = [TPCPreferences themeName];

	(void)[self resetPreferencesForThemeNamed:themeName];
}

- (BOOL)resetPreferencesForActiveTheme
{
	NSString *themeName = self.cachedThemeName;

	return [self resetPreferencesForThemeNamed:themeName];
}

- (BOOL)resetPreferencesForThemeNamed:(NSString *)themeName
{
	NSParameterAssert(themeName != nil);

	NSString *suggestedFontName = nil;
	NSString *suggestedThemeName = nil;

	BOOL validationResult = [self performValidationForTheme:themeName suggestedFont:&suggestedFontName suggestedTheme:&suggestedThemeName];

	if (validationResult == NO) {
		if (suggestedFontName) {
			[TPCPreferences setThemeChannelViewFontName:suggestedFontName];
		}

		if (suggestedThemeName) {
			[TPCPreferences setThemeName:suggestedThemeName];
		}

		return YES;
	} else {
		return NO;
	}
}

- (BOOL)performValidationForTheme:(NSString *)validatedTheme suggestedFont:(NSString **)suggestedFontName suggestedTheme:(NSString **)suggestedThemeName
{
	NSParameterAssert(validatedTheme != nil);
	NSParameterAssert(suggestedFontName != NULL);
	NSParameterAssert(suggestedThemeName != NULL);

	/* Validate font */
	BOOL keyChanged = NO;

	NSString *fontName = [TPCPreferences themeChannelViewFontName];

	if ([NSFont fontIsAvailable:fontName] == NO) {
		if ( suggestedFontName) {
			*suggestedFontName = [TPCPreferences themeChannelViewFontNameDefault];
		}

		keyChanged = YES;
	}

	/* Validate theme */
	NSString *themeName = [self.class extractThemeName:validatedTheme];

	NSString *themeSource = [self.class extractThemeSource:validatedTheme];

	LogToConsoleInfo("Performing validation on theme named '%{public}@' with source type of '%{public}@'", themeName, themeSource);

	if ([themeSource isEqualToString:TPCThemeControllerBundledThemeNameBasicPrefix] || themeSource == nil)
	{
		/* If the theme is faulted and is a bundled theme, then we can do
		 nothing except try to recover by using the default one. */
		if ([self.class themeExists:validatedTheme] == NO) {
			if ( suggestedThemeName) {
				*suggestedThemeName = [TPCPreferences themeNameDefault];

				keyChanged = YES;
			}
		}
	}
	else if ([themeSource isEqualToString:TPCThemeControllerCustomThemeNameBasicPrefix])
	{
		/* Even if the current theme is custom and is valid, we still will validate whether
		 a cloud variant of it exists and if it does, prefer that over the custom. */

#if TEXTUAL_BUILT_WITH_ICLOUD_SUPPORT == 1
		NSString *cloudTheme = [self.class buildFilename:themeName forStorageLocation:TPCThemeControllerStorageCloudLocation];

		if ([self.class themeExists:cloudTheme]) {
			/* If the theme exists in the cloud, then we go to that. */
			if ( suggestedThemeName) {
				*suggestedThemeName = cloudTheme;

				keyChanged = YES;
			}
		} else {
#endif

			/* If there is no cloud theme, then we continue validation. */
			if ([self.class themeExists:validatedTheme] == NO) {
				NSString *bundledTheme = [self.class buildFilename:themeName forStorageLocation:TPCThemeControllerStorageBundleLocation];

				if ([self.class themeExists:bundledTheme]) {
					/* Use a bundled theme with the same name if available. */
					if ( suggestedThemeName) {
						*suggestedThemeName = bundledTheme;

						keyChanged = YES;
					}
				} else {
					/* Revert back to the default theme if no recovery is possible. */
					if ( suggestedThemeName) {
						*suggestedThemeName = [TPCPreferences themeNameDefault];

						keyChanged = YES;
					}
				}
			}

#if TEXTUAL_BUILT_WITH_ICLOUD_SUPPORT == 1
		}
#endif

	}
	else if ([themeSource isEqualToString:TPCThemeControllerCloudThemeNameBasicPrefix])
	{
		if ([self.class themeExists:validatedTheme] == NO) {
			/* If the current theme stored in the cloud is not valid, then we try to revert
			 to a custom one or a bundled one depending which one is available. */
			NSString *customTheme = [self.class buildFilename:themeName forStorageLocation:TPCThemeControllerStorageCustomLocation];

			NSString *bundledTheme = [self.class buildFilename:themeName forStorageLocation:TPCThemeControllerStorageBundleLocation];

			if ([self.class themeExists:customTheme]) {
				/* Use a custom theme with the same name if available. */
				if ( suggestedThemeName) {
					*suggestedThemeName = customTheme;

					keyChanged = YES;
				}
			} else if ([self.class themeExists:bundledTheme]) {
				/* Use a bundled theme with the same name if available. */
				if ( suggestedThemeName) {
					*suggestedThemeName = bundledTheme;

					keyChanged = YES;
				}
			} else {
				/* Revert back to the default theme if no recovery is possible. */
				if ( suggestedThemeName) {
					*suggestedThemeName = [TPCPreferences themeNameDefault];

					keyChanged = YES;
				}
			}
		}
	}

	return (keyChanged == NO);
}

- (BOOL)isBundledTheme
{
	return (self.storageLocation == TPCThemeControllerStorageBundleLocation);
}

+ (nullable NSString *)buildFilename:(NSString *)name forStorageLocation:(TPCThemeControllerStorageLocation)storageLocation
{
	NSParameterAssert(name != nil);
	NSParameterAssert(storageLocation != TPCThemeControllerStorageUnknownLocation);

	switch (storageLocation) {
		case TPCThemeControllerStorageBundleLocation:
		{
			return [TPCThemeControllerBundledThemeNameCompletePrefix stringByAppendingString:name];
		}
		case TPCThemeControllerStorageCustomLocation:
		{
			return [TPCThemeControllerCustomThemeNameCompletePrefix stringByAppendingString:name];
		}
		case TPCThemeControllerStorageCloudLocation:
		{
			return [TPCThemeControllerCloudThemeNameCompletePrefix stringByAppendingString:name];
		}
		default:
		{
			break;
		}
	}

	return nil;
}

+ (nullable NSString *)descriptionForStorageLocation:(TPCThemeControllerStorageLocation)storageLocation
{
	switch (storageLocation) {
		case TPCThemeControllerStorageBundleLocation:
		{
			return TXTLS(@"BasicLanguage[1030]");
		}
		case TPCThemeControllerStorageCustomLocation:
		{
			return TXTLS(@"BasicLanguage[1031]");
		}
		case TPCThemeControllerStorageCloudLocation:
		{
			return TXTLS(@"BasicLanguage[1032]");
		}
		default:
		{
			break;
		}
	}

	return nil;
}

+ (nullable NSString *)extractThemeSource:(NSString *)source
{
	NSParameterAssert(source != nil);

	if ([source hasPrefix:TPCThemeControllerCloudThemeNameCompletePrefix] == NO &&
		[source hasPrefix:TPCThemeControllerCustomThemeNameCompletePrefix] == NO &&
		[source hasPrefix:TPCThemeControllerBundledThemeNameCompletePrefix] == NO)
	{
		return nil;
	}

	NSInteger colonIndex = [source stringPosition:@":"];

	return [source substringToIndex:colonIndex];
}

+ (nullable NSString *)extractThemeName:(NSString *)source
{
	NSParameterAssert(source != nil);

	if ([source hasPrefix:TPCThemeControllerCloudThemeNameCompletePrefix] == NO &&
		[source hasPrefix:TPCThemeControllerCustomThemeNameCompletePrefix] == NO &&
		[source hasPrefix:TPCThemeControllerBundledThemeNameCompletePrefix] == NO)
	{
		return nil;
	}

	NSInteger colonIndex = [source stringPosition:@":"];

	return [source substringAfterIndex:colonIndex];
}

+ (TPCThemeControllerStorageLocation)expectedStorageLocationOfThemeWithName:(NSString *)themeName
{
	NSParameterAssert(themeName != nil);

	if ([themeName hasPrefix:TPCThemeControllerCloudThemeNameCompletePrefix]) {
		return TPCThemeControllerStorageCloudLocation;
	} else if ([themeName hasPrefix:TPCThemeControllerCustomThemeNameCompletePrefix]) {
		return TPCThemeControllerStorageCustomLocation;
	} else if ([themeName hasPrefix:TPCThemeControllerBundledThemeNameCompletePrefix]) {
		return TPCThemeControllerStorageBundleLocation;
	} else {
		return TPCThemeControllerStorageUnknownLocation;
	}
}

+ (void)enumerateAvailableThemesWithBlock:(void(NS_NOESCAPE ^)(NSString *themeName, TPCThemeControllerStorageLocation storageLocation, BOOL multipleVaraints, BOOL *stop))enumerationBlock
{
	NSParameterAssert(enumerationBlock != nil);

	/* First create a dictionary whoes key is the storage location and
	 value is list of themes at it. */
	NSArray *(^checkPath)(NSString *) = ^NSArray *(NSString * _Nullable storagePath) {
		if (storagePath == nil) {
			return @[];
		}

		NSArray *files = [RZFileManager() contentsOfDirectoryAtPath:storagePath error:NULL];

		NSMutableArray<NSString *> *themes = [NSMutableArray arrayWithCapacity:files.count];

		for (NSString *file in files) {
			NSString *filePath = [storagePath stringByAppendingPathComponent:file];

			if ([self themeAtPathIsValid:filePath] == NO) {
				continue;
			}

			[themes addObject:file];
		}

		return themes;
	};

	NSMutableDictionary<NSNumber *, NSArray<NSString *> *> *themesMappedByLocation = [NSMutableDictionary dictionary];

	themesMappedByLocation[@(TPCThemeControllerStorageBundleLocation)] = checkPath([TPCPathInfo bundledThemes]);
	themesMappedByLocation[@(TPCThemeControllerStorageCustomLocation)] = checkPath([TPCPathInfo customThemes]);

#if TEXTUAL_BUILT_WITH_ICLOUD_SUPPORT == 1
	[themesMappedByLocation setObject:checkPath([TPCPathInfo cloudCustomThemes]) forKey:@(TPCThemeControllerStorageCloudLocation)];
#endif

	/* Next translate result into a dictionary whoes key is the name of the
	 theme and value is all storage locations that contain it. */
	NSMutableDictionary<NSString *, NSMutableArray<NSNumber *> *> *themesMappedByName = [NSMutableDictionary dictionary];

	[themesMappedByLocation enumerateKeysAndObjectsUsingBlock:^(NSNumber *storageLocation, NSArray<NSString *> *themes, BOOL *stop) {
		[themes enumerateObjectsUsingBlock:^(NSString *theme, NSUInteger index, BOOL *stop) {
			NSMutableArray<NSNumber *> *mappedLocations = themesMappedByName[theme];

			if (mappedLocations == nil) {
				mappedLocations = [NSMutableArray array];

				themesMappedByName[theme] = mappedLocations;
			}

			[mappedLocations addObject:storageLocation];
		}];
	}];

	/* Create sorted list of themes */
	NSArray *sortedThemes = themesMappedByName.sortedDictionaryKeys;

	/* Perform enumeration */
	BOOL stopEnumeration = NO;

	for (NSString *themeName in sortedThemes) {
		NSArray *themeLocations = themesMappedByName[themeName];

		BOOL multipleVaraints = (themeLocations.count > 1);

		for (NSNumber *themeLocation in themeLocations) {
			enumerationBlock(themeName, themeLocation.unsignedIntegerValue, multipleVaraints, &stopEnumeration);

			if (stopEnumeration) {
				break;
			}
		} // for themeLocation
	} // for themeName
}

void activeThemePathMonitorCallback(ConstFSEventStreamRef streamRef,
									void *clientCallBackInfo,
									size_t numEvents,
									void *eventPaths,
									const FSEventStreamEventFlags eventFlags[],
									const FSEventStreamEventId eventIds[])
{
	@autoreleasepool {
		TPCThemeController *themeController = (__bridge TPCThemeController *)(clientCallBackInfo);

		BOOL activeThemeContentsWereDeleted = NO;
		BOOL activeThemeContentsWereModified = NO;

		BOOL postDidChangeNotification = NO;

		NSString *themePath = themeController.path;

#define _themeFilePath(s)					[themePath stringByAppendingPathComponent:(s)]

#define _updateConditionForPath(s)			if ([path isEqualToString:_themeFilePath((s))]) {						\
												if ([RZFileManager() fileExistsAtPath:path] == NO) {				\
													activeThemeContentsWereDeleted = YES;							\
												} else {															\
													activeThemeContentsWereModified = YES;							\
												}																	\
																													\
												continue;															\
											}

		NSArray *transformedPaths = (__bridge NSArray *)(eventPaths);

		for (NSUInteger i = 0; i < numEvents; i++) {
			FSEventStreamEventFlags flags = eventFlags[i];

			NSString *path = transformedPaths[i];

			/* Update status of any monitored files */
			if ( flags & kFSEventStreamEventFlagItemIsFile &&
				(flags & kFSEventStreamEventFlagItemCreated ||
				 flags & kFSEventStreamEventFlagItemRemoved ||
				 flags & kFSEventStreamEventFlagItemRenamed ||
				 flags & kFSEventStreamEventFlagItemModified))
			{
				if ([path hasPrefix:themePath] == NO) {
					continue;
				}

				/* Recognize if one of these files were either deleted or modified.
				 If one was, then we set continue; to skip any further action and 
				 update the theme based on deletion or modification status. */
				_updateConditionForPath(@"design.css")
				_updateConditionForPath(@"scripts.js")
				_updateConditionForPath(@"Data/Settings/styleSettings.plist")

				/* Check status for generic files. */
				NSString *fileExtension = path.pathExtension;

				if ([fileExtension isEqualToString:@"js"] ||
					[fileExtension isEqualToString:@"css"])
				{
					activeThemeContentsWereModified = YES;

					continue; // Only thing we care about here...
				}
			}

			/* Update status of inset stuff */
			if (flags & kFSEventStreamEventFlagItemIsDir) {
				BOOL pathIsThemeRoot = [path isEqualToString:themePath];

				/* Establish base context of event */
				if (flags & kFSEventStreamEventFlagItemRemoved ||
					flags & kFSEventStreamEventFlagItemRenamed)
				{
					activeThemeContentsWereDeleted = pathIsThemeRoot;
				}

				postDidChangeNotification = pathIsThemeRoot;
			}
		}

		if (activeThemeContentsWereDeleted)
		{
			LogToConsoleInfo("The contents of the configured theme was deleted. Validation and reload will now occur.");

			(void)[themeController validateThemeAndReloadIfNecessary];
		}
		else if (activeThemeContentsWereModified)
		{
			if ([TPCPreferences automaticallyReloadCustomThemesWhenTheyChange]) {
				[TPCPreferences performReloadAction:TPCPreferencesReloadStyleWithTableViewsAction];
			}
		}

		if (postDidChangeNotification) {
			[RZNotificationCenter() postNotificationName:TPCThemeControllerThemeListDidChangeNotification object:nil];
		}
	}

#undef _themeFilePath
}

- (void)reloadMonitoringActiveThemePath
{
	[self stopMonitoringActiveThemePath];

	[self startMonitoringActiveThemePath];
}

- (void)stopMonitoringActiveThemePath
{
	if (self.eventStreamRef == NULL) {
		return;
	}

	FSEventStreamStop(self.eventStreamRef);
	FSEventStreamInvalidate(self.eventStreamRef);
	FSEventStreamRelease(self.eventStreamRef);

	self.eventStreamRef = NULL;
}

- (void)startMonitoringActiveThemePath
{
	if (self.eventStreamRef) {
		[self stopMonitoringActiveThemePath];
	}

	NSArray<NSString *> *pathsToWatch = nil;

#if TEXTUAL_BUILT_WITH_ICLOUD_SUPPORT == 1
	if (sharedCloudManager().ubiquitousContainerIsAvailable) {
		pathsToWatch = @[[TPCPathInfo customThemes], [TPCPathInfo cloudCustomThemes]];
	} else {
#endif

		pathsToWatch = @[[TPCPathInfo customThemes]];

#if TEXTUAL_BUILT_WITH_ICLOUD_SUPPORT == 1
	}
#endif

	CFArrayRef pathsToWatchRef = (__bridge CFArrayRef)(pathsToWatch);

	CFAbsoluteTime latency = 5.0;

	FSEventStreamContext context;
	context.version = 0;
	context.info = (__bridge void *)(self);
	context.retain = NULL;
	context.release = NULL;
	context.copyDescription = NULL;

	FSEventStreamRef stream = FSEventStreamCreate(NULL, &activeThemePathMonitorCallback, &context, pathsToWatchRef, kFSEventStreamEventIdSinceNow, latency, (kFSEventStreamCreateFlagFileEvents | kFSEventStreamCreateFlagUseCFTypes));

	FSEventStreamScheduleWithRunLoop(stream, CFRunLoopGetCurrent(), kCFRunLoopDefaultMode);

	FSEventStreamStart(stream);

	self.eventStreamRef = stream;
}

- (void)copyActiveThemeToDestinationLocation:(TPCThemeControllerStorageLocation)destinationLocation reloadOnCopy:(BOOL)reloadOnCopy openOnCopy:(BOOL)openOnCopy
{
	NSAssert((self.currentCopyOperation == nil),
		@"Tried to create a new copy operation with operation already in progress");

	if (self.storageLocation == destinationLocation) {
		LogToConsoleError("Tried to copy active theme to same storage location that it already exists within");

		return;
	}

	if (TPCThemeControllerStorageBundleLocation == destinationLocation) {
		LogToConsoleError("Tried to copy active theme to the application itself");

		return;
	}

	TPCThemeControllerCopyOperation *copyOperation = [TPCThemeControllerCopyOperation new];

	copyOperation.themeController = self;

	copyOperation.themeName = self.name;

	copyOperation.pathBeingCopiedFrom = self.path;

	copyOperation.destinationLocation = destinationLocation;

	copyOperation.openThemeWhenCopied = openOnCopy;
	copyOperation.reloadThemeWhenCopied = reloadOnCopy;

	[copyOperation beginOperation];

	self.currentCopyOperation = copyOperation;
}

- (void)copyActiveThemeOperationCompleted
{
	self.currentCopyOperation = nil;
}

@end

#pragma mark -
#pragma mark Theme Controller Copy Operation

@implementation TPCThemeControllerCopyOperation

- (void)beginOperation
{
	/* Setup progress indicator. */
	  TDCProgressIndicatorSheet *progressIndicator =
	[[TDCProgressIndicatorSheet alloc] initWithWindow:[NSApp keyWindow]];

	self.progressIndicator = progressIndicator;

	[self.progressIndicator start];

	/* All work is done in a background thread. */
	/* Once started, the operation cannot be cancelled. It will occur
	 then it will either call -cancelOperation itself on failure or wait
	 for the theme controller itself to call -completeOperation which 
	 signials to the copier that the theme controller sees the files. */
	[self performBlockOnGlobalQueue:^{
		[self _beginOperation];
	}];
}

- (void)_beginOperation
{
	[self _defineDestinationPath];

	NSURL *sourceURL = [NSURL fileURLWithPath:self.pathBeingCopiedFrom isDirectory:YES];

	NSURL *destinationURL = [NSURL fileURLWithPath:self.pathBeingCopiedTo isDirectory:YES];

#define _cancelOperationAndReturn			[self cancelOperation];		\
																		\
											return;

#if TEXTUAL_BUILT_WITH_ICLOUD_SUPPORT == 1
	if (self.destinationLocation == TPCThemeControllerStorageCloudLocation)
	{
		/* When copying to iCloud, we copy the style to a temporary folder then 
		 have OS X handle the transfer of said folder to iCloud on our behalf. */
		if ([RZFileManager() fileExistsAtURL:destinationURL]) {
			NSError *trashItemError = nil;

			if ([RZFileManager() trashItemAtURL:destinationURL resultingItemURL:NULL error:&trashItemError]) {
				LogToConsoleInfo("A copy of the theme being copied already exists at the destination path. This copy has been moved to the trash.");
			} else {
				LogToConsoleError("Failed to trash destination: '%{public}@': %{public}@",
					destinationURL.path, trashItemError.localizedDescription);

				_cancelOperationAndReturn
			}
		}

		/* Copy to temporary location */
		NSURL *fakeDestinationURL = [[TPCPathInfo applicationTemporaryURL] URLByAppendingPathComponent:[NSString stringWithUUID]];

		NSError *copyFileError = nil;

		if ([RZFileManager() copyItemAtURL:sourceURL toURL:fakeDestinationURL error:&copyFileError] == NO) {
			LogToConsoleError("Failed to perform copy: '%{public}@' -> '%{public}@': %{public}@",
				sourceURL.path, fakeDestinationURL.path, copyFileError.localizedDescription);

			_cancelOperationAndReturn
		}

		/* Move item to iCloud */
		NSError *setUbiquitousError = nil;

		if ([RZFileManager() setUbiquitous:YES itemAtURL:fakeDestinationURL destinationURL:destinationURL error:&setUbiquitousError] == NO) {
			LogToConsoleError("Failed to set item as ubiquitous: '%{public}@': %{public}@",
				fakeDestinationURL.path, setUbiquitousError.localizedDescription);

			_cancelOperationAndReturn
		}

		/* Once the operation is completed, we can try to delete the temporary folder. */
		/* As the folder is only a temporary one, we don't care if this process errors out. */
		(void)[RZFileManager() removeItemAtURL:fakeDestinationURL error:NULL];
	}
	else
	{
#endif

		if ([RZFileManager() replaceItemAtURL:destinationURL
								withItemAtURL:sourceURL
							moveToDestination:NO
					   moveDestinationToTrash:YES] == NO)
		{
			_cancelOperationAndReturn
		}

#if TEXTUAL_BUILT_WITH_ICLOUD_SUPPORT == 1
	}
#endif

	[self completeOperation];

#undef _cancelOperationAndReturn

}

- (void)_defineDestinationPath
{
	NSString *destinationPath = nil;

	if (self.destinationLocation == TPCThemeControllerStorageCustomLocation)
	{
		destinationPath = [TPCPathInfo customThemes];

#if TEXTUAL_BUILT_WITH_ICLOUD_SUPPORT == 1
	}
	else if (self.destinationLocation == TPCThemeControllerStorageCloudLocation)
	{
		/* If the destination was set for the cloud, but the cloud is not available,
		 then we update our destinationLocation property so that the theme controller
		 actually will know where to look for the new theme. */
		if (sharedCloudManager().ubiquitousContainerIsAvailable == NO) {
			self.destinationLocation = TPCThemeControllerStorageCustomLocation;

			destinationPath = [TPCPathInfo customThemes];
		} else {
			destinationPath = [TPCPathInfo cloudCustomThemes];
		}
#endif

	}

	destinationPath = [destinationPath stringByAppendingPathComponent:self.themeName];

	self.pathBeingCopiedTo = destinationPath;
}

- (void)cancelOperation
{
	XRPerformBlockAsynchronouslyOnMainQueue(^{
		[self _cancelOperation];
	});
}

- (void)completeOperation
{
	/* The copy process is usually instantaneous so add a slight 
	 delay because I like to mess with people */
	[NSThread sleepForTimeInterval:3.0];

	XRPerformBlockAsynchronouslyOnMainQueue(^{
		[self _completeOperation];
	});
}

- (void)_cancelOperation
{
	[self invalidateOperation];
}

- (void)_completeOperation
{
	/* Maybe open new path of theme */
	if (self.openThemeWhenCopied) {
		(void)[RZWorkspace() openFile:self.pathBeingCopiedTo];
	}

	/* Maybe reload new theme */
	if (self.reloadThemeWhenCopied) {
		NSString *newThemeName = [TPCThemeController buildFilename:self.themeName forStorageLocation:self.destinationLocation];

		[TPCPreferences setThemeName:newThemeName];

		[TPCPreferences performReloadAction:TPCPreferencesReloadStyleWithTableViewsAction];
	}

	/* Close progress indicator */
	[self invalidateOperation];
}

- (void)invalidateOperation
{
	[self.progressIndicator stop];
	 self.progressIndicator = nil;

	[self.themeController copyActiveThemeOperationCompleted];
}

@end

NS_ASSUME_NONNULL_END
