// Created by Codeux Software <support AT codeux DOT com> <https://github.com/codeux/Textual>
// You can redistribute it and/or modify it under the new BSD license.

@interface LanguagePreferences : NSObject 
+ (void)setThemeForLocalization:(NSString *)path;
+ (NSString *)localizedStringWithKey:(NSString *)key;
@end