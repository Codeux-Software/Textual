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

@class GRMustacheTemplate;
@class GRMustacheInvocation;

/**
 * The various ways GRMustache can interpret a value.
 *
 * **Companion guide:** https://github.com/groue/GRMustache/blob/master/Guides/delegate.md
 *
 * @see GRMustacheTemplateDelegate
 * 
 * @since v4.1
 */
typedef enum {
    /**
     * The value is interpreted for section rendering: whether it is a NSNumber,
     * an object conforming to the NSFastEnumeration protocol, an object
     * conforming to the GRMustacheHelper protocol, or any other value, the
     * section will render differently.
     *
     * @since v4.1
     */
    GRMustacheInterpretationSection,
    
    /**
     * The value is interpreted for variable substitution, for tags such as
     * `{{name}}`.
     *
     * @since v4.1
     */
    GRMustacheInterpretationVariable,
} GRMustacheInterpretation;

/**
 * The protocol for a GRMustacheTemplate's delegate.
 *
 * The delegate's can observe, and alter, the rendering of a template.
 *
 * **Companion guide:** https://github.com/groue/GRMustache/blob/master/Guides/delegate.md
 * 
 * @since v1.12
 */
@protocol GRMustacheTemplateDelegate<NSObject>
@optional

////////////////////////////////////////////////////////////////////////////////
/// @name Observing the Full Template Rendering
////////////////////////////////////////////////////////////////////////////////

/**
 * Sent right before a template starts rendering.
 *
 * @param template  The template that is about to render.
 *
 * @since v1.12
 */
- (void)templateWillRender:(GRMustacheTemplate *)template AVAILABLE_GRMUSTACHE_VERSION_4_0_AND_LATER;

/**
 * Sent right after a template has finished rendering.
 *
 * @param template  The template that did render.
 *
 * @since v1.12
 */
- (void)templateDidRender:(GRMustacheTemplate *)template AVAILABLE_GRMUSTACHE_VERSION_4_0_AND_LATER;


////////////////////////////////////////////////////////////////////////////////
/// @name Observing the Rendering of individual Mustache tags
////////////////////////////////////////////////////////////////////////////////

/**
 * Sent right before GRMustache interprets and renders a value (Deprecated in
 * GRMustache 4.1).
 *
 * @param template    The template that is about to interpret a value.
 * @param invocation  The invocation object providing information about the
 *                    value.
 *
 * @see GRMustacheInvocation
 *
 * @since v1.12
 * @deprecated v4.1
 */
- (void)template:(GRMustacheTemplate *)template willRenderReturnValueOfInvocation:(GRMustacheInvocation *)invocation AVAILABLE_GRMUSTACHE_VERSION_4_0_AND_LATER_BUT_DEPRECATED_IN_GRMUSTACHE_VERSION_4_1;

/**
 * Sent right after GRMustache has interpreted and rendered a value (Deprecated
 * in GRMustache 4.1).
 *
 * @param template    The template that has rendered a value.
 * @param invocation  The invocation object providing information about the
 *                    value.
 *
 * @see GRMustacheInvocation
 *
 * @since v1.12
 * @deprecated v4.1
 */
- (void)template:(GRMustacheTemplate *)template didRenderReturnValueOfInvocation:(GRMustacheInvocation *)invocation AVAILABLE_GRMUSTACHE_VERSION_4_0_AND_LATER_BUT_DEPRECATED_IN_GRMUSTACHE_VERSION_4_1;

/**
 * Sent right before GRMustache interprets and renders a value.
 *
 * @param template        The template that is about to interpret a value.
 * @param invocation      The invocation object providing information about the
 *                        value.
 * @param interpretation  The way GRMustache will interpret the value.
 *
 * @see GRMustacheInvocation
 * @since v4.1
 */
- (void)template:(GRMustacheTemplate *)template willInterpretReturnValueOfInvocation:(GRMustacheInvocation *)invocation as:(GRMustacheInterpretation)interpretation AVAILABLE_GRMUSTACHE_VERSION_4_1_AND_LATER;

/**
 * Sent right after GRMustache has interpreted and rendered a value.
 *
 * @param template        The template that has rendered a value.
 * @param invocation      The invocation object providing information about the
 *                        value.
 * @param interpretation  The way GRMustache has interpreted the value.
 *
 * @see GRMustacheInvocation
 * @since v4.1
 */
- (void)template:(GRMustacheTemplate *)template didInterpretReturnValueOfInvocation:(GRMustacheInvocation *)invocation as:(GRMustacheInterpretation)interpretation AVAILABLE_GRMUSTACHE_VERSION_4_1_AND_LATER;
@end
