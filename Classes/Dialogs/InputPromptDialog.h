// Created by Michael Morris <mikey AT codeux DOT com> <http://github.com/mikemac11/Textual>
// You can redistribute it and/or modify it under the new BSD license.

#import <Cocoa/Cocoa.h>

@interface InputPromptDialog : NSObject 
{
	NSInteger buttonClicked;
	NSString *finalModalValue;
	
	IBOutlet NSWindow *dialogWindow;
	
	IBOutlet NSButton *defaultButton;
	IBOutlet NSButton *alternateButton;
	
	IBOutlet NSTextField *dialogTitle;
	IBOutlet NSTextField *userInputField;
	IBOutlet NSTextField *informationalText;
}

@property (nonatomic, assign) NSInteger buttonClicked;
@property (nonatomic, retain) NSString *finalModalValue;
@property (nonatomic, retain) NSWindow *dialogWindow;
@property (nonatomic, retain) NSButton *defaultButton;
@property (nonatomic, retain) NSButton *alternateButton;
@property (nonatomic, retain) NSTextField *dialogTitle;
@property (nonatomic, retain) NSTextField *userInputField;
@property (nonatomic, retain) NSTextField *informationalText;

- (void)runModal;

- (NSInteger)buttonClicked;
- (NSString *)promptValue;

- (void)alertWithMessageText:(NSString *)messageTitle 
			   defaultButton:(NSString *)defaultButtonTitle 
			 alternateButton:(NSString *)alternateButtonTitle 
			 informativeText:(NSString *)informativeText
			defaultUserInput:(NSString *)userInputText;

- (IBAction)modalDidCloseWithDefaultButton:(id)sender;
- (IBAction)modalDidCloseWithAlternateButton:(id)sender;

@end