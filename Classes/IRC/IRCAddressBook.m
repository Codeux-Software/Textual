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

#import "NSObjectHelperPrivate.h"
#import "NSStringHelper.h"
#import "IRCAddressBookInternal.h"

NS_ASSUME_NONNULL_BEGIN

@implementation IRCAddressBookEntry

NSString * const IRCAddressBookDictionaryValueEntryTypeKey						= @"entryType";

NSString * const IRCAddressBookDictionaryValueIgnoreNoticeMessagesKey			= @"ignoreNoticeMessages";
NSString * const IRCAddressBookDictionaryValueIgnorePublicMessagesKey			= @"ignorePublicMessages";
NSString * const IRCAddressBookDictionaryValueIgnorePublicMessageHighlightsKey	= @"ignorePublicMessageHighlights";
NSString * const IRCAddressBookDictionaryValueIgnorePrivateMessagesKey			= @"ignorePrivateMessages";
NSString * const IRCAddressBookDictionaryValueIgnorePrivateMessageHighlightsKey	= @"ignorePrivateMessageHighlights";
NSString * const IRCAddressBookDictionaryValueIgnoreGeneralEventMessagesKey		= @"ignoreGeneralEventMessages";
NSString * const IRCAddressBookDictionaryValueIgnoreFileTransferRequestsKey		= @"ignoreFileTransferRequests";
NSString * const IRCAddressBookDictionaryValueIgnoreClientToClientProtocolKey	= @"ignoreClientToClientProtocol";

NSString * const IRCAddressBookDictionaryValueTrackUserActivityKey				= @"trackUserActivity";

- (void)populateDefaultsPreflight
{
	ObjectIsAlreadyInitializedAssert

	self->_defaults = @{
	  @"entryType" : @(IRCAddressBookIgnoreEntryType),
	  @"ignoreClientToClientProtocol" : @(NO),
	  @"ignoreFileTransferRequests"	: @(NO),
	  @"ignoreGeneralEventMessages"	: @(NO),
	  @"ignoreNoticeMessages" : @(NO),
	  @"ignorePrivateMessageHighlights" : @(NO),
	  @"ignorePrivateMessages" : @(NO),
	  @"ignorePublicMessageHighlights" : @(NO),
	  @"ignorePublicMessages" : @(NO),
	  @"trackUserActivity" : @(NO)
	};
}

- (void)populateDefaultsPostflight
{
	ObjectIsAlreadyInitializedAssert

	SetVariableIfNil(self->_hostmask, @"")
	SetVariableIfNil(self->_hostmaskRegularExpression, @"")

	SetVariableIfNil(self->_uniqueIdentifier, [NSString stringWithUUID])
}

+ (instancetype)newIgnoreEntry
{
	return [self newIgnoreEntryForHostmask:nil];
}

+ (instancetype)newIgnoreEntryForHostmask:(nullable NSString *)hostmask
{
	if (hostmask == nil) {
		hostmask = @"";
	}

	NSDictionary *dic = @{
		@"hostmask" : hostmask,
		IRCAddressBookDictionaryValueEntryTypeKey : @(IRCAddressBookIgnoreEntryType),
		IRCAddressBookDictionaryValueIgnoreNoticeMessagesKey : @(YES),
		IRCAddressBookDictionaryValueIgnorePublicMessagesKey : @(YES),
		IRCAddressBookDictionaryValueIgnorePublicMessageHighlightsKey : @(YES),
		IRCAddressBookDictionaryValueIgnorePrivateMessagesKey : @(YES),
		IRCAddressBookDictionaryValueIgnorePrivateMessageHighlightsKey : @(YES),
		IRCAddressBookDictionaryValueIgnoreGeneralEventMessagesKey : @(YES),
		IRCAddressBookDictionaryValueIgnoreFileTransferRequestsKey : @(YES),
		IRCAddressBookDictionaryValueIgnoreClientToClientProtocolKey : @(YES),
	};

	IRCAddressBookEntry *object = [[self alloc] initWithDictionary:dic];

	return object;
}

