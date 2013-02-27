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
#import "GRMustacheConfiguration.h"

@class GRMustacheTemplateRepository;

/**
 * The types of Mustache tags
 *
 * @since v6.0
 */
typedef NS_ENUM(NSUInteger, GRMustacheTagType) {
    /**
     * The type for variable tags such as {{ name }}
     *
     * @since v6.0
     */
    GRMustacheTagTypeVariable = 1 << 1 AVAILABLE_GRMUSTACHE_VERSION_6_0_AND_LATER,
    
    /**
     * The type for section tags such as {{# name }}...{{/}}
     *
     * @since v6.0
     */
    GRMustacheTagTypeSection = 1 << 2 AVAILABLE_GRMUSTACHE_VERSION_6_0_AND_LATER,
    
    /**
     * The type for overridable section tags such as {{$ name }}...{{/}}
     *
     * @since v6.0
     */
    GRMustacheTagTypeOverridableSection = 1 << 3 AVAILABLE_GRMUSTACHE_VERSION_6_0_AND_LATER,
    
    /**
     * The type for inverted section tags such as {{^ name }}...{{/}}
     *
     * @since v6.0
     */
    GRMustacheTagTypeInvertedSection = 1 << 4 AVAILABLE_GRMUSTACHE_VERSION_6_0_AND_LATER,
} AVAILABLE_GRMUSTACHE_VERSION_6_0_AND_LATER;


/**
 * GRMustacheTag instances represent Mustache tags that render values, such as
 * a variable tag {{ name }}, or a section tag {{# name }}...{{/}).
 *
 * **Companion guide:** https://github.com/groue/GRMustache/blob/master/Guides/rendering_objects.md
 */
@interface GRMustacheTag: NSObject {
@private
    id _expression;
    GRMustacheTemplateRepository *_templateRepository;
    GRMustacheContentType _contentType;
}

/**
 * The type of the tag
 */
@property (nonatomic, readonly) GRMustacheTagType type AVAILABLE_GRMUSTACHE_VERSION_6_0_AND_LATER;

/**
 * The template repository that did provide the template string from which the
 * receiver tag has been extracted.
 *
 * Caveat: Make sure you own (retain) template repositories. Don't use templates
 * returned by methods like `[GRMustacheTemplate templateFrom...]`: they return
 * autoreleased templates with an implicit autoreleased repository that will
 * eventually be deallocated when your rendering object tries to access it.
 *
 * @see GRMustacheTemplateRepository
 */
@property (nonatomic, readonly) GRMustacheTemplateRepository *templateRepository AVAILABLE_GRMUSTACHE_VERSION_6_0_AND_LATER;

/**
 * The literal and unprocessed inner content of the tag, the `...` in
 * `{{# name }}...{{/}}`.
 *
 * Variable tags such as `{{ name }}` have no inner content: their inner
 * template string is the empty string.
 */
@property (nonatomic, readonly) NSString *innerTemplateString AVAILABLE_GRMUSTACHE_VERSION_6_0_AND_LATER;

/**
 * Returns the rendering of the tag's inner content, rendering all inner
 * Mustache tags with the rendering context argument.
 *
 * Note that variable tags such as `{{ name }}` have no inner content, and
 * return the empty string.
 *
 * @param context   A context for rendering inner tags.
 * @param HTMLSafe  Upon return contains YES or NO, depending on the content
 *                  type of the tag's template, as set by the configuration of
 *                  the source template repository. HTML templates yield YES,
 *                  text templates yield NO.
 * @param error     If there is an error rendering the tag, upon return contains
 *                  an NSError object that describes the problem.
 *
 * @see GRMustacheConfiguration
 * @see GRMustacheContentType
 *
 * @return The rendering of the tag's inner content.
 */
- (NSString *)renderContentWithContext:(GRMustacheContext *)context HTMLSafe:(BOOL *)HTMLSafe error:(NSError **)error AVAILABLE_GRMUSTACHE_VERSION_6_0_AND_LATER;

@end
