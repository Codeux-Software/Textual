// Created by Codeux Software <support AT codeux DOT com> <https://github.com/codeux/Textual>
// You can redistribute it and/or modify it under the new BSD license.

#define LinkTextualIRCFrameworks

#import "TextualApplication.h"

@interface TPI_BlowfishCommands : NSObject 

- (NSDictionary *)pluginOutputDisplayRules;

- (void)messageSentByUser:(IRCClient *)client
				  message:(NSString *)messageString
				  command:(NSString *)commandString;

- (NSArray *)pluginSupportsUserInputCommands;

@end