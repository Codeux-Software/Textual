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

@class GRMustacheContext;
@class GRMustacheTag;

/**
 * The protocol for your own objects that perform custom rendering.
 *
 * **Companion guide:** https://github.com/groue/GRMustache/blob/master/Guides/rendering_objects.md
 */
@protocol GRMustacheRendering <NSObject>

/**
 * This method is invoked when the receiver should be rendered by a Mustache
 * tag.
 *
 * It returns three values: the rendering itself, a boolean that says whether
 * the rendering is HTML-safe or not, and an eventual error.
 *
 * Input values are the tag that should be rendered, and the context object that
 * represents the current context stack.
 *
 * Depending on the content type of the currently rendered template, an output
 * parameter _HTMLSafe_ set to NO will have the returned string HTML-escaped.
 *
 * @param tag       The tag to be rendered
 * @param context   A context for rendering inner tags.
 * @param HTMLSafe  Upon return contains YES if the result is HTML-safe.
 * @param error     If there is an error performing the rendering, upon return
 *                  contains an NSError object that describes the problem.
 *
 * @return The rendering of the receiver for the given tag, in the given
 *         context.
 *
 * @see GRMustacheTag
 * @see GRMustacheContext
 * @see GRMustacheContentType
 */
- (NSString *)renderForMustacheTag:(GRMustacheTag *)tag
                           context:(GRMustacheContext *)context
                          HTMLSafe:(BOOL *)HTMLSafe
                             error:(NSError **)error AVAILABLE_GRMUSTACHE_VERSION_6_0_AND_LATER;

@end
