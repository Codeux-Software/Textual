/* ********************************************************************* 
                  _____         _               _
                 |_   _|____  _| |_ _   _  __ _| |
                   | |/ _ \ \/ / __| | | |/ _` | |
                   | |  __/>  <| |_| |_| | (_| | |
                   |_|\___/_/\_\\__|\__,_|\__,_|_|

 Copyright (c) 2010 — 2014 Codeux Software, LLC & respective contributors.
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

#import "TPISystemProfilerModelIDRequestController.h"

/* This is a sloppy, self-contained mess which I wrote in 1 hour. Give me a break! */

#pragma mark -
#pragma mark Private Declarations

#define _requestTimeoutInterval			30.0

#define _userDefaultsModelCacheKey			@"Private Extension Store -> System Profiler Extension -> Cached Model Identifier Value"
#define _userDefaultsSerialCacheKey			@"Private Extension Store -> System Profiler Extension -> Cached Serial Number Value"

@interface TPISystemProfilerModelIDRequestController ()
@property (nonatomic, strong) id internalObject;

- (void)tearDownInternalObject;
@end

@interface TPISystemProfilerModelIDRequestControllerInternal : NSObject <NSXMLParserDelegate, NSURLConnectionDelegate>
@property (nonatomic, assign) BOOL xmlParserIsOnTargetElement; /* We are only targetting a single value so a BOOL is enough. */
@property (nonatomic, strong) NSXMLParser *xmlParserObject;
@property (nonatomic, strong) NSMutableString *xmlParsedTemporaryStore;
@property (nonatomic, strong) NSMutableData *responseData;
@property (nonatomic, strong) NSURLConnection *requestConnection;
@property (nonatomic, strong) NSHTTPURLResponse *requestResponse;
@property (nonatomic, copy) NSString *serialNumberValue;

- (void)setupConnectionRequest;
@end

#pragma mark -
#pragma mark Public Interface

@implementation TPISystemProfilerModelIDRequestController

+ (instancetype)sharedController
{
	static id sharedSelf = nil;

	static dispatch_once_t onceToken;

	dispatch_once(&onceToken, ^{
		 sharedSelf = [TPISystemProfilerModelIDRequestController new];
	});

	return sharedSelf;
}

- (void)requestIdentifier
{
	/* Check cache before requesting a new identifier */
	NSString *currentSerial = [self serialNumberCharacters];

	id cachedValue = [RZUserDefaults() objectForKey:_userDefaultsModelCacheKey];

	if (cachedValue) {
		id cachedSerialNumber = [RZUserDefaults() objectForKey:_userDefaultsSerialCacheKey];

		if (cachedSerialNumber) {
			if ([cachedSerialNumber isEqual:currentSerial]) {
				return; // Matching serial numbers…
			} else {
				/* Invalidate cache. */
				[RZUserDefaults() removeObjectForKey:_userDefaultsModelCacheKey];

				[RZUserDefaults() removeObjectForKey:_userDefaultsSerialCacheKey];
			}
		}
	}

	/* Cached failed, check with Apple */
	[self setInternalObject:[TPISystemProfilerModelIDRequestControllerInternal new]];

	[[self internalObject] setSerialNumberValue:currentSerial];
	[[self internalObject] setupConnectionRequest];
}

- (NSString *)cachedIdentifier
{
	return [RZUserDefaults() objectForKey:_userDefaultsModelCacheKey];
}

- (void)tearDownInternalObject
{
	[self setInternalObject:nil];
}

- (NSString *)serialNumberCharacters
{
	/* Retrieve serial number of this Mac. */
	NSString *serial = nil;

	io_service_t platformExpert = IOServiceGetMatchingService(kIOMasterPortDefault, IOServiceMatching("IOPlatformExpertDevice"));

	if (platformExpert) {
		CFTypeRef serialNumberAsCFString =

		IORegistryEntryCreateCFProperty(platformExpert, CFSTR(kIOPlatformSerialNumberKey), kCFAllocatorDefault, 0);

		if (serialNumberAsCFString) {
			serial = CFBridgingRelease(serialNumberAsCFString);
		}

		IOObjectRelease(platformExpert);
	}

	/* The format of serial numbers changed a few years back so we check length
	 to know how many characters to give Apple. This entire thing is a hack. */
	if ([serial length] == 11) {
		serial = [serial substringFromIndex:([serial length] - 3)];
	} else if ([serial length] == 12) {
		serial = [serial substringFromIndex:([serial length] - 4)];
	} else {
		serial = nil;
	}

	return serial;
}

