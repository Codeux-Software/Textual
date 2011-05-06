//
//  whateverAppDelegate.m
//  whatever
//
//  Created by Michael Morris on 4/28/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "whateverAppDelegate.h"

@implementation whateverAppDelegate

@synthesize window;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
	
	NSImage *leftCell = [NSImage imageNamed:@"InputBoxLeft-Active.png"];
	
	
	[leftCell drawAtPoint:NSMakePoint(50, 50)
				 fromRect:NSZeroRect
				operation:NSCompositeSourceOver
				 fraction:1];
}

@end
