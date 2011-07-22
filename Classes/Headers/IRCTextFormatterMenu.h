// Modifications by Codeux Software <support AT codeux DOT com> <https://github.com/codeux/Textual>
// You can redistribute it and/or modify it under the new BSD license.

#define IRCTextFormatterMenuTag		53037

@interface IRCTextFormatterMenu : NSObject {
	IBOutlet NSMenuItem *formatterMenu;
	
	IBOutlet NSMenu	*foregroundColorMenu;
	IBOutlet NSMenu *backgroundColorMenu;
	
	BOOL sheetOverrideEnabled;
	
	TextField *textField;
}

@property (nonatomic, assign) TextField *textField;
@property (nonatomic, retain) NSMenuItem *formatterMenu;
@property (nonatomic, retain) NSMenu *foregroundColorMenu;
@property (nonatomic, retain) NSMenu *backgroundColorMenu;
@property (nonatomic, assign) BOOL sheetOverrideEnabled;

- (void)enableSheetField:(TextField *)field;
- (void)enableWindowField:(TextField *)field;

- (BOOL)boldSet;
- (BOOL)italicSet;
- (BOOL)underlineSet;
- (BOOL)foregroundColorSet;
- (BOOL)backgroundColorSet;

- (void)insertBoldCharIntoTextBox:(id)sender;
- (void)insertItalicCharIntoTextBox:(id)sender;
- (void)insertUnderlineCharIntoTextBox:(id)sender;
- (void)insertForegroundColorCharIntoTextBox:(id)sender;
- (void)insertBackgroundColorCharIntoTextBox:(id)sender;

- (void)removeBoldCharFromTextBox:(id)sender;
- (void)removeItalicCharFromTextBox:(id)sender;
- (void)removeUnderlineCharFromTextBox:(id)sender;
- (void)removeForegroundColorCharFromTextBox:(id)sender;
- (void)removeBackgroundColorCharFromTextBox:(id)sender;
@end