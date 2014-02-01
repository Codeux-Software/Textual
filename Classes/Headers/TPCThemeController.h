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

#define TPCThemeControllerCustomStyleNameBasicPrefix			@"user"
#define TPCThemeControllerCustomStyleNameCompletePrefix			@"user:"

#define TPCThemeControllerBundledStyleNameBasicPrefix			@"resource"
#define TPCThemeControllerBundledStyleNameCompletePrefix		@"resource:"

typedef enum TPCThemeControllerStorageLocation : NSInteger {
	TPCThemeControllerStorageBundleLocation,
	TPCThemeControllerStorageCustomLocation,
	TPCThemeControllerStorageCloudLocation,
	TPCThemeControllerStorageUnknownLocation
} TPCThemeControllerStorageLocation;

@interface TPCThemeController : NSObject
@property (nonatomic, strong) NSURL *baseURL;
@property (nonatomic, strong) NSString *associatedThemeName;
@property (nonatomic, strong) NSString *sharedCacheID;
@property (nonatomic, strong) TPCThemeSettings *customSettings;

/* Calls for the active theme. */
- (void)load;

- (NSString *)path;
- (NSString *)actualPath; // Ignores iCloud cache and queries iCloud directly.

- (NSString *)name;

- (TPCThemeControllerStorageLocation)storageLocation;

- (BOOL)isBundledTheme;

- (BOOL)actualPathForCurrentThemeIsEqualToCachedPath;

/* Calls for all themes. */
+ (BOOL)themeExists:(NSString *)themeName;

+ (NSString *)pathOfThemeWithName:(NSString *)themeName;
+ (NSString *)pathOfThemeWithName:(NSString *)themeName skipCloudCache:(BOOL)ignoreCloudCache;

+ (NSString *)buildResourceFilename:(NSString *)name;
+ (NSString *)buildUserFilename:(NSString *)name;

+ (NSString *)extractThemeSource:(NSString *)source;
+ (NSString *)extractThemeName:(NSString *)source;

+ (TPCThemeControllerStorageLocation)storageLocationOfThemeWithName:(NSString *)themeName;
@end
