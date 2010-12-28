// Created by Satoshi Nakagawa <psychs AT limechat DOT net> <http://github.com/psychs/limechat>
// You can redistribute it and/or modify it under the new BSD license.

@implementation IRCSendingMessage

@synthesize command;
@synthesize params;
@synthesize completeColon;

- (id)initWithCommand:(NSString *)aCommand
{
	if ((self = [super init])) {
		command = [[aCommand uppercaseString] retain];
		completeColon = YES;
		params = [NSMutableArray new];
	}
	return self;
}

- (void)dealloc
{
	[command release];
	[params release];
	[super dealloc];
}

- (void)addParameter:(NSString *)parameter
{
	[params addObject:parameter];
}

- (NSString *)string
{
	if (!string) {
		BOOL forceCompleteColon = NO;
		
		if ([command isEqualToString:IRCCI_PRIVMSG] ||[command isEqualToString:IRCCI_NOTICE]) {
			forceCompleteColon = YES;
		} else if ([command isEqualToString:IRCCI_NICK]
				 || [command isEqualToString:IRCCI_MODE]
				 || [command isEqualToString:IRCCI_JOIN]
				 || [command isEqualToString:IRCCI_NAMES]
				 || [command isEqualToString:IRCCI_WHO]
				 || [command isEqualToString:IRCCI_LIST]
				 || [command isEqualToString:IRCCI_INVITE]
				 || [command isEqualToString:IRCCI_WHOIS]
				 || [command isEqualToString:IRCCI_WHOWAS]
				 || [command isEqualToString:IRCCI_ISON]
				 || [command isEqualToString:IRCCI_USER]) {
			completeColon = NO;
		}
		
		NSMutableString *d = [NSMutableString new];
		
		[d appendString:command];
		
		NSInteger count = [params count];
		
		if (count > 0) {
			for (NSInteger i = 0; i < count-1; ++i) {
				NSString *s = [params safeObjectAtIndex:i];
				
				[d appendString:@" "];
				[d appendString:s];
			}
			
			[d appendString:@" "];
			NSString *s = [params safeObjectAtIndex:count-1];
			NSInteger len = s.length;
			BOOL firstColonOrSpace = NO;
			if (len > 0) {
				UniChar c = [s characterAtIndex:0];
				firstColonOrSpace = (c == ' ' || c == ':');
			}
			
			if (forceCompleteColon || completeColon && (s.length == 0 || firstColonOrSpace)) {
				[d appendString:@":"];
			}
			[d appendString:s];
		}
		
		[d appendString:@"\r\n"];
		
		string = d;
	}
	return string;
}

@end