/* ********************************************************************* 
                  _____         _               _
                 |_   _|____  _| |_ _   _  __ _| |
                   | |/ _ \ \/ / __| | | |/ _` | |
                   | |  __/>  <| |_| |_| | (_| | |
                   |_|\___/_/\_\\__|\__,_|\__,_|_|

 Copyright (c) 2010 - 2016 Codeux Software, LLC & respective contributors.
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

NS_ASSUME_NONNULL_BEGIN

/* Copy operation class is responsible for copying the active theme to a different
 location when a user requests a local copy of the theme. */
@interface TPCThemeControllerCopyOperation : NSObject
@property (nonatomic, copy) NSString *themeName; // Name without source prefix
@property (nonatomic, copy) NSString *pathBeingCopiedTo;
@property (nonatomic, copy) NSString *pathBeingCopiedFrom;
@property (nonatomic, assign) TPCThemeControllerStorageLocation destinationLocation;
@property (nonatomic, assign) BOOL reloadThemeWhenCopied; // If YES, setThemeName: is called when copy completes. Otherwise, files are copied and nothing happens.
@property (nonatomic, assign) BOOL openThemeWhenCopied;
@property (nonatomic, strong) TDCProgressInformationSheet *progressIndicator;

- (void)beginOperation;
@end

/* Private header for theme controller that a plugin does not need access to. */
@interface TPCThemeController ()
@property (nonatomic, copy) NSString *cachedThemeName;
@property (nonatomic, copy, readwrite) NSURL *baseURL;
@property (nonatomic, strong, readwrite) TPCThemeSettings *customSettings;
@property (nonatomic, assign, readwrite) TPCThemeControllerStorageLocation storageLocation;
@property (nonatomic, assign) FSEventStreamRef eventStreamRef;
@property (nonatomic, strong) TPCThemeControllerCopyOperation *currentCopyOperation;

- (void)load; // Calling this more than once will throw an exception
- (void)reload;

- (void)reloadMonitoringActiveThemePath;

- (void)prepareForApplicationTermination;

- (void)copyActiveThemeToDestinationLocation:(TPCThemeControllerStorageLocation)destinationLocation reloadOnCopy:(BOOL)reloadOnCopy openNewPathOnCopy:(BOOL)openNewPathOnCopy;
@end

NS_ASSUME_NONNULL_END
