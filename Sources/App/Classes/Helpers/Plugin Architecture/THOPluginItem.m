/* *********************************************************************
 *                  _____         _               _
 *                 |_   _|____  _| |_ _   _  __ _| |
 *                   | |/ _ \ \/ / __| | | |/ _` | |
 *                   | |  __/>  <| |_| |_| | (_| | |
 *                   |_|\___/_/\_\\__|\__,_|\__,_|_|
 *
 * Copyright (c) 2010 - 2015 Codeux Software, LLC & respective contributors.
 *       Please see Acknowledgements.pdf for additional information.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *
 *  * Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 *  * Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 *  * Neither the name of Textual, "Codeux Software, LLC", nor the
 *    names of its contributors may be used to endorse or promote products
 *    derived from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE AUTHOR AND CONTRIBUTORS ``AS IS'' AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED. IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE LIABLE
 * FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
 * OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
 * LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
 * OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
 * SUCH DAMAGE.
 *
 *********************************************************************** */

#import "THOPluginProtocol.h"
#import "THOPluginItemPrivate.h"

NS_ASSUME_NONNULL_BEGIN

@interface THOPluginItem ()
@property (nonatomic, strong, readwrite, nullable) NSBundle *bundle;
@property (nonatomic, strong, readwrite, nullable) id primaryClass;
@property (nonatomic, assign, readwrite) THOPluginItemSupportedFeature supportedFeatures;
@property (nonatomic, copy, readwrite, nullable) NSArray<NSString *> *supportedUserInputCommands;
@property (nonatomic, copy, readwrite, nullable) NSArray<NSString *> *supportedServerInputCommands;
@property (nonatomic, copy, readwrite, nullable) NSArray<THOPluginOutputSuppressionRule *> *outputSuppressionRules;
@property (nonatomic, copy, readwrite, nullable) NSString *pluginPreferencesPaneMenuItemTitle;
@property (nonatomic, strong, readwrite, nullable) NSView *pluginPreferencesPaneView;
@end

@implementation THOPluginItem

#define VOCT(o, t)				 [o isKindOfClass:[t class]]
#define VTAE(o, t)				([o isKindOfClass:[t class]] && NSObjectIsNotEmpty(o))

