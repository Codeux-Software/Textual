// Created by Codeux Software <support AT codeux DOT com> <https://github.com/codeux/Textual>
// You can redistribute it and/or modify it under the new BSD license.
// Converted to ARC Support on June 09, 2012

#import "TextualApplication.h"

@implementation TDChanInviteExceptionSheet

- (id)init
{
    if ((self = [super init])) {
		[NSBundle loadNibNamed:@"TDChanInviteExceptionSheet" owner:self];
		
		self.list  = [NSMutableArray new];
        self.modes = [NSMutableArray new];
    }
    
    return self;
}

- (void)show
{
	IRCClient  *u = self.delegate;
	IRCChannel *c = [u.world selectedChannel];
	
	NSString *nheader;
	
	nheader = [self.header stringValue];
	nheader = [NSString stringWithFormat:nheader, c.name];
	
	[self.header setStringValue:nheader];
	
    [self startSheet];
}

- (void)ok:(id)sender
{
	[self endSheet];
	
	if ([self.delegate respondsToSelector:@selector(chanInviteExceptionDialogWillClose:)]) {
		[self.delegate chanInviteExceptionDialogWillClose:self];
	}
}

- (void)clear
{
    [self.list removeAllObjects];
	
    [self reloadTable];
}

- (void)addException:(NSString *)host tset:(NSString *)time setby:(NSString *)owner
{
    [self.list safeAddObject:@[host, [owner nicknameFromHostmask], time]];
    
    [self reloadTable];
}

- (void)reloadTable
{
    [self.table reloadData];
}

#pragma mark -
#pragma mark Actions

- (void)onUpdate:(id)sender
{
    if ([self.delegate respondsToSelector:@selector(chanInviteExceptionDialogOnUpdate:)]) {
		[self.delegate chanInviteExceptionDialogOnUpdate:self];
    }
}

- (void)onRemoveExceptions:(id)sender
{
    NSString *modeString;
    
	NSMutableString *str   = [NSMutableString stringWithString:@"-"];
	NSMutableString *trail = [NSMutableString string];
	
	NSIndexSet *indexes = [self.table selectedRowIndexes];
	
    NSInteger indexTotal = 0;
    
	for (NSNumber *index in [indexes arrayFromIndexSet]) {
        indexTotal++;
        
		NSArray *iteml = [self.list safeObjectAtIndex:[index unsignedIntegerValue]];
		
		if (NSObjectIsNotEmpty(iteml)) {
			[str   appendString:@"I"];
			[trail appendFormat:@" %@", [iteml safeObjectAtIndex:0]];
		}
        
		if (indexTotal == TXMaximumNodesPerModeCommand) {
            modeString = (id)[str stringByAppendingString:trail];
            
            [self.modes safeAddObject:modeString];
            
            [str   setString:@"-"];
            [trail setString:NSStringEmptyPlaceholder];
            
            indexTotal = 0;
        }
	}
	
    if (NSObjectIsNotEmpty(trail)) {
        modeString = (id)[str stringByAppendingString:trail];
        
        [self.modes safeAddObject:modeString];
    }
    
	[self ok:sender];
}

#pragma mark -
#pragma mark NSTableView Delegate

- (NSInteger)numberOfRowsInTableView:(NSTableView *)sender
{
    return self.list.count;
}

- (id)tableView:(NSTableView *)sender objectValueForTableColumn:(NSTableColumn *)column row:(NSInteger)row
{
    NSArray *item = [self.list safeObjectAtIndex:row];

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