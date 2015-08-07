/* ********************************************************************* 
                  _____         _               _
                 |_   _|____  _| |_ _   _  __ _| |
                   | |/ _ \ \/ / __| | | |/ _` | |
                   | |  __/>  <| |_| |_| | (_| | |
                   |_|\___/_/\_\\__|\__,_|\__,_|_|

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

#import "BuildConfig.h"

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
		
		NSString *basePath = [searchArray[0] stringByAppendingPathComponent:endPath];
		
		if ([RZFileManager() fileExistsAtPath:basePath] == NO) {
			[RZFileManager() createDirectoryAtPath:basePath withIntermediateDirectories:YES attributes:nil error:NULL];
		}
		
		return basePath;
	}
	
	return nil;
}

+ (NSString *)applicationGroupContainerPath
{
#if TEXTUAL_BUILT_INSIDE_SANDBOX == 1
	NSURL *url = [RZFileManager() containerURLForSecurityApplicationGroupIdentifier:TXBundleBuildGroupContainerIdentifier];

	return [url relativePath];
#else
	NSArray *searchArray = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES);

	if ([searchArray count]) {
		NSString *endPath = [NSString stringWithFormat:@"/Group Containers/%@/", TXBundleBuildGroupContainerIdentifier];

		NSString *dest = [searchArray[0] stringByAppendingPathComponent:endPath];

		if (dest) {
			if ([RZFileManager() fileExistsAtPath:dest] == NO) {
				[RZFileManager() createDirectoryAtPath:dest withIntermediateDirectories:YES attributes:nil error:NULL];
			}

			return dest;
		}
	}

	return nil;
#endif
}

+ (NSString *)applicationLocalContainerApplicationSupportPath
{
	NSArray *searchArray = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES);

	if ([searchArray count]) {
		NSString *basePath = [searchArray[0] stringByAppendingPathComponent:@"/Textual/"];

		if ([RZFileManager() fileExistsAtPath:basePath] == NO) {
			[RZFileManager() createDirectoryAtPath:basePath withIntermediateDirectories:YES attributes:nil error:NULL];
		}

		return basePath;
	}

	return nil;
}

+ (NSString *)applicationSupportFolderPath
{
	return [TPCPathInfo applicationGroupContainerApplicationSupportPath];
}

+ (NSString *)applicationGroupContainerApplicationSupportPath
{
	NSString *dest = [TPCPathInfo applicationGroupContainerPath];
	
	if (dest) {
		dest = [dest stringByAppendingPathComponent:@"/Library/Application Support/Textual/"];
		
		if ([RZFileManager() fileExistsAtPath:dest] == NO) {
			[RZFileManager() createDirectoryAtPath:dest withIntermediateDirectories:YES attributes:nil error:NULL];
		}
		
		return dest;
	}
	
	return nil;
}

+ (NSString *)systemDiagnosticReportsFolderPath
{
	return @"/Library/Logs/DiagnosticReports";
}

+ (NSString *)localUserDiagnosticReportsFolderPath
{
	NSString *homefolder = [TPCPathInfo userHomeDirectoryPathOutsideSandbox];

	return [homefolder stringByAppendingPathComponent:@"/Library/Logs/DiagnosticReports"];
}

+ (NSString *)customThemeFolderPath
{
	NSString *dest = [[TPCPathInfo applicationGroupContainerApplicationSupportPath] stringByAppendingPathComponent:@"/Styles/"];
	
	if ([RZFileManager() fileExistsAtPath:dest] == NO) {
		[RZFileManager() createDirectoryAtPath:dest withIntermediateDirectories:YES attributes:nil error:NULL];
	}
	
	return dest;
}

+ (NSString *)customExtensionFolderPath
{
	NSString *dest = [[TPCPathInfo applicationGroupContainerApplicationSupportPath] stringByAppendingPathComponent:@"/Extensions/"];
	
	if ([RZFileManager() fileExistsAtPath:dest] == NO) {
		[RZFileManager() createDirectoryAtPath:dest withIntermediateDirectories:YES attributes:nil error:NULL];
	}
	
	return dest;
}

#if TEXTUAL_BUILT_WITH_ICLOUD_SUPPORT == 1
+ (NSString *)applicationUbiquitousContainerPath
{
	return [sharedCloudManager() ubiquitousContainerURLPath];
}

+ (NSString *)cloudCustomThemeFolderPath
{
	NSString *source = [TPCPathInfo applicationUbiquitousContainerPath];
	
	NSObjectIsEmptyAssertReturn(source, nil); // We need a source folder first...
	
	NSString *dest = [source stringByAppendingPathComponent:@"/Documents/Styles/"];
	
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

+ (void)openCloudPathOrErrorIfUnavailable:(NSString *)path
{
	if ([sharedCloudManager() ubiquitousContainerIsAvailable] == NO) {
		[TLOPopupPrompts sheetWindowWithWindow:[NSApp keyWindow]
										  body:TXTLS(@"BasicLanguage[1102][2]")
										 title:TXTLS(@"BasicLanguage[1102][1]")
								 defaultButton:BLS(1186)
							   alternateButton:nil
								   otherButton:nil
								suppressionKey:nil
							   suppressionText:nil
							   completionBlock:nil];
	} else {
		[RZWorkspace() openFile:path];
	}
}

+ (void)openApplicationUbiquitousContainer
{
	[TPCPathInfo openCloudPathOrErrorIfUnavailable:[TPCPathInfo applicationUbiquitousContainerPath]];
}

+ (void)openCloudCustomThemeFolder
{
	[TPCPathInfo openCloudPathOrErrorIfUnavailable:[TPCPathInfo cloudCustomThemeFolderPath]];
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
	NSString *oldpath = [TPCPathInfo systemUnsupervisedScriptFolderPath]; // Returns our path.
		
	return [oldpath stringByDeletingLastPathComponent]; // Remove bundle ID from path.
}

+ (NSString *)systemUnsupervisedScriptFolderPath
{
	NSArray *searchArray = NSSearchPathForDirectoriesInDomains(NSApplicationScriptsDirectory, NSUserDomainMask, YES);

	if ([searchArray count]) {

#if TEXTUAL_BUILT_INSIDE_SANDBOX == 1
		return searchArray[0];
#else
		NSString *basePath = searchArray[0];

		if ([RZFileManager() fileExistsAtPath:basePath] == NO) {
			[RZFileManager() createDirectoryAtPath:basePath withIntermediateDirectories:YES attributes:nil error:NULL];
		}

		return basePath;
#endif

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

+ (NSString *)userPreferencesFolderPath
{
	NSArray *searchArray = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES);

	if ([searchArray count]) {
		NSString *basePath = [searchArray[0] stringByAppendingPathComponent:@"/Preferences/"];

		return basePath;
	}

	return nil;
}

+ (NSString *)userHomeDirectoryPathOutsideSandbox
{
	struct passwd *pw = getpwuid(getuid());
	
	return @(pw->pw_dir);
}

#pragma mark -
#pragma mark Factory


+ (NSArray *)buildPathArrayWithPaths:(NSArray *)paths
{
	/* We now filter based on conditions. */
	NSMutableArray *pathData = [NSMutableArray array];

	/* What considers are path valid? */
	void (^checkPath)(NSString *) = ^(NSString *pathInfo) {
		if (pathInfo) {
			if ([pathInfo length] > 0) {
				BOOL isDirectory = NO;

				BOOL pathExists = [RZFileManager() fileExistsAtPath:pathInfo isDirectory:&isDirectory];

				if (pathExists) {
					if (isDirectory) {
						[pathData addObject:pathInfo];
					}
				}
			}
		}
	};

	/* Filter list. */
	for (NSString *pathObject in paths) {
		checkPath(pathObject);
	}

	/* Return results. */
	return [pathData copy];
}

+ (NSArray *)buildPathArray:(NSString *)path, ...
{
	NSMutableArray *pathObjects = [NSMutableArray array];

	if ( path) {
		[pathObjects addObject:path];
	}
	
	id pathObj;
	
	va_list args;
	va_start(args, path);
	
	while ((pathObj = va_arg(args, id))) {
		[pathObjects addObject:pathObj];
	}
	
	va_end(args);

	return [self buildPathArrayWithPaths:pathObjects];
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
	
	NSData *bookmark = [RZUserDefaults() dataForKey:@"LogTranscriptDestinationSecurityBookmark_5"];
	
	NSObjectIsEmptyAssert(bookmark);
	
	NSError *resolveError = nil;
	
	BOOL isStale = YES;
	
	NSURL *resolvedBookmark = [NSURL URLByResolvingBookmarkData:bookmark
														options:NSURLBookmarkResolutionWithSecurityScope
												  relativeToURL:nil
											bookmarkDataIsStale:&isStale
														  error:&resolveError];
	
	if (resolveError) {
		DebugLogToConsole(@"Error creating bookmark for URL: %@", [resolveError localizedDescription]);
	} else {
			 logToDiskLocationResolvedBookmark = [resolvedBookmark copy];
		
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
	[RZUserDefaults() setObject:value forKey:@"LogTranscriptDestinationSecurityBookmark_5"];
	
	/* Reset our folder. */
	[TPCPathInfo startUsingLogLocationSecurityScopedBookmark];
}

@end
