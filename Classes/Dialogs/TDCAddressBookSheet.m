/* ********************************************************************* 
       _____        _               _    ___ ____   ____
      |_   _|___  _| |_ _   _  __ _| |  |_ _|  _ \ / ___|
       | |/ _ \ \/ / __| | | |/ _` | |   | || |_) | |
       | |  __/>  <| |_| |_| | (_| | |   | ||  _ <| |___
       |_|\___/_/\_\\__|\__,_|\__,_|_|  |___|_| \_\\____|

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

@implementation TDCAddressBookSheet

- (id)init
{
	if ((self = [super init])) {
		[RZMainBundle() loadCustomNibNamed:@"TDCAddressBookSheet" owner:self topLevelObjects:nil];

		[self buildTextFieldValidationBlocks];
	}

	return self;
}

- (void)buildTextFieldValidationBlocks
{
	/* Define host field for ignore entries. */
	[self.ignoreEntryHostmaskField setStringValueIsInvalidOnEmpty:YES];
	[self.ignoreEntryHostmaskField setStringValueUsesOnlyFirstToken:YES];
	[self.ignoreEntryHostmaskField setTextDidChangeCallback:self];

	[self.ignoreEntryHostmaskField setValidationBlock:^BOOL(NSString *currentValue) {
		NSString *valueWithoutWildcard = [currentValue stringByReplacingOccurrencesOfString:@"*" withString:@"-"];

		return [valueWithoutWildcard isHostmask];
	}];

	/* Define nickname field for user tracking. */
	[self.userTrackingEntryNicknameField setStringValueIsInvalidOnEmpty:YES];
	[self.userTrackingEntryNicknameField setStringValueUsesOnlyFirstToken:YES];
	[self.userTrackingEntryNicknameField setTextDidChangeCallback:self];

	[self.userTrackingEntryNicknameField setValidationBlock:^BOOL(NSString *currentValue) {
		return [currentValue isNickname];
	}];
}

- (void)validatedTextFieldTextDidChange:(id)sender
{
	/* Enable or disable OK button based on validation. */
	if (self.ignore.entryType == IRCAddressBookIgnoreEntryType) {
		[self.ignoreEntrySaveButton setEnabled:[self.ignoreEntryHostmaskField valueIsValid]];
	} else {
		[self.userTrackingEntrySaveButton setEnabled:[self.userTrackingEntryNicknameField valueIsValid]];
	}
}

- (void)start
{
	if (self.ignore.entryType == IRCAddressBookIgnoreEntryType) {
		self.sheet = self.ignoreView;

		if (self.ignore.hostmask) {
			[self.ignoreEntryHostmaskField setStringValue:self.ignore.hostmask];
		}

		[self.sheet makeFirstResponder:self.ignoreEntryHostmaskField];
	} else {
		self.sheet = self.notifyView;

		if (self.ignore.hostmask) {
			[self.userTrackingEntryNicknameField setStringValue:self.ignore.hostmask];
		}

		[self.sheet makeFirstResponder:self.userTrackingEntryNicknameField];
	}

	[self.notifyJoinsCheck					setState:self.ignore.notifyJoins];
	
	[self.ignoreCTCPCheck					setState:self.ignore.ignoreCTCP];
	[self.ignoreJPQECheck					setState:self.ignore.ignoreJPQE];
	[self.ignoreNoticesCheck				setState:self.ignore.ignoreNotices];
	[self.ignorePrivateHighlightsCheck		setState:self.ignore.ignorePrivateHighlights];
	[self.ignorePrivateMessagesCheck		setState:self.ignore.ignorePrivateMessages];
	[self.ignorePublicHighlightsCheck		setState:self.ignore.ignorePublicHighlights];
	[self.ignorePublicMessagesCheck			setState:self.ignore.ignorePublicMessages];
	[self.ignoreFileTransferRequestsCheck	setState:self.ignore.ignoreFileTransferRequests];

	[self.hideInMemberListCheck				setState:self.ignore.hideInMemberList];
	[self.hideMessagesContainingMatchCheck	setState:self.ignore.hideMessagesContainingMatch];
	
	[self startSheet];
}

- (void)ok:(id)sender
{
	if (self.ignore.entryType == IRCAddressBookIgnoreEntryType) {
		self.ignore.hostmask = [self.ignoreEntryHostmaskField value];
	} else {
		self.ignore.hostmask = [self.userTrackingEntryNicknameField value];
	}

	self.ignore.notifyJoins					= [self.notifyJoinsCheck state];
	
	self.ignore.ignoreCTCP					= [self.ignoreCTCPCheck state];
	self.ignore.ignoreJPQE					= [self.ignoreJPQECheck state];
	self.ignore.ignoreNotices				= [self.ignoreNoticesCheck state];
	self.ignore.ignorePrivateHighlights		= [self.ignorePrivateHighlightsCheck state];
	self.ignore.ignorePrivateMessages		= [self.ignorePrivateMessagesCheck state];
	self.ignore.ignorePublicHighlights		= [self.ignorePublicHighlightsCheck state];
	self.ignore.ignorePublicMessages		= [self.ignorePublicMessagesCheck state];
	self.ignore.ignoreFileTransferRequests	= [self.ignoreFileTransferRequestsCheck state];

	self.ignore.hideInMemberList			= [self.hideInMemberListCheck state];
	self.ignore.hideMessagesContainingMatch = [self.hideMessagesContainingMatchCheck state];
	
	if ([self.delegate respondsToSelector:@selector(ignoreItemSheetOnOK:)]) {
		[self.delegate ignoreItemSheetOnOK:self];
	}
	
	[super ok:nil];
}

#pragma mark -
#pragma mark NSWindow Delegate

- (void)windowWillClose:(NSNotification *)note
{
	if ([self.delegate respondsToSelector:@selector(ignoreItemSheetWillClose:)]) {
		[self.delegate ignoreItemSheetWillClose:self];
	}
}

@end
