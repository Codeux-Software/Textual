/* ********************************************************************* 
                  _____         _               _
                 |_   _|____  _| |_ _   _  __ _| |
                   | |/ _ \ \/ / __| | | |/ _` | |
                   | |  __/>  <| |_| |_| | (_| | |
                   |_|\___/_/\_\\__|\__,_|\__,_|_|

 Copyright (c) 2008 - 2010 Satoshi Nakagawa <psychs AT limechat DOT net>
 Copyright (c) 2010 - 2015 Codeux Software, LLC & respective contributors.
        Please see Acknowledgements.pdf for additional information.

 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions
 are met:

    * Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the
      documentation and/or other materials provided with the distribution.
    * Neither the name of Textual and/or "Codeux Software, LLC", nor the 
      names of its contributors may be used to endorse or promote products 
      derived from this software without specific prior written permission.

 THIS SOFTWARE IS PROVIDED BY THE AUTHOR AND CONTRIBUTORS ``AS IS'' AND
 ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 ARE DISCLAIMED. IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE LIABLE
 FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
 OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
 LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
 OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
 SUCH DAMAGE.

 *********************************************************************** */

#import "TextualApplication.h"

@implementation NSOutlineView (TXOutlineViewHelper)

- (NSInteger)countSelectedRows
{
	return [[self selectedRowIndexes] count];
}

- (void)selectItemAtIndex:(NSInteger)index
{
	[self selectRowIndexes:[NSIndexSet indexSetWithIndex:index] byExtendingSelection:NO];
	
	[self scrollRowToVisible:index];
}

- (BOOL)isGroupItem:(id)item
{
	return ([self levelForItem:item] == 0);
}

- (NSInteger)rowForGroupItem:(id)item
{
	if ([self isGroupItem:item]) {
		NSInteger rowCount = -1;
		
		for (NSInteger i = 0; i < [self numberOfRows]; i++) {
			id curRow = [self itemAtRow:i];
			
			if ([self isGroupItem:curRow]) {
				rowCount += 1;
				
				if (item == curRow) {
					return rowCount;
				}
			}
		}
	}
	
	return -1;
}

- (NSArray *)groupItems
{
	NSMutableArray *groups = [NSMutableArray array];
	
	for (NSInteger i = 0; i < [self numberOfRows]; i++) {
		id curRow = [self itemAtRow:i];
		
		if ([self isGroupItem:curRow]) {
			[groups addObject:curRow];
		}
	}
	
	return groups;
}

- (NSArray *)rowsFromParentGroup:(id)child
{
	if ([self isGroupItem:child] == NO) {
		child = [self parentForItem:child];
	}
	
	return [self rowsInGroup:child];
}

- (NSArray *)rowsInGroup:(id)group
{
	NSMutableArray *allRows = [NSMutableArray array];
	
	for (NSInteger i = 0; i < [self numberOfRows]; i++) {
		id curent = [self itemAtRow:i];
		id parent = [self parentForItem:curent];

		if ([parent isEqual:group]) {
			[allRows addObject:curent];
		}
	}
	
	return allRows;
}

@end