+ (instancetype)newUserTrackingEntry
{
	NSDictionary *dic = @{
		IRCAddressBookDictionaryValueEntryTypeKey : @(IRCAddressBookUserTrackingEntryType),
		IRCAddressBookDictionaryValueTrackUserActivityKey : @(YES)
	};

	IRCAddressBookEntry *object = [[self alloc] initWithDictionary:dic];

	return object;
}

DESIGNATED_INITIALIZER_EXCEPTION_BODY_BEGIN
- (instancetype)init
{
	ObjectIsAlreadyInitializedAssert

	if ((self = [super init])) {
		[self populateDefaultsPreflight];

		[self populateDefaultsPostflight];

		[self rebuildCache];

		self->_objectInitialized = YES;

		return self;
	}

	return nil;
}
DESIGNATED_INITIALIZER_EXCEPTION_BODY_END

- (instancetype)initWithDictionary:(NSDictionary<NSString *, id> *)dic
{
	ObjectIsAlreadyInitializedAssert

	if ((self = [super init])) {
		[self populateDefaultsPreflight];

		[self populateDictionaryValues:dic];

		[self populateDefaultsPostflight];

		[self rebuildCache];

		self->_objectInitialized = YES;

		return self;
	}

	return nil;
}

- (void)populateDictionaryValues:(NSDictionary<NSString *, id> *)dic
{
	NSParameterAssert(dic != nil);

	if ([self isMutable] == NO) {
		ObjectIsAlreadyInitializedAssert
	}

	NSMutableDictionary<NSString *, id> *defaultsMutable = [self->_defaults mutableCopy];

	[defaultsMutable addEntriesFromDictionary:dic];

	[dic assignUnsignedIntegerTo:&self->_entryType forKey:@"entryType"];

	if (self->_entryType == IRCAddressBookIgnoreEntryType) {
		/* Load the newest set of keys */
		[dic assignBoolTo:&self->_ignoreClientToClientProtocol forKey:@"ignoreClientToClientProtocol"];
		[dic assignBoolTo:&self->_ignoreFileTransferRequests forKey:@"ignoreFileTransferRequests"];
		[dic assignBoolTo:&self->_ignoreGeneralEventMessages forKey:@"ignoreGeneralEventMessages"];
		[dic assignBoolTo:&self->_ignoreNoticeMessages forKey:@"ignoreNoticeMessages"];
		[dic assignBoolTo:&self->_ignorePrivateMessageHighlights forKey:@"ignorePrivateMessageHighlights"];
		[dic assignBoolTo:&self->_ignorePrivateMessages forKey:@"ignorePrivateMessages"];
		[dic assignBoolTo:&self->_ignorePublicMessageHighlights forKey:@"ignorePublicMessageHighlights"];
		[dic assignBoolTo:&self->_ignorePublicMessages forKey:@"ignorePublicMessages"];

		/* Load legacy keys (if they exist) */
		[dic assignBoolTo:&self->_ignoreClientToClientProtocol forKey:@"ignoreCTCP"];
		[dic assignBoolTo:&self->_ignoreGeneralEventMessages forKey:@"ignoreJPQE"];
		[dic assignBoolTo:&self->_ignoreNoticeMessages forKey:@"ignoreNotices"];
		[dic assignBoolTo:&self->_ignorePrivateMessageHighlights forKey:@"ignorePMHighlights"];
		[dic assignBoolTo:&self->_ignorePrivateMessages forKey:@"ignorePrivateMsg"];
		[dic assignBoolTo:&self->_ignorePublicMessageHighlights forKey:@"ignoreHighlights"];
		[dic assignBoolTo:&self->_ignorePublicMessages forKey:@"ignorePublicMsg"];
	}
	else if (self->_entryType == IRCAddressBookUserTrackingEntryType)
	{
		/* Load the newest set of keys */
		[dic assignBoolTo:&self->_trackUserActivity forKey:@"trackUserActivity"];

		/* Load legacy keys (if they exist) */
		[dic assignBoolTo:&self->_trackUserActivity forKey:@"notifyJoins"];
	}

	[dic assignStringTo:&self->_hostmask forKey:@"hostmask"];
	[dic assignStringTo:&self->_uniqueIdentifier forKey:@"uniqueIdentifier"];
}

- (void)rebuildCache
{
	[self rebuildHostmaskRegularExpression];

	[self rebuildTrackingNickname];
}

