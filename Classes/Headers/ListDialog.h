// Created by Satoshi Nakagawa <psychs AT limechat DOT net> <http://github.com/psychs/limechat>
// Modifications by Codeux Software <support AT codeux DOT com> <https://github.com/codeux/Textual>
// You can redistribute it and/or modify it under the new BSD license.

@interface ListDialog : NSWindowController
{
	id delegate;
	
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

@property (assign) id delegate;
@property (readonly) NSInteger sortKey;
@property (readonly) NSComparisonResult sortOrder;
@property (retain) NSMutableArray *list;
@property (retain) NSMutableArray *filteredList;
@property (retain) ListView *table;
@property (retain) NSSearchField *filterText;
@property (retain) NSButton *updateButton;
@property (retain) NSTextField *channelCount;
@property (retain) NSTextField *networkName;

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