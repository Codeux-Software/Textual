// Created by Codeux Software <support AT codeux DOT com> <https://github.com/codeux/Textual>
// You can redistribute it and/or modify it under the new BSD license.

#import "TextualApplication.h"

@interface TDChanBanSheet : TDCSheetBase
@property (nonatomic, strong) TVCListView *table;
@property (nonatomic, strong) NSTextField *header;
@property (nonatomic, strong) NSMutableArray *list;
@property (nonatomic, strong) NSMutableArray *modes;

- (void)show;
- (void)clear;

- (void)addBan:(NSString *)host tset:(NSString *)time setby:(NSString *)owner;

- (void)onUpdate:(id)sender;
- (void)onRemoveBans:(id)sender;
@end

@interface NSObject (TXChanBanDialogDelegate)
- (void)chanBanDialogOnUpdate:(TDChanBanSheet *)sender;
- (void)chanBanDialogWillClose:(TDChanBanSheet *)sender;
@end