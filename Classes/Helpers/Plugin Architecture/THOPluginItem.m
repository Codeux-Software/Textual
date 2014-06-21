/* ********************************************************************* 
       _____        _               _    ___ ____   ____
      |_   _|___  _| |_ _   _  __ _| |  |_ _|  _ \ / ___|
       | |/ _ \ \/ / __| | | |/ _` | |   | || |_) | |
       | |  __/>  <| |_| |_| | (_| | |   | ||  _ <| |___
       |_|\___/_/\_\\__|\__,_|\__,_|_|  |___|_| \_\\____|

 Copyright (c) 2010 — 2014 Codeux Software & respective contributors.
     Please see Acknowledgements.pdf for additional information.

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
	PointerIsNotEmptyAssert(_primaryClass);

	/* Initialize the principal class. */
	Class principalClass = [bundle principalClass];

	PointerIsEmptyAssert(principalClass);

	_primaryClass = [principalClass new];

	/* Say hello! */
	BOOL supportsOldFeature = [_primaryClass respondsToSelector:@selector(pluginLoadedIntoMemory:)];
	BOOL supportsNewFeature = [_primaryClass respondsToSelector:@selector(pluginLoadedIntoMemory)];
	
	if (supportsOldFeature || supportsNewFeature)
	{
		if (supportsNewFeature) {
			[_primaryClass pluginLoadedIntoMemory];
		} else {
			[_primaryClass pluginLoadedIntoMemory:worldController];
			
			LogToConsole(@"DEPRECATED: Primary class %@ uses deprecated -pluginLoadedIntoMemory:", _primaryClass);
		}
	}
	
	/* Process server output suppression rules. */
	if ([_primaryClass respondsToSelector:@selector(pluginOutputDisplayRules)])
	{
		// Use id, never assume what a 3rd party might give.
		id outputRulesO = [_primaryClass pluginOutputDisplayRules];

		if (VTAE(outputRulesO, NSDictionary)) {
			NSMutableDictionary *sharedRules = [NSMutableDictionary dictionary];

			for (NSString *command in outputRulesO) { // Dictionary keys are always NSString.
				NSArray *appndix = [self processOutputSuppressionRules:outputRulesO forCommand:command];

				if (NSObjectIsNotEmpty(appndix)) {
					[sharedRules setObject:appndix forKey:command];
				}
			}

			_outputSuppressionRules = sharedRules;
		}
	}

	/* Does the bundle have a preference pane?… */
	supportsOldFeature = ([_primaryClass respondsToSelector:@selector(preferencesMenuItemName)] &&
						  [_primaryClass respondsToSelector:@selector(preferencesView)]);
	
	supportsNewFeature = ([_primaryClass respondsToSelector:@selector(pluginPreferencesPaneMenuItemName)] &&
						  [_primaryClass respondsToSelector:@selector(pluginPreferencesPaneView)]);
	
	if (supportsOldFeature || supportsNewFeature)
	{
		id itemView;
		id itemName;
		
		if (supportsNewFeature) {
			itemView = [_primaryClass pluginPreferencesPaneView];
			itemName = [_primaryClass pluginPreferencesPaneMenuItemName];
		} else {
			itemView = [_primaryClass preferencesView];
			itemName = [_primaryClass preferencesMenuItemName];
			
			LogToConsole(@"DEPRECATED: Primary class %@ uses deprecated -preferencesMenuItemName", _primaryClass);
			LogToConsole(@"DEPRECATED: Primary class %@ uses deprecated -preferencesView", _primaryClass);
		}

		if (VTAE(itemName, NSString) && VOCT(itemView, NSView)) {
			_hasPreferencePaneView = YES;
		}
	}

	/* Process user input commands. */
	supportsOldFeature = ([_primaryClass respondsToSelector:@selector(messageSentByUser:message:command:)] &&
						  [_primaryClass respondsToSelector:@selector(pluginSupportsUserInputCommands)]);
	
	supportsNewFeature = ([_primaryClass respondsToSelector:@selector(userInputCommandInvokedOnClient:commandString:messageString:)] &&
						  [_primaryClass respondsToSelector:@selector(subscribedUserInputCommands)]);
	
	if (supportsOldFeature || supportsNewFeature)
	{
		id spdcmds;
		
		if (supportsNewFeature) {
			spdcmds = [_primaryClass subscribedUserInputCommands];
		} else {
			spdcmds = [_primaryClass pluginSupportsUserInputCommands];
			
			LogToConsole(@"DEPRECATED: Primary class %@ uses deprecated -messageSentByUser:message:command:", _primaryClass);
			LogToConsole(@"DEPRECATED: Primary class %@ uses deprecated -pluginSupportsUserInputCommands", _primaryClass);
		}
		
		if (VTAE(spdcmds, NSArray)) {
			NSMutableArray *supportedCommands = [NSMutableArray array];

			for (id command in spdcmds) {
				if (VOCT(command, NSString))  {
					if (NSObjectIsNotEmpty(command)) {
						[supportedCommands addObject:[command lowercaseString]];
					}
				}
			}

			_supportedUserInputCommands = supportedCommands;
		}
	}

	/* Process server input commands. */
	supportsOldFeature = ([_primaryClass respondsToSelector:@selector(messageReceivedByServer:sender:message:)] &&
						  [_primaryClass respondsToSelector:@selector(pluginSupportsServerInputCommands)]);
	
	supportsNewFeature = ([_primaryClass respondsToSelector:@selector(didReceiveServerInputOnClient:senderInformation:messageInformation:)] &&
						  [_primaryClass respondsToSelector:@selector(subscribedServerInputCommands)]);
	
	if (supportsOldFeature || supportsNewFeature)
	{
		id spdcmds;
		
		if (supportsNewFeature) {
			spdcmds = [_primaryClass subscribedServerInputCommands];
		} else {
			spdcmds = [_primaryClass pluginSupportsServerInputCommands];
			
			LogToConsole(@"DEPRECATED: Primary class %@ uses deprecated -messageReceivedByServer:sender:message:", _primaryClass);
			LogToConsole(@"DEPRECATED: Primary class %@ uses deprecated -pluginSupportsServerInputCommands", _primaryClass);
		}

		if (VTAE(spdcmds, NSArray)) {
			NSMutableArray *supportedCommands = [NSMutableArray array];

			for (id command in spdcmds) {
				if (VOCT(command, NSString))  {
					[supportedCommands addObject:[command lowercaseString]];
				}
			}

			_supportedServerInputCommands = supportedCommands;
		}
	}
	
	/* Check whether plugin supports certain evnets so we do not have
	 to ask if it responds to the responder everytime we call it. */
	
	/* Renderer events. */
	if ([_primaryClass respondsToSelector:@selector(didPostNewMessageForViewController:messageInfo:isThemeReload:isHistoryReload:)])
	{
		_supportsNewMessagePostedEventNotifications = YES;
	}
	
	if ([_primaryClass respondsToSelector:@selector(willRenderMessage:lineType:memberType:)])
	{
		_supportsWillRenderMessageEventNotifications = YES;
	}
	
	/* Inline media. */
	if ([_primaryClass respondsToSelector:@selector(processInlineMediaContentURL:)])
	{
		_supportsInlineMediaManipulation = YES;
	}
	
	/* Data interception. */
	if ([_primaryClass respondsToSelector:@selector(interceptServerInput:for:)])
	{
		_supportsServerInputDataInterception = YES;
	}
	
	if ([_primaryClass respondsToSelector:@selector(interceptUserInput:command:)])
	{
		_supportsUserInputDataInterception = YES;
	}
}

