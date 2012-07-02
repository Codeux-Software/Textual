// Created by Satoshi Nakagawa <psychs AT limechat DOT net> <http://github.com/psychs/limechat>
// You can redistribute it and/or modify it under the new BSD license.

#import "TextualApplication.h"

@implementation TLOpenLink

+ (void)open:(NSURL *)url
{
	if ([TPCPreferences openBrowserInBackground]) {
		[_NSWorkspace() openURLs:@[url]
		 withAppBundleIdentifier:nil
					  options:NSWorkspaceLaunchWithoutActivation
    additionalEventParamDescriptor:nil
			  launchIdentifiers:nil];
	} else {
		[_NSWorkspace() openURL:url];
	}
}

+ (void)openAndActivate:(NSURL *)url
{
	[_NSWorkspace() openURL:url];
}

+ (void)openWithString:(NSString *)url
{
	[self open:[NSURL URLWithString:url]];
}

@end