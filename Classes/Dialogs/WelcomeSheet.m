// Created by Satoshi Nakagawa <psychs AT limechat DOT net> <http://github.com/psychs/limechat>
// Modifications by Codeux Software <support AT codeux DOT com> <https://github.com/codeux/Textual>
// You can redistribute it and/or modify it under the new BSD license.
// Converted to ARC Support on Thursday, June 08, 2012

@interface WelcomeSheet (Private)
- (void)updateOKButton;
- (void)tableViewSelectionIsChanging:(NSNotification *)note;
@end

@implementation WelcomeSheet

@synthesize delegate;
@synthesize okButton;
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
		
		self.channels = [NSMutableArray new];
	}
	
	return self;
}

- (void)show
{
	[self tableViewSelectionIsChanging:nil];
	[self updateOKButton];
	
	[self.nickText setStringValue:[Preferences defaultNickname]];
	
	[self startSheet];
}

- (void)close
{
	self.delegate = nil;
	
	[self endSheet];
}

- (void)onOK:(id)sender
{
	NSMutableSet *set = [NSMutableSet set];
	NSMutableArray *chans = [NSMutableArray array];
	
	for (__strong NSString *s in self.channels) {
		if (NSObjectIsNotEmpty(s)) {
			if ([s isChannelName] == NO) {
				s = [@"#" stringByAppendingString:s];
			}
			
			if ([set containsObject:s] == NO) {
				[chans addObject:s];
				[set addObject:s];
			}
		}
	}
	
	NSMutableDictionary *dic = [NSMutableDictionary dictionary];
	
	[dic setBool:self.autoConnectCheck.state forKey:@"autoConnect"];
	
	[dic setObject:chans forKey:@"channels"];
	[dic setObject:self.nickText.stringValue forKey:@"nick"];
	[dic setObject:[self.hostCombo.stringValue cleanedServerHostmask] forKey:@"host"];
	
	if ([self.delegate respondsToSelector:@selector(WelcomeSheet:onOK:)]) {
		[self.delegate WelcomeSheet:self onOK:dic];
	}
	
	[self endSheet];
}

- (void)onCancel:(id)sender
{
	[self endSheet];
}

- (void)onAddChannel:(id)sender
{
	[self.channels safeAddObject:NSNullObject];
	
	[self.channelTable reloadData];
	
	NSInteger row = (self.channels.count - 1);
	
	[self.channelTable selectItemAtIndex:row];
	[self.channelTable editColumn:0 row:row withEvent:nil select:YES];
}

- (void)onDeleteChannel:(id)sender
{
	NSInteger n = [self.channelTable selectedRow];
	
	if (n >= 0) {
		[self.channels safeRemoveObjectAtIndex:n];
		
		[self.channelTable reloadData];
		
		NSInteger count = self.channels.count;
		if (count <= n) n = (count - 1);
		
		if (n >= 0) {
			[self.channelTable selectItemAtIndex:n];
		}
		
		[self tableViewSelectionIsChanging:nil];
	}
}

- (void)controlTextDidChange:(NSNotification *)note
{
	[self updateOKButton];
}

- (void)onHostComboChanged:(id)sender
{
	[self updateOKButton];
}

- (void)updateOKButton
{
	NSString *nick = self.nickText.stringValue;
	NSString *host = self.hostCombo.stringValue;
	
	BOOL enabled = (NSObjectIsNotEmpty(nick) && NSObjectIsNotEmpty(host));
	
	[self.okButton setEnabled:enabled];
}

#pragma mark -
#pragma mark NSTableViwe Delegate

- (void)textDidEndEditing:(NSNotification *)note
{
	NSInteger n = [self.channelTable editedRow];
	
	if (n >= 0) {
		NSString *s = [[[[note object] textStorage] string] copy];
		
		[self.channels replaceObjectAtIndex:n withObject:s];
		
		[self.channelTable reloadData];
		[self.channelTable selectItemAtIndex:n];
		
		[self tableViewSelectionIsChanging:nil];
	}
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)sender
{
	return self.channels.count;
}

- (id)tableView:(NSTableView *)sender objectValueForTableColumn:(NSTableColumn *)column row:(NSInteger)row
{
	return [self.channels safeObjectAtIndex:row];
}

- (void)tableViewSelectionIsChanging:(NSNotification *)note
{
	[self.deleteChannelButton setEnabled:([self.channelTable selectedRow] >= 0)];
}

#pragma mark -
#pragma mark NSWindow Delegate

- (void)windowWillClose:(NSNotification *)note
{
	if ([self.delegate respondsToSelector:@selector(WelcomeSheetWillClose:)]) {
		[self.delegate WelcomeSheetWillClose:self];
	}
}

@end