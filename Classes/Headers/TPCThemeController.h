/* ********************************************************************* 
                  _____         _               _
                 |_   _|____  _| |_ _   _  __ _| |
                   | |/ _ \ \/ / __| | | |/ _` | |
                   | |  __/>  <| |_| |_| | (_| | |
                   |_|\___/_/\_\\__|\__,_|\__,_|_|

 Copyright (c) 2008 - 2010 Satoshi Nakagawa <psychs AT limechat DOT net>
 Copyright (c) 2010 — 2014 Codeux Software, LLC & respective contributors.
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

#define TPCThemeControllerCloudThemeNameBasicPrefix				@"cloud"
#define TPCThemeControllerCloudThemeNameCompletePrefix			@"cloud:"

#define TPCThemeControllerCustomThemeNameBasicPrefix			@"user"
#define TPCThemeControllerCustomThemeNameCompletePrefix			@"user:"

#define TPCThemeControllerBundledThemeNameBasicPrefix			@"resource"
#define TPCThemeControllerBundledThemeNameCompletePrefix		@"resource:"

#define TPCThemeControllerThemeListDidChangeNotification		@"TPCThemeControllerThemeListDidChangeNotification"

typedef enum TPCThemeControllerStorageLocation : NSInteger {
	TPCThemeControllerStorageBundleLocation,
	TPCThemeControllerStorageCustomLocation,
	TPCThemeControllerStorageCloudLocation,
	TPCThemeControllerStorageUnknownLocation
} TPCThemeControllerStorageLocation;

@interface TPCThemeController : NSObject
@property (nonatomic, copy) NSURL *baseURL;
@property (nonatomic, copy) NSString *associatedThemeName;
@property (nonatomic, copy) NSString *sharedCacheID;
@property (nonatomic, strong) TPCThemeSettings *customSettings;
@property (nonatomic, assign) TPCThemeControllerStorageLocation storageLocation;

/* Calls for the active theme. */
- (void)load; // Calling this more than once will throw an exception
- (void)reload;

@property (readonly, copy) NSDictionary *dictionaryOfAllThemes;

@property (readonly, copy) NSString *path;
@property (readonly, copy) NSString *actualPath; // Ignores iCloud cache and queries iCloud directly.

@property (readonly, copy) NSString *name;

@property (getter=isBundledTheme, readonly) BOOL bundledTheme;

- (void)copyActiveStyleToDestinationLocation:(TPCThemeControllerStorageLocation)destinationLocation reloadOnCopy:(BOOL)reloadOnCopy openNewPathOnCopy:(BOOL)openNewPathOnCopy;

/* Returns YES if a theme reload was necessary. */
- (BOOL)validateThemeAndRelaodIfNecessary;

/* Calls for all themes. */
/* A theme is considered existent if the designated design.css file and scripts.js for
 it exists. Otherwise, the theme is considered nonexistent even if the folder exists. */
+ (BOOL)themeExists:(NSString *)themeName;

+ (NSString *)pathOfThemeWithName:(NSString *)themeName;
+ (NSString *)pathOfThemeWithName:(NSString *)themeName skipCloudCache:(BOOL)ignoreCloudCache storageLocation:(TPCThemeControllerStorageLocation *)storageLocation;

+ (NSString *)buildFilename:(NSString *)name forStorageLocation:(TPCThemeControllerStorageLocation)storageLocation;

+ (NSString *)extractThemeSource:(NSString *)source;
+ (NSString *)extractThemeName:(NSString *)source;

+ (TPCThemeControllerStorageLocation)expectedStorageLocationOfThemeWithName:(NSString *)themeName;
+ (TPCThemeControllerStorageLocation)actaulStorageLocationOfThemeWithName:(NSString *)themeName;
@end
