/* ********************************************************************* 
				  _____         _               _
				 |_   _|____  _| |_ _   _  __ _| |
				   | |/ _ \ \/ / __| | | |/ _` | |
				   | |  __/>  <| |_| |_| | (_| | |
				   |_|\___/_/\_\\__|\__,_|\__,_|_|

 Copyright (c) 2010 — 2014 Codeux Software & respective contributors.
     Please see Acknowledgements.pdf for additional information.

 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions
 are met:

    * Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the
      documentation and/or other materials provided with the distribution.
    * Neither the name of Textual and/or Codeux Software, nor the names of 
      its contributors may be used to endorse or promote products derived 
      from this software without specific prior written permission.

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

@implementation IRCAddressBookEntry

- (instancetype)initWithDictionary:(NSDictionary *)dic
{
	if ((self = [super init])) {
		self.itemUUID = [dic objectForKey:@"uniqueIdentifier" orUseDefault:[NSString stringWithUUID]];
		
		self.entryType = [dic integerForKey:@"entryType" orUseDefault:IRCAddressBookIgnoreEntryType];
		
		self.hostmask						= [dic objectForKey:@"hostmask" orUseDefault:nil];
		
		self.notifyJoins					= [dic boolForKey:@"notifyJoins" orUseDefault:NO];
        
		self.ignoreCTCP						= [dic boolForKey:@"ignoreCTCP" orUseDefault:NO];
		self.ignoreJPQE						= [dic boolForKey:@"ignoreJPQE" orUseDefault:NO];
		self.ignoreNotices					= [dic boolForKey:@"ignoreNotices" orUseDefault:NO];
		self.ignorePrivateHighlights		= [dic boolForKey:@"ignorePMHighlights" orUseDefault:NO];
		self.ignorePrivateMessages			= [dic boolForKey:@"ignorePrivateMsg" orUseDefault:NO];
		self.ignorePublicHighlights			= [dic boolForKey:@"ignoreHighlights" orUseDefault:NO];
		self.ignorePublicMessages			= [dic boolForKey:@"ignorePublicMsg" orUseDefault:NO];
		self.ignoreFileTransferRequests		= [dic boolForKey:@"ignoreFileTransferRequests" orUseDefault:NO];
		
		self.hideMessagesContainingMatch	= [dic boolForKey:@"hideMessagesContainingMatch" orUseDefault:NO];

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
	return [[self.hostmask nicknameFromHostmask] lowercaseString];
}

- (void)setHostmask:(NSString *)hostmask
{
	if ([hostmask isEqualToString:_hostmask]) {
		return;
	}

	if (self.entryType == IRCAddressBookUserTrackingEntryType) {
		_hostmask = [hostmask copy];

		self.hostmaskRegex = [NSString stringWithFormat:@"^%@!(.*?)@(.*?)$", hostmask];
	} else {
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

		_hostmask = [hostmask copy];

		self.hostmaskRegex = [NSString stringWithFormat:@"^%@$", new_hostmask];
	}
}

- (NSDictionary *)dictionaryValue
{
	NSMutableDictionary *dic = [NSMutableDictionary dictionary];

	[dic maybeSetObject:self.itemUUID				forKey:@"uniqueIdentifier"];
	[dic maybeSetObject:self.hostmask				forKey:@"hostmask"];

	[dic setInteger:self.entryType					forKey:@"entryType"];

	[dic setBool:self.hideMessagesContainingMatch	forKey:@"hideMessagesContainingMatch"];

	[dic setBool:self.ignoreFileTransferRequests	forKey:@"ignoreFileTransferRequests"];
	[dic setBool:self.ignorePublicMessages			forKey:@"ignorePublicMsg"];
	[dic setBool:self.ignorePrivateMessages			forKey:@"ignorePrivateMsg"];
	[dic setBool:self.ignorePublicHighlights		forKey:@"ignoreHighlights"];
	[dic setBool:self.ignorePrivateHighlights		forKey:@"ignorePMHighlights"];
	[dic setBool:self.ignoreNotices					forKey:@"ignoreNotices"];
	[dic setBool:self.ignoreCTCP					forKey:@"ignoreCTCP"];
	[dic setBool:self.ignoreJPQE					forKey:@"ignoreJPQE"];
    
	[dic setBool:self.notifyJoins				forKey:@"notifyJoins"];
	
	return dic;
}

- (id)copyWithZone:(NSZone *)zone
{
	return [[IRCAddressBookEntry allocWithZone:zone] initWithDictionary:[self dictionaryValue]];
}

@end
