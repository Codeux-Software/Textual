/* ********************************************************************* 
       _____        _               _    ___ ____   ____
      |_   _|___  _| |_ _   _  __ _| |  |_ _|  _ \ / ___|
       | |/ _ \ \/ / __| | | |/ _` | |   | || |_) | |
       | |  __/>  <| |_| |_| | (_| | |   | ||  _ <| |___
       |_|\___/_/\_\\__|\__,_|\__,_|_|  |___|_| \_\\____|

 Copyright (c) 2008 - 2010 Satoshi Nakagawa <psychs AT limechat DOT net>
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

@implementation TDCModeSheet

- (id)init
{
	if ((self = [super init])) {
		[RZMainBundle() loadCustomNibNamed:@"TDCModeSheet" owner:self topLevelObjects:nil];
	}

	return self;
}

- (void)start
{
	[_sCheck setState:[[_mode modeInfoFor:@"s"] modeIsSet]];
	[_pCheck setState:[[_mode modeInfoFor:@"p"] modeIsSet]];
	[_nCheck setState:[[_mode modeInfoFor:@"n"] modeIsSet]];
	[_tCheck setState:[[_mode modeInfoFor:@"t"] modeIsSet]];
	[_iCheck setState:[[_mode modeInfoFor:@"i"] modeIsSet]];
	[_mCheck setState:[[_mode modeInfoFor:@"m"] modeIsSet]];

	IRCModeInfo *kCheckInfo = [_mode modeInfoFor:@"k"];
	IRCModeInfo *lCheckInfo = [_mode modeInfoFor:@"l"];
	
	NSInteger lcheckInfoActl = [[lCheckInfo modeParamater] integerValue];
	
	BOOL kCheckOn = NSObjectIsNotEmpty([kCheckInfo modeParamater]);
	
	BOOL lCheckOn = (lcheckInfoActl > 0);

	[_kCheck setState:kCheckOn];
	[_lCheck setState:lCheckOn];
	
	if ([kCheckInfo modeIsSet]) {
		[_kText setStringValue:[kCheckInfo modeParamater]];
	} else {
		[_kText setStringValue:NSStringEmptyPlaceholder];
	}
	
	if (lcheckInfoActl < 0) {
		lcheckInfoActl = 0;
	}
	
	[_lText setStringValue:[NSString stringWithInteger:lcheckInfoActl]];
	
	[self updateTextFields];
	[self startSheet];
}

- (void)updateTextFields
{
	[_kText setEnabled:([_kCheck state] == NSOnState)];
	[_lText setEnabled:([_lCheck state] == NSOnState)];
}

- (void)onChangeCheck:(id)sender
{
	[self updateTextFields];
	
	if ([_sCheck state] == NSOnState &&
		[_pCheck state] == NSOnState)
	{
		if (sender == _sCheck) {
			[_pCheck setState:NSOffState];
		} else {
			[_sCheck setState:NSOffState];
		}
	}
}

- (void)ok:(id)sender
{
	[[_mode modeInfoFor:@"s"] setModeIsSet:[_sCheck state]];
	[[_mode modeInfoFor:@"p"] setModeIsSet:[_pCheck state]];
	[[_mode modeInfoFor:@"n"] setModeIsSet:[_nCheck state]];
	[[_mode modeInfoFor:@"t"] setModeIsSet:[_tCheck state]];
	[[_mode modeInfoFor:@"i"] setModeIsSet:[_iCheck state]];
	[[_mode modeInfoFor:@"m"] setModeIsSet:[_mCheck state]];
	
	if ([_kCheck state] == NSOnState) {
		[[_mode modeInfoFor:@"k"] setModeIsSet:YES];
		[[_mode modeInfoFor:@"k"] setModeParamater:[_kText firstTokenStringValue]];
	} else {
		[[_mode modeInfoFor:@"k"] setModeIsSet:NO];
	}
	
	if ([_lCheck state] == NSOnState) {
		[[_mode modeInfoFor:@"l"] setModeIsSet:YES];
		[[_mode modeInfoFor:@"l"] setModeParamater:[_lText firstTokenStringValue]];
	} else {
		[[_mode modeInfoFor:@"l"] setModeIsSet:NO];
		[[_mode modeInfoFor:@"l"] setModeParamater:@"0"];
	}
	
	if ([[self delegate] respondsToSelector:@selector(modeSheetOnOK:)]) {
		[[self delegate] modeSheetOnOK:self];
	}
	
	[super ok:nil];
}

#pragma mark -
#pragma mark NSWindow Delegate

- (void)windowWillClose:(NSNotification *)note
{
	if ([[self delegate] respondsToSelector:@selector(modeSheetWillClose:)]) {
		[[self delegate] modeSheetWillClose:self];
	}
}

@end
