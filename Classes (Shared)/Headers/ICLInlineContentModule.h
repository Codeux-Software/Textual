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

#import "ICLPayloadMutable.h"

NS_ASSUME_NONNULL_BEGIN

@class ICLInlineContentModule;

/* See description for self.completionBlock */
typedef void (^ICLInlineContentModuleCompletionBlock)(NSError * _Nullable error);

/* See description for -actionBlockForURL: */
typedef void (^ICLInlineContentModuleActionBlock)(ICLInlineContentModule *module);

/**
 * Modules are always a subclass, instead of a protocol, to give us
 * greater flexibility when adding private components to the parent.
 */
@interface ICLInlineContentModule : NSObject
/**
 * Mutable copy of the payload this module has access to modify.
 * This paylaod includes the address and the unique identifier.
 */
@property (readonly, strong) ICLPayloadMutable *payload;

/**
 * The completion block called when this module has finished performing
 * whatever logic it contains.
 *
 * The error argument is optional.
 *   If     nil, the action succeeded and the payload is processed.
 *   If non-nil, the action failed and the error is processed.
 */
@property (readonly) ICLInlineContentModuleCompletionBlock completionBlock;

/**
 * Module objects are not allowed to be allocated by a plugin.
 */
- (instancetype)init NS_UNAVAILABLE;

#pragma mark -
#pragma mark Rules

/**
 An optional array of domains that the module is specific to.

 If this array is non-nil and the domain does not appear in the
 array, then the module is skipped over. One of the action methods
 defined below is never called.
 */
@property (readonly, copy, nullable, class) NSArray<NSString *> *domains;

#pragma mark -
#pragma mark Payload Helpers

/* If a non-nil value is returned for any of these properties,
 then that value is inserted into the payload. */
/* See ICLPayload.h for a description of each property. */
@property (copy, readonly, nullable) NSArray<NSURL *> *styleResources;
@property (copy, readonly, nullable) NSArray<NSURL *> *scriptResources;
@property (copy, readonly, nullable) NSString *entrypoint;

#pragma mark -
#pragma mark Action

/**
 * Returns a block to perform if the module is interested in the URL.
 *
 * The block is passed one argument: a new instance of the module.
 * The block can then use that to do stateful work, or it can
 * disregard the argument and do whatever else it wants.
 *
 * The return value of -actionBlockForURL: is favored over -actionForURL:
 * The latter is never called if -actionBlockForURL: returns a value.
 *
 * nil is returned if this method is not implemented.
 */
+ (nullable ICLInlineContentModuleActionBlock)actionBlockForURL:(NSURL *)url;

/**
 * Returns a selector to perform if the module is interested in the URL.
 *
 * The selector is performed on a new instance of the module which means
 * the selector returned must be one for an instance method.
 *
 * The selector:
 *   1. Does not return a value (void)
 *   2. Does not take arguments
 *
 * Example:
 *
 * 		- (void)performAction
 * 		{
 *
 * 		}
 *
 * NULL is returned if this method is not implemented.
 */
+ (SEL)actionForURL:(NSURL *)url;

#pragma mark -
#pragma mark Context

/**
 Whether the module's content is an image or video.
 This can include video services, not just video files.
 */
@property (readonly, class) BOOL contentImageOrVideo;

/**
 Whether the module might add content to the DOM which
 is not trusted such as HTML downloaded from some website.
 Other untrusted resources include remote resources.
 */
@property (readonly, class) BOOL contentUntrusted;

/**
 Whether module might load content that is not safe for work.
 */
@property (readonly, class) BOOL contentNotSafeForWork;
@end

NS_ASSUME_NONNULL_END
