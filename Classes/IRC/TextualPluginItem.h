// Created by Michael Morris <mikey AT codeux DOT com> <http://github.com/mikemac11/Textual>
// You can redistribute it and/or modify it under the new BSD license.

#import <Cocoa/Cocoa.h>
#import "PluginProtocol.h"

@interface TextualPluginItem : NSObject {
	PluginProtocol *bundleClass;
}

@property (retain) PluginProtocol *bundleClass;

@end