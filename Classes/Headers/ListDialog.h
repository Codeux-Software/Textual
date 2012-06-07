// Created by Satoshi Nakagawa <psychs AT limechat DOT net> <http://github.com/psychs/limechat>
// Modifications by Codeux Software <support AT codeux DOT com> <https://github.com/codeux/Textual>
// You can redistribute it and/or modify it under the new BSD license.

@interface ListDialog : NSWindowController
{
	id __unsafe_unretained delegate;
	
	IBOutlet ListView *table;
	
	NSMutableArray *list;
	NSMutableArray *filteredList;
	
	NSInteger sortKey;
	
	NSComparisonResult sortOrder;
	
	IBOutlet NSButton *updateButton;
	
	IBOutlet NSTextField *channelCount;
	IBOutlet NSTextField *networkName;
	IBOutlet NSSearchField *filterText;
}

@property (nonatomic, unsafe_unretained) id delegate;
@property (nonatomic, readonly) NSInteger sortKey;
@property (nonatomic, readonly) NSComparisonResult sortOrder;
@property (nonatomic, strong) NSMutableArray *list;
@property (nonatomic, strong) NSMutableArray *filteredList;
@property (nonatomic, strong) ListView *table;
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

@interface NSObject (ListDialogDelegate)
- (void)listDialogOnUpdate:(ListDialog *)sender;
- (void)listDialogOnJoin:(ListDialog *)sender channel:(NSString *)channel;
- (void)listDialogWillClose:(ListDialog *)sender;
@end