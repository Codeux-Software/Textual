#import <Cocoa/Cocoa.h>
#import "PluginProtocol.h"

@interface TextualPluginItem : NSObject {
	PluginProtocol *bundleClass;
}

@property (retain) PluginProtocol *bundleClass;

@end