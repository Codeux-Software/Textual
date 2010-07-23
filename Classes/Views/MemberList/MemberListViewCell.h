#import <Cocoa/Cocoa.h>
#import "OtherTheme.h"
#import "IRCUser.h"

@interface MemberListViewCell : NSCell
{
	IRCUser* member;
}

@property (retain) IRCUser* member;

- (void)setup:(OtherTheme*)theme;
- (void)themeChanged;
@end