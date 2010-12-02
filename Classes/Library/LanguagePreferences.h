#import <Cocoa/Cocoa.h>

#include "NSStringHelper.h"

@interface LanguagePreferences : NSObject 

+ (void)setThemeForLocalization:(NSString *)path;
+ (NSString *)localizedStringWithKey:(NSString *)key;

@end