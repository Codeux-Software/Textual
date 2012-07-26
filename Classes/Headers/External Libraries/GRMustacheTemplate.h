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

#import "GRMustacheTemplateDelegate.h" // @protocol

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
    NSArray *_elems;
    id<GRMustacheTemplateDelegate> _delegate;
}

////////////////////////////////////////////////////////////////////////////////
/// @name Setting the Delegate
////////////////////////////////////////////////////////////////////////////////

/**
 * The template's delegate.
 *
 * **Companion guide:** https://github.com/groue/GRMustache/blob/master/Guides/delegate.md
 *
 * @see GRMustacheTemplateDelegate
 * 
 * @since v1.12
 */
 
@property (nonatomic, assign) id<GRMustacheTemplateDelegate> delegate AVAILABLE_GRMUSTACHE_VERSION_4_0_AND_LATER;


////////////////////////////////////////////////////////////////////////////////
/// @name Parsing and Rendering Template Strings
////////////////////////////////////////////////////////////////////////////////

/**
 * Parses a template string, and returns a compiled template.
 * 
 * @param templateString  The template string
 * @param outError        If there is an error loading or parsing template and
 *                        partials, upon return contains an NSError object that
 *                        describes the problem.
 *
 * @return A GRMustacheTemplate instance
 *
 * @since v1.11
 */
+ (id)templateFromString:(NSString *)templateString error:(NSError **)outError AVAILABLE_GRMUSTACHE_VERSION_4_0_AND_LATER;

/**
 * Renders a context object from a template string.
 * 
 * @param object          A context object used for interpreting Mustache tags
 * @param templateString  The template string
 * @param outError        If there is an error loading or parsing template and
 *                        partials, upon return contains an NSError object that
 *                        describes the problem.
 *
 * @return A string containing the rendered template
 *
 * @since v1.0
 */
+ (NSString *)renderObject:(id)object fromString:(NSString *)templateString error:(NSError **)outError AVAILABLE_GRMUSTACHE_VERSION_4_0_AND_LATER;


////////////////////////////////////////////////////////////////////////////////
/// @name Parsing and Rendering Files
////////////////////////////////////////////////////////////////////////////////

/**
 * Parses a template file, and returns a compiled template.
 * 
 * The template at path must be encoded in UTF8. See the
 * GRMustacheTemplateRepository class for more encoding options.
 * 
 * @param path      The path of the template
 * @param outError  If there is an error loading or parsing template and
 *                  partials, upon return contains an NSError object that
 *                  describes the problem.
 * 
 * @return A GRMustacheTemplate instance
 *
 * @see GRMustacheTemplateRepository
 *
 * @since v1.11
 */
+ (id)templateFromContentsOfFile:(NSString *)path error:(NSError **)outError AVAILABLE_GRMUSTACHE_VERSION_4_0_AND_LATER;

#if !TARGET_OS_IPHONE || __IPHONE_OS_VERSION_MAX_ALLOWED >= 40000

/**
 * Parses a template file, and returns a compiled template.
 * 
 * The template at url must be encoded in UTF8. See the
 * GRMustacheTemplateRepository class for more encoding options.
 * 
 * @param url       The URL of the template
 * @param outError  If there is an error loading or parsing template and
 *                  partials, upon return contains an NSError object that
 *                  describes the problem.
 *
 * @return A GRMustacheTemplate instance
 * 
 * @see GRMustacheTemplateRepository
 *
 * @since v1.11
 */
+ (id)templateFromContentsOfURL:(NSURL *)url error:(NSError **)outError AVAILABLE_GRMUSTACHE_VERSION_4_0_AND_LATER;

#endif /* if !TARGET_OS_IPHONE || __IPHONE_OS_VERSION_MAX_ALLOWED >= 40000 */

/**
 * Renders a context object from a file template.
 * 
 * The template at path must be encoded in UTF8. See the
 * GRMustacheTemplateRepository class for more encoding options.
 * 
 * @param object    A context object used for interpreting Mustache tags
 * @param path      The path of the template
 * @param outError  If there is an error loading or parsing template and
 *                  partials, upon return contains an NSError object that
 *                  describes the problem.
 *
 * @return A string containing the rendered template
 * 
 * @see GRMustacheTemplateRepository
 *
 * @since v1.4.0
 */
+ (NSString *)renderObject:(id)object fromContentsOfFile:(NSString *)path error:(NSError **)outError AVAILABLE_GRMUSTACHE_VERSION_4_0_AND_LATER;


#if !TARGET_OS_IPHONE || __IPHONE_OS_VERSION_MAX_ALLOWED >= 40000

/**
 * Renders a context object from a file template.
 * 
 * The template at url must be encoded in UTF8. See the
 * GRMustacheTemplateRepository class for more encoding options.
 * 
 * @param object    A context object used for interpreting Mustache tags
 * @param url       The URL of the template
 * @param outError  If there is an error loading or parsing template and
 *                  partials, upon return contains an NSError object that
 *                  describes the problem.
 *
 * @return A string containing the rendered template
 * 
 * @see GRMustacheTemplateRepository
 *
 * @since v1.0
 */
