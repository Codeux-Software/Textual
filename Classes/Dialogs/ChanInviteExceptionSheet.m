
// Created by Codeux Software <support AT codeux DOT com> <https://github.com/codeux/Textual>
// You can redistribute it and/or modify it under the new BSD license.

@interface ChanInviteExceptionSheet (Private)
- (void)reloadTable;
@end

@implementation ChanInviteExceptionSheet

@synthesize list;
@synthesize table;
@synthesize header;
@synthesize modes;

- (id)init
{
    if ((self = [super init])) {
		[NSBundle loadNibNamed:@"ChanInviteExceptionSheet" owner:self];
		
		list  = [NSMutableArray new];
        modes = [NSMutableArray new];
    }
    
    return self;
}

- (void)dealloc
{
    [list drain];
	[modes drain];
	
    [super dealloc];
}

- (void)show
{
	IRCClient  *u = delegate;
	IRCChannel *c = [u.world selectedChannel];
	
	NSString *nheader;
	
	nheader = [header stringValue];
	nheader = [NSString stringWithFormat:nheader, c.name];
	
	[header setStringValue:nheader];
	
    [self startSheet];
}

- (void)ok:(id)sender
{
	[self endSheet];
	
	if ([delegate respondsToSelector:@selector(chanInviteExceptionDialogWillClose:)]) {
		[delegate chanInviteExceptionDialogWillClose:self];
	}
}

- (void)clear
{
    [list removeAllObjects];
	
    [self reloadTable];
}

- (void)addException:(NSString *)host tset:(NSString *)time setby:(NSString *)owner
{
    [list safeAddObject:[NSArray arrayWithObjects:host, [owner nicknameFromHostmask], time, nil]];
    
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
    if ([delegate respondsToSelector:@selector(chanInviteExceptionDialogOnUpdate:)]) {
		[delegate chanInviteExceptionDialogOnUpdate:self];
    }
}

- (void)onRemoveExceptions:(id)sender
{
    NSString *modeString;
    
	NSMutableString *str   = [NSMutableString stringWithString:@"-"];
	NSMutableString *trail = [NSMutableString string];
	
	NSIndexSet *indexes = [table selectedRowIndexes];
	
    NSInteger indexTotal = 0;
    
	for (NSNumber *index in [indexes arrayFromIndexSet]) {
        indexTotal++;
        
		NSArray *iteml = [list safeObjectAtIndex:[index unsignedIntegerValue]];
		
		if (NSObjectIsNotEmpty(iteml)) {
			[str   appendString:@"I"];
			[trail appendFormat:@" %@", [iteml safeObjectAtIndex:0]];
		}
        
		if (indexTotal == MAXIMUM_SETS_PER_MODE) {
            modeString = (id)[str stringByAppendingString:trail];
            
            [modes safeAddObject:modeString];
            
            [str   setString:@"-"];
            [trail setString:NSNullObject];
            
            indexTotal = 0;
        }
	}
	
    if (NSObjectIsNotEmpty(trail)) {
        modeString = (id)[str stringByAppendingString:trail];
        
        [modes safeAddObject:modeString];
    }
    
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