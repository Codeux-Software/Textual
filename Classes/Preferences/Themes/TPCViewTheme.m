/* ********************************************************************* 
       _____        _               _    ___ ____   ____
      |_   _|___  _| |_ _   _  __ _| |  |_ _|  _ \ / ___|
       | |/ _ \ \/ / __| | | |/ _` | |   | || |_) | |
       | |  __/>  <| |_| |_| | (_| | |   | ||  _ <| |___
       |_|\___/_/\_\\__|\__,_|\__,_|_|  |___|_| \_\\____|

 Copyright (c) 2010 — 2012 Codeux Software & respective contributors.
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

@implementation TPCViewTheme

- (id)init
{
	if ((self = [super init])) {
		self.other = [TPCOtherTheme new];
	}
	
	return self;
}

- (void)setName:(NSString *)value
{
	if (NSDissimilarObjects(self.name, value)) {
		_name = value;
	}
	
	[self load];
}

- (void)validateFilePathExistanceAndReload:(BOOL)reload
{
	if (self.name) {
		NSString *kind = [TPCViewTheme extractThemeSource:[TPCPreferences themeName]];
		NSString *filename = [TPCViewTheme extractThemeName:[TPCPreferences themeName]];
		
		if (NSObjectIsNotEmpty(kind) && NSObjectIsNotEmpty(filename)) {
			if ([kind isEqualToString:@"resource"]) {
				self.path = [[TPCPreferences bundledThemeFolderPath] stringByAppendingPathComponent:filename];
			} else {
				self.path = [[TPCPreferences customThemeFolderPath] stringByAppendingPathComponent:filename];
			}
			
			if ([_NSFileManager() fileExistsAtPath:self.path] == NO) {
				if ([kind isEqualToString:@"resource"] == NO) {
					self.path = [[TPCPreferences bundledThemeFolderPath] stringByAppendingPathComponent:filename];
					
					if (reload) [self reload];
				}
			}
			
			if ([_NSFileManager() fileExistsAtPath:self.path] == NO) {
				LogToConsole(@"Error: No path to local resources.");
				exit(0);
			}
			
			self.baseUrl = [NSURL fileURLWithPath:self.path];
			self.other.path = self.path;
			
			return;
		}
	}
	
	self.other.path = nil;
}

- (void)load
{
	[self validateFilePathExistanceAndReload:NO];
}

- (void)reload
{
	[self.other reload];
}

+ (NSString *)buildResourceFilename:(NSString *)name
{
	return [NSString stringWithFormat:@"resource:%@", name];
}

+ (NSString *)buildUserFilename:(NSString *)name
{
	return [NSString stringWithFormat:@"user:%@", name];
}

+ (NSString *)extractThemeSource:(NSString *)source
{
	if ([source hasPrefix:@"user:"] == NO && 
		[source hasPrefix:@"resource:"] == NO) return nil;
	
	return [source safeSubstringToIndex:[source stringPosition:@":"]];
}

+ (NSString *)extractThemeName:(NSString *)source
{
	if ([source hasPrefix:@"user:"] == NO && 
		[source hasPrefix:@"resource:"] == NO) return nil;
    
	return [source safeSubstringAfterIndex:[source stringPosition:@":"]];	
}

@end