@end

@implementation TPISystemProfilerModelIDRequestControllerInternal

#pragma mark -
#pragma mark Private Interface

- (void)tearDownInternalObject
{
	TXPerformBlockAsynchronouslyOnMainQueue(^{
		[[TPISystemProfilerModelIDRequestController sharedController] tearDownInternalObject];
	});
}

#pragma mark -
#pragma mark Connection Delegate

- (NSString *)addressSourceURL
{
	NSString *serialCode = [[TPISystemProfilerModelIDRequestController sharedController] serialNumberCharacters];

	return [NSString stringWithFormat:@"http://support-sp.apple.com/sp/product?cc=%@&lang=en_US", serialCode];
}

- (void)destroyConnectionRequest
{
	if ( [self requestConnection]) {
		[[self requestConnection] cancel];
	}

	[self setRequestConnection:nil];
	[self setRequestResponse:nil];
	[self setResponseData:nil];
}

- (void)setupConnectionRequest
{
	[self setResponseData:[NSMutableData data]];

	NSURL *requestURL = [NSURL URLWithString:[self addressSourceURL]];

	NSMutableURLRequest *baseRequest = [NSMutableURLRequest requestWithURL:requestURL
															   cachePolicy:NSURLRequestReloadIgnoringCacheData
														   timeoutInterval:_requestTimeoutInterval];

	[baseRequest setHTTPMethod:@"GET"];

	NSURLConnection *reqeust = [[NSURLConnection alloc] initWithRequest:baseRequest delegate:self];

	[self setRequestConnection:reqeust];

	[[self requestConnection] start];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
	BOOL isValidResponse = ([[self requestResponse] statusCode] == 200);

	if (isValidResponse) {
		[self didRecieveXMLData:[self responseData]];
	} else {
		[self tearDownInternalObject];
	}

	[self destroyConnectionRequest];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
	[self destroyConnectionRequest]; // Destroy the existing request.

	[self tearDownInternalObject];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
	[[self responseData] appendData:data];
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
	[self setRequestResponse:(id)response]; // Save a reference to our response.
}

- (NSCachedURLResponse *)connection:(NSURLConnection *)connection willCacheResponse:(NSCachedURLResponse *)cachedResponse
{
	return nil; /* Do not return any cache. */
}

#pragma mark -
#pragma mark XML Parser Delegate

- (void)didRecieveXMLData:(NSData *)incomingData
{
	NSXMLParser *parser = [[NSXMLParser alloc] initWithData:incomingData];

	[self setXmlParserObject:parser];

	[self setXmlParsedTemporaryStore:[NSMutableString string]];

	[parser setDelegate:self];

	[parser parse];
}

- (void)parserDidEndDocument:(NSXMLParser *)parser
{
	[self setXmlParserIsOnTargetElement:NO];

	[self setXmlParserObject:nil];
	[self setXmlParsedTemporaryStore:nil];

	[self tearDownInternalObject];
}

- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict
{
	if ([elementName isEqualToString:@"configCode"]) {
		[self setXmlParserIsOnTargetElement:YES];
	}
}

- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string
{
	if ([self xmlParserIsOnTargetElement]) {
		[[self xmlParsedTemporaryStore] appendString:string];
	}
}

- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName
{
	if ([elementName isEqualToString:@"configCode"]) {
		[RZUserDefaults() setObject:[self xmlParsedTemporaryStore] forKey:_userDefaultsModelCacheKey];

		[RZUserDefaults() setObject:[self serialNumberValue] forKey:_userDefaultsSerialCacheKey];

		[self setXmlParserIsOnTargetElement:NO];
	}
}

@end
