// Created by Codeux Software <support AT codeux DOT com> <https://github.com/codeux/Textual>
// You can redistribute it and/or modify it under the new BSD license.

#import "TextualApplication.h"

#define TPCPreferencesMigrationAssistantUpgradePath		@"2.1.1"
#define TPCPreferencesMigrationAssistantVersionKey		@"MigrationAssistantVersion"

@interface TPCPreferencesMigrationAssistant : NSObject
+ (void)convertExistingGlobalPreferences;

+ (NSDictionary *)convertIRCClientConfiguration:(NSDictionary *)config;
+ (NSDictionary *)convertIRCChannelConfiguration:(NSDictionary *)config;
@end