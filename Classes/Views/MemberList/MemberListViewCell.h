#import <Cocoa/Cocoa.h>
#import "OtherTheme.h"
#import "IRCUser.h"

@interface MemberListViewCell : NSCell
{
	IRCUser* member;
	OtherTheme* theme;
	
	NSMutableParagraphStyle* markStyle;
	NSMutableParagraphStyle* nickStyle;
}

@property (nonatomic, retain) IRCUser* member;
@property (nonatomic, retain) OtherTheme* theme;
@property (nonatomic, retain) NSMutableParagraphStyle* markStyle;
@property (nonatomic, retain) NSMutableParagraphStyle* nickStyle;

+ (MemberListViewCell*)initWithTheme:(OtherTheme*)theme;
- (void)themeChanged;
@end