/* *********************************************************************
 *                  _____         _               _
 *                 |_   _|____  _| |_ _   _  __ _| |
 *                   | |/ _ \ \/ / __| | | |/ _` | |
 *                   | |  __/>  <| |_| |_| | (_| | |
 *                   |_|\___/_/\_\\__|\__,_|\__,_|_|
 *
 * Copyright (c) 2012 - 2018 Codeux Software, LLC & respective contributors.
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

#import "TPISystemProfilerModelRequest.h"

NS_ASSUME_NONNULL_BEGIN

#pragma mark -
#pragma mark Private Declarations

NSString * const _userDefaultsModelCacheKey	= @"Private Extension Store -> System Profiler Extension -> Cached Model Identifier Value";
NSString * const _userDefaultsSerialCacheKey = @"Private Extension Store -> System Profiler Extension -> Cached Serial Number Value";

@interface TPISystemProfilerModelRequest ()
@property (nonatomic, strong, nullable) NSURLSessionTask *sessionTask;
@end

#pragma mark -
#pragma mark Public Interface

@implementation TPISystemProfilerModelRequest

+ (TPISystemProfilerModelRequest *)sharedController
{
	static id sharedSelf = nil;

	static dispatch_once_t onceToken;

	dispatch_once(&onceToken, ^{
		 sharedSelf = [TPISystemProfilerModelRequest new];
	});

	return sharedSelf;
}

+ (nullable NSString *)serialNumberCharacters
{
	/* For those concerned about security, take note of the following:
	 This method reads your Mac's serial number, but only uses the last
	 few characters in it. Those last few characters are what is sent
	 to Apple. The characters are the same for every Mac of the same
	 model and does not uniquely identify you. */
	/* This is the same request that the About My Mac dialog performs. */
	/* The reason that a dictionary of these values is not maintained
	 is because this approach allows the model to be obtained without
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

- (void)requestIdentifier
{
	if (self.sessionTask != nil) {
		LogToConsoleError("A request is already active.");

		return;
	}

	NSString *serialNumber = [self.class serialNumberCharacters];

	if (serialNumber == nil) {
		LogToConsoleError("Unexpected nil serial number.");

		return;
	}

	id cachedSerialNumber 	= [RZUserDefaults() objectForKey:_userDefaultsSerialCacheKey];

	id cachedModel 			= [RZUserDefaults() objectForKey:_userDefaultsModelCacheKey];

	if (cachedSerialNumber != nil && cachedModel != nil) {
		if ([cachedSerialNumber isEqual:serialNumber]) {
			LogToConsoleDebug("Cache hit.");

			return;
		}

		LogToConsoleDebug("Cache poisoned.");

		[RZUserDefaults() removeObjectForKey:_userDefaultsSerialCacheKey];

		[RZUserDefaults() removeObjectForKey:_userDefaultsModelCacheKey];
	}

	/* Cached failed, check with Apple */
	LogToConsoleDebug("Performing request.");

	[self performRequestForSerialNumber:serialNumber];
}

- (nullable NSString *)cachedIdentifier
{
	return [RZUserDefaults() objectForKey:_userDefaultsModelCacheKey];
}

- (void)performRequestForSerialNumber:(NSString *)serialNumber
{
	NSParameterAssert(serialNumber != nil);

	NSString *requestAddress = [NSString stringWithFormat:@"http://support-sp.apple.com/sp/product?cc=%@&lang=en_US", serialNumber];

	NSURL *requestURL = [NSURL URLWithString:requestAddress];

	__weak TPISystemProfilerModelRequest *weakSelf = self;

	NSURLSession *session = [NSURLSession sharedSession];

	NSURLSessionTask *task = [session dataTaskWithURL:requestURL completionHandler:^(NSData *data, NSURLResponse *response, NSError *error)
	{
		if (data == nil || ((NSHTTPURLResponse *)response).statusCode != 200) {
			if (error) {
				LogToConsoleError("Request failed with error: %@",
					error.localizedDescription);
			}

			return;
		}

		[weakSelf processResponse:data forSerialNumber:serialNumber];

		weakSelf.sessionTask = nil;
	}];

	[task resume];

	self.sessionTask = task;
}

- (void)processResponse:(NSData *)data forSerialNumber:(NSString *)serialNumber
{
	if (data.length > 512) {
		LogToConsoleError("Length of data exceeds maximum.");

		return;
	}

	NSString *string = [NSString stringWithData:data encoding:NSASCIIStringEncoding];

	if (string == nil) {
		LogToConsoleError("Failed to convert data into string.");

		return;
	}

	/* The first version of this class used an XML parser to obtain the
	 value of a single element. I no longer wanted to maintain that.
	 The response is simple enough that we can use a regular expression. */
	/* This will produce two matches:
		1) "<configCode>iMac Pro (2017)</configCode>",
		2) "iMac Pro (2017)"
	 */
	NSArray *matches = [XRRegularExpression matchesInString:string
												  withRegex:@"<configCode>([^\n]+)<\\/configCode>"
												withoutCase:NO 			/* Case sensitive */
											substringGroups:YES];		/* Substring group */

	if (matches.count != 2) {
		LogToConsoleError("Wrong number of matches.");

		return;
	}

	[self saveModelInformation:matches[1] forSerialNumber:serialNumber];
}

- (void)saveModelInformation:(NSString *)modelInformation forSerialNumber:(NSString *)serialNumber
{
	NSParameterAssert(modelInformation != nil);
	NSParameterAssert(serialNumber != nil);

	LogToConsoleInfo("Saving model '%@'", modelInformation);

	[RZUserDefaults() setObject:modelInformation forKey:_userDefaultsModelCacheKey];

	[RZUserDefaults() setObject:serialNumber forKey:_userDefaultsSerialCacheKey];
}

@end

NS_ASSUME_NONNULL_END
