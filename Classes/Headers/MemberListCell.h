@class IRCUser;

@interface MemberListCell : NSTextFieldCell
{
	IRCUser *member;
}

@property (nonatomic, assign) IRCUser *member;
@end