- (void)rebuildHostmaskRegularExpression
{
	NSString *hostmask = self.hostmask;

	if (self.entryType == IRCAddressBookIgnoreEntryType) {
		hostmask = [hostmask stringByReplacingOccurrencesOfString:@"\\" withString:@"\\\\"];
		hostmask = [hostmask stringByReplacingOccurrencesOfString:@"{" withString:@"\\{"];
		hostmask = [hostmask stringByReplacingOccurrencesOfString:@"}" withString:@"\\}"];
		hostmask = [hostmask stringByReplacingOccurrencesOfString:@")" withString:@"\\)"];
		hostmask = [hostmask stringByReplacingOccurrencesOfString:@"(" withString:@"\\("];
		hostmask = [hostmask stringByReplacingOccurrencesOfString:@"]" withString:@"\\]"];
		hostmask = [hostmask stringByReplacingOccurrencesOfString:@"[" withString:@"\\["];
		hostmask = [hostmask stringByReplacingOccurrencesOfString:@"^" withString:@"\\^"];
		hostmask = [hostmask stringByReplacingOccurrencesOfString:@"|" withString:@"\\|"];
		hostmask = [hostmask stringByReplacingOccurrencesOfString:@"~" withString:@"\\~"];
		hostmask = [hostmask stringByReplacingOccurrencesOfString:@"*" withString:@"(.*?)"];
	} else if (self.entryType == IRCAddressBookUserTrackingEntryType) {
		hostmask = [NSString stringWithFormat:@"^%@!(.*?)@(.*?)$", hostmask];
	}

	self->_hostmaskRegularExpression = [hostmask copy];
}

- (void)rebuildTrackingNickname
{
	if (self.entryType != IRCAddressBookUserTrackingEntryType) {
		return;
	}

	NSString *hostmask = self.hostmask;

	hostmask = hostmask.nicknameFromHostmask;

	self->_trackingNickname = [hostmask copy];
}

- (BOOL)checkMatch:(NSString *)hostmask
{
	NSParameterAssert(hostmask != nil);

	return [XRRegularExpression string:hostmask isMatchedByRegex:self.hostmaskRegularExpression withoutCase:YES];
}

- (NSDictionary<NSString *, id> *)dictionaryValue
{
	NSMutableDictionary<NSString *, id> *dic = [NSMutableDictionary dictionary];

	[dic maybeSetObject:self.hostmask forKey:@"hostmask"];
	[dic maybeSetObject:self.uniqueIdentifier forKey:@"uniqueIdentifier"];

	if (self.entryType == IRCAddressBookIgnoreEntryType)
	{
		[dic setBool:self.ignoreClientToClientProtocol forKey:@"ignoreClientToClientProtocol"];
		[dic setBool:self.ignoreFileTransferRequests forKey:@"ignoreFileTransferRequests"];
		[dic setBool:self.ignoreGeneralEventMessages forKey:@"ignoreGeneralEventMessages"];
		[dic setBool:self.ignoreMessagesContainingMatch forKey:@"ignoreMessagesContainingMatch"];
		[dic setBool:self.ignoreNoticeMessages forKey:@"ignoreNoticeMessages"];
		[dic setBool:self.ignorePrivateMessageHighlights forKey:@"ignorePrivateMessageHighlights"];
		[dic setBool:self.ignorePrivateMessages forKey:@"ignorePrivateMessages"];
		[dic setBool:self.ignorePublicMessageHighlights forKey:@"ignorePublicMessageHighlights"];
		[dic setBool:self.ignorePublicMessages forKey:@"ignorePublicMessages"];
	}
	else if (self.entryType == IRCAddressBookUserTrackingEntryType)
	{
		[dic setBool:self.trackUserActivity forKey:@"trackUserActivity"];
	}

	[dic setUnsignedInteger:self.entryType forKey:@"entryType"];

	return [dic dictionaryByRemovingDefaults:self->_defaults];
}

- (id)copyWithZone:(nullable NSZone *)zone
{
	  IRCAddressBookEntry *object =
	[[IRCAddressBookEntry alloc] initWithDictionary:[self dictionaryValue]];

	return object;
}

