// Created by Satoshi Nakagawa <psychs AT limechat DOT net> <http://github.com/psychs/limechat>
// You can redistribute it and/or modify it under the new BSD license.

@implementation URLOpener

+ (void)open:(NSURL *)url
{
	if ([Preferences openBrowserInBackground]) {
		[_NSWorkspace() openURLs:[NSArray arrayWithObject:url] withAppBundleIdentifier:nil options:NSWorkspaceLaunchWithoutActivation additionalEventParamDescriptor:nil launchIdentifiers:nil];
	} else {
		[_NSWorkspace() openURL:url];
	}
}

+ (void)openAndActivate:(NSURL *)url
{
	[_NSWorkspace() openURL:url];
}

@end