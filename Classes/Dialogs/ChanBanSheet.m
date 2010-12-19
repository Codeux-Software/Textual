// Created by Codeux Software <support AT codeux DOT com> <https://github.com/codeux/Textual>
// You can redistribute it and/or modify it under the new BSD license.

#import "ChanBanSheet.h"

@interface ChanBanSheet (Private)
- (void)reloadTable;
@end

@implementation ChanBanSheet

@synthesize list;
@synthesize table;
@synthesize updateButton;
@synthesize modeString;

- (id)init
{
    if ((self = [super init])) {
	  [NSBundle loadNibNamed:@"ChanBanSheet" owner:self];
	  
	  list = [NSMutableArray new];
    }
    
    return self;
}

- (void)dealloc
{
    [list release];
    [super dealloc];
}

- (void)show
{
    [self startSheet];
}

- (void)ok:(id)sender
{
	[self endSheet];
	
	if ([delegate respondsToSelector:@selector(chanBanDialogWillClose:)]) {
		[delegate chanBanDialogWillClose:self];
	}
}

- (void)clear
{
    [list removeAllObjects];
	
    [self reloadTable];
}

- (void)addBan:(NSString *)host tset:(NSString *)time setby:(NSString *)owner
{
    [list addObject:[NSArray arrayWithObjects:host, [owner nicknameFromHostmask], time, nil]];
    
    [self reloadTable];
}

- (void)reloadTable
{
    [table reloadData];
}

#pragma mark -
#pragma mark Actions

- (void)onUpdate:(id)sender
{
    if ([delegate respondsToSelector:@selector(chanBanDialogOnUpdate:)]) {
	  [delegate chanBanDialogOnUpdate:self];
    }
}

- (void)onRemoveBans:(id)sender
{
	NSMutableString *str = [NSMutableString stringWithString:@"-"];
	NSMutableString *trail = [NSMutableString string];
	
	NSIndexSet *indexes = [table selectedRowIndexes];
	NSUInteger current_index = [indexes lastIndex];
	
	while (current_index != NSNotFound)
	{
		[str appendString:@"b"];
		[trail appendFormat:@" %@", [[list safeObjectAtIndex:current_index] safeObjectAtIndex:0]];
		
		current_index = [indexes indexLessThanIndex:current_index];
	}
	
	modeString = [str stringByAppendingString:trail];
    
	[self ok:sender];
}

#pragma mark -
#pragma mark NSTableView Delegate

- (NSInteger)numberOfRowsInTableView:(NSTableView *)sender
{
    return list.count;
}

- (id)tableView:(NSTableView *)sender objectValueForTableColumn:(NSTableColumn *)column row:(NSInteger)row
{
    NSArray *item = [list safeObjectAtIndex:row];
    NSString *col = [column identifier];
    
    if ([col isEqualToString:@"mask"]) {
	  return [item safeObjectAtIndex:0];
    } else if ([col isEqualToString:@"setby"]) {
	  return [item safeObjectAtIndex:1];
    } else {
	  return [item safeObjectAtIndex:2];
    }
}

@end