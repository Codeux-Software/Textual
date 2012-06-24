// Created by Codeux Software <support AT codeux DOT com> <https://github.com/codeux/Textual>
// You can redistribute it and/or modify it under the new BSD license.
// Converted to ARC Support on June 08, 2012

#import "TextualApplication.h"

@implementation TLOLanguagePreferences

static NSDictionary *themeLocalizations = nil;

+ (void)setThemeForLocalization:(NSString *)path
{
	themeLocalizations = nil;
	
	NSString *filepath = [path stringByAppendingPathComponent:@"/BasicLanguage.plist"];
	
	if ([_NSFileManager() fileExistsAtPath:filepath]) {
		NSDictionary *localkeys = [NSDictionary dictionaryWithContentsOfFile:filepath];
	
		if (localkeys) {
			themeLocalizations = localkeys;
		}
	}
}

+ (NSString *)localizedStringWithKey:(NSString *)key
{
	if (PointerIsEmpty(themeLocalizations)) {
		return NSLocalizedStringFromTable(key, @"BasicLanguage", nil);
	} else {
		NSString *localstring = themeLocalizations[key];
		
		if (localstring) {
			return [localstring reservedCharactersToIRCFormatting];
		}
		
		return NSLocalizedStringFromTable(key, @"BasicLanguage", nil);
	}
}

@end