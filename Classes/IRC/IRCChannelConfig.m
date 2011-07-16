// Created by Satoshi Nakagawa <psychs AT limechat DOT net> <http://github.com/psychs/limechat>
// Modifications by Codeux Software <support AT codeux DOT com> <https://github.com/codeux/Textual>
// You can redistribute it and/or modify it under the new BSD license.

@implementation IRCChannelConfig

@synthesize type;
@synthesize name;
@synthesize password;
@synthesize autoJoin;
@synthesize growl;
@synthesize mode;
@synthesize topic;
@synthesize ihighlights;
@synthesize encryptionKey;
@synthesize iJPQActivity;
@synthesize inlineImages;

- (id)init
{
	if ((self = [super init])) {
		type = CHANNEL_TYPE_CHANNEL;
		
        inlineImages = NO;
        iJPQActivity = NO;
        ihighlights = NO;
		autoJoin = YES;
		growl = YES;
		
		name = NSNullObject;
		mode = NSNullObject;
		topic = NSNullObject;
		password = NSNullObject;
		encryptionKey = NSNullObject;
	}
    
	return self;
}

- (id)initWithDictionary:(NSDictionary *)dic
{
	[self init];
    
    type = [dic integerForKey:@"type"];
    
    name = (([[dic stringForKey:@"name"] retain]) ?: NSNullObject);
    password = (([[dic stringForKey:@"password"] retain]) ?: NSNullObject);
    
    growl = [dic boolForKey:@"growl"];
    autoJoin = [dic boolForKey:@"auto_join"];
    ihighlights = [dic boolForKey:@"ignore_highlights"];
    inlineImages = [dic boolForKey:@"disable_images"];
    iJPQActivity = [dic boolForKey:@"ignore_join,leave"];
    
    mode = (([[dic stringForKey:@"mode"] retain]) ?: NSNullObject);
    topic = (([[dic stringForKey:@"topic"] retain]) ?: NSNullObject);
    encryptionKey = (([[dic stringForKey:@"encryptionKey"] retain]) ?: NSNullObject);
    
    return self;
}

- (void)dealloc
{
	[name drain];
	[mode drain];
	[topic drain];
	[password drain];
	[encryptionKey drain];
	
	[super dealloc];
}

- (NSMutableDictionary *)dictionaryValue
{
	NSMutableDictionary *dic = [NSMutableDictionary dictionary];
	
	[dic setInteger:type forKey:@"type"];
	
	[dic setBool:growl forKey:@"growl"];
	[dic setBool:autoJoin forKey:@"auto_join"];
    [dic setBool:ihighlights forKey:@"ignore_highlights"];
    [dic setBool:inlineImages forKey:@"disable_images"];
    [dic setBool:iJPQActivity forKey:@"ignore_join,leave"];
	
	if (name) [dic setObject:name forKey:@"name"];
	if (password) [dic setObject:password forKey:@"password"];
	if (mode) [dic setObject:mode forKey:@"mode"];
	if (topic) [dic setObject:topic forKey:@"topic"];
	if (encryptionKey) [dic setObject:encryptionKey forKey:@"encryptionKey"];
	
	return dic;
}

- (id)mutableCopyWithZone:(NSZone *)zone
{
	return [[IRCChannelConfig allocWithZone:zone] initWithDictionary:[self dictionaryValue]];
}

@end