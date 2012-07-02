// Created by Codeux Software <support AT codeux DOT com> <https://github.com/codeux/Textual>
// You can redistribute it and/or modify it under the new BSD license.

#import "TextualApplication.h"

@interface TDCHighlightSheet : TDCSheetBase
@property (nonatomic, strong) TVCListView *table;
@property (nonatomic, strong) NSTextField *header;
@property (nonatomic, weak) NSMutableArray *list;

- (void)show;
- (void)onClearList:(id)sender;
@end

@interface NSObject (TXHighlightSheetDelegate)
- (void)highlightSheetWillClose:(TDCHighlightSheet *)sender;
@end