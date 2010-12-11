// Created by Codeux Software <support AT codeux DOT com> <https://github.com/codeux/Textual>
// You can redistribute it and/or modify it under the new BSD license.

// Dirty NSAlert substitution 

#import "InputPromptDialog.h"
#import "NSObject+DDExtensions.h"

@implementation InputPromptDialog

@synthesize finalModalValue;
@synthesize buttonClicked;
@synthesize dialogWindow;
@synthesize defaultButton;
@synthesize alternateButton;
@synthesize dialogTitle;
@synthesize userInputField;
@synthesize informationalText;

- (void)dealloc
{
	[finalModalValue release];
    [super dealloc];
}

- (NSInteger)buttonClicked
{
	return buttonClicked;
}

- (NSString *)promptValue
{
	return [finalModalValue trim];
}

- (void)alertWithMessageText:(NSString *)messageTitle 
			   defaultButton:(NSString *)defaultButtonTitle 
			 alternateButton:(NSString *)alternateButtonTitle 
			 informativeText:(NSString *)informativeText
			defaultUserInput:(NSString *)userInputText
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	[NSBundle loadNibNamed:@"InputPromptDialog" owner:self];
	
	if (userInputText != nil) {
		[userInputField setStringValue:userInputText];
	}
	
	[informationalText setStringValue:informativeText];
	[defaultButton setTitle:((defaultButtonTitle == nil) ? TXTLS(@"OK_BUTTON") : defaultButtonTitle)];
	[dialogTitle setStringValue:((messageTitle == nil) ? TXTLS(@"INPUT_REQUIRED_TO_CONTINUE") : messageTitle)];
	[alternateButton setTitle:((alternateButtonTitle  == nil) ? TXTLS(@"CANCEL_BUTTON") : alternateButtonTitle)];
	
	[pool release];
}

- (void)runModal
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	// The below text size calculation method is based off the examples at:
	// <http://developer.apple.com/mac/library/documentation/Cocoa/Conceptual/TextLayout/Tasks/StringHeight.html>
	
	NSRect infoTextFrame = [informationalText frame];
	
	NSTextStorage *textStorage = [[[NSTextStorage alloc] initWithString:[informationalText stringValue]] autorelease];
	NSTextContainer *textContainer = [[[NSTextContainer alloc] initWithContainerSize: NSMakeSize(298.0, FLT_MAX)] autorelease];
	NSLayoutManager *layoutManager = [[[NSLayoutManager alloc] init] autorelease];
	
	[layoutManager addTextContainer:textContainer];
	[textStorage addLayoutManager:layoutManager];
	
	[textStorage addAttribute:NSFontAttributeName value:[NSFont fontWithName:@"Lucida Grande" size:11.0] range:NSMakeRange(0, [textStorage length])];
	[textContainer setLineFragmentPadding:0.0];
	
	[layoutManager glyphRangeForTextContainer:textContainer];
	
	NSInteger newHeight = ([layoutManager usedRectForTextContainer:textContainer].size.height + 5);
	NSInteger heightDiff = (infoTextFrame.size.height - newHeight);
	
	NSRect windowFrame = [dialogWindow frame];
	windowFrame.size.height = ((windowFrame.size.height - heightDiff) + 3);
	[dialogWindow setFrame:windowFrame display:NO animate:NO];
	
	infoTextFrame.size.height = (newHeight + 3);
	[informationalText setFrame:infoTextFrame];
	
	[dialogWindow makeKeyAndOrderFront:nil];
	
	while ([dialogWindow isVisible]) {
		continue; // Do nothing - Just hang method until we have value to work with
	}
	
	[pool release];
}

- (IBAction)modalDidCloseWithDefaultButton:(id)sender
{
	buttonClicked = NSAlertDefaultReturn;
	finalModalValue = [[userInputField stringValue] retain];
	[dialogWindow close];
}

- (IBAction)modalDidCloseWithAlternateButton:(id)sender
{
	buttonClicked = NSAlertAlternateReturn;
	finalModalValue = [[userInputField stringValue] retain];
	[dialogWindow close];
}

@end