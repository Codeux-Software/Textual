/* ********************************************************************* 
       _____        _               _    ___ ____   ____
      |_   _|___  _| |_ _   _  __ _| |  |_ _|  _ \ / ___|
       | |/ _ \ \/ / __| | | |/ _` | |   | || |_) | |
       | |  __/>  <| |_| |_| | (_| | |   | ||  _ <| |___
       |_|\___/_/\_\\__|\__,_|\__,_|_|  |___|_| \_\\____|

 Copyright (c) 2008 - 2010 Satoshi Nakagawa <psychs AT limechat DOT net>
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

#pragma mark -
#pragma mark Theme Controller Private Headers

/* Copy operation class is responsible for copying the active theme to a different
 location when a user requests a local copy of the theme. */
@interface TPCThemeControllerCopyOperation : NSObject
@property (nonatomic, copy) NSString *themeName; // Name without source prefix
@property (nonatomic, copy) NSString *pathBeingCopiedTo; // Set by -beginOperation. Do not set this to pick destination
@property (nonatomic, copy) NSString *pathBeingCopiedFrom; // Must be set before -beginOperation is called
@property (nonatomic, assign) TPCThemeControllerStorageLocation destinationLocation;
@property (nonatomic, assign) BOOL reloadThemeWhenCopied; // If YES, setThemeName: is called when copy completes. Otherwise, files are copied and nothing happens.
@property (nonatomic, assign) BOOL openPathToNewThemeWhenCopied;
@property (nonatomic, strong) TDCProgressInformationSheet *progressIndicator;

- (void)beginOperation; // Is dependent on most of stuff above being defined
- (void)endOperation;
@end

/* Private header for theme controller that a plugin does not need access to. */
@interface TPCThemeController ()
@property (nonatomic, assign) FSEventStreamRef eventStreamRef;
@property (nonatomic, strong) TPCThemeControllerCopyOperation *currentCopyOperation;

- (void)copyOperationFailedWithAnError:(NSString *)copyError;
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

- (void)dealloc
{
	[self stopMonitoringActiveThemePath];
}

- (NSString *)path
{
	return [[self baseURL] path];
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

#ifdef TEXTUAL_BUILT_WITH_ICLOUD_SUPPORT
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
	
	/* Define a shared cache ID for files. */
	[self setSharedCacheID:[NSString stringWithInteger:TXRandomNumber(5000)]];
	
	/* Reload theme settings. */
	[[self customSettings] reloadWithPath:path];
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

- (BOOL)performValidationForCurrentTheme:(NSString **)suggestedThemeName suggestedFont:(NSString **)suggestedFontName
{
	return [self performValidationForTheme:[self associatedThemeName] suggestedTheme:suggestedThemeName suggestedFont:suggestedFontName];
}

- (BOOL)performValidationForTheme:(NSString *)validatedTheme suggestedTheme:(NSString **)suggestedThemeName suggestedFont:(NSString **)suggestedFontName
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
				*suggestedThemeName = [TXDefaultTextualChannelViewStyle copy];
				
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
						*suggestedThemeName = [TXDefaultTextualChannelViewStyle copy];
						
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
						*suggestedThemeName = [TXDefaultTextualChannelViewStyle copy];
						
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
			
			break;
		}
		case TPCThemeControllerStorageCustomLocation:
		{
			return [TPCThemeControllerCustomThemeNameCompletePrefix stringByAppendingString:name];
			
			break;
		}
		case TPCThemeControllerStorageCloudLocation:
		{
			return [TPCThemeControllerCloudThemeNameCompletePrefix stringByAppendingString:name];
			
			break;
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
		if (pathObj) {
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
							}  // that
						} // is
					} // a
				} // lot
			} // of
		} // if
	}; // statements
	
#ifdef TEXTUAL_BUILT_WITH_ICLOUD_SUPPORT
	checkPath([TPCPathInfo cloudCustomThemeCachedFolderPath], TPCThemeControllerCloudThemeNameCompletePrefix);
