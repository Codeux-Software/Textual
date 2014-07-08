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

@implementation TPCThemeController

- (id)init
{
	if ((self = [super init])) {
		self.customSettings = [TPCThemeSettings new];
	}
	
	return self;
}

- (NSString *)path
{
	return [self.baseURL path];
}

- (NSString *)actualPath
{
	return [TPCThemeController pathOfThemeWithName:self.associatedThemeName skipCloudCache:YES];
}

- (NSString *)name
{
	return [TPCThemeController extractThemeName:self.associatedThemeName];
}

- (BOOL)actualPathForCurrentThemeIsEqualToCachedPath
{
	NSString *updatedPath = [TPCThemeController pathOfThemeWithName:self.associatedThemeName];

	NSString *otherPath = [self path];

	if (NSObjectIsEmpty(updatedPath) && NSObjectIsNotEmpty(otherPath)) {
		return NO;
	}
	
	return ([updatedPath isEqualToString:otherPath]);
}

+ (BOOL)themeExists:(NSString *)themeName
{
	TPCThemeControllerStorageLocation location = [TPCThemeController storageLocationOfThemeWithName:themeName];
	
	return NSDissimilarObjects(location, TPCThemeControllerStorageUnknownLocation);
}

+ (NSString *)pathOfThemeWithName:(NSString *)themeName
{
	return [self pathOfThemeWithName:themeName skipCloudCache:NO];
}

+ (NSString *)pathOfThemeWithName:(NSString *)themeName skipCloudCache:(BOOL)ignoreCloudCache
{
	NSString *filekind = [TPCThemeController extractThemeSource:themeName];
	NSString *filename = [TPCThemeController extractThemeName:themeName];
	
	NSObjectIsEmptyAssertReturn(filekind, nil);
	NSObjectIsEmptyAssertReturn(filename, nil);
	
	NSString *path = nil;
	
	if ([filekind isEqualToString:TPCThemeControllerCustomStyleNameBasicPrefix]) {
		/* Does the theme exist in the cloud? */

#ifdef TEXTUAL_BUILT_WITH_ICLOUD_SUPPORT
		if (ignoreCloudCache) {
			path = [[TPCPathInfo cloudCustomThemeFolderPath] stringByAppendingPathComponent:filename];
		} else {
			path = [[TPCPathInfo cloudCustomThemeCachedFolderPath] stringByAppendingPathComponent:filename];
		}
		
		if ([RZFileManager() fileExistsAtPath:path]) {
			NSString *cssFile = [path stringByAppendingPathComponent:@"design.css"];
			
			if ([RZFileManager() fileExistsAtPath:cssFile]) {
				return path;
			}
		}
#endif
		
		/* Does it exist locally? */
		path = [[TPCPathInfo customThemeFolderPath] stringByAppendingPathComponent:filename];
		
		if ([RZFileManager() fileExistsAtPath:path]) {
			NSString *cssFile = [path stringByAppendingPathComponent:@"design.css"];
			
			if ([RZFileManager() fileExistsAtPath:cssFile]) {
				return path;
			}
		}
	} else {
		/* Does the theme exist in app? */
		path = [[TPCPathInfo bundledThemeFolderPath] stringByAppendingPathComponent:filename];
		
		if ([RZFileManager() fileExistsAtPath:path]) {
			NSString *cssFile = [path stringByAppendingPathComponent:@"design.css"];
			
			if ([RZFileManager() fileExistsAtPath:cssFile]) {
				return path;
			}
		}
	}
	
	return nil;
}

- (void)validateFilePathExistanceAndReload
{
	/* Try to find a theme by the stored name. */
	self.associatedThemeName = [TPCPreferences themeName];
	
	NSString *path = [TPCThemeController pathOfThemeWithName:self.associatedThemeName];
	
	if (NSObjectIsEmpty(path)) {
		NSAssert(NO, @"Missing style resource files.");
	}

	/* We have a path. */
	self.baseURL = [NSURL fileURLWithPath:path];

	/* Define a shared cache ID for files. */
	self.sharedCacheID = [NSString stringWithInteger:TXRandomNumber(5000)];

	/* Reload theme settings. */
	[self.customSettings reloadWithPath:path];
}

- (void)load
{
	[self validateFilePathExistanceAndReload];
}

- (BOOL)isBundledTheme
{
	return ([self storageLocation] == TPCThemeControllerStorageBundleLocation);
}

- (TPCThemeControllerStorageLocation)storageLocation
{
	return [TPCThemeController storageLocationOfThemeAtPath:[self path]];
}

+ (NSString *)buildResourceFilename:(NSString *)name
{
	return [TPCThemeControllerBundledStyleNameCompletePrefix stringByAppendingString:name];
}

+ (NSString *)buildUserFilename:(NSString *)name
{
	return [TPCThemeControllerCustomStyleNameCompletePrefix stringByAppendingString:name];
}

+ (TPCThemeControllerStorageLocation)storageLocationOfThemeWithName:(NSString *)themeName
{
	NSString *path = [TPCThemeController pathOfThemeWithName:themeName];
	
	return [TPCThemeController storageLocationOfThemeAtPath:path];
}

+ (TPCThemeControllerStorageLocation)storageLocationOfThemeAtPath:(NSString *)path
{
	if ([path hasPrefix:[TPCPathInfo bundledThemeFolderPath]]) {
		return TPCThemeControllerStorageBundleLocation;
	}
	
	if ([path hasPrefix:[TPCPathInfo customThemeFolderPath]]) {
		return TPCThemeControllerStorageCustomLocation;
	}
	
#ifdef TEXTUAL_BUILT_WITH_ICLOUD_SUPPORT
	if ([path hasPrefix:[TPCPathInfo cloudCustomThemeCachedFolderPath]]) {
		return TPCThemeControllerStorageCloudLocation;
	}
#endif
	
	return TPCThemeControllerStorageUnknownLocation;
}

+ (NSString *)extractThemeSource:(NSString *)source
{
	if ([source hasPrefix:TPCThemeControllerCustomStyleNameCompletePrefix] == NO &&
		[source hasPrefix:TPCThemeControllerBundledStyleNameCompletePrefix] == NO)
	{
		return nil;
    }

	return [source substringToIndex:[source stringPosition:@":"]];
}

+ (NSString *)extractThemeName:(NSString *)source
{
	if ([source hasPrefix:TPCThemeControllerCustomStyleNameCompletePrefix] == NO &&
		[source hasPrefix:TPCThemeControllerBundledStyleNameCompletePrefix] == NO)
	{
		return nil;
    }
	
	return [source substringAfterIndex:[source stringPosition:@":"]];	
}

@end
