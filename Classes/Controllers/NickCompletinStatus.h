#import <Foundation/Foundation.h>

@interface NickCompletinStatus : NSObject
{
	NSString* text;
	NSRange range;
}

@property (retain) NSString* text;
@property (assign) NSRange range;

- (void)clear;
@end