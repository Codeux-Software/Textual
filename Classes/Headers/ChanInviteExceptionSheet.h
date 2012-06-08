// Created by Codeux Software <support AT codeux DOT com> <https://github.com/codeux/Textual>
// You can redistribute it and/or modify it under the new BSD license.

@interface ChanInviteExceptionSheet : SheetBase
{
	NSMutableArray *list;
	NSMutableArray *modes;
	
	IBOutlet ListView *table;
	IBOutlet NSTextField *header;
}

@property (strong) ListView *table;
@property (strong) NSTextField *header;
@property (strong) NSMutableArray *list;
@property (strong) NSMutableArray *modes;

- (void)show;
- (void)clear;

- (void)addException:(NSString *)host tset:(NSString *)time setby:(NSString *)owner;

- (void)onUpdate:(id)sender;
- (void)onRemoveExceptions:(id)sender;
@end

@interface NSObject (ChanInviteExceptionSheetDelegate)
- (void)chanInviteExceptionDialogOnUpdate:(ChanInviteExceptionSheet *)sender;
- (void)chanInviteExceptionDialogWillClose:(ChanInviteExceptionSheet *)sender;
@end