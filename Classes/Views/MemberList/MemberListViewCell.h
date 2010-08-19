#import <Cocoa/Cocoa.h>
#import "OtherTheme.h"
#import "IRCUser.h"

@interface MemberListViewCell : NSCell
{
	IRCUser* member;
}

@property (nonatomic, retain) IRCUser* member;

- (void)setup:(OtherTheme*)theme;
- (void)themeChanged;
@end