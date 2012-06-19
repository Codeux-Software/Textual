// Created by Codeux Software <support AT codeux DOT com> <https://github.com/codeux/Textual>
// You can redistribute it and/or modify it under the new BSD license.
// Converted to ARC Support on June 07, 2012

@interface TVCInputTextField : TVCTextField <NSTextViewDelegate>
@property (nonatomic, unsafe_unretained) id actionTarget;
@property (nonatomic, unsafe_unretained) SEL actionSelector;
@property (nonatomic, strong) NSAttributedString *placeholderString;

- (void)resetTextFieldCellSize;
- (void)setReturnActionWithSelector:(SEL)selector owner:(id)owner;
@end

@interface TVCInputTextFieldBackground : NSView
@end