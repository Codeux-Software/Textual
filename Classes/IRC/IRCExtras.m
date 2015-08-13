/* ********************************************************************* 
                  _____         _               _
                 |_   _|____  _| |_ _   _  __ _| |
                   | |/ _ \ \/ / __| | | |/ _` | |
                   | |  __/>  <| |_| |_| | (_| | |
                   |_|\___/_/\_\\__|\__,_|\__,_|_|

 Copyright (c) 2008 - 2010 Satoshi Nakagawa <psychs AT limechat DOT net>
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

@implementation IRCExtras

+ (void)parseIRCProtocolURI:(NSString *)location
{
	[self parseIRCProtocolURI:location withDescriptor:nil];
}

+ (void)parseIRCProtocolURI:(NSString *)location withDescriptor:(NSAppleEventDescriptor *)event
{
	NSObjectIsEmptyAssert(location);

	/* Basic input clean up. */
	NSString *locationValue = location;

	locationValue = [locationValue decodeURIFragment];
	locationValue = [locationValue trim];

	/* We will scan our input to look for each slash in it.
	 There is supposed to be one (minus the scheme), so let's
	 hope there is, but just incase, count the slashes in our
	 entire input. We need two for the scheme and one to
	 seperate the channel name from the server name. If there
	 is more than three, then our input is already invalid and
	 we do not want to go any further with it. */
	NSArray *slashMatches = [XRRegularExpression matchesInString:locationValue withRegex:@"([/])"];

	if (NSNumberInRange([slashMatches count], 2, 3) == NO) {
		return;
	}

	/* Now that we have established that our input is valid in a
	 very basic way; we move on to doing more work on it. The next
	 step will be to seperate the sections of the one slash dividing
	 the channel list from that of the server address and port. After
	 they are seperated, we will run the server address section through
	 NSURL. If NSURL does not result in a valid result, then we can
	 consider the beginning of our URL trash and invalid. */
	NSString *serverInfo = locationValue;
	NSString *channelInfo = nil;

	if ([slashMatches count] == 3) { // Only cut if we do have an extra slash.
		NSRange backwardRange = [locationValue rangeOfString:@"/" options:NSBackwardsSearch];

		if (NSDissimilarObjects(backwardRange.location, NSNotFound)) {
			serverInfo = [locationValue substringToIndex:backwardRange.location];

			channelInfo = [locationValue substringAfterIndex:backwardRange.location];
		}
	}

	/* We now have each section of the URL in its own store so time
	 to run the first section through NSURL to see if it returns a
	 valid scheme and host. */
	NSURL *baseURL = [NSURL URLWithString:serverInfo];

	NSString *serverAddress = [baseURL host];
	NSString *addressScheme = [baseURL scheme];

	/* 
	 Reserved space checks. Textual has for sometime supported the
	 textual:// scheme, but until now it has done nothing except mimic
	 irc:// — it now has a purpose. A quicker way to access resources. 
	 
	 These can prove to be very helpful in #textual 
	 
	 Syntax: textual://<token> 
	 
	 Reserved tokens:

		 acknowledgements					— Open acknowledgements file.
		 appstore-page						— Open our Mac App Store page.
		 contributors						— Open contributors file. 
		 diagnostic-reports-folder			— System diagnostic reports folder.
		 custom-style-folder				— Open the custom style storage location folder.
		 icloud-style-folder				— Open the custom style storage location folder.
		 custom-styles-folder				— Same as custom-style-folder except plural.
		 icloud-styles-folder				— Same as custom-style-folder except plural.
		 newsletter							— Open the subscription page for the newsletter.
		 support-channel					— Connect to the #textual channel.
		 testing-channel					— Connect to the #textual-testing channel.
		 unsupervised-script-folder			— Open the unsupervised scripts folder.
		 unsupervised-scripts-folder		— Same as unsupervised-script-folder except plural.
		 knowledge-base						— Open the homepage of our knowledge base.
	 */

	if ([addressScheme isEqualToString:@"textual"]) {
		if ([serverAddress isEqualToString:@"acknowledgements"])
		{
			[menuController() showAcknowledgments:nil];
		}
		else if ([serverAddress isEqualToString:@"appstore-page"])
		{
			[menuController() openMacAppStoreDownloadPage:nil];
		}
		else if ([serverAddress isEqualToString:@"contributors"])
		{
			[menuController() showAcknowledgments:nil];
		}
		else if ([serverAddress isEqualToString:@"custom-style-folder"] ||
				 [serverAddress isEqualToString:@"custom-styles-folder"])
		{
			[RZWorkspace() openFile:[TPCPathInfo customThemeFolderPath]];
		}
		else if ([serverAddress isEqualToString:@"newsletter"])
		{
			[TLOpenLink openWithString:@"https://www.codeux.com/textual/newsletter/"];
		}
		else if ([serverAddress isEqualToString:@"diagnostic-reports-folder"])
		{
			[RZWorkspace() openFile:[TPCPathInfo localUserDiagnosticReportsFolderPath]];
			[RZWorkspace() openFile:[TPCPathInfo systemDiagnosticReportsFolderPath]];
		}
		else if ([serverAddress isEqualToString:@"support-channel"])
		{
			[menuController() connectToTextualHelpChannel:nil];
		}
		else if ([serverAddress isEqualToString:@"testing-channel"])
		{
			[menuController() connectToTextualTestingChannel:nil];
		}
		else if ([serverAddress isEqualToString:@"icloud-style-folder"] ||
				 [serverAddress isEqualToString:@"icloud-styles-folder"])
		{
#if TEXTUAL_BUILT_WITH_ICLOUD_SUPPORT == 1
			[TPCPathInfo openCloudCustomThemeFolder];
#endif
		}
		else if ([serverAddress isEqualToString:@"unsupervised-script-folder"] ||
				 [serverAddress isEqualToString:@"unsupervised-scripts-folder"])
		{
			[RZWorkspace() openFile:[TPCPathInfo systemUnsupervisedScriptFolderPath]];
		}
		else if ([serverAddress isEqualToString:@"knowledge-base"])
		{
			[TLOpenLink openWithString:@"https://www.codeux.com/textual/help/"];
		}

		return;
	}

	/* Continue normal parsing... */
	NSNumber *serverPort = [baseURL port];

	if (serverPort == nil) {
		serverPort = @(IRCConnectionDefaultServerPort);
	}

	__block BOOL connectionUsesSSL = NO;

	NSObjectIsEmptyAssert(serverAddress);
	NSObjectIsEmptyAssert(addressScheme);

	if ([addressScheme isEqualToString:@"ircs"]) {
		connectionUsesSSL = YES;
	}

	/* If we have made it to this point without this method returning,
	 then everything is going smooth so far. We have established our
	 server address, the URL scheme, and associated channel information. */

	/* We will now parse the actual channel information. */
	/* This method does not actually create the connection. It only formats 
	 the input so that another can. Therefore, we do not have to take much 
	 care with the channel information. Just a basic parse to establish if 
	 the "needssl" token is present as well as the channel name having a 
	 pound (#) sign in front of it. */
	NSMutableString *channelList = [NSMutableString string];

	if (channelInfo) {
		NSArray *dataSections = [channelInfo split:@","];

		[dataSections enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
			if (idx > 4) {
				*stop = YES;
				
				return;
			} else {
				BOOL isLastObject = ((idx + 1) == [dataSections count]);
				
				if ([obj isEqualIgnoringCase:@"needssl"] && isLastObject) {
					connectionUsesSSL = YES;
				} else {
					NSString *objcopy = [obj copy];
					
					if ([objcopy hasPrefix:@"#"] == NO) {
						objcopy = [@"#" stringByAppendingString:objcopy];
					}
					
					if ([objcopy isChannelName]) {
						[channelList appendString:objcopy];
						[channelList appendString:@","];
					}
				}
			}
		}];

		/* Erase end commas. */
		[channelList deleteCharactersInRange:NSMakeRange(([channelList length] - 1), 1)];
	}

	/* We have parsed every part of our URL. Build the final result and
	 pass it along. We are done here. */
	NSMutableString *finalResult = [NSMutableString string];

	if (connectionUsesSSL) {
		[finalResult appendString:@"-SSL "];
	}

	[finalResult appendFormat:@"%@:%@", serverAddress, serverPort];

	/* A URL is consider untrusted and will not auto connect. */
	[IRCExtras createConnectionAndJoinChannel:finalResult channel:channelList autoConnect:NO];
}

