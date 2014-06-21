/* ********************************************************************* 
       _____        _               _    ___ ____   ____
      |_   _|___  _| |_ _   _  __ _| |  |_ _|  _ \ / ___|
       | |/ _ \ \/ / __| | | |/ _` | |   | || |_) | |
       | |  __/>  <| |_| |_| | (_| | |   | ||  _ <| |___
       |_|\___/_/\_\\__|\__,_|\__,_|_|  |___|_| \_\\____|

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

#include <unistd.h>         // -------
#include <sys/types.h>      // --- | For +userHomeDirectoryPathOutsideSandbox
#include <pwd.h>            // -------

@implementation TPCPathInfo

#pragma mark -
#pragma mark Misc. Paths

+ (NSString *)applicationTemporaryFolderPath
{
	return NSTemporaryDirectory();
}

+ (NSString *)applicationCachesFolderPath
{
	NSArray *searchArray = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
	
	if ([searchArray count]) {
		NSString *endPath = [NSString stringWithFormat:@"/%@/", [TPCApplicationInfo applicationBundleIdentifier]];
		
		NSString *basePath = [searchArray[0] stringByAppendingString:endPath];
		
		if ([RZFileManager() fileExistsAtPath:basePath] == NO) {
			[RZFileManager() createDirectoryAtPath:basePath withIntermediateDirectories:YES attributes:nil error:NULL];
		}
		
		return basePath;
	}
	
	return nil;
}

+ (NSString *)applicationSupportFolderPath
{
	NSArray *searchArray = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES);
	
	if ([searchArray count]) {
		NSString *dest = [searchArray[0] stringByAppendingPathComponent:@"/Textual IRC/"];
		
		if ([RZFileManager() fileExistsAtPath:dest] == NO) {
			[RZFileManager() createDirectoryAtPath:dest withIntermediateDirectories:YES attributes:nil error:NULL];
		}
		
		return dest;
	}
	
	return nil;
}

+ (NSString *)customThemeFolderPath
{
	NSString *dest = [[TPCPathInfo applicationSupportFolderPath] stringByAppendingPathComponent:@"/Styles/"];
	
	if ([RZFileManager() fileExistsAtPath:dest] == NO) {
		[RZFileManager() createDirectoryAtPath:dest withIntermediateDirectories:YES attributes:nil error:NULL];
	}
	
	return dest;
}

+ (NSString *)customExtensionFolderPath
{
	NSString *dest = [[TPCPathInfo applicationSupportFolderPath] stringByAppendingPathComponent:@"/Extensions/"];
	
	if ([RZFileManager() fileExistsAtPath:dest] == NO) {
		[RZFileManager() createDirectoryAtPath:dest withIntermediateDirectories:YES attributes:nil error:NULL];
	}
	
	return dest;
}

#ifdef TEXTUAL_BUILT_WITH_ICLOUD_SUPPORT
+ (NSString *)applicationUbiquitousContainerPath
{
	return [sharedCloudManager() ubiquitousContainerURLPath];
}

+ (NSString *)cloudCustomThemeFolderPath
{
	NSString *source = [TPCPathInfo applicationUbiquitousContainerPath];
	
	NSObjectIsEmptyAssertReturn(source, nil); // We need a source folder first…
	
	NSString *dest = [source stringByAppendingPathComponent:@"/Styles/"];
	
	if ([RZFileManager() fileExistsAtPath:dest] == NO) {
		[RZFileManager() createDirectoryAtPath:dest withIntermediateDirectories:YES attributes:nil error:NULL];
	}
	
	return dest;
}

+ (NSString *)cloudCustomThemeCachedFolderPath
{
	NSString *dest = [[TPCPathInfo applicationCachesFolderPath] stringByAppendingPathComponent:@"/iCloud Caches/Styles/"];
	
	if ([RZFileManager() fileExistsAtPath:dest] == NO) {
		[RZFileManager() createDirectoryAtPath:dest withIntermediateDirectories:YES attributes:nil error:NULL];
	}
	
	return dest;
}
#endif

+ (NSString *)bundledScriptFolderPath
{
	return [[TPCPathInfo applicationResourcesFolderPath] stringByAppendingPathComponent:@"/Scripts/"];
}

+ (NSString *)bundledThemeFolderPath
{
	return [[TPCPathInfo applicationResourcesFolderPath] stringByAppendingPathComponent:@"/Styles/"];
}

+ (NSString *)bundledExtensionFolderPath
{
	return [[TPCPathInfo applicationResourcesFolderPath] stringByAppendingPathComponent:@"/Extensions/"];
}

+ (NSString *)applicationResourcesFolderPath
{
	return [RZMainBundle() resourcePath];
}

+ (NSString *)applicationBundlePath
{
	return [RZMainBundle() bundlePath];
}

+ (NSString *)systemUnsupervisedScriptFolderRootPath
{
	if ([CSFWSystemInformation featureAvailableToOSXMountainLion]) {
		NSString *oldpath = [TPCPathInfo systemUnsupervisedScriptFolderPath]; // Returns our path.
		
		return [oldpath stringByDeletingLastPathComponent]; // Remove bundle ID from path.
	}
	
	return nil;
}

+ (NSString *)systemUnsupervisedScriptFolderPath
{
	if ([CSFWSystemInformation featureAvailableToOSXMountainLion]) {
		NSArray *searchArray = NSSearchPathForDirectoriesInDomains(NSApplicationScriptsDirectory, NSUserDomainMask, YES);
		
		if ([searchArray count]) {
			return searchArray[0];
		}
	}
	
	return nil;
}

+ (NSString *)userDownloadFolderPath
{
	NSArray *searchArray = NSSearchPathForDirectoriesInDomains(NSDownloadsDirectory, NSUserDomainMask, YES);
	
	if ([searchArray count]) {
		return searchArray[0];
	}
	
	return nil;
}

+ (NSString *)userHomeDirectoryPathOutsideSandbox
{
	struct passwd *pw = getpwuid(getuid());
	
	return [NSString stringWithUTF8String:pw->pw_dir];
}


#pragma mark -
#pragma mark Factory

+ (NSArray *)buildPathArray:(NSString *)path, ...
{
	NSMutableArray *pathData = [NSMutableArray array];
	
	/* What considers are path valid? */
	void (^checkPath)(NSString *) = ^(NSString *pathObj) {
		if (pathObj) {
			if ([pathObj length] > 0) {
				BOOL pathExists = [RZFileManager() fileExistsAtPath:pathObj];
				
				if (pathExists) {
					[pathData addObject:pathObj];
				}
			}
		}
	};
	
	/* Add first path in arguments. */
	checkPath(path);

	/* Add any paths that follow. */
	NSString *pathObj;
	
	va_list args;
	va_start(args, path);
	
	while ((pathObj = va_arg(args, NSString *))) {
		checkPath(pathObj);
	}
	
	va_end(args);
	
	/* Return results. */
	return [pathData copy];
}

