// Created by Codeux Software <support AT codeux DOT com> <https://github.com/codeux/Textual>
// You can redistribute it and/or modify it under the new BSD license.

#import "TextualApplication.h"

@interface TVCInputTextField : TVCTextField <NSTextViewDelegate>
@property (nonatomic, unsafe_unretained) id actionTarget;
@property (nonatomic, unsafe_unretained) SEL actionSelector;
@property (nonatomic, strong) NSAttributedString *placeholderString;

- (void)updateTextDirection;
- (void)resetTextFieldCellSize;

- (void)setReturnActionWithSelector:(SEL)selector owner:(id)owner;

- (TVCInputTextFieldBackground *)backgroundView;
@end

@interface TVCInputTextFieldBackground : NSView
@property (nonatomic, assign) BOOL windowIsActive;
@end