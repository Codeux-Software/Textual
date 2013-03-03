// The MIT License
// 
// Copyright (c) 2013 Gwendal Roué
// 
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
// 
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
// 
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

#import <Foundation/Foundation.h>
#import "GRMustacheAvailabilityMacros.h"

@class GRMustacheTemplate;
@class GRMustacheInvocation;
@class GRMustacheTag;

/**
 * Objects conforming to the GRMustacheTagDelegate protocol can observe and
 * alter, the rendering of Mustache tags.
 *
 * **Companion guide:** https://github.com/groue/GRMustache/blob/master/Guides/delegate.md
 * 
 * @since v6.0
 */
@protocol GRMustacheTagDelegate<NSObject>
@optional

/**
 * Sent right before a Mustache tag renders.
 *
 * @param tag     The Mustache tag about to render.
 * @param object  The object about to be rendered.
 *
 * @return the object that should be rendered.
 *
 * @since v6.0
 */
- (id)mustacheTag:(GRMustacheTag *)tag willRenderObject:(id)object AVAILABLE_GRMUSTACHE_VERSION_6_0_AND_LATER;

/**
 * Sent right after a Mustache tag has rendered.
 *
 * @param tag        The Mustache tag that has just rendered.
 * @param object     The rendered object.
 * @param rendering  The actual rendering
 *
 * @since v6.0
 */
- (void)mustacheTag:(GRMustacheTag *)tag didRenderObject:(id)object as:(NSString *)rendering AVAILABLE_GRMUSTACHE_VERSION_6_0_AND_LATER;

/**
 * Sent right after a Mustache tag has failed rendering.
 *
 * @param tag     The Mustache tag that has just failed rendering.
 * @param object  The rendered object.
 * @param error   The error.
 *
 * @since v6.0
 */
- (void)mustacheTag:(GRMustacheTag *)tag didFailRenderingObject:(id)object withError:(NSError *)error AVAILABLE_GRMUSTACHE_VERSION_6_0_AND_LATER;

@end