#pragma mark -
#pragma mark Logging

static NSURL *logToDiskLocationResolvedBookmark;

+ (void)startUsingLogLocationSecurityScopedBookmark
{
	// URLByResolvingBookmarkData throws some weird shit during shutdown.
	// We're just going to loose whatever long we were wanting to save.
	// Probably the disconnect message. Oh well.
	if ([masterController() applicationIsTerminating]) {
		return;
	}
	
	NSData *bookmark = [RZUserDefaults() dataForKey:@"LogTranscriptDestinationSecurityBookmark"];
	
	NSObjectIsEmptyAssert(bookmark);
	
	NSError *resolveError;
	
	BOOL isStale = YES;
	
	NSURL *resolvedBookmark = [NSURL URLByResolvingBookmarkData:bookmark
														options:NSURLBookmarkResolutionWithSecurityScope
												  relativeToURL:nil
											bookmarkDataIsStale:&isStale
														  error:&resolveError];
	
	if (resolveError) {
		DebugLogToConsole(@"Error creating bookmark for URL: %@", [resolveError localizedDescription]);
	} else {
			 logToDiskLocationResolvedBookmark = resolvedBookmark;
		
		if ([logToDiskLocationResolvedBookmark startAccessingSecurityScopedResource] == NO) {
			DebugLogToConsole(@"Failed to access bookmark.");
		}
	}
}

+ (NSURL *)logFileFolderLocation
{
	return logToDiskLocationResolvedBookmark;
}

+ (void)setLogFileFolderLocation:(id)value
{
	/* Destroy old pointer if needed. */
	if ( logToDiskLocationResolvedBookmark) {
		[logToDiskLocationResolvedBookmark stopAccessingSecurityScopedResource];
		 logToDiskLocationResolvedBookmark = nil;
	}
	
	/* Set new location. */
	[RZUserDefaults() setObject:value forKey:@"LogTranscriptDestinationSecurityBookmark"];
	
	/* Reset our folder. */
	[TPCPathInfo startUsingLogLocationSecurityScopedBookmark];
}

@end
