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

@implementation IRCAddressBook

- (id)initWithDictionary:(NSDictionary *)dic
{
	if ((self = [super init])) {
		self.cid = (([dic integerForKey:@"cid"]) ?: TXRandomNumber(9999));
		
		self.hostmask = dic[@"hostmask"];
		
		self.ignorePublicMsg	= [dic boolForKey:@"ignorePublicMsg"];
		self.ignorePrivateMsg	= [dic boolForKey:@"ignorePrivateMsg"];
		self.ignoreHighlights	= [dic boolForKey:@"ignoreHighlights"];
		self.ignoreNotices		= [dic boolForKey:@"ignoreNotices"];
		self.ignoreCTCP			= [dic boolForKey:@"ignoreCTCP"];
		self.ignoreJPQE			= [dic boolForKey:@"ignoreJPQE"];
		self.notifyJoins		= [dic boolForKey:@"notifyJoins"];
		self.ignorePMHighlights	= [dic boolForKey:@"ignorePMHighlights"];
		
		self.entryType = (IRCAddressBookEntryType)[dic integerForKey:@"entryType"];
		
		[self processHostMaskRegex];

		return self;
	}

	return nil;
}

- (void)processHostMaskRegex
{
	if (self.entryType == IRCAddressBookUserTrackingEntryType) {
		NSString *nickname = [self trackingNickname];
		
		self.hostmaskRegex = nil;
		self.hostmask = nil;
		
		self.hostmask	  = nickname;
		self.hostmaskRegex = [NSString stringWithFormat:@"^%@!(.*?)@(.*?)$", nickname];
	} else {
		if (NSObjectIsEmpty(self.hostmaskRegex)) {
			NSString *nhostmask = self.hostmask;
			
			if ([nhostmask contains:@"@"] == NO) {
				nhostmask = [nhostmask stringByAppendingString:@"@*"];
			} 
			
			NSRange atsrange = [nhostmask rangeOfString:@"@" options:NSBackwardsSearch];
			
			if ([nhostmask length] >= 2) {
				NSString *first = [nhostmask safeSubstringToIndex:atsrange.location];
				NSString *second = [nhostmask safeSubstringFromIndex:(atsrange.location + 1)];
				
				if (NSObjectIsEmpty(first)) {
					first = @"*";
				}
				
				if ([first contains:@"!"] == NO) {
					nhostmask = [NSString stringWithFormat:@"%@!*@%@", first, second];
				}
			}
			
			if (NSDissimilarObjects(self.hostmask, nhostmask)) {
				self.hostmask = nhostmask;
			}
			
			/* There probably is an easier way to escape characters before making
			 our regular expression, but let us do it the hard way instead. More fun. */
			
			NSString *new_hostmask = self.hostmask;
			
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
			
			self.hostmaskRegex = nil;
			self.hostmaskRegex = [NSString stringWithFormat:@"^%@$", new_hostmask];
		}
	}
}

- (NSDictionary *)dictionaryValue
{
	NSMutableDictionary *dic = [NSMutableDictionary dictionary];
	
	dic[@"hostmask"] = self.hostmask;
	
	[dic setBool:self.ignorePublicMsg		forKey:@"ignorePublicMsg"];
	[dic setBool:self.ignorePrivateMsg		forKey:@"ignorePrivateMsg"];
	[dic setBool:self.ignoreHighlights		forKey:@"ignoreHighlights"];
	[dic setBool:self.ignorePMHighlights	forKey:@"ignorePMHighlights"];
	[dic setBool:self.ignoreNotices			forKey:@"ignoreNotices"];
	[dic setBool:self.ignoreCTCP			forKey:@"ignoreCTCP"];
	[dic setBool:self.ignoreJPQE			forKey:@"ignoreJPQE"];
	[dic setBool:self.notifyJoins			forKey:@"notifyJoins"];
	
	[dic setInteger:self.entryType			forKey:@"entryType"];
	[dic setInteger:self.cid				forKey:@"cid"];
	
	return dic;
}

- (BOOL)checkIgnore:(NSString *)thehost
{
	if (self.hostmaskRegex && thehost) {
        return [TLORegularExpression string:thehost
						  isMatchedByRegex:self.hostmaskRegex
							   withoutCase:YES];
	}
	
	return NO;
}

- (NSString *)trackingNickname
{
	return [self.hostmask nicknameFromHostmask];
}

@end