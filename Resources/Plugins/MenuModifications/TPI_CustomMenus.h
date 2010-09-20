#import <Cocoa/Cocoa.h>

#include "IRCWorld.h"
#include "IRCClient.h"
#include "NSObject+DDExtensions.h"

@interface TPI_CustomMenus : NSObject
- (void)pluginLoadedIntoMemory:(IRCWorld *)world;
@end
