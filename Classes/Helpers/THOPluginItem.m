/* ********************************************************************* 
       _____        _               _    ___ ____   ____
      |_   _|___  _| |_ _   _  __ _| |  |_ _|  _ \ / ___|
       | |/ _ \ \/ / __| | | |/ _` | |   | || |_) | |
       | |  __/>  <| |_| |_| | (_| | |   | ||  _ <| |___
       |_|\___/_/\_\\__|\__,_|\__,_|_|  |___|_| \_\\____|

 Copyright (c) 2010 — 2012 Codeux Software & respective contributors.
        Please see Contributors.pdf and Acknowledgements.pdf

 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions
 are met:

    * Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the
      documentation and/or other materials provided with the distribution.
    * Neither the name of the Textual IRC Client & Codeux Software nor the
      names of its contributors may be used to endorse or promote products
      derived from this software without specific prior written permission.

 THIS SOFTWARE IS PROVIDED BY THE AUTHOR AND CONTRIBUTORS ``AS IS'' AND
 ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 ARE DISCLAIMED. IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE LIABLE
 FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
 OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
 LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
 OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
 SUCH DAMAGE.

 *********************************************************************** */

#import "TextualApplication.h"

@implementation THOTextualPluginItem

- (void)initWithPluginClass:(Class)primaryClass 
				  andBundle:(NSBundle *)bundle
				andIRCWorld:(IRCWorld *)world
		  withUserInputDict:(NSMutableDictionary **)userDict
		withServerInputDict:(NSMutableDictionary **)serverDict
		 withOuputRulesDict:(NSMutableDictionary **)outputRulesDict
{
	self.pluginPrimaryClass = [primaryClass new];

	if (self.pluginPrimaryClass) {
		NSMutableDictionary *newUserDict		= [*userDict mutableCopy];
		NSMutableDictionary *newServerDict		= [*serverDict mutableCopy];
		NSMutableDictionary *newOutputRulesDict	= [*outputRulesDict mutableCopy];
		
		// Ouput Rules
		
		if ([self.pluginPrimaryClass respondsToSelector:@selector(pluginOutputDisplayRules)]) {
			NSDictionary *pluginRules = [self.pluginPrimaryClass pluginOutputDisplayRules];
			
			if (NSObjectIsNotEmpty(pluginRules)) {
				for (NSString *command in pluginRules) {
					if ([TPCPreferences indexOfIRCommand:command publicSearch:NO] >= 1) {
						id objectValue = pluginRules[command];
						
						if ([objectValue isKindOfClass:[NSArray class]]) {
							for (NSArray *commandRules in objectValue) {
								if ([commandRules count] == 4) {
									NSString *regex		= [commandRules safeObjectAtIndex:0];
									
									NSNumber *channels	= [commandRules safeObjectAtIndex:1];
									NSNumber *queries	= [commandRules safeObjectAtIndex:2];
									NSNumber *console	= [commandRules safeObjectAtIndex:3];
									
									if (NSObjectIsNotEmpty(regex)) {
										NSArray *boss_entry = @[console, channels, queries];
										
										if ([newOutputRulesDict containsKey:command] == NO) {
											newOutputRulesDict[command] = [[NSMutableDictionary alloc] init];
										}
										
										NSDictionary *originalEntries = newOutputRulesDict[command];
										
										if ([originalEntries containsKeyIgnoringCase:regex]) {
											LogToConsole(@"Extension Error: Found multiple entries of the same regular expression in an output rule. Using only first. (Command = \"%@\" Expression = \"%@\")", command, regex);
										} else {
											newOutputRulesDict[command][regex] = boss_entry;
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
		
		if ([self.pluginPrimaryClass respondsToSelector:@selector(messageSentByUser:message:command:)]) {
			if ([self.pluginPrimaryClass respondsToSelector:@selector(pluginSupportsUserInputCommands)]) {
				NSArray *spdcmds = [self.pluginPrimaryClass pluginSupportsUserInputCommands];
				
				if (NSObjectIsNotEmpty(spdcmds)) {
					for (__strong NSString *cmd in spdcmds) {
						cmd = [cmd uppercaseString];
						
						NSArray *cmdDict = newUserDict[cmd];
						
						if (NSObjectIsEmpty(cmdDict)) {
							newUserDict[cmd] = [[NSMutableArray alloc] init];
						}
						
						if ([cmdDict containsObject:bundle] == NO) {
							[newUserDict[cmd] safeAddObject:self];
						}
					}
				}
			}
		}
		
		// Server Input
		
		if ([self.pluginPrimaryClass respondsToSelector:@selector(messageReceivedByServer:sender:message:)]) {
			if ([self.pluginPrimaryClass respondsToSelector:@selector(pluginSupportsServerInputCommands)]) {
				NSArray *spdcmds = [self.pluginPrimaryClass pluginSupportsServerInputCommands];
				
				if (NSObjectIsNotEmpty(spdcmds)) {
					for (__strong NSString *cmd in spdcmds) {
						cmd = [cmd uppercaseString];
						
						NSArray *cmdDict = newServerDict[cmd];
						
						if (NSObjectIsEmpty(cmdDict)) {
							newServerDict[cmd] = [[NSMutableArray alloc] init];
						}
						
						if ([cmdDict containsObject:bundle] == NO) {
							[newServerDict[cmd] safeAddObject:self];
						}
					}
				}
			}
		}
		
		if ([self.pluginPrimaryClass respondsToSelector:@selector(pluginLoadedIntoMemory:)]) {
			[self.pluginPrimaryClass pluginLoadedIntoMemory:world];
		}
		
		*userDict			= newUserDict;
		*serverDict			= newServerDict;
		*outputRulesDict	= newOutputRulesDict;
	}
}

- (void)dealloc
{
	if ([self.pluginPrimaryClass respondsToSelector:@selector(pluginUnloadedFromMemory)]) {
		[self.pluginPrimaryClass pluginUnloadedFromMemory];
	}
	
	
}

@end