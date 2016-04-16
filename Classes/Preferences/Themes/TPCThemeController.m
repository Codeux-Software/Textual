/* ********************************************************************* 
                  _____         _               _
                 |_   _|____  _| |_ _   _  __ _| |
                   | |/ _ \ \/ / __| | | |/ _` | |
                   | |  __/>  <| |_| |_| | (_| | |
                   |_|\___/_/\_\\__|\__,_|\__,_|_|

 Copyright (c) 2008 - 2010 Satoshi Nakagawa <psychs AT limechat DOT net>
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

#import "TPCThemeControllerPrivate.h"

NSString * const TPCThemeControllerCloudThemeNameBasicPrefix			= @"cloud";
NSString * const TPCThemeControllerCloudThemeNameCompletePrefix			= @"cloud:";

NSString * const TPCThemeControllerCustomThemeNameBasicPrefix			= @"user";
NSString * const TPCThemeControllerCustomThemeNameCompletePrefix		= @"user:";

NSString * const TPCThemeControllerBundledThemeNameBasicPrefix			= @"resource";
NSString * const TPCThemeControllerBundledThemeNameCompletePrefix		= @"resource:";

NSString * const TPCThemeControllerThemeListDidChangeNotification		= @"TPCThemeControllerThemeListDidChangeNotification";

#pragma mark -
#pragma mark Theme Controller

@implementation TPCThemeController

- (instancetype)init
{
	if ((self = [super init])) {
		self.customSettings = [TPCThemeSettings new];
	}
	
	return self;
}

- (void)prepareForApplicationTermination
{
	[self stopMonitoringActiveThemePath];

	[self removeTemporaryCopyOfTheme];
}

- (NSString *)path
{
	NSURL *baseURL = [self baseURL];

	return [baseURL path];
}

- (NSString *)temporaryPathLeading
{
	return [TPCPathInfo applicationCachesFolderPath];
}

- (NSString *)temporaryPath
{
	return [[self temporaryPathLeading] stringByAppendingPathComponent:@"/Cached-Style-Resources/"];
}

- (BOOL)usesTemporaryPath
{
	if ([XRSystemInformation isUsingOSXElCapitanOrLater]) {
		return [TPCPreferences webKit2Enabled];
	} else {
		return NO;
	}
}

- (NSString *)name
{
	return [TPCThemeController extractThemeName:self.cachedThemeName];
}

+ (BOOL)themeExists:(NSString *)themeName
{
	NSString *themePath = [self pathOfThemeWithName:themeName];

	return (themePath != nil);
}

+ (BOOL)themeAtPathIsValid:(NSString *)path
{
	PointerIsEmptyAssertReturn(path, NO)

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

	NSString *jssFile = [path stringByAppendingPathComponent:@"scripts.js"];

	if ([RZFileManager() fileExistsAtPath:jssFile] == NO) {
		return NO;
	}

	return YES;
}

+ (NSString *)pathOfThemeWithName:(NSString *)themeName
{
	return [TPCThemeController pathOfThemeWithName:themeName storageLocation:NULL];
}

+ (NSString *)pathOfThemeWithName:(NSString *)themeName storageLocation:(TPCThemeControllerStorageLocation *)storageLocation;
{
	if ( storageLocation) { // Reset value of pointer
		*storageLocation = TPCThemeControllerStorageUnknownLocation;
	}

	NSString *fileSource = [TPCThemeController extractThemeSource:themeName];

	NSString *fileName = [TPCThemeController extractThemeName:themeName];

	NSObjectIsEmptyAssertReturn(fileSource, nil)
	NSObjectIsEmptyAssertReturn(fileName, nil);

	TPCThemeControllerStorageLocation _storageLocation;

	NSString *path = nil;

#if TEXTUAL_BUILT_WITH_ICLOUD_SUPPORT == 1
	if ([fileSource isEqualToString:TPCThemeControllerCloudThemeNameBasicPrefix])
	{
		_storageLocation = TPCThemeControllerStorageCloudLocation;

		path = [[TPCPathInfo cloudCustomThemeFolderPath] stringByAppendingPathComponent:fileName];
	}
	else
#endif
	
	if ([fileSource isEqualToString:TPCThemeControllerCustomThemeNameBasicPrefix])
	{
		_storageLocation = TPCThemeControllerStorageCustomLocation;

		path = [[TPCPathInfo customThemeFolderPath] stringByAppendingPathComponent:fileName];
	}
	else
	{
		_storageLocation = TPCThemeControllerStorageBundleLocation;

		path = [[TPCPathInfo bundledThemeFolderPath] stringByAppendingPathComponent:fileName];
	}

	if ([TPCThemeController themeAtPathIsValid:path]) {
		if ( storageLocation) {
			*storageLocation = _storageLocation;
		}

		return path;
	}
	
	return nil;
}

- (void)load
{
	static BOOL _didLoad = NO;
	
	if (_didLoad == NO) {
		_didLoad = YES;
	} else {
		NSAssert(NO, @"Method called more than one time");
	}
		
	[self startMonitoringAcitveThemePath];

	/* resetPreferencesForPreferredTheme is called for the configured
	 theme before the first ever -reload is called to recover from a
	 style being deleted while the app was closed. */
	[self resetPreferencesForPreferredTheme];

	[self reload];
}

- (void)reload
{
	/* Try to find a theme by the stored name. */
	NSString *themeName = [TPCPreferences themeName];
	
	TPCThemeControllerStorageLocation storageLocation;
	
	NSString *path = [TPCThemeController pathOfThemeWithName:themeName storageLocation:&storageLocation];
	
	if (storageLocation == TPCThemeControllerStorageUnknownLocation) {
		NSAssert(NO, @"Missing style resource files");
	}

	self.cachedThemeName = themeName;

	self.storageLocation = storageLocation;

	self.baseURL = [NSURL fileURLWithPath:path];

	[self.customSettings reloadWithPath:path];

	[self maybePresentCompatibilityWarningDialog];

	[self createTemporaryCopyOfTheme];
}

- (void)removeTemporaryCopyOfTheme
{
	if ([self usesTemporaryPath] == NO) {
		return;
	}

	NSString *temporaryPath = [self temporaryPath];

	if ([RZFileManager() fileExistsAtPath:temporaryPath] == NO) {
		return;
	}

	NSError *removeFileError = nil;

	if ([RZFileManager() removeItemAtPath:temporaryPath error:&removeFileError] == NO) {
		LogToConsole(@"Failed to remove temporary directory: %@", [removeFileError localizedDescription]);
	}
}

- (void)createTemporaryCopyOfTheme
{
	if ([self usesTemporaryPath] == NO) {
		return;
	}

	NSString *temporaryPath = [self temporaryPath];

	[RZFileManager() replaceItemAtPath:temporaryPath
						withItemAtPath:[self path]
					 moveToDestination:NO
				moveDestinationToTrash:NO];
}

- (void)maybePresentCompatibilityWarningDialog
{
	if ([self.customSettings usesIncompatibleTemplateEngineVersion]) {
		NSUInteger nameHash = [self.cachedThemeName hash];

		NSString *suppressionKey = [NSString stringWithFormat:@"incompatible_theme_dialog_%lu", nameHash];

		(void)[TLOPopupPrompts dialogWindowWithMessage:TXTLS(@"BasicLanguage[1246][2]", [self name])
												 title:TXTLS(@"BasicLanguage[1246][1]")
										 defaultButton:TXTLS(@"BasicLanguage[1186]")
									   alternateButton:nil
										suppressionKey:suppressionKey
									   suppressionText:nil];
	}
}

- (BOOL)validateThemeAndRelaodIfNecessary
{
	if ([self resetPreferencesForFaultedTheme]) {
		LogToConsole(@"Reloading theme because it failed validation");

		[TPCPreferences performReloadActionForActionType:TPCPreferencesKeyReloadStyleAction];
		
		return YES;
	} else {
		return NO;
	}
}

- (void)resetPreferencesForPreferredTheme
{
	NSString *themeName = [TPCPreferences themeName];

	(void)[self resetPreferencesForFaultedTheme:themeName];
}

- (BOOL)resetPreferencesForFaultedTheme
{
	NSString *themeName = [self cachedThemeName];

	return [self resetPreferencesForFaultedTheme:themeName];
}

- (BOOL)resetPreferencesForFaultedTheme:(NSString *)themeName
{
	NSString *suggestedThemeName = nil;
	NSString *suggestedFontName = nil;
	
	BOOL validationResult = [self performValidationForTheme:themeName suggestedTheme:&suggestedThemeName suggestedFont:&suggestedFontName];

	if (validationResult == NO) {
		if (suggestedThemeName) {
			[TPCPreferences setThemeName:suggestedThemeName];
		}
		
		if (suggestedFontName) {
			[TPCPreferences setThemeChannelViewFontName:suggestedFontName];
		}
		
		return YES;
	} else {
		return NO;
	}
}

- (BOOL)performValidationForCurrentTheme:(NSString **)suggestedThemeName suggestedFont:(NSString **)suggestedFontName
{
	NSString *themeName = [self cachedThemeName];

	return [self performValidationForTheme:themeName suggestedTheme:suggestedThemeName suggestedFont:suggestedFontName];
}

- (BOOL)performValidationForTheme:(NSString *)validatedTheme suggestedTheme:(NSString **)suggestedThemeName suggestedFont:(NSString **)suggestedFontName
{
	/* Validate font. */
	BOOL keyChanged = NO;

	NSString *fontName = [TPCPreferences themeChannelViewFontName];

	if ([NSFont fontIsAvailable:fontName] == NO) {
		if ( suggestedFontName) {
			*suggestedFontName = TXDefaultTextualChannelViewFont;
		}
		
		keyChanged = YES;
	}
	
	/* Validate theme. */
	NSString *themeSource = [TPCThemeController extractThemeSource:validatedTheme];

	NSString *themeName = [TPCThemeController extractThemeName:validatedTheme];

	DebugLogToConsole(@"Performing validation on theme named \"%@\" with source type of \"%@\"", themeName, themeSource);
	
	if ([themeSource isEqualToString:TPCThemeControllerBundledThemeNameBasicPrefix])
	{
		/* If the theme is faulted and is a bundled theme, then we can do
		 nothing except try to recover by using the default one. */
		if ([TPCThemeController themeExists:validatedTheme] == NO) {
			if ( suggestedThemeName) {
				*suggestedThemeName = TXDefaultTextualChannelViewTheme;
				
				keyChanged = YES;
			}
		}
	}
	else if ([themeSource isEqualToString:TPCThemeControllerCustomThemeNameBasicPrefix])
	{
		/* Even if the current theme is custom and is valid, we still will validate whether
		 a cloud variant of it exists and if it does, prefer that over the custom. */
		NSString *cloudTheme = [TPCThemeController buildFilename:themeName forStorageLocation:TPCThemeControllerStorageCloudLocation];

		NSString *bundledTheme = [TPCThemeController buildFilename:themeName forStorageLocation:TPCThemeControllerStorageBundleLocation];
		
		if ([TPCThemeController themeExists:cloudTheme]) {
			/* If the theme exists in the cloud, then we go to that. */
			if ( suggestedThemeName) {
				*suggestedThemeName = cloudTheme;

				keyChanged = YES;
			}
		} else {
			/* If there is no cloud theme, then we continue validation. */
			if ([TPCThemeController themeExists:validatedTheme] == NO) {
				if ([TPCThemeController themeExists:bundledTheme]) {
					/* Use a bundled theme with the same name if available. */
					if ( suggestedThemeName) {
						*suggestedThemeName = bundledTheme;
						
						keyChanged = YES;
					}
				} else {
					/* Revert back to the default theme if no recovery is possible. */
					if ( suggestedThemeName) {
						*suggestedThemeName = TXDefaultTextualChannelViewTheme;
						
						keyChanged = YES;
					}
				}
			}
		}
	}
	else if ([themeSource isEqualToString:TPCThemeControllerCloudThemeNameBasicPrefix])
	{
		if ([TPCThemeController themeExists:validatedTheme] == NO) {
			/* If the current theme stored in the cloud is not valid, then we try to revert
			 to a custom one or a bundled one depending which one is available. */
			NSString *customTheme = [TPCThemeController buildFilename:themeName forStorageLocation:TPCThemeControllerStorageCustomLocation];

			NSString *bundledTheme = [TPCThemeController buildFilename:themeName forStorageLocation:TPCThemeControllerStorageBundleLocation];
			
			if ([TPCThemeController themeExists:customTheme]) {
				/* Use a custom theme with the same name if available. */
				if ( suggestedThemeName) {
					*suggestedThemeName = customTheme;
					
					keyChanged = YES;
				}
			} else if ([TPCThemeController themeExists:bundledTheme]) {
				/* Use a bundled theme with the same name if available. */
				if ( suggestedThemeName) {
					*suggestedThemeName = bundledTheme;
					
					keyChanged = YES;
				}
			} else {
				/* Revert back to the default theme if no recovery is possible. */
				if ( suggestedThemeName) {
					*suggestedThemeName = TXDefaultTextualChannelViewTheme;
					
					keyChanged = YES;
				}
			}
		}
	}

	return (keyChanged == NO);
}

- (BOOL)isBundledTheme
{
	return ([self storageLocation] == TPCThemeControllerStorageBundleLocation);
}

+ (NSString *)buildFilename:(NSString *)name forStorageLocation:(TPCThemeControllerStorageLocation)storageLocation
{
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

+ (NSString *)extractThemeSource:(NSString *)source
{
	if ([source hasPrefix:TPCThemeControllerCloudThemeNameCompletePrefix] == NO &&
		[source hasPrefix:TPCThemeControllerCustomThemeNameCompletePrefix] == NO &&
		[source hasPrefix:TPCThemeControllerBundledThemeNameCompletePrefix] == NO)
	{
		return nil;
    }

	NSInteger colonIndex = [source stringPosition:@":"];

	return [source substringToIndex:colonIndex];
}

+ (NSString *)extractThemeName:(NSString *)source
{
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

- (NSDictionary *)dictionaryOfAllThemes
{
	NSMutableDictionary *allThemes = [NSMutableDictionary dictionary];

	void (^checkPath)(NSString *, NSString *) = ^(NSString *storagePath, NSString *storageType) {
		if ([RZFileManager() fileExistsAtPath:storagePath] == NO) {
			return;
		}

		NSArray *files = [RZFileManager() contentsOfDirectoryAtPath:storagePath error:NULL];
			
		for (NSString *file in files) {
			if ([allThemes containsKey:file]) {
				continue;
			}

			NSString *filePath = [storagePath stringByAppendingPathComponent:file];

			if ([TPCThemeController themeAtPathIsValid:filePath] == NO) {
				continue;
			}

			allThemes[file] = storageType;
		}
	};
	
	/* File paths are ordered by priority. Top-most will be most important. */
#if TEXTUAL_BUILT_WITH_ICLOUD_SUPPORT == 1
	checkPath([TPCPathInfo cloudCustomThemeFolderPath], TPCThemeControllerCloudThemeNameCompletePrefix);
#endif
	
	checkPath([TPCPathInfo customThemeFolderPath], TPCThemeControllerCustomThemeNameCompletePrefix);
	checkPath([TPCPathInfo bundledThemeFolderPath], TPCThemeControllerBundledThemeNameCompletePrefix);
	
	return allThemes;
}

void activeThemePathMonitorCallback(ConstFSEventStreamRef streamRef,
									void *clientCallBackInfo,
									size_t numEvents,
									void *eventPaths,
									const FSEventStreamEventFlags eventFlags[],
									const FSEventStreamEventId eventIds[])
{
	/* One of these days I will get around to making this less shitty. Today is not that day. */
	@autoreleasepool {
		BOOL activeThemeContentsWereDeleted = NO;
		BOOL activeThemeContentsWereModified = NO;
		
		BOOL postDidChangeNotification = NO;

		NSString *themePath = [themeController() path];

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

			/* Update status of any monitored files. */
			if ( flags & kFSEventStreamEventFlagItemIsFile &&
				(flags & kFSEventStreamEventFlagItemCreated ||
				 flags & kFSEventStreamEventFlagItemRemoved ||
				 flags & kFSEventStreamEventFlagItemRenamed ||
				 flags & kFSEventStreamEventFlagItemModified))
			{
				if ([path hasPrefix:[themeController() path]] == NO) {
					continue;
				}

				/* Recognize if one of these files were either deleted or modified.
				 If one was, then we set continue; to skip any further action and 
				 update the theme based on deletion or modification status. */
				_updateConditionForPath(@"design.css")
				_updateConditionForPath(@"scripts.js")
				_updateConditionForPath(@"Data/Settings/styleSettings.plist")
				
				/* Check status for generic files. */
				NSString *fileExtension = [path pathExtension];

				if ([fileExtension isEqualToString:@"js"] ||
					[fileExtension isEqualToString:@"css"])
				{
					activeThemeContentsWereModified = YES;
					
					continue; // Only thing we care about here...
				}
			}
			
			/* Update status of inset stuff. */
			if (flags & kFSEventStreamEventFlagItemIsDir) {
				BOOL pathIsThemeRoot = [path isEqualToString:themePath];

				/* Establish base context of event. */
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
			LogToConsole(@"The contents of the configured theme was deleted. Validation and reload will now occur.");

			(void)[themeController() validateThemeAndRelaodIfNecessary];
		}
		else if (activeThemeContentsWereModified)
		{
			if ([TPCPreferences automaticallyReloadCustomThemesWhenTheyChange]) {
				[TPCPreferences performReloadActionForActionType:TPCPreferencesKeyReloadStyleWithTableViewsAction];
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

	[self startMonitoringAcitveThemePath];
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

- (void)startMonitoringAcitveThemePath
{
	void *callbackInfo = NULL;
	
	NSArray *pathsToWatch = nil;

#if TEXTUAL_BUILT_WITH_ICLOUD_SUPPORT == 1
	if ([sharedCloudManager() ubiquitousContainerIsAvailable]) {
		pathsToWatch = @[[TPCPathInfo customThemeFolderPath], [TPCPathInfo cloudCustomThemeFolderPath]];
	} else {
#endif

		pathsToWatch = @[[TPCPathInfo customThemeFolderPath]];

#if TEXTUAL_BUILT_WITH_ICLOUD_SUPPORT == 1
	}
#endif

	CFArrayRef pathsToWatchRef = (__bridge CFArrayRef)(pathsToWatch);
	
	CFAbsoluteTime latency = 5.0;
 
	FSEventStreamRef stream = FSEventStreamCreate(NULL, &activeThemePathMonitorCallback, callbackInfo, pathsToWatchRef, kFSEventStreamEventIdSinceNow, latency, (kFSEventStreamCreateFlagFileEvents | kFSEventStreamCreateFlagUseCFTypes));
	
	FSEventStreamScheduleWithRunLoop(stream, CFRunLoopGetCurrent(), kCFRunLoopDefaultMode);
	FSEventStreamStart(stream);
	
	self.eventStreamRef = stream;
}

- (void)copyActiveThemeToDestinationLocation:(TPCThemeControllerStorageLocation)destinationLocation reloadOnCopy:(BOOL)reloadOnCopy openNewPathOnCopy:(BOOL)openNewPathOnCopy
{
	if (self.currentCopyOperation) {
		NSAssert(NO, @"Tried to create a new copy operation with one already in progress");
	} else if ([self storageLocation] == destinationLocation) {
		LogToConsole(@"Tried to copy active theme to same storage location that it already exists within");
	} else if (TPCThemeControllerStorageBundleLocation == destinationLocation) {
		LogToConsole(@"Tried to copy active theme to the application itself");
	} else {
		TPCThemeControllerCopyOperation *copyOperation = [TPCThemeControllerCopyOperation new];
		
		[copyOperation setThemeName:[self name]];

		[copyOperation setPathBeingCopiedFrom:[self path]];
		[copyOperation setDestinationLocation:destinationLocation];

		[copyOperation setOpenThemeWhenCopied:openNewPathOnCopy];
		[copyOperation setReloadThemeWhenCopied:reloadOnCopy];
		
		[copyOperation beginOperation];

		self.currentCopyOperation = copyOperation;
	}
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
	TDCProgressInformationSheet *ps = [TDCProgressInformationSheet new];
	
	[ps startWithWindow:[NSApp keyWindow]];

	self.progressIndicator = ps;
	
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

	NSURL *sourceURL = [NSURL fileURLWithPath:self.pathBeingCopiedFrom];

	NSURL *destinationURL = [NSURL fileURLWithPath:self.pathBeingCopiedTo];

#define _cancelOperationAndReturn			[self cancelOperation];		\
																		\
											return;

#if TEXTUAL_BUILT_WITH_ICLOUD_SUPPORT == 1
	if (self.destinationLocation == TPCThemeControllerStorageCloudLocation)
	{
		/* When copying to iCloud, we copy the style to a temporary folder then 
		 have OS X handle the transfer of said folder to iCloud on our behalf. */
		if ([RZFileManager() fileExistsAtPath:[destinationURL path]]) {
			NSError *trashItemError = nil;

			if ([RZFileManager() trashItemAtURL:destinationURL resultingItemURL:NULL error:&trashItemError]) {
				LogToConsole(@"A copy of the theme being copied already exists at the destination path. This copy has been moved to the trash.")
			} else {
				LogToConsole(@"Failed to trash destination: '%@': %@",
					[destinationURL path], [trashItemError localizedDescription])

				_cancelOperationAndReturn
			}
		}

		/* Copy to temporary location */
		NSString *fakeDestinationPath = [[TPCPathInfo applicationTemporaryFolderPath] stringByAppendingPathComponent:[NSString stringWithUUID]];
		
		NSURL *fakeDestinationURL = [NSURL fileURLWithPath:fakeDestinationPath];

		NSError *copyFileError = nil;

		if ([RZFileManager() copyItemAtURL:sourceURL toURL:fakeDestinationURL error:&copyFileError] == NO) {
			LogToConsole(@"Failed to perform copy: '%@' -> '%@': %@",
				[sourceURL path], [fakeDestinationURL path], [copyFileError localizedDescription])

			_cancelOperationAndReturn
		}

		/* Move item to iCloud */
		NSError *setUbiquitousError = nil;

		if ([RZFileManager() setUbiquitous:YES itemAtURL:fakeDestinationURL destinationURL:destinationURL error:&setUbiquitousError] == NO) {
			LogToConsole(@"Failed to set item as ubiquitous: '%@': %@",
				[fakeDestinationURL path], [setUbiquitousError localizedDescription])

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
		destinationPath = [TPCPathInfo customThemeFolderPath];

#if TEXTUAL_BUILT_WITH_ICLOUD_SUPPORT == 1
	}
	else if (self.destinationLocation == TPCThemeControllerStorageCloudLocation)
	{
		/* If the destination was set for the cloud, but the cloud is not available,
		 then we update our destinationLocation property so that the theme controller
		 actually will know where to look for the new theme. */
		if ([sharedCloudManager() ubiquitousContainerIsAvailable] == NO) {
			self.destinationLocation = TPCThemeControllerStorageCustomLocation;

			destinationPath = [TPCPathInfo customThemeFolderPath];
		} else {
			destinationPath = [TPCPathInfo cloudCustomThemeFolderPath];
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
	/* Maybe open new path of theme. */
	if (self.openThemeWhenCopied) {
		[RZWorkspace() openFile:self.pathBeingCopiedTo];
	}
	
	/* Maybe reload new theme. */
	if (self.reloadThemeWhenCopied) {
		NSString *newThemeName = [TPCThemeController buildFilename:self.themeName forStorageLocation:self.destinationLocation];
		
		[TPCPreferences setThemeName:newThemeName];

		[TPCPreferences performReloadActionForActionType:TPCPreferencesKeyReloadStyleWithTableViewsAction];
	}
	
	/* Close progress indicator */
	[self invalidateOperation];
}

- (void)invalidateOperation
{
	[self.progressIndicator stop];
	 self.progressIndicator = nil;
	
	[themeController() copyActiveThemeOperationCompleted];
}

@end
