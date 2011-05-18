// Created by Satoshi Nakagawa <psychs AT limechat DOT net> <http://github.com/psychs/limechat>
// Modifications by Codeux Software <support AT codeux DOT com> <https://github.com/codeux/Textual>
// You can redistribute it and/or modify it under the new BSD license.

@interface ModeSheet (Private)
- (void)updateTextFields;
@end

@implementation ModeSheet

@synthesize mode;
@synthesize channelName;
@synthesize uid;
@synthesize cid;
@synthesize sCheck;
@synthesize pCheck;
@synthesize nCheck;
@synthesize tCheck;
@synthesize iCheck;
@synthesize mCheck;
@synthesize kCheck;
@synthesize lCheck;
@synthesize kText;
@synthesize lText;

- (id)init
{
	if ((self = [super init])) {
		[NSBundle loadNibNamed:@"ModeSheet" owner:self];
	}

	return self;
}

- (void)dealloc
{
	[channelName drain];
	
	[super dealloc];
}

- (void)start
{
	[sCheck setState:[mode modeInfoFor:@"s"].plus];
	[pCheck setState:[mode modeInfoFor:@"p"].plus];
	[nCheck setState:[mode modeInfoFor:@"n"].plus];
	[tCheck setState:[mode modeInfoFor:@"t"].plus];
	[iCheck setState:[mode modeInfoFor:@"i"].plus];
	[mCheck setState:[mode modeInfoFor:@"m"].plus];
	
	[kCheck setState:NSObjectIsNotEmpty([mode modeInfoFor:@"k"].param)];
	[lCheck setState:([[mode modeInfoFor:@"s"].param integerValue] > 0)];
	
	if ([mode modeInfoFor:@"k"].plus) {
		[kText setStringValue:[mode modeInfoFor:@"k"].param];
	} else {
		[kText setStringValue:NSNullObject];
	}
	
	NSInteger lCount = [[mode modeInfoFor:@"l"].param integerValue];
	
	if (lCount < 0) {
		lCount = 0;
	}
	
	if (lCount > 0) {
		[lCheck setState:NSOnState];
	}
	
	[lText setStringValue:[NSString stringWithDouble:lCount]];
	
	[self updateTextFields];
	[self startSheet];
}

- (void)updateTextFields
{
	[kText setEnabled:(kCheck.state == NSOnState)];
	[lText setEnabled:(lCheck.state == NSOnState)];
}

- (void)onChangeCheck:(id)sender
{
	[self updateTextFields];
	
	if ([sCheck state] == NSOnState && [pCheck state] == NSOnState) {
		if (sender == sCheck) {
			[pCheck setState:NSOffState];
		} else {
			[sCheck setState:NSOffState];
		}
	}
}

- (void)ok:(id)sender
{
	[mode modeInfoFor:@"s"].plus = [sCheck state];
	[mode modeInfoFor:@"p"].plus = [pCheck state];
	[mode modeInfoFor:@"n"].plus = [nCheck state];
	[mode modeInfoFor:@"t"].plus = [tCheck state];
	[mode modeInfoFor:@"i"].plus = [iCheck state];
	[mode modeInfoFor:@"m"].plus = [mCheck state];
	
	if ([kCheck state] == NSOnState) {
		[mode modeInfoFor:@"k"].plus = YES;
		[mode modeInfoFor:@"k"].param = [kText stringValue];
	} else {
		[mode modeInfoFor:@"k"].plus = NO;
	}
	
	if ([lCheck state] == NSOnState) {
		[mode modeInfoFor:@"l"].plus = YES;
		[mode modeInfoFor:@"l"].param = [lText stringValue];
	} else {
		[mode modeInfoFor:@"l"].plus = NO;
		[mode modeInfoFor:@"l"].param = @"0";
	}
	
	if ([delegate respondsToSelector:@selector(modeSheetOnOK:)]) {
		[delegate modeSheetOnOK:self];
	}
	
	[super ok:sender];
}

#pragma mark -
#pragma mark NSWindow Delegate

- (void)windowWillClose:(NSNotification *)note
{
	if ([delegate respondsToSelector:@selector(modeSheetWillClose:)]) {
		[delegate modeSheetWillClose:self];
	}
}

@end