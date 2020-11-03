/* *********************************************************************
 *                  _____         _               _
 *                 |_   _|____  _| |_ _   _  __ _| |
 *                   | |/ _ \ \/ / __| | | |/ _` | |
 *                   | |  __/>  <| |_| |_| | (_| | |
 *                   |_|\___/_/\_\\__|\__,_|\__,_|_|
 *
 * Copyright (c) 2008 - 2010 Satoshi Nakagawa <psychs AT limechat DOT net>
 * Copyright (c) 2010 - 2020 Codeux Software, LLC & respective contributors.
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

#warning TODO: Add monitoring for changes to themes including being deleted.

#import "TXAppearance.h"
#import "TXGlobalModels.h"
#import "TXMasterController.h"
#import "TXMenuController.h"
#import "TDCAlert.h"
#import "TDCProgressIndicatorSheetPrivate.h"
#import "TLOLocalization.h"
#import "TPCPathInfo.h"
#import "TPCPreferencesCloudSync.h"
#import "TPCPreferencesLocalPrivate.h"
#import "TPCPreferencesReload.h"
#import "TPCResourceManager.h"
#import "TPCThemePrivate.h"
#import "TPCThemeControllerPrivate.h"

NS_ASSUME_NONNULL_BEGIN

NSString * const TPCThemeControllerCloudThemeNameBasicPrefix			= @"cloud";
NSString * const TPCThemeControllerCloudThemeNameCompletePrefix			= @"cloud:";

NSString * const TPCThemeControllerCustomThemeNameBasicPrefix			= @"user";
NSString * const TPCThemeControllerCustomThemeNameCompletePrefix		= @"user:";

NSString * const TPCThemeControllerBundledThemeNameBasicPrefix			= @"resource";
NSString * const TPCThemeControllerBundledThemeNameCompletePrefix		= @"resource:";

NSString * const TPCThemeControllerThemeListDidChangeNotification		= @"TPCThemeControllerThemeListDidChangeNotification";

typedef NSDictionary		<NSString *, TPCTheme *> 	*TPCThemeControllerThemeList;
typedef NSMutableDictionary	<NSString *, TPCTheme *> 	*TPCThemeControllerThemeListMutable;

/* Copy operation class is responsible for copying the active theme to a 
 different location when a user requests a local copy of the theme. */
@interface TPCThemeControllerCopyOperation : NSObject
@property (nonatomic, weak) TPCThemeController *themeController;
@property (nonatomic, copy) NSString *themeName; // Name without source prefix
@property (nonatomic, copy) NSString *pathBeingCopiedTo;
@property (nonatomic, copy) NSString *pathBeingCopiedFrom;
@property (nonatomic, assign) TPCThemeStorageLocation destinationLocation;
@property (nonatomic, assign) BOOL reloadThemeWhenCopied; // If YES, setThemeName: is called when copy completes. Otherwise, files are copied and nothing happens.
@property (nonatomic, assign) BOOL openThemeWhenCopied;
@property (nonatomic, strong) TDCProgressIndicatorSheet *progressIndicator;

- (void)beginOperation;
@end

@interface TPCThemeController ()
@property (nonatomic, copy) NSString *cachedThemeName;
@property (nonatomic, copy, readwrite) NSString *cacheToken;
@property (nonatomic, strong, readwrite) TPCTheme *theme;
@property (nonatomic, strong, nullable) TPCThemeControllerCopyOperation *currentCopyOperation;
@property (nonatomic, strong) TPCThemeControllerThemeListMutable bundledThemes;
@property (nonatomic, strong) TPCThemeControllerThemeListMutable customThemes;
@property (nonatomic, strong) TPCThemeControllerThemeListMutable cloudThemes;
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
	self.bundledThemes = [NSMutableDictionary dictionary];
	self.customThemes = [NSMutableDictionary dictionary];
	self.cloudThemes = [NSMutableDictionary dictionary];

	[self populateThemes];

	[RZNotificationCenter() addObserver:self
							   selector:@selector(applicationAppearanceChanged:)
								   name:TXApplicationAppearanceChangedNotification
								 object:nil];

	[RZNotificationCenter() addObserver:self
							   selector:@selector(themeIntegrityCompromised:)
								   name:TPCThemeIntegrityCompromisedNotification
								 object:nil];

	[RZNotificationCenter() addObserver:self
							   selector:@selector(themeWasModified:)
								   name:TPCThemeWasModifiedNotification
								 object:nil];

	[RZNotificationCenter() addObserver:self
							   selector:@selector(themeVarietyChanged:)
								   name:TPCThemeAppearanceChangedNotification
								 object:nil];

	[RZNotificationCenter() addObserver:self
							   selector:@selector(themeVarietyChanged:)
								   name:TPCThemeVarietyChangedNotification
								 object:nil];
}

