/* ********************************************************************* 
       _____        _               _    ___ ____   ____
      |_   _|___  _| |_ _   _  __ _| |  |_ _|  _ \ / ___|
       | |/ _ \ \/ / __| | | |/ _` | |   | || |_) | |
       | |  __/>  <| |_| |_| | (_| | |   | ||  _ <| |___
       |_|\___/_/\_\\__|\__,_|\__,_|_|  |___|_| \_\\____|

 Copyright (c) 2010 — 2013 Codeux Software & respective contributors.
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

@implementation TDCModeSheet

- (id)init
{
	if ((self = [super init])) {
		[NSBundle loadNibNamed:@"TDCModeSheet" owner:self];
	}

	return self;
}

- (void)start
{
	[self.sCheck setState:[self.mode modeInfoFor:@"s"].modeIsSet];
	[self.pCheck setState:[self.mode modeInfoFor:@"p"].modeIsSet];
	[self.nCheck setState:[self.mode modeInfoFor:@"n"].modeIsSet];
	[self.tCheck setState:[self.mode modeInfoFor:@"t"].modeIsSet];
	[self.iCheck setState:[self.mode modeInfoFor:@"i"].modeIsSet];
	[self.mCheck setState:[self.mode modeInfoFor:@"m"].modeIsSet];

	IRCModeInfo *kCheckInfo = [self.mode modeInfoFor:@"k"];
	IRCModeInfo *lCheckInfo = [self.mode modeInfoFor:@"l"];
	
	BOOL kCheckOn = NSObjectIsNotEmpty(kCheckInfo.modeParamater);
	BOOL lCheckOn = (lCheckInfo.modeParamater.integerValue > 0);

	[self.kCheck setState:kCheckOn];
	[self.lCheck setState:lCheckOn];
	
	if (kCheckInfo.modeIsSet) {
		[self.kText setStringValue:kCheckInfo.modeParamater];
	} else {
		[self.kText setStringValue:NSStringEmptyPlaceholder];
	}
	
	NSInteger lCheckCount = lCheckInfo.modeParamater.integerValue;
								
	if (lCheckCount < 0) {
		lCheckCount = 0;
	}
	
	[self.lText setStringValue:[NSString stringWithInteger:lCheckCount]];
	
	[self updateTextFields];
	[self startSheet];
}

- (void)updateTextFields
{
	[self.kText setEnabled:(self.kCheck.state == NSOnState)];
	[self.lText setEnabled:(self.lCheck.state == NSOnState)];
}

- (void)onChangeCheck:(id)sender
{
	[self updateTextFields];
	
	if ([self.sCheck state] == NSOnState &&
		[self.pCheck state] == NSOnState)
	{
		if (sender == self.sCheck) {
			[self.pCheck setState:NSOffState];
		} else {
			[self.sCheck setState:NSOffState];
		}
	}
}

- (void)ok:(id)sender
{
	[self.mode modeInfoFor:@"s"].modeIsSet = [self.sCheck state];
	[self.mode modeInfoFor:@"p"].modeIsSet = [self.pCheck state];
	[self.mode modeInfoFor:@"n"].modeIsSet = [self.nCheck state];
	[self.mode modeInfoFor:@"t"].modeIsSet = [self.tCheck state];
	[self.mode modeInfoFor:@"i"].modeIsSet = [self.iCheck state];
	[self.mode modeInfoFor:@"m"].modeIsSet = [self.mCheck state];
	
	if ([self.kCheck state] == NSOnState) {
		[self.mode modeInfoFor:@"k"].modeIsSet = YES;
		[self.mode modeInfoFor:@"k"].modeParamater = self.kText.firstTokenStringValue;
	} else {
		[self.mode modeInfoFor:@"k"].modeIsSet = NO;
	}
	
	if ([self.lCheck state] == NSOnState) {
		[self.mode modeInfoFor:@"l"].modeIsSet = YES;
		[self.mode modeInfoFor:@"l"].modeParamater = self.lText.firstTokenStringValue;
	} else {
		[self.mode modeInfoFor:@"l"].modeIsSet = NO;
		[self.mode modeInfoFor:@"l"].modeParamater = @"0";
	}
	
	if ([self.delegate respondsToSelector:@selector(modeSheetOnOK:)]) {
		[self.delegate modeSheetOnOK:self];
	}
	
	[super ok:nil];
}

#pragma mark -
#pragma mark NSWindow Delegate

- (void)windowWillClose:(NSNotification *)note
{
	if ([self.delegate respondsToSelector:@selector(modeSheetWillClose:)]) {
		[self.delegate modeSheetWillClose:self];
	}
}

@end