- (BOOL)loadBundle:(NSBundle *)bundle
{
	NSParameterAssert(bundle != nil);

	/* Initialize the principal class */
	Class principalClass = bundle.principalClass;

	if (principalClass == nil) {
		return NO;
	}

	id <THOPluginProtocol> primaryClass = [[principalClass alloc] init];

	if ([primaryClass respondsToSelector:@selector(pluginLoadedIntoMemory)]) {
		[primaryClass pluginLoadedIntoMemory];
	}

	/* Build list of supported features */
	THOPluginItemSupportedFeature supportedFeatures = 0;

	/* Process server output suppression rules */
	if ([primaryClass respondsToSelector:@selector(pluginOutputSuppressionRules)])
	{
		id outputRules = primaryClass.pluginOutputSuppressionRules;

		if (VTAE(outputRules, NSArray)) {
			NSMutableArray *sharedRules = [NSMutableArray array];

			for (id outputRule in outputRules) {
				if (VOCT(outputRule, THOPluginOutputSuppressionRule) == NO) {
					continue;
				}

				[sharedRules addObject:outputRule];
			}

			self.outputSuppressionRules = sharedRules;

			supportedFeatures |= THOPluginItemSupportedFeatureOutputSuppressionRules;
		}
	}

	/* Does the bundle have a preference pane?... */
	if ([primaryClass respondsToSelector:@selector(pluginPreferencesPaneMenuItemName)] &&
		[primaryClass respondsToSelector:@selector(pluginPreferencesPaneView)])
	{
		id itemTitle = primaryClass.pluginPreferencesPaneMenuItemName;
		id itemView = primaryClass.pluginPreferencesPaneView;

		if (VTAE(itemTitle, NSString) && VOCT(itemView, NSView)) {
			self.pluginPreferencesPaneMenuItemTitle = itemTitle;
			self.pluginPreferencesPaneView = itemView;

			supportedFeatures |= THOPluginItemSupportedFeaturePreferencePane;
		}
	}

	/* Process user input commands */
	if ([primaryClass respondsToSelector:@selector(subscribedUserInputCommands)] &&
		[primaryClass respondsToSelector:@selector(userInputCommandInvokedOnClient:commandString:messageString:)])
	{
		id subscribedCommands = primaryClass.subscribedUserInputCommands;

		if (VTAE(subscribedCommands, NSArray)) {
			NSMutableArray *supportedCommands = [NSMutableArray array];

			for (id command in subscribedCommands) {
				if (VTAE(command, NSString) == NO)  {
					continue;
				}

				[supportedCommands addObject:[command lowercaseString]];
			}

			self.supportedUserInputCommands = supportedCommands;

			supportedFeatures |= THOPluginItemSupportedFeatureSubscribedUserInputCommands;
		}
	}

	/* Process server input commands */
	if ([primaryClass respondsToSelector:@selector(subscribedServerInputCommands)] &&
		[primaryClass respondsToSelector:@selector(didReceiveServerInput:onClient:)])
	{
		id subscribedCommands = primaryClass.subscribedServerInputCommands;

		if (VTAE(subscribedCommands, NSArray)) {
			NSMutableArray *supportedCommands = [NSMutableArray array];

			for (id command in subscribedCommands) {
				if (VTAE(command, NSString) == NO)  {
					continue;
				}

				[supportedCommands addObject:[command lowercaseString]];
			}

			self.supportedServerInputCommands = supportedCommands;

			supportedFeatures |= THOPluginItemSupportedFeatureSubscribedServerInputCommands;
		}
	}

	/* Check whether plugin supports certain evnets so we do not have
	 to ask if it responds to the selector every time we call it. */

	/* Renderer events */
	if ([primaryClass respondsToSelector:@selector(didPostNewMessage:forViewController:)]) {
		supportedFeatures |= THOPluginItemSupportedFeatureNewMessagePostedEvent;
	}

	if ([primaryClass respondsToSelector:@selector(willRenderMessage:forViewController:lineType:memberType:)]) {
		supportedFeatures |= THOPluginItemSupportedFeatureWillRenderMessageEvent;
	}

	if ([primaryClass respondsToSelector:@selector(didReceiveJavaScriptPayload:fromViewController:)]) {
		supportedFeatures |= THOPluginItemSupportedFeatureWebViewJavaScriptPayloads;
	}

	/* Data interception */
	if ([primaryClass respondsToSelector:@selector(interceptServerInput:for:)]) {
		supportedFeatures |= THOPluginItemSupportedFeatureServerInputDataInterception;
	}

	if ([primaryClass respondsToSelector:@selector(interceptUserInput:command:)]) {
		supportedFeatures |= THOPluginItemSupportedFeatureUserInputDataInterception;
	}

	if ([primaryClass respondsToSelector:@selector(receivedText:authoredBy:destinedFor:asLineType:onClient:receivedAt:wasEncrypted:)]) {
		supportedFeatures |= THOPluginItemSupportedFeatureDidReceivePlainTextMessageEvent;
	}

	if ([primaryClass respondsToSelector:@selector(receivedCommand:withText:authoredBy:destinedFor:onClient:receivedAt:referenceMessage:)]) {
		supportedFeatures |= THOPluginItemSupportedFeatureDidReceiveCommandEvent;
	}

	/* Deprecated and removed */
	if ([primaryClass respondsToSelector:@selector(didPostNewMessageForViewController:messageInfo:isThemeReload:isHistoryReload:)]) {
		LogToConsoleError("'%@' implements '-[THOPluginProtocol %@]' but that wont be called because it's obsolete.",
			bundle, @"didPostNewMessageForViewController:messageInfo:isThemeReload:isHistoryReload:");
	}

	if ([primaryClass respondsToSelector:@selector(didReceiveServerInputOnClient:senderInformation:messageInformation:)]) {
		LogToConsoleError("'%@' implements '-[THOPluginProtocol %@]' but that wont be called because it's obsolete.",
			bundle, @"didReceiveServerInputOnClient:senderInformation:messageInformation:");
	}

	/* Finish up */
	self.bundle = bundle;

	self.supportedFeatures = supportedFeatures;

	self.primaryClass = primaryClass;

	return YES;
}

- (void)unloadBundle
{
	if (self.primaryClass == nil) {
		return;
	}

	if ([self.primaryClass respondsToSelector:@selector(pluginWillBeUnloadedFromMemory)]) {
		[self.primaryClass pluginWillBeUnloadedFromMemory];
	}

	self.primaryClass = nil;

	self.bundle = nil;
}

- (BOOL)supportsFeature:(THOPluginItemSupportedFeature)feature
{
	return ((self->_supportedFeatures & feature) == feature);
}

@end

NS_ASSUME_NONNULL_END
