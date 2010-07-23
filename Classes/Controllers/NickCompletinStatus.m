#import "NickCompletinStatus.h"

@implementation NickCompletinStatus

@synthesize text;
@synthesize range;

- (id)init
{
	if (self = [super init]) {
		[self clear];
	}
	return self;
}

- (void)dealloc
{
	[text release];
	[super dealloc];
}

- (void)clear
{
	self.text = nil;
	range = NSMakeRange(NSNotFound, 0);
}

@end