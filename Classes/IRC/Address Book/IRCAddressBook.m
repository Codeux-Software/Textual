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

@implementation IRCAddressBook

- (id)initWithDictionary:(NSDictionary *)dic
{
	if ((self = [super init])) {
		self.itemUUID = NSDictionaryObjectKeyValueCompare(dic, @"uniqueIdentifier", [NSString stringWithUUID]);
		
		self.notifyJoins				= NSDictionaryBOOLKeyValueCompare(dic, @"notifyJoins", NO);
        
		self.ignoreCTCP					= NSDictionaryBOOLKeyValueCompare(dic, @"ignoreCTCP", NO);
		self.ignoreJPQE					= NSDictionaryBOOLKeyValueCompare(dic, @"ignoreJPQE", NO);
		self.ignoreNotices				= NSDictionaryBOOLKeyValueCompare(dic, @"ignoreNotices", NO);
		self.ignorePrivateHighlights	= NSDictionaryBOOLKeyValueCompare(dic, @"ignorePMHighlights", NO);
		self.ignorePrivateMessages		= NSDictionaryBOOLKeyValueCompare(dic, @"ignorePrivateMsg", NO);
		self.ignorePublicHighlights		= NSDictionaryBOOLKeyValueCompare(dic, @"ignoreHighlights", NO);
		self.ignorePublicMessages		= NSDictionaryBOOLKeyValueCompare(dic, @"ignorePublicMsg", NO);

		/* entryType must be set above hostmask since setHostmask: reads entryType. */
		self.entryType = NSDictionaryIntegerKeyValueCompare(dic, @"entryType", IRCAddressBookIgnoreEntryType);

		self.hostmask = NSDictionaryObjectKeyValueCompare(dic, @"hostmask", nil);

		return self;
	}

	return nil;
}

- (BOOL)checkIgnore:(NSString *)thehost
{
	if (self.hostmaskRegex && thehost) {
        return [TLORegularExpression string:thehost isMatchedByRegex:self.hostmaskRegex withoutCase:YES];
	}

	return NO;
}

- (NSString *)trackingNickname
{
	return [self.hostmask nicknameFromHostmask];
}

- (void)setHostmask:(NSString *)hostmask
{
	if ([hostmask isEqualToString:self.hostmask]) {
		return;
	}

	if (self.entryType == IRCAddressBookUserTrackingEntryType) {
        hostmask = [hostmask nicknameFromHostmask];
        
		if ([hostmask isNickname]) {
            _hostmask = hostmask;

			self.hostmaskRegex = [NSString stringWithFormat:@"^%@!(.*?)@(.*?)$", hostmask];
		}
	} else {
		/* Make valid hostmask. */
		
		if ([hostmask contains:@"@"] == NO) {
			hostmask = [hostmask stringByAppendingString:@"@*"];
		} 
		
		NSRange atsrange = [hostmask rangeOfString:@"@" options:NSBackwardsSearch];
		
		if (hostmask.length > 2) {
			NSString *first = [hostmask safeSubstringToIndex:atsrange.location];
			NSString *second = [hostmask safeSubstringAfterIndex:atsrange.location];
			
			if (NSObjectIsEmpty(first)) {
				first = @"*";
			}
			
			if ([first contains:@"!"] == NO) {
				hostmask = [NSString stringWithFormat:@"%@!*@%@", first, second];
			}
		}
		
		/* There probably is an easier way to escape characters before making
		 our regular expression, but let us do it the hard way instead. More fun. */
		
		NSString *new_hostmask = hostmask;
		
		new_hostmask = [new_hostmask stringByReplacingOccurrencesOfString:@"\\" withString:@"\\\\"];
		new_hostmask = [new_hostmask stringByReplacingOccurrencesOfString:@"{" withString:@"\\{"];
		new_hostmask = [new_hostmask stringByReplacingOccurrencesOfString:@"}" withString:@"\\}"];
		new_hostmask = [new_hostmask stringByReplacingOccurrencesOfString:@")" withString:@"\\)"];
		new_hostmask = [new_hostmask stringByReplacingOccurrencesOfString:@"(" withString:@"\\("];
		new_hostmask = [new_hostmask stringByReplacingOccurrencesOfString:@"]" withString:@"\\]"];
		new_hostmask = [new_hostmask stringByReplacingOccurrencesOfString:@"[" withString:@"\\["];
		new_hostmask = [new_hostmask stringByReplacingOccurrencesOfString:@"^" withString:@"\\^"];
		new_hostmask = [new_hostmask stringByReplacingOccurrencesOfString:@"|" withString:@"\\|"];
		new_hostmask = [new_hostmask stringByReplacingOccurrencesOfString:@"~" withString:@"\\~"];
		new_hostmask = [new_hostmask stringByReplacingOccurrencesOfString:@"*" withString:@"(.*?)"];

		_hostmask = hostmask;
		
		self.hostmaskRegex = [NSString stringWithFormat:@"^%@$", new_hostmask];
	}
}

- (NSDictionary *)dictionaryValue
{
	NSMutableDictionary *dic = [NSMutableDictionary dictionary];

	[dic safeSetObject:self.itemUUID forKey:@"uniqueIdentifier"];
	[dic safeSetObject:self.hostmask forKey:@"hostmask"];

	[dic setInteger:self.entryType forKey:@"entryType"];
	
	[dic setBool:self.ignorePublicMessages		forKey:@"ignorePublicMsg"];
	[dic setBool:self.ignorePrivateMessages		forKey:@"ignorePrivateMsg"];
	[dic setBool:self.ignorePublicHighlights	forKey:@"ignoreHighlights"];
	[dic setBool:self.ignorePrivateHighlights	forKey:@"ignorePMHighlights"];
	[dic setBool:self.ignoreNotices				forKey:@"ignoreNotices"];
	[dic setBool:self.ignoreCTCP				forKey:@"ignoreCTCP"];
	[dic setBool:self.ignoreJPQE				forKey:@"ignoreJPQE"];
    
	[dic setBool:self.notifyJoins				forKey:@"notifyJoins"];
	
	return dic;
}

- (id)mutableCopyWithZone:(NSZone *)zone
{
	return [[IRCAddressBook allocWithZone:zone] initWithDictionary:[self dictionaryValue]];
}

@end
