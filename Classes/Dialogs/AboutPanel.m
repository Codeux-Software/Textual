// Created by Codeux Software <support AT codeux DOT com> <https://github.com/codeux/Textual>
// You can redistribute it and/or modify it under the new BSD license.
// Converted to ARC Support on Thursday, June 09, 2012

@implementation AboutPanel

@synthesize delegate;
@synthesize versionInfo;

- (id)init
{
	if ((self = [super init])) {
		[NSBundle loadNibNamed:@"AboutPanel" owner:self];
	}

	return self;
}

- (void)show
{	
	[self.versionInfo setStringValue:[NSString stringWithFormat:TXTLS(@"ABOUT_WINDOW_BUILD_NUMBER"), 
								 [[Preferences textualInfoPlist] objectForKey:@"CFBundleVersion"]]];	
	
	[self.window center];
	[self.window makeKeyAndOrderFront:nil];
}

- (void)windowWillClose:(NSNotification *)note
{
	if ([self.delegate respondsToSelector:@selector(aboutPanelWillClose:)]) {
		[self.delegate aboutPanelWillClose:self];
	}
}

@end