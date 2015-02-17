/* ********************************************************************* 
                  _____         _               _
                 |_   _|____  _| |_ _   _  __ _| |
                   | |/ _ \ \/ / __| | | |/ _` | |
                   | |  __/>  <| |_| |_| | (_| | |
                   |_|\___/_/\_\\__|\__,_|\__,_|_|

 Copyright (c) 2010 - 2015 Codeux Software, LLC & respective contributors.
        Please see Acknowledgements.pdf for additional information.

 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions
 are met:

    * Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the
      documentation and/or other materials provided with the distribution.
    * Neither the name of Textual and/or "Codeux Software, LLC", nor the 
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

#import "BuildConfig.h"

@implementation THOPluginItem

#define TXBundleMininumBundleVersionForLoadingExtensions			@"5.0.0"

#define OINE(o)					 NSObjectIsNotEmpty(o)

#define VOCT(o, t)				 [o isKindOfClass:[t class]]
#define VTAE(o, t)				([o isKindOfClass:[t class]] && NSObjectIsNotEmpty(o))

- (BOOL)loadBundle:(NSBundle *)bundle
{
	/* Only load once. */
	PointerIsNotEmptyAssertReturn(self.primaryClass, NO);

	/* Begin version comparison. */
	NSDictionary *bundleInfo = [bundle infoDictionary];
	
	NSString *comparisonVersion = bundleInfo[@"MinimumTextualVersion"];
	
	if (comparisonVersion == nil) {
		LogToConsole(@"-------------- WARNING -------------- ");
		LogToConsole(@"Textual has loaded a bundle at the following path which did not specify a minimum version:");
		LogToConsole(@"  ");
		LogToConsole(@"   Bundle Path: %@", [bundle bundlePath]);
		LogToConsole(@"  ");
		LogToConsole(@"Please add a key-value pair in the bundle's Info.plist file with the key name as \"MinimumTextualVersion\"");
		LogToConsole(@"For example, to support this version and later, add the value:");
		LogToConsole(@"  ");
		LogToConsole(@"     <key>MinimumTextualVersion</key>");
		LogToConsole(@"     <string>%@</string>", TXBundleMininumBundleVersionForLoadingExtensions);
		LogToConsole(@"  ");
		LogToConsole(@"Failure to provide a minimum version is currently only a warning, but in the future, Textual will");
		LogToConsole(@"refuse to load bundles that do not specify a minimum version to load within.");
		LogToConsole(@"-------------- WARNING -------------- ");
	} else {
		NSComparisonResult comparisonResult = [comparisonVersion compare:TXBundleMininumBundleVersionForLoadingExtensions options:NSNumericSearch];
		
		if (comparisonResult == NSOrderedDescending) {
			LogToConsole(@"-------------- ERROR -------------- ");
			LogToConsole(@"Textual has failed to load the bundle at the followig path because the specified minimum version is out of range:");
			LogToConsole(@"  ");
			LogToConsole(@"   Bundle Path: %@", [bundle bundlePath]);
			LogToConsole(@"  ");
			LogToConsole(@"   Minimum version specified by bundle: %@", comparisonVersion);
			LogToConsole(@"   Version used by Textual for comparison: %@", TXBundleMininumBundleVersionForLoadingExtensions);
			LogToConsole(@"  ");
			LogToConsole(@"-------------- ERROR -------------- ");
			
			return NO; // Cancel operation.
		}
	}
	
	/* Initialize the principal class. */
	Class principalClass = [bundle principalClass];

	PointerIsEmptyAssertReturn(principalClass, NO);

	self.primaryClass = [principalClass new];

	/* Say hello! */
	BOOL supportsOldFeature = [self.primaryClass respondsToSelector:@selector(pluginLoadedIntoMemory:)];
	BOOL supportsNewFeature = [self.primaryClass respondsToSelector:@selector(pluginLoadedIntoMemory)];
	
	if (supportsOldFeature || supportsNewFeature)
	{
		if (supportsNewFeature) {
			[self.primaryClass pluginLoadedIntoMemory];
		} else {
			[self.primaryClass pluginLoadedIntoMemory:worldController()];
			
			LogToConsole(@"DEPRECATED: Primary class %@ uses deprecated -pluginLoadedIntoMemory:", self.primaryClass);
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
					sharedRules[command] = appndix;
				}
			}

			self.outputSuppressionRules = sharedRules;
		}
	}

	/* Does the bundle have a preference pane?… */
	supportsOldFeature = ([self.primaryClass respondsToSelector:@selector(preferencesMenuItemName)] &&
						  [self.primaryClass respondsToSelector:@selector(preferencesView)]);
	
	supportsNewFeature = ([self.primaryClass respondsToSelector:@selector(pluginPreferencesPaneMenuItemName)] &&
						  [self.primaryClass respondsToSelector:@selector(pluginPreferencesPaneView)]);
	
	if (supportsOldFeature || supportsNewFeature)
	{
		id itemView;
		id itemName;
		
		if (supportsNewFeature) {
			itemView = [self.primaryClass pluginPreferencesPaneView];
			itemName = [self.primaryClass pluginPreferencesPaneMenuItemName];
		} else {
			itemView = [self.primaryClass preferencesView];
			itemName = [self.primaryClass preferencesMenuItemName];
			
			LogToConsole(@"DEPRECATED: Primary class %@ uses deprecated -preferencesMenuItemName", self.primaryClass);
			LogToConsole(@"DEPRECATED: Primary class %@ uses deprecated -preferencesView", self.primaryClass);
		}

		if (VTAE(itemName, NSString) && VOCT(itemView, NSView)) {
			self.hasPreferencePaneView = YES;
		}
	}

	/* Process user input commands. */
	supportsOldFeature = ([self.primaryClass respondsToSelector:@selector(messageSentByUser:message:command:)] &&
						  [self.primaryClass respondsToSelector:@selector(pluginSupportsUserInputCommands)]);
	
	supportsNewFeature = ([self.primaryClass respondsToSelector:@selector(userInputCommandInvokedOnClient:commandString:messageString:)] &&
						  [self.primaryClass respondsToSelector:@selector(subscribedUserInputCommands)]);
	
	if (supportsOldFeature || supportsNewFeature)
	{
		id spdcmds;
		
		if (supportsNewFeature) {
			spdcmds = [self.primaryClass subscribedUserInputCommands];
		} else {
			spdcmds = [self.primaryClass pluginSupportsUserInputCommands];
			
			LogToConsole(@"DEPRECATED: Primary class %@ uses deprecated -messageSentByUser:message:command:", self.primaryClass);
			LogToConsole(@"DEPRECATED: Primary class %@ uses deprecated -pluginSupportsUserInputCommands", self.primaryClass);
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

			self.supportedUserInputCommands = supportedCommands;
		}
	}

	/* Process server input commands. */
	supportsOldFeature = ([self.primaryClass respondsToSelector:@selector(messageReceivedByServer:sender:message:)] &&
						  [self.primaryClass respondsToSelector:@selector(pluginSupportsServerInputCommands)]);
	
	supportsNewFeature = ([self.primaryClass respondsToSelector:@selector(didReceiveServerInputOnClient:senderInformation:messageInformation:)] &&
						  [self.primaryClass respondsToSelector:@selector(subscribedServerInputCommands)]);
	
	if (supportsOldFeature || supportsNewFeature)
	{
		id spdcmds;
		
		if (supportsNewFeature) {
			spdcmds = [self.primaryClass subscribedServerInputCommands];
		} else {
			spdcmds = [self.primaryClass pluginSupportsServerInputCommands];
			
			LogToConsole(@"DEPRECATED: Primary class %@ uses deprecated -messageReceivedByServer:sender:message:", self.primaryClass);
			LogToConsole(@"DEPRECATED: Primary class %@ uses deprecated -pluginSupportsServerInputCommands", self.primaryClass);
		}

		if (VTAE(spdcmds, NSArray)) {
			NSMutableArray *supportedCommands = [NSMutableArray array];

			for (id command in spdcmds) {
				if (VOCT(command, NSString))  {
					[supportedCommands addObject:[command lowercaseString]];
				}
			}

			self.supportedServerInputCommands = supportedCommands;
		}
	}
	
	/* Check whether plugin supports certain evnets so we do not have
	 to ask if it responds to the responder everytime we call it. */
	
	/* Renderer events. */
	if ([self.primaryClass respondsToSelector:@selector(didPostNewMessageForViewController:messageInfo:isThemeReload:isHistoryReload:)])
	{
		self.supportsNewMessagePostedEventNotifications = YES;
	}
	
	if ([self.primaryClass respondsToSelector:@selector(willRenderMessage:forViewController:lineType:memberType:)])
	{
		self.supportsWillRenderMessageEventNotifications = YES;
	}
	
	/* Inline media. */
	if ([self.primaryClass respondsToSelector:@selector(processInlineMediaContentURL:)])
	{
		self.supportsInlineMediaManipulation = YES;
	}
	
	/* Data interception. */
	if ([self.primaryClass respondsToSelector:@selector(interceptServerInput:for:)])
	{
		self.supportsServerInputDataInterception = YES;
	}
	
	if ([self.primaryClass respondsToSelector:@selector(interceptUserInput:command:)])
	{
		self.supportsUserInputDataInterception = YES;
	}
	
	return YES;
}

