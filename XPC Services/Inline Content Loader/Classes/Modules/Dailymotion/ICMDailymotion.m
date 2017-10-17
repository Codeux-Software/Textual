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

@interface ICMDailymotion ()
@property (nonatomic, copy) NSString *videoIdentifier;
@end

@implementation ICMDailymotion

- (void)_performAction
{
	ICLPayloadMutable *payload = self.payload;

	NSDictionary *templateAttributes =
	@{
	  @"uniqueIdentifier" : payload.uniqueIdentifier,
	  @"videoIdentifier" : self.videoIdentifier
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

#pragma mark -
#pragma mark Action Block

+ (nullable ICLInlineContentModuleActionBlock)actionBlockForURL:(NSURL *)url
{
	NSString *videoIdentifier = [self _videoIdentifierForURL:url];

	if (videoIdentifier == nil) {
		return nil;
	}

	return [self _actionBlockForVideo:videoIdentifier];
}

+ (ICLInlineContentModuleActionBlock)_actionBlockForVideo:(NSString *)videoIdentifier
{
	NSParameterAssert(videoIdentifier != nil);

	return [^(ICLInlineContentModule *module) {
		__weak ICMDailymotion *moduleTyped = (id)module;

		moduleTyped.videoIdentifier = videoIdentifier;

		[moduleTyped _performAction];
	} copy];
}

+ (nullable NSString *)_videoIdentifierForURL:(NSURL *)url
{
	NSString *urlPath = url.path.percentEncodedURLPath;

	if ([urlPath hasPrefix:@"/video/"] == NO) {
		return nil;
	}

	urlPath = [urlPath substringFromIndex:7]; // "/video/"

	/* Cut after first underscore so that URLs such as:
	 http://www.dailymotion.com/video/x19pvwt_the-fantastic-four-1994-unreleased-roger-corman_shortfilms
	 Automatically translate to their parent:
	 http://www.dailymotion.com/video/x19pvwt */
	NSInteger underscorePosition = [urlPath stringPosition:@"_"];

	if (underscorePosition > 0) {
		urlPath = [urlPath substringToIndex:underscorePosition];
	}

	NSString *videoIdentifier = urlPath;

	if (videoIdentifier.isAlphabeticNumericOnly == NO) {
		return nil;
	}

	return videoIdentifier;
}

+ (nullable NSArray<NSString *> *)domains
{
	static NSArray<NSString *> *domains = nil;

	static dispatch_once_t onceToken;

	dispatch_once(&onceToken, ^{
		domains =
		@[
		  @"dailymotion.com",
		  @"www.dailymotion.com",
		  @"mobile.dailymotion.com"
		];
	});

	return domains;
}

#pragma mark -
#pragma mark Utilities

- (nullable GRMustacheTemplate *)template
{
	static GRMustacheTemplate *template = nil;

	static dispatch_once_t onceToken;

	dispatch_once(&onceToken, ^{
		NSString *templatePath =
		[RZMainBundle() pathForResource:@"ICMDailymotion" ofType:@"mustache" inDirectory:@"Components"];

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

- (nullable NSArray<NSString *> *)scriptResources
{
	static NSArray<NSString *> *scriptResources = nil;

	static dispatch_once_t onceToken;

	dispatch_once(&onceToken, ^{
		scriptResources =
		[[super scriptResources] arrayByAddingObjectsFromArray:
		@[
		  [RZMainBundle() pathForResource:@"ICMDailymotion" ofType:@"js" inDirectory:@"Components"]
		]];
	});

	return scriptResources;
}

- (nullable NSString *)entrypoint
{
	return @"_ICMDailymotion";
}

@end

NS_ASSUME_NONNULL_END
