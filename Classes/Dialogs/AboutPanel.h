// Created by Michael Morris <mikey AT codeux DOT com> <http://github.com/mikemac11/Textual>
// You can redistribute it and/or modify it under the new BSD license.

#import <Foundation/Foundation.h>

@interface AboutPanel : NSWindowController
{
	id delegate;
	
	IBOutlet NSTextField *versionInfo;
}

@property (assign) id delegate;
@property (retain) NSTextField *versionInfo;

- (void)show;
@end

@interface NSObject (AboutPanelDelegate)
- (void)aboutPanelWillClose:(AboutPanel*)sender;
@end