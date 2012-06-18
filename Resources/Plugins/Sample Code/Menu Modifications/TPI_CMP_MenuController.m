// Created by Codeux Software <support AT codeux DOT com> <https://github.com/codeux/Textual>
// You can redistribute it and/or modify it under the new BSD license.

#import "TPI_CMP_MenuController.h"

@implementation TXMenuController (TPI_CMP_MenuController)

- (void)postLinkToTextualHomepage:(id)sender
{
	IRCClient *u = [self.world selectedClient];
	if (PointerIsEmpty(u)) return;
	
	for (IRCUser* m in [self selectedMembers:sender]) {
		[[u invokeOnMainThread] sendPrivmsgToSelectedChannel:[NSString stringWithFormat:@"%@, the Textual IRC Client can be downloaded from http://www.codeux.com/textual/", m.nick]];
	}
	
	[self deselectMembers:sender];
}

@end