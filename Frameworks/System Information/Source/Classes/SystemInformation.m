/* ********************************************************************* 
				  _____         _               _
				 |_   _|____  _| |_ _   _  __ _| |
				   | |/ _ \ \/ / __| | | |/ _` | |
				   | |  __/>  <| |_| |_| | (_| | |
				   |_|\___/_/\_\\__|\__,_|\__,_|_|

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
    * Neither the name of Textual and/or Codeux Software, nor the names of 
      its contributors may be used to endorse or promote products derived 
      from this software without specific prior written permission.

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

#define NSAppKitVersionNumber10_6		1038
#define NSAppKitVersionNumber10_7		1138
#define NSAppKitVersionNumber10_7_2		1138.23
#define NSAppKitVersionNumber10_7_3		1138.32
#define NSAppKitVersionNumber10_7_4		1138.47
#define NSAppKitVersionNumber10_8		1187
#define NSAppKitVersionNumber10_9		1265

@implementation CSFWSystemInformation

#pragma mark -
#pragma mark Public.

+ (NSString *)systemBuildVersion
{
	id cachedValue = nil;
	
	if (cachedValue == nil) {
		cachedValue = [self retrieveSystemInformationKey:@"ProductBuildVersion"];
	}
	
	return cachedValue;
}

+ (NSString *)systemStandardVersion
{
	id cachedValue = nil;
	
	if (cachedValue == nil) {
		cachedValue = [self retrieveSystemInformationKey:@"ProductVersion"];
	}
	
	return cachedValue;
}

+ (NSString *)systemOperatingSystemName
{
	id cachedValue = nil;
	
	if (cachedValue == nil) {
		cachedValue = [self retrieveSystemInformationKey:@"ProductName"];
	}
	
	return cachedValue;
}

+ (BOOL)featureAvailableToOSXLion
{
	BOOL _valueCached = NO;
	
	BOOL cachedValue = NO;
	
	if (_valueCached == NO) {
		_valueCached = YES;

		if ([[NSProcessInfo processInfo] respondsToSelector:@selector(isOperatingSystemAtLeastVersion:)]) {
			NSOperatingSystemVersion compareVersion;

			compareVersion.majorVersion = 10;
			compareVersion.minorVersion = 7;
			compareVersion.patchVersion = 0;

			cachedValue = [[NSProcessInfo processInfo] isOperatingSystemAtLeastVersion:compareVersion];
		} else {
			cachedValue = (floor(NSAppKitVersionNumber) > NSAppKitVersionNumber10_6);
		}
	}
	
	return cachedValue;
}

+ (BOOL)featureAvailableToOSXMountainLion
{
	BOOL _valueCached = NO;
	
	BOOL cachedValue = NO;
	
	if (_valueCached == NO) {
		_valueCached = YES;

		if ([[NSProcessInfo processInfo] respondsToSelector:@selector(isOperatingSystemAtLeastVersion:)]) {
			NSOperatingSystemVersion compareVersion;

			compareVersion.majorVersion = 10;
			compareVersion.minorVersion = 8;
			compareVersion.patchVersion = 0;

			cachedValue = [[NSProcessInfo processInfo] isOperatingSystemAtLeastVersion:compareVersion];
		} else {
			cachedValue = (floor(NSAppKitVersionNumber) > NSAppKitVersionNumber10_7);
		}
	}
	
	return cachedValue;
}

+ (BOOL)featureAvailableToOSXMavericks
{
	BOOL _valueCached = NO;
	
	BOOL cachedValue = NO;
	
	if (_valueCached == NO) {
		_valueCached = YES;

		if ([[NSProcessInfo processInfo] respondsToSelector:@selector(isOperatingSystemAtLeastVersion:)]) {
			NSOperatingSystemVersion compareVersion;

			compareVersion.majorVersion = 10;
			compareVersion.minorVersion = 9;
			compareVersion.patchVersion = 0;

			cachedValue = [[NSProcessInfo processInfo] isOperatingSystemAtLeastVersion:compareVersion];
		} else {
			cachedValue = (floor(NSAppKitVersionNumber) > NSAppKitVersionNumber10_8);
		}
	}
	
	return cachedValue;
}

+ (BOOL)featureAvailableToOSXYosemite
{
	BOOL _valueCached = NO;
	
	BOOL cachedValue = NO;
	
	if (_valueCached == NO) {
		_valueCached = YES;

		if ([[NSProcessInfo processInfo] respondsToSelector:@selector(isOperatingSystemAtLeastVersion:)]) {
			NSOperatingSystemVersion compareVersion;

			compareVersion.majorVersion = 10;
			compareVersion.minorVersion = 10;
			compareVersion.patchVersion = 0;

			cachedValue = [[NSProcessInfo processInfo] isOperatingSystemAtLeastVersion:compareVersion];
		} else {
			cachedValue = (floor(NSAppKitVersionNumber) > NSAppKitVersionNumber10_9);
		}
	}
	
	return cachedValue;
}

#pragma mark -
#pragma mark Private.

+ (NSString *)systemModelToken
{
	id cachedValue = nil;
	
	if (cachedValue == nil) {
		char modelBuffer[256];
		
		size_t sz = sizeof(modelBuffer);
		
		if (sysctlbyname("hw.model", modelBuffer, &sz, NULL, 0) == 0) {
			modelBuffer[(sizeof(modelBuffer) - 1)] = 0;
			
			cachedValue = @(modelBuffer);
		}
	}
	
	return cachedValue;
}

+ (NSString *)systemModelName
{
	id cachedValue = nil;
	
	if (cachedValue == nil) {
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
			@"imac"			: @"iMac",
			@"xserve"		: @"Xserve"
		};
		
		NSString *modelToken = [self systemModelToken];
		
		if ([modelToken length] <= 0) {
			return nil;
		}
		
		modelToken = [modelToken lowercaseString];
		
		for (NSString *modelPrefix in modelPrefixes) {
			if ([modelToken hasPrefix:modelPrefix]) {
				cachedValue = modelPrefixes[modelPrefix];
			}
		}
		
		cachedValue = nil;
	}
	
	return cachedValue;
}

+ (NSString *)retrieveSystemInformationKey:(NSString *)key
{
	NSDictionary *sysinfo = [self systemInformationDictionary];

	NSString *infos = sysinfo[key];

	if ([infos length] <= 0) {
		return nil;
	}

	return infos;
}

+ (NSDictionary *)createDictionaryFromFileAtPath:(NSString *)path
{
	NSFileManager *fileManger = [NSFileManager defaultManager];

	if ([fileManger fileExistsAtPath:path]) {
		return [NSDictionary dictionaryWithContentsOfFile:path];
	} else {
		return nil;
	}
}

+ (NSDictionary *)systemInformationDictionary
{
	NSDictionary *systemInfo = [CSFWSystemInformation createDictionaryFromFileAtPath:@"/System/Library/CoreServices/SystemVersion.plist"];

	if (systemInfo == nil) {
		systemInfo = [CSFWSystemInformation createDictionaryFromFileAtPath:@"/System/Library/CoreServices/ServerVersion.plist"];
	}

	return systemInfo;
}

@end
