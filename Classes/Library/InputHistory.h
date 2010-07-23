#import <Cocoa/Cocoa.h>

@interface InputHistory : NSObject
{
	NSMutableArray* buf;
	NSInteger pos;
}

@property (retain) NSMutableArray* buf;
@property NSInteger pos;

- (void)add:(NSString*)s;
- (NSString*)up:(NSString*)s;
- (NSString*)down:(NSString*)s;
@end