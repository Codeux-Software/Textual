// Created by Codeux Software <support AT codeux DOT com> <https://github.com/codeux/Textual>
// You can redistribute it and/or modify it under the new BSD license.

#import "TextualApplication.h"

@interface NSFont (TXFontHelper)
- (NSFont *)convertToItalics;

- (BOOL)fontMatchesFont:(NSFont *)otherFont;
- (BOOL)fontMatchesName:(NSString *)fontName;

- (BOOL)fontTraitSet:(NSFontTraitMask)trait;
+ (BOOL)fontIsAvailable:(NSString *)fontName;
@end