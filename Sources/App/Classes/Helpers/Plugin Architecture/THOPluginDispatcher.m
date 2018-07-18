/* *********************************************************************
 *                  _____         _               _
 *                 |_   _|____  _| |_ _   _  __ _| |
 *                   | |/ _ \ \/ / __| | | |/ _` | |
 *                   | |  __/>  <| |_| |_| | (_| | |
 *                   |_|\___/_/\_\\__|\__,_|\__,_|_|
 *
 * Copyright (c) 2010 - 2016 Codeux Software, LLC & respective contributors.
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

#import "IRCClient.h"
#import "IRCMessage.h"
#import "THOPluginItemPrivate.h"
#import "THOPluginManagerPrivate.h"
#import "THOPluginProtocolPrivate.h"
#import "THOPluginDispatcherPrivate.h"

NS_ASSUME_NONNULL_BEGIN

NSString * const THOPluginProtocolCompatibilityMinimumVersion = @"6.0.0";

@interface IRCMessage (IRCMessagePluginExtension)
- (THOPluginDidReceiveServerInputConcreteObject *)didReceiveServerInputConcreteObject;
@end

@implementation THOPluginDispatcher

+ (dispatch_queue_t)dispatchQueue
{
	static dispatch_queue_t dispatchQueue = NULL;

	static dispatch_once_t onceToken;

	dispatch_once(&onceToken, ^{
		dispatchQueue =
		XRCreateDispatchQueueWithPriority("Textual.THOPluginDispatcher.PluginManagerDispatchQueue", DISPATCH_QUEUE_SERIAL, QOS_CLASS_DEFAULT);
	});

	return dispatchQueue;
}

+ (BOOL)receivedCommand:(NSString *)command withText:(nullable NSString *)text authoredBy:(IRCPrefix *)textAuthor destinedFor:(nullable IRCChannel *)textDestination onClient:(IRCClient *)client receivedAt:(NSDate *)receivedAt referenceMessage:(nullable IRCMessage *)referenceMessage
{
	NSParameterAssert(command != nil);
	NSParameterAssert(client != nil);
	NSParameterAssert(receivedAt != nil);

	for (THOPluginItem *plugin in sharedPluginManager().loadedPlugins)
	{
		if ([plugin supportsFeature:THOPluginItemSupportedFeatureDidReceiveCommandEvent] == NO) {
			continue;
		}

		BOOL returnedValue = [plugin.primaryClass receivedCommand:command withText:text authoredBy:textAuthor destinedFor:textDestination onClient:client receivedAt:receivedAt referenceMessage:referenceMessage];

		if (returnedValue == NO) {
			return NO;
		}
	}

	return YES;
}

+ (BOOL)receivedText:(NSString *)text authoredBy:(IRCPrefix *)textAuthor destinedFor:(nullable IRCChannel *)textDestination asLineType:(TVCLogLineType)lineType onClient:(IRCClient *)client receivedAt:(NSDate *)receivedAt wasEncrypted:(BOOL)wasEncrypted
{
	NSParameterAssert(text != nil);
	NSParameterAssert(textAuthor != nil);
	NSParameterAssert(client != nil);
	NSParameterAssert(receivedAt != nil);

	for (THOPluginItem *plugin in sharedPluginManager().loadedPlugins)
	{
		if ([plugin supportsFeature:THOPluginItemSupportedFeatureDidReceivePlainTextMessageEvent] == NO) {
			continue;
		}

		BOOL returnedValue = [plugin.primaryClass receivedText:text authoredBy:textAuthor destinedFor:textDestination asLineType:lineType onClient:client receivedAt:receivedAt wasEncrypted:wasEncrypted];

		if (returnedValue == NO) {
			return NO;
		}
	}

	return YES;
}

+ (nullable IRCMessage *)interceptServerInput:(IRCMessage *)inputObject for:(IRCClient *)client
{
	NSParameterAssert(inputObject != nil);
	NSParameterAssert(client != nil);

	IRCMessage *returnValue = inputObject;

	for (THOPluginItem *plugin in sharedPluginManager().loadedPlugins)
	{
		if ([plugin supportsFeature:THOPluginItemSupportedFeatureServerInputDataInterception] == NO) {
			continue;
		}

		IRCMessage *returnedValue = [plugin.primaryClass interceptServerInput:returnValue for:client];

		if (returnedValue == nil) {
			return nil;
		} else if (returnedValue != returnValue) {
			if ([returnedValue isKindOfClass:[IRCMessageMutable class]]) {
				returnValue = [returnedValue copy];
			} else {
				returnValue = returnedValue;
			}
		}
	}

	return returnValue;
}

+ (nullable id)interceptUserInput:(id)inputObject command:(IRCRemoteCommand)commandString
{
	NSParameterAssert(inputObject != nil);

	id returnValue = inputObject;

	for (THOPluginItem *plugin in sharedPluginManager().loadedPlugins)
	{
		if ([plugin supportsFeature:THOPluginItemSupportedFeatureUserInputDataInterception] == NO) {
			continue;
		}

		id returnedValue = [plugin.primaryClass interceptUserInput:returnValue command:commandString];

		if (returnedValue == nil) {
			return nil;
		} else if ([returnedValue isEqual:returnValue] == NO &&
				   ([returnedValue isKindOfClass:[NSString class]] ||
					[returnedValue isKindOfClass:[NSAttributedString class]]))
		{
			if ([returnedValue isKindOfClass:[NSMutableString class]] ||
				[returnedValue isKindOfClass:[NSMutableAttributedString class]])
			{
				returnValue = [returnedValue copy];
			} else {
				returnValue = returnedValue;
			}
		}
	}

	return returnValue;
}

+ (NSString *)willRenderMessage:(NSString *)newMessage forViewController:(TVCLogController *)viewController lineType:(TVCLogLineType)lineType memberType:(TVCLogLineMemberType)memberType
{
	NSParameterAssert(newMessage != nil);
	NSParameterAssert(viewController != nil);

	NSString *returnValue = newMessage;

	for (THOPluginItem *plugin in sharedPluginManager().loadedPlugins)
	{
		if ([plugin supportsFeature:THOPluginItemSupportedFeatureWillRenderMessageEvent] == NO) {
			continue;
		}

		NSString *returnedValue = [plugin.primaryClass willRenderMessage:returnValue forViewController:viewController lineType:lineType memberType:memberType];

		if (returnedValue.length == 0) {
			continue;
		} else if ([returnedValue isEqualToString:returnValue]) {
			continue;
		}

		returnValue = [returnedValue copy];
	}

	return returnValue;
}

+ (void)userInputCommandInvokedOnClient:(IRCClient *)client commandString:(NSString *)commandString messageString:(NSString *)messageString
{
	NSParameterAssert(client != nil);
	NSParameterAssert(commandString != nil);
	NSParameterAssert(messageString != nil);

	XRPerformBlockAsynchronouslyOnQueue([self dispatchQueue], ^{
		NSString *lowercaseCommand = commandString.lowercaseString;

		NSString *uppercaseCommand = commandString.uppercaseString;

		for (THOPluginItem *plugin in sharedPluginManager().loadedPlugins)
		{
			if ([plugin supportsFeature:THOPluginItemSupportedFeatureSubscribedUserInputCommands] == NO) {
				continue;
			}

			if ([plugin.supportedUserInputCommands containsObject:lowercaseCommand] == NO) {
				continue;
			}

			[plugin.primaryClass userInputCommandInvokedOnClient:client commandString:uppercaseCommand messageString:messageString];
		}
	});
}

+ (void)didReceiveJavaScriptPayload:(THOPluginWebViewJavaScriptPayloadConcreteObject *)payloadObject fromViewController:(TVCLogController *)viewController
{
	NSParameterAssert(payloadObject != nil);
	NSParameterAssert(viewController != nil);

	XRPerformBlockAsynchronouslyOnQueue([self dispatchQueue], ^{
		for (THOPluginItem *plugin in sharedPluginManager().loadedPlugins)
		{
			if ([plugin supportsFeature:THOPluginItemSupportedFeatureWebViewJavaScriptPayloads] == NO) {
				continue;
			}

			[plugin.primaryClass didReceiveJavaScriptPayload:payloadObject fromViewController:viewController];
		}
	});
}

+ (void)didReceiveServerInput:(IRCMessage *)inputObject onClient:(IRCClient *)client
{
	NSParameterAssert(inputObject != nil);
	NSParameterAssert(client != nil);

	XRPerformBlockAsynchronouslyOnQueue([self dispatchQueue], ^{
		THOPluginDidReceiveServerInputConcreteObject *messageObject =
		inputObject.didReceiveServerInputConcreteObject;

		messageObject.networkAddress = client.serverAddress;
		messageObject.networkName = client.networkName;

		NSString *lowercaseCommand = inputObject.command.lowercaseString;

		for (THOPluginItem *plugin in sharedPluginManager().loadedPlugins)
		{
			if ([plugin supportsFeature:THOPluginItemSupportedFeatureSubscribedServerInputCommands] == NO) {
				continue;
			}

			if ([plugin.supportedServerInputCommands containsObject:lowercaseCommand] == NO) {
				continue;
			}

			[plugin.primaryClass didReceiveServerInput:messageObject onClient:client];
		}
	});
}

+ (NSCache<NSString *, THOPluginDidPostNewMessageConcreteObject *> *)didPostNewMessageObjectCache
{
	static NSCache *queue = nil;

	static dispatch_once_t onceToken;

	dispatch_once(&onceToken, ^{
		queue = [NSCache new];
	});

	return queue;
}

+ (void)enqueueDidPostNewMessage:(THOPluginDidPostNewMessageConcreteObject *)messageObject
{
	NSParameterAssert(messageObject != nil);

	[[self didPostNewMessageObjectCache] setObject:messageObject forKey:messageObject.lineNumber];
}

+ (void)dequeueDidPostNewMessageWithLineNumber:(NSString *)messageLineNumber forViewController:(TVCLogController *)viewController
{
	NSParameterAssert(messageLineNumber != nil);
	NSParameterAssert(viewController != nil);

	THOPluginDidPostNewMessageConcreteObject *messageObject = [[self didPostNewMessageObjectCache] objectForKey:messageLineNumber];

	if (messageObject == nil) {
		return;
	}

	XRPerformBlockAsynchronouslyOnQueue([self dispatchQueue], ^{
		for (THOPluginItem *plugin in sharedPluginManager().loadedPlugins)
		{
			if ([plugin supportsFeature:THOPluginItemSupportedFeatureNewMessagePostedEvent] == NO) {
				continue;
			}

			[plugin.primaryClass didPostNewMessage:messageObject forViewController:viewController];
		}
	});
}

@end

#pragma mark -

@implementation IRCMessage (IRCMessagePluginExtension)

- (THOPluginDidReceiveServerInputConcreteObject *)didReceiveServerInputConcreteObject
{
	 THOPluginDidReceiveServerInputConcreteObject *messageObject =
	[THOPluginDidReceiveServerInputConcreteObject new];

	messageObject.senderIsServer = self.senderIsServer;

	messageObject.senderNickname = self.senderNickname;
	messageObject.senderUsername = self.senderUsername;
	messageObject.senderAddress = self.senderAddress;
	messageObject.senderHostmask = self.senderHostmask;

	messageObject.receivedAt = self.receivedAt;

	messageObject.messageParamaters = self.params;
	messageObject.messageSequence = self.sequence;

	messageObject.messageCommand = self.command;
	messageObject.messageCommandNumeric = self.commandNumeric;

	return messageObject;
}

@end

#pragma mark -

@implementation THOPluginDidPostNewMessageConcreteObject
@end

#pragma mark -

@implementation THOPluginDidReceiveServerInputConcreteObject
@end

#pragma mark -

@implementation THOPluginWebViewJavaScriptPayloadConcreteObject
@end

#pragma mark -

@implementation THOPluginOutputSuppressionRule
@end

NS_ASSUME_NONNULL_END
