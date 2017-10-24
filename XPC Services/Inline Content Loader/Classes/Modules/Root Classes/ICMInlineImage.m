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

@interface ICMInlineImage ()
@property (nonatomic, strong, nullable) ICLMediaAssessor *imageCheck;
@property (nonatomic, copy, nullable) NSString *finalAddress;
@end

@implementation ICMInlineImage

- (void)performActionForFinalAddress:(NSString *)address
{
	[self performActionForFinalAddress:address bypassImageCheck:NO];
}

- (void)performActionForFinalAddress:(NSString *)address bypassImageCheck:(BOOL)bypassImageCheck
{
	NSParameterAssert(address != nil);

	NSAssert((self.finalAddress == nil), @"Module already initialized");

	/* If we do not force a scheme,
	 then file:// is used by WebKit. */
	if ([address hasPrefix:@"//"]) {
		address = [@"https:" stringByAppendingString:address];
	}

	self.finalAddress = address;

	if (bypassImageCheck == NO) {
		[self _performImageCheck];
	} else {
		[self _safeToLoadImage];
	}
}

- (void)_performImageCheck
{
	ICLMediaAssessor *imageCheck =
	[ICLMediaAssessor assessorForAddress:self.finalAddress
								withType:ICLMediaTypeImage
						 completionBlock:^(ICLMediaAssessment *assessment, NSError *error) {
							 BOOL safeToLoad = (error == nil);

							 if (safeToLoad) {
								 [self _safeToLoadImage];
							 } else {
								 [self _unsafeToLoadImage];
							 }

							 self.imageCheck = nil;
						 }];

	self.imageCheck = imageCheck;

	[imageCheck resume];
}

- (void)_unsafeToLoadImage
{
	[self notifyUnsafeToLoadImage];
}

- (void)_safeToLoadImage
{
	ICLPayloadMutable *payload = self.payload;

	NSDictionary *templateAttributes =
	@{
		@"anchorLink" : payload.url.absoluteString,
		@"classAttribute" : self.classAttribute,
		@"imageURL" : self.finalAddress,
		@"preferredMaximumWidth" : @([TPCPreferences inlineMediaMaxWidth]),
		@"uniqueIdentifier" : payload.uniqueIdentifier
	};

	NSError *templateRenderError = nil;

	NSString *html = [self.template renderObject:templateAttributes error:&templateRenderError];

	payload.html = html;

	self.completionBlock(templateRenderError);
}

- (void)notifyUnsafeToLoadImage
{
	self.completionBlock(self.genericValidationFailedError);
}

#pragma mark -
#pragma mark Action Block

+ (ICLInlineContentModuleActionBlock)actionBlockForFinalAddress:(NSString *)address
{
	return [self actionBlockForFinalAddress:address bypassImageCheck:NO];
}

+ (ICLInlineContentModuleActionBlock)actionBlockForFinalAddress:(NSString *)address bypassImageCheck:(BOOL)bypassImageCheck
{
	NSParameterAssert(address != nil);

	return [^(ICLInlineContentModule *module) {
		__weak ICMInlineImage *moduleTyped = (id)module;

		[moduleTyped performActionForFinalAddress:address bypassImageCheck:NO];
	} copy];
}

#pragma mark -
#pragma mark Utilities

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

@end

#pragma mark -
#pragma mark Foundation

@implementation ICMInlineImageFoundation

+ (BOOL)contentImageOrVideo
{
	return YES;
}

- (nullable NSURL *)templateURL
{
	return [RZMainBundle() URLForResource:@"ICMInlineImage" withExtension:@"mustache" subdirectory:@"Components"];
}

- (nullable NSArray<NSURL *> *)styleResources
{
	static NSArray<NSURL *> *styleResources = nil;

	static dispatch_once_t onceToken;

	dispatch_once(&onceToken, ^{
		styleResources =
		@[
		  [RZMainBundle() URLForResource:@"ICMInlineImage" withExtension:@"css" subdirectory:@"Components"]
		];
	});

	return styleResources;
}

- (nullable NSArray<NSURL *> *)scriptResources
{
	static NSArray<NSURL *> *scriptResources = nil;

	static dispatch_once_t onceToken;

	dispatch_once(&onceToken, ^{
		scriptResources =
		@[
		  [RZMainBundle() URLForResource:@"InlineImageLiveResize" withExtension:@"js"],
		  [RZMainBundle() URLForResource:@"ICMInlineImage" withExtension:@"js" subdirectory:@"Components"]
		];
	});

	return scriptResources;
}

- (nullable NSString *)entrypoint
{
	return @"_ICMInlineImage";
}

- (NSString *)classAttribute
{
	return @"";
}

@end

NS_ASSUME_NONNULL_END
