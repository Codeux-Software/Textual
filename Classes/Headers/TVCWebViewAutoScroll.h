// Created by Allan Odgaard.

#import "TextualApplication.h"

@interface TVCWebViewAutoScroll : NSObject
@property (nonatomic, assign) NSRect lastFrame;
@property (nonatomic, assign) NSRect lastVisibleRect;
@property (nonatomic, nweak) WebFrameView *webFrame;
@end
