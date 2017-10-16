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

@interface ICMVimeo ()
@property (nonatomic, copy) NSString *videoIdentifier;
@end

@implementation ICMVimeo

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
		__weak ICMVimeo *moduleTyped = (id)module;

		moduleTyped.videoIdentifier = videoIdentifier;

		[moduleTyped _performAction];
	} copy];
}

+ (nullable NSString *)_videoIdentifierForURL:(NSURL *)url
{
	NSString *urlHost = url.host.lowercaseString;

	if ([urlHost isEqualToString:@"vimeo.com"] == NO &&
		[urlHost isEqualToString:@"www.vimeo.com"] == NO)
	{
		return nil;
	}

	NSString *urlPath = url.path.percentEncodedURLPath;

	if (urlPath.length == 0) {
		return nil;
	}

	NSString *videoIdentifier = [videoIdentifier trimCharacters:@"/"];

	if (videoIdentifier.isNumericOnly == NO) {
		return nil;
	}

	return videoIdentifier;
}

#pragma mark -
#pragma mark Utilities

- (nullable GRMustacheTemplate *)template
{
	static GRMustacheTemplate *template = nil;

	static dispatch_once_t onceToken;

	dispatch_once(&onceToken, ^{
		NSString *templatePath =
		[RZMainBundle() pathForResource:@"ICMVimeo" ofType:@"mustache" inDirectory:@"Components"];

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

- (nullable NSArray<NSString *> *)styleResources
{
	static NSArray<NSString *> *styleResources = nil;

	static dispatch_once_t onceToken;

	dispatch_once(&onceToken, ^{
		styleResources =
		@[
		  [RZMainBundle() pathForResource:@"ICMVimeo" ofType:@"css" inDirectory:@"Components"]
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
		  [RZMainBundle() pathForResource:@"ICMInlineVideo" ofType:@"js" inDirectory:@"Components"],
		  [RZMainBundle() pathForResource:@"ICMVimeo" ofType:@"js" inDirectory:@"Components"]
		];
	});

	return scriptResources;
}

- (nullable NSString *)entrypoint
{
	return @"_ICMVimeo";
}

@end

NS_ASSUME_NONNULL_END
