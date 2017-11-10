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

#import <SecurityInterface/SFCertificateTrustPanel.h>

#import "TPI_ZNCAdditions.h"

#import "IRCClientPrivate.h"
#import "TVCMainWindowPrivate.h"

NS_ASSUME_NONNULL_BEGIN

@implementation TPI_ZNCAdditions

#pragma mark -
#pragma mark Plugin API

- (void)didReceiveServerInput:(THOPluginDidReceiveServerInputConcreteObject *)inputObject onClient:(IRCClient *)client
{
	if (client.isConnectedToZNC == NO) {
		return;
	}

	NSString *sender = inputObject.senderNickname;

	NSString *message = inputObject.messageSequence;

	if ([client nickname:sender isZNCUser:@"status"] && [message hasPrefix:@"Disconnected from IRC"]) {
		/* We listen for ZNC disconnects so that we can terminate channels when we
		 disconnect from the server ZNC was connected to. ZNC does not localize 
		 itself so detecting these disconnects is not very hard... */

		[self performBlockOnMainThread:^{
			[self handleIRCSideDisconnect:client];
		}];
	}
}

- (void)userInputCommandInvokedOnClient:(IRCClient *)client
						  commandString:(NSString *)commandString
						  messageString:(NSString *)messageString
{
	/* Throw error if user tries to invoke a command that requires the
	 user to be connected to a ZNC bouncer */
	if (client.isConnectedToZNC == NO) {
		[client printDebugInformation:TPILocalizedString(@"BasicLanguage[1000]")];

		return;
	}

	/* Process commands */
	if ([commandString isEqualIgnoringCase:@"ZNCCERT"])
	{
		/* Textual is designed not to import partial content. It will either
		 return the complete certificate chain at this point, or nil. */
		NSData *certificateData = client.zncBouncerCertificateChainData;

		if (certificateData == nil) {
			[client printDebugInformation:TPILocalizedString(@"BasicLanguage[1003]")];

			return;
		}

		/* Given the raw, base64 encoded data, convert it into certificate objects. */
		SecItemImportExportKeyParameters importParameters;

		importParameters.flags = kSecKeyNoAccessControl;
		importParameters.version = SEC_KEY_IMPORT_EXPORT_PARAMS_VERSION;

		importParameters.accessRef = NULL;
		importParameters.alertTitle = NULL;
		importParameters.alertPrompt = NULL;
		importParameters.passphrase = NULL;

		importParameters.keyAttributes = NULL;
		importParameters.keyUsage = NULL;

		SecExternalItemType itemType = kSecItemTypeCertificate;

		SecExternalFormat externalFormat = kSecFormatPEMSequence;

		int flags = 0;

		CFArrayRef certificateArray = NULL;

		OSStatus operationStatus =
		SecItemImport((__bridge CFDataRef)(certificateData), NULL, &externalFormat, &itemType, flags, &importParameters, NULL, &certificateArray);

		/* Display an error or hand the certificate chain off 
		 to Apple's own APIs to display them in a dialog. */
		if (operationStatus != noErr) {
			[client printDebugInformation:TPILocalizedString(@"BasicLanguage[1004]")];

			return;
		}

		[self performBlockOnMainThread:^{
			SFCertificateTrustPanel *panel = [SFCertificateTrustPanel new];

			[panel setDefaultButtonTitle:TXTLS(@"Prompts[0008]")];

			[panel setAlternateButtonTitle:nil];

			[panel beginSheetForWindow:[NSApp mainWindow]
						 modalDelegate:nil
						didEndSelector:NULL
						   contextInfo:NULL
						  certificates:(__bridge NSArray *)certificateArray
							 showGroup:YES];
		}];

		CFRelease(certificateArray);
	}

	/* ------ */

	else if ([commandString isEqualIgnoringCase:@"DETACH"] ||
			 [commandString isEqualIgnoringCase:@"ATTACH"])
	{
		messageString = messageString.trim;

		IRCChannel *matchedChannel = nil;

		if ([client stringIsChannelName:messageString]) {
			matchedChannel = [client findChannel:messageString];
		} else {
			matchedChannel = mainWindow().selectedChannel;
		}

		if (matchedChannel == nil) {
			return;
		}

		BOOL isAttachEvent = [commandString isEqualIgnoringCase:@"ATTACH"];

		matchedChannel.autoJoin = isAttachEvent;

		if (isAttachEvent) {
			[client joinUnlistedChannel:matchedChannel.name];
		} else {
			[client sendLine:[NSString stringWithFormat:@"%@ %@", commandString, matchedChannel.name]];

			[client printDebugInformation:TPILocalizedString(@"BasicLanguage[1001]", matchedChannel.name) inChannel:matchedChannel];
		}
	}
}

