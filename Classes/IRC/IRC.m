#import "IRC.h"

@implementation IRC

@synthesize commandIndex;

- (void)dealloc
{
	[commandIndex release];
	[super dealloc];
}

- (id)init
{
	if (self = [super init]) {
	}
	return self;
}

@end