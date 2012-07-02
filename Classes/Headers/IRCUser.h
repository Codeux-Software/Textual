// Created by Satoshi Nakagawa <psychs AT limechat DOT net> <http://github.com/psychs/limechat>
// Modifications by Codeux Software <support AT codeux DOT com> <https://github.com/codeux/Textual>
// You can redistribute it and/or modify it under the new BSD license.

#import "TextualApplication.h"

@interface IRCUser : NSObject
@property (nonatomic, weak) IRCISupportInfo *supportInfo;
@property (nonatomic, strong) NSString *nick;
@property (nonatomic, strong) NSString *username;
@property (nonatomic, strong) NSString *address;
@property (nonatomic, assign) BOOL q;
@property (nonatomic, assign) BOOL a;
@property (nonatomic, assign) BOOL o;
@property (nonatomic, assign) BOOL h;
@property (nonatomic, assign) BOOL v;
@property (nonatomic, assign) BOOL isMyself;
@property (nonatomic, assign) char mark;
@property (nonatomic, assign) BOOL isOp;
@property (nonatomic, assign) BOOL isHalfOp;
@property (nonatomic, assign) BOOL isIRCOp;
@property (nonatomic, assign) NSInteger colorNumber;
@property (nonatomic, assign) CGFloat totalWeight;
@property (nonatomic, assign) CGFloat incomingWeight;
@property (nonatomic, assign) CGFloat outgoingWeight;
@property (nonatomic, assign) CFAbsoluteTime lastFadedWeights;

- (BOOL)hasMode:(char)mode;
- (NSString *)banMask;

- (void)outgoingConversation;
- (void)incomingConversation;
- (void)conversation;

- (NSComparisonResult)compare:(IRCUser *)other;
@end