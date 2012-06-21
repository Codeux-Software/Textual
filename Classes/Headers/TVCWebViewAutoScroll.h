// Created by Allan Odgaard.
// Converted to ARC Support on June 07, 2012

#import "TextualApplication.h"

@interface TVCWebViewAutoScroll : NSObject
@property (nonatomic, assign) NSRect lastFrame;
@property (nonatomic, assign) NSRect lastVisibleRect;
@property (nonatomic, weak) WebFrameView *webFrame;
@end