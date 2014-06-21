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
	[_ignoreEntryHostmaskField setStringValueIsInvalidOnEmpty:YES];
	[_ignoreEntryHostmaskField setStringValueUsesOnlyFirstToken:YES];
	[_ignoreEntryHostmaskField setTextDidChangeCallback:self];

	[_ignoreEntryHostmaskField setValidationBlock:^BOOL(NSString *currentValue) {
		NSString *valueWithoutWildcard = [currentValue stringByReplacingOccurrencesOfString:@"*" withString:@"-"];

		return [valueWithoutWildcard isHostmask];
	}];

	/* Define nickname field for user tracking. */
	[_userTrackingEntryNicknameField setStringValueIsInvalidOnEmpty:YES];
	[_userTrackingEntryNicknameField setStringValueUsesOnlyFirstToken:YES];
	[_userTrackingEntryNicknameField setTextDidChangeCallback:self];

	[_userTrackingEntryNicknameField setValidationBlock:^BOOL(NSString *currentValue) {
		return [currentValue isNickname];
	}];
}

- (void)validatedTextFieldTextDidChange:(id)sender
{
	/* Enable or disable OK button based on validation. */
	if ([_ignore entryType] == IRCAddressBookIgnoreEntryType) {
		[_ignoreEntrySaveButton setEnabled:[_ignoreEntryHostmaskField valueIsValid]];
	} else {
		[_userTrackingEntrySaveButton setEnabled:[_userTrackingEntryNicknameField valueIsValid]];
	}
}

- (void)start
{
	if ([_ignore entryType] == IRCAddressBookIgnoreEntryType) {
		[self setSheet:_ignoreView];

		if ([_ignore hostmask]) {
			[_ignoreEntryHostmaskField setStringValue:[_ignore hostmask]];
		}

		[[self sheet] makeFirstResponder:_ignoreEntryHostmaskField];
	} else {
		[self setSheet:_notifyView];

		if ([_ignore hostmask]) {
			[_userTrackingEntryNicknameField setStringValue:[_ignore hostmask]];
		}

		[[self sheet] makeFirstResponder:_userTrackingEntryNicknameField];
	}

	[_notifyJoinsCheck					setState:[_ignore notifyJoins]];
	
	[_ignoreCTCPCheck					setState:[_ignore ignoreCTCP]];
	[_ignoreJPQECheck					setState:[_ignore ignoreJPQE]];
	[_ignoreNoticesCheck				setState:[_ignore ignoreNotices]];
	[_ignorePrivateHighlightsCheck		setState:[_ignore ignorePrivateHighlights]];
	[_ignorePrivateMessagesCheck		setState:[_ignore ignorePrivateMessages]];
	[_ignorePublicHighlightsCheck		setState:[_ignore ignorePublicHighlights]];
	[_ignorePublicMessagesCheck			setState:[_ignore ignorePublicMessages]];
	[_ignoreFileTransferRequestsCheck	setState:[_ignore ignoreFileTransferRequests]];

	[_hideInMemberListCheck				setState:[_ignore hideInMemberList]];
	[_hideMessagesContainingMatchCheck	setState:[_ignore hideMessagesContainingMatch]];
	
	[self startSheet];
}

- (void)ok:(id)sender
{
	if ([_ignore entryType] == IRCAddressBookIgnoreEntryType) {
		[_ignore setHostmask:[_ignoreEntryHostmaskField value]];
	} else {
		[_ignore setHostmask:[_userTrackingEntryNicknameField value]];
	}
	
	[_ignore setNotifyJoins:				[_notifyJoinsCheck state]];
	
	[_ignore setIgnoreCTCP:					[_ignoreCTCPCheck state]];
	[_ignore setIgnoreJPQE:					[_ignoreJPQECheck state]];
	[_ignore setIgnoreNotices:				[_ignoreNoticesCheck state]];
	[_ignore setIgnorePrivateHighlights:	[_ignorePrivateHighlightsCheck state]];
	[_ignore setIgnorePrivateMessages:		[_ignorePrivateMessagesCheck state]];
	[_ignore setIgnorePublicHighlights:		[_ignorePublicHighlightsCheck state]];
	[_ignore setIgnorePublicMessages:		[_ignorePublicMessagesCheck state]];
	[_ignore setIgnoreFileTransferRequests:	[_ignoreFileTransferRequestsCheck state]];

	[_ignore setHideInMemberList:				[_hideInMemberListCheck state]];
	[_ignore setHideMessagesContainingMatch:	[_hideMessagesContainingMatchCheck state]];
	
	if ([[self delegate] respondsToSelector:@selector(ignoreItemSheetOnOK:)]) {
		[[self delegate] ignoreItemSheetOnOK:self];
	}
	
	[super ok:nil];
}

#pragma mark -
#pragma mark NSWindow Delegate

- (void)windowWillClose:(NSNotification *)note
{
	if ([[self delegate] respondsToSelector:@selector(ignoreItemSheetWillClose:)]) {
		[[self delegate] ignoreItemSheetWillClose:self];
	}
}

@end
