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

@implementation IRCExtras

+ (void)parseIRCProtocolURI:(NSString *)location
{
	NSObjectIsEmptyAssert(location);

	/* Basic input clean up. */
    location = [location decodeURIFragement];
	location = [location trim];

	/* We will scan our input to look for each slash in it.
	 There is supposed to be one (minus the scheme), so let's
	 hope there is, but just incase, count the slashes in our
	 entire input. We need two for the scheme and one to
	 seperate the channel name from the server name. If there
	 is more than three, then our input is already invalid and
	 we do not want to go any further with it. */

	NSArray *slashMatches = [TLORegularExpression matchesInString:location withRegex:@"([/])"];

	if (NSNumberInRange(slashMatches.count, 2, 3) == NO) {
		return;
	}

	/* Now that we have established that our input is valid in a
	 very basic way; we move on to doing more work on it. The next
	 step will be to seperate the sections of the one slash dividing
	 the channel list from that of the server address and port. After
	 they are seperated, we will run the server address section through
	 NSURL. If NSURL does not result in a valid result, then we can
	 consider the beginning of our URL trash and invalid. */

	NSString *serverInfo = location;
	NSString *channelInfo = nil;

	if (slashMatches.count == 3) { // Only cut if we do have an extra slash.
		NSRange backwardRange = [location rangeOfString:@"/" options:NSBackwardsSearch];

		if (NSDissimilarObjects(backwardRange.location, NSNotFound)) {
			serverInfo = [location safeSubstringToIndex:backwardRange.location];
			channelInfo = [location safeSubstringAfterIndex:backwardRange.location];
		}
	}

	/* We now have each section of the URL in its own store so time
	 to run the first section through NSURL to see if it returns a
	 valid scheme and host. */

	NSURL *baseURL = [NSURL URLWithString:serverInfo];

	NSString *serverAddress = [baseURL host];
	NSString *addressScheme = [baseURL scheme];

	NSNumber *serverPort = [baseURL port];

	if (PointerIsEmpty(serverPort)) {
		serverPort = @(IRCConnectionDefaultServerPort);
	}

	BOOL connectionUsesSSL = NO;

	NSObjectIsEmptyAssert(serverAddress);
	NSObjectIsEmptyAssert(addressScheme);

	if ([addressScheme isEqualToString:@"ircs"]) {
		connectionUsesSSL = YES;
	}

	/* If we have made it to this point without this method returning,
	 then everything is going smooth so far. We have established our
	 server address, the URL scheme, and associated channel information. */

	/* We will now parse the actual channel information. */
	/* As mentioned in the comment block above, this method does not
	 actually create the connection. It only formats the input so that
	 another can. Therefore, we do not have to take much care with the
	 channel information. Just a basic parse to establish if the "needssl"
	 token is present as well as the channel name having a pound (#) sign
	 in front of it. */

	NSMutableString *channelList = [NSMutableString string];

	if (NSObjectIsNotEmpty(channelInfo)) {
		NSInteger channelCount = 0;

		NSArray *dataSections = [channelInfo split:@","];

		NSString *lastObject = dataSections.lastObject;

		for (__strong NSString *dataValue in dataSections) {
			NSAssertReturnLoopBreak(channelCount < 5);

			BOOL isLastObject = [dataValue isEqualToString:lastObject];

			if ([dataValue isEqualIgnoringCase:@"needssl"] && isLastObject) {
				connectionUsesSSL = YES;
			} else {
				if ([dataValue isChannelName] == NO) {
					dataValue = [@"#" stringByAppendingString:dataValue];
				}

				[channelList appendString:dataValue];
				[channelList appendString:@","];
			}

			channelCount += 1;
		}

		/* Erase end commas. */
		[channelList deleteCharactersInRange:NSMakeRange((channelList.length - 1), 1)];
	}

	/* We have parsed every part of our URL. Build the final result and
	 pass it along. We are done here. */

	NSString *finalResult = NSStringEmptyPlaceholder;

	if (connectionUsesSSL) {
		finalResult = @"-SSL ";
	}

	finalResult = [finalResult stringByAppendingFormat:@"%@:%@", serverAddress, serverPort];

	/* A URL is consider untrusted and will not auto connect. */
	[IRCExtras createConnectionAndJoinChannel:finalResult channel:channelList autoConnect:NO];
}

