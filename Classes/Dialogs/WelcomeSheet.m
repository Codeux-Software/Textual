// Created by Satoshi Nakagawa <psychs AT limechat DOT net> <http://github.com/psychs/limechat>
// Modifications by Codeux Software <support AT codeux DOT com> <https://github.com/codeux/Textual>
// You can redistribute it and/or modify it under the new BSD license.

#import "WelcomeSheet.h"
#import "ServerSheet.h"
#import "Preferences.h"
#import "NSStringHelper.h"

@interface WelcomeSheet (Private)
- (void)updateOKButton;
- (void)tableViewSelectionIsChanging:(NSNotification *)note;
@end

@implementation WelcomeSheet

@synthesize channels;
@synthesize nickText;
@synthesize hostCombo;
@synthesize channelTable;
@synthesize autoConnectCheck;
@synthesize addChannelButton;
@synthesize deleteChannelButton;

- (id)init
{
	if ((self = [super init])) {
		[NSBundle loadNibNamed:@"WelcomeSheet" owner:self];
		
		channels = [NSMutableArray new];
	}
	return self;
}

- (void)dealloc
{
	[channels release];
	[super dealloc];
}

- (void)show
{
	[self tableViewSelectionIsChanging:nil];
	[self updateOKButton];
	
	[nickText setStringValue:[Preferences defaultNickname]];
	
	[self startSheet];
}

- (void)close
{
	delegate = nil;
	[self endSheet];
}

- (void)onOK:(id)sender
{
	NSMutableSet* set = [NSMutableSet set];
	NSMutableArray* chans = [NSMutableArray array];
	
	for (NSString* s in channels) {
		if (s.length > 0) {
			if (![s isChannelName]) {
				s = [@"#" stringByAppendingString:s];
			}
			
			if (![set containsObject:s]) {
				[chans addObject:s];
				[set addObject:s];
			}
		}
	}
	
	NSMutableDictionary* dic = [NSMutableDictionary dictionary];
	[dic setObject:nickText.stringValue forKey:@"nick"];
	[dic setObject:hostCombo.stringValue forKey:@"host"];
	[dic setObject:chans forKey:@"channels"];
	[dic setObject:[NSNumber numberWithBool:autoConnectCheck.state] forKey:@"autoConnect"];
	
	if ([delegate respondsToSelector:@selector(WelcomeSheet:onOK:)]) {
		[delegate WelcomeSheet:self onOK:dic];
	}
	
	[self endSheet];
}

- (void)onCancel:(id)sender
{
	[self endSheet];
}

- (void)onAddChannel:(id)sender
{
	[channels addObject:@""];
	[channelTable reloadData];
	NSInteger row = channels.count - 1;
	[channelTable selectItemAtIndex:row];
	[channelTable editColumn:0 row:row withEvent:nil select:YES];
}

- (void)onDeleteChannel:(id)sender
{
	NSInteger n = [channelTable selectedRow];
	if (n >= 0) {
		[channels safeRemoveObjectAtIndex:n];
		[channelTable reloadData];
		NSInteger count = channels.count;
		if (count <= n) n = count - 1;
		if (n >= 0) {
			[channelTable selectItemAtIndex:n];
		}
		[self tableViewSelectionIsChanging:nil];
	}
}

- (void)controlTextDidChange:(NSNotification*)note
{
	[self updateOKButton];
}

- (void)onHostComboChanged:(id)sender
{
	[self updateOKButton];
}

- (void)updateOKButton
{
	NSString* nick = nickText.stringValue;
	NSString* host = hostCombo.stringValue;
	[okButton setEnabled:nick.length > 0 && host.length > 0];
}

#pragma mark -
#pragma mark NSTableViwe Delegate

- (void)textDidEndEditing:(NSNotification*)note
{
	NSInteger n = [channelTable editedRow];
	if (n >= 0) {
		NSString* s = [[[[[note object] textStorage] string] copy] autorelease];
		[channels replaceObjectAtIndex:n withObject:s];
		[channelTable reloadData];
		[channelTable selectItemAtIndex:n];
		[self tableViewSelectionIsChanging:nil];
	}
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)sender
{
	return channels.count;
}

- (id)tableView:(NSTableView *)sender objectValueForTableColumn:(NSTableColumn *)column row:(NSInteger)row
{
	return [channels safeObjectAtIndex:row];
}

- (void)tableViewSelectionIsChanging:(NSNotification *)note
{
	[deleteChannelButton setEnabled:[channelTable selectedRow] >= 0];
}

#pragma mark -
#pragma mark NSWindow Delegate

- (void)windowWillClose:(NSNotification*)note
{
	if ([delegate respondsToSelector:@selector(WelcomeSheetWillClose:)]) {
		[delegate WelcomeSheetWillClose:self];
	}
}

@end