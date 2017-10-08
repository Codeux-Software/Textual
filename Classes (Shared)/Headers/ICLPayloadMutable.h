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

#import "ICLPayload.h"

NS_ASSUME_NONNULL_BEGIN

#pragma mark -
#pragma mark Mutable Object

@interface ICLPayloadMutable : ICLPayload
/**
 * @brief The length of the content. This value is optional.
 */
@property (nonatomic, assign, readwrite) NSUInteger contentLength;

/**
 * @brief The size of the content. This value is optional.
 */
@property (nonatomic, assign, readwrite) NSSize contentSize;

/**
 * A collection of paths for .css files that need to be loaded to allow the
 *  rendered HTML to appear correct.
 */
@property (nonatomic, copy, nullable, readwrite) NSArray<NSString *> *styleResources;

/**
 * A collection of paths for .js files that need to be loaded to allow the
 *  rendered HTML to appear correct.
 *
 * At least one file is required so that the entrypoint can be called.
 */
@property (nonatomic, copy, readwrite) NSArray<NSString *> *scriptResources;

/**
 * @brief Rendered HTML or an empty string
 *
 * @discussion
 * A module does not need to render the HTML through Objective-C.
 * It can render it in JavaScript or by some other means.
 *
 * If a module renders HTML using Objective-C, then the final result
 * can be assigned to this property. The value of this property is
 * then passed inside the -entrypointPayload dictionary.
 */
@property (nonatomic, copy, readwrite) NSString *html;

/**
 * @brief The name of a JavaSript function that will be called for the
 * purpose of inlining this payload.
 *
 * @discussion
 * The entrypoint takes two arguments. The first is the value of the
 * -entrypointPayload property defined below. The second is a callback
 * function which the entrypoint is required to pass rendered HTML.
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
@property (nonatomic, copy, readwrite) NSString *entrypoint;

/**
 * @brief A dictionary that is passed as the first argument to -entrypoint.
 *
 * @discussion
 * This dictionary is guaranteed to always contain the following keys:
 * 	1. "html" (string)
 * 	2. "url" (string)
 * 	3. "uniqueIdentifier" (string)
 * The value of these keys mirror the payload's.
 *
 * ICLPayload will not allow you to override the value of these keys.
 *
 * ----------------------------------------------
 *
 * Types are translated as such:
 *
 * 	Objective-C          JavaScript
 * 	-----------          ----------
 * 	NSArray         =>   array
 * 	BOOL            =>   boolean
 * 	NSNumber        =>   number
 * 	NSDictionary    =>   object
 * 	NSString        =>   string
 * 	NSURL           =>   string
 *
 * Custom types cannot be passed.
 */
@property (nonatomic, copy, null_resettable, readwrite) NSDictionary<NSString *, id <NSCopying>> *entrypointPayload;
@end

NS_ASSUME_NONNULL_END