- (NSArray *)subscribedUserInputCommands
{
	return @[@"detach", @"attach", @"znccert"];
}

- (NSArray *)subscribedServerInputCommands
{
	return @[@"privmsg"];
}

- (nullable IRCMessage *)interceptBufferExtrasPlaybackModule:(IRCMessage *)input forClient:(IRCClient *)client
{
	if ([client isCapabilityEnabled:ClientIRCv3SupportedCapabilityZNCPlaybackModule] == NO) {
		return input;
	}

	NSString *stringIn = [input paramAt:1];

	if ([stringIn hasPrefix:@"The playback buffer for ["]	&&
		[stringIn contains:@"] channels matching ["]		&& // This is much cleaner than regular expression...
		[stringIn hasSuffix:@"] has been cleared."])
	{
		return nil; // Ignore this event
	}

	return input;
}

#warning TODO: Update buffextras support to work with changes to znc/znc git repository.
- (nullable IRCMessage *)interceptBufferExtrasZNCModule:(IRCMessage *)input forClient:(IRCClient *)client
{
	/* Define user information */
	NSMutableArray *paramsMutable = [input.params mutableCopy];

	NSMutableString *stringIn = [paramsMutable[1] mutableCopy];

	NSString *hostmask = stringIn.token;

	if (hostmask.length == 0) {
		return input; // Return original; bad input
	}

	IRCPrefixMutable *senderMutable = [input.sender mutableCopy];

	NSString *nicknameInt = nil;
	NSString *usernameInt = nil;
	NSString *addressInt = nil;

	if ([hostmask hostmaskComponents:&nicknameInt username:&usernameInt address:&addressInt onClient:client]) {
		if (NSObjectsAreEqual(nicknameInt, client.userNickname)) {
			return nil; // Do not post these events for self
		}

		senderMutable.nickname = nicknameInt;
		senderMutable.username = usernameInt;
		senderMutable.address = addressInt;

		senderMutable.isServer = NO;
	} else {
		senderMutable.nickname = hostmask;

		senderMutable.isServer = YES;
	}

	senderMutable.hostmask = hostmask;

	/* Process string */
	IRCMessageMutable *inputMutable = [input mutableCopy];

	if ([stringIn hasPrefix:@"is now known as "]) {
		/* Begin nickname change */
		[stringIn deleteCharactersInRange:NSMakeRange(0, (@"is now known as ").length)];

		NSString *newNickname = stringIn.token;

		if (newNickname.length == 0) {
			return input;
		}

		inputMutable.command = IRCPrivateCommandIndex("nick");

		[paramsMutable removeObjectAtIndex:1];

		[paramsMutable addObject:newNickname];
		/* End nickname change */
	}
	else if ([stringIn isEqualToString:@"joined"])
	{
		/* Begin channel join */
		inputMutable.command = IRCPrivateCommandIndex("join");

		[paramsMutable removeObjectAtIndex:1];
		/* End channel join */
	}
	else if ([stringIn hasPrefix:@"set mode: "])
	{
		/* Begin mode processing */
		[stringIn deleteCharactersInRange:NSMakeRange(0, (@"set mode: ").length)];

		NSString *modeChanges = stringIn.token;

		if (modeChanges.length == 0) {
			return input;
		}

		inputMutable.command = IRCPrivateCommandIndex("mode");

		[paramsMutable removeObjectAtIndex:1];

		[paramsMutable addObject:modeChanges];

		[paramsMutable addObject:stringIn];
		/* End mode processing */
	}
	else if ([stringIn hasPrefix:@"quit with message: ["] && [stringIn hasSuffix:@"]"])
	{
		/* Begin quit message */
		[stringIn deleteCharactersInRange:NSMakeRange(0, (@"quit with message: [").length)];	// Remove leading

		[stringIn deleteCharactersInRange:NSMakeRange((stringIn.length - 1), 1)];				// Remove trailing

		inputMutable.command = IRCPrivateCommandIndex("quit");

		[paramsMutable removeObjectAtIndex:1];

		[paramsMutable addObject:stringIn];
		/* End quit message */
	}
	else if ([stringIn hasPrefix:@"parted with message: ["] && [stringIn hasSuffix:@"]"])
	{
		/* Begin part message */
		[stringIn deleteCharactersInRange:NSMakeRange(0, (@"parted with message: [").length)];		// Remove leading

		[stringIn deleteCharactersInRange:NSMakeRange((stringIn.length - 1), 1)];					// Remove trailing

		inputMutable.command = IRCPrivateCommandIndex("part");

		[paramsMutable removeObjectAtIndex:1];

		[paramsMutable addObject:stringIn];
		/* End part message */
	}
	else if ([stringIn hasPrefix:@"kicked "] && [stringIn hasSuffix:@"]"])
	{
		/* Begin kick message */
		[stringIn deleteCharactersInRange:NSMakeRange(0, (@"kicked ").length)];		// Remove leading

		[stringIn deleteCharactersInRange:NSMakeRange((stringIn.length - 1), 1)];	// Remove trailing

		NSString *kickedNickname = stringIn.token;

		if (kickedNickname.length == 0 || [stringIn hasPrefix:@"Reason: ["] == NO) {
			return input;
		}

		[stringIn deleteCharactersInRange:NSMakeRange(0, (@"Reason: [").length)];

		inputMutable.command = IRCPrivateCommandIndex("kick");

		[paramsMutable removeObjectAtIndex:1];

		[paramsMutable addObject:kickedNickname];

		[paramsMutable addObject:stringIn];
		/* End kick message. */
	}
	else if ([stringIn hasPrefix:@"changed the topic to: "])
	{
		/* Begin topic change */
		/* We get the latest topic on join so we tell Textual to ignore this line. */

		return nil;
		/* End topic change */
	}

	/* Return modified input */
	inputMutable.isPrintOnlyMessage = YES;

	inputMutable.params = paramsMutable;

	inputMutable.sender = senderMutable;

	return inputMutable;
}

- (nullable IRCMessage *)interceptServerInput:(IRCMessage *)input for:(IRCClient *)client
{
	if (input.paramsCount != 2) {
		return input;
	}

	if (client.isConnectedToZNC == NO) {
		return input;
	}

	if (NSObjectsAreEqual(input.command, IRCPrivateCommandIndex("privmsg")) == NO) {
		return input;
	}

	IRCPrefix *senderInfo = input.sender;

	NSString *sender = senderInfo.nickname;

	if ([client nickname:sender isZNCUser:@"buffextras"]) {
		return [self interceptBufferExtrasZNCModule:input forClient:client];
	} else if ([client nickname:sender isZNCUser:@"playback"]) {
		return [self interceptBufferExtrasPlaybackModule:input forClient:client];
	}

	return input;
}

#pragma mark -
#pragma mark Private API

- (void)handleIRCSideDisconnect:(IRCClient *)client
{
	for (IRCChannel *channel in client.channelList) {
		if (channel.isActive == NO) {
			continue;
		}

		if ([channel.name hasPrefix:@"~#"]) { // Don't leave internal channels
			continue;
		}

		[channel deactivate];
	}

	[mainWindow() reloadTreeGroup:client];
}

@end

NS_ASSUME_NONNULL_END
