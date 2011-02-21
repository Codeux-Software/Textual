// Created by Codeux Software <support AT codeux DOT com> <https://github.com/codeux/Textual>
// You can redistribute it and/or modify it under the new BSD license.

@interface ChanBanSheet : SheetBase
{
	NSString *modeString;
	NSMutableArray *list;
	
	IBOutlet ListView *table;
}

@property (nonatomic, retain) ListView *table;
@property (nonatomic, retain) NSString *modeString;
@property (nonatomic, retain) NSMutableArray *list;

- (void)show;
- (void)clear;

- (void)addBan:(NSString *)host tset:(NSString *)time setby:(NSString *)owner;

- (void)onUpdate:(id)sender;
- (void)onRemoveBans:(id)sender;
@end

@interface NSObject (ChanBanDialogDelegate)
- (void)chanBanDialogOnUpdate:(ChanBanSheet *)sender;
- (void)chanBanDialogWillClose:(ChanBanSheet *)sender;
@end