#endif
	
	checkPath([TPCPathInfo customThemeFolderPath], TPCThemeControllerCustomThemeNameCompletePrefix);
	checkPath([TPCPathInfo bundledThemeFolderPath], TPCThemeControllerBundledThemeNameCompletePrefix);
	
	return [allThemes sortedDictionary];
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

		for (NSInteger i = 0; i < numEvents; i++) {
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
					_updateConditionForPath(@"design.css")
					_updateConditionForPath(@"scripts.js")
					_updateConditionForPath(@"Data/Settings/styleSettings.plist")
				}
				
				continue; // Only thing we care about here…
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
					
					if (copyOperation) {
						NSString *nameFromPath = [path lastPathComponent];

						if ([[copyOperation themeName] isEqual:nameFromPath]) {
							NSString *pathWithoutName = [path stringByDeletingLastPathComponent];
							
							if (
#ifdef TEXTUAL_BUILT_WITH_ICLOUD_SUPPORT
                                ([copyOperation destinationLocation] == TPCThemeControllerStorageCloudLocation && [pathWithoutName isEqual:[TPCPathInfo cloudCustomThemeCachedFolderPath]]) ||
#endif
								([copyOperation destinationLocation] == TPCThemeControllerStorageCustomLocation && [pathWithoutName isEqual:[TPCPathInfo customThemeFolderPath]]))
							{
								[copyOperation endOperation];
								
								[themeController() setCurrentCopyOperation:nil];
							}
						}
					}
				}
				
				postDidChangeNotification = YES;
			}
		}
	
		if (activeThemeContentsWereDeleted) {
			LogToConsole(@"The contents of the configured theme was deleted. Validation and reload will now occur.");

			(void)[themeController() validateThemeAndRelaodIfNecessary];
		} else if (activeThemeContentsWereModified) {
			
#if TPCThemeControllerReloadsStyleOnContentsDidChange == 1
			[TPCPreferences performReloadActionForActionType:TPCPreferencesKeyReloadStyleWithTableViewsAction];
#endif
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
#ifdef TEXTUAL_BUILT_WITH_ICLOUD_SUPPORT
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
	} else {
		if ([self storageLocation] == destinationLocation) {
			LogToConsole(@"Tried to copy active theme to same storage location that it already exists within");
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
}

- (void)copyOperationFailedWithAnError:(NSString *)copyError
{
	[self setCurrentCopyOperation:nil];
	
	LogToConsole(@"%@", copyError);
}

@end

#pragma mark -
#pragma mark Theme Controller Copy Operation

@implementation TPCThemeControllerCopyOperation

- (void)endOperation
{
	/* Maybe open new path of theme. */
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
	[[self progressIndicator] stop];
	
	[self setProgressIndicator:nil];
}

- (void)beginOperation
{
	/* Setup progress indicator. */
	TDCProgressInformationSheet *ps = [TDCProgressInformationSheet new];
	
	[ps startWithWindow:[NSApp keyWindow]];
	
	[self setProgressIndicator:ps];
	
	/* Define which path we are copying to. */
	NSString *newpath = nil;
	
	if ([self destinationLocation] == TPCThemeControllerStorageCustomLocation) {
		newpath = [[TPCPathInfo customThemeFolderPath] stringByAppendingPathComponent:[self themeName]];
		
#ifdef TEXTUAL_BUILT_WITH_ICLOUD_SUPPORT
	} else if ([self destinationLocation] == TPCThemeControllerStorageCloudLocation) {
		if ([sharedCloudManager() ubiquitousContainerIsAvailable]) {
			newpath = [[TPCPathInfo cloudCustomThemeFolderPath] stringByAppendingPathComponent:[self themeName]];
		} else {
			newpath = [[TPCPathInfo customThemeFolderPath] stringByAppendingPathComponent:[self themeName]];
			
			[self setDestinationLocation:TPCThemeControllerStorageCustomLocation];
		}
#endif
		
	}

	[self setPathBeingCopiedTo:newpath];
	
	/* Perform copy operation. */
	NSURL *source = [NSURL fileURLWithPath:[self pathBeingCopiedFrom]];
	NSURL *destination = [NSURL fileURLWithPath:[self pathBeingCopiedTo]];

	NSError *copyError;
	
	[RZFileManager() copyItemAtURL:source toURL:destination error:&copyError];
	
	if (copyError) {
		/* We queue inside the main queue so that setting currentCopyOperation
		 to nil when called from within the operation we are setting to nil. */

		TXPerformBlockAsynchronouslyOnMainQueue(^{
			[ps stop];
			
			[NSApp presentError:copyError];
			
			[themeController() copyOperationFailedWithAnError:[copyError localizedDescription]];
		});
	}
}

@end
