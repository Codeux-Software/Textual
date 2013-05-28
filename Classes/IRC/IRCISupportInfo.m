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

#define _channelUserModeValue		100

@implementation IRCISupportInfo

- (id)init
{
	if ((self = [super init])) {
		[self reset];
	}
	
	return self;
}

- (void)reset
{
    /* Our configuration cache is not used very much throughout Textual, but having it
     part of the source does make future expansion that may require access to it possible. */
    /* Each item of the configuration cache is a dictionary containing key and values for 
     each configuration that was feeded for the line that was parsed then inserted. If a 
     configuration key does not have an actual value, then it is defined as a BOOL, YES. */

    _cachedConfiguration = @[];
    
	self.networkAddress = nil;
	
	self.networkName = nil;
	self.networkNameActual = nil;

	self.channelNamePrefixes = @"#";

	self.nicknameLength = 9; // Default for IRC protocol.
	self.modesCount = TXMaximumNodesPerModeCommand;

	self.userModePrefixes = @{
		@"o" : @"@",
		@"v" : @"+"
	};

	self.channelModes = @{
		@"o" : @(_channelUserModeValue),
		@"v" : @(_channelUserModeValue)
	};
}


- (void)update:(NSString *)configData client:(IRCClient *)client
{
	if ([configData hasSuffix:IRCISupportRawSuffix]) {
		configData = [configData safeSubstringToIndex:(configData.length - IRCISupportRawSuffix.length)];
	}

	NSObjectIsEmptyAssert(configData);

    NSMutableDictionary *cachedConfig = [NSMutableDictionary dictionary];
	
	NSArray *configVariables = [configData split:NSStringWhitespacePlaceholder];
	
	for (NSString *cvar in configVariables) {
		NSString *vakey = cvar;
		NSString *value = nil;
		
		NSRange r = [cvar rangeOfString:@"="];

		if (NSDissimilarObjects(r.location, NSNotFound)) {
			vakey = [cvar safeSubstringToIndex:r.location];
			value = [cvar safeSubstringFromIndex:NSMaxRange(r)];

            [cachedConfig safeSetObject:value forKey:vakey];
		} else {
            [cachedConfig safeSetObject:@(YES) forKey:vakey];
        }
        
		if (value) {
			if ([vakey isEqualIgnoringCase:@"PREFIX"]) {
				[self parsePrefix:value];
			} else if ([vakey isEqualIgnoringCase:@"CHANMODES"]) {
				[self parseChannelModes:value];
			} else if ([vakey isEqualIgnoringCase:@"NICKLEN"]) {
				self.nicknameLength = [value integerValue];
			} else if ([vakey isEqualIgnoringCase:@"MODES"]) {
				self.modesCount = [value integerValue];
			} else if ([vakey isEqualIgnoringCase:@"NETWORK"]) {
				self.networkNameActual = value;
				self.networkName = TXTFLS(@"IRCServerNetworkName", value);
			} else if ([vakey isEqualIgnoringCase:@"CHANTYPES"]) {
				self.channelNamePrefixes = value;
			}
		}

		if ([vakey isEqualIgnoringCase:@"WATCH"]) {
			client.CAPWatchCommand = YES;
		} else if ([vakey isEqualIgnoringCase:@"NAMESX"] && client.CAPmultiPrefix == NO) {
			[client sendLine:@"PROTOCTL NAMESX"];
			
			client.CAPmultiPrefix = YES;
			
			[client.CAPacceptedCaps addObject:@"multi-prefix"];
		} else if ([vakey isEqualIgnoringCase:@"UHNAMES"] && client.CAPuserhostInNames == NO) {
			[client sendLine:@"PROTOCTL UHNAMES"];
			
			client.CAPuserhostInNames = YES;
			
			[client.CAPacceptedCaps addObject:@"userhost-in-names"];
		}
	}

    _cachedConfiguration = [_cachedConfiguration arrayByAddingObject:cachedConfig];
}

- (NSArray *)buildConfigurationRepresentation
{
    /* This takes our cached configuration data and builds it into what it would look like if we
      were to receive an actual 005. The only difference is this method formats each token that
      is in our configuration cache to make them easier to see. We use bold for the tokens. This
      is pretty much only used in developer mode, but it could have other uses? */

    NSObjectIsEmptyAssertReturn(self.cachedConfiguration, nil);

    NSArray *resultArray = @[];

    for (NSDictionary *cachedConfig in self.cachedConfiguration) {
        NSObjectIsEmptyAssertLoopContinue(cachedConfig);

        NSMutableString *cacheString = [NSMutableString string];

        NSArray *sortedKeys = cachedConfig.sortedDictionaryKeys;

        for (NSString *configToken in sortedKeys) {
            /* Does it have value or is it empty? */

            id objectValue = cachedConfig[configToken];

            if ([objectValue isKindOfClass:[NSString class]]) {
                [cacheString appendFormat:@"\002%@\002=%@ ", configToken, objectValue];
            } else {
                [cacheString appendFormat:@"\002%@\002 ", configToken];
            }
        }

        NSObjectIsEmptyAssertLoopContinue(cacheString);

        [cacheString appendString:IRCISupportRawSuffix];

        resultArray = [resultArray arrayByAddingObject:cacheString];
    }

    return resultArray;
}

