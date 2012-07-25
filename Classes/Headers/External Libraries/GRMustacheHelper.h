// The MIT License
// 
// Copyright (c) 2012 Gwendal Roué
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

#import "TextualApplication.h"

@class GRMustacheSection;


// =============================================================================
#pragma mark - <GRMustacheHelper>

/**
 * The protocol for implementing Mustache "lambda" sections.
 *
 * The responsability of a GRMustacheHelper is to render a Mustache section such
 * as `{{#bold}}...{{/bold}}`.
 *
 * When the data given to a Mustache section is a GRMustacheHelper, GRMustache
 * invokes the `renderSection:` method of the helper, and inserts the raw return
 * value in the template rendering.
 *
 * **Companion guide:** https://github.com/groue/GRMustache/blob/master/Guides/runtime/helpers.md
 *
 * @since v1.9
 */
@protocol GRMustacheHelper<NSObject>
@required

////////////////////////////////////////////////////////////////////////////////
/// @name Rendering Sections
////////////////////////////////////////////////////////////////////////////////

/**
 * Returns the rendering of a Mustache section.
 *
 * @param section   The section to render
 *
 * @return The rendering of the section
 *
 * @since v2.0
 */
- (NSString *)renderSection:(GRMustacheSection *)section AVAILABLE_GRMUSTACHE_VERSION_4_0_AND_LATER;
@end


// =============================================================================
#pragma mark - GRMustacheHelper

#if NS_BLOCKS_AVAILABLE

/**
 * The GRMustacheHelper class helps building mustache helpers without writing a
 * custom class that conforms to the GRMustacheHelper protocol.
 *
 * **Companion guide:** https://github.com/groue/GRMustache/blob/master/Guides/runtime/helpers.md
 *
 * @see GRMustacheHelper protocol
 *
 * @since v2.0
 */ 
@interface GRMustacheHelper: NSObject<GRMustacheHelper>

////////////////////////////////////////////////////////////////////////////////
/// @name Creating helper objects
////////////////////////////////////////////////////////////////////////////////

/**
 * Returns a GRMustacheHelper object that executes the provided block when
 * rendering a section.
 *
 * @param block   The block that renders a section.
 *
 * @return a GRMustacheHelper object.
 *
 * @since v2.0
 */
+ (id)helperWithBlock:(NSString *(^)(GRMustacheSection* section))block AVAILABLE_GRMUSTACHE_VERSION_4_0_AND_LATER;
@end

#endif /* if NS_BLOCKS_AVAILABLE */
