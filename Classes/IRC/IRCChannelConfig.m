/* ********************************************************************* 
       _____        _               _    ___ ____   ____
      |_   _|___  _| |_ _   _  __ _| |  |_ _|  _ \ / ___|
       | |/ _ \ \/ / __| | | |/ _` | |   | || |_) | |
       | |  __/>  <| |_| |_| | (_| | |   | ||  _ <| |___
       |_|\___/_/\_\\__|\__,_|\__,_|_|  |___|_| \_\\____|

 Copyright (c) 2010 — 2012 Codeux Software & respective contributors.
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

@implementation IRCChannelConfig

- (id)init
{
	if ((self = [super init])) {
		self.guid = [NSString stringWithUUID];

		self.type = IRCChannelNormalType;
		
        self.ignoreInlineImages	= NO;
        self.ignoreJPQActivity	= NO;
        self.ignoreHighlights	= NO;
		self.autoJoin			= YES;
		self.growl				= YES;
		
		self.name			= NSStringEmptyPlaceholder;
		self.mode			= NSStringEmptyPlaceholder;
		self.topic			= NSStringEmptyPlaceholder;
		self.password		= NSStringEmptyPlaceholder;
		self.encryptionKey	= NSStringEmptyPlaceholder;
	}
    
	return self;
}

- (id)initWithDictionary:(NSDictionary *)dic
{
	if ((self = [self init])) {
		dic = [TPCPreferencesMigrationAssistant convertIRCChannelConfiguration:dic];

		self.type			= (IRCChannelType)[dic integerForKey:@"channelType"];

		self.guid			= (([dic stringForKey:@"uniqueIdentifier"]) ?: self.guid);
		
		self.name			= (([dic stringForKey:@"channelName"])	 ?: NSStringEmptyPlaceholder);
		self.password		= (([dic stringForKey:@"secretJoinKey"]) ?: NSStringEmptyPlaceholder);
		
		self.growl				= [dic boolForKey:@"enableNotifications"];
		self.autoJoin			= [dic boolForKey:@"joinOnConnect"];
		self.ignoreHighlights	= [dic boolForKey:@"ignoreHighlights"];
		self.ignoreInlineImages	= [dic boolForKey:@"disableInlineMedia"];
		self.ignoreJPQActivity	= [dic boolForKey:@"ignoreJPQActivity"];
		
		self.mode			= (([dic stringForKey:@"defaultMode"])		?: NSStringEmptyPlaceholder);
		self.topic			= (([dic stringForKey:@"defaultTopic"])		?: NSStringEmptyPlaceholder);
		self.encryptionKey	= (([dic stringForKey:@"encryptionKey"])	?: NSStringEmptyPlaceholder);
		
		return self;
	}
	
	return nil;
}

- (NSMutableDictionary *)dictionaryValue
{
	NSMutableDictionary *dic = [NSMutableDictionary dictionary];
	
	[dic setInteger:self.type forKey:@"channelType"];
	
	[dic setBool:self.growl					forKey:@"enableNotifications"];
	[dic setBool:self.autoJoin				forKey:@"joinOnConnect"];
    [dic setBool:self.ignoreHighlights		forKey:@"ignoreHighlights"];
    [dic setBool:self.ignoreInlineImages	forKey:@"disableInlineMedia"];
    [dic setBool:self.ignoreJPQActivity		forKey:@"ignoreJPQActivity"];

	[dic safeSetObject:self.guid				forKey:@"uniqueIdentifier"];
	[dic safeSetObject:self.name				forKey:@"channelName"];
	[dic safeSetObject:self.password			forKey:@"secretJoinKey"];
	[dic safeSetObject:self.mode				forKey:@"defaultMode"];
	[dic safeSetObject:self.topic				forKey:@"defaultTopic"];
	[dic safeSetObject:self.encryptionKey		forKey:@"encryptionKey"];
	
	/* Migration Assistant Dictionary Addition. */
	[dic safeSetObject:TPCPreferencesMigrationAssistantUpgradePath
				forKey:TPCPreferencesMigrationAssistantVersionKey];
	
	return [dic sortedDictionary];
}

- (id)mutableCopyWithZone:(NSZone *)zone
{
	return [[IRCChannelConfig allocWithZone:zone] initWithDictionary:[self dictionaryValue]];
}

@end