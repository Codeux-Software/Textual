// Created by Satoshi Nakagawa <psychs AT limechat DOT net> <http://github.com/psychs/limechat>
// Modifications by Codeux Software <support AT codeux DOT com> <https://github.com/codeux/Textual>
// You can redistribute it and/or modify it under the new BSD license.
// Converted to ARC Support on June 08, 2012

#import "TextualApplication.h"

@interface TPCViewTheme (Private)
- (void)load;
@end

@implementation TPCViewTheme


- (id)init
{
	if ((self = [super init])) {
		self.other = [TPCOtherTheme new];
		
		self.core_js = [TLOFileWithContent new];
		self.core_js.filename = [[TPCPreferences whereResourcePath] stringByAppendingPathComponent:@"/JavaScript/API/core.js"];
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
				self.path = [[TPCPreferences whereThemesLocalPath] stringByAppendingPathComponent:filename];
			} else {
				self.path = [[TPCPreferences whereThemesPath] stringByAppendingPathComponent:filename];
			}
			
			if ([_NSFileManager() fileExistsAtPath:self.path] == NO) {
				if ([kind isEqualToString:@"resource"] == NO) {
					self.path = [[TPCPreferences whereThemesLocalPath] stringByAppendingPathComponent:filename];
					
					if (reload) [self reload];
				}
			}
			
			if ([_NSFileManager() fileExistsAtPath:self.path] == NO) {
				NSLog(@"Error: No path to local resources.");
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