// Created by Codeux Software <support AT codeux DOT com> <https://github.com/codeux/Textual>
// You can redistribute it and/or modify it under the new BSD license.

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

@property (assign) NSInteger buttonClicked;
@property (retain) NSString *finalModalValue;
@property (retain) NSWindow *dialogWindow;
@property (retain) NSButton *defaultButton;
@property (retain) NSButton *alternateButton;
@property (retain) NSTextField *dialogTitle;
@property (retain) NSTextField *userInputField;
@property (retain) NSTextField *informationalText;

- (void)runModal;

- (NSInteger)buttonClicked;
- (NSString *)promptValue;

- (void)alertWithMessageText:(NSString *)messageTitle 
			   defaultButton:(NSString *)defaultButtonTitle 
			 alternateButton:(NSString *)alternateButtonTitle 
			 informativeText:(NSString *)informativeText
			defaultUserInput:(NSString *)userInputText;

- (void)modalDidCloseWithDefaultButton:(id)sender;
- (void)modalDidCloseWithAlternateButton:(id)sender;

@end