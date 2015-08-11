/* ********************************************************************* 
                  _____         _               _
                 |_   _|____  _| |_ _   _  __ _| |
                   | |/ _ \ \/ / __| | | |/ _` | |
                   | |  __/>  <| |_| |_| | (_| | |
                   |_|\___/_/\_\\__|\__,_|\__,_|_|

 Copyright (c) 2008 - 2010 Satoshi Nakagawa <psychs AT limechat DOT net>
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

@interface TDCServerChangeNicknameSheet ()
@property (nonatomic, weak) IBOutlet TVCTextFieldWithValueValidation *tnewNicknameTextField;
@property (nonatomic, weak) IBOutlet NSTextField *toldNicknameTextField;
@end

@implementation TDCServerChangeNicknameSheet

- (instancetype)init
{
	if ((self = [super init])) {
		[RZMainBundle() loadNibNamed:@"TDCServerChangeNicknameSheet" owner:self topLevelObjects:nil];
	}

	return self;
}

- (void)start:(NSString *)nickname
{
	/* Define nickname field for user tracking. */
	[self.tnewNicknameTextField setStringValueIsInvalidOnEmpty:YES];
	[self.tnewNicknameTextField setStringValueUsesOnlyFirstToken:YES];
	
	[self.tnewNicknameTextField setOnlyShowStatusIfErrorOccurs:YES];
	
	[self.tnewNicknameTextField setTextDidChangeCallback:self];
	
	[self.tnewNicknameTextField setValidationBlock:^BOOL(NSString *currentValue) {
		return [currentValue isHostmaskNickname];
	}];
	
	[self.tnewNicknameTextField setStringValue:nickname];
	[self.toldNicknameTextField setStringValue:nickname];

	[self.sheet makeFirstResponder:self.tnewNicknameTextField];
	
	[self startSheet];
}

- (void)validatedTextFieldTextDidChange:(id)sender
{
	[self.okButton setEnabled:[self.tnewNicknameTextField valueIsValid]];
}

- (void)ok:(id)sender
{
	if ([self.delegate respondsToSelector:@selector(serverChangeNicknameSheet:didInputNickname:)]) {
		NSString *newNickname = [self.tnewNicknameTextField value];

		[self.delegate serverChangeNicknameSheet:self didInputNickname:newNickname];
	}
	
	[super ok:sender];
}

#pragma mark -
#pragma mark NSWindow Delegate

- (void)windowWillClose:(NSNotification *)note
{
	if ([self.delegate respondsToSelector:@selector(serverChangeNicknameSheetWillClose:)]) {
		[self.delegate serverChangeNicknameSheetWillClose:self];
	}
}

@end
