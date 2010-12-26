// Created by Codeux Software <support AT codeux DOT com> <https://github.com/codeux/Textual>
// You can redistribute it and/or modify it under the new BSD license.

#import "LanguagePreferences.h"

@implementation LanguagePreferences

static NSDictionary *themeLocalizations = nil;

+ (void)setThemeForLocalization:(NSString *)path
{
	[themeLocalizations release];
	themeLocalizations = nil;
	
	NSString *filepath = [path stringByAppendingPathComponent:@"/BasicLanguage.plist"];
	
	if ([TXNSFileManager() fileExistsAtPath:filepath]) {
		NSDictionary *localkeys = [[NSDictionary alloc] initWithContentsOfFile:filepath];
			
		if (localkeys) {
			themeLocalizations = localkeys;
		}
	}
}

+ (NSString *)localizedStringWithKey:(NSString *)key
{
	if (themeLocalizations == nil) {
		return NSLocalizedStringFromTable(key, @"BasicLanguage", nil);
	} else {
		NSString *localstring = [themeLocalizations objectForKey:key];
		
		if (localstring) return [localstring stringWithASCIIFormatting];
		
		return NSLocalizedStringFromTable(key, @"BasicLanguage", nil);;
	}
}

@end