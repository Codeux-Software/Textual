// Created by Codeux Software <support AT codeux DOT com> <https://github.com/codeux/Textual>
// You can redistribute it and/or modify it under the new BSD license.
// Converted to ARC Support on Thursday, June 09, 2012

@interface TVCInputPromptDialog : NSObject 
@property (nonatomic, assign) NSInteger buttonClicked;
@property (nonatomic, strong) NSString *finalModalValue;
@property (nonatomic, strong) NSWindow *dialogWindow;
@property (nonatomic, strong) NSButton *defaultButton;
@property (nonatomic, strong) NSButton *alternateButton;
@property (nonatomic, strong) NSTextField *dialogTitle;
@property (nonatomic, strong) NSTextField *userInputField;
@property (nonatomic, strong) NSTextField *informationalText;

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