+ (NSString *)renderObject:(id)object fromContentsOfURL:(NSURL *)url error:(NSError **)outError AVAILABLE_GRMUSTACHE_VERSION_4_0_AND_LATER;

#endif /* if !TARGET_OS_IPHONE || __IPHONE_OS_VERSION_MAX_ALLOWED >= 40000 */


////////////////////////////////////////////////////////////////////////////////
/// @name Parsing and Rendering NSBundle Resources
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
 * @param name      The name of a bundle resource of extension "mustache"
 * @param bundle    The bundle where to look for the template resource
 * @param outError  If there is an error loading or parsing template and
 *                  partials, upon return contains an NSError object that
 *                  describes the problem.
 *
 * @return A GRMustacheTemplate instance
 *
 * @see GRMustacheTemplateRepository
 *
 * @since v1.11
 */
+ (id)templateFromResource:(NSString *)name bundle:(NSBundle *)bundle error:(NSError **)outError AVAILABLE_GRMUSTACHE_VERSION_4_0_AND_LATER;

/**
 * Parses a bundle resource template, and returns a compiled template.
 * 
 * If you provide nil as a bundle, the resource will be looked in the main
 * bundle.
 * 
 * The template resource must be encoded in UTF8. See the
 * GRMustacheTemplateRepository class for more encoding options.
 * 
 * @param name      The name of a bundle resource
 * @param ext       The extension of the bundle resource
 * @param bundle    The bundle where to look for the template resource
 * @param outError  If there is an error loading or parsing template and
 *                  partials, upon return contains an NSError object that
 *                  describes the problem.
 *
 * @return A GRMustacheTemplate instance
 * 
 * @see GRMustacheTemplateRepository
 *
 * @since v1.11
 */
+ (id)templateFromResource:(NSString *)name withExtension:(NSString *)ext bundle:(NSBundle *)bundle error:(NSError **)outError AVAILABLE_GRMUSTACHE_VERSION_4_0_AND_LATER;


/**
 * Renders a context object from a bundle resource template.
 * 
 * If you provide nil as a bundle, the resource will be looked in the main
 * bundle.
 * 
 * The template resource must be encoded in UTF8. See the
 * GRMustacheTemplateRepository class for more encoding options.
 * 
 * @param object    A context object used for interpreting Mustache tags
 * @param name      The name of a bundle resource of extension "mustache"
 * @param bundle    The bundle where to look for the template resource
 * @param outError  If there is an error loading or parsing template and
 *                  partials, upon return contains an NSError object that
 *                  describes the problem.
 *
 * @return A string containing the rendered template
 * 
 * @see GRMustacheTemplateRepository
 *
 * @since v1.0
 */
+ (NSString *)renderObject:(id)object fromResource:(NSString *)name bundle:(NSBundle *)bundle error:(NSError **)outError AVAILABLE_GRMUSTACHE_VERSION_4_0_AND_LATER;

/**
 * Renders a context object from a bundle resource template.
 * 
 * If you provide nil as a bundle, the resource will be looked in the main
 * bundle.
 * 
 * The template resource must be encoded in UTF8. See the
 * GRMustacheTemplateRepository class for more encoding options.
 * 
 * @param object    A context object used for interpreting Mustache tags
 * @param name      The name of a bundle resource
 * @param ext       The extension of the bundle resource
 * @param bundle    The bundle where to look for the template resource.
 * @param outError  If there is an error loading or parsing template and
 *                  partials, upon return contains an NSError object that
 *                  describes the problem.
 *
 * @return A string containing the rendered template
 * 
 * @see GRMustacheTemplateRepository
 *
 * @since v1.0
 */
+ (NSString *)renderObject:(id)object fromResource:(NSString *)name withExtension:(NSString *)ext bundle:(NSBundle *)bundle error:(NSError **)outError AVAILABLE_GRMUSTACHE_VERSION_4_0_AND_LATER;


////////////////////////////////////////////////////////////////////////////////
/// @name Rendering a Parsed Template
////////////////////////////////////////////////////////////////////////////////

/**
 * Renders a template with a context stack initialized with a single object.
 * 
 * @param object  A context object used for interpreting Mustache tags
 *
 * @return A string containing the rendered template
 *
 * @since v1.0
 */
- (NSString *)renderObject:(id)object AVAILABLE_GRMUSTACHE_VERSION_4_0_AND_LATER;

/**
 * Renders a template with a context stack initialized with several objects.
 * 
 * @param object  The bottom object in the context stack.
 * @param ...     The other objects in the context stack.
 *
 * @return A string containing the rendered template
 *
 * @since v1.5
 */
- (NSString *)renderObjects:(id)object, ... __attribute__ ((sentinel)) AVAILABLE_GRMUSTACHE_VERSION_4_0_AND_LATER;

/**
 * Renders a template without any context object for interpreting Mustache tags.
 * 
 * @return A string containing the rendered template
 *
 * @since v1.0
 */
- (NSString *)render AVAILABLE_GRMUSTACHE_VERSION_4_0_AND_LATER;

@end