- (void)prepareForApplicationTermination
{
	LogToConsoleTerminationProgress("Preparing theme controller.");

	LogToConsoleTerminationProgress("Removing theme controller observers.");

	[RZNotificationCenter() removeObserver:self];

	LogToConsoleTerminationProgress("Removing theme change observers.");

//	[self stopMonitoringActiveThemePath];

	LogToConsoleTerminationProgress("Empty theme cache.");

	[self removeTemporaryCopyOfTheme];
}

- (NSURL *)baseURL
{
	TEXTUAL_DEPRECATED_WARNING

	return self.originalURL;
}

- (NSString *)path
{
	TEXTUAL_DEPRECATED_WARNING

	return self.originalURL.path;
}

- (NSURL *)originalURL
{
	return self.theme.originalURL;
}

- (NSString *)originalPath
{
	return self.originalURL.path;
}

- (NSURL *)temporaryURL
{
	return self.theme.temporaryURL;
}

- (NSString *)temporaryPath
{
	return self.temporaryURL.path;
}

- (TPCThemeSettings *)settings
{
	return self.theme.settings;
}

- (TPCThemeStorageLocation)storageLocation
{
	return self.theme.storageLocation;
}

- (BOOL)usesTemporaryPath
{
	TEXTUAL_DEPRECATED_WARNING

	return YES;
}

- (NSString *)name
{
	return self.theme.name;
}

+ (BOOL)themeExists:(NSString *)themeName
{
	TEXTUAL_DEPRECATED_WARNING

	return NO;
}

- (BOOL)themeExists:(NSString *)themeName
{
	TPCTheme *theme = [self themeNamed:themeName createIfNecessary:YES];

	return theme.usable;
}

- (nullable TPCTheme *)themeNamed:(NSString *)themeName
{
	return [self themeNamed:themeName createIfNecessary:NO];
}

- (nullable TPCTheme *)themeNamed:(NSString *)themeName createIfNecessary:(BOOL)createIfNecessary
{
	NSParameterAssert(themeName != nil);

	NSString *fileName = [self.class extractThemeName:themeName];

	if (fileName == nil) {
		return nil;
	}

	TPCThemeStorageLocation storageLocation = [self.class storageLocationOfThemeWithName:themeName];

	if (storageLocation == TPCThemeStorageLocationUnknown) {
		return nil;
	}

	TPCThemeControllerThemeListMutable list = [self mutableListForStorageLocation:storageLocation];

	if (list == nil) {
		return nil;
	}

	NSString *filePath = [self.class pathOfThemeWithFilename:fileName storageLocation:storageLocation];

	if (filePath == nil) {
		return nil;
	}

	NSURL *fileURL = [NSURL fileURLWithPath:filePath isDirectory:YES];

	return [self themeAtURL:fileURL
			   withFilename:fileName
			storageLocation:storageLocation
					 inList:list
		  createIfNecessary:createIfNecessary
			 skipFileExists:NO];
}

- (nullable TPCTheme *)themeAtURL:(NSURL *)url withFilename:(NSString *)name storageLocation:(TPCThemeStorageLocation)storageLocation inList:(TPCThemeControllerThemeListMutable)list createIfNecessary:(BOOL)createIfNecessary skipFileExists:(BOOL)skipFileExists
{
	NSParameterAssert(url != nil);
	NSParameterAssert(url.isFileURL);
	NSParameterAssert(name != nil);
	NSParameterAssert(name.length > 0);
	NSParameterAssert(list != nil);

	TPCTheme *theme = nil;

	@synchronized (list) {
		theme = list[name];
	}

	if (theme || (theme == nil && createIfNecessary == NO)) {
		return theme;
	}

	if (skipFileExists == NO && [RZFileManager() directoryExistsAtURL:url] == NO) {
		return nil;
	}

#if TEXTUAL_BUILT_WITH_ICLOUD_SUPPORT == 1
	if ([RZFileManager() isUbiquitousItemAtURLDownloaded:url] == NO) {
		return NO;
	}
#endif

	theme = [[TPCTheme alloc] initWithURL:url inStorageLocation:storageLocation];

	[self addTheme:theme withFilename:name storageLocation:storageLocation];

	return theme;
}

