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

@implementation TDCNickSheet

- (instancetype)init
{
	if ((self = [super init])) {
		[RZMainBundle() loadCustomNibNamed:@"TDCNickSheet" owner:self topLevelObjects:nil];
	}

	return self;
}

- (void)start:(NSString *)nickname
{
	/* Define nickname field for user tracking. */
	[self.tnewNicknameField setStringValueIsInvalidOnEmpty:YES];
	[self.tnewNicknameField setStringValueUsesOnlyFirstToken:YES];
	
	[self.tnewNicknameField setOnlyShowStatusIfErrorOccurs:YES];
	
	[self.tnewNicknameField setTextDidChangeCallback:self];
	
	[self.tnewNicknameField setValidationBlock:^BOOL(NSString *currentValue) {
		return [currentValue isHostmaskNickname];
	}];
	
	[self.tnewNicknameField setStringValue:nickname];
	[self.toldNicknameField setStringValue:nickname];
	
	[self.sheet makeFirstResponder:self.tnewNicknameField];
	
	[self startSheet];
}

- (void)validatedTextFieldTextDidChange:(id)sender
{
	[self.okButton setEnabled:[self.tnewNicknameField valueIsValid]];
}

- (void)ok:(id)sender
{
	if ([self.delegate respondsToSelector:@selector(nickSheet:didInputNickname:)]) {
		NSString *newNickname = [self.tnewNicknameField value];
		
		[self.delegate nickSheet:self didInputNickname:newNickname];
	}
	
	[super ok:sender];
}

#pragma mark -
#pragma mark NSWindow Delegate

- (void)windowWillClose:(NSNotification *)note
{
	if ([self.delegate respondsToSelector:@selector(nickSheetWillClose:)]) {
		[self.delegate nickSheetWillClose:self];
	}
}

@end
