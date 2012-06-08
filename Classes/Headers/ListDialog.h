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

@property (unsafe_unretained) id delegate;
@property (readonly) NSInteger sortKey;
@property (readonly) NSComparisonResult sortOrder;
@property (strong) NSMutableArray *list;
@property (strong) NSMutableArray *filteredList;
@property (strong) ListView *table;
@property (strong) NSSearchField *filterText;
@property (strong) NSButton *updateButton;
@property (strong) NSTextField *channelCount;
@property (strong) NSTextField *networkName;

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