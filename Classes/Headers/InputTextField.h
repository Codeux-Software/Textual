// Created by Codeux Software <support AT codeux DOT com> <https://github.com/codeux/Textual>
// You can redistribute it and/or modify it under the new BSD license.

@class TextField;

@interface InputTextField : TextField <NSTextViewDelegate>
{
    NSAttributedString *_placeholderString;
    
    id _actionTarget;
    SEL _actonSelector;
}

- (void)resetTextFieldCellSize;
- (void)setReturnActionWithSelector:(SEL)selector owner:(id)owner;
@end

@interface InputTextFieldScroller : NSScrollView 
@end