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

#import <objc/message.h>
#import <Foundation/Foundation.h>
#import "GRMustacheAvailabilityMacros.h"
#import "GRMustacheTagDelegate.h"

/**
 * The GRMustacheContext represents a Mustache rendering context: it internally
 * maintains three stacks:
 *
 * - a *context stack*, that makes it able to provide the current context
 *   object, and to perform key lookup.
 *
 * - a *protected context stack*, whose objects define important keys that
 *   should not be overriden.
 *
 * - a *tag delegate stack*, so that tag delegates are notified when a Mustache
 *   tag is rendered.
 *
 * **Companion guides:**
 *
 * - https://github.com/groue/GRMustache/blob/master/Guides/view_model.md
 * - https://github.com/groue/GRMustache/blob/master/Guides/delegate.md
 * - https://github.com/groue/GRMustache/blob/master/Guides/rendering_objects.md
 * - https://github.com/groue/GRMustache/blob/master/Guides/protected_contexts.md
 *
 * @see GRMustacheRendering protocol
 */
@interface GRMustacheContext : NSObject {
@private
    GRMustacheContext *_contextParent;
    id _contextObject;
    NSMutableDictionary *_managedPropertiesStore;
    GRMustacheContext *_protectedContextParent;
    id _protectedContextObject;
    GRMustacheContext *_hiddenContextParent;
    id _hiddenContextObject;
    GRMustacheContext *_tagDelegateParent;
    id<GRMustacheTagDelegate> _tagDelegate;
    GRMustacheContext *_templateOverrideParent;
    id _templateOverride;
    NSDictionary *_depthsForAncestors;
}


////////////////////////////////////////////////////////////////////////////////
/// @name Creating Rendering Contexts
////////////////////////////////////////////////////////////////////////////////

/**
 * Returns an initialized empty rendering context.
 *
 * Empty contexts do not provide any value for any key.
 *
 * If you wish to use the services provided by the GRMustache standard library,
 * you should create a context with the +[GRMustacheContext contextWithObject:]
 * method, like this:
 *
 *     [GRMustacheContext contextWithObject:[GRMustache standardLibrary]]
 *
 * @return A rendering context.
 *
 * @see +[GRMustache standardLibrary]
 */
- (id)init;

/**
 * Returns an empty rendering context.
 *
 * Empty contexts do not provide any value for any key.
 *
 * If you wish to use the services provided by the GRMustache standard library,
 * you should create a context with the +[GRMustacheContext contextWithObject:]
 * method, like this:
 *
 *     [GRMustacheContext contextWithObject:[GRMustache standardLibrary]]
 *
 * @return A rendering context.
 *
 * @see contextWithObject:
 * @see +[GRMustache standardLibrary]
 *
 * @since v6.4
 */
+ (instancetype)context AVAILABLE_GRMUSTACHE_VERSION_6_4_AND_LATER;

/**
 * Returns a rendering context containing a single object.
 *
 * Keys defined by _object_ gets available for template rendering.
 *
 *     context = [GRMustacheContext contextWithObject:@{ @"name": @"Arthur" }];
 *     [context valueForMustacheKey:@"name"];   // @"Arthur"
 *
 * If _object_ conforms to the GRMustacheTemplateDelegate protocol, it is also
 * made the top of the tag delegate stack.
 *
 * If _object_ is an instance of GRMustacheContext, its class must be the class
 * of the receiver, or any subclass, and the returned context is _object.
 * An exception is raised otherwise.
 *
 * **Companion guide:** https://github.com/groue/GRMustache/blob/master/Guides/delegate.md
 *
 * @param object  An object
 *
 * @return A rendering context.
 *
 * @see contextByAddingObject:
 *
 * @see GRMustacheTemplateDelegate
 *
 * @since v6.4
 */
+ (instancetype)contextWithObject:(id)object AVAILABLE_GRMUSTACHE_VERSION_6_4_AND_LATER;

