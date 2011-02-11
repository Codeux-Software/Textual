// Created by Satoshi Nakagawa <psychs AT limechat DOT net> <http://github.com/psychs/limechat>
// Modifications by Codeux Software <support AT codeux DOT com> <https://github.com/codeux/Textual>
// You can redistribute it and/or modify it under the new BSD license.

@implementation InviteSheet

@synthesize nicks;
@synthesize uid;
@synthesize titleLabel;
@synthesize channelPopup;

- (id)init
{
	if ((self = [super init])) {
		[NSBundle loadNibNamed:@"InviteSheet" owner:self];
	}

	return self;
}

- (void)dealloc
{
	[nicks drain];
	
	[super dealloc];
}

- (void)startWithChannels:(NSArray *)channels
{
	NSString *target = nil;
	
	if (nicks.count == 1) {
		target = [nicks safeObjectAtIndex:0];
	} else if (nicks.count == 2) {
		NSString *first = [nicks safeObjectAtIndex:0];
		NSString *second = [nicks safeObjectAtIndex:1];
		
		target = TXTFLS(@"INVITE_SHEET_TWO_PEOPLE", first, second);
	} else {
		target = TXTFLS(@"INVITE_SHEET_MULTIPLE_PEOPLE", nicks.count);
	}
	
	titleLabel.stringValue = TXTFLS(@"INVITE_SHEET_TARGET_DESC", target);
	
	for (NSString *s in channels) {
		[channelPopup addItemWithTitle:s];
	}
	
	[self startSheet];
}

- (void)invite:(id)sender
{
	NSString *channelName = [[channelPopup selectedItem] title];
	
	if ([delegate respondsToSelector:@selector(inviteSheet:onSelectChannel:)]) {
		[delegate inviteSheet:self onSelectChannel:channelName];
	}
	
	[self endSheet];
}

#pragma mark -
#pragma mark NSWindow Delegate

- (void)windowWillClose:(NSNotification *)note
{
	if ([delegate respondsToSelector:@selector(inviteSheetWillClose:)]) {
		[delegate inviteSheetWillClose:self];
	}
}

@end