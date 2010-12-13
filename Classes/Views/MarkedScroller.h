// Created by Satoshi Nakagawa <psychs AT limechat DOT net> <http://github.com/psychs/limechat>
// You can redistribute it and/or modify it under the new BSD license.

@interface MarkedScroller : NSScroller
{
	id dataSource;
}

@property (nonatomic, assign) id dataSource;
@end

@interface NSObject (MarkedScrollerDataSource)
- (NSArray*)markedScrollerPositions:(MarkedScroller*)sender;
- (NSColor*)markedScrollerColor:(MarkedScroller*)sender;
@end