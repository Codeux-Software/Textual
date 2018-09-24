/* *********************************************************************
 *                  _____         _               _
 *                 |_   _|____  _| |_ _   _  __ _| |
 *                   | |/ _ \ \/ / __| | | |/ _` | |
 *                   | |  __/>  <| |_| |_| | (_| | |
 *                   |_|\___/_/\_\\__|\__,_|\__,_|_|
 *
 * Copyright (c) 2017, 2018 Codeux Software, LLC & respective contributors.
 *       Please see Acknowledgements.pdf for additional information.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *
 *  * Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 *  * Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 *  * Neither the name of Textual, "Codeux Software, LLC", nor the
 *    names of its contributors may be used to endorse or promote products
 *    derived from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE AUTHOR AND CONTRIBUTORS ``AS IS'' AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED. IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE LIABLE
 * FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
 * OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
 * LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
 * OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
 * SUCH DAMAGE.
 *
 *********************************************************************** */

#import "NSObjectHelperPrivate.h"
#import "ICLMediaAssessment.h"
#import "ICLMediaAssessmentInternal.h"

NS_ASSUME_NONNULL_BEGIN

@implementation ICLMediaAssessment

ClassWithDesignatedInitializerInitMethod

- (instancetype)initWithURL:(NSURL *)url asType:(ICLMediaType)type
{
	NSParameterAssert(url != nil);

	ObjectIsAlreadyInitializedAssert

	if ((self = [super init])) {
		self->_url = [url copy];

		self->_type = type;

		[self populateDefaultsPostflight];

		self->_objectInitialized = YES;

		return self;
	}

	return nil;
}

DESIGNATED_INITIALIZER_EXCEPTION_BODY_BEGIN
- (instancetype)_initAfterCopy
{
	ObjectIsAlreadyInitializedAssert

	if ((self = [super init])) {
		self->_objectInitialized = YES;

		return self;
	}

	return nil;
}

- (nullable instancetype)initWithCoder:(NSCoder *)aDecoder
{
	NSParameterAssert(aDecoder != nil);

	ObjectIsAlreadyInitializedAssert

	if ((self = [super init])) {
		[self decodeWithCoder:aDecoder];

		[self populateDefaultsPostflight];

		self->_objectInitialized = YES;

		return self;
	}

	return nil;
}
DESIGNATED_INITIALIZER_EXCEPTION_BODY_END

- (void)decodeWithCoder:(NSCoder *)aDecoder
{
	NSParameterAssert(aDecoder != nil);

	ObjectIsAlreadyInitializedAssert

	self->_url = [aDecoder decodeObjectOfClass:[NSURL class] forKey:@"url"];

	self->_type = [aDecoder decodeUnsignedIntegerForKey:@"type"];

	self->_contentType = [aDecoder decodeStringForKey:@"contentType"];
	self->_contentLength = [aDecoder decodeUnsignedIntegerForKey:@"contentLength"];

	[self initializedClassHealthCheck];
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
	[aCoder encodeObject:self->_url forKey:@"url"];

	[aCoder encodeUnsignedInteger:self->_type forKey:@"type"];

	[aCoder encodeString:self->_contentType forKey:@"contentType"];
	[aCoder encodeUnsignedInteger:self->_contentLength forKey:@"contentLength"];
}

+ (BOOL)supportsSecureCoding
{
	return YES;
}

- (void)populateDefaultsPostflight
{
	ObjectIsAlreadyInitializedAssert

	SetVariableIfNil(self->_contentType, @"application/binary");
}

- (void)initializedClassHealthCheck
{
	ObjectIsAlreadyInitializedAssert

	NSParameterAssert(self->_url != nil);
	NSParameterAssert(self->_contentType != nil);
}

- (id)copyWithZone:(nullable NSZone *)zone asMutable:(BOOL)copyAsMutable
{
	ICLMediaAssessment *object = nil;

	if (copyAsMutable) {
		object = [ICLMediaAssessmentMutable allocWithZone:zone];
	} else {
		object = [ICLMediaAssessment allocWithZone:zone];
	}

	object->_objectInitializedAsCopy = YES;

	object->_url = self->_url;

	object->_type = self->_type;

	object->_contentType = self->_contentType;
	object->_contentLength = self->_contentLength;

	return [object _initAfterCopy];
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

@implementation ICLMediaAssessmentMutable

@dynamic type;
@dynamic contentType;
@dynamic contentLength;

- (void)setType:(ICLMediaType)type
{
	if (self->_type != type) {
		self->_type = type;
	}
}

- (void)setContentType:(NSString *)contentType
{
	if (self->_contentType != contentType) {
		self->_contentType = contentType;
	}
}

- (void)setContentLength:(unsigned long long)contentLength
{
	if (self->_contentLength != contentLength) {
		self->_contentLength = contentLength;
	}
}

@end

NS_ASSUME_NONNULL_END
