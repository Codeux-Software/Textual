// Created by Codeux Software <support AT codeux DOT com> <https://github.com/codeux/Textual>
// You can redistribute it and/or modify it under the new BSD license.
// Converted to ARC Support on Thursday, June 09, 2012

@interface HighlightSheet : SheetBase
@property (nonatomic, strong) ListView *table;
@property (nonatomic, strong) NSTextField *header;
@property (nonatomic, weak) NSMutableArray *list;

- (void)show;
- (void)onClearList:(id)sender;
@end

@interface NSObject (highlightSheetDelegate)
- (void)highlightSheetWillClose:(HighlightSheet *)sender;
@end