+ (void)createConnectionAndJoinChannel:(NSString *)serverInfo channel:(NSString *)channelList autoConnect:(BOOL)autoConnect
{
	NSObjectIsEmptyAssert(serverInfo);

	/* Establish our variables. */
	NSInteger serverPort = IRCConnectionDefaultServerPort;

	NSString *serverAddress = nil;
	NSString *serverPassword = nil;

    BOOL connectionUsesSSL = NO;

	/* Begin parsing. */
	NSString *tempStore = nil;

    NSMutableString *base = [serverInfo mutableCopy];

	/* Get our first token. A token is everything before
	 the first occurrence of a space character. getToken
	 will get everything before a space in a string, then
	 erase the remaining content of that string so that
	 each call to getToken gives us the next section
	 of our string. */
    tempStore = [base getToken];

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

		serverAddress = [tempStore safeSubstringWithRange:servRange];

		tempStore = [tempStore safeSubstringAfterIndex:srendPos];
    } else {
		if (hasOpeningBracket == NO && hasClosingBracket == NO) {
			/* Our server address did not contain brackets. Does it
			 contain a colon (:) which means a port is included? */

			if ([tempStore contains:@":"]) {
				NSInteger cutPos = [tempStore stringPosition:@":"];

				serverAddress = [tempStore safeSubstringToIndex:cutPos];

				/* We cut the server address out of our temporary store,
				 but left the colon and everything after it, in it. */
				tempStore = [tempStore safeSubstringFromIndex:cutPos];
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

        tempStore = [tempStore safeSubstringFromIndex:chopIndex];

		/* Make sure the port number matches a valid format. If it does,
		 then we are all good, and done with the port. */
        if ([TLORegularExpression string:tempStore isMatchedByRegex:@"^([0-9]{1,6})$"]) {
            serverPort = [tempStore integerValue];
        }
    } else {
		/* If our temporary store did not have a colon in front of it indicating
		 a port, then we get our next token and see if that will parse correctly. */
        if (NSObjectIsNotEmpty(base)) {
            tempStore = [base getToken];

            if ([TLORegularExpression string:tempStore isMatchedByRegex:@"^(\\+?[0-9]{1,6})$"]) {
                if ([tempStore hasPrefix:@"+"]) {
                    tempStore = [tempStore safeSubstringFromIndex:1];

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
    
	NSMutableDictionary *dic = [NSMutableDictionary dictionary];
	
	dic[@"serverAddress"] = serverAddress;
	dic[@"connectionName"] = serverAddress;

	dic[@"serverPort"]		= @(serverPort);
	dic[@"connectOnLaunch"] = @(autoConnect);
	dic[@"connectUsingSSL"]	= @(connectionUsesSSL);
	
	NSMutableArray *channels = [NSMutableArray array];
	
	NSArray *chunks = [channelList split:@","];
		
	for (NSString *cc in chunks) {
		[channels safeAddObject:[IRCChannelConfig seedDictionary:cc.trim]];
	}

	dic[@"channelList"] = channels;

	/* Migration Assistant Dictionary Addition. */
	[dic safeSetObject:TPCPreferencesMigrationAssistantUpgradePath
				forKey:TPCPreferencesMigrationAssistantVersionKey];

	/* Feed the world our seed and finish up. */
	IRCClient *uf = [[self worldController] createClient:dic reload:YES];

	if (NSObjectIsNotEmpty(serverPassword)) {
		[uf.config setServerPassword:serverPassword];
	}
	
	[[self worldController] save];

	if (autoConnect) {
		[uf connect];
	}
}

@end