- (void)dealloc
{
	BOOL supportsOldFeature = [_primaryClass respondsToSelector:@selector(pluginUnloadedFromMemory)];
	BOOL supportsNewFeature = [_primaryClass respondsToSelector:@selector(pluginWillBeUnloadedFromMemory)];
	
	if (supportsOldFeature || supportsNewFeature)
	{
		if (supportsNewFeature) {
			[_primaryClass pluginWillBeUnloadedFromMemory];
		} else {
			[_primaryClass pluginUnloadedFromMemory];
		}
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

- (NSView *)pluginPreferenesPaneView
{
	BOOL supportsOldFeature = [_primaryClass respondsToSelector:@selector(preferencesView)];
	BOOL supportsNewFeature = [_primaryClass respondsToSelector:@selector(pluginPreferencesPaneView)];
	
	if (supportsOldFeature || supportsNewFeature)
	{
		if (supportsNewFeature) {
			return [_primaryClass pluginPreferencesPaneView];
		} else {
			return [_primaryClass preferencesView];
		}
	}
	
	return nil;
}

- (NSString *)pluginPreferencesPaneMenuItemName
{
	BOOL supportsOldFeature = [_primaryClass respondsToSelector:@selector(preferencesMenuItemName)];
	BOOL supportsNewFeature = [_primaryClass respondsToSelector:@selector(pluginPreferencesPaneMenuItemName)];
	
	if (supportsOldFeature || supportsNewFeature)
	{
		if (supportsNewFeature) {
			return [_primaryClass pluginPreferencesPaneMenuItemName];
		} else {
			return [_primaryClass preferencesMenuItemName];
		}
	}
	
	return nil;
}

@end
