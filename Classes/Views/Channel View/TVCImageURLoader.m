/* ********************************************************************* 
       _____        _               _    ___ ____   ____
      |_   _|___  _| |_ _   _  __ _| |  |_ _|  _ \ / ___|
       | |/ _ \ \/ / __| | | |/ _` | |   | || |_) | |
       | |  __/>  <| |_| |_| | (_| | |   | ||  _ <| |___
       |_|\___/_/\_\\__|\__,_|\__,_|_|  |___|_| \_\\____|

 Copyright (c) 2010 — 2013 Codeux Software & respective contributors.
        Contributors.rtfd and Acknowledgements.rtfd

 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions
 are met:

    * Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the
      documentation and/or other materials provided with the distribution.
    * Neither the name of the Textual IRC Client & Codeux Software nor the
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

#import "TextualApplication.h"

#define _imageLoaderMaxRequestTime			30

/* We shouldn't want to load anything larger than this. */
#define _imageMaximumImageWidth				5000

/* Private stuff. =) */
@interface TVCImageURLoader ()
@property (nonatomic, nweak) TVCLogController *requestOwner;
@property (nonatomic, strong) NSMutableData *responseData;
@property (nonatomic, strong) NSString *requestImageUniqeID;
@property (nonatomic, strong) NSURLConnection *requestConnection;
@property (nonatomic, strong) NSHTTPURLResponse *requestResponse;
@property (nonatomic, assign) BOOL isInRequestWithCheckForMaximumHeight;
@end

@implementation TVCImageURLoader

#pragma mark -
#pragma mark Public API

- (NSArray *)headRequestExceptions
{
	/* List of services that will only respond successfully to a 
	 GET request instead of a HEAD request. */

	return @[
		@"docs.google.com"
	];
}

- (void)destroyConnectionRequest
{
	if (self.requestConnection) {
		[self.requestConnection cancel];
	}

	self.requestImageUniqeID = nil;
	self.requestConnection = nil;
	self.requestResponse = nil;
	self.requestOwner = nil;
	self.responseData = nil;
}

- (void)assesURL:(NSString *)baseURL withID:(NSString *)uniqueID forController:(TVCLogController *)controller
{
	/* Validate input. */
	PointerIsEmptyAssert(controller);

	NSObjectIsEmptyAssert(baseURL);
	NSObjectIsEmptyAssert(uniqueID);

	/* Reset the connection if needed. Probably wont be ever needed, but just incase… */
	[self destroyConnectionRequest];

	/* Create the request. */
	/* We use a mutable request because we are going to set the HTTP method. */
	NSURL *requestURL = [NSURL URLWithString:baseURL];

	NSMutableURLRequest *baseRequest = [NSMutableURLRequest requestWithURL:requestURL
															   cachePolicy:NSURLRequestReloadIgnoringCacheData
														   timeoutInterval:_imageLoaderMaxRequestTime];

	/* This is stored in a local variable so that a user changing something during a load in
	 progess, it does not fuck up any of the already existing requests. */
	self.isInRequestWithCheckForMaximumHeight = ([TPCPreferences inlineImagesMaxHeight] > 0);

	if (self.isInRequestWithCheckForMaximumHeight) {
		self.responseData = [NSMutableData data];

		[baseRequest setHTTPMethod:@"GET"];
	} else {
		if ([self.headRequestExceptions containsObject:requestURL.host]) {
			[baseRequest setHTTPMethod:@"GET"];
		} else {
			[baseRequest setHTTPMethod:@"HEAD"]; // We only want the HEAD which contains file information.
		}
	}

	/* Send the actual request off. */
	self.requestImageUniqeID = uniqueID;
	self.requestOwner = controller;

	self.requestConnection = [[NSURLConnection alloc] initWithRequest:baseRequest delegate:self];

	[self.requestConnection start];
}

#pragma mark -
#pragma mark NSURLConnection Delegate

- (BOOL)continueWithImageProcessing
{
	PointerIsEmptyAssertReturn(self.requestResponse, NO);

	/* Get data from headers. */
	NSDictionary *headers = self.requestResponse.allHeaderFields;

	TXFSLongInt sizeInBytes = [headers longLongForKey:@"Content-Length"];

	NSString *imageContentType = [headers stringForKey:@"Content-Type"];

	/* Check size. */
	if (sizeInBytes > [TPCPreferences inlineImagesMaxFilesize] || sizeInBytes < 10) {
		return NO;
	}

	/* Check type. */
	NSArray *validContentTypes = [TVCImageURLParser validImageContentTypes];

	if ([validContentTypes containsObject:imageContentType] == NO) {
		return NO;
	}

	return YES;
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
	/* Yay! It finished loading. Time to check the data out. :-D */
	BOOL isValidResponse = (self.requestResponse.statusCode == 200); // Setting as a var incase I end up adding more conditions down the line.

    if (isValidResponse) {
		if (self.isInRequestWithCheckForMaximumHeight) { // Are we checking the actual image size?
			PointerIsEmptyAssert(self.responseData); // I hope we had some data…

			NSImage *loadedImage = [[NSImage alloc] initWithData:self.responseData]; // Create the NSImage instance of the image.

			PointerIsEmptyAssert(loadedImage); // Did something fail?

			/* The first image rep of the NSImage we have is taken in order to check the height
			 of the image because it may be an animated gif so NSImage will return a size of
			 0, 0 for itself unless we check the first rep. */
			NSBitmapImageRep *firstRep = [[loadedImage representations] objectAtIndex:0];

			if ([firstRep pixelsHigh] > [TPCPreferences inlineImagesMaxHeight] || [firstRep pixelsWide] > _imageMaximumImageWidth) { // So what's up with the size?
				firstRep = nil;
				loadedImage = nil;

				[self destroyConnectionRequest]; // Destroy local vars.

				return; // Image is too big, don't do crap with it.
			}
		}

		/* Send the information off. We will validate the information higher up. */
		[self.requestOwner imageLoaderFinishedLoadingForImageWithID:self.requestImageUniqeID];
	}

	/* Cleaning. */
	[self destroyConnectionRequest];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
	/* We failed with error… that is not good. */
	[self destroyConnectionRequest]; // Destroy the existing request.

	/* Log something… */
	LogToConsole(@"Failed to complete connection request with error: %@", [error localizedDescription]);
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
	if (self.isInRequestWithCheckForMaximumHeight) {
		[self.responseData appendData:data]; // We only care about the data if we are going to be checking its size.
	}
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
	self.requestResponse = (id)response; // Save a reference to our response.

	if ([self continueWithImageProcessing] == NO) { // Check the headers.
		[self destroyConnectionRequest]; // Destroy the connection if we do not want to continue.
	}
}

- (NSCachedURLResponse *)connection:(NSURLConnection *)connection willCacheResponse:(NSCachedURLResponse *)cachedResponse
{
	return nil; /* Do not return any cache. */
}

@end
