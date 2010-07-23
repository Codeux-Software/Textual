#import <Foundation/Foundation.h>
#import "SheetBase.h"

@interface InviteSheet : SheetBase
{
	NSArray* nicks;
	NSInteger uid;
	
	IBOutlet NSTextField* titleLabel;
	IBOutlet NSPopUpButton* channelPopup;
}

@property (retain) NSArray* nicks;
@property (assign) NSInteger uid;
@property (retain) NSTextField* titleLabel;
@property (retain) NSPopUpButton* channelPopup;

- (void)startWithChannels:(NSArray*)channels;
- (void)invite:(id)sender;
@end

@interface NSObject (InviteSheetDelegate)
- (void)inviteSheet:(InviteSheet*)sender onSelectChannel:(NSString*)channelName;
- (void)inviteSheetWillClose:(InviteSheet*)sender;
@end