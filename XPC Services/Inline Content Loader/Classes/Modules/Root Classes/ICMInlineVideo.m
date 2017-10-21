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

#import "ICMInlineVideoCheck.h"

NS_ASSUME_NONNULL_BEGIN

@interface ICMInlineVideo ()
@property (nonatomic, strong, nullable) ICMInlineVideoCheck *videoCheck;
@property (nonatomic, copy, nullable) NSString *finalAddress;
@end

@implementation ICMInlineVideo

- (void)performActionForFinalAddress:(NSString *)address
{
	[self performActionForFinalAddress:address bypassVideoCheck:NO];
}

- (void)performActionForFinalAddress:(NSString *)address bypassVideoCheck:(BOOL)bypassVideoCheck
{
	NSParameterAssert(address != nil);

	NSAssert((self.finalAddress == nil), @"Module already initialized");

	/* If we do not force a scheme,
	 then file:// is used by WebKit. */
	if ([address hasPrefix:@"//"]) {
		address = [@"https:" stringByAppendingString:address];
	}

	self.finalAddress = address;

	if (bypassVideoCheck == NO) {
		[self _performVideoCheck];
	} else {
		[self _safeToLoadVideo];
	}
}

- (void)_performVideoCheck
{
	ICMInlineVideoCheck *videoCheck = [ICMInlineVideoCheck new];

	self.videoCheck = videoCheck;

	[videoCheck checkAddress:self.finalAddress
			 completionBlock:^(BOOL safeToLoad, NSString * _Nullable videoOfType) {
			 if (safeToLoad) {
				 [self _safeToLoadVideo];
			 } else {
				 [self _unsafeToLoadVideo];
			 }

			 self.videoCheck = nil;
		 }];
}

- (void)_unsafeToLoadVideo
{
	[self notifyUnsafeToLoadVideo];
}

- (void)_safeToLoadVideo
{
	ICLPayloadMutable *payload = self.payload;

	double playbackSpeed = self.videoPlaybackSpeed;

	if (playbackSpeed < 0.125 || playbackSpeed > 6.0) {
		playbackSpeed = 1.0;
	}

	NSDictionary *templateAttributes =
	@{
		@"anchorLink" : payload.url.absoluteString,
		@"classAttribute" : self.classAttribute,
		@"preferredMaximumWidth" : @([TPCPreferences inlineMediaMaxWidth]),
		@"uniqueIdentifier" : payload.uniqueIdentifier,
		@"videoAutoplayEnabled" : @(self.videoAutoplayEnabled),
		@"videoControlsEnabled" : @(self.videoControlsEnabled),
		@"videoLoopEnabled" : @(self.videoLoopEnabled),
		@"videoMuteEnabled" : @(self.videoMuteEnabled),
		@"videoPlaybackSpeed" : @(playbackSpeed),
		@"videoStartTime" : @(self.videoStartTime),
		@"videoURL" : self.finalAddress
	};

	NSError *templateRenderError = nil;

	NSString *html = [self.template renderObject:templateAttributes error:&templateRenderError];

	/* We only want to assign to the payload if we have success (HTML) */
	if (html) {
		payload.html = html;

		payload.entrypoint = self.entrypoint;

		payload.styleResources = self.styleResources;
		payload.scriptResources = self.scriptResources;
	}

	self.completionBlock(templateRenderError);
}

- (void)notifyUnsafeToLoadVideo
{
	self.completionBlock(self.genericValidationFailedError);
}

#pragma mark -
#pragma mark Action Block

+ (ICLInlineContentModuleActionBlock)actionBlockForFinalAddress:(NSString *)address
{
	return [self actionBlockForFinalAddress:address bypassVideoCheck:NO];
}

+ (ICLInlineContentModuleActionBlock)actionBlockForFinalAddress:(NSString *)address bypassVideoCheck:(BOOL)bypassVideoCheck
{
	NSParameterAssert(address != nil);

	return [^(ICLInlineContentModule *module) {
		__weak ICMInlineVideo *moduleTyped = (id)module;

		[moduleTyped performActionForFinalAddress:address bypassVideoCheck:bypassVideoCheck];
	} copy];
}

#pragma mark -
#pragma mark Utilities

- (nullable GRMustacheTemplate *)template
{
	static GRMustacheTemplate *template = nil;

	static dispatch_once_t onceToken;

	dispatch_once(&onceToken, ^{
		NSString *templatePath =
		[RZMainBundle() pathForResource:@"ICMInlineVideo" ofType:@"mustache" inDirectory:@"Components"];

		/* This module isn't designed to handle GRMustacheTemplate ever returning a
		 nil value, but if it ever happens, we log error to better understand why. */
		NSError *templateLoadError;

		template = [GRMustacheTemplate templateFromContentsOfFile:templatePath error:&templateLoadError];

		if (template == nil) {
			LogToConsoleError("Failed to load template '%@': %@",
				templatePath, templateLoadError.localizedDescription);
		}
	});

	return template;
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

@implementation ICMInlineVideoFoundation

- (instancetype)initWithPayload:(ICLPayloadMutable *)payload completionBlock:(ICLInlineContentModuleCompletionBlock)completionBlock
{
	if ((self = [super initWithPayload:payload completionBlock:completionBlock])) {
		[self prepareInitialState];

		return self;
	}

	return nil;
}

- (void)prepareInitialState
{
	self.videoControlsEnabled = YES;

	self.videoPlaybackSpeed = 1.0;
}

- (nullable NSArray<NSString *> *)styleResources
{
	static NSArray<NSString *> *styleResources = nil;

	static dispatch_once_t onceToken;

	dispatch_once(&onceToken, ^{
		styleResources =
		@[
		  [RZMainBundle() pathForResource:@"ICMInlineVideo" ofType:@"css" inDirectory:@"Components"]
		];
	});

	return styleResources;
}

- (nullable NSArray<NSString *> *)scriptResources
{
	static NSArray<NSString *> *scriptResources = nil;

	static dispatch_once_t onceToken;

	dispatch_once(&onceToken, ^{
		scriptResources =
		@[
		  [RZMainBundle() pathForResource:@"ICMInlineVideo" ofType:@"js" inDirectory:@"Components"]
		];
	});

	return scriptResources;
}

- (nullable NSString *)entrypoint
{
	return @"_ICMInlineVideo";
}

@end

#pragma mark -
#pragma mark Gif Video

@implementation ICMInlineGifVideo

- (instancetype)initWithPayload:(ICLPayloadMutable *)payload completionBlock:(ICLInlineContentModuleCompletionBlock)completionBlock
{
	if ((self = [super initWithPayload:payload completionBlock:completionBlock])) {
		[self prepareInitialState];

		return self;
	}

	return nil;
}

- (void)prepareInitialState
{
	[super prepareInitialState];

	self.videoAutoplayEnabled = YES;
	self.videoControlsEnabled = NO;
	self.videoLoopEnabled = YES;
	self.videoMuteEnabled = YES;
}

@end

NS_ASSUME_NONNULL_END
