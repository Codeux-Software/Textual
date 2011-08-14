// Created by Codeux Software <support AT codeux DOT com> <https://github.com/codeux/Textual>
// You can redistribute it and/or modify it under the new BSD license.

@interface ChanBanExceptionSheet : SheetBase
{
	NSMutableArray *list;
	NSMutableArray *modes;
	
	IBOutlet ListView *table;
	IBOutlet NSTextField *header;
}

@property (nonatomic, retain) ListView *table;
@property (nonatomic, retain) NSTextField *header;
@property (nonatomic, retain) NSMutableArray *list;
@property (nonatomic, retain) NSMutableArray *modes;

- (void)show;
- (void)clear;

- (void)addException:(NSString *)host tset:(NSString *)time setby:(NSString *)owner;

- (void)onUpdate:(id)sender;
- (void)onRemoveExceptions:(id)sender;
@end

@interface NSObject (ChanBanExceptionSheetDelegate)
- (void)chanBanExceptionDialogOnUpdate:(ChanBanExceptionSheet *)sender;
- (void)chanBanExceptionDialogWillClose:(ChanBanExceptionSheet *)sender;
@end