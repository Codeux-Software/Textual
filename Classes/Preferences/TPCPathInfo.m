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

#if TEXTUAL_BUILT_INSIDE_SANDBOX == 1
#include <pwd.h>            // -------
#include <sys/types.h>      // --- | For +userHomeDirectoryPathOutsideSandbox
#include <unistd.h>         // -------
#endif

NS_ASSUME_NONNULL_BEGIN

@implementation TPCPathInfo

+ (void)_createDirectoryOrOutputError:(NSString *)path
{
	NSParameterAssert(path != nil);

	if ([RZFileManager() fileExistsAtPath:path]) {
		return;
	}

	NSError *createDirectoryError = nil;

	if ([RZFileManager() createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:&createDirectoryError] == NO) {
		LogToConsole(@"Failed to create directory at path: '%@' - %@",
			path, [createDirectoryError localizedDescription])
	}
}

+ (NSString *)applicationBundlePath
{
	return RZMainBundle().bundlePath;
}

+ (nullable NSString *)applicationCachesFolderPath
{
	NSArray *pathArray = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
	
	if (pathArray.count == 0) {
		return nil;
	}

	NSString *endPath = [NSString stringWithFormat:@"/%@/", TXBundleBuildProductIdentifier];
	
	NSString *basePath = [pathArray.firstObject stringByAppendingPathComponent:endPath];

	[TPCPathInfo _createDirectoryOrOutputError:basePath];
	
	return basePath;
}

+ (nullable NSString *)applicationGroupContainerPath
{
#if TEXTUAL_BUILT_INSIDE_SANDBOX == 1

	NSURL *basePath = [RZFileManager() containerURLForSecurityApplicationGroupIdentifier:TXBundleBuildGroupContainerIdentifier];

	if (basePath == nil) {
		return nil;
	}

	return [basePath relativePath];

#else

	NSArray *pathArray = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES);

	if (pathArray.count == 0) {
		return nil;
	}

	NSString *endPath = [NSString stringWithFormat:@"/Group Containers/%@/", TXBundleBuildGroupContainerIdentifier];

	NSString *basePath = [pathArray.firstObject stringByAppendingPathComponent:endPath];

	[TPCPathInfo _createDirectoryOrOutputError:basePath];

	return basePath;

#endif
}

+ (nullable NSString *)applicationLogsFolderPath
{
	NSArray *pathArray = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES);

	if (pathArray.count == 0) {
		return nil;
	}

	NSString *endPath = [NSString stringWithFormat:@"/Logs/%@/", TXBundleBuildProductIdentifier];

	NSString *basePath = [pathArray.firstObject stringByAppendingPathComponent:endPath];

	[TPCPathInfo _createDirectoryOrOutputError:basePath];

	return basePath;
}

+ (NSString *)applicationResourcesFolderPath
{
	return RZMainBundle().resourcePath;
}

+ (NSString *)applicationTemporaryFolderPath
{
	return NSTemporaryDirectory();
}

+ (nullable NSString *)applicationSupportFolderPathInGroupContainer
{
	NSString *sourcePath = [TPCPathInfo applicationGroupContainerPath];

	if (sourcePath == nil) {
		return nil;
	}

	NSString *basePath = [sourcePath stringByAppendingPathComponent:@"/Library/Application Support/Textual/"];
		
	[TPCPathInfo _createDirectoryOrOutputError:basePath];
		
	return basePath;
}

+ (nullable NSString *)applicationSupportFolderPathInLocalContainer
{
	NSArray *pathArray = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES);

	if (pathArray.count == 0) {
		return nil;
	}

	NSString *basePath = [pathArray.firstObject stringByAppendingPathComponent:@"/Textual/"];

	[TPCPathInfo _createDirectoryOrOutputError:basePath];

	return basePath;
}

+ (NSString *)systemDiagnosticReportsFolderPath
{
	return @"/Library/Logs/DiagnosticReports";
}

+ (NSString *)userDiagnosticReportsFolderPath
{
	NSString *sourcePath = [TPCPathInfo userHomeFolderPath];

	return [sourcePath stringByAppendingPathComponent:@"/Library/Logs/DiagnosticReports"];
}

+ (nullable NSString *)customExtensionFolderPath
{
	NSString *sourcePath = [TPCPathInfo applicationSupportFolderPathInGroupContainer];

	if (sourcePath == nil) {
		return nil;
	}

	NSString *basePath = [sourcePath stringByAppendingPathComponent:@"/Extensions/"];

	[TPCPathInfo _createDirectoryOrOutputError:basePath];

	return basePath;
}

+ (nullable NSString *)customThemeFolderPath
{
	NSString *sourcePath = [TPCPathInfo applicationSupportFolderPathInGroupContainer];

	if (sourcePath == nil) {
		return nil;
	}

	NSString *basePath = [sourcePath stringByAppendingPathComponent:@"/Styles/"];

	[TPCPathInfo _createDirectoryOrOutputError:basePath];

	return basePath;
}

+ (nullable NSString *)customScriptsFolderPath
{
	NSArray *pathArray = NSSearchPathForDirectoriesInDomains(NSApplicationScriptsDirectory, NSUserDomainMask, YES);

	if (pathArray.count == 0) {
		return nil;
	}

	NSString *basePath = pathArray.firstObject;

#if TEXTUAL_BUILT_INSIDE_SANDBOX == 0
	[TPCPathInfo _createDirectoryOrOutputError:basePath];
#endif
	
	return basePath;
}

+ (nullable NSString *)customScriptsFolderPathLeading
{
	NSString *sourcePath = [TPCPathInfo customScriptsFolderPath];

	if (sourcePath == nil) {
		return nil;
	}

	return sourcePath.stringByDeletingLastPathComponent;
}

+ (NSString *)bundledExtensionFolderPath
{
	NSString *sourcePath = [TPCPathInfo applicationResourcesFolderPath];

	return [sourcePath stringByAppendingPathComponent:@"/Extensions/"];
}

+ (NSString *)bundledScriptFolderPath
{
	NSString *sourcePath = [TPCPathInfo applicationResourcesFolderPath];

	return [sourcePath stringByAppendingPathComponent:@"/Scripts/"];
}

+ (NSString *)bundledThemeFolderPath
{
	NSString *sourcePath = [TPCPathInfo applicationResourcesFolderPath];

	return [sourcePath stringByAppendingPathComponent:@"/Styles/"];
}

+ (nullable NSString *)userDownloadsFolderPath
{
	NSArray *searchArray = NSSearchPathForDirectoriesInDomains(NSDownloadsDirectory, NSUserDomainMask, YES);
	
	if (searchArray.count == 0) {
		return nil;
	}

	return searchArray.firstObject;
}

+ (nullable NSString *)userPreferencesFolderPath
{
	NSArray *searchArray = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES);

	if (searchArray.count == 0) {
		return nil;
	}

	return [searchArray.firstObject stringByAppendingPathComponent:@"/Preferences/"];
}

+ (NSString *)userHomeFolderPath
{
#if TEXTUAL_BUILT_INSIDE_SANDBOX == 1
	uid_t userId = getuid();

	struct passwd *pw = getpwuid(userId);
	
	return @(pw->pw_dir);
#else
	return NSHomeDirectory();
#endif
}

@end

#pragma mark -

#if TEXTUAL_BUILT_WITH_ICLOUD_SUPPORT == 1
@implementation TPCPathInfo (TPCPathInfoCloudExtension)

+ (nullable NSString *)applicationUbiquitousContainerPath
{
	return [sharedCloudManager() ubiquitousContainerPath];
}

+ (nullable NSString *)cloudCustomThemeFolderPath
{
	NSString *sourcePath = [TPCPathInfo applicationUbiquitousContainerPath];

	if (sourcePath == nil) {
		return nil;
	}

	NSString *basePath = [sourcePath stringByAppendingPathComponent:@"/Documents/Styles/"];

	[TPCPathInfo _createDirectoryOrOutputError:basePath];

	return basePath;
}

+ (void)_openCloudPathOrErrorIfUnavailable:(NSString *)path
{
	NSParameterAssert(path != nil);

	if ([sharedCloudManager() ubiquitousContainerIsAvailable] == NO) {
		[TLOPopupPrompts sheetWindowWithWindow:[NSApp keyWindow]
										  body:TXTLS(@"Prompts[1105][2]")
										 title:TXTLS(@"Prompts[1105][1]")
								 defaultButton:TXTLS(@"Prompts[1040]")
							   alternateButton:nil
								   otherButton:nil];

		return;
	}

	(void)[RZWorkspace() openFile:path];
}

+ (void)openApplicationUbiquitousContainerPath
{
	NSString *sourcePath = [TPCPathInfo applicationUbiquitousContainerPath];

	[TPCPathInfo _openCloudPathOrErrorIfUnavailable:sourcePath];
}

+ (void)openCloudCustomThemeFolderPath
{
	NSString *sourcePath = [TPCPathInfo cloudCustomThemeFolderPath];

	[TPCPathInfo _openCloudPathOrErrorIfUnavailable:sourcePath];
}

@end
#endif

#pragma mark -

@implementation TPCPathInfo (TPCPathInfoTranscriptFolderExtension)

static NSURL *_transcriptFolderURL = nil;

+ (nullable NSURL *)transcriptFolderURL
{
	return _transcriptFolderURL;
}

+ (void)setTranscriptFolderURL:(nullable NSData *)transcriptFolderURL
{
	if ( _transcriptFolderURL) {
		[_transcriptFolderURL stopAccessingSecurityScopedResource];
		 _transcriptFolderURL = nil;
	}

	[RZUserDefaults() setObject:transcriptFolderURL forKey:@"LogTranscriptDestinationSecurityBookmark_5"];

	[TPCPathInfo startUsingTranscriptFolderURL];
}

+ (void)startUsingTranscriptFolderURL
{
	NSData *bookmark = [RZUserDefaults() dataForKey:@"LogTranscriptDestinationSecurityBookmark_5"];

	if (bookmark == nil) {
		return;
	}

	BOOL resolvedBookmarkIsStale = YES;
	
	NSError *resolvedBookmarkError = nil;
	
	NSURL *resolvedBookmark =
	[NSURL URLByResolvingBookmarkData:bookmark
							  options:NSURLBookmarkResolutionWithSecurityScope
						relativeToURL:nil
				  bookmarkDataIsStale:&resolvedBookmarkIsStale
								error:&resolvedBookmarkError];

	if (resolvedBookmarkIsStale) {
		(void)[TLOPopupPrompts dialogWindowWithMessage:TXTLS(@"Prompts[1134][2]")
												 title:TXTLS(@"Prompts[1134][1]")
										 defaultButton:TXTLS(@"Prompts[0005]")
									   alternateButton:nil];
	}

	if (resolvedBookmark == nil) {
		LogToConsole(@"Error creating bookmark for URL: %@",
			[resolvedBookmarkError localizedDescription])

		return;
	}

	_transcriptFolderURL = resolvedBookmark;
		
	if ([_transcriptFolderURL startAccessingSecurityScopedResource] == NO) {
		LogToConsole(@"Failed to access bookmark")
	}
}

@end

NS_ASSUME_NONNULL_END
