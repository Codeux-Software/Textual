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
#import "TPCPreferences.h"
#import "ICLMediaAssessment.h"
#import "ICLMediaAssessor.h"

NS_ASSUME_NONNULL_BEGIN

/* Hardcoded maximum width for images (and maybe other media) */
#define _assessorMaximumImageWidth				7200

NSString * const ICLMediaAssessorErrorDomain = @"ICLMediaAssessorErrorDomain";

@interface ICLMediaAssessorConfiguration : NSObject
@property (nonatomic, copy) ICLMediaAssessorCompletionBlock completionBlock;
@property (nonatomic, assign) ICLMediaType expectedType;
@property (nonatomic, copy) NSURL *url;
@end

@interface ICLMediaAssessorLimits : NSObject
@property (nonatomic, assign) NSUInteger imageMaximumWidth;
@property (nonatomic, assign) NSUInteger imageMaximumHeight;
@property (nonatomic, assign) unsigned long long imageMaximumFilesize;
@end

@interface ICLMediaAssessorRequest : NSObject
@property (nonatomic, strong, nullable) NSURLSession *session;
@property (nonatomic, strong, nullable) NSURLSessionTask *task;
@property (nonatomic, copy, nullable) NSError *alternateError;
@property (nonatomic, assign) BOOL doNotFinalize;
@end

@interface ICLMediaAssessorState : NSObject
@property (nonatomic, copy, nullable) ICLMediaAssessment *assessment;
@property (nonatomic, assign) BOOL performExtendedValidation;
@end

@interface ICLMediaAssessor ()
{
@private
	BOOL _objectInitialized;
}

@property (nonatomic, strong, nullable) ICLMediaAssessorConfiguration *config;
@property (nonatomic, strong, nullable) ICLMediaAssessorLimits *limits;
@property (nonatomic, strong, nullable) ICLMediaAssessorRequest *request;
@property (nonatomic, strong, nullable) ICLMediaAssessorState *state;
@end

@implementation ICLMediaAssessor

#pragma mark -
#pragma mark Construction

ClassWithDesignatedInitializerInitMethod

+ (instancetype)assessorForAddress:(NSString *)address completionBlock:(ICLMediaAssessorCompletionBlock)completionBlock
{
	return [self assessorForAddress:address withType:ICLMediaTypeUnknown completionBlock:completionBlock];
}

+ (instancetype)assessorForURL:(NSURL *)url completionBlock:(ICLMediaAssessorCompletionBlock)completionBlock
{
	return [self assessorForURL:url withType:ICLMediaTypeUnknown completionBlock:completionBlock];
}

+ (instancetype)assessorForAddress:(NSString *)address withType:(ICLMediaType)type completionBlock:(ICLMediaAssessorCompletionBlock)completionBlock
{
	ICLMediaAssessor *object = [[self alloc] initWithAddress:address withType:type completionBlock:completionBlock];

	return object;
}

+ (instancetype)assessorForURL:(NSURL *)url withType:(ICLMediaType)type completionBlock:(ICLMediaAssessorCompletionBlock)completionBlock
{
	ICLMediaAssessor *object = [[self alloc] initWithURL:url withType:type completionBlock:completionBlock];

	return object;
}

- (instancetype)initWithAddress:(NSString *)address withType:(ICLMediaType)type completionBlock:(ICLMediaAssessorCompletionBlock)completionBlock
{
	NSParameterAssert(address != nil);
	NSParameterAssert(completionBlock != nil);

	NSURL *url = [NSURL URLWithString:address];

	return [self initWithURL:url withType:type completionBlock:completionBlock];
}

- (instancetype)initWithURL:(NSURL *)url withType:(ICLMediaType)type completionBlock:(ICLMediaAssessorCompletionBlock)completionBlock
{
	NSParameterAssert(url != nil);
	NSParameterAssert(url.isFileURL == NO);
	NSParameterAssert(completionBlock != nil);

	ObjectIsAlreadyInitializedAssert

	if ((self = [super init])) {
		[self prepareToAssessURL:url withType:type completionBlock:completionBlock];

		self->_objectInitialized = YES;

		return self;
	}

	return nil;
}

