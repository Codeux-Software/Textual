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

@interface TDChannelModifyModesSheet ()
@property (nonatomic, weak) IBOutlet NSButton *sCheck;
@property (nonatomic, weak) IBOutlet NSButton *pCheck;
@property (nonatomic, weak) IBOutlet NSButton *nCheck;
@property (nonatomic, weak) IBOutlet NSButton *tCheck;
@property (nonatomic, weak) IBOutlet NSButton *iCheck;
@property (nonatomic, weak) IBOutlet NSButton *mCheck;
@property (nonatomic, weak) IBOutlet NSButton *kCheck;
@property (nonatomic, weak) IBOutlet NSButton *lCheck;
@property (nonatomic, weak) IBOutlet NSTextField *kText;
@property (nonatomic, weak) IBOutlet NSTextField *lText;

- (IBAction)onChangeCheck:(id)sender;
@end

@implementation TDChannelModifyModesSheet

- (instancetype)init
{
	if ((self = [super init])) {
		[RZMainBundle() loadNibNamed:@"TDChannelModifyModesSheet" owner:self topLevelObjects:nil];
	}

	return self;
}

- (void)start
{
	[self.sCheck setState:[[self.mode modeInfoFor:@"s"] modeIsSet]];
	[self.pCheck setState:[[self.mode modeInfoFor:@"p"] modeIsSet]];
	[self.nCheck setState:[[self.mode modeInfoFor:@"n"] modeIsSet]];
	[self.tCheck setState:[[self.mode modeInfoFor:@"t"] modeIsSet]];
	[self.iCheck setState:[[self.mode modeInfoFor:@"i"] modeIsSet]];
	[self.mCheck setState:[[self.mode modeInfoFor:@"m"] modeIsSet]];

	IRCModeInfo *kCheckInfo = [self.mode modeInfoFor:@"k"];
	IRCModeInfo *lCheckInfo = [self.mode modeInfoFor:@"l"];
	
	NSInteger lcheckInfoActl = [[lCheckInfo modeParamater] integerValue];
	
	BOOL kCheckOn = NSObjectIsNotEmpty([kCheckInfo modeParamater]);
	
	BOOL lCheckOn = (lcheckInfoActl > 0);

	[self.kCheck setState:kCheckOn];
	[self.lCheck setState:lCheckOn];
	
	if ([kCheckInfo modeIsSet]) {
		[self.kText setStringValue:[kCheckInfo modeParamater]];
	} else {
		[self.kText setStringValue:NSStringEmptyPlaceholder];
	}
	
	[self updateTextFields];
	[self startSheet];
}

- (NSString *)channelUserLimitMode
{
	return [[self.mode modeInfoFor:@"l"] modeParamater];
}

- (void)setChannelUserLimitMode:(NSString *)value
{
	[[self.mode modeInfoFor:@"l"] setModeParamater:value];
}

- (BOOL)validateValue:(inout __autoreleasing id *)value forKey:(NSString *)key error:(out NSError *__autoreleasing *)outError
{
	if ([key isEqualToString:@"channelUserLimitMode"]) {
		NSInteger n = [*value integerValue];
		
		if (n < 0) {
			*value = [NSString stringWithInteger:0];
		} else if (n > 99999) {
			*value = [NSString stringWithInteger:99999];
		}
	}
	
	return YES;
}

- (void)updateTextFields
{
	[self.kText setEnabled:([self.kCheck state] == NSOnState)];
	[self.lText setEnabled:([self.lCheck state] == NSOnState)];
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
	[[self.mode modeInfoFor:@"s"] setModeIsSet:[self.sCheck state]];
	[[self.mode modeInfoFor:@"p"] setModeIsSet:[self.pCheck state]];
	[[self.mode modeInfoFor:@"n"] setModeIsSet:[self.nCheck state]];
	[[self.mode modeInfoFor:@"t"] setModeIsSet:[self.tCheck state]];
	[[self.mode modeInfoFor:@"i"] setModeIsSet:[self.iCheck state]];
	[[self.mode modeInfoFor:@"m"] setModeIsSet:[self.mCheck state]];
	
	if ([self.kCheck state] == NSOnState) {
		[[self.mode modeInfoFor:@"k"] setModeIsSet:YES];
		[[self.mode modeInfoFor:@"k"] setModeParamater:[self.kText trimmedFirstTokenStringValue]];
	} else {
		[[self.mode modeInfoFor:@"k"] setModeIsSet:NO];
	}
	
	if ([self.lCheck state] == NSOnState) {
		[[self.mode modeInfoFor:@"l"] setModeIsSet:YES];
	} else {
		[[self.mode modeInfoFor:@"l"] setModeIsSet:NO];
		[[self.mode modeInfoFor:@"l"] setModeParamater:@"0"];
	}
	
	if ([self.delegate respondsToSelector:@selector(channelModifyModesSheetOnOK:)]) {
		[self.delegate channelModifyModesSheetOnOK:self];
	}
	
	[super ok:nil];
}

#pragma mark -
#pragma mark NSWindow Delegate

- (void)windowWillClose:(NSNotification *)note
{
	if ([self.delegate respondsToSelector:@selector(channelModifyModesSheetWillClose:)]) {
		[self.delegate channelModifyModesSheetWillClose:self];
	}
}

@end
