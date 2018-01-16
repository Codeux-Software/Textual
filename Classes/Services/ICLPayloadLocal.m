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

#import "TPCPathInfoPrivate.h"
#import "ICLPayloadInternal.h"

NS_ASSUME_NONNULL_BEGIN

@implementation ICLPayload (ICLPayloadLocalPrivate)

- (NSString *)_resourcesTemporaryLocation
{
	NSString *sourcePath = [TPCPathInfo applicationTemporaryProcessSpecific];

	NSString *basePath = [sourcePath stringByAppendingPathComponent:@"/ICLPayload-Resources/"];

	[TPCPathInfo _createDirectoryAtPath:basePath];

	return basePath;
}

/* WebKit2 uses sandboxed processes. We copy the resources files to
 the application's temporary folder so that it can access them. */
- (nullable NSArray<NSString *> *)_copyResourcesToTemporaryLocation:(nullable NSArray<NSURL *> *)resources
{
	if (resources == nil) {
		return nil;
	}

	NSString *basePath = [self _resourcesTemporaryLocation];

	NSString *(^copyOperation)(NSURL *) = ^NSString *(NSURL *resourceURL)
	{
		if (resourceURL.isFileURL == NO) {
			return resourceURL.absoluteString;
		}

		NSString *resourcePath = resourceURL.relativePath;

		NSString *filename =
		[NSString stringWithFormat:@"%@.%@",
		 resourcePath.md5,
		 resourcePath.pathExtension];

		NSString *destinationPath = [basePath stringByAppendingPathComponent:filename];

		if ([RZFileManager() fileExistsAtPath:destinationPath]) {
			return destinationPath;
		}

		NSError *copyError;

		BOOL copyResult =
		[RZFileManager() copyItemAtPath:resourcePath
								 toPath:destinationPath
								  error:&copyError];

		if (copyResult == NO) {
			LogToConsoleError("Copy operation for '%@' failed with error: ",
				resourcePath, copyError.localizedDescription);
		}

		return destinationPath;
	};

	NSMutableArray<NSString *> *temporaryResources = [NSMutableArray arrayWithCapacity:resources.count];

	for (NSURL *resourceURL in resources) {
		@autoreleasepool {
			[temporaryResources addObject:copyOperation(resourceURL)];
		}
	}

	return [temporaryResources copy];
}

- (NSDictionary<NSString *, id> *)javaScriptObject
{
	NSMutableDictionary *dic = [NSMutableDictionary dictionary];

	[dic setUnsignedInteger:self->_contentLength forKey:@"contentLength"];

	[dic setObject:@{
		@"width" : @(self->_contentSize.width),
		@"height" : @(self->_contentSize.height)
	} forKey:@"contentSize"];

	[dic maybeSetObject:[self _copyResourcesToTemporaryLocation:self->_styleResources]
				 forKey:@"styleResources"];

	[dic maybeSetObject:[self _copyResourcesToTemporaryLocation:self->_scriptResources]
				 forKey:@"scriptResources"];

	[dic setObject:self->_html forKey:@"html"];

	NSString *entrypoint = self->_entrypoint;

	if (entrypoint) {
		[dic setObject:entrypoint forKey:@"entrypoint"];

		/* call self. instead of self->_ for entrypointPayload to allow
		 the default values to be assigned to the exported object. */
		[dic setObject:self.entrypointPayload forKey:@"entrypointPayload"];
	}

	[dic setObject:self->_url forKey:@"url"];
	[dic setObject:self->_urlToInline forKey:@"urlToInline"];

	[dic setObject:self->_lineNumber forKey:@"lineNumber"];

	[dic setObject:self->_uniqueIdentifier forKey:@"uniqueIdentifier"];
//	[dic setObject:self->_viewIdentifier forKey:@"viewIdentifier"];

	[dic setUnsignedInteger:self->_index forKey:@"index"];

	return [dic copy];
}

@end

NS_ASSUME_NONNULL_END
