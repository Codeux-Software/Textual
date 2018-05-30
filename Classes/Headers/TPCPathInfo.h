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

NS_ASSUME_NONNULL_BEGIN

@interface TPCPathInfo : NSObject
#pragma mark -
#pragma mark Application Specific

@property (readonly, class) NSString *applicationBundle;
@property (readonly, class) NSURL *applicationBundleURL;

@property (readonly, class) NSString *applicationResources;
@property (readonly, class) NSURL *applicationResourcesURL;

@property (readonly, class, nullable) NSString *applicationCaches;
@property (readonly, class, nullable) NSURL *applicationCachesURL;

@property (readonly, class, nullable) NSString *groupContainer;
@property (readonly, class, nullable) NSURL *groupContainerURL;

@property (readonly, class, nullable) NSString *groupContainerApplicationCaches;
@property (readonly, class, nullable) NSURL *groupContainerApplicationCachesURL;

@property (readonly, class, nullable) NSString *applicationSupport;
@property (readonly, class, nullable) NSURL *applicationSupportURL;

@property (readonly, class, nullable) NSString *groupContainerApplicationSupport;
@property (readonly, class, nullable) NSURL *groupContainerApplicationSupportURL;

@property (readonly, class, nullable) NSString *applicationLogs;
@property (readonly, class, nullable) NSURL *applicationLogsURL;

@property (readonly, class) NSString *applicationTemporary;
@property (readonly, class) NSURL *applicationTemporaryURL;

@property (readonly, class) NSString *applicationTemporaryProcessSpecific;
@property (readonly, class) NSURL *applicationTemporaryProcessSpecificURL;

@property (readonly, class) NSString *bundledExtensions;
@property (readonly, class) NSURL *bundledExtensionsURL;

@property (readonly, class) NSString *bundledScripts;
@property (readonly, class) NSURL *bundledScriptsURL;

@property (readonly, class) NSString *bundledThemes;
@property (readonly, class) NSURL *bundledThemesURL;

@property (readonly, class, nullable) NSString *customExtensions;
@property (readonly, class, nullable) NSURL *customExtensionsURL;

@property (readonly, class, nullable) NSString *customScripts;
@property (readonly, class, nullable) NSURL *customScriptsURL;

@property (readonly, class, nullable) NSString *customThemes;
@property (readonly, class, nullable) NSURL *customThemesURL;

#pragma mark -
#pragma mark System Specific

@property (readonly, class, nullable) NSString *systemApplications;
@property (readonly, class, nullable) NSURL *systemApplicationsURL;

@property (readonly, class) NSString *systemDiagnosticReports;
@property (readonly, class) NSURL *systemDiagnosticReportsURL;

#pragma mark -
#pragma mark User Specific

@property (readonly, class, nullable) NSString *userApplicationScripts;
@property (readonly, class, nullable) NSURL *userApplicationScriptsURL;

@property (readonly, class) NSString *userDiagnosticReports;
@property (readonly, class) NSURL *userDiagnosticReportsURL;

@property (readonly, class, nullable) NSString *userDownloads;
@property (readonly, class, nullable) NSURL *userDownloadsURL;

@property (readonly, class) NSString *userHome;
@property (readonly, class) NSURL *userHomeURL;

@property (readonly, class, nullable) NSString *userPreferences;
@property (readonly, class, nullable) NSURL *userPreferencesURL;
@end

#if TEXTUAL_BUILT_WITH_ICLOUD_SUPPORT == 1
@interface TPCPathInfo (TPCPathInfoCloudExtension)
@property (readonly, class, nullable) NSString *applicationUbiquitousContainer;
@property (readonly, class, nullable) NSURL *applicationUbiquitousContainerURL;

+ (void)openApplicationUbiquitousContainer;

@property (readonly, class, nullable) NSString *cloudCustomThemes;
@property (readonly, class, nullable) NSURL *cloudCustomThemesURL;

+ (void)openCloudCustomThemes;
@end
#endif

@interface TPCPathInfo (TPCPathInfoDeprecated)
+ (NSString *)applicationBundlePath TEXTUAL_DEPRECATED("Use +applicationBundle instead");
+ (nullable NSString *)applicationCachesFolderPath TEXTUAL_DEPRECATED("Use +applicationCaches instead");
+ (nullable NSString *)applicationCachesFolderInsideGroupContainerPath TEXTUAL_DEPRECATED("Use +groupContainerApplicationCaches instead");
+ (nullable NSString *)applicationGroupContainerPath TEXTUAL_DEPRECATED("Use +groupContainer instead");
+ (nullable NSString *)applicationLogsFolderPath TEXTUAL_DEPRECATED("Use +applicationLogs instead");
+ (NSString *)applicationResourcesFolderPath TEXTUAL_DEPRECATED("Use +applicationResources instead");
+ (NSString *)applicationTemporaryFolderPath TEXTUAL_DEPRECATED("Use +applicationTemporary instead");

+ (nullable NSString *)applicationSupportFolderPathInGroupContainer TEXTUAL_DEPRECATED("Use +groupContainerApplicationSupport instead");
+ (nullable NSString *)applicationSupportFolderPathInLocalContainer TEXTUAL_DEPRECATED("Use +applicationSupport instead");

+ (nullable NSString *)systemApplicationFolderPath TEXTUAL_DEPRECATED("Use +systemApplications instead");
+ (nullable NSURL *)systemApplicationFolderURL TEXTUAL_DEPRECATED("Use +systemApplicationsURL instead");

+ (NSString *)systemDiagnosticReportsFolderPath TEXTUAL_DEPRECATED("Use +systemDiagnosticReports instead");
+ (NSString *)userDiagnosticReportsFolderPath TEXTUAL_DEPRECATED("Use +userDiagnosticReports instead");

+ (nullable NSString *)customExtensionFolderPath TEXTUAL_DEPRECATED("Use +customExtensions instead");
+ (nullable NSString *)customScriptsFolderPath TEXTUAL_DEPRECATED("Use +customScripts instead");
+ (nullable NSString *)customScriptsFolderPathLeading TEXTUAL_DEPRECATED("Use +userApplicationScripts instead");
+ (nullable NSString *)customThemeFolderPath TEXTUAL_DEPRECATED("Use +customThemes instead");

+ (NSString *)bundledExtensionFolderPath TEXTUAL_DEPRECATED("Use +bundledExtensions instead");
+ (NSString *)bundledScriptFolderPath TEXTUAL_DEPRECATED("Use +bundledScripts instead");
+ (NSString *)bundledThemeFolderPath TEXTUAL_DEPRECATED("Use +bundledThemes instead");

+ (nullable NSString *)userDownloadsFolderPath TEXTUAL_DEPRECATED("Use +userDownloads instead");
+ (NSString *)userHomeFolderPath TEXTUAL_DEPRECATED("Use +userHome instead");
+ (nullable NSString *)userPreferencesFolderPath TEXTUAL_DEPRECATED("Use +userPreferences instead");
@end

NS_ASSUME_NONNULL_END
