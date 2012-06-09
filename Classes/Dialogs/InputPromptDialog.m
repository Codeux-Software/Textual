// Created by Codeux Software <support AT codeux DOT com> <https://github.com/codeux/Textual>
// You can redistribute it and/or modify it under the new BSD license.
// Converted to ARC Support on Thursday, June 09, 2012

// Dirty NSAlert substitution 

#define TEXT_CONTAINER_WIDTH			298.0
#define TEXT_CONTAINER_PADDING			3
#define TEXT_CONTAINER_HEIGHT_FIX		5

@implementation InputPromptDialog

@synthesize finalModalValue;
@synthesize buttonClicked;
@synthesize dialogWindow;
@synthesize defaultButton;
@synthesize alternateButton;
@synthesize dialogTitle;
@synthesize userInputField;
@synthesize informationalText;

- (NSString *)promptValue
{
	return [self.finalModalValue trim];
}

- (void)alertWithMessageText:(NSString *)messageTitle 
			   defaultButton:(NSString *)defaultButtonTitle 
			 alternateButton:(NSString *)alternateButtonTitle 
			 informativeText:(NSString *)informativeText
			defaultUserInput:(NSString *)userInputText
{
	[NSBundle loadNibNamed:@"InputPromptDialog" owner:self];
	
	if (NSObjectIsNotEmpty(userInputText)) {
		[self.userInputField setStringValue:userInputText];
	}
	
	[self.dialogTitle setStringValue:messageTitle];
	[self.defaultButton setTitle:defaultButtonTitle];
	[self.alternateButton setTitle:alternateButtonTitle];
	[self.informationalText setStringValue:informativeText];
}

- (void)runModal
{
	NSRect infoTextFrame = [self.informationalText frame];
	
	NSLayoutManager *layoutManager	= [NSLayoutManager new];
	NSTextStorage	*textStorage	= [[NSTextStorage alloc] initWithString:[self.informationalText stringValue]];
	NSTextContainer *textContainer	= [[NSTextContainer alloc] initWithContainerSize:NSMakeSize(TEXT_CONTAINER_WIDTH, FLT_MAX)];
	
	[layoutManager addTextContainer:textContainer];
	
	[textStorage addLayoutManager:layoutManager];
	[textStorage addAttribute:NSFontAttributeName 
						value:[NSFont fontWithName:@"Lucida Grande" size:11.0] 
						range:NSMakeRange(0, [textStorage length])];
	
	[textContainer setLineFragmentPadding:0.0];
	
	[layoutManager glyphRangeForTextContainer:textContainer];
	
	NSInteger newHeight		= ([layoutManager usedRectForTextContainer:textContainer].size.height + TEXT_CONTAINER_HEIGHT_FIX);
	NSInteger heightDiff	= (infoTextFrame.size.height - newHeight);
	
	NSRect windowFrame = [self.dialogWindow frame];
	
	infoTextFrame.size.height	= (newHeight + TEXT_CONTAINER_PADDING);
	windowFrame.size.height		= ((windowFrame.size.height - heightDiff) + TEXT_CONTAINER_PADDING);
	
	[self.dialogWindow setFrame:windowFrame display:NO animate:NO];
	[self.dialogWindow makeKeyAndOrderFront:nil];
	
	[self.informationalText setFrame:infoTextFrame];
	
	while ([self.dialogWindow isVisible]) {
		continue;
	}
}

- (void)modalDidCloseWithDefaultButton:(id)sender
{
	self.buttonClicked = NSAlertDefaultReturn;
	
	self.finalModalValue = [self.userInputField stringValue];
	
	[self.dialogWindow close];
}

- (void)modalDidCloseWithAlternateButton:(id)sender
{
	self.buttonClicked = NSAlertAlternateReturn;
	
	self.finalModalValue = [self.userInputField stringValue];
	
	[self.dialogWindow close];
}

@end