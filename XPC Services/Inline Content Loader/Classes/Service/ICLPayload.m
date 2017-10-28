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

#import "NSObjectHelperPrivate.h"
#import "ICLPayloadInternal.h"

NS_ASSUME_NONNULL_BEGIN

@implementation ICLPayload (ICLPayloadPrivate)

- (nullable instancetype)initWithURL:(NSURL *)url
				withUniqueIdentifier:(NSString *)uniqueIdentifier
						atLineNumber:(NSString *)lineNumber
							   index:(NSUInteger)index
							  inView:(NSString *)viewIdentifier
{
	NSParameterAssert(url != nil);
	NSParameterAssert(uniqueIdentifier != nil);
	NSParameterAssert(lineNumber != nil);
	NSParameterAssert(viewIdentifier != nil);

	ObjectIsAlreadyInitializedAssert

	if ((self = [super init])) {
		self->_url = [url copy];
		self->_lineNumber = [lineNumber copy];
		self->_index = index;
		self->_uniqueIdentifier = [uniqueIdentifier copy];
		self->_viewIdentifier = [viewIdentifier copy];

		[self populateDefaultsPostflight];

		self->_objectInitialized = YES;

		return self;
	}

	return nil;
}

- (instancetype)initWithDeferredPayload:(ICLPayload *)payload
{
	NSParameterAssert(payload != nil);

	ObjectIsAlreadyInitializedAssert

	if ((self = [super init])) {
		/* All values are immutable which means we
		 don't need to copy their contents. */
		self->_url = payload.url;
		self->_urlToInline = payload.urlToInline;
		self->_lineNumber = payload.lineNumber;
		self->_index = payload.index;
		self->_uniqueIdentifier = payload.uniqueIdentifier;
		self->_viewIdentifier = payload.viewIdentifier;
		self->_classAttribute = payload.classAttribute;

		[self populateDefaultsPostflight];

		self->_objectInitialized = YES;

		return self;
	}

	return nil;
}

@end

NS_ASSUME_NONNULL_END
