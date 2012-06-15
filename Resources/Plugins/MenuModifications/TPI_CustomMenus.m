// Created by Codeux Software <support AT codeux DOT com> <https://github.com/codeux/Textual>
// You can redistribute it and/or modify it under the new BSD license.

#import "TPI_CustomMenus.h"
#import "TPI_CMP_MenuController.h"

@implementation TPI_CustomMenus

- (void)pluginLoadedIntoMemory:(IRCWorld *)world
{
	NSMenu *newMenu = world.memberMenu;
	
	NSMenuItem* newMenuItem = [[NSMenuItem alloc] initWithTitle:@"Post Link to Textual Download Page"
														  action:nil keyEquivalent:@""];
	
	[newMenuItem setTarget:world.menuController];
	[newMenuItem setAction:@selector(postLinkToTextualHomepage:)];
	
	[newMenu addItem:[NSMenuItem separatorItem]];
	[newMenu addItem:newMenuItem];
	
	world.memberMenu = newMenu;
}

@end