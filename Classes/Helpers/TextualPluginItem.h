// Created by Michael Morris <mikey AT codeux DOT com> <http://github.com/mikemac11/Textual>
// You can redistribute it and/or modify it under the new BSD license.

#import <Cocoa/Cocoa.h>
#import "PluginProtocol.h"

@interface TextualPluginItem : NSObject {
	NSBundle *pluginBundle;
	PluginProtocol* pluginPrimaryClass;
}

@property (nonatomic, retain) NSBundle *pluginBundle;
@property (nonatomic, retain) PluginProtocol* pluginPrimaryClass;

- (void)initWithPluginClass:(Class)primaryClass 
				  andBundle:(NSBundle*)bundle
				andIRCWorld:(IRCWorld*)world
		  withUserInputDict:(NSMutableDictionary*)newUserDict
		withServerInputDict:(NSMutableDictionary*)newServerDict
	  withUserInputDictRefs:(NSMutableDictionary**)userDict
	withServerInputDictRefs:(NSMutableDictionary**)serverDict;

@end
