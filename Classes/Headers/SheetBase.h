// Created by Satoshi Nakagawa <psychs AT limechat DOT net> <http://github.com/psychs/limechat>
// You can redistribute it and/or modify it under the new BSD license.

@interface SheetBase : NSObject
{
	id delegate;
	
	NSWindow *window;

	IBOutlet NSWindow *sheet;
	IBOutlet NSButton *okButton;
	IBOutlet NSButton *cancelButton;
}

@property (nonatomic, assign) id delegate;
@property (nonatomic, assign) NSWindow *window;
@property (nonatomic, retain) NSWindow *sheet;
@property (nonatomic, retain) NSButton *okButton;
@property (nonatomic, retain) NSButton *cancelButton;

- (void)startSheet;
- (void)startSheetWithWindow:(NSWindow *)awindow;

- (void)endSheet;

- (void)ok:(id)sender;
- (void)cancel:(id)sender;
@end