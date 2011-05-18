// Created by Codeux Software <support AT codeux DOT com> <https://github.com/codeux/Textual>
// You can redistribute it and/or modify it under the new BSD license.

@implementation TextualPluginItem

@synthesize pluginBundle;
@synthesize pluginPrimaryClass;

- (void)initWithPluginClass:(Class)primaryClass 
				  andBundle:(NSBundle *)bundle
				andIRCWorld:(IRCWorld *)world
		  withUserInputDict:(NSMutableDictionary **)userDict
		withServerInputDict:(NSMutableDictionary **)serverDict
		 withOuputRulesDict:(NSMutableDictionary **)outputRulesDict;
{
	pluginPrimaryClass = [primaryClass new];
	
	if (pluginPrimaryClass) {
		NSMutableDictionary *newUserDict		= [*userDict mutableCopy];
		NSMutableDictionary *newServerDict		= [*serverDict mutableCopy];
		NSMutableDictionary *newOutputRulesDict	= [*outputRulesDict mutableCopy];
		
		[*userDict drain];
		[*serverDict drain];
		[*outputRulesDict drain];
		
		// Ouput Rules
		
		if ([pluginPrimaryClass respondsToSelector:@selector(pluginOutputDisplayRules)]) {
			NSDictionary *pluginRules = [pluginPrimaryClass pluginOutputDisplayRules];
			
			if (NSObjectIsNotEmpty(pluginRules)) {
				for (NSString *command in pluginRules) {
					if ([Preferences commandUIndex:command] >= 1) {
						id objectValue = [pluginRules objectForKey:command];
						
						if ([objectValue isKindOfClass:[NSArray class]]) {
							for (NSArray *commandRules in objectValue) {
								if ([commandRules count] == 4) {
									NSString *regex		= [commandRules safeObjectAtIndex:0];
									
									NSNumber *channels	= [commandRules safeObjectAtIndex:1];
									NSNumber *queries	= [commandRules safeObjectAtIndex:2];
									NSNumber *console	= [commandRules safeObjectAtIndex:3];
									
									if (NSObjectIsNotEmpty(regex)) {
										NSArray *boss_entry = [NSArray arrayWithObjects:console, channels, queries, nil];
										
										if ([newOutputRulesDict containsKey:command] == NO) {
											[newOutputRulesDict setObject:[NSMutableDictionary newad] forKey:command];
										}
										
										NSDictionary *originalEntries = [newOutputRulesDict objectForKey:command];
										
										if ([originalEntries containsKeyIgnoringCase:regex]) {
											NSLog(@"Extension Error: Found multiple entries of the same regular expression in an output rule. Using only first. (Command = \"%@\" Expression = \"%@\")", command, regex);
										} else {
											[[newOutputRulesDict objectForKey:command] setObject:boss_entry forKey:regex];
										}
									}
								}
							}
						}
					}
				}
			}
		}
		
		// User Input
		
		if ([pluginPrimaryClass respondsToSelector:@selector(messageSentByUser:message:command:)]) {
			if ([pluginPrimaryClass respondsToSelector:@selector(pluginSupportsUserInputCommands)]) {
				NSArray *spdcmds = [pluginPrimaryClass pluginSupportsUserInputCommands];
				
				if (NSObjectIsNotEmpty(spdcmds)) {
					for (NSString *cmd in spdcmds) {
						cmd = [cmd uppercaseString];
						
						NSArray *cmdDict = [newUserDict objectForKey:cmd];
						
						if (NSObjectIsEmpty(cmdDict)) {
							[newUserDict setObject:[NSMutableArray newad] forKey:cmd];
						}
						
						if ([cmdDict containsObject:bundle] == NO) {
							[[newUserDict objectForKey:cmd] safeAddObject:self];
						}
					}
				}
			}
		}
		
		// Server Input
		
		if ([pluginPrimaryClass respondsToSelector:@selector(messageReceivedByServer:sender:message:)]) {
			if ([pluginPrimaryClass respondsToSelector:@selector(pluginSupportsServerInputCommands)]) {
				NSArray *spdcmds = [pluginPrimaryClass pluginSupportsServerInputCommands];
				
				if (NSObjectIsNotEmpty(spdcmds)) {
					for (NSString *cmd in spdcmds) {
						cmd = [cmd uppercaseString];
						
						NSArray *cmdDict = [newServerDict objectForKey:cmd];
						
						if (NSObjectIsEmpty(cmdDict)) {
							[newServerDict setObject:[NSMutableArray newad] forKey:cmd];
						}
						
						if ([cmdDict containsObject:bundle] == NO) {
							[[newServerDict objectForKey:cmd] safeAddObject:self];
						}
					}
				}
			}
		}
		
		if ([pluginPrimaryClass respondsToSelector:@selector(pluginLoadedIntoMemory:)]) {
			[pluginPrimaryClass pluginLoadedIntoMemory:world];
		}
		
		*userDict			= [newUserDict retain];
		*serverDict			= [newServerDict retain];
		*outputRulesDict	= [newOutputRulesDict retain];
		
		[newUserDict drain];
		[newServerDict drain];
		[newOutputRulesDict drain];
	}
}

- (void)dealloc
{
	if ([pluginPrimaryClass respondsToSelector:@selector(pluginUnloadedFromMemory)]) {
		[pluginPrimaryClass pluginUnloadedFromMemory];
	}
	
	[pluginPrimaryClass drain];
	[pluginBundle drain];
	
	[super dealloc];
}

@end