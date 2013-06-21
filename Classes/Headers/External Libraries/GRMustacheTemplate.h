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

@class GRMustacheContext;

/**
 * The GRMustacheTemplate class provides with Mustache template rendering
 * services.
 * 
 * **Companion guide:** https://github.com/groue/GRMustache/blob/master/Guides/templates.md
 * 
 * @since v1.0
 */
@interface GRMustacheTemplate: NSObject {
@private
    NSArray *_components;
    GRMustacheContext *_baseContext;
    GRMustacheContentType _contentType;
}


////////////////////////////////////////////////////////////////////////////////
/// @name Creating Templates
////////////////////////////////////////////////////////////////////////////////

/**
 * Parses a template string, and returns a compiled template.
 *
 * @param templateString  The template string.
 * @param error           If there is an error loading or parsing template and
 *                        partials, upon return contains an NSError object that
 *                        describes the problem.
 *
 * @return A GRMustacheTemplate instance.
 *
 * @since v1.11
 */
+ (instancetype)templateFromString:(NSString *)templateString error:(NSError **)error AVAILABLE_GRMUSTACHE_VERSION_6_0_AND_LATER;

/**
 * Parses a template file, and returns a compiled template.
 *
 * The template at path must be encoded in UTF8. See the
 * GRMustacheTemplateRepository class for more encoding options.
 *
 * @param path      The path of the template.
 * @param error     If there is an error loading or parsing template and
 *                  partials, upon return contains an NSError object that
 *                  describes the problem.
 *
 * @return A GRMustacheTemplate instance.
 *
 * @see GRMustacheTemplateRepository
 *
 * @since v1.11
 */
+ (instancetype)templateFromContentsOfFile:(NSString *)path error:(NSError **)error AVAILABLE_GRMUSTACHE_VERSION_6_0_AND_LATER;

/**
 * Parses a template file, and returns a compiled template.
 *
 * The template at url must be encoded in UTF8. See the
 * GRMustacheTemplateRepository class for more encoding options.
 *
 * @param url       The URL of the template.
 * @param error     If there is an error loading or parsing template and
 *                  partials, upon return contains an NSError object that
 *                  describes the problem.
 *
 * @return A GRMustacheTemplate instance.
 *
 * @see GRMustacheTemplateRepository
 *
 * @since v1.11
 */
+ (instancetype)templateFromContentsOfURL:(NSURL *)url error:(NSError **)error AVAILABLE_GRMUSTACHE_VERSION_6_0_AND_LATER;

/**
 * Parses a bundle resource template, and returns a compiled template.
 *
 * If you provide nil as a bundle, the resource will be looked in the main
 * bundle.
 *
 * The template resource must be encoded in UTF8. See the
 * GRMustacheTemplateRepository class for more encoding options.
 *
 * @param name      The name of a bundle resource of extension "mustache".
 * @param bundle    The bundle where to look for the template resource. If nil,
 *                  the main bundle is used.
 * @param error     If there is an error loading or parsing template and
 *                  partials, upon return contains an NSError object that
 *                  describes the problem.
 *
 * @return A GRMustacheTemplate instance.
 *
 * @see GRMustacheTemplateRepository
 *
 * @since v1.11
 */
+ (instancetype)templateFromResource:(NSString *)name bundle:(NSBundle *)bundle error:(NSError **)error AVAILABLE_GRMUSTACHE_VERSION_6_0_AND_LATER;


////////////////////////////////////////////////////////////////////////////////
/// @name Configuring Templates
////////////////////////////////////////////////////////////////////////////////

/**
 * The template's base context: all rendering start from this context.
 *
 * Its default value comes from the configuration of the source template
 * repository. Unless specified, it contains the GRMustache standard library.
 *
 * @see GRMustacheContext
 * @see GRMustacheConfiguration
 * @see GRMustacheTemplateRepository
 * @see [GRMustache standardLibrary]
 *
 * @since v6.0
 */
@property (nonatomic, retain) GRMustacheContext *baseContext AVAILABLE_GRMUSTACHE_VERSION_6_0_AND_LATER;


////////////////////////////////////////////////////////////////////////////////
/// @name Rendering Templates
////////////////////////////////////////////////////////////////////////////////


/**
 * Renders an object from a template string.
 *
 * @param object          An object used for interpreting Mustache tags.
 * @param templateString  The template string.
 * @param error           If there is an error during rendering, upon return
 *                        contains an NSError object that describes the problem.
 *
 * @return A string containing the rendered template.
 *
 * @since v1.0
 */
+ (NSString *)renderObject:(id)object fromString:(NSString *)templateString error:(NSError **)error AVAILABLE_GRMUSTACHE_VERSION_6_0_AND_LATER;

/**
 * Renders an object from a bundle resource template.
 *
 * If you provide nil as a bundle, the resource will be looked in the main
 * bundle, with a "mustache" extension.
 *
 * The template resource must be encoded in UTF8. See the
 * GRMustacheTemplateRepository class for more encoding options.
 *
 * @param object  An object used for interpreting Mustache tags.
 * @param name    The name of a bundle resource of extension "mustache".
 * @param bundle  The bundle where to look for the template resource. If nil,
 *                the main bundle is used.
 * @param error   If there is an error during rendering, upon return contains an
 *                NSError object that describes the problem.
 *
 * @return A string containing the rendered template.
 *
 * @see GRMustacheTemplateRepository
 *
 * @since v1.0
 */
+ (NSString *)renderObject:(id)object fromResource:(NSString *)name bundle:(NSBundle *)bundle error:(NSError **)error AVAILABLE_GRMUSTACHE_VERSION_6_0_AND_LATER;

/**
 * Renders a template with a context stack initialized with the provided object
 * on top of the base context.
 *
 * @param object  An object used for interpreting Mustache tags.
 * @param error   If there is an error rendering the template and its
 *                partials, upon return contains an NSError object that
 *                describes the problem.
 *
 * @return A string containing the rendered template.
 *
 * @since v6.0
 */
- (NSString *)renderObject:(id)object error:(NSError **)error AVAILABLE_GRMUSTACHE_VERSION_6_0_AND_LATER;

/**
 * Renders a template with a context stack initialized with the provided objects
 * on top of the base context.
 *
 * @param objects  An array of context objects for interpreting Mustache tags.
 * @param error    If there is an error rendering the template and its
 *                 partials, upon return contains an NSError object that
 *                 describes the problem.
 *
 * @return A string containing the rendered template.
 *
 * @since v6.0
 */
- (NSString *)renderObjectsFromArray:(NSArray *)objects error:(NSError **)error AVAILABLE_GRMUSTACHE_VERSION_6_0_AND_LATER;

/**
 * Returns the rendering of the receiver, given a rendering context.
 *
 * @param context   A rendering context.
 * @param HTMLSafe  Upon return contains YES or NO, depending on the content
 *                  type of the template, as set by the configuration of the
 *                  source template repository. HTML templates yield YES, text
 *                  templates yield NO.
 * @param error     If there is an error rendering the tag, upon return contains
 *                  an NSError object that describes the problem.
 *
 * @return The rendering of the template.
 *
 * @see GRMustacheConfiguration
 * @see GRMustacheContentType
 *
 * @since v6.0
 */
- (NSString *)renderContentWithContext:(GRMustacheContext *)context HTMLSafe:(BOOL *)HTMLSafe error:(NSError **)error AVAILABLE_GRMUSTACHE_VERSION_6_0_AND_LATER;

@end
