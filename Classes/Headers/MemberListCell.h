@class IRCUser;

@interface MemberListCell : NSCell
{
	IRCUser *member;
	
	NSMutableParagraphStyle *nickStyle;
}

@property (nonatomic, retain) IRCUser *member;
@property (nonatomic, readonly) NSMutableParagraphStyle *nickStyle;
@end