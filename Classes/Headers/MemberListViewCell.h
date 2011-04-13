@class IRCUser;

@interface MemberListViewCell : NSCell
{
	IRCUser *member;
	OtherTheme *theme;
	
	NSMutableParagraphStyle *markStyle;
	NSMutableParagraphStyle *nickStyle;
}

@property (retain) IRCUser *member;
@property (retain) OtherTheme *theme;
@property (retain) NSMutableParagraphStyle *markStyle;
@property (retain) NSMutableParagraphStyle *nickStyle;

+ (MemberListViewCell *)initWithTheme:(OtherTheme *)theme;
- (void)themeChanged;
@end