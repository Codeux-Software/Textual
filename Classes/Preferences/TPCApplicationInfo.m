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

#import "BuildConfig.h"

#import "TextualApplication.h"

@implementation TPCApplicationInfo

+ (NSString *)applicationName
{
	NSString *name = TXBundleBuildProductName;

	NSInteger spacePosition = [name stringPosition:NSStringWhitespacePlaceholder];
	
	if (spacePosition > 0) {
		return [name substringToIndex:spacePosition];
	} else {
		return  name;
	}
}

+ (NSString *)applicationVersion
{
	return TXBundleBuildVersion;
}

+ (NSString *)applicationVersionShort
{
	return TXBundleBuildVersionShort;
}

+ (NSInteger)applicationProcessID
{
	return [RZProcessInfo() processIdentifier];
}

+ (NSString *)applicationBundleIdentifier
{
	return TXBundleBuildProductIdentifier;
}

+ (NSString *)applicationBuildScheme
{
	return TXBundleBuildScheme;
}

+ (BOOL)runningInHighResolutionMode
{
	return [TXUserInterface runningInHighResolutionMode];
}

+ (NSDictionary *)applicationInfoPlist
{
	return [RZMainBundle() infoDictionary];
}

+ (BOOL)sandboxEnabled
{
	NSString *suffix = [NSString stringWithFormat:@"Containers/%@/Data", [TPCApplicationInfo applicationBundleIdentifier]];
	
	return [NSHomeDirectory() hasSuffix:suffix];
}

+ (NSDate *)applicationLaunchDate
{
	NSRunningApplication *runningApp = [NSRunningApplication currentApplication];
	
	/* This can be nil when launched from something not launchd. i.e. Xcode */
	return [runningApp launchDate];
}

+ (NSTimeInterval)timeIntervalSinceApplicationLaunch
{
	NSDate *launchDate = [TPCApplicationInfo applicationLaunchDate];
	
	PointerIsEmptyAssertReturn(launchDate, 0);
	
	return [NSDate secondsSinceUnixTimestamp:[launchDate timeIntervalSince1970]];
}

+ (NSTimeInterval)timeIntervalSinceApplicationInstall
{
	NSTimeInterval appStartTime = [TPCApplicationInfo timeIntervalSinceApplicationLaunch];
	
	return ([RZUserDefaults() integerForKey:@"TXRunTime"] + appStartTime);
}

+ (void)saveTimeIntervalSinceApplicationInstall
{
	[RZUserDefaults() setInteger:[TPCApplicationInfo timeIntervalSinceApplicationInstall] forKey:@"TXRunTime"];
}

+ (NSInteger)applicationRunCount
{
	return [RZUserDefaults() integerForKey:@"TXRunCount"];
}

+ (void)updateApplicationRunCount
{
	[RZUserDefaults() setInteger:([TPCApplicationInfo applicationRunCount] + 1) forKey:@"TXRunCount"];
}

@end
