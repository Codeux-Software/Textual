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

/* See description for self.completionBlock */
typedef void (^ICLInlineContentModuleCompletionBlock)(NSError * _Nullable error);

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

/**
 * Instructs the module to perform whatever logic it contains.
 * Once finished, the module is then expected to call self.completionBlock()
 * This method does not need to invoke super by default.
 */
- (void)performAction;
@end

NS_ASSUME_NONNULL_END
