// Created by Codeux Software <support AT codeux DOT com> <https://github.com/codeux/Textual>
// You can redistribute it and/or modify it under the new BSD license.
// Converted to ARC Support on Thursday, June 07, 2012

@class TextField;

@interface InputTextField : TextField <NSTextViewDelegate>
@property (nonatomic, assign) id _actionTarget;
@property (nonatomic, assign) SEL _actionSelector;
@property (nonatomic, strong) NSAttributedString *_placeholderString;

- (void)resetTextFieldCellSize;
- (void)setReturnActionWithSelector:(SEL)selector owner:(id)owner;
@end

@interface InputTextFieldScroller : NSScrollView 
@end