/* ********************************************************************* 
       _____        _               _    ___ ____   ____
      |_   _|___  _| |_ _   _  __ _| |  |_ _|  _ \ / ___|
       | |/ _ \ \/ / __| | | |/ _` | |   | || |_) | |
       | |  __/>  <| |_| |_| | (_| | |   | ||  _ <| |___
       |_|\___/_/\_\\__|\__,_|\__,_|_|  |___|_| \_\\____|

 Copyright (c) 2010 — 2013 Codeux Software & respective contributors.
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

@implementation THOPluginItem

#define OINE(o)					 NSObjectIsNotEmpty(o)

#define VOCT(o, t)				 [o isKindOfClass:[t class]]
#define VTAE(o, t)				([o isKindOfClass:[t class]] && NSObjectIsNotEmpty(o))

- (void)loadBundle:(NSBundle *)bundle
{
	/* Only load once. */
	if (PointerIsNotEmpty(self.primaryClass)) {
		return;
	}

	/* Initialize the principal class. */
	Class principalClass = [bundle principalClass];

	if (PointerIsEmpty(principalClass)) {
		return;
	}

	_primaryClass = [principalClass new];

	/* Say hello! */
	if ([self.primaryClass respondsToSelector:@selector(pluginLoadedIntoMemory:)])
	{
		TXMasterController *master = TPCPreferences.masterController;

		if (master) {
			[self.primaryClass pluginLoadedIntoMemory:master.world];
		}
	}
	
	/* Process server output suppression rules. */
	if ([self.primaryClass respondsToSelector:@selector(pluginOutputDisplayRules)])
	{
		// Use id, never assume what a 3rd party might give.
		id outputRulesO = [self.primaryClass pluginOutputDisplayRules];

		if (VTAE(outputRulesO, NSDictionary)) {
			NSMutableDictionary *sharedRules = [NSMutableDictionary dictionary];

			for (NSString *command in outputRulesO) { // Dictionary keys are always NSString.
				NSArray *appndix = [self processOutputSuppressionRules:outputRulesO forCommand:command];

				if (NSObjectIsNotEmpty(appndix)) {
					[sharedRules safeSetObject:appndix forKey:command];
				}
			}

			_outputSuppressionRules = sharedRules;
		}
	}

	/* Does the bundle have a preference pane?… */
	if ([self.primaryClass respondsToSelector:@selector(preferencesMenuItemName)] &&
		[self.primaryClass respondsToSelector:@selector(preferencesView)])
	{
		id itemView = [self.primaryClass preferencesView];
		id itemName = [self.primaryClass preferencesMenuItemName];

		if (VTAE(itemName, NSString) && VOCT(itemView, NSView)) {
			_hasPreferencePaneView = YES;
		}
	}

	/* Process user input commands. */
	if ([self.primaryClass respondsToSelector:@selector(messageSentByUser:message:command:)] &&
		[self.primaryClass respondsToSelector:@selector(pluginSupportsUserInputCommands)])
	{
		id spdcmds = [self.primaryClass pluginSupportsUserInputCommands];

		if (VTAE(spdcmds, NSArray)) {
			NSMutableArray *supportedCommands = [NSMutableArray array];

			for (id command in spdcmds) {
				if (VOCT(command, NSString))  {
					[supportedCommands safeAddObject:[command lowercaseString]];
				}
			}

			_supportedUserInputCommands = supportedCommands;
		}
	}

	/* Process server input commands. */
	if ([self.primaryClass respondsToSelector:@selector(messageReceivedByServer:sender:message:)] &&
		[self.primaryClass respondsToSelector:@selector(pluginSupportsServerInputCommands)])
	{
		id spdcmds = [self.primaryClass pluginSupportsServerInputCommands];

		if (VTAE(spdcmds, NSArray)) {
			NSMutableArray *supportedCommands = [NSMutableArray array];

			for (id command in spdcmds) {
				if (VOCT(command, NSString))  {
					[supportedCommands safeAddObject:[command lowercaseString]];
				}
			}

			_supportedServerInputCommands = supportedCommands;
		}
	}
}

- (void)dealloc
{
	if ([self.primaryClass respondsToSelector:@selector(pluginUnloadedFromMemory)]) {
		[self.primaryClass pluginUnloadedFromMemory];
	}
}

- (NSArray *)processOutputSuppressionRules:(NSDictionary *)outputRules forCommand:(NSString *)sourceCommand
{
	id commandRules = outputRules[sourceCommand];
	
	if (VTAE(commandRules, NSArray)) {
		NSArray *newBosses;

		for (id commandRule in commandRules) {
			if (VTAE(commandRule, NSArray) && [commandRule count] == 4) {
				NSString *ruleMatch	= commandRule[0];

				id hideChannel	= commandRule[1];
				id hideQuery	= commandRule[2];
				id hideConsole	= commandRule[3];

				NSArray *bossEntry = @[ruleMatch, hideConsole, hideChannel, hideQuery];

				if (NSObjectIsEmpty(newBosses)) {
					newBosses = @[bossEntry];
				} else {
					newBosses = [newBosses arrayByAddingObject:bossEntry];
				}
			}
		}

		return newBosses;
	}

	return nil;
}

@end
