#import "TableProgressIndicator.h"

@implementation TableProgressIndicator

- (void)mouseDown:(NSEvent *)e
{
	[[self superview] mouseDown:e];
}

- (void)rightMouseDown:(NSEvent *)e
{
	[[self superview] rightMouseDown:e];
}

@end