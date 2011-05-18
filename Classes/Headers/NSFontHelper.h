// Created by Codeux Software <support AT codeux DOT com> <https://github.com/codeux/Textual>
// You can redistribute it and/or modify it under the new BSD license.

@interface NSFont (NSFontHelper)
- (NSFont *)convertToItalics;
- (BOOL)fontMatchesFont:(NSFont *)otherFont;
- (BOOL)fontTraitSet:(NSFontTraitMask)trait;
- (BOOL)fontMatchesName:(NSString *)fontName;
+ (BOOL)fontIsAvailable:(NSString *)fontName;
@end