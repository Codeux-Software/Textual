// Created by Satoshi Nakagawa <psychs AT limechat DOT net> <http://github.com/psychs/limechat>
// You can redistribute it and/or modify it under the new BSD license.

@interface SheetBase : NSObject
{
	id __unsafe_unretained delegate;
	
	NSWindow *__unsafe_unretained window;

	IBOutlet NSWindow *sheet;
	IBOutlet NSButton *okButton;
	IBOutlet NSButton *cancelButton;
}

@property (unsafe_unretained) id delegate;
@property (unsafe_unretained) NSWindow *window;
@property (strong) NSWindow *sheet;
@property (strong) NSButton *okButton;
@property (strong) NSButton *cancelButton;

- (void)startSheet;
- (void)startSheetWithWindow:(NSWindow *)awindow;

- (void)endSheet;

- (void)ok:(id)sender;
- (void)cancel:(id)sender;
@end