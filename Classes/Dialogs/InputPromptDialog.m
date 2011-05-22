// Created by Codeux Software <support AT codeux DOT com> <https://github.com/codeux/Textual>
// You can redistribute it and/or modify it under the new BSD license.

// Dirty NSAlert substitution 

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
	[finalModalValue drain];
	
    [super dealloc];
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
	[NSBundle loadNibNamed:@"InputPromptDialog" owner:self];
	
	if (NSObjectIsNotEmpty(userInputText)) {
		[userInputField setStringValue:userInputText];
	}
	
	[dialogTitle setStringValue:messageTitle];
	[defaultButton setTitle:defaultButtonTitle];
	[alternateButton setTitle:alternateButtonTitle];
	[informationalText setStringValue:informativeText];
}

- (void)runModal
{
	NSRect infoTextFrame = [informationalText frame];
	
	NSLayoutManager *layoutManager	= [NSLayoutManager new];
	NSTextStorage	*textStorage	= [[NSTextStorage alloc] initWithString:[informationalText stringValue]];
	NSTextContainer *textContainer	= [[NSTextContainer alloc] initWithContainerSize:NSMakeSize(298.0, FLT_MAX)];
	
	[layoutManager addTextContainer:textContainer];
	
	[textStorage addLayoutManager:layoutManager];
	[textStorage addAttribute:NSFontAttributeName 
						value:[NSFont fontWithName:@"Lucida Grande" size:11.0] 
						range:NSMakeRange(0, [textStorage length])];
	
	[textContainer setLineFragmentPadding:0.0];
	
	[layoutManager glyphRangeForTextContainer:textContainer];
	
	NSInteger newHeight		= ([layoutManager usedRectForTextContainer:textContainer].size.height + 5);
	NSInteger heightDiff	= (infoTextFrame.size.height - newHeight);
	
	NSRect windowFrame = [dialogWindow frame];
	
	infoTextFrame.size.height	= (newHeight + 3);
	windowFrame.size.height		= ((windowFrame.size.height - heightDiff) + 3);
	
	[dialogWindow setFrame:windowFrame display:NO animate:NO];
	[dialogWindow makeKeyAndOrderFront:nil];
	
	[informationalText setFrame:infoTextFrame];
	
	while ([dialogWindow isVisible]) {
		continue;
	}
	
	[textStorage drain];
	[textContainer drain];
	[layoutManager drain];
}

- (void)modalDidCloseWithDefaultButton:(id)sender
{
	buttonClicked = NSAlertDefaultReturn;
	
	finalModalValue = [[userInputField stringValue] retain];
	
	[dialogWindow close];
}

- (void)modalDidCloseWithAlternateButton:(id)sender
{
	buttonClicked = NSAlertAlternateReturn;
	
	finalModalValue = [[userInputField stringValue] retain];
	
	[dialogWindow close];
}

@end