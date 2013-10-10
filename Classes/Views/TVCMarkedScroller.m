/* *********************************************************************
       _____        _               _    ___ ____   ____
      |_   _|___  _| |_ _   _  __ _| |  |_ _|  _ \ / ___|
       | |/ _ \ \/ / __| | | |/ _` | |   | || |_) | |
       | |  __/>  <| |_| |_| | (_| | |   | ||  _ <| |___
       |_|\___/_/\_\\__|\__,_|\__,_|_|  |___|_| \_\\____|

 Copyright (c) 2008 - 2010 Satoshi Nakagawa <psychs AT limechat DOT net>
 Copyright (c) 2010 — 2013 Codeux Software & respective contributors.
        Please see Contributors.rtfd and Acknowledgements.rtfd

 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions
 are met:

    * Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the
      documentation and/or other materials provided with the distribution.
    * Neither the name of the Textual IRC Client & Codeux Software nor the
      names of its contributors may be used to endorse or promote products
      derived from this software without specific prior written permission.

 THIS SOFTWARE IS PROVIDED BY THE AUTHOR AND CONTRIBUTORS ``AS IS'' AND
 ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 ARE DISCLAIMED. IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE LIABLE
 FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
 OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
 LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
 OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
 SUCH DAMAGE.

 *********************************************************************** */

#import "TextualApplication.h"

const static int INSET = 3;

@implementation TVCMarkedScroller

+ (BOOL)isCompatibleWithOverlayScrollers
{
  return self == [TVCMarkedScroller class];
}

- (void)updateScroller
{
  self.markData = [self.dataSource markedScrollerPositions:self];
}

- (void)drawContentInMarkedScroller
{
  if (!self.dataSource) return;
  if (![self.dataSource respondsToSelector:@selector(markedScrollerPositions:)]) return;
  if (![self.dataSource respondsToSelector:@selector(markedScrollerColor:)]) return;
  if (!self.markData || !self.markData.count) return;

  NSScrollView* scrollView = (NSScrollView*)[self superview];
  int contentHeight = [[scrollView contentView] documentRect].size.height;

  //
  // prepare transform
  //
  NSAffineTransform* transform = [NSAffineTransform transform];
  int width = [self rectForPart:NSScrollerKnobSlot].size.width - INSET * 2;
  CGFloat scale = [self rectForPart:NSScrollerKnobSlot].size.height / (CGFloat)contentHeight;
  int offset = [self rectForPart:NSScrollerKnobSlot].origin.y;
  int indent = [self rectForPart:NSScrollerKnobSlot].origin.x + INSET;
  [transform scaleXBy:1 yBy:scale];
  [transform translateXBy:0 yBy:offset];

  //
  // make lines
  //
  NSMutableArray* lines = [NSMutableArray array];
  NSPoint prev = NSMakePoint(-1, -1);

  for (NSNumber* e in self.markData) {
    int i = [e intValue];
    NSPoint pt = NSMakePoint(indent, i);
    pt = [transform transformPoint:pt];
    pt.x = ceil(pt.x);
    pt.y = ceil(pt.y) + 0.5;
    if (pt.x == prev.x && pt.y == prev.y) continue;
    prev = pt;
    NSBezierPath* line = [NSBezierPath bezierPath];
    [line setLineWidth:1];
    [line moveToPoint:pt];
    [line relativeLineToPoint:NSMakePoint(width, 0)];
    [lines addObject:line];
  }

  //
  // draw lines
  //
  NSColor* color = [self.dataSource markedScrollerColor:self];
  [color set];

  for (NSBezierPath* e in lines) {
    [e stroke];
  }
}

- (void)drawKnob
{
  [self drawContentInMarkedScroller];
  [super drawKnob];
}

@end
