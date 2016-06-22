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

@interface TDCAddressBookSheet ()
@property (nonatomic, weak) IBOutlet NSButton *ignoreClientToClientProtocolCheck;
@property (nonatomic, weak) IBOutlet NSButton *ignoreFileTransferRequestsCheck;
@property (nonatomic, weak) IBOutlet NSButton *ignoreGeneralEventMessagesCheck;
@property (nonatomic, weak) IBOutlet NSButton *ignoreNoticeMessagesCheck;
@property (nonatomic, weak) IBOutlet NSButton *ignorePrivateMessageHighlightsCheck;
@property (nonatomic, weak) IBOutlet NSButton *ignorePrivateMessagesCheck;
@property (nonatomic, weak) IBOutlet NSButton *ignorePublicMessageHighlightsCheck;
@property (nonatomic, weak) IBOutlet NSButton *ignorePublicMessagesCheck;
@property (nonatomic, weak) IBOutlet NSButton *trackUserActivityCheck;
@property (nonatomic, weak) IBOutlet NSButton *ignoreEntrySaveButton;
@property (nonatomic, weak) IBOutlet NSButton *userTrackingEntrySaveButton;
@property (nonatomic, weak) IBOutlet TVCTextFieldWithValueValidation *ignoreEntryHostmaskTextField;
@property (nonatomic, weak) IBOutlet TVCTextFieldWithValueValidation *userTrackingEntryNicknameTextField;
@property (nonatomic, strong) IBOutlet NSWindow *ignoreEntryView;
@property (nonatomic, strong) IBOutlet NSWindow *userTrackingEntryView;
@end

@implementation TDCAddressBookSheet

- (instancetype)init
{
	if ((self = [super init])) {
		[RZMainBundle() loadNibNamed:@"TDCAddressBookSheet" owner:self topLevelObjects:nil];

		[self buildTextFieldValidationBlocks];
	}

	return self;
}

- (void)buildTextFieldValidationBlocks
{
	/* Define host field for ignore entries. */
	[self.ignoreEntryHostmaskTextField setStringValueIsInvalidOnEmpty:YES];
	[self.ignoreEntryHostmaskTextField setStringValueUsesOnlyFirstToken:YES];
	
	[self.ignoreEntryHostmaskTextField setTextDidChangeCallback:self];

	[self.ignoreEntryHostmaskTextField setValidationBlock:^BOOL(NSString *currentValue) {
		NSString *valueWithoutWildcard = [currentValue stringByReplacingOccurrencesOfString:@"*" withString:@"-"];

		return [valueWithoutWildcard isHostmask];
	}];

	/* Define nickname field for user tracking. */
	[self.userTrackingEntryNicknameTextField setStringValueIsInvalidOnEmpty:YES];
	[self.userTrackingEntryNicknameTextField setStringValueUsesOnlyFirstToken:YES];
	
	[self.userTrackingEntryNicknameTextField setTextDidChangeCallback:self];

	[self.userTrackingEntryNicknameTextField setValidationBlock:^BOOL(NSString *currentValue) {
		return [currentValue isHostmaskNickname];
	}];
}

- (void)validatedTextFieldTextDidChange:(id)sender
{
	/* Enable or disable OK button based on validation. */
	if ([self.ignore entryType] == IRCAddressBookIgnoreEntryType) {
		[self.ignoreEntrySaveButton setEnabled:[self.ignoreEntryHostmaskTextField valueIsValid]];
	} else {
		[self.userTrackingEntrySaveButton setEnabled:[self.userTrackingEntryNicknameTextField valueIsValid]];
	}
}

- (void)start
{
	if ([self.ignore entryType] == IRCAddressBookIgnoreEntryType) {
		[self setSheet:self.ignoreEntryView];

		if ([self.ignore hostmask]) {
			[self.ignoreEntryHostmaskTextField setStringValue:[self.ignore hostmask]];
		}

		[[self sheet] makeFirstResponder:self.ignoreEntryHostmaskTextField];
	} else {
		[self setSheet:self.userTrackingEntryView];

		if ([self.ignore hostmask]) {
			[self.userTrackingEntryNicknameTextField setStringValue:[self.ignore hostmask]];
		}

		[self.sheet makeFirstResponder:self.userTrackingEntryNicknameTextField];
	}

	[self.trackUserActivityCheck				setState:[self.ignore trackUserActivity]];
	
	[self.ignoreClientToClientProtocolCheck		setState:[self.ignore ignoreClientToClientProtocol]];
	[self.ignoreGeneralEventMessagesCheck		setState:[self.ignore ignoreGeneralEventMessages]];
	[self.ignoreFileTransferRequestsCheck		setState:[self.ignore ignoreFileTransferRequests]];
	[self.ignoreNoticeMessagesCheck				setState:[self.ignore ignoreNoticeMessages]];
	[self.ignorePrivateMessageHighlightsCheck	setState:[self.ignore ignorePrivateMessageHighlights]];
	[self.ignorePrivateMessagesCheck			setState:[self.ignore ignorePrivateMessages]];
	[self.ignorePublicMessageHighlightsCheck	setState:[self.ignore ignorePublicMessageHighlights]];
	[self.ignorePublicMessagesCheck				setState:[self.ignore ignorePublicMessages]];
	
	[self startSheet];
}

- (void)ok:(id)sender
{
	if ([self.ignore entryType] == IRCAddressBookIgnoreEntryType) {
		[self.ignore setHostmask:[self.ignoreEntryHostmaskTextField value]];
	} else {
		[self.ignore setHostmask:[self.userTrackingEntryNicknameTextField value]];
	}
	
	[self.ignore setTrackUserActivity:					[self.trackUserActivityCheck state]];
	
	[self.ignore setIgnoreClientToClientProtocol:		[self.ignoreClientToClientProtocolCheck state]];
	[self.ignore setIgnoreFileTransferRequests:			[self.ignoreFileTransferRequestsCheck state]];
	[self.ignore setIgnoreGeneralEventMessages:			[self.ignoreGeneralEventMessagesCheck state]];
	[self.ignore setIgnoreNoticeMessages:				[self.ignoreNoticeMessagesCheck state]];
	[self.ignore setIgnorePrivateMessageHighlights:		[self.ignorePrivateMessageHighlightsCheck state]];
	[self.ignore setIgnorePrivateMessages:				[self.ignorePrivateMessagesCheck state]];
	[self.ignore setIgnorePublicMessageHighlights:		[self.ignorePublicMessageHighlightsCheck state]];
	[self.ignore setIgnorePublicMessages:				[self.ignorePublicMessagesCheck state]];
	
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
