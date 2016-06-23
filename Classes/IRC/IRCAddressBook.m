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

#import "TextualApplication.h"

@implementation IRCAddressBookEntry

NSString * const IRCAddressBookDictionaryValueIgnoreNoticeMessagesKey			= @"ignoreNoticeMessages";
NSString * const IRCAddressBookDictionaryValueIgnorePublicMessagesKey			= @"ignorePublicMessages";
NSString * const IRCAddressBookDictionaryValueIgnorePublicMessageHighlightsKey	= @"ignorePublicMessageHighlights";
NSString * const IRCAddressBookDictionaryValueIgnorePrivateMessagesKey			= @"ignorePrivateMessages";
NSString * const IRCAddressBookDictionaryValueIgnorePrivateMessageHighlightsKey	= @"ignorePrivateMessageHighlights";
NSString * const IRCAddressBookDictionaryValueIgnoreGeneralEventMessagesKey		= @"ignoreGeneralEventMessages";
NSString * const IRCAddressBookDictionaryValueIgnoreFileTransferRequestsKey		= @"ignoreFileTransferRequests";
NSString * const IRCAddressBookDictionaryValueIgnoreClientToClientProtocolKey	= @"ignoreClientToClientProtocol";

NSString * const IRCAddressBookDictionaryValueTrackUserActivityKey				= @"trackUserActivity";

+ (instancetype)newIgnoreEntry
{
	IRCAddressBookEntry *newEntry = [IRCAddressBookEntry new];

	[newEntry setEntryType:IRCAddressBookIgnoreEntryType];

	[newEntry setIgnoreClientToClientProtocol:YES];
	[newEntry setIgnoreFileTransferRequests:YES];
	[newEntry setIgnoreGeneralEventMessages:YES];
	[newEntry setIgnoreNoticeMessages:YES];
	[newEntry setIgnorePrivateMessageHighlights:YES];
	[newEntry setIgnorePrivateMessages:YES];
	[newEntry setIgnorePublicMessageHighlights:YES];
	[newEntry setIgnorePublicMessages:YES];

	[newEntry setTrackUserActivity:NO];

	return newEntry;
}

+ (instancetype)newUserTrackingEntry
{
	IRCAddressBookEntry *newEntry = [IRCAddressBookEntry new];

	[newEntry setEntryType:IRCAddressBookUserTrackingEntryType];

	[newEntry setIgnoreClientToClientProtocol:NO];
	[newEntry setIgnoreFileTransferRequests:NO];
	[newEntry setIgnoreGeneralEventMessages:NO];
	[newEntry setIgnoreNoticeMessages:NO];
	[newEntry setIgnorePrivateMessageHighlights:NO];
	[newEntry setIgnorePrivateMessages:NO];
	[newEntry setIgnorePublicMessageHighlights:NO];
	[newEntry setIgnorePublicMessages:NO];

	[newEntry setTrackUserActivity:YES];

	return newEntry;
}

- (NSDictionary *)defaults
{
	static id _defaults = nil;

	if (_defaults == nil) {
		NSDictionary *defaults = @{
			 @"entryType"							: @(IRCAddressBookIgnoreEntryType),

			 @"trackUserActivity"					: @(NO),

			 @"ignoreClientToClientProtocol"		: @(NO),
			 @"ignoreGeneralEventMessages"			: @(NO),
			 @"ignoreNoticeMessages"				: @(NO),
			 @"ignorePrivateMessages"				: @(NO),
			 @"ignorePrivateMessageHighlights"		: @(NO),
			 @"ignorePublicMessages"				: @(NO),
			 @"ignorePublicMessageHighlights"		: @(NO),
			 @"ignoreFileTransferRequests"			: @(NO),
		 };

		_defaults = [defaults copy];
	}

	return _defaults;
}

- (void)populateDefaults
{
	NSDictionary *defaults = [self defaults];

	self.itemUUID							= [NSString stringWithUUID];

	self.entryType							= [defaults integerForKey:@"entryType"];

	self.trackUserActivity					= [defaults boolForKey:@"trackUserActivity"];

	self.ignoreClientToClientProtocol		= [defaults boolForKey:@"ignoreClientToClientProtocol"];
	self.ignoreFileTransferRequests			= [defaults boolForKey:@"ignoreFileTransferRequests"];
	self.ignoreGeneralEventMessages			= [defaults boolForKey:@"ignoreGeneralEventMessages"];
	self.ignoreNoticeMessages				= [defaults boolForKey:@"ignoreNoticeMessages"];
	self.ignorePrivateMessageHighlights		= [defaults boolForKey:@"ignorePrivateMessageHighlights"];
	self.ignorePrivateMessages				= [defaults boolForKey:@"ignorePrivateMessages"];
	self.ignorePublicMessageHighlights		= [defaults boolForKey:@"ignorePublicMessageHighlights"];
	self.ignorePublicMessages				= [defaults boolForKey:@"ignorePublicMessages"];
}

- (instancetype)init
{
	if ((self = [super init])) {
		[self populateDefaults];
	}

	return self;
}

- (instancetype)initWithDictionary:(NSDictionary *)dic
{
	if ((self = [self init])) {
		[self populateDictionaryValues:dic];
	}

	return self;
}

