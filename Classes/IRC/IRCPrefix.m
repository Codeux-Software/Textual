#import "IRCPrefix.h"

@implementation IRCPrefix

@synthesize raw;
@synthesize nick;
@synthesize user;
@synthesize address;
@synthesize isServer;

- (id)init
{
	if (self = [super init]) {
		raw = @"";
		nick = @"";
		user = @"";
		address = @"";
	}
	return self;
}

- (void)dealloc
{
	[raw release];
	[nick release];
	[user release];
	[address release];
	[super dealloc];
}

@end