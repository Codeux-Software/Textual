// Created by Codeux Software <support AT codeux DOT com> <https://github.com/codeux/Textual>
// You can redistribute it and/or modify it under the new BSD license.

@implementation LanguagePreferences

static NSDictionary *themeLocalizations = nil;

+ (void)setThemeForLocalization:(NSString *)path
{
	[themeLocalizations drain];
	themeLocalizations = nil;
	
	NSString *filepath = [path stringByAppendingPathComponent:@"/BasicLanguage.plist"];
	
	if ([_NSFileManager() fileExistsAtPath:filepath]) {
		NSDictionary *localkeys = [NSDictionary dictionaryWithContentsOfFile:filepath];
	
		[localkeys retain];
			
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
		NSString *localstring = [themeLocalizations objectForKey:key];
		
		if (localstring) {
			return [localstring reservedCharactersToIRCFormatting];
		}
		
		return NSLocalizedStringFromTable(key, @"BasicLanguage", nil);
	}
}

@end