- (NSArray *)parseMode:(NSString *)modeString
{
	NSMutableArray *modeArray = [NSMutableArray array];
	
	NSMutableString *modeInfo = [modeString mutableCopy];
	
	BOOL beingSet = NO;
	
	while (modeInfo.length >= 1) {
		NSString *token = [modeInfo getToken];

		NSObjectIsEmptyAssertLoopBreak(token);

		NSString *c = [token stringCharacterAtIndex:0];
		
		if ([c isEqualToString:@"+"] || [c isEqualToString:@"-"]) {
			beingSet = [c isEqualToString:@"+"];
			
			token = [token safeSubstringFromIndex:1];
			
			for (NSInteger i = 0; i < token.length; i++) {
				c = [token stringCharacterAtIndex:i];

				if ([c isEqualToString:@"-"]) {
					beingSet = NO;
				} else if ([c isEqualToString:@"+"]) {
					beingSet = YES;
				} else {
					IRCModeInfo *m = [IRCModeInfo modeInfo];

					m.modeToken = c;
					m.modeIsSet = beingSet;
					
					if ([self hasParamForMode:c isSet:beingSet]) {
						m.modeParamater = [modeInfo getToken];
					}

					[modeArray safeAddObject:m];
				}
			}
		}
	}
	
	return modeArray;
}

- (void)parsePrefix:(NSString *)value
{
	// Format: (qaohv)~&@%+

	if ([value contains:@"("] && [value contains:@")"]) {
		NSInteger endSignPos = [value stringPosition:@")"];
		
		NSString *nodes;
		NSString *chars;
		
		nodes = [value safeSubstringToIndex:endSignPos];
		nodes = [nodes safeSubstringFromIndex:1];
		
		chars = [value safeSubstringAfterIndex:endSignPos];

		NSInteger modeLength = nodes.length;
		NSInteger charLength = chars.length;

		NSMutableDictionary *channelModes = [self.channelModes mutableCopy];
		NSMutableDictionary *modePrefixes = [self.userModePrefixes mutableCopy];
		
		if (charLength == modeLength) {
			for (NSInteger i = 0; i < charLength; i++) {
				NSString *modeKey = [nodes stringCharacterAtIndex:i];
				NSString *modeChar = [chars stringCharacterAtIndex:i];

				[modePrefixes setObject:modeChar forKey:modeKey];
				
				[channelModes setInteger:_channelUserModeValue forKey:modeKey];
			}
		}

		self.channelModes = channelModes;
		self.userModePrefixes = modePrefixes;
	}
}

- (BOOL)hasParamForMode:(NSString *)m isSet:(BOOL)modeIsSet
{
	// Input: CHANMODES=A,B,C,D
	//
	// A = Always has a paramater.			Index: 1
	// B = Always has a paramater.			Index: 2
	// C = Only has a paramater when set.	Index: 3
	// D = Never has a paramater.			Index: 4

	NSInteger modeIndex = [self.channelModes integerForKey:m];

	if (modeIndex == 1 || modeIndex == 2 || modeIndex == _channelUserModeValue) {
		return YES;
	} else if (modeIndex == 3) {
		return modeIsSet;
	} else {
		return NO;
	}
}

- (void)parseChannelModes:(NSString *)str
{
	// Input: CHANMODES=A,B,C,D
	//
	// A = Always has a paramater.			Index: 1
	// B = Always has a paramater.			Index: 2
	// C = Only has a paramater when set.	Index: 3
	// D = Never has a paramater.			Index: 4

	NSMutableDictionary *channelModes = [self.channelModes mutableCopy];

	NSArray *allmodes = [str split:@","];

	for (NSInteger i = 0; i < allmodes.count; i++) {
		NSString *modeset = [allmodes safeObjectAtIndex:i];
		
		for (NSInteger j = 0; j < modeset.length; j++) {
			NSString *mode = [modeset stringCharacterAtIndex:j];

			[channelModes setInteger:(i + 1) forKey:mode];
		}
	}

	self.channelModes = channelModes;
}

- (NSString *)userModePrefixSymbol:(NSString *)mode
{
	return [self.userModePrefixes objectForKey:mode];
}

- (BOOL)modeIsSupportedUserPrefix:(NSString *)mode
{
	return NSObjectIsNotEmpty([self userModePrefixSymbol:mode]);
}

- (IRCModeInfo *)createMode:(NSString *)mode
{
	NSObjectIsEmptyAssertReturn(mode, nil);
	
	IRCModeInfo *m = [IRCModeInfo modeInfo];

	m.modeIsSet = NO;
	m.modeParamater = NSStringEmptyPlaceholder;
	m.modeToken = [mode stringCharacterAtIndex:0];
	
	return m;
}

@end
