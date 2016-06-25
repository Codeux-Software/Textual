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

#import "TPI_ZNCAdditions.h"

#import "TVCMainWindowPrivate.h"

@implementation TPI_ZNCAdditions

#pragma mark -
#pragma mark Plugin API

- (void)didReceiveServerInput:(THOPluginDidReceiveServerInputConcreteObject *)inputObject onClient:(IRCClient *)client
{
	if ([client isZNCBouncerConnection]) {
		NSString *sender = [inputObject senderNickname];

		NSString *message = [inputObject messageSequence];

		if ([sender isEqualToString:@"*status"] && [message hasPrefix:@"Disconnected from IRC"]) {
			/* We listen for ZNC disconnects so that we can terminate channels when we
			 disconnect from the server ZNC was connected to. ZNC does not localize 
			 itself so detecting these disconnects is not very hard... */

			/* handleIRCSideDisconnect: calls -deactivate on IRCChannel. That call in 
			 IRCChannel posts a script event to the active style. Therefore, we have to
			 invoke the calls on the main thread because WebKit is not thread safe. */
			[self performBlockOnMainThread:^{
				[self handleIRCSideDisconnect:client];
			}];
		}
	}
}

- (void)userInputCommandInvokedOnClient:(IRCClient *)client
						  commandString:(NSString *)commandString
						  messageString:(NSString *)messageString
{
	/* Throw error if user tries to invoke a command that requires the
	 user to be connected to a ZNC bouncer */
	if ([client isZNCBouncerConnection] == NO) {
		[client printDebugInformation:TPILocalizedString(@"BasicLanguage[1000]")];

		return;
	}

	/* Process commands */
	if ([commandString isEqualIgnoringCase:@"ZNCCERT"])
	{
		/* Textual is designed not to import partial content. It will either
		 return the complete certificate chain at this point, or nil. */
		NSData *certificateData = [client zncBouncerCertificateChainData];

		if (certificateData == nil) {
			[client printDebugInformation:TPILocalizedString(@"BasicLanguage[1003]")];

			return;
		}

		/* Given the raw, base64 encoded data, convert it into certificate objects. */
		SecItemImportExportKeyParameters importParameters;

		importParameters.version = SEC_KEY_IMPORT_EXPORT_PARAMS_VERSION;
		importParameters.flags = kSecKeyNoAccessControl;

		importParameters.passphrase = NULL;
		importParameters.alertTitle = NULL;
		importParameters.alertPrompt = NULL;
		importParameters.accessRef = NULL;

		importParameters.keyUsage = NULL;
		importParameters.keyAttributes = NULL;

		SecExternalItemType itemType = kSecItemTypeCertificate;

		SecExternalFormat externalFormat = kSecFormatPEMSequence;

		int flags = 0;

		CFArrayRef certificateArray = NULL;

		OSStatus operationStatus =
		SecItemImport((__bridge CFDataRef)(certificateData), NULL, &externalFormat, &itemType, flags, &importParameters, NULL, &certificateArray);

		/* Display an error or hand the certificate chain off to Apple's own
		 APIs to display them in a dialog. */
		if (operationStatus == noErr) {
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
		} else {
			[client printDebugInformation:TPILocalizedString(@"BasicLanguage[1004]")];
		}
	}

	/* ------ */

	else if ([commandString isEqualIgnoringCase:@"DETACH"] ||
			 [commandString isEqualIgnoringCase:@"ATTACH"])
	{
		BOOL isDetach = [commandString isEqualIgnoringCase:@"DETACH"];
		BOOL isAttach = [commandString isEqualIgnoringCase:@"ATTACH"];

		messageString = [messageString trim];
		
		IRCChannel *matchedChannel = nil;
		
		if ([messageString isChannelNameOn:client]) {
			matchedChannel = [client findChannel:messageString];
		} else {
			matchedChannel = [mainWindow() selectedChannel];
		}
		
		if (matchedChannel) {
			[[matchedChannel config] setAutoJoin:isAttach];
			
			if (isDetach) {
				[client sendLine:[NSString stringWithFormat:@"%@ %@", commandString, [matchedChannel name]]];
			
				[client printDebugInformation:TPILocalizedString(@"BasicLanguage[1001]", [matchedChannel name]) channel:matchedChannel];
			} else {
				[client joinUnlistedChannel:[matchedChannel name]];
			}
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

- (IRCMessage *)interceptBufferExtrasPlaybackModule:(IRCMessage *)input senderInfo:(IRCPrefix *)senderInfo client:(IRCClient *)client
{
	NSString *s = [input paramAt:1];

	if ([s hasPrefix:@"The playback buffer for ["]		&&
		[s contains:@"] channels matching ["]			&& // This is much cleaner than regular expression...
		[s hasSuffix:@"] has been cleared."])
	{
		return nil; // Ignore this event
	}
	
	return input;
}

- (IRCMessage *)interceptBufferExtrasZNCModule:(IRCMessage *)input senderInfo:(IRCPrefix *)senderInfo client:(IRCClient *)client
{
	/* Begin processing data. */
	NSMutableArray *mutparams = [[input params] mutableCopy];
	
	NSMutableString *s = [mutparams[1] mutableCopy];
	
	/* Define user information. */
	NSString *hostmask = [s getToken];
	
	if ([hostmask length] <= 0) {
		return input;
	}
	
	NSString *nicknameInt = nil;
	NSString *usernameInt = nil;
	NSString *addressInt = nil;
	
	if ([hostmask hostmaskComponents:&nicknameInt username:&usernameInt address:&addressInt onClient:client]) {
		if (NSObjectsAreEqual(nicknameInt, [client localNickname])) {
			return nil; // Do not post these events for self.
		}

		[senderInfo setNickname:nicknameInt];
		[senderInfo setUsername:usernameInt];
		[senderInfo setAddress:addressInt];
	} else {
		[senderInfo setNickname:hostmask];
		
		[senderInfo setIsServer:YES];
	}

	[senderInfo setHostmask:hostmask];

	[senderInfo setIsServer:NO];
	
	/* Let Textual know to treat this message as a special event. */
	[input setIsPrintOnlyMessage:YES];
	
	/* Start actual work. */
	if ([s hasPrefix:@"is now known as "]) {
		/* Begin nickname change. */
		[s deleteCharactersInRange:NSMakeRange(0, [@"is now known as " length])];
		
		NSString *newNickname = [s getToken];
		
		NSObjectIsEmptyAssertReturn(newNickname, input);
		
		[input setCommand:IRCPrivateCommandIndex("nick")];
		
		[mutparams removeObjectAtIndex:1];
		
		[mutparams addObject:newNickname];
		/* End nickname change. */
	}
	else if ([s isEqualToString:@"joined"])
	{
		/* Begin channel join. */
		[input setCommand:IRCPrivateCommandIndex("join")];
		
		[mutparams removeObjectAtIndex:1];
		/* End channel join. */
	}
	else if ([s hasPrefix:@"set mode: "])
	{
		/* Begin mode processing. */
		[s deleteCharactersInRange:NSMakeRange(0, [@"set mode: " length])];
		
		[input setCommand:IRCPrivateCommandIndex("mode")];
		
		NSString *modesSet = [s getToken];
		
		NSObjectIsEmptyAssertReturn(modesSet, input);
		
		[mutparams removeObjectAtIndex:1];
		
		[mutparams addObject:modesSet];
		[mutparams addObject:s];
		/* End mode processing. */
	}
	else if ([s hasPrefix:@"quit with message: ["] && [s hasSuffix:@"]"])
	{
		/* Begin quit message. */
		[s deleteCharactersInRange:NSMakeRange(0, [@"quit with message: [" length])];	// Remove front.
		[s deleteCharactersInRange:NSMakeRange(([s length] - 1), 1)];					// Remove trailing character.
		
		[input setCommand:IRCPrivateCommandIndex("quit")];
		
		[mutparams removeObjectAtIndex:1];
		
		[mutparams addObject:s];
		/* End quit message. */
	}
	else if ([s hasPrefix:@"parted with message: ["] && [s hasSuffix:@"]"])
	{
		/* Begin part message. */
		[s deleteCharactersInRange:NSMakeRange(0, [@"parted with message: [" length])];		// Remove front.
		[s deleteCharactersInRange:NSMakeRange(([s length] - 1), 1)];						// Remove trailing character.
		
		[input setCommand:IRCPrivateCommandIndex("part")];
		
		[mutparams removeObjectAtIndex:1];
		
		[mutparams addObject:s];
		/* End part message. */
	}
	else if ([s hasPrefix:@"kicked "] && [s hasSuffix:@"]"])
	{
		/* Begin kick message. */
		[s deleteCharactersInRange:NSMakeRange(0, [@"kicked " length])];	// Remove front.
		[s deleteCharactersInRange:NSMakeRange(([s length] - 1), 1)];		// Remove trailing character.
		
		NSString *whoKicked = [s getToken];
		
		if (NSObjectIsEmpty(whoKicked) || [s hasPrefix:@"Reason: ["] == NO) {
			return input;
		}
		
		[s deleteCharactersInRange:NSMakeRange(0, [@"Reason: [" length])];
		
		[input setCommand:IRCPrivateCommandIndex("kick")];
		
		[mutparams removeObjectAtIndex:1];
		
		[mutparams addObject:whoKicked];
		[mutparams addObject:s];
		/* End kick message. */
	}
	else if ([s hasPrefix:@"changed the topic to: "])
	{
		/* Begin topic change. */
		/* We get the latest topic on join so we tell Textual to ignore this line. */
		
		return nil;
		/* End topic change. */
	}
	
	[input setParams:mutparams];
	
	return input;
}

- (IRCMessage *)interceptServerInput:(IRCMessage *)input for:(IRCClient *)client
{
	/* Only do work if client is even detected as ZNC. */
	if ([client isZNCBouncerConnection] == NO) {
		return input;
	}
	
	/* What type of message is this person sending? */
	if (NSObjectsAreEqual([input command], IRCPrivateCommandIndex("privmsg")) == NO) {
		return input;
	}
	
	/* Check our count. */
	if (([input paramsCount] == 2) == NO) {
		return input;
	}
	
	/* Who is sending this message? */
	IRCPrefix *senderInfo = [input sender];
	
	NSString *senderNickname = [senderInfo nickname];
	
	if (NSObjectsAreEqual(senderNickname, [client nicknameWithZNCUserPrefix:@"buffextras"])) {
		return [self interceptBufferExtrasZNCModule:input senderInfo:senderInfo client:client];
	} else if (NSObjectsAreEqual(senderNickname, [client nicknameWithZNCUserPrefix:@"playback"])) {
		if ([client isCapacityEnabled:ClientIRCv3SupportedCapacityZNCPlaybackModule]) {
			return [self interceptBufferExtrasPlaybackModule:input senderInfo:senderInfo client:client];
		} else {
			return input;
		}
	} else {
		return input;
	}
}

#pragma mark -
#pragma mark Private API

- (void)handleIRCSideDisconnect:(IRCClient *)client
{
	for (IRCChannel *c in [client channelList]) {
		NSAssertReturnLoopContinue( [c isActive]);
        NSAssertReturnLoopContinue([[c name] hasPrefix:@"~#"] == NO);
		
        [c deactivate];
	}

	[mainWindow() reloadTreeGroup:client];
}

@end
