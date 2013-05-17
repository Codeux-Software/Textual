/* ********************************************************************* 
       _____        _               _    ___ ____   ____
      |_   _|___  _| |_ _   _  __ _| |  |_ _|  _ \ / ___|
       | |/ _ \ \/ / __| | | |/ _` | |   | || |_) | |
       | |  __/>  <| |_| |_| | (_| | |   | ||  _ <| |___
       |_|\___/_/\_\\__|\__,_|\__,_|_|  |___|_| \_\\____|

 Copyright (c) 2010 — 2013 Codeux Software & respective contributors.
        Please see Contributors.pdf and Acknowledgements.pdf

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

- (void)validateFilePathExistanceAndReload
{
	NSString *filekind = [TPCThemeController extractThemeSource:[TPCPreferences themeName]];
	NSString *filename = [TPCThemeController extractThemeName:[TPCPreferences themeName]];

	NSObjectIsEmptyAssert(filekind);
	NSObjectIsEmptyAssert(filename);

	NSString *path = nil;

	/* Determine the path. */
	if ([filekind isEqualToString:TPCThemeControllerBundledStyleNameBasicPrefix]) {
		path = [[TPCPreferences bundledThemeFolderPath] stringByAppendingPathComponent:filename];
	} else {
		path = [[TPCPreferences customThemeFolderPath] stringByAppendingPathComponent:filename];
	}

	/* Does the path exist? */
	if ([RZFileManager() fileExistsAtPath:path] == NO) {
		/* Path does not exist. If the path is to a custom theme, then check whether a
		 bundled theme with the same name exists. If it does not, throw exception. */
		
		if ([filekind isEqualToString:TPCThemeControllerBundledStyleNameBasicPrefix] == NO) {
			path = [[TPCPreferences bundledThemeFolderPath] stringByAppendingPathComponent:filename];

			if ([RZFileManager() fileExistsAtPath:path] == NO) {
				NSAssert(NO, @"No path to local resources.");
			}
		} else {
			/* Path that was checked is not a custom theme. Throw exception. */
			
			NSAssert(NO, @"No path to local resources.");
		}
	}

	self.baseURL = [NSURL fileURLWithPath:path];

	/* Reload theme settings. */
	[self.customSettings reloadWithPath:path];
}

- (void)load
{
	[self validateFilePathExistanceAndReload];
}

+ (NSString *)buildResourceFilename:(NSString *)name
{
	return [TPCThemeControllerBundledStyleNameCompletePrefix stringByAppendingString:name];
}

+ (NSString *)buildUserFilename:(NSString *)name
{
	return [TPCThemeControllerCustomStyleNameCompletePrefix stringByAppendingString:name];
}

+ (NSString *)extractThemeSource:(NSString *)source
{
	if ([source hasPrefix:TPCThemeControllerCustomStyleNameCompletePrefix] == NO &&
		[source hasPrefix:TPCThemeControllerBundledStyleNameCompletePrefix] == NO)
	{
		return nil;
    }

	return [source safeSubstringToIndex:[source stringPosition:@":"]];
}

+ (NSString *)extractThemeName:(NSString *)source
{
	if ([source hasPrefix:TPCThemeControllerCustomStyleNameCompletePrefix] == NO &&
		[source hasPrefix:TPCThemeControllerBundledStyleNameCompletePrefix] == NO)
	{
		return nil;
    }
	
	return [source safeSubstringAfterIndex:[source stringPosition:@":"]];	
}

@end
