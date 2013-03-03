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
 * maintains two stacks:
 *
 * - a *context stack*, that makes it able to provide the current context
 *   object, and to perform key lookup.
 * - a *tag delegate stack*, so that tag delegates are notified when a Mustache
 *   tag is rendered.
 *
 * @see GRMustacheRendering protocol
 */
@interface GRMustacheContext : NSObject {
@private
    GRMustacheContext *_contextParent;
    id _contextObject;
    GRMustacheContext *_protectedContextParent;
    id _protectedContextObject;
    GRMustacheContext *_hiddenContextParent;
    id _hiddenContextObject;
    GRMustacheContext *_tagDelegateParent;
    id<GRMustacheTagDelegate> _tagDelegate;
    GRMustacheContext *_templateOverrideParent;
    id _templateOverride;
}


////////////////////////////////////////////////////////////////////////////////
/// @name Creating Contexts
////////////////////////////////////////////////////////////////////////////////


/**
 * @return An empty rendering context.
 *
 * @since v6.4
 */
+ (instancetype)context AVAILABLE_GRMUSTACHE_VERSION_6_4_AND_LATER;

/**
 * Returns a context with _object_ at the top of the context stack.
 *
 * If _object_ conforms to the GRMustacheTemplateDelegate protocol, it is also
 * made the top of the tag delegate stack.
 *
 * @param object  An object
 *
 * @return A rendering context.
 *
 * @since v6.4
 */
+ (instancetype)contextWithObject:(id)object AVAILABLE_GRMUSTACHE_VERSION_6_4_AND_LATER;

/**
 * Returns a context with _object_ at the top of the protected context stack.
 *
 * Unlike contextWithObject:, this method does not put the object to the
 * tag delegate stack if it conforms to the GRMustacheTemplateDelegate protocol.
 *
 * **Companion guide:** https://github.com/groue/GRMustache/blob/master/Guides/protected_context.md
 *
 * @param object  An object
 *
 * @return A rendering context.
 *
 * @since v6.4
 */
+ (instancetype)contextWithProtectedObject:(id)object AVAILABLE_GRMUSTACHE_VERSION_6_4_AND_LATER;

/**
 * Returns a context with _tagDelegate_ at the top of the tag delegate stack.
 *
 * @param tagDelegate  A tag delegate
 *
 * @return A rendering context.
 */
+ (instancetype)contextWithTagDelegate:(id<GRMustacheTagDelegate>)tagDelegate AVAILABLE_GRMUSTACHE_VERSION_6_4_AND_LATER;


////////////////////////////////////////////////////////////////////////////////
/// @name Deriving New Contexts
////////////////////////////////////////////////////////////////////////////////


/**
 * Returns a new rendering context that is the copy of the receiver, and the
 * given object added at the top of the context stack.
 *
 * If _object_ conforms to the GRMustacheTemplateDelegate protocol, it is also
 * added at the top of the tag delegate stack.
 *
 * @param object  An object
 *
 * @return A new rendering context.
 *
 * @since v6.0
 */
- (GRMustacheContext *)contextByAddingObject:(id)object AVAILABLE_GRMUSTACHE_VERSION_6_0_AND_LATER;

/**
 * Returns a new rendering context that is the copy of the receiver, and the
 * given object added at the top of the protected context stack.
 *
 * Unlike contextByAddingObject:, this method does not add the object to the
 * tag delegate stack if it conforms to the GRMustacheTemplateDelegate protocol.
 *
 * **Companion guide:** https://github.com/groue/GRMustache/blob/master/Guides/protected_context.md
 *
 * @param object  An object
 *
 * @return A new rendering context.
 *
 * @since v6.0
 */
- (GRMustacheContext *)contextByAddingProtectedObject:(id)object AVAILABLE_GRMUSTACHE_VERSION_6_0_AND_LATER;

/**
 * Returns a new rendering context that is the copy of the receiver, and the
 * given object added at the top of the tag delegate stack.
 *
 * @param tagDelegate  A tag delegate
 *
 * @return A new rendering context.
 *
 * @since v6.0
 */
- (GRMustacheContext *)contextByAddingTagDelegate:(id<GRMustacheTagDelegate>)tagDelegate AVAILABLE_GRMUSTACHE_VERSION_6_0_AND_LATER;

@end
