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

@interface THOPluginItem ()
@property (nonatomic, readwrite, strong) id primaryClass;
@property (nonatomic, readwrite, assign) THOPluginItemSupportedFeatures supportedFeatures;
@property (nonatomic, readwrite, copy) NSArray *supportedUserInputCommands;
@property (nonatomic, readwrite, copy) NSArray *supportedServerInputCommands;
@property (nonatomic, readwrite, copy) NSArray *outputSuppressionRules;
@property (nonatomic, readwrite, strong) NSView *pluginPreferencesPaneView;
@property (nonatomic, readwrite, copy) NSString *pluginPreferencesPaneMenuItemName;
@end

@implementation THOPluginItem

#define VOCT(o, t)				 [o isKindOfClass:[t class]]
#define VTAE(o, t)				([o isKindOfClass:[t class]] && NSObjectIsNotEmpty(o))

- (BOOL)loadBundle:(NSBundle *)bundle
{
	/* Only load once. */
	if (self.primaryClass != nil) {
		NSAssert(NO, @"-loadBundle: called a THOPluginItem instance that is already loaded");
	}

	/* Begin version comparison. */
	NSDictionary *bundleInfo = [bundle infoDictionary];
	
	NSString *comparisonVersion = bundleInfo[@"MinimumTextualVersion"];
	
	if (comparisonVersion == nil) {
		LogToConsole(@" -------------- WARNING -------------- ");
		LogToConsole(@" Textual has loaded a bundle at the following path which did not specify a minimum version: ");
		LogToConsole(@"  ");
		LogToConsole(@"		Bundle Path: %@", [bundle bundlePath]);
		LogToConsole(@"  ");
		LogToConsole(@" Please add a key-value pair in the bundle's Info.plist file with the key name as \"MinimumTextualVersion\" ");
		LogToConsole(@" For example, to support this version and later, add the value: ");
		LogToConsole(@"  ");
		LogToConsole(@"     <key>MinimumTextualVersion</key>");
		LogToConsole(@"     <string>%@</string>", THOPluginProtocolCompatibilityMinimumVersion);
		LogToConsole(@"  ");
		LogToConsole(@" Failure to provide a minimum version is currently only a warning, but in the future, Textual will ");
		LogToConsole(@" refuse to load bundles that do not specify a minimum version to load within. ");
		LogToConsole(@"-------------- WARNING -------------- ");
	} else {
		NSComparisonResult comparisonResult = [comparisonVersion compare:THOPluginProtocolCompatibilityMinimumVersion options:NSNumericSearch];
		
		if (comparisonResult == NSOrderedAscending) {
			LogToConsole(@" -------------- ERROR -------------- ");
			LogToConsole(@" Textual has failed to load the bundle at the followig path because the specified minimum version is out of range:");
			LogToConsole(@"  ");
			LogToConsole(@"		Bundle Path: %@", [bundle bundlePath]);
			LogToConsole(@"  ");
			LogToConsole(@"		Minimum version specified by bundle: %@", comparisonVersion);
			LogToConsole(@"		Version used by Textual for comparison: %@", THOPluginProtocolCompatibilityMinimumVersion);
			LogToConsole(@"  ");
			LogToConsole(@" -------------- ERROR -------------- ");
			
			return NO; // Cancel operation.
		}
	}
	
	/* Initialize the principal class. */
	Class principalClass = [bundle principalClass];

	if (principalClass == nil) {
		return NO;
	}

	self.primaryClass = [principalClass new];

	if ([self.primaryClass respondsToSelector:@selector(pluginLoadedIntoMemory)]) {
		[self.primaryClass pluginLoadedIntoMemory];
	}

	/* Build list of supported features. */
	THOPluginItemSupportedFeatures supportedFeatures = 0;

	/* Process server output suppression rules. */
	if ([self.primaryClass respondsToSelector:@selector(pluginOutputSuppressionRules)])
	{
		id outputRules = [self.primaryClass pluginOutputSuppressionRules];

		if (VTAE(outputRules, NSArray)) {
			NSMutableArray *sharedRules = [NSMutableArray array];

			for (id outputRule in outputRules) {
				if (VOCT(outputRule, THOPluginOutputSuppressionRule)) {
					[sharedRules addObject:outputRule];
				}
			}

			self.outputSuppressionRules = sharedRules;

			supportedFeatures |= THOPluginItemSupportsOutputSuppressionRules;
		}
	}

	/* Does the bundle have a preference pane?... */
	if ([self.primaryClass respondsToSelector:@selector(pluginPreferencesPaneMenuItemName)] &&
		[self.primaryClass respondsToSelector:@selector(pluginPreferencesPaneView)])
	{
		id itemView = [self.primaryClass pluginPreferencesPaneView];
		id itemName = [self.primaryClass pluginPreferencesPaneMenuItemName];

		if (VTAE(itemName, NSString) && VOCT(itemView, NSView)) {
			supportedFeatures |= THOPluginItemSupportsPreferencePane;
		}
	}

	/* Process user input commands. */
	if ([self.primaryClass respondsToSelector:@selector(subscribedUserInputCommands)] &&
		[self.primaryClass respondsToSelector:@selector(userInputCommandInvokedOnClient:commandString:messageString:)])
	{
		id subscribedCommands = [self.primaryClass subscribedUserInputCommands];
		
		if (VTAE(subscribedCommands, NSArray)) {
			NSMutableArray *supportedCommands = [NSMutableArray array];

			for (id command in subscribedCommands) {
				if (VTAE(command, NSString))  {
					[supportedCommands addObject:[command lowercaseString]];
				}
			}

			self.supportedUserInputCommands = supportedCommands;

			supportedFeatures |= THOPluginItemSupportsSubscribedUserInputCommands;
		}
	}

	/* Process server input commands. */
	if ( [self.primaryClass respondsToSelector:@selector(subscribedServerInputCommands)] &&
		([self.primaryClass respondsToSelector:@selector(didReceiveServerInput:onClient:)] ||
		 [self.primaryClass respondsToSelector:@selector(didReceiveServerInputOnClient:senderInformation:messageInformation:)]))
	{
		id subscribedCommands = [self.primaryClass subscribedServerInputCommands];

		if (VTAE(subscribedCommands, NSArray)) {
			NSMutableArray *supportedCommands = [NSMutableArray array];

			for (id command in subscribedCommands) {
				if (VTAE(command, NSString))  {
					[supportedCommands addObject:[command lowercaseString]];
				}
			}

			self.supportedServerInputCommands = supportedCommands;

			supportedFeatures |= THOPluginItemSupportsSubscribedServerInputCommands;
		}
	}
	
	/* Check whether plugin supports certain evnets so we do not have
	 to ask if it responds to the responder everytime we call it. */

	/* Renderer events. */
	if ([self.primaryClass respondsToSelector:@selector(didPostNewMessage:forViewController:)] ||
		[self.primaryClass respondsToSelector:@selector(didPostNewMessageForViewController:messageInfo:isThemeReload:isHistoryReload:)])
	{
		supportedFeatures |= THOPluginItemSupportsNewMessagePostedEvent;
	}
	
	if ([self.primaryClass respondsToSelector:@selector(willRenderMessage:forViewController:lineType:memberType:)]) {
		supportedFeatures |= THOPluginItemSupportsWillRenderMessageEvent;
	}
	
	/* Inline media. */
	if ([self.primaryClass respondsToSelector:@selector(processInlineMediaContentURL:)]) {
		supportedFeatures |= THOPluginItemSupportsInlineMediaManipulation;
	}
	
	/* Data interception. */
	if ([self.primaryClass respondsToSelector:@selector(interceptServerInput:for:)]) {
		supportedFeatures |= THOPluginItemSupportsServerInputDataInterception;
	}
	
	if ([self.primaryClass respondsToSelector:@selector(interceptUserInput:command:)]) {
		supportedFeatures |= THOPluginItemSupportsUserInputDataInterception;
	}

	/* Finish up */
	self.supportedFeatures = supportedFeatures;
	
	return YES;
}

- (void)sendDealloc
{
	if (self.primaryClass == nil) {
		return; // Send to where... ?
	}

	if ([self.primaryClass respondsToSelector:@selector(pluginWillBeUnloadedFromMemory)]) {
		[self.primaryClass pluginWillBeUnloadedFromMemory];
	}
}

- (BOOL)supportsFeature:(THOPluginItemSupportedFeatures)feature
{
	return ((_supportedFeatures & feature) == feature);
}

@end
