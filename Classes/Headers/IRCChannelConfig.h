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
	NSString *encryptionKey;
}

@property (assign) ChannelType type;
@property (retain) NSString *name;
@property (retain) NSString *password;
@property (assign) BOOL autoJoin;
@property (assign) BOOL growl;
@property (assign) BOOL ihighlights;
@property (retain) NSString *mode;
@property (retain) NSString *topic;
@property (retain) NSString *encryptionKey;

- (id)initWithDictionary:(NSDictionary *)dic;
- (NSMutableDictionary *)dictionaryValue;

@end