/**
 * Returns a context containing a single protected object.
 *
 * Keys defined by _object_ gets "protected", which means that they can not be
 * overriden by other objects that will eventually enter the context stack.
 *
 *     // Create a context with a protected `precious` key
 *     context = [GRMustacheContext contextWithProtectedObject:@{ @"precious": @"gold" }];
 *
 *     // Derive a new context by attempting to override the `precious` key:
 *     context = [context contextByAddingObject:@{ @"precious": @"lead" }];
 *
 *     // Protected keys can't be overriden
 *     [context valueForMustacheKey:@"precious"];   // @"gold"
 *
 * **Companion guide:** https://github.com/groue/GRMustache/blob/master/Guides/protected_context.md
 *
 * @param object  An object
 *
 * @return A rendering context.
 *
 * @see contextByAddingProtectedObject:
 *
 * @since v6.4
 */
+ (instancetype)contextWithProtectedObject:(id)object AVAILABLE_GRMUSTACHE_VERSION_6_4_AND_LATER;

/**
 * Returns a context containing a single tag delegate.
 *
 * _tagDelegate_ will be notified of the rendering of all tags rendered from the
 * receiver or from contexts derived from the receiver.
 *
 * Unlike contextWithObject: and contextWithProtectedObject:, _tagDelegate_ will
 * not provide any key to the templates. It will only be notified of the
 * rendering of tags.
 *
 * **Companion guide:** https://github.com/groue/GRMustache/blob/master/Guides/delegate.md
 *
 * @param tagDelegate  A tag delegate
 *
 * @return A rendering context.
 *
 * @see GRMustacheTagDelegate
 *
 * @since v6.4
 */
+ (instancetype)contextWithTagDelegate:(id<GRMustacheTagDelegate>)tagDelegate AVAILABLE_GRMUSTACHE_VERSION_6_4_AND_LATER;


////////////////////////////////////////////////////////////////////////////////
/// @name Deriving New Contexts
////////////////////////////////////////////////////////////////////////////////


/**
 * Returns a new rendering context that is the copy of the receiver, and the
 * given object added at the top of the context stack.
 *
 * Keys defined by _object_ gets available for template rendering, and override
 * the values defined by objects already contained in the context stack. Keys
 * unknown to _object_ will be looked up deeper in the context stack.
 *
 *     context = [GRMustacheContext contextWithObject:@{ @"a": @"ignored", @"b": @"foo" }];
 *     context = [context contextByAddingObject:@{ @"a": @"bar" }];
 *
 *     // `a` is overriden
 *     [context valueForMustacheKey:@"a"];   // @"bar"
 *
 *     // `b` is inherited
 *     [context valueForMustacheKey:@"b"];   // @"foo"
 *
 * _object_ can not override keys defined by the objects of the protected
 * context stack, though. See contextWithProtectedObject: and
 * contextByAddingProtectedObject:.
 *
 * If _object_ conforms to the GRMustacheTemplateDelegate protocol, it is also
 * added at the top of the tag delegate stack.
 *
 * If _object_ is an instance of GRMustacheContext, its class must be the class
 * of the receiver, or any subclass, and the returned context will be an
 * instance of the class of _object_. An exception is raised otherwise.
 *
 * **Companion guide:** https://github.com/groue/GRMustache/blob/master/Guides/delegate.md
 *
 * @param object  An object
 *
 * @return A new rendering context.
 *
 * @see GRMustacheTemplateDelegate
 *
 * @since v6.0
 */
- (instancetype)contextByAddingObject:(id)object AVAILABLE_GRMUSTACHE_VERSION_6_0_AND_LATER;

/**
 * Returns a new rendering context that is the copy of the receiver, and the
 * given object added at the top of the protected context stack.
 *
 * Keys defined by _object_ gets "protected", which means that they can not be
 * overriden by other objects that will eventually enter the context stack.
 *
 *     // Derive a context with a protected `precious` key
 *     context = [context contextByAddingProtectedObject:@{ @"precious": @"gold" }];
 *
 *     // Derive a new context by attempting to override the `precious` key:
 *     context = [context contextByAddingObject:@{ @"precious": @"lead" }];
 *
 *     // Protected keys can't be overriden
 *     [context valueForMustacheKey:@"precious"];   // @"gold"
 *
 * **Companion guide:** https://github.com/groue/GRMustache/blob/master/Guides/protected_context.md
 *
 * @param object  An object
 *
 * @return A new rendering context.
 *
 * @since v6.0
 */
- (instancetype)contextByAddingProtectedObject:(id)object AVAILABLE_GRMUSTACHE_VERSION_6_0_AND_LATER;

/**
 * Returns a new rendering context that is the copy of the receiver, and the
 * given object added at the top of the tag delegate stack.
 *
 * _tagDelegate_ will be notified of the rendering of all tags rendered from the
 * receiver or from contexts derived from the receiver.
 *
 * Unlike contextByAddingObject: and contextByAddingProtectedObject:,
 * _tagDelegate_ will not provide any key to the templates. It will only be
 * notified of the rendering of tags.
 *
 * **Companion guide:** https://github.com/groue/GRMustache/blob/master/Guides/delegate.md
 *
 * @param tagDelegate  A tag delegate
 *
 * @return A new rendering context.
 *
 * @see GRMustacheTagDelegate
 *
 * @since v6.0
 */
- (instancetype)contextByAddingTagDelegate:(id<GRMustacheTagDelegate>)tagDelegate AVAILABLE_GRMUSTACHE_VERSION_6_0_AND_LATER;


////////////////////////////////////////////////////////////////////////////////
/// @name Fetching Values from the Context Stack
////////////////////////////////////////////////////////////////////////////////

/**
 * Returns the object at the top of the receiver's context stack.
 *
 * The returned object is the same as the one that would be rendered by a
 * `{{ . }}` tag.
 *
 *     user = ...;
 *     context = [GRMustacheContext contextWithObject:user];
 *     context.topMustacheObject;  // user
 *
 * @return The object at the top of the receiver's context stack.
 *
 * @see contextWithObject:
 * @see contextByAddingObject:
 *
 * @since v6.7
 */
@property (nonatomic, readonly) id topMustacheObject AVAILABLE_GRMUSTACHE_VERSION_6_7_AND_LATER;

/**
 * Returns the value stored in the context stack for the given key.
 *
 * If you want the value for an full expression such as @"user.name" or
 * @"uppercase(user.name)", use the valueForMustacheExpression:error: method.
 *
 * ### Search Pattern for valueForMustacheKey:
 *
 * When the default implementation of valueForMustacheKey: is invoked on a
 * receiver, the following search pattern is used:
 *
 * 1. Searches the protected context stack for an object whose valueForKey:
 *    method returns a non-nil value.
 *
 * 2. Otherwise (irrelevant protected context stack), search the context stack
 *    for an object whose valueForKey: method returns a non-nil value, or for an
 *    initialized managed property (managed properties are properties defined by
 *    GRMustacheContext subclasses as @dynamic).
 *
 * 3. Otherwise (irrelevant protected context stack, irrelevant regular context
 *    stack, no initialized managed property), performs a regular call to
 *    `valueForKey:` on the receiver, so that methods defined by subclasses can
 *    provide default values.
 *
 * 4. If none of the above situations occurs, returns the result of
 *    valueForUndefinedMustacheKey:.
 *
 * **Companion guide:** https://github.com/groue/GRMustache/blob/master/Guides/view_model.md
 *
 * @see valueForUndefinedMustacheKey:
 * @see valueForMustacheExpression:error:
 *
 * @since v6.6
 */
- (id)valueForMustacheKey:(NSString *)key AVAILABLE_GRMUSTACHE_VERSION_6_6_AND_LATER;

/**
 * This method is invoked when a key could not be resolved to any value.
 *
 * Subclasses can override this method to return an alternate value for
 * undefined keys. The default implementation returns nil.
 *
 * **Companion guide:** https://github.com/groue/GRMustache/blob/master/Guides/view_model.md
 *
 * @see valueForMustacheKey:
 * @see valueForMustacheExpression:error:
 *
 * @since v6.7
 */
- (id)valueForUndefinedMustacheKey:(NSString *)key AVAILABLE_GRMUSTACHE_VERSION_6_7_AND_LATER;

/**
 * Evaluate the expression in the receiver context.
 *
 * This method can evaluate complex expressions such as @"user.name" or
 * @"uppercase(user.name)".
 *
 * **Companion guide:** https://github.com/groue/GRMustache/blob/master/Guides/view_model.md
 *
 * @see valueForUndefinedMustacheKey:
 * @see valueForMustacheExpression:error:
 *
 * @since v6.6
 */
- (id)valueForMustacheExpression:(NSString *)expression error:(NSError **)error AVAILABLE_GRMUSTACHE_VERSION_6_6_AND_LATER;

@end
