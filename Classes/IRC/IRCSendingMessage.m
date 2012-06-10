// Created by Satoshi Nakagawa <psychs AT limechat DOT net> <http://github.com/psychs/limechat>
// You can redistribute it and/or modify it under the new BSD license.
// Converted to ARC Support on Thursday, June 09, 2012

@implementation IRCSendingMessage

@synthesize string;
@synthesize command;
@synthesize params;
@synthesize completeColon;

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
		
		if ([self.command isEqualToString:IRCCI_PRIVMSG] ||
			[self.command isEqualToString:IRCCI_NOTICE]) {
			
			forceCompleteColon = YES;
		} else if ([self.command isEqualToString:IRCCI_NICK]
				 || [self.command isEqualToString:IRCCI_MODE]
				 || [self.command isEqualToString:IRCCI_JOIN]
				 || [self.command isEqualToString:IRCCI_NAMES]
				 || [self.command isEqualToString:IRCCI_WHO]
				 || [self.command isEqualToString:IRCCI_LIST]
				 || [self.command isEqualToString:IRCCI_INVITE]
				 || [self.command isEqualToString:IRCCI_WHOIS]
				 || [self.command isEqualToString:IRCCI_WHOWAS]
				 || [self.command isEqualToString:IRCCI_ISON]
				 || [self.command isEqualToString:IRCCI_USER]) {
			
			self.completeColon = NO;
		}
		
		NSMutableString *d = [NSMutableString new];
		
		[d appendString:self.command];
		
		NSInteger count = [self.params count];
		
		if (NSObjectIsNotEmpty(self.params)) {
			for (NSInteger i = 0; i < (count - 1); ++i) {
				NSString *s = [self.params safeObjectAtIndex:i];
				
				[d appendString:NSWhitespaceCharacter];
				[d appendString:s];
			}
			
			[d appendString:NSWhitespaceCharacter];
			
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
		
		string = d;
	}
	
	return self.string;
}

@end