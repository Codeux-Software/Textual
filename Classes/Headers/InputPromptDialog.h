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
@property (strong) NSString *finalModalValue;
@property (strong) NSWindow *dialogWindow;
@property (strong) NSButton *defaultButton;
@property (strong) NSButton *alternateButton;
@property (strong) NSTextField *dialogTitle;
@property (strong) NSTextField *userInputField;
@property (strong) NSTextField *informationalText;

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