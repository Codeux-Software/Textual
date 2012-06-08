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
    BOOL inlineImages;
    BOOL iJPQActivity;
	
	NSString *mode;
	NSString *topic;
	NSString *encryptionKey;
}

@property (nonatomic, assign) ChannelType type;
@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSString *password;
@property (nonatomic, assign) BOOL autoJoin;
@property (nonatomic, assign) BOOL growl;
@property (nonatomic, assign) BOOL ihighlights;
@property (nonatomic, assign) BOOL inlineImages;
@property (nonatomic, assign) BOOL iJPQActivity;
@property (nonatomic, strong) NSString *mode;
@property (nonatomic, strong) NSString *topic;
@property (nonatomic, strong) NSString *encryptionKey;

- (id)initWithDictionary:(NSDictionary *)dic;
- (NSMutableDictionary *)dictionaryValue;

@end