- (void)sendDealloc
{
	BOOL supportsOldFeature = [self.primaryClass respondsToSelector:@selector(pluginUnloadedFromMemory)];
	BOOL supportsNewFeature = [self.primaryClass respondsToSelector:@selector(pluginWillBeUnloadedFromMemory)];
	
	if (supportsOldFeature || supportsNewFeature)
	{
		if (supportsNewFeature) {
			[self.primaryClass pluginWillBeUnloadedFromMemory];
		} else {
			[self.primaryClass pluginUnloadedFromMemory];
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
	BOOL supportsOldFeature = [self.primaryClass respondsToSelector:@selector(preferencesView)];
	BOOL supportsNewFeature = [self.primaryClass respondsToSelector:@selector(pluginPreferencesPaneView)];
	
	if (supportsOldFeature || supportsNewFeature)
	{
		if (supportsNewFeature) {
			return [self.primaryClass pluginPreferencesPaneView];
		} else {
			return [self.primaryClass preferencesView];
		}
	}
	
	return nil;
}

- (NSString *)pluginPreferencesPaneMenuItemName
{
	BOOL supportsOldFeature = [self.primaryClass respondsToSelector:@selector(preferencesMenuItemName)];
	BOOL supportsNewFeature = [self.primaryClass respondsToSelector:@selector(pluginPreferencesPaneMenuItemName)];
	
	if (supportsOldFeature || supportsNewFeature)
	{
		if (supportsNewFeature) {
			return [self.primaryClass pluginPreferencesPaneMenuItemName];
		} else {
			return [self.primaryClass preferencesMenuItemName];
		}
	}
	
	return nil;
}

@end
