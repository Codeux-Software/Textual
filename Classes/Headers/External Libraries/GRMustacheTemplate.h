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
}

////////////////////////////////////////////////////////////////////////////////
/// @name Setting the Base Context
////////////////////////////////////////////////////////////////////////////////

/**
 * The template's base context: all rendering start from this context.
 *
 * Its default value is a context containing the GRMustache filter library.
 *
 * You can set it to another context derived from the GRMustacheContext methods
 * such as `contextByAddingObject:`, `contextByAddingProtectedObject:` or
 * `contextByAddingTagDelegate:`.
 *
 * If you set it to nil, it is restored to its default value.
 *
 * @see GRMustacheContext
 *
 * @since v6.0
 */

@property (nonatomic, retain) GRMustacheContext *baseContext AVAILABLE_GRMUSTACHE_VERSION_6_0_AND_LATER;


////////////////////////////////////////////////////////////////////////////////
/// @name Template Strings
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
+ (id)templateFromString:(NSString *)templateString error:(NSError **)error AVAILABLE_GRMUSTACHE_VERSION_6_0_AND_LATER;


////////////////////////////////////////////////////////////////////////////////
/// @name Template Files
////////////////////////////////////////////////////////////////////////////////

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
+ (id)templateFromContentsOfFile:(NSString *)path error:(NSError **)error AVAILABLE_GRMUSTACHE_VERSION_6_0_AND_LATER;

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
+ (id)templateFromContentsOfURL:(NSURL *)url error:(NSError **)error AVAILABLE_GRMUSTACHE_VERSION_6_0_AND_LATER;


////////////////////////////////////////////////////////////////////////////////
/// @name Template Resources
////////////////////////////////////////////////////////////////////////////////

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
 * @param bundle    The bundle where to look for the template resource.
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
+ (id)templateFromResource:(NSString *)name bundle:(NSBundle *)bundle error:(NSError **)error AVAILABLE_GRMUSTACHE_VERSION_6_0_AND_LATER;


////////////////////////////////////////////////////////////////////////////////
/// @name Rendering a Template
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
 * @param bundle  The bundle where to look for the template resource.
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
 * Renders a template with a context stack initialized with a single object.
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
 * Renders a template with a context stack initialized with an array of objects.
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
 * @param HTMLSafe  Upon return contains YES (templates renders HTML-safe strings).
 * @param error     If there is an error rendering the tag, upon return contains
 *                  an NSError object that describes the problem.
 *
 * @return The rendering of the tag.
 *
 * @since v6.0
 */
- (NSString *)renderContentWithContext:(GRMustacheContext *)context HTMLSafe:(BOOL *)HTMLSafe error:(NSError **)error AVAILABLE_GRMUSTACHE_VERSION_6_0_AND_LATER;

@end
