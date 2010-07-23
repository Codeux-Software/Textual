#import <Cocoa/Cocoa.h>

typedef enum {
	CHANNEL_TYPE_CHANNEL,
	CHANNEL_TYPE_TALK,
} ChannelType;

@interface IRCChannelConfig : NSObject <NSMutableCopying>
{
	ChannelType type;
	
	NSString* name;
	NSString* password;
	
	BOOL autoJoin;
	BOOL growl;
	
	NSString* mode;
	NSString* topic;
}

@property (assign) ChannelType type;
@property (retain) NSString* name;
@property (retain) NSString* password;
@property (assign) BOOL autoJoin;
@property (assign) BOOL growl;
@property (retain) NSString* mode;
@property (retain) NSString* topic;

- (id)initWithDictionary:(NSDictionary*)dic;
- (NSMutableDictionary*)dictionaryValue;

@end