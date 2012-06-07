// Created by Codeux Software <support AT codeux DOT com> <https://github.com/codeux/Textual>
// You can redistribute it and/or modify it under the new BSD license.

@interface AboutPanel : NSWindowController
{
	id __unsafe_unretained delegate;
	
	IBOutlet NSTextField *versionInfo;
}

@property (nonatomic, unsafe_unretained) id delegate;
@property (nonatomic, strong) NSTextField *versionInfo;

- (void)show;
@end

@interface NSObject (AboutPanelDelegate)
- (void)aboutPanelWillClose:(AboutPanel *)sender;
@end