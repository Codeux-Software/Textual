/* ********************************************************************* 
                  _____         _               _
                 |_   _|____  _| |_ _   _  __ _| |
                   | |/ _ \ \/ / __| | | |/ _` | |
                   | |  __/>  <| |_| |_| | (_| | |
                   |_|\___/_/\_\\__|\__,_|\__,_|_|

 Copyright (c) 2010 - 2015 Codeux Software, LLC & respective contributors.
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

NS_ASSUME_NONNULL_BEGIN

#pragma mark -
#pragma mark Private Declarations

#define _requestTimeoutInterval			30.0

NSString * const _userDefaultsModelCacheKey	= @"Private Extension Store -> System Profiler Extension -> Cached Model Identifier Value";
NSString * const _userDefaultsSerialCacheKey = @"Private Extension Store -> System Profiler Extension -> Cached Serial Number Value";

@interface TPISystemProfilerModelIDRequestController ()
@property (nonatomic, strong, nullable) id internalObject;

- (void)tearDownInternalObject;
@end

@interface TPISystemProfilerModelIDRequestControllerInternal : NSObject <NSXMLParserDelegate, NSURLConnectionDelegate>
@property (nonatomic, assign) BOOL xmlParserIsOnTargetElement; /* We are only targetting a single value so a BOOL is enough. */
@property (nonatomic, strong) NSXMLParser *xmlParserObject;
@property (nonatomic, strong) NSMutableString *modelInformation;
@property (nonatomic, strong) NSURLConnection *requestConnection;
@property (nonatomic, strong) NSHTTPURLResponse *requestResponse;
@property (nonatomic, strong) NSMutableData *requestResponseData;
@property (nonatomic, copy) NSString *serialNumber;

- (void)setupConnectionRequest;
@end

#pragma mark -
#pragma mark Public Interface

@implementation TPISystemProfilerModelIDRequestController

+ (TPISystemProfilerModelIDRequestController *)sharedController
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
	NSString *serialNumber = [self serialNumberCharacters];

	id cachedModel = [RZUserDefaults() objectForKey:_userDefaultsModelCacheKey];

	id cachedSerialNumber = [RZUserDefaults() objectForKey:_userDefaultsSerialCacheKey];

	if (cachedModel != nil && cachedSerialNumber != nil) {
		if ([cachedSerialNumber isEqual:serialNumber]) {
			return;
		} else {
			[RZUserDefaults() removeObjectForKey:_userDefaultsModelCacheKey];

			[RZUserDefaults() removeObjectForKey:_userDefaultsSerialCacheKey];
		}
	}

	/* Cached failed, check with Apple */
	self.internalObject = [TPISystemProfilerModelIDRequestControllerInternal new];

	[self.internalObject setSerialNumber:serialNumber];

	[self.internalObject setupConnectionRequest];
}

- (nullable NSString *)cachedIdentifier
{
	return [RZUserDefaults() objectForKey:_userDefaultsModelCacheKey];
}

- (void)tearDownInternalObject
{
	self.internalObject = nil;
}

- (nullable NSString *)serialNumberCharacters
{
	/* For those concerned about security, take note of the following:
	 This method reads your Mac's serial number, but only uses the last
	 few characters in it are used. Those last few characters are what 
	 is sent to Apple. The characters are the same for every Mac of the 
	 same model and does not uniquely identify you. */
	/* This is the same request that the About My Mac dialog performs. */
	/* The reason that a dictionary of these values is not maintained is
	 because this approach allows the model to be obtained without 
	 updating the dictionary every time there is a new model. */

	/* Retrieve serial number of this Mac */
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

	/* The format of serial numbers changed a few years back so we 
	 check length to know how many characters to give Apple. */
	if (serial.length == 11) {
		serial = [serial substringFromIndex:(serial.length - 3)];
	} else if (serial.length == 12) {
		serial = [serial substringFromIndex:(serial.length - 4)];
	} else {
		/* If the serial number length is unexpected, then do not
		 return it at all incase it may identify the sender. */

		serial = nil;
	}

	return serial;
}

@end

#pragma mark -

@implementation TPISystemProfilerModelIDRequestControllerInternal

#pragma mark -
#pragma mark Private Interface

- (void)tearDownInternalObject
{
	XRPerformBlockAsynchronouslyOnMainQueue(^{
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
	if ( self.requestConnection) {
		[self.requestConnection cancel];
	}

	self.requestConnection = nil;
	self.requestResponse = nil;
	self.requestResponseData = nil;
}

- (void)setupConnectionRequest
{
	self.requestResponseData = [NSMutableData data];

	NSURL *requestURL = [NSURL URLWithString:[self addressSourceURL]];

	NSMutableURLRequest *baseRequest =
	[NSMutableURLRequest requestWithURL:requestURL
							cachePolicy:NSURLRequestReloadIgnoringCacheData
						timeoutInterval:_requestTimeoutInterval];

	baseRequest.HTTPMethod = @"GET";

	NSURLConnection *reqeust = [[NSURLConnection alloc] initWithRequest:baseRequest delegate:self];

	self.requestConnection = reqeust;

	[self.requestConnection start];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
	BOOL isValidResponse = (self.requestResponse.statusCode == 200);

	if (isValidResponse) {
		[self didReceiveXMLData:self.requestResponseData];
	} else {
		[self tearDownInternalObject];
	}

	[self destroyConnectionRequest];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
	[self destroyConnectionRequest];

	[self tearDownInternalObject];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
	[self.requestResponseData appendData:data];
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
	self.requestResponse = (id)response; // Save a reference to our response.
}

- (nullable NSCachedURLResponse *)connection:(NSURLConnection *)connection willCacheResponse:(NSCachedURLResponse *)cachedResponse
{
	return nil; /* Do not return any cache */
}

#pragma mark -
#pragma mark XML Parser Delegate

- (void)didReceiveXMLData:(NSData *)incomingData
{
	self.modelInformation = [NSMutableString string];

	NSXMLParser *parser = [[NSXMLParser alloc] initWithData:incomingData];

	parser.delegate = self;

	[parser parse];

	self.xmlParserObject = parser;
}

- (void)parserDidEndDocument:(NSXMLParser *)parser
{
	self.xmlParserIsOnTargetElement = NO;

	self.xmlParserObject = nil;

	self.modelInformation = nil;

	[self tearDownInternalObject];
}

- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(nullable NSString *)namespaceURI qualifiedName:(nullable NSString *)qName attributes:(NSDictionary<NSString *, NSString *> *)attributeDict
{
	if ([elementName isEqualToString:@"configCode"] == NO) {
		return;
	}

	self.xmlParserIsOnTargetElement = YES;
}

- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string
{
	if (self.xmlParserIsOnTargetElement == NO) {
		return;
	}

	[self.modelInformation appendString:string];
}

- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(nullable NSString *)namespaceURI qualifiedName:(nullable NSString *)qName
{
	if ([elementName isEqualToString:@"configCode"] == NO) {
		return;
	}

	[RZUserDefaults() setObject:self.modelInformation forKey:_userDefaultsModelCacheKey];

	[RZUserDefaults() setObject:self.serialNumber forKey:_userDefaultsSerialCacheKey];

	self.xmlParserIsOnTargetElement = NO;
}

@end

NS_ASSUME_NONNULL_END
