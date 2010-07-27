// Created by Michael Morris <mikey AT codeux DOT com> <http://github.com/mikemac11/Textual>
// You can redistribute it and/or modify it under the new BSD license.

#import <Foundation/Foundation.h>
#import "SheetBase.h"
#import "ListView.h"

@interface ChanBanSheet : SheetBase
{
	NSMutableArray* list;
	NSString* modeString;

	IBOutlet ListView* table;
	IBOutlet NSButton* updateButton;
}

@property (retain) NSMutableArray* list;
@property (retain) ListView* table;
@property (retain) NSButton* updateButton;
@property (retain) NSString* modeString;

- (void)show;
- (void)clear;

- (void)addBan:(NSString*)host tset:(NSString*)time setby:(NSString*)owner;

- (void)onUpdate:(id)sender;
- (void)onRemoveBans:(id)sender;
@end

@interface NSObject (ChanBanDialogDelegate)
- (void)chanBanDialogOnUpdate:(ChanBanSheet*)sender;
- (void)chanBanDialogWillClose:(ChanBanSheet*)sender;
@end