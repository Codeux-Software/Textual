// Created by Satoshi Nakagawa <psychs AT limechat DOT net> <http://github.com/psychs/limechat>
// Modifications by Codeux Software <support AT codeux DOT com> <https://github.com/codeux/Textual>
// You can redistribute it and/or modify it under the new BSD license.

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