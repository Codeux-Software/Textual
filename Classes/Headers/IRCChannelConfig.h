// Created by Satoshi Nakagawa <psychs AT limechat DOT net> <http://github.com/psychs/limechat>
// Modifications by Codeux Software <support AT codeux DOT com> <https://github.com/codeux/Textual>
// You can redistribute it and/or modify it under the new BSD license.
// Converted to ARC Support on Thursday, June 09, 2012

typedef enum {
	IRCChannelNormalType,
	IRCChannelPrivateMessageType,
} IRCChannelType;

@interface IRCChannelConfig : NSObject <NSMutableCopying>
@property (nonatomic, assign) IRCChannelType type;
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