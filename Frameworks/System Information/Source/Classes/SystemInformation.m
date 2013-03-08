/* ********************************************************************* 
       _____        _               _    ___ ____   ____
      |_   _|___  _| |_ _   _  __ _| |  |_ _|  _ \ / ___|
       | |/ _ \ \/ / __| | | |/ _` | |   | || |_) | |
       | |  __/>  <| |_| |_| | (_| | |   | ||  _ <| |___
       |_|\___/_/\_\\__|\__,_|\__,_|_|  |___|_| \_\\____|

 Copyright (c) 2010 — 2013 Codeux Software & respective contributors.
        Please see Contributors.pdf and Acknowledgements.pdf

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

#import "SystemInformation.h"

#include <sys/sysctl.h>

@implementation CSFWSystemInformation

#pragma mark -
#pragma mark Public.

+ (NSString *)systemBuildVersion
{
	return [self retrieveSystemInformationKey:@"ProductBuildVersion"];
}

+ (NSString *)systemStandardVersion
{
	return [self retrieveSystemInformationKey:@"ProductVersion"];
}

+ (NSString *)systemOperatingSystemName
{
	return [self retrieveSystemInformationKey:@"ProductName"];
}

#pragma mark -
#pragma mark Private.

+ (NSString *)systemModelToken
{
	char modelBuffer[256];

	size_t sz = sizeof(modelBuffer);

	if (sysctlbyname("hw.model", modelBuffer, &sz, NULL, 0) == 0) {
		modelBuffer[(sizeof(modelBuffer) - 1)] = 0;

		return @(modelBuffer);
	}

	return nil;
}

+ (NSString *)systemModelName
{
	/* This method is not returning very detailed information. Only
	 the model being ran on. Therefore, not much love will be put into
	 it. As can be seen below, we are defining our models inline instead
	 of using a dictionary that will have to be loaded from a file. */
	
	NSDictionary *modelPrefixes = @{
		 @"macbookpro"	: @"MacBook Pro",
		 @"macbookair"	: @"MacBook Air",
		 @"macbook"		: @"MacBook",
		 @"macpro"		: @"Mac Pro",
		 @"macmini"		: @"Mac Mini",
		 @"imac"		: @"iMac",
		 @"xserve"		: @"Xserve"
	};

	NSString *modelToken = [self systemModelToken];

	if (modelToken.length <= 0) {
		return nil;
	}

	modelToken = modelToken.lowercaseString;

	for (NSString *modelPrefix in modelPrefixes) {
		if ([modelToken hasPrefix:modelPrefix]) {
			return modelPrefixes[modelPrefix];
		}
	}

	return nil;
}

+ (NSString *)retrieveSystemInformationKey:(NSString *)key
{
	NSDictionary *sysinfo = [self systemInformationDictionary];

	NSString *infos = [sysinfo objectForKey:key];

	if (infos.length <= 0) {
		return nil;
	}

	return infos;
}

+ (NSDictionary *)systemInformationDictionary
{
	NSString *normalPath = @"/System/Library/CoreServices/SystemVersion.plist";
	NSString *serverPath = @"/System/Library/CoreServices/ServerVersion.plist";

	NSFileManager *fileManger = [NSFileManager defaultManager];

	BOOL normalPathExists = [fileManger fileExistsAtPath:normalPath];
	BOOL serverPathExists = [fileManger fileExistsAtPath:serverPath];
	
	if (normalPathExists == NO && serverPathExists == NO) {
		return nil;
	}

	NSDictionary *systemVersionPlist;

	if (normalPathExists) {
		systemVersionPlist = [NSDictionary dictionaryWithContentsOfFile:normalPath];
	} else {
		systemVersionPlist = [NSDictionary dictionaryWithContentsOfFile:serverPath];
	}

	if (systemVersionPlist.count <= 0) {
		return nil;
	}

	return systemVersionPlist;
}

@end
