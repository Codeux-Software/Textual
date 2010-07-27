// Created by Michael Morris <mikey AT codeux DOT com> <http://github.com/mikemac11/Textual>
// You can redistribute it and/or modify it under the new BSD license.

#import "AboutPanel.h"
#import "Preferences.h"

@implementation AboutPanel

@synthesize delegate;

- (id)init
{
	if (self = [super init]) {
		[NSBundle loadNibNamed:@"AboutPanel" owner:self];
	}
	return self;
}

- (void)dealloc
{
	[super dealloc];
}

- (void)show
{
	[versionInfo setStringValue:[NSString stringWithFormat:TXTLS(@"ABOUT_WINDOW_BUILD_NUMBER"), 
								 [[Preferences textualInfoPlist] objectForKey:@"CFBundleVersion"],
								 [[Preferences textualInfoPlist] objectForKey:@"Build Number"]]];
	
	if (![self.window isVisible]) {
		[self.window center];
	}
	
	[self.window makeKeyAndOrderFront:nil];
}

- (void)close
{
	[self.window close];
}

- (void)windowWillClose:(NSNotification*)note
{
	if ([delegate respondsToSelector:@selector(aboutPanelWillClose:)]) {
		[delegate aboutPanelWillClose:self];
	}
}

@synthesize versionInfo;
@end