// Created by Satoshi Nakagawa <psychs AT limechat DOT net> <http://github.com/psychs/limechat>
// Modifications by Codeux Software <support AT codeux DOT com> <https://github.com/codeux/Textual>
// You can redistribute it and/or modify it under the new BSD license.

#import "TextualApplication.h"

@implementation TDCInviteSheet

- (id)init
{
	if ((self = [super init])) {
		[NSBundle loadNibNamed:@"TDCInviteSheet" owner:self];
	}

	return self;
}

- (void)startWithChannels:(NSArray *)channels
{
	NSString *target = nil;
	
	if (self.nicks.count == 1) {
		target = [self.nicks safeObjectAtIndex:0];
	} else if (self.nicks.count == 2) {
		NSString *first = [self.nicks safeObjectAtIndex:0];
		NSString *second = [self.nicks safeObjectAtIndex:1];
		
		target = TXTFLS(@"InviteSheetTwoPeopleSelected", first, second);
	} else {
		target = TXTFLS(@"InviteSheetMultiplePeopleSelected", self.nicks.count);
	}
	
	self.titleLabel.stringValue = TXTFLS(@"InviteSheetTargetDescription", target);
	
	for (NSString *s in channels) {
		[self.channelPopup addItemWithTitle:s];
	}
	
	[self startSheet];
}

- (void)invite:(id)sender
{
	NSString *channelName = [self.channelPopup selectedItem].title;
	
	if ([self.delegate respondsToSelector:@selector(inviteSheet:onSelectChannel:)]) {
		[self.delegate inviteSheet:self onSelectChannel:channelName];
	}
	
	[self endSheet];
}

#pragma mark -
#pragma mark NSWindow Delegate

- (void)windowWillClose:(NSNotification *)note
{
	if ([self.delegate respondsToSelector:@selector(inviteSheetWillClose:)]) {
		[self.delegate inviteSheetWillClose:self];
	}
}

@end