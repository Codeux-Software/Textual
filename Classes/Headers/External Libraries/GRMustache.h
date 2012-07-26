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

/**
 * A C struct that hold GRMustache version information
 * 
 * @since v1.0
 */
typedef struct {
    int major;    /**< The major component of the version. */
    int minor;    /**< The minor component of the version. */
    int patch;    /**< The patch-level component of the version. */
} GRMustacheVersion;


/**
 * The GRMustache class provides with global-level information and configuration
 * of the GRMustache library.
 *
 * @since v1.0
 */
@interface GRMustache: NSObject

////////////////////////////////////////////////////////////////////////////////
/// @name Getting the GRMustache version
////////////////////////////////////////////////////////////////////////////////

/**
 * @return The version of GRMustache as a GRMustacheVersion struct.
 *
 * @since v1.0
 */
+ (GRMustacheVersion)version AVAILABLE_GRMUSTACHE_VERSION_4_0_AND_LATER;

////////////////////////////////////////////////////////////////////////////////
/// @name Preventing NSUndefinedKeyException when using GRMustache in Development configuration
////////////////////////////////////////////////////////////////////////////////

/**
 * Have GRMustache avoid most `NSUndefinedKeyExceptions` when rendering
 * templates.
 * 
 * The rendering of a GRMustache template can lead to many
 * `NSUndefinedKeyExceptions` to be raised, because of the heavy usage of
 * Key-Value Coding. Those exceptions are nicely handled by GRMustache, and are
 * part of the regular rendering of a template.
 * 
 * Unfortunately, when debugging a project, developers usually set their
 * debugger to stop on every Objective-C exceptions. GRMustache rendering can
 * thus become a huge annoyance. This method prevents it.
 * 
 * You'll get a slight performance hit, so you'd probably make sure this call
 * does not enter your Release configuration.
 * 
 * One way to achieve this is to add `-DDEBUG` to the "Other C Flags" setting of
 * your development configuration, and to wrap the
 * `preventNSUndefinedKeyExceptionAttack` method call in a #if block, like:
 * 
 *     #ifdef DEBUG
 *     [GRMustache preventNSUndefinedKeyExceptionAttack];
 *     #endif
 * 
 * **Companion guide:** https://github.com/groue/GRMustache/blob/master/Guides/runtime/context_stack.md
 * 
 * @since v1.7
 */
+ (void)preventNSUndefinedKeyExceptionAttack AVAILABLE_GRMUSTACHE_VERSION_4_0_AND_LATER;

@end
