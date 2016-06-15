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

NS_ASSUME_NONNULL_BEGIN

@implementation TPCApplicationInfo

+ (NSString *)applicationName
{
	return TXBundleBuildProductName;
}

+ (NSString *)applicationVersion
{
	return TXBundleBuildVersion;
}

+ (NSString *)applicationVersionShort
{
	return TXBundleBuildVersionShort;
}

+ (int)applicationProcessID
{
	return RZProcessInfo().processIdentifier;
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

+ (NSDictionary<NSString *, id> *)applicationInfoPlist
{
	return RZMainBundle().infoDictionary;
}

+ (BOOL)sandboxEnabled
{
#if TEXTUAL_BUILT_INSIDE_SANDBOX == 1
	return YES;
#else
	return NO;
#endif
}

+ (nullable NSDate *)applicationLaunchDate
{
	NSRunningApplication *runningApp = [NSRunningApplication currentApplication];

	return runningApp.launchDate;
}

+ (NSTimeInterval)timeIntervalSinceApplicationLaunch
{
	NSDate *launchDate = [TPCApplicationInfo applicationLaunchDate];

	if (launchDate == nil) {
		return 0;
	}

	return (launchDate.timeIntervalSinceNow * (-1));
}

+ (NSTimeInterval)timeIntervalSinceApplicationInstall
{
	NSTimeInterval runTime = [TPCApplicationInfo timeIntervalSinceApplicationLaunch];

	NSTimeInterval runTimeTotal = [RZUserDefaults() doubleForKey:@"TXRunTime"];

	return (runTimeTotal + runTime);
}

+ (void)saveTimeIntervalSinceApplicationInstall
{
	NSTimeInterval timeInterval = [TPCApplicationInfo timeIntervalSinceApplicationInstall];

	[RZUserDefaults() setDouble:timeInterval forKey:@"TXRunTime"];
}

+ (NSUInteger)applicationRunCount
{
	return [RZUserDefaults() unsignedIntegerForKey:@"TXRunCount"];
}

+ (void)incrementApplicationRunCount
{
	NSUInteger runCount = ([TPCApplicationInfo applicationRunCount] + 1);

	[RZUserDefaults() setUnsignedInteger:runCount forKey:@"TXRunCount"];
}

@end

NS_ASSUME_NONNULL_END