+ (void)createConnectionAndJoinChannel:(NSString *)serverInfo channel:(NSString *)channelList autoConnect:(BOOL)autoConnect
{
	[self createConnectionAndJoinChannel:serverInfo channel:channelList autoConnect:autoConnect focusChannel:NO];
}

+ (void)createConnectionAndJoinChannel:(NSString *)serverInfo channel:(NSString *)channelList autoConnect:(BOOL)autoConnect focusChannel:(BOOL)focusChannel
{
	NSObjectIsEmptyAssert(serverInfo);

	/* Establish our variables. */
	NSInteger serverPort = IRCConnectionDefaultServerPort;

	NSString *serverAddress = nil;
	NSString *serverPassword = nil;

    BOOL connectionUsesSSL = NO;

	/* Begin parsing. */
	NSMutableString *base = [serverInfo mutableCopy];

	/* Get our first token. A token is everything before
	 the first occurrence of a space character. getToken
	 will get everything before a space in a string, then
	 erase the remaining content of that string so that
	 each call to getToken gives us the next section
	 of our string. */
	NSString *tempStore = [base getToken];

    /* Secure Socket Layer? */
    if ([tempStore isEqualIgnoringCase:@"-SSL"]) {
        connectionUsesSSL = YES;

		/* If the SSL define was our first token, we
		 go to our next token. */
        tempStore = [base getToken];
    }

    /* Server Address. */
	BOOL hasOpeningBracket = [tempStore hasPrefix:@"["];
	BOOL hasClosingBracket = [tempStore contains:@"]"];

    if (hasOpeningBracket && hasClosingBracket) {
		/* Get address from inside brackets. */
		NSInteger startPos = ([tempStore stringPosition:@"["] + 1);
		NSInteger srendPos =  [tempStore stringPosition:@"]"];

		NSRange servRange = NSMakeRange(startPos, (srendPos - startPos));

		serverAddress = [tempStore substringWithRange:servRange];

		tempStore = [tempStore substringAfterIndex:srendPos];
    } else {
		if (hasOpeningBracket == NO && hasClosingBracket == NO) {
			/* Our server address did not contain brackets. Does it
			 contain a colon (:) which means a port is included? */

			if ([tempStore contains:@":"]) {
				NSInteger cutPos = [tempStore stringPosition:@":"];

				serverAddress = [tempStore substringToIndex:cutPos];

				/* We cut the server address out of our temporary store,
				 but left the colon and everything after it, in it. */
				tempStore = [tempStore substringFromIndex:cutPos];
			} else {
				serverAddress = tempStore;
			}
		} else {
			/* If we have a opening bracket but no closing or any
			 combination of the two, then return this method as our
			 server address is already invalid. If there were not
			 brackets either, then we are not treating the server
			 as an IPv4 address so any colon will be considered
			 for port use only. */

			return;
		}
	}

    /* Server Port */
    if ([tempStore hasPrefix:@":"]) {
        NSInteger chopIndex = 1;

		/* Does the port define an SSL connection? */
        if ([tempStore hasPrefix:@":+"]) {
            chopIndex = 2;

            connectionUsesSSL = YES;
        }

        tempStore = [tempStore substringFromIndex:chopIndex];

		/* Make sure the port number matches a valid format. If it does,
		 then we are all good, and done with the port. */
        if ([XRRegularExpression string:tempStore isMatchedByRegex:@"^([0-9]{1,6})$"]) {
            serverPort = [tempStore integerValue];
        }
    } else {
		/* If our temporary store did not have a colon in front of it indicating
		 a port, then we get our next token and see if that will parse correctly. */
        if (NSObjectIsNotEmpty(base)) {
            tempStore = [base getToken];

            if ([XRRegularExpression string:tempStore isMatchedByRegex:@"^(\\+?[0-9]{1,6})$"]) {
                if ([tempStore hasPrefix:@"+"]) {
                    tempStore = [tempStore substringFromIndex:1];

                    connectionUsesSSL = YES;
                }

				/* Looks like our token gave us a valid port. */
				serverPort = [tempStore integerValue];
            }
        }
    }

    /* Server Password. */
	/* If our base is still not empty after taking out the token for the
	 server address and port, then we are going to treat that as the server
	 password. Anything after this token will be ignored completely. */
    if (NSObjectIsNotEmpty(base)) {
        tempStore = [base getToken];
        
        serverPassword = tempStore;
    }
    
    /* Add Server. */
	NSObjectIsEmptyAssert(serverAddress);
	
	IRCClientConfig *baseConfig = [IRCClientConfig new];

	[baseConfig setConnectionName:serverAddress];
	
	[baseConfig setServerAddress:serverAddress];
	[baseConfig setServerPort:serverPort];

	[baseConfig setPrefersSecuredConnection:connectionUsesSSL];
	
	if ([channelList length] > 0) {
		NSMutableArray *channels = [NSMutableArray array];
		
		NSArray *chunks = [channelList split:@","];
			
		for (NSString *cc in chunks) {
			[channels addObject:[IRCChannelConfig seedWithName:[cc trim]]];
		}

		[baseConfig setChannelList:channels];
	}
	
	if (serverPassword) {
		[baseConfig setServerPassword:serverPassword];
		
		[baseConfig writeServerPasswordKeychainItemToDisk];
	}

	/* Feed the world our seed and finish up. */
	IRCClient *uf = [worldController() createClient:baseConfig reload:YES];
	
	[worldController() save];

	if (autoConnect) {
		[uf connect];
	}

	/* Focus the newly added connection? */
	if (focusChannel) {
		[uf selectFirstChannelInChannelList];
	}
}

@end
