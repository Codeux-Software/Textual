/* ********************************************************************* 
       _____        _               _    ___ ____   ____
      |_   _|___  _| |_ _   _  __ _| |  |_ _|  _ \ / ___|
       | |/ _ \ \/ / __| | | |/ _` | |   | || |_) | |
       | |  __/>  <| |_| |_| | (_| | |   | ||  _ <| |___
       |_|\___/_/\_\\__|\__,_|\__,_|_|  |___|_| \_\\____|

 Copyright (c) 2010 — 2014 Codeux Software & respective contributors.
     Please see Acknowledgements.pdf for additional information.

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

#define _requestTimeoutInterval			30.0

@interface TDCFileTransferDialogRemoteAddress ()
@property (nonatomic, uweak) id requestDelegate;
@property (nonatomic, strong) NSMutableData *responseData;
@property (nonatomic, strong) NSURLConnection *requestConnection;
@property (nonatomic, strong) NSHTTPURLResponse *requestResponse;
@end

@implementation TDCFileTransferDialogRemoteAddress

#pragma mark -
#pragma mark Public API

- (void)requestRemoteIPAddressFromExternalSource:(id)delegate
{
	/* Who would we be talking with? */
	PointerIsEmptyAssert(delegate);
	
	/* Remember it. */
	self.requestDelegate = delegate;
	
	/* Do work… */
	[self setupConnectionRequest];
}

- (void)destroyConnectionRequest
{
	if ( self.requestConnection) {
		[self.requestConnection cancel];
	}
	
	self.requestConnection = nil;
	self.requestResponse = nil;
	self.responseData = nil;
}

- (void)setupConnectionRequest
{
	/* Pointer to write to. */
	self.responseData = [NSMutableData data];
	
	/* Setup request. */
	NSURL *requestURL = [NSURL URLWithString:[self addressSourceURL]];
	
	NSMutableURLRequest *baseRequest = [NSMutableURLRequest requestWithURL:requestURL
															   cachePolicy:NSURLRequestReloadIgnoringCacheData
														   timeoutInterval:_requestTimeoutInterval];
	
	[baseRequest setHTTPMethod:@"GET"];
	
	/* Create the connection and request it. */
	 self.requestConnection = [[NSURLConnection alloc] initWithRequest:baseRequest delegate:self];
	
	[self.requestConnection start];
}

- (NSString *)addressSourceURL
{
	NSArray *services = @[
	  @"http://wtfismyip.com/text",
	  @"http://canhazip.com/",
	  @"http://ifconfig.me/ip",
	  @"http://v4.ipv6-test.com/api/myip.php",
	];
	
	NSInteger rndIndx = (arc4random() % [services count]);

	return services[rndIndx];
}

#pragma mark -
#pragma mark Connection Delegate

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
	/* Yay! It finished loading. Time to check the data out. :-D */
	BOOL isValidResponse = ([self.requestResponse statusCode] == 200);
	
    if (isValidResponse) {
		NSString *address = [NSString stringWithData:self.responseData encoding:NSUTF8StringEncoding];
		
		if (self.requestDelegate) {
			if ([self.requestDelegate respondsToSelector:@selector(fileTransferRemoteAddressRequestDidDetectAddress:)]) {
				[self.requestDelegate fileTransferRemoteAddressRequestDidDetectAddress:address];
			}
		}
	}
	
	/* Cleaning. */
	[self destroyConnectionRequest];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
	/* We failed with error… that is not good. */
	[self destroyConnectionRequest]; // Destroy the existing request.
	
	/* Log something… */
	if (self.requestDelegate) {
		if ([self.requestDelegate respondsToSelector:@selector(fileTransferRemoteAddressRequestDidCloseWithError:)]) {
			[self.requestDelegate fileTransferRemoteAddressRequestDidCloseWithError:error];
		}
	}
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
	[self.responseData appendData:data]; // Just writing comments at this point to write them. dealwithit.gif
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
	self.requestResponse = (id)response; // Save a reference to our response.
}

- (NSCachedURLResponse *)connection:(NSURLConnection *)connection willCacheResponse:(NSCachedURLResponse *)cachedResponse
{
	return nil; /* Do not return any cache. */
}

@end
