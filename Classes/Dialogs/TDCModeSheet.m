/* ********************************************************************* 
       _____        _               _    ___ ____   ____
      |_   _|___  _| |_ _   _  __ _| |  |_ _|  _ \ / ___|
       | |/ _ \ \/ / __| | | |/ _` | |   | || |_) | |
       | |  __/>  <| |_| |_| | (_| | |   | ||  _ <| |___
       |_|\___/_/\_\\__|\__,_|\__,_|_|  |___|_| \_\\____|

 Copyright (c) 2010 — 2012 Codeux Software & respective contributors.
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
	[self.sCheck setState:[self.mode modeInfoFor:@"s"].plus];
	[self.pCheck setState:[self.mode modeInfoFor:@"p"].plus];
	[self.nCheck setState:[self.mode modeInfoFor:@"n"].plus];
	[self.tCheck setState:[self.mode modeInfoFor:@"t"].plus];
	[self.iCheck setState:[self.mode modeInfoFor:@"i"].plus];
	[self.mCheck setState:[self.mode modeInfoFor:@"m"].plus];
	
	[self.kCheck setState:NSObjectIsNotEmpty([self.mode modeInfoFor:@"k"].param)];
	[self.lCheck setState:([self.mode modeInfoFor:@"s"].param.integerValue > 0)];
	
	if ([self.mode modeInfoFor:@"k"].plus) {
		[self.kText setStringValue:[self.mode modeInfoFor:@"k"].param];
	} else {
		[self.kText setStringValue:NSStringEmptyPlaceholder];
	}
	
	NSInteger lCount = [self.mode modeInfoFor:@"l"].param.integerValue;
								
	if (lCount < 0) {
		lCount = 0;
	}
	
	if (lCount > 0) {
		[self.lCheck setState:NSOnState];
	}
	
	[self.lText setStringValue:[NSString stringWithInteger:lCount]];
	
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
		[self.pCheck state] == NSOnState) {
		
		if (sender == self.sCheck) {
			[self.pCheck setState:NSOffState];
		} else {
			[self.sCheck setState:NSOffState];
		}
	}
}

- (void)ok:(id)sender
{
	[self.mode modeInfoFor:@"s"].plus = [self.sCheck state];
	[self.mode modeInfoFor:@"p"].plus = [self.pCheck state];
	[self.mode modeInfoFor:@"n"].plus = [self.nCheck state];
	[self.mode modeInfoFor:@"t"].plus = [self.tCheck state];
	[self.mode modeInfoFor:@"i"].plus = [self.iCheck state];
	[self.mode modeInfoFor:@"m"].plus = [self.mCheck state];
	
	if ([self.kCheck state] == NSOnState) {
		[self.mode modeInfoFor:@"k"].plus = YES;
		[self.mode modeInfoFor:@"k"].param = [self.kText stringValue];
	} else {
		[self.mode modeInfoFor:@"k"].plus = NO;
	}
	
	if ([self.lCheck state] == NSOnState) {
		[self.mode modeInfoFor:@"l"].plus = YES;
		[self.mode modeInfoFor:@"l"].param = [self.lText stringValue];
	} else {
		[self.mode modeInfoFor:@"l"].plus = NO;
		[self.mode modeInfoFor:@"l"].param = @"0";
	}
	
	if ([self.delegate respondsToSelector:@selector(modeSheetOnOK:)]) {
		[self.delegate modeSheetOnOK:self];
	}
	
	[super ok:sender];
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