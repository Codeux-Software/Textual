// Created by Satoshi Nakagawa <psychs AT limechat DOT net> <http://github.com/psychs/limechat>
// Modifications by Codeux Software <support AT codeux DOT com> <https://github.com/codeux/Textual>
// You can redistribute it and/or modify it under the new BSD license.

@class IRCISupportInfo;

@interface IRCUser : NSObject
{
	IRCISupportInfo *supportInfo;
	
	NSString *nick;
	NSString *username;
	NSString *address;
	
	BOOL q;
	BOOL a;
	BOOL o;
	BOOL h;
	BOOL v;
	
	BOOL isMyself;
	
	NSInteger colorNumber;
	
	CGFloat incomingWeight;
	CGFloat outgoingWeight;
	
	CFAbsoluteTime lastFadedWeights;
}

@property (nonatomic, assign) IRCISupportInfo *supportInfo;
@property (nonatomic, retain) NSString *nick;
@property (nonatomic, retain) NSString *username;
@property (nonatomic, retain) NSString *address;
@property (nonatomic, assign) BOOL q;
@property (nonatomic, assign) BOOL a;
@property (nonatomic, assign) BOOL o;
@property (nonatomic, assign) BOOL h;
@property (nonatomic, assign) BOOL v;
@property (nonatomic, assign) BOOL isMyself;
@property (nonatomic, readonly) char mark;
@property (nonatomic, readonly) BOOL isOp;
@property (nonatomic, readonly) BOOL isHalfOp; 
@property (nonatomic, readonly) NSInteger colorNumber;
@property (nonatomic, readonly) CGFloat totalWeight;
@property (nonatomic, readonly) CGFloat incomingWeight;
@property (nonatomic, readonly) CGFloat outgoingWeight;
@property (nonatomic, assign) CFAbsoluteTime lastFadedWeights;

- (BOOL)hasMode:(char)mode;
- (NSString *)banMask;

- (void)outgoingConversation;
- (void)incomingConversation;
- (void)conversation;

- (NSComparisonResult)compare:(IRCUser *)other;
@end