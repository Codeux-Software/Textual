#import "TPI_CMP_MenuController.h"

@implementation MenuController (TPI_CMP_MenuController)

- (void)postLinkToTextualHomepage:(id)sender
{
	IRCClient *u = [world selectedClient];
	if (!u) return;
	
	NSArray *nicknames = [self selectedMembers:sender];
	
	if (pointedNick && [nicknames isEqual:[NSArray array]]) {
		[[u invokeOnMainThread] sendPrivmsgToSelectedChannel:[NSString stringWithFormat:@"%@, the Textual IRC Client can be downloaded from http://www.codeux.com/textual/", pointedNick]];
	} else {
		for (IRCUser* m in nicknames) {
			[[u invokeOnMainThread] sendPrivmsgToSelectedChannel:[NSString stringWithFormat:@"%@, the Textual IRC Client can be downloaded from http://www.codeux.com/textual/", m.nick]];
		}
		
		[self deselectMembers:sender];
	}
}

@end