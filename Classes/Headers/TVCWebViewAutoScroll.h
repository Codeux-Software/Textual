// Created by Allan Odgaard.

#import "TextualApplication.h"

@interface TVCWebViewAutoScroll : NSObject
@property (nonatomic, assign, readonly) NSRect lastFrame;
@property (nonatomic, assign, readonly) NSRect lastVisibleRect;
@property (nonatomic, nweak) WebFrameView *webFrame;
@end