- (id)mutableCopyWithZone:(nullable NSZone *)zone
{
	  IRCAddressBookEntryMutable *object =
	[[IRCAddressBookEntryMutable alloc] initWithDictionary:[self dictionaryValue]];

	return object;
}

- (id)uniqueCopy
{
	return [self uniqueCopyAsMutable:NO];
}

- (id)uniqueCopyMutable
{
	return [self uniqueCopyAsMutable:YES];
}

- (id)uniqueCopyAsMutable:(BOOL)asMutable
{
	IRCAddressBookEntry *object = nil;

	if (asMutable == NO) {
		object = [self copy];
	} else {
		object = [self mutableCopy];
	}

	object->_uniqueIdentifier = [NSString stringWithUUID];

	return object;
}

- (BOOL)isMutable
{
	return NO;
}

@end

#pragma mark -

@implementation IRCAddressBookEntryMutable

@dynamic entryType;
@dynamic hostmask;
@dynamic ignoreClientToClientProtocol;
@dynamic ignoreFileTransferRequests;
@dynamic ignoreGeneralEventMessages;
@dynamic ignoreMessagesContainingMatch;
@dynamic ignoreNoticeMessages;
@dynamic ignorePrivateMessageHighlights;
@dynamic ignorePrivateMessages;
@dynamic ignorePublicMessageHighlights;
@dynamic ignorePublicMessages;
@dynamic trackUserActivity;

- (BOOL)isMutable
{
	return YES;
}

- (void)setEntryType:(IRCAddressBookEntryType)entryType
{
	if (self->_entryType != entryType) {
		self->_entryType = entryType;

		[self rebuildCache];
	}
}

- (void)setHostmask:(NSString *)hostmask
{
	NSParameterAssert(hostmask != nil);

	if (self->_hostmask != hostmask) {
		self->_hostmask = [hostmask copy];

		[self rebuildCache];
	}
}

- (void)setIgnoreClientToClientProtocol:(BOOL)ignoreClientToClientProtocol
{
	if (self->_ignoreClientToClientProtocol != ignoreClientToClientProtocol) {
		self->_ignoreClientToClientProtocol = ignoreClientToClientProtocol;
	}
}

- (void)setIgnoreFileTransferRequests:(BOOL)ignoreFileTransferRequests
{
	if (self->_ignoreFileTransferRequests != ignoreFileTransferRequests) {
		self->_ignoreFileTransferRequests = ignoreFileTransferRequests;
	}
}

- (void)setIgnoreGeneralEventMessages:(BOOL)ignoreGeneralEventMessages
{
	if (self->_ignoreGeneralEventMessages != ignoreGeneralEventMessages) {
		self->_ignoreGeneralEventMessages = ignoreGeneralEventMessages;
	}
}

- (void)setIgnoreNoticeMessages:(BOOL)ignoreNoticeMessages
{
	if (self->_ignoreNoticeMessages != ignoreNoticeMessages) {
		self->_ignoreNoticeMessages = ignoreNoticeMessages;
	}
}

- (void)setIgnorePrivateMessageHighlights:(BOOL)ignorePrivateMessageHighlights
{
	if (self->_ignorePrivateMessageHighlights != ignorePrivateMessageHighlights) {
		self->_ignorePrivateMessageHighlights = ignorePrivateMessageHighlights;
	}
}

- (void)setIgnorePrivateMessages:(BOOL)ignorePrivateMessages
{
	if (self->_ignorePrivateMessages != ignorePrivateMessages) {
		self->_ignorePrivateMessages = ignorePrivateMessages;
	}
}

- (void)setIgnorePublicMessageHighlights:(BOOL)ignorePublicMessageHighlights
{
	if (self->_ignorePublicMessageHighlights != ignorePublicMessageHighlights) {
		self->_ignorePublicMessageHighlights = ignorePublicMessageHighlights;
	}
}

- (void)setIgnorePublicMessages:(BOOL)ignorePublicMessages
{
	if (self->_ignorePublicMessages != ignorePublicMessages) {
		self->_ignorePublicMessages = ignorePublicMessages;
	}
}

- (void)setTrackUserActivity:(BOOL)trackUserActivity
{
	if (self->_trackUserActivity != trackUserActivity) {
		self->_trackUserActivity = trackUserActivity;
	}
}

@end

NS_ASSUME_NONNULL_END