- (void)populateDictionaryValues:(NSDictionary *)dic
{
	/* With the old keys populated, try to fill in the new ones. */
	[dic assignBoolTo:&_trackUserActivity				forKey:@"trackUserActivity"];

	[dic assignBoolTo:&_ignoreClientToClientProtocol	forKey:@"ignoreClientToClientProtocol"];
	[dic assignBoolTo:&_ignoreFileTransferRequests		forKey:@"ignoreFileTransferRequests"];
	[dic assignBoolTo:&_ignoreGeneralEventMessages		forKey:@"ignoreGeneralEventMessages"];
	[dic assignBoolTo:&_ignoreNoticeMessages			forKey:@"ignoreNoticeMessages"];
	[dic assignBoolTo:&_ignorePrivateMessageHighlights	forKey:@"ignorePrivateMessageHighlights"];
	[dic assignBoolTo:&_ignorePrivateMessages			forKey:@"ignorePrivateMessages"];
	[dic assignBoolTo:&_ignorePublicMessageHighlights	forKey:@"ignorePublicMessageHighlights"];
	[dic assignBoolTo:&_ignorePublicMessages			forKey:@"ignorePublicMessages"];

	[dic assignStringTo:&_itemUUID						forKey:@"uniqueIdentifier"];

	[dic assignUnsignedIntegerTo:&_entryType			forKey:@"entryType"];

	/* First try to assign legacy keys. If these keys do not exist in the
	 dictionary, then there is no sadness in losing them. The new key names
	 will be used in -dictionaryValue after the first pass. */
	[dic assignBoolTo:&_trackUserActivity				forKey:@"notifyJoins"];

	[dic assignBoolTo:&_ignoreClientToClientProtocol	forKey:@"ignoreCTCP"];
	[dic assignBoolTo:&_ignoreGeneralEventMessages		forKey:@"ignoreJPQE"];
	[dic assignBoolTo:&_ignoreNoticeMessages			forKey:@"ignoreNotices"];
	[dic assignBoolTo:&_ignorePrivateMessageHighlights	forKey:@"ignorePMHighlights"];
	[dic assignBoolTo:&_ignorePrivateMessages			forKey:@"ignorePrivateMsg"];
	[dic assignBoolTo:&_ignorePublicMessageHighlights	forKey:@"ignoreHighlights"];
	[dic assignBoolTo:&_ignorePublicMessages			forKey:@"ignorePublicMsg"];

	/* Cannot use assign* on self.hostmask because it uses a custom setter. */
	self.hostmask = [dic objectForKey:@"hostmask" orUseDefault:nil];
}

- (BOOL)checkIgnore:(NSString *)thehost
{
	if (thehost) {
		if (self.hostmaskRegularExpression) {
			return [XRRegularExpression string:thehost isMatchedByRegex:self.hostmaskRegularExpression withoutCase:YES];
		}
	}

	return NO;
}

- (NSString *)trackingNickname
{
	NSString *nickname = [self.hostmask nicknameFromHostmask];

	return [nickname lowercaseString];
}

- (void)setHostmask:(NSString *)hostmask
{
	if ([hostmask isEqualToString:_hostmask]) {
		return; // Do not write out duplicate hostmask.
	}

	if (self.entryType == IRCAddressBookUserTrackingEntryType) {
		_hostmask = [hostmask copy];

		self.hostmaskRegularExpression = [NSString stringWithFormat:@"^%@!(.*?)@(.*?)$", hostmask];
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

		self.hostmaskRegularExpression = [NSString stringWithFormat:@"^%@$", new_hostmask];
	}
}

- (NSDictionary *)dictionaryValue
{
	NSMutableDictionary *dic = [NSMutableDictionary dictionary];

	[dic maybeSetObject:self.itemUUID				forKey:@"uniqueIdentifier"];
	[dic maybeSetObject:self.hostmask				forKey:@"hostmask"];

	[dic setInteger:self.entryType					forKey:@"entryType"];

	[dic setBool:self.ignoreClientToClientProtocol		forKey:@"ignoreClientToClientProtocol"];
	[dic setBool:self.ignoreFileTransferRequests		forKey:@"ignoreFileTransferRequests"];
	[dic setBool:self.ignoreGeneralEventMessages		forKey:@"ignoreGeneralEventMessages"];
	[dic setBool:self.ignoreNoticeMessages				forKey:@"ignoreNoticeMessages"];
	[dic setBool:self.ignorePublicMessages				forKey:@"ignorePublicMessages"];
	[dic setBool:self.ignorePrivateMessages				forKey:@"ignorePrivateMessages"];
	[dic setBool:self.ignorePublicMessageHighlights		forKey:@"ignorePublicMessageHighlights"];
	[dic setBool:self.ignorePrivateMessageHighlights	forKey:@"ignorePrivateMessageHighlights"];
    
	[dic setBool:self.trackUserActivity				forKey:@"trackUserActivity"];

	return [dic dictionaryByRemovingDefaults:[self defaults]];
}

- (id)copyWithZone:(NSZone *)zone
{
	return [[IRCAddressBookEntry allocWithZone:zone] initWithDictionary:[self dictionaryValue]];
}

@end
