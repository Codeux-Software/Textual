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

#import "ICLPayloadInternal.h"

NS_ASSUME_NONNULL_BEGIN

@implementation ICLPayload

- (instancetype)_init
{
	return [super init];
}

- (nullable instancetype)initWithCoder:(NSCoder *)aDecoder
{
	NSParameterAssert(aDecoder != nil);

	ObjectIsAlreadyInitializedAssert

	if ((self = [super init])) {
		[self decodeWithCoder:aDecoder];

		[self populateDefaultsPostflight];

		return self;
	}

	return nil;
}

- (void)decodeWithCoder:(NSCoder *)aDecoder
{
	NSParameterAssert(aDecoder != nil);

	ObjectIsAlreadyInitializedAssert

	self->_contentLength = [aDecoder decodeUnsignedIntegerForKey:@"contentLength"];
	self->_contentSize = [aDecoder decodeSizeForKey:@"contentSize"];

	self->_cssResources = [aDecoder decodeObjectOfClass:[NSArray class] forKey:@"cssResources"];
	self->_jsResources = [aDecoder decodeObjectOfClass:[NSArray class] forKey:@"jsResources"];

	self->_html = [aDecoder decodeStringForKey:@"html"];

	self->_url = [aDecoder decodeObjectOfClass:[NSURL class] forKey:@"url"];

	self->_uniqueIdentifier = [aDecoder decodeStringForKey:@"uniqueIdentifier"];

	[self initializedClassHealthCheck];
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
	[aCoder encodeUnsignedInteger:self->_contentLength forKey:@"contentLength"];
	[aCoder encodeSize:self->_contentSize forKey:@"contentSize"];

	[aCoder maybeEncodeObject:self->_cssResources forKey:@"cssResources"];
	[aCoder maybeEncodeObject:self->_jsResources forKey:@"jsResources"];

	[aCoder encodeObject:self->_html forKey:@"html"];

	[aCoder encodeObject:self->_url forKey:@"url"];

	[aCoder encodeObject:self->_uniqueIdentifier forKey:@"uniqueIdentifier"];
}

+ (BOOL)supportsSecureCoding
{
	return YES;
}

- (void)populateDefaultsPostflight
{
	self->_contentSize = NSZeroSize;

	self->_html = @"";
}

- (void)initializedClassHealthCheck
{
	ObjectIsAlreadyInitializedAssert

	NSParameterAssert(self->_html != nil);
	NSParameterAssert(self->_url != nil);
	NSParameterAssert(self->_uniqueIdentifier != nil);
}

- (id)copyWithZone:(nullable NSZone *)zone asMutable:(BOOL)copyAsMutable
{
	ICLPayload *object = nil;

	if (copyAsMutable) {
		object = [ICLPayloadMutable allocWithZone:zone];
	} else {
		object = [ICLPayload allocWithZone:zone];
	}

	object->_objectInitializedAsCopy = YES;

	object->_contentLength = self->_contentLength;
	object->_contentSize = self->_contentSize;

	object->_cssResources = self->_cssResources;
	object->_jsResources = self->_jsResources;

	object->_html = self->_html;

	object->_url = self->_url;

	object->_uniqueIdentifier = self->_uniqueIdentifier;

	return [object _init];
}

- (id)copyWithZone:(nullable NSZone *)zone
{
	return [self copyWithZone:zone asMutable:NO];
}

- (id)mutableCopyWithZone:(nullable NSZone *)zone
{
	return [self copyWithZone:zone asMutable:YES];
}

- (BOOL)isMutable
{
	return NO;
}

@end

#pragma mark -

@implementation ICLPayloadMutable

@dynamic contentLength;
@dynamic contentSize;
@dynamic cssResources;
@dynamic jsResources;
@dynamic html;

- (BOOL)isMutable
{
	return YES;
}

- (void)setContentLength:(NSUInteger)contentLength
{
	if (self->_contentLength != contentLength) {
		self->_contentLength = contentLength;
	}
}

- (void)setContentSize:(NSSize)contentSize
{
	self->_contentSize = contentSize;
}

- (void)setCssResources:(nullable NSArray<NSString *> *)cssResources
{
	if (self->_cssResources != cssResources) {
		self->_cssResources = [cssResources copy];
	}
}

- (void)setJsResources:(nullable NSArray<NSString *> *)jsResources
{
	if (self->_jsResources != jsResources) {
		self->_jsResources = [jsResources copy];
	}
}

- (void)setHtml:(NSString *)html
{
	NSParameterAssert(html != nil);

	if (self->_html != html) {
		self->_html = html;
	}
}

@end

NS_ASSUME_NONNULL_END
