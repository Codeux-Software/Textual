// Created by Satoshi Nakagawa <psychs AT limechat DOT net> <http://github.com/psychs/limechat>
// You can redistribute it and/or modify it under the new BSD license.

#import "TextualApplication.h"

@implementation IRCSendingMessage

- (id)initWithCommand:(NSString *)aCommand
{
	if ((self = [super init])) {
		self.completeColon = YES;
		
		self.params = [NSMutableArray new];
		
		self.command = [aCommand uppercaseString];
	}
	
	return self;
}

- (void)addParameter:(NSString *)parameter
{
	[self.params safeAddObject:parameter];
}

- (NSString *)string
{
	if (NSObjectIsEmpty(self.string)) {
		BOOL forceCompleteColon = NO;
		
		if ([self.command isEqualToString:IRCCommandIndexPrivmsg] ||
			[self.command isEqualToString:IRCCommandIndexNotice]) {
			
			forceCompleteColon = YES;
		} else if ([self.command isEqualToString:IRCCommandIndexNick]
				   || [self.command isEqualToString:IRCCommandIndexMode]
				   || [self.command isEqualToString:IRCCommandIndexJoin]
				   || [self.command isEqualToString:IRCCommandIndexNames]
				   || [self.command isEqualToString:IRCCommandIndexWho]
				   || [self.command isEqualToString:IRCCommandIndexList]
				   || [self.command isEqualToString:IRCCommandIndexInvite]
				   || [self.command isEqualToString:IRCCommandIndexWhois]
				   || [self.command isEqualToString:IRCCommandIndexWhowas]
				   || [self.command isEqualToString:IRCCommandIndexIson]
				   || [self.command isEqualToString:IRCCommandIndexUser]) {
			
			self.completeColon = NO;
		}
		
		NSMutableString *d = [NSMutableString new];
		
		[d appendString:self.command];
		
		NSInteger count = [self.params count];
		
		if (NSObjectIsNotEmpty(self.params)) {
			for (NSInteger i = 0; i < (count - 1); ++i) {
				NSString *s = [self.params safeObjectAtIndex:i];
				
				[d appendString:NSStringWhitespacePlaceholder];
				[d appendString:s];
			}
			
			[d appendString:NSStringWhitespacePlaceholder];
			
			NSString *s = [self.params safeObjectAtIndex:(count - 1)];
			
			BOOL firstColonOrSpace = NO;
			
			if (NSObjectIsNotEmpty(s)) {
				UniChar c = [s characterAtIndex:0];
				
				firstColonOrSpace = (c == ' ' || c == ':');
			}
			
			if (forceCompleteColon || (self.completeColon && (NSObjectIsEmpty(s) || firstColonOrSpace))) {
				[d appendString:@":"];
			}
			
			[d appendString:s];
		}
		
		[d appendString:@"\r\n"];
		
		_string = d;
	}
	
	return self.string;
}

@end