#import <Cocoa/Cocoa.h>

@interface MarkedScroller : NSScroller
{
	id dataSource;
}

@property (assign) id dataSource;
@end

@interface NSObject (MarkedScrollerDataSource)
- (NSArray*)markedScrollerPositions:(MarkedScroller*)sender;
- (NSColor*)markedScrollerColor:(MarkedScroller*)sender;
@end