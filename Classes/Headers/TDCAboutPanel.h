// Created by Codeux Software <support AT codeux DOT com> <https://github.com/codeux/Textual>
// You can redistribute it and/or modify it under the new BSD license.

#import "TextualApplication.h"

@interface TDCAboutPanel : NSWindowController
@property (nonatomic, unsafe_unretained) id delegate;
@property (nonatomic, strong) NSTextField *versionInfo;

- (void)show;
@end

@interface NSObject (TXAboutPanelDelegate)
- (void)aboutPanelWillClose:(TDCAboutPanel *)sender;
@end