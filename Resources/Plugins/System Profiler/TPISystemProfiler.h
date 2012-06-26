// Created by Codeux Software <support AT codeux DOT com> <https://github.com/codeux/Textual>
// You can redistribute it and/or modify it under the new BSD license.

#include "SystemProfiler.h"

@interface TPISystemProfiler : NSObject
/* User Input */
- (void)messageSentByUser:(IRCClient *)client
				  message:(NSString *)messageString
				  command:(NSString *)commandString;

- (NSArray *)pluginSupportsUserInputCommands;

/* Allocation & Deallocation */
- (void)pluginLoadedIntoMemory:(IRCWorld *)world;

/* Preference Pane */
- (NSView *)preferencesView;
- (NSString *)preferencesMenuItemName;
@end