- (void)addTheme:(nullable TPCTheme *)theme withFilename:(NSString *)name storageLocation:(TPCThemeStorageLocation)storageLocation
{
	[self add:YES theme:theme withFilename:name storageLocation:storageLocation];
}

- (void)removeThemeWithFilename:(NSString *)name storageLocation:(TPCThemeStorageLocation)storageLocation
{
	[self add:NO theme:nil withFilename:name storageLocation:storageLocation];
}

- (void)add:(BOOL)addOrRemove theme:(nullable TPCTheme *)theme withFilename:(NSString *)name storageLocation:(TPCThemeStorageLocation)storageLocation
{
	NSParameterAssert(theme != nil);
	NSParameterAssert(addOrRemove && name != nil);
	NSParameterAssert(addOrRemove && name.length > 0);
	NSParameterAssert(storageLocation != TPCThemeStorageLocationUnknown);

	TPCThemeControllerThemeListMutable list = [self mutableListForStorageLocation:storageLocation];

	if (list == nil) {
		return;
	}

	@synchronized (list) {
		if (addOrRemove) {
			list[name] = theme;
		} else {
			[list removeObjectForKey:name];
		}
	}
}

+ (nullable NSString *)pathOfThemeWithName:(NSString *)themeName
{
	return [self pathOfThemeWithName:themeName storageLocation:NULL];
}

+ (nullable NSString *)pathOfThemeWithName:(NSString *)themeName storageLocation:(nullable TPCThemeStorageLocation *)storageLocationIn
{
	NSParameterAssert(themeName != nil);

	TPCThemeStorageLocation storageLocation = [self.class storageLocationOfThemeWithName:themeName];

	if ( storageLocationIn) {
		*storageLocationIn = storageLocation;
	}

	if (storageLocation == TPCThemeStorageLocationUnknown) {
		return nil;
	}

	NSString *fileName = [self extractThemeName:themeName];

	if (fileName == nil) {
		return nil;
	}

	return [self pathOfThemeWithFilename:fileName storageLocation:storageLocation];
}

+ (nullable NSString *)pathOfThemeWithFilename:(NSString *)name storageLocation:(TPCThemeStorageLocation)storageLocation
{
	NSParameterAssert(name != nil);
	NSParameterAssert(name.length > 0);
	NSParameterAssert(storageLocation != TPCThemeStorageLocationUnknown);

	NSString *basePath = [self pathOfStorageLocation:storageLocation];

	if (basePath == nil) {
		return nil;
	}

	NSString *filePath = [basePath stringByAppendingPathComponent:name];

	return filePath.stringByStandardizingPath;
}

+ (nullable NSString *)pathOfStorageLocation:(TPCThemeStorageLocation)storageLocation
{
	NSParameterAssert(storageLocation != TPCThemeStorageLocationUnknown);

	switch (storageLocation) {
		case TPCThemeStorageLocationBundle:
		{
			return [TPCPathInfo bundledThemes];
		}
		case TPCThemeStorageLocationCustom:
		{
			return [TPCPathInfo customThemes];
		}

#if TEXTUAL_BUILT_WITH_ICLOUD_SUPPORT == 1
		case TPCThemeStorageLocationCloud:
		{
			return [TPCPathInfo cloudCustomThemes];
		}
#endif

		default:
		{
			break;
		}
	}

	return nil;
}

- (nullable TPCThemeControllerThemeListMutable)mutableListForStorageLocation:(TPCThemeStorageLocation)storageLocation
{
	NSParameterAssert(storageLocation != TPCThemeStorageLocationUnknown);

	switch (storageLocation) {
		case TPCThemeStorageLocationBundle:
		{
			return self.bundledThemes;
		}
		case TPCThemeStorageLocationCustom:
		{
			return self.customThemes;
		}

#if TEXTUAL_BUILT_WITH_ICLOUD_SUPPORT == 1
		case TPCThemeStorageLocationCloud:
		{
			return self.cloudThemes;
		}
#endif

		default:
		{
			break;
		}
	}

	return nil;
}

- (void)populateThemes
{
	[self populateThemesFromStorageLocation:TPCThemeStorageLocationBundle];
	[self populateThemesFromStorageLocation:TPCThemeStorageLocationCustom];
	[self populateThemesFromStorageLocation:TPCThemeStorageLocationCloud];
}

- (void)populateThemesFromStorageLocation:(TPCThemeStorageLocation)storageLocation
{
	NSParameterAssert(storageLocation != TPCThemeStorageLocationUnknown);

	NSString *path = [self.class pathOfStorageLocation:storageLocation];

	if (path == nil) {
		return;
	}

	TPCThemeControllerThemeListMutable list = [self mutableListForStorageLocation:storageLocation];

	if (list == nil) {
		return;
	}

	NSURL *url = [NSURL fileURLWithPath:path isDirectory:YES];

	NSError *preFileListError;

	NSArray *preFileList =
	[RZFileManager() contentsOfDirectoryAtURL:url
				   includingPropertiesForKeys:@[NSURLNameKey, NSURLIsDirectoryKey]
									  options:(NSDirectoryEnumerationSkipsHiddenFiles |
											   NSDirectoryEnumerationSkipsPackageDescendants)
										error:&preFileListError];

	if (preFileListError) {
		LogToConsoleError("Failed to list contents of theme folder: %@",
			preFileListError.localizedDescription);
	}

	for (NSURL *fileURL in preFileList) {
		NSNumber *isDirectory = [fileURL resourceValueForKey:NSURLIsDirectoryKey];

		if ([isDirectory boolValue] == NO) {
			continue;
		}

		NSString *name = [fileURL resourceValueForKey:NSURLNameKey];

		(void)[self themeAtURL:fileURL
				  withFilename:name
			   storageLocation:storageLocation
						inList:list
			 createIfNecessary:YES
				skipFileExists:YES];
	}
}

- (TPCThemeControllerThemeList)themesInStorageLocation:(TPCThemeStorageLocation)storageLocation
{
	NSParameterAssert(storageLocation != TPCThemeStorageLocationUnknown);

	TPCThemeControllerThemeListMutable list = [self mutableListForStorageLocation:storageLocation];

	if (list == nil) {
		return @{};
	}

	return [list copy];
}

+ (void)enumerateAvailableThemesWithBlock:(void(NS_NOESCAPE ^)(NSString *fileName, TPCThemeStorageLocation storageLocation, BOOL multipleVaraints, BOOL *stop))enumerationBlock
{
	TEXTUAL_DEPRECATED_WARNING
}

- (void)enumerateAvailableThemesWithBlock:(void(NS_NOESCAPE ^)(NSString *fileName, TPCThemeStorageLocation storageLocation, BOOL multipleVaraints, BOOL *stop))enumerationBlock
{
	NSParameterAssert(enumerationBlock != nil);

	/* Create a dictionary of the theme name (file name) as the key,
	 and an array of storage locations it appears within as the value. */
	NSMutableDictionary<NSString *, NSMutableArray<NSNumber *> *> *themesMappedByName = [NSMutableDictionary dictionary];

	void (^_mapByName)(TPCThemeStorageLocation) = ^(TPCThemeStorageLocation storageLocation)
	{
		TPCThemeControllerThemeList themes = [self themesInStorageLocation:storageLocation];

		[themes enumerateKeysAndObjectsUsingBlock:^(NSString *name, TPCTheme *theme, BOOL *stop) {
			if (theme.usable == NO) {
				return;
			}

			NSMutableArray<NSNumber *> *mappedLocations = themesMappedByName[name];

			if (mappedLocations == nil) {
				mappedLocations = [NSMutableArray array];

				themesMappedByName[name] = mappedLocations;
			}

			[mappedLocations addObject:@(storageLocation)];
		}];
	};

	_mapByName(TPCThemeStorageLocationBundle);
	_mapByName(TPCThemeStorageLocationCustom);

#if TEXTUAL_BUILT_WITH_ICLOUD_SUPPORT == 1
	_mapByName(TPCThemeStorageLocationCloud);
#endif

	/* Create sorted list of themes */
	NSArray *themeNamesSorted = themesMappedByName.sortedDictionaryKeys;

	/* Perform enumeration */
	BOOL stopEnumeration = NO;

	for (NSString *themeName in themeNamesSorted) {
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

- (void)applicationAppearanceChanged:(NSNotification *)notification
{
	[self.theme updateAppearance];
}

- (void)themeVarietyChanged:(NSNotification *)notification
{
	[self updatePreferences];
}

- (void)themeIntegrityCompromised:(NSNotification *)notification
{
	if (self.theme != notification.object) {
		return;
	}

	if ([self resetPreferencesForActiveTheme] == NO) { // Validate theme
		return;
	}

	LogToConsoleInfo("Reloading theme because it failed validation.");

	[TPCPreferences performReloadAction:TPCPreferencesReloadActionStyle];

	[RZNotificationCenter() postNotificationName:TPCThemeControllerThemeListDidChangeNotification object:self];

	[self presentIntegrityCompromisedAlert];
}

- (void)themeWasModified:(NSNotification *)notification
{
	if (self.theme != notification.object) {
		return;
	}

	if ([TPCPreferences automaticallyReloadCustomThemesWhenTheyChange] == NO) {
		return;
	}

	LogToConsoleInfo("Reloading theme because it was modified.");

	[TPCPreferences performReloadAction:TPCPreferencesReloadActionStyle];
}

- (void)load
{
	/* resetPreferencesForPreferredTheme is called for the configured
	 theme before the first ever -reload is called to recover from a
	 style being deleted while the app was closed. */
	[self resetPreferencesForPreferredTheme];

	[self reload];
}

- (void)reload
{
	NSString *themeName = [TPCPreferences themeName];

	TPCTheme *theme = [self themeNamed:themeName createIfNecessary:YES];

	NSAssert1((theme != nil), @"Missing style resource files: %@", themeName);

	if (self.theme != theme) {
		self.theme = theme;
	} else {
		return;
	}

	self.cachedThemeName = themeName;

	self.cacheToken = [NSString stringWithUnsignedInteger:TXRandomNumber(1000000)];

	[self updatePreferences];

	[self createTemporaryCopyOfTheme];

	[self presentCompatibilityAlert];

	[self presentInvertSidebarColorsAlert];
}

- (void)updatePreferences
{
	/* Inform our defaults controller about a few overrides. */
	/* These setValue calls basically tell the NSUserDefaultsController for the "Preferences"
	 window that the active theme has overrode a few user configurable options. The window then
	 blanks out the options specified to prevent the user from modifying. */
	TPCThemeSettings *settings = self.settings;

	[TPCPreferences setThemeChannelViewFontPreferenceUserConfigurable:(settings.themeChannelViewFont == nil)];

	[TPCPreferences setThemeNicknameFormatPreferenceUserConfigurable:(settings.themeNicknameFormat.length == 0)];

	[TPCPreferences setThemeTimestampFormatPreferenceUserConfigurable:(settings.themeTimestampFormat.length == 0)];
}

- (void)recreateTemporaryCopyOfThemeIfNecessary
{
	NSURL *temporaryURL = self.temporaryURL;

	if ([RZFileManager() fileExistsAtURL:temporaryURL]) {
		return;
	}

	[self createTemporaryCopyOfTheme];
}

- (void)removeTemporaryCopyOfTheme
{
	NSURL *temporaryURL = self.temporaryURL;

	if ([RZFileManager() fileExistsAtURL:temporaryURL] == NO) {
		return;
	}

	NSError *removeItemError = nil;

	if ([RZFileManager() removeItemAtURL:temporaryURL error:&removeItemError] == NO) {
		LogToConsoleError("Failed to remove temporary directory: %@",
				removeItemError.localizedDescription);
	}
}

- (void)createTemporaryCopyOfTheme
{
	NSURL *originalURL = self.originalURL;

	NSURL *temporaryURL = self.temporaryURL;

	[RZFileManager() replaceItemAtURL:temporaryURL
						withItemAtURL:originalURL
					moveToDestination:NO
			   moveDestinationToTrash:NO];
}

- (void)presentCompatibilityAlert
{
	if (self.settings.usesIncompatibleTemplateEngineVersion == NO) {
		return;
	}

	NSUInteger themeNameHash = self.cachedThemeName.hash;

	NSString *suppressionKey = [NSString stringWithFormat:
					@"incompatible_theme_dialog_%lu", themeNameHash];

	[TDCAlert alertWithMessage:TXTLS(@"Prompts[76t-pn]")
						 title:TXTLS(@"Prompts[py0-cr]", self.name)
				 defaultButton:TXTLS(@"Prompts[2a3-5s]")
			   alternateButton:TXTLS(@"Prompts[c7s-dq]")
				suppressionKey:suppressionKey
			   suppressionText:nil
			   completionBlock:^(TDCAlertResponse buttonClicked, BOOL suppressed, id underlyingAlert) {
				   if (buttonClicked != TDCAlertResponseDefault) {
					   return;
				   }

				   [menuController() showStylePreferences:nil];
			   }];
}

- (void)presentInvertSidebarColorsAlert
{
	if (self.settings.invertSidebarColors == NO) {
		return;
	}

	if ([TXSharedApplication sharedAppearance].properties.isDarkAppearance) {
		return;
	}

	NSUInteger themeNameHash = self.cachedThemeName.hash;

	NSString *suppressionKey = [NSString stringWithFormat:
								@"theme_appearance_dialog_%lu", themeNameHash];

	[TDCAlert alertWithMessage:TXTLS(@"Prompts[193-6o]")
						 title:TXTLS(@"Prompts[ezn-rm]", self.name)
				 defaultButton:TXTLS(@"Prompts[hf0-w3]")
			   alternateButton:TXTLS(@"Prompts[hv0-79]")
				suppressionKey:suppressionKey
			   suppressionText:nil
			   completionBlock:^(TDCAlertResponse buttonClicked, BOOL suppressed, id underlyingAlert) {
				   if (buttonClicked == TDCAlertResponseDefault) {
					   return;
				   }

				   [TPCPreferences setAppearance:TXPreferredAppearanceDark];

				   [TPCPreferences performReloadAction:TPCPreferencesReloadActionAppearance];
			   }];
}

- (void)presentIntegrityCompromisedAlert
{
	[TDCAlert alertWithMessage:TXTLS(@"Prompts[3wd-gj]")
						 title:TXTLS(@"Prompts[fjw-hj]", self.name)
				 defaultButton:TXTLS(@"Prompts[c4z-2b]")
			   alternateButton:TXTLS(@"Prompts[c7s-dq]")
			   completionBlock:^(TDCAlertResponse buttonClicked, BOOL suppressed, id underlyingAlert) {
				   if (buttonClicked != TDCAlertResponseDefault) {
					   return;
				   }

				   [menuController() showStylePreferences:nil];
			   }];
}

- (void)resetPreferencesForPreferredTheme
{
	NSString *themeName = [TPCPreferences themeName];

	[self resetPreferencesForThemeNamed:themeName];
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

	BOOL validationResult = [self performValidationForTheme:themeName
											  suggestedFont:&suggestedFontName
											 suggestedTheme:&suggestedThemeName];

	if (validationResult) {
		return NO;
	}

	if (suggestedFontName) {
		[TPCPreferences setThemeChannelViewFontName:suggestedFontName];
	}

	if (suggestedThemeName) {
		[TPCPreferences setThemeName:suggestedThemeName];
	}

	return YES;
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

	LogToConsoleInfo("Performing validation on theme named '%@' with source type of '%@'.", themeName, themeSource);

	/* Note from October 2020 during refactoring:
	 I know this is ugly as hell. Please don't shame me for it.
	 I just don't have the time to improve it.
	 If it works, it works. */

	if (themeSource == nil || [themeSource isEqualToString:TPCThemeControllerBundledThemeNameBasicPrefix])
	{
		/* Remap name of bundled themes. */
		NSString *bundledTheme = [self remappedThemeName:validatedTheme];

		if (bundledTheme) {
			if ( suggestedThemeName) {
				*suggestedThemeName = bundledTheme;

				keyChanged = YES;
			}
		}

		/* If the theme is faulted and is a bundled theme, then we can do
		 nothing except try to recover by using the default one. */
		if (bundledTheme == nil) {
			bundledTheme = validatedTheme;
		}

		if ([self themeExists:bundledTheme] == NO) {
			if ( suggestedThemeName) {
				*suggestedThemeName = [TPCPreferences themeNameDefault];

				keyChanged = YES;
			}
		} // preferred theme exists
	} // theme source bundled

	else if ([themeSource isEqualToString:TPCThemeControllerCustomThemeNameBasicPrefix])
	{
		/* Even if the current theme is custom and is valid, we still will validate whether
		 a cloud variant of it exists and if it does, prefer that over the custom. */

#if TEXTUAL_BUILT_WITH_ICLOUD_SUPPORT == 1
		NSString *cloudTheme = [self.class buildFilename:themeName forStorageLocation:TPCThemeStorageLocationCloud];

		if ([self themeExists:cloudTheme]) {
			/* If the theme exists in the cloud, then we go to that. */
			if ( suggestedThemeName) {
				*suggestedThemeName = cloudTheme;

				keyChanged = YES;
			}
		} else { // theme exists
#endif

			/* If there is no cloud theme, then we continue validation. */
			if ([self themeExists:validatedTheme] == NO) {
				NSString *bundledTheme = [self.class buildFilename:themeName forStorageLocation:TPCThemeStorageLocationBundle];

				if ([self themeExists:bundledTheme]) {
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
				} // bundled theme exists
			} // preferred theme exists

#if TEXTUAL_BUILT_WITH_ICLOUD_SUPPORT == 1
		} // cloud theme exists
#endif

	} // theme source custom

	else if ([themeSource isEqualToString:TPCThemeControllerCloudThemeNameBasicPrefix])
	{
		if ([self themeExists:validatedTheme] == NO) {
			/* If the current theme stored in the cloud is not valid, then we try to revert
			 to a custom one or a bundled one depending which one is available. */
			NSString *customTheme = [self.class buildFilename:themeName forStorageLocation:TPCThemeStorageLocationCustom];

			NSString *bundledTheme = [self.class buildFilename:themeName forStorageLocation:TPCThemeStorageLocationBundle];

			if ([self themeExists:customTheme]) {
				/* Use a custom theme with the same name if available. */
				if ( suggestedThemeName) {
					*suggestedThemeName = customTheme;

					keyChanged = YES;
				}
			} else if ([self themeExists:bundledTheme]) {
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
	} // theme source

	return (keyChanged == NO);
}

- (nullable NSString *)remappedThemeName:(NSString *)themeName
{
	NSParameterAssert(themeName != nil);

	static NSDictionary<NSString *, NSString *> *cachedValues = nil;

	static dispatch_once_t onceToken;

	dispatch_once(&onceToken, ^{
		NSDictionary *staticValues =
		[TPCResourceManager loadContentsOfPropertyListInResources:@"StaticStore"];

		cachedValues =
		[staticValues dictionaryForKey:@"TPCThemeController Remapped Themes"];
	});

	return cachedValues[themeName];
}

- (BOOL)isBundledTheme
{
	return (self.storageLocation == TPCThemeStorageLocationBundle);
}

+ (nullable NSString *)buildFilename:(NSString *)name forStorageLocation:(TPCThemeStorageLocation)storageLocation
{
	NSParameterAssert(name != nil);
	NSParameterAssert(name.length > 0);
	NSParameterAssert(storageLocation != TPCThemeStorageLocationUnknown);

	switch (storageLocation) {
		case TPCThemeStorageLocationBundle:
		{
			return [TPCThemeControllerBundledThemeNameCompletePrefix stringByAppendingString:name];
		}
		case TPCThemeStorageLocationCustom:
		{
			return [TPCThemeControllerCustomThemeNameCompletePrefix stringByAppendingString:name];
		}
		case TPCThemeStorageLocationCloud:
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

+ (nullable NSString *)descriptionForStorageLocation:(TPCThemeStorageLocation)storageLocation
{
	switch (storageLocation) {
		case TPCThemeStorageLocationBundle:
		{
			return TXTLS(@"BasicLanguage[7lm-bq]");
		}
		case TPCThemeStorageLocationCustom:
		{
			return TXTLS(@"BasicLanguage[bm2-4p]");
		}
		case TPCThemeStorageLocationCloud:
		{
			return TXTLS(@"BasicLanguage[aqy-6c]");
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

	NSString *name = [source substringAfterIndex:colonIndex];

	if (name.length == 0) {
		return nil;
	}

	return name;
}

+ (TPCThemeStorageLocation)storageLocationOfThemeWithName:(NSString *)themeName
{
	NSParameterAssert(themeName != nil);

	if ([themeName hasPrefix:TPCThemeControllerCloudThemeNameCompletePrefix]) {
		return TPCThemeStorageLocationCloud;
	} else if ([themeName hasPrefix:TPCThemeControllerCustomThemeNameCompletePrefix]) {
		return TPCThemeStorageLocationCustom;
	} else if ([themeName hasPrefix:TPCThemeControllerBundledThemeNameCompletePrefix]) {
		return TPCThemeStorageLocationBundle;
	}

	return TPCThemeStorageLocationUnknown;
}

+ (TPCThemeStorageLocation)expectedStorageLocationOfThemeWithName:(NSString *)themeName
{
	TEXTUAL_DEPRECATED_WARNING

	return [self storageLocationOfThemeWithName:themeName];
}

- (void)copyActiveThemeToDestinationLocation:(TPCThemeStorageLocation)destinationLocation reloadOnCopy:(BOOL)reloadOnCopy openOnCopy:(BOOL)openOnCopy
{
	NSAssert((self.currentCopyOperation == nil),
		@"Tried to create a new copy operation with operation already in progress");

	if (self.storageLocation == destinationLocation) {
		LogToConsoleError("Tried to copy active theme to same storage location that it already exists within");

		return;
	}

	if (TPCThemeStorageLocationBundle == destinationLocation) {
		LogToConsoleError("Tried to copy active theme to the application itself");

		return;
	}

	TPCThemeControllerCopyOperation *copyOperation = [TPCThemeControllerCopyOperation new];

	copyOperation.themeController = self;

	copyOperation.themeName = self.name;

	copyOperation.pathBeingCopiedFrom = self.originalPath;

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
	if (self.destinationLocation == TPCThemeStorageLocationCloud)
	{
		/* When copying to iCloud, we copy the style to a temporary folder then 
		 have OS X handle the transfer of said folder to iCloud on our behalf. */
		if ([RZFileManager() fileExistsAtURL:destinationURL]) {
			NSError *trashItemError = nil;

			if ([RZFileManager() trashItemAtURL:destinationURL resultingItemURL:NULL error:&trashItemError]) {
				LogToConsoleInfo("A copy of the theme being copied already exists at the destination path. This copy has been moved to the trash.");
			} else {
				LogToConsoleError("Failed to trash destination: '%@': %@",
					destinationURL.path, trashItemError.localizedDescription);

				_cancelOperationAndReturn
			}
		}

		/* Copy to temporary location */
		NSURL *fakeDestinationURL = [[TPCPathInfo applicationTemporaryURL] URLByAppendingPathComponent:[NSString stringWithUUID]];

		NSError *copyFileError = nil;

		if ([RZFileManager() copyItemAtURL:sourceURL toURL:fakeDestinationURL error:&copyFileError] == NO) {
			LogToConsoleError("Failed to perform copy: '%@' -> '%@': %@",
				sourceURL.path, fakeDestinationURL.path, copyFileError.localizedDescription);

			_cancelOperationAndReturn
		}

		/* Move item to iCloud */
		NSError *setUbiquitousError = nil;

		if ([RZFileManager() setUbiquitous:YES itemAtURL:fakeDestinationURL destinationURL:destinationURL error:&setUbiquitousError] == NO) {
			LogToConsoleError("Failed to set item as ubiquitous: '%@': %@",
				fakeDestinationURL.path, setUbiquitousError.localizedDescription);

			_cancelOperationAndReturn
		}

		/* Once the operation is completed, we can try to delete the temporary folder. */
		/* As the folder is only a temporary one, we don't care if this process errors out. */
		[RZFileManager() removeItemAtURL:fakeDestinationURL error:NULL];
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

	if (self.destinationLocation == TPCThemeStorageLocationCustom)
	{
		destinationPath = [TPCPathInfo customThemes];

#if TEXTUAL_BUILT_WITH_ICLOUD_SUPPORT == 1
	}
	else if (self.destinationLocation == TPCThemeStorageLocationCloud)
	{
		/* If the destination was set for the cloud, but the cloud is not available,
		 then we update our destinationLocation property so that the theme controller
		 actually will know where to look for the new theme. */
		if (sharedCloudManager().ubiquitousContainerIsAvailable == NO) {
			self.destinationLocation = TPCThemeStorageLocationCustom;

			destinationPath = [TPCPathInfo customThemes];
		} else {
			destinationPath = [TPCPathInfo cloudCustomThemes];
		}
#endif

	}

	destinationPath = [destinationPath stringByAppendingPathComponent:self.themeName];

	/* Cast as nonnull to make static analzyer happy */
	self.pathBeingCopiedTo = (NSString * _Nonnull)destinationPath;
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
		[RZWorkspace() openFile:self.pathBeingCopiedTo];
	}

	/* Maybe reload new theme */
	if (self.reloadThemeWhenCopied) {
		NSString *newThemeName = [TPCThemeController buildFilename:self.themeName forStorageLocation:self.destinationLocation];

		[TPCPreferences setThemeName:newThemeName];

		[TPCPreferences performReloadAction:TPCPreferencesReloadActionStyle];
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
