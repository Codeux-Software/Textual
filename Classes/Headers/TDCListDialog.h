// Created by Satoshi Nakagawa <psychs AT limechat DOT net> <http://github.com/psychs/limechat>
// Modifications by Codeux Software <support AT codeux DOT com> <https://github.com/codeux/Textual>
// You can redistribute it and/or modify it under the new BSD license.

#import "TextualApplication.h"

@interface TDCListDialog : NSWindowController
@property (nonatomic, unsafe_unretained) id delegate;
@property (nonatomic, assign) NSInteger sortKey;
@property (nonatomic, assign) NSComparisonResult sortOrder;
@property (nonatomic, strong) NSMutableArray *list;
@property (nonatomic, strong) NSMutableArray *filteredList;
@property (nonatomic, strong) TVCListView *table;
@property (nonatomic, strong) NSSearchField *filterText;
@property (nonatomic, strong) NSButton *updateButton;
@property (nonatomic, strong) NSTextField *channelCount;
@property (nonatomic, strong) NSTextField *networkName;

- (void)start;
- (void)show;
- (void)close;
- (void)clear;

- (void)addChannel:(NSString *)channel count:(NSInteger)count topic:(NSString *)topic;

- (void)onClose:(id)sender;
- (void)onUpdate:(id)sender;
- (void)onJoin:(id)sender;
- (void)onSearchFieldChange:(id)sender;
@end

@interface NSObject (TXListDialogDelegate)
- (void)listDialogOnUpdate:(TDCListDialog *)sender;
- (void)listDialogOnJoin:(TDCListDialog *)sender channel:(NSString *)channel;
- (void)listDialogWillClose:(TDCListDialog *)sender;
@end