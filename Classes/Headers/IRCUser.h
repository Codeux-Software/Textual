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

@property (assign) IRCISupportInfo *supportInfo;
@property (retain) NSString *nick;
@property (retain) NSString *username;
@property (retain) NSString *address;
@property (assign) BOOL q;
@property (assign) BOOL a;
@property (assign) BOOL o;
@property (assign) BOOL h;
@property (assign) BOOL v;
@property (assign) BOOL isMyself;
@property (readonly) char mark;
@property (readonly) BOOL isOp;
@property (readonly) BOOL isHalfOp; 
@property (readonly) NSInteger colorNumber;
@property (readonly) CGFloat totalWeight;
@property (readonly) CGFloat incomingWeight;
@property (readonly) CGFloat outgoingWeight;
@property (assign) CFAbsoluteTime lastFadedWeights;

- (BOOL)hasMode:(char)mode;
- (NSString *)banMask;

- (void)outgoingConversation;
- (void)incomingConversation;
- (void)conversation;

- (NSComparisonResult)compare:(IRCUser *)other;
@end