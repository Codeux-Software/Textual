/* ********************************************************************* 
                  _____         _               _
                 |_   _|____  _| |_ _   _  __ _| |
                   | |/ _ \ \/ / __| | | |/ _` | |
                   | |  __/>  <| |_| |_| | (_| | |
                   |_|\___/_/\_\\__|\__,_|\__,_|_|

 Copyright (c) 2010 - 2017 Codeux Software, LLC & respective contributors.
        Please see Acknowledgements.pdf for additional information.

 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions
 are met:

    * Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the
      documentation and/or other materials provided with the distribution.
    * Neither the name of Textual and/or "Codeux Software, LLC", nor the 
      names of its contributors may be used to endorse or promote products 
      derived from this software without specific prior written permission.

 THIS SOFTWARE IS PROVIDED BY THE AUTHOR AND CONTRIBUTORS ``AS IS'' AND
 ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 ARE DISCLAIMED. IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE LIABLE
 FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
 OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
 LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
 OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
 SUCH DAMAGE.

 *********************************************************************** */

NS_ASSUME_NONNULL_BEGIN

#pragma mark -
#pragma mark Immutable Object

@interface ICLPayload : NSObject <NSCoding, NSSecureCoding, NSCopying, NSMutableCopying>
/**
 * Payload objects are not allowed to be allocated by a plugin.
 * Each new instance of ICLContentLoaderModule is given a mutable payload.
 * Modify that, then the loader will create an immutable copy when appropriate.
 */
- (instancetype)init NS_UNAVAILABLE;

/**
 * @brief The value of the address argument supplied to the loader.
 */
@property (copy, readonly) NSURL *url;

/**
 * @brief The value of the unique identifier argument supplied to the loader.
 */
@property (copy, readonly) NSString *uniqueIdentifier;

/**
 * @brief The length of the content. This value is optional.
 */
@property (readonly) NSUInteger contentLength;

/**
 * @brief The size of the content. This value is optional.
 */
@property (readonly) NSSize contentSize;

/**
 * A collection of paths for .css files that need to be loaded to allow the
 *  rendered HTML to appear correct.
 */
@property (copy, readonly, nullable) NSArray<NSString *> *styleResources;

/**
 * A collection of paths for .js files that need to be loaded to allow the
 *  rendered HTML to appear correct.
 *
 * At least one file is required so that the entrypoint can be called.
 */
@property (copy, readonly) NSArray<NSString *> *scriptResources;

/**
 * The name of a JavaSript function that will be called for the purpose
 *  of inlining this payload.
 *
 * The entrypoint takes two arguments. The first is the value of the
 *  -entrypointPayload property defined below. The second is a callback
 *  function which the entrypoint is required to call after it has
 *  finished rendering the HTML to display.
 *
 * Example:
 *
 * 	MyObject.entrypoint = function(payload, callbackFunction)
 * 	{
 * 		// Do work here...
 *
 * 		callbackFunction("some HTML to display");
 * 	}
 *
 * The HTML can be set to "display: none" by default if it prefers.
 * The callback function does not apply styling to the HTML.
 * It only inserts it.
 */
@property (copy, readonly) NSString *entrypoint;

/**
 * A payload that is passed as the second argument to the -entrypoint.
 *
 * ICLPayload automatically sets "url" and "uniqueIdentifier" values
 * to this dictionary to mirror the values present in the payload.
 * You do not need to do this yourself.
 *
 * Types are translated as such:
 *
 * Objective-C          JavaScript
 * -----------          ----------
 * NSArray         =>   array
 * BOOL            =>   boolean
 * NSNumber        =>   number
 * NSDictionary    =>   object
 * NSString        =>   string
 * NSURL           =>   string
 *
 * Custom types cannot be passed.
 */
@property (copy, readonly) NSDictionary<NSString *, id <NSCopying>> *entrypointPayload;
@end

NS_ASSUME_NONNULL_END
