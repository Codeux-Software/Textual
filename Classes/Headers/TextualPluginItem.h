// Created by Codeux Software <support AT codeux DOT com> <https://github.com/codeux/Textual>
// You can redistribute it and/or modify it under the new BSD license.

@interface TextualPluginItem : NSObject {
	NSBundle *pluginBundle;
	
	PluginProtocol *pluginPrimaryClass;
}

@property (nonatomic, retain) NSBundle *pluginBundle;
@property (nonatomic, retain) PluginProtocol *pluginPrimaryClass;

- (void)initWithPluginClass:(Class)primaryClass 
				  andBundle:(NSBundle *)bundle
				andIRCWorld:(IRCWorld *)world
		  withUserInputDict:(NSMutableDictionary **)userDict
		withServerInputDict:(NSMutableDictionary **)serverDict
		 withOuputRulesDict:(NSMutableDictionary **)outputRulesDict;

@end