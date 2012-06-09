// Created by Codeux Software <support AT codeux DOT com> <https://github.com/codeux/Textual>
// You can redistribute it and/or modify it under the new BSD license.
// Converted to ARC Support on Thursday, June 08, 2012

@interface TextualPluginItem : NSObject
@property (nonatomic, strong) NSBundle *pluginBundle;
@property (nonatomic, strong) PluginProtocol *pluginPrimaryClass;

- (void)initWithPluginClass:(Class)primaryClass 
				  andBundle:(NSBundle *)bundle
				andIRCWorld:(IRCWorld *)world
		  withUserInputDict:(NSMutableDictionary **)userDict
		withServerInputDict:(NSMutableDictionary **)serverDict
		 withOuputRulesDict:(NSMutableDictionary **)outputRulesDict;
@end