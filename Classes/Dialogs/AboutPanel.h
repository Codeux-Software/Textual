// Created by Codeux Software <support AT codeux DOT com> <https://github.com/codeux/Textual>
// You can redistribute it and/or modify it under the new BSD license.

@interface AboutPanel : NSWindowController
{
	id delegate;
	
	IBOutlet NSTextField *versionInfo;
}

@property (nonatomic, assign) id delegate;
@property (nonatomic, retain) NSTextField *versionInfo;

- (void)show;
@end

@interface NSObject (AboutPanelDelegate)
- (void)aboutPanelWillClose:(AboutPanel *)sender;
@end