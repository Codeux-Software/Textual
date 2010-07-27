// Created by Satoshi Nakagawa <psychs AT limechat DOT net> <http://github.com/psychs/limechat>
// Modifications by Michael Morris <mikey AT codeux DOT com> <http://github.com/mikemac11/Textual>
// You can redistribute it and/or modify it under the new BSD license.

#import <Cocoa/Cocoa.h>

@class MenuController;

@interface LogPolicy : NSObject
{
	MenuController* menuController;
	NSMenu* menu;
	NSMenu* urlMenu;
	NSMenu* addrMenu;
	NSMenu* memberMenu;
	NSMenu* chanMenu;
	NSString* url;
	NSString* addr;
	NSString* nick;
	NSString* chan;
}

@property (assign) id menuController;
@property (retain) NSMenu* menu;
@property (retain) NSMenu* urlMenu;
@property (retain) NSMenu* addrMenu;
@property (retain) NSMenu* memberMenu;
@property (retain) NSMenu* chanMenu;
@property (retain) NSString* url;
@property (retain) NSString* addr;
@property (retain) NSString* nick;
@property (retain) NSString* chan;

@end