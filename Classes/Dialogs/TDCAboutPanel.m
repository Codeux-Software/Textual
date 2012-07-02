// Created by Codeux Software <support AT codeux DOT com> <https://github.com/codeux/Textual>
// You can redistribute it and/or modify it under the new BSD license.

#import "TextualApplication.h"

@implementation TDCAboutPanel

- (id)init
{
	if ((self = [super init])) {
		[NSBundle loadNibNamed:@"TDCAboutPanel" owner:self];
	}

	return self;
}

- (void)show
{	
	[self.versionInfo setStringValue:[NSString stringWithFormat:TXTLS(@"AboutWindowBuildNumber"), 
								 [TPCPreferences textualInfoPlist][@"CFBundleVersion"]]];	
	
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