- (void)prepareToAssessURL:(NSURL *)url withType:(ICLMediaType)type completionBlock:(ICLMediaAssessorCompletionBlock)completionBlock
{
	NSParameterAssert(url != nil);
	NSParameterAssert(completionBlock != nil);

	ObjectIsAlreadyInitializedAssert

	/* Prepare configuration */
	ICLMediaAssessorConfiguration *config = [ICLMediaAssessorConfiguration new];

	config.completionBlock = completionBlock;

	config.expectedType = type;

	config.url = url;

	self.config = config;
}

#pragma mark -
#pragma mark Actions (Public)

- (void)resume
{
	[self _assess];
}

- (void)suspend
{
	[self _cancel];
}

#pragma mark -
#pragma mark Actions (Private)

- (void)_assess
{
	NSAssert((self.request == nil), @"An assessment is already in progress");

	ICLMediaAssessorConfiguration *config = self.config;

	NSAssert((config != nil), @"-assess called after an assessment finalized");

	/* Prepare request */
	ICLMediaAssessorRequest *request = [ICLMediaAssessorRequest new];

	NSURLSession *urlSession = [NSURLSession sessionWithConfiguration:[self.class _sharedSessionConfiguration] delegate:(id)self delegateQueue:nil];

	request.session = urlSession;

	/* We use a data task which is always GET.
	 Many services block HEAD requests, so we use GET.
	 When we are only interested in the headers, we close the
	 connection after receiving them, so we don't waste resources. */
	NSURLSessionDataTask *urlSessionTask = [urlSession dataTaskWithURL:config.url];

	request.task = urlSessionTask;

	self.request = request;

	/* Prepare limits */
	ICLMediaType expectedType = self.config.expectedType;

	if (expectedType == ICLMediaTypeUnknown ||
		expectedType == ICLMediaTypeImage)
	{
		ICLMediaAssessorLimits *limits = [ICLMediaAssessorLimits new];

		limits.imageMaximumWidth = _assessorMaximumImageWidth;
		limits.imageMaximumHeight = [TPCPreferences inlineMediaMaxHeight];
		limits.imageMaximumFilesize = [TPCPreferences inlineImagesMaxFilesize];

		self.limits = limits;
	}

	/* Perform request */
	[urlSessionTask resume];
}

- (void)_cancel
{
	[self _cancelRequest];
}

#pragma mark -
#pragma mark Utilities

- (void)_cancelRequest
{
	ICLMediaAssessorRequest *request = self.request;

	if (request == nil) {
		return;
	}

	request.doNotFinalize = YES;

	NSURLSession *session = request.session;

	[session invalidateAndCancel];
}

- (void)_flushRequestState
{
	self.limits = nil;
	self.state = nil;
	self.request = nil;
}

- (void)_finalizeAssessmentWithError:(nullable NSError *)error
{
	if (error.isURLSessionCancelError) {
		error = self.request.alternateError;
	}

	[self _performCompletionBlockWithError:error];

	[self _flushRequestState];

	self.config = nil;
}

- (void)_performCompletionBlockWithError:(nullable NSError *)error
{
	ICLMediaAssessorConfiguration *config = self.config;

	ICLMediaAssessment *assessment = self.state.assessment;

	/* This condition is typically true when we refuse an authentication challenge. */
	if (error == nil && assessment == nil) {
		error = [self _errorWithDescription:@"Assessment failed" code:ICLMediaAssessorErrorCodeAssessmentFailed];
	}

	config.completionBlock(assessment, error);
}

- (NSError *)_errorWithDescription:(NSString *)errorDescription code:(ICLMediaAssessorErrorCode)errorCode
{
	NSParameterAssert(errorDescription != nil);

	return
	[NSError errorWithDomain:ICLMediaAssessorErrorDomain
						code:errorCode
					userInfo:@{
		NSLocalizedDescriptionKey : errorDescription
	}];
}

#pragma mark -
#pragma mark URL Session Delegate

+ (NSURLSessionConfiguration *)_sharedSessionConfiguration
{
	static NSURLSessionConfiguration *config = nil;

	static dispatch_once_t onceToken;

	dispatch_once(&onceToken, ^{
		config = [NSURLSessionConfiguration ephemeralSessionConfiguration];

		/* Ignore local caches */
		config.requestCachePolicy = NSURLRequestReloadIgnoringLocalCacheData;

		/* Do not send cookies from local store */
		config.HTTPShouldSetCookies = NO;

		/* Do not allow cookies to be set */
		config.HTTPCookieAcceptPolicy = NSHTTPCookieAcceptPolicyNever;
	});

	return config;
}

- (nullable ICLMediaAssessorState *)_readHeadersInWithError:(NSError **)error
{
	NSParameterAssert(error != NULL);

	NSHTTPURLResponse *response = (id)self.request.task.response;

	/* Read in status code */
	if (response.statusCode != 200) {
		*error = [self _errorWithDescription:@"Endpoint did not respond with OK (200)" code:ICLMediaAssessorErrorCodeUnexpectedStatusCode];

		return nil;
	}

	/* Read in content type */
	NSString *contentType = response.MIMEType;

	if (contentType.length > 128) {
		*error = [self _errorWithDescription:@"Content-Type header is improperly formatted" code:ICLMediaAssessorErrorCodeMalformedContentType];

		return nil;
	}

	/* Read in content length */
	long long contentLength = response.expectedContentLength;

	if (contentLength <= 0) {
		*error = [self _errorWithDescription:@"Content-Length header is improperly formatted" code:ICLMediaAssessorErrorCodeMalformedContentLength];

		return nil;
	}

	/* Figure out what type of media this is */
	ICLMediaType mediaType = ICLMediaTypeOther;

	BOOL performExtendedValidation = NO;

	/* Content is an image */
	if ([[self.class validImageContentTypes] containsObject:contentType])
	{
		mediaType = ICLMediaTypeImage;
	}

	/* Content is a video */
	else if ([[self.class validVideoContentTypes] containsObject:contentType])
	{
		mediaType = ICLMediaTypeVideo;
	}

	/* Is this a type we are interested in? */
	ICLMediaType expectedType = self.config.expectedType;

	if (expectedType != ICLMediaTypeUnknown &&
		expectedType != mediaType)
	{
		*error = [self _errorWithDescription:@"Unexpected media type" code:ICLMediaAssessorErrorCodeUnexpectedType];

		return nil;
	}

	/* Perform basic validation */
	switch (mediaType) {
		case ICLMediaTypeImage:
		{
			ICLMediaAssessorLimits *limits = self.limits;

			/* Limit maximum filesize */
			if (contentLength > limits.imageMaximumFilesize) {
				*error = [self _errorWithDescription:@"Content-Length exceeds maximum allowed" code:ICLMediaAssessorErrorCodeContentLengthExceeded];

				return nil;
			}

			/* Limiting the height of an image requires us to download
			 the contents of the image first, which we do by setting
			 the performExtendedValidation flag on the state. */
			if (limits.imageMaximumHeight > 0) {
				performExtendedValidation = YES;
			}

			break;
		}
		default:
		{
			break;
		}
	}

	/* Complete read in */
	ICLMediaAssessmentMutable *assessment =
	[[ICLMediaAssessmentMutable alloc] initWithURL:response.URL asType:mediaType];

	assessment.contentType = contentType;
	assessment.contentLength = contentLength;

	ICLMediaAssessorState *state = [ICLMediaAssessorState new];

	state.assessment = assessment;

	state.performExtendedValidation = performExtendedValidation;

	return state;
}

