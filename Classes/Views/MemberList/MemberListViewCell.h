#import <Cocoa/Cocoa.h>
#import "OtherTheme.h"
#import "IRCUser.h"

@interface MemberListViewCell : NSCell
{
	IRCUser* member;
	OtherTheme* theme;
}

@property (nonatomic, retain) IRCUser* member;
@property (nonatomic, retain) OtherTheme* theme;

+ (MemberListViewCell*)initWithTheme:(OtherTheme*)theme;
- (void)themeChanged;
@end