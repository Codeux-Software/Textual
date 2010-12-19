// Created by Satoshi Nakagawa <psychs AT limechat DOT net> <http://github.com/psychs/limechat>
// Modifications by Codeux Software <support AT codeux DOT com> <https://github.com/codeux/Textual>
// You can redistribute it and/or modify it under the new BSD license.

typedef enum {
	CHANNEL_TYPE_CHANNEL,
	CHANNEL_TYPE_TALK,
} ChannelType;

@interface IRCChannelConfig : NSObject <NSMutableCopying>
{
	ChannelType type;
	
	NSString *name;
	NSString *password;
	
	BOOL growl;
	BOOL autoJoin;
    BOOL ihighlights;
	
	NSString *mode;
	NSString *topic;
}

@property (nonatomic, assign) ChannelType type;
@property (nonatomic, retain) NSString *name;
@property (nonatomic, retain) NSString *password;
@property (nonatomic, assign) BOOL autoJoin;
@property (nonatomic, assign) BOOL growl;
@property (nonatomic, assign) BOOL ihighlights;
@property (nonatomic, retain) NSString *mode;
@property (nonatomic, retain) NSString *topic;

- (id)initWithDictionary:(NSDictionary *)dic;
- (NSMutableDictionary *)dictionaryValue;

@end