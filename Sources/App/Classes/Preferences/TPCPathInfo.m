/* *********************************************************************
 *                  _____         _               _
 *                 |_   _|____  _| |_ _   _  __ _| |
 *                   | |/ _ \ \/ / __| | | |/ _` | |
 *                   | |  __/>  <| |_| |_| | (_| | |
 *                   |_|\___/_/\_\\__|\__,_|\__,_|_|
 *
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

#import "BuildConfig.h"

#import "TDCAlert.h"
#import "TLOLanguagePreferences.h"
#import "TPCPreferencesLocal.h"
#import "TPCPreferencesCloudSyncPrivate.h"
#import "TPCPreferencesUserDefaults.h"
#import "TPCPathInfoPrivate.h"

#if TEXTUAL_BUILT_INSIDE_SANDBOX == 1
#include <pwd.h>            // -------
#include <sys/types.h>      // --- | For +userHomeDirectoryPathOutsideSandbox
#include <unistd.h>         // -------
#endif

NS_ASSUME_NONNULL_BEGIN

@implementation TPCPathInfo

#pragma mark -
#pragma mark Utilities

+ (void)_createDirectoryAtPath:(NSString *)directoryPath
{
	NSParameterAssert(directoryPath != nil);

	if ([RZFileManager() fileExistsAtPath:directoryPath]) {
		return;
	}

	NSError *createDirectoryError = nil;

	if ([RZFileManager() createDirectoryAtPath:directoryPath withIntermediateDirectories:YES attributes:nil error:&createDirectoryError] == NO) {
		LogToConsoleError("Failed to create directory at path: '%@' - %@",
			directoryPath.description, createDirectoryError.localizedDescription);
	}
}

+ (void)_createDirectoryAtURL:(NSURL *)directoryURL
{
	NSParameterAssert(directoryURL != nil);

	if ([RZFileManager() fileExistsAtURL:directoryURL]) {
		return;
	}

	NSError *createDirectoryError = nil;

	if ([RZFileManager() createDirectoryAtURL:directoryURL withIntermediateDirectories:YES attributes:nil error:&createDirectoryError] == NO) {
		LogToConsoleError("Failed to create directory at path: '%@' - %@",
			directoryURL.description, createDirectoryError.localizedDescription);
	}
}

#pragma mark -
#pragma mark Application Specific

+ (NSString *)applicationBundle
{
	return RZMainBundle().bundlePath;
}

+ (NSURL *)applicationBundleURL
{
	return RZMainBundle().bundleURL;
}

+ (NSString *)applicationResources
{
	return RZMainBundle().resourcePath;
}

+ (NSURL *)applicationResourcesURL
{
	return RZMainBundle().resourceURL;
}

+ (nullable NSString *)applicationCaches
{
	NSArray *pathArray = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);

	if (pathArray.count == 0) {
		return nil;
	}

	NSString *endPath = [NSString stringWithFormat:@"/%@/", TXBundleBuildProductIdentifier];

	NSString *basePath = [pathArray.firstObject stringByAppendingPathComponent:endPath];

	[self _createDirectoryAtPath:basePath];

	return basePath;
}

+ (nullable NSURL *)applicationCachesURL
{
	NSString *sourcePath = self.applicationCaches;

	if (sourcePath == nil) {
		return nil;
	}

	return [NSURL fileURLWithPath:sourcePath isDirectory:YES];
}

+ (nullable NSString *)groupContainer
{
	NSURL *sourceURL = self.groupContainerURL;

	if (sourceURL == nil) {
		return nil;
	}

	return sourceURL.path;
}

+ (nullable NSURL *)groupContainerURL
{
	NSURL *baseURL = [RZFileManager() containerURLForSecurityApplicationGroupIdentifier:TXBundleBuildGroupContainerIdentifier];

	if (baseURL == nil) {
		return nil;
	}

#if TEXTUAL_BUILT_INSIDE_SANDBOX == 0
	[self _createDirectoryAtURL:baseURL];
#endif

	return baseURL;
}

+ (nullable NSString *)groupContainerApplicationCaches
{
	NSURL *sourceURL = self.groupContainerApplicationCachesURL;

	if (sourceURL == nil) {
		return nil;
	}

	return sourceURL.path;
}

+ (nullable NSURL *)groupContainerApplicationCachesURL
{
	NSURL *sourceURL = self.groupContainerURL;

	if (sourceURL == nil) {
		return nil;
	}

	NSURL *baseURL = [sourceURL URLByAppendingPathComponent:@"/Library/Caches/"];

	[self _createDirectoryAtURL:baseURL];

	return baseURL;
}

+ (nullable NSString *)applicationSupport
{
	NSArray *pathArray = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES);

	if (pathArray.count == 0) {
		return nil;
	}

	NSString *basePath = [pathArray.firstObject stringByAppendingPathComponent:@"/Textual/"];

	[self _createDirectoryAtPath:basePath];

	return basePath;
}

+ (nullable NSURL *)applicationSupportURL
{
	NSString *sourcePath = self.applicationSupport;

	if (sourcePath == nil) {
		return nil;
	}

	return [NSURL fileURLWithPath:sourcePath isDirectory:YES];
}

+ (nullable NSString *)groupContainerApplicationSupport
{
	NSURL *sourceURL = self.groupContainerApplicationSupportURL;

	if (sourceURL == nil) {
		return nil;
	}

	return sourceURL.path;
}

+ (nullable NSURL *)groupContainerApplicationSupportURL
{
	NSURL *sourceURL = self.groupContainerURL;

	if (sourceURL == nil) {
		return nil;
	}

	NSURL *baseURL = [sourceURL URLByAppendingPathComponent:@"/Library/Application Support/Textual/"];

	[self _createDirectoryAtURL:baseURL];

	return baseURL;
}

+ (nullable NSString *)applicationLogs
{
	NSArray *pathArray = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES);

	if (pathArray.count == 0) {
		return nil;
	}

	NSString *endPath = [NSString stringWithFormat:@"/Logs/%@/", TXBundleBuildProductIdentifier];

	NSString *basePath = [pathArray.firstObject stringByAppendingPathComponent:endPath];

	[self _createDirectoryAtPath:basePath];

	return basePath;
}

+ (nullable NSURL *)applicationLogsURL
{
	NSString *sourcePath = self.applicationLogs;

	if (sourcePath == nil) {
		return nil;
	}

	return [NSURL fileURLWithPath:sourcePath isDirectory:YES];
}

+ (NSString *)applicationTemporary
{
	NSString *sourcePath = NSTemporaryDirectory();

	NSString *endPath = [NSString stringWithFormat:@"/%@/", TXBundleBuildProductIdentifier];

	NSString *basePath = [sourcePath stringByAppendingPathComponent:endPath];

	[self _createDirectoryAtPath:basePath];

	return basePath;
}

+ (NSURL *)applicationTemporaryURL
{
	return [NSURL fileURLWithPath:self.applicationTemporary isDirectory:YES];
}

+ (NSString *)applicationTemporaryProcessSpecific
{
	NSString *sourcePath = self.applicationTemporary;

	int processIdentifier = [[NSProcessInfo processInfo] processIdentifier];

	NSString *endPath = [NSString stringWithFormat:@"/tmp-%i", processIdentifier];

	NSString *basePath = [sourcePath stringByAppendingPathComponent:endPath];

	[self _createDirectoryAtPath:basePath];

	return basePath;
}

+ (NSURL *)applicationTemporaryProcessSpecificURL
{
	return [NSURL fileURLWithPath:self.applicationTemporaryProcessSpecific isDirectory:YES];
}

+ (NSString *)bundledExtensions
{
	return self.bundledExtensionsURL.path;
}

+ (NSURL *)bundledExtensionsURL
{
	NSURL *baseURL = self.applicationResourcesURL;

	return [baseURL URLByAppendingPathComponent:@"/Bundled Extensions/"];
}

+ (NSString *)bundledScripts
{
	return self.bundledScriptsURL.path;
}

+ (NSURL *)bundledScriptsURL
{
	NSURL *baseURL = self.applicationResourcesURL;

	return [baseURL URLByAppendingPathComponent:@"/Bundled Scripts/"];
}

+ (NSString *)bundledThemes
{
	return self.bundledThemesURL.path;
}

+ (NSURL *)bundledThemesURL
{
	NSURL *baseURL = self.applicationResourcesURL;

	return [baseURL URLByAppendingPathComponent:@"/Bundled Styles/"];
}

+ (nullable NSString *)customExtensions
{
	NSURL *sourceURL = self.customExtensionsURL;

	if (sourceURL == nil) {
		return nil;
	}

	return sourceURL.path;
}

+ (nullable NSURL *)customExtensionsURL
{
	NSURL *sourceURL = self.groupContainerApplicationSupportURL;

	if (sourceURL == nil) {
		return nil;
	}

	NSURL *baseURL = [sourceURL URLByAppendingPathComponent:@"/Extensions/"];

	[self _createDirectoryAtURL:baseURL];

	return baseURL;
}

+ (nullable NSString *)customScripts
{
	NSArray *pathArray = NSSearchPathForDirectoriesInDomains(NSApplicationScriptsDirectory, NSUserDomainMask, YES);

	if (pathArray.count == 0) {
		return nil;
	}

	NSString *basePath = pathArray.firstObject;

#if TEXTUAL_BUILT_INSIDE_SANDBOX == 0
	[self _createDirectoryAtPath:basePath];
#endif

	return basePath;
}

+ (nullable NSURL *)customScriptsURL
{
	NSString *sourcePath = self.customScripts;

	if (sourcePath == nil) {
		return nil;
	}

	return [NSURL fileURLWithPath:sourcePath isDirectory:YES];
}

+ (nullable NSString *)customThemes
{
	NSURL *sourceURL = self.customThemesURL;

	if (sourceURL == nil) {
		return nil;
	}

	return sourceURL.path;
}

+ (nullable NSURL *)customThemesURL
{
	NSURL *sourceURL = self.groupContainerApplicationSupportURL;

	if (sourceURL == nil) {
		return nil;
	}

	NSURL *baseURL = [sourceURL URLByAppendingPathComponent:@"/Styles/"];

	[self _createDirectoryAtURL:baseURL];

	return baseURL;
}

#pragma mark -
#pragma mark System Specific

+ (nullable NSString *)systemApplications
{
	NSArray *searchArray = NSSearchPathForDirectoriesInDomains(NSApplicationDirectory, NSSystemDomainMask, YES);

	if (searchArray.count == 0) {
		return nil;
	}

	return searchArray.firstObject;
}

+ (nullable NSURL *)systemApplicationsURL
{
	NSString *sourcePath = self.systemApplications;

	if (sourcePath == nil) {
		return nil;
	}

	return [NSURL fileURLWithPath:sourcePath isDirectory:YES];
}

+ (NSString *)systemDiagnosticReports
{
	return @"/Library/Logs/DiagnosticReports";
}

+ (NSURL *)systemDiagnosticReportsURL
{
	return [NSURL fileURLWithPath:self.systemDiagnosticReports isDirectory:YES];
}

#pragma mark -
#pragma mark User Specific

+ (nullable NSString *)userApplicationScripts
{
	NSURL *sourceURL = self.userApplicationScriptsURL;

	if (sourceURL == nil) {
		return nil;
	}

	return sourceURL.path;
}

+ (nullable NSURL *)userApplicationScriptsURL
{
	NSURL *sourceURL = self.customScriptsURL;

	return [sourceURL URLByDeletingLastPathComponent];
}

+ (NSString *)userDiagnosticReports
{
	return self.userDiagnosticReportsURL.path;
}

+ (NSURL *)userDiagnosticReportsURL
{
	NSURL *sourceURL = self.userHomeURL;

	return [sourceURL URLByAppendingPathComponent:@"/Library/Logs/DiagnosticReports"];
}

+ (nullable NSString *)userDownloads
{
	NSArray *searchArray = NSSearchPathForDirectoriesInDomains(NSDownloadsDirectory, NSUserDomainMask, YES);

	if (searchArray.count == 0) {
		return nil;
	}

	return searchArray.firstObject;
}

+ (nullable NSURL *)userDownloadsURL
{
	NSString *sourcePath = self.userDownloads;

	if (sourcePath == nil) {
		return nil;
	}

	return [NSURL fileURLWithPath:sourcePath isDirectory:YES];
}

+ (NSString *)userHome
{
#if TEXTUAL_BUILT_INSIDE_SANDBOX == 1
	uid_t userId = getuid();

	struct passwd *pw = getpwuid(userId);

	return @(pw->pw_dir);
#else
	return NSHomeDirectory();
#endif
}

+ (NSURL *)userHomeURL
{
	return [NSURL fileURLWithPath:self.userHome isDirectory:YES];
}

+ (nullable NSString *)userPreferences
{
	NSArray *searchArray = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES);

	if (searchArray.count == 0) {
		return nil;
	}

	return [searchArray.firstObject stringByAppendingPathComponent:@"/Preferences/"];
}

+ (nullable NSURL *)userPreferencesURL
{
	NSString *sourcePath = self.userPreferences;

	if (sourcePath == nil) {
		return nil;
	}

	return [NSURL fileURLWithPath:sourcePath isDirectory:YES];
}

@end

#pragma mark -
#pragma mark iCloud

#if TEXTUAL_BUILT_WITH_ICLOUD_SUPPORT == 1
@implementation TPCPathInfo (TPCPathInfoCloudExtension)

+ (nullable NSString *)applicationUbiquitousContainer
{
	return sharedCloudManager().ubiquitousContainerPath;
}

+ (nullable NSURL *)applicationUbiquitousContainerURL
{
	return sharedCloudManager().ubiquitousContainerURL;
}

+ (nullable NSString *)cloudCustomThemes
{
	NSURL *sourceURL = self.cloudCustomThemesURL;

	if (sourceURL == nil) {
		return nil;
	}

	return sourceURL.path;
}

+ (nullable NSURL *)cloudCustomThemesURL
{
	NSURL *sourceURL = self.applicationUbiquitousContainerURL;

	if (sourceURL == nil) {
		return nil;
	}

	NSURL *baseURL = [sourceURL URLByAppendingPathComponent:@"/Documents/Styles/"];

	[self _createDirectoryAtURL:baseURL];

	return baseURL;
}

+ (void)_openCloudPathOrErrorIfUnavailable:(NSString *)path
{
	NSParameterAssert(path != nil);

	if (sharedCloudManager().ubiquitousContainerIsAvailable == NO) {
		[TDCAlert alertSheetWithWindow:[NSApp keyWindow]
								  body:TXTLS(@"Prompts[wjn-f1]")
								 title:TXTLS(@"Prompts[rn7-08]")
						 defaultButton:TXTLS(@"Prompts[68u-z9]")
					   alternateButton:nil
						   otherButton:nil];

		return;
	}

	[RZWorkspace() openFile:path];
}

+ (void)openApplicationUbiquitousContainer
{
	NSString *sourcePath = self.applicationUbiquitousContainer;

	[self _openCloudPathOrErrorIfUnavailable:sourcePath];
}

+ (void)openCloudCustomThemes
{
	NSString *sourcePath = self.cloudCustomThemes;

	[self _openCloudPathOrErrorIfUnavailable:sourcePath];
}

@end
#endif

#pragma mark -
#pragma mark Transcript URL

@implementation TPCPathInfo (TPCPathInfoTranscriptFolderExtension)

static NSURL * _Nullable _transcriptFolderURL = nil;

+ (nullable NSString *)transcriptFolder
{
	return _transcriptFolderURL.path;
}

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

	[self startUsingTranscriptFolderURL];
}

+ (void)warnUserAboutStaleTranscriptFolderURL
{
	/* If logging isn't enabled, then we don't inform user of stale
	 bookmarks because they probably aren't interested in that fact. */
	if ([TPCPreferences logToDisk] == NO) {
		return;
	}
	
	[TDCAlert alertWithMessage:TXTLS(@"Prompts[atn-1c]")
						 title:TXTLS(@"Prompts[b7o-v4]")
				 defaultButton:TXTLS(@"Prompts[c7s-dq]")
			   alternateButton:nil];
}

+ (void)startUsingTranscriptFolderURL
{
	/* Even if user has logging disabled, we still start using the bookmark
	 so that we can present it in the Preferences window while the pop up
	 for selecting a new location is disabled. */
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
		/* "On return, if YES, the bookmark data is stale. 
		 Your app should create a new bookmark using the 
		 returned URL and use it in place of any stored 
		 copies of the existing bookmark." */
		NSData *newBookmark = [resolvedBookmark bookmarkDataWithOptions:NSURLBookmarkCreationWithSecurityScope
										 includingResourceValuesForKeys:nil
														  relativeToURL:nil
																  error:NULL];

		if (newBookmark) {
			[self setTranscriptFolderURL:newBookmark];
		} else {
			[self warnUserAboutStaleTranscriptFolderURL];
		}

		return;
	}

	if (resolvedBookmark == nil) {
		LogToConsoleError("Error creating bookmark for URL: %@",
			  resolvedBookmarkError.localizedDescription);

		[self warnUserAboutStaleTranscriptFolderURL];

		return;
	}

	_transcriptFolderURL = resolvedBookmark;

	if ([_transcriptFolderURL startAccessingSecurityScopedResource] == NO) {
		LogToConsoleError("Failed to access bookmark");
	}
}

@end

#pragma mark -
#pragma mark Deprecated

@implementation TPCPathInfo (TPCPathInfoDeprecated)

+ (NSString *)applicationBundlePath
{
	TEXTUAL_DEPRECATED_WARNING

	return self.applicationBundle;
}

+ (nullable NSString *)applicationCachesFolderPath
{
	TEXTUAL_DEPRECATED_WARNING

	return self.applicationCaches;
}

+ (nullable NSString *)applicationCachesFolderInsideGroupContainerPath
{
	TEXTUAL_DEPRECATED_WARNING

	return self.groupContainerApplicationCaches;
}

+ (nullable NSString *)applicationGroupContainerPath
{
	TEXTUAL_DEPRECATED_WARNING

	return self.groupContainer;
}

+ (nullable NSString *)applicationLogsFolderPath
{
	TEXTUAL_DEPRECATED_WARNING

	return self.applicationLogs;
}

+ (NSString *)applicationResourcesFolderPath
{
	TEXTUAL_DEPRECATED_WARNING

	return self.applicationResources;
}

+ (NSString *)applicationTemporaryFolderPath
{
	TEXTUAL_DEPRECATED_WARNING

	return self.applicationTemporary;
}

+ (nullable NSString *)applicationSupportFolderPathInGroupContainer
{
	TEXTUAL_DEPRECATED_WARNING

	return self.groupContainerApplicationSupport;
}

+ (nullable NSString *)applicationSupportFolderPathInLocalContainer
{
	TEXTUAL_DEPRECATED_WARNING

	return self.applicationSupport;
}

+ (nullable NSString *)systemApplicationFolderPath
{
	TEXTUAL_DEPRECATED_WARNING

	return self.systemApplications;
}

+ (nullable NSURL *)systemApplicationFolderURL
{
	TEXTUAL_DEPRECATED_WARNING

	return self.systemApplicationsURL;
}

+ (NSString *)systemDiagnosticReportsFolderPath
{
	TEXTUAL_DEPRECATED_WARNING

	return self.systemDiagnosticReports;
}

+ (NSString *)userDiagnosticReportsFolderPath
{
	TEXTUAL_DEPRECATED_WARNING

	return self.userDiagnosticReports;
}

+ (nullable NSString *)customExtensionFolderPath
{
	TEXTUAL_DEPRECATED_WARNING

	return self.customExtensions;
}

+ (nullable NSString *)customScriptsFolderPath
{
	TEXTUAL_DEPRECATED_WARNING

	return self.customScripts;
}

+ (nullable NSString *)customScriptsFolderPathLeading
{
	TEXTUAL_DEPRECATED_WARNING

	return self.userApplicationScripts;
}

+ (nullable NSString *)customThemeFolderPath
{
	TEXTUAL_DEPRECATED_WARNING

	return self.customThemes;
}

+ (NSString *)bundledExtensionFolderPath
{
	TEXTUAL_DEPRECATED_WARNING

	return self.bundledExtensions;
}

+ (NSString *)bundledScriptFolderPath
{
	TEXTUAL_DEPRECATED_WARNING

	return self.bundledScripts;
}

+ (NSString *)bundledThemeFolderPath
{
	TEXTUAL_DEPRECATED_WARNING

	return self.bundledThemes;
}

+ (nullable NSString *)userDownloadsFolderPath
{
	TEXTUAL_DEPRECATED_WARNING

	return self.userDownloads;
}

+ (NSString *)userHomeFolderPath
{
	TEXTUAL_DEPRECATED_WARNING

	return self.userHome;
}

+ (nullable NSString *)userPreferencesFolderPath
{
	TEXTUAL_DEPRECATED_WARNING

	return self.userPreferences;
}

@end

NS_ASSUME_NONNULL_END