#pragma mark
#pragma mark URL Session Delegate Cont.

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveResponse:(NSURLResponse *)response completionHandler:(void (^)(NSURLSessionResponseDisposition disposition))completionHandler
{
	/* Response might not be an HTTP response if we
	 end up receiving a redirect to a data URL. */
	if ([response isKindOfClass:[NSHTTPURLResponse class]] == NO) {
		self.request.alternateError =
		[self _errorWithDescription:@"Invalid response type (not HTTP)" code:ICLMediaAssessorErrorCodeUnexpectedResponse];

		completionHandler(NSURLSessionResponseCancel);

		return;
	}

	/* Perform basic assessment of request.
	 -readHeadersIn returning a nil value indicates that
	 something was erroneous and we should not continue. */
	NSError *readHeadersInError;

	ICLMediaAssessorState *state = [self _readHeadersInWithError:&readHeadersInError];

	if (state == nil) {
		self.request.alternateError = readHeadersInError;

		completionHandler(NSURLSessionResponseCancel);

		return;
	}

	self.state = state;

	/* Some requests may require us to download the data
	 of the media to perform extended validation, such
	 as when the user limits the height of images. */
	/* When we don't have to perform extended validation,
	 we can just cancel any further actions because we
	 already have enough from the headers. */
	if (state.performExtendedValidation == NO) {
		completionHandler(NSURLSessionResponseCancel);

		return;
	}

	/* Change to download task */
	completionHandler(NSURLSessionResponseBecomeDownload);
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask willCacheResponse:(NSCachedURLResponse *)proposedResponse completionHandler:(void (^)(NSCachedURLResponse * _Nullable cachedResponse))completionHandler
{
	/* Do not perform caching */

	completionHandler(nil);
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task willPerformHTTPRedirection:(NSHTTPURLResponse *)response newRequest:(NSURLRequest *)request completionHandler:(void (^)(NSURLRequest * _Nullable))completionHandler
{
	/* Follow redirects */

	completionHandler(request);
}

- (void)URLSession:(NSURLSession *)session didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition disposition, NSURLCredential * _Nullable credential))completionHandler
{
	/* Refuse challenge requests */

	NSString *authenticationMethod = challenge.protectionSpace.authenticationMethod;

	if ([authenticationMethod isEqualToString:NSURLAuthenticationMethodHTTPBasic] ||
		[authenticationMethod isEqualToString:NSURLAuthenticationMethodHTTPDigest])
	{
		completionHandler(NSURLSessionAuthChallengeCancelAuthenticationChallenge, nil);

		return;
	}

	completionHandler(NSURLSessionAuthChallengePerformDefaultHandling, nil);
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didBecomeDownloadTask:(NSURLSessionDownloadTask *)downloadTask
{
	self.request.task = downloadTask;
}

- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didFinishDownloadingToURL:(NSURL *)location
{
	/* According to the documentation for NSURLSession,
	 the file at the URL will be deleted once this delegate
	 call completes which means we do not have to do much:
	 Just perform our extended validation, then return. */

	NSError *extendedValidationError;

	if ([self _performExtendedValidationAtURL:location withError:&extendedValidationError]) {
		return; /* Success */
	}

	self.request.alternateError = extendedValidationError;

	[session invalidateAndCancel];
}

- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didWriteData:(int64_t)bytesWritten totalBytesWritten:(int64_t)totalBytesWritten totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite
{
	/* Don't allow our Content-Length to lie to us/ */

	if ([self _downloadProgressExceededMaximumFilesize:totalBytesWritten] == NO) {
		return; /* Success */
	}

	self.request.alternateError =
	[self _errorWithDescription:@"Maximum response size exceeded" code:ICLMediaAssessorErrorCodeContentLengthExceeded];

	[session invalidateAndCancel];
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(nullable NSError *)error
{
	/* If -suspend was called on this object,
	 cleanup the request but do not finalize. */
	if (self.request.doNotFinalize) {
		[self _flushRequestState];

		return;
	}

	[self _finalizeAssessmentWithError:error];
}

#pragma mark -
#pragma mark Basic Validation

+ (NSArray<NSString *> *)validImageContentTypes
{
	static NSArray<NSString *> *cachedValue = nil;

	static dispatch_once_t onceToken;

	dispatch_once(&onceToken, ^{
		cachedValue =
		@[@"image/gif",
		  @"image/jpeg",
		  @"image/png",
		  @"image/svg+xml",
		  @"image/tiff",
		  @"image/x-ms-bmp"];
	});

	return cachedValue;
}

+ (NSArray<NSString *> *)validVideoContentTypes
{
	static NSArray<NSString *> *cachedValue = nil;

	static dispatch_once_t onceToken;

	dispatch_once(&onceToken, ^{
		cachedValue =
		@[@"video/3gpp",
		  @"video/3gpp2",
		  @"video/mp4",
		  @"video/quicktime",
		  @"video/x-m4v"];
	});

	return cachedValue;
}

#pragma mark -
#pragma mark Extended Validation

- (BOOL)_downloadProgressExceededMaximumFilesize:(unsigned long long)downloadProgress
{
	unsigned long long maximumFilesize = 0;

	switch (self.state.assessment.type) {
		case ICLMediaTypeImage:
		{
			maximumFilesize = self.limits.imageMaximumFilesize;

			break;
		}
		default:
		{
			break;
		}
	}

	if (maximumFilesize == 0) {
		return NO; /* Success */
	}

	return (downloadProgress > maximumFilesize);
}

- (BOOL)_performExtendedValidationAtURL:(NSURL *)url withError:(NSError **)error
{
	NSParameterAssert(url != nil);
	NSParameterAssert(error != NULL);

	switch (self.state.assessment.type) {
		case ICLMediaTypeImage:
		{
			return [self _performExtendedValidationForImageAtURL:url withError:error];

			break;
		}
		default:
		{
			break;
		}
	}

	return YES; /* Success */
}

- (BOOL)_performExtendedValidationForImageAtURL:(NSURL *)url withError:(NSError **)error
{
	NSParameterAssert(url != nil);
	NSParameterAssert(error != NULL);

	CGImageSourceRef image = CGImageSourceCreateWithURL((__bridge CFURLRef)url, NULL);

	if (image == NULL) {
		*error =
		[self _errorWithDescription:@"Image validation: CGImageSourceCreateWithURL() returned NULL" code:ICLMediaAssessorErrorCodeAssessmentFailed];

		return NO;
	}

	CFDictionaryRef imageProperties = CGImageSourceCopyPropertiesAtIndex(image, 0, NULL);

	if (imageProperties == NULL) {
		CFRelease(image);

		*error =
		[self _errorWithDescription:@"Image validation: CGImageSourceCopyPropertiesAtIndex() returned NULL" code:ICLMediaAssessorErrorCodeAssessmentFailed];

		return NO;
	}

	NSNumber *imageWidth = CFDictionaryGetValue(imageProperties, kCGImagePropertyPixelWidth);
	NSNumber *imageHeight = CFDictionaryGetValue(imageProperties, kCGImagePropertyPixelHeight);

	CFRelease(image);
	CFRelease(imageProperties);

	ICLMediaAssessorLimits *limits = self.limits;

	if (imageWidth.integerValue > limits.imageMaximumWidth)
	{
		*error = [self _errorWithDescription:@"Image validation: Maximum width exceeded" code:ICLMediaAssessorErrorCodeMaximumWidthExceeded];

		return NO;
	}
	else if (imageHeight.integerValue > limits.imageMaximumHeight)
	{
		*error = [self _errorWithDescription:@"Image validation: Maximum height exceeded" code:ICLMediaAssessorErrorCodeMaximumHeightExceeded];

		return NO;
	}

	return YES; /* Success */
}

#pragma mark -
#pragma mark Logging

+ (void)logError:(NSError *)error
{
	NSParameterAssert(error != nil);

	if ([error.domain isEqualToString:ICLMediaAssessorErrorDomain] == NO) {
		return;
	}

	ICLMediaAssessorErrorCode errorCode = error.code;

	switch (errorCode) {
		case ICLMediaAssessorErrorCodeAssessmentFailed:
		case ICLMediaAssessorErrorCodeUnexpectedStatusCode:
		case ICLMediaAssessorErrorCodeMalformedContentType:
		case ICLMediaAssessorErrorCodeMalformedContentLength:
		case ICLMediaAssessorErrorCodeUnexpectedResponse:
		{
			LogToConsoleDebug("Assessor fatal error: %@",
				error.localizedDescription);
		}
		case ICLMediaAssessorErrorCodeUnexpectedType:
		case ICLMediaAssessorErrorCodeContentLengthExceeded:
		case ICLMediaAssessorErrorCodeMaximumWidthExceeded:
		case ICLMediaAssessorErrorCodeMaximumHeightExceeded:
		{
			LogToConsoleDebug("Assessor validation error: %@",
				error.localizedDescription);
		}
	} // switch()
}

@end

#pragma mark -

@implementation ICLMediaAssessorConfiguration
@end

@implementation ICLMediaAssessorLimits
@end

@implementation ICLMediaAssessorRequest
@end

@implementation ICLMediaAssessorState
@end

NS_ASSUME_NONNULL_END
