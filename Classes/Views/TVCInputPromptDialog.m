// Created by Codeux Software <support AT codeux DOT com> <https://github.com/codeux/Textual>
// You can redistribute it and/or modify it under the new BSD license.
// Converted to ARC Support on June 09, 2012

#import "TextualApplication.h"

// Dirty NSAlert substitution 

#define _textContainerWidth				298.0
#define _textContainerPadding			3
#define _textContainerHeightFix			5

@implementation TVCInputPromptDialog

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
	[NSBundle loadNibNamed:@"TVCInputPromptDialog" owner:self];
	
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
	NSTextContainer *textContainer	= [[NSTextContainer alloc] initWithContainerSize:NSMakeSize(_textContainerWidth, FLT_MAX)];
	
	[layoutManager addTextContainer:textContainer];
	
	[textStorage addLayoutManager:layoutManager];
	[textStorage addAttribute:NSFontAttributeName 
						value:[NSFont fontWithName:@"Lucida Grande" size:11.0] 
						range:NSMakeRange(0, [textStorage length])];
	
	[textContainer setLineFragmentPadding:0.0];
	
	[layoutManager glyphRangeForTextContainer:textContainer];
	
	NSInteger newHeight		= ([layoutManager usedRectForTextContainer:textContainer].size.height + _textContainerHeightFix);
	NSInteger heightDiff	= (infoTextFrame.size.height - newHeight);
	
	NSRect windowFrame = [self.dialogWindow frame];
	
	infoTextFrame.size.height	= (newHeight + _textContainerPadding);
	windowFrame.size.height		= ((windowFrame.size.height - heightDiff) + _textContainerPadding);
	
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