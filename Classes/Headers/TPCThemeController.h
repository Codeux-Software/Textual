/* *********************************************************************
 *                  _____         _               _
 *                 |_   _|____  _| |_ _   _  __ _| |
 *                   | |/ _ \ \/ / __| | | |/ _` | |
 *                   | |  __/>  <| |_| |_| | (_| | |
 *                   |_|\___/_/\_\\__|\__,_|\__,_|_|
 *
 * Copyright (c) 2008 - 2010 Satoshi Nakagawa <psychs AT limechat DOT net>
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

@class TPCThemeSettings;

TEXTUAL_EXTERN NSString * const TPCThemeControllerCloudThemeNameBasicPrefix;
TEXTUAL_EXTERN NSString * const TPCThemeControllerCloudThemeNameCompletePrefix;

TEXTUAL_EXTERN NSString * const TPCThemeControllerCustomThemeNameBasicPrefix;
TEXTUAL_EXTERN NSString * const TPCThemeControllerCustomThemeNameCompletePrefix;

TEXTUAL_EXTERN NSString * const TPCThemeControllerBundledThemeNameBasicPrefix;
TEXTUAL_EXTERN NSString * const TPCThemeControllerBundledThemeNameCompletePrefix;

TEXTUAL_EXTERN NSString * const TPCThemeControllerThemeListDidChangeNotification;

typedef NS_ENUM(NSUInteger, TPCThemeControllerStorageLocation) {
	TPCThemeControllerStorageUnknownLocation = 0,
	TPCThemeControllerStorageBundleLocation,
	TPCThemeControllerStorageCustomLocation,
	TPCThemeControllerStorageCloudLocation
};

@interface TPCThemeController : NSObject
@property (readonly, copy) NSURL *baseURL;
@property (readonly) TPCThemeSettings *customSettings;
@property (readonly) TPCThemeControllerStorageLocation storageLocation;

/* Calls for the active theme */
@property (readonly, copy) NSString *name;

@property (readonly) BOOL usesTemporaryPath;
@property (readonly, copy) NSString *temporaryPath;

@property (readonly, copy) NSString *path;

@property (readonly, copy) NSString *cacheToken;

@property (getter=isBundledTheme, readonly) BOOL bundledTheme;

/* Returns YES if a theme reload was necessary */
- (BOOL)validateThemeAndReloadIfNecessary;

/* Calls for all themes */
+ (void)enumerateAvailableThemesWithBlock:(void(NS_NOESCAPE ^)(NSString *themeName, TPCThemeControllerStorageLocation storageLocation, BOOL multipleVaraints, BOOL *stop))enumerationBlock;

/* A theme is considered existent if the designated design.css file and scripts.js for
 it exists. Otherwise, the theme is considered nonexistent even if the folder exists. */
+ (BOOL)themeExists:(NSString *)themeName;

+ (nullable NSString *)pathOfThemeWithName:(NSString *)themeName;
+ (nullable NSString *)pathOfThemeWithName:(NSString *)themeName storageLocation:(nullable TPCThemeControllerStorageLocation *)storageLocation;

+ (nullable NSString *)buildFilename:(NSString *)name forStorageLocation:(TPCThemeControllerStorageLocation)storageLocation;

+ (nullable NSString *)extractThemeSource:(NSString *)source;
+ (nullable NSString *)extractThemeName:(NSString *)source;

+ (TPCThemeControllerStorageLocation)expectedStorageLocationOfThemeWithName:(NSString *)themeName;

+ (nullable NSString *)descriptionForStorageLocation:(TPCThemeControllerStorageLocation)storageLocation;
@end

NS_ASSUME_NONNULL_END
