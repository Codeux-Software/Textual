#import <Cocoa/Cocoa.h>

typedef enum {
	LINE_TYPE_SYSTEM,
	LINE_TYPE_ERROR,
	LINE_TYPE_CTCP,
	LINE_TYPE_REPLY,
	LINE_TYPE_ERROR_REPLY,
	LINE_TYPE_DCC_SEND_SEND,
	LINE_TYPE_DCC_SEND_RECEIVE,
	LINE_TYPE_PRIVMSG,
	LINE_TYPE_PRIVMSG_NH,
	LINE_TYPE_NOTICE,
	LINE_TYPE_ACTION,
	LINE_TYPE_ACTION_NH,
	LINE_TYPE_JOIN,
	LINE_TYPE_PART,
	LINE_TYPE_KICK,
	LINE_TYPE_QUIT,
	LINE_TYPE_KILL,
	LINE_TYPE_NICK,
	LINE_TYPE_MODE,
	LINE_TYPE_TOPIC,
	LINE_TYPE_INVITE,
	LINE_TYPE_WEBSITE,
	LINE_TYPE_DEBUG_SEND,
	LINE_TYPE_DEBUG_RECEIVE,
} LogLineType;

typedef enum {
	MEMBER_TYPE_NORMAL,
	MEMBER_TYPE_MYSELF,
} LogMemberType;

@interface LogLine : NSObject
{
	NSString* time;
	NSString* place;
	NSString* nick;
	NSString* body;
	LogLineType lineType;
	LogMemberType memberType;
	NSString* nickInfo;
	NSString* clickInfo;
	BOOL identified;
	NSInteger nickColorNumber;
	NSArray* keywords;
	NSArray* excludeWords;
}

@property (retain) NSString* time;
@property (retain) NSString* place;
@property (retain) NSString* nick;
@property (retain) NSString* body;
@property (assign) LogLineType lineType;
@property (assign) LogMemberType memberType;
@property (retain) NSString* nickInfo;
@property (retain) NSString* clickInfo;
@property (assign) BOOL identified;
@property (assign) NSInteger nickColorNumber;
@property (retain) NSArray* keywords;
@property (retain) NSArray* excludeWords;

+ (NSString*)lineTypeString:(LogLineType)type;
+ (NSString*)memberTypeString:(LogMemberType)type;

@end