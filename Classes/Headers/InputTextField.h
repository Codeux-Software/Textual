// Created by Codeux Software <support AT codeux DOT com> <https://github.com/codeux/Textual>
// You can redistribute it and/or modify it under the new BSD license.

@interface InputTextField : TextField
{
	NSInteger oldHeight;
}

@property (nonatomic, readonly) NSInteger oldHeight;
@end

@interface InputTextFieldCell : NSTextFieldCell 
@end