// Created by Satoshi Nakagawa <psychs AT limechat DOT net> <http://github.com/psychs/limechat>
// You can redistribute it and/or modify it under the new BSD license.
// Converted to ARC Support on June 07, 2012

#import "TextualApplication.h"

@interface TVCThinSplitView : NSSplitView
@property (nonatomic, assign) NSInteger fixedViewIndex;
@property (nonatomic, assign) NSInteger position;
@property (nonatomic, assign) BOOL inverted;
@property (nonatomic, assign) BOOL hidden;
@property (nonatomic, nonatomic) NSInteger altDividerThickness;
@end