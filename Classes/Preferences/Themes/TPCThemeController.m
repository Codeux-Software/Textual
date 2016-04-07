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

#pragma mark -
#pragma mark Theme Controller Private Headers

NSString * const TPCThemeControllerCloudThemeNameBasicPrefix			= @"cloud";
NSString * const TPCThemeControllerCloudThemeNameCompletePrefix			= @"cloud:";

NSString * const TPCThemeControllerCustomThemeNameBasicPrefix			= @"user";
NSString * const TPCThemeControllerCustomThemeNameCompletePrefix		= @"user:";

NSString * const TPCThemeControllerBundledThemeNameBasicPrefix			= @"resource";
NSString * const TPCThemeControllerBundledThemeNameCompletePrefix		= @"resource:";

NSString * const TPCThemeControllerThemeListDidChangeNotification		= @"TPCThemeControllerThemeListDidChangeNotification";

/* Copy operation class is responsible for copying the active theme to a different
 location when a user requests a local copy of the theme. */
/* I only comment most of this stuff to remember why I did it later on. I am not 
 commenting it for a plugin to use this private implementaion. */
@interface TPCThemeControllerCopyOperation : NSObject
@property (nonatomic, copy) NSString *themeName; // Name without source prefix
@property (nonatomic, copy) NSString *pathBeingCopiedTo; // Set by -beginOperation. Do not set this to pick destination.
@property (nonatomic, copy) NSString *pathBeingCopiedFrom; // Must be set before -beginOperation is called
@property (nonatomic, assign) TPCThemeControllerStorageLocation destinationLocation;
@property (nonatomic, assign) BOOL reloadThemeWhenCopied; // If YES, setThemeName: is called when copy completes. Otherwise, files are copied and nothing happens.
@property (nonatomic, assign) BOOL openPathToNewThemeWhenCopied;
@property (nonatomic, strong) TDCProgressInformationSheet *progressIndicator;

- (void)beginOperation; // Is dependent on most of stuff above being defined
- (void)completeOperation;

- (void)maybeFinishWithFolderPath:(NSString *)path;
@end

/* Private header for theme controller that a plugin does not need access to. */
@interface TPCThemeController ()
@property (nonatomic, assign) FSEventStreamRef eventStreamRef;
@property (nonatomic, strong) TPCThemeControllerCopyOperation *currentCopyOperation;
@end

#pragma mark -
#pragma mark Theme Controller

@implementation TPCThemeController

- (instancetype)init
{
	if ((self = [super init])) {
		[self setCustomSettings:[TPCThemeSettings new]];
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
	return [[self baseURL] path];
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

- (NSString *)actualPath
{
	return [TPCThemeController pathOfThemeWithName:[self associatedThemeName] skipCloudCache:YES storageLocation:NULL];
}

- (NSString *)name
{
	return [TPCThemeController extractThemeName:[self associatedThemeName]];
}

+ (BOOL)themeExists:(NSString *)themeName
{
	TPCThemeControllerStorageLocation expectedLocation = [TPCThemeController expectedStorageLocationOfThemeWithName:themeName];

	TPCThemeControllerStorageLocation actualLocation = [TPCThemeController actaulStorageLocationOfThemeWithName:themeName];
	
	return (expectedLocation == actualLocation);
}

+ (NSString *)pathOfThemeWithName:(NSString *)themeName
{
	return [self pathOfThemeWithName:themeName skipCloudCache:NO storageLocation:NULL];
}

+ (NSString *)pathOfThemeWithName:(NSString *)themeName skipCloudCache:(BOOL)ignoreCloudCache storageLocation:(TPCThemeControllerStorageLocation *)storageLocation
{
	NSString *filekind = [TPCThemeController extractThemeSource:themeName];
	NSString *filename = [TPCThemeController extractThemeName:themeName];
	
	if (NSObjectIsNotEmpty(filename) &&
		NSObjectIsNotEmpty(filekind))
	{
		NSString *path = nil;

#if TEXTUAL_BUILT_WITH_ICLOUD_SUPPORT == 1
		if ([filekind isEqualToString:TPCThemeControllerCloudThemeNameBasicPrefix]) {
			/* Does the theme exist in the cloud? */
			if (ignoreCloudCache) {
				path = [[TPCPathInfo cloudCustomThemeFolderPath] stringByAppendingPathComponent:filename];
			} else {
				path = [[TPCPathInfo cloudCustomThemeCachedFolderPath] stringByAppendingPathComponent:filename];
			}
			
			if ([RZFileManager() fileExistsAtPath:path]) {
				NSString *cssFile = [path stringByAppendingPathComponent:@"design.css"];
				NSString *jssFile = [path stringByAppendingPathComponent:@"scripts.js"];
				
				if ([RZFileManager() fileExistsAtPath:cssFile] &&
					[RZFileManager() fileExistsAtPath:jssFile])
				{
					if ( storageLocation) {
						*storageLocation = TPCThemeControllerStorageCloudLocation;
					}
					
					return path;
				}
			}
		} else
#endif
		
		if ([filekind isEqualToString:TPCThemeControllerCustomThemeNameBasicPrefix]) {
			/* Does it exist locally? */
			path = [[TPCPathInfo customThemeFolderPath] stringByAppendingPathComponent:filename];
			
			if ([RZFileManager() fileExistsAtPath:path]) {
				NSString *cssFile = [path stringByAppendingPathComponent:@"design.css"];
				NSString *jssFile = [path stringByAppendingPathComponent:@"scripts.js"];
				
				if ([RZFileManager() fileExistsAtPath:cssFile] &&
					[RZFileManager() fileExistsAtPath:jssFile])
				{
					if ( storageLocation) {
						*storageLocation = TPCThemeControllerStorageCustomLocation;
					}
					
					return path;
				}
			}
		} else {
			/* Does the theme exist in app? */
			path = [[TPCPathInfo bundledThemeFolderPath] stringByAppendingPathComponent:filename];
			
			if ([RZFileManager() fileExistsAtPath:path]) {
				NSString *cssFile = [path stringByAppendingPathComponent:@"design.css"];
				NSString *jssFile = [path stringByAppendingPathComponent:@"scripts.js"];
				
				if ([RZFileManager() fileExistsAtPath:cssFile] &&
					[RZFileManager() fileExistsAtPath:jssFile])
				{
					if ( storageLocation) {
						*storageLocation = TPCThemeControllerStorageBundleLocation;
					}
					
					return path;
				}
			}
		}
	}
	
	if ( storageLocation) {
		*storageLocation = TPCThemeControllerStorageUnknownLocation;
	}
	
	return nil;
}

- (void)load
{
	static BOOL _didLoad = NO;
	
	if (_didLoad) {
		NSAssert(NO, @"Method called more than one time");
	} else {
		_didLoad = YES;
		
		[self startMonitoringAcitveThemePath];

		[self resetConfiguredPreferencesForFaultedTheme:NO];

		[self reload];
	}
}

- (void)reload
{
	/* Destroy temporary directory if it already exists. */
	[self removeTemporaryCopyOfTheme];

	/* Try to find a theme by the stored name. */
	[self setAssociatedThemeName:[TPCPreferences themeName]];
	
	TPCThemeControllerStorageLocation storageLocation = TPCThemeControllerStorageUnknownLocation;
	
	NSString *path = [TPCThemeController pathOfThemeWithName:[self associatedThemeName]
											  skipCloudCache:NO
											 storageLocation:&storageLocation];
	
	if (storageLocation == TPCThemeControllerStorageUnknownLocation) {
		NSAssert(NO, @"Missing style resource files");
	}
	
	[self setStorageLocation:storageLocation];
	
	/* We have a path. */
	[self setBaseURL:[NSURL fileURLWithPath:path]];

	/* Reload theme settings. */
	[[self customSettings] reloadWithPath:path];

	/* Maybe present warning dialog. */
	[self maybePresentCompatibilityWarningDialog];

	/* Create temporary copy of theme. */
	[self createTemporaryCopyOfTheme];
}

- (void)removeTemporaryCopyOfTheme
{
	NSString *temporaryPath = [self temporaryPath];

	if ([RZFileManager() directoryExistsAtPath:temporaryPath]) {
		NSError *removeFileError = nil;

		if ([RZFileManager() removeItemAtPath:temporaryPath error:&removeFileError] == NO) {
			LogToConsole(@"Failed to remove temporary directory: %@", [removeFileError localizedDescription]);
		}
	}
}

- (void)createTemporaryCopyOfTheme
{
	/* Do not create temporary path if we do no need it. */
	NSAssertReturn([self usesTemporaryPath]);

	/* Perform copy operation */
	NSString *temporaryPath = [self temporaryPath];

	NSError *copyFileError = nil;

	if ([RZFileManager() copyItemAtPath:[self path] toPath:temporaryPath error:&copyFileError] == NO) {
		LogToConsole(@"Failed to copy temporary directory: %@", [copyFileError localizedDescription]);
	}
}

- (void)maybePresentCompatibilityWarningDialog
{
	if ([[self customSettings] usesIncompatibleTemplateEngineVersion]) {
		/* Use hash of name so the suppression is per-theme. */
		NSString *suppressionKey = [NSString stringWithFormat:@"incompatible_theme_dialog_%lu", [[self associatedThemeName] hash]];

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
	if ([self resetConfiguredPreferencesForFaultedTheme]) {
		LogToConsole(@"Reloading theme because it failed validation");

		[TPCPreferences performReloadActionForActionType:TPCPreferencesKeyReloadStyleAction];
		
		return YES;
	} else {
		return NO;
	}
}

- (BOOL)resetConfiguredPreferencesForFaultedTheme
{
	return [self resetConfiguredPreferencesForFaultedTheme:YES];
}

- (BOOL)resetConfiguredPreferencesForFaultedTheme:(BOOL)usesLoadedTheme
{
	NSString *suggestedThemeName = nil;
	NSString *suggestedFontName = nil;
	
	NSString *validatedTheme = nil;
	
	if (usesLoadedTheme) {
		validatedTheme = [self associatedThemeName];
	} else {
		validatedTheme = [TPCPreferences themeName];
	}
	
	BOOL validationResult = [self performValidationForTheme:validatedTheme suggestedTheme:&suggestedThemeName suggestedFont:&suggestedFontName];

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

- (BOOL)performValidationForCurrentTheme:(NSString * __autoreleasing *)suggestedThemeName suggestedFont:(NSString * __autoreleasing *)suggestedFontName
{
	return [self performValidationForTheme:[self associatedThemeName] suggestedTheme:suggestedThemeName suggestedFont:suggestedFontName];
}

- (BOOL)performValidationForTheme:(NSString *)validatedTheme suggestedTheme:(NSString * __autoreleasing  *)suggestedThemeName suggestedFont:(NSString * __autoreleasing *)suggestedFontName
{
	/* Validate font. */
	BOOL keyChanged = NO;
	
	if ([NSFont fontIsAvailable:[TPCPreferences themeChannelViewFontName]] == NO) {
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
				*suggestedThemeName = [TXDefaultTextualChannelViewTheme copy];
				
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
				*suggestedThemeName = [cloudTheme copy];

				keyChanged = YES;
			}
		} else {
			/* If there is no cloud theme, then we continue validation. */
			if ([TPCThemeController themeExists:validatedTheme] == NO) {
				if ([TPCThemeController themeExists:bundledTheme]) {
					/* Use a bundled theme with the same name if available. */
					if ( suggestedThemeName) {
						*suggestedThemeName = [bundledTheme copy];
						
						keyChanged = YES;
					}
				} else {
					/* Revert back to the default theme if no recovery is possible. */
					if ( suggestedThemeName) {
						*suggestedThemeName = [TXDefaultTextualChannelViewTheme copy];
						
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
					*suggestedThemeName = [customTheme copy];
					
					keyChanged = YES;
				}
			} else {
				if ([TPCThemeController themeExists:bundledTheme]) {
					/* Use a bundled theme with the same name if available. */
					if ( suggestedThemeName) {
						*suggestedThemeName = [bundledTheme copy];
						
						keyChanged = YES;
					}
				} else {
					/* Revert back to the default theme if no recovery is possible. */
					if ( suggestedThemeName) {
						*suggestedThemeName = [TXDefaultTextualChannelViewTheme copy];
						
						keyChanged = YES;
					}
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

+ (TPCThemeControllerStorageLocation)actaulStorageLocationOfThemeWithName:(NSString *)themeName
{
	TPCThemeControllerStorageLocation storageLocation = TPCThemeControllerStorageUnknownLocation;
	
	NSString *path = [TPCThemeController pathOfThemeWithName:themeName skipCloudCache:NO storageLocation:&storageLocation];
	
#pragma unused(path)
	
	return storageLocation;
}

+ (NSString *)extractThemeSource:(NSString *)source
{
	if ([source hasPrefix:TPCThemeControllerCloudThemeNameCompletePrefix] == NO &&
		[source hasPrefix:TPCThemeControllerCustomThemeNameCompletePrefix] == NO &&
		[source hasPrefix:TPCThemeControllerBundledThemeNameCompletePrefix] == NO)
	{
		return nil;
    }

	return [source substringToIndex:[source stringPosition:@":"]];
}

+ (NSString *)extractThemeName:(NSString *)source
{
	if ([source hasPrefix:TPCThemeControllerCloudThemeNameCompletePrefix] == NO &&
		[source hasPrefix:TPCThemeControllerCustomThemeNameCompletePrefix] == NO &&
		[source hasPrefix:TPCThemeControllerBundledThemeNameCompletePrefix] == NO)
	{
		return nil;
    }
	
	return [source substringAfterIndex:[source stringPosition:@":"]];	
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

	void (^checkPath)(NSString *, NSString *) = ^(NSString *pathObj, NSString *typeName) {
		if ([pathObj length] > 0) {
			BOOL pathExists = [RZFileManager() fileExistsAtPath:pathObj];
			
			if (pathExists) {
				NSArray *files = [RZFileManager() contentsOfDirectoryAtPath:pathObj error:NULL];
					
				for (NSString *file in files) {
					if ([allThemes containsKey:file]) {
						; // Theme already exists somewhere else.
					} else {
						NSString *cssfilelocal = [pathObj stringByAppendingPathComponent:[file stringByAppendingString:@"/design.css"]];
						NSString *jssfilelocal = [pathObj stringByAppendingPathComponent:[file stringByAppendingString:@"/scripts.js"]];
						
						if ([RZFileManager() fileExistsAtPath:cssfilelocal] &&
							[RZFileManager() fileExistsAtPath:jssfilelocal])
						{
							allThemes[file] = typeName;
						}
					}
				}
			}
		}
	};
	
	/* File paths are ordered by priority. Top-most will be most important. */
#if TEXTUAL_BUILT_WITH_ICLOUD_SUPPORT == 1
	checkPath([TPCPathInfo cloudCustomThemeCachedFolderPath], TPCThemeControllerCloudThemeNameCompletePrefix);
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

#define _themeFilePath(s)					[[themeController() path] stringByAppendingPathComponent:(s)]
	
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
			
			BOOL isChangeType = NO;

			/* Update status of any monitored files. */
			if ( flags & kFSEventStreamEventFlagItemIsFile &&
				(flags & kFSEventStreamEventFlagItemCreated ||
				 flags & kFSEventStreamEventFlagItemRemoved ||
				 flags & kFSEventStreamEventFlagItemRenamed ||
				 flags & kFSEventStreamEventFlagItemModified))
			{
				if ([path hasPrefix:[themeController() path]]) {
					/* Recognize if one of these files were either deleted or modified. 
					 If one was, then we set continue; to skip any further action and 
					 update the theme based on deletion or modification status. */
					_updateConditionForPath(@"design.css")
					_updateConditionForPath(@"scripts.js")
					_updateConditionForPath(@"Data/Settings/styleSettings.plist")
					
					/* Check status for generic files. */
					if ([path hasSuffix:@".js"] ||
						[path hasSuffix:@".css"])
					{
						activeThemeContentsWereModified = YES;
						
						continue; // Only thing we care about here...
					}
				}
				
				continue; // Only thing we care about here...
			}
			
			/* Update status of inset stuff. */
			if (flags & kFSEventStreamEventFlagItemIsDir) {
				/* Establish base context of event. */
				if (flags & kFSEventStreamEventFlagItemCreated) {
					isChangeType = YES;
				} else if (flags & kFSEventStreamEventFlagItemRemoved ||
						   flags & kFSEventStreamEventFlagItemRenamed)
				{
					if ([path isEqualToString:[themeController() path]]) {
						activeThemeContentsWereDeleted = YES;
					}
					
					isChangeType = YES;
				}
				
				/* Maybe post notification for root changes. */
				if (isChangeType) {
					TPCThemeControllerCopyOperation *copyOperation = [themeController() currentCopyOperation];
					
					if ( copyOperation) {
						[copyOperation maybeFinishWithFolderPath:path];
					}
				}
				
				postDidChangeNotification = YES;
			}
		}
	
		if (activeThemeContentsWereDeleted) {
			LogToConsole(@"The contents of the configured theme was deleted. Validation and reload will now occur.");

			(void)[themeController() validateThemeAndRelaodIfNecessary];
		} else if (activeThemeContentsWereModified) {
			if ([TPCPreferences automaticallyReloadCustomThemesWhenTheyChange]) {
				[TPCPreferences performReloadActionForActionType:TPCPreferencesKeyReloadStyleWithTableViewsAction];
			}
		}
		
		/* I should probably make this so it only posts when a the highest possible folder 
		 in our monitored folders change, but that would require me to give a fuck. */
		if (postDidChangeNotification) {
			[RZNotificationCenter() postNotificationName:TPCThemeControllerThemeListDidChangeNotification object:nil];
		}
	}

#undef _themeFilePath
}

- (void)stopMonitoringActiveThemePath
{
	if ([self eventStreamRef]) {
		FSEventStreamStop([self eventStreamRef]);
		FSEventStreamInvalidate([self eventStreamRef]);
		FSEventStreamRelease([self eventStreamRef]);
		
		[self setEventStreamRef:NULL];
	}
}

- (void)startMonitoringAcitveThemePath
{
	void *callbackInfo = NULL;
	
	NSArray *pathsToWatch = @[
#if TEXTUAL_BUILT_WITH_ICLOUD_SUPPORT == 1
		[TPCPathInfo cloudCustomThemeCachedFolderPath],
#endif
							  
		[TPCPathInfo customThemeFolderPath]
	];
	
	CFAbsoluteTime latency = 5.0;
 
	FSEventStreamRef stream = FSEventStreamCreate(NULL, &activeThemePathMonitorCallback, callbackInfo, (__bridge CFArrayRef)(pathsToWatch), kFSEventStreamEventIdSinceNow, latency, (kFSEventStreamCreateFlagFileEvents | kFSEventStreamCreateFlagUseCFTypes));
	
	FSEventStreamScheduleWithRunLoop(stream, CFRunLoopGetCurrent(), kCFRunLoopDefaultMode);
	FSEventStreamStart(stream);
	
	[self setEventStreamRef:stream];
}

- (void)copyActiveStyleToDestinationLocation:(TPCThemeControllerStorageLocation)destinationLocation reloadOnCopy:(BOOL)reloadOnCopy openNewPathOnCopy:(BOOL)openNewPathOnCopy
{
	if ([self currentCopyOperation]) {
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
		
		[copyOperation setReloadThemeWhenCopied:reloadOnCopy];
		[copyOperation setOpenPathToNewThemeWhenCopied:openNewPathOnCopy];
		
		[copyOperation beginOperation];
		
		[self setCurrentCopyOperation:copyOperation];
	}
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
	
	[self setProgressIndicator:ps];
	
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
	/* Define which path we are copying to. */
	NSString *destinationPath = nil;
	
#if TEXTUAL_BUILT_WITH_ICLOUD_SUPPORT == 1
	BOOL isCloudCopy = NO;
#endif
	
	if ([self destinationLocation] == TPCThemeControllerStorageCustomLocation) {
		destinationPath = [TPCPathInfo customThemeFolderPath];
		
#if TEXTUAL_BUILT_WITH_ICLOUD_SUPPORT == 1
	} else if ([self destinationLocation] == TPCThemeControllerStorageCloudLocation) {
		if ([sharedCloudManager() ubiquitousContainerIsAvailable]) {
			isCloudCopy = YES;
		
			destinationPath = [TPCPathInfo cloudCustomThemeFolderPath];
		} else {
			destinationPath = [TPCPathInfo customThemeFolderPath];
			
			/* If the destination was set for the cloud, but the cloud is not available,
			 then we update our destinationLocation property so that the theme controller
			 actually will know where to look for the new theme. */
			[self setDestinationLocation:TPCThemeControllerStorageCustomLocation];
		}
#endif
		
	}
	
	/* Append name to destination path. */
	destinationPath = [destinationPath stringByAppendingPathComponent:[self themeName]];
	
	[self setPathBeingCopiedTo:destinationPath];
	
	/* Now that we know where the files will go, we can begin copying them. */
	NSURL *destinationURL = [NSURL fileURLWithPath:destinationPath];

#if TEXTUAL_BUILT_WITH_ICLOUD_SUPPORT == 1
	/* If we are copying to the cloud, then we take special precautions. */
	if (isCloudCopy) {
		/* While we are doing cloud related work, we pause metadata updates. */
		[sharedCloudManager() pauseCloudContainerMetadataUpdates];

		/* Does the theme already exist within the cache? */
		NSString *cachePath = [[TPCPathInfo cloudCustomThemeCachedFolderPath] stringByAppendingPathComponent:[self themeName]];
		
		if ([RZFileManager() fileExistsAtPath:cachePath]) {
			/* Try to delete */
			NSError *deletionError = nil;
			
			/* Perform deletion operation */
			if ([RZFileManager() removeItemAtPath:cachePath error:&deletionError] == NO) {
				[self cancelOperationAndReportError:deletionError];
				
				return; // Cannot continue without success
			}
		}
	}
#endif
	
	/* We can now check if the theme already exists at the destination. */
	if ([RZFileManager() fileExistsAtPath:destinationPath]) {
		/* Try to delete */
		NSError *deletionError = nil;
		
		/* Perform deletion operation */
		if ([RZFileManager() trashItemAtURL:destinationURL resultingItemURL:NULL error:&deletionError] == NO) {
#if TEXTUAL_BUILT_WITH_ICLOUD_SUPPORT == 1
			if (isCloudCopy) {
				[sharedCloudManager() resumeCloudContainerMetadataUpdates];
			}
#endif
			
			[self cancelOperationAndReportError:deletionError];
			
			return; // Cannot continue without success
		} else {
			LogToConsole(@"A copy of the theme being copied already exists at the destination path. This copy has been moved to the trash.");
		}
	}
	
	/* It is important to resume the metadata updates before performin the
	 copying or the theme will never get copied to the cache and update. */
#if TEXTUAL_BUILT_WITH_ICLOUD_SUPPORT == 1
	if (isCloudCopy) {
		[sharedCloudManager() resumeCloudContainerMetadataUpdates];
	}
#endif

	/* Perform copy operation. */
	NSError *copyError = nil;
	
#if TEXTUAL_BUILT_WITH_ICLOUD_SUPPORT == 1
	if (isCloudCopy) {
		/* When copying to iCloud, we copy the style to a temporary folder then have OS X 
		 handle the transfer of said folder to iCloud on our behalf. */
		NSString *fakeDestinationPath = [[TPCPathInfo applicationTemporaryFolderPath] stringByAppendingPathComponent:[NSString stringWithUUID]];
		
		NSURL *fakeDestinationPathURL = [NSURL fileURLWithPath:fakeDestinationPath];
		
		if ([RZFileManager() copyItemAtPath:[self pathBeingCopiedFrom] toPath:fakeDestinationPath error:&copyError] == NO) {
			[self cancelOperationAndReportError:copyError];
		} else {
			if ([RZFileManager() setUbiquitous:YES itemAtURL:fakeDestinationPathURL destinationURL:destinationURL error:&copyError] == NO) {
				[self cancelOperationAndReportError:copyError];
			}
		}
		
		/* Once the operation is completed, we can try to delete the temporary folder. */
		/* As the folder is only a temporary one, we don't care if this process errors out. */
		[RZFileManager() removeItemAtURL:fakeDestinationPathURL error:NULL];
	} else {
#endif
		
		if ([RZFileManager() copyItemAtPath:[self pathBeingCopiedFrom] toPath:destinationPath error:&copyError] == NO) {
			[self cancelOperationAndReportError:copyError];
		}
		
#if TEXTUAL_BUILT_WITH_ICLOUD_SUPPORT == 1
	}
#endif
	
}

- (void)maybeFinishWithFolderPath:(NSString *)path
{
	/* Gather some context information about the path. */
	NSString *pathWithoutName = [path stringByDeletingLastPathComponent];

	NSString *comparisonPath = nil;
	
#if TEXTUAL_BUILT_WITH_ICLOUD_SUPPORT == 1
	if ([self destinationLocation] == TPCThemeControllerStorageCloudLocation) {
		comparisonPath = [TPCPathInfo cloudCustomThemeCachedFolderPath];
	} else {
#endif
		
		comparisonPath = [TPCPathInfo customThemeFolderPath];

#if TEXTUAL_BUILT_WITH_ICLOUD_SUPPORT == 1
	}
#endif
	
	if ([comparisonPath isEqual:pathWithoutName] == NO) {
		return; // Path has no relation to this copy operation
	}
	
	/* Compare folder names. */
	NSString *nameFromPath = [path lastPathComponent];
	
	if ([[self themeName] isEqual:nameFromPath] == NO) {
		return; // Path has no relation to this copy operation
	}
	
	/* Path is good and we can finish operation. */
	[self completeOperation];
}

- (void)cancelOperation
{
	/* -cancelOperation is called on the main queue in an async fashion so that
	 the reference to self (the copy operation) can be set to nil from within it. */
	XRPerformBlockAsynchronouslyOnMainQueue(^{
		[self invalidateOperation];
	});
}

- (void)cancelOperationAndReportError:(NSError *)error
{
	XRPerformBlockAsynchronouslyOnMainQueue(^{
		[self invalidateOperation];
		
		[NSApp presentError:error];
	});
}

- (void)completeOperation
{
	/* Maybe open new path of theme. */
	XRPerformBlockAsynchronouslyOnMainQueue(^{
		if ([self openPathToNewThemeWhenCopied]) {
			[RZWorkspace() openFile:[self pathBeingCopiedTo]];
		}
		
		/* Maybe reload new theme. */
		if ([self reloadThemeWhenCopied]) {
			/* Set new theme name. */
			NSString *newThemeName = [TPCThemeController buildFilename:[self themeName] forStorageLocation:[self destinationLocation]];
			
			[TPCPreferences setThemeName:newThemeName];
			
			/* Perform reload operation. */
			[TPCPreferences performReloadActionForActionType:TPCPreferencesKeyReloadStyleWithTableViewsAction];
		}
		
		/* Close progress indicator. */
		[self invalidateOperation];
	});
}

- (void)invalidateOperation
{
	[[self progressIndicator] stop];
	
	[themeController() setCurrentCopyOperation